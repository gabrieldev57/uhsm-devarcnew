import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import encryptedToken from '@salesforce/apex/ARC_caseFileUploadController.encryptedToken';  
import UploadLogo from '@salesforce/resourceUrl/UploadLogo';

export default class caseFileUpload extends LightningElement {
    imageUrl = UploadLogo; 
    @api caseId;
    @api decryptedCaseId;
    showSuccessModal = false;

    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        this.caseId = urlParams.get('caseId');
    
        if (this.caseId) {
            encryptedToken({ encrypted: this.caseId })
                .then((result) => {
                    this.caseId = result;
                })
                .catch(error => {
                    console.error('Decryption failed:', error);
                    this.showToast('Error', 'Failed to decrypt Case ID.', 'error');
                });
        }   
    }  
    
    

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files.map(file => file.documentId);
        this.showSuccessModal = true;
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant })); 
    }
    encryptedToken() {
        const urlParams = new URLSearchParams(window.location.search);
        this.caseId = urlParams.get('caseId');
    
        if (this.caseId) {
            encryptedToken({ encrypted: this.caseId })
                .then((result) => {
                    this.caseId = result;
                })
                .catch(error => {
                    console.error('Decryption failed:', error);
                    this.showToast('Error', 'Failed to decrypt Case ID.', 'error');
                });
        }
    }

    closeModal() {
        this.showSuccessModal = false;
    }
}