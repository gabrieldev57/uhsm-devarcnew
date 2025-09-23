import { LightningElement, wire, track, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_RecipientSelector extends OmniscriptBaseMixin(LightningElement) {
    @api hipaas = [];  // This will be the JSON passed from Omniscript
    @track recipientOptions = [];
    @track selectedRecipient = '';
    @track selectedRecipientDetails = null;

    // Handle recipients JSON passed into the component
    @api
    get recipientData() {
        return this.hipaas;
    }

    set recipientData(data) {
        this.hipaas = data;
        // Prepare options for the combobox
        if (data) {
            this.recipientOptions = data.map((recipient) => ({
                Id: recipient.Id,
                label: recipient.name,
                value: recipient.email,
                memberID: recipient.memberID,
                address: recipient.address
            }));
        }
    }

     // Handler when a recipient is selected from the dropdown
     handleRecipientChange(event) {
        const selectedMemberId = event.detail.value;
        this.selectedRecipient = selectedMemberId;
        
        // Find selected recipient details based on member ID
        this.selectedRecipientDetails = this.recipients.find(
            (recipient) => recipient.Id === selectedMemberId
        );
    }
}