import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import getPaymentMethod from '@salesforce/apex/ARC_CompanyDetailsController.getPaymentMethod';
import updatePaymentMethod from '@salesforce/apex/ARC_CompanyDetailsController.updatePaymentMethod';
import loadCompanyContacts from '@salesforce/apex/ARC_CompanyDetailsController.loadCompanyContacts';
import { refreshApex } from '@salesforce/apex';

export default class aRC_editPaymentMethodModal extends LightningModal {
    @api recordId;

    order;
    isReady = false;

    cardNumber;
    bankAccountNumber;
    wiredPaymentResult;
    accountHolderPreloaded = false;
    billingContactPreloaded = false;

    showSuccessMessage = false;
    showErrorMessage = false;
    errorMessage = '';

    // Account Holder
    sameAsPrimaryContact = 'Yes';
    useExistingContact = 'Yes';
    existingContactId;
    selectedExistingContactId;
    accountId;
    newContact = {
        FirstName: '',
        LastName: '',
        Email: '',
        PortalAccess: ''
    };

    // Billing Contact
    sameAsAccountHolder = 'Yes';
    useExistingBillingContact = 'Yes';
    selectedExistingBillingContactId;
    billingContact = {
        FirstName: '',
        LastName: '',
        Title: '',
        Email: '',
        Phone: '',
        PortalAccess: ''
    };

    // Billing Address
    billingAddressDifferent = 'No';
    billingAddressDisabled = true;
    billingAddress = {
        Street: '',
        City: '',
        State: '',
        PostalCode: ''
    };

    // Expiration Date
    expirationInput = '';
    expirationMonth;
    expirationYear;
    accountBillingAddress = null;

    // Options
    portalAccessOptions = [
        { label: 'No Access', value: 'No Access' },
        { label: 'Viewer', value: 'Viewer' },
        { label: 'Admin', value: 'Admin' }
    ];

    paymentMethodOptions = [
        { label: 'Credit Card', value: 'Credit Card' },
        { label: 'Bank Account', value: 'Bank Account' }
    ];

    yesNoOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];

    stateOptions = [
        { label: 'Alabama', value: 'AL' }, { label: 'Alaska', value: 'AK' }, { label: 'Arizona', value: 'AZ' },
        { label: 'Arkansas', value: 'AR' }, { label: 'California', value: 'CA' }, { label: 'Colorado', value: 'CO' },
        { label: 'Connecticut', value: 'CT' }, { label: 'Delaware', value: 'DE' }, { label: 'Florida', value: 'FL' },
        { label: 'Georgia', value: 'GA' }, { label: 'Hawaii', value: 'HI' }, { label: 'Idaho', value: 'ID' },
        { label: 'Illinois', value: 'IL' }, { label: 'Indiana', value: 'IN' }, { label: 'Iowa', value: 'IA' },
        { label: 'Kansas', value: 'KS' }, { label: 'Kentucky', value: 'KY' }, { label: 'Louisiana', value: 'LA' },
        { label: 'Maine', value: 'ME' }, { label: 'Maryland', value: 'MD' }, { label: 'Massachusetts', value: 'MA' },
        { label: 'Michigan', value: 'MI' }, { label: 'Minnesota', value: 'MN' }, { label: 'Mississippi', value: 'MS' },
        { label: 'Missouri', value: 'MO' }, { label: 'Montana', value: 'MT' }, { label: 'Nebraska', value: 'NE' },
        { label: 'Nevada', value: 'NV' }, { label: 'New Hampshire', value: 'NH' }, { label: 'New Jersey', value: 'NJ' },
        { label: 'New Mexico', value: 'NM' }, { label: 'New York', value: 'NY' }, { label: 'North Carolina', value: 'NC' },
        { label: 'North Dakota', value: 'ND' }, { label: 'Ohio', value: 'OH' }, { label: 'Oklahoma', value: 'OK' },
        { label: 'Oregon', value: 'OR' }, { label: 'Pennsylvania', value: 'PA' }, { label: 'Rhode Island', value: 'RI' },
        { label: 'South Carolina', value: 'SC' }, { label: 'South Dakota', value: 'SD' }, { label: 'Tennessee', value: 'TN' },
        { label: 'Texas', value: 'TX' }, { label: 'Utah', value: 'UT' }, { label: 'Vermont', value: 'VT' },
        { label: 'Virginia', value: 'VA' }, { label: 'Washington', value: 'WA' }, { label: 'West Virginia', value: 'WV' },
        { label: 'Wisconsin', value: 'WI' }, { label: 'Wyoming', value: 'WY' }
    ];

    contactOptions = [];

    // ================= WIRE =================

    @wire(getPaymentMethod)
    wiredPayment(result) {
        this.wiredPaymentResult = result;
        const { data, error } = result;
        if (data) {
            this.order = { ...data.order };
            this.accountId = data.order.ChargentOrders__Account__c;
            this.isReady = true;

            // Prefill billing address
            this.billingAddress.Street = data.BillingStreet || '';
            this.billingAddress.City = data.BillingCity || '';
            this.billingAddress.State = this.getStateAbbreviation(data.BillingState);
            this.billingAddress.PostalCode = data.BillingPostalCode || '';

            this.accountBillingAddress = {
                Street: data.AccountBillingStreet || '',
                City: data.AccountBillingCity || '',
                State: this.getStateAbbreviation(data.AccountBillingState),
                PostalCode: data.AccountBillingPostalCode || ''
            };

            // Yes = same = fields disabled, No = different = fields enabled
            // const hasCustomBillingAddress = !!(data.BillingStreet || data.BillingCity || data.BillingState || data.BillingPostalCode);
            // if (hasCustomBillingAddress) {
            //     this.billingAddressDifferent = 'No';
            //     this.billingAddressDisabled = false;
            // } else {
            //     this.billingAddressDifferent = 'Yes';
            //     this.billingAddressDisabled = true;
            // }
            const orderAddress = {
                street: (data.BillingStreet || '').trim().toLowerCase(),
                city: (data.BillingCity || '').trim().toLowerCase(),
                state: this.getStateAbbreviation(data.BillingState || '').toLowerCase(),
                postalCode: (data.BillingPostalCode || '').trim().toLowerCase()
            };
            const accountAddress = {
                street: (data.AccountBillingStreet || '').trim().toLowerCase(),
                city: (data.AccountBillingCity || '').trim().toLowerCase(),
                state: this.getStateAbbreviation(data.AccountBillingState || '').toLowerCase(),
                postalCode: (data.AccountBillingPostalCode || '').trim().toLowerCase()
            };

            const isSameAsAccount = orderAddress.street === accountAddress.street &&
                                    orderAddress.city === accountAddress.city &&
                                    orderAddress.state === accountAddress.state &&
                                    orderAddress.postalCode === accountAddress.postalCode;

            this.billingAddressDifferent = isSameAsAccount ? 'Yes' : 'No';
            this.billingAddressDisabled = isSameAsAccount;

            if (this.order.ChargentOrders__Card_Expiration_Month__c && this.order.ChargentOrders__Card_Expiration_Year__c) {
                this.expirationMonth = this.order.ChargentOrders__Card_Expiration_Month__c;
                this.expirationYear = this.order.ChargentOrders__Card_Expiration_Year__c;
                this.expirationInput = `${this.expirationMonth}/${this.expirationYear}`;
            }

            // Prefill account holder radio
            if (data.isSameAsPrimaryContact !== null && data.isSameAsPrimaryContact !== undefined) {
                this.sameAsPrimaryContact = data.isSameAsPrimaryContact ? 'Yes' : 'No';
            }

            // Prefill account holder contact data if different from primary business contact
            if (!data.isSameAsPrimaryContact && data.accountHolderContact) {
                const ah = data.accountHolderContact;
                this.useExistingContact = 'Yes';
                this.selectedExistingContactId = ah.contactId;
                this.accountHolderPreloaded = true;
                this.newContact = {
                    FirstName: ah.firstName || '',
                    LastName: ah.lastName || '',
                    Email: ah.email || '',
                    PortalAccess: ah.portalAccess || ''
                };
            }

            // Prefill billing contact radio
            if (data.isBillingSameAsHolder !== null && data.isBillingSameAsHolder !== undefined) {
                this.sameAsAccountHolder = data.isBillingSameAsHolder ? 'Yes' : 'No';
            }

            // Prefill billing contact data if different from account holder
            if (!data.isBillingSameAsHolder && data.billingContactData) {
                const bc = data.billingContactData;
                this.useExistingBillingContact = 'Yes';
                this.selectedExistingBillingContactId = bc.contactId;
                this.billingContactPreloaded = true;
                this.billingContact = {
                    FirstName: bc.firstName || '',
                    LastName: bc.lastName || '',
                    Title: bc.title || '',
                    Email: bc.email || '',
                    Phone: bc.phone || '',
                    PortalAccess: bc.portalAccess || ''
                };
            }

        } else if (error) {
            console.error(error);
        }
    }

    @wire(loadCompanyContacts)
    wiredCompanyContacts({ data, error }) {
        if (data?.acrs) {
            this.contactOptions = data.acrs.map(acr => ({
                label: `${acr.Contact.FirstName} ${acr.Contact.LastName}`,
                value: acr.ContactId
            }));
        } else if (error) {
            console.error('Error loading company contacts', error);
        }
    }

    // ================= GETTERS =================

    get isCreditCard() { return this.order?.ChargentOrders__Payment_Method__c === 'Credit Card'; }
    get isBankAccount() { return this.order?.ChargentOrders__Payment_Method__c === 'Bank Account'; }

    get isExpirationValid() {
        return this.order?.ChargentOrders__Payment_Method__c !== 'Credit Card' || (this.expirationMonth && this.expirationYear);
    }

    get isSaveDisabled() {
        let valid = true;

        if (this.isBankAccount) {
            const hasBankInfo = !!this.order?.ChargentOrders__Bank_Name__c &&
                                !!this.order?.ChargentOrders__Bank_Routing_Number__c &&
                                !!this.bankAccountNumber;
            valid = valid && hasBankInfo;
        }

        if (this.isCreditCard) {
            valid = valid && this.isExpirationValid;
        }

        if (this.sameAsPrimaryContact === 'No') {
            if (this.useExistingContact === 'Yes') {
                valid = valid && !!this.selectedExistingContactId;
            } else if (this.useExistingContact === 'No') {
                valid = valid &&
                    !!this.newContact.FirstName &&
                    !!this.newContact.LastName &&
                    !!this.newContact.Email &&
                    !!this.newContact.PortalAccess;
            }
        }

        if (this.sameAsAccountHolder === 'No') {
            if (this.useExistingBillingContact === 'Yes') {
                valid = valid && !!this.selectedExistingBillingContactId;
            } else if (this.useExistingBillingContact === 'No') {
                valid = valid &&
                    !!this.billingContact.FirstName &&
                    !!this.billingContact.LastName &&
                    !!this.billingContact.Email &&
                    !!this.billingContact.PortalAccess;
            }
        }

        return !valid;
    }

    get showAccountHolderOptions() { return this.sameAsPrimaryContact === 'No'; }
    get useExistingContactYes() { return this.useExistingContact === 'Yes'; }
    get useExistingContactNo() { return this.useExistingContact === 'No'; }

    get showBillingContactOptions() { return this.sameAsAccountHolder === 'No'; }
    get useExistingBillingContactYes() { return this.useExistingBillingContact === 'Yes'; }
    get useExistingBillingContactNo() { return this.useExistingBillingContact === 'No'; }

    get showAccountHolderPreloadedInputs() {
        return this.useExistingContact === 'Yes' && this.accountHolderPreloaded;
    }

    get showBillingContactPreloadedInputs() {
        return this.useExistingBillingContact === 'Yes' && this.billingContactPreloaded;
    }

    // ================= HELPERS =================

    getStateAbbreviation(stateName) {
        if (!stateName) return '';
        const stateMap = {
            'alabama': 'AL', 'alaska': 'AK', 'arizona': 'AZ', 'arkansas': 'AR',
            'california': 'CA', 'colorado': 'CO', 'connecticut': 'CT', 'delaware': 'DE',
            'florida': 'FL', 'georgia': 'GA', 'hawaii': 'HI', 'idaho': 'ID',
            'illinois': 'IL', 'indiana': 'IN', 'iowa': 'IA', 'kansas': 'KS',
            'kentucky': 'KY', 'louisiana': 'LA', 'maine': 'ME', 'maryland': 'MD',
            'massachusetts': 'MA', 'michigan': 'MI', 'minnesota': 'MN', 'mississippi': 'MS',
            'missouri': 'MO', 'montana': 'MT', 'nebraska': 'NE', 'nevada': 'NV',
            'new hampshire': 'NH', 'new jersey': 'NJ', 'new mexico': 'NM', 'new york': 'NY',
            'north carolina': 'NC', 'north dakota': 'ND', 'ohio': 'OH', 'oklahoma': 'OK',
            'oregon': 'OR', 'pennsylvania': 'PA', 'rhode island': 'RI', 'south carolina': 'SC',
            'south dakota': 'SD', 'tennessee': 'TN', 'texas': 'TX', 'utah': 'UT',
            'vermont': 'VT', 'virginia': 'VA', 'washington': 'WA', 'west virginia': 'WV',
            'wisconsin': 'WI', 'wyoming': 'WY'
        };
        if (stateName.length === 2) return stateName.toUpperCase();
        return stateMap[stateName.toLowerCase()] || stateName;
    }

    // ================= HANDLERS =================

    handleExpirationChange(event) {
        let value = event.target.value.replace(/\D/g, '');
        if (value.length >= 3) value = value.substring(0, 2) + '/' + value.substring(2, 4);
        value = value.substring(0, 5);
        this.expirationInput = value;

        if (value.length === 5) {
            const [month, year] = value.split('/');
            const monthNum = parseInt(month, 10);
            this.expirationMonth = monthNum >= 1 && monthNum <= 12 ? month : null;
            this.expirationYear = monthNum >= 1 && monthNum <= 12 ? year : null;
        } else {
            this.expirationMonth = null;
            this.expirationYear = null;
        }
    }

    handleCancel() {
        this.close({ saved: false });
    }

    handleFieldChange(event) {
        const { name, value } = event.target;

        if (name.startsWith('newContact_')) {
            const fieldName = name.replace('newContact_', '');
            this.newContact = { ...this.newContact, [fieldName]: value };
        } else if (name.startsWith('billingContact_')) {
            const fieldName = name.replace('billingContact_', '');
            this.billingContact = { ...this.billingContact, [fieldName]: value };
        } else if (name.startsWith('billingAddress_')) {
            const fieldName = name.replace('billingAddress_', '');
            this.billingAddress = { ...this.billingAddress, [fieldName]: value };
        } else {
            switch (name) {
                case 'sameAsPrimaryContact':
                    this.sameAsPrimaryContact = value;
                    if (value === 'Yes') {
                        this.clearAccountHolderData();
                    }
                    break;
                case 'useExistingContact':
                    this.useExistingContact = value;
                    if (value === 'Yes') {
                        this.accountHolderPreloaded = false;
                        this.clearNewContactData();
                    } else {
                        this.accountHolderPreloaded = false;
                        this.selectedExistingContactId = null;
                    }
                    break;
                case 'sameAsAccountHolder':
                    this.sameAsAccountHolder = value;
                    if (value === 'Yes') {
                        this.clearBillingContactData();
                    }
                    break;
                case 'useExistingBillingContact':
                    this.useExistingBillingContact = value;
                    if (value === 'Yes') {
                        this.billingContactPreloaded = false;
                        this.clearNewBillingContactData();
                    } else {
                        this.billingContactPreloaded = false;
                        this.selectedExistingBillingContactId = null;
                    }
                    break;
                case 'billingAddressDifferent':
                    this.billingAddressDifferent = value;
                    this.billingAddressDisabled = value === 'Yes';
                    if (value === 'Yes') {
                        this.billingAddress = {
                            Street: this.accountBillingAddress?.Street || '',
                            City: this.accountBillingAddress?.City || '',
                            State: this.accountBillingAddress?.State || '',
                            PostalCode: this.accountBillingAddress?.PostalCode || ''
                        };
                    } else {
                        this.clearBillingAddressData();
                    }
                    break;
                    // this.billingAddressDifferent = value;
                    // this.billingAddressDisabled = value === 'Yes';
                    // if (value === 'Yes') {
                    //     this.clearBillingAddressData();
                    // }
                    // break;
                case 'cardNumber':
                    this.cardNumber = value;
                    break;
                case 'ChargentOrders__Bank_Account_Number__c':
                    this.bankAccountNumber = value;
                    break;
                case 'selectedExistingContactId':
                    this.selectedExistingContactId = value;
                    break;
                case 'selectedExistingBillingContactId':
                    this.selectedExistingBillingContactId = value;
                    break;
                default:
                    this.order = { ...this.order, [name]: value };
            }
        }
    }

    clearAccountHolderData() {
        this.selectedExistingContactId = null;
        this.clearNewContactData();
    }

    clearNewContactData() {
        this.newContact = {
            FirstName: '',
            LastName: '',
            Email: '',
            PortalAccess: ''
        };
    }

    clearBillingContactData() {
        this.selectedExistingBillingContactId = null;
        this.clearNewBillingContactData();
    }

    clearNewBillingContactData() {
        this.billingContact = {
            FirstName: '',
            LastName: '',
            Title: '',
            Email: '',
            Phone: '',
            PortalAccess: ''
        };
    }

    clearBillingAddressData() {
        this.billingAddress = {
            Street: '',
            City: '',
            State: '',
            PostalCode: ''
        };
    }

    async handleSave() {
        if (!this.validateInputs()) {
            return;
        }

        let accountHolderPayload = null;

        if (this.sameAsPrimaryContact === 'No') {
            if (this.useExistingContact === 'Yes' && this.selectedExistingContactId) {
                accountHolderPayload = {
                    action: 'SELECT',
                    accountId: this.accountId,
                    contact: { Id: this.selectedExistingContactId },
                    addressDTO: null,
                    isSameAsPrimaryContact: false
                };
            } else if (this.useExistingContact === 'No') {
                accountHolderPayload = {
                    action: 'CREATE',
                    accountId: this.accountId,
                    contact: {
                        FirstName: this.newContact.FirstName,
                        LastName: this.newContact.LastName,
                        Email: this.newContact.Email,
                        PortalAccess: this.newContact.PortalAccess
                    },
                    addressDTO: null,
                    isSameAsPrimaryContact: false
                };
            }
        } else {
            accountHolderPayload = {
                action: 'SELECT',
                accountId: this.accountId,
                contact: null,
                addressDTO: null,
                isSameAsPrimaryContact: true
            };
        }

        let billingContactPayload = null;

        if (this.sameAsAccountHolder === 'No') {
            if (this.useExistingBillingContact === 'Yes' && this.selectedExistingBillingContactId) {
                billingContactPayload = {
                    action: 'SELECT',
                    accountId: this.accountId,
                    contact: { Id: this.selectedExistingBillingContactId },
                    isSameAsAccountHolder: false
                };
            } else if (this.useExistingBillingContact === 'No') {
                billingContactPayload = {
                    action: 'CREATE',
                    accountId: this.accountId,
                    contact: {
                        FirstName: this.billingContact.FirstName,
                        LastName: this.billingContact.LastName,
                        Email: this.billingContact.Email,
                        Phone: this.billingContact.Phone,
                        Title: this.billingContact.Title,
                        PortalAccess: this.billingContact.PortalAccess
                    },
                    isSameAsAccountHolder: false
                };
            }
        } else {
            billingContactPayload = {
                action: 'SELECT',
                accountId: this.accountId,
                contact: null,
                isSameAsAccountHolder: true
            };
        }

        const payload = {
            orderId: this.order.Id,
            paymentMethod: this.order.ChargentOrders__Payment_Method__c,
            cardNumber: this.cardNumber,
            expirationMonth: this.expirationMonth,
            expirationYear: this.expirationYear,
            bankAccountNumber: this.bankAccountNumber,
            bankName: this.order.ChargentOrders__Bank_Name__c,
            bankRoutingNumber: this.order.ChargentOrders__Bank_Routing_Number__c,
            accountHolderPayload: accountHolderPayload,
            billingContactPayload: billingContactPayload,
            billingAddress: this.billingAddressDifferent === 'No' ? this.billingAddress : null
        };

        try {
            await updatePaymentMethod({ payload });
            this.showSuccessMessage = true;
            await refreshApex(this.wiredPaymentResult);
            setTimeout(() => {
                this.close({ saved: true });
            }, 2000);
        } catch (e) {
            console.error('Error saving payment method:', e);
            this.errorMessage = e.body?.message || e.message || 'Error updating payment information';
            this.showErrorMessage = true;
            setTimeout(() => {
                this.showErrorMessage = false;
            }, 5000);
        }
    }

    validateInputs() {
        const inputs = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-radio-group')];
        let isValid = true;
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }
}