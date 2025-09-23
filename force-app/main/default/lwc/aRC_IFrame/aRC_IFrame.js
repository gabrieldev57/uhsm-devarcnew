import { api, LightningElement, wire } from 'lwc';
import getSMBLegacy from '@salesforce/apex/ARC_IFrameController.getSMBLegacyURL';

export default class ARC_IFrame extends LightningElement {
  @api recordId;
  @api height = '500px';
  @api referrerPolicy = 'no-referrer';
  @api sandbox = '';
  @api url = '';
  @api width = '100%';
  hasUrl = false;


  getApexData(){
    getSMBLegacy({ caseId: this.recordId})
    .then(response => {
        if(response != null){
            if(response.ARC_SMBUrl__c != null) {
                this.url = response.ARC_SMBUrl__c;
                this.hasUrl = true;
            }
            else if(response.ARC_SMBSearchUrl__c != null){
                this.url = response.ARC_SMBSearchUrl__c;
                this.hasUrl = true;
            }
            else this.hasUrl = false;
        }
        else this.hasUrl = false;
    });
  }

  connectedCallback(){
    this.getApexData();
  }

}