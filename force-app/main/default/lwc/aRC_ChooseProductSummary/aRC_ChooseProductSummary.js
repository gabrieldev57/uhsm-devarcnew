import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';


export default class deleteAfterUsing extends OmniscriptBaseMixin(LightningElement) {

	@api selectedProducts;
	dataExists = false;
    @api repriceProductOutput(repriceProducts) {
		console.log("repriceProductSummary")
		repriceProducts.records.sort((a, b) => {
            if (a.Type__c == 'Medical' && b.SubType__c == 'SMART') {
                return 1;
            }
            if (a.SubType__c == 'SMART' && b.SubType__c == 'AIDD') {
                return -1;
            }
            return 0;
        });
		this.selectedProducts = repriceProducts;
		let coreProductObject = new Object();
		let totalPrice = Number(0);

		this.selectedProducts.records.forEach((r) => {
			totalPrice = totalPrice + r.Price
			if (r.Type__c == "Medical") {
				coreProductObject.Name = r.Name
				coreProductObject.CoverageList = new Array()
				coreProductObject.CensusMemberNameList = new Array()
				coreProductObject.Price = r.Price ? "$" + r.Price.toFixed(2) : "$ 0";
				coreProductObject.childProductList = new Array()

				r.childProducts.records.forEach((c, index) => {
					if (c.RecordTypeName__c == "CoverageSpec") {
						let coverageName = index == 0 ? c.Name : " " + c.Name
						coreProductObject.CoverageList.push(coverageName)
					}
				});
				let censusMemberName = r.CalculatedPriceData.CensusMemberName

				if (censusMemberName == undefined) {
					let filteredList = Object.keys(r.CalculatedPriceData).filter((key) => key !== "Price" && key !== "aggByKey" && key !== "detailPrice")
					filteredList.map((key, index) => {
						censusMemberName = index == 0 ? r.CalculatedPriceData[key].CensusMemberName : " " + r.CalculatedPriceData[key].CensusMemberName
						coreProductObject.CensusMemberNameList.push(censusMemberName)
					})
				} else {
					coreProductObject.CensusMemberNameList.push(censusMemberName)
				}
			}else{
				let product = new Object()
				product.Name = r.Name
				product.CoverageList = new Array()
				product.CensusMemberNameList = new Array()
				product.Price = r.Price ? "$" + r.Price.toFixed(2) : "$ 0";
				console.log("r: "+JSON.stringify(r))
				r.childProducts.records.forEach((c, index) => {
					if (c.RecordTypeName__c == "CoverageSpec") {
						let coverageName = index == 0 ? c.Name : " " + c.Name
						product.CoverageList.push(coverageName)
					}
				});
				let censusMemberName = r.CalculatedPriceData.CensusMemberName
				if (censusMemberName == undefined) {
					let filteredList = Object.keys(r.CalculatedPriceData).filter((key) => key !== "Price" && key !== "aggByKey" && key !== "detailPrice")
					filteredList.forEach((key, index) => {
						censusMemberName = index == 0 ? r.CalculatedPriceData[key].CensusMemberName : " " + r.CalculatedPriceData[key].CensusMemberName
						product.CensusMemberNameList.push(censusMemberName)
					})
				} else {
					product.CensusMemberNameList.push(censusMemberName)
				}
				coreProductObject.childProductList.push(product)
			}
		})
		this.dataExists = true;
		totalPrice = "$" + totalPrice.toFixed(2)
		coreProductObject.totalPrice = totalPrice
		this.product = coreProductObject;
	}
	@api product;
}