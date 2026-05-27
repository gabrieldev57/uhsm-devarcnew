/**
 * Validates a specific field based on its name and value.
 * @param {Object} beneficiary - The object of the beneficiary.
 * @returns {Object} - An object containing the list of errors for that beneficiary and isValid flag.
 */
export function validateBeneficiaryOnChange(beneficiary) {
    let errors = [];

    // Required Name field
    if (!beneficiary.BeneficiaryName || beneficiary.BeneficiaryName.trim() === '') {
        errors.push({
            field: 'BeneficiaryName',
            error_message: 'Beneficiary Name is required'
        });
    }

    // Check email format
    if (!beneficiary.BeneficiaryBirthdate) {
        errors.push({ 
            field: 'BeneficiaryBirthdate', 
            error_message: 'Beneficiary Birthdate is required' 
        }); 
    }

    // Required Relationship field
    if (!beneficiary.BeneficiaryRelationship) {
        errors.push({
            field: 'BeneficiaryRelationship',
            error_message: 'Relationship is required'
        });
    }

    // Other Relationship field is required when Relationship equals to 'Other' 
    if (beneficiary.BeneficiaryRelationship === 'Other' && (!beneficiary.BeneficiaryOtherRelationship || beneficiary.BeneficiaryOtherRelationship.trim() === '')) {
        errors.push({
            field: 'BeneficiaryOtherRelationship',
            error_message: 'Please specify the relationship'
        });
    }

    if (!beneficiary.BeneficiaryPhone || beneficiary.BeneficiaryPhone.trim() === '') {
        errors.push({
            field: 'BeneficiaryContact',
            error_message: 'Phone number is required'
        })
    } else if (beneficiary.BeneficiaryPhone.length >= 40) {
        errors.push({
            field: 'BeneficiaryContact',
            error_message: 'Phone number cannot exceed 40 digits.'
        })
    }
 
    return {
        isValid: Object.keys(errors).length === 0,
        errors
    };
}