import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_CustomButtonsNextPrev extends OmniscriptBaseMixin(LightningElement) {
validation;

connectedCallBack(){
    setTimeout(() => {
        this.validation = this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN.validation;
    }, 200);
}

handleNext(){
    this.validation = this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN.validation;
    if (this.validation) this.omniNextStep();
}
handlePrev(){
    this.omniPrevStep();
}
}