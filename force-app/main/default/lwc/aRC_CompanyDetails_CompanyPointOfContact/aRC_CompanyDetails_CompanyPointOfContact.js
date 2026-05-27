import { LightningElement, api, wire, track } from 'lwc';
//import getPrimaryContact from '@salesforce/apex/ARC_CompanyDetailsController.getPrimaryContact';
import { refreshApex } from '@salesforce/apex';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import PORTAL_ACCESS_FIELD from '@salesforce/schema/Contact.ARC_PortalAccess__c';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
//import savePBC from '@salesforce/apex/ARC_CompanyDetailsController.savePBC';


export default class ARC_CompanyDetails_CompanyPointOfContact extends LightningElement {

    //========================================================== Full Contact List Variables =====================================================
    _initializedFullContactList = false;
    @track _fullContactList = []; // <-------------------- IT COMES FROM MAIN LWC --------------------
    @api 
    set fullContactList(value){  
        this._fullContactList = Array.isArray(value) ? value : [];
        if (this._fullContactList.length === 0){
            return;
        }
        this.initializeFullContactList();
    }
    get fullContactList(){
        return this._fullContactList;
    }

    @api recordId;
    //@track isEdit = false;
    _isEdit = false;
    _justSaved = false;
    @track selectedPrimaryContactAction = 'KEEP';
    @api mode;
    primaryBusinessContact;
    wiredContactResult;
    hasPrimaryRoleSelected = false;
    selectedPortalAccess;
    contactObjectInfo;
    contactRecordTypeId;
    portalAccessPicklist;
    contactList = [];
    primaryContactOptions = [
        { label: 'Edit Contact', value: 'KEEP' },
        { label: 'Select Contact', value: 'SELECT' },
        { label: 'New Contact', value: 'CREATE' }
    ];
    //Control Primary Contact Action
    editOrCreateContact = true;
    selectExistingContact = false;

    //Data (original - do not mutate)
    originalContactList = [];
    originalPrimaryBusinessContact;

    //Data (draft - editable)
    @track draftContact = {
        action: 'KEEP',
        accountId: null,
        contact: {
            Id: null,
            FirstName: '',
            LastName: '',
            Email: '',
            Phone: '',
            Title: '',
            //ARC_PortalAccess__c: ''
            PortalAccess: ''
        },
        roles: 'Primary Business Contact'
    };
    keepDraftContact = null;
    createDraftContact = null;
    selectDraftContact = null;

    //Selection (Select scenario)
    @track selectedExistingContactId;

    //Wire reference (refresh later)
    wiredContactResult;

    @api
    getDraftForSave() {
        return JSON.parse(JSON.stringify(this.draftContact));
    }

    @api
    set isEdit(value) {
        const wasEdit = this._isEdit;
        this._isEdit = value ?? false;

        // Cancel → rollback
        if (wasEdit && !this._isEdit && !this._justSaved) {
            this.resetToOriginal();
        }

        this._justSaved = false;
    }

    get isEdit() {
        return this._isEdit;
    }

    @wire(getObjectInfo, { objectApiName: CONTACT_OBJECT })
    results({ error, data }) {
        if (data) {
            this.contactRecordTypeId = data.defaultRecordTypeId;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contactRecordTypeId = undefined;
        }
    }


    @wire(getPicklistValues, { recordTypeId: "$contactRecordTypeId", fieldApiName: PORTAL_ACCESS_FIELD })
    picklistResults({ error, data }) {
        if (data) {
            this.portalAccessPicklist = data.values;
        } else if (error) {
            this.error = error;
            this.portalAccessPicklist = undefined;
        }
    }

    handlePortalAccessChange(event){
        this.selectedPortalAccess = event.detail.value;
        this.draftContact = {
            ...this.draftContact,
            contact: {
                ...this.draftContact.contact,
                PortalAccess: this.selectedPortalAccess
            }
        };


        if (this.selectedPrimaryContactAction === 'KEEP') {
            this.keepDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        }
    
        if (this.selectedPrimaryContactAction === 'CREATE') {
            this.createDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        }
    
        if (this.selectedPrimaryContactAction === 'SELECT') {
            this.selectDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        }
    }

