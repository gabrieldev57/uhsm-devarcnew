import { LightningElement, api, wire } from 'lwc';
import retrieveEm from '@salesforce/apex/getCurrentEmailMessage.getCurrentEmailMessage';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
// import  deleteRecord  from '@salesforce/apex/getCurrentEmailMessage.deleteRecord';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class ARC_EmailMessageViewer extends NavigationMixin(LightningElement) {
    columns = [
        { label: 'Subject', fieldName: 'Subject' },
        { label: 'To Address', fieldName: 'ToAddress' },
        { label: 'From Address', fieldName: 'FromAddress' },
        { label: 'Send Date', fieldName: 'SendDate'},
        { label: 'Sent By', fieldName: 'CreatedBy.Name' },
        { label: 'Type', fieldName: 'Type__c'}
    ];

    @api recordId;
    data;
    recordCount;
    wiredRecords;
    recordsList = [];
    numberList = [];
    lastElement;
	dataList= [];	
    
		
    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference) {
            console.log(currentPageReference);
            this.recordId = currentPageReference.attributes.recordId || null;
        }
    }

    connectedCallback() {
        console.log('record?' + this.recordId)
    }

    @wire(retrieveEm, { recordId: "$recordId" })
    getRecordsData(provisionedData) {
        debugger;
        this.wiredRecords = provisionedData
        const { data, error } = provisionedData
        
        if (data) {
            console.log('data'+JSON.stringify(data));
             this.data = data.length > 9 ? data.slice(0, 9) : data
            if((data.length/10) >1){
                try {
                
                for(let i =0;i<=(data.length/10);i++){
                    let records = []
                    console.log(i)
                    
                    for(let i2=(i*10);i2<(i*10)+10;i2++){
                        console.log(i)
                        if(data[i2]){
                            records.push(data[i2])
                        }
                        
                    }
                    this.recordsList.push(records)
                    
                }
                for(let i = 0;i<this.recordsList.length;i++){
                    this.numberList.push(i+1);
                }
            } catch (error) {
                   console.log(error); 
            }
            }
            console.log(this.recordsList)
            this.recordCount = data.length
        }

    }

    accordionFunctionality(event) {
        event.currentTarget.classList.toggle("active");

        var panel = event.currentTarget.nextElementSibling;
        panel.classList.toggle("active")
        if (!panel.classList.contains("active")) {
            panel.style.maxHeight = 0;
        } else {
            panel.style.maxHeight = panel.scrollHeight + "px";
        }
    }

    changePage(event){
        try {
            
        
        console.log('PAGE'+event.target.dataset.id)
        this.data=this.recordsList[(parseInt(event.target.dataset.id) - 1)]
    } catch (error) {
            console.error(error)
    }

    if(this.lastElement){
        event.target.style='color: rgb(18 39 68);font-weight: 600;text-decoration: underline;'
        this.lastElement.style='color:rgba(53, 93, 150, 1);'
        this.lastElement= event.target;
    }
    if(!this.lastElement){
        this.lastElement = event.target
        event.target.style='color: rgb(18 39 68);font-weight: 600;text-decoration: underline;'
    }
    

    }

    navigateToRelatedList(event) {
        // Navigate to the CaseComments related list page
        // for a specific Case record.
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'vlocity_ins__GroupCensusMember__c',
                relationshipApiName: 'Email_Messages__r',
                actionName: 'view'
            }
        });
    }

    // deleteHandler(event) {
    //     console.log('h',event.currentTarget.dataset.id)
    //     deleteRecord(event.currentTarget.dataset.id)
    //         .then((t) => {
    //             if(t){

                
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Success',
    //                     message: 'Record deleted',
    //                     variant: 'success'
    //                 })
    //             );
    //         }else{
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error deleting record',
    //                     message: error.body.message,
    //                     variant: 'error'
    //                 })
    //             );
    //         }
    //             refreshApex(this.wiredRecords)

    //         })
    //         .catch(error => {
    //             console.log(error)
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error deleting record',
    //                     message: error.body.message,
    //                     variant: 'error'
    //                 })
    //             );
    //         });
    // }

    refresh(){
        refreshApex(this.wiredRecords)
    }


}