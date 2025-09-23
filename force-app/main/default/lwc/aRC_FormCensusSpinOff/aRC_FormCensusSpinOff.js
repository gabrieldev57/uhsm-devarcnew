import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
import {
    addNewMember,
    removeMember,
    validateMemberOnChange,
    _validateCompleteForm,
    GET_CensusMembers,
    GET_AddressSuggestionsFromGoogleMapsAPI,
    GET_AddressDetailsFromGoogleMapsAPI,
    _calculateAgeFromBirthdate,
    updatePrimaryCopyAddressVisibility,
    updateEmailAndPhoneVisibility,
    GET_AvailableStates
} from './aRC_FormCensusSpinOffUtilities';

export default class ARC_FormCensus extends OmniscriptBaseMixin(LightningElement) {
    @api memberAssignment; // List of members and their family assignment
    census_errors = []; // List of validation errors
    is_form_valid = true; // Form validation status
    initial_values; // Stores the initial values of the census members
    all_census_members; // List of all census members separated by census displayed on the JSON
    maskAttribute = {
        mask: '(000)000-0000'
    }

    @api moreThan3Dependents = false;
    extraMemberPopupDisplayed = false;
    childAmmount = 0;
    @api availableStates = []; // List of available states for address selection

    // Getter and setter for census_members
    _census_members = []; // Internal array to hold census member data
    @api
    get census_members() {
        return this._census_members;
    }

    set census_members(census_member_list) {
        console.log('census_member_list =>', census_member_list);
        console.log('census_errors =>', this.census_errors);

        census_member_list.forEach(member => {
            let first = member.vlocity_ins__FirstName__c || '';
            let middle = member.ARC_MiddleInitial__c || '';
            let last = member.vlocity_ins__LastName__c || '';

            if (member.individual_errors.length > 0) {
                member.fullName = `${first} ${middle} ${last} - HAS ERRORS`.trim();
                member.accordionStyle = '--slds-c-accordion-heading-text-color: red;';
            } else {
                member.fullName = `${first} ${middle} ${last}`.trim();
                member.accordionStyle = '--slds-c-accordion-heading-text-color: black;';
            }
        });
        
        // Step 1: Assign the value to the getter, private property _census_members
        this._census_members = census_member_list;

        // Step 2: Perform a deep copy of the original list with all of its objects to avoid modifying the original census members
        let updatedFamily = JSON.parse(JSON.stringify(this._census_members)).map(member => this.cleanCensusMemberFields(member));
        this.all_census_members[1] = updatedFamily;

        // Step 3: Process each census member and clean some fields for output and then update in the omniscript only
        this.omniApplyCallResp({ 'census_component': { 'census_members': this.all_census_members, 'is_form_valid': this.is_form_valid } });

        // Step 4: Save original list to state
        let previous_state = this.omniGetSaveState('LWC_Census') || {}; // Preserve previous values
        this.omniSaveState({ ...previous_state, all_census_members: this.all_census_members, census_members: this.census_members, initial_values: this.initial_values, is_form_valid: this.is_form_valid, census_errors: this.census_errors }, 'LWC_Census', true);
    }

    // Returns the current theme based on the Omniscript layout
    get theme() {
        return this.getAttribute('data-omni-layout') === 'lightning' ? 'slds' : 'nds';
    }

    // Lifecycle hook: Fetches census members when the component initializes
    async connectedCallback() {

        let savedState = this.omniGetSaveState('LWC_Census');

        if (savedState && Object.keys(savedState).length > 0) {
            this.is_form_valid = savedState.is_form_valid;
            this.census_errors = savedState.census_errors;
            this.all_census_members = savedState.all_census_members;
            this.initial_values = savedState.intial_values;
            this.census_members = savedState.census_members;
            this.omniApplyCallResp({ 'census_component': { 'initial_values': this.initial_values } });
        } else {
            this.all_census_members = await GET_CensusMembers(this);
            this.census_members = this.all_census_members[1];
            this.all_census_members = this.all_census_members.map(memberGroup =>
                memberGroup.map(member =>
                    this.cleanCensusMemberFields(member)
                )
            );
            this.initial_values = [...this.all_census_members];
            this.omniApplyCallResp({ 'census_component': { 'initial_values': this.initial_values, 'census_members': this.all_census_members } });
            let previous_state = this.omniGetSaveState('LWC_Census') || {}; // Preserve previous values
            this.omniSaveState({ ...previous_state, all_census_members: this.all_census_members, census_members: this.census_members, initial_values: this.initial_values, is_form_valid: this.is_form_valid, census_errors: this.census_errors }, 'LWC_Census', true);
        }

        const isUniquePrimary = this.census_members.filter(member => (member.ARC_Relationship__c?.value === 'Primary' && member.IsRemoveMember == false)).length === 1;
        // Disable input fields and remove member button based on update type
        this.census_members.forEach((member) => {
            member = updateEmailAndPhoneVisibility(member);
            member.DISABLE_INPUT_FIELDS = false;
            member.DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS = false;
            member.DISPLAY_BUTTON_REMOVE_MEMBER = true;
        });
        this.loadAvailableStates();
    }

