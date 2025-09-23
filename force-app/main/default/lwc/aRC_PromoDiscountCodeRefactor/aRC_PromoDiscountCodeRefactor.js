import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';


export default class ARC_PromoDiscountCodeRefactor extends OmniscriptBaseMixin(LightningElement) {
    //@api contractId; // Id of the contract to get order information
    @track UI = {}; // Controls the display of the UI

    handleRadioInput(event) {
        // console.log(event.target)
        // console.log(event.currentTarget)
        // console.log(event.target.value)
        this.UI.radioValue = event.target.value;

        if (this.UI.radioValue == "YES") {
            this.UI.showCodeInput = true;
        } else if (this.UI.radioValue == "NO") {
            this.clearValidationMessages();
            this.clearFieldValues();
            this.UI.showCodeInput = false;
        }

    }

    handleTextInputChange(event) {
        this.UI.textInputValue = event.target.value;
    }

    async handleValidateButton() {
        this.clearValidationMessages();

        // let params = { input: JSON.stringify({ 'ContractId': this.contractId }), sClassName: 'ARC_PromotionCode', sMethodName: 'getContractInformation', options: '{}', };
        // let getContractInformation = await this.omniRemoteCall(params, true);

        let params = { input: JSON.stringify({ 'PromotionCode': this.UI.textInputValue }), sClassName: 'ARC_PromotionCode', sMethodName: 'getDiscountCodeInformation', options: '{}', };
        let getDiscountCodeInformation = await this.omniRemoteCall(params, true);

        // console.log(getContractInformation);
        console.log(getDiscountCodeInformation);

        // NO DISCOUNT CODE FOUND, CODE IS INVALID
        if (!getDiscountCodeInformation.result.code && this.UI.textInputValue) {
            this.displayErrorMessage(`${this.UI.textInputValue} is not a valid promotion code.`);
            return;

        }

        // NO TEXT INPUT, CODE FIELD IS EMPTY
        if (!getDiscountCodeInformation.result.code && !this.UI.textInputValue) {
            this.displayErrorMessage('A value is required to be input before validating the code');
            return;
        }

        this.codeValues = getDiscountCodeInformation.result.code;

        let changeFeeAmount;
        ////PROGRAM CHANGE LOGIC


        const isProgramChange = this.omniJsonData?.pcChanges ? true : false;
        const isSpinOff = this.omniJsonData?.soChanges ? true : false

        console.log('isProgramChange ' + isProgramChange)

        const individualProducts = this.omniJsonData.PlansSummary?.BLK_ProductSummary?.BLK_ProductsPrices?.BLK_IndividualProducts;

        const medicalPriceStr = individualProducts.find(prod => prod.Type === 'Medical')?.TXT_PlanSelectedPrice;

        const medicalPrice = medicalPriceStr ? parseFloat(medicalPriceStr.replace('$', '')) : null;



        this.MedicalPrice = medicalPrice;

        if (isProgramChange) {

            changeFeeAmount = this.omniJsonData.pcChanges.feeAmount ? this.omniJsonData.pcChanges.feeAmount : null;


        } else if (isSpinOff) {
            changeFeeAmount = this.omniJsonData.soChanges.feeAmount ? this.omniJsonData.soChanges.feeAmount : null;
        }

        console.log('this.MedicalPrice ' + this.MedicalPrice);
        console.log('changeFeeAmount ' + changeFeeAmount);

        //RECURRING
        if (this.codeValues.ARC_DiscountType__c == 'First Month Payment') {
            this.clearFieldValues();
            this.UI.subtotal_amount = this.MedicalPrice;
            this.UI.orderName = 'First Month Order';
        }
        else if (this.codeValues.ARC_DiscountType__c == 'Next X Number of Recurring Payments') {
            this.clearFieldValues();
            this.UI.subtotal_amount = this.MedicalPrice;
            this.UI.orderName = 'Recurring Monthly Order';
        }
        //CHANGE FEE
        else if (this.codeValues.ARC_DiscountType__c == 'Change Fee') {
            this.clearFieldValues();
            this.UI.subtotal_amount = changeFeeAmount;
            this.UI.orderName = 'Change Fee';
        }
        //APP FEE
        else if (this.codeValues.ARC_DiscountType__c == 'App Fee') {
            this.displayErrorMessage(`Invalid use of promotional code ${this.UI.textInputValue} for Program Change`)
            return;
        }

        if (this.codeValues.ARC_DiscountedAmount__c) {
            this.UI.discount_amount = this.codeValues.ARC_DiscountedAmount__c.toFixed(2);
        } else if (this.codeValues.ARC_DiscountRate__c) {
            this.UI.discount_label_percent = 'Percent';
            this.UI.discount_amount = ((this.UI.subtotal_amount * this.codeValues.ARC_DiscountRate__c) / 100).toFixed(2);
            this.UI.discount = this.codeValues.ARC_DiscountRate__c + '%';
            this.UI.showPercent = true;
        }

        console.log('subtotal_amount', this.UI.subtotal_amount)
        console.log('discount_amount', this.UI.discount_amount)

        if ((this.UI.subtotal_amount - this.UI.discount_amount) < 0) {
            console.log('subtotal', this.UI.subtotal_amount);
            this.UI.total_amount = (1).toFixed(2);
            this.UI.discount_amount = (this.UI.subtotal_amount - 1).toFixed(2);
        } else {
            this.UI.total_amount = (this.UI.subtotal_amount - this.UI.discount_amount).toFixed(2);
        }
        this.UI.subtotal_amount = (this.UI.subtotal_amount).toFixed(2);
        this.UI.ARC_DiscountType__c = this.codeValues.ARC_DiscountType__c == 'Next X Number of Recurring Payments' ?
            this.codeValues.ARC_DiscountType__c.replace('X', this.codeValues.ARC_NumbeOfRecurringPaymentsToDiscount__c).replace('Number of', '') :
            this.codeValues.ARC_DiscountType__c;
        this.UI.showDiscountDetail = true;
        this.UI.showDiscountInfo = true;


        this.discountId = this.omniJsonData.PromoDiscountId;

        if (this.UI.radioValue == 'YES' && this.codeValues) {
            let jsonData = {
                'Id': this.discountId ? this.discountId : null,
                'PromotionCodeId': this.codeValues.Id,
                'PromotionCodeName': this.codeValues.Name,
                'ApplyOver': this.codeValues.ARC_ApplyOver__c,
                //'ContractId': this.contractId,
                'DiscountAmount': this.UI.discount_amount,
                'MedicalPrice': this.UI.ARC_DiscountType__c != 'App Fee' && this.UI.ARC_DiscountType__c != 'Change Fee' ? this.MedicalPrice : null,
                'NumberOfPayments': this.codeValues.ARC_NumbeOfRecurringPaymentsToDiscount__c,
                'DiscountPrice': this.UI.total_amount,
                'AgentId': this.omniJsonData.userId
            }
            console.log('jsonData =>', jsonData);
            this.omniUpdateDataJson(jsonData, true)
            this.displaySuccessMessage();
        }
    }

