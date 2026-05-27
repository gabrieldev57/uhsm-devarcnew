import { LightningElement, api, track } from 'lwc';

export default class ARC_CustomModal extends LightningElement {
    @track detail; // Detail data to use in modal if needed
    @api customClass; // Custom class to add to the modal container for custom css
    
    @track includeHeader = true;
    @track includeFooter = true;
    get bNoHeader(){
        return !this.includeHeader
    }
    get bNoFooter(){
        return !this.includeHeader
    }

    @track isOpen = false;
    @track modalClass = "custom-modal"

    connectedCallback(){
        // Add custom class to the modal's main classList
        if(this.customClass) this.modalClass = this.modalClass + " " + this.customClass
    }

    // Method to open the modal
    // When using await thisModal.open(data), data is stored in this.detail
    // the rest of the code on the method that calls that line will executed
    // with the data that returns on the 'close' method
    @api
    open(args) {
        this.detail = args.detail
        this.isOpen = true;
        return new Promise((resolve, reject) => {
            this.resolve = resolve;
            this.reject = reject;
        });
    }

    // Closes and retuns data from the modal result
    close(result) {
        this.isOpen = false;
        this.resolve(result);
    }
    handleClose() {
        this.close();
    }
}