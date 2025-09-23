import insOsEnrolleeBenefitsSummaryRow from 'vlocity_ins/insOsEnrolleeBenefitsSummaryRow';
import { api } from 'lwc';

export default class Arc_insOsEnrolleeBenefitsSummaryRowShopv2 extends insOsEnrolleeBenefitsSummaryRow {

    labels = {
        InsWhosCovered : "Who’s Applying",
        InsPlanDetails : "Program Details",
        InsYou : "You",
        InsMonthAbrv : "Mo"
    };

    @api productid;
    @api dependents;

    get dependentNames() {
        let dependentNames = '';
        if (this.dependents && this.dependents.length) {
            dependentNames += this.dependents.map(d => d).join(', ');
        }
        return dependentNames;
    }
}