    // Unified handler for field changes
    handler_FieldOnChange(event) {
        const { name: field_name, dataset: { memberindex }, checked, value } = event.currentTarget;
        const fieldValue = checked || value;

        console.log('field_name:', field_name);
        console.log('fieldValue:', fieldValue);


        // Logic that handles each field update differently
        this.fieldUpdatesHandler(memberindex, field_name, fieldValue);


        if(field_name != 'ARC_PhysicalAddressState__c'){
            const [census_members, census_errors, is_form_valid] = validateMemberOnChange(this.census_members, field_name, fieldValue, memberindex, this.census_errors);
            this.refreshCensusUI(census_members, census_errors, is_form_valid);
        }
    }

    // Handles address suggestion selection
    async handler_AddressSuggestionSelect(event) {
        const { dataset: { memberindex }, value } = event.currentTarget;
        const place_id = this.census_members[memberindex].addresses_map[value];
        const addressDetails = await GET_AddressDetailsFromGoogleMapsAPI(this, place_id, memberindex);

        Object.entries(addressDetails).forEach(([key, val]) => {
            let member = this.census_members[memberindex];
            this.fieldUpdatesHandler(memberindex, key, val)

            if (value != null && value != '') {
                member.individual_errors = member.individual_errors.filter(
                    (error) => !error.name.includes(key)
                )
            }

        });

        if (this.census_members[memberindex].ARC_Relationship__c.value === 'Primary') {
            this.census_members.forEach((member, index) => {
                if (member.CopyAddressFromPrimary && member.IsDependent) {
                    Object.entries(addressDetails).forEach(([key, val]) => this.fieldUpdatesHandler(index, key, val));
                }
            });
        }
        this.refreshCensusUI();
    }

    // Handles address search input with debounce
    async handler_SearchBarOnKeyUp(event) {
        const { name: field_name, value, dataset: { memberindex } } = event.currentTarget;
        this.fieldUpdatesHandler(memberindex, field_name, value);

        if (value.length > 2) {
            const response = await GET_AddressSuggestionsFromGoogleMapsAPI(this, value);
            this.fieldUpdatesHandler(memberindex, 'addresses_map', response);
            this.fieldUpdatesHandler(memberindex, 'address_suggestions', Object.keys(response));
        }
        this.refreshCensusUI();
    }

    // Adds a new member to the census
    handler_AddMemberButton() {
        this.childAmmount = 0;
        this.census_members = addNewMember(this.census_members);
        this.census_members.forEach(member => {
            member.DISPLAY_BUTTON_REMOVE_MEMBER = this.census_members.filter(m => !m.IsRemoveMember).length > 1;
            if (member.ARC_Relationship__c.value == 'Child' && member.IsRemoveMember == false) {
                this.childAmmount++;
            }
        });
        console.log('this.childAmmount =>', this.childAmmount);
        if(this.childAmmount == 3){                   
            if (!this.extraMemberPopupDisplayed) {
                this.extraMemberPopupDisplayed = true;
                this.moreThan3Dependents = true;
              }
        } else {
            this.moreThan3Dependents = false;
        }
        this.refreshCensusUI();
    }

    // Handles "Copy Address from Primary" checkbox changes
    handler_CheckboxCopyAddressFromPrimaryOnChange(event) {
        const { checked, dataset: { memberindex } } = event.currentTarget;
        const primary_member = this.census_members.find(member => member.ARC_Relationship__c.value === 'Primary');

        if (primary_member && checked) {
            const { ARC_Address__c, ARC_PhysicalAddressState__c, ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressZipCode__c } = primary_member;
            Object.entries({ ARC_Address__c, ARC_PhysicalAddressState__c, ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressZipCode__c }).forEach(([key, val]) => {
                this.fieldUpdatesHandler(memberindex, key, val)
            });
        } else if (!checked) {
            const address_fields = ['ARC_Address__c', 'ARC_PhysicalAddressCity__c', 'ARC_PhysicalAddressState__c', 'ARC_PhysicalAddressStreet__c', 'ARC_PhysicalAddressZipCode__c'];
            for (const field_name of address_fields) {
                this.fieldUpdatesHandler(memberindex, field_name, '');
            }
        }

        this.census_members[memberindex].individual_errors = this.census_members[memberindex].individual_errors.filter(
            (error) => !(
                error.name.includes('ARC_PhysicalAddressCity__c') ||
                error.name.includes('ARC_PhysicalAddressState__c') ||
                error.name.includes('ARC_PhysicalAddressStreet__c') ||
                error.name.includes('ARC_PhysicalAddressZipCode__c')
            )
        );

        this.fieldUpdatesHandler(memberindex, 'CopyAddressFromPrimary', checked);
        this.fieldUpdatesHandler(memberindex, 'ShowAddressForDependent', !checked);
        this.refreshCensusUI(this.census_members);
    }

