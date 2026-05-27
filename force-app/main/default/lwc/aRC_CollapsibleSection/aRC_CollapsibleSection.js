import { LightningElement, api, track } from 'lwc';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';

/**
 * ARC_CollapsibleSection - Collapsible section wrapper with accessible toggle
 * 
 * @description Reusable collapsible section component with SLDS styling,
 *              color accent line, and auto-close on save functionality.
 *              
 *              Can be used in two modes:
 *              1. Uncontrolled: Section manages its own open/close state (default)
 *              2. Controlled: Parent controls open/close via the 'open' property
 * 
 * Events:
 *   - sectiontoggle: Fired when section is expanded/collapsed { detail: { open: Boolean } }
 *   - requestclose: Fired when section requests to be closed (e.g., after save)
 *   - save: Fired when save button is clicked
 */
export default class ArcCollapsibleSection extends LightningElement {
    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API PROPERTIES
    // ═══════════════════════════════════════════════════════════════════════
    
    /** @api Section title displayed in header */
    @api title = 'Section Title';
    
    /** @api SLDS icon name */
    @api iconName = 'utility:chevronright';

    /** @api Custom icon URL (optional, overrides iconName) */
    @api customIconUrl = '';
    
    /** @api Whether section starts in open state (uncontrolled mode) */
    @api startOpen = false;


    /** @api hide the status btn from Account Record Page */
    @api hideStatus = false;
    get showStatusBadge() {
        return !this.hideStatus;
    }
    
    /** 
     * @api Controlled open state - when set, parent controls open/close.
     * If not set (null/undefined), section manages its own state.
     */
    @api 
    get open() {
        return this._controlledOpen;
    }
    set open(value) {
        this._controlledOpen = value;
        // If controlled mode is enabled, sync internal state
        if (value !== undefined && value !== null) {
            this._isControlled = true;
            this._internalOpen = value;
        }
    }
    
    /** @api Whether section auto-closes after save action */
    @api autoCloseOnSave = false;

    /** @api Section status: 'not-started', 'in-progress', 'complete', 'error' */
    @api status = 'not-started';

    /** @api Hide the Save button (e.g. for read-only community users) */
    @api hideSave = false;

    /** @api Subtitle text displayed below title */
    @api subtitle = '';

    /** @api Accent color for left border (CSS color value) */
    @api accentColor = '#0176d3'; // SLDS brand blue

    /** @api CSS filter to apply to the custom section icon (for color changes) */
    @api iconColorFilter = '';

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE STATE
    // ═══════════════════════════════════════════════════════════════════════
    
    _internalOpen = false;
    _isControlled = false;
    _controlledOpen = null;

    // ═══════════════════════════════════════════════════════════════════════
    // COMPUTED - Current open state (controlled or uncontrolled)
    // ═══════════════════════════════════════════════════════════════════════
    
    get isOpen() {
        return this._isControlled ? this._controlledOpen : this._internalOpen;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // LIFECYCLE HOOKS
    // ═══════════════════════════════════════════════════════════════════════
    
    connectedCallback() {
        // Only use startOpen for uncontrolled mode
        if (!this._isControlled) {
            this._internalOpen = this.startOpen;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * @api Notify the section that a save was completed.
     * If autoCloseOnSave is true, the section will collapse.
     */
    @api
    notifySaved() {
        if (this.autoCloseOnSave && this.isOpen) {
            if (!this._isControlled) {
                this._internalOpen = false;
            }
            this.dispatchToggleEvent(false);
            this.dispatchEvent(new CustomEvent('requestclose'));
        }
    }

    /**
     * @api Programmatically expand the section (uncontrolled mode only)
     */
    @api
    expand() {
        if (!this._isControlled && !this._internalOpen) {
            this._internalOpen = true;
            this.dispatchToggleEvent(true);
        }
    }

    /**
     * @api Programmatically collapse the section (uncontrolled mode only)
     */
    @api
    collapse() {
        if (!this._isControlled && this._internalOpen) {
            this._internalOpen = false;
            this.dispatchToggleEvent(false);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════
    
    handleToggle() {
        const newState = !this.isOpen;
        
        // In uncontrolled mode, update internal state
        if (!this._isControlled) {
            this._internalOpen = newState;
        }
        
        // Always dispatch event so parent can react (or control in controlled mode)
        this.dispatchToggleEvent(newState);
    }

    handleKeyDown(event) {
        // Accessible keyboard support
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleToggle();
        }
    }

    handleSave(event) {
        event.stopPropagation(); // Prevent toggle when clicking save
        // Dispatch save event for parent to handle
        this.dispatchEvent(new CustomEvent('save'));
        
        // TODO: Parent should call notifySaved() after successful save
        // This allows for async save operations before auto-close
    }

    stopProp(event) {
        event.stopPropagation(); // Prevent card header toggle when clicking elements in right section
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    dispatchToggleEvent(openState) {
        this.dispatchEvent(new CustomEvent('sectiontoggle', {
            detail: { open: openState },
            bubbles: false,
            composed: false
        }));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS (Computed Properties)
    // ═══════════════════════════════════════════════════════════════════════
    
    get sectionClasses() {
        return `groupCard ${this.isOpen ? 'expanded' : ''}`;
    }

    get chevronIcon() {
        return this.isOpen ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get statusClass() {
        return `statusBadge ${this.status}`;
    }
    get iconClass() {
        return this.isOpen ? 'iconWrap open' : 'iconWrap';
    }

    get statusLabel() {
        const labels = {
            'complete': 'Complete',
            'in-progress': 'In Progress',
            'not-started': 'Not Started',
            'error': 'Error'
        };
        return labels[this.status] || 'Not Started';
    }

    get statusIcon() {
        const icons = {
            'complete': 'utility:success',
            'in-progress': 'utility:clock',
            'not-started': 'utility:record',
            'error': 'utility:error'
        };
        return icons[this.status] || 'utility:record';
    }

    get showSaveButtonInHeader() {
        return this.isOpen && !this.hideSave;
    }

    get cardBodyClass() {
        return this.isOpen ? 'cardBody' : 'cardBody slds-hide';
    }

    get sectionIconUrl() {
        return this.customIconUrl || '';
    }

    get useCustomSectionIcon() {
        return !!this.customIconUrl;
    }
}