import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import getPrimaryBusinessContact from '@salesforce/apex/ARC_CompanyContactSectionController.getPrimaryBusinessContact';
import getCompanyOfficerContact from '@salesforce/apex/ARC_CompanyContactSectionController.getCompanyOfficerContact';
import getOtherContacts from '@salesforce/apex/ARC_CompanyContactSectionController.getOtherContacts';
import getTPAContacts from '@salesforce/apex/ARC_CompanyContactSectionController.getTPAContacts';
import getAccountHolderContact from '@salesforce/apex/ARC_CompanyContactSectionController.getAccountHolderContact';
import getBillingContact from '@salesforce/apex/ARC_CompanyContactSectionController.getBillingContact';
import getOwnerContacts from '@salesforce/apex/ARC_CompanyContactSectionController.getOwnerContacts';
import saveContactSection from '@salesforce/apex/ARC_BusinessFormController.saveContactSection';
import sendEmailForCompanyContactChanges from '@salesforce/apex/ARC_SGEmails.sendEmailForCompanyContactChanges';
import checkDeletePermissions from '@salesforce/apex/ARC_BusinessFormController.checkDeletePermissions';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';
import {refreshApex} from '@salesforce/apex';

/**
 * ARC_CompanyContactSection - Self-contained Company Contacts section
 * 
 * @description Handles company contacts collection including:
 *              - Primary Business Contact
 *              - Company Officer Contact
 *              - Other Contacts
 *              - Third Party Administrators (TPA)
 * 
 * Events:
 *   - change: Fired when any field changes { detail: { section, data } }
 *   - save: Fired after save attempt { detail: { section, data, isValid, errors } }
 */
export default class ARC_CompanyContactSection extends LightningElement {
    /** @api Record Id (Opportunity Id) from parent */
    @api recordId;

    /** @api Set to true when embedded in a community page (no recordId available) */
    @api isCommunity = false;

    @track _communityAccountId = null;
    @track _userProfile = null;
    @track isSaving = false;
    @track isSaved = false;
    @track isSavingOtherContact = false;
    @track isSavingTPA = false;
    @track isSavingOwnership = false;
    @track isSavedOtherContact = false;
    @track isSavedTPA = false;
    @track isSavedOwnership = false;
    @track sectionStatus = 'not-started';
    @track isLoading = true;
    @track loadError = null;

    // Original state memory for comparing changes
    _originalPrimary = null;
    _originalOfficer = null;
    _originalAccHolder = null;
    _originalBillContact = null;
    _originalOther = [];
    _originalTpas = [];
    _originalOwnership = [];

    // Custom icon URLs for section and subsections
    sectionIconUrl = `${SGFormIcons}/contactBook.svg`;
    primaryContactIconUrl = `${SGFormIcons}/primaryContact.svg#primaryContact`;
    companyOfficerIconUrl = `${SGFormIcons}/companyOfficer.svg#companyOfficer`;
    otherContactsIconUrl = `${SGFormIcons}/otherContacts.svg#otherContacts`;
    tpaIconUrl = `${SGFormIcons}/tpa.svg#tpa`;

    // ═══════════════════════════════════════════════════════════════════════
    // STATIC OPTIONS (Reusable across sections)
    // ═══════════════════════════════════════════════════════════════════════

    portalAccessOptions = [
        { label: 'No Access', value: 'No Access' },
        { label: 'Viewer', value: 'Viewer' },
        { label: 'Admin', value: 'Admin' }
    ];

    contactMethodOptions = [
        { label: 'Select Existing Contact', value: 'existing' },
        { label: 'Create New Contact', value: 'new' }
    ];

    yesNoOptions = [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
    ];
    
    // ═══════════════════════════════════════════════════════════════════════
    // PRIMARY BUSINESS CONTACT
    // ═══════════════════════════════════════════════════════════════════════
    
    @track primaryContact = {
        id: null,
        contactId: null,
        acrId: null,
        firstName: '',
        lastName: '',
        title: '',
        email: '',
        phone: '',
        street: '',
        city: '',
        state: '',
        zip: '',
        portalAccess: '',
        roles: ''
    };

    @track isEditingPrimaryContact = false;
    @track primaryContactMethod = 'existing';
    @track newPrimaryContact = { firstName: '', lastName: '', title: '', email: '', phone: '', street: '', city: '', state: '', zip: '' };
    // Backup for undo functionality
    primaryContactBackup = null;

    // ═══════════════════════════════════════════════════════════════════════
    // COMPANY OFFICER CONTACT
    // ═══════════════════════════════════════════════════════════════════════
    
    @track officerSameAsPrimary = true;
    @track officerContactMethod = 'existing';
    @track officerPortalAccess = '';
    @track officerContact = { contactId: null, acrId: null, firstName: '', lastName: '', title: '', email: '', phone: '', street: '', city: '', state: '', zip: '', portalAccess: '', roles: '' };
    @track newOfficerContact = { firstName: '', lastName: '', title: '', email: '', phone: '', street: '', city: '', state: '', zip: '' };
    @track isEditingOfficerContact = false;
    // Backup for undo functionality
    officerContactBackup = null;
    officerSameAsPrimaryBackup = null;

    // ═══════════════════════════════════════════════════════════════════════
    // OTHER CONTACTS
    // ═══════════════════════════════════════════════════════════════════════
    
    @track otherContacts = [];
    @track otherContactsToDelete = []; // Track contacts marked for deletion

    otherContactColumns = [
        { label: 'Name', fieldName: 'fullName', type: 'name-with-icon' },
        { label: 'Title', fieldName: 'title', type: 'text' },
        { label: 'Email', fieldName: 'email', type: 'text' },
        { label: 'Portal Access', fieldName: 'portalAccess', type: 'badge' }
    ];

    // ═══════════════════════════════════════════════════════════════════════
    // THIRD PARTY ADMINISTRATORS
    // ═══════════════════════════════════════════════════════════════════════
    
    @track tpaList = [];
    @track tpasToDelete = []; // Track TPAs marked for deletion

    tpaColumns = [
        { label: 'TPA Company Name', fieldName: 'companyName', type: 'text' },
        { label: 'Mailing Address', fieldName: 'mailingAddress', type: 'text' },
        { label: 'City', fieldName: 'city', type: 'text' },
        { label: 'State', fieldName: 'state', type: 'text' },
        { label: 'Zip', fieldName: 'zip', type: 'text' },
        { label: 'Contact Name', fieldName: 'contactName', type: 'text' },
        { label: 'Phone', fieldName: 'phone', type: 'text' },
        { label: 'Email', fieldName: 'email', type: 'text' },
        { label: 'Portal Access', fieldName: 'portalAccess', type: 'badge' }
    ];

    // ═══════════════════════════════════════════════════════════════════════
    // ACCOUNT HOLDER CONTACT (Account mode only)
    // ═══════════════════════════════════════════════════════════════════════

    @track accountHolderContact = { id: null, contactId: null, acrId: null, firstName: '', lastName: '', title: '', email: '', phone: '', street: '', city: '', state: '', zip: '', portalAccess: '', roles: '' };
    @track isEditingAccountHolder = false;
    @track accountHolderContactMethod = 'existing';
    @track newAccountHolderContact = { firstName: '', lastName: '', title: '', email: '', phone: '', street: '', city: '', state: '', zip: '' };
    accountHolderBackup = null;

    // ═══════════════════════════════════════════════════════════════════════
    // BILLING CONTACT (Account mode only)
    // ═══════════════════════════════════════════════════════════════════════

    @track billingContact = { id: null, contactId: null, acrId: null, firstName: '', lastName: '', title: '', email: '', phone: '', street: '', city: '', state: '', zip: '', portalAccess: '', roles: '' };
    @track billingContactPortalAccess = '';
    @track isEditingBillingContact = false;
    @track billingContactMethod = 'existing';
    @track newBillingContact = { firstName: '', lastName: '', title: '', email: '', phone: '', street: '', city: '', state: '', zip: '' };
    billingContactBackup = null;

    @track accountHolderSameAsPrimary = false;
    @track billingSameAsAccountHolder = false;

    // ═══════════════════════════════════════════════════════════════════════
    // OWNERSHIP CONTACTS (Account mode only)
    // ═══════════════════════════════════════════════════════════════════════

    @track ownershipContacts = [];
    @track ownershipContactsToRemoveRole = [];

    ownershipColumns = [
        { label: 'Name', fieldName: 'fullName', type: 'name-with-icon' },
        { label: 'Title', fieldName: 'title', type: 'text' },
        { label: 'Email', fieldName: 'email', type: 'text' },
        { label: 'Ownership %', fieldName: 'ownershipPercentage', type: 'text' },
        { label: 'Portal Access', fieldName: 'portalAccess', type: 'badge' }
    ];

    // ═══════════════════════════════════════════════════════════════════════
    // WIRE ADAPTERS - Data Loading
    // ═══════════════════════════════════════════════════════════════════════

    @wire(getRecord, { recordId: USER_ID, fields: ['User.AccountId', 'User.Profile.Name'] })
    wiredCommunityAccountId({ data, error }) {
        if (data) {
            if (this.isCommunity) {
                this._communityAccountId = data.fields.AccountId.value;
            }
            this._userProfile = data.fields.Profile.value?.fields.Name.value;
        } else if (error) {
            console.error('Error loading user record:', error);
        }
    }

    @wire(getPrimaryBusinessContact, { opportunityId: '$effectiveRecordId' })
    wiredPrimaryContact({ error, data }) {
        if (data && data.contact) {
            this.primaryContact = this.mapContactData(data);
            this._originalPrimary = { ...this.primaryContact }; // Save original primary contact data
            this.checkIfOfficerSameAsPrimary();
            this.updateSectionStatus();
        } else if (error) {
            console.error('Error loading primary contact:', error);
        }
    }

    @wire(getCompanyOfficerContact, { opportunityId: '$effectiveRecordId' })
    wiredOfficerContact({ error, data }) {
        if (data && data.contact) {
            this.officerContact = this.mapContactData(data);
            this.officerPortalAccess = data.portalAccess || '';
            this._originalOfficer = { ...this.officerContact, portalAccess: this.officerPortalAccess }; // Save original company officer contact data
            this.checkIfOfficerSameAsPrimary();
            this.updateSectionStatus();
        } else if (error) {
            console.error('Error loading officer contact:', error);
        }
    }
    wiredOtherContactsVar
    @wire(getOtherContacts, { opportunityId: '$effectiveRecordId' })
    wiredOtherContacts(retrieved) {
        this.wiredOtherContactsVar = retrieved
        const { error, data } = retrieved;
        if (data) {
            this.isLoading = false;
            this.otherContacts = data.map(contact => ({
                id: contact.Id,
                contactId: contact.Id,
                firstName: contact.FirstName || '',
                lastName: contact.LastName || '',
                title: contact.Title || '',
                email: contact.Email || '',
                phone: this.formatPhone(contact.Phone),
                street: contact.MailingStreet || '',
                city: contact.MailingCity || '',
                state: contact.MailingState || '',
                zip: contact.MailingPostalCode || '',
                portalAccess: contact.ARC_PortalAccess__c || '',
                isNew: false,
                isModified: false
            }));
            this._originalOther = JSON.parse(JSON.stringify(this.otherContacts)); // Save original other contacts data
            this.updateSectionStatus();
        } else if (error) {
            this.isLoading = false;
            console.error('Error loading other contacts:', error);
        }
    }

