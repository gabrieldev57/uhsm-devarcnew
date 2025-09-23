import { LightningElement } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";

export default class ARC_refreshRecordPage extends OmniscriptBaseMixin(LightningElement) {

    connectedCallback() {
        eval("$A.get('e.force:refreshView').fire();");
    }
}