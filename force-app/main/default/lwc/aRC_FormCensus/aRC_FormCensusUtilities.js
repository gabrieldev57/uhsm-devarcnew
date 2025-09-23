import {
    validateRequiredFields, validateSSNFormat, validateMiddleInitialFormat, validatePhoneNumberFormat, validateHeightFeet, validateHeightInches, validateIsNotFutureDate,
    validateLegalAdultPhoneAndEmail, validateUniquePrimaryMember, validateUniqueSpouse,
    validateSpouseIsLegalAdult, validateUnderagePrimaryHasNoSpouse, validateMaxAge64PrimaryAndSpouse,
    validateMaxAge26Children, validateUnderagePrimaryIsOldestMember, validateEmailFormat, validateAvailableState,
    REQUIRED_FIELDS
} from "./aRC_FormCensusValidations";

/**
 * Fetches existing members for a given ARC_FormCensus object by making an Apex remote call.
 * @param {Object} ARC_FormCensus - The ARC_FormCensus object containing the census_id and other relevant data.
 * @returns {Array} - An array of census members retrieved from the server.
 */
export async function GET_CensusMembers(ARC_FormCensus) {
    const response = await ARC_FormCensus.omniRemoteCall({
        input: { 'contract_id': ARC_FormCensus.contract_id, 'census_id': ARC_FormCensus.census_id, 'is_pcspinoff': ARC_FormCensus.is_pcspinoff },
        sClassName: "ARC_FormCensusController",
        sMethodName: "GET_CensusMembers",
        options: "{}",
    }, true);
    return response.result.census_members;
}

/**
 * Fetches inactive members for a given ARC_FormCensus object by making an Apex remote call.
 * @param {Object} ARC_FormCensus - The ARC_FormCensus object containing the census_id and other relevant data.
 * @param {string} search_input - The search input for inactive members.
 * @returns {Array} - An array of inactive census members retrieved from the server.
 */
export async function GET_InactiveCensusMembers(ARC_FormCensus, census_members) {
    const response = await ARC_FormCensus.omniRemoteCall({
        input: { 'census_id': ARC_FormCensus.census_id, 'contract_id': ARC_FormCensus.contract_id, 'census_members': census_members },
        sClassName: "ARC_FormCensusController",
        sMethodName: "GET_InactiveCensusMembers",
        options: "{}",
    }, true);
    return response.result.inactive_members;
}

/**
 * Fetches inactive members for a given ARC_FormCensus object by making an Apex remote call.
 * @param {Object} ARC_FormCensus - The ARC_FormCensus object containing the census_id and other relevant data.
 * @param {string} search_input - The search input for inactive members.
 * @returns {Array} - An array of inactive census members retrieved from the server.
 */
export async function GET_InactiveCensusMemberDetails(ARC_FormCensus, existing_member_id) {
    const response = await ARC_FormCensus.omniRemoteCall({
        input: { 'census_member_id': existing_member_id },
        sClassName: "ARC_FormCensusController",
        sMethodName: "GET_InactiveCensusMemberDetails",
        options: "{}",
    }, true);
    return response.result.census_member_details;
}

/**
 * Adds a new member to the ARC_FormCensus object's census_members array.
 * The new member is a copy of the last member in the array, with most properties reset to default values.
 * @param {Array} census_members - The census_members array.
 * @returns {Array} - A new array with the updated census_members, including the new member.
 */
