import { LightningElement, api, wire,track } from 'lwc';
import getMemberAndProgramData from '@salesforce/apex/ARC_CaseHandler.getMemberAndProgramData';
import updateCasePersonAccount from '@salesforce/apex/ARC_CaseHandler.updateCasePersonAccount';
import { subscribe, onError } from 'lightning/empApi';
import {refreshApex} from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';


export default class ARC_CaseMemberInfo extends NavigationMixin(LightningElement) {

    @api recordId; //case id 
    selectedAccountId=null;
    isUW = false;
    accountData = {
      Name:null,
      Phone:null,
      PersonEmail:null
    };
    activePlan;
    firstEffectiveDate;
    birthdate;
    zipCode;
    state;
    @api contractId;
    contractNumber;
    contractEffDate;
    formattedContractEffDate;
    formattedBirthdate;
    formattedFirstDate;
    subscription = {};
    @api channelName = '/event/ARC_CasePersonAccountUpdate__e';
    @track _wiredData;
    temporalAccountId;
    searchAccount = true;
    isLoading = false;
    personAccountFilter = {
      criteria: [
      {
      fieldPath: 'RecordType.DeveloperName',
      operator: 'eq',
      value: 'ARC_IFPPersonAccount',
      },
      ],
    };
    @wire(getMemberAndProgramData, { caseId: '$recordId' })
    wiredData(wireResult) {
      this._wiredData = wireResult;
      const {error, data} = wireResult;   
      if (data) {
        this.caseData = data.caseData;
        if(data.accountData == null){
          this.accountData = {
            Name:null,
            Phone:null,
            PersonEmail:null
          };
        } else this.accountData = data.accountData;

        if(this.caseData?.RecordType.Name == 'Underwriting'){
          this.isUW = true;
          this.zipCode = this.accountData.BillingPostalCode;
          this.state = this.accountData.BillingState;
          this.contract = this.caseData.ARC_Contract__c;
          this.contractNumber = this.caseData.ARC_Contract__r?.ContractNumber;
          this.contractEffDate = this.caseData.ARC_Contract__r?.ARC_EffectiveDate__c;
          this.formattedContractEffDate = new Date(this.contractEffDate+"T00:00:00").toLocaleDateString('en-US');
        }
        this.activePlan = data.currentProgram!=null ? data.currentProgram : null;
        this.firstEffectiveDate = data.effectiveDate;
        this.birthdate = this.accountData?.PersonBirthdate!=null ? this.accountData?.PersonBirthdate : null;
        this.formattedBirthdate = this.birthdate!=null ? new Date(this.birthdate+"T00:00:00").toLocaleDateString('en-US'): null;
        this.formattedFirstDate = this.firstEffectiveDate!=null ? new Date(this.firstEffectiveDate+"T00:00:00").toLocaleDateString('en-US') : null;
        if(this.accountData !=null ) {
          this.searchAccount = false;
          this.selectedAccountId = this.accountData.Id;
        }
      } else if (error) {
        console.error('Error fetching data:', error);
      }
    }
    
    connectedCallback(){
      this.registerErrorListener();
      this.handleSubscribe();
  }

  //SUBSCRIPTION & HANDLING TO Case Person Account Update EVENT
  handleSubscribe() {        
    const messageCallback = response => {
        if(response.data.payload.ARC_CaseId__c == this.recordId){
            return refreshApex(this._wiredData);
        }
    };        

        subscribe(this.channelName, -1, messageCallback).then((response) => {
            // console.log(
            //     'Subscription request sent to: ',
            //     JSON.stringify(response.channel)
            // );
            this.subscription = response;
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }       

    handleClick() {
      this.isExpanded = !this.isExpanded; // Toggle expansion state
      let expandableSection = this.template.querySelector('[data-id="expandable-section"]');
      expandableSection.classList.toggle('slds-is-open');
    }

    navigateToContractRecord() {
      if (this.contract) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.contract,
                objectApiName: 'Contract', 
                actionName: 'view'
            }
        });
      }
  }
  navigateToPARecord() {
    if (this.accountData.Id) {
      this[NavigationMixin.Navigate]({
          type: 'standard__recordPage',
          attributes: {
              recordId: this.accountData.Id,
              objectApiName: 'Account', 
              actionName: 'view'
          }
      });
    }
  }


  handleRecordChange(event) {
    this.selectedAccountId = event.detail.recordId;
    
  }
  


  changeAccount(){
    this.searchAccount = true;
  }


  handleSave(){
    this.isLoading = true;

    updateCasePersonAccount({ caseId: this.recordId, personAccountId: this.selectedAccountId })
      .then(() => {
        this.searchAccount = false; // Hide record picker
        refreshApex(this._wiredData); // Refresh data after update
      })
      .catch(error => {
        // Handle error
        console.error('Error updating Case Person Account:', error);
      })
      .finally(()=> {
        this.isLoading=false;
      })
  }
  
  handleCancel(){
    this.searchAccount = false;
  }

}