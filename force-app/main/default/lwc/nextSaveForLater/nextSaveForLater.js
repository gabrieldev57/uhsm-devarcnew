import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
export default class NextStepOmniScript extends OmniscriptBaseMixin(LightningElement) {
    
    handleNext() {
        try {
            console.log('Attempting to move to the next step...');
            this.omniNextStep(); // Trigger OmniScript to move to the next step
            console.log('Successfully moved to the next step.');
            this.omniSaveState(this.omniJsonData, 'AutoSaveOmniScriptKey', true);
            console.log('Successfully saved current state');
        } catch (error) {
            console.error('Error while navigating to the next step:', error);
        }
    }
}