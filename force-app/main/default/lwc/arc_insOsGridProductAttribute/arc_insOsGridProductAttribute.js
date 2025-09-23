import insOsGridProductAttribute from 'vlocity_ins/insOsGridProductAttribute';
import tileTemplate from './arc_insOsGridProductAttribute.html';
import { api } from 'lwc';
import { dataFormatter } from 'vlocity_ins/insUtility';

export default class arc_InsOsGridProductAttribute extends insOsGridProductAttribute {
    @api attribute;
    @api isCart = false;
    @api rootChannel;
    @api theme;
    @api isGeneralAttribute;

    render() {
        return tileTemplate;
    }

    connectedCallback() {
        const labels = [];
        const displayValues = [];
        if (this.attribute) {
            let attributeFields = JSON.parse(JSON.stringify(this.attribute.fields));
            attributeFields = attributeFields.filter(f => !f.hidden);
            this.isValuePopoverHidden = !attributeFields.length;
            attributeFields.forEach(attr => {
                if (this.isCart && attr.userValues) {
                    attr.displayValue = attr.userValues;
                }
                labels.push(attr.label);
                displayValues.push(dataFormatter.formatDisplayValue(attr));
            });
            this.item = {
                label: this.attribute.label ? this.attribute.label : labels.join(this.attribute.separator),
                displayValue: displayValues.join(this.attribute.separator)
            };
        }
    }
}