    initializeFullContactList(){
        if (this._initializedFullContactList) return;
        this._initializedFullContactList = true;
        if (!this._fullContactList){
            return;
        }
        const pbc = this._fullContactList;
        this.primaryBusinessContact = pbc.find(
            acr => acr.Roles === 'Primary Business Contact'
        );

        if (this.primaryBusinessContact?.Contact?.ARC_PortalAccess__c){
            this.selectedPortalAccess = this.primaryBusinessContact.Contact.ARC_PortalAccess__c;
        } else {
            this.selectedPortalAccess = undefined;
        }

        this.contactList = pbc;
        this.originalContactList = JSON.parse(JSON.stringify(this.contactList));
        this.originalPrimaryBusinessContact = 
            this.originalContactList.find(
                acr => acr.Roles?.includes('Primary Business Contact')
            );
        
        if (!this.originalPrimaryBusinessContact){
            this.originalPrimaryBusinessContact = false;
        }

        this.resetToOriginal();
    }


    @api
    resetToOriginal(){
        this.initializeDraftFromOriginal();
        this.selectExistingContact = null;
        this.selectedPrimaryContactAction = 'KEEP'; //Existing Contact is selected
        this.selectedExistingContactId = null;
        this.isEdit = false;
        //Rollback Portal Access
        this.editOrCreateContact = true;
        this.keepDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        this.createDraftContact = null;//clean temp create
        this.selectDraftContact = null;

        //Wait until DOM reflects the new state (edit/view)
        Promise.resolve().then(() => {
            const fields = this.template.querySelectorAll(
                'lightning-input, lightning-textarea, lightning-combobox'
            );

            fields.forEach(f => {
                // Clean manual errors
                if (typeof f.setCustomValidity === 'function') {
                  f.setCustomValidity('');
                }
                // Evaluate required/pattern/ to delete the empty error messahe
                if (typeof f.reportValidity === 'function') {
                  f.reportValidity();
                }
            });
        });
    }

    initializeDraftFromOriginal(){
        if (!this.originalPrimaryBusinessContact) {
            return;
        }

        const acr = this.originalPrimaryBusinessContact;
        const sourceContact = acr.Contact ?? acr.contact;
        this.draftContact = {
            action: 'KEEP',
            accountId: acr.AccountId ?? acr.accountId,
            contact: {
                Id: acr.ContactId ?? sourceContact.Id,
                FirstName: sourceContact.FirstName,
                LastName: sourceContact.LastName,
                Email: sourceContact.Email,
                Phone: (sourceContact.Phone || '').replace(/\D/g, ''),
                Title: sourceContact.Title,
                PortalAccess: sourceContact.ARC_PortalAccess__c ?? sourceContact.PortalAccess ?? ''
            },
            roles: 'Primary Business Contact'
        };

        this.keepDraftContact = JSON.parse(JSON.stringify(this.draftContact));
    }

    get isReadOnly() {
        return !this.isEdit;
    }

    get isRequired() {
        return this.isEdit;
    }

    handleInputChange(event) {
        const field = event.target.name;
        let value = event.target.value;

        if (field === 'Phone') {
            value = (value || '').replace(/\D/g, '').slice(0, 10);
        }        
        
        if (!this.draftContact || !this.draftContact.contact) {
            return;
        }

        this.draftContact = {
            ...this.draftContact,
            contact: {
                ...this.draftContact.contact,
                [field]: value
            }
        };

        if(this.selectedPrimaryContactAction == 'KEEP'){
            this.keepDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        }

        if(this.selectedPrimaryContactAction == 'CREATE'){
            this.createDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        }

        if (this.selectedPrimaryContactAction === 'SELECT') {
            this.selectDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        }
    }

    handlePrimaryContactActionChange(event){
        this.saveKeepDraftIfNeeded();
        this.saveCreateDraftIfNeeded();
        this.saveSelectDraftIfNeeded();

        this.selectedPrimaryContactAction = event.detail.value;

        if (this.selectedPrimaryContactAction === 'KEEP') {
            this.loadKeepDraft();
        }

        if (this.selectedPrimaryContactAction === 'SELECT') {
            this.loadSelectDraft();
        }

        if (this.selectedPrimaryContactAction === 'CREATE') {
            this.loadCreateDraft();
            this.showPendingSaveIcon = true;  
        }

        requestAnimationFrame(() => {
            if (this.selectedPrimaryContactAction !== 'CREATE'){
                this.clearValidationState();
            }
        });
    }

    saveKeepDraftIfNeeded() {
        if (this.selectedPrimaryContactAction === 'KEEP' && this.draftContact) {
            this.keepDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        }
    }

