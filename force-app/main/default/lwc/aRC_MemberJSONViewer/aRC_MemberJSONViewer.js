// wireGetRecordDynamicContact.js
import { LightningElement, api, wire, track } from 'lwc';
import getJSON from '@salesforce/apex/ARC_MemberJSONController.getJSONFields';




export default class ARC_MemberJSONViewer extends LightningElement {
    @api recordId;
    @api claim;
    @track mapSubmitter = [];
    @track mapServiceFacility= [];
    @track mapReferringProvider= [];
    @track mapPatient= [];



    @wire(getJSON, { claimId: '$recordId' })
    wiredClaim({ error, data }) {
        if (data) {
            this.claim = data;

            var submitter = this.claim[0];
            for(var key in submitter){
                this.mapSubmitter.push({value:submitter[key], key:key.replace('EDI', '').replace('.', ' -> ').replace(/[A-Z]/g, ' $&').trim().slice(0, -3).replace('_', ' ')});
            }

            var serviceFacility = this.claim[1];
            for(var key in serviceFacility){
                this.mapServiceFacility.push({value:serviceFacility[key], key:key.replace('.', ' -> ').replace(/[A-Z]/g, ' $&').trim().slice(0, -3).replace('_', ' ')});
            }

            var referringProvider = this.claim[2];
            for(var key in referringProvider){
                this.mapReferringProvider.push({value:referringProvider[key], key:key.replace('.', ' -> ').replace(/[A-Z]/g, ' $&').trim().slice(0, -3).replace('_', ' ')});
            }

            var patient = this.claim[3];
            for(var key in patient){
                this.mapPatient.push({value:patient[key], key:key.replace('.', ' -> ').replace(/[A-Z]/g, ' $&').trim().slice(0, -3).replace('_', ' ')});
            }

            
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.claim = undefined;
        }
    }
  
      
}