    // Handles removing a member from the census
    handler_YESRemoveMemberModal(event) {
        let [census_members, census_errors, is_form_valid] = removeMember(this.census_members, event.currentTarget.dataset.memberindex, this.census_errors);
        this.refreshCensusUI(census_members, census_errors, is_form_valid);
    }

    // Cancels the removal of a member
    handler_NORemoveMemberModal(event) {
        const { memberindex } = event.currentTarget.dataset;
        this.fieldUpdatesHandler(memberindex, 'DISPLAY_MODAL_REMOVE_MEMBER', false);
        this.fieldUpdatesHandler(memberindex, 'DISPLAY_BUTTON_REMOVE_MEMBER', true);
        this.refreshCensusUI();
    }

    // Toggles SSN visibility
    handler_toggleSSNVisibility(event) {
        const { memberindex } = event.currentTarget.dataset;
        this.fieldUpdatesHandler(memberindex, 'showSSN', this.census_members[memberindex]['showSSN'] === 'password' ? 'text' : 'password');
        this.refreshCensusUI();
    }

    // Helper function: Removes unnecessary fields from census member
    cleanCensusMemberFields(member) {
        const fieldsToClean = [
            'vlocity_ins__Gender__c',
            'ARC_Relationship__c',
            'ARC_Smoker__c',
            'ARC_Phone__c',
            'vlocity_ins__Email__c',
            'ARC_isPregnant__c'
        ];

        for (const field_name of fieldsToClean) {
            if (member[field_name]['DISPLAY_FIELD'] === false) {
                member[field_name]['value'] = "";
            }
            if (typeof member[field_name] === 'object') {
                member[field_name] = member[field_name].value;
            }
        }

        return member;
    }

    // Updates census data and triggers re-render
    refreshCensusUI(census_members = null, census_errors = null, isFormValid = null) {
        if (isFormValid !== null) this.is_form_valid = isFormValid;
        if (census_members !== null) {
            this.census_members = [...census_members];
        } else {
            this.census_members = this.census_members;
        }
        this.census_members = census_members !== null ? [...census_members] : [...this.census_members];

        if (census_errors !== null) this.census_errors = census_errors;
    }

