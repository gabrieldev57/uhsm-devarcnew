import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";

export default class ARC_ClearJsonNavigation extends OmniscriptBaseMixin(LightningElement) {
    @api step;

    async connectedCallback() {
        this.omniSaveState({}, 'LWC_Census', true);
        if (this.step === 'STEP_ChangeSelect') {
            this.omniSaveState({}, 'STEP_SelectContract', true);
        }
        const restoredJson = await this.omniGetSaveState(this.step);
        if (restoredJson && Object.keys(restoredJson).length > 0) {
            const currentKeys = Object.keys(this.omniJsonData);
            const keysToRemove = currentKeys.filter(k => !restoredJson.hasOwnProperty(k));
            keysToRemove.forEach(key => {
                const blank = {};
                blank[key] = null;
                this.omniApplyCallResp(blank);
            });
            this.omniApplyCallResp(restoredJson);
        }
    }

    //nextStep
    handler_NextStep() {
        this.omniSaveState(this.omniJsonData, this.step);
        this.omniNextStep();
    }

    //previousStep
    handler_PreviousStep() {
        this.omniPrevStep();
    }
}