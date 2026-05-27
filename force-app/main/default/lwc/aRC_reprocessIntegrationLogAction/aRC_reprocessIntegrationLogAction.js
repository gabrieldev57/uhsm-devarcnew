import { LightningElement, api } from 'lwc';
import processApex from '@salesforce/apex/ARC_ProcessIntegrationLog.process';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ProcessIntegrationJsonQuickAction extends LightningElement {
    @api recordId; // auto-provided in Quick Action & on record pages
    message = '';
    isLoading = false;

    async handleClick() {
        this.isLoading = true;
        this.message = '';
        try {
            const res = await processApex({ recordId: this.recordId });
            // Compose a friendly message
            const status = res?.httpStatus != null ? ` (HTTP ${res.httpStatus})` : '';
            this.message = res?.success
                ? `Processed successfully${status}.`
                : `Processing failed${status}: ${res?.errorMessage || res?.errorCode || 'Unknown error'}`;

            // Optional toast
            this.dispatchEvent(
                new ShowToastEvent({
                    title: res?.success ? 'Processed' : 'Processing failed',
                    message: this.message,
                    variant: res?.success ? 'success' : 'error'
                })
            );
        } catch (e) {
            const errMsg = e?.body?.message || e?.message || 'Unexpected error';
            this.message = 'Error: ' + errMsg;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: this.message,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
            // Close the Quick Action modal if launched as an Action
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
}