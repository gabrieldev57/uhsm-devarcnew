import { FlexCardMixin } from "vlocity_ins/flexCardMixin";
    import {interpolateWithRegex, interpolateKeyValue, loadCssFromStaticResource } from "vlocity_ins/flexCardUtility";
    import { load } from "vlocity_ins/newportLoader";
          
          import { LightningElement, api, track, wire } from "lwc";
          import pubsub from "vlocity_ins/pubsub";
          import { getRecord } from "lightning/uiRecordApi";
          
          import data from "./definition";
          
          import styleDef from "./styleDefinition";
              
          export default class cfInsPolicyListFlyout_nds extends FlexCardMixin(LightningElement){
              @api debug;
              @api recordId;
              @api objectApiName;
              
              @track record;
              
              
              pubsubEvent = [];
              customEvent = [];
              
              connectedCallback() {
                super.connectedCallback();
                this.setStyleDefinition(styleDef);
                data.Session = {} //reinitialize on reload
                
                
                
                
                this.setAttribute(
                  "class",
                  "card-a7UVA00000132w12AA"
                );
                this.loadCustomStylesheetAttachement("00PVA000002dqMK2AY");
                
                
                load(this)
                .then(() => {
                  this.setDefinition(data); 
 this.registerEvents();
                  this.isProcessing = false;
                  //this.isNewport = false;
                })
                .catch(() => {
                  this.setDefinition(data); 
 this.registerEvents();
                });
                
              }
              
              disconnectedCallback(){
                super.disconnectedCallback();
                    
                    

                  this.unregisterEvents();
              }

              registerEvents() {
                
              }

              unregisterEvents(){
                
              }
            
              renderedCallback() {
                super.renderedCallback();
                
              }
          }