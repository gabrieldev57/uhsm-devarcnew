import {LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { NavigationMixin } from 'lightning/navigation';

export default class ARC_TransactionsList360 extends NavigationMixin(OmniscriptBaseMixin(LightningElement)) {
    @api recordId;
    transactionsData = [];
    totalTransactions = 0;
    pageSize = 20;
    totalPages;
    pageNumber = 1; // Page number by default
    recordsToDisplay = []; //Records to be displayed on the page

    connectedCallback() {
        console.log("ARC_TransactionsList360 - recordId is "+ this.recordId);
        this.getTransactions();
    }

    get hasTransactions() {
        return this.transactionsData && this.transactionsData.length > 0;
    }

    getSettlementStatusClass(status) {

        if(status == 'Settled' || status == 'N/A (Promotion)') {
            return 'status-settled'; 
        } else if(status == 'Pending'){
            return 'status-pending';
        } else {
            return 'status-failed';
        }
    }

    formatCurrencyAmount(amount) {
        const parsed = parseFloat(amount);
        if (isNaN(parsed)) return '$0.00';
        const isNegative = parsed < 0;
        return isNegative 
            ? `-$${Math.abs(parsed).toFixed(2)}`
            : `$${parsed.toFixed(2)}`;
    }



    getTransactions(){
        this.transactionsData = [];

        let IPInput={
            "PersonAccountId": this.recordId
        }
        console.log('IPInput ' + JSON.stringify(IPInput));
        const params = {
            input: IPInput,
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'PersonAccount_Transactions360', 
            options: '{}',
        };
        this.omniRemoteCall(params, true)
        .then(response => {
            if (response.result && response.result.IPResult) {
                const rawData = response.result.IPResult.transactions || response.result.IPResult || [];
                this.transactionsData = rawData.map(transaction => {
                        const formattedTransactionAmount = this.formatCurrencyAmount(transaction.TransactionAmount);

                        const cleanTLI = Array.isArray(transaction.TLI) ? 
                            transaction.TLI
                                .filter(tli => tli !== null && tli !== undefined)
                                .map(tli => {
                                    return {
                                        ...tli,
                                        formattedAmount: this.formatCurrencyAmount(tli.ARC_Amount__c)
                                    };
                                })
                            : [];
                    return {
                        ...transaction,
                        TLI: cleanTLI,
                        TransactionAmount: formattedTransactionAmount,
                        settlementStatusClass: this.getSettlementStatusClass(transaction.TransactionSettlementStatus)
                    };
                });
                
                console.log('Response2 -> ' + JSON.stringify(this.transactionsData))
                var count = this.transactionsData.length;
                this.totalTransactions = count; // update total records count
                console.log('Total transactions: ' +this.totalTransactions);
                this.paginationHelper(); // call helper menthod to update pagination logic 
            }
        })
 
        .catch(error => {
            console.error('Error:', error);
        });
    }

    navigateToRecord(event) {
        const transactionId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: transactionId,
                objectApiName: 'ChargentOrders__Transaction__c',
                actionName: 'view'
            }
        });
    }

    // Handle navigation buttons function
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
    get bDisablePrevious() {
        return this.pageNumber == 1;
    }
    get bDisableNext() {
        return this.pageNumber == this.totalPages;
    }




    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // Calculate total pages
        this.totalPages = Math.ceil(this.totalTransactions / this.pageSize);
        // Set page number
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        console.log('pageNumber:', this.pageNumber, 'pageSize:', this.pageSize);
        console.log('from:', (this.pageNumber - 1) * this.pageSize, 'to:', this.pageNumber * this.pageSize);
        // Set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalTransactions) {
                break;
            }
            this.recordsToDisplay.push(this.transactionsData[i]);
        }
    }


}