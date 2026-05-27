import { LightningElement, api, wire, track } from 'lwc';
import getMemberAndProgramData from '@salesforce/apex/ARC_CaseHandler.getMemberAndProgramData';
import updateCasePersonAccount from '@salesforce/apex/ARC_CaseHandler.updateCasePersonAccount';
import getEmployerInfo from '@salesforce/apex/ARC_CaseHandler.getEmployerInfo';
import getPolicyCoverages from '@salesforce/apex/ARC_CaseHandler.getPolicyCoverages';
import { subscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import CASE_RECORDTYPE_DEVELOPER_NAME_FIELD from '@salesforce/schema/Case.RecordType.DeveloperName';


export default class ARC_CaseMemberInfo extends NavigationMixin(LightningElement) {

  @api recordId; //case id 
  selectedAccountId = null;
  hideComponent = false; // for the entire component
  isSmallGroupUW = false;
  isUW = false;
  accountData = {
    Name: null,
    Phone: null,
    PersonEmail: null
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

  //-------------- UHSM-3204
  employerData = false;
  employerAccountId;
  employerAccountName;
  employerGroupNumber;
  employerPCName;
  employerPCPhone;
  employerPCEmail;
  employerContractOED;
  formattedContractOED;
  showEmployerSection = false;
  activeCoverages = '';
  continuousCoverageStartDate;
  //-------------- UHSM-3204

  // @wire(getRecord, {
  //   recordId: '$recordId',
  //   fields: [CASE_RECORDTYPE_DEVELOPER_NAME_FIELD]
  // })

  // wiredCaseRecord({ data, error }) {
  //   if (data) {
  //    // const recordTypeDeveloperName = getFieldValue(data, CASE_RECORDTYPE_DEVELOPER_NAME_FIELD);
  //     //this.isSmallGroupUW = recordTypeDeveloperName === 'ARC_SmallGroupUnderwriting'; //
  //     this.hideComponent = false;
  //   } else if (error) {
  //     console.error('Error fetching Case record:', error);
  //   }
  // }

  // get showComponent() {
  //   return !this.hideComponent;
  // }

  get showMemberSection() {
    // if (this.isSmallGroupUW) return false;
    return !this.accountData?.Id;
  }

  @wire(getMemberAndProgramData, { caseId: '$recordId' })
  wiredData(wireResult) {
    this._wiredData = wireResult;
    const { error, data } = wireResult;
    console.log("data from member and program plan: ", data);
    if (data) {
      this.caseData = data.caseData;
      this.currentData = data.currentProgram;
      if (data.accountData == null) {
        this.accountData = {
          Name: null,
          Phone: null,
          PersonEmail: null
        };
      } else this.accountData = data.accountData;

      if (this.caseData?.RecordType.Name == 'Underwriting') {
        this.isUW = true;
        this.zipCode = this.accountData.BillingPostalCode;
        this.state = this.accountData.BillingState;
        this.contract = this.caseData.ARC_Contract__c;
        this.contractNumber = this.caseData.ARC_Contract__r?.ContractNumber;
        this.contractEffDate = this.caseData.ARC_Contract__r?.ARC_EffectiveDate__c;
        this.formattedContractEffDate = new Date(this.contractEffDate + "T00:00:00").toLocaleDateString('en-US');
      }
      this.activePlan = data.currentProgram != null ? data.currentProgram : null;
      this.firstEffectiveDate = data.effectiveDate;
      this.birthdate = this.accountData?.PersonBirthdate != null ? this.accountData?.PersonBirthdate : null;
      this.formattedBirthdate = this.birthdate != null ? new Date(this.birthdate + "T00:00:00").toLocaleDateString('en-US') : null;
      this.formattedFirstDate = this.firstEffectiveDate != null ? new Date(this.firstEffectiveDate + "T00:00:00").toLocaleDateString('en-US') : null;
      this.continuousCoverageStartDate = this.accountData.ARC_ContinuousCoverageStartDate__c;
      if (this.accountData?.Id != null) {
        this.searchAccount = false;
        this.selectedAccountId = this.accountData.Id;
      }
    } else if (error) {
      console.error('Error fetching data:', error);
    }
    console.log('isLoading:', this.isLoading);
    console.log('searchAccount:', this.searchAccount);
    console.log('accountData:', JSON.stringify(this.accountData));
  }

  connectedCallback() {
    this.registerErrorListener();
    this.handleSubscribe();
  }

  //SUBSCRIPTION & HANDLING TO Case Person Account Update EVENT
  handleSubscribe() {
    const messageCallback = response => {
      if (response.data.payload.ARC_CaseId__c == this.recordId) {
        return refreshApex(this._wiredData);
      }
    };

    subscribe(this.channelName, -1, messageCallback).then((response) => {
      this.subscription = response;
    });
  }

  registerErrorListener() {
    onError((error) => {
      console.log('Received error from server: ', JSON.stringify(error));
    });
  }

  handleClick(event) {
    const header = event.currentTarget;
    const section = header.closest('.slds-section');
    if (section) {
      section.classList.toggle('slds-is-open');
    }
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

  changeAccount() {
    this.searchAccount = true;
  }

  handleSave() {
    this.isLoading = true;

    updateCasePersonAccount({ caseId: this.recordId, personAccountId: this.selectedAccountId })
      .then(() => {
        this.searchAccount = false;
        refreshApex(this._wiredData);
      })
      .catch(error => {
        console.error('Error updating Case Person Account:', error);
      })
      .finally(() => {
        this.isLoading = false;
      })
  }

  handleCancel() {
    this.searchAccount = false;
  }

  //-------------- UHSM-3204
  @wire(getEmployerInfo, { caseId: '$recordId' })
  wiredEmployerInfo({ data, error }) {
    if (data) {
      this.employerData = true;
      this.employerAccountId = data.accountId;
      this.employerAccountName = data.accountName;
      this.employerGroupNumber = data.groupNumber;
      this.employerPCName = data.pbcName;
      this.employerPCPhone = data.pbcPhone;
      this.employerPCEmail = data.pbcEmail;
      this.employerContractOED = data.contracOriginalEffeciveDate;
      this.showEmployerSection = !!data.isSmallGroup && !!data.accountId;
    } else if (error) {
      this.showEmployerSection = false;
      console.error(error);
    }
    console.log('getEmployerInfo data:', JSON.stringify(data));
    console.log('getEmployerInfo error:', JSON.stringify(error));
    console.log('showEmployerSection:', this.showEmployerSection);
  }

  get employerUrl() {
    return this.employerAccountId ? `/${this.employerAccountId}` : '';
  }

  get formattedContractDate() {
    return this.formatDate(this.employerContractOED);
  }

  get formattedContinuousCoverageStartDate() {
    return this.formatDate(this.continuousCoverageStartDate);
  }

  formatDate(dateValue) {
    if (!dateValue) return '';

    if (typeof dateValue === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(dateValue)) {
      const [y, m, d] = dateValue.split('-').map(Number);
      return `${String(m).padStart(2, '0')}/${String(d).padStart(2, '0')}/${y}`;
    }

    const date = new Date(dateValue);
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const year = date.getFullYear();

    return `${month}/${day}/${year}`;
  }

  @wire(getPolicyCoverages, { caseId: '$recordId' })
  wiredPolicyCovearges({ data, error }) {
    if (data) {
      const covNames = (data || [])
        .map(x => x.coverageName)
        .filter(Boolean);

      const uniqueNames = [...new Set(covNames)]
        .sort((a, b) => a.localeCompare(b));

      this.activeCoverages = uniqueNames.length
        ? uniqueNames.join(', ')
        : '';
    } else if (error) {
      console.error('getPolicyCoverages error:', error);
      this.activeCoverages = '';
    }
  }
  //-------------- UHSM-3204

}