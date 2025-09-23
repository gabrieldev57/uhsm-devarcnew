/* global moment */
import { LightningElement, wire, api, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import App from "@salesforce/resourceUrl/app2";
import getJSON from '@salesforce/apex/aRC_JsonTreeController.getJSONInput';

export default class ARC_InputJSONViewer extends LightningElement {
  @api jsonText;
  @api reactJsonViewProps;
  @api recordId;
  @track claim;
  @track json;

  @wire(getJSON, { claimId: '$recordId' })
    wiredClaim({ error, data }) {
        if (data) {
            console.log("JSON::::::::::::: " + data);
            
            this.claim = data;
            console.log("DATAAAAAAAAA" + this.claim.ARC_InputJSON__c);
            this.jsonText = this.claim.ARC_InputJSON__c;                   
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.claim = undefined;
        }
    }

  renderedCallback() {
    Promise.all([loadScript(this, App)]).then(() => {
      mount(this.template.querySelector("div"), {
        jsonText: this.jsonText,
        reactJsonViewProps: this.reactJsonViewProps
      });
    });
  }
}