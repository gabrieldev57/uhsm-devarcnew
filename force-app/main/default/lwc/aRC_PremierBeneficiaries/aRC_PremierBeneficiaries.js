import { LightningElement , api} from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
import { validateBeneficiaryOnChange } from './aRC_PremierBeneficiariesValidations';

export default class aRC_PremierBeneficiaries extends OmniscriptBaseMixin(LightningElement) {

    @api census_members; // List of census memebrs received from OS

    adultCensusMembers = []; // List of Census Members that can add Beneficiaries (over 18 years old)
    showOtherRelationshipField = false;
    hasValidationErrors = false;

    relationshipOptions = [
    { label: 'Spouse', value: 'Spouse' },
    { label: 'Child', value: 'Child' },
    { label: 'Parent', value: 'Parent' },
    { label: 'Sibling', value: 'Sibling' },
    { label: 'Grandchild', value: 'Grandchild' },
    { label: 'Grandparent', value: 'Grandparent' },
    { label: 'Aunt/Uncle', value: 'Aunt/Uncle' },
    { label: 'Niece/Nephew', value: 'Niece/Nephew' },
    { label: 'Cousin', value: 'Cousin' },
    { label: 'In-Law', value: 'In-Law' },
    { label: 'Friend', value: 'Friend' },
    { label: 'Estate/Trust', value: 'Estate/Trust' },
    { label: 'Charity/Organization', value: 'Charity/Organization' },
    { label: 'Other', value: 'Other' }
    ];

    connectedCallback() {
        this.filterAdults(); 
    }

    // Method to filter adults from the complete census member list
    filterAdults() {
        // const members = this.census_members;
        const raw = this.census_members;
        const members = (raw?.length > 1 && Array.isArray(raw[1])) ? raw[1] : raw; 
        this.adultCensusMembers = members
            .filter(member => member.ARC_Age__c >= 18 && member.IsRemoveMember === false)
            .map(member => {
                let beneficiariesCount = member.beneficiaries?.length ?? 0;
                let fullName = member.vlocity_ins__FirstName__c + ' ' + member.vlocity_ins__LastName__c;
                return {
                    ...member,
                    fullName: fullName,
                    label: fullName + ' (' + beneficiariesCount + ')',
                    beneficiaries: member.beneficiaries? member.beneficiaries.map(beneficiary => {
                        return {
                            ...beneficiary, 
                            errors: beneficiary.errors || []
                        }
                    }) : [],
                    memberOpenSections: [],
                    beneficiaryOpenSections: [],
                    canAddBeneficiary: true
                }
            })
        console.log('Filtered Adults START:', JSON.stringify(this.adultCensusMembers, null, 2));
    }

    handler_FieldOnChange(event) {
        const memberIndex = event.target.dataset.memberindex;
        const beneficiaryIndex = event.target.dataset.beneficiaryindex;
        const fieldName = event.target.name;
        const value = event.detail?.value ?? event.target.value;

        const updatedMembers = [...this.adultCensusMembers];

        const beneficiary = {
            ...updatedMembers[memberIndex].beneficiaries[beneficiaryIndex],
            [fieldName]: value
        };

        if (fieldName === 'BeneficiaryRelationship') {
            beneficiary.isOtherRelationship = value === 'Other';
            if (value !== 'Other') {
                beneficiary.BeneficiaryOtherRelationship = '';
            }
        }

        this.hasValidationErrors = false;

        // Validate beneficiary fields and attach to beneficiary object
        const validationResult = validateBeneficiaryOnChange(beneficiary, memberIndex, beneficiaryIndex);
        console.log('VALIDATION RESULT: ' + JSON.stringify(validationResult, null, 2));
        beneficiary.errors = validationResult.errors || [];

        updatedMembers[memberIndex].beneficiaries[beneficiaryIndex] = beneficiary;

        this.adultCensusMembers = updatedMembers;
        console.log('UPDATED:', JSON.stringify(this.adultCensusMembers, null, 2));

        this.refreshUI();
    }

