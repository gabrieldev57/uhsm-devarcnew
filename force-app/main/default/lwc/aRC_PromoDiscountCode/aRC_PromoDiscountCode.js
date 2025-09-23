import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_PromoDiscountCode extends OmniscriptBaseMixin(LightningElement) {
    @api contractId; // Id of the contract to get order information
    @api referral; // If this is an account that came from a referral, we want to hide discount info
    @api internal; // If this is a self enroll we hide the discount section and code input
    @track UI = {}; // Controls the display of the UI

   async connectedCallback() {
       let savedState = this.omniGetSaveState('LWC_PromoDiscountState');

       if (savedState) {
           this.UI = savedState.UI;
           this.codeValues = savedState.codeValues;
           this.MedicalPrice = savedState.MedicalPrice;
       } else {
           this.UI = {};
           this.codeValues = null;
           this.MedicalPrice = null;
       }
            
       // Referrals
       if (this.referral) {
            if (!this.internal){
                this.UI.showDiscountRadio = false;                
                this.UI.showCodeInput = false;
            } else {
                this.UI.showDiscountRadio = true;
                this.UI.showCodeInput = true;
            }
           this.UI.showCodeActive = true;
           this.UI.radioValue = 'YES';
           
           this.UI.textInputValue = 'EW34tgGE$34';

           this.omniUpdateDataJson({
               radioValue: 'YES',
               textInputValue: this.UI.textInputValue
           });

           await this.applyDiscountCode(this.UI.textInputValue);
           return;
       } else {
            this.UI.showDiscountRadio = true;            
       }
       

       let checkActivePromotionCodeExist = await this.omniRemoteCall({
           input: '{}',
           sClassName: 'ARC_PromotionCode',
           sMethodName: 'checkActivePromotionCodeExist',
           options: '{}'
       }, true);

       if (checkActivePromotionCodeExist.result.ListIsNotEmpty) {
           this.UI.showCodeActive = true;
       } else {
           this.UI.showCodeInactive = true;
       }
   }

   renderedCallback() {
       setTimeout(() => {
           const yesRadio = this.template.querySelector('input[type="radio"][value="YES"]');
           if (this.UI.radioValue === 'YES' && yesRadio) {
               yesRadio.checked = true;
           }

           const codeInput = this.template.querySelector('lightning-input.code');
           if (codeInput && this.UI.textInputValue) {
               codeInput.value = this.UI.textInputValue;
           }

           if (this.UI.errorMessage) {
               this.displayErrorMessage(this.UI.errorMessage);
           }
       }, 0);
   }

   async disconnectedCallback() {
       let stateToSave = {
           UI: this.UI,
           codeValues: this.codeValues,
           MedicalPrice: this.MedicalPrice
       };
       this.omniSaveState(stateToSave, 'LWC_PromoDiscountState', true);
   }

    get showRadio() {
       return !this.UI.hideDiscountRadio;
    }


    handleRadioInput(event) {
        console.log(event.target)
        console.log(event.currentTarget)
        console.log(event.target.value)
        this.UI.radioValue = event.target.value;

        if (this.UI.radioValue === "YES") {
            this.UI.showCodeInput = true;
        } else {
            this.clearValidationMessages();
            this.clearFieldValues();
            this.UI.showCodeInput = false;
        }
  }

   handleTextInputChange(event) {
       this.UI.textInputValue = event.target.value;
   }

   handleValidateButton() {
       this.applyDiscountCode(this.UI.textInputValue);
   }

   async applyDiscountCode(promoCode) {
       this.clearValidationMessages();

       let contractInfo = await this.omniRemoteCall({
           input: JSON.stringify({ ContractId: this.contractId }),
           sClassName: 'ARC_PromotionCode',
           sMethodName: 'getContractInformation',
           options: '{}'
       }, true);

       let discountInfo = await this.omniRemoteCall({
           input: JSON.stringify({ PromotionCode: promoCode }),
           sClassName: 'ARC_PromotionCode',
           sMethodName: 'getDiscountCodeInformation',
           options: '{}'
       }, true);
        // NO DISCOUNT CODE FOUND, CODE IS INVALID
       if (!discountInfo.result.code && promoCode) {
           this.displayErrorMessage(`${promoCode} is not a valid promotion code.`);
           return;
       }
        // NO TEXT INPUT, CODE FIELD IS EMPTY
       if (!discountInfo.result.code && !promoCode) {
           this.displayErrorMessage('A value is required to be input before validating the code');
           return;
       }

       this.codeValues = discountInfo.result.code;
       this.contractValues = contractInfo.result.contract;

       let appFeeAmount = this.contractValues.ARC_AppFeeOrder__r?.ChargentOrders__Charge_Amount__c;
       let changeFeeAmount;

       if (this.contractValues.ARC_ContractReason__c === 'Program Upgrade') {
           changeFeeAmount = this.omniJsonData.UpgradeFee;
       } else if (this.contractValues.ARC_ContractReason__c === 'Add Member') {
           changeFeeAmount = this.omniJsonData.AddMemberFee;
       }

       this.MedicalPrice = this.contractValues.vlocity_ins__ContractLineItems__r?.records[0]?.vlocity_ins__UnitPrice__c;

        //ENROLL || SPINOFF LOGIC 
        if (this.contractValues.ARC_ContractReason__c?.includes('New Application')) {
            //RECURRING
           if (this.codeValues.ARC_DiscountType__c === 'First Month Payment') {
               this.clearFieldValues();
               this.UI.subtotal_amount = this.MedicalPrice;
               this.UI.orderName = 'First Month Order';
           } else if (this.codeValues.ARC_DiscountType__c === 'Next X Number of Recurring Payments') {
               this.clearFieldValues();
               this.UI.subtotal_amount = this.MedicalPrice;
               this.UI.orderName = 'Recurring Monthly Order';
           //APP FEE    
           } else if (this.codeValues.ARC_DiscountType__c === 'App Fee') {
               this.clearFieldValues();
               this.UI.subtotal_amount = appFeeAmount;
               this.UI.orderName = 'App Fee';
           } else {
               this.displayErrorMessage(`Invalid use of promotional code ${promoCode} for Shop & Enrollment`);
               return;
           }
        //PROGRAM CHANGE LOGIC
       } else if (this.contractValues.ARC_SingleReasonForPC__c) {
           this.MedicalPrice = JSON.parse(JSON.stringify(this.omniJsonData.changesForContracts[0].MedicalPrice));

           if (this.codeValues.ARC_DiscountType__c === 'First Month Payment') {
               this.clearFieldValues();
               this.UI.subtotal_amount = this.MedicalPrice;
               this.UI.orderName = 'First Month Order';
           } else if (this.codeValues.ARC_DiscountType__c === 'Next X Number of Recurring Payments') {
               this.clearFieldValues();
               this.UI.subtotal_amount = this.MedicalPrice;
               this.UI.orderName = 'Recurring Monthly Order';
           } else if (this.codeValues.ARC_DiscountType__c === 'Change Fee') {
               this.clearFieldValues();
               this.UI.subtotal_amount = changeFeeAmount;
               this.UI.orderName = 'Change Fee';
           } else {
               this.displayErrorMessage(`Invalid use of promotional code ${promoCode} for Program Change`);
               return;
           }
       }

       if (this.codeValues.ARC_DiscountedAmount__c) {
           this.UI.discount_amount = this.codeValues.ARC_DiscountedAmount__c.toFixed(2);
       } else if (this.codeValues.ARC_DiscountRate__c) {
           this.UI.discount_label_percent = 'Percent';
           this.UI.discount_amount = ((this.UI.subtotal_amount * this.codeValues.ARC_DiscountRate__c) / 100).toFixed(2);
           this.UI.discount = this.codeValues.ARC_DiscountRate__c + '%';
           this.UI.showPercent = true;
       }

       if ((this.UI.subtotal_amount - this.UI.discount_amount) < 0) {
           this.UI.total_amount = (1).toFixed(2);
           this.UI.discount_amount = (this.UI.subtotal_amount - 1).toFixed(2);
       } else {
           this.UI.total_amount = (this.UI.subtotal_amount - this.UI.discount_amount).toFixed(2);
       }

       this.UI.subtotal_amount = (this.UI.subtotal_amount).toFixed(2);

       this.UI.ARC_DiscountType__c =
           this.codeValues.ARC_DiscountType__c === 'Next X Number of Recurring Payments'
               ? this.codeValues.ARC_DiscountType__c.replace('X', this.codeValues.ARC_NumbeOfRecurringPaymentsToDiscount__c).replace('Number of', '')
               : this.codeValues.ARC_DiscountType__c;

       this.UI.showDiscountDetail = true;
       this.UI.showDiscountInfo = true;

       this.discountId = this.omniJsonData.PromoDiscountId;

       let jsonData = {
           Id: this.discountId || null,
           PromotionCodeId: this.codeValues.Id,
           PromotionCodeName: this.codeValues.Name,
           ContractId: this.contractId,
           DiscountAmount: this.UI.discount_amount,
           MedicalPrice: this.UI.ARC_DiscountType__c !== 'App Fee' && this.UI.ARC_DiscountType__c !== 'Change Fee' ? this.MedicalPrice : null,
           NumberOfPayments: this.codeValues.ARC_NumbeOfRecurringPaymentsToDiscount__c,
           DiscountPrice: this.UI.total_amount,
           AgentId: this.omniJsonData.userId,
           radioValue: 'YES',
           textInputValue: promoCode
       };

       this.omniUpdateDataJson(jsonData, true);
       this.displaySuccessMessage();
   }

   displaySuccessMessage() {
       this.UI.successMessage = 'Valid Code';
   }

   displayErrorMessage(errorMessage) {
       this.UI.errorMessage = errorMessage;
   }

   clearValidationMessages() {
       this.UI.errorMessage = null;
       this.UI.successMessage = null;
   }

   clearFieldValues() {
       this.UI.textInputValue = null;
       this.UI.total_amount = null;
       this.UI.discount_amount = null;
       this.UI.subtotal_amount = null;
       this.UI.showPercent = false;
       this.UI.showDiscountInfo = false;
   }
}