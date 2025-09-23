import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import {loadStyle} from 'lightning/platformResourceLoader';
import ARC_CustomStyles from '@salesforce/resourceUrl/ARC_CustomStyles';
import getPolicyParticipants from '@salesforce/apex/ARC_ClaimMemberLayoutController.getPolicyParticipants';
import selectParticipant from '@salesforce/apex/ARC_ClaimMemberLayoutController.selectPolParticipant';
import resetPatient from '@salesforce/apex/ARC_ClaimMemberLayoutController.resetPatient';
import policyAssignment from '@salesforce/apex/ARC_ClaimMemberLayoutController.policyAssignment';
import POLICY from '@salesforce/schema/Claim.PolicyNumberId';
import INPUT_MEMBER from '@salesforce/schema/Claim.ARC_Name_Birthdate_Street__c';
import DOS_FROM from '@salesforce/schema/Claim.ARC_DOSFrom__c';
import DOS_TO from '@salesforce/schema/Claim.ARC_DOSTo__c';


const columnsParticipant = [
    { label: 'Name', fieldName: 'name', hideDefaultActions: true, sorteable:true ,cellAttributes:{
        class:{fieldName:'okWithDos'} }},
    { label: 'Birthdate', fieldName: 'birthdate', hideDefaultActions: true,},
    { label: 'Role', fieldName: 'role', hideDefaultActions: true,},
    { label: 'Street', fieldName: 'street', hideDefaultActions: true,},
    { label: 'State', fieldName: 'state', hideDefaultActions: true,},
    { label: 'Zip Code', fieldName: 'zipcode', hideDefaultActions: true,},
    { label: 'City', fieldName: 'city', hideDefaultActions: true, },
    { label: 'Effective Date', fieldName: 'effectiveDate', hideDefaultActions: true, },
    { label: 'Expiration Date', fieldName: 'expirationDate', hideDefaultActions: true,}

];

const columnsPolicy = [
    { label: 'Name', fieldName: 'name', hideDefaultActions: true,},
    { label: 'Effective Date', fieldName: 'effDate', hideDefaultActions: true,},
    { label: 'Expiration Date', fieldName: 'expDate', hideDefaultActions: true,},
    { label: 'Active', fieldName: 'isActive', hideDefaultActions: true,},
    { label: 'Program Name', fieldName: 'prodName', hideDefaultActions: true,},
    { label: 'Contract Reason', fieldName: 'contReason', hideDefaultActions: true,}
];

export default class ARC_ClaimMemberLayout extends LightningElement {
    columnsParticipant = columnsParticipant;
    columnsPolicy = columnsPolicy;
    @api recordId;
    policyPopulated;
    inputMember;
    participantSelected;
    policySelected;
    dataParticipant = [];
    dataPolicy = [];
    isLoading = false;
    modalOpen = false;
    isReseting = false;
    searched = false;
    memberLayout = true;
    policyLayout = false;
    participantsNotFound = false;
    noPolicy = false;
    memberName;
    memberBirthdate;
    memberStreet;
    dosFrom;
    dosTo;
    disDuplicate = false;


    @wire(getRecord, { recordId: '$recordId', fields: [POLICY, INPUT_MEMBER, DOS_FROM, DOS_TO] })
    fetchLaborCategory({ data, error }) {
        if (data) {
            getFieldValue(data, POLICY) ? this.policyPopulated = true : this.policyPopulated = false;
            this.inputMember = getFieldValue(data, INPUT_MEMBER);
            if(this.inputMember?.length > 0) {
                this.memberName = this.inputMember.split(';')[0];
                this.memberBirthdate = this.inputMember.split(';')[1].substring(0, 10);
                this.memberStreet = this.inputMember.split(';')[2];
            }
            this.dosFrom = getFieldValue(data, DOS_FROM); 
            this.dosTo = getFieldValue(data, DOS_TO);

        }else{
            console.error(error);
        }
    }

    // CONFIRM BUTTON
    get isData(){
        if (this.participantSelected) {
            return true;
        }else{
            return false;
        }
    }

    resetComponent(){
        this.isLoading = false;
        this.modalOpen = false;
        this.searched = false;
        this.memberLayout = true;
        this.policyLayout = false;
        this.noPolicy = false;
        this.participantSelected = null;
        this.dataParticipant = [];
        this.dataPolicy = [];
        this.isReseting = false;
        this.policySelected = null;
        this.disDuplicate = false;
    }

