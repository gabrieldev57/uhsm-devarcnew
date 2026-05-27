import { LightningElement, api, wire } from 'lwc';
import getAccountManager from '@salesforce/apex/ARC_CompanyDetailsController.getAccountManager';

export default class ARC_CompanyDetails_AccountManager extends LightningElement {
    @api recordId;
    manager;

    @wire(getAccountManager)
    wiredManager({ error, data }) {
        if (data) {
            console.log('Selling Agent:', data);
            this.manager = data;
        } else if (error) {
            console.error('Error loading account manager data', error);
        }
    }

    get hasSellingAgent(){
        return this.manager && this.manager.Name;
    }

    get formattedManagerPhone(){
        if (!this.manager?.Phone) return '';

        const digits = this.manager.Phone.replace(/\D/g, '');

        if (digits.length != 10){
            return this.manager.Phone;
        }

        return `(${digits.slice(0,3)}) ${digits.slice(3,6)}-${digits.slice(6)}`;
    }
}