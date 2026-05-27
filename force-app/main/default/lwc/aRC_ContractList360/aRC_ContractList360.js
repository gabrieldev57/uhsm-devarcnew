import { track, LightningElement, wire, api } from 'lwc';
import getContracts360 from '@salesforce/apex/ARC_ContractSearchBar.getContracts360';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
const DELAY = 150;

export default class ARC_ContractList360 extends NavigationMixin(LightningElement) {
    keyString = '';
    @api recordId;
    contractIds = '';
    userId = '';
    @track contractList = [];
    @track wiredContracts;
    @track isLoading = false;

    @wire(getContracts360, { keyString: '$keyString', recordId: '$recordId' })
    retrieveContracts(result) {
        this.wiredContracts = result;
        const { error, data } = result;
        if (data) {
          
            this.contractList = JSON.parse(JSON.stringify(data)).map(c => {
                c.isVoided = (c.status === 'Voided');
                c._expanded = false;             
                return c;
            });
            this.isLoading = false;
        }
        else if (error) {
            console.log('ARC_ContractList360 error', error);
        }
    }

    toggleContractDetails(event) {
        const contractId = event.currentTarget.dataset.id;
        const idx = this.contractList.findIndex(c => c.id === contractId);
        if (idx === -1) return;
        this.contractList[idx]._expanded = !this.contractList[idx]._expanded;
        this.contractList = [...this.contractList]; 
    }


    handleKeyChange(event) {
        const searchString = event.target.value;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            this.keyString = searchString;
        }, DELAY);
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

    handleRefresh(e) {
        this.isLoading = true;
        refreshApex(this.wiredContracts)
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error refreshing contract list:', error);
                this.isLoading = false;
            });

    }

}