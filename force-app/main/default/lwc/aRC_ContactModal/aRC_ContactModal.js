import { LightningElement, api, track } from 'lwc';

/**
 * ARC_ContactModal - Reusable modal for adding/editing contacts
 * 
 * @description Modal component that wraps aRC_ContactForm with Portal Access dropdown.
 *              Can be used for both New and Edit operations.
 * 
 * Usage:
 *   // For new contact
 *   const result = await this.template.querySelector('c-a-r-c_-contact-modal').open();
 *   
 *   // For edit contact
 *   const result = await this.template.querySelector('c-a-r-c_-contact-modal').open({
 *       contact: existingContact,
 *       mode: 'edit'
 *   });
 * 
 * Returns:
 *   { action: 'save', contact: {...} } on save
 *   { action: 'cancel' } on cancel
 */
export default class ArcContactModal extends LightningElement {
    @track isOpen = false;
    @track mode = 'new'; // 'new' or 'edit'
    @track editIndex = null; // Index of contact being edited (for reference)
    @track hideAddress = false;
    @track hidePhone = false;
    
    @track contactData = {
        firstName: '',
        lastName: '',
        title: '',
        email: '',
        phone: '',
        street: '',
        city: '',
        state: '',
        zip: '',
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

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    get modalTitle() {
        return this.mode === 'edit' ? 'Edit Contact' : 'New Contact';
    }

    get saveButtonLabel() {
        return this.mode === 'edit' ? 'Save Changes' : 'Add Contact';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @api Open the modal
     * @param {Object} options - Optional configuration
     * @param {Object} options.contact - Contact data to pre-fill (for edit mode)
     * @param {String} options.mode - 'new' or 'edit'
     * @param {Number} options.index - Index of contact being edited
     * @returns {Promise} Resolves with result when modal closes
     */
    @api
    open(options = {}) {
        this.mode = options.mode || 'new';
        this.editIndex = options.index !== undefined ? options.index : null;
        this.hideAddress = options.hideAddress === true;
        this.hidePhone = options.hidePhone === true;
        
        if (options.contact) {
            this.contactData = {
                firstName: options.contact.firstName || '',
                lastName: options.contact.lastName || '',
                title: options.contact.title || '',
                email: options.contact.email || '',
                phone: options.contact.phone || '',
                street: options.contact.street || '',
                city: options.contact.city || '',
                state: options.contact.state || '',
                zip: options.contact.zip || '',
                portalAccess: options.contact.portalAccess || ''
            };
        } else {
            // Reset to empty for new contact
            this.contactData = {
                firstName: '',
                lastName: '',
                title: '',
                email: '',
                phone: '',
                street: '',
                city: '',
                state: '',
                zip: '',
                portalAccess: ''
            };
        }
        
        this.isOpen = true;
        
        return new Promise((resolve, reject) => {
            this.resolve = resolve;
            this.reject = reject;
        });
    }

    /**
     * @api Close the modal
     */
    @api
    close() {
        this.isOpen = false;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    handlePortalAccessChange(event) {
        this.contactData = {
            ...this.contactData,
            portalAccess: event.detail.value
        };
    }

    handleFieldChange(event) {
        const { contact } = event.detail;
        // Update all fields from the form's contact state
        this.contactData = {
            ...this.contactData,
            firstName: contact.firstName,
            lastName: contact.lastName,
            title: contact.title,
            email: contact.email,
            phone: contact.phone,
            street: contact.street,
            city: contact.city,
            state: contact.state,
            zip: contact.zip
        };
    }

    handleCancel() {
        this.isOpen = false;
        if (this.resolve) {
            this.resolve({ action: 'cancel' });
        }
    }

    handleSave() {
        // Validate the form
        const contactForm = this.template.querySelector('c-a-r-c_-contact-form');
        if (contactForm && !contactForm.reportValidity()) {
            return;
        }

        // Validate portal access
        const portalAccessCombo = this.template.querySelector('lightning-combobox');
        if (portalAccessCombo && !portalAccessCombo.reportValidity()) {
            return;
        }

        this.isOpen = false;
        if (this.resolve) {
            this.resolve({
                action: 'save',
                contact: { ...this.contactData },
                index: this.editIndex,
                mode: this.mode
            });
        }
    }
}