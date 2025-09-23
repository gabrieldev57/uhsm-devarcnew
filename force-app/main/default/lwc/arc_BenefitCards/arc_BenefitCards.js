import { LightningElement, wire, track, api } from 'lwc';
import ARC_RetrieveBenefitCards from "@salesforce/apex/ARC_RetrieveBenefitCards.getContentVersionInfo";
import getBenefitCards from "@salesforce/apex/ARC_RetrieveBenefitCards.getBenefitCards";
import communityPath from '@salesforce/community/basePath';

export default class ARC_BenefitCards extends LightningElement {

    @api finalRecords;
    @track files;
    @api title;
    @api subtitle;
    @api description;
    @api cardsList;
    @api slider;
    @api horizontal;
    @track isSlider = false;
    @track slidesPerViewM = 2;
    @track slidesPerViewL = 4;
    @track includeHeader;
    communityPage = communityPath;

    @wire(ARC_RetrieveBenefitCards, { cardsList: '$cardsList'})
    filesData({ data, error }) {
        if (data) {
            this.files = data.map(obj => ({ ...obj, url: this.communityPage.split('/s')[0] + '/sfc/servlet.shepherd/version/download/' + obj.ImageId }))
        } else if (error) {
        }
    }

    @wire(getBenefitCards, { files: '$files'})
    specsData({ data, error }) {
        if (data) {
            let records = [];
            this.files.forEach((file) => {
                // records.push({...file});
                data.forEach((benefitCard) => {
                    if (file.RecordId == benefitCard.Id) {
                        records.push({
                            'RecId': benefitCard.Id,
                            'Description': benefitCard.ARC_Description__c,
                            'Title': benefitCard.ARC_Title__c,
                            'Link': benefitCard.ARC_Link__c,
                            'ImageUrl': file.url,
                        });
                    }
                });
            });
            
            if(records.length > 1 & this.slider) this.isSlider = true;

            this.finalRecords = records;
           
        } else if (error) {
            window.console.log('error ===> ' + JSON.stringify(error));
        }
    }

    connectedCallback(){
        this.includeHeader = this.title || this.subtitle || this.description ? true : false;
        if(this.horizontal){
            this.slidesPerViewM = "auto";
            this.slidesPerViewL = "auto";
        }
    }
    
    renderedCallback(){
        let component = this.template.querySelector('.component-container');
        if(this.horizontal){
            component.classList.add("benefit-card-type-horizontal")
        }
    }


    // connectedCallback() {

    //     arc_retrieveBenefitCards()
    //         .then(BenefitCardsList => {
    //             console.log(BenefitCardsList);

    //             this.cardsList = BenefitCardsList;

    //         })
    //         .catch(error => {

    //             this.error = error;

    //         });
    // }
}