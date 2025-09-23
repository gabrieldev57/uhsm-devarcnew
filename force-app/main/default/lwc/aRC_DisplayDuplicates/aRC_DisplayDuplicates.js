import { LightningElement, api, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import {getRecord} from 'lightning/uiRecordApi';
import DUPLICATE from '@salesforce/schema/Claim.ARC_Duplicate__c';
import PARTIALDUPLICATE from '@salesforce/schema/Claim.ARC_PartialDuplicate__c';
import DUPLICATECLAIM from '@salesforce/schema/Claim.ARC_Duplicate_SMB__c';
import getDuplicateClaim from '@salesforce/apex/ARC_CheckForDuplicateClaimHandler.getDuplicateClaims';

export default class aRC_DisplayDuplicates extends NavigationMixin(LightningElement) {
    @api showDuplicate;
    @api showPartialDuplicate;
    @api recordId;
    @api reason;
    @api smbDuplicateName;
    @api smbDuplicateId;

    fadingOutLoading = false;

    @wire(getRecord, {recordId:'$recordId', fields: [DUPLICATE,PARTIALDUPLICATE,DUPLICATECLAIM]})
    wiredRecord({data,error}){
        if(data){
            if(data.fields.ARC_Duplicate__c.value){
                getDuplicateClaim({clmId: data.fields.ARC_Duplicate_SMB__c.value})
                .then(res => {
                    this.showDuplicate = true;
                    this.showPartialDuplicate = false;
                    this.reason = 'Duplicate';
                    this.smbDuplicateName=res.Name;
                    this.smbDuplicateId=res.Id;
                });
            } else if (data.fields.ARC_Duplicate__c.value == false && data.fields.ARC_PartialDuplicate__c.value == true) {
                getDuplicateClaim({clmId: data.fields.ARC_Duplicate_SMB__c.value})
                .then(res => {
                    this.showDuplicate = false;
                    this.showPartialDuplicate = true;
                    this.reason = 'Partial Duplicate';
                    this.smbDuplicateName=res.Name;
                    this.smbDuplicateId=res.Id;
                });
            } else {
                this.showDuplicate = false;
                this.showPartialDuplicate = false;
            }
        }
    }

    handleAnimationEnd(event){
        if(event.target.className.includes("alert danger-alert")){
            this.showDuplicate = false;
        } 
        if(event.target.className.includes("alert warning-alert")) {
            this.showPartialDuplicate = false;
        }
    }

    handleNavigate(evt){
        console.log('event:'+evt);
        let clmSelected = evt.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: clmSelected,
                objectApiName: 'Claim',
                actionName: 'view'
            },
        });
    }

}