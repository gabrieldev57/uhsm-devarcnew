import { LightningElement, api, track } from 'lwc';

/**
 * ARC_ConfirmModal - Reusable confirmation modal
 * 
 * @description Modal component for confirmation dialogs (e.g., delete confirmations).
 *              Returns a promise that resolves with user's choice.
 * 
 * Usage:
 *   const confirmed = await this.template.querySelector('c-a-r-c_-confirm-modal').open({
 *       title: 'Confirm Delete',
 *       message: 'Are you sure you want to delete this item? This action cannot be undone.',
 *       confirmLabel: 'Delete'
 *   });
 *   
 *   if (confirmed) {
 *       // User clicked confirm
 *   }
 */
export default class ArcConfirmModal extends LightningElement {
    @track isOpen = false;
    @track title = 'Confirm';
    @track message = 'Are you sure?';
    @track confirmLabel = 'Confirm';
    
    resolve;

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @api Open the modal
     * @param {Object} options - Configuration
     * @param {String} options.title - Modal title
     * @param {String} options.message - Confirmation message
     * @param {String} options.confirmLabel - Label for confirm button (default: 'Confirm')
     * @returns {Promise<Boolean>} Resolves with true if confirmed, false if cancelled
     */
    @api
    open(options = {}) {
        this.title = options.title || 'Confirm';
        this.message = options.message || 'Are you sure?';
        this.confirmLabel = options.confirmLabel || 'Confirm';
        
        this.isOpen = true;
        
        return new Promise((resolve) => {
            this.resolve = resolve;
        });
    }

    @api
    close() {
        this.isOpen = false;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    handleCancel() {
        this.isOpen = false;
        if (this.resolve) {
            this.resolve(false);
        }
    }

    handleConfirm() {
        this.isOpen = false;
        if (this.resolve) {
            this.resolve(true);
        }
    }
}