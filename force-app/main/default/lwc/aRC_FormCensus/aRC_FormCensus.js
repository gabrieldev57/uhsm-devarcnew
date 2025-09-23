import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
import {
    addNewMember,
    addExistingMember,
    removeMember,
    validateMemberOnChange,
    _validateCompleteForm,
    GET_CensusMembers,
    GET_InactiveCensusMembers,
    GET_InactiveCensusMemberDetails,
    GET_AddressSuggestionsFromGoogleMapsAPI,
    GET_AddressDetailsFromGoogleMapsAPI,
    _calculateAgeFromBirthdate,
    updatePrimaryCopyAddressVisibility,
    updateEmailAndPhoneVisibility,
    GET_AvailableStates
} from './aRC_FormCensusUtilities';

export default class ARC_FormCensus extends OmniscriptBaseMixin(LightningElement) {
    @api osData;

    @api contract_id; // Unique identifier for the contract
    @api census_id; // Unique identifier for the census
    @api is_pcspinoff // Flag to recognize a PC Spin Off
    @api select_update_type; // User-selected update type affecting census behavior
    inactive_census_members_list = []; // List of inactive census members
    select_existing_member_value = null; // Member selected in the select existing member modal
    census_errors = []; // List of validation errors
    is_form_valid = true; // Form validation status
    initial_values; // Stores the initial values of the census members
    maskAttribute = {
        mask: '(000)000-0000'
    }

    @api availableStates = [];
    @api openSections = [];

    @api moreThan3Dependents = false;
    extraMemberPopupDisplayed = false;
    childAmmount = 0;

    // Getter and setter for census_members
    _census_members = []; // Internal array to hold census member data
    @api
    get census_members() {
        return this._census_members;
    }

    set census_members(census_member_list) {
        // Helper function: Removes unnecessary fields from census member
        const cleanCensusMemberFields = (member) => {
            const fieldsToClean = ['vlocity_ins__Gender__c', 'ARC_Relationship__c', 'ARC_Smoker__c', 'ARC_Phone__c', 'vlocity_ins__Email__c', 'ARC_isPregnant__c'];
            for (const field_name of fieldsToClean) {
                if (member[field_name]['DISPLAY_FIELD'] == false) {
                    member[field_name]['value'] = "";
                }
                member[field_name] = member[field_name].value;
            }
            return member;
        };

        // Helper function: Assigns isLast flag
        const flagLastMember = (census_members) => {
            let lastActiveFound = false;
            // Reverse the array to iterate from the end
            census_members.reverse().forEach((member) => {
                if (!member.IsRemoveMember && !lastActiveFound) {
                    member.isLast = true;
                    lastActiveFound = true; // Ensure only one gets flagged
                } else {
                    member.isLast = false;
                }
            });
            // Reverse back to restore the original order
            census_members.reverse();
            return census_members;
        }

        console.log('census_member_list =>', census_member_list);
        console.log('census_errors =>', this.census_errors);

        census_member_list.forEach(member => {
            if (member.IsNewMember == true || member.IsInactiveMember == true) {
                this.openSections.push(member.Id);
            }

            let first = member.vlocity_ins__FirstName__c || '';
            let middle = member.ARC_MiddleInitial__c || '';
            let last = member.vlocity_ins__LastName__c || '';

            if(member.individual_errors.length > 0){
                member.fullName = `${first} ${middle} ${last} - HAS ERRORS`.trim();
                member.accordionStyle = '--slds-c-accordion-heading-text-color: red;';
            } else {
                member.fullName = `${first} ${middle} ${last}`.trim();
                member.accordionStyle = '--slds-c-accordion-heading-text-color: black;';
            }
        });
        
        // Step 1: Assign the value to the getter, private property _census_members
        this._census_members = flagLastMember(census_member_list);
        // Step 2: Perform a deep copy of the original list with all of its objects to avoid modifying the original census members
        let census_members_copy = JSON.parse(JSON.stringify(census_member_list));
        census_members_copy = census_members_copy.map(cleanCensusMemberFields);
        // Step 3: Process each census member and clean some fields for output and then update in the omniscript only
        this.omniApplyCallResp({ 'census_component': { 'census_members': census_members_copy, 'is_form_valid': this.is_form_valid, 'initial-values': this.initial_values } });

        // Step 4: Save original list to state
        let previous_state = this.omniGetSaveState('LWC_Census') || {}; // Preserve previous values
        this.omniSaveState({ ...previous_state, census_members: this._census_members, is_form_valid: this.is_form_valid, census_errors: this.census_errors }, 'LWC_Census', true);
    }

    // Determines if the "Add Member" button should be displayed
    get DISPLAY_BUTTONS_ADD_MEMBER() {
        return this.select_update_type.includes('Add or Remove a Member');
    }

    // Determines if the "Add Existing Member" button should be displayed
    get DISPLAY_BUTTONS_ADD_EXISTING_MEMBER() {
        // Define variable to be checked if is PC Spin Off or not
        let IsPCSpinOff = false;
        if(this.omniJsonData.hasOwnProperty('IsPCSpinOff')) {
            // Get IsPCSpinOff node value from JSON
            IsPCSpinOff = this.omniJsonData?.IsPCSpinOff;
        }
        console.log('Is PC Spin Off?', IsPCSpinOff);
        if(IsPCSpinOff != true) {
            // Show Add existing member always is not PC Spin Off
            return this.select_update_type.includes('Add or Remove a Member');
        }
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
            this.census_members = savedState.census_members;
            this.initial_values = savedState.intial_values;
            this.omniApplyCallResp({ 'census_component': { 'initial_values': this.initial_values } });
        } else {
            this.census_members = await GET_CensusMembers(this);
            this.initial_values = this.census_members;
            this.omniApplyCallResp({ 'census_component': { 'initial_values': this.initial_values } });
        }

