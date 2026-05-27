import { _calculateAgeFromBirthdate, _isNewbornMember } from "./aRC_FormCensusSpinOffUtilities";

// Field API name to label map
export const REQUIRED_FIELDS = {
    'vlocity_ins__FirstName__c': 'First Name',
    'vlocity_ins__LastName__c': 'Last Name',
    'vlocity_ins__Birthdate__c': 'Date of Birth',
    'vlocity_ins__Gender__c': 'Gender',
    'ARC_HeightFeet__c': 'Height (Feet)',
    'ARC_HeightInches__c': 'Height (Inches)',
    'ARC_Weight__c': 'Weight',
    'ARC_PhysicalAddressCity__c': 'City',
    'ARC_PhysicalAddressState__c': 'State',
    'ARC_PhysicalAddressStreet__c': 'Street Address',
    'ARC_PhysicalAddressZipCode__c': 'Zip Code',
    'ARC_Phone__c': 'Phone',
    'vlocity_ins__SocialSecurityNumber__c': 'Social Security Number',
    'ARC_Relationship__c': 'Relationship',
    'vlocity_ins__Email__c': 'Email',
};

/**
 * Validates if required fields are populated based on business rules
 * @param {string} field_name - The name of the field to validate
 * @param {object} member - The member object containing field values
 * @param {number} member_index - Index of the member in the collection
 * @returns {object|null} Validation result object or null if field isn't required
 */
export function validateRequiredFields(field_name, member, member_index) {
    // Skip if this field isn't in our required fields list
    if (!Object.keys(REQUIRED_FIELDS).includes(field_name)) {
        return null;
    }

    if(member['IsRemoveMember'] == true){
        console.log(' remove member fields are not requried' )
        return null;
    }

    const fieldLabel = REQUIRED_FIELDS[field_name];
    // Extract the field value, handling both direct values and nested value objects
    const value = member[field_name]?.value !== undefined ? member[field_name].value : member[field_name];

    // Special case: Phone and Email aren't required for minors (under 18)
    const isChild = member.ARC_Relationship__c.value === 'Child';
    const isMinor = member.ARC_Age__c < 18;
    const isContactField = field_name === 'ARC_Phone__c' || field_name === 'vlocity_ins__Email__c';
    
    if (isChild && isMinor && isContactField) {
        return {
            name: `validateRequiredField${field_name}`,
            member_index,
            success: true, // Validation passes for this special case
        };
    }

    // Standard required field validation
    if (value == '' || value == undefined || value == null) {
        return {
            name: `validateRequiredField${field_name}`,
            member_index,
            success: false,
            error_message: `The field "${fieldLabel}" is required and cannot be empty.`,
        };
    }

    // If we get here, the field has a value and validation passes
    return {
        name: `validateRequiredField${field_name}`,
        member_index,
        success: true,
    };
}

// Validate SSN format (only digits allowed)
export function validateSSNFormat(field_name, modified_member, member_index) {
    if (field_name !== 'vlocity_ins__SocialSecurityNumber__c' && field_name !== 'vlocity_ins__Birthdate__c') {
        return null;
    }

    const SSN = modified_member.vlocity_ins__SocialSecurityNumber__c;
    const isNewborn = _isNewbornMember(modified_member);

    if (!isNewborn) {
        const isValid = SSN && /^[0-9]+$/.test(SSN);
        return isValid
            ? { name: 'validateSSNFormat', member_index, success: true }
            : { name: 'validateSSNFormat', member_index, success: false, error_message: "Field SSN must contain only numbers and cannot be empty." };
    }

    // Newborn logic: allow empty but ensure only numbers if present
    if (!SSN || /^[0-9]*$/.test(SSN)) {
        return { name: 'validateSSNFormat', member_index, success: true };
    }

    return { name: 'validateSSNFormat', member_index, success: false, error_message: "Field SSN must contain only numbers." };
}

// Validate US ZIP Code format (5 digits or 5+4 with hyphen, max 10 chars)
export function validateZipCodeFormat(field_name, value, member_index) {
    if (field_name !== 'ARC_PhysicalAddressZipCode__c') return null;

    const zipRegex = /^\d{5}(-\d{4})?$/;

    if (!value) {
        return { name: 'validateZipCodeFormat', member_index, success: false, error_message: "Zip Code is required." };
    }
    if (value.length > 10) {
        return { name: 'validateZipCodeFormat', member_index, success: false, error_message: "Zip Code must be at most 10 characters." };
    }
    if (!zipRegex.test(value)) {
        return { name: 'validateZipCodeFormat', member_index, success: false, error_message: "Zip Code must be 5 digits or 5+4 digits (e.g. 12345 or 12345-6789)." };
    }
    return { name: 'validateZipCodeFormat', member_index, success: true };
}

