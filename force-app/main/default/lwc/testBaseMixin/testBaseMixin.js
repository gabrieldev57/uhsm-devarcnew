import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
export default class TestBaseMixin extends OmniscriptBaseMixin(LightningElement) {
    @api step;
    async connectedCallback() {
        this.omniNextStep();
    }
}