    displaySuccessMessage() {
        this.UI.successMessage = 'Valid Code';
    }

    displayErrorMessage(errorMessage) {
        this.UI.errorMessage = errorMessage
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

    async connectedCallback() {
        let savedState = this.omniGetSaveState('LWC_PromoDiscountState')
        if (savedState != null) {
            this.UI = savedState.UI;
            this.codeValues = savedState.codeValues;
            this.MedicalPrice = savedState.MedicalPrice;
        } else {
            this.UI = {};
            this.codeValues = null;
            this.MedicalPrice = null;
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
        if (this.UI.radioValue == 'YES') {
            this.template.querySelector('input[type="radio"][value="YES"]').checked = true;
            if (this.UI.textInputValue) {
                this.template.querySelector('lightning-input.code').value = this.UI.textInputValue;
            }
            if (this.UI.errorMessage) {
                this.displayErrorMessage(this.UI.errorMessage);
            }
        } else if (this.UI.radioValue == 'NO') {
            this.template.querySelector('input[type="radio"][value="NO"]').checked = true;
        }
    }

    async disconnectedCallback() {

        let stateToSave = { 'UI': this.UI, 'codeValues': this.codeValues, 'MedicalPrice': this.MedicalPrice, }
        this.omniSaveState(stateToSave, 'LWC_PromoDiscountState', true);
    }
}