import { LightningElement, api, track } from 'lwc';

/**
 * ARC_PaymentMethod - Payment method selector with Bank Account and Credit Card options
 * 
 * @description Payment method component that shows radio selector and conditionally
 *              displays bank account fields or credit card form.
 * 
 * Events:
 *   - paymentchange: Fired when payment method or data changes 
 *     { detail: { method: String, data: Object } }
 *   - validity: Fired when validity state changes { detail: { valid: Boolean } }
 */
export default class ArcPaymentMethod extends LightningElement {
    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════
    
    /** @api Default selected payment method: 'bank' or 'card' */
    @api 
    get defaultMethod() {
        return this._defaultMethod;
    }
    set defaultMethod(value) {
        this._defaultMethod = value;
        if (!this.selectedMethod) {
            this.selectedMethod = value || 'bank';
        }
    }

    /** @api Whether the form is read-only */
    @api readOnly = false;

    /** @api Pre-fill contact for account holder lookup */
    @api existingContact = null;

    /** @api Record Id (Opportunity Id) for context-aware lookups */
    @api recordId = null;

    // ═══════════════════════════════════════════════════════════════════════
    // TRACKED STATE
    // ═══════════════════════════════════════════════════════════════════════
    
    @track selectedMethod = 'bank';
    @track bankSameAsPrimary = true;
    @track useExistingContact = false;
    @track selectedContact = null;
    
    // Account Holder Contact Data (structured for easy access)
    @track accountHolderData = {
        firstName: '',
        lastName: '',
        email: '',
        portalAccess: '',
        street: '',
        city: '',
        state: '',
        zip: ''
    };
    
    // Billing Contact State
    @track billingSameAsHolder = true;
    @track billingUseExisting = false;
    @track selectedBillingContact = null;
    
    // Billing Contact Data (structured for easy access)
    @track billingContactData = {
        firstName: '',
        lastName: '',
        title: '',
        email: '',
        portalAccess: '',
        phone: ''
    };
    
    // Bank Account Data (payment details only)
    @track bankData = {
        financialInstitutionName: '',
        routingNumber: '',
        accountNumber: ''
    };

    _defaultMethod = 'bank';
    _contactsProcessed = false; // Flag to track if contacts have been initially processed
    
    // Track original contact IDs for ACR role removal
    _originalAccountHolderId = null;
    _originalBillingContactId = null;

    // ═══════════════════════════════════════════════════════════════════════
    // RADIO GROUP OPTIONS
    // ═══════════════════════════════════════════════════════════════════════
    
    paymentMethodOptions = [
        { label: 'Bank Account', value: 'bank' },
        { label: 'Credit Card', value: 'card' }
    ];

    yesNoOptions = [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
    ];

    get portalAccessOptions() {
        return [
            { label: 'No Access', value: 'No Access' },
            { label: 'Viewer', value: 'Viewer' },
            { label: 'Admin', value: 'Admin' }
        ];
    }

    // ═══════════════════════════════════════════════════════════════════════
    // STATE OPTIONS
    // ═══════════════════════════════════════════════════════════════════════
    
