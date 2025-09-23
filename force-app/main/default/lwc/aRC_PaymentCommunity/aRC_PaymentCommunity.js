import { LightningElement,api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { NavigationMixin } from 'lightning/navigation';

export default class ARC_PaymentCommunity extends OmniscriptBaseMixin(NavigationMixin(LightningElement)) {
    @api userId;
    @api IPResult = {"Transaction":{}};
    @api conditions = {}

    async connectedCallback(){
		const response = await this.omniRemoteCall({
			input: {"userIdCommunity":this.userId},
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'PersonAccount_ConsoleOrder',
			options: '{}',
		}, true)

        if (response.error == false) {
            const {IsActive,Transaction:{ResponseStatus} = {ResponseStatus:""},TransactionFound,PaymentDelayed,IsContractActive,UpToDate,FirstMonth} = response.result.IPResult;
            this.IPResult = {...this.IPResult,...response.result.IPResult};
            this.conditions.c1 = ResponseStatus != "Approved" && FirstMonth == true && TransactionFound == true && (IsActive == true || (IsActive == false && IsContractActive == false))
            this.conditions.c2 = FirstMonth == false && (IsActive == true || (IsActive == false && IsContractActive == false))
            this.conditions.c3 = ResponseStatus == "Approved" && UpToDate == true && FirstMonth == true && (IsActive == true || (IsActive == false && IsContractActive == false))
            this.conditions.c4 = IsActive == false && IsContractActive == true && ContractReason == "Remove Member"
            this.conditions.c5 = PaymentDelayed == true && FirstMonth == true && (IsActive == true || (IsActive == false && IsContractActive == false))
            this.conditions.c6 = IsActive == false && IsContractActive == true && ContractReason == "Remove Member"
            this.conditions.c7 = FirstMonth == true && TransactionFound == true && (IsActive == true && IsContractActive == true || (IsActive == false && IsContractActive == false))
            this.conditions.c8 = FirstMonth != true || TransactionFound == false
        }
    }

    handleUpdatePaymentMethod() {
        // Define the pageReference for the Named Page using its URL
        const pageReference = {
            type: 'standard__webPage',
            attributes: {
                url: '/change-payment-method'
            }
        }
    
        // Use the NavigationMixin's navigate method to navigate to the Named Page
        this[NavigationMixin.Navigate](pageReference)
    }
}