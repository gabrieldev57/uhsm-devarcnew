import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_CustomPasswordField extends OmniscriptBaseMixin(LightningElement) {
    inputType = 'password';
    error1 = 'Please use only numbers';
    error2 = 'The SSN must have eleven numbers';
    validation;
    errorInput = false;
    errorMessage = '';

    connectedCallback() {
        this.omniUpdateDataJson({ validation: false });
        if (
            this.omniJsonData.STEP_GuardiansInformation &&
            this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN &&
            this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN.response
        ) {
            this.validation = true;
            this.errorInput = false;
            this.errorMessage = '';
        }
    }

    renderedCallback() {
    if (
        this.omniJsonData.STEP_GuardiansInformation &&
        this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN
    ) {
        const ssnInput = this.template.querySelector('[data-id="ssnInpt"]');
        if (ssnInput) {
            ssnInput.required = true;
            const response =
                this.omniJsonData.STEP_GuardiansInformation.TXT_GuardianSSN.response || '';
            if (response) {
                ssnInput.value = response;
                ssnInput.className =
                    'vlocity-input nds-input nds-input_mask nds-not-empty nds-is-dirty';
            }

            this.runValidation(ssnInput.value, false);
        }
        }
    }


    runValidation(value, fromChange) {
        const input = this.template.querySelector('[data-id="ssnInpt"]');
        const container = this.template.querySelector('[data-id="contInput"]');

        if (!value) {
            this.errorInput = true;
            this.errorMessage = 'SSN is required';
            this.validation = false;
            this.omniUpdateDataJson({
                validation: false,
                ssnError: this.errorMessage,
                response: ''
            });
            if (container) {
                container.className =
                    'nds-form-element nds-form-container nds-has-error';
            }
            if (input) {
                input.className = 'vlocity-input nds-input nds-input_mask';
                input.setCustomValidity(this.errorMessage);
                if (fromChange) {
                    input.reportValidity();
                }
            }
            return false;
        }

        if (input) {
            input.className =
                'vlocity-input nds-input nds-input_mask nds-not-empty nds-is-dirty';
            input.setCustomValidity('');
        }
        if (container) {
            container.className = 'nds-form-element nds-form-container';
        }

        if (isNaN(value)) {
            this.errorInput = true;
            this.errorMessage = this.error1;
            this.validation = false;
            this.omniUpdateDataJson({
                validation: false,
                ssnError: this.errorMessage,
                response: ''
            });
            if (container) {
                container.className =
                    'nds-form-element nds-form-container nds-has-error';
            }
            if (input) {
                input.setCustomValidity(this.errorMessage);
                if (fromChange) {
                    input.reportValidity();
                }
            }
            return false;
        }

        if (value.length < 9) {
            this.errorInput = true;
            this.errorMessage = this.error2;
            this.validation = false;
            this.omniUpdateDataJson({
                validation: false,
                ssnError: this.errorMessage,
                response: ''
            });
            if (container) {
                container.className =
                    'nds-form-element nds-form-container nds-has-error';
            }
            if (input) {
                input.setCustomValidity(this.errorMessage);
                if (fromChange) {
                    input.reportValidity();
                }
            }
            return false;
        }

        this.errorInput = false;
        this.errorMessage = '';
        this.validation = true;
        this.omniUpdateDataJson({
            validation: true,
            ssnError: '',
            response: value
        });
        if (container) {
            container.className = 'nds-form-element nds-form-container';
        }
        if (input) {
            input.setCustomValidity('');
            if (fromChange) {
                input.reportValidity();
            }
        }
        return true;
    }

    handleInputChange() {
        const input = this.template.querySelector('[data-id="ssnInpt"]');
        const value = input ? input.value : '';
        this.runValidation(value, true);
    }

    @api
    reportValidity() {
        const input = this.template.querySelector('[data-id="ssnInpt"]');
        const value = input ? input.value : '';
        return this.runValidation(value, false);
    }

    handleChangeType(evt) {
        if (evt.currentTarget.dataset.id === 'fieldView') {
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