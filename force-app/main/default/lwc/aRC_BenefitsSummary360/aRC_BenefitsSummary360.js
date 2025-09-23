import { LightningElement, api,wire, track } from 'lwc';
import getProducts from '@salesforce/apex/ARC_BenefitSummaryHandler.getBenefitsSummary360Data';
import METAL_BROCHURE from "@salesforce/resourceUrl/Metal_Brochures";


export default class ARC_BenefitsSummary360 extends LightningElement {
    @api recordId;
    @track isLoaded = false;
    @track products;

    @wire(getProducts, { personAccountId:  '$recordId'})
    getData({ error, data }) {
        if(data){
            this.products = JSON.parse(JSON.stringify(data));
            this.products.forEach(product => {
                if(product.name.includes('UHSM')) product.link = METAL_BROCHURE+'/'+product.link+'.pdf';
            });
            this.isLoaded=true;
        }
        else if(error){
            console.log('benefitSummary360',error);
        }
    }

}