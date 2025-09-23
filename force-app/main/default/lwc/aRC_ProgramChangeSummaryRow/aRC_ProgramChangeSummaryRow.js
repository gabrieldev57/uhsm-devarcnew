import insOsEnrolleeBenefitsSummaryRow from 'vlocity_ins/insOsEnrolleeBenefitsSummaryRow';
import { api } from 'lwc';

export default class aRC_ProgramChangeSummaryRow extends insOsEnrolleeBenefitsSummaryRow {
    labels = {
        InsWhosCovered : "Who’s Applying",
        InsPlanDetails : "Program Details",
        InsYou : "You",
        InsMonthAbrv : "Mo"
    };
    @api dependents;
    @api product;

    get dependentNames() {
        let dependentNames = '';

        if (this.dependents.length) {
            const memberProducts = this.dependents.filter(dep => dep.productsIds.includes(this.product.Id));
            dependentNames = memberProducts.map(member => member.FirstName + ' ' + member.LastName).join(', ');
        }
        return dependentNames;
    }

    get price() {
        return this.product.Price
    }
}