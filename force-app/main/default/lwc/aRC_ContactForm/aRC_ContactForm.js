import { LightningElement, api, track } from 'lwc';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';

/**
 * ARC_ContactForm - Reusable contact information form
 * 
 * @description Renders a form with standard contact fields (firstName, lastName, title, email, phone).
 *              Supports read-only mode for displaying selected contact data.
 * 
 * Events:
 *   - change: Fired when any field changes { detail: { field: String, value: String, contact: Object } }
 */
export default class ArcContactForm extends LightningElement {
    /** @api Title for the form card */
    @api title = 'Contact Information';

    /** @api Icon name for the header (SLDS icon) */
    @api iconName = 'standard:contact';

    /** @api Custom icon URL (optional, overrides iconName) */
    @api customIconUrl = '';

    /** @api Whether all fields are read-only */
    @api readOnly = false;

    /** @api Whether fields are required */
    @api required = false;

    /** @api Show/hide the card wrapper */
    @api hideCard = false;

    /** @api Hide address fields (street, city, state, zip) */
    @api hideAddress = false;

    /** @api Hide phone field */
    @api hidePhone = false;

    // Internal tracked state for form fields
    @track _firstName = '';
    @track _lastName = '';
    @track _contactTitle = '';
    @track _email = '';
    @track _phone = '';
    @track _street = '';
    @track _city = '';
    @track _state = '';
    @track _zip = '';

    // @api contact object - single source of truth
    @api
    get contact() {
        return {
            firstName: this._firstName,
            lastName: this._lastName,
            title: this._contactTitle,
            email: this._email,
            phone: this._phone,
            street: this._street,
            city: this._city,
            state: this._state,
            zip: this._zip
        };
    }
    set contact(value) {
        if (value) {
            this._firstName = value.firstName || '';
            this._lastName = value.lastName || '';
            this._contactTitle = value.title || '';
            this._email = value.email || '';
            this._phone = this.formatPhone((value.phone || '').replace(/\D/g, ''));
            this._street = value.street || '';
            this._city = value.city || '';
            this._state = value.state || '';
            this._zip = value.zip || '';
        }
    }

    // Default custom icon for new contact
    newContactIconUrl = `${SGFormIcons}/newContact.svg`;

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    get firstName() {
        return this._firstName;
    }

    get lastName() {
        return this._lastName;
    }

    get contactTitle() {
        return this._contactTitle;
    }

    get email() {
        return this._email;
    }

    get phone() {
        return this._phone;
    }

    get street() {
        return this._street;
    }

    get city() {
        return this._city;
    }

    get state() {
        return this._state;
    }

    get zip() {
        return this._zip;
    }

    get showCard() {
        return !this.hideCard;
    }

    get showAddressFields() {
        return !this.hideAddress;
    }

    get showPhoneField() {
        return !this.hidePhone;
    }

    get useCustomIcon() {
        return !!this.customIconUrl;
    }

    get headerIconUrl() {
        return this.customIconUrl || this.newContactIconUrl;
    }

    renderedCallback() {
        const icon = this.template.querySelector('[data-icon="header"]');

        if (icon) {
            icon.style.setProperty('--icon-url', `url("${this.headerIconUrl}")`);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @api Get the current contact data
     * @returns {Object} Contact object with all field values
     */
    @api
    getContact() {
        return {
            firstName: this._firstName,
            lastName: this._lastName,
            title: this._contactTitle,
            email: this._email,
            phone: this._phone,
            street: this._street,
            city: this._city,
            state: this._state,
            zip: this._zip
        };
    }

    /**
     * @api Set contact data programmatically
     * @param {Object} contact - Contact object
     */
    @api
    setContact(contact) {
        if (contact) {
            this._firstName = contact.firstName || '';
            this._lastName = contact.lastName || '';
            this._contactTitle = contact.title || '';
            this._email = contact.email || '';
            this._phone = this.formatPhone((contact.phone || '').replace(/\D/g, ''));
            this._street = contact.street || '';
            this._city = contact.city || '';
            this._state = contact.state || '';
            this._zip = contact.zip || '';
        }
    }

    /**
     * @api Report validity of all fields
     * @returns {Boolean} Whether all fields are valid
     */
    @api
    reportValidity() {
        const inputs = this.template.querySelectorAll('lightning-input');
        let isValid = true;
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });
        return isValid;
    }

    /**
     * @api Reset form to empty state
     */
    @api
    reset() {
        this._firstName = '';
        this._lastName = '';
        this._contactTitle = '';
        this._email = '';
        this._phone = '';
        this._street = '';
        this._city = '';
        this._state = '';
        this._zip = '';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;

        console.log('=== CONTACT FORM FIELD CHANGE ===');
        console.log('Field:', field);
        console.log('Value:', value);

        // Update internal state
        switch (field) {
            case 'firstName':
                this._firstName = value;
                break;
            case 'lastName':
                this._lastName = value;
                break;
            case 'title':
                this._contactTitle = value;
                break;
            case 'email':
                this._email = value;
                break;
            case 'phone':
                this._phone = this.formatPhone(value);
                break;
            case 'street':
                this._street = value;
                break;
            case 'city':
                this._city = value;
                break;
            case 'state':
                this._state = value;
                break;
            case 'zip':
                this._zip = value;
                break;
        }

        const contactData = this.getContact();
        console.log('Contact data being dispatched:', JSON.stringify(contactData));
        console.log('=================================');

        // Dispatch change event with field info and full contact
        this.dispatchEvent(new CustomEvent('formchange', {
            detail: {
                field: field,
                value: value,
                contact: contactData
            },
            bubbles: false,
            composed: false
        }));

    }

    formatPhone(digits) {
        const d = (digits || '').replace(/\D/g, '').slice(0, 10);
        if (d.length === 0) return '';
        if (d.length <= 3) return `(${d}`;
        if (d.length <= 6) return `(${d.slice(0, 3)}) ${d.slice(3)}`;
        return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
    }

    handlePhoneFocus(event) {
        const digits = (this._phone || '').replace(/\D/g, '');
        this._phone = digits;
        event.target.setCustomValidity('');
        setTimeout(() => {
            const input = event.target.shadowRoot && event.target.shadowRoot.querySelector('input');
            if (input) { input.selectionStart = input.selectionEnd = input.value.length; }
        }, 0);
    }

    handlePhoneKeyDown(event) {
        const allowed = ['Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Tab', 'Enter'];
        if (!allowed.includes(event.key) && !/^\d$/.test(event.key)) {
            event.preventDefault();
        }
        const digits = (event.target.value || '').replace(/\D/g, '');
        if (/^\d$/.test(event.key) && digits.length >= 10) {
            event.preventDefault();
        }
    }

    handlePhoneBlur(event) {
        const digits = (event.target.value || '').replace(/\D/g, '');
        this._phone = this.formatPhone(digits);
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
}