export function addNewMember(census_members) {

    // Create a deep copy of the last member in the array
    const newMember = JSON.parse(JSON.stringify(census_members[census_members.length - 1]));

    let fictionalId = `MEM-${Date.now()}${Math.floor(Math.random() * 1000)}`;

    // Add additional properties to the new member
    const updatedMember = {
        ...newMember,
        Id: fictionalId,
        PersonContactId: fictionalId,
        PersonAccountId: fictionalId,
        IsNewMember: true,
        IsRemoveMember: false,
        ShowMember: true,
        DISABLE_INPUT_FIELDS: false,
        DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS: false,
        DISPLAY_BUTTON_REMOVE_MEMBER: true,
        DISPLAY_MODAL_REMOVE_MEMBER: false,
        ShowAddressForDependent: false,
        CopyAddressFromPrimary: true,
        IsDependent: true,
        vlocity_ins__Gender__c: { ...newMember.vlocity_ins__Gender__c, value: '' },
        ARC_Relationship__c: {
            options: [
                { label: 'Primary', value: 'Primary' },
                { label: 'Spouse', value: 'Spouse' },
                { label: 'Child', value: 'Child' }
            ], 
            value: ''
        },
        ARC_Phone__c: { DISPLAY_FIELD: true, value: '' },
        vlocity_ins__Email__c: { DISPLAY_FIELD: true, value: '' },
        ARC_Smoker__c: { DISPLAY_FIELD: true, value: false },
        ARC_isPregnant__c: { DISPLAY_FIELD: true, value: false },
        vlocity_ins__IsPrimaryMember__c: false,
        ARC_Age__c: null,
        ARC_Weight__c: null,
        ARC_HeightInches__c: null,
        ARC_HeightFeet__c: null,
        showSSN: 'password',
        vlocity_ins__SocialSecurityNumber__c: '',
        vlocity_ins__Birthdate__c: null,
        ARC_MiddleInitial__c: '',
        vlocity_ins__FirstName__c: '',
        vlocity_ins__LastName__c: '',
        individual_errors: [],
    };

    // Return a new array with the updated member added
    return [...census_members, updatedMember];
}


/**
 * Adds an inactive member to the ARC_FormCensus object's census_members array.
 * @param {Array} census_members - The census_members array.
 * @param {Object} existing_member - The inactive member to add.
 * @returns {Array} - The updated census_members array with the inactive member added.
 */
export function addExistingMember(census_members, existing_member, census_errors) {
    const updatedMember = { ...existing_member, IsInactiveMember: true, IsNewMember: false, IsRemoveMember: false, ShowMember: true, DISABLE_INPUT_FIELDS: false, DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS: false, DISPLAY_BUTTON_REMOVE_MEMBER: true };
    const updated_members_list = [...census_members, updatedMember];
    const member_index = updated_members_list.length - 1;

    // Re-run relationship validations
    const validation_results = [
        validateUniquePrimaryMember(null, updated_members_list),
        validateUniqueSpouse(null, updated_members_list),
        validateUnderagePrimaryHasNoSpouse(null, updated_members_list),
        validateUnderagePrimaryIsOldestMember(null, updated_members_list),
    ];

    const [updated_members, updated_errors, is_form_valid] = handler_validationResults(
        validation_results,
        updated_members_list,
        census_errors
    );
    return [updated_members, updated_errors, is_form_valid];
}

/**
 * Marks a member as removed by setting the IsRemoveMember and ShowMember flags using the member's index.
 * @param {Array} census_members - The census_members array.
 * @param {number} member_index - The index of the member to remove.
 * @returns {Array} - The updated census_members array with the member marked as removed.
 */
export function removeMember(census_members, select_update_type, member_index, census_errors) {
    let member_to_remove = census_members[member_index];

    if (member_to_remove.IsNewMember || member_to_remove.IsInactiveMember) { // Remove from array completely
        census_members.splice(member_index, 1);
    } else { // Hide from UI
        member_to_remove.IsRemoveMember = true;
        member_to_remove.ShowMember = false;
        // Clear member individual errors
    }

    // Clear individual errors
    member_to_remove['individual_errors'] = [];

    // Enable/Disable copy address functionality if there is only one primary member
    census_members = updatePrimaryCopyAddressVisibility(census_members, select_update_type);

    // Re-run relationship validations
    const validation_results = [
        validateUniquePrimaryMember(null, census_members),
        validateUniqueSpouse(null, census_members),
        validateUnderagePrimaryHasNoSpouse(null, census_members),
        validateUnderagePrimaryIsOldestMember(null, census_members),
    ];

    const [updated_members, updated_errors, is_form_valid] = handler_validationResults(
        validation_results,
        census_members,
        census_errors
    );

    return [updated_members, updated_errors, is_form_valid];
}