    stateOptions = [
        { label: 'Select State', value: '' },
        { label: 'Alabama', value: 'AL' },
        { label: 'Alaska', value: 'AK' },
        { label: 'Arizona', value: 'AZ' },
        { label: 'Arkansas', value: 'AR' },
        { label: 'California', value: 'CA' },
        { label: 'Colorado', value: 'CO' },
        { label: 'Connecticut', value: 'CT' },
        { label: 'Delaware', value: 'DE' },
        { label: 'Florida', value: 'FL' },
        { label: 'Georgia', value: 'GA' },
        { label: 'Hawaii', value: 'HI' },
        { label: 'Idaho', value: 'ID' },
        { label: 'Illinois', value: 'IL' },
        { label: 'Indiana', value: 'IN' },
        { label: 'Iowa', value: 'IA' },
        { label: 'Kansas', value: 'KS' },
        { label: 'Kentucky', value: 'KY' },
        { label: 'Louisiana', value: 'LA' },
        { label: 'Maine', value: 'ME' },
        { label: 'Maryland', value: 'MD' },
        { label: 'Massachusetts', value: 'MA' },
        { label: 'Michigan', value: 'MI' },
        { label: 'Minnesota', value: 'MN' },
        { label: 'Mississippi', value: 'MS' },
        { label: 'Missouri', value: 'MO' },
        { label: 'Montana', value: 'MT' },
        { label: 'Nebraska', value: 'NE' },
        { label: 'Nevada', value: 'NV' },
        { label: 'New Hampshire', value: 'NH' },
        { label: 'New Jersey', value: 'NJ' },
        { label: 'New Mexico', value: 'NM' },
        { label: 'New York', value: 'NY' },
        { label: 'North Carolina', value: 'NC' },
        { label: 'North Dakota', value: 'ND' },
        { label: 'Ohio', value: 'OH' },
        { label: 'Oklahoma', value: 'OK' },
        { label: 'Oregon', value: 'OR' },
        { label: 'Pennsylvania', value: 'PA' },
        { label: 'Rhode Island', value: 'RI' },
        { label: 'South Carolina', value: 'SC' },
        { label: 'South Dakota', value: 'SD' },
        { label: 'Tennessee', value: 'TN' },
        { label: 'Texas', value: 'TX' },
        { label: 'Utah', value: 'UT' },
        { label: 'Vermont', value: 'VT' },
        { label: 'Virginia', value: 'VA' },
        { label: 'Washington', value: 'WA' },
        { label: 'West Virginia', value: 'WV' },
        { label: 'Wisconsin', value: 'WI' },
        { label: 'Wyoming', value: 'WY' }
    ];

    // ═══════════════════════════════════════════════════════════════════════
    // PAYMENT METHOD OPTIONS
    // ═══════════════════════════════════════════════════════════════════════
    
    paymentMethodOptions = [
        { label: 'Bank Account', value: 'bank' },
        { label: 'Credit Card', value: 'card' }
    ];

    // ═══════════════════════════════════════════════════════════════════════
    // LIFECYCLE HOOKS
    // ═══════════════════════════════════════════════════════════════════════
    
