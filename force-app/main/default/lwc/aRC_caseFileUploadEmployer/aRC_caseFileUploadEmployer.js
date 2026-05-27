import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import encryptedToken from '@salesforce/apex/ARC_caseFileUploadController.encryptedToken';
import UploadLogo from '@salesforce/resourceUrl/UploadLogo';
import updateCaseAndReplaceFile from '@salesforce/apex/ARC_EmployerCaseFileUploadController.updateCaseAndReplaceFile';

export default class ARC_caseFileUploadEmployer extends LightningElement {
    imageUrl = UploadLogo;
    @api caseId;
    showSuccessModal = false;

    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        const encryptedCaseId = urlParams.get('caseId');

       // this.observer = new MutationObserver(() => { const closeBtn = document.querySelector('.slds-modal__close'); if (closeBtn) { closeBtn.style.display = 'none'; this.observer.disconnect(); } }); this.observer.observe(document.body, { childList: true, subtree: true });

        const style = document.createElement('style');
        style.id = 'hide-modal-close-btn';
        style.textContent = '.slds-modal__close { display: none !important; }';
        document.head.appendChild(style);

        if (encryptedCaseId) {
            encryptedToken({ encrypted: encryptedCaseId })
                .then((result) => {
                    this.caseId = result;
                })
                .catch(error => {
                    this.showToast('Error', 'Failed to decrypt Case ID.', 'error');
                });
        }
    }

    disconnectedCallback() { 
        const style = document.getElementById('hide-modal-close-btn');
        if (style) {
            style.remove();
         }
     }

    // handleUploadFinished(event) {
    //     const uploadedFiles = event.detail.files;

    //     console.log('Response: ' + JSON.stringify(uploadedFiles));

    //     if (!uploadedFiles || uploadedFiles.length === 0) {
    //         this.showToast('Error', 'No file was uploaded.', 'error');
    //         return;
    //     }

    //     if (uploadedFiles.length !== 1) {
    //         this.showToast('Error', 'Please upload only one CSV file.', 'error');
    //         return;
    //     }

    //     const uploadedFile = uploadedFiles[0];
    //     const fileName = uploadedFile.name;


    //     if (!fileName.toLowerCase().endsWith('.csv')) {
    //         this.showToast('Error', 'Only CSV files are allowed.', 'error');
    //         return;
    //     }


    //     let inputmap = {
    //         'caseId': this.caseId,
    //         'newContentVersionId': uploadedFile.contentVersionId
    //     };

    //     updateCaseAndReplaceFile({
    //         mapIds: inputmap
    //     })
    //     .then(() => {
    //         this.showSuccessModal = true;
    //     })
    //     .catch(error => {
    //         this.showToast(
    //             'Error', 
    //             error.body?.message || 'Failed to process the uploaded file.', 
    //             'error'
    //         );
    //     });
    // }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;

        if (!uploadedFiles || uploadedFiles.length === 0) {
            this.showToast('Error', 'No file was uploaded.', 'error');
            return;
        }

        const hasMultipleFiles = uploadedFiles.length > 1;

        if (hasMultipleFiles) {
            this.showToast(
                'Error',
                'If you upload multiple files, only the last file will be processed, please ensure to only upload one file indeed.',
                'error'
            );
        }

        // last file in the list
        const uploadedFile = uploadedFiles[uploadedFiles.length - 1];
        const fileName = uploadedFile.name;

        if (!fileName.toLowerCase().endsWith('.csv')) {
            this.showToast('Error', 'Only CSV files are allowed.', 'error');
            return;
        }

        const inputmap = {
            caseId: this.caseId,
            newContentVersionId: uploadedFile.contentVersionId
        };

        updateCaseAndReplaceFile({ mapIds: inputmap })
            .then(() => {
                if (!hasMultipleFiles) {
                    this.showSuccessModal = true;
                }
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    error.body?.message || 'Failed to process the uploaded file.',
                    'error'
                );
            });
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    closeModal() {
        this.showSuccessModal = false;
    }
}