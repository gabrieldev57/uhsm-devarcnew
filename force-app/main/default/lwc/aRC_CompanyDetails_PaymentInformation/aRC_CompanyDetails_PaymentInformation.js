import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getPaymentMethod from '@salesforce/apex/ARC_CompanyDetailsController.getPaymentMethod';
import aRC_editPaymentMethodModal from 'c/aRC_editPaymentMethodModal';

export default class ARC_CompanyDetails_PaymentInformation extends NavigationMixin(LightningElement) {
    @api recordId;
    @api canEdit;

    order;
    CardExpiration;
    BankAccountType;
    FullAddress;
    AccountHolder;
    PaymentFrequency;

    wiredOrderResult;

    hasNoPaymentInfo = false;
    errorMessage;


    //MODAL

    async editModeButton() {
        const result = await aRC_editPaymentMethodModal.open({
            size: 'medium',
            recordId: this.recordId
        });

        if (result?.saved) {
            await refreshApex(this.wiredOrderResult);
        }
    }

    

    //DATA
    @wire(getPaymentMethod)
    wiredOrder(result) {
        this.wiredOrderResult = result;

        const { data, error } = result;

        if (data) {
            if (!data.order) {
            this.hasNoPaymentInfo = true;
            this.order = null;
            this.errorMessage = 'Payment information cannot be loaded. The contract must be Awaiting Activation or Activated and have a related Chargent Order.';
            return;
        }
            this.hasNoPaymentInfo = false;
            this.errorMessage = null;


            this.order = data.order;
            this.CardExpiration = data.CardExpiration;
            this.BankAccountType = data.BankAccountType;
            this.FullAddress = data.FullAddress;
            this.AccountHolder = data.AccountHolder;
            this.PaymentFrequency = data.PaymentFrequency;
        }else if (error) {
            console.error('Error loading payment method', error);
            this.hasNoPaymentInfo = true;
            this.errorMessage = 'Payment information cannot be loaded. The contract must be Awaiting Activation or Activated and have a related Chargent Order.';
        }
    }

    

    // GETTERS (DISPLAY)
    
    get isCreditCard() {
        return this.order?.ChargentOrders__Payment_Method__c === 'Credit Card';
    }

    get maskedCardNumber() {
        if (!this.order?.ChargentOrders__Card_Last_4__c) {
            return '';
        }
        return `•••• •••• •••• ${this.order.ChargentOrders__Card_Last_4__c}`;
    }

    get maskedAccountNumber() {
        if (!this.order?.ChargentOrders__Bank_Account_Last_4__c) {
            return '';
        }
        return `•••• •••• •••• ${this.order.ChargentOrders__Bank_Account_Last_4__c}`;
    }

    get showPaymentError() {
        return this.hasNoPaymentInfo;
    }

    handleViewInvoices() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Invoices__c'
            }
        });
    }

}