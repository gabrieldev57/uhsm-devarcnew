import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
 
export default class arc_ProgramChange_ReasonsPlansSummary extends OmniscriptBaseMixin(LightningElement)  {
   
    @api reasonList;
    connectedCallback(){
        console.log('this.reasonList = ', this.reasonList);
        this.reasonList = this.reasonList.split(";");
    }
 
}