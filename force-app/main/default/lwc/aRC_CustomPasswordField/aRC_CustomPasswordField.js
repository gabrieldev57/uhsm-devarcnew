import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_CustomPasswordField extends OmniscriptBaseMixin(LightningElement) {
    inputType = 'password';
    error1= 'Please use only numbers';
    error2= 'The SSN must have eleven numbers';
    validation;
    errorInput = false;
    errorMessage='';

    connectedCallback(){
        this.omniUpdateDataJson({'validation':false});
        if(this.omniJsonData.STEP_GuardiansInformation && this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN){
            if(this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN.response){
                this.validation=true;
            }
        }
    }

    renderedCallback() {
        if(this.omniJsonData.STEP_GuardiansInformation && this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN){
            if(this.template.querySelector('[data-id="ssnInpt"]')){
                this.template.querySelector('[data-id="ssnInpt"]').value = this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN.response || '';
                this.template.querySelector('[data-id="ssnInpt"]').className = 'vlocity-input nds-input nds-input_mask nds-not-empty nds-is-dirty';
            }
        }
    }

    handleInputChange(){
        const inpt = this.template.querySelector('[data-id="ssnInpt"]').value;

        if (inpt != '') {
            this.template.querySelector('[data-id="ssnInpt"]').className = 'vlocity-input nds-input nds-input_mask nds-not-empty nds-is-dirty';

            if(!isNaN(inpt)) {
                this.errorInput = false;
                this.template.querySelector('[data-id="contInput"]').className = 'nds-form-element nds-form-container';
                if(inpt.length < 9) {
                    this.validation=false;
                    this.errorInput = true;
                    this.errorMessage = this.error2;
                    this.omniUpdateDataJson({'validation':false});
                }
                else {
                    this.errorInput = false;
                    this.omniUpdateDataJson({'validation':true});
                    this.omniUpdateDataJson({'response': inpt});
                    this.validation = true;
                }
            }else{
                this.template.querySelector('[data-id="contInput"]').className = 'nds-form-element nds-form-container nds-has-error';
                this.errorMessage= this.error1;
                this.errorInput = true;
                this.validation = false;
                this.omniUpdateDataJson({'validation':false});
            }
        }else{
            this.errorInput = false;
            this.validation = false;
            this.omniUpdateDataJson({'validation':false});
            this.template.querySelector('[data-id="contInput"]').className = 'nds-form-element nds-form-container';
            this.template.querySelector('[data-id="ssnInpt"]').className = 'vlocity-input nds-input nds-input_mask';
        } 

        console.log('INPUT CHANGE', this.validation)

    }

    handleChangeType(evt){
        if(evt.currentTarget.dataset.id == 'fieldView'){
            switch (this.inputType) {
                case 'password':
                    this.inputType = 'text';
                    break;
                case 'text':
                    this.inputType = 'password';
                    break;
            }
        }
    }
}