import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import SALES_FORM from '@salesforce/schema/Opportunity.ARC_SalesFormCompleted__c';
import CENSUS_CSV from '@salesforce/schema/Opportunity.ARC_CensusCsvUploaded__c';
import GROUP_CLASSES from '@salesforce/schema/Opportunity.ARC_GroupClassesContributionsDefined__c';

const FIELDS = [SALES_FORM, CENSUS_CSV, GROUP_CLASSES];

export default class ARC_SG_OpportunityProgress extends LightningElement {
    @api recordId;
    
    opportunityData;
    error;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredOpportunity({ error, data }) {
        if (data) {
            this.opportunityData = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.opportunityData = undefined;
        }
    }

    get steps() {
        if (!this.opportunityData) return [];

        const rawSteps = [
            {
                label: 'Business Application Form',
                isCompleted: getFieldValue(this.opportunityData, SALES_FORM)
            },
            {
                label: 'Census CSV Uploaded',
                isCompleted: getFieldValue(this.opportunityData, CENSUS_CSV)
            },
            {
                label: 'Group Classes & Contributions Defined',
                isCompleted: getFieldValue(this.opportunityData, GROUP_CLASSES)
            }
        ];

        return rawSteps.map((step, index) => {
            const isLast = index === rawSteps.length - 1;
            return {
                id: index,
                label: step.label,
                statusLabel: step.isCompleted ? 'Completed' : 'Pending',
                wrapperClass: `step-wrapper ${isLast ? 'last-step' : ''}`,
                iconName: step.isCompleted ? 'utility:check' : '', 
                bubbleClass: step.isCompleted ? 'bubble completed' : 'bubble pending',
                textClass: step.isCompleted ? 'step-text completed-text' : 'step-text pending-text',
                badgeClass: step.isCompleted ? 'slds-badge slds-theme_success' : 'slds-badge slds-badge_lightest'
            };
        });
    }
}