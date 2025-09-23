import { LightningElement, api } from 'lwc';
import CLAIMED_AMOUNT from '@salesforce/schema/ClaimCoveragePaymentDetail.ClaimedAmount';
import ADJUSTED_AMOUNT from '@salesforce/schema/ClaimCoveragePaymentDetail.AdjustedAmount';

export default class POC_TestLightningForm extends LightningElement {
    @api recordId;
    fields = [CLAIMED_AMOUNT, ADJUSTED_AMOUNT];
}