/**
 * Validates a specific field based on its name and value.
 * @param {Array} census_members - The array of census members.
 * @param {string} field_name - The name of the field to validate.
 * @param {any} value - The value to validate.
 * @param {string} member_index - The ID of the member being validated.
 * @param {Array} census_errors - The array of existing validation errors.
 * @returns {Array} - An array containing updated census_members, census_errors, and is_form_valid flag.
 */
export function validateMemberOnChange(census_members, field_name, value, member_index, census_errors, availableStates) {
    const validation_results = [
        validateRequiredFields(field_name, census_members[member_index], member_index),
        validateSSNFormat(field_name, census_members[member_index], member_index),
        validateMiddleInitialFormat(field_name, census_members[member_index], member_index),
        validatePhoneNumberFormat(field_name, value, member_index),
        validateEmailFormat(field_name, value, member_index),
        validateHeightFeet(field_name, value, member_index),
        validateHeightInches(field_name, value, member_index),
        validateIsNotFutureDate(field_name, value, member_index),
        validateLegalAdultPhoneAndEmail(field_name, census_members[member_index], member_index),
        // validateMaxAge64PrimaryAndSpouse(field_name, census_members[member_index], member_index),
        validateMaxAge26Children(field_name, census_members[member_index], member_index),
        validateSpouseIsLegalAdult(field_name, census_members[member_index], member_index),

        validateUniquePrimaryMember(field_name, census_members),
        validateUniqueSpouse(field_name, census_members),
        validateUnderagePrimaryHasNoSpouse(field_name, census_members),
        validateUnderagePrimaryIsOldestMember(field_name, census_members),
        validateAvailableState(field_name, value, member_index, availableStates),
    ];

    const [updated_members, updated_errors, is_form_valid] = handler_validationResults(
        validation_results,
        census_members,
        census_errors
    );

    return [updated_members, updated_errors, is_form_valid];
}

export function _validateCompleteForm(census_members, census_errors, is_form_valid) {
    const validation_results = [
        validateUniquePrimaryMember(null, census_members),
        validateUniqueSpouse(null, census_members),
        validateUnderagePrimaryHasNoSpouse(null, census_members),
        validateUnderagePrimaryIsOldestMember(null, census_members),
    ];
    [census_members, census_errors, is_form_valid] = handler_validationResults(validation_results, census_members, census_errors);
    for (const [member_index, census_member] of census_members.entries()) {
        for (const field_name of Object.keys(REQUIRED_FIELDS)) {
            let validation_result = [validateRequiredFields(field_name, census_member, member_index)];
            // Destructure updated values
            [census_members, census_errors, is_form_valid] = handler_validationResults(validation_result, census_members, census_errors);            
        }
    }
    return [census_members, census_errors, is_form_valid];
}

function handler_validationResults(list_of_validations_results, census_members, census_errors) {
    list_of_validations_results.forEach(validation_result => {
        if (validation_result === null) {
            return;
        };

        console.log(`${validation_result.name}: ${validation_result.success ? 'Passed' : 'Failed'}`);
        console.log('census_members =>', census_members);

        if (validation_result.success) { // si es true
            if (validation_result.member_index !== null) {
                census_members[validation_result.member_index].individual_errors = census_members[validation_result.member_index].individual_errors.filter(error => error.name !== validation_result.name);
            } else {
                census_errors = census_errors.filter(error => error.name !== validation_result.name);
            }
        } else {
            if (validation_result.member_index !== null) {
                if (!census_members[validation_result.member_index].individual_errors.some(error => error.name === validation_result.name)) {
                    census_members[validation_result.member_index].individual_errors.push(validation_result);
                }
            } else {
                if (!census_errors.some(error => error.name === validation_result.name)) {
                    census_errors.push(validation_result);
                }
            }
        }
    });
    const is_form_valid = census_members.every(member => member.individual_errors.length === 0) && census_errors.length === 0;
    return [census_members, census_errors, is_form_valid];
}

