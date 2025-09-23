import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_CreateNewPassword extends OmniscriptBaseMixin(LightningElement) {
    @track showPasswordInput = true;
    @track showConfirmInput = true;
    @track newPassFocus = false;
    @track confirmPassFocus = false;
    @track blankSpace = true;
    @track textValue = '';
    @track textConfValue = '';
    @track validationError = true;
    @track validationErrorConfirm = true;
    @api username;
    containsUsername = false;


    handleChangeType(evt){

        if(evt.currentTarget.dataset.id == 'newView') this.showPasswordInput = !this.showPasswordInput;
        else if(evt.currentTarget.dataset.id == 'confirmView') this.showConfirmInput = !this.showConfirmInput;
    }

    get renderPasswordInput() {
        return this.showPasswordInput;
    }

    get renderConfirmInput() {
        return this.showConfirmInput;
    }

    handleInputChange(evt){
        let lowercase = this.template.querySelector('[data-id="lowercase"]');
        let capital = this.template.querySelector('[data-id="capital"]');
        let number = this.template.querySelector('[data-id="number"]');
        let special = this.template.querySelector('[data-id="special"]');
        let length = this.template.querySelector('[data-id="length"]');
        let samePass = this.template.querySelector('[data-id="samePass"]');
        let strongPassword = new RegExp('(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9])(?=.{8,})') 
        let mediumPassword = new RegExp('^(?=.*[A-Z].*[A-Z])(?=.*[!@#$&*])(?=.*[0-9].*[0-9])(?=.*[a-z].*[a-z].*[a-z]).{8}$')
        
        let lowerCaseLetters = /[a-z]/g;
        let upperCaseLetters = /[A-Z]/g;
        let numbers = /[0-9]/g;
        let specialCharacters = /[!@#$%^&*_=+\-~(){}|;:'",<.>?\/\[\]\\]/g;

        switch (evt.currentTarget.dataset.id) {
            case 'newInput':
                this.textValue = evt.detail.value;

                if(this.passwordContainsUsername(this.username,this.textValue)){
                    this.validationError = true;
                    this.containsUsername = true;
                }else{
                    this.validationError = false;
                    this.containsUsername = false;
                }

                if (this.textValue.match(strongPassword)) {
                    console.log('strong');
                }

                if (this.textValue.match(mediumPassword)) {
                    console.log('medium');
                }

                if(this.textValue.match(lowerCaseLetters)){
                    lowercase.classList.remove("invalid");
                    lowercase.classList.add("valid");
                    this.validationError = false;
                }else{
                    lowercase.classList.remove("valid");
                    lowercase.classList.add("invalid");
                    this.validationError = true;
                }

                if(this.textValue.match(upperCaseLetters)){
                    capital.classList.remove("invalid");
                    capital.classList.add("valid");
                    this.validationError = false;
                }else{
                    capital.classList.remove("valid");
                    capital.classList.add("invalid");
                    this.validationError = true;
                }

                if(this.textValue.match(numbers)){
                    number.classList.remove("invalid");
                    number.classList.add("valid");
                    this.validationError = false;
                }else{
                    number.classList.remove("valid");
                    number.classList.add("invalid");
                    this.validationError = true;
                }

                if (this.textValue.length >= 8){
                    length.classList.remove("invalid");
                    length.classList.add("valid");
                    this.validationError = false;
                }else{
                    length.classList.remove("valid");
                    length.classList.add("invalid");
                    this.validationError = true;
                }

                if (this.textValue.match(specialCharacters)){
                    special.classList.remove("invalid");
                    special.classList.add("valid");
                    this.validationError = false;
                }else{
                    special.classList.remove("valid");
                    special.classList.add("invalid");
                    this.validationError = true;
                }

                if (this.confirmPassFocus) {
                    if (this.textValue === this.template.querySelector('[data-id="confirmInput"]').value && this.validationError == false) {    
                        samePass.classList.remove("invalid");
                        samePass.classList.add("valid");
                        this.validationErrorConfirm = false;
                    }else{
                        samePass.classList.remove("valid");
                        samePass.classList.add("invalid");
                        this.validationErrorConfirm = true;
                    }
                }
                break;
                
            case 'confirmInput':
                this.textConfValue = evt.target.value;
                if (this.template.querySelector('[data-id="newInput"]').value === evt.detail.value && this.template.querySelector('[data-id="newInput"]').value != '') {    
                    samePass.classList.remove("invalid");
                    samePass.classList.add("valid");
                    this.validationErrorConfirm = false;
                }else{
                    samePass.classList.remove("valid");
                    samePass.classList.add("invalid");
                    this.validationErrorConfirm = true;
                }
            break
        }
    }

    handleNext() {
        if(this.validationError == false && this.validationErrorConfirm == false){
            this.omniUpdateDataJson(this.template.querySelector('[data-id="newInput"]').value);
            this.omniNextStep();
        }else{
            if (this.validationError == true) {
                this.template.querySelector('[data-id="newInput"]').classList.add('slds-has-error-cus')
                this.template.querySelector('[data-id="newInput"]').classList.add('vibrate-1')
                setTimeout(() => {
                    this.template.querySelector('[data-id="newInput"]').classList.remove('vibrate-1')
                }, 500);
            }else{
                this.template.querySelector('[data-id="newInput"]').classList.remove('slds-has-error-cus')
            }
            if (this.validationErrorConfirm == true) {
                this.template.querySelector('[data-id="confirmInput"]').classList.add('slds-has-error-cus')
                this.template.querySelector('[data-id="confirmInput"]').classList.add('vibrate-1')
                setTimeout(() => {
                    this.template.querySelector('[data-id="confirmInput"]').classList.remove('vibrate-1')
                }, 500);
            }else{
                this.template.querySelector('[data-id="confirmInput"]').classList.remove('slds-has-error-cus')
            }
        }
    }

    handlePrev(){
        this.omniPrevStep();
    }

    handleFocus(evt){
        switch (evt.currentTarget.dataset.id) {
            case 'newInput':
                this.newPassFocus = true;
                this.blankSpace = false;
                break;
        
            case 'confirmInput':
                this.confirmPassFocus = true;
                this.blankSpace = false;
                break;
        }
    }

    passwordContainsUsername(username,password) {

        // Check if the password contains the account name
        if (password.toLowerCase().includes(username.split('@')[0].toLowerCase())) {
            return true;
        }

        // Check if the password contains parts of the full name exceeding two consecutive characters
        const fullName = username.split('@')[0].replace(/[0-9]/g, ''); // Remove any digits from the username
        for (let i = 0; i < fullName.length - 2; i++) {
            const substring = fullName.substring(i, i + 3);
            if (password.toLowerCase().includes(substring.toLowerCase())) {
                return true;
            }
        }
        return false;
    }
}