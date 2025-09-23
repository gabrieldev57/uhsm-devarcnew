import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
// import template from './aRC_DownloadPlansSummary.html';
import { jsPDF } from "./jspdf";

export default class ARC_DownloadPlansSummary extends OmniscriptBaseMixin(LightningElement) {

    @api osData;
    @track selectedProducts;

    connectedCallback() {
        console.log("Soy Yo")
        this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
        this.selectedProducts = this.osData.selectedProducts;
    }

    handleDownload() {

        var columns = ["ID", "Name", "Country"];
        var rows = [
            [1, "Shaw", "Tanzania"],
            [2, "Nelson", "Kazakhstan"],
            [3, "Garcia", "Madagascar"]
        ];
        var doc = new jsPDF();
        
        // doc.text(10, 10, 'Hola');
        // doc.table(20, 100, [
        //     {
        //         id: 1,
        //         name: 'Leidy'
        //     },
        //     {
        //         id: 2,
        //         name: 'Leris'
        //     }
        // ]);
        doc.autoTable(columns, rows);
        doc.save('hola.pdf');
        


        
        // var sum = 0;
        // for (let product of this.selectedProducts) {
        //     let y = 20;
        //     sum = sum + y;
        //     let price = product.Price.toString();
        //     doc.text(product.Name, 10, sum);
        //     y = 10;
        //     sum = sum + y;
        //     doc.text('Price: ' + price, 10, sum);
        // }
        // doc.save("doc.pdf");

        // // // var pdf = new jsPDF('p', 'pt', 'a4');
        // // // pdf.addHTML(this.template.querySelector("[data-name='medic']"), function() {
        // // // pdf.save('web.pdf');
        // // // });
        // console.log('test');
    }
}