export function updatePrimaryCopyAddressVisibility(census_members, select_update_type){
    const isUniquePrimary = census_members.filter(member => (
        member.ARC_Relationship__c.value === 'Primary' && member.IsRemoveMember == false
    )).length === 1;

    console.log('filter', census_members.filter(member => {
        member.ARC_Relationship__c?.value === 'Primary' && member.IsRemoveMember == false
    }).length)
    census_members.forEach(member => {
        member.DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS = !isUniquePrimary || (!select_update_type.includes('Demographic Updates') && !member.IsNewMember)
    });
    return census_members
}

export function updateEmailAndPhoneVisibility(member) {
    const isAdult = member.ARC_Age__c >= 18;
    const isChild = member.ARC_Relationship__c?.value === 'Child';

    if (!isChild || (isChild && isAdult)) {
        member.ARC_Phone__c.DISPLAY_FIELD = true
        member.vlocity_ins__Email__c.DISPLAY_FIELD = true
    } else {
        member.ARC_Phone__c.DISPLAY_FIELD = false
        member.vlocity_ins__Email__c.DISPLAY_FIELD = false

        member.ARC_Phone__c.value = ""
        member.vlocity_ins__Email__c.value = ""
        
        member.individual_errors = member.individual_errors.filter(
            (error) => !(
                error.name.includes('validateRequiredFieldARC_Phone__c') ||
                error.name.includes('validateRequiredFieldvlocity_ins__Email__c')
            )
        );
    }

    return member;
};

/**
 * Calculates age from a given birthdate.
 * @param {string} birthdate - The birthdate in YYYY-MM-DD format.
 * @returns {number|null} - The calculated age or null if the input is invalid.
 */
export function _calculateAgeFromBirthdate(birthdate) {
    if (!birthdate) return null;
    const birthDate = new Date(birthdate + 'T00:00:00');
    const today = new Date();
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    const dayDiff = today.getDate() - birthDate.getDate();
    if (monthDiff < 0 || (monthDiff === 0 && dayDiff < 0)) age--;
    return age;
}

export function _isNewbornMember(member) {
    const dateOfBirthPlusOneMonth = new Date(member.vlocity_ins__Birthdate__c);
    dateOfBirthPlusOneMonth.setMonth(dateOfBirthPlusOneMonth.getMonth() + 1);
    return dateOfBirthPlusOneMonth > new Date();
}

/**
 * Fetches address suggestions based on user input by making an Apex remote call.
 * @param {Object} ARC_FormCensus - The ARC_FormCensus object.
 * @param {string} input - The partial address input by the user.
 * @returns {Array} - An array of address suggestions.
 */
export async function GET_AddressSuggestionsFromGoogleMapsAPI(ARC_FormCensus, input) {
    const response = await ARC_FormCensus.omniRemoteCall({
        input: { 'input': input },
        sClassName: "ARC_FormCensusController",
        sMethodName: "GET_AddressSuggestionsFromGoogleMapsAPI",
        options: "{}",
    }, true);
    return response.result.suggestions;
}

/**
 * Fetches address details based on a place_id by making an Apex remote call.
 * @param {Object} ARC_FormCensus - The ARC_FormCensus object.
 * @param {string} place_id - The place_id for the address.
 * @returns {Object} - An object containing address details.
 */
export async function GET_AddressDetailsFromGoogleMapsAPI(ARC_FormCensus, place_id) {
    const { result: { ARC_PhysicalAddressState__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressZipCode__c, ARC_PhysicalAddressStreet__c } } = await ARC_FormCensus.omniRemoteCall({
        input: { 'place_id': place_id },
        sClassName: "ARC_FormCensusController",
        sMethodName: "GET_AddressDetailsFromGoogleMapsAPI",
        options: "{}",
    }, true);
    return { ARC_PhysicalAddressState__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressZipCode__c, ARC_PhysicalAddressStreet__c };
}

// /**
//  * Return Available States
//  */
export async function GET_AvailableStates(context) {
    const response = await context.omniRemoteCall({
        input: {},
        sClassName: 'ARC_FormCensusController',
        sMethodName: 'getAvailableStates',
        options: '{}',
    }, true);

    return response.result.availableStates || [];
}