import { LightningElement, api, track } from 'lwc';

export default class ARC_EmployeesTab extends LightningElement {
    @api label;
    @api value;
    @api active = false;

    get computedClass() {
        return ` ${this.active ? 'slds-show' : 'slds-hide'}`;
    }
}