        console.log('this.select_update_type.includes =>', this.select_update_type.includes('Add or Remove a Member'));

        const isUniquePrimary = this.census_members.filter(member => (member.ARC_Relationship__c?.value === 'Primary' && member.IsRemoveMember == false)).length === 1;
        // Disable input fields and remove member button based on update type
        this.census_members.forEach((member, memberindex) => {
            member = updateEmailAndPhoneVisibility(member);
            member.DISABLE_INPUT_FIELDS = !this.select_update_type.includes('Demographic Updates') && member.IsNewMember == false;
            member.DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS = !isUniquePrimary || (!this.select_update_type.includes('Demographic Updates') && !member.IsNewMember);
            member.DISPLAY_BUTTON_REMOVE_MEMBER = this.select_update_type.includes('Add or Remove a Member');
        });

        this.loadAvailableStates();
    }

    // Unified handler for field changes
    handler_FieldOnChange(event) {
        const { name: field_name, dataset: { memberindex }, checked, value } = event.currentTarget;
        const fieldValue = checked || value;

        console.log('field_name:', field_name);
        console.log('fieldValue:', fieldValue);

        const addressFields = ['ARC_Address__c', 'ARC_PhysicalAddressState__c', 'ARC_PhysicalAddressStreet__c', 'ARC_PhysicalAddressCity__c', 'ARC_PhysicalAddressZipCode__c'];

        // Auto Populate Dependents Address Fields with Primary Address Information
        if (this.census_members[memberindex].ARC_Relationship__c.value === 'Primary' && addressFields.includes(field_name)) {  
            this.census_members.forEach((member, index) => {
                if (member.CopyAddressFromPrimary && member.IsDependent) {
                    this.fieldUpdatesHandler(index, field_name, fieldValue);

                }
            });
        } 

        // Logic that handles each field update differently
        this.fieldUpdatesHandler(memberindex, field_name, fieldValue);
       

        const [census_members, census_errors, is_form_valid] = validateMemberOnChange(this.census_members, field_name, fieldValue, memberindex, this.census_errors, this.availableStates);
        this.refreshCensusUI(census_members, census_errors, is_form_valid);
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
        this.childAmmount=0;
        this.census_members = addNewMember(this.census_members);
        this.census_members.forEach(member => {
            member.DISPLAY_BUTTON_REMOVE_MEMBER = this.census_members.filter(m => !m.IsRemoveMember).length > 1;
            if(member.ARC_Relationship__c.value == 'Child' && member.IsRemoveMember == false){
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

    // Opens the modal to add an inactive member
    async handle_AddExistingMemberButton() {
        this.select_existing_member_value = null;
        this.inactive_census_members_list = await GET_InactiveCensusMembers(this, this.census_members);
        this.template.querySelector('.add-inactive-member-modal')?.openModal();
    }

    handler_SelectExistingMember(event) {
        this.select_existing_member_value = event.currentTarget.value;
    }

    //New logic for adding an existing member
    async handler_ConfirmAddExistingMemberModal(){
        if(!this.select_existing_member_value){
            return;
        }
        const census_member_details = await GET_InactiveCensusMemberDetails(this, this.select_existing_member_value);
        let [census_members, census_errors, is_form_valid] = addExistingMember(this.census_members, census_member_details, this.census_errors);
        this.refreshCensusUI(census_members, census_errors, is_form_valid);
        this.template.querySelector('.add-inactive-member-modal')?.closeModal();
    }

    // Cancels adding an existing member
    handler_CancelAddExistingMemberModal() {
        this.template.querySelector('.add-inactive-member-modal')?.closeModal();
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
                error.name.includes('ARC_PhysicalAddressZipCode__c') ||
                error.name.includes('validateAvailableState')
            )
        );

        this.fieldUpdatesHandler(memberindex, 'CopyAddressFromPrimary', checked);
        this.fieldUpdatesHandler(memberindex, 'ShowAddressForDependent', !checked);
        this.refreshCensusUI(this.census_members);
    }

    // Handles removing a member from the census
    handler_YESRemoveMemberModal(event) {
        let [census_members, census_errors, is_form_valid] = removeMember(this.census_members, this.select_update_type, event.currentTarget.dataset.memberindex, this.census_errors)
        this.refreshCensusUI(census_members, census_errors, is_form_valid);
        console.log('this.census_members Remove Member=>', this.census_members);
        console.log('this.census_members.length => remove member', this.census_members.length);
        console.log('census_errors =>', census_errors);
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

            const [census_members, census_errors, is_form_valid] = validateMemberOnChange(this.census_members, 'ARC_Relationship__c', relationshipField.value, memberindex, this.census_errors, this.availableStates);

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
            

        console.log('entro 1');
        switch (fieldName) {
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
                this.census_members = updatePrimaryCopyAddressVisibility(this.census_members, this.select_update_type);

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

    async loadAvailableStates() {
        try {
            const states = await GET_AvailableStates(this);
            this.availableStates = states;
        } catch (error) {
            console.error('Error loading available states:', error);
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
}