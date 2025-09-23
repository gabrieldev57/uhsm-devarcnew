import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
 
export default class arc_ProgramChange_PlansSummary extends OmniscriptBaseMixin(LightningElement)  {
   
    @api reasonList;
    @api feeApplicable;
    @api programSummaryFeeText;
    @api feeAmount;
    @api effDate;
    @api individualProducts;
    @api monthlyPrice;
    
    connectedCallback(){

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