    loadKeepDraft() {
        if (this.keepDraftContact) {
            this.draftContact = JSON.parse(JSON.stringify(this.keepDraftContact));
        } else {
            this.initializeDraftFromOriginal();
        }
    
        this.editOrCreateContact = true;
        this.selectExistingContact = false;
    }

    initializeCreateDraft() {
        this.draftContact = {
            action: 'CREATE',
            accountId: this.originalPrimaryBusinessContact.AccountId,
            contact: {
                Id: null,
                FirstName: '',
                LastName: '',
                Email: '',
                Phone: '',
                Title: '',
                PortalAccess: ''
            },
            roles: 'Primary Business Contact'
        };
    
        this.createDraftContact = JSON.parse(JSON.stringify(this.draftContact));
    }

    saveCreateDraftIfNeeded() {
        if (this.selectedPrimaryContactAction === 'CREATE' && this.draftContact) {
            this.createDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        }
    }

    loadCreateDraft() {
        if (this.createDraftContact) {
            this.draftContact = JSON.parse(JSON.stringify(this.createDraftContact));
        } else {
            this.initializeCreateDraft();
        }
    
        this.editOrCreateContact = true;
        this.selectExistingContact = false;
    }

    saveSelectDraftIfNeeded() {
        if (this.selectedPrimaryContactAction === 'SELECT' && this.draftContact) {
            this.selectDraftContact = JSON.parse(JSON.stringify(this.draftContact));
        }
    }

    loadSelectDraft() {
        this.selectExistingContact = true;
    
        if (this.selectDraftContact && this.selectedExistingContactId) {
            this.draftContact = JSON.parse(JSON.stringify(this.selectDraftContact));
            this.editOrCreateContact = true;
            return;
        }
    
        if (this.selectedExistingContactId) {
            this.loadSelectedContact(this.selectedExistingContactId);
            return;
        }
    
        this.editOrCreateContact = false;
    }

    loadSelectedContact(contactId) {
        if (!contactId) {
            this.editOrCreateContact = false;
            return;
        }
    
        const cb = this.template.querySelector('lightning-combobox[data-name="selectNewPbc"]');
        if (cb) {
            cb.setCustomValidity('');
            cb.reportValidity();
        }
    
        const selected = this.originalContactList.find(
            acr => acr.ContactId === contactId
        );
    
        if (!selected) {
            this.editOrCreateContact = false;
            return;
        }
    
        this.draftContact = {
            action: 'SELECT',
            accountId: selected.AccountId,
            contact: {
                Id: selected.ContactId,
                FirstName: selected.Contact.FirstName,
                LastName: selected.Contact.LastName,
                Email: selected.Contact.Email,
                Phone: (selected.Contact.Phone || '').replace(/\D/g, ''),
                Title: selected.Contact.Title,
                PortalAccess: selected.Contact.ARC_PortalAccess__c ?? ''
            },
            roles: 'Primary Business Contact'
        };
    
        this.selectedPortalAccess = this.draftContact.contact.PortalAccess;
        this.selectedExistingContactId = this.draftContact.contact.Id;
        this.editOrCreateContact = true;
    
        this.selectDraftContact = JSON.parse(JSON.stringify(this.draftContact));
    
        requestAnimationFrame(() => {
            this.template
                .querySelectorAll('lightning-input, lightning-combobox')
                .forEach(field => {
                    field.reportValidity();
                });
        });
    }

    get contactOptions() {
        if (!this.contactList) return [];
    
        return this.contactList
            .filter(acr =>
                acr.Contact && acr.ContactId !== this.primaryBusinessContact?.ContactId
            )
            .map(acr => ({
                label: `${acr.Contact.FirstName || ''} ${acr.Contact.LastName || ''}`.trim(),
                value: acr.ContactId
            }));
    }

    get contactFullName() {
        if (!this.draftContact || !this.draftContact.contact) {
            return '';
        }
    
        const { FirstName, LastName } = this.draftContact.contact;
        return `${FirstName || ''} ${LastName || ''}`.trim();
    }

    handleContactChange(event){
        const contactId = event.detail.value;
        this.loadSelectedContact(contactId);
    }

