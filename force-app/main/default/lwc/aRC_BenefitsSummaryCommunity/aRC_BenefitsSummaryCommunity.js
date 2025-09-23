import { LightningElement, wire, track } from 'lwc';
import UID from '@salesforce/user/Id';
import getContractsAndPlans from '@salesforce/apex/ARC_BenefitSummaryHandler.calculateDatesPerMemberAndProgram';


export default class ARC_BenefitSummaryCommunity extends LightningElement {


    @track contracts = [];
    @track isLoaded = false;
    userId = UID;

    @wire(getContractsAndPlans, { userId: '$userId' })
    getData({ error, data }) {
        console.log('inside JS');
        if (data) {
            this.contracts = JSON.parse(JSON.stringify(data));
            this.isLoaded = true;
        }
        if (error) {
            console.log('ARC_BenefitSummaryHandler error', error);
            this.isLoaded = true;
        }
        else this.isLoaded = true;
    }

    get contractsIsEmpty() {
        console.log('this.contracts.length', this.contracts.length);
        return this.contracts.length === 0;
    }

}