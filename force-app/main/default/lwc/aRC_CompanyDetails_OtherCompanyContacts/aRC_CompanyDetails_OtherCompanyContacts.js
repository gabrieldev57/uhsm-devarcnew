import { LightningElement, api, wire, track } from 'lwc';
import CONTACT_OBJECT from '@salesforce/schema/Contact';
import PORTAL_ACCESS_FIELD from '@salesforce/schema/Contact.ARC_PortalAccess__c';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const ROW_ACTIONS = [
    { label: 'Edit Details', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];


const base_columns = [
    { label: 'TPA Company Name', fieldName: 'accountName', type: 'text' },
    { label: 'Contact Name', fieldName: 'contactName', type: 'text' },
    { label: 'Email', fieldName: 'email', type: 'text' },
    { label: 'Portal Access', fieldName: 'portalAccess', type: 'text' }
];

const base_columns_oc = [
    { label: 'Name', fieldName: 'contactName', type: 'text' },
    { label: 'Title', fieldName: 'title', type: 'text' },
    { label: 'Email', fieldName: 'email', type: 'text' },
    { label: 'Portal Access', fieldName: 'portalAccess', type: 'text' },
    { label: 'Role', fieldName: 'roles', type: 'text' }
];

const actions_column = {
    type: 'action',
    typeAttributes: {
        rowActions: (row, doneCallback) => {
            if (row._state === ContactRowState.PENDING_DELETE) {
                doneCallback([{ label: 'Undo Delete', name: 'undo_delete' }]);
            } else {
                doneCallback(ROW_ACTIONS);
            }
        }
    }
};

const ContactRowState = Object.freeze({
    PERSISTED: 'PERSISTED',        
    DRAFT_NEW: 'DRAFT_NEW',         
    DRAFT_EDIT: 'DRAFT_EDIT',       
    PENDING_DELETE: 'PENDING_DELETE'
});

export default class ARC_CompanyDetails_OtherCompanyContacts extends LightningElement {
    @api isReadOnly;
    @api recordId;
    activeSections = ['CompanyOfficerContact', 'OtherContacts', 'ThirdPartyAdministratorContacts'];
    //activeSectionsMessage = '';
    _isEdit = false;
    hasInitialized = false;
    @api canEdit;
    contactRecordTypeId;
    primaryBusinessContact;

    @track isViewModalOpen = false;
    @track isDeleteModalOpen = false;
    @track selectedRow;
    @track selecedSource;
    @track columns = [];
    @track isContactModalOpen = false;
    modalMode;
    @track contactDraft;
    @track modalTitle;
    _pendingDeletes = [];
    rowPendingDelete;

    _originalTableDataOC;
    _originalTableDataTPA;
    _originalPendingDeletes;

    //========================================================== Full Contact List Variables =====================================================
    _initializedFullContactList = false;
    accountId;
    @track _fullContactList = []; // <-------------------- IT COMES FROM MAIN LWC --------------------
    @api 
    set fullContactList(value){  
        this._fullContactList = Array.isArray(value) ? value : [];
        this._initializedFullContactList = false;
        if (this._fullContactList.length === 0){
            return;
        }
        this._fullContactList = value.map(acr =>
            this.normalizeContactFromServer(acr)
        );
        this.initializeFullContactList();
        this.syncCompanyOfficerSameAsPbc?.();
    }
    get fullContactList(){
        return this._fullContactList;
    }
    //=============================================================================================================================================

    //========================================================== CompanyOfficeVariables ==========================================================
    _initializedCompanyOfficers = false;
    @track _companyOfficers = []; // <-------------------- IT COMES FROM MAIN LWC --------------------
    @api 
    set companyOfficers(value){  
        this._companyOfficers = Array.isArray(value) ? value : [];
        this._initializedCompanyOfficers = false;
        if (this._companyOfficers.length === 0){
            return;
        }
        this.initializeCompanyOfficers();
        this.syncCompanyOfficerSameAsPbc?.();
    }
    get companyOfficers(){
        return this._companyOfficers;
    }

    @track companyOfficerDraft = {
        mode: 'SAME_AS_PBC',
        dirty: false
    };

    companyOfficePicklistOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];

    sameCompanyOfficer = true;
    selectSameCompanyOfficer = false;
    @track companyOfficerSameAsPrimaryBusinessContact = 'Yes';
    companyOfficerContactOptions = [
        { label: 'Select Contact', value: 'SELECT' },
        { label: 'New Contact', value: 'CREATE' }
    ];
    @track selectedCompanyOfficeContactAction = 'SELECT'
    selectedPortalAccessCompOfficer;
    portalAccessPicklistCompOfficer;
    currentCompanyOfficer;
    showCompanyOfficerCombobox = false

    //=============================================================================================================================================

    //========================================================== Other Contacts Variables =====================================================
    _initializedOC = false;
    @track columnsOC = [];
    @track tableDataOC = [];
    @track _otherContacts = [];
    @track draftContactOC = {
        action: '',
        accountId: null,
        Contact: {
            Id: null,
            FirstName: '',
            LastName: '',
            Email: '',
            Phone: '',
            Title: '',
            PortalAccess: '',
            OwnershipPercentage: null
        },
        roles: ''
    };
    @api
    set otherContacts(value){  
        this._otherContacts = Array.isArray(value) ? value : [];
        this.rebuildOCList(); 
    }
    get otherContacts(){
        return this._otherContacts;
    }
    @track showOther = false;
    //=============================================================================================================================================

    //========================================================== TPA Variables =====================================================
    _initializedTPA = false;
    @track columnsTPA = [];
    @track tableDataTPA = [];
    @track _thirdPartyAdmins = [];
    @track tpaAccountName;
    @api
    set thirdPartyAdmins(value){  
        this._thirdPartyAdmins = Array.isArray(value) ? value : [];
        //this.tpaAccountName = this._thirdPartyAdmins[0]?.Account?.Name;
        this.tpaAccountName = this._thirdPartyAdmins[0]?.Account?.Name || 
                            this._thirdPartyAdmins[0]?.Contact?.Account?.Name || '';
        this.rebuildTPAList()
    }
    get thirdPartyAdmins(){
        return this._thirdPartyAdmins;
    }
    @track showTPA = false;
    @track isContactModalOpenTPA = false;
    //==============================================================================================================================
    

    buildColumns(tableType){
        let base;

        switch (tableType) {
            case 'TPA':
                base = [...base_columns];
                break;
            case 'OTHER':
                base = [...base_columns_oc];
                break;
            default:
                base = [];
        }

        if (this._isEdit) {
            base.push(actions_column);
        }
        return base;
    }

    updateAllColumns(){
        this.columnsTPA = this.buildColumns('TPA');
        this.columnsOC = this.buildColumns('OTHER');
    }


    connectedCallback() {
        this.updateAllColumns();

        if (this.companyOfficerSameAsPrimaryBusinessContact === 'Yes'){
            this.companyOfficerDraft = {
                action: 'SAME_AS_PBC',
                dirty: false,
            };
        }
    }

    
    initializeCompanyOfficers(){
        if (this._initializedCompanyOfficers) return;
        this._initializedCompanyOfficers = true;
        
        if (!Array.isArray(this._companyOfficers) || this._companyOfficers.length === 0) return;

        const acr = this._companyOfficers[0];
        this.currentCompanyOfficer = acr;

        const coContact = acr.Contact || {};
        
        this.companyOfficerDraft = {
            action: 'UPDATE',
            accountId: acr.AccountId,
            contactId: acr.ContactId,
            Contact: {
                Id: acr.ContactId,
                FirstName: coContact.FirstName || '',
                LastName: coContact.LastName || '',
                Email: coContact.Email || '',
                Phone: coContact.Phone || '',
                Title: coContact.Title || '',
                PortalAccess: coContact.ARC_PortalAccess__c || ''
            },
            roles: this.normalizeRoles(acr.Roles)
        };
        this.selectedPortalAccessCompOfficer = this.companyOfficerDraft.Contact.PortalAccess;
        this.syncCompanyOfficerSameAsPbc();
    }

    get contactFullName() {
        if (!this.companyOfficerDraft || !this.companyOfficerDraft.Contact) {
            return '';
        }
    
        const { FirstName, LastName } = this.companyOfficerDraft.Contact;
        return `${FirstName || ''} ${LastName || ''}`.trim();
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
            this.portalAccessPicklistCompOfficer = data.values;
        } else if (error) {
            this.error = error;
            this.portalAccessPicklistCompOfficer = undefined;
        }
    }

    handlePortalAccessChange(event){
        this.selectedPortalAccessCompOfficer = event.detail.value;
        this.companyOfficerDraft = {
            ...this.companyOfficerDraft,
            dirty: true,
            Contact: {
                ...this.companyOfficerDraft.Contact,
                PortalAccess: this.selectedPortalAccessCompOfficer
            }
        };
    }


    //Cancel will only reset variables
    @api
    set isEdit(value){
        const wasEdit = this._isEdit;
        this._isEdit = value ?? false;

        if (!wasEdit && this._isEdit) {
            this._originalTableDataOC = JSON.parse(JSON.stringify(this.tableDataOC));
            this._originalTableDataTPA = JSON.parse(JSON.stringify(this.tableDataTPA));
            this._originalPendingDeletes = JSON.parse(JSON.stringify(this._pendingDeletes || []));
        }

        // Cancel => restore snapshot
        if (wasEdit && !this._isEdit && !this._justSaved) {
            this.restoreFromSnapshot();
            this.resetToOriginal();
        }

        this._justSaved = false; //it gets cleaned always.
        this.updateAllColumns();
    }

    get isEdit(){
        return this._isEdit;
    }

    get isReadOnly() {
        return !this.isEdit;
    }

    get isRequired() {
        return this.isEdit;
    }

    restoreFromSnapshot(){
        this.tableDataOC = JSON.parse(JSON.stringify(this._originalTableDataOC || []));
        this.tableDataTPA = JSON.parse(JSON.stringify(this._originalTableDataTPA || []));
        this._pendingDeletes = JSON.parse(JSON.stringify(this._originalPendingDeletes || []));

        this.isViewModalOpen = false;
        this.isDeleteModalOpen = false;
        this.selectedTableRowId = null;
        this.selecedSource = null;
        this.draftContactOC = null;
        this.rowPendingDelete = null;
    }

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        if (openSections.length === 0) {
            this.activeSectionsMessage = 'All sections are closed';
        } else {
            this.activeSectionsMessage = 'Open sections: ' + openSections.join(', ');
        }
    }

    handleCompanyOfficePicklist(event){
        this.companyOfficerSameAsPrimaryBusinessContact = event.detail.value;

        if(this.companyOfficerSameAsPrimaryBusinessContact == 'No'){
            this.sameCompanyOfficer = false;
            this.selectSameCompanyOfficer = false;
            this.showCompanyOfficerCombobox = true;

            this.companyOfficerDraft = {
                action: null,
                dirty: false
            };
            
        } else if (this.companyOfficerSameAsPrimaryBusinessContact == 'Yes') {
            this.selectSameCompanyOfficer = false;
            this.sameCompanyOfficer = true;
            this.showCompanyOfficerCombobox = false;

            this.companyOfficerDraft = {
                action: 'SAME_AS_PBC',
                dirty: true
            };
        }
    }

    handleCompanyOfficerContactActionChange(event){

        this.selectedCompanyOfficeContactAction = event.detail.value;

        if (this.selectedCompanyOfficeContactAction === 'SELECT') {
            this.companyOfficerDraft = {
                action: 'SELECT',
                dirty: false,
                accountId: this.currentCompanyOfficer?.AccountId,
                contactId: null,
                Contact: { FirstName:'', LastName:'', Email:'', Phone:'', Title:'', PortalAccess:'' },
                roles: []
              };

            this.selectedPortalAccessCompOfficer = '';
            this.showCompanyOfficerCombobox = true;
            this.selectSameCompanyOfficer = false;
            return;
        }

        if (this.selectedCompanyOfficeContactAction === 'CREATE') {
            this.companyOfficerDraft = {
                action: 'CREATE',
                dirty: true,
                accountId: this.currentCompanyOfficer.AccountId,
                Contact: {
                    Id: null,
                    FirstName: '',
                    LastName: '',
                    Email: '',
                    Phone: '',
                    PortalAccess: ''
                },
                roles: ['Company Officer Contact']
            };

            this.selectedPortalAccessCompOfficer = ''; 
            this.selectSameCompanyOfficer = true;
            this.showCompanyOfficerCombobox = false;
        }
    }


    initializeFullContactList(){
        if (this._initializedFullContactList) return;

        this._initializedFullContactList = true;
        if (!Array.isArray(this._fullContactList) || this._fullContactList.length === 0) {
            return;
        }

        const pbc = this._fullContactList.find(acr =>
            Array.isArray(acr.roles) && acr.roles.includes('Primary Business Contact')
        );
        this.primaryBusinessContact = pbc || null;
        this.accountId = pbc?.AccountId || null;
        this.initializeCompanyOfficerDraft();
        this.syncCompanyOfficerSameAsPbc();
    }

    get contactOptions() {
        if (!Array.isArray(this._fullContactList)) {
            return [];
        }
    
        const base = this._fullContactList.
        filter(acr => {
            if (!acr?.ContactId || !acr?.Contact) return false;

            if (acr.ContactId === this.primaryBusinessContact?.ContactId) return false;

            if (acr.Roles?.includes('Third Party Administrator')) return false;

            return true;
        })
        .map(acr => ({
            label: `${acr.Contact.FirstName ?? ''} ${acr.Contact.LastName ?? ''} - ${acr.Roles ?? ''}`.trim(),
            value: acr.ContactId
        }));

        const currentId = this.currentCompanyOfficer?.ContactId;
        const hasCurrent = currentId && base.some(o => o.value === currentId);

        if (!hasCurrent && currentId) {
            const co = this.currentCompanyOfficer;
            return [
              {
                label: `${co.Contact?.FirstName ?? ''} ${co.Contact?.LastName ?? ''} - ${co.Roles ?? 'Company Officer Contact'}`.trim(),
                value: currentId
              },
              ...base
            ];
          }
        
        return base;
    }

    collectCompanyOfficerDraft({ create, update }) {
        const d = this.companyOfficerDraft;
    
        if (!d || !d.dirty) {
            return;
        }
        switch (d.action) {
    
            case 'SAME_AS_PBC':
                update.push({
                    action: 'UPDATE',
                    contactId: this.primaryBusinessContact.ContactId,
                    Contact: {
                        ...this.primaryBusinessContact.Contact
                    },
                    roles: this.mergeRoles(
                        this.primaryBusinessContact?.roles || this.primaryBusinessContact?.Roles,
                        'Company Officer Contact'
                    )
                });
                break;
    
            case 'SELECT':
            case 'UPDATE':
                update.push({
                    action: 'UPDATE',
                    accountId: d.accountId,
                    contactId: d.contactId,
                    Contact: {
                        ...d.Contact
                    },
                    //roles: ['Company Officer Contact']
                    roles: this.mergeRoles(d.roles, 'Company Officer Contact')
                });
                break;
    
            case 'CREATE':
                create.push({
                    action: 'CREATE',
                    accountId: d.accountId,
                    Contact: {
                        ...d.Contact
                    },
                    roles: ['Company Officer Contact']
                });
                break;
    
            default:
                break;
        }
    }

    mergeRoles(existingRoles, roleToAdd) {
        return [...new Set([...this.normalizeRoles(existingRoles), roleToAdd])];
    }

    get optionsMultiPicklist(){
        return [
            { label: 'Billing Contact', value: 'Billing Contact' },
            { label: 'Account Holder', value: 'Account Holder' },
            { label: 'Ownership', value: 'Ownership' },
            { label: 'Other', value: 'Other' },
        ];
    }

    get companyOfficerDraftContactReady() {
        return !!this.companyOfficerDraft?.Contact;
    }

    handleContactChange(event){
        const contactId = event.detail.value;
        const selected = this._fullContactList.find(acr => acr.ContactId === contactId);
        if (!selected) return;

        this.companyOfficerDraft = this.buildCompanyOfficerDraftFromAcr(selected);
        this.companyOfficerDraft.dirty = true;

        this.selectedPortalAccessCompOfficer = this.companyOfficerDraft.Contact.PortalAccess;
        this.selectSameCompanyOfficer = true;

        //Clear required input
        requestAnimationFrame(() => {
            this.template
            .querySelectorAll('lightning-input')
            .forEach(input => {
                input.reportValidity();
            })
        });
        
    }

    handleInputChange(event){
        const field = event.target.name;
        let value = event.detail?.value ?? event.target.value;

        if (field === 'Phone') {
            value = (value || '').replace(/\D/g, '').slice(0, 10);
        } 

        if (!this.companyOfficerDraft) {
            const selected = this._fullContactList.find(acr => acr.ContactId === this.selectedExistingContactId);
            if (!selected) return;
    
            this.companyOfficerDraft = this.buildCompanyOfficerDraftFromAcr(selected);
        }

        this.companyOfficerDraft = {
            ...this.companyOfficerDraft,
            dirty: true,
            Contact: {
                ...this.companyOfficerDraft.Contact,
                [field]: value
            }
        };
    }

    syncCompanyOfficerSameAsPbc(){
        const pbcId = this.primaryBusinessContact?.ContactId;
        const coId = this.currentCompanyOfficer?.ContactId;
        
        if (!pbcId || !coId) return;

        const same = pbcId === coId;

        this.companyOfficerSameAsPrimaryBusinessContact = same ? 'Yes' : 'No';
        this.sameCompanyOfficer = same;
        this.selectSameCompanyOfficer = !same; 
        this.showCompanyOfficerCombobox = !same; 
        if (!same){
            const co = this.currentCompanyOfficer;
            this.companyOfficerDraft = {
                action: 'UPDATE',
                dirty: false,
                accountId: co.AccountId,
                contactId: co.ContactId,
                Contact: {
                    Id: co.ContactId,
                    FirstName: co.Contact?.FirstName || '',
                    LastName: co.Contact?.LastName || '',
                    Email: co.Contact?.Email || '', 
                    Phone: co.Contact?.Phone || '',
                    Title: co.Contact?.Title || '',
                    PortalAccess: co.Contact?.ARC_PortalAccess__c || ''
                },
                roles: ['Company Officer Contact']
            };
            this.selectedPortalAccessCompOfficer = this.companyOfficerDraft.Contact.PortalAccess;
            this.selectedExistingContactId = this.currentCompanyOfficer?.ContactId;
        } else {
            this.companyOfficerDraft = { action: 'SAME_AS_PBC', dirty: false, Contact: { PortalAccess: '' } };
            this.selectedPortalAccessCompOfficer = this.primaryBusinessContact?.Contact?.ARC_PortalAccess__c || '';
        }
    }

    ///// TAP LOGIC
    rebuildTPAList(){
        this.tableDataTPA = this._thirdPartyAdmins.map(row => {
            
            const cleanOriginalRow = JSON.parse(JSON.stringify(row));
            cleanOriginalRow.hasUser = row.hasUser || false;
            
            return {
                Id: row.Id,
                groupAccountName: row.Account?.Name || '',
                accountName: row.Contact?.Account?.Name || row.Account?.Name || '',
                contactName: `${row.Contact?.FirstName || ''} ${row.Contact?.LastName || ''}`.trim(),
                email: row.Contact?.Email || '',
                phone: row.Contact?.Phone || '',
                portalAccess: row.Contact?.ARC_PortalAccess__c ?? row.Contact?.PortalAccess ?? '',
                _source: 'TPA',
                _state: ContactRowState.PERSISTED,
                _originalRow: cleanOriginalRow,
                _draftContactOC: null
            };
        });

        this._pendingDeletes = [];
    }

    rebuildOCList(){
        this.tableDataOC = (this._otherContacts || []).map(row => {
            const cleanOriginalRow = JSON.parse(JSON.stringify(row));
            cleanOriginalRow.roles = this.normalizeRoles(row.Roles);
            cleanOriginalRow.hasUser = row.hasUser || false;

            delete cleanOriginalRow.Roles;

            if (cleanOriginalRow.Contact) {
                cleanOriginalRow.Contact.OwnershipPercentage =
                    row.Contact?.ARC_OwnershipPercentage__c ?? null;
            }
    
            return {
                Id: row.Id,
                contactName: `${row.Contact?.FirstName || ''} ${row.Contact?.LastName || ''}`.trim(),
                title: row.Contact?.Title,
                email: row.Contact?.Email || '',
                portalAccess: row.Contact?.ARC_PortalAccess__c,
                roles: this.formatRolesForDisplay(cleanOriginalRow.roles, row.Contact?.ARC_OwnershipPercentage__c),
                _source: 'OTHER',
                _state: ContactRowState.PERSISTED,
                _originalRow: cleanOriginalRow,
                _draftContactOC: null
            };
        });
        this._pendingDeletes = [];
    }

    getUniqueRoleAssignmentsForValidation() {
        const assignments = [];
        const uniqueRoles = [
            'Billing Contact',
            'Account Holder',
            'Company Officer Contact'
        ];
    
        // 1. Other Contacts
        (this.tableDataOC || []).forEach(row => {
            if (!row || row._state === ContactRowState.PENDING_DELETE) {
                return;
            }
    
            const effectiveRoles =
                row._state === ContactRowState.DRAFT_NEW || row._state === ContactRowState.DRAFT_EDIT
                    ? this.normalizeRoles(row._draftContactOC?.roles)
                    : this.normalizeRoles(row._originalRow?.roles);
    
            const contactId =
                row._state === ContactRowState.DRAFT_NEW || row._state === ContactRowState.DRAFT_EDIT
                    ? row._draftContactOC?.contactId || row._draftContactOC?.Contact?.Id
                    : row._originalRow?.ContactId || row._originalRow?.Contact?.Id;
    
            uniqueRoles.forEach(role => {
                if (effectiveRoles.includes(role) && contactId) {
                    assignments.push({ role, contactId });
                }
            });
        });
    
        // 2. Company Officer section
        if (this.companyOfficerDraft?.contactId || this.companyOfficerDraft?.Contact?.Id) {
            const cocContactId = this.companyOfficerDraft.contactId || this.companyOfficerDraft.Contact?.Id;
            const cocRoles = this.normalizeRoles(this.companyOfficerDraft.roles);
    
            uniqueRoles.forEach(role => {
                if (cocRoles.includes(role) && cocContactId) {
                    assignments.push({ role, contactId: cocContactId });
                }
            });
        }
    
        return assignments;
    }

    validateUniqueRolesBeforeSave() {
        const assignments = this.getUniqueRoleAssignmentsForValidation();
    
        const roleToContactIds = new Map();
    
        assignments.forEach(({ role, contactId }) => {
            if (!roleToContactIds.has(role)) {
                roleToContactIds.set(role, new Set());
            }
            roleToContactIds.get(role).add(contactId);
        });
    
        const duplicatedRoles = [];
    
        roleToContactIds.forEach((contactIds, role) => {
            if (contactIds.size > 1) {
                duplicatedRoles.push(role);
            }
        });
    
        if (duplicatedRoles.length > 0) {
            return {
                isValid: false,
                duplicatedRoles,
                message: this.buildUniqueRoleValidationMessage(duplicatedRoles)
            };
        }
    
        return {
            isValid: true,
            duplicatedRoles: [],
            message: ''
        };
    }

    buildUniqueRoleValidationMessage(duplicatedRoles) {
        if (!duplicatedRoles || duplicatedRoles.length === 0) {
            return '';
        }
    
        if (duplicatedRoles.length === 1) {
            return `Only one contact can have the role "${duplicatedRoles[0]}". Please review the Other Contacts section and try again.`;
        }
    
        const quotedRoles = duplicatedRoles.map(role => `"${role}"`);
    
        if (quotedRoles.length === 2) {
            return `Only one contact can have each of these roles: ${quotedRoles[0]} and ${quotedRoles[1]}. Please review the Other Contacts section and try again.`;
        }
    
        const lastRole = quotedRoles.pop();
        return `Only one contact can have each of these roles: ${quotedRoles.join(', ')}, and ${lastRole}. Please review the Other Contacts section and try again.`;
    }

    buildDraftFromRow(row) {
        const contact = row?.Contact || row?._originalRow?.Contact || {};
        const portalAccess = contact.PortalAccess ?? contact.ARC_PortalAccess__c ?? '';
        const ownershipPercentage = contact.OwnershipPercentage ?? contact.ARC_OwnershipPercentage__c ?? null;

        const normalizeRoles = (roles) => {
            if (!roles) return [];
            if (Array.isArray(roles)) return roles;
            return roles.split(/[,;]+/).map(r => r.trim()).filter(Boolean);
        };
    
        return {
            action: '',
            accountId: row.accountId ?? row.AccountId,
            Contact: {
                Id: contact.Id ?? row?.ContactId ?? null,
                FirstName: row.Contact?.FirstName || '',
                LastName: row.Contact?.LastName || '',
                Email: row.Contact?.Email || '',
                Phone: row.Contact?.Phone || '',
                Title: row.Contact?.Title || '',
                PortalAccess: portalAccess,
                OwnershipPercentage: ownershipPercentage
            },
            roles: normalizeRoles(row.roles ?? row.Roles)
        };
    }

    updateRowInTable(tableData, selectedId) {
        const updated = JSON.parse(JSON.stringify(this.draftContactOC));

        return tableData.map(row => {
            if (row.Id !== selectedId) return row;

            const rawRoles =
                updated.roles ??
                updated.Contact?.roles ??
                row._draftContactOC?.roles ??
                row._originalRow?.Roles ??
                [];

            const normalizedRoles = this.normalizeRoles(rawRoles);

            const cleanOriginalRow = JSON.parse(JSON.stringify(row._originalRow));
            delete cleanOriginalRow.Roles;

            const cleanUpdatedContact = { ...(updated.Contact || {}) };
            delete cleanUpdatedContact.roles;

            const mergedDraft = {
                ...cleanOriginalRow,
                roles: normalizedRoles,
                Contact: {
                    ...cleanOriginalRow.Contact,
                    ...cleanUpdatedContact
                }
            };
            return this.decorateRowState({
                ...row,
                roles: this.formatRolesForDisplay(normalizedRoles, mergedDraft.Contact?.OwnershipPercentage),
                contactName: `${mergedDraft.Contact?.FirstName || ''} ${mergedDraft.Contact?.LastName || ''}`.trim(),
                title: mergedDraft.Contact?.Title || '',
                email: mergedDraft.Contact?.Email || '',
                portalAccess: mergedDraft.Contact?.PortalAccess || mergedDraft.Contact?.ARC_PortalAccess__c || '',
                _state: ContactRowState.DRAFT_EDIT,
                _draftContactOC: mergedDraft
            });
        });
    }

    markRowForDelete(tableData, rowId) {
        this.isDeleteModalOpen = false;
        return tableData.map(row => {
            if (row.Id !== rowId) return row;
    
            return this.decorateRowState({
                ...row,
                _state: ContactRowState.PENDING_DELETE,
                _draftContactOC: row._originalRow, 
                _previousState: row._state
            });
        });
    }

    decorateRowState(row) {
        if (row._state === ContactRowState.DRAFT_EDIT) {
            return {
                ...row,
                _stateLabel: 'Edited – will be updated on Save All',
                _stateIcon: 'utility:edit',
                _stateTextClass: 'slds-text-color_success',
                _stateIconClass: 'slds-icon_container slds-icon-utility-announcement'
            };
        }

        if (row._state === ContactRowState.PENDING_DELETE) {
            return {
                ...row,
                _stateLabel: 'Pending delete – will be removed on Save All',
                _stateIcon: 'utility:delete',
                _stateTextClass: 'slds-text-color_error',
                _stateIconClass: 'slds-icon-text-error'
            };
        }

        if (row._state === ContactRowState.DRAFT_NEW) {
            return {
                ...row,
                _stateLabel: 'Pending creation – will be created on Save All',
                _stateIcon: 'utility:contact',
                _stateTextClass: 'slds-text-color_success',
                _stateIconClass: 'slds-icon-text-success'
            };
        }
    
        return {
            ...row,
            _stateLabel: '',
            _stateTextClass: '',
            _stateIcon: null,
            _stateIconClass: ''
        };
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        this.currentState = row._state;
        this.selectedTableRowId = row.Id;
        this.selecedSource = row._source;

        // For TPA edit, use reusable modal and return
        if (actionName === 'edit' && row._source === 'TPA') {
            await this.openReusableTPAModalForEdit(row);
            return;
        }

        // Existing behavior (OTHER uses your legacy modal)
        // ------------------------------------------------
        const tableType = event.target.dataset.table;

        let sourceData;
        if (row._state === ContactRowState.PERSISTED) {
            sourceData = row._originalRow;
        } else {
            sourceData = row._draftContactOC;
        }

        this.activeTable = tableType;
        this.draftContactOC = this.buildDraftFromRow(sourceData);

        if (this.selecedSource === 'TPA'){
            this.showTPA = true;
            this.showOther = false;
        } else if(this.selecedSource === 'OTHER'){
            this.showOther = true;
            this.showTPA = false;
        }

        if (actionName === 'edit') {
            this.isViewModalOpen = true;
        }

        if (actionName === 'delete') {
            this.rowPendingDelete = row;
            this.isDeleteModalOpen = true;
        }

        if (actionName === 'undo_delete') {
            this.undoDelete(row);
        }
    }

    async openReusableTPAModalForEdit(row) {
        const modal = this.template.querySelector('c-a-r-c_-t-p-a-modal');
        if (!modal) return;
    
        const tpaForModal = this.mapTPARowToModalInput(row);
    
        const result = await modal.open({
            mode: 'edit',
            tpa: tpaForModal
            // index: not needed in your component
        });
    
        if (!result || result.action !== 'save') return;
    
        // Update row in tableDataTPA
        const updatedDraft = this.mapTPAModalResultToDraft(result.tpa);
        
        this.tableDataTPA = this.tableDataTPA.map(r => {
            if (r.Id !== row.Id) return r;
    
            const isNew = r._state === ContactRowState.DRAFT_NEW;
    
            // If it is a new draft row, keep it DRAFT_NEW; otherwise mark as DRAFT_EDIT
            const nextState = isNew ? ContactRowState.DRAFT_NEW : ContactRowState.DRAFT_EDIT;

            const targetAccountId = updatedDraft.useExistingAccount ? (updatedDraft.accountId || null) : this.accountId;

            const groupAccountId = r?._originalRow?.AccountId || this.accountId;
            const contactId =
                r?._originalRow?.ContactId ||
                r?._originalRow?.Contact?.Id ||
                r?._draftContactOC?.Contact?.Id ||
                null;
    
            const nextRow = this.decorateRowState({
                ...r,
                accountName: updatedDraft.companyName || r.accountName,
                contactName: `${updatedDraft.firstName || ''} ${updatedDraft.lastName || ''}`.trim(),
                email: updatedDraft.email || '',
                phone: updatedDraft.phone || '', 
                portalAccess: updatedDraft.portalAccess || '',
                _state: nextState,
                _draftContactOC: {
                    ...(r._draftContactOC || {
                        action: 'UPDATE',
                        accountId: groupAccountId,
                        contactId: contactId,
                        Contact: { Id: contactId },
                        roles: ['Third Party Administrator']
                    }),
                    accountId: groupAccountId,
                    action: isNew ? 'CREATE' : 'UPDATE',
                    contactId: contactId,
                    Contact: {
                        ...(r._draftContactOC?.Contact || {}),
                        Id: contactId,
                        FirstName: updatedDraft.firstName || '',
                        LastName: updatedDraft.lastName || '',
                        Email: updatedDraft.email || '',
                        Phone: updatedDraft.phone || '',
                        PortalAccess: updatedDraft.portalAccess || ''
                    },
                    roles: ['Third Party Administrator'],
                    tpaUi: {
                        useExistingAccount: !!updatedDraft.useExistingAccount,
                        accountId: updatedDraft.accountId || null,
                        companyName: updatedDraft.companyName || '',
                        mailingAddress: updatedDraft.mailingAddress || '',
                        city: updatedDraft.city || '',
                        state: updatedDraft.state || '',
                        zip: updatedDraft.zip || '',
                        firstName: updatedDraft.firstName || '',
                        lastName: updatedDraft.lastName || '',
                        email: updatedDraft.email || '',
                        phone: updatedDraft.phone || ''
                    }
                }
            });
    
            return nextRow;
        });
        this.isContactModalOpen = false;
    }

    mapTPAModalResultToDraft(tpa) {
        // EN: Normalize the modal payload into a predictable shape.
        return {
            useExistingAccount: !!tpa?.useExistingAccount,
            accountId: tpa?.accountId || null,
            companyName: tpa?.companyName || '',
            mailingAddress: tpa?.mailingAddress || '',
            city: tpa?.city || '',
            state: tpa?.state || '',
            zip: tpa?.zip || '',
            firstName: tpa?.firstName || '',
            lastName: tpa?.lastName || '',
            phone: tpa?.phone || '',
            email: tpa?.email || '',
            portalAccess: tpa?.portalAccess || ''
        };
    }
    
    mapTPARowToModalInput(row) {
        // Try to recover previously saved UI fields first

        // Prefer draft (user edits) > originalRow (server) > row display fields
        const draft = row?._draftContactOC || null;
        const orig  = row?._originalRow || null;

        const draftContact = draft?.Contact || {};
        const origContact  = orig?.Contact || {};

        // UI cache (account/address selection) — only contains account/address today
        const ui = draft?.tpaUi || {};
        // Name fallback
        const contactNameParts = (row?.contactName || '').trim().split(/\s+/);
        const fallbackFirst = contactNameParts[0] || '';
        const fallbackLast  = contactNameParts.slice(1).join(' ') || '';

        const firstName = draftContact.FirstName ?? origContact.FirstName ?? ui.firstName ?? fallbackFirst;
        const lastName  = draftContact.LastName  ?? origContact.LastName  ?? ui.lastName  ?? fallbackLast;

        const email = draftContact.Email ?? origContact.Email ?? ui.email ?? '';
        const phone = draftContact.Phone ?? origContact.Phone ?? ui.phone ?? '';

        const portalAccess =
            draftContact.PortalAccess ??
            origContact.ARC_PortalAccess__c ??
            origContact.PortalAccess ??
            row?.portalAccess ??
            '';

        const businessAccountId =
            ui.accountId ||
            row?._originalRow?.Contact?.AccountId ||
            row?.Contact?.AccountId ||
            null;

        const businessAccountName =
            ui.companyName ||
            row?._originalRow?.Contact?.Account?.Name ||
            row?.Contact?.Account?.Name ||
            row?.accountName ||
            '';

        const contactAcc = row?._originalRow?.Contact?.Account || {};

        return {
            // This helps the modal set the radio properly
            useExistingAccount: ui.useExistingAccount ?? true,

            // Account/address (modal uses these for displaying existing/new)
            accountId: businessAccountId,
            companyName: businessAccountName,
            mailingAddress: ui.mailingAddress ?? contactAcc.BillingStreet ?? '',
            city: ui.city ?? contactAcc.BillingCity ?? '',
            state: ui.state ?? contactAcc.BillingState ?? '',
            zip: ui.zip ?? contactAcc.BillingPostalCode ?? '',

            // Contact fields
            firstName,
            lastName,
            phone,
            email,
            portalAccess
        };
    }

    removeDraftRow(row) {
        if (row._source === 'OTHER') {
            this.tableDataOC = this.tableDataOC.filter(r => r.Id !== row.Id);
        }
    
        if (row._source === 'TPA') {
            this.tableDataTPA = this.tableDataTPA.filter(r => r.Id !== row.Id);
        }
    }

    undoDelete(row) {
        const restoredRow = this.decorateRowState({
            ...row,
            _state: row._previousState ?? ContactRowState.PERSISTED,
            _previousState: null
        });
    
        if (row._source === 'OTHER') {
            this.tableDataOC = this.tableDataOC.map(r =>
                r.Id === row.Id ? restoredRow : r
            );
        }
    
        if (row._source === 'TPA') {
            this.tableDataTPA = this.tableDataTPA.map(r =>
                r.Id === row.Id ? restoredRow : r
            );
        }
    }

    closeViewModal() {
        this.isViewModalOpen = false;
        this.selectedRow = null;
        this.newContactModal = false
    }

    closeDeleteModal() {
        this.selectedRow = null;
        this.isDeleteModalOpen = false;
        this.selectedTableRowId = null;
        this.selecedSource = null;
    }

    handleDraftChanges(event){
        const field = event.target.name;
        let value = event.detail?.value ?? event.target.value;
        const input = event.target;

        if (field === 'roles') {
            this.draftContactOC = {
                ...this.draftContactOC,
                roles: Array.isArray(value) ? value : []
            };
            requestAnimationFrame(() => this.validateOwnershipInputRealtime());
            return;
        }

        if (field === 'OwnershipPercentage') {
            value = this.normalizeOwnershipPercentage(value);
        }

        if (field === 'Phone') {
            const digits = (value || '').replace(/\D/g, '').slice(0, 10);

            this.draftContactOC = {
                ...this.draftContactOC,
                roles: this.draftContactOC.roles,
                Contact: {
                    ...this.draftContactOC.Contact,
                    [field]: digits
                }
            };

            input.value = this.formatPhoneFromDigits(digits);
            return;   
        }
            
        this.draftContactOC = {
            ...this.draftContactOC,
            roles: this.draftContactOC.roles,
            Contact: {
                ...this.draftContactOC.Contact,
                [field]: value
            }
        };  

        this.validateOwnershipInputRealtime();
    }

    //New Contact logic 
    buildNewRowFromDraft(draft, source) {
        const tempId = crypto.randomUUID(); //key temporal

        // If TPA selected an existing business account, that becomes Contact.AccountId
        const targetAccountId =
            (source === 'TPA' && draft?.tpaUi?.useExistingAccount)
            ? draft.tpaUi.accountId
            : draft.accountId;
    
        return this.decorateRowState({
            Id: tempId,
            accountName: source === 'TPA'
                    ? this.tpaAccountName
                    : null,
            contactName: `${draft.Contact.FirstName} ${draft.Contact.LastName}`,
            email: draft.Contact.Email,
            title: draft.Contact.Title,
            phone: draft.Contact.Phone,
            portalAccess: draft.Contact.PortalAccess,
            roles: this.formatRolesForDisplay(draft.roles, draft.Contact.OwnershipPercentage),
            _source: source, // OTHER | TPA
            _state: ContactRowState.DRAFT_NEW,
            _originalRow: null,
            _draftContactOC: {
                action: 'CREATE',
                accountId: targetAccountId,
                Contact: { ...draft.Contact },
                roles: [...(draft.roles || [])],
                tpaUi: draft._tpaUi || draft.tpaUi || null
            }
        });
    }

    get isOtherContact() {
        return this.modalMode === 'OTHER';
    }

    handleModalSaveOnEditedRecords(){
        if (!this.validateOwnershipInputRealtime()) {
            const ownershipInput =
                this.template.querySelector('lightning-input[data-name="OwnershipPercentage"]') ||
                this.template.querySelector('lightning-input[data-field="OwnershipPercentage"]');

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: ownershipInput?.validationMessage || 'Review the Ownership % value before saving.',
                    variant: 'error'
                })
            );
            return;
        }

        if (!this.validateModalInputs()) {
            return;
        }

        if (!this.selectedTableRowId || !this.draftContactOC) {
            return;
        }

        if (this.selecedSource === 'OTHER') {
            this.tableDataOC = this.updateRowInTable(
                this.tableDataOC,
                this.selectedTableRowId
            );
        }
    
        if (this.selecedSource === 'TPA') {
            this.tableDataTPA = this.updateRowInTable(
                this.tableDataTPA,
                this.selectedTableRowId
            );
        }
        this.closeViewModal();
    }

    handleModalDeleteOnRecords(){
       //if (!this.selectedTableRowId) return;
       const row = this.rowPendingDelete;
       if (!row) return;
   
       if (row._state === ContactRowState.DRAFT_NEW) {
           this.removeDraftRow(row);
           this.closeDeleteModal();
           return;
       }
   
       this._pendingDeletes = this._pendingDeletes || [];

       const contactId = row._originalRow?.Contact?.Id || row._originalRow?.ContactId;
       if(contactId){
        const hasUser = row._originalRow?.hasUser || false;

        this._pendingDeletes.push({
           contactId: contactId,
           hasUser: hasUser,
           acrId: row._originalRow?.Id
        });

       }
          
       if (row._source === 'OTHER') {
           this.tableDataOC = this.tableDataOC.filter(r => r.Id !== row.Id);
       }
   
       if (row._source === 'TPA') {
           this.tableDataTPA = this.tableDataTPA.filter(r => r.Id !== row.Id);
       }
   
       this.closeDeleteModal();
    }

    markRowAsPendingDelete(row) {
        this.isContactModalOpen = false;
        if (row._state === ContactRowState.DRAFT_NEW) {
            return null;
        }
    
        return this.decorateRowState({
            ...row,
            _state: ContactRowState.PENDING_DELETE
        });
    }

    async handleNewContact(event){
        const type = event.target.value;

        if (type === 'OTHER') {
            this.modalMode = 'OTHER';
            this.modalTitle = 'New Contact';
            this.isContactModalOpen = true;
        } else if (type === 'TPA') {
            this.modalMode = 'TPA';
            this.modalTitle = 'New Third Party Administrator';
            this.isContactModalOpen = false;
            await this.openReusableTPAModalForNew();
        }

        this.contactDraft = {
            action: 'CREATE',
            source: this.modalMode,
            accountId: this.accountId,
            accountName: '',
            Contact: {
                FirstName: '',
                LastName: '',
                Email: '',
                Phone: '',
                Title: '',
                PortalAccess: '',
                OwnershipPercentage: null
            },
            roles: this.modalMode === 'TPA'
                ? ['Third Party Administrator']
                : []
        };
    }

    handleModalSave(){
        if (!this.validateOwnershipInputRealtime()) {
            const ownershipInput =
                this.template.querySelector('lightning-input[data-name="OwnershipPercentage"]') ||
                this.template.querySelector('lightning-input[data-field="OwnershipPercentage"]');

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: ownershipInput?.validationMessage || 'Review the Ownership % value before saving.',
                    variant: 'error'
                })
            );
            return;
        }

        if (!this.validateModalInputs()) {
            return;
        }

        const newRow = this.buildNewRowFromDraft(
            this.contactDraft,
            this.modalMode // OTHER | TPA
        );
        if (this.modalMode === 'OTHER') {
            this.tableDataOC = [...this.tableDataOC, newRow];
        }
    
        if (this.modalMode === 'TPA') {
            this.tableDataTPA = [...this.tableDataTPA, newRow];
        }
    
        this.closeContactModal();
    }

    async openReusableTPAModalForNew() {
        const modal = this.template.querySelector('c-a-r-c_-t-p-a-modal');
        if (!modal) {
            // If this happens, the modal wasn't added to the HTML
            return;
        }
        const result = await modal.open({ mode: 'new' });
        if (!result || result.action !== 'save') return;
    
        // Map modal result -> our row draft structure (UI only)
        const draft = this.mapTPAModalResultToDraft(result.tpa);
    
        // Create a new DRAFT_NEW row in our table
        const tempId = crypto.randomUUID();
    
        const newRow = this.decorateRowState({
            Id: tempId,
            accountName: draft.companyName || '',
            contactName: `${draft.firstName || ''} ${draft.lastName || ''}`.trim(),
            portalAccess: draft.portalAccess || '',
            email: draft.email || '',
            phone: draft.phone || '',
            _source: 'TPA',
            _state: ContactRowState.DRAFT_NEW,
            _originalRow: null,
            _draftContactOC: {
                action: 'CREATE',
                accountId: this.accountId, // keep your existing behavior for now
                Contact: {
                    Id: null,
                    FirstName: draft.firstName || '',
                    LastName: draft.lastName || '',
                    Email: draft.email || '',
                    Phone: draft.phone || '',
                    Title: '', // modal doesn't provide Title
                    PortalAccess: draft.portalAccess || ''
                },
                roles: ['Third Party Administrator'],
    
                // Extra UI-only fields (safe to keep here)
                tpaUi: {
                    useExistingAccount: !!draft.useExistingAccount,
                    accountId: draft.accountId || null,
                    companyName: draft.companyName || '',
                    mailingAddress: draft.mailingAddress || '',
                    city: draft.city || '',
                    state: draft.state || '',
                    zip: draft.zip || ''
                }
            }
        });
        this.tableDataTPA = [...this.tableDataTPA, newRow];
    }

    validateModalInputs() {
        const inputs = this.template.querySelectorAll(
            'lightning-input, lightning-combobox'
        );
    
        let isValid = true;
    
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });
    
        return isValid;
    }

    handleNewContactInput(event){
        const field = event.target.dataset.field;
        let value = event.detail?.value ?? event.target.value;
        const input = event.target;

        if (!field) return;

        if (field === 'roles') {
            this.contactDraft = {
                ...this.contactDraft,
                roles: Array.isArray(value) ? value : []
            };
            requestAnimationFrame(() => this.validateOwnershipInputRealtime());
            return;
        }

        if (field === 'Phone') {
            const digits = (value || '').replace(/\D/g, '').slice(0, 10);

            this.contactDraft = {
                ...this.contactDraft,
                Contact: {
                    ...this.contactDraft.Contact,
                    [field]: digits
                }
            };

            input.value = this.formatPhoneFromDigits(digits);
            return;   
        }

        if (field === 'OwnershipPercentage') {
            value = this.normalizeOwnershipPercentage(value);
        }

        this.contactDraft = {
            ...this.contactDraft,
            Contact: {
                ...this.contactDraft.Contact,
                [field]: value
            }
        };

        this.validateOwnershipInputRealtime();
    }

    closeContactModal(){
        this.isContactModalOpen = false;
    }

    @api
    refreshData() {
        if (this.wiredContactResult) {
            refreshApex(this.wiredContactResult);
        }
    }

    resetToOriginal(){
        this.companyOfficerSameAsPrimaryBusinessContact = 'Yes';
        this.sameCompanyOfficer = true;
        this.selectSameCompanyOfficer = false;
        this.isEdit = false;

        this.selectedRow = null;
        this.selectedTableRowId = null;
        this.draftContactOC = null;
    }

    normalizeContactFromServer(acr){
        const c = acr?.Contact || {};

        return {
            ...acr,
            roles: this.normalizeRoles(acr.Roles),
            Contact: {
                ...c,
                PortalAccess: c.ARC_PortalAccess__c ?? c.PortalAccess ?? '',
                OwnershipPercentage: c.ARC_OwnershipPercentage__c ?? c.OwnershipPercentage ?? null
            }
        };
    }

    normalizeRoles(roles){
        if (!roles) return [];
        //if (!roles) return '';
        if (Array.isArray(roles)) {
            return roles
                .filter(r => r && r.trim())
                .map(r => r.trim());
        }

        if (typeof roles === 'string') {
            return roles
                .split(/[,;]+/)
                .map(r => r.trim())
                .filter(r => r);
        }

        return '';
    }

    formatRolesForDisplay(roles, ownershipPercentage = null) {
        const normalizedRoles = this.normalizeRoles(roles);
        if (!Array.isArray(normalizedRoles) || normalizedRoles.length === 0) {
            return '';
        }
    
        return normalizedRoles
            .map(role => {
                if (role === 'Ownership' && ownershipPercentage !== null && ownershipPercentage !== undefined && ownershipPercentage !== '') {
                    return `Ownership (${Number(ownershipPercentage)}%)`;
                }
                return role;
            })
            .join(', ');
    }

    get showEditOwnershipField() {
        return this.rowHasOwnershipRole(this.draftContactOC?.roles);
    }
    
    get showNewOwnershipField() {
        return this.rowHasOwnershipRole(this.contactDraft?.roles);
    }
    
    rowHasOwnershipRole(roles) {
        return this.normalizeRoles(roles).includes('Ownership');
    }
    
    normalizeOwnershipPercentage(value) {
        if (value === null || value === undefined || value === '') {
            return null;
        }
    
        const numericValue = Number(value);
        if (Number.isNaN(numericValue)) {
            return null;
        }
    
        //return Number(numericValue.toFixed(2));
        return numericValue;
    }
    
    formatOwnershipPercentage(value) {
        if (value === null || value === undefined || value === '') {
            return '';
        }
        return `${Number(value)}%`;
    }
    
    calculateOwnershipTotal({ excludeRowId = null, draftRoles = null, draftOwnershipPercentage = null } = {}) {
        let total = 0;
    
        (this.tableDataOC || []).forEach(row => {
            if (!row || row._state === ContactRowState.PENDING_DELETE) {
                return;
            }
    
            if (excludeRowId && row.Id === excludeRowId) {
                return;
            }
    
            const source =
                row._state === ContactRowState.DRAFT_NEW || row._state === ContactRowState.DRAFT_EDIT
                    ? row._draftContactOC
                    : row._originalRow;
    
            const roles = this.normalizeRoles(source?.roles ?? source?.Roles);
            if (!roles.includes('Ownership')) {
                return;
            }
    
            const percentage = Number(
                source?.Contact?.OwnershipPercentage ??
                source?.Contact?.ARC_OwnershipPercentage__c ??
                0
            );
    
            if (!Number.isNaN(percentage)) {
                total += percentage;
            }
        });
    
        if (this.rowHasOwnershipRole(draftRoles)) {
            const currentDraftValue = Number(draftOwnershipPercentage ?? 0);
            if (!Number.isNaN(currentDraftValue)) {
                total += currentDraftValue;
            }
        }
    
        return Number(total.toFixed(2));
    }

    getOwnershipContactsCount() {
        let count = 0;
    
        (this.tableDataOC || []).forEach(row => {
            if (!row || row._state === ContactRowState.PENDING_DELETE) {
                return;
            }
    
            const source =
                row._state === ContactRowState.DRAFT_NEW || row._state === ContactRowState.DRAFT_EDIT
                    ? row._draftContactOC
                    : row._originalRow;
    
            const roles = this.normalizeRoles(source?.roles ?? source?.Roles);
            if (roles.includes('Ownership')) {
                count += 1;
            }
        });
    
        return count;
    }
    
    validateOwnershipTotalOnSave() {
        const ownershipContactsCount = this.getOwnershipContactsCount();
        if (ownershipContactsCount === 0) {
            return { isValid: true, total: 0 };
        }
    
        const total = this.calculateOwnershipTotal();
        if (total !== 100) {
            return {
                isValid: false,
                total,
                message: `The total Ownership % across all Ownership contacts must equal 100%. Current total: ${total}%.`
            };
        }
    
        return { isValid: true, total };
    }
    
    validateOwnershipInputRealtime() {
        const activeInput =
            this.template.querySelector('lightning-input[data-name="OwnershipPercentage"]') ||
            this.template.querySelector('lightning-input[data-field="OwnershipPercentage"]');
    
        if (!activeInput) {
            return true;
        }
    
        const editInput = this.template.querySelector('lightning-input[data-name="OwnershipPercentage"]');
        const newInput = this.template.querySelector('lightning-input[data-field="OwnershipPercentage"]');
        const isEditModal = !!editInput && !newInput;
        const draft = isEditModal ? this.draftContactOC : this.contactDraft;
        const roles = draft?.roles;
        const ownershipValue = draft?.Contact?.OwnershipPercentage;
    
        if (!this.rowHasOwnershipRole(roles)) {
            activeInput.setCustomValidity('');
            activeInput.reportValidity();
            return true;
        }
    
        if (ownershipValue === null || ownershipValue === undefined || ownershipValue === '') {
            activeInput.setCustomValidity('Ownership % is required when the contact has the Ownership role.');
            activeInput.reportValidity();
            return false;
        }
    
        const numericValue = Number(ownershipValue);
    
        if (Number.isNaN(numericValue)) {
            activeInput.setCustomValidity('Ownership % must be a valid number.');
            activeInput.reportValidity();
            return false;
        }
    
        if (!Number.isInteger(numericValue)) {
            activeInput.setCustomValidity('Ownership % must be a whole number.');
            activeInput.reportValidity();
            return false;
        }
    
        if (numericValue <= 0) {
            activeInput.setCustomValidity('Ownership % must be greater than 0.');
            activeInput.reportValidity();
            return false;
        }
    
        if (numericValue > 100) {
            activeInput.setCustomValidity('Ownership % cannot be greater than 100.');
            activeInput.reportValidity();
            return false;
        }
    
        const total = this.calculateOwnershipTotal({
            excludeRowId: isEditModal ? this.selectedTableRowId : null,
            draftRoles: roles,
            draftOwnershipPercentage: numericValue
        });
    
        if (total > 100) {
            activeInput.setCustomValidity('The total Ownership % for all Ownership contacts cannot exceed 100.');
            activeInput.reportValidity();
            return false;
        }
    
        activeInput.setCustomValidity('');
        activeInput.reportValidity();
        return true;
    }

    @api
    getDraftForSave() {
        const create = [];
        const update = [];
        const del = [];

        const roleValidation = this.validateUniqueRolesBeforeSave();
        if (!roleValidation.isValid) {
            //this.showToast('Validation Error', roleValidation.message, 'error');
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: roleValidation.message,
                    variant: 'error'
                })
            );
            return;
        }

        const ownershipValidation = this.validateOwnershipTotalOnSave();
        if (!ownershipValidation.isValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: ownershipValidation.message,
                    variant: 'error'
                })
            );
            return;
        }

        if (this._pendingDeletes?.length) {
            del.push(...this._pendingDeletes);
        }
        // ============================
        // Company Officer
        // ============================
        this.collectCompanyOfficerDraft({ create, update });
        // ============================
        // Tables (OTHER + TPA)
        // ============================
        const normalizeContact = (contact) => {
            if (!contact) return contact;
        
            const c = {... contact};

            if (!c.PortalAccess && c.ARC_PortalAccess__c) {
                c.PortalAccess = c.ARC_PortalAccess__c;
            }

            delete c.ARC_PortalAccess__c;

            if (c.OwnershipPercentage !== undefined) {
                c.ContactOwnershipPercentage = c.OwnershipPercentage;
            }
            
            delete c.OwnershipPercentage;
            delete c.ARC_OwnershipPercentage__c;
        
            return c;
        };

        const processTables = (table) => {
            (table || []).forEach(row => {
                switch (row._state) {
                    case ContactRowState.DRAFT_NEW:
                        create.push({
                            ...row._draftContactOC,
                            roles: this.normalizeRoles(row._draftContactOC.roles),
                            Contact: normalizeContact(row._draftContactOC.Contact)
                        });
                        break;

                    case ContactRowState.DRAFT_EDIT:
                        const clean = {...row._draftContactOC};
                        update.push({
                            ...clean,
                            roles: this.normalizeRoles(clean.roles),
                            Contact: normalizeContact(clean.Contact)
                        });
                        break;

                    case ContactRowState.PENDING_DELETE:
                        del.push({
                            contactId: row._originalRow?.Contact?.Id,
                            acrId: row._originalRow?.Id
                        });
                        break;
                }
            });
        };

        processTables(this.tableDataOC);
        processTables(this.tableDataTPA);
        return { create, update, delete: del };
    }

    handlePhoneEmailInput() {
        const email = this.template.querySelector('lightning-input[data-name="Email"]');
        const phone = this.template.querySelector('lightning-input[data-name="Phone"]');

        if (phone) {
            const raw = phone.value || '';
            const digits = raw.replace(/\D/g, '').slice(0, 10); // keep 10 digits max

            // 1) Save clean digits in draft object (single source of truth)
            this.companyOfficerDraft  = {
                ...this.companyOfficerDraft ,
                Contact: {
                    ...this.companyOfficerDraft.Contact,
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

    handlePhoneBlurNewContact(event) {
        const input = event.target;
        const raw = input.value || '';
        const digits = raw.replace(/\D/g, '').slice(0, 10);
    
        input.value = this.formatPhoneFromDigits(digits);
    
        input.setCustomValidity(
            digits.length === 0 || digits.length === 10
                ? ''
                : 'Enter a 10-digit phone number'
        );
    
        input.reportValidity();
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
        const raw = this.companyOfficerDraft?.Contact?.Phone || '';
        // normalize no matter what
        return this.formatPhoneFromDigits(this.normalizePhone(raw));
    }

    get formattedDraftContactPhone() {
        const raw = this.draftContactOC?.Contact?.Phone || '';
        return this.formatPhoneFromDigits(this.normalizePhone(raw));
    }

    buildCompanyOfficerDraftFromAcr(selected) {
        if (!selected) return null;
    
        return {
            action: 'SELECT',
            accountId: selected.AccountId,
            contactId: selected.ContactId,
            dirty: false,
            Contact: {
                Id: selected.ContactId,
                FirstName: selected.Contact?.FirstName || '',
                LastName: selected.Contact?.LastName || '',
                Email: selected.Contact?.Email || '',
                Phone: selected.Contact?.Phone || '',
                Title: selected.Contact?.Title || '',
                PortalAccess: selected.Contact?.ARC_PortalAccess__c || ''
            },
            //roles: ['Company Officer Contact']
            roles: this.mergeRoles(selected.roles ?? selected.Roles, 'Company Officer Contact')
        };
    }

    initializeCompanyOfficerDraft() {
        const selected = this._fullContactList.find(acr =>
            acr.Roles && acr.Roles.includes('Company Officer Contact')
        );
    
        if (!selected) return;
    
        this.selectedExistingContactId = selected.ContactId;
        this.companyOfficerDraft = this.buildCompanyOfficerDraftFromAcr(selected);
        this.selectedPortalAccessCompOfficer = this.companyOfficerDraft.Contact.PortalAccess;
    }
}