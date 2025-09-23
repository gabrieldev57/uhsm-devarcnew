import { api } from 'lwc';
import insOsCensusRow from 'vlocity_ins/insOsCensusRow';
import template from './arc_DemoCensusRow.html'
import { track } from 'lwc';
import { commonUtils, dataFormatter } from 'vlocity_ins/insUtility';

export default class arc_DemoCensusRow extends insOsCensusRow {

    @api osData;
    @api requiredFieldsPrimary;
    @api requiredFieldsDependent;
    @api visibleFieldsPrimary;
    @api visibleFieldsDependent;
    @api tabAddressPosition = false;
    @api clickedCensus = false;
    @track auxAddDependent = false;
    @api hasDependents;

    @api 
    set memberAmmount(value){
        console.log('memberAmmountsss ',value);
        this.hasDependents = value >1;
    }

    get memberAmmount(){
        return this.memberAmmount;
    }

    get memberNameIsUndefined() {
        return this.memberName == 'undefined undefined';
    }

    connectedCallback() {
        super.connectedCallback();
        commonUtils.triggerCustomEvent.call(this, 'selected', { detail: this.member });

        this.hideAddDependent = this.osData.FieldsetType == 'IFPEnroll' || this.osData.FieldsetType == 'IFPProgramChangePlan' ? true : false;

        this.hideDiv = this.osData.QuoteProcess == 'IFP' ? true : false;
        this.clickedCensus = this.clickedCensus == false ? true : false;

        if (this.osData.userInputs2 != null) {
            this.hideDependentTab = this.osData.userInputs2['RF_Census.CRF_Dependants'] == 0 ? true : false;
        }

        // if(this.osData.FieldsetType == 'IFPProgramChangeMultiple' && this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member') && this.osData.STEP_RemoveMember.FRML_PrimaryWasSelected == true){
        //      this.hidePrimaryTab = true;
        // }

        if (this.osData.FieldsetType == 'IFPProgramChangeAddMember') {
            this.hidePrimaryTab = true;
        }

        if (this.osData.FieldsetType == 'IFPProgramChangeAddMember' || this.osData.FieldsetType == 'IFPProgramChangeMultiple') {
            this.addNewFirstDependent();
        }


    }

    handleUpdate(ev) {

        commonUtils.triggerCustomEvent.call(this, 'update', ev);
    }

    handleUpdateAddress(ev) {
        let supportMember = Object.assign({}, ev.detail);
        let modifiedMember = Object.assign({}, this.member);
        modifiedMember = this.replaceAddress(supportMember, modifiedMember);
        commonUtils.triggerCustomEvent.call(this, 'update', { detail: modifiedMember });
    }

    replaceAddress(member, memberSaved) {
        memberSaved.ARC_PhysicalAddressCity__c = member.ARC_PhysicalAddressCity__c;
        memberSaved.ARC_PhysicalAddressState__c = member.ARC_PhysicalAddressState__c;
        memberSaved.ARC_PhysicalAddressStreet__c = member.ARC_PhysicalAddressStreet__c;
        memberSaved.ARC_PhysicalAddressStreet2__c = member.ARC_PhysicalAddressStreet2__c;
        memberSaved.ARC_PhysicalAddressZipCode__c = member.ARC_PhysicalAddressZipCode__c;
        // memberSaved.ARC_MailingAddressCity__c = member.ARC_MailingAddressCity__c;
        // memberSaved.ARC_MailingAddressState__c = member.ARC_MailingAddressState__c;
        // memberSaved.ARC_MailingAddressStreet__c = member.ARC_MailingAddressStreet__c;
        // memberSaved.ARC_MailingAddressStreet2__c = member.ARC_MailingAddressStreet2__c;
        // memberSaved.ARC_MailingAddressZipCode__c = member.ARC_MailingAddressZipCode__c;
        return memberSaved;
    }

    handleActive(event) {
        const tab = event.target;
        this.tabAddressPosition = true;

    }

    render() {
        return template;
    }

    addNewFirstDependent() {
        if (this.osData && this.osData.clickedDependent == false && this.osData.FieldsetType != "IFPEnroll" && this.osData.FieldsetType != "IFPProgramChangePlan" && this.member.dependents.length < 1) {
            this.auxAddDependent = true;
            commonUtils.triggerCustomEvent.call(this, 'new', { detail: this.member });
        }

    }


}