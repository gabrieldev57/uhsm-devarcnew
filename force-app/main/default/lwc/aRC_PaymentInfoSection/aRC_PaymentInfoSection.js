import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountBillingAddress from '@salesforce/apex/ARC_PaymentInfoController.getAccountBillingAddress';
import getChargentOrder from '@salesforce/apex/ARC_PaymentInfoController.getChargentOrder';
import getPaymentContacts from '@salesforce/apex/ARC_PaymentInfoController.getPaymentContacts';
import savePaymentInformation from '@salesforce/apex/ARC_BusinessFormController.savePaymentInformation';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';

/**
 * ARC_PaymentInfoSection - Self-contained Payment Information section
 * 
 * @description Handles payment info collection with its own validation and save.
 *              Retrieves existing ChargentOrder data if available.
 * 
 * Events:
 *   - save: Fired after save attempt { detail: { section, data, isValid, errors } }
 */
export default class ARC_PaymentInfoSection extends LightningElement {
    /** @api Record Id (Opportunity Id) from parent */
    @api recordId;
    
    accountBillingAddress = null;
    isLoading = false;
    hasExistingOrder = false;
    chargentOrderId = null;
    isInitialLoad = true; // Track if we're in initial load phase
    
    // Contact data
    contactsData = null;
    
    // Store the retrieved billing address (from ChargentOrder or user entry)
    // This is used to restore the address when toggling back to "Yes"
    retrievedBillingAddress = null;
    
    @track isSaving = false;
    @track sectionStatus = 'not-started';

    // Custom icon URL for section header
    sectionIconUrl = `${SGFormIcons}/card.svg`;
    
    @track paymentInfo = {
        isBillingAddressDifferent: false,
        billingAddress: {
            street: '',
            city: '',
            state: '',
            zipCode: ''
        },
        paymentMethod: 'bank',
        bankData: {},
        creditCardData: null,
        accountHolder: null,
        billingContact: null
    };

    // Options for Yes/No radio groups (used by aRC_RadioGroup)
    yesNoOptions = [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
    ];

    connectedCallback() {
        this.loadPaymentInformation();
    }

