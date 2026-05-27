import { LightningElement, api, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import generateMissedInvoices from '@salesforce/apex/ARC_MissedInvoiceController.generateMissedInvoices';

export default class ARC_GenerateMissedInvoices extends LightningElement {
    // @api recordId works when placed on a record page component.
    // For Quick Actions (ScreenAction) the recordId comes from CurrentPageReference.
    @api recordId;

    @wire(CurrentPageReference)
    setCurrentPageReference(pageRef) {
        if (pageRef?.state?.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }
    isLoading = false;
    isDone = false;
    message = 'This will generate all missed invoices for this contract. Do you want to continue?';

    handleGenerate() {
        this.isLoading = true;
        generateMissedInvoices({ contractId: this.recordId })
            .then(result => {
                this.message = result;
                this.isDone = true;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: result,
                    variant: 'success'
                }));
            })
            .catch(error => {
                this.message = error.body?.message || 'An unexpected error occurred.';
                this.isDone = true;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: this.message,
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    connectedCallback(){
        console.log('recordId2', this.recordId);
    }
}