    connectedCallback() {
        this.selectedMethod = this._defaultMethod || 'bank';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * @api Set contacts data (refreshes contact lookups)
     * @param {Object} contactsData - Fresh contact data from server
     */
    @api
    setContactsData(contactsData) {
        if (!contactsData) return;
        
        this.contactsData = contactsData;
        
        // Update Primary Business Contact if present
        if (contactsData.primaryBusinessContact) {
            this.primaryBusinessContact = contactsData.primaryBusinessContact;
        }
        
        // If using "same as primary" for bank account holder, update it
        if (this.bankSameAsPrimary && contactsData.primaryBusinessContact) {
            this.selectedContact = contactsData.primaryBusinessContact;
        }
        
        // Update credit card form if it exists
        const creditCardForm = this.template.querySelector('c-a-r-c_-credit-card-form');
        if (creditCardForm && creditCardForm.setContactsData) {
            creditCardForm.processContactsData(contactsData);
        }
    }
    
    /**
     * @api Get the current payment data
     * @returns {Object} Payment method and associated data
     */
    @api
    getPaymentData() {
        // Build account holder info (now shared between bank and card)
        const accountHolderInfo = this.buildAccountHolderInfo();
        
        // Build billing contact info
        const billingContactInfo = this.buildBillingContactInfo();

        if (this.selectedMethod === 'card') {
            const creditCardForm = this.template.querySelector('c-a-r-c_-credit-card-form');
            const cardData = creditCardForm ? creditCardForm.getPaymentData() : null;
            return {
                method: 'card',
                data: cardData ? cardData.data : null,
                accountHolder: accountHolderInfo, // Use parent's account holder, not credit card form's
                billingContact: billingContactInfo
            };
        }
        return {
            method: 'bank',
            data: { ...this.bankData },
            accountHolder: accountHolderInfo,
            billingContact: billingContactInfo
        };
    }

    /**
     * @api Set the payment data (for pre-filling from existing data)
     * @param {Object} paymentData - Object containing method, bankData, cardData
     */
    @api
    get paymentData() {
        return this._paymentData;
    }
    set paymentData(value) {
        this._paymentData = value;
        this.updatePaymentData(value);
    }

    _paymentData = null;

    updatePaymentData(paymentData) {
        if (!paymentData) return;
        
        // Set payment method
        if (paymentData.method) {
            this.selectedMethod = paymentData.method;
        }
        
        // Set bank data
        if (paymentData.bankData) {
            this.bankData = {
                financialInstitutionName: paymentData.bankData.financialInstitutionName || '',
                routingNumber: paymentData.bankData.routingNumber || '',
                accountNumber: paymentData.bankData.accountNumber || ''
            };
        }
        
        // Set card data (for credit card form)
        if (paymentData.cardData) {
            this._cardData = paymentData.cardData;
        }
        
        // Process contacts data only on initial load
        if (paymentData.contacts && !this._contactsProcessed) {
            this.processContactsData(paymentData.contacts);
            this._contactsProcessed = true;
        } else if (paymentData.contacts) {
            // Just store the contacts for credit card form without overriding radio states
            this._contactsData = paymentData.contacts;
        }
    }
    
    /**
     * Process contacts data to set radio buttons and populate fields
     */
    processContactsData(contacts) {
        // Store contacts data for credit card form
        this._contactsData = contacts;
        
        const { primaryBusinessContact, accountHolder, billingContact } = contacts;
        
        // Store original contact IDs for ACR role removal
        this._originalAccountHolderId = accountHolder ? accountHolder.id : null;
        this._originalBillingContactId = billingContact ? billingContact.id : null;
        
        // Check if Account Holder is the same as Primary Business Contact
        if (accountHolder && primaryBusinessContact && accountHolder.id === primaryBusinessContact.id) {
            this.bankSameAsPrimary = true;
            this.useExistingContact = false;
        } else if (accountHolder) {
            // Account Holder exists but is different from Primary
            this.bankSameAsPrimary = false;
            this.useExistingContact = true;
            this.selectedContact = accountHolder;
            this.populateAccountHolderFields(accountHolder);
            
            // Set the lookup selection after render
            setTimeout(() => {
                const lookup = this.template.querySelector('c-a-r-c_-generic-lookup[data-field="accountHolder"]');
                if (lookup) {
                    lookup.setSelection(accountHolder);
                }
            }, 0);
        } else {
            // No Account Holder contact - default to same as primary
            this.bankSameAsPrimary = true;
            this.useExistingContact = false;
        }
        
        // Check if Billing Contact is the same as Account Holder
        if (billingContact && accountHolder && billingContact.id === accountHolder.id) {
            this.billingSameAsHolder = true;
            this.billingUseExisting = false;
        } else if (billingContact) {
            // Billing Contact exists but is different from Account Holder
            this.billingSameAsHolder = false;
            this.billingUseExisting = true;
            this.selectedBillingContact = billingContact;
            this.populateBillingContactFields(billingContact);
            
            // Set the lookup selection after render
            setTimeout(() => {
                const lookup = this.template.querySelector('c-a-r-c_-generic-lookup[data-field="billingContact"]');
                if (lookup) {
                    lookup.setSelection(billingContact);
                }
            }, 0);
        } else {
            // No Billing Contact - default to same as holder
            this.billingSameAsHolder = true;
            this.billingUseExisting = false;
        }
    }
    
    /**
     * Populate Account Holder fields from contact data
     */
    populateAccountHolderFields(contact) {
        this.accountHolderData = {
            firstName: contact.firstName || '',
            lastName: contact.lastName || '',
            email: contact.email || '',
            portalAccess: contact.portalAccess || '',
            street: contact.street || '',
            city: contact.city || '',
            state: contact.state || '',
            zip: contact.zip || ''
        };
    }
    
    /**
     * Populate Billing Contact fields from contact data
     */
    populateBillingContactFields(contact) {
        this.billingContactData = {
            firstName: contact.firstName || '',
            lastName: contact.lastName || '',
            title: contact.title || '',
            email: contact.email || '',
            portalAccess: contact.portalAccess || '',
            phone: this.formatPhone((contact.phone || '').replace(/\D/g, ''))
        };
    }


    _cardData = null;
    _contactsData = null;

    get cardDataForChild() {
        return {
            cardData: this._cardData,
            contacts: this._contactsData
        };
    }

    /**
     * Build account holder info object based on radio selections
     * @returns {Object} Account holder information
     */
    buildAccountHolderInfo() {
        // Determine previous contact ID (the one we're replacing)
        // If we're changing from an existing contact to a different one, include the original ID
        // Handle both Id and id (case-insensitive)
        const currentContactId = this.selectedContact ? (this.selectedContact.Id || this.selectedContact.id) : null;
        const previousContactId = (this._originalAccountHolderId && this._originalAccountHolderId !== currentContactId) 
            ? this._originalAccountHolderId 
            : null;
        
        // If same as primary contact
        if (this.bankSameAsPrimary) {
            return {
                sameAsPrimary: true,
                useExisting: false,
                contactId: null,
                previousContactId: previousContactId,
                isNew: false,
                data: null
            };
        }
        
        // Return account holder data (editable fields) with metadata
        return {
            sameAsPrimary: false,
            useExisting: this.useExistingContact,
            contactId: currentContactId,
            previousContactId: previousContactId,
            isNew: !this.useExistingContact,
            data: { ...this.accountHolderData }
        };
    }

    /**
     * Build billing contact info object based on radio selections
     * @returns {Object} Billing contact information
     */
    buildBillingContactInfo() {
        // Determine previous contact ID (the one we're replacing)
        // Handle both Id and id (case-insensitive)
        const currentContactId = this.selectedBillingContact ? (this.selectedBillingContact.Id || this.selectedBillingContact.id) : null;
        const previousContactId = (this._originalBillingContactId && this._originalBillingContactId !== currentContactId) 
            ? this._originalBillingContactId 
            : null;
        
        // If same as account holder
        if (this.billingSameAsHolder) {
            return {
                sameAsAccountHolder: true,
                useExisting: false,
                contactId: null,
                previousContactId: previousContactId,
                isNew: false,
                data: null
            };
        }
        
        // Return billing contact data (editable fields) with metadata
        return {
            sameAsAccountHolder: false,
            useExisting: this.billingUseExisting,
            contactId: currentContactId,
            previousContactId: previousContactId,
            isNew: !this.billingUseExisting,
            data: { ...this.billingContactData }
        };
    }

    /**
     * @api Check validity of payment fields
     * @returns {Boolean} Whether all required fields are valid
     */
    @api
    checkValidity() {
        if (this.selectedMethod === 'card') {
            const creditCardForm = this.template.querySelector('c-arc-credit-card-form');
            return creditCardForm ? creditCardForm.checkValidity() : false;
        }
        
        // Validate bank account fields
        const inputs = this.template.querySelectorAll('lightning-input');
        let isValid = true;
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                isValid = false;
            }
        });
        return isValid;
    }

    /**
     * @api Report validity and show error messages
     * @returns {Boolean} Whether all required fields are valid
     */
    @api
    reportValidity() {
        let isValid = true;

        if (this.selectedMethod === 'card') {
            const creditCardForm = this.template.querySelector('c-a-r-c_-credit-card-form');
            if (creditCardForm && creditCardForm.reportValidity) {
                if (!creditCardForm.reportValidity()) {
                    isValid = false;
                }
            }
        }
        
        // Report validity on all lightning-input fields
        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        // Report validity on all lightning-combobox fields (state dropdowns)
        const comboboxes = this.template.querySelectorAll('lightning-combobox');
        comboboxes.forEach(combobox => {
            if (!combobox.reportValidity()) {
                isValid = false;
            }
        });

        // Report validity on all GenericLookup components (contact searches)
        const lookups = this.template.querySelectorAll('c-a-r-c_-generic-lookup');
        lookups.forEach(lookup => {
            if (lookup.reportValidity && !lookup.reportValidity()) {
                isValid = false;
            }
        });

        this.dispatchEvent(new CustomEvent('validity', {
            detail: { valid: isValid }
        }));
        
        return isValid;
    }

    /**
     * @api Tokenize credit card (only applicable for card method)
     * @returns {Promise} Resolves with token or rejects
     */
    @api
    async tokenizeCard() {
        if (this.selectedMethod !== 'card') {
            return Promise.reject(new Error('Current payment method is not credit card'));
        }
        
        const creditCardForm = this.template.querySelector('c-arc-credit-card-form');
        if (creditCardForm) {
            return creditCardForm.tokenize();
        }
        return Promise.reject(new Error('Credit card form not found'));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @api Validate the payment method form using standard Salesforce field validation
     * @returns {Object} { isValid: Boolean, errors: Array<String> }
     */
    @api
    validate() {
        const isValid = this.reportValidity();
        
        return {
            isValid: isValid,
            errors: []
        };
    }

    /**
     * @api Update contact IDs after save to prevent duplicate creation
     * @param {Id} accountHolderContactId - The Account Holder contact ID
     * @param {Id} billingContactId - The Billing Contact ID
     */
    @api
    updateContactIds(accountHolderContactId, billingContactId) {
        // For BANK ACCOUNT: Update Account Holder contact if a new one was created (manual entry mode)
        if (this.selectedMethod === 'bank' && accountHolderContactId && !this.bankSameAsPrimary && !this.useExistingContact) {
            // Build contact object
            const newContact = {
                Id: accountHolderContactId,
                id: accountHolderContactId,
                Name: `${this.accountHolderData.firstName || ''} ${this.accountHolderData.lastName || ''}`.trim(),
                FirstName: this.accountHolderData.firstName,
                LastName: this.accountHolderData.lastName,
                Email: this.accountHolderData.email || '',
                Title: '',
                MailingStreet: this.accountHolderData.street,
                MailingCity: this.accountHolderData.city,
                MailingState: this.accountHolderData.state,
                MailingPostalCode: this.accountHolderData.zip
            };
            
            // Set state - this should make radio show "Yes" and lookup appear
            this.selectedContact = newContact;
            this._originalAccountHolderId = accountHolderContactId;
            this.useExistingContact = true;
            
            // Set lookup selection after a brief delay for DOM rendering
            setTimeout(() => {
                const lookup = this.template.querySelector('c-a-r-c_-generic-lookup[data-field="accountHolder"]');
                if (lookup) {
                    lookup.setSelection(newContact);
                }
            }, 200);
        }
        
        // For CREDIT CARD: Delegate to credit card form component
        if (this.selectedMethod === 'card' && accountHolderContactId) {
            const creditCardForm = this.template.querySelector('c-a-r-c_-credit-card-form');
            if (creditCardForm && creditCardForm.updateContactIds) {
                creditCardForm.updateContactIds(accountHolderContactId);
            } else {
                console.error('[PaymentMethod] ✗ Credit card form not found or missing updateContactIds method');
            }
        }
        
        // Update BILLING CONTACT if a new one was created (manual entry mode) - works for BOTH bank and card
        if (billingContactId && !this.billingSameAsHolder && !this.billingUseExisting) {
            // Build contact object
            const newBillingContact = {
                Id: billingContactId,
                id: billingContactId,
                Name: `${this.billingContactData.firstName || ''} ${this.billingContactData.lastName || ''}`.trim(),
                FirstName: this.billingContactData.firstName,
                LastName: this.billingContactData.lastName,
                Title: this.billingContactData.title || '',
                Email: this.billingContactData.email || '',
                Phone: this.billingContactData.phone || ''
            };
            
            // Set state - this should make radio show "Yes" and lookup appear
            this.selectedBillingContact = newBillingContact;
            this._originalBillingContactId = billingContactId;
            this.billingUseExisting = true;
            
            // Set lookup selection after a brief delay for DOM rendering
            setTimeout(() => {
                const lookup = this.template.querySelector('c-a-r-c_-generic-lookup[data-field="billingContact"]');
                if (lookup) {
                    lookup.setSelection(newBillingContact);
                }
            }, 200);
        }
        
        // Broadcast contact updates after save
        if (accountHolderContactId && this.accountHolderData) {
            this.broadcastContactUpdate(accountHolderContactId, this.accountHolderData);
        }
        
        if (billingContactId && !this.billingSameAsHolder && this.billingContactData) {
            this.broadcastContactUpdate(billingContactId, this.billingContactData);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════
    
    handleMethodChange(event) {
        const newMethod = event.detail.value;
        const oldMethod = this.selectedMethod;
        
        this.selectedMethod = newMethod;
        
        this.dispatchPaymentChange();
        setTimeout(() => {
            if (newMethod === 'card' && oldMethod === 'bank') {
                // Switching from bank to card - update credit card form with current bank selections
                const creditCardForm = this.template.querySelector('c-a-r-c_-credit-card-form');
                console.log('Switching to card, updating credit card form');
                if (creditCardForm) {
                    creditCardForm.updateCardData(this.cardDataForChild);
                }
            } else if (newMethod === 'bank' && oldMethod === 'card') {
                
                // Update bank account holder lookup after state sync
                const lookup = this.template.querySelector('c-a-r-c_-generic-lookup[data-field="accountHolder"]');
                if (lookup && this.selectedContact) {
                    lookup.setSelection(this.selectedContact);
                }
            }
        }, 0);
    }

    handleUseExistingContactChange(event) {
        this.useExistingContact = event.detail.value === 'yes';
        if (!this.useExistingContact) {
            this.selectedContact = null;
            this.accountHolderData = {
                firstName: '',
                lastName: '',
                email: '',
                street: '',
                city: '',
                state: '',
                zip: ''
            };
        }
    }

    handleBankSameAsPrimaryChange(event) {
        this.bankSameAsPrimary = event.detail.value === 'yes';
        if (this.bankSameAsPrimary) {
            // hide secondary options when same as primary
            this.useExistingContact = false;
            this.selectedContact = null;
        }
    }

    handleContactSelect(event) {
        this.selectedContact = event.detail.record;
        // Auto-fill account holder info from selected contact
        if (this.selectedContact) {
            this.accountHolderData = {
                firstName: this.selectedContact.FirstName || '',
                lastName: this.selectedContact.LastName || '',
                email: this.selectedContact.Email || '',
                street: this.selectedContact.MailingStreet || '',
                city: this.selectedContact.MailingCity || '',
                state: this.selectedContact.MailingState || '',
                zip: this.selectedContact.MailingPostalCode || ''
            };
        }
        this.dispatchPaymentChange();
    }

    handleContactClear() {
        this.selectedContact = null;
        // Clear account holder data when contact is cleared
        this.accountHolderData = {
            firstName: '',
            lastName: '',
            email: '',
            street: '',
            city: '',
            state: '',
            zip: ''
        };
        this.dispatchPaymentChange();
    }

    handleBankFieldChange(event) {
        const field = event.target.dataset.field;
        let value = event.target.value;
        
        // Special handling for routing number (digits only, max 9)
        if (field === 'routingNumber') {
            value = value.replace(/\D/g, '').substring(0, 9);
        }
        // Special handling for account number (digits only)
        if (field === 'accountNumber') {
            value = value.replace(/\D/g, '');
        }
        
        this.bankData = {
            ...this.bankData,
            [field]: value
        };
        this.dispatchPaymentChange();
    }

    handleAccountHolderFieldChange(event) {
        const field = event.target.dataset.field;
        // For combobox, value is in event.detail.value; for input, it's in event.target.value
        const value = event.detail?.value !== undefined ? event.detail.value : event.target.value;
        
        this.accountHolderData = {
            ...this.accountHolderData,
            [field]: value
        };
        
        this.dispatchPaymentChange();
    }

    handleAddressChange(event) {
        const address = event.detail.address;
        this.accountHolderData.street = address.street;
        this.accountHolderData.city = address.city;
        this.accountHolderData.state = address.state;
        this.accountHolderData.zip = address.zipCode;
        this.dispatchPaymentChange();
    }

    handleCreditCardChange(event) {
        this.dispatchPaymentChange();
    }

    handleTokenizedCard(event) {
        // Forward the tokenized card event
        this.dispatchEvent(new CustomEvent('tokenizedcard', {
            detail: event.detail
        }));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BILLING CONTACT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    handleBillingSameAsHolderChange(event) {
        this.billingSameAsHolder = event.detail.value === 'yes';
        if (this.billingSameAsHolder) {
            this.billingUseExisting = false;
            this.selectedBillingContact = null;
        }
        this.dispatchPaymentChange();
    }

    handleBillingUseExistingChange(event) {
        this.billingUseExisting = event.detail.value === 'yes';
        if (!this.billingUseExisting) {
            this.selectedBillingContact = null;
        }
        this.dispatchPaymentChange();
    }

    handleBillingContactSelect(event) {
        this.selectedBillingContact = event.detail.record;
        if (this.selectedBillingContact) {
            this.billingContactData = {
                firstName: this.selectedBillingContact.FirstName || '',
                lastName: this.selectedBillingContact.LastName || '',
                title: this.selectedBillingContact.Title || '',
                email: this.selectedBillingContact.Email || '',
                phone: this.formatPhone((this.selectedBillingContact.Phone || '').replace(/\D/g, ''))
            };
        }
        this.dispatchPaymentChange();
    }

    handleBillingContactClear() {
        this.selectedBillingContact = null;
        // Clear billing contact data when contact is cleared
        this.billingContactData = {
            firstName: '',
            lastName: '',
            title: '',
            email: '',
            phone: ''
        };
        this.dispatchPaymentChange();
    }

    handleBillingFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        
        this.billingContactData = {
            ...this.billingContactData,
            [field]: value
        };
        
        this.dispatchPaymentChange();
    }

    formatPhone(digits) {
        const d = (digits || '').replace(/\D/g, '').slice(0, 10);
        if (d.length === 0) return '';
        if (d.length <= 3) return `(${d}`;
        if (d.length <= 6) return `(${d.slice(0, 3)}) ${d.slice(3)}`;
        return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
    }

    handleBillingPhoneFocus(event) {
        const digits = (this.billingContactData.phone || '').replace(/\D/g, '');
        this.billingContactData = { ...this.billingContactData, phone: digits };
        event.target.setCustomValidity('');
        setTimeout(() => {
            const input = event.target.shadowRoot && event.target.shadowRoot.querySelector('input');
            if (input) { input.selectionStart = input.selectionEnd = input.value.length; }
        }, 0);
    }

    handleBillingPhoneKeyDown(event) {
        const allowed = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Tab', 'Enter'];
        if (!allowed.includes(event.key) && !/^\d$/.test(event.key)) {
            event.preventDefault();
        }
        const digits = (event.target.value || '').replace(/\D/g, '');
        if (/^\d$/.test(event.key) && digits.length >= 10) {
            event.preventDefault();
        }
    }

    handleBillingPhoneBlur(event) {
        const digits = (event.target.value || '').replace(/\D/g, '');
        this.billingContactData = { ...this.billingContactData, phone: this.formatPhone(digits) };
        this.dispatchPaymentChange();
        setTimeout(() => {
            const input = this.template.querySelector('[data-field="phone"]');
            if (!input) return;
            if (digits.length > 0 && digits.length < 10) {
                input.setCustomValidity('Please enter a complete 10-digit US phone number');
            } else {
                input.setCustomValidity('');
            }
            input.reportValidity();
        }, 50);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    dispatchPaymentChange() {
        this.dispatchEvent(new CustomEvent('paymentchange', {
            detail: this.getPaymentData(),
            bubbles: false,
            composed: false
        }));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS (Computed Properties)
    // ═══════════════════════════════════════════════════════════════════════
    
    get isBankAccount() {
        return this.selectedMethod === 'bank';
    }

    get isCreditCard() {
        return this.selectedMethod === 'card';
    }

    get isBankSelected() {
        return this.selectedMethod === 'bank';
    }

    get isCardSelected() {
        return this.selectedMethod === 'card';
    }

    get isUseExistingYes() {
        return this.useExistingContact;
    }

    get isUseExistingNo() {
        return !this.useExistingContact;
    }

    get useExistingContactOptions() {
        return [
            { label: 'Yes', value: 'yes' },
            { label: 'No', value: 'no' }
        ];
    }

    get useExistingContactValue() {
        return this.useExistingContact ? 'yes' : 'no';
    }

    get showContactLookup() {
        return this.useExistingContact && !this.bankSameAsPrimary;
    }

    get showAccountHolderFields() {
        // Show fields when not same as primary AND:
        // - (useExisting = Yes AND contact is selected), OR
        // - (useExisting = No - manual entry)
        if (this.bankSameAsPrimary) {
            return false;
        }
        // If using existing contact, only show fields when a contact is selected
        if (this.useExistingContact) {
            return this.selectedContact !== null;
        }
        // If not using existing (manual entry), always show fields
        return true;
    }

    get isBankSamePrimaryYes() {
        return this.bankSameAsPrimary;
    }

    get isBankSamePrimaryNo() {
        return !this.bankSameAsPrimary;
    }

    get bankSameAsPrimaryValue() {
        return this.bankSameAsPrimary ? 'yes' : 'no';
    }

    get showBankUseExistingContactRadio() {
        return !this.bankSameAsPrimary;
    }

    get routingNumberPattern() {
        // Accept either 9 digits OR masked format (all asterisks: **********)
        return '([0-9]{9}|\\*{10})';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // BILLING CONTACT GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    get isBillingSameHolderYes() {
        return this.billingSameAsHolder;
    }

    get isBillingSameHolderNo() {
        return !this.billingSameAsHolder;
    }

    get billingSameAsHolderValue() {
        return this.billingSameAsHolder ? 'yes' : 'no';
    }

    get showBillingUseExistingRadio() {
        return !this.billingSameAsHolder;
    }

    get isBillingUseExistingYes() {
        return this.billingUseExisting;
    }

    get isBillingUseExistingNo() {
        return !this.billingUseExisting;
    }

    get billingUseExistingValue() {
        return this.billingUseExisting ? 'yes' : 'no';
    }

    get showBillingContactLookup() {
        return !this.billingSameAsHolder && this.billingUseExisting;
    }

    get showBillingContactFields() {
        // Show fields when not same as holder AND:
        // - (useExisting = Yes AND contact is selected), OR
        // - (useExisting = No - manual entry)
        if (this.billingSameAsHolder) {
            return false;
        }
        // If using existing contact, only show fields when a contact is selected
        if (this.billingUseExisting) {
            return this.selectedBillingContact !== null;
        }
        // If not using existing (manual entry), always show fields
        return true;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CONTACT SYNC METHODS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Check if contact information was changed
     */
    hasContactInfoChanged(oldData, newData) {
        return oldData.firstName !== newData.firstName ||
               oldData.lastName !== newData.lastName ||
               oldData.email !== newData.email ||
               oldData.phone !== newData.phone ||
               oldData.portalAccess !== newData.portalAccess;
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

    /**
     * @api Sync contact data when updated from another section
     */
    @api
    syncContactData(contactId, contactData) {
        let updated = false;
        
        // Update account holder if it matches
        if (this.selectedContact?.Id === contactId) {
            this.accountHolderData = {
                ...this.accountHolderData,
                firstName: contactData.firstName || this.accountHolderData.firstName,
                lastName: contactData.lastName || this.accountHolderData.lastName,
                email: contactData.email || this.accountHolderData.email,
                portalAccess: contactData.portalAccess || this.accountHolderData.portalAccess
            };
            updated = true;
        }
        
        // Update billing contact if it matches
        if (this.selectedBillingContact?.Id === contactId) {
            this.billingContactData = {
                ...this.billingContactData,
                firstName: contactData.firstName || this.billingContactData.firstName,
                lastName: contactData.lastName || this.billingContactData.lastName,
                email: contactData.email || this.billingContactData.email,
                phone: contactData.phone || this.billingContactData.phone,
                portalAccess: contactData.portalAccess || this.billingContactData.portalAccess
            };
            updated = true;
        }
        
        if (updated) {
            // Force UI update
            this.accountHolderData = {...this.accountHolderData};
            this.billingContactData = {...this.billingContactData};
        }
    }
}