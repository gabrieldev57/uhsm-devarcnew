import { LightningElement, api } from 'lwc';
import ContractComparison from '@salesforce/apex/ARC_CaseHandler.getContractComparison';
import { NavigationMixin } from 'lightning/navigation';


export default class ARC_NewContractCompare extends NavigationMixin(LightningElement) {
    caseId = ''; // This property will hold the Case Id
    caseData;
    newMemberplans = [];
    oldMemberPlans = [];
    newMembers = [];
    oldMembers = [];
    newContract;
    oldContractLineItems = [];
    contReason;
    formatedOldEffDate;
    formatedNewEffDate;
    formatedNewPTDate;
    formatedOldPTDate;
    @api recordId; // This property will hold the Case Id


    connectedCallback() {
        this.fetchData();
    }

    fetchData() {
        ContractComparison({ caseId: this.recordId })
            .then(data => {
                if (data) {

                    this.caseData = data.caseDataAndMembers;
                    this.oldMemberPlans = data.oldMemberPlans;
                    this.newMemberplans = data.newMemberPlans;
                    this.newContract = data.newContract;
                    this.oldContractLineItems = data.oldContractLineItems;
                    this.newContractLineItems = data.newContractLineItems;
                    if (this.newContract?.vlocity_ins__ExpiredContractId__r?.ARC_EffectiveDate__c != null) {
                        this.formatedOldEffDate = new Date(this.newContract?.vlocity_ins__ExpiredContractId__r?.ARC_EffectiveDate__c + "T00:00:00").toLocaleDateString('en-US', {
                            year: "numeric",
                            month: "2-digit",
                            day: "2-digit",
                        });
                    } else {
                        this.formatedOldEffDate = '';
                    }
                    if (this.newContract?.ARC_EffectiveDate__c != null) {
                        this.formatedNewEffDate = new Date(this.newContract?.ARC_EffectiveDate__c + "T00:00:00").toLocaleDateString('en-US', {
                            year: "numeric",
                            month: "2-digit",
                            day: "2-digit",
                        });
                    } else {
                        this.formatedNewEffDate = '';
                    }
                    //Populate Paid Through Date
                    if (this.newContract?.vlocity_ins__ExpiredContractId__r?.ARC_PaidThroughDate__c != null) {
                        this.formatedOldPTDate = new Date(this.newContract?.vlocity_ins__ExpiredContractId__r?.ARC_PaidThroughDate__c + "T00:00:00").toLocaleDateString('en-US', {
                            year: "numeric",
                            month: "2-digit",
                            day: "2-digit",
                        });
                    } else {
                        this.formatedOldPTDate = '';
                    }
                    if (this.newContract?.ARC_PaidThroughDate__c != null) {
                        this.formatedNewPTDate = new Date(this.newContract.ARC_PaidThroughDate__c + "T00:00:00").toLocaleDateString('en-US', {
                            year: "numeric",
                            month: "2-digit",
                            day: "2-digit",
                        });
                    } else {
                        this.formatedNewPTDate = '';
                    }

                    //fetch old contract members and old contract line items
                    for (let mp of this.oldMemberPlans) {
                        if (!this.oldMembers.some(acc => acc.Id == mp.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.AccountId)) {
                            let customAcc = new Object();
                            customAcc.Id = mp.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.AccountId;
                            customAcc.Name = mp.vlocity_ins__GroupCensusMemberId__r?.Name;
                            this.oldMembers.push(customAcc);
                        }
                    }

                    //fetch new contract members
                    for (let mp of this.newMemberplans) {
                        if (!this.newMembers.some(acc => acc.Id == mp.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.AccountId)) {
                            let customAcc = new Object();
                            customAcc.Id = mp.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.AccountId;
                            customAcc.Name = mp.vlocity_ins__GroupCensusMemberId__r?.Name;
                            this.newMembers.push(customAcc);
                        }
                    }

                    this.contReason = this.newContract?.ARC_ContractReason__c.replace(/;/g, "; ");
                }
            })
            .catch(error => {
                // Handle errors
                console.error(error);
            });
    }

    handleMemberNavigate(event) {
        const memberId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: memberId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    handlePlanNavigate(event) {
        const planId = event.target.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: planId,
                objectApiName: 'vlocity_ins__ContractLineItem__c',
                actionName: 'view'
            }
        });
    }

    handleContractNavigate(event) {
        const contractId = event.target.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: contractId,
                objectApiName: 'Contract',
                actionName: 'view'
            }
        });
    }

}