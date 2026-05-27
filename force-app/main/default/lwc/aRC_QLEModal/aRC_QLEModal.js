import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ARC_QLEModal extends LightningElement {

    @api flowApiName;
    @api flowTitle;
    @api flowInputVariables;

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {

            const outputVars = event.detail.outputVariables;
            const caseCreated = outputVars?.find(v => v.name === 'varCreatedCaseId');

            if (caseCreated?.value) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'The QLE has been created successfully.',
                    variant: 'success'
                }));
            }

            this.handleClose();
        }
    }
}