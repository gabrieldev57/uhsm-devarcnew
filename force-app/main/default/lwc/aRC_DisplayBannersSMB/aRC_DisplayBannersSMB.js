import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['Claim.ARC_PrimaryInsurance__c', 'Claim.ARC_Linked_PA_Voided__c'];

export default class ARC_DisplayBannersSMB extends LightningElement {

    @api recordId;
    hasPrimaryInsuranceAtDOS = false;
    voidedPreAuth = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredClaim({ error, data }) {
        if (data) {
            console.log(data);
            // Primary Insurance
            const primaryInsuranceFlag = data.fields.ARC_PrimaryInsurance__c.value;
            this.hasPrimaryInsuranceAtDOS = primaryInsuranceFlag == 'With Primary Insurance';
            
            // Voided Auth
            const voidedPreAuthFlag = data.fields.ARC_Linked_PA_Voided__c.value;
            this.voidedPreAuth = voidedPreAuthFlag == true;
        }
    }
}