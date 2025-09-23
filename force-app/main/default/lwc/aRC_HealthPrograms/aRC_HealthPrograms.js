import { LightningElement, wire, track, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getContentVersionInfo from '@salesforce/apex/ARC_HealthProgramRecords.getContentVersionInfo';
import getHealthProgramSpecs from '@salesforce/apex/ARC_HealthProgramRecords.getHealthProgramSpecs';

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

    @wire(getContentVersionInfo, { programsList: '$programsList' })
    filesData({ data, error }) {
        if (data) {
            // window.console.log('data ---> ' + JSON.stringify(data));
            // window.console.log('programsList ---> ' + JSON.stringify(this.programsList));
            this.files = data.map(obj => ({ ...obj, url: '/sfc/servlet.shepherd/version/download/' + obj.Id }));
        } else if (error) {
            window.console.log('error ===> ' + JSON.stringify(error));
        }
    }

    @wire(getHealthProgramSpecs, { files: '$files'})
    specsData({ data, error }) {
        if (data) {
            // window.console.log('specsData ---> ' + JSON.stringify(data));
            let records = [];
            this.files.forEach((file) => {
                let specs = [];
                
                data.forEach((healthSpec) => {
                    if (file.RecordId == healthSpec.ARC_HealthProgram__c) {
                        window.console.log('recordId: ' + file.RecordId + ' id: ' + healthSpec.Id);
                        specs.push({'RecId': healthSpec.Id, 'Name': healthSpec.Name, 'Description': healthSpec.ARC_Description__c, 'Order':healthSpec.ARC_Order__c });
                    }
                });

                //window.console.log('specs UO---> ' + JSON.stringify(specs));
                specs.sort((a, b) => {
                    return a.Order - b.Order;
                })

                // data.forEach((healthSpec) => {
                //     if (file.RecordId == healthSpec.ARC_HealthProgram__c) {
                //         window.console.log('recordId: ' + file.RecordId + ' id: ' + healthSpec.Id);
                //         specs.push({'RecId': healthSpec.Id, 'Name': healthSpec.Name, 'Description': healthSpec.ARC_Description__c});
                //     }
                // });

                // if(this.programsList === "Vacation" || this.programsList === "VacationPremium") this.specs = ["Price", "Nights", "Services", "Stars"];

                // // sort Specs by name
                // this.specs.forEach(specName => {
                //     let spec = data[data.findIndex(o => o.ARC_HealthProgram__c === file.RecordId && o.Name === specName)];
                //     specs.push({'RecId': spec.Id, 'Name': spec.Name, 'Description': spec.ARC_Description__c});
                // })

                records.push({...file, specs});
            });

            if(records.length > 1 & this.slider) this.isSlider = true;

            this.finalRecords = records;

            // window.console.log('records: ' + JSON.stringify(this.finalRecords));

        } else if (error) {
            window.console.log('error ===> ' + JSON.stringify(error));
        }
    }
}