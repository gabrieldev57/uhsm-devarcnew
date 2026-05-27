import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
 
export default class arc_ProgramChange_PlansSummary extends OmniscriptBaseMixin(LightningElement)  {
   
    @api reasonList;
    @api feeApplicable;
    @api programSummaryFeeText;
    _feeAmount;
    _feeAmountPending;
    @api programSummaryFeeTextPending;
    @api effDate;
    @api individualProducts;
    @api monthlyPrice;

    @api
    get feeAmount() {
        return this.formatFee(this._feeAmount);
    }
    set feeAmount(value) {
        this._feeAmount = value;
    }

    @api
    get feeAmountPending() {
        return this.formatFee(this._feeAmountPending);
    }
    set feeAmountPending(value) {
        this._feeAmountPending = value;
    }

    formatFee(fee) {
        if (fee == null || fee === '') return '';
        if(fee.toString().includes('$')) return fee;
        let feeStr = fee.toString().trim();
        feeStr = feeStr.replace(/^\$/, '');
        feeStr = feeStr.replace(/\$/g, '');
        feeStr = feeStr.replace(/,/g, '');
        let num = parseFloat(feeStr);
        if (isNaN(num)) return fee;
        return `$${num.toFixed(2)}`;
    }
    
    connectedCallback(){
        console.log('programSummaryFeeTextPending' + this.programSummaryFeeTextPending);

        // ...existing code...

        this.reasonList = this.reasonList.split(";");

        const orderKeys = ["Medical", "SMART", "AIDD"];

        this.individualProducts = this.individualProducts.sort((a, b) => {
            const getKey = (prod) => {
                if (prod.Type === "Medical") {
                    return "Medical";
                }

                const name = prod.TXT_PlanSelected.toUpperCase(); 
                if (name.startsWith("SMART")) {
                    return "SMART";
                }
                if (name.startsWith("AIDD")) {
                    return "AIDD";
                }
                return null;
            }
            const keyA = getKey(a);
            const keyB = getKey(b);

            const idxA = keyA !== null ? orderKeys.indexOf(keyA) : orderKeys.length;
            const idxB = keyB !== null ? orderKeys.indexOf(keyB) : orderKeys.length;

            return idxA - idxB;
        });

        this.planSelected = this.individualProducts.map(product => product.TXT_PlanSelected);
        this.planSelectedPrice = this.individualProducts.map(product => product.TXT_PlanSelectedPrice);
    }
}