    handleAddBeneficiary(event) {
        const updatedMembers = [...this.adultCensusMembers];
        const memberIndex = event.target.dataset.memberindex;
        const beneficiaryCount = updatedMembers[memberIndex].beneficiaries.length;
        if (beneficiaryCount <= 1) {
            const newBeneficiary = {
                Id: `${updatedMembers[memberIndex].Id}-${Date.now()}`,
                BeneficiaryRelationship: '',
                BeneficiaryOtherRelationship: '',
                BeneficiaryName: '',
                BeneficiaryPhone: '',
                BeneficiaryBirthdate: '',
                Label: beneficiaryCount === 0 ? 'Primary Beneficiary' : beneficiaryCount === 1 ? 'Secondary Beneficiary' : 'Beneficiary',
                isOtherRelationship: false,
                errors: []
            };

            updatedMembers[memberIndex].beneficiaries = [...updatedMembers[memberIndex].beneficiaries, newBeneficiary]; // Add new beneficiary to member beneficiary list
            updatedMembers[memberIndex].memberOpenSections = [updatedMembers[memberIndex].Id];
            updatedMembers[memberIndex].beneficiaryOpenSections = [];
            updatedMembers[memberIndex].canAddBeneficiary = updatedMembers[memberIndex].beneficiaries.length <= 1 ? true : false;
            updatedMembers[memberIndex].label = updatedMembers[memberIndex].fullName + ' (' + updatedMembers[memberIndex].beneficiaries.length + ')';

            this.adultCensusMembers = updatedMembers;

            setTimeout(() => {
                const refreshedMembers = [...this.adultCensusMembers];

                refreshedMembers[memberIndex].beneficiaryOpenSections = [
                    newBeneficiary.Id
                ];

                this.adultCensusMembers = refreshedMembers;
            }, 0);
        }
    }


    handler_RemoveMember(event) {
        const memberIndex = event.currentTarget.dataset.memberindex;
        const beneficiaryIndex = event.currentTarget.dataset.beneficiaryindex;

        // Get beneficiaries list
        const updatedMembers = [...this.adultCensusMembers];
        const beneficiaries = [...updatedMembers[memberIndex].beneficiaries];

        // Remove the beneficiary
        beneficiaries.splice(beneficiaryIndex, 1);
        // Recalculate labels (important)
        const updatedBeneficiaries = beneficiaries.map((B, index) => ({
            ...B,
            Label: index === 0 ? 'Primary Beneficiary' : index === 1 ? 'Secondary Beneficiary' : 'Beneficiary'
        }));

        // Assign back
        updatedMembers[memberIndex] = {
            ...updatedMembers[memberIndex],
            beneficiaries: updatedBeneficiaries,
            canAddBeneficiary: beneficiaries.length <= 1 ? true : false,
            label: updatedMembers[memberIndex].fullName + ' (' + updatedBeneficiaries.length + ')'
        };

        this.adultCensusMembers = updatedMembers;
        this.refreshUI();

        console.log('After removal:', JSON.stringify(this.adultCensusMembers, null, 2));
    
    }

    refreshUI() {
        const raw = JSON.parse(JSON.stringify(this.census_members));
        const allCensusMembers =
            raw?.length > 1 && Array.isArray(raw[1])
                ? raw[1]
                : raw;
        const OsUpdatedMembers = allCensusMembers.map(member => {
            // Find matching adult member (if exists)
            const osMember = this.adultCensusMembers.find(
                m => m.Id === member.Id
            );
            if (osMember) {
                return {
                    ...member,
                    beneficiaries: osMember.beneficiaries
                };
            }
            return member; // non-adults unchanged
        });

        const response =
            raw?.length > 1 && Array.isArray(raw[1])
                ? [raw[0], OsUpdatedMembers]
                : OsUpdatedMembers;

        this.omniApplyCallResp({
            census_component: {
                census_members: response
            }
        });
    }

    validateAllBeneficiaries() {
        let isValid = true;
        const updatedMembers = this.adultCensusMembers.map((member) => {
            let memberHasError = false;
            let beneficiarySectionsToOpen = [];
            const updatedBeneficiaries = member.beneficiaries.map((beneficiary) => {
                const result = validateBeneficiaryOnChange(beneficiary);
                if (!result.isValid) {
                    isValid = false;
                    memberHasError = true;
                    beneficiarySectionsToOpen.push(beneficiary.Id);
                }
                return {
                    ...beneficiary,
                    errors: result.errors || []
                };
            });
            return {
                ...member,
                beneficiaries: updatedBeneficiaries,
                memberOpenSections: memberHasError ? [member.Id] : [],
                beneficiaryOpenSections: beneficiarySectionsToOpen
            };
        });
        this.adultCensusMembers = updatedMembers;
        this.hasValidationErrors = !isValid;
        return isValid;
    }

    scrollToFirstError() {
        const errorElement = this.template.querySelector('.error-container');
        if (errorElement) {
            errorElement.scrollIntoView({
                behavior: 'smooth',
                block: 'center'
            });
        }
    }

    //nextStep
    handler_NextStep() {
        const isValid = this.validateAllBeneficiaries();
        if (!isValid) {
            this.scrollToFirstError();
            return;
        }
        this.hasValidationErrors = false;
        this.omniNextStep();
    }

    //previousStep
    handler_PreviousStep() {
        // this.template.querySelector('.discard-warning-modal')?.openModal();
        this.omniPrevStep();
    }

    // Returns the current theme based on the Omniscript layout
    get theme() {
        return this.getAttribute('data-omni-layout') === 'lightning' ? 'slds' : 'nds';
    }
}