    async loadPaymentInformation() {
        if (!this.recordId) {
            console.warn('No recordId provided, cannot load payment information');
            return;
        }
        
        this.isLoading = true;
        try {
            // Load account billing address, chargent order, and contacts in parallel
            const [accountResult, chargentOrder, contactsResult] = await Promise.all([
                getAccountBillingAddress({ opportunityId: this.recordId }),
                getChargentOrder({ opportunityId: this.recordId }),
                getPaymentContacts({ opportunityId: this.recordId })
            ]);
            
            // Store contacts data
            if (contactsResult) {
                this.contactsData = contactsResult;
                
                // Populate paymentInfo with contact data for isComplete() validation
                if (contactsResult.accountHolder) {
                    this.paymentInfo.accountHolder = {
                        sameAsPrimary: contactsResult.primaryBusinessContact && 
                                      contactsResult.accountHolder.id === contactsResult.primaryBusinessContact.id,
                        useExisting: true,
                        contactId: contactsResult.accountHolder.id,
                        isNew: false,
                        data: contactsResult.accountHolder
                    };
                }
                
                if (contactsResult.billingContact) {
                    this.paymentInfo.billingContact = {
                        sameAsAccountHolder: contactsResult.accountHolder && 
                                           contactsResult.billingContact.id === contactsResult.accountHolder.id,
                        useExisting: true,
                        contactId: contactsResult.billingContact.id,
                        isNew: false,
                        data: contactsResult.billingContact
                    };
                }
            }
            
            // Store account billing address
            if (accountResult) {
                this.accountBillingAddress = {
                    street: accountResult.BillingStreet || '',
                    city: accountResult.BillingCity || '',
                    state: accountResult.BillingState || '',
                    zipCode: accountResult.BillingPostalCode || ''
                };
            }
            
            // If ChargentOrder exists, populate fields
            if (chargentOrder) {
                this.hasExistingOrder = true;
                this.chargentOrderId = chargentOrder.id;
                
                // Check if required payment fields are complete
                const hasCompletePaymentData = this.isPaymentDataComplete(chargentOrder);
                
                // Check if ChargentOrder has a billing address
                const orderHasBillingAddress = chargentOrder.billingStreet || 
                                                chargentOrder.billingCity || 
                                                chargentOrder.billingState || 
                                                chargentOrder.billingZip;
                
                if (orderHasBillingAddress) {
                    // Set billing address from ChargentOrder
                    const orderBillingAddress = {
                        street: chargentOrder.billingStreet || '',
                        city: chargentOrder.billingCity || '',
                        state: chargentOrder.billingState || '',
                        zipCode: chargentOrder.billingZip || ''
                    };
                    this.paymentInfo.billingAddress = orderBillingAddress;
                    
                    // Store retrieved address for restore on toggle
                    this.retrievedBillingAddress = { ...orderBillingAddress };
                    
                    // Compare addresses to set the radio
                    this.paymentInfo.isBillingAddressDifferent = this.areBillingAddressesDifferent(
                        orderBillingAddress,
                        this.accountBillingAddress
                    );// ? false : true; 
                } else {
                    // ChargentOrder has no billing address - use Account billing address
                    if (this.accountBillingAddress) {
                        this.paymentInfo.billingAddress = { ...this.accountBillingAddress };
                    }
                    this.paymentInfo.isBillingAddressDifferent = false;
                    this.retrievedBillingAddress = null;
                }
                
                // Set payment method
                this.paymentInfo.paymentMethod = chargentOrder.paymentMethod || 'bank';
                
                // Set bank data if bank payment - show masked values
                if (chargentOrder.paymentMethod === 'bank') {
                    this.paymentInfo.bankData = {
                        financialInstitutionName: chargentOrder.bankName || '',
                        // Routing number: Show all asterisks (encrypted field, no last 4 available)
                        routingNumber: chargentOrder.routingNumber ? '**********' : '',
                        // Account number: Show masked with last 4 digits
                        accountNumber: chargentOrder.bankLast4 ? `*****${chargentOrder.bankLast4}` : '',
                        // Store original last 4 to detect changes
                        _originalLast4: chargentOrder.bankLast4 || ''
                    };
                }
                
                // Set card data if card payment - show masked values with last 4
                if (chargentOrder.paymentMethod === 'card') {
                    // Format expiration date as MM/YY
                    let expirationDate = '';
                    if (chargentOrder.cardExpirationMonth && chargentOrder.cardExpirationYear) {
                        const month = String(chargentOrder.cardExpirationMonth).padStart(2, '0');
                        // Convert year from 2025 format to 25
                        const yearStr = String(chargentOrder.cardExpirationYear);
                        const year = yearStr.length === 4 ? yearStr.slice(-2) : yearStr;
                        expirationDate = `${month}/${year}`;
                    }

                    this.paymentInfo.creditCardData = {
                        // Show masked card number with last 4 digits
                        cardNumber: chargentOrder.cardLast4 ? `************${chargentOrder.cardLast4}` : '',
                        expirationMonth: chargentOrder.cardExpirationMonth || '',
                        expirationYear: chargentOrder.cardExpirationYear || '',
                        expirationDate: expirationDate,
                        // Store original last 4 to detect changes
                        _originalLast4: chargentOrder.cardLast4 || ''
                    };
                }
                
                // Set status based on data completeness
                if (this.isComplete()) {
                    this.sectionStatus = 'complete';
                } else if (this.paymentInfo.paymentMethod || this.paymentInfo.billingAddress?.street) {
                    this.sectionStatus = 'in-progress';
                } else {
                    this.sectionStatus = 'not-started';
                }
                
                // Mark initial load complete after setting status
                this.isInitialLoad = false;
                
            } else {
                // No existing order - use account billing address as default
                this.hasExistingOrder = false;
                if (this.accountBillingAddress) {
                    this.paymentInfo.billingAddress = { ...this.accountBillingAddress };
                }
                this.paymentInfo.isBillingAddressDifferent = false;
                
                // Mark initial load complete for new payment info
                this.isInitialLoad = false;
            }
            
            // Force reactivity by reassigning the entire paymentInfo object
            this.paymentInfo = { ...this.paymentInfo };
            
        } catch (error) {
            console.error('Error loading payment information:', error);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Check if ChargentOrder has all required payment data
     * @param {Object} chargentOrder - ChargentOrder record
     * @returns {Boolean} Whether payment data is complete
     */
    isPaymentDataComplete(chargentOrder) {
        if (!chargentOrder) return false;
        
        const paymentMethod = chargentOrder.paymentMethod;
        
        // Check billing address is complete
        const hasBillingAddress = chargentOrder.billingStreet && 
                                 chargentOrder.billingCity && 
                                 chargentOrder.billingState && 
                                 chargentOrder.billingZip;
        
        if (!hasBillingAddress) return false;
        
        // Check payment method specific fields
        if (paymentMethod === 'bank') {
            // Bank requires: financial institution name, routing number (encrypted), account last 4
            return !!(chargentOrder.bankName && 
                     chargentOrder.routingNumber && 
                     chargentOrder.bankLast4);
        } else if (paymentMethod === 'card') {
            // Credit card requires: card last 4, expiration month, expiration year
            return !!(chargentOrder.cardLast4 && 
                     chargentOrder.cardExpirationMonth && 
                     chargentOrder.cardExpirationYear);
        }
        
        return false;
    }

    /**
     * Compare two billing addresses to check if they're different
     * Handles state abbreviations (e.g., CO vs Colorado)
     */
    areBillingAddressesDifferent(addr1, addr2) {
        if (!addr1 || !addr2) return false;
        
        const normalize = (str) => (str || '').trim().toLowerCase();
        const normalizeState = (state) => {
            const stateStr = normalize(state);
            // Map of state abbreviations to full names
            const stateMap = {
                'al': 'alabama', 'ak': 'alaska', 'az': 'arizona', 'ar': 'arkansas',
                'ca': 'california', 'co': 'colorado', 'ct': 'connecticut', 'de': 'delaware',
                'fl': 'florida', 'ga': 'georgia', 'hi': 'hawaii', 'id': 'idaho',
                'il': 'illinois', 'in': 'indiana', 'ia': 'iowa', 'ks': 'kansas',
                'ky': 'kentucky', 'la': 'louisiana', 'me': 'maine', 'md': 'maryland',
                'ma': 'massachusetts', 'mi': 'michigan', 'mn': 'minnesota', 'ms': 'mississippi',
                'mo': 'missouri', 'mt': 'montana', 'ne': 'nebraska', 'nv': 'nevada',
                'nh': 'new hampshire', 'nj': 'new jersey', 'nm': 'new mexico', 'ny': 'new york',
                'nc': 'north carolina', 'nd': 'north dakota', 'oh': 'ohio', 'ok': 'oklahoma',
                'or': 'oregon', 'pa': 'pennsylvania', 'ri': 'rhode island', 'sc': 'south carolina',
                'sd': 'south dakota', 'tn': 'tennessee', 'tx': 'texas', 'ut': 'utah',
                'vt': 'vermont', 'va': 'virginia', 'wa': 'washington', 'wv': 'west virginia',
                'wi': 'wisconsin', 'wy': 'wyoming'
            };
            
            // Check if it's an abbreviation and convert to full name
            if (stateMap[stateStr]) {
                return stateMap[stateStr];
            }
            
            // Check if it's a full name that matches an abbreviation value
            for (const [abbr, fullName] of Object.entries(stateMap)) {
                if (fullName === stateStr) {
                    return fullName;
                }
            }
            
            return stateStr;
        };
        
        return normalize(addr1.street) !== normalize(addr2.street) ||
               normalize(addr1.city) !== normalize(addr2.city) ||
               normalizeState(addr1.state) !== normalizeState(addr2.state) ||
               normalize(addr1.zipCode) !== normalize(addr2.zipCode);
    }

    get paymentMethodData() {
        return {
            method: this.paymentInfo.paymentMethod,
            bankData: this.paymentInfo.bankData,
            cardData: this.paymentInfo.creditCardData,
            contacts: this.contactsData
        };
    }

    get billingAddressDifferentValue() {
        return this.paymentInfo.isBillingAddressDifferent ? 'no' : 'yes';
    }

    get isBillingAddressReadOnly() {
        return !this.paymentInfo.isBillingAddressDifferent;
    }

    @api
    get status() {
        return this.sectionStatus;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPER METHODS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Set status to in-progress when user starts editing (if not already complete)
     * Also marks initial load as complete since user is now interacting
     */
    setInProgress() {
        // User interaction means we're past initial load
        this.isInitialLoad = false;
        
        if (this.sectionStatus !== 'complete') {
            this.sectionStatus = 'in-progress';
        }
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
     * @api Refresh payment contacts data (called when Contact Section is saved)
     */
    @api
    async refreshContacts() {
        try {
            const contactsResult = await getPaymentContacts({ opportunityId: this.recordId });
            if (contactsResult) {
                this.contactsData = contactsResult;
                
                // Update paymentInfo with contact data for isComplete() validation
                if (contactsResult.accountHolder) {
                    this.paymentInfo.accountHolder = {
                        sameAsPrimary: contactsResult.primaryBusinessContact && 
                                      contactsResult.accountHolder.id === contactsResult.primaryBusinessContact.id,
                        useExisting: true,
                        contactId: contactsResult.accountHolder.id,
                        isNew: false,
                        data: contactsResult.accountHolder
                    };
                }
                
                if (contactsResult.billingContact) {
                    this.paymentInfo.billingContact = {
                        sameAsAccountHolder: contactsResult.accountHolder && 
                                           contactsResult.billingContact.id === contactsResult.accountHolder.id,
                        useExisting: true,
                        contactId: contactsResult.billingContact.id,
                        isNew: false,
                        data: contactsResult.billingContact
                    };
                }
                
                // Update payment method component with fresh contact data
                const paymentMethod = this.template.querySelector('c-a-r-c_-payment-method');
                if (paymentMethod) {
                    paymentMethod.setContactsData(contactsResult);
                }
                console.log('Payment contacts refreshed', JSON.stringify(contactsResult,null,2));
            }
        } catch (error) {
            console.error('Error refreshing payment contacts:', error);
        }
    }

    @api
    getData() {
        return { ...this.paymentInfo };
    }

    @api
    setData(data) {
        if (data) {
            this.paymentInfo = { ...this.paymentInfo, ...data };
        }
    }

    /**
     * @api Update the group account address when Business Details changes
     * This handles the sync logic based on whether payment was saved or not
     */
    @api
    updateGroupAccountAddress(newAddress) {
        if (!newAddress) return;
        
        // Update the stored account billing address
        this.accountBillingAddress = { ...newAddress };
        
        // Scenario 1: Payment NOT saved yet (no ChargentOrder exists)
        // Update billing address if using group account address
        if (!this.hasExistingOrder) {
            if (!this.paymentInfo.isBillingAddressDifferent) {
                // Using group account address - update it
                this.paymentInfo.billingAddress = { ...newAddress };
                this.paymentInfo = { ...this.paymentInfo }; // Force reactivity
            }
            return;
        }
        
        // Scenario 2: Payment WAS saved (ChargentOrder exists)
        // Only update UI state if using group account address
        if (!this.paymentInfo.isBillingAddressDifferent) {
            // Currently using group account address - update the display
            this.paymentInfo.billingAddress = { ...newAddress };
            
            // Check if addresses are now different
            // If different, we need to change the radio to "Yes" automatically
            const nowDifferent = this.areBillingAddressesDifferent(
                this.retrievedBillingAddress || {},
                newAddress
            );// ? false : true;
            
            if (nowDifferent && this.retrievedBillingAddress) {
                // Addresses no longer match - switch to "different" mode
                // Restore the saved ChargentOrder billing address
                this.paymentInfo.isBillingAddressDifferent = true;
                this.paymentInfo.billingAddress = { ...this.retrievedBillingAddress };
            }
            
            this.paymentInfo = { ...this.paymentInfo }; // Force reactivity
        }
        // If isBillingAddressDifferent is true, do nothing - user has custom address
        // ChargentOrder billing address remains unchanged
    }

    // ═══════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Validate all fields in this section using standard Salesforce field validation
     * @returns {Object} { isValid: Boolean, errors: Array<String> }
     */
    validate() {
        const isValid = this.reportFieldValidity();
        // Don't update status here - that's handled by isComplete()

        return {
            isValid: isValid,
            errors: []
        };
    }

    /**
     * Check if section is complete (all required fields filled)
     * This determines the section status, not whether save is allowed
     * @returns {Boolean} Whether all required fields have values
     */
    isComplete() {
        // During initial load, always check stored data even if components exist
        // because components haven't been initialized with loaded data yet
        // const paymentMethod = this.template.querySelector('c-a-r-c_-payment-method');
        // const addressBlock = this.template.querySelector('c-a-r-c_-address-block');
        
        // If components don't exist yet OR we're in initial load, check stored data directly
        if (this.paymentInfo) {
            console.log('IsComplete DAta', JSON.stringify(this.paymentInfo,null,2));
            // Check billing address
            const hasBillingAddress = this.paymentInfo.billingAddress && 
                                     this.paymentInfo.billingAddress.street && 
                                     this.paymentInfo.billingAddress.city && 
                                     this.paymentInfo.billingAddress.state && 
                                     this.paymentInfo.billingAddress.zipCode;
            if (!hasBillingAddress) {
                return false;
            }
            
            // Check payment method and data
            if (this.paymentInfo.paymentMethod === 'bank') {
                if (!this.paymentInfo.bankData || !this.paymentInfo.bankData.financialInstitutionName || !this.paymentInfo.bankData.accountNumber || !this.paymentInfo.bankData.routingNumber) {
                    return false;
                }
            } else if (this.paymentInfo.paymentMethod === 'card') {
                if (!this.paymentInfo.creditCardData || !this.paymentInfo.creditCardData.cardNumber ||
                    !this.paymentInfo.creditCardData.expirationMonth || 
                    !this.paymentInfo.creditCardData.expirationYear) {
                    return false;
                }
            } else {
                return false;
            }

            // Account holder form: firstName, lastName, email, portalAccess, street, city, state, zip
            const hasRequiredAccountHolderFields = (c) =>
                c && c.firstName && c.lastName && c.email && c.portalAccess && c.street && c.city && c.state && c.zip;
            // Billing contact form: firstName, lastName, title, email, portalAccess, phone
            const hasRequiredBillingContactFields = (c) =>
                c && c.firstName && c.lastName && c.title && c.email && c.portalAccess && c.phone;

            const accountHolder = this.paymentInfo.accountHolder;
            if (!accountHolder) return false;
            if (!accountHolder.sameAsPrimary) {
                if (!hasRequiredAccountHolderFields(accountHolder.data || accountHolder)) return false;
            }

            const billingContact = this.paymentInfo.billingContact;
            if (!billingContact) return false;
            if (!billingContact.sameAsAccountHolder) {
                if (!hasRequiredBillingContactFields(billingContact.data || billingContact)) return false;
            }

            return true;
        }else{
            return false;
        }
        
        // Components exist and initialized - use them for validation (during save/after render)
        
        // Get the current billing address - prefer stored data over component value
        // Component value might be empty if it hasn't fully initialized yet
        // const billingAddress = this.paymentInfo.billingAddress || addressBlock.value;
        
        // // Check billing address is complete
        // const hasBillingAddress = billingAddress && 
        //                          billingAddress.street && 
        //                          billingAddress.city && 
        //                          billingAddress.state && 
        //                          billingAddress.zipCode;
        
        // if (!hasBillingAddress) {
        //     return false;
        // }
        
        // // Get payment data to check completeness
        // const paymentData = paymentMethod.getPaymentData();
        // if (!paymentData) {
        //     return false;
        // }
        
        // // Check account holder exists (handle both direct and nested data structure)
        // const accountHolder = paymentData.accountHolder;
        // console.log('Account Holder: ' + JSON.stringify(accountHolder,null,2));
        // if (!accountHolder) {
        //     return false;
        // }
        
        
        // // Account holder can be: useExisting contact OR new contact with data
        // const accountHolderData = accountHolder.data || accountHolder;
        // if (!accountHolderData || !accountHolderData.firstName || !accountHolderData.lastName) {
        //     return false;
        // }
        
        // // Check billing contact exists (handle same as account holder case)
        // const billingContact = paymentData.billingContact;
        // console.log('Billing Contact: ' + JSON.stringify(billingContact,null,2));
        // if (!billingContact) {
        //     return false;
        // }
        
        
        // // If billing contact is same as account holder, it's valid
        // if (!billingContact.sameAsAccountHolder) {
        //     const billingContactData = billingContact.data || billingContact;
        //     if (!billingContactData || !billingContactData.firstName || !billingContactData.lastName) {
        //         return false;
        //     }
        // }
        
        // // Check payment method specific fields
        // if (paymentData.method === 'bank') {
        //     const bankData = paymentData.data;
        //     if (!bankData || !bankData.financialInstitutionName) {
        //         return false;
        //     }
        // } else if (paymentData.method === 'card') {
        //     const cardData = paymentData.data;
        //     if (!cardData || !cardData.expirationMonth || !cardData.expirationYear) {
        //         return false;
        //     }
        // } else {
        //     return false;
        // }
        
        // return true;
    }

    /**
     * Report validity on all lightning-input fields to show red borders
     * @returns {Boolean} Whether all fields are valid
     */
    reportFieldValidity() {
        let isValid = true;

        // Report validity on all lightning-input fields in this section
        const inputs = this.template.querySelectorAll('lightning-input');
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        // Report validity on address block if it exists
        const addressBlock = this.template.querySelector('c-a-r-c_-address-block');
        if (addressBlock && addressBlock.reportValidity) {
            if (!addressBlock.reportValidity()) {
                isValid = false;
            }
        }

        // Report validity on payment method component
        const paymentMethod = this.template.querySelector('c-a-r-c_-payment-method');
        if (paymentMethod && paymentMethod.reportValidity) {
            if (!paymentMethod.reportValidity()) {
                isValid = false;
            }
        }

        return isValid;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    handleBillingAddressDifferentChange(event) {
        const isDifferent = event.detail.value === 'no';
        this.paymentInfo.isBillingAddressDifferent = isDifferent;
        
        if (!isDifferent) {
            // User selected "No" (same as account) - use account billing address
            if (this.accountBillingAddress) {
                this.paymentInfo.billingAddress = { ...this.accountBillingAddress };
            }
        } else {
            // User selected "Yes" (different from account)
            // Restore the retrieved address if it exists and is not blank
            if (this.retrievedBillingAddress && this.hasNonBlankAddress(this.retrievedBillingAddress)) {
                this.paymentInfo.billingAddress = { ...this.retrievedBillingAddress };
            } else if (this.hasNonBlankAddress(this.paymentInfo.billingAddress)) {
                // Keep current address if it has data (user may have typed something)
                // Don't clear it - just leave it as is
            } else {
                // Clear only if no previous data exists
                this.paymentInfo.billingAddress = {
                    street: '',
                    city: '',
                    state: '',
                    zipCode: ''
                };
            }
        }
        
        this.setInProgress();
        this.dispatchChangeEvent();
    }
    
    /**
     * Check if an address has any non-blank fields
     */
    hasNonBlankAddress(address) {
        if (!address) return false;
        return !!(address.street || address.city || address.state || address.zipCode);
    }

    handleBillingAddressChange(event) {
        this.paymentInfo.billingAddress = { ...event.detail.address };
        
        // Update retrieved address when user types (if different from account)
        if (this.paymentInfo.isBillingAddressDifferent) {
            this.retrievedBillingAddress = { ...event.detail.address };
        }
        
        this.setInProgress();
    }

    handlePaymentMethodChange(event) {
        const { method, data, accountHolder, billingContact } = event.detail;
        this.paymentInfo.paymentMethod = method;
        
        // Store account holder and billing contact data
        this.paymentInfo.accountHolder = accountHolder;
        this.paymentInfo.billingContact = billingContact;
        
        // Update the current method's data WITHOUT clearing the other method's data
        if (method === 'bank') {
            this.paymentInfo.bankData = data;
            // Don't clear creditCardData - preserve it for when user switches back
        } else if (method === 'card') {
            this.paymentInfo.creditCardData = data;
            // Don't clear bankData - preserve it for when user switches back
        }
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    dispatchChangeEvent() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: { section: 'paymentInfo', data: this.getData() }
        }));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SAVE HANDLER
    // ═══════════════════════════════════════════════════════════════════════

    async handleSave() {
        // Validate contact fields before saving
        console.log('Validating contacts before save', JSON.stringify(this.paymentInfo,null,2));
        // Account holder form: firstName, lastName, email, portalAccess, street, city, state, zip
        const hasRequiredAccountHolderFields = (c) =>
            c && c.firstName && c.lastName && c.email && c.portalAccess && c.street && c.city && c.state && c.zip;
        // Billing contact form: firstName, lastName, title, email, portalAccess, phone
        const hasRequiredBillingContactFields = (c) =>
            c && c.firstName && c.lastName && c.title && c.email && c.portalAccess && c.phone;

        const accountHolder = this.paymentInfo.accountHolder;
        if (!accountHolder) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation Error', message: 'Account Holder is required.', variant: 'error' }));
            return;
        }
        if (!accountHolder.sameAsPrimary) {
            const ahData = accountHolder.data || accountHolder;
            if (!hasRequiredAccountHolderFields(ahData)) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Validation Error', message: 'Account Holder is missing required fields (First Name, Last Name, Email, Portal Access, Street, City, State, Zip).', variant: 'error' }));
                return;
            }
        }

        const billingContact = this.paymentInfo.billingContact;
        if (!billingContact) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation Error', message: 'Billing Contact is required.', variant: 'error' }));
            return;
        }
        if (!billingContact.sameAsAccountHolder) {
            const bcData = billingContact.data || billingContact;
            if (!hasRequiredBillingContactFields(bcData)) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Validation Error', message: 'Billing Contact is missing required fields (First Name, Last Name, Title, Email, Portal Access, Phone).', variant: 'error' }));
                return;
            }
        }

