import {api} from 'lwc';
import insOsCensusRow from 'vlocity_ins/insOsCensusRow';
import template from './arc_CensusRow.html'
import {track } from 'lwc';
import { commonUtils, dataFormatter } from 'vlocity_ins/insUtility';

export default class arc_CensusRow extends insOsCensusRow {

    @api osData;
    @api requiredFieldsPrimary;
    @api requiredFieldsDependent;
    @api visibleFieldsPrimary;
    @api visibleFieldsDependent;
    @api tabAddressPosition = false;
    @api jsondata;

    connectedCallback(){
        super.connectedCallback();
        // this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
        // console.log("Data desde el census row?: "+this.osData);
      this.hideDiv = this.osData.QuoteProcess == 'IFP' ? true: false;
      this.clickedCensus = this.osData.clickedCensus == false ? true: false;
    //   console.log("asi esta el census! cuando llega al row: "+ JSON.stringify(this.census))
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

    replaceAddress(member, memberSaved){
        memberSaved.ARC_PhysicalAddressCity__c = member.ARC_PhysicalAddressCity__c;
        memberSaved.ARC_PhysicalAddressState__c = member.ARC_PhysicalAddressState__c;
        memberSaved.ARC_PhysicalAddressStreet__c = member.ARC_PhysicalAddressStreet__c;
        memberSaved.ARC_PhysicalAddressStreet2__c = member.ARC_PhysicalAddressStreet2__c;
        memberSaved.ARC_PhysicalAddressZipCode__c = member.ARC_PhysicalAddressZipCode__c;
        memberSaved.ARC_MailingAddressCity__c = member.ARC_MailingAddressCity__c;
        memberSaved.ARC_MailingAddressState__c = member.ARC_MailingAddressState__c;
        memberSaved.ARC_MailingAddressStreet__c = member.ARC_MailingAddressStreet__c;
        memberSaved.ARC_MailingAddressStreet2__c = member.ARC_MailingAddressStreet2__c;
        memberSaved.ARC_MailingAddressZipCode__c = member.ARC_MailingAddressZipCode__c;
        return memberSaved;
    }

    handleActive(event){
        const tab = event.target;
        this.tabAddressPosition = true;
    
    }
 
    render () {
        return template;
    }

}