import { LightningElement, api, wire, track } from 'lwc';
import getSelectedPlans from '@salesforce/apex/ARC_SGSelectedPlansController.getSelectedPlans';

export default class ARC_SGSelectedPlansComponent extends LightningElement {
    @api recordId;
    @track plans = [];
    error;

    @wire(getSelectedPlans, { accountId: '$recordId' })
    wiredPlans({ error, data }) {
        if (data) {
            this.plans = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.plans = undefined;
            console.error('Error fetching plans:', error);
        }
    }

    get hasPlans() {
        return this.plans && this.plans.length > 0;
    }

    get planCount() {
        return this.plans ? this.plans.length : 0;
    }

    get totalMonthly() {
        if (!this.plans) return '0.00';
        const total = this.plans.reduce((sum, plan) => sum + (plan.unitPrice || 0), 0);
        return total.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    }
}