    @wire(getTPAContacts, { opportunityId: '$effectiveRecordId' })
    wiredTPAContacts({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.tpaList = data.map(tpa => ({
                id: tpa.id || tpa.contactId,
                accountId: tpa.accountId,
                contactId: tpa.contactId,
                companyName: tpa.companyName || '',
                contactName: tpa.contactName || '',
                firstName: tpa.firstName || '',
                lastName: tpa.lastName || '',
                email: tpa.email || '',
                phone: this.formatPhone(tpa.phone),
                mailingAddress: tpa.mailingAddress || '',
                city: tpa.city || '',
                state: tpa.state || '',
                zip: tpa.zip || '',
                portalAccess: tpa.portalAccess || 'No Access',
                isNew: false,
                isModified: false
            }));
            this._originalTpas = JSON.parse(JSON.stringify(this.tpaList)); // Save original TPA contacts data
            this.updateSectionStatus();
        } else if (error) {
            console.error('Error loading TPA contacts:', error);
        }
    }

    @wire(getAccountHolderContact, { opportunityId: '$effectiveRecordId' })
    wiredAccountHolder({ error, data }) {
        if (data && data.contact) {
            this.accountHolderContact = this.mapContactData(data);
            this.accountHolderPortalAccess = data.portalAccess || '';
            this._originalAccHolder = { ...this.accountHolderContact, portalAccess: this.accountHolderPortalAccess }; // Save original Account Holder contact data
            // Auto-detect same-as-primary
            if (this.primaryContact.contactId && this.accountHolderContact.contactId === this.primaryContact.contactId) {
                this.accountHolderSameAsPrimary = true;
            }
        } else if (error) {
            console.error('Error loading account holder:', error);
        }
    }

    @wire(getBillingContact, { opportunityId: '$effectiveRecordId' })
    wiredBillingContact({ error, data }) {
        if (data && data.contact) {
            this.billingContact = this.mapContactData(data);
            this.billingContactPortalAccess = data.portalAccess || '';
            this._originalBillContact = { ...this.billingContact, portalAccess: this.billingContactPortalAccess }; // Save original Billing contact data
            // Auto-detect same-as-account-holder
            if (this.accountHolderContact.contactId && this.billingContact.contactId === this.accountHolderContact.contactId) {
                this.billingSameAsAccountHolder = true;
            }
        } else if (error) {
            console.error('Error loading billing contact:', error);
        }
    }