export function validateMiddleInitialFormat(field_name, modified_member, member_index) {
    if(field_name !== 'ARC_MiddleInitial__c'){
        return null
    }

    let regExp = /^[a-zA-Z]*$/; // Only letters

    if (regExp.test(modified_member['ARC_MiddleInitial__c'])) {
        return { name: 'validateMiddleInitialFormat', member_index, success: true };
    }

    return { name: 'validateMiddleInitialFormat', member_index, success: false, error_message: "Middle Initial can contain only letters." };
}

export function validatePhoneNumberFormat(field_name, value, member_index) {
    if (field_name !== 'ARC_Phone__c') {
        return null
    }

    if (!value) {
        return { name: 'validatePhoneNumberFormat', member_index, success: false, error_message: "Phone number is too short." };
    }

    if (value.length == 10) {
        return { name: 'validatePhoneNumberFormat', member_index, success: true };
    } else if (value.length < 10) {
        return { name: 'validatePhoneNumberFormat', member_index, success: false, error_message: "Phone number is too short." };
    }
}


// Validate Email format
export function validateEmailFormat(field_name, value, member_index) {
    if (field_name === 'vlocity_ins__Email__c') {
        console.log('validation email runs');
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/; // Standard email regex
        if (emailRegex.test(value)) {
            return { name: 'validateEmail', member_index, success: true }
        } else {
            return { name: 'validateEmail', member_index, success: false, error_message: "Invalid email format." }
        }
    }
    return null
}

// Validate height in feet (0-7)
export function validateHeightFeet(field_name, value, member_index) {
    if (field_name !== 'ARC_HeightFeet__c') return null;

    const feet = Number(value); // Ensure it's a number
    if (!Number.isInteger(feet) || feet < 0 || feet > 7) {
        return { name: 'validateHeightFeet', member_index, success: false, error_message: "Height (feet) must be between 0 and 7." };
    }

    return { name: 'validateHeightFeet', member_index, success: true };
}

// Validate height in inches (0-12)
export function validateHeightInches(field_name, value, member_index) {
    if (field_name !== 'ARC_HeightInches__c') return null;

    const inches = Number(value); // Ensure it's a number
    if (!Number.isInteger(inches) || inches < 0 || inches > 12) {
        return { name: 'validateHeightInches', member_index, success: false, error_message: "Height (inches) must be between 0 and 12." };
    }

    return { name: 'validateHeightInches', member_index, success: true };
}

// Validate that the date is not in the future
export function validateIsNotFutureDate(field_name, inputDate, member_index) {
    return field_name === 'vlocity_ins__Birthdate__c' ?
        new Date(inputDate) > new Date() ? { name: 'validateIsNotFutureDate', member_index, success: false, error_message: "Date of birth cannot be in the future." }
            : { name: 'validateIsNotFutureDate', member_index, success: true }
        : null;
}

// Validate that legal adults have both phone and email
export function validateLegalAdultPhoneAndEmail(field_name, modified_member, member_index) {
    if (['vlocity_ins__Birthdate__c', 'ARC_Phone__c', 'vlocity_ins__Email__c'].includes(field_name)) {
        const age = modified_member.ARC_Age__c;
        return age >= 18 && (!modified_member.vlocity_ins__Email__c || !modified_member.ARC_Phone__c) ?
            { name: 'validateLegalAdultPhoneAndEmail', member_index, success: false, error_message: "Legal adult must have both phone and email." }
            : { name: 'validateLegalAdultPhoneAndEmail', member_index, success: true };
    }
    return null;
}

// Validate that the primary member or spouse is not older than 64
export function validateMaxAge64PrimaryAndSpouse(field_name, modified_member, member_index) {
    if ((field_name === 'ARC_Relationship__c' || field_name === 'vlocity_ins__Birthdate__c')) {
        if (modified_member.ARC_Relationship__c.value === 'Primary' || modified_member.ARC_Relationship__c.value === 'Spouse') {
            const age = modified_member.ARC_Age__c;
            if (age < 65) {
                return { name: 'validateMaxAge64PrimaryAndSpouse', member_index, success: true };
            } else {
                return { name: 'validateMaxAge64PrimaryAndSpouse', member_index, success: false, error_message: "The date must not be more than 65 years old." };
            }
        }
        return { name: 'validateMaxAge64PrimaryAndSpouse', member_index, success: true }
    }
    return null;
}

// Validate that a child is not older than 26
export function validateMaxAge26Children(field_name, modified_member, member_index) {
    if ((field_name === 'ARC_Relationship__c' || field_name === 'vlocity_ins__Birthdate__c')) {
        if (modified_member.ARC_Relationship__c.value === 'Child') {
            const age = modified_member.ARC_Age__c;
            if (age < 27) {
                return { name: 'validateMaxAge26Children', member_index, success: true };
            } else {
                return { name: 'validateMaxAge26Children', member_index, success: false, error_message: "The date must not be more than 27 years old." };
            }
        } else {
            return { name: 'validateMaxAge26Children', member_index, success: true };
        }
    }
    return null;
}

