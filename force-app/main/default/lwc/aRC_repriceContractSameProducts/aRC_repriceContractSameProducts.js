import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from "lightning/uiRecordApi";
import getUnderwritingCaseMembers from '@salesforce/apex/ARC_GetUnderwritingCaseMember.getUnderwritingCaseMembers';
import CASE_CONTRACT_STATUS from "@salesforce/schema/Case.ARC_Contract__r.Status";
import CASE_STATUS from "@salesforce/schema/Case.Status";
import { refreshApex } from "@salesforce/apex";
import { subscribe, MessageContext } from 'lightning/messageService';
import UC_MEMBER_UPDATE_CHANNEL from '@salesforce/messageChannel/ARC_UCMemberUpdate__c';




export default class ARC_repriceContractSameProducts extends NavigationMixin(LightningElement) {
    @track showModal = false;
    modalTitle;
    modalText;
    modalQuestion;
    okFunction;
    @api recordId;
    case;
    underwritingCaseMembers;
    getUnderwritingCaseMembersResult
    subscription;


    @wire(getUnderwritingCaseMembers, {
        caseId: "$caseId"
    }) getUnderwritingCaseMembers(result) {
        this.getUnderwritingCaseMembersResult = result;
        if (result.data) {
            this.underwritingCaseMembers = result.data.underwritingCaseMembers;
        } else if (result.error) {
            console.error(error);
        }
    }


    @wire(getRecord, {
        recordId: "$caseId",
        fields: [CASE_CONTRACT_STATUS, CASE_STATUS]
    })
    getCase({ error, data }) {
        if (error) {
            console.error(error);
        } else if (data) {
            this.case = data;
        }
    }

    @wire(MessageContext) messageContext;

    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    get caseId() {
        return this.recordId;
    }

    get allRejected() {
        return this.underwritingCaseMembers && this.underwritingCaseMembers.every(member => member.ARC_ApprovalResolution__c == 'Rejected');
    }

    get hasOneRejected() {
        return this.underwritingCaseMembers && this.underwritingCaseMembers.some(member => member.ARC_ApprovalResolution__c == 'Rejected');
    }

    get showReprice() {
        return this.hasOneRejected && !this.allRejected && this.case?.fields.ARC_Contract__r.value.fields.Status.value != 'Terminated' && this.case?.fields.Status.value == 'In Progress';
    }

    handleShowModal() {
        this.showModal = true;
    }

    handleOkButton() {
        this.navigateToRepriceOS();
    }

    handleCloseModal() {
        this.showModal = false;
    }

    handleClickRepriceBtnChangeProd() {
        this.handleShowModal();
    }

    navigateToRepriceOS() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'vlocity_ins__vlocityLWCOmniWrapper'
            },
            state: {
                c__target: 'c:individualAndFamilyRepriceCasePAEnglish',
                c__layout: 'newport', // or 'newport'
                c__ContextId: this.recordId,
                c__tabIcon: 'custom:custom18',
                c__tabLabel: 'Reprice Contract'
            }
        });
        this.handleCloseModal();
    }

    refreshComponent() {
        refreshApex(this.getUnderwritingCaseMembersResult);

    }

    subscribeToMessageChannel() {
        this.subscription = subscribe(this.messageContext,
            UC_MEMBER_UPDATE_CHANNEL,
            (message) => this.handleMessage(message)
        );
    }

    handleMessage(message) {
        if (message.caseId == this.recordId) {
            console.log('Message received', message);
            this.refreshComponent();
        }
    }


}