import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getContentVersionInfo from '@salesforce/apex/ARC_HealthProgramRecords.getContentVersionInfo';
import getHealthProgramSpecs from '@salesforce/apex/ARC_HealthProgramRecords.getHealthProgramSpecs';
import communityPath from '@salesforce/community/basePath';

export default class ARC_HealthPrograms extends NavigationMixin(LightningElement) {
    @api title;
    @api subtitle;
    @api text;
    @api programsList;
    @api slider;
    @track isSlider = false;
    @track files;
    programHeader;
    @track finalRecords = [];
    communityPage = communityPath;

    @wire(getContentVersionInfo, { programsList: '$programsList' })
    filesData({ data, error }) {
        if (data) {
            this.files = data.map(obj => ({ ...obj, url: this.communityPage.split('/s')[0] + '/sfc/servlet.shepherd/version/download/' + obj.Id }));

        } else if (error) {
            window.console.log('error ===> ' + JSON.stringify(error));
        }
    }

    @wire(getHealthProgramSpecs, { files: '$files'})
    specsData({ data, error }) {
        if (data) {
            let records = [];
            this.files.forEach((file) => {
                let specs = [];
                
                
                data.forEach((healthSpec) => {
                    if (file.RecordId == healthSpec.ARC_HealthProgram__c) {
                        specs.push({'RecId': healthSpec.Id, 'Name': healthSpec.Name, 'Description': healthSpec.ARC_Description__c, 'Order':healthSpec.ARC_Order__c });
                    }
                });
                specs.sort((a, b) => {
                    return a.Order - b.Order;
                })
                
                records.push({...file, specs});
            });

            if(records.length > 1 & this.slider) this.isSlider = true;

            this.finalRecords = records;

        } else if (error) {
            window.console.log('error specsData ===> ' + JSON.stringify(error));
        }
    }
}