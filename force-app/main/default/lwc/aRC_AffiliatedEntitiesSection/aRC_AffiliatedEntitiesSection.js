import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAffiliatedEntities from '@salesforce/apex/ARC_AffiliatedEntitiesController.getAffiliatedEntities';
import saveAffiliatedEntities from '@salesforce/apex/ARC_BusinessFormController.saveAffiliatedEntities';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';

/**
 * ARC_AffiliatedEntitiesSection - Capture affiliated entities for employer
 * 
 * @description Optional section to capture affiliated business entities
 *              Each entity is saved as a child Account with ParentId = Employer Account
 */
export default class ARC_AffiliatedEntitiesSection extends LightningElement {
    /** @api Record Id (Opportunity Id) from parent */
    @api recordId;

    @track isSaving = false;
    @track isSaved = false;
    @track sectionStatus = 'not-started';
    @track isLoading = true;
    @track loadError = null;
    @track affiliatedEntities = [];

    // Table columns configuration
    entityColumns = [
        { label: 'Legal Name', fieldName: 'legalName', type: 'text' },
        { label: 'Federal Tax ID', fieldName: 'federalTaxId', type: 'text' },
        { label: 'Number of Employees', fieldName: 'numberOfEmployees', type: 'number' }
    ];
    
    // Custom icon URL for section header
    sectionIconUrl = `${SGFormIcons}/business.svg`;

    // ═══════════════════════════════════════════════════════════════════════
    // WIRE ADAPTERS
    // ═══════════════════════════════════════════════════════════════════════

