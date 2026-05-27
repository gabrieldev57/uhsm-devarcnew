import { LightningElement, api ,track} from 'lwc';

export default class ARC_SendEnrollmentLinkModal extends LightningElement {
    @api flowApiName;             // Flow API name
    @api flowTitle = 'Flow';      // Modal title
    @api flowInputVariables = []; // Flow input variables
    @track isOpen = false;
    @track modalAlreadyOpened = false;
    @track emailActionInProgress = false;

    flowKey = Date.now();        
    flowStarted = false;        
    flowCompleted = false;       
    newStyleBackground = false;

    /** Open the modal and pass input variables */
    @api
    openModal(flowInputs = []) {
        console.log('Opening modal. Previous isOpen:', this.isOpen, ', modalAlreadyOpened:', this.modalAlreadyOpened);
        if (this.isOpen) {
            console.log('Modal already open, skipping...');
            return; // Prevent duplicate modal open
        }
        if (this.modalAlreadyOpened) return;
        this.flowInputVariables = flowInputs;
        this.isOpen = true;
        this.flowStarted = false;
        this.flowCompleted = false;
        this.flowKey = Date.now(); // reset flow instance for rerun if needed
        console.log('Modal opened, flowInputs=', flowInputs);
    }

    /** Close modal manually */
    closeModal() {
        this.isOpen = false;
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleClose() {
        // User clicked close button
        this.closeModal();
    }

    /** Flow status change handler */
    handleFlowStatusChange(event) {
        const status = event.detail.status;
        console.log('Flow Status Event Received:', status);
        console.log('Flags before processing - flowStarted:', this.flowStarted, ', flowCompleted:', this.flowCompleted, ', emailActionInProgress:', this.emailActionInProgress);
    
        // Only mark flow started once
        if (!this.flowStarted && status === 'STARTED') {
            this.flowStarted = true;
            this.emailActionInProgress = true; // mark that LWC initiated email action
            console.log('Flow really started, setting flowStarted=true and emailActionInProgress=true');
        }
    
        // Handle FINISHED/ERROR/CANCELED only once and only if LWC initiated action
        if ((status === 'FINISHED' || status === 'ERROR' || status === 'CANCELED') 
            && this.flowStarted && !this.flowCompleted) {
            
            this.flowCompleted = true;
            this.flowStarted = false;
            console.log('Flow marked as completed. flowCompleted=true, flowStarted=false');
    
            if (this.emailActionInProgress) {
                console.log('Closing modal and notifying parent because emailActionInProgress=true');
                this.isOpen = false; // close modal internally
                this.dispatchEvent(new CustomEvent('close')); // notify parent once
                console.log('Flow completed, modal closed, parent notified');
            } else {
                console.log('Ignoring FINISHED event because emailActionInProgress=false');
            }
    
            // Reset email action flag for next modal open
            this.emailActionInProgress = false;
            console.log('emailActionInProgress reset to false for next modal open');
        }
    
        console.log('Flags after processing - flowStarted:', this.flowStarted, ', flowCompleted:', this.flowCompleted, ', emailActionInProgress:', this.emailActionInProgress);
    }

   
    renderedCallback() {
        if (this.newStyleBackground) return;

        const style = document.createElement('style');
        style.innerText = `
            .slds-modal__content .slds-spinner_container {
                background-color: transparent !important;
                background: none !important;
            }
        `;
        document.head.appendChild(style);
        this.newStyleBackground = true;
    }
    
}