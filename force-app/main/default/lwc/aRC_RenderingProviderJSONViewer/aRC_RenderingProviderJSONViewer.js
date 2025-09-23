import { LightningElement, api, wire, track } from 'lwc';
import getJSON from '@salesforce/apex/ARCRenderingProviderJSONViewerController.getRenderingProviderJSON';


export default class ARC_RenderingProviderJSONViewer extends LightningElement {
    
    @api recordId;
    @api con;
    @track mapProvider = [];
    
    
    
    @wire(getJSON, { contactId: '$recordId' })
    wiredAccount({ error, data }) {
        if (data) {
            this.con = data;
            for(var key in this.con){
                this.mapProvider.push({value:this.con[key], key:key.replace('EDI', '').replace('.', ' -> ').replace(/[A-Z]/g, ' $&').trim().slice(0, -3).replace('_', ' ')});
            }          
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.con = undefined;
        }
    }
}