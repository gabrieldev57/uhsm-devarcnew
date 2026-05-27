import { LightningElement, api, track } from 'lwc';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';

/**
 * ARC_FormTable - Generic reusable data table component
 * 
 * @description Pure data table for displaying rows with edit/delete actions.
 *              Header, title, and add button should be controlled by the parent component.
 * 
 * Events:
 *   - rowschange: Fired when rows array changes { detail: { rows: Array } }
 *   - editrow: Fired when edit is requested { detail: { row: Object, index: Number } }
 *   - removerow: Fired when remove is requested { detail: { row: Object, index: Number } }
 */
export default class ArcFormTable extends LightningElement {
    // Custom icon URLs
    editIconUrl = `${SGFormIcons}/edit.svg`;
    trashIconUrl = `${SGFormIcons}/trash.svg`;
    greenCheckUrl = `${SGFormIcons}/greenCheck.svg`;
    redXUrl = `${SGFormIcons}/redX.svg`;

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════

    /** @api Array of row objects */
    @api 
    get rows() {
        return this._rows;
    }
    set rows(value) {
        this._rows = value ? [...value] : [];
    }

    /** @api Column definitions array [{ label, fieldName, type }] */
    @api
    get columns() {
        return this._columns;
    }
    set columns(value) {
        this._columns = value ? [...value] : [];
    }

    /** @api Whether the table is read-only (hides action buttons) */
    @api readOnly = false;

    /** @api Whether to show totals row */
    @api showTotals = false;

    /** @api Field name for percentage total calculation */
    @api totalField = '';

    /** @api Message to show when table is empty */
    @api emptyMessage = 'No items added yet.';

    /** @api Label for row count (e.g., "TPAs", "Contacts", "Items") */
    @api rowCountLabel = 'items';

    /** @api Whether the table is rendered inside a community/experience site */
    @api isCommunity = false;

    // ═══════════════════════════════════════════════════════════════════════
    // TRACKED STATE
    // ═══════════════════════════════════════════════════════════════════════
    
    @track _rows = [];
    @track _columns = [];

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * @api Get current rows array
     * @returns {Array} Current rows
     */
    @api
    getRows() {
        return [...this._rows];
    }

    /**
     * @api Add a row programmatically
     * @param {Object} row - Row object to add
     */
    @api
    addRow(row) {
        if (this._rows.length < this.maxRows) {
            this._rows = [...this._rows, { ...row, id: this.generateId() }];
            this.dispatchRowsChange();
        }
    }

    /**
     * @api Update a row at specific index
     * @param {Number} index - Index of row to update
     * @param {Object} row - New row data
     */
    @api
    updateRow(index, row) {
        if (index >= 0 && index < this._rows.length) {
            this._rows = this._rows.map((r, i) => i === index ? { ...row, id: r.id } : r);
            this.dispatchRowsChange();
        }
    }

    /**
     * @api Remove a row at specific index
     * @param {Number} index - Index of row to remove
     */
    @api
    removeRow(index) {
        if (index >= 0 && index < this._rows.length) {
            this._rows = this._rows.filter((_, i) => i !== index);
            this.dispatchRowsChange();
        }
    }

    /**
     * @api Check validity of table data
     * @returns {Boolean} Whether table has valid data
     */
    @api
    checkValidity() {
        return this._rows.length > 0;
    }

