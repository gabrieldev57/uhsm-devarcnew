import { LightningElement, api } from 'lwc';
import './badgeTemplate.css'; 


export default class BadgeTemplate extends LightningElement {
    @api value;

    get computedBadgeClass() {
        // base SLDS badge
        let baseClass = 'slds-badge slds-m-around_x-small';

        // dynamically add SLDS theme classes based on status
        switch(this.value) {
            case 'Active':
                return `${baseClass} slds-theme_success`; // green
            case 'Awaiting Approval':
            case 'Awaiting Activation':
            case 'Awaiting Signature':
                return `${baseClass} slds-theme_warning`; // yellow/orange
            case 'Inactive':
                return `${baseClass} slds-theme_error`; // red
            default:
                return `${baseClass} slds-theme_default`; // gray
        }
    }
}