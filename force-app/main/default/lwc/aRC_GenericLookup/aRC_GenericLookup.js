import { LightningElement, api, track } from 'lwc';
import searchContactsByOpportunity from '@salesforce/apex/ARC_ContactLookupController.searchContactsByOpportunity';
import searchSICCodes from '@salesforce/apex/ARC_BusinessDetailsController.searchSICCodes';
import searchUsers from '@salesforce/apex/ARC_BusinessDetailsController.searchUsers';
import searchBusinessAccounts from '@salesforce/apex/ARC_CompanyContactSectionController.searchBusinessAccounts';

/**
 * ARC_GenericLookup - Reusable lookup component with server-side search
 * 
 * @description Generic lookup component with debounced search, server-side filtering
 *              for contacts related to the Opportunity's account.
 * 
 * Events:
 *   - select: Fired when a record is selected { detail: { record: Object } }
 *   - clear: Fired when the selection is cleared
 */
export default class ArcGenericLookup extends LightningElement {
    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════
    
    /** @api Placeholder text for search input */
    @api placeholder = 'Search...';
    
    /** @api Minimum characters required before search triggers */
    @api minChars = 0;
    
    /** @api Maximum number of results to display */
    @api limit = 10;

    /** @api Label for the lookup field */
    @api label = 'Search';

    /** @api Whether the field is required */
    @api required = false;

    /** @api Whether the field is disabled */
    @api disabled = false;

    /** @api Object type for display (e.g., 'Contact', 'SIC_Code__mdt') */
    @api objectType = 'Record';

    /** @api Icon name for result items */
    @api iconName = 'standard:contact';

    /** @api Opportunity Id for filtering contacts by Opportunity's Account */
    @api opportunityId = null;

    // ═══════════════════════════════════════════════════════════════════════
    // TRACKED STATE
    // ═══════════════════════════════════════════════════════════════════════
    
    @track searchTerm = '';
    @track searchResults = [];
    @track selectedRecord = null;
    @track isLoading = false;
    @track showDropdown = false;
    @track errorMessage = '';

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════
    
    debounceTimeout = null;
    DEBOUNCE_DELAY = 300; // milliseconds

    // ═══════════════════════════════════════════════════════════════════════
    // LIFECYCLE HOOKS
    // ═══════════════════════════════════════════════════════════════════════
    
