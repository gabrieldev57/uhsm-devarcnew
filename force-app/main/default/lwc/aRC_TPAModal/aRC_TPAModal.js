import { LightningElement, api, track } from 'lwc';

/**
 * ARC_TPAModal - Reusable modal for adding/editing Third Party Administrators
 * 
 * Usage:
 *   const result = await this.template.querySelector('c-a-r-c_-t-p-a-modal').open();
 *   const result = await this.template.querySelector('c-a-r-c_-t-p-a-modal').open({
 *       tpa: existingTPA,
 *       mode: 'edit'
 *   });
 */
export default class ArcTPAModal extends LightningElement {
    @track isOpen = false;
    @track mode = 'new';
    @track editIndex = null;
    @track useExistingAccount = false; // Track whether using existing or creating new Account
    @track selectedAccount = null; // Store selected Account record
    
    @track tpaData = {
        accountId: null,
        companyName: '',
        mailingAddress: '',
        city: '',
        state: '',
        zip: '',
        firstName: '',
        lastName: '',
        phone: '',
        email: '',
        portalAccess: ''
    };

    resolve;
    reject;

    // Portal Access options
    portalAccessOptions = [
        { label: 'No Access', value: 'No Access' },
        { label: 'Viewer', value: 'Viewer' },
        { label: 'Admin', value: 'Admin' }
    ];

    // US State options
    stateOptions = [
        { label: 'AL', value: 'AL' }, { label: 'AK', value: 'AK' }, { label: 'AZ', value: 'AZ' },
        { label: 'AR', value: 'AR' }, { label: 'CA', value: 'CA' }, { label: 'CO', value: 'CO' },
        { label: 'CT', value: 'CT' }, { label: 'DE', value: 'DE' }, { label: 'FL', value: 'FL' },
        { label: 'GA', value: 'GA' }, { label: 'HI', value: 'HI' }, { label: 'ID', value: 'ID' },
        { label: 'IL', value: 'IL' }, { label: 'IN', value: 'IN' }, { label: 'IA', value: 'IA' },
        { label: 'KS', value: 'KS' }, { label: 'KY', value: 'KY' }, { label: 'LA', value: 'LA' },
        { label: 'ME', value: 'ME' }, { label: 'MD', value: 'MD' }, { label: 'MA', value: 'MA' },
        { label: 'MI', value: 'MI' }, { label: 'MN', value: 'MN' }, { label: 'MS', value: 'MS' },
        { label: 'MO', value: 'MO' }, { label: 'MT', value: 'MT' }, { label: 'NE', value: 'NE' },
        { label: 'NV', value: 'NV' }, { label: 'NH', value: 'NH' }, { label: 'NJ', value: 'NJ' },
        { label: 'NM', value: 'NM' }, { label: 'NY', value: 'NY' }, { label: 'NC', value: 'NC' },
        { label: 'ND', value: 'ND' }, { label: 'OH', value: 'OH' }, { label: 'OK', value: 'OK' },
        { label: 'OR', value: 'OR' }, { label: 'PA', value: 'PA' }, { label: 'RI', value: 'RI' },
        { label: 'SC', value: 'SC' }, { label: 'SD', value: 'SD' }, { label: 'TN', value: 'TN' },
        { label: 'TX', value: 'TX' }, { label: 'UT', value: 'UT' }, { label: 'VT', value: 'VT' },
        { label: 'VA', value: 'VA' }, { label: 'WA', value: 'WA' }, { label: 'WV', value: 'WV' },
        { label: 'WI', value: 'WI' }, { label: 'WY', value: 'WY' }, { label: 'DC', value: 'DC' }
    ];

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    get modalTitle() {
        return this.mode === 'edit' ? 'Edit TPA' : 'Add Third Party Administrator';
    }

    get saveButtonLabel() {
        return this.mode === 'edit' ? 'Save Changes' : 'Add TPA';
    }

    get accountSelectionOptions() {
        return [
            { label: 'Use Existing Account', value: 'existing' },
            { label: 'Create New Account', value: 'new' }
        ];
    }

