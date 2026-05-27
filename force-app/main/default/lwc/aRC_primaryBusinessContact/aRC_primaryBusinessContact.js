import { LightningElement, api, wire } from 'lwc';
import getPrimaryBusinessContact from '@salesforce/apex/aRC_primaryBusinessContactController.getPrimaryBusinessContact';

export default class ARC_primaryBusinessContact extends LightningElement {
    @api recordId;
    contact;
    error;

    @wire(getPrimaryBusinessContact, { opportunityId: '$recordId' })
    wiredPrimaryBusinessContact({ data, error }) {
        if (data) {
            this.contact = data;
            this.error = undefined;
        } else if (error) {
            this.contact = undefined;
            this.error = error;
        }
    }

    get hasContact() {
        return !!this.contact;
    }

    get noData() {
        return !this.contact && !this.error;
    }

    get contactUrl() {
        return this.contact?.contactId ? '/' + this.contact.contactId : '#';
    }

    get emailHref() {
        return this.contact?.email ? 'mailto:' + this.contact.email : '#';
    }
}