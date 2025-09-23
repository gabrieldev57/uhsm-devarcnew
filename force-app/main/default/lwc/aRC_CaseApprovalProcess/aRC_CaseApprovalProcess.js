import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';
import { publish, MessageContext } from 'lightning/messageService';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import approvalCloseAllButtons from '@salesforce/customPermission/Case_Approval_Close_All';
import approvalCloseVoid from '@salesforce/customPermission/Case_Approval_Close_Void';
import approvalEditFields from '@salesforce/customPermission/Case_Approval_Edit_Fields';
import getUnderwritingCaseMembers from '@salesforce/apex/ARC_GetUnderwritingCaseMember.getUnderwritingCaseMembers';
import saveUCMembers from '@salesforce/apex/ARC_GetUnderwritingCaseMember.saveUCMembers';
import closeCase from '@salesforce/apex/ARC_GetUnderwritingCaseMember.closeCase';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import USER_ID from '@salesforce/user/Id';
import CASE_IS_CLOSED from '@salesforce/schema/Case.IsClosed';
import CASE_STATUS from '@salesforce/schema/Case.Status';
import CASE_OWNER from '@salesforce/schema/Case.OwnerId';
import CASE_REPRICED from '@salesforce/schema/Case.ARC_repricedContract__c';
import CASE_SIGNED from '@salesforce/schema/Case.ARC_Contract__r.vlocity_ins__LastDocuSignEnvelopeStatus__c';
import CONTRACT_OBJECT from '@salesforce/schema/Contract';
import CONTRACT_CANCELLATION_REASON from '@salesforce/schema/Contract.ARC_CancellationReason__c';
import UC_MEMBER_UPDATE_CHANNEL from '@salesforce/messageChannel/ARC_UCMemberUpdate__c';



export default class ARC_CaseApprovalProcess extends NavigationMixin(LightningElement) {

    /**Permission sets
    Case_Approval_Close_All_buttons
    Case_Approval_Close_Void_button
    Case_Approval_Edit_Fields
    */

    get hasApprovalCloseAllButtons() {
        return approvalCloseAllButtons;
    }

    get hasApprovalCloseVoid() {
        return approvalCloseVoid;
    }

    get hasApprovalEditFields() {
        return approvalEditFields;
    }


    @api recordId;
    userId = USER_ID;
    @track prfName;
    @track claimProfile = false;
    @track adminProfile = false;
    dataRetrieved;
    @track repricedContract;
    disableButtons = false;
    isSaved = true;
    isChanged = false;
    case;
    _isLoading = false;
    underwritingCaseMembers = [];
    selectedCloseOption;
    picklistValues;
    cancelReasonOptions;
    contractRecordTypeId;
    cancelReasonSelectedOptions;
    showModal = false;



    // get case
    @wire(getRecord, {
        recordId: "$caseId", fields: [CASE_STATUS, CASE_REPRICED, CASE_SIGNED, CASE_IS_CLOSED, CASE_OWNER]
    }) getCaseRecord({ data, error }) {
        if (data) {
            this.case = data;
            // console.log('this.case = data', this.case);
            // console.log("contract status", this.case?.fields.ARC_Contract__r.value.fields.vlocity_ins__LastDocuSignEnvelopeStatus__c.value);
            // console.log("contract value ", this.case?.fields.ARC_Contract__r.value);
        }
        if (error) {
            console.error(error);
        }

    }

