import { LightningElement, api } from 'lwc';
import reprocessProgramChange from '@salesforce/apex/ARC_ReprocessProgramChange.reprocessProgramChange';

export default class ReprocessProgramChangeQuickAction extends LightningElement {
    @api recordId; // this is passed automatically in Quick Action context
    message = '';
    isLoading = false;

    handleClick() {
        this.isLoading = true;
        this.message = '';
        reprocessProgramChange({ recordId: this.recordId })
            .then(result => {
                this.message = result;
            })
            .catch(error => {
                this.message = 'Error: ' + (error.body?.message || error.message);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}