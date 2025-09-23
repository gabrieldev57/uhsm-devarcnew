import insOsEnrolleeBenefitsSummary from 'vlocity_ins/insOsEnrolleeBenefitsSummary';
import { api } from 'lwc';

export default class arc_insOsEnrolleeBenefitsSummary extends insOsEnrolleeBenefitsSummary {
    // @api dependents;
    @api initJson;
    productsWithMembers = [];
    isProducts = false;

    connectedCallback(){
        super.connectedCallback();
        let inputProducts = [...JSON.parse(JSON.stringify(this.initJson))];
        inputProducts.sort((a, b) => {
            if (a.Type__c == 'Medical' && b.SubType__c == 'SMART') {
                return 1;
            }
            if (a.SubType__c == 'SMART' && b.SubType__c == 'AIDD') {
                return -1;
            }
            return 0;
        });

        inputProducts.forEach(product => {
            let objectToAdd = {'plans': {}, 'dependents': []};
            objectToAdd.plans = product;
            if (product.CalculatedPriceData) {
                let censusMemberName = product.CalculatedPriceData.CensusMemberName;
                if (censusMemberName == undefined) {
                    let filteredList = Object.keys(product.CalculatedPriceData).filter((key) => key !== "Price" && key !== "aggByKey")
                    filteredList.map((key, index) => {
                        censusMemberName = index == 0 ? product.CalculatedPriceData[key].CensusMemberName : product.CalculatedPriceData[key].CensusMemberName;
                        objectToAdd.dependents.push(censusMemberName);
                    })
                }else{
                    objectToAdd.dependents.push(censusMemberName);
                }
            }

            this.productsWithMembers.push(objectToAdd);
        }); 

        if (this.productsWithMembers.length > 0) this.isProducts = true;
    } 

}