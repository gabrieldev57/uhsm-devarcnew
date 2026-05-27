import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * ARC_OwnerModal - Modal for adding/editing company owners
 * 
 * Usage:
 *   const result = await this.template.querySelector('c-a-r-c_-owner-modal').open();
 *   const result = await this.template.querySelector('c-a-r-c_-owner-modal').open({
 *       owner: existingOwner,
 *       mode: 'edit'
 *   });
 */
export default class ArcOwnerModal extends LightningElement {
    @api opportunityId; // Passed from parent for contact lookup

    @track isOpen = false;
    @track mode = 'new';
    @track editIndex = null;
    @track contactType = 'new'; // 'new' or 'existing'
    @track existingContactIds = []; // Contact IDs to exclude from search
    @track currentTotalOwnership = 0; // Total % already allocated by other owners
    @track ownershipErrorMessage = '';
    
    @track ownerData = {
        contactId: null,
        firstName: '',
        lastName: '',
        middleInitial: '',
        email: '',
        phone: '',
        ownershipPercentage: null,
        isEligible: false,
        portalAccess: 'No Access'
    };

    resolve;
    reject;

    // Contact Type options
    contactTypeOptions = [
        { label: 'Create New Contact', value: 'new' },
        { label: 'Select Existing Contact', value: 'existing' }
    ];

    // Portal Access options
    portalAccessOptions = [
        { label: 'No Access', value: 'No Access' },
        { label: 'Viewer', value: 'Viewer' },
        { label: 'Admin', value: 'Admin' }
    ];

    // Yes/No options for Eligible
    eligibleOptions = [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
    ];

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    get modalTitle() {
        return this.mode === 'edit' ? 'Edit Owner' : 'Add Owner';
    }

    get saveButtonLabel() {
        return this.mode === 'edit' ? 'Save Changes' : 'Add Owner';
    }

    get eligibleValue() {
        return this.ownerData.isEligible ? 'yes' : 'no';
    }

    get showContactLookup() {
        return this.contactType === 'existing' && this.mode !== 'edit';
    }

    get showContactFields() {
        return this.contactType === 'new' || this.mode === 'edit';
    }