    displayMessage(title, variant){
        const evt = new ShowToastEvent({
            title: title,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    handleSuccess() {
        const even = new ShowToastEvent({
            title: 'Success!',
            message: 'Record Saved  !',
            variant: 'success'
        });
        this.dispatchEvent(even);
    }

    handleManageModal(e){
        const action = e.currentTarget.dataset.manage;
        action == 'open' ? this.modalOpen = true : this.resetComponent();  
    }

    renderedCallback(){ 
        if(this.isCssLoaded){
            return
        } 
 
        this.isCssLoaded = true
 
        loadStyle(this, ARC_CustomStyles+'/ARC_FindPatientStyle.css').then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{ 
            console.log(error)
        });
    }

    handleSearch(){
        if (this.memberName && this.memberBirthdate && this.memberStreet && this.dosFrom && this.dosTo) {
            this.isLoading = true;
            getPolicyParticipants({name: this.memberName, birthdate: this.memberBirthdate, street: this.memberStreet, dosFrom: this.dosFrom, dosTo: this.dosTo})
                .then(result => {
                    if (result.message != 'NoPP') {
                        this.searched = true;
                        let polparts = [];
                        const participantSet = new Set();
                        result.polparts1.forEach(participant => {
                            let obj = {};
                            obj['participant'] = participant;
                            obj['restrictedQuery'] = true;
                            participantSet.add(participant.Id);
                            polparts.push(obj);
                        });
                        result.polparts2.forEach(participant => {
                            if(!participantSet.has(participant.Id)){
                                let obj = {};
                                obj['participant'] = participant;
                                obj['restrictedQuery'] = false;
                                polparts.push(obj);
                                participantSet.add(participant.Id);
                            }
                        });

                        let allData = [];
                        polparts.forEach(part => {
                            let obj = {};
                            obj['id'] = part.participant.Id;
                            obj['name'] = part.participant.PrimaryParticipantContact.Name;
                            obj['birthdate'] = part.participant.PrimaryParticipantContact.Birthdate;
                            obj['role'] = part.participant.Role;
                            obj['street'] = part.participant.PrimaryParticipantContact.Account.BillingStreet;
                            obj['state'] = part.participant.PrimaryParticipantContact.Account.BillingState;
                            obj['zipcode'] = part.participant.PrimaryParticipantContact.Account.BillingPostalCode;
                            obj['city'] = part.participant.PrimaryParticipantContact.Account.BillingCity;
                            obj['effectiveDate'] = part.participant.InsurancePolicy.ARC_EffectiveDate__c;
                            obj['expirationDate'] = part.participant.InsurancePolicy.ARC_ExpirationDate__c;
                            obj['restrictedQuery'] = part.restrictedQuery;
                            obj['okWithDos'] = part.restrictedQuery ? "" : "red-background";
                            console.log()

                            allData.push(obj);
                            this.participantsNotFound=false;
                        });
                        this.dataParticipant = allData;
                        if(result.message == 'InvalidPP') this.displayMessage('These members are not within the date of service', 'warning');
                        else if (result.message == 'SomeInvalidPP') this.displayMessage('There are some members not within the date of service', 'warning');
                    }else{
                        this.searched = false;
                        this.dataParticipant = [];
                        this.participantsNotFound = true;
                    }
                })
                .catch(error => {
                    console.error(error);
                })
                .finally(() => {
                    this.isLoading = false;
                    this.participantSelected = null;
                })
        }else{
            this.displayMessage('Missing data', 'error');
        }
    }

    
    handleSelectParticipant(e){
        this.participantSelected = e.detail.selectedRows[0].id;
    }

    handleSelectPolicy(e){
        this.policySelected = e.detail.selectedRows[0].id;
    }

    handleConfirmPolPart(){
        if (this.participantSelected) {
            this.isLoading = true;
            selectParticipant({claimId: this.recordId, participantId: this.participantSelected})
                .then(response => {
                    this.isLoading = false;
                    if(response != 'Updated'){
                        memberPolicyMessage = response;
                        this.policyLayout = true;
                        this.memberLayout = false;
                    }else{
                        this.resetComponent();
                        this.displayMessage('The SMB has been updated!', 'success');
                    }
                })
                .catch(error => {
                    console.error(error);
                })
        }
    }

    handleManageAlert(e){
        const action = e.currentTarget.dataset.manage;
        action == 'open' ? this.isReseting = true : this.isReseting = false;
    }

    handleReset(){
        this.isReseting = false;
        
        resetPatient({claimId: this.recordId})
            .then(response => {
                switch (response) {
                    case 'updated':
                        this.displayMessage('SMB Patient has been reseted!', 'success');
                        this.resetComponent();
                        break;
                    case 'error':
                        this.displayMessage('Error', 'error');
                        break;
                }
            })
            .error(error => {
                console.error(error);
            })
    }

    handleChangeMember(e){
        const inp = e.currentTarget.dataset.id;
        switch (inp) {
            case 'memberName':
                this.memberName = e.target.value;
                break;
            case 'memberBirthdate':
                this.memberBirthdate = e.target.value;
                break;
            case 'memberStreet':
                this.memberStreet = e.target.value;
                break;
            case 'dosFrom':
                this.dosFrom = e.target.value;
                break;
            case 'dosTo':
                this.dosTo = e.target.value;
                break;
        }
    }

    handleConfirmPolicy(e){
        const selected = e.currentTarget.dataset.id;
        let inputMember = this.participantSelected;
        let inputPolicy = selected == 'policy' ? this.policySelected : null;

        this.isLoading = true;
        policyAssignment({member: inputMember, policy: inputPolicy, claimId: this.recordId})
            .then(response => {
                if(response == 'updated'){
                    this.displayMessage('The SMB has been updated!', 'success');
                }else if(response == 'error'){
                    this.displayMessage('Error', 'error');
                }
            })
            .catch(() => {
                this.displayMessage('Error', 'error');
            })
            .finally(() => {
                this.resetComponent();
            })
    }
    

    get disPayBtn(){
        let disable = false;
        if(this.memberName != null && this.memberName != '' && this.memberBirthdate != null && this.memberStreet != null && this.memberStreet != '' && this.dosFrom != null && this.dosTo != null) disable = false;
        else disable = true;
        return disable;
    }
}