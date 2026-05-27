import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOwnerContacts from '@salesforce/apex/ARC_CompanyContactSectionController.getOwnerContacts';
import saveOwnership from '@salesforce/apex/ARC_BusinessFormController.saveOwnership';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';

/**
 * ARC_OwnershipSection - Self-contained Company Ownership section
 * 
 * @description Handles company ownership collection with add/edit/delete functionality.
 *              Retrieves owner contacts via ACR with "Ownership" role.
 *              Can work independently or be controlled by a parent component.
 * 
 * Events:
 *   - change: Fired when any owner data changes { detail: { section, data } }
 *   - save: Fired after save attempt { detail: { section, data, isValid, errors } }
 */
export default class ARC_OwnershipSection extends LightningElement {
    /** @api Record Id (Opportunity Id) from parent */
    @api recordId;

    @track isSaving = false;
    @track isSaved = false;
    @track sectionStatus = 'not-started';
    @track isLoading = true;
    @track loadError = null;

    // Custom icon URL for section header
    sectionIconUrl = `${SGFormIcons}/otherContacts.svg`;
    
    // ═══════════════════════════════════════════════════════════════════════
    // OWNERS DATA
    // ═══════════════════════════════════════════════════════════════════════
    
    @track owners = [];
    @track ownersToRemoveRole = []; // Contact Ids to remove Ownership role from
    @track validationErrors = [];

    // Table columns configuration
    ownerColumns = [
        { label: 'First Name', fieldName: 'firstName', type: 'text' },
        { label: 'Last Name', fieldName: 'lastName', type: 'text' },
        { label: 'M.I.', fieldName: 'middleInitial', type: 'text' },
        { label: 'Ownership %', fieldName: 'ownershipDisplay', type: 'text' },
        { label: 'Eligible', fieldName: 'eligibleDisplay', type: 'eligible' },
        { label: 'Portal Access', fieldName: 'portalAccess', type: 'badge' }
    ];

    // ═══════════════════════════════════════════════════════════════════════
    // WIRE ADAPTERS - Data Retrieval
    // ═══════════════════════════════════════════════════════════════════════

    @wire(getOwnerContacts, { opportunityId: '$recordId' })
    wiredOwnerContacts(result) {
        this._wiredOwnerContacts = result;
        const { error, data } = result;
        this.isLoading = false;
        if (data) {
            const owners = data.owners || [];
            const sectionComplete = data.sectionComplete === true;

            // Transform the data from Apex to match component's expected format
            this.owners = owners.map(owner => ({
                id: owner.id || owner.contactId,
                contactId: owner.contactId,
                firstName: owner.firstName || '',
                lastName: owner.lastName || '',
                middleInitial: owner.middleInitial || '',
                ownershipPercentage: owner.ownershipPercentage,
                isEligible: owner.isEligible || false,
                portalAccess: owner.portalAccess || 'No Access',
                email: owner.email,
                phone: owner.phone,
                isNew: false,
                isModified: false
            }));
            this.loadError = null;
            
            // Restore complete status: either owners present and complete, or flag set with empty list
            if (this.isComplete()) {
                this.sectionStatus = 'complete';
            } else if (sectionComplete && this.owners.length === 0) {
                this.sectionStatus = 'complete';
            } else if (this.owners.length > 0) {
                this.sectionStatus = 'in-progress';
            } else {
                this.sectionStatus = 'not-started';
            }
        } else if (error) {
            console.error('Error loading owner contacts:', error);
            this.loadError = error.body?.message || 'Error loading owner data';
            this.owners = [];
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS (Computed Properties)
    // ═══════════════════════════════════════════════════════════════════════

    @api
    get status() {
        return this.sectionStatus;
    }

    /**
     * Set status to in-progress when user starts editing (if not already complete)
     */
    setInProgress() {
        if (this.sectionStatus !== 'complete') {
            this.sectionStatus = 'in-progress';
        }
    }

    get hasOwners() {
        return this.owners.length > 0;
    }

    get ownersCount() {
        return this.owners.length;
    }

    /**
     * Transform owners data for table display
     */
    get ownersForTable() {
        return this.owners.map(owner => ({
            ...owner,
            ownershipDisplay: owner.ownershipPercentage != null ? `${owner.ownershipPercentage}%` : '',
            eligibleDisplay: owner.isEligible ? 'Yes' : 'No'
        }));
    }

    /**
     * Calculate total ownership percentage
     */
    get totalOwnership() {
        return this.owners.reduce((sum, owner) => sum + (owner.ownershipPercentage || 0), 0);
    }

    /**
     * Check if total ownership exceeds 100%
     */
    get isOverAllocated() {
        return this.totalOwnership > 100;
    }

    /**
     * CSS class for total ownership display
     */
    get totalOwnershipClass() {
        return this.isOverAllocated ? 'total-warning' : 'total-normal';
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
     * @returns {Array} All owners data
     */
    @api
    getData() {
        return [...this.owners];
    }

    /**
     * @api Set section data
     * @param {Array} data - Owners array to set
     */
    @api
    setData(data) {
        if (data && Array.isArray(data)) {
            this.owners = [...data];
        }
    }

    /**
     * @api Validate all fields
     * @returns {Object} { isValid: Boolean, errors: Array }
     */
    @api
    validate() {
        const errors = [];
        
        // At least one owner required
        if (this.owners.length === 0) {
            errors.push('At least one owner is required');
        }

        // Check total ownership equals exactly 100%
        const total = this.totalOwnership;
        if (total !== 100) {
            errors.push(`Total ownership must equal 100%. Current total: ${total}%`);
        }

        // Check each owner has required fields
        this.owners.forEach((owner, index) => {
            if (!owner.firstName || !owner.lastName) {
                errors.push(`Owner ${index + 1}: First and Last name are required`);
            }
            if (owner.ownershipPercentage == null || owner.ownershipPercentage <= 0) {
                errors.push(`Owner ${index + 1}: Ownership percentage is required and must be greater than 0`);
            }
            if (owner.ownershipPercentage > 100) {
                errors.push(`Owner ${index + 1}: Ownership percentage cannot exceed 100%`);
            }
        });

        return {
            isValid: errors.length === 0,
            errors
        };
    }

    /**
     * Check if section is complete (all requirements met)
     * This determines the section status, not whether save is allowed
     * @returns {Boolean} Whether section meets all completion requirements
     */
    isComplete() {
        if (this.owners.length === 0) return false;
        if (this.totalOwnership !== 100) return false;
        
        // Check all owners have required fields
        return this.owners.every(owner => 
            owner.firstName && owner.lastName && owner.ownershipPercentage > 0
        );
    }

    /**
     * @api Reset section to initial state
     */
    @api
    reset() {
        this.owners = [];
        this.sectionStatus = 'not-started';
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS - Owners
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Handle Add Owner button click
     */
    async handleAddOwner() {
        const modal = this.template.querySelector('c-a-r-c_-owner-modal');
        if (modal) {
            const existingContactIds = this.owners
                .filter(owner => owner.contactId)
                .map(owner => owner.contactId);
            const currentTotal = this.owners.reduce((sum, o) => sum + (parseFloat(o.ownershipPercentage) || 0), 0);
            const result = await modal.open({ mode: 'new', existingContactIds, currentTotalOwnership: currentTotal });
            if (result && result.action === 'save') {
                const newOwner = {
                    id: `owner_${Date.now()}`,
                    contactId: null,
                    isNew: true,
                    isModified: false,
                    ...result.owner
                };
                this.owners = [...this.owners, newOwner];
                this.setInProgress();
                this.dispatchChangeEvent();
                await this._saveInstant();
            }
        }
    }

    /**
     * Handle Edit Owner action from table
     */
    async handleEditOwner(event) {
        const { row, index } = event.detail;
        const modal = this.template.querySelector('c-a-r-c_-owner-modal');
        if (modal) {
            const currentTotal = this.owners.reduce((sum, o, i) =>
                i !== index ? sum + (parseFloat(o.ownershipPercentage) || 0) : sum, 0);
            const result = await modal.open({
                mode: 'edit',
                owner: row,
                index: index,
                currentTotalOwnership: currentTotal
            });
            if (result && result.action === 'save') {
                const updatedOwner = {
                    ...row,
                    ...result.owner,
                    isModified: !row.isNew
                };
                
                this.owners = this.owners.map((owner, i) =>
                    i === result.index ? updatedOwner : owner
                );
                
                this.setInProgress();
                this.dispatchChangeEvent();
                await this._saveInstant();
            }
        }
    }

    /**
     * Check if contact information was changed
     */
    hasContactInfoChanged(oldData, newData) {
        return oldData.firstName !== newData.firstName ||
               oldData.lastName !== newData.lastName ||
               oldData.middleInitial !== newData.middleInitial ||
               oldData.email !== newData.email ||
               oldData.phone !== newData.phone;
    }

    /**
     * Broadcast contact update to other sections
     */
    broadcastContactUpdate(owner) {
        this.dispatchEvent(new CustomEvent('contactupdate', {
            bubbles: true,
            composed: true,
            detail: {
                contactId: owner.contactId,
                contactData: {
                    firstName: owner.firstName,
                    lastName: owner.lastName,
                    middleInitial: owner.middleInitial,
                    email: owner.email,
                    phone: owner.phone,
                    portalAccess: owner.portalAccess
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
        this.owners = this.owners.map(owner => {
            if (owner.contactId === contactId) {
                updated = true;
                return {
                    ...owner,
                    firstName: contactData.firstName || owner.firstName,
                    lastName: contactData.lastName || owner.lastName,
                    middleInitial: contactData.middleInitial || owner.middleInitial,
                    email: contactData.email || owner.email,
                    phone: contactData.phone || owner.phone,
                    portalAccess: contactData.portalAccess || owner.portalAccess
                };
            }
            return owner;
        });
        
        if (updated) {
            // Force UI update
            this.owners = [...this.owners];
        }
    }

    /**
     * Handle Remove Owner action from table
     */
    async handleRemoveOwner(event) {
        const { index } = event.detail;
        const owner = this.owners[index];
        
        const confirmed = await this.showConfirmDialog(
            'Remove Owner',
            `Are you sure you want to remove ${owner.firstName || ''} ${owner.lastName || ''} as an owner? The contact record will be kept.`,
            'Remove',
            'destructive'
        );
        if (!confirmed) return;

        if (owner.contactId) {
            this.ownersToRemoveRole = [...this.ownersToRemoveRole, owner.contactId];
        }
        
        this.owners = this.owners.filter((_, i) => i !== index);
        this.setInProgress();
        this.dispatchChangeEvent();
        await this._saveInstant();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SAVE HANDLER
    // ═══════════════════════════════════════════════════════════════════════

    async handleSave() {
        await this._saveInstant();
    }

    async _saveInstant() {
        this.isSaving = true;
        
        try {
            const result = await saveOwnership({
                opportunityId: this.recordId,
                ownersData: this.owners,
                ownersToRemoveRole: this.ownersToRemoveRole
            });
            
            if (result.isSuccess) {
                const savedOwners = result.data?.owners || [];
                this.owners = this.owners.map(owner => {
                    const saved = savedOwners.find(s =>
                        s.tempId === owner.id || s.contactId === owner.contactId
                    );
                    if (saved) {
                        return { ...owner, contactId: saved.contactId, id: saved.contactId, isNew: false, isModified: false };
                    }
                    return owner;
                });
                
                this.ownersToRemoveRole = [];
                this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
                await refreshApex(this._wiredOwnerContacts);
                
                this.owners.forEach(owner => {
                    if (owner.contactId) this.broadcastContactUpdate(owner);
                });
                
                this._flashSaved();
                this.dispatchEvent(new CustomEvent('save', {
                    detail: { section: 'ownership', data: this.getData(), isValid: true, errors: [] }
                }));
            } else {
                this.showToast('Error', result.message || 'Failed to save ownership', 'error');
                this.dispatchEvent(new CustomEvent('save', {
                    detail: { section: 'ownership', data: this.getData(), isValid: false, errors: [result.message] }
                }));
            }
        } catch (error) {
            console.error('Error saving ownership:', error);
            const errorMessage = error.body?.message || error.message || 'An unexpected error occurred';
            this.showToast('Error', errorMessage, 'error');
            this.dispatchEvent(new CustomEvent('save', {
                detail: { section: 'ownership', data: this.getData(), isValid: false, errors: [errorMessage] }
            }));
        } finally {
            this.isSaving = false;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * Real-time validation after each change
     */
    validateRealTime() {
        this.validate();
    }

    dispatchChangeEvent() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: {
                section: 'ownership',
                data: this.getData()
            }
        }));
    }

    _flashSaved() {
        this.isSaved = true;
        setTimeout(() => { this.isSaved = false; }, 3000);
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    async showConfirmDialog(title, message, confirmLabel = 'Confirm', variant = 'default') {
        const modal = this.template.querySelector('c-a-r-c_-confirm-modal');
        if (modal) {
            return await modal.open({ title, message, confirmLabel });
        }
        // eslint-disable-next-line no-alert
        return confirm(message);
    }
}