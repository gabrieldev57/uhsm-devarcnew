import {LightningElement, api} from 'lwc';

export default class ARC_SubmitLOA extends LightningElement {

    @api flowApiName;
    @api flowTitle;
    @api flowInputVariables;

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.handleClose();
        }
    }
    
}