    //Get Profile Name from User
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.prfName = data.fields.Profile.value.fields.Name.value;
            // console.log("profile is: ",this.prfName);
            if (this.prfName == 'Claim Auditor' || this.prfName == 'Claim User' || this.prfName == 'Claim Administrator') {
                this.claimProfile = true;
            }
            else if(this.prfName == "System Administrator"){
                this.adminProfile = true;
            }
        }
    }


    //get underwritingCaseMembers
    @wire(getUnderwritingCaseMembers, {
        caseId: "$caseId"
    }) getUnderwritingCaseMembers({ data, error }) {
        if (data) {
            this.underwritingCaseMembers = this.formatUCMembers(data.underwritingCaseMembers);
            // console.log("underwritingCaseMembers: ",this.underwritingCaseMembers);
        }
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
                // console.log("message: ",message);
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
                // console.log("message: ",message);
            }
            this.showToast('Error', message, 'error', 'dismissable');
        }
    }    

    @wire(getObjectInfo, { objectApiName: CONTRACT_OBJECT })
    results({ error, data }) {
        if (data) {
            this.contractRecordTypeId = data.defaultRecordTypeId;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contractRecordTypeId = undefined;
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$contractRecordTypeId", fieldApiName: CONTRACT_CANCELLATION_REASON })
    picklistResults({ error, data }) {
        if (data) {
            this.picklistValues = data.values;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.picklistValues = undefined;
        }
    }

    @wire(MessageContext) messageContext;    


    get caseId() {
        return this.recordId;
    }

    get optionsStatus() {
        return [
            { label: 'Approved', value: 'Approved' },
            { label: 'Rejected', value: 'Rejected' },
            { label: 'Pending', value: 'Pending' },
            { label: 'Non-Locate', value: 'Non-Locate' }
        ];
    }

    get disableCloseApproveButtonForAdmins() {
        return !(!this.isMissingData &&
            ((
                this.case?.fields.Status.value === "In Progress"
                && (this.case?.fields.ARC_repricedContract__c.value == false)
                && (this.allMembersApprovedForAdmin)
                && this.allMembersRejected == false
            ) ||
            (
                this.case?.fields.Status.value === "In Progress"
                && (this.case?.fields.ARC_repricedContract__c.value == true)
                && (this.case?.fields.ARC_Contract__r.value.fields.vlocity_ins__LastDocuSignEnvelopeStatus__c.value == "Completed")
            ) 
            )
        );
    }

    get disableCloseApproveButton() {
        return !(!this.isMissingData &&
            ((
                this.case?.fields.Status.value === "In Progress"
                && (this.case?.fields.ARC_repricedContract__c.value == false)
                && (this.allMembersApproved)
                && this.allMembersRejected == false
            ) ||
            (
                this.case?.fields.Status.value === "In Progress"
                && (this.case?.fields.ARC_repricedContract__c.value == true)
                && (this.case?.fields.ARC_Contract__r.value.fields.vlocity_ins__LastDocuSignEnvelopeStatus__c.value == "Completed")
            ) ||
            (
                this.hasApprovalCloseVoid == 'undefined' || this.hasApprovalEditFields == 'undefined' || this.hasApprovalCloseAllButtons == 'undefined'
            )) && (this.userId == this.case?.fields.OwnerId.value) 
            
        );
    }

    get disableCloseDeny() {
        return (
            (this.case?.fields.IsClosed.value 
                || this.userId != this.case?.fields.OwnerId.value 
                // || this.prfName === 'WS Sales' 
                // || this.prfName === 'Claim Auditor' 
                // || this.prfName === 'Claim User' 
                // || this.prfName === 'Claim Administrator'
            ) || 
            (
                this.case?.fields.Status.value === "Draft"
            ) || 
            (
                this.hasApprovalCloseVoid == undefined 
                && this.hasApprovalEditFields == undefined 
                && this.hasApprovalCloseAllButtons == undefined
            ) || 
            (
                this.hasApprovalCloseAllButtons == undefined
            )
        )
    }

    get disableCloseDenyForAdmins() {
        return (this.case?.fields.IsClosed.value)
    }

    get disableCloseVoid() {
        return (
            (this.case?.fields.IsClosed.value 
                || this.userId != this.case?.fields.OwnerId.value 
            ) || 
            (
                this.hasApprovalCloseVoid == undefined 
                && this.hasApprovalEditFields == undefined 
                && this.hasApprovalCloseAllButtons == undefined
            ) ||
            (
                this.hasApprovalCloseAllButtons == undefined 
                && this.hasApprovalCloseVoid == true 
                && (this.case?.fields.ARC_Contract__r.value.fields.vlocity_ins__LastDocuSignEnvelopeStatus__c.value == 'Completed' || this.case?.fields.ARC_Contract__r.value == null) 
            ) ||
            (
                this.hasApprovalCloseAllButtons == undefined 
                && this.hasApprovalCloseVoid == undefined 
                && (this.case?.fields.ARC_Contract__r.value.fields.vlocity_ins__LastDocuSignEnvelopeStatus__c.value == 'Completed' || this.case?.fields.ARC_Contract__r.value == null) 
            ) ||
            (
                this.hasApprovalEditFields == true
                && (this.hasApprovalCloseVoid == undefined && this.hasApprovalCloseAllButtons == undefined)
            )
        )
    }

    get disableCloseVoidForAdmins() {
        return (this.case?.fields.IsClosed.value)
    }

    get allMembersRejected() {
        return this.underwritingCaseMembers.every(ucMember => ucMember.ARC_ApprovalResolution__c === 'Rejected');
    }

    get allMembersApproved() {
        return this.underwritingCaseMembers.every(ucMember => ucMember.ARC_ApprovalResolution__c === 'Approved') && (this.hasApprovalEditFields == 'undefined' || this.hasApprovalCloseAllButtons == true);
    }

    get allMembersApprovedForAdmin() {
        return this.underwritingCaseMembers.every(ucMember => ucMember.ARC_ApprovalResolution__c === 'Approved');

    }

    get isUCMembersEmpty() {
        return this.underwritingCaseMembers.length === 0;
    }

    set isLoading(value) {
        this._isLoading = value;
    }

    get isLoading() {
        return this.case === undefined || this._isLoading;
    }

    get disableSaveButton() {
        return this.userId != this.case?.fields.OwnerId.value
        || this.prfName === 'WS Sales' 
        || this.prfName === 'Claim Auditor' 
        || this.prfName === 'Claim User' 
        || this.prfName === 'Claim Administrator'
    }

    get isMissingData() {
        return this.underwritingCaseMembers.find(ucMember => (ucMember.ARC_ApprovalResolution__c !== 'Pending' && (ucMember.ARC_Score__c === false || ucMember.ARC_Score__c === ''))) !== undefined;
    }

    get disableInputs() {
        return this.case?.fields.IsClosed.value 
        || this.userId != this.case?.fields.OwnerId.value
        // || this.prfName === 'WS Sales' 
        // || this.prfName === 'Claim Auditor' 
        // || this.prfName === 'Claim User' 
        // || this.prfName === 'Claim Administrator'
        || (this.hasApprovalEditFields == 'undefined' && (this.hasApprovalCloseVoid == undefined || hasApprovalCloseAllButtons == undefined))
        || ((this.hasApprovalEditFields == undefined && this.hasApprovalCloseVoid == undefined && this.hasApprovalCloseAllButtons == undefined) && this.adminProfile == false)

    }

    
    handleSave() {
        // console.log('this.underwritingCaseMembers', this.underwritingCaseMembers);
        if (!this.isMissingData) {
            this.isLoading = true;
            saveUCMembers({ ucMembersMapList: this.underwritingCaseMembers, userId: this.userId, caseId: this.recordId })
                .then(() => {
                    this.showToast('Success', 'Records updated successfully!', 'Success', 'dismissable');
                    this.disableButtons = false;
                })
                .catch(error => {
                    console.error(error);
                    this.showToast('Error', 'An error occurred while updating the record', 'Error', 'dismissable');
                }).finally(() => {
                    this.isLoading = false;
                    this.isSaved = true;
                    this.isChanged = false;
                    this.publishUCMemberUpdateEvent();
                });
        } else {
            this.showToast('Error', 'The Score can be empty only in Pending statuses', 'Error', 'dismissable')
        }

    }

    formatUCMembers(ucMembers) {
        return ucMembers.map(ucMember => {
            let birthdate = ucMember.ARC_Member__r.vlocity_ins__Birthdate__c;
            let arrayBirthdate = birthdate.split('-');
            let formattedBirthdate = birthdate ? arrayBirthdate[1] + '/' + arrayBirthdate[2] + '/' + arrayBirthdate[0] : '';

            let formattedMember = {
                ...ucMember,
                ARC_Member__r: {
                    ...ucMember.ARC_Member__r,
                    vlocity_ins__Birthdate__c: formattedBirthdate,
                    vlocity_ins__SocialSecurityNumber__c: ucMember.ARC_Member__r.vlocity_ins__SocialSecurityNumber__c?.replace(/^(\d\d\d)(\d{2})(\d{0,4}).*/, "$1-$2-$3")
                }
            };
            return formattedMember;
        });
    }
    gotoMember(event) {
        if (event.currentTarget.dataset.memberid) {
            this.navigateToRecord(event.currentTarget.dataset.memberid, 'vlocity_ins__Member__c');
        }
    }

    gotoUser(event) {
        if (event.currentTarget.dataset.userid) {
            this.navigateToRecord(event.currentTarget.dataset.userid, 'User');
        }
    }

    navigateToRecord(recordId, objectApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: 'view'
            },
        });
    }


    get disableSaveButtonModal() {
        return this.cancelReasonSelectedOptions == null;
    }


    handleCloseCase(evt) {
        this.selectedCloseOption = evt.currentTarget.dataset.id;

        if (this.selectedCloseOption === 'Closed Voided' && this.showModal == false) {
            this.showModal = true;
            this.cancelReasonOptions = this.picklistValues
        }
        else if (this.selectedCloseOption === 'Closed Rejected' && this.showModal == false) {
            this.showModal = true;
            this.cancelReasonOptions = this.picklistValues.filter(element => element.label == 'UHSM Denial' || element.label == 'UHSM Partial Denial');
        }
        else {
            this.showModal = false;
            this.isLoading = true;
            closeCase({ status: this.selectedCloseOption, caseId: this.recordId, cancelReason: this.cancelReasonSelectedOptions })
                .then((response) => {
                    if(!this.isUCMembersEmpty) this.handleSave();
                    this.showToast('Success', 'Case Closed successfully!', 'Success', 'dismissable');
                })
                .catch(error => {
                    console.log("error: ", error);
                    let errorString = error.body.fieldErrors.Status?.map(e => e.message).join(', ');
                    this.showToast('Error', 'An error occurred while updating the record: ' + errorString, 'Error', 'dismissable');
                })
                .finally(() => {
                    this.isLoading = false;
                    this.dispatchEvent(new RefreshEvent());
                })
        }


    }

    handleInputChange(event) {
        // this.dispatchEvent(new RefreshEvent());
        this.isSaved = false;
        this.isChanged = true;

        let UCMemberId = event.target.dataset.id;
        let fieldName = event.target.dataset.fieldname;
        // console.log("fieldName is ",fieldName);
        let value = event.target.value;
        // console.log("value is ",value);

        this.underwritingCaseMembers = this.underwritingCaseMembers.map(ucMember => {
            if (ucMember.Id === UCMemberId) {
                return { ...ucMember, [fieldName]: value };
            }
            return ucMember;
        });
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    handleCancelReasonChange(event) {
        this.cancelReasonSelectedOptions = event.detail.value;
    }

    closeModal() {
        this.showModal = false;
    }

    publishUCMemberUpdateEvent() {
        const payload = {
            caseId: this.recordId
        };
        publish(this.messageContext, UC_MEMBER_UPDATE_CHANNEL, payload);
    }
}