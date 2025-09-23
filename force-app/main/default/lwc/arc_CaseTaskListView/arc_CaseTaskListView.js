import { LightningElement, api, wire, track } from 'lwc';
import getTasks from '@salesforce/apex/ARC_LWCDataHandlerTasksListView.getTasks';
import { getRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from 'lightning/navigation';
import TASK_ID_FIELD from '@salesforce/schema/Task.Id';
import CASE_STATUS from '@salesforce/schema/Case.Status';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { subscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    { label: 'Task', fieldName: "Subject", type: 'navigateToRecord', typeAttributes: { recordId: { fieldName: TASK_ID_FIELD.fieldApiName } } },
    { label: "Description", fieldName: "Description", wrapText: true, initialWidth: 350 },
    { label: "Status", fieldName: "Status", sortable: true, initialWidth: 85 },
    { label: "Assigned To", fieldName: "ownerName", sortable: true, initialWidth: 130 },
    {
        label: "Due Date", fieldName: "ActivityDate", type: "date", sortable: true, initialWidth: 119, typeAttributes: {
            timeZone: 'UTC',
            month: 'short',
            day: 'numeric',
            year: 'numeric',
        }
    },
    {
        label: "Completed Date", fieldName: "CompletedDateTime", type: "date", sortable: true, initialWidth: 153, typeAttributes: {
            timeZone: 'UTC',
            month: 'short',
            day: 'numeric',
            year: 'numeric',
        }
    }
];

export default class Arc_CaseTaskListView extends NavigationMixin(LightningElement) {
    @api recordId;
    @track error;
    @track data;
    @track columns = COLUMNS;
    @track sortBy = 'CompletedDateTime';
    @track sortDirection = 'desc';
    isUnderwritingAndClosed;
    @track _wiredTasks;

    @wire(getTasks, { CaseId: '$recordId' })
    wiredTasks(wireResult) {
        this._wiredTasks = wireResult;
        const { error, data } = wireResult;
        if (data) {
            this.data = data.map(task => ({
                ...task,
                ownerName: task.Owner.Name,
                Subject: task.Subject || 'View'
            }));

            this.sortTaskData(this.sortBy, this.sortDirection)
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getRecord, {
        recordId: "$recordId", fields: [CASE_STATUS]
    }) getCaseRecord({ data, error }) {
        if (data) {
            const { fields: { Status: { value: CaseStatus } }, recordTypeInfo: { name: RecordTypeName } } = data
            this.isUnderwritingAndClosed = RecordTypeName == 'Underwriting' && CaseStatus.toLowerCase().includes("closed") ? false : true;
        }
        if (error) {
            console.error(error);
        }
    }

    connectedCallback() {
        this.handleSubscribe();
    }

    //SUBSCRIPTION & HANDLING TO TASK CREATION EVENT
    handleSubscribe() {
        const messageCallback = response => {
            if (response.data.payload.ARC_Case_ID__c == this.recordId) {
                return refreshApex(this._wiredTasks);
            }
        };

        subscribe('/event/ARC_TaskCreationEvent__e', -1, messageCallback)
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

    navigateToNewTask() {
        const defaultValues = encodeDefaultFieldValues({
            WhatId: this.recordId
        });
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Task',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues,
                useRecordTypeCheck: 1
            }
        });
    }

    handleSortTaskData(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = this.sortDirection == "asc" ? "desc" : "asc";
        this.sortTaskData(event.detail.fieldName, this.sortDirection);
    }

    sortTaskData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));

        let isReverse = direction == 'asc' ? 1 : -1;
        parseData.sort((a, b) => {
            a = a[fieldname] ? a[fieldname] : '';
            b = b[fieldname] ? b[fieldname] : '';

            let index;
            
            if(!a && b){
                index = -1
            } else if (a && !b){
                index = 1
            } else if(!a && !b){
                index = 0
            } else if (a > b){
                index = -1
            } else if (a < b){
                index = 1
            }

            return isReverse * index;
        });
        this.data = parseData;
    }

}