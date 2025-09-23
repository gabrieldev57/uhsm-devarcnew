import { LightningElement, api } from "lwc";
import { FlowNavigationBackEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';


import STATUS from '@salesforce/schema/Case.Status';
import TYPE from '@salesforce/schema/Case.Case_Type__c';
import REASON from '@salesforce/schema/Case.ARC_Reason__c';
import REASON_OTHER from '@salesforce/schema/Case.ARC_CaseReasonOther__c';
import SUBJECT from '@salesforce/schema/Case.Subject';
import DESCRIPTION from '@salesforce/schema/Case.Description';
import ORIGIN from '@salesforce/schema/Case.Origin';
import CALLER from '@salesforce/schema/Case.ARC_Type__c';
import PRIORITY from '@salesforce/schema/Case.Priority';
import SMB from '@salesforce/schema/Case.ARC_SMB__c';
import PERSON_ACCOUNT from '@salesforce/schema/Case.ARC_PersonAccount__c';

export default class ARC_NewCaseFromSMB extends NavigationMixin(LightningElement) {
    @api recordTypeId;
    @api smbId;
    @api personAccountId;
    fields = [STATUS,TYPE,REASON,REASON_OTHER,SUBJECT,DESCRIPTION,ORIGIN,CALLER,PRIORITY,SMB,PERSON_ACCOUNT]

    handleSuccess(event) {
        const toastEvent = new ShowToastEvent({
            title: 'Success',
            message: 'Case record has been saved successfully.',
            variant: 'success'
        });
        this.dispatchEvent(toastEvent);

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });
    }


    handleCancel() {
        const nextNavigationEvent = new FlowNavigationFinishEvent();
        this.dispatchEvent(nextNavigationEvent);
    }

    handleBack() {
        const nextNavigationEvent = new (FlowNavigationBackEvent);
        this.dispatchEvent(nextNavigationEvent);
    }

}