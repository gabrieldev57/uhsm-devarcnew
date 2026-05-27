import { LightningElement, api, track } from 'lwc';

/**
 * ARC_AffiliatedEntityModal - Modal for adding/editing affiliated entities
 * 
 * Usage:
 *   const result = await this.template.querySelector('c-a-r-c_-affiliated-entity-modal').open();
 *   const result = await this.template.querySelector('c-a-r-c_-affiliated-entity-modal').open({
 *       entity: existingEntity,
 *       mode: 'edit'
 *   });
 */
export default class ArcAffiliatedEntityModal extends LightningElement {
    @track isOpen = false;
    @track mode = 'new';
    @track editIndex = null;
    
    @track entityData = {
        accountId: null,
        legalName: '',
        federalTaxId: '',
        numberOfEmployees: null
    };

    resolve;
    reject;

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    get modalTitle() {
        return this.mode === 'edit' ? 'Edit Affiliated Entity' : 'Add Affiliated Entity';
    }

    get saveButtonLabel() {
        return this.mode === 'edit' ? 'Save Changes' : 'Add Entity';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API
    // ═══════════════════════════════════════════════════════════════════════

    @api
    open(options = {}) {
        this.mode = options.mode || 'new';
        this.editIndex = options.index !== undefined ? options.index : null;
        
        if (options.entity) {
            this.entityData = {
                accountId: options.entity.accountId || null,
                legalName: options.entity.legalName || '',
                federalTaxId: options.entity.federalTaxId || '',
                numberOfEmployees: options.entity.numberOfEmployees || null
            };
        } else {
            this.entityData = {
                accountId: null,
                legalName: '',
                federalTaxId: '',
                numberOfEmployees: null
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

    handleFieldChange(event) {
        const fieldName = event.target.name;
        let value = event.target.value;
        
        // Convert number field to proper type
        if (fieldName === 'numberOfEmployees') {
            value = value ? parseInt(value, 10) : null;
        }
        
        this.entityData = {
            ...this.entityData,
            [fieldName]: value
        };
    }

    /**
     * Auto-format Federal Tax ID as user types (XX-XXXXXXX)
     */
    handleFederalTaxIdKeyUp(event) {
        let value = event.target.value.replace(/\D/g, ''); // Remove non-digits
        if (value.length > 9) {
            value = value.substring(0, 9);
        }
        // Add dash after first 2 digits
        if (value.length > 2) {
            value = value.substring(0, 2) + '-' + value.substring(2);
        }
        event.target.value = value;
        
        // Update entity data
        this.entityData = {
            ...this.entityData,
            federalTaxId: value
        };
    }

    handleCancel() {
        this.isOpen = false;
        if (this.reject) {
            this.reject({ cancelled: true });
        }
    }

    handleSave() {
        // Validate required fields
        const inputs = this.template.querySelectorAll('lightning-input');
        const allValid = [...inputs].reduce((validSoFar, input) => {
            input.reportValidity();
            return validSoFar && input.checkValidity();
        }, true);

        if (!allValid) {
            return;
        }

        // Return the entity data
        const result = {
            ...this.entityData,
            index: this.editIndex
        };

        this.isOpen = false;
        if (this.resolve) {
            this.resolve(result);
        }
    }
}