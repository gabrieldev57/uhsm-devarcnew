import { LightningElement, api } from 'lwc';

/**
 * ARC_RadioGroup - Reusable radio button group component
 * 
 * @description Renders a fieldset with radio buttons in a styled box.
 *              Supports horizontal layout with customizable options.
 * 
 * Events:
 *   - change: Fired when selection changes { detail: { value: String } }
 */
export default class ArcRadioGroup extends LightningElement {
    /** @api Label for the radio group (shown as legend) */
    @api label = '';

    /** @api Unique name for the radio group */
    @api name = '';

    /** @api Array of options [{ label: String, value: String }] */
    @api options = [];

    /** @api Currently selected value */
    @api value = '';

    /** @api Whether the field is required */
    @api required = false;

    /** @api Whether the radio group is disabled */
    @api disabled = false;

    /** @api Whether to hide the styled box background */
    @api hideBox = false;

    /** @api Custom CSS class for the container */
    @api containerClass = '';

    /** @api Custom background color for the radio box */
    @api backgroundColor = '';

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    get containerClasses() {
        let classes = 'radio-group-container';
        if (!this.hideBox) {
            classes += ' radio-box';
        }
        if (this.containerClass) {
            classes += ' ' + this.containerClass;
        }
        return classes;
    }

    get containerStyle() {
        if (this.backgroundColor && !this.hideBox) {
            return `background-color: ${this.backgroundColor};`;
        }
        return '';
    }

    get optionsWithChecked() {
        return this.options.map((opt, index) => ({
            ...opt,
            id: `${this.name}_${opt.value}_${index}`,
            isChecked: opt.value === this.value,
            spanClass: index < this.options.length - 1 ? 'slds-radio slds-m-right_medium' : 'slds-radio'
        }));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    handleChange(event) {
        const selectedValue = event.target.value;
        this.dispatchEvent(new CustomEvent('change', {
            detail: { value: selectedValue }
        }));
    }
}