import omniscriptSetValues from "vlocity_ins/omniscriptSetValues";
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";


export default class ARC_OverrideNextButton extends OmniscriptBaseMixin(omniscriptSetValues) {

    connectedCallback(){
        super.connectedCallback()
    }

    execute(){
        this.omniNextStep()
    }
}