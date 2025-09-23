import { LightningElement ,wire,api,track} from 'lwc';
import historyHandler from '@salesforce/apex/HistoryHandler.getAllHistoryRecords';

export default class HistoryHandlerAllDataLWC extends LightningElement {

    @track showSpinner = true;
    @api recordId;
    // JS Properties 
    pageSizeOptions = [10,20,30,40,50]; //Page size options
    records=[]; //All records available in the data table
    columns = []; //columns information available in the data table
    totalRecords = 0; //Total no.of records
    pageSize; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number    
    recordsToDisplay = []; //Records to be displayed on the page
    
    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }
    // connectedCallback method called when the element is inserted into a document
    connectedCallback() {
        // set datatable columns info
        this.columns = [
            {
                label: 'Parent Name',
                fieldName: 'ParentName',
                type: 'url', 
                typeAttributes: {label: { fieldName: 'ParentObjName' }, target: '_blank'}
            },
            {
                label: 'Field',
                fieldName: 'Field'
            },
            {
                label: 'Old Value',
                fieldName: 'OldValue'
            },
            {
                label: 'New Value',
                fieldName: 'NewValue'
            },
            {
                label: 'Date',
                fieldName: 'CreatedDate',
                type: 'date', 
                typeAttributes: {  
                    day: 'numeric',  
                    month: 'short',  
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: true
                    }
            },
            {
                label: 'User',
                fieldName: 'CreatedByName'
            },
        ];
        // fetch contact records from apex method 
        historyHandler({recordIds: this.recordId})
            .then((result) => {
                var data = JSON.parse(JSON.stringify(result));
                data.forEach(item => {
                   if(item.record.Field!='contractActivation' && item.record.Field!='contractApproval'){
                    var ParentName;
                    var ParentObjName;
                    var ParentIds =item.record.ParentId;
                    if(item.record.AccountId) ParentName=  item.record.AccountId;
                    if(item.record.OrderId) ParentName= item.record.OrderId;
                    if(item.record.ContractId) ParentName= item.record.ContractId;
                    if(item.record.ParentId) ParentName= item.record.ParentId;
                    if(item.record.AccountId) ParentObjName=  'Account';
                    if(item.record.ContractId) ParentObjName= 'Contract';
                    if (ParentIds && String(ParentIds).startsWith('a3q')) ParentObjName = 'Group Census Member';
                    if (ParentIds && String(ParentIds).startsWith('aBa')) ParentObjName = 'Chargent Order';
                   const newItem = {
                        NewValue: item.record.NewValue,
                        CreatedByName: item.record.CreatedBy.Name,
                        OldValue:item.record.OldValue,
                        ParentName:item.record.ParentName,
                        CreatedDate: item.record.CreatedDate,
                        Field:item.label,
                        ParentName: "/" +ParentName,
                        ParentObjName:ParentObjName
                      };
                    this.records.push(newItem);
                     
                }
                });
                this.records.sort((a, b) => new Date(b.CreatedDate) - new Date(a.CreatedDate));
                var count = this.records.length;
                this.totalRecords = count; // update total records count                 
                this.pageSize = this.pageSizeOptions[0]; //set pageSize with default value as first option
                this.paginationHelper(); // call helper menthod to update pagination logic 
                this.showSpinner = false;
            })
            .catch((error) => {
                this.showSpinner = false;
                console.log('error while fetch contacts--> ' + error);a
            });
           
    }
    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }
    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }
    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }

    
    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        // set page number
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.records[i]);
        }

      
    }
}