    /**
     * @api Reset rows to empty array
     */
    @api
    reset() {
        this._rows = [];
        this.dispatchRowsChange();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    handleEditRow(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const row = this._rows[index];
        
        this.dispatchEvent(new CustomEvent('editrow', {
            detail: { row: row, index: index },
            bubbles: false,
            composed: false
        }));
    }

    handleRemoveRow(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const row = this._rows[index];
        
        // Dispatch event FIRST - let parent handle confirmation and deletion
        // Parent will call a public method to actually remove the row if confirmed
        this.dispatchEvent(new CustomEvent('removerow', {
            detail: { row: row, index: index },
            bubbles: false,
            composed: false
        }));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    generateId() {
        return 'row_' + Date.now() + '_' + Math.random().toString(36).substring(2, 9);
    }

    dispatchRowsChange() {
        this.dispatchEvent(new CustomEvent('rowschange', {
            detail: { rows: [...this._rows] },
            bubbles: false,
            composed: false
        }));
    }

    getCellValue(row, column) {
        const value = row[column.fieldName];
        
        if (value === null || value === undefined) {
            return '-';
        }

        switch (column.type) {
            case 'boolean':
                return value ? 'Yes' : 'No';
            case 'percent':
                return `${value}%`;
            case 'currency':
                return `$${parseFloat(value).toFixed(2)}`;
            case 'date':
                return new Date(value).toLocaleDateString();
            default:
                return value;
        }
    }

    getBooleanIcon(value) {
        return value ? 'utility:check' : 'utility:close';
    }

    /**
     * Get badge CSS class based on value
     * @param {String} value - The badge value
     * @returns {String} CSS class for the badge
     */
    getBadgeClass(value) {
        const normalizedValue = (value || '').toLowerCase();
        
        // Map values to badge styles
        const badgeClasses = {
            'admin': 'badge badge-admin',
            'viewer': 'badge badge-viewer',
            'full access': 'badge badge-admin',
            'no access': 'badge badge-no-access',
            'active': 'badge badge-success',
            'inactive': 'badge badge-inactive',
            'pending': 'badge badge-warning'
        };
        
        return badgeClasses[normalizedValue] || 'badge badge-default';
    }

    /**
     * Get eligible display class based on value
     * @param {String} value - The eligible display value ('Yes' or 'No')
     * @returns {String} CSS class for the eligible display
     */
    getEligibleClass(value) {
        const normalizedValue = (value || '').toLowerCase();
        return normalizedValue === 'yes' ? 'eligible eligible-yes' : 'eligible eligible-no';
    }

    /**
     * Get eligible icon URL based on value
     * @param {String} value - The eligible display value ('Yes' or 'No')
     * @returns {String} URL for the eligible icon
     */
    getEligibleIcon(value) {
        const normalizedValue = (value || '').toLowerCase();
        return normalizedValue === 'yes' ? this.greenCheckUrl : this.redXUrl;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS (Computed Properties)
    // ═══════════════════════════════════════════════════════════════════════
    
    get hasRows() {
        return this._rows.length > 0;
    }

    get rowsWithIndex() {
        return this._rows.map((row, index) => {
            const processedRow = {
                ...row,
                index: index,
                cells: this._columns.map(col => ({
                    key: `${row.id}_${col.fieldName}`,
                    value: this.getCellValue(row, col),
                    isBoolean: col.type === 'boolean',
                    isBadge: col.type === 'badge',
                    isNameWithIcon: col.type === 'name-with-icon',
                    isEligible: col.type === 'eligible',
                    badgeClass: col.type === 'badge' ? this.getBadgeClass(row[col.fieldName]) : '',
                    eligibleClass: col.type === 'eligible' ? this.getEligibleClass(row[col.fieldName]) : '',
                    eligibleIcon: col.type === 'eligible' ? this.getEligibleIcon(row[col.fieldName]) : '',
                    booleanValue: row[col.fieldName],
                    booleanIcon: this.getBooleanIcon(row[col.fieldName])
                }))
            };
            return processedRow;
        });
    }

    get totalValue() {
        if (!this.totalField) return 0;
        return this._rows.reduce((sum, row) => {
            return sum + (parseFloat(row[this.totalField]) || 0);
        }, 0);
    }

    get totalDisplay() {
        return `${this.totalValue.toFixed(1)}%`;
    }

    get isTotalValid() {
        return this.totalValue <= 100;
    }

    get totalClass() {
        return this.isTotalValid 
            ? 'slds-text-color_success' 
            : 'slds-text-color_error';
    }

    get showEmptyState() {
        return !this.hasRows;
    }

    get containerClass() {
        return this.isCommunity ? 'form-table-container community-mode' : 'form-table-container';
    }

    get showActions() {
        return !this.readOnly;
    }

    get totalColspan() {
        // For totals row, span most columns then show total
        return this._columns.length - 1;
    }

    get showRowCount() {
        return this.hasRows;
    }

    get rowCount() {
        return this._rows.length;
    }
}