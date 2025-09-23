import { LightningElement, api, wire, track } from 'lwc';
import getJSON from '@salesforce/apex/ARC_ProviderJSONViewerController.getProviderJSON';


export default class ARC_ProviderJSONViewer extends LightningElement {
    
    @api recordId;
    @api acc;
    @track mapProvider = [];
    
    
    
    @wire(getJSON, { accountId: '$recordId' })
    wiredAccount({ error, data }) {
        if (data) {
            this.acc = data;
            for(var key in this.acc){
                this.mapProvider.push({value:this.acc[key], key:key.replace('EDI', '').replace('.', ' -> ').replace(/[A-Z]/g, ' $&').trim().slice(0, -3).replace('_', ' ')});
            }          
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.acc = undefined;
        }
    }
}