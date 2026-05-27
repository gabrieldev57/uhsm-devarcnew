import { LightningElement, api, wire } from 'lwc';
import getCoverageParticipantId from '@salesforce/apex/ARC_Beneficiaries360Controller.getCoverageParticipantId';

export default class ARC_Beneficiaries360 extends LightningElement {
    @api recordId;
    coverageParticipantId;
    displayComponent = false;
    isReadOnly = true;

    connectedCallback() {
        // console.log('Record Id =====> ', this.recordId)
    }

    @wire(getCoverageParticipantId, { accountId: '$recordId' })
    wiredCoverageParticipantId({ data, error }) {
        if (data) {
            // console.log('Data retrieved ===> ', data);
            this.coverageParticipantId = data.coverageParticipantId;
            this.displayComponent = data.displayComponent;
        } else if (error) {
            // console.error('Error Message ====> ', error);
        }
    }

    handleEdit() {
        this.isReadOnly = false;
    }

    handleCancel() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
        this.isReadOnly = true;
    }

    handleSuccess() {
        this.isReadOnly = true;
    }
}