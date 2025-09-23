import { LightningElement } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class Arc_ReasonsProgramChange extends OmniscriptBaseMixin(LightningElement)  {
    
    reasonList;
    connectedCallback(){
        let reasonsstring = this.omniJsonData.FilterProgramsToUpdate.singleReasonToDisplay;
        console.log(reasonsstring)
        this.reasonList = reasonsstring.split("\n");
    }

}