    loadSelectedContact(contactId){
        if (!contactId){
            this.editOrCreateContact = false;
            return;
        }

        const cb = this.template.querySelector('lightning-combobox[data-name="selectNewPbc"]');
        if (cb){
            cb.setCustomValidity('');
            cb.reportValidity();
        }

        const selected = this.originalContactList.find(
            acr => acr.ContactId === contactId
        );
    
    
        if (!selected) {
            this.editOrCreateContact = false;
            return;
        }

        this.draftContact = {
            action: 'SELECT',
            accountId: selected.AccountId,
            contact: {
                Id: selected.ContactId,
                FirstName: selected.Contact.FirstName,
                LastName: selected.Contact.LastName,
                Email: selected.Contact.Email,
                Phone: selected.Contact.Phone,
                Title: selected.Contact.Title,
                PortalAccess: selected.Contact.ARC_PortalAccess__c ?? ''
            },
            roles: 'Primary Business Contact'
        };

        this.selectedPortalAccess = this.draftContact.contact.PortalAccess;
        this.selectedExistingContactId = this.draftContact.contact.Id;
        this.editOrCreateContact = true;

        requestAnimationFrame(() => {
            this.template
                .querySelectorAll('lightning-input, lightning-combobox')
                .forEach(field => {
                    field.reportValidity();
                });
        });
    }

    handlePhoneEmailInput() {
        const email = this.template.querySelector('lightning-input[data-name="Email"]');
        const phone = this.template.querySelector('lightning-input[data-name="Phone"]');

        if (phone) {
            const raw = phone.value || '';
            const digits = raw.replace(/\D/g, '').slice(0, 10); // keep 10 digits max

            // 1) Save clean digits in draft object (single source of truth)
            this.draftContact = {
                ...this.draftContact,
                contact: {
                    ...this.draftContact.contact,
                    Phone: digits
                }
            };
            // 2) Show pretty format in the UI input
            phone.value = this.formatPhoneFromDigits(digits); 
            phone.setCustomValidity(digits.length === 10 ? '' : 'Enter a 10-digit phone number');
            phone.reportValidity();
        }

        // Clear custom validity and re-validate
        if (email) {
            email.setCustomValidity('');
            email.reportValidity();
        }
    }

    @api
    validateRoles() {
        return this.hasPrimaryRoleSelected;
    }

    @api
    validateInputs() {
        let allValid = true;

        const inputs = [...this.template.querySelectorAll('lightning-input')];
        const comboboxes = [...this.template.querySelectorAll('lightning-combobox')];

        [...inputs, ...comboboxes].forEach(field => {
            if (typeof field.setCustomValidity === 'function') {
                field.setCustomValidity('');
            }
        });

        if (this.selectExistingContact) {
            const selectPbcCb = this.template.querySelector(
                'lightning-combobox[data-name="selectNewPbc"]'
            );

            const hasSelection = !!this.selectedExistingContactId;
            if (selectPbcCb && !hasSelection) {
                selectPbcCb.setCustomValidity('Please select a Contact.');
                allValid = selectPbcCb.reportValidity() && allValid;
            }
        }

        inputs.forEach(input => {
            allValid = input.reportValidity() && allValid;
        });

        comboboxes.forEach(cb => {
            allValid = cb.reportValidity() && allValid;
        });

        return allValid;
    }

    @api
    getFieldValues() {
        let values = {};
        this.template.querySelectorAll('lightning-input').forEach(input => {
            values[input.name] = input.value;
        });
        values['Id'] = this.contact.Id;
        return values;
    }

    @api
    refreshData() {
        if (this.wiredContactResult) {
            refreshApex(this.wiredContactResult);
        }
    }

    @api
    commitSavedState() {
        this.originalPrimaryBusinessContact = JSON.parse(
            JSON.stringify(this.draftContact)
        );
        this.resetToOriginal();
    }

    normalizePhone(phone) {
        return (phone || '').replace(/\D/g, '').slice(0, 10);
    }
      
    formatPhoneFromDigits(digits) {
        if (!digits) return '';
        const d = digits.replace(/\D/g, '');
        if (d.length < 4) return d;
        if (d.length < 7) return `(${d.slice(0,3)}) ${d.slice(3)}`;
        return `(${d.slice(0,3)}) ${d.slice(3,6)}-${d.slice(6,10)}`;
    }

    get formattedDraftPhone() {
        const raw = this.draftContact?.contact?.Phone || '';
        return this.formatPhoneFromDigits(this.normalizePhone(raw));
    }

    clearValidationState() {
        const fields = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea'
        );
    
        fields.forEach(f => {
            try {
                f.setCustomValidity('');
                f.reportValidity();
            } catch (e) {

            }
        });
    }
}