    disconnectedCallback() {
        // Clean up debounce timeout
        if (this.debounceTimeout) {
            clearTimeout(this.debounceTimeout);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * @api Clear the current selection
     */
    @api
    clearSelection() {
        this.selectedRecord = null;
        this.searchTerm = '';
        this.searchResults = [];
        this.showDropdown = false;
        this.dispatchEvent(new CustomEvent('clear'));
    }

    /**
     * @api Set a record programmatically
     * @param {Object} record - The record to select
     */
    @api
    setSelection(record) {
        if (record) {
            // Transform the record to match expected format
            const transformedRecord = {
                Id: record.Id || record.id,
                Name: record.Name || `${record.firstName || ''} ${record.lastName || ''}`.trim(),
                Title: record.Title || record.title || '',
                Email: record.Email || record.email || '',
                ...record
            };
            this.selectedRecord = transformedRecord;
            this.showDropdown = false;
        }
    }

    /**
     * @api Check validity of the field
     * @returns {Boolean} Whether the field is valid
     */
    @api
    checkValidity() {
        if (this.required && !this.selectedRecord) {
            this.errorMessage = 'Please select a record';
            return false;
        }
        this.errorMessage = '';
        return true;
    }

    /**
     * @api Report validity and show error message if invalid
     * @returns {Boolean} Whether the field is valid
     */
    @api
    reportValidity() {
        return this.checkValidity();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════
    
    handleSearchInput(event) {
        const value = event.target.value;
        this.searchTerm = value;
        this.errorMessage = '';

        // Clear existing debounce
        if (this.debounceTimeout) {
            clearTimeout(this.debounceTimeout);
        }

        // Debounce the search - always perform search (even for empty string for dropdown)
        this.debounceTimeout = setTimeout(() => {
            this.performSearch(value);
        }, this.DEBOUNCE_DELAY);
    }

    handleFocus() {
        // Load contacts on focus if dropdown not already populated
        if (this.searchResults.length === 0 && !this.selectedRecord) {
            this.performSearch(this.searchTerm || '');
        } else if (this.searchResults.length > 0) {
            this.showDropdown = true;
        }
    }

    handleBlur() {
        // Delay closing dropdown to allow click events to fire
        setTimeout(() => {
            this.showDropdown = false;
        }, 200);
    }

    handleResultClick(event) {
        const recordId = event.currentTarget.dataset.id;
        const record = this.searchResults.find(r => r.Id === recordId);
        
        if (record) {
            this.selectedRecord = record;
            this.showDropdown = false;
            this.searchTerm = '';
            this.searchResults = [];
            
            this.dispatchEvent(new CustomEvent('select', {
                detail: { record: record },
                bubbles: false,
                composed: false
            }));
        }
    }

    handleRemoveSelection() {
        this.clearSelection();
    }

    handleKeyDown(event) {
        // TODO: Add keyboard navigation for accessibility
        // Arrow up/down to navigate results
        // Enter to select
        // Escape to close dropdown
        if (event.key === 'Escape') {
            this.showDropdown = false;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * Perform search - uses Apex for Contact or SIC Code searches
     */
    async performSearch(searchTerm) {
        this.isLoading = true;
        
        try {
            if (this.objectType === 'Contact' && this.opportunityId) {
                // Contact search
                const results = await searchContactsByOpportunity({ 
                    searchTerm: searchTerm,
                    opportunityId: this.opportunityId,
                    limitCount: this.limit 
                });
                
                this.searchResults = results.map(record => ({
                    ...record,
                    Title: record.Title || '',
                    subtitle: record.Title ? `${record.Title} • ${record.Email || ''}` : (record.Email || '')
                }));
                this.showDropdown = this.searchResults.length > 0;
            } else if (this.objectType === 'SIC_Code__mdt') {
                // SIC Code search
                const results = await searchSICCodes({ 
                    searchTerm: searchTerm || '',
                    limitCount: this.limit 
                });
                
                this.searchResults = results;
                console.log('GenericLookup: SIC search results', this.searchResults);
                this.showDropdown = this.searchResults.length > 0;
            } else if (this.objectType === 'User') {
                // User search
                const results = await searchUsers({ 
                    searchTerm: searchTerm || '',
                    limitCount: this.limit 
                });
                
                this.searchResults = results.map(record => ({
                    ...record,
                    subtitle: record.Email || ''
                }));
                console.log('GenericLookup: User search results', this.searchResults);
                this.showDropdown = this.searchResults.length > 0;
            } else if (this.objectType === 'Account') {
                // Account search (for TPA Business Accounts)
                const results = await searchBusinessAccounts({ 
                    searchTerm: searchTerm || '',
                    limitCount: this.limit 
                });
                
                this.searchResults = results.map(record => ({
                    ...record,
                    subtitle: this.formatAccountAddress(record)
                }));
                console.log('GenericLookup: Account search results', this.searchResults);
                this.showDropdown = this.searchResults.length > 0;
            } else if (this.objectType === 'Contact' && !this.opportunityId) {
                console.warn('GenericLookup: opportunityId is required for Contact searches');
                this.errorMessage = 'Configuration error: opportunityId is required';
                this.searchResults = [];
                this.showDropdown = false;
            }
        } catch (error) {
            this.errorMessage = 'Error searching records';
            console.error('Search error:', error);
            this.searchResults = [];
            this.showDropdown = false;
        } finally {
            this.isLoading = false;
        }
    }

    formatAccountAddress(account) {
        const parts = [];
        if (account.BillingStreet) parts.push(account.BillingStreet);
        if (account.BillingCity) parts.push(account.BillingCity);
        if (account.BillingState) parts.push(account.BillingState);
        if (account.BillingPostalCode) parts.push(account.BillingPostalCode);
        return parts.join(', ');
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS (Computed Properties)
    // ═══════════════════════════════════════════════════════════════════════
    
    get hasSelection() {
        return this.selectedRecord !== null;
    }

    get showSearchInput() {
        return !this.hasSelection;
    }

    get selectedRecordName() {
        return this.selectedRecord ? this.selectedRecord.Name : '';
    }

    get selectedRecordSubtitle() {
        if (!this.selectedRecord) return '';
        const parts = [];
        if (this.selectedRecord.Title) parts.push(this.selectedRecord.Title);
        if (this.selectedRecord.Email) parts.push(this.selectedRecord.Email);
        return parts.join(' • ');
    }

    get dropdownClass() {
        return this.showDropdown ? 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open' : 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }

    get inputClass() {
        let classes = 'slds-input slds-combobox__input';
        if (this.errorMessage) {
            classes += ' slds-has-error';
        }
        return classes;
    }

    get hasError() {
        return this.errorMessage && this.errorMessage.length > 0;
    }

    get noResultsFound() {
        return !this.isLoading && this.searchTerm.length >= this.minChars && this.searchResults.length === 0;
    }

    get searchResultsWithIndex() {
        return this.searchResults.map((record, index) => ({
            ...record,
            index: index,
            // Keep existing subtitle if present, otherwise build from Title and Email (for Contacts)
            subtitle: record.subtitle || (record.Title ? `${record.Title} • ${record.Email || ''}` : (record.Email || ''))
        }));
    }
}