    get showAccountLookup() {
        return this.useExistingAccount;
    }

    get showAccountFields() {
        return true; // Always show account fields (editable)
    }

    get accountSelectionValue() {
        return this.useExistingAccount ? 'existing' : 'new';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API
    // ═══════════════════════════════════════════════════════════════════════

    @api
    open(options = {}) {
        this.mode = options.mode || 'new';
        this.editIndex = options.index !== undefined ? options.index : null;
        
        if (options.tpa) {
            // Editing existing TPA
            this.useExistingAccount = !!options.tpa.accountId;
            this.selectedAccount = options.tpa.accountId ? {
                Id: options.tpa.accountId,
                Name: options.tpa.companyName,
                BillingStreet: options.tpa.mailingAddress,
                BillingCity: options.tpa.city,
                BillingState: options.tpa.state,
                BillingPostalCode: options.tpa.zip
            } : null;
            
            this.tpaData = {
                accountId: options.tpa.accountId || null,
                companyName: options.tpa.companyName || '',
                mailingAddress: options.tpa.mailingAddress || '',
                city: options.tpa.city || '',
                state: options.tpa.state || '',
                zip: options.tpa.zip || '',
                firstName: options.tpa.firstName || '',
                lastName: options.tpa.lastName || '',
                phone: this.formatPhone(options.tpa.phone || ''),
                email: options.tpa.email || '',
                portalAccess: options.tpa.portalAccess || ''
            };
            
            // Set the selection in lookup after render
            if (this.useExistingAccount && this.selectedAccount) {
                setTimeout(() => {
                    const lookup = this.template.querySelector('c-a-r-c_-generic-lookup');
                    if (lookup) {
                        lookup.setSelection(this.selectedAccount);
                    }
                }, 100);
            }
        } else {
            // New TPA - default to creating new Account
            this.useExistingAccount = false;
            this.selectedAccount = null;
            
            this.tpaData = {
                accountId: null,
                companyName: '',
                mailingAddress: '',
                city: '',
                state: '',
                zip: '',
                firstName: '',
                lastName: '',
                phone: '',
                email: '',
                portalAccess: ''
            };
        }
        
        this.isOpen = true;
        
        return new Promise((resolve, reject) => {
            this.resolve = resolve;
            this.reject = reject;
        });
    }

    @api
    close() {
        this.isOpen = false;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    handleAccountSelectionChange(event) {
        this.useExistingAccount = event.detail.value === 'existing';
        
        // Clear data when switching
        if (this.useExistingAccount) {
            // Switching to existing - clear manual entry fields
            this.tpaData.companyName = '';
            this.tpaData.mailingAddress = '';
            this.tpaData.city = '';
            this.tpaData.state = '';
            this.tpaData.zip = '';
            this.selectedAccount = null;
            this.tpaData.accountId = null;
            
            // Clear lookup
            setTimeout(() => {
                const lookup = this.template.querySelector('c-a-r-c_-generic-lookup');
                if (lookup) {
                    lookup.clearSelection();
                }
            }, 0);
        } else {
            // Switching to new - clear selected account
            this.selectedAccount = null;
            this.tpaData.accountId = null;
        }
    }

    handleAccountSelect(event) {
        const account = event.detail.record;
        this.selectedAccount = account;
        this.tpaData.accountId = account.Id;
        this.tpaData.companyName = account.Name;
        this.tpaData.mailingAddress = account.BillingStreet || '';
        this.tpaData.city = account.BillingCity || '';
        this.tpaData.state = account.BillingState || '';
        this.tpaData.zip = account.BillingPostalCode || '';
        
        // COMMENTED OUT: Populate contact fields if Account has a Contact
        // This ensures a new Contact is created when selecting existing Account (for new TPA)
        // Only existing TPAs being edited will keep their contact data
        /*
        if (account.Contacts && account.Contacts.length > 0) {
            const contact = account.Contacts[0];
            this.tpaData.firstName = contact.FirstName || '';
            this.tpaData.lastName = contact.LastName || '';
            this.tpaData.email = contact.Email || '';
            this.tpaData.phone = contact.Phone || '';
            this.tpaData.portalAccess = contact.ARC_PortalAccess__c || '';
        }
        */
    }

    handleAccountClear() {
        this.selectedAccount = null;
        this.tpaData.accountId = null;
        this.tpaData.companyName = '';
    }

    handleFieldChange(event) {
        const fieldName = event.target.name;
        const value = event.detail?.value !== undefined ? event.detail.value : event.target.value;
        
        this.tpaData = {
            ...this.tpaData,
            [fieldName]: value
        };
    }

    formatPhone(digits) {
        const d = (digits || '').replace(/\D/g, '').slice(0, 10);
        if (d.length === 0) return '';
        if (d.length <= 3) return `(${d}`;
        if (d.length <= 6) return `(${d.slice(0, 3)}) ${d.slice(3)}`;
        return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
    }

    // On focus: show raw digits so user can edit freely, and clear any validation error
    handlePhoneFocus(event) {
        const digits = (this.tpaData.phone || '').replace(/\D/g, '');
        this.tpaData = { ...this.tpaData, phone: digits };
        event.target.setCustomValidity('');
        // Move cursor to end after reactive update
        setTimeout(() => {
            const input = event.target.shadowRoot && event.target.shadowRoot.querySelector('input');
            if (input) { input.selectionStart = input.selectionEnd = input.value.length; }
        }, 0);
    }

    // Block non-digit keys (allow control keys: backspace, delete, arrows, tab)
    handlePhoneKeyDown(event) {
        const allowed = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Tab', 'Enter'];
        if (!allowed.includes(event.key) && !/^\d$/.test(event.key)) {
            event.preventDefault();
        }
        // Also enforce max 10 digits
        const digits = (event.target.value || '').replace(/\D/g, '');
        if (/^\d$/.test(event.key) && digits.length >= 10) {
            event.preventDefault();
        }
    }

    // On blur: format the raw digits into (555) 123-4567 and show inline error if incomplete
    handlePhoneBlur(event) {
        const digits = (event.target.value || '').replace(/\D/g, '');
        const formatted = this.formatPhone(digits);
        this.tpaData = { ...this.tpaData, phone: formatted };
        setTimeout(() => {
            const input = this.template.querySelector('[name="phone"]');
            if (!input) return;
            if (digits.length > 0 && digits.length < 10) {
                input.setCustomValidity('Please enter a complete 10-digit US phone number');
            } else {
                input.setCustomValidity('');
            }
            input.reportValidity();
        }, 50);
    }

    handleCancel() {
        this.isOpen = false;
        if (this.resolve) {
            this.resolve({ action: 'cancel' });
        }
    }

    handleSave() {
        let isValid = true;
        if (this.useExistingAccount) {
            // When using existing account, validate account selection and contact fields
            const accountLookup = this.template.querySelector('c-a-r-c_-generic-lookup');
            if (accountLookup && !accountLookup.checkValidity()) {
                accountLookup.reportValidity();
                isValid = false;
            }
            
            if (!this.selectedAccount) {
                isValid = false;
            }
            
            // Validate contact fields and portal access
            const contactInputs = this.template.querySelectorAll('[data-validate="contact"]');
            contactInputs.forEach(input => {
                if (!input.reportValidity()) {
                    isValid = false;
                }
            });
        } else {
            // When creating new account, validate all fields including radio group
            
            const allInputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
            allInputs.forEach(input => {
                if (!input.reportValidity()) {
                    isValid = false;
                }
            });
        }

        if (!isValid) {
            return;
        }

        this.isOpen = false;
        if (this.resolve) {
            this.resolve({
                action: 'save',
                tpa: { 
                    ...this.tpaData,
                    useExistingAccount: this.useExistingAccount
                },
                index: this.editIndex,
                mode: this.mode
            });
        }
    }
}