        this.isSaving = true;

        try {
            // Build payment data for Apex
            const paymentData = this.buildPaymentDataForSave();
            console.log('Saving payment data to Apex:', JSON.stringify(paymentData,null,2));
            
            // Call Apex to save - pass chargentOrderId if we have an existing order
            const result = await savePaymentInformation({ 
                opportunityId: this.recordId,
                chargentOrderId: this.chargentOrderId,
                paymentData: paymentData
            });

            if (result.isSuccess) {
                await this.refreshContacts(); // Refresh contacts after save 
                // Store chargentOrderId if a new order was created
                if (result.recordId && !this.chargentOrderId) {
                    this.chargentOrderId = result.recordId;
                    this.hasExistingOrder = true;
                }
                
                // Update contact IDs in payment method component so they're not recreated on next save
                if (result.data) {
                    const paymentMethod = this.template.querySelector('c-a-r-c_-payment-method');
                    if (paymentMethod) {
                        paymentMethod.updateContactIds(
                            result.data.accountHolderContactId,
                            result.data.billingContactId
                        );
                    }
                }
                
                // Update paymentInfo.billingAddress with the actual saved value
                const addressBlock = this.template.querySelector('c-a-r-c_-address-block');
                if (addressBlock && addressBlock.value) {
                    this.paymentInfo.billingAddress = { ...addressBlock.value };
                    // Update retrieved address for future toggles
                    if (this.paymentInfo.isBillingAddressDifferent) {
                        this.retrievedBillingAddress = { ...addressBlock.value };
                    }
                }
                
                // Update status based on completion
                this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';

                // Show success toast
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Payment information saved successfully.',
                    variant: 'success'
                }));

                // Notify parent
                this.dispatchEvent(new CustomEvent('save', {
                    detail: { 
                        section: 'paymentInfo', 
                        data: this.getData(),
                        isValid: true,
                        errors: []
                    }
                }));

                // Collapse section after successful save
                const section = this.template.querySelector('c-a-r-c_-collapsible-section');
                if (section) {
                    section.notifySaved();
                }
            } else {
                // Handle save failure - show error toast with actual error message from Apex
                this.sectionStatus = 'error';
                
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Unable to Save Payment Information',
                    message: result.message || 'There was a problem saving your payment details.',
                    variant: 'error',
                    mode: 'sticky'
                }));
            }

        } catch (error) {
            console.error('Error saving payment info:', error);
            this.sectionStatus = 'error';
            
            // Extract error message from Apex exception
            let errorMessage = 'An unexpected error occurred. Please try again or contact support if the problem persists.';
            if (error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error.message) {
                errorMessage = error.message;
            }
            
            // Show error toast with actual error message
            this.dispatchEvent(new ShowToastEvent({
                title: 'Unable to Save Payment Information',
                message: errorMessage,
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * Build the payment data object for Apex save
     * Only include bank/card numbers if they've been changed (not masked values)
     * @returns {Object} Payment data formatted for Apex
     */
    buildPaymentDataForSave() {
        const paymentMethod = this.template.querySelector('c-a-r-c_-payment-method');
        const paymentMethodData = paymentMethod ? paymentMethod.getPaymentData() : null;

        // Get billing address directly from the address block component to ensure we have the latest value
        const addressBlock = this.template.querySelector('c-a-r-c_-address-block');
        const billingAddress = addressBlock ? addressBlock.value : this.paymentInfo.billingAddress;
        

        let data = null;
        
        if (this.paymentInfo.paymentMethod === 'bank') {
            const bankData = paymentMethodData?.data || this.paymentInfo.bankData;
            data = {
                financialInstitutionName: bankData.financialInstitutionName || ''
            };
            // Only include routing/account numbers if they're not masked (user entered new values)
            if (bankData.routingNumber && !bankData.routingNumber.startsWith('*')) {
                data.routingNumber = bankData.routingNumber;
            }
            if (bankData.accountNumber && !bankData.accountNumber.startsWith('*')) {
                data.accountNumber = bankData.accountNumber;
            }
        } else {
            const cardData = paymentMethodData?.data || this.paymentInfo.creditCardData;
            data = {};
            // Only include card number if it's not masked (user entered new value)
            if (cardData?.cardNumber && !cardData.cardNumber.startsWith('*')) {
                data.cardNumber = cardData.cardNumber;
            }
            if (cardData?.expirationMonth) {
                data.expirationMonth = cardData.expirationMonth;
            }
            if (cardData?.expirationYear) {
                data.expirationYear = cardData.expirationYear;
            }
        }

        return {
            method: this.paymentInfo.paymentMethod,
            data: data,
            accountHolder: paymentMethodData?.accountHolder || this.paymentInfo.accountHolder,
            billingContact: paymentMethodData?.billingContact || this.paymentInfo.billingContact,
            billingAddress: billingAddress
        };
    }

    /**
     * @api Sync contact data when updated from another section
     */
    @api
    syncContactData(contactId, contactData) {
        // Sync with child payment method components
        const bankComponent = this.template.querySelector('c-a-r-c_-bank-account-form');
        const cardComponent = this.template.querySelector('c-a-r-c_-credit-card-form');
        
        if (bankComponent && typeof bankComponent.syncContactData === 'function') {
            bankComponent.syncContactData(contactId, contactData);
        }
        
        if (cardComponent && typeof cardComponent.syncContactData === 'function') {
            cardComponent.syncContactData(contactId, contactData);
        }
    }
}