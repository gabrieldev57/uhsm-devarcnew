import insOsGridProductAttribute from 'vlocity_ins/insOsGridProductAttribute';
import tileTemplate from './arc_InsOsGridStyledProductAttribute.html';
import { api } from 'lwc';
import { dataFormatter } from 'vlocity_ins/insUtility';

export default class arc_InsOsGridStyledProductAttribute extends insOsGridProductAttribute {
    @api attribute;
    @api isCart = false;
    @api rootChannel;
    @api theme;
    @api isGeneralAttribute;
    @api fitText;

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
                // displayValues.push(dataFormatter.formatDisplayValue(attr));
                // Remove decimals and round up. To follow design.
                displayValues.push(this.removeDecimals(dataFormatter.formatDisplayValue(attr)));
            });
            this.item = {
                label: this.attribute.label ? this.attribute.label : labels.join(this.attribute.separator),
                displayValue: displayValues.join(this.attribute.separator)
            };
        }
    }

    removeDecimals(str) {
        return str.replace(/(\.\d{2})/g, '');
    }

    renderedCallback(){
        if(!this.hasRendered){
            if(this.fitText){
                // Defer to allow rendering to complete
                setTimeout(() => {
                    this.fitTextToContainer(this.refs.container, this.refs.value);
                }, 0);
    
                // Add window resize fallback
                window.addEventListener('resize', () => {
                    this.fitTextToContainer(this.refs.container, this.refs.value);
                });
            }
        }
        this.hasRendered = true
    }
    fitTextToContainer(container, text) {
        if (!container || !text) return;

        let fontSize = parseInt(window.getComputedStyle(text).fontSize);
        text.style.whiteSpace = 'nowrap';

        while (text.offsetHeight > container.clientHeight && fontSize > 5) {
            fontSize -= 1;
            text.style.fontSize = `${fontSize}px`;
        }
    }
}