import { LightningElement ,api,wire,track} from 'lwc';
import getPolicyHistory from '@salesforce/apex/ARC_PolicyHistoryController.getPolicyHistory';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import { refreshApex } from '@salesforce/apex';

const USER_FIELDS = ['User.Profile.Name'];

export default class ARC_PolicyHistory extends LightningElement {

    @api recordId; 
    @track historyRecords = []; 
    @track userProfile;
    allRecords = []; 
    error;

    pageSize = 5;
    pageNumber = 1;
    totalRecords = 0;
    totalPages = 0;
    showQLEModal = false;

    /* Datatable Columns*/
    columns = [
        { label: 'Effective Date', fieldName: 'ARC_EffectiveDate__c', type: 'text' },
        { label: 'Expiration Date', fieldName: 'ARC_PolicyExpirationDate__c', type: 'text' },
        { label: 'Reason', fieldName: 'ARC_Reason__c',hideDefaultActions: true ,type: 'text' , wrapText: true},
        { label: 'Status', fieldName: 'Status',hideDefaultActions: true ,type: 'text'}
    ];

    _wiredHistoryResult;

    @wire(getPolicyHistory, { personAccountId: '$recordId' })
    wiredHistory(result) {
        this._wiredHistoryResult = result;
        const { data, error } = result;
        if (data) {
            console.log('data from Policy History', data);
            this.allRecords = data.map(record => ({
                ...record,
                ARC_EffectiveDate__c: this.formatDate(record.ARC_EffectiveDate__c),
                ARC_PolicyExpirationDate__c: this.formatDate(record.ARC_PolicyExpirationDate__c)
            }));
            this.totalRecords = data.length;
            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            this.pageNumber = 1;
            this.updatePageData();
            this.error = undefined;
        } else if (error) {
            this.error = error;
            console.log('error from Policy History', error);
            this.allRecords = [];
        }
    }

    @api
    refresh() {
        if (this._wiredHistoryResult) {
            return refreshApex(this._wiredHistoryResult);
        }
    }

    @wire(getRecord, { recordId: USER_ID, fields: USER_FIELDS })
        wiredUser({ error, data }) {
            if (data) {
                this.userProfile = data.fields.Profile.value.fields.Name.value;
            } else if (error) {
                console.error('Error loading user profile:', error);
            }
    }

    get isEmployerAdmin() {
        return this.userProfile === 'Employer Admin';
    }


    handleAddEvent() {
        this.showQLEModal = true;
    }

    updatePageData() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.historyRecords = this.allRecords.slice(start, end);
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.updatePageData();
        }
    }

    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.updatePageData();
        }
    }

    handleQLEClose() {
        this.showQLEModal = false;
    }

    get disablePrevious() {
        return this.pageNumber === 1;
    }

    get disableNext() {
        return this.pageNumber === this.totalPages;
    }

    get qleFlowInputVariables() {
        return [
            {
                name: 'recordId', 
                type: 'String',
                value: this.recordId
            }
        ];
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const [year, month, day] = dateStr.split('-');
        if (!year || !month || !day) return dateStr;
        return `${month}-${day}-${year}`;
    }
}