import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";

export default class ARC_EffectiveDateNavigation extends OmniscriptBaseMixin(LightningElement) {
    @api updateTypes; // Type of change selected

    handler_CancelDiscardChanges() {
        this.template.querySelector('.discard-warning-modal')?.closeModal();
    }

    handler_ConfirmDiscardChanges() {
        this.template.querySelector('.discard-warning-modal')?.closeModal();
        this.omniPrevStep();
    }

    //nextStep
    handler_NextStep() {
        this.omniNextStep();
    }

    //previousStep
    handler_PreviousStep() {
        console.log('updateTypes => ', this.updateTypes);
        if (this.updateTypes === 'Change to Programs & Effective Date') {
            this.template.querySelector('.discard-warning-modal')?.openModal();
        } else {
            this.omniPrevStep();
        } 
    }
}