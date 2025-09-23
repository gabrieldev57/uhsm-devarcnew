import insOsEnrolleeBenefitsSummaryRow from 'vlocity_ins/insOsEnrolleeBenefitsSummaryRow';
import { api } from 'lwc';
import tmpl from "./arc_insOsEnrolleeBenefitsSummaryRow.html";

export default class Arc_insOsEnrolleeBenefitsSummaryRow extends insOsEnrolleeBenefitsSummaryRow {

    labels = {
        InsWhosCovered: "Active Members",
        InsPlanDetails: "Program Details",
        InsYou: "You",
        InsMonthAbrv: "Mo"
    };

    @api dependents;
    @api product;

    render() {return tmpl;}

    get dependentNames() {
        let dependentNames = '';

        if (this.dependents.length) {
            if (this.dependents[0].productsIds != null) {
                const memberProducts = this.dependents.filter(dep => dep.productsIds.includes(this.product.Id));
                dependentNames = memberProducts.map(member => member.FirstName + ' ' + member.LastName).join(', ');
            } else {
                if (this.dependents && this.dependents.length) {
                    dependentNames += this.dependents.map(d => d.FirstName + ' ' + d.LastName).join(', ');
                }
            }
        }
        return dependentNames;
    }

    get price() {
        return this.product.Price
    }
}