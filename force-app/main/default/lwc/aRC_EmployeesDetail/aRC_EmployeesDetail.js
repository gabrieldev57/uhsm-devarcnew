import { LightningElement, api, wire,track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const FIELDS = [
    'Account.BillingStreet',
    'Account.BillingCity',
    'Account.BillingState',
    'Account.BillingPostalCode',
    'Account.PersonBirthdate',
    'Account.vlocity_ins__SocialSecurityNumber__pc',
    'Account.PersonEmail',
    'Account.Phone',
    'Account.ARC_HireDate__c',
    'Account.ARC_TerminationDate__c',
    'Account.ARC_JobTitle__c'
];


export default class ARC_EmployeesDetail extends LightningElement {
    @api recordId;          // Account Id (can be Person Account)
    @api object = 'Account';
    @api canEdit = false;
    @track editMode = false;

    @track isLoading = false;
    error;

    street;
    city;
    state;
    postalCode;
    birthdate;
    hireDate;
    terminationDate;
    ssn;
    email;
    phone;
    jobTitle;

    // Fetch address fields
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.street = data.fields.BillingStreet.value;
            this.city = data.fields.BillingCity.value;
            this.state = data.fields.BillingState.value;
            this.postalCode = data.fields.BillingPostalCode.value;
            this.birthdate = data.fields.PersonBirthdate.value;
            this.hireDate = data.fields.ARC_HireDate__c.value;
            this.terminationDate = data.fields.ARC_TerminationDate__c.value;
            this.ssn = data.fields.vlocity_ins__SocialSecurityNumber__pc.value;
            this.email = data.fields.PersonEmail.value;
            this.phone = data.fields.Phone.value;
            this.jobTitle = data.fields.ARC_JobTitle__c.value;
        } else if (error) {
            this.error = error;
        }
    }

    // Format address
    get formattedAddress() {
        let address = '';

        if (this.street) address += this.street;
        if (this.city) address += `, ${this.city}`;
        if (this.state) address += `, ${this.state}`;
        if (this.postalCode) address += ` ${this.postalCode}`;

        return address;
    }

    // format date of birth
    get formattedBirthdate() {
        if (!this.birthdate) return '';
        const parts = this.birthdate.split('-');
        return `${parts[1]}-${parts[2]}-${parts[0]}`;
    }

    get formattedHireDate() {
        if (!this.hireDate) return '';
        const parts = this.hireDate.split('-');
        return `${parts[1]}-${parts[2]}-${parts[0]}`;
    }

    get formattedTerminationDate() {
        if (!this.terminationDate) return '';
        const parts = this.terminationDate.split('-');
        return `${parts[1]}-${parts[2]}-${parts[0]}`;
    }

    //masked ssn
    get maskedSSN() {
        if (!this.ssn) return '';
    
        const last4 = this.ssn.slice(-4);
        return `●●●-●●-${last4}`; 
    }

    /*** Cancel edit mode*/
    handleCancel() {
        this.isLoading = false;
        this.editMode = false;
    }

    handleEdit() {
        this.editMode = true;
    }

    get showEditButton() {
        return this.canEdit && !this.editMode;
    }

    handleSubmit(event) {
        event.preventDefault(); // prevent default submit
        this.isLoading = true;   // show spinner

        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleError(event) {
       // this.isSaving = false; // hide spinner
       this.isLoading = false;  // hide spinner
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error updating record',
                message: event.detail.message,
                variant: 'error'
            })
        );
    }

    /*success handler*/
    handleSuccess(event) {
        this.isLoading = false;  // hide spinner
        this.editMode = false;

    const updatedRecordId = event.detail.id; // ID of the updated record

    // Show toast message
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message: 'Record has been updated successfully',
            variant: 'success'
        })
    );

    //console.log('Record updated: ', updatedRecordId);
    }
}