    @wire(getOwnerContacts, { opportunityId: '$effectiveRecordId' })
    wiredOwnershipContacts({ error, data }) {
        if (data) {
            const owners = data.owners || [];
            this.ownershipContacts = owners.map(o => ({
                id: o.contactId,
                contactId: o.contactId,
                firstName: o.firstName || '',
                lastName: o.lastName || '',
                middleInitial: o.middleInitial || '',
                title: '',
                email: o.email || '',
                phone: this.formatPhone(o.phone),
                ownershipPercentage: o.ownershipPercentage || '',
                isEligible: o.isEligible || false,
                portalAccess: o.portalAccess || '',
                isNew: false,
                isModified: false
            }));
            this._originalOwnership = JSON.parse(JSON.stringify(this.ownershipContacts)); // Save original Ownership contacts data
        } else if (error) {
            console.error('Error loading ownership contacts:', error);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS (Computed Properties)
    // ═══════════════════════════════════════════════════════════════════════

    @api
    get status() {
        return this.sectionStatus;
    }

    get effectiveRecordId() {
        return this.isCommunity ? this._communityAccountId : this.recordId;
    }

    /** In community, only Employer Admin can edit. Outside community, always editable. */
    get canEdit() {
        if (!this.isCommunity) return true;
        return this._userProfile === 'Employer Admin';
    }

    get isReadOnly() {
        return !this.canEdit;
    }

    get hideStatusBadge() {
        const id = this.effectiveRecordId;
        return id && String(id).startsWith('001');
    }

    // In community, always open immediately (isCommunity is known at mount).
    // In record page, open once we confirm account mode.
    get shouldStartOpen() {
        return this.isCommunity || this.hideStatusBadge;
    }

    get contentClass() {
        return this.isCommunity ? 'community-mode' : '';
    }

    get isAccountMode() {
        const id = this.effectiveRecordId;
        return id && String(id).startsWith('001');
    }

    get accountHolderSameAsPrimaryValue() {
        return this.accountHolderSameAsPrimary ? 'yes' : 'no';
    }

    get billingSameAsAccountHolderValue() {
        return this.billingSameAsAccountHolder ? 'yes' : 'no';
    }

    // Account Holder getters
    get hasAccountHolder() {
        return !!(this.accountHolderContact.contactId || this.accountHolderContact.firstName);
    }

    get showAccountHolderDisplay() {
        return !this.accountHolderSameAsPrimary && this.hasAccountHolder && !this.isEditingAccountHolder;
    }

    get showAccountHolderEdit() {
        return !this.accountHolderSameAsPrimary && (this.isEditingAccountHolder || !this.hasAccountHolder);
    }

    get showAccountHolderLookup() {
        return this.showAccountHolderEdit && this.accountHolderContactMethod === 'existing';
    }

    get showAccountHolderEditFields() {
        return this.accountHolderContactMethod === 'existing' && this.accountHolderContact.contactId;
    }

    get showNewAccountHolderFields() {
        return this.showAccountHolderEdit && this.accountHolderContactMethod === 'new';
    }

    // Billing Contact getters
    get hasBillingContact() {
        return !!(this.billingContact.contactId || this.billingContact.firstName);
    }

    get showBillingContactDisplay() {
        return !this.billingSameAsAccountHolder && this.hasBillingContact && !this.isEditingBillingContact;
    }

    get showBillingContactEdit() {
        return !this.billingSameAsAccountHolder && (this.isEditingBillingContact || !this.hasBillingContact);
    }

    get showBillingContactLookup() {
        return this.showBillingContactEdit && this.billingContactMethod === 'existing';
    }

    get showBillingContactEditFields() {
        return this.billingContactMethod === 'existing' && this.billingContact.contactId;
    }

    get showNewBillingContactFields() {
        return this.showBillingContactEdit && this.billingContactMethod === 'new';
    }

    // Ownership getters
    get ownershipContactsWithFullName() {
        return this.ownershipContacts.map(c => ({
            ...c,
            fullName: `${c.firstName} ${c.lastName}`
        }));
    }

    get totalOwnershipPercentage() {
        return this.ownershipContacts.reduce((sum, c) => sum + (c.ownershipPercentage || 0), 0);
    }

    get isOwnershipOverAllocated() {
        return this.totalOwnershipPercentage > 100;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPER METHODS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Set status to in-progress when user starts editing (if not already complete)
     */
    setInProgress() {
        if (this.sectionStatus !== 'complete') {
            this.sectionStatus = 'in-progress';
        }
    }

    /**
     * Update section status based on loaded data
     */
    updateSectionStatus() {
        if (this.isComplete()) {
            this.sectionStatus = 'complete';
        } else if (this.hasPrimaryContact || this.hasOfficerContact || this.otherContacts.length > 0 || this.tpaList.length > 0) {
            this.sectionStatus = 'in-progress';
        } else {
            this.sectionStatus = 'not-started';
        }
    }

    /**
     * @api Refresh Other Contacts list from server
     * Called after save to reflect role changes (e.g., Primary→Other or Other→Primary)
     */
    @api
    async refreshOtherContacts() {
        try {
            await refreshApex(this.wiredOtherContactsVar);
        } catch (error) {
            console.error('Error refreshing other contacts:', error);
        }
    }

    // Primary Contact
    get hasPrimaryContact() {
        // Check existing contact OR new contact fields
        const hasExisting = this.primaryContact.contactId || this.primaryContact.firstName;
        const hasNew = this.primaryContactMethod === 'new' && 
                      (this.newPrimaryContact.firstName || this.newPrimaryContact.lastName || this.newPrimaryContact.email);
        return hasExisting || hasNew;
    }

    get showPrimaryContactDisplay() {
        return this.hasPrimaryContact && !this.isEditingPrimaryContact;
    }

    /**
     * Shows edit UI when:
     * 1. User clicked "Change" to edit existing contact
     * 2. There's no primary contact yet (initial state)
     */
    get showPrimaryContactEdit() {
        return this.isEditingPrimaryContact || !this.hasPrimaryContact;
    }

    get isExistingContactMethod() {
        return this.primaryContactMethod === 'existing';
    }

    get isNewContactMethod() {
        return this.primaryContactMethod === 'new';
    }

    get showPrimaryContactLookup() {
        // Show lookup when: editing AND method=existing (to allow changing selection)
        return this.showPrimaryContactEdit && this.primaryContactMethod === 'existing';
    }

    get showPrimaryContactEditFields() {
        return this.primaryContactMethod === 'existing' && this.primaryContact.contactId;
    }

    get showNewContactFields() {
        const shouldShow = this.showPrimaryContactEdit && this.primaryContactMethod === 'new';
        return shouldShow;
    }

    get showInitialLookup() {
        // Never show just the lookup - always show full edit UI
        return false;
    }

    get currentPrimaryContactFields() {
        // Return the appropriate contact data based on method
        if (this.primaryContactMethod === 'new') {
            return this.newPrimaryContact;
        }
        return this.primaryContact;
    }

    // Company Officer
    get officerSameAsPrimaryValue() {
        return this.officerSameAsPrimary ? 'yes' : 'no';
    }

    get hasOfficerContact() {
        // Check existing contact OR new contact fields
        const hasExisting = this.officerContact.contactId || this.officerContact.firstName;
        const hasNew = this.officerContactMethod === 'new' && 
                      (this.newOfficerContact.firstName || this.newOfficerContact.lastName || this.newOfficerContact.email);
        return hasExisting || hasNew;
    }

    get showOfficerContactDisplay() {
        // Show officer card when: not same as primary AND has officer contact AND not editing
        return !this.officerSameAsPrimary && this.hasOfficerContact && !this.isEditingOfficerContact;
    }

    get showOfficerContactEdit() {
        return this.isEditingOfficerContact;
    }

    get showOfficerSelection() {
        // Show selection options when editing OR when no officer contact yet (and not same as primary)
        return !this.officerSameAsPrimary && (!this.hasOfficerContact || this.isEditingOfficerContact);
    }

    get showOfficerLookup() {
        // Show lookup when: in selection mode AND method=existing (to allow changing selection)
        return this.showOfficerSelection && this.officerContactMethod === 'existing';
    }

    get showOfficerEditFields() {
        // Don't show edit fields separately - lookup handles the contact display
        return this.officerContactMethod === 'existing' && this.officerContact.contactId;
    }

    get showNewOfficerContactFields() {
        // Show new contact fields when: in selection mode AND method=new
        return this.showOfficerSelection && this.officerContactMethod === 'new';
    }

    get isOfficerMethodExisting() {
        return this.officerContactMethod === 'existing';
    }

    get officerContactData() {
        if (this.officerContactMethod === 'new') {
            return this.newOfficerContact;
        }
        return this.officerContact;
    }

    // Other Contacts
    get hasOtherContacts() {
        return this.otherContacts.length > 0;
    }

    get otherContactsCount() {
        return this.otherContacts.length;
    }

    get otherContactsWithFullName() {
        return this.otherContacts.map(contact => ({
            ...contact,
            fullName: `${contact.firstName} ${contact.lastName}`
        }));
    }

    // TPAs
    get hasTPAs() {
        return this.tpaList.length > 0;
    }

    get tpaCount() {
        return this.tpaList.length;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API METHODS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @api Expand this section programmatically
     */
    @api
    expand() {
        const collapsibleSection = this.template.querySelector('c-a-r-c_-collapsible-section');
        if (collapsibleSection && typeof collapsibleSection.expand === 'function') {
            collapsibleSection.expand();
        }
    }

    /**
     * @api Get current section data
     * @returns {Object} All contacts data
     */
    @api
    getData() {
        return {
            primaryContact: { ...this.primaryContact },
            primaryContactMethod: this.primaryContactMethod,
            newPrimaryContact: { ...this.newPrimaryContact },
            officerSameAsPrimary: this.officerSameAsPrimary,
            officerContactMethod: this.officerContactMethod,
            officerPortalAccess: this.officerPortalAccess,
            officerContact: { ...this.officerContact },
            newOfficerContact: { ...this.newOfficerContact },
            otherContacts: [...this.otherContacts],
            tpaList: [...this.tpaList]
        };
    }

    /**
     * @api Set section data
     * @param {Object} data - Contact data to set
     */
    @api
    setData(data) {
        if (data) {
            if (data.primaryContact) {
                this.primaryContact = { ...this.primaryContact, ...data.primaryContact };
            }
            if (data.primaryContactMethod) {
                this.primaryContactMethod = data.primaryContactMethod;
            }
            if (data.newPrimaryContact) {
                this.newPrimaryContact = { ...this.newPrimaryContact, ...data.newPrimaryContact };
            }
            if (data.officerSameAsPrimary !== undefined) {
                this.officerSameAsPrimary = data.officerSameAsPrimary;
            }
            if (data.officerContactMethod) {
                this.officerContactMethod = data.officerContactMethod;
            }
            if (data.officerPortalAccess) {
                this.officerPortalAccess = data.officerPortalAccess;
            }
            if (data.officerContact) {
                this.officerContact = { ...this.officerContact, ...data.officerContact };
            }
            if (data.newOfficerContact) {
                this.newOfficerContact = { ...this.newOfficerContact, ...data.newOfficerContact };
            }
            if (data.otherContacts) {
                this.otherContacts = [...data.otherContacts];
            }
            if (data.tpaList) {
                this.tpaList = [...data.tpaList];
            }
        }
    }

    /**
     * @api Validate all fields using standard validation
     * Shows field-level errors but doesn't determine section completion
     * @returns {Object} { isValid: Boolean, errors: Array }
     */
    @api
    validate() {
        let isValid = true;
        const errors = [];
        
        // Validate all lightning-input and lightning-combobox fields
        const allInputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        allInputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        // Validate ContactForm components (new contact fields)
        const contactForms = this.template.querySelectorAll('c-a-r-c_-contact-form');
        contactForms.forEach(form => {
            if (form && typeof form.reportValidity === 'function') {
                if (!form.reportValidity()) {
                    isValid = false;
                }
            }
        });

        return {
            isValid,
            errors
        };
    }

    /**
     * Check if section is complete (all required contacts are filled)
     * This determines the section status, not whether save is allowed
     * @returns {Boolean} Whether all required contacts exist with required fields
     */
    isComplete() {
        // Helper to check if a contact has all required fields
        const hasRequiredFields = (contact) => {
            return contact && 
                   contact.firstName && 
                   contact.lastName && 
                   contact.title && 
                   contact.email && 
                   contact.phone;
        };

        // Primary contact is required with all required fields
        if (!this.hasPrimaryContact) {
            return false;
        }
        if (!hasRequiredFields(this.primaryContact)) {
            return false;
        }
        
        // Officer contact is required (unless same as primary)
        if (!this.officerSameAsPrimary) {
            if (!this.hasOfficerContact) {
                return false;
            }
            if (!hasRequiredFields(this.officerContact)) {
                return false;
            }
        }
        
        return true;
    }

    /**
     * @api Reset section to initial state
     */
    @api
    reset() {
        this.primaryContact = {
            id: null,
            contactId: null,
            firstName: '',
            lastName: '',
            title: '',
            email: '',
            phone: '',
            portalAccess: '',
            state:'',
            city:'',
            street:'',
            zip:''
        };
        this.isEditingPrimaryContact = false;
        this.officerSameAsPrimary = true;
        this.isEditingOfficerContact = false;
        this.officerContact = {
            contactId: null,
            firstName: '',
            lastName: '',
            title: '',
            email: '',
            phone: ''
        };
        this.otherContacts = [];
        this.tpaList = [];
        this.ownershipContacts = [];
        this.sectionStatus = 'not-started';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS - Primary Contact
    // ═══════════════════════════════════════════════════════════════════════

    handleChangePrimaryContact() {
        // Create backup for undo
        this.primaryContactBackup = { ...this.primaryContact };
        
        // Enter edit mode
        this.isEditingPrimaryContact = true;
        this.primaryContactMethod = 'existing';
        
        // Pre-populate lookup with current selection
        setTimeout(() => {
            const lookup = this.template.querySelector('c-a-r-c_-generic-lookup');
            if (lookup && this.primaryContact.contactId) {
                lookup.setSelection({
                    Id: this.primaryContact.contactId,
                    Name: `${this.primaryContact.firstName} ${this.primaryContact.lastName}`,
                    Title: this.primaryContact.title,
                    Email: this.primaryContact.email,
                    Phone: this.primaryContact.phone
                });
            }
        }, 100);
    }

    handleCancelPrimaryContactEdit() {
        // Restore from backup
        if (this.primaryContactBackup) {
            this.primaryContact = { ...this.primaryContactBackup };
        }
        this.primaryContactBackup = null;
        this.isEditingPrimaryContact = false;
        this.newPrimaryContact = this.getEmptyContact();
    }

    handlePrimaryContactMethodChange(event) {
        this.primaryContactMethod = event.detail.value;
        // Reset fields when switching methods
        if (this.primaryContactMethod === 'new') {
            this.newPrimaryContact = this.getEmptyContact();
            // Reset portal access to blank for new contact
            this.primaryContact = { ...this.primaryContact, portalAccess: '' };
            // Ensure we stay in edit mode when creating new contact
            this.isEditingPrimaryContact = true;
        }
    }

    handlePortalAccessChange(event) {
        this.primaryContact = {
            ...this.primaryContact,
            portalAccess: event.detail.value
        };
        this.dispatchChangeEvent();
    }

    handlePrimaryContactSelect(event) {
        const contact = this.parseContactFromLookup(event.detail.record);
        this.primaryContact = { ...this.primaryContact, ...contact };
        this.isEditingPrimaryContact = true; // Keep edit form open to fill missing fields
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    /**
     * Handles changes from the ContactForm component for new primary contact
     */
    handleNewPrimaryContactChange(event) {
        this.newPrimaryContact = { ...event.detail.contact };
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    /**
     * Handles changes when editing existing primary contact fields
     */
    handlePrimaryContactEditChange(event) {
        this.primaryContact = {
            ...this.primaryContact,
            ...event.detail.contact
        };
        console.log('Primary Contact after edit change:', JSON.stringify(this.primaryContact, null, 2));
        this.setInProgress();
        this.dispatchChangeEvent();
    }
    

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS - Company Officer
    // ═══════════════════════════════════════════════════════════════════════

    handleChangeOfficerContact() {
        // Create backup for undo
        this.officerContactBackup = { ...this.officerContact };
        this.officerSameAsPrimaryBackup = this.officerSameAsPrimary;
        
        // Enter edit mode
        this.isEditingOfficerContact = true;
        this.officerContactMethod = 'existing';
        
        // Pre-populate lookup with current selection
        setTimeout(() => {
            const lookups = this.template.querySelectorAll('c-a-r-c_-generic-lookup');
            const officerLookup = Array.from(lookups).find(l => l.label === 'Select Company Officer');
            if (officerLookup && this.officerContact.contactId) {
                officerLookup.setSelection({
                    Id: this.officerContact.contactId,
                    Name: `${this.officerContact.firstName} ${this.officerContact.lastName}`,
                    Title: this.officerContact.title,
                    Email: this.officerContact.email,
                    Phone: this.officerContact.phone
                });
            }
        }, 100);
    }

    handleCancelOfficerContactEdit() {
        // Restore from backup
        if (this.officerContactBackup) {
            this.officerContact = { ...this.officerContactBackup };
        }
        if (this.officerSameAsPrimaryBackup !== null) {
            this.officerSameAsPrimary = this.officerSameAsPrimaryBackup;
        }
        this.officerContactBackup = null;
        this.officerSameAsPrimaryBackup = null;
        this.isEditingOfficerContact = false;
        this.newOfficerContact = this.getEmptyContact();
    }

    async handleOfficerSameChange(event) {
        const previousValue = this.officerSameAsPrimary;
        this.officerSameAsPrimary = event.detail.value === 'yes';
        
        // When switching from Yes to No: clear officer contact to show selection UI
        if (previousValue === true && this.officerSameAsPrimary === false) {
            this.officerContact = this.getEmptyContactWithId();
            this.newOfficerContact = this.getEmptyContact();
            this.officerContactMethod = 'existing';
            this.officerPortalAccess = '';
            // Enter edit mode to show selection UI
            this.isEditingOfficerContact = false; // Not editing existing, just selecting new
        }
        
        // When switching from No to Yes: clear officer contact, then save immediately
        if (this.officerSameAsPrimary) {
            this.officerContact = this.getEmptyContactWithId();
            this.newOfficerContact = this.getEmptyContact();
            this.officerContactMethod = 'existing';
            this.officerPortalAccess = '';
            this.isEditingOfficerContact = false;
            this.dispatchChangeEvent();
            await this.handleSave();
            return;
        }
        
        this.dispatchChangeEvent();
    }

    handleOfficerContactMethodChange(event) {
        this.officerContactMethod = event.detail.value;
        // Reset the contact data when switching methods
        if (this.officerContactMethod === 'existing') {
            this.newOfficerContact = this.getEmptyContact();
        } else {
            this.officerContact = this.getEmptyContactWithId();
            // Reset portal access to blank for new contact
            this.officerPortalAccess = '';
            // Ensure we stay in edit mode when creating new contact
            this.isEditingOfficerContact = true;
        }
        this.dispatchChangeEvent();
    }

    handleOfficerPortalAccessChange(event) {
        this.officerPortalAccess = event.detail.value;
        this.dispatchChangeEvent();
    }

    handleOfficerContactSelect(event) {
        const contact = this.parseContactFromLookup(event.detail.record);
        this.officerContact = { ...contact };
        this.officerPortalAccess = contact.portalAccess || '';
        this.isEditingOfficerContact = true;
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    
    /**
     * Handles changes from the ContactForm component for new officer contact
     */
    handleNewOfficerContactChange(event) {
        this.newOfficerContact = { ...event.detail.contact };
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    /**
     * Handles changes when editing existing officer contact fields
     */
    handleOfficerContactEditChange(event) {
        this.officerContact = {
            ...this.officerContact,
            ...event.detail.contact
        };
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS - Other Contacts
    // ═══════════════════════════════════════════════════════════════════════

    async handleAddOtherContact() {
        const modal = this.template.querySelector('c-a-r-c_-contact-modal');
        if (modal) {
            const result = await modal.open({ mode: 'new', hideAddress: true, hidePhone: true });
            if (result && result.action === 'save') {
                this.isSavingOtherContact = true;
                try {
                    const contactToSave = {
                        contact: {
                            Id: null,
                            FirstName: result.contact.firstName,
                            LastName: result.contact.lastName,
                            Title: result.contact.title,
                            Email: result.contact.email,
                            Phone: result.contact.phone,
                            ARC_PortalAccess__c: result.contact.portalAccess || '',
                            MailingStreet: result.contact.street || '',
                            MailingCity: result.contact.city || '',
                            MailingState: result.contact.state || '',
                            MailingPostalCode: result.contact.zip || ''
                        },
                        acrId: null,
                        portalAccess: result.contact.portalAccess || '',
                        isNew: true,
                        isModified: false
                    };
                    const saveResult = await saveContactSection({
                        opportunityId: this.effectiveRecordId,
                        contactSectionData: { otherContacts: [contactToSave] }
                    });
                    if (!saveResult.isSuccess) throw new Error(saveResult.message);

                    const saved = saveResult.data?.otherContacts?.[0];
                    const newContact = {
                        id: saved?.contactId || `contact_${Date.now()}`,
                        contactId: saved?.contactId || null,
                        acrId: saved?.acrId || null,
                        isNew: false,
                        isModified: false,
                        ...result.contact
                    };
                    this.otherContacts = [...this.otherContacts, newContact];
                    this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
                    this._flashSavedOtherContact();
                    this.dispatchChangeEvent();
                } catch (error) {
                    this.showToast('Error', error.body?.message || error.message || 'An error occurred while saving', 'error');
                } finally {
                    this.isSavingOtherContact = false;
                }
            }
        }
    }

    async handleEditOtherContact(event) {
        const { row, index } = event.detail;
        const modal = this.template.querySelector('c-a-r-c_-contact-modal');
        if (modal) {
            const result = await modal.open({
                mode: 'edit',
                contact: row,
                index: index,
                hideAddress: true,
                hidePhone: true
            });
            if (result && result.action === 'save') {
                const originalContact = this.otherContacts[result.index];
                this.isSavingOtherContact = true;
                try {
                    const contactToSave = {
                        contact: {
                            Id: originalContact?.contactId || null,
                            FirstName: result.contact.firstName,
                            LastName: result.contact.lastName,
                            Title: result.contact.title,
                            Email: result.contact.email,
                            Phone: result.contact.phone,
                            ARC_PortalAccess__c: result.contact.portalAccess || '',
                            MailingStreet: result.contact.street || '',
                            MailingCity: result.contact.city || '',
                            MailingState: result.contact.state || '',
                            MailingPostalCode: result.contact.zip || ''
                        },
                        acrId: originalContact?.acrId || null,
                        portalAccess: result.contact.portalAccess || '',
                        isNew: false,
                        isModified: true
                    };
                    const saveResult = await saveContactSection({
                        opportunityId: this.effectiveRecordId,
                        contactSectionData: { otherContacts: [contactToSave] }
                    });
                    if (!saveResult.isSuccess) throw new Error(saveResult.message);

                    const saved = saveResult.data?.otherContacts?.[0];
                    this.otherContacts = this.otherContacts.map((contact, i) => {
                        if (i === result.index) {
                            return {
                                ...contact,
                                ...result.contact,
                                contactId: saved?.contactId || contact.contactId,
                                acrId: saved?.acrId || contact.acrId,
                                isNew: false,
                                isModified: false
                            };
                        }
                        return contact;
                    });
                    this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
                    this._flashSavedOtherContact();
                    this.dispatchChangeEvent();
                } catch (error) {
                    this.showToast('Error', error.body?.message || error.message || 'An error occurred while saving', 'error');
                } finally {
                    this.isSavingOtherContact = false;
                }
            }
        }
    }

    async handleRemoveOtherContact(event) {
        const { index } = event.detail;
        const contact = this.otherContacts[index];
        
        // Show confirmation dialog
        const confirmed = await this.showConfirmDialog(
            'Delete Contact',
            `Are you sure you want to delete ${contact.firstName} ${contact.lastName}? This action cannot be undone.`,
            'Delete',
            'destructive'
        );
        
        if (!confirmed) {
            return;
        }
        
        // If contact has a real contactId (was saved), check delete permission
        if (contact.contactId) {
            try {
                const permissions = await checkDeletePermissions();
                if (!permissions.hasContactDelete) {
                    this.showToast('Error', 'You do not have permission to delete Contact records', 'error');
                    return;
                }
            } catch (error) {
                this.showToast('Error', 'Unable to verify permissions', 'error');
                return;
            }
            
            // Mark for deletion
            this.otherContactsToDelete = [...this.otherContactsToDelete, contact.contactId];
        }
        
        // Remove from list
        this.otherContacts = this.otherContacts.filter((_, i) => i !== index);
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS - TPA
    // ═══════════════════════════════════════════════════════════════════════

    async handleAddTPA() {
        const modal = this.template.querySelector('c-a-r-c_-t-p-a-modal');
        if (modal) {
            const result = await modal.open({ mode: 'new' });
            if (result && result.action === 'save') {
                this.isSavingTPA = true;
                try {
                    const tpaToSave = {
                        accountId: null,
                        contactId: null,
                        companyName: result.tpa.companyName,
                        firstName: result.tpa.firstName,
                        lastName: result.tpa.lastName,
                        email: result.tpa.email,
                        phone: result.tpa.phone,
                        mailingAddress: result.tpa.mailingAddress,
                        city: result.tpa.city,
                        state: result.tpa.state,
                        zip: result.tpa.zip,
                        portalAccess: result.tpa.portalAccess || '',
                        isNew: true,
                        isModified: false
                    };
                    const saveResult = await saveContactSection({
                        opportunityId: this.effectiveRecordId,
                        contactSectionData: { tpas: [tpaToSave] }
                    });
                    if (!saveResult.isSuccess) throw new Error(saveResult.message);

                    const saved = saveResult.data?.tpas?.[0];
                    const newTPA = {
                        id: saved?.contactId || `tpa_${Date.now()}`,
                        accountId: saved?.accountId || null,
                        contactId: saved?.contactId || null,
                        isNew: false,
                        isModified: false,
                        contactName: `${result.tpa.firstName || ''} ${result.tpa.lastName || ''}`.trim(),
                        ...result.tpa
                    };
                    this.tpaList = [...this.tpaList, newTPA];
                    this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
                    this._flashSavedTPA();
                    this.dispatchChangeEvent();
                } catch (error) {
                    this.showToast('Error', error.body?.message || error.message || 'An error occurred while saving', 'error');
                } finally {
                    this.isSavingTPA = false;
                }
            }
        }
    }

    async handleEditTPA(event) {
        const { row, index } = event.detail;
        const modal = this.template.querySelector('c-a-r-c_-t-p-a-modal');
        if (modal) {
            const result = await modal.open({
                mode: 'edit',
                tpa: row,
                index: index
            });
            if (result && result.action === 'save') {
                const originalTPA = this.tpaList[result.index];
                this.isSavingTPA = true;
                try {
                    const tpaToSave = {
                        accountId: originalTPA?.accountId || null,
                        contactId: originalTPA?.contactId || null,
                        companyName: result.tpa.companyName,
                        firstName: result.tpa.firstName,
                        lastName: result.tpa.lastName,
                        email: result.tpa.email,
                        phone: result.tpa.phone,
                        mailingAddress: result.tpa.mailingAddress,
                        city: result.tpa.city,
                        state: result.tpa.state,
                        zip: result.tpa.zip,
                        portalAccess: result.tpa.portalAccess || '',
                        isNew: false,
                        isModified: true
                    };
                    const saveResult = await saveContactSection({
                        opportunityId: this.effectiveRecordId,
                        contactSectionData: { tpas: [tpaToSave] }
                    });
                    if (!saveResult.isSuccess) throw new Error(saveResult.message);

                    const saved = saveResult.data?.tpas?.[0];
                    this.tpaList = this.tpaList.map((tpa, i) => {
                        if (i === result.index) {
                            return {
                                ...tpa,
                                ...result.tpa,
                                accountId: saved?.accountId || tpa.accountId,
                                contactId: saved?.contactId || tpa.contactId,
                                id: saved?.contactId || tpa.id,
                                contactName: `${result.tpa.firstName || tpa.firstName || ''} ${result.tpa.lastName || tpa.lastName || ''}`.trim(),
                                isNew: false,
                                isModified: false
                            };
                        }
                        return tpa;
                    });
                    this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
                    this._flashSavedTPA();
                    this.dispatchChangeEvent();
                } catch (error) {
                    this.showToast('Error', error.body?.message || error.message || 'An error occurred while saving', 'error');
                } finally {
                    this.isSavingTPA = false;
                }
            }
        }
    }

    async handleRemoveTPA(event) {
        const { index } = event.detail;
        const tpa = this.tpaList[index];
        
        // Show confirmation dialog
        const confirmed = await this.showConfirmDialog(
            'Delete Third Party Administrator',
            `Are you sure you want to delete ${tpa.companyName}? This action cannot be undone.`,
            'Delete',
            'destructive'
        );
        
        if (!confirmed) {
            return;
        }
        
        // If TPA has real IDs (was saved), check delete permissions
        if (tpa.accountId && tpa.contactId) {
            try {
                const permissions = await checkDeletePermissions();
                
                // Check both Contact and Account delete permissions
                if (!permissions.hasContactDelete || !permissions.hasAccountDelete) {
                    this.showToast('Error', 'You do not have permission to delete Contact and Account records', 'error');
                    return;
                }
            } catch (error) {
                this.showToast('Error', 'Unable to verify permissions', 'error');
                return;
            }
            
            // Mark for deletion
            this.tpasToDelete = [...this.tpasToDelete, {
                accountId: tpa.accountId,
                contactId: tpa.contactId
            }];
        }
        
        // Remove from list
        this.tpaList = this.tpaList.filter((_, i) => i !== index);
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS - Account Holder (Account mode only)
    // ═══════════════════════════════════════════════════════════════════════

    handleChangeAccountHolder() {
        this.accountHolderBackup = { ...this.accountHolderContact };
        this.isEditingAccountHolder = true;
        this.accountHolderContactMethod = 'existing';

        // Pre-populate lookup with current selection
        setTimeout(() => {
            const lookups = this.template.querySelectorAll('c-a-r-c_-generic-lookup');
            const ahLookup = Array.from(lookups).find(l => l.label === 'Search Account Holder');
            if (ahLookup && this.accountHolderContact.contactId) {
                ahLookup.setSelection({
                    Id: this.accountHolderContact.contactId,
                    Name: `${this.accountHolderContact.firstName} ${this.accountHolderContact.lastName}`,
                    Title: this.accountHolderContact.title,
                    Email: this.accountHolderContact.email,
                    Phone: this.accountHolderContact.phone
                });
            }
        }, 100);
    }

    handleCancelAccountHolderEdit() {
        if (this.accountHolderBackup) {
            this.accountHolderContact = { ...this.accountHolderBackup };
        }
        this.accountHolderBackup = null;
        this.isEditingAccountHolder = false;
        this.newAccountHolderContact = this.getEmptyContact();
    }

    handleAccountHolderMethodChange(event) {
        this.accountHolderContactMethod = event.detail.value;
        if (this.accountHolderContactMethod === 'new') {
            this.newAccountHolderContact = this.getEmptyContact();
            this.accountHolderContact = { ...this.accountHolderContact, portalAccess: '' };
            this.isEditingAccountHolder = true;
        } else {
            this.newAccountHolderContact = this.getEmptyContact();
            this.accountHolderContact = this.getEmptyContactWithId();
        }
    }

    handleAccountHolderPortalAccessChange(event) {
        this.accountHolderPortalAccess = event.detail.value;
        this.accountHolderContact = { ...this.accountHolderContact, portalAccess: event.detail.value };
    }

    handleAccountHolderSelect(event) {
        const contact = this.parseContactFromLookup(event.detail.record);
        this.accountHolderContact = { ...this.accountHolderContact, ...contact };
        this.isEditingAccountHolder = true;
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    handleAccountHolderEditChange(event) {
        this.accountHolderContact = { ...this.accountHolderContact, ...event.detail.contact };
        this.setInProgress();
    }

    handleNewAccountHolderChange(event) {
        this.newAccountHolderContact = { ...event.detail.contact };
        this.setInProgress();
    }

    async handleAccountHolderSameChange(event) {
        const previousValue = this.accountHolderSameAsPrimary;
        this.accountHolderSameAsPrimary = event.detail.value === 'yes';

        // When switching from Yes to No: clear AH contact to show selection UI
        if (previousValue === true && this.accountHolderSameAsPrimary === false) {
            this.accountHolderContact = this.getEmptyContactWithId();
            this.newAccountHolderContact = this.getEmptyContact();
            this.accountHolderContactMethod = 'existing';
            this.isEditingAccountHolder = false;
        }

        // When switching from No to Yes: clear AH contact, then save immediately
        if (this.accountHolderSameAsPrimary) {
            this.accountHolderContact = this.getEmptyContactWithId();
            this.newAccountHolderContact = this.getEmptyContact();
            this.accountHolderContactMethod = 'existing';
            this.isEditingAccountHolder = false;
            this.dispatchChangeEvent();
            await this.handleSave();
            return;
        }

        this.dispatchChangeEvent();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS - Billing Contact (Account mode only)
    // ═══════════════════════════════════════════════════════════════════════

    async handleBillingSameChange(event) {
        const previousValue = this.billingSameAsAccountHolder;
        this.billingSameAsAccountHolder = event.detail.value === 'yes';

        // When switching from Yes to No: clear billing contact to show selection UI
        if (previousValue === true && this.billingSameAsAccountHolder === false) {
            this.billingContact = this.getEmptyContactWithId();
            this.newBillingContact = this.getEmptyContact();
            this.billingContactMethod = 'existing';
            this.isEditingBillingContact = false;
        }

        // When switching from No to Yes: clear billing contact, then save immediately
        if (this.billingSameAsAccountHolder) {
            this.billingContact = this.getEmptyContactWithId();
            this.newBillingContact = this.getEmptyContact();
            this.billingContactMethod = 'existing';
            this.isEditingBillingContact = false;
            this.dispatchChangeEvent();
            await this.handleSave();
            return;
        }

        this.dispatchChangeEvent();
    }

    handleChangeBillingContact() {
        this.billingContactBackup = { ...this.billingContact };
        this.isEditingBillingContact = true;
        this.billingContactMethod = 'existing';

        // Pre-populate lookup with current selection
        setTimeout(() => {
            const lookups = this.template.querySelectorAll('c-a-r-c_-generic-lookup');
            const billingLookup = Array.from(lookups).find(l => l.label === 'Search Billing Contact');
            if (billingLookup && this.billingContact.contactId) {
                billingLookup.setSelection({
                    Id: this.billingContact.contactId,
                    Name: `${this.billingContact.firstName} ${this.billingContact.lastName}`,
                    Title: this.billingContact.title,
                    Email: this.billingContact.email,
                    Phone: this.billingContact.phone
                });
            }
        }, 100);
    }

    handleCancelBillingContactEdit() {
        if (this.billingContactBackup) {
            this.billingContact = { ...this.billingContactBackup };
        }
        this.billingContactBackup = null;
        this.isEditingBillingContact = false;
        this.newBillingContact = this.getEmptyContact();
    }

    handleBillingContactMethodChange(event) {
        this.billingContactMethod = event.detail.value;
        if (this.billingContactMethod === 'new') {
            this.newBillingContact = this.getEmptyContact();
            this.billingContactPortalAccess = '';
            this.isEditingBillingContact = true;
        } else {
            this.billingContact = this.getEmptyContactWithId();
            this.billingContactPortalAccess = '';
        }
    }

    handleBillingContactPortalAccessChange(event) {
        this.billingContactPortalAccess = event.detail.value;
    }

    handleBillingContactSelect(event) {
        const contact = this.parseContactFromLookup(event.detail.record);
        this.billingContact = { ...contact };
        this.billingContactPortalAccess = contact.portalAccess || '';
        this.isEditingBillingContact = true;
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    handleBillingContactEditChange(event) {
        this.billingContact = { ...this.billingContact, ...event.detail.contact };
        this.setInProgress();
    }

    handleNewBillingContactChange(event) {
        this.newBillingContact = { ...event.detail.contact };
        this.setInProgress();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS - Ownership Contacts (Account mode only)
    // ═══════════════════════════════════════════════════════════════════════

    async handleAddOwnershipContact() {
        const modal = this.template.querySelector('c-a-r-c_-owner-modal');
        if (modal) {
            const existingIds = this.ownershipContacts
                .filter(c => c.contactId)
                .map(c => c.contactId);
            const currentTotal = this.ownershipContacts.reduce((sum, c) => sum + (parseFloat(c.ownershipPercentage) || 0), 0);
            const result = await modal.open({
                mode: 'new',
                existingContactIds: existingIds,
                currentTotalOwnership: currentTotal
            });
            if (result && result.action === 'save') {
                const newContact = {
                    id: `ownership_${Date.now()}`,
                    isNew: true,
                    isModified: false,
                    ...result.owner
                };
                this.ownershipContacts = [...this.ownershipContacts, newContact];
                this.isSavingOwnership = true;
                try {
                    const ownershipToSave = this.ownershipContacts.map(c => ({
                        contact: {
                            Id: c.contactId || null,
                            FirstName: c.firstName,
                            LastName: c.lastName,
                            Title: c.title,
                            Email: c.email,
                            Phone: c.phone,
                            ARC_PortalAccess__c: c.portalAccess || '',
                            ARC_OwnershipPercentage__c: c.ownershipPercentage || null,
                            ARC_Eligible__c: c.isEligible || false,
                            MailingStreet: c.street,
                            MailingCity: c.city,
                            MailingState: c.state,
                            MailingPostalCode: c.zip
                        },
                        acrId: c.acrId || null,
                        portalAccess: c.portalAccess || '',
                        isNew: c.isNew,
                        isModified: c.isModified
                    }));
                    const saveResult = await saveContactSection({
                        opportunityId: this.effectiveRecordId,
                        contactSectionData: { ownershipContacts: ownershipToSave }
                    });
                    if (!saveResult.isSuccess) throw new Error(saveResult.message);

                    if (saveResult.data?.ownershipContacts) {
                        let idIndex = 0;
                        this.ownershipContacts = this.ownershipContacts.map(c => {
                            if (c.isNew || c.isModified) {
                                const saved = saveResult.data.ownershipContacts[idIndex++];
                                return { ...c, contactId: saved.contactId, id: saved.contactId, acrId: saved.acrId, isNew: false, isModified: false };
                            }
                            return c;
                        });
                    }
                    this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
                    this._flashSavedOwnership();
                    this.dispatchChangeEvent();
                } catch (error) {
                    this.showToast('Error', error.body?.message || error.message || 'An error occurred while saving', 'error');
                } finally {
                    this.isSavingOwnership = false;
                }
            }
        }
    }

    async handleEditOwnershipContact(event) {
        const { row, index } = event.detail;
        const modal = this.template.querySelector('c-a-r-c_-owner-modal');
        if (modal) {
            // Exclude the current owner's percentage from the total so they can edit freely
            const currentTotal = this.ownershipContacts.reduce((sum, c, i) => sum + (i !== index ? (parseFloat(c.ownershipPercentage) || 0) : 0), 0);
            const result = await modal.open({ mode: 'edit', owner: row, index, currentTotalOwnership: currentTotal });
            if (result && result.action === 'save') {
                const updatedList = this.ownershipContacts.map((c, i) => {
                    if (i === result.index) {
                        return { ...c, ...result.owner, isModified: !c.isNew };
                    }
                    return c;
                });
                this.ownershipContacts = updatedList;
                this.isSavingOwnership = true;
                try {
                    const ownershipToSave = this.ownershipContacts.map(c => ({
                        contact: {
                            Id: c.contactId || null,
                            FirstName: c.firstName,
                            LastName: c.lastName,
                            Title: c.title,
                            Email: c.email,
                            Phone: c.phone,
                            ARC_PortalAccess__c: c.portalAccess || '',
                            ARC_OwnershipPercentage__c: c.ownershipPercentage || null,
                            ARC_Eligible__c: c.isEligible || false,
                            MailingStreet: c.street,
                            MailingCity: c.city,
                            MailingState: c.state,
                            MailingPostalCode: c.zip
                        },
                        acrId: c.acrId || null,
                        portalAccess: c.portalAccess || '',
                        isNew: c.isNew,
                        isModified: c.isModified
                    }));
                    const saveResult = await saveContactSection({
                        opportunityId: this.effectiveRecordId,
                        contactSectionData: { ownershipContacts: ownershipToSave }
                    });
                    if (!saveResult.isSuccess) throw new Error(saveResult.message);

                    if (saveResult.data?.ownershipContacts) {
                        let idIndex = 0;
                        this.ownershipContacts = this.ownershipContacts.map(c => {
                            if (c.isNew || c.isModified) {
                                const saved = saveResult.data.ownershipContacts[idIndex++];
                                return { ...c, contactId: saved.contactId, id: saved.contactId, acrId: saved.acrId, isNew: false, isModified: false };
                            }
                            return c;
                        });
                    }
                    this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
                    this._flashSavedOwnership();
                    this.dispatchChangeEvent();
                } catch (error) {
                    this.showToast('Error', error.body?.message || error.message || 'An error occurred while saving', 'error');
                } finally {
                    this.isSavingOwnership = false;
                }
            }
        }
    }

    async handleRemoveOwnershipContact(event) {
        const { index } = event.detail;
        const contact = this.ownershipContacts[index];

        const confirmed = await this.showConfirmDialog(
            'Remove Ownership Contact',
            `Are you sure you want to remove ${contact.firstName} ${contact.lastName} as an owner? The contact record will be kept.`,
            'Remove',
            'destructive'
        );
        if (!confirmed) return;

        if (contact.contactId) {
            this.ownershipContactsToRemoveRole = [...this.ownershipContactsToRemoveRole, contact.contactId];
        }

        this.ownershipContacts = this.ownershipContacts.filter((_, i) => i !== index);
        this.setInProgress();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SAVE HANDLER
    // ═══════════════════════════════════════════════════════════════════════

    async handleSave() {
        // Validate Primary and Officer contact forms if they're being created/edited
        const contactForms = this.template.querySelectorAll('c-a-r-c_-contact-form');
        let isValid = true;
        
        contactForms.forEach(form => {
            if (form && typeof form.reportValidity === 'function') {
                if (!form.reportValidity()) {
                    isValid = false;
                }
            }
        });
        
        // Validate Portal Access for Primary Contact
        const primaryPortalAccess = this.template.querySelector('[data-id="primaryPortalAccess"]');
        if (primaryPortalAccess && !primaryPortalAccess.reportValidity()) {
            isValid = false;
        }

        // Validate Portal Access for Officer Contact (if not same as primary)
        if (!this.officerSameAsPrimary) {
            const officerPortalAccess = this.template.querySelector('[data-id="officerPortalAccess"]');
            if (officerPortalAccess && !officerPortalAccess.reportValidity()) {
                isValid = false;
            }
        }

        if (!isValid) {
            this.showToast('Validation Error', 'Please fill in all required contact fields', 'error');
            return;
        }

        // Block save if ownership total exceeds 100%
        if (this.isAccountMode && this.isOwnershipOverAllocated) {
            this.showToast('Error', `Total ownership is ${this.totalOwnershipPercentage}%. It cannot exceed 100%.`, 'error');
            return;
        }

        this.isSaving = true;

        try {
            // Prepare all contact section data in a single object
            const contactSectionData = this.prepareContactSectionData();

            // Call unified save method (single transaction with rollback on failure)
            const result = await saveContactSection({
                opportunityId: this.effectiveRecordId,
                contactSectionData: contactSectionData
            });

            if (!result.isSuccess) {
                throw new Error(result.message);
            }
            else {
                const id = this.effectiveRecordId;
                if (!this.isCommunity && id && String(id).startsWith('001')) {
                    const detectedChanges = this.generateChangesReport();
                    if (detectedChanges) {
                        await sendEmailForCompanyContactChanges({
                            email: this.primaryContact?.email,
                            primaryContactName: this.primaryContact?.firstName + ' ' + this.primaryContact?.lastName,
                            primaryContactAcrId: this.primaryContact?.acrId,
                            changes: detectedChanges
                        });
                    }
                }
            }

            // Update local state with saved data
            this.updateLocalStateAfterSave(result.data);

            // Auto-detect same-as relationships after save
            this._checkAndFlipSameAsFlags();
            
            // Refresh Other Contacts list to reflect role changes
            await this.refreshOtherContacts();
            
            // Update status based on completion
            this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
            this._flashSaved();
            
            // Broadcast contact updates after successful save
            if (this.primaryContact?.contactId) {
                this.broadcastContactUpdate(this.primaryContact.contactId, this.primaryContact);
            }
            if (this.officerContact?.contactId) {
                this.broadcastContactUpdate(this.officerContact.contactId, this.officerContact);
            }
            this.otherContacts.forEach(contact => {
                if (contact.contactId) {
                    this.broadcastContactUpdate(contact.contactId, contact);
                }
            });
            this.tpaList.forEach(tpa => {
                if (tpa.contactId) {
                    this.broadcastContactUpdate(tpa.contactId, tpa);
                }
            });
            
            this.dispatchEvent(new CustomEvent('save', {
                detail: {
                    section: 'companyContacts',
                    data: this.getData(),
                    isValid: true,
                    errors: []
                }
            }));

        } catch (error) {
            console.error('Error saving company contacts:', error);
            this.showToast('Error', error.body?.message || error.message || 'An error occurred while saving', 'error');
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * Prepare all contact section data for unified save
     * @returns {Object} All contact section data structured for Apex
     */
    prepareContactSectionData() {
        const data = {};

        // 1. Primary Business Contact
        if (this.primaryContactMethod) {
            const contactData = this.prepareSaveData(
                this.primaryContact,
                this.newPrimaryContact,
                this.primaryContactMethod,
                this.primaryContact.portalAccess
            );
            
            data.primaryContact = {
                contactData: contactData,
                contactMethod: this.primaryContactMethod,
                acrId: this.primaryContact.acrId
            };
        }

        // 2. Company Officer Contact
        if (this.officerSameAsPrimary || this.officerContactMethod) {
            if (this.officerSameAsPrimary) {
                data.officerContact = {
                    sameAsPrimary: true,
                    contactData: null,
                    contactMethod: null,
                    acrId: this.officerContact.acrId
                };
            } else {
                const contactData = this.prepareSaveData(
                    this.officerContact,
                    this.newOfficerContact,
                    this.officerContactMethod,
                    this.officerPortalAccess
                );
                
                data.officerContact = {
                    sameAsPrimary: false,
                    contactData: contactData,
                    contactMethod: this.officerContactMethod,
                    acrId: this.officerContact.acrId
                };
            }
        }

        // 3. Other Contacts (only new or modified)
        const otherContactsToSave = this.otherContacts
            .filter(contact => contact.isNew || contact.isModified)
            .map(contact => ({
                contact: {
                    Id: contact.contactId,
                    FirstName: contact.firstName,
                    LastName: contact.lastName,
                    Title: contact.title,
                    Email: contact.email,
                    Phone: contact.phone,
                    ARC_PortalAccess__c: contact.portalAccess || '',
                    MailingStreet: contact.street,
                    MailingCity: contact.city,
                    MailingState: contact.state,
                    MailingPostalCode: contact.zip
                },
                acrId: contact.acrId,
                portalAccess: contact.portalAccess || '',
                isNew: contact.isNew,
                isModified: contact.isModified
            }));
        
        if (otherContactsToSave.length > 0) {
            data.otherContacts = otherContactsToSave;
        }

        // 4. Other Contacts to Delete
        if (this.otherContactsToDelete.length > 0) {
            data.otherContactsToDelete = this.otherContactsToDelete;
        }

        // 5. TPAs (only new or modified)
        const tpasToSave = this.tpaList
            .filter(tpa => tpa.isNew || tpa.isModified)
            .map(tpa => ({
                accountId: tpa.accountId,
                contactId: tpa.contactId,
                companyName: tpa.companyName,
                firstName: tpa.firstName,
                lastName: tpa.lastName,
                email: tpa.email,
                phone: tpa.phone,
                mailingAddress: tpa.mailingAddress,
                city: tpa.city,
                state: tpa.state,
                zip: tpa.zip,
                portalAccess: tpa.portalAccess || '',
                isNew: tpa.isNew,
                isModified: tpa.isModified
            }));
        
        if (tpasToSave.length > 0) {
            data.tpas = tpasToSave;
        }

        // 6. TPAs to Delete
        if (this.tpasToDelete.length > 0) {
            data.tpasToDelete = this.tpasToDelete;
        }

        // 7. Account-mode only sections
        if (this.isAccountMode) {
            // Account Holder
            data.accountHolderContact = {
                sameAsPrimary: this.accountHolderSameAsPrimary,
                contactData: this.accountHolderSameAsPrimary ? null : this.prepareSaveData(
                    this.accountHolderContact,
                    this.newAccountHolderContact,
                    this.accountHolderContactMethod,
                    this.accountHolderContact.portalAccess
                ),
                contactMethod: this.accountHolderContactMethod,
                acrId: this.accountHolderContact.acrId
            };

            // Billing Contact
            data.billingContact = {
                sameAsAccountHolder: this.billingSameAsAccountHolder,
                contactData: this.billingSameAsAccountHolder ? null : this.prepareSaveData(
                    this.billingContact,
                    this.newBillingContact,
                    this.billingContactMethod,
                    this.billingContactPortalAccess
                ),
                contactMethod: this.billingContactMethod,
                acrId: this.billingContact.acrId
            };

            // Ownership Contacts — send all (full list needed for ACR management)
            const ownershipToSave = this.ownershipContacts
                .map(c => ({
                    contact: {
                        Id: c.contactId,
                        FirstName: c.firstName,
                        LastName: c.lastName,
                        Title: c.title,
                        Email: c.email,
                        Phone: c.phone,
                        ARC_PortalAccess__c: c.portalAccess || '',
                        ARC_OwnershipPercentage__c: c.ownershipPercentage || null,
                        ARC_Eligible__c: c.isEligible || false,
                        MailingStreet: c.street,
                        MailingCity: c.city,
                        MailingState: c.state,
                        MailingPostalCode: c.zip
                    },
                    acrId: c.acrId,
                    portalAccess: c.portalAccess || '',
                    isNew: c.isNew,
                    isModified: c.isModified
                }));

            if (ownershipToSave.length > 0) {
                data.ownershipContacts = ownershipToSave;
            }

            if (this.ownershipContactsToRemoveRole.length > 0) {
                data.ownershipContactsToRemoveRole = this.ownershipContactsToRemoveRole;
            }
        }

        return data;
    }

    /**
     * Update local component state after successful save
     * @param {Object} savedData - Data returned from Apex save
     */
    updateLocalStateAfterSave(savedData) {
        // Update Primary Contact
        if (savedData.primaryContact) {
            if (this.primaryContactMethod === 'new') {
                this.primaryContact = {
                    ...this.newPrimaryContact,
                    contactId: savedData.primaryContact.contactId,
                    id: savedData.primaryContact.contactId,
                    acrId: savedData.primaryContact.acrId,
                    portalAccess: this.primaryContact.portalAccess,
                    roles: ''
                };
                this.newPrimaryContact = this.getEmptyContact();
                // Change method to 'existing' since contact is now created
                this.primaryContactMethod = 'existing';
            } else {
                this.primaryContact.contactId = savedData.primaryContact.contactId;
                this.primaryContact.acrId = savedData.primaryContact.acrId;
            }
            this.isEditingPrimaryContact = false;
            this.primaryContactBackup = null;
        }

        // Update Officer Contact
        if (savedData.officerContact) {
            if (this.officerSameAsPrimary) {
                this.officerContact = {
                    ...this.primaryContact,
                    acrId: savedData.officerContact.acrId,
                    portalAccess: this.officerPortalAccess
                };
            } else if (this.officerContactMethod === 'new') {
                this.officerContact = {
                    ...this.newOfficerContact,
                    contactId: savedData.officerContact.contactId,
                    id: savedData.officerContact.contactId,
                    acrId: savedData.officerContact.acrId,
                    portalAccess: this.officerPortalAccess,
                    roles: ''
                };
                this.newOfficerContact = this.getEmptyContact();
                // Change method to 'existing' since contact is now created
                this.officerContactMethod = 'existing';
            } else {
                this.officerContact.contactId = savedData.officerContact.contactId;
                this.officerContact.acrId = savedData.officerContact.acrId;
            }
            this.isEditingOfficerContact = false;
            this.officerContactBackup = null;
            this.officerSameAsPrimaryBackup = null;
        }

        // Update Other Contacts
        if (savedData.otherContacts) {
            let idIndex = 0;
            this.otherContacts = this.otherContacts.map(contact => {
                if (contact.isNew || contact.isModified) {
                    const saved = savedData.otherContacts[idIndex++];
                    return {
                        ...contact,
                        contactId: saved.contactId,
                        id: saved.contactId,
                        acrId: saved.acrId,
                        isNew: false,
                        isModified: false
                    };
                }
                return contact;
            });
        }
        this.otherContactsToDelete = [];

        // Update TPAs
        if (savedData.tpas) {
            let idIndex = 0;
            this.tpaList = this.tpaList.map(tpa => {
                if (tpa.isNew || tpa.isModified) {
                    const saved = savedData.tpas[idIndex++];
                    return {
                        ...tpa,
                        accountId: saved.accountId,
                        contactId: saved.contactId,
                        id: saved.contactId,
                        isNew: false,
                        isModified: false
                    };
                }
                return tpa;
            });
        }
        this.tpasToDelete = [];

        // Update Account Holder
        if (savedData.accountHolder) {
            if (this.accountHolderSameAsPrimary) {
                this.accountHolderContact = {
                    ...this.primaryContact,
                    acrId: savedData.accountHolder.acrId
                };
            } else if (this.accountHolderContactMethod === 'new') {
                this.accountHolderContact = {
                    ...this.newAccountHolderContact,
                    contactId: savedData.accountHolder.contactId,
                    id: savedData.accountHolder.contactId,
                    acrId: savedData.accountHolder.acrId
                };
                this.newAccountHolderContact = this.getEmptyContact();
                this.accountHolderContactMethod = 'existing';
            } else {
                this.accountHolderContact.contactId = savedData.accountHolder.contactId;
                this.accountHolderContact.acrId = savedData.accountHolder.acrId;
            }
            this.isEditingAccountHolder = false;
            this.accountHolderBackup = null;
        }

        // Update Billing Contact
        if (savedData.billingContact) {
            if (this.billingSameAsAccountHolder) {
                this.billingContact = {
                    ...this.accountHolderContact,
                    acrId: savedData.billingContact.acrId
                };
            } else if (this.billingContactMethod === 'new') {
                this.billingContact = {
                    ...this.newBillingContact,
                    contactId: savedData.billingContact.contactId,
                    id: savedData.billingContact.contactId,
                    acrId: savedData.billingContact.acrId,
                    portalAccess: this.billingContactPortalAccess
                };
                this.newBillingContact = this.getEmptyContact();
                this.billingContactMethod = 'existing';
            } else {
                this.billingContact.contactId = savedData.billingContact.contactId;
                this.billingContact.acrId = savedData.billingContact.acrId;
            }
            this.isEditingBillingContact = false;
            this.billingContactBackup = null;
        }

        // Update Ownership Contacts
        if (savedData.ownershipContacts) {
            let idIndex = 0;
            this.ownershipContacts = this.ownershipContacts.map(c => {
                if (c.isNew || c.isModified) {
                    const saved = savedData.ownershipContacts[idIndex++];
                    return {
                        ...c,
                        contactId: saved.contactId,
                        id: saved.contactId,
                        acrId: saved.acrId,
                        isNew: false,
                        isModified: false
                    };
                }
                return c;
            });
        }
        this.ownershipContactsToRemoveRole = [];

        // Updated the original memory for future editions
        this._originalPrimary = { ...this.primaryContact };
        this._originalOfficer = { ...this.officerContact, portalAccess: this.officerPortalAccess };
        this._originalAccHolder = {...this.accountHolderContact, portalAccess: this.accountHolderPortalAccess};
        this._originalBillContact = {...this.billingContact, portalAccess: this.billingContactPortalAccess};
        this._originalOther = JSON.parse(JSON.stringify(this.otherContacts));
        this._originalTpas = JSON.parse(JSON.stringify(this.tpaList));
        this._originalOwnership = JSON.parse(JSON.stringify(this.ownershipContacts));
    }

    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    _flashSaved() {
        if (this._savedTimer) clearTimeout(this._savedTimer);
        this.isSaved = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._savedTimer = setTimeout(() => { this.isSaved = false; this._savedTimer = null; }, 2500);
    }

    _flashSavedOtherContact() {
        if (this._savedTimerOther) clearTimeout(this._savedTimerOther);
        this.isSavedOtherContact = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._savedTimerOther = setTimeout(() => { this.isSavedOtherContact = false; this._savedTimerOther = null; }, 2500);
    }

    _flashSavedTPA() {
        if (this._savedTimerTPA) clearTimeout(this._savedTimerTPA);
        this.isSavedTPA = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._savedTimerTPA = setTimeout(() => { this.isSavedTPA = false; this._savedTimerTPA = null; }, 2500);
    }

    _flashSavedOwnership() {
        if (this._savedTimerOwnership) clearTimeout(this._savedTimerOwnership);
        this.isSavedOwnership = true;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._savedTimerOwnership = setTimeout(() => { this.isSavedOwnership = false; this._savedTimerOwnership = null; }, 2500);
    }

    _checkAndFlipSameAsFlags() {
        const primaryId = this.primaryContact?.contactId;

        // Officer same as primary?
        if (!this.officerSameAsPrimary && this.officerContact?.contactId && primaryId
                && this.officerContact.contactId === primaryId) {
            this.officerSameAsPrimary = true;
            this.officerContact = this.getEmptyContactWithId();
            this.newOfficerContact = this.getEmptyContact();
            this.officerContactMethod = 'existing';
            this.isEditingOfficerContact = false;
        }

        // Account holder same as primary?
        if (!this.accountHolderSameAsPrimary && this.accountHolderContact?.contactId && primaryId
                && this.accountHolderContact.contactId === primaryId) {
            this.accountHolderSameAsPrimary = true;
            this.accountHolderContact = this.getEmptyContactWithId();
            this.newAccountHolderContact = this.getEmptyContact();
            this.accountHolderContactMethod = 'existing';
            this.isEditingAccountHolder = false;
        }

        // Billing same as account holder?
        const accountHolderId = this.accountHolderSameAsPrimary
            ? primaryId
            : this.accountHolderContact?.contactId;
        if (!this.billingSameAsAccountHolder && this.billingContact?.contactId && accountHolderId
                && this.billingContact.contactId === accountHolderId) {
            this.billingSameAsAccountHolder = true;
            this.billingContact = this.getEmptyContactWithId();
            this.newBillingContact = this.getEmptyContact();
            this.billingContactMethod = 'existing';
            this.isEditingBillingContact = false;
        }
    }

    /**
     * Show confirmation dialog using custom modal
     * @param {String} title - Dialog title
     * @param {String} message - Confirmation message
     * @param {String} confirmLabel - Label for confirm button (default: 'Confirm')
     * @param {String} variant - Variant type (default, destructive, etc.) - not used but kept for compatibility
     * @returns {Promise<Boolean>} - True if confirmed, false if cancelled
     */
    async showConfirmDialog(title, message, confirmLabel = 'Confirm', variant = 'default') {
        const modal = this.template.querySelector('c-a-r-c_-confirm-modal');
        if (modal) {
            return await modal.open({ title, message, confirmLabel });
        }
        // Fallback to native confirm if modal not found
        return confirm(message);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Check if there were changes in a specific contact and return the formatted text
     * @param {String} typeLabel - type of contact (e.g., 'Primary Contact', 'Company Officer Contact', etc.)
     * @param {Object} oldObj - old data info
     * @param {Object} newObj - new data info
     * @returns {String} Text with changes report or null if no changes
     */
    evaluateContactChange(typeLabel, oldObj, newObj) {
        if (!oldObj && newObj) {
            return `${typeLabel} details have been changed, portal access changed to ${newObj.portalAccess || 'No Access.'}`;
        }
        if (!newObj) return null;

        if (oldObj.contactId !== newObj.contactId) {
            return `${typeLabel} details have been changed, portal access changed to ${newObj.portalAccess || 'No Access.'}`;
        }

        const normalize = (val) => val ? String(val).trim() : '';

        const detailsChanged = (
            normalize(oldObj.firstName) !== normalize(newObj.firstName) ||
            normalize(oldObj.lastName) !== normalize(newObj.lastName) ||  
            normalize(oldObj.middleInitial) !== normalize(newObj.middleInitial) || 
            normalize(oldObj.email) !== normalize(newObj.email) ||
            normalize(oldObj.phone) !== normalize(newObj.phone) ||
            normalize(oldObj.ownershipPercentage) !== normalize(newObj.ownershipPercentage) ||
            normalize(oldObj.isEligible) !== normalize(newObj.isEligible) ||
            normalize(oldObj.title) !== normalize(newObj.title) ||
            normalize(oldObj.street) !== normalize(newObj.street) ||
            normalize(oldObj.mailingAddress) !== normalize(newObj.mailingAddress) || 
            normalize(oldObj.companyName) !== normalize(newObj.companyName) ||       
            normalize(oldObj.city) !== normalize(newObj.city) ||
            normalize(oldObj.state) !== normalize(newObj.state) ||
            normalize(oldObj.zip) !== normalize(newObj.zip)
        );

        const accessChanged = normalize(oldObj.portalAccess) !== normalize(newObj.portalAccess);

        if (detailsChanged && accessChanged) {
            return `${typeLabel} details have been changed, portal access changed to ${newObj.portalAccess || 'No Access.'}`;
        } else if (detailsChanged) {
            return `${typeLabel} details have been changed.`;
        } else if (accessChanged) {
            return `${typeLabel} portal access changed to ${newObj.portalAccess || 'No Access.'}`;
        }

        return null; 
    }

    /**
     * Generate the final report of all combined changes
     * @returns {String} Join all found changes
     */
    generateChangesReport() {
        let changes = [];

        // Evaluate Primary Contact
        let currentPrimary = this.primaryContactMethod === 'new' 
            ? { ...this.newPrimaryContact, portalAccess: this.primaryContact.portalAccess, contactId: null } 
            : this.primaryContact;
        
        let primaryChange = this.evaluateContactChange('Primary Business Contact', this._originalPrimary, currentPrimary);
        if (primaryChange) changes.push(`<li>${primaryChange}</li>`);

        // Evaluate Officer Contact
        let currentOfficer = this.officerContactMethod === 'new'
            ? { ...this.newOfficerContact, portalAccess: this.officerPortalAccess, contactId: null }
            : { ...this.officerContact, portalAccess: this.officerPortalAccess };
        
        if (this.officerSameAsPrimary && this._originalOfficer && this._originalOfficer.contactId !== currentPrimary.contactId) {
            changes.push(`<li>Company Officer Contact details have been changed.</li>`);
        } else if (!this.officerSameAsPrimary) {
            let officerChange = this.evaluateContactChange('Company Officer Contact', this._originalOfficer, currentOfficer);
            if (officerChange) changes.push(`<li>${officerChange}</li>`);
        }

        // Evaluate Account Holder
        let currentAccHolder = this.accountHolderContactMethod === 'new'
            ? {...this.newAccountHolderContact, portalAccess: this.accountHolderPortalAccess, contactId: null}
            : {...this.accountHolderContact, portalAccess: this.accountHolderPortalAccess};

        if (this.accountHolderSameAsPrimary && this._originalAccHolder && this._originalAccHolder.contactId !== currentPrimary.contactId) {
            changes.push(`<li>Account Holder Contact details have been changed.</li>`);
        } else if (!this.accountHolderSameAsPrimary) {
            let accHolderChange = this.evaluateContactChange('Account Holder Contact', this._originalAccHolder, currentAccHolder);
            if (accHolderChange) changes.push(`<li>${accHolderChange}</li>`);
        }        

        // Evaluate Billing Contact
        let currentBillContact = this.billingContactMethod === 'new'
            ? {...this.newBillingContact, portalAccess: this.billingContactPortalAccess, contactId: null}
            : {...this.billingContact, portalAccess: this.billingContactPortalAccess};

        if (this.billingSameAsAccountHolder && this._originalBillContact && this._originalBillContact.contactId !== currentAccHolder.contactId) {
            changes.push(`<li>Billing Contact details have been changed.</li>`);
        } else if (!this.billingSameAsAccountHolder) {
            let billContactChange = this.evaluateContactChange('Billing Contact', this._originalBillContact, currentBillContact);
            if (billContactChange) changes.push(`<li>${billContactChange}</li>`);
        }

        // Evaluate Other Contacts
        this.otherContacts.forEach(contact => {
            if (contact.isNew || contact.isModified) {
                let orig = this._originalOther.find(o => o.contactId === contact.contactId);

                let fullName = `${contact.firstName || ''} ${contact.lastName || ''}`.trim();
                let label = `Other Contact (${fullName})`;

                let otherChange = this.evaluateContactChange(label, orig, contact);
                if (otherChange) changes.push(`<li>${otherChange}</li>`);
            }
        });

        // Evaluate TPAs
        this.tpaList.forEach(tpa => {
            if (tpa.isNew || tpa.isModified) {
                let orig = this._originalTpas.find(o => o.contactId === tpa.contactId);

                let compName = tpa.companyName ? tpa.companyName.trim() : 'New TPA';
                let label = `Third Party Administrator (${compName})`;
                
                let tpaChange = this.evaluateContactChange(label, orig, tpa);
                if (tpaChange) changes.push(`<li>${tpaChange}</li>`);
            }
        });

        // Evaluate Ownership Contacts
        this.ownershipContacts.forEach(owner => {
            if (owner.isNew || owner.isModified) {
                let orig = this._originalOwnership.find(o => o.contactId === owner.contactId);

                let fullName = `${owner.firstName || ''} ${owner.lastName || ''}`.trim();
                let label = `Ownership Contact (${fullName})`;
                let ownerChange = this.evaluateContactChange(label, orig, owner);
                if (ownerChange) changes.push(`<li>${ownerChange}</li>`);
            }
        });

        return changes.join('\n');
    }

    /**
     * Formats a raw phone string to (XXX) XXX-XXXX.
     * Strips all non-digits, then formats if exactly 10 digits; otherwise returns as-is.
     * @param {String} phone - Raw phone value
     * @returns {String} Formatted phone or original value
     */
    formatPhone(phone) {
        if (!phone) return '';
        const digits = String(phone).replace(/\D/g, '');
        if (digits.length === 10) {
            return `(${digits.slice(0, 3)}) ${digits.slice(3, 6)}-${digits.slice(6)}`;
        }
        if (digits.length === 11 && digits[0] === '1') {
            return `(${digits.slice(1, 4)}) ${digits.slice(4, 7)}-${digits.slice(7)}`;
        }
        return phone;
    }

    /**
     * Maps ContactData wrapper from Apex to LWC contact object
     * @param {Object} contactDataWrapper - Wrapper from Apex with {contact, acrId, roles, portalAccess}
     * @returns {Object} Contact object formatted for LWC
     */
    mapContactData(contactDataWrapper) {
        return {
            id: contactDataWrapper.contact.Id,
            contactId: contactDataWrapper.contact.Id,
            acrId: contactDataWrapper.acrId,
            firstName: contactDataWrapper.contact.FirstName || '',
            lastName: contactDataWrapper.contact.LastName || '',
            title: contactDataWrapper.contact.Title || '',
            email: contactDataWrapper.contact.Email || '',
            phone: this.formatPhone(contactDataWrapper.contact.Phone),
            portalAccess: contactDataWrapper.portalAccess || '',
            roles: contactDataWrapper.roles || '',
            street: contactDataWrapper.contact.MailingStreet || '',
            city: contactDataWrapper.contact.MailingCity || '',
            state: contactDataWrapper.contact.MailingState || '',
            zip: contactDataWrapper.contact.MailingPostalCode || ''
        };
    }

    /**
     * Parses contact record from lookup component
     * Handles Name fallback when FirstName/LastName not provided
     * @param {Object} contact - Contact record from lookup
     * @returns {Object} Parsed contact with firstName, lastName, etc.
     */
    parseContactFromLookup(contact) {
        // Parse Name as fallback if FirstName/LastName not provided
        let firstName = contact.FirstName || '';
        let lastName = contact.LastName || '';
        
        if (!firstName && !lastName && contact.Name) {
            const nameParts = contact.Name.split(' ');
            firstName = nameParts[0] || '';
            lastName = nameParts.slice(1).join(' ') || '';
        }
        
        return {
            contactId: contact.Id,
            firstName: firstName,
            lastName: lastName,
            title: contact.Title || '',
            email: contact.Email || '',
            phone: this.formatPhone(contact.Phone),
            street: contact.MailingStreet || '',
            city: contact.MailingCity || '',
            state: contact.MailingState || '',
            zip: contact.MailingPostalCode || '',
            portalAccess: contact.ARC_PortalAccess__c || ''
        };
    }

    /**
     * Prepares contact data for save based on method (new vs existing)
     * @param {Object} existingContact - Existing contact object
     * @param {Object} newContact - New contact object
     * @param {String} method - 'new' or 'existing'
     * @param {String} portalAccess - Portal access level
     * @returns {Object} Data formatted for Apex save method
     */
    prepareSaveData(existingContact, newContact, method, portalAccess) {
        if (method === 'new') {
            return {
                method: 'new',
                firstName: newContact.firstName,
                lastName: newContact.lastName,
                title: newContact.title,
                email: newContact.email,
                phone: newContact.phone,
                street: newContact.street,
                city: newContact.city,
                state: newContact.state,
                zip: newContact.zip,
                portalAccess: portalAccess
            };
        } else {
            // Existing contact - include all fields for update
            return {
                method: 'existing',
                contactId: existingContact.contactId || existingContact.id,
                firstName: existingContact.firstName,
                lastName: existingContact.lastName,
                title: existingContact.title,
                email: existingContact.email,
                phone: existingContact.phone,
                street: existingContact.street,
                city: existingContact.city,
                state: existingContact.state,
                zip: existingContact.zip,
                portalAccess: portalAccess
            };
        }
    }

    /**
     * Check if officer contact is the same as primary contact
     * Called after both contacts are loaded
     */
    checkIfOfficerSameAsPrimary() {
        if (this.primaryContact.contactId && this.officerContact.contactId) {
            this.officerSameAsPrimary = (this.primaryContact.contactId === this.officerContact.contactId);
        } 
        else if (this.primaryContact.contactId || this.officerContact.contactId) {
            this.officerSameAsPrimary = false;
        }
    }

    /**
     * Returns an empty contact object - used to reset contact fields
     * @returns {Object} Empty contact with all fields as empty strings
     */
    getEmptyContact() {
        return { firstName: '', lastName: '', title: '', email: '', phone: '', street: '', city: '', state: '', zip: '', portalAccess: '' };
    }

    /**
     * Returns an empty contact with contactId field - for existing contact selection
     * @returns {Object} Empty contact with contactId null and all fields empty
     */
    getEmptyContactWithId() {
        return { contactId: null, firstName: '', lastName: '', title: '', email: '', phone: '', street: '', city: '', state: '', zip: '', portalAccess: '' };
    }

    dispatchChangeEvent() {
        // this.dispatchEvent(new CustomEvent('change', {
        //     detail: {
        //         section: 'companyContacts',
        //         data: this.getData()
        //     },
        //     bubbles: false,
        //     composed: false

        // }));
    }

    /**
     * @api Sync contact data when updated from another section
     */
    @api
    syncContactData(contactId, contactData) {
        let updated = false;
        
        // Update primary contact if it matches
        if (this.primaryContact.contactId === contactId) {
            this.primaryContact = {
                ...this.primaryContact,
                firstName: contactData.firstName || this.primaryContact.firstName,
                lastName: contactData.lastName || this.primaryContact.lastName,
                email: contactData.email || this.primaryContact.email,
                phone: contactData.phone || this.primaryContact.phone,
                portalAccess: contactData.portalAccess || this.primaryContact.portalAccess
            };
            updated = true;
        }
        
        // Update officer contact if it matches
        if (this.officerContact.contactId === contactId) {
            this.officerContact = {
                ...this.officerContact,
                firstName: contactData.firstName || this.officerContact.firstName,
                lastName: contactData.lastName || this.officerContact.lastName,
                email: contactData.email || this.officerContact.email,
                phone: contactData.phone || this.officerContact.phone,
                portalAccess: contactData.portalAccess || this.officerContact.portalAccess
            };
            this.officerPortalAccess = contactData.portalAccess || this.officerPortalAccess;
            updated = true;
        }

        // Update account holder if any match
        if (this.accountHolderContact && this.accountHolderContact.contactId === contactId) {
            this.accountHolderContact = {
                ...this.accountHolderContact,
                firstName: contactData.firstName || this.accountHolderContact.firstName,
                lastName: contactData.lastName || this.accountHolderContact.lastName,
                email: contactData.email || this.accountHolderContact.email,
                phone: contactData.phone || this.accountHolderContact.phone,
                portalAccess: contactData.portalAccess || this.accountHolderContact.portalAccess
            };
            updated = true;
        }

        // Update billing contact if any match
        if (this.billingContact && this.billingContact.contactId === contactId) {
            this.billingContact = {
                ...this.billingContact,
                firstName: contactData.firstName || this.billingContact.firstName,
                lastName: contactData.lastName || this.billingContact.lastName,
                email: contactData.email || this.billingContact.email,
                phone: contactData.phone || this.billingContact.phone,
                portalAccess: contactData.portalAccess || this.billingContact.portalAccess
            };
            updated = true;
        }
        
        // Update other contacts if any match
        this.otherContacts = this.otherContacts.map(contact => {
            if (contact.contactId === contactId) {
                updated = true;
                return {
                    ...contact,
                    firstName: contactData.firstName || contact.firstName,
                    lastName: contactData.lastName || contact.lastName,
                    email: contactData.email || contact.email,
                    phone: contactData.phone || contact.phone,
                    portalAccess: contactData.portalAccess || contact.portalAccess
                };
            }
            return contact;
        });
        
        // Update TPAs if any match
        this.tpaList = this.tpaList.map(tpa => {
            if (tpa.contactId === contactId) {
                updated = true;
                return {
                    ...tpa,
                    firstName: contactData.firstName || tpa.firstName,
                    lastName: contactData.lastName || tpa.lastName,
                    contactName: `${contactData.firstName || tpa.firstName} ${contactData.lastName || tpa.lastName}`,
                    email: contactData.email || tpa.email,
                    phone: contactData.phone || tpa.phone,
                    portalAccess: contactData.portalAccess || tpa.portalAccess
                };
            }
            return tpa;
        });
 
        // Update Ownership if any match
        this.ownershipContacts = this.ownershipContacts.map(owner => {
            if (owner.contactId === contactId) {
                updated = true;
                return {
                    ...owner,
                    firstName: contactData.firstName || owner.firstName,
                    lastName: contactData.lastName || owner.lastName,
                    email: contactData.email || owner.email,
                    phone: contactData.phone || owner.phone,
                    portalAccess: contactData.portalAccess || owner.portalAccess
                };
            }
            return owner;
        });
        
        if (updated) {
            // Force UI update
            this.primaryContact = {...this.primaryContact};
            this.officerContact = {...this.officerContact};
            if (this.isAccountMode) {
                this.accountHolderContact = {...this.accountHolderContact};
                this.billingContact = {...this.billingContact};
            }
            this.otherContacts = [...this.otherContacts];
            this.tpaList = [...this.tpaList];
            this.ownershipContacts = [...this.ownershipContacts];
        }
    }

    /**
     * Broadcast contact update to other sections
     */
    broadcastContactUpdate(contactId, contactData) {
        this.dispatchEvent(new CustomEvent('contactupdate', {
            bubbles: true,
            composed: true,
            detail: {
                contactId: contactId,
                contactData: {
                    firstName: contactData.firstName,
                    lastName: contactData.lastName,
                    middleInitial: contactData.middleInitial || '',
                    email: contactData.email,
                    phone: contactData.phone,
                    portalAccess: contactData.portalAccess
                }
            }
        }));
    }
}