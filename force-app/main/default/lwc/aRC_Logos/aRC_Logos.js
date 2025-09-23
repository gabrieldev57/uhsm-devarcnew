import { LightningElement,wire,track,api } from 'lwc';
import staticResourceURL from '@salesforce/resourceUrl/ARC_Logos'; //imports path to the static resource zip file 'ARC_Logos'
import ARC_ExtractZipFiles from '@salesforce/apex/ARC_ExtractZipFiles.getImagesList'; //imports every file name inside 'ARC_Logos' static resource

export default class aRC_Logos extends LightningElement {
    @api title;
    @api folder;
    
    @track urlList;

    connectedCallback() {
        ARC_ExtractZipFiles()
            .then(logosList => {
                if(this.folder) logosList = logosList.filter(logo => logo.split("/")[0] === this.folder);
                var staticResourcesList = logosList.map(logo => {
                    return staticResourceURL+'/'+logo
                });
                this.urlList=staticResourcesList;
            })
            .catch(error => {
                console.log(error);
                this.error = error;
            });

    }
}