    get isContactTypeDisabled() {
        // Disable contact type radio when editing an existing saved owner
        return this.mode === 'edit' && this.ownerData.contactId !== null;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API
    // ═══════════════════════════════════════════════════════════════════════

    @api
    open(options = {}) {
        this.mode = options.mode || 'new';
        this.editIndex = options.index !== undefined ? options.index : null;
        this.existingContactIds = options.existingContactIds || [];
        this.currentTotalOwnership = options.currentTotalOwnership || 0;
        this.ownershipErrorMessage = '';
        
        if (this.mode === 'new') {
            // Reset contact type for new entries
            this.contactType = 'new';
        } else if (this.mode === 'edit' && options.owner) {
            // Set contact type based on whether it's an existing contact or new
            this.contactType = options.owner.contactId ? 'existing' : 'new';
        }
        
        if (options.owner) {
            this.ownerData = {
                contactId: options.owner.contactId || null,
                firstName: options.owner.firstName || '',
                lastName: options.owner.lastName || '',
                middleInitial: options.owner.middleInitial || '',
                email: options.owner.email || '',
                phone: this.formatPhone((options.owner.phone || '').replace(/\D/g, '')),
                ownershipPercentage: options.owner.ownershipPercentage || null,
                isEligible: options.owner.isEligible || false,
                portalAccess: options.owner.portalAccess || 'No Access'
            };
        } else {
            this.ownerData = {
                contactId: null,
                firstName: '',
                lastName: '',
                middleInitial: '',
                email: '',
                phone: '',
                ownershipPercentage: null,
                isEligible: false,
                portalAccess: 'No Access'
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

    handleContactTypeChange(event) {
        this.contactType = event.detail.value;
        
        // Clear contact data when switching types
        if (this.contactType === 'new') {
            this.ownerData = {
                ...this.ownerData,
                contactId: null,
                firstName: '',
                lastName: '',
                middleInitial: ''
            };
        }
    }

    handleContactSelect(event) {
        const contact = event.detail.record;
        
        if (contact) {
            // Check if this contact is already an owner
            if (this.existingContactIds.includes(contact.Id)) {
                // Show error - contact already added
                const evt = new ShowToastEvent({
                    title: 'Contact Already Added',
                    message: 'This contact is already listed as an owner.',
                    variant: 'error'
                });
                this.dispatchEvent(evt);
                
                // Clear the lookup
                const lookup = this.template.querySelector('c-a-r-c_-generic-lookup');
                if (lookup && lookup.clearSelection) {
                    lookup.clearSelection();
                }
                return;
            }
            
            this.ownerData = {
                ...this.ownerData,
                contactId: contact.Id,
                firstName: contact.FirstName || '',
                lastName: contact.LastName || '',
                middleInitial: contact.vlocity_ins__MiddleName__c || '',
                email: contact.Email || '',
                phone: this.formatPhone((contact.Phone || '').replace(/\D/g, '')),
                portalAccess: contact.ARC_PortalAccess__c || 'No Access'
            };
        }
    }

    handleFieldChange(event) {
        const fieldName = event.target.name;
        let value = event.target.value;
        
        // Clear ownership error when user changes the percentage
        if (fieldName === 'ownershipPercentage') {
            this.ownershipErrorMessage = '';
        }
        
        // Handle percentage as number
        if (fieldName === 'ownershipPercentage') {
            value = value ? parseFloat(value) : null;
        }
        
        this.ownerData = {
            ...this.ownerData,
            [fieldName]: value
        };
    }

    handleEligibleChange(event) {
        this.ownerData = {
            ...this.ownerData,
            isEligible: event.detail.value === 'yes'
        };
    }

    formatPhone(digits) {
        const d = (digits || '').replace(/\D/g, '').slice(0, 10);
        if (d.length === 0) return '';
        if (d.length <= 3) return `(${d}`;
        if (d.length <= 6) return `(${d.slice(0, 3)}) ${d.slice(3)}`;
        return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
    }

    handlePhoneFocus(event) {
        const digits = (this.ownerData.phone || '').replace(/\D/g, '');
        this.ownerData = { ...this.ownerData, phone: digits };
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
        this.ownerData = { ...this.ownerData, phone: this.formatPhone(digits) };
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
        // Validate all fields
        const allInputs = this.template.querySelectorAll('lightning-input, lightning-combobox, c-a-r-c_-generic-lookup, c-a-r-c_-radio-group');
        let isValid = true;
        
        allInputs.forEach(input => {
            if (input.reportValidity && !input.reportValidity()) {
                isValid = false;
            }
        });

        if (!isValid) {
            return;
        }

        // Validate percentage range
        if (this.ownerData.ownershipPercentage == null || this.ownerData.ownershipPercentage <= 0 || this.ownerData.ownershipPercentage > 100) {
            const percentInput = this.template.querySelector('[name="ownershipPercentage"]');
            if (percentInput) {
                percentInput.setCustomValidity('Ownership percentage must be between 1 and 100');
                percentInput.reportValidity();
            }
            return;
        }

        // Validate against current total
        const newTotal = this.currentTotalOwnership + (this.ownerData.ownershipPercentage || 0);
        if (newTotal > 100) {
            this.ownershipErrorMessage = `Total ownership would be ${parseFloat(newTotal.toFixed(2))}%. It cannot exceed 100%.`;
            return;
        }

        // Clear custom validity and error message if previously set
        const percentInput = this.template.querySelector('[name="ownershipPercentage"]');
        if (percentInput) {
            percentInput.setCustomValidity('');
        }
        this.ownershipErrorMessage = '';

        this.isOpen = false;
        if (this.resolve) {
            this.resolve({
                action: 'save',
                owner: { ...this.ownerData },
                index: this.editIndex,
                mode: this.mode
            });
        }
    }
}