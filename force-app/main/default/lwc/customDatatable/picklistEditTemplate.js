import { LightningElement,api } from 'lwc';

export default class PicklistEditTemplate extends LightningElement {

    @api editedValue;
    @api typeAttributes;

    handleChange(event) {
        const selectedValue = event.detail.value;

        this.dispatchEvent(new CustomEvent('change', {
            bubbles: true,
            composed: true,
            detail: {
                value: selectedValue,
            }
        }));
    }
}