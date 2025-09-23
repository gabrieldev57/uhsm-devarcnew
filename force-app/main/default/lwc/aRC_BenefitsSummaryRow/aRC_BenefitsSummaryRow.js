import { LightningElement, api } from 'lwc';

export default class ARC_BenefitSummaryRow extends LightningElement {

    @api product;
    @api hideeffectivedates;
    @api showprogramdetails;

    labels = {
        InsWhosCovered: "Active Members",
        InsPlanDetails: "Program Details",
        InsYou: "You",
        InsMonthAbrv: "Mo",
        EffectiveDate: "Effective Date",
    };

    async handleDownloadPdfFile(event){
        console.log(event.target.dataset.link);
            const downloadLink = document.createElement('a');
            downloadLink.href = event.target.dataset.link;
            downloadLink.target = "_blank";
            downloadLink.click();
    }
}