// Validate that there is exactly one primary member
export function validateUniquePrimaryMember(field_name, census_members) {
    if (field_name === 'ARC_Relationship__c' || field_name == null) {
        const primaryCount = census_members.filter(member => member.ARC_Relationship__c.value === 'Primary' && member.IsRemoveMember === false).length;
        return primaryCount !== 1 ?
            { name: 'validateUniquePrimaryMember', member_index: null, success: false, error_message: "Census must have exactly one primary member." }
            : { name: 'validateUniquePrimaryMember', member_index: null, success: true };
    }
    return null;
}

// Validate that there is at most one spouse
export function validateUniqueSpouse(field_name, census_members) {
    if (field_name === 'ARC_Relationship__c' || field_name == null) {
        const spouseCount = census_members.filter(member => member.ARC_Relationship__c.value === 'Spouse' && member.IsRemoveMember === false).length;
        return spouseCount > 1 ?
            { name: 'validateUniqueSpouse', member_index: null, success: false, error_message: "Census must have only one spouse." }
            : { name: 'validateUniqueSpouse', member_index: null, success: true };
    }
    return null;
}

// Validate that the spouse is a legal adult
export function validateSpouseIsLegalAdult(field_name, modified_member, member_index) {
    if (['vlocity_ins__Birthdate__c', 'ARC_Relationship__c'].includes(field_name)) {
        if (modified_member.ARC_Relationship__c.value == 'Spouse') {
            if (modified_member.ARC_Age__c < 18) {
                return { name: 'validateSpouseIsLegalAdult', member_index, success: false, error_message: "Spouse must be a legal adult." }
            } else {
                return { name: 'validateSpouseIsLegalAdult', member_index, success: true };
            }
        }
        return { name: 'validateSpouseIsLegalAdult', member_index, success: true };
    }
    return null;
}

// Validate that an underage primary member has no spouse
export function validateUnderagePrimaryHasNoSpouse(field_name, census_members) {
    if (['vlocity_ins__Birthdate__c', 'ARC_Relationship__c'].includes(field_name) || field_name == null) {
        const primary_member = census_members.filter(member => member.ARC_Relationship__c.value === 'Primary' && member.IsRemoveMember === false);
        const spouse_member = census_members.filter(member => member.ARC_Relationship__c.value === 'Spouse' && member.IsRemoveMember === false);
        if (primary_member.length == 1 && spouse_member.length > 0 && primary_member[0].ARC_Age__c < 18) {
            return { name: 'validateUnderagePrimaryHasNoSpouse', member_index: null, success: false, error_message: "Underage primary cannot have a spouse." };
        } else {
            return { name: 'validateUnderagePrimaryHasNoSpouse', member_index: null, success: true };
        }
    }
    return null;
}

// Validate that the underage primary member is the oldest
export function validateUnderagePrimaryIsOldestMember(field_name, census_members) {
    if (['vlocity_ins__Birthdate__c', 'ARC_Relationship__c'].includes(field_name) || field_name == null) {
        const primary_member = census_members.filter(member => member.ARC_Relationship__c.value === 'Primary' && member.IsRemoveMember === false)
        if (primary_member.length == 1 && primary_member[0].ARC_Age__c < 18) {
            // Exclude the modified member from the comparison
            const otherMembers = census_members.filter(member => member.Id !== primary_member[0].Id && member.IsRemoveMember === false);
            // Check if modified member has the earliest birthdate (i.e., is the oldest)
            const isOldest = otherMembers.every(member =>
                !member.vlocity_ins__Birthdate__c || !primary_member[0].vlocity_ins__Birthdate__c ||
                new Date(primary_member[0].vlocity_ins__Birthdate__c) <= new Date(member.vlocity_ins__Birthdate__c)
            );
            return isOldest
                ? { name: 'validateUnderagePrimaryIsOldestMember', member_index: null, success: true }
                : { name: 'validateUnderagePrimaryIsOldestMember', member_index: null, success: false, error_message: "Primary member must be the oldest member." };
        }
        return { name: 'validateUnderagePrimaryIsOldestMember', member_index: null, success: true };
    }
    return null;
}

// Validate if state is available
export function validateAvailableState(field_name, value, member_index, availableStates) {

    if (field_name !== 'ARC_PhysicalAddressState__c') return null;
    
    console.log('member_index +  value -> ' + member_index + ' ' + value)
    if(value != ''){
        let normalizedValue = (value || '').toUpperCase();
        console.log('normalizedValue -> ' + Array.isArray(availableStates))
        if (Array.isArray(availableStates) && !availableStates.includes(normalizedValue)) {
            return {
                name: 'validateAvailableState',
                member_index,
                success: false,
                error_message: 'Please insert a valid state.',
            };
        }

    }else if(!value ){
        return {
            name: 'validateAvailableState',
            member_index,
            success: false,
            error_message: 'State cannot be empty.',
        };

    }

    return { name: 'validateAvailableState', member_index, success: true };
}