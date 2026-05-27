import { LightningElement, api } from 'lwc';
import getInvoicePreviewById from '@salesforce/apex/ARC_CompanyInvoicesController.getInvoicePreviewById';

export default class ARC_InvoicePreviewFrame extends LightningElement {
    @api height = '100vh';
    @api width = '100%';

    invoiceId;
    url = '';
    hasUrl = false;
    isLoading = true;
    hasError = false;

    connectedCallback() {
        this.invoiceId = this.getInvoiceIdFromUrl();
        console.log('Invoice Id from URL:', this.invoiceId);
        this.getApexData();
    }

    getInvoiceIdFromUrl() {
        const urlParams = new URLSearchParams(window.location.search);
        return urlParams.get('invoiceId');
    }

    getApexData() {
        if (!this.invoiceId) {
            console.log('No invoiceId found in URL');
            this.hasUrl = false;
            this.hasError = true;
            this.isLoading = false;
            return;
        }

        getInvoicePreviewById({ invoiceId: this.invoiceId })
            .then(response => {
                console.log('Invoice preview response:', JSON.parse(JSON.stringify(response)));

                if (response != null && response.pdfPreview != null) {
                    this.url = response.pdfPreview;
                    this.hasUrl = true;
                    this.hasError = false;

                    console.log('PDF iframe URL:', this.url);
                } else {
                    console.log('No pdfPreview found for invoice preview');
                    this.hasUrl = false;
                    this.hasError = true;
                }

                this.isLoading = false;
            })
            .catch(error => {
                console.log('Error loading invoice preview:', JSON.parse(JSON.stringify(error)));
                this.hasUrl = false;
                this.hasError = true;
                this.isLoading = false;
            });
    }
}