    fieldUpdatesHandler(memberindex, fieldName, value) {
        let member = this.census_members[memberindex];

        // Common value update for simple fields
        const setMemberFieldValue = () => {
            if (member[fieldName]?.value !== undefined) {
                member[fieldName].value = value;
            } else {
                member[fieldName] = value;
            }
        };

        // Updates relationship options based on age removes Spouse from the picklist if the member is -18
        const updateRelationshipOptionsVisibility = (member) => {
            const relationshipField = member['ARC_Relationship__c'];
            let relationshipOptions = [...relationshipField.options];
            const isAdult = member['ARC_Age__c'] >= 18;
            const spouseOptionIndex = relationshipOptions.findIndex(option => option.value === 'Spouse');

            if (isAdult && spouseOptionIndex === -1) {
                relationshipOptions.splice(1, 0, { label: 'Spouse', value: 'Spouse' });
            } else if (!isAdult && spouseOptionIndex !== -1) {
                relationshipOptions.splice(spouseOptionIndex, 1);
                if (relationshipField.value === 'Spouse') {
                    relationshipField.value = 'Child';
                }
            }

            relationshipField.options = [...relationshipOptions];

            const [census_members, census_errors, is_form_valid] = validateMemberOnChange(this.census_members, 'ARC_Relationship__c', relationshipField.value, memberindex, this.census_errors);

            this.refreshCensusUI(census_members, census_errors, is_form_valid);
        }

        const updatePregnancyCheckboxVisibility = (member) => {
            if (member['vlocity_ins__Gender__c']['value'] == 'Male') {
                member['ARC_isPregnant__c']['DISPLAY_FIELD'] = false
            } else if (member['vlocity_ins__Gender__c']['value'] == 'Female') {
                member['ARC_isPregnant__c']['DISPLAY_FIELD'] = member['ARC_Age__c'] >= 18;
            }
        }
        const validateState = () => {
            const [census_members, census_errors, is_form_valid] = validateMemberOnChange(this.census_members, 'ARC_PhysicalAddressState__c', value, memberindex, this.census_errors, this.availableStates);
            this.refreshCensusUI(census_members, census_errors, is_form_valid);
        }
        
        switch (fieldName) {
            // case 'vlocity_ins__SocialSecurityNumber__c':
            // case 'ARC_Relationship__c':
            case 'ARC_Smoker__c':
            case 'ARC_Phone__c':
            case 'vlocity_ins__Email__c':
            case 'ARC_isPregnant__c':
                setMemberFieldValue();
                break;
            case 'vlocity_ins__Birthdate__c':
                setMemberFieldValue();
                let age = _calculateAgeFromBirthdate(member.vlocity_ins__Birthdate__c);
                member.ARC_Age__c = age;
                updateRelationshipOptionsVisibility(member);
                updatePregnancyCheckboxVisibility(member);
                member = updateEmailAndPhoneVisibility(member);
                member.ARC_Smoker__c.DISPLAY_FIELD = age >= 18;
                break;
            case 'ARC_Relationship__c':
                setMemberFieldValue();
                member.vlocity_ins__IsPrimaryMember__c = value === 'Primary';
                member.IsDependent = !member.vlocity_ins__IsPrimaryMember__c;
                this.census_members = updatePrimaryCopyAddressVisibility(this.census_members);

                if (member.vlocity_ins__Birthdate__c) {
                    member = updateEmailAndPhoneVisibility(member);
                }
                break;
            case 'vlocity_ins__Gender__c':
                setMemberFieldValue();
                updatePregnancyCheckboxVisibility(member);
                break;
            case 'ARC_HeightFeet__c':
                if (!/^\d+$/.test(value)) {
                    value = null;
                } else {
                    value = value.replace(/^0+/, '') || '0';
                }
                member[fieldName] = value;
                break;
            case 'ARC_HeightInches__c':
                if (!/^\d+$/.test(value)) {
                    value = null;
                } else {
                    value = value.replace(/^0+/, '') || '0';
                }
                member[fieldName] = value;
                break;
            case 'ARC_Weight__c':
                if (!/^\d+$/.test(value)) {
                    value = null;
                } else {
                    value = value.replace(/^0+/, '') || '0';
                }
                member[fieldName] = value;
                break;
            case 'ARC_PhysicalAddressState__c':
                validateState();
            default:
                member[fieldName] = value;
                break;
        }
    }

    // Opens the "Remove Member" modal
    handler_RemoveMember(event) {
        const { memberindex } = event.currentTarget.dataset;
        this.fieldUpdatesHandler(memberindex, 'DISPLAY_MODAL_REMOVE_MEMBER', true);
        this.fieldUpdatesHandler(memberindex, 'DISPLAY_BUTTON_REMOVE_MEMBER', false);

        if (this.census_members.filter(member => !member.IsRemoveMember).length < 2) {
            this.census_members.forEach(member => member.DISPLAY_BUTTON_REMOVE_MEMBER = false);
        }
        this.refreshCensusUI();
    }

    handler_CancelDiscardChanges() {
        this.template.querySelector('.discard-warning-modal')?.closeModal();
    }

    handler_ConfirmDiscardChanges() {
        this.template.querySelector('.discard-warning-modal')?.closeModal();
        this.omniPrevStep();
    }

    //nextStep
    handler_NextStep() {
        let [census_members, census_errors, is_form_valid] = _validateCompleteForm(this.census_members, this.census_errors, this.is_form_valid);
        this.refreshCensusUI(census_members, census_errors, is_form_valid);

        if (is_form_valid) {
            this.omniNextStep();
        }
    }

    //previousStep
    handler_PreviousStep() {
        this.template.querySelector('.discard-warning-modal')?.openModal();
    }

    handleCloseExtraDepModal() {
        this.moreThan3Dependents = false;
        this.extraMemberPopupDisplayed = false;
    }

    async loadAvailableStates() {
        try {
            const states = await GET_AvailableStates(this);
            this.availableStates = states; 
            console.log('Available states loaded:', this.availableStates);
        } catch (error) {
            console.error('Error loading available states:', error);
        }
    }
}