import { LightningElement, api, wire } from 'lwc';
import getCompanyDetails from '@salesforce/apex/ARC_CompanyDetailsController.getCompanyDetails';
import { refreshApex } from '@salesforce/apex';

export default class ARC_CompanyDetails_CompanyDetails extends LightningElement {
    @api recordId;
    //@api isEdit;
    employer;
    SIC;
    originalEmployer;
    originalSIC;
    _isEdit = false;
    hasInitialized = false;
    @api canEdit;

    //Fixes
    originalEmployerDraft = {
        SIC : '',
        employer : {}
    };

    connectedCallback() {
        //console.log('userId', userId);
    }

    @wire(getCompanyDetails)
    wiredEmployer(result) {
        this.wiredEmployerResult = result;
        console.log("data getCompanyDetails: ", this.wiredEmployerResult);
        const { data, error } = result;
        if (data) {
            this.originalEmployer = JSON.parse(JSON.stringify(data.employer));
            this.originalSIC = data.SIC;
            this.employer = JSON.parse(JSON.stringify(data.employer));
            this.SIC = data.SIC;

            //this code will help us to clone the original employer
            this.originalEmployerDraft = {
                SIC : this.originalSIC,
                employer : JSON.parse(JSON.stringify(this.originalEmployer))
            };

            this.hasInitialized = true;
        } else if (error) {
            console.error('Error loading employer data', error);
        }
    }

    //Cancel logic
    //Cancel will only reset variables
    @api
    set isEdit(value){
        const wasEdit = this._isEdit;
        this._isEdit = value ?? false;
        
        //If cancel was clicked we pass from edit -> view. Keep Save logic apart.
        if (wasEdit && !this._isEdit && !this._justSaved){
            this.resetForm();
        }

        this._justSaved = false; //it gets cleaned always.
    }

    get isEdit(){
        return this._isEdit;
    }

    get isReadOnly() {
        return !this.isEdit;
    }

    get isRequired() {
        return this.isEdit;
    }

    handleFieldChange(event) {
        const { name, value } = event.target;
      
        // Clonar para reactividad (super importante)
        this.employer = {
          ...this.employer,
          [name]: value
        };
      }

    resetForm(){
        if (!this.originalEmployerDraft?.employer){
            return;
        }
        this.employer = JSON.parse(JSON.stringify(this.originalEmployerDraft.employer));
        this.SIC = this.originalEmployerDraft.SIC;
    }

    @api
    confirmSave(){
        //this.SIC = this.employer.Sic;
        this.SIC = this.employer.SIC;
        this.employer = {
            ...this.employer,
             vlocity_ins__CalculatedAddress__c: `${this.employer.BillingStreet}, ${this.employer.BillingCity}, ${this.employer.BillingState} ${this.employer.BillingPostalCode}`
        };

        //The new state becomes the origial
        this.originalEmployer = JSON.parse(JSON.stringify(this.employer));
        this.originalSIC = this.SIC;
        
        this._justSaved = true;
    }

    @api
    validateInputs() {
        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, input) => validSoFar && input.reportValidity(), true);
        return allValid;
    }

    @api
    getFieldValues() {
        let values = {};
        this.template.querySelectorAll('lightning-input').forEach(input => {
            values[input.name] = input.value;
        });
        values['Id'] = this.employer.Id;

        if (values.ARC_FederalEmployerTaxIDNumber__c !== undefined) {
            values.FedTaxId = values.ARC_FederalEmployerTaxIDNumber__c;
            // optional: do not set what it's not expected
            delete values.ARC_FederalEmployerTaxIDNumber__c;
        }

        if (values.vlocity_ins__Email__c !== undefined){
            values.BillingContactEmail = values.vlocity_ins__Email__c;
            // optional: do not set what it's not expected
            delete values.vlocity_ins__Email__c;
        }
        
        if (values.SICCodeDisplay !== undefined){
            values.SIC = this.employer?.Sic;
            values.SICDescription = this.employer?.SicDesc;
            delete values.SICCodeDisplay;
        }
        return values;
    }

    @api
    async refreshData() {
        if (this.wiredEmployerResult) {
            await refreshApex(this.wiredEmployerResult);
        }
    }

    get sicDisplayValue() {
        const sic = this.employer?.Sic || '';
        const sicDesc = this.employer?.SicDesc || '';
    
        if (sic && sicDesc) {
            return `${sic} - ${sicDesc}`;
        }
        return sic || sicDesc || '';
    }
}