    @wire(getAffiliatedEntities, { opportunityId: '$recordId' })
    wiredAffiliatedEntities({ error, data }) {
        this.isLoading = false;
        if (data) {
            const entities = data.entities || [];
            const sectionComplete = data.sectionComplete === true;

            // Load existing affiliated entities
            this.affiliatedEntities = entities.map(entity => ({
                id: entity.Id,
                accountId: entity.Id,
                legalName: entity.Name || '',
                federalTaxId: entity.ARC_FederalEmployerTaxIDNumber__c || '',
                numberOfEmployees: entity.ARC_Number_Of_Employees__c || null,
                isNew: false,
                isModified: false
            }));
            
            this.loadError = null;
            
            // Restore complete status from persisted flag or actual data completeness
            if (this.isComplete() && this.affiliatedEntities.length > 0) {
                this.sectionStatus = 'complete';
            } else if (sectionComplete && this.affiliatedEntities.length === 0) {
                this.sectionStatus = 'complete';
            } else if (this.affiliatedEntities.length > 0) {
                this.sectionStatus = 'in-progress';
            } else {
                this.sectionStatus = 'not-started';
            }
        } else if (error) {
            console.error('Error loading affiliated entities:', error);
            this.loadError = error.body?.message || 'Error loading entity data';
            this.affiliatedEntities = [];
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    @api
    get status() {
        return this.sectionStatus;
    }

    /**
     * Set status to in-progress when user starts editing
     */
    setInProgress() {
        if (this.sectionStatus !== 'complete') {
            this.sectionStatus = 'in-progress';
        }
    }

    get hasEntities() {
        return this.affiliatedEntities.length > 0;
    }

    /**
     * Transform entities data for table display
     */
    get entitiesForTable() {
        return this.affiliatedEntities.map(entity => ({
            ...entity,
            numberOfEmployees: entity.numberOfEmployees || 0
        }));
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
     * @returns {Array} All entities data
     */
    @api
    getData() {
        return [...this.affiliatedEntities];
    }

    /**
     * @api Set section data
     * @param {Array} data - Entities array to set
     */
    @api
    setData(data) {
        if (data && Array.isArray(data)) {
            this.affiliatedEntities = [...data];
        }
    }

    /**
     * @api Validate all fields - always valid since section is optional
     * @returns {Object} { isValid: Boolean, errors: Array }
     */
    @api
    validate() {
        // This section is optional, so it's always valid
        // However, if entities are added, they must have required fields filled
        const errors = [];
        
        for (const entity of this.affiliatedEntities) {
            if (!entity.legalName || !entity.federalTaxId) {
                errors.push('All entities must have a Legal Name and Federal Tax ID');
                break;
            }
        }

        return {
            isValid: errors.length === 0,
            errors: errors
        };
    }

    /**
     * Check if section is complete (all added entities have required fields)
     * This section is optional, so empty is considered complete
     * @returns {Boolean} Whether section is complete
     */
    isComplete() {
        // Empty list is valid (section is optional)
        if (this.affiliatedEntities.length === 0) return true;
        
        // If entities exist, all must have required fields
        return this.affiliatedEntities.every(entity => 
            entity.legalName && entity.federalTaxId
        );
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Handle Add Entity button click
     */
    async handleAddEntity() {
        const modal = this.template.querySelector('c-a-r-c_-affiliated-entity-modal');
        if (modal) {
            const result = await modal.open({ mode: 'new' });
            if (result && !result.cancelled) {
                const newEntity = {
                    id: `entity_${Date.now()}`,
                    accountId: null,
                    isNew: true,
                    isModified: false,
                    legalName: result.legalName,
                    federalTaxId: result.federalTaxId,
                    numberOfEmployees: result.numberOfEmployees
                };
                this.affiliatedEntities = [...this.affiliatedEntities, newEntity];
                this.setInProgress();
                await this._saveInstant();
            }
        }
    }

    /**
     * Handle Edit Entity action from table
     */
    async handleEditEntity(event) {
        const { row, index } = event.detail;
        const modal = this.template.querySelector('c-a-r-c_-affiliated-entity-modal');
        if (modal) {
            const result = await modal.open({
                mode: 'edit',
                entity: row,
                index: index
            });
            if (result && !result.cancelled) {
                const updatedEntity = {
                    ...row,
                    legalName: result.legalName,
                    federalTaxId: result.federalTaxId,
                    numberOfEmployees: result.numberOfEmployees,
                    isModified: !row.isNew
                };
                
                this.affiliatedEntities = this.affiliatedEntities.map((entity, i) =>
                    i === index ? updatedEntity : entity
                );
                
                this.setInProgress();
                await this._saveInstant();
            }
        }
    }

    /**
     * Handle Remove Entity action from table
     */
    async handleRemoveEntity(event) {
        const { index } = event.detail;
        const entity = this.affiliatedEntities[index];

        const confirmed = await this.showConfirmDialog(
            'Remove Entity',
            `Are you sure you want to remove "${entity.legalName || 'this entity'}"? This action cannot be undone.`,
            'Remove',
            'destructive'
        );
        if (!confirmed) return;

        this.affiliatedEntities = this.affiliatedEntities.filter((_, i) => i !== index);
        
        if (this.affiliatedEntities.length === 0) {
            this.sectionStatus = 'not-started';
        } else {
            this.setInProgress();
        }
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
            const entitiesForSave = this.affiliatedEntities.map(entity => ({
                id: entity.accountId,
                legalName: entity.legalName,
                federalTaxId: entity.federalTaxId,
                numberOfEmployees: entity.numberOfEmployees
            }));

            const result = await saveAffiliatedEntities({
                opportunityId: this.recordId,
                entitiesData: JSON.stringify(entitiesForSave)
            });

            if (result.isSuccess) {
                this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
                this._flashSaved();
                this.dispatchEvent(new CustomEvent('save', {
                    detail: { section: 'affiliatedEntities', data: this.affiliatedEntities, isValid: true, errors: [] }
                }));
            } else {
                this.sectionStatus = 'error';
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Unable to Save Affiliated Entities',
                    message: result.message || 'There was a problem saving affiliated entities.',
                    variant: 'error',
                    mode: 'sticky'
                }));
            }
        } catch (error) {
            console.error('Error saving affiliated entities:', error);
            this.sectionStatus = 'error';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Unable to Save Affiliated Entities',
                message: 'An unexpected error occurred. Please try again or contact support.',
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isSaving = false;
        }
    }

    _flashSaved() {
        this.isSaved = true;
        setTimeout(() => { this.isSaved = false; }, 3000);
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