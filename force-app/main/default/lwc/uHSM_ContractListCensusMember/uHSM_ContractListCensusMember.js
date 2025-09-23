import { track, LightningElement, wire, api } from 'lwc';
import getContract from '@salesforce/apex/ARC_ContractSearchBar.getContractbyCensusMember';
import { NavigationMixin } from 'lightning/navigation';
const DELAY = 300;

export default class UHSM_ContractListCensusMember extends NavigationMixin(LightningElement) {
    contractNumber='';
    @api recordId;
    
    @track contractList =[];
    @wire(getContract,{contractNumber:'$contractNumber', recordId: '$recordId'}) 
    retrieveContracts({ error, data }) { 
       
        if(data){
            this.contractList = data;
             console.log("recordId");
            console.log(this.recordId);
        }
        else if(error){
             console.log("recordId");
            console.log(this.recordId);
        }
    }

    handleKeyChange(event){
        const searchString= event.target.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(()=>{
            this.contractNumber =searchString;
        },DELAY);
    }

    newContract(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                recordId: event.currentTarget.dataset.id,
                objectApiName: 'Contract',
                actionName: 'new'
            },
        });
    }

    viewRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.id,
                objectApiName: 'Contract',
                actionName: 'view'
            },
        });
    }

    editRecord(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.id,
                objectApiName: 'Contract',
                actionName: 'edit'
            },
        });
    }

    viewOwner(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.ownerid,
                objectApiName: 'User',
                actionName: 'view'
            },
        });
    }
}