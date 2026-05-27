import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getBusinessDetails from '@salesforce/apex/ARC_BusinessDetailsController.getBusinessDetails';
import saveAccountManager from '@salesforce/apex/ARC_BusinessFormController.saveAccountManager';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';

/**
 * ARC_AccountManagerSection - Account Manager section
 * 
 * @description Handles Account Manager selection with its own validation and save.
 */
export default class ARC_AccountManagerSection extends LightningElement {
    /** @api Record Id (Opportunity Id) from parent */
    @api recordId;

    @track isSaving = false;
    @track sectionStatus = 'not-started';
    @track accountManagerId = null;
    @track accountManagerName = '';
    
    _accountManagerSet = false; // Track if Account Manager has been pre-selected

    // Custom icon URL for section header
    sectionIconUrl = `${SGFormIcons}/business.svg`;

    // ═══════════════════════════════════════════════════════════════════════
    // WIRE ADAPTERS
    // ═══════════════════════════════════════════════════════════════════════

    @wire(getBusinessDetails, { opportunityId: '$recordId' })
    wiredBusinessDetails({ error, data }) {
        if (data) {
            this.accountManagerId = data.accountManagerId;
            this.accountManagerName = data.accountManagerName;
            
            // Pre-select Account Manager in lookup if available
            if (this.accountManagerId && !this._accountManagerSet) {
                this._accountManagerSet = true;
                setTimeout(() => {
                    const lookup = this.template.querySelector('c-a-r-c_-generic-lookup[data-type="account"]');
                    if (lookup && this.accountManagerId) {
                        lookup.setSelection({
                            Id: this.accountManagerId,
                            Name: this.accountManagerName
                        });
                    }
                }, 100);
            }
            
            this.updateSectionStatus();
        } else if (error) {
            console.error('Error loading account manager data:', error);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    @api
    get status() {
        return this.sectionStatus;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    handleAccountManagerSelect(event) {
        this.accountManagerId = event.detail.record.Id;
        this.accountManagerName = event.detail.record.Name;
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    handleAccountManagerClear() {
        this.accountManagerId = null;
        this.accountManagerName = '';
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SAVE HANDLER
    // ═══════════════════════════════════════════════════════════════════════

    async handleSave() {
        // Optional field - no validation required
        
        this.isSaving = true;

        try {
            console.log('AccountManagerSection - Saving accountManagerId:', this.accountManagerId);
            console.log('AccountManagerSection - recordId:', this.recordId);

            const result = await saveAccountManager({
                opportunityId: this.recordId,
                accountManagerId: this.accountManagerId
            });

            console.log('AccountManagerSection - Save result:', JSON.stringify(result, null, 2));

            this.sectionStatus = this.accountManagerId ? 'complete' : 'not-started';
            this.showToast('Success', 'Account Manager saved successfully', 'success');
            
            const section = this.template.querySelector('c-a-r-c_-collapsible-section');
            if (section) {
                section.notifySaved();
            }

            this.dispatchEvent(new CustomEvent('save', {
                detail: {
                    section: 'accountManager',
                    data: this.getData(),
                    isValid: true,
                    errors: []
                }
            }));

        } catch (error) {
            console.error('Error saving account manager:', error);
            this.showToast('Error', error.body?.message || error.message || 'An error occurred while saving', 'error');
        } finally {
            this.isSaving = false;
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
     * @api Get current section data
     * @returns {Object} Account Manager data
     */
    @api
    getData() {
        return {
            accountManagerId: this.accountManagerId,
            accountManagerName: this.accountManagerName
        };
    }

    /**
     * @api Set section data
     * @param {Object} data - Account Manager data to set
     */
    @api
    setData(data) {
        if (data) {
            if (data.accountManagerId) {
                this.accountManagerId = data.accountManagerId;
            }
            if (data.accountManagerName) {
                this.accountManagerName = data.accountManagerName;
            }
        }
    }

    /**
     * @api Validate all fields
     * @returns {Object} { isValid: Boolean, errors: Array }
     */
    @api
    validate() {
        // Optional section - always valid
        return {
            isValid: true,
            errors: []
        };
    }

    /**
     * @api Reset section to initial state
     */
    @api
    reset() {
        this.accountManagerId = null;
        this.accountManagerName = '';
        this.sectionStatus = 'not-started';
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
        this.sectionStatus = this.accountManagerId ? 'complete' : 'not-started';
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

    /**
     * Dispatch change event to parent
     */
    dispatchChangeEvent() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                section: 'accountManager',
                data: this.getData()
            }
        }));
    }
}