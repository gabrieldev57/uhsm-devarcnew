import { LightningElement, track, wire } from 'lwc';
import resetPassword from "@salesforce/apex/ARC_CommunityController.resetPasswordController";
import decryptText from "@salesforce/apex/ARC_EncryptionHelper.decryptText";
import validateLink from "@salesforce/apex/ARC_ExpirationLinksController.validateLink";
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import WESHARE_LOGO from "@salesforce/resourceUrl/WeShareLogo";
import getCommunityURL from "@salesforce/apex/ARC_CommunityController.getCommunityURL";


export default class ARC_CommunityResetPassword extends NavigationMixin(LightningElement) {

	@track showPasswordInput = true;
	@track showConfirmInput = true;
	@track newPassFocus = false;
	@track formValues = {};
	@track formValidations = {
		password: false,
		password_confirm: false,
		old_password: true
	};
	showSpinner = false;
	disableButton = true;
	disableComponent = !true;
	@track imageUrls = { enabledCheckboxUrl: null, disabledCheckboxUrl: null, weShareLogoUrl: WESHARE_LOGO }
	userId = '';

	get renderPasswordInput() {
		return this.showPasswordInput;
	}

	get renderConfirmInput() {
		return this.showConfirmInput;
	}

	@wire(CurrentPageReference)
	async getURLParameters(currentPageReference) {
		if(currentPageReference){
			this.userId = await decryptText({'encryptedString': decodeURIComponent(currentPageReference.state?.id).replaceAll(' ','+')});
			const response = await validateLink({ 'userId': this.userId });
			if (response?.success == true) {
				this.disableComponent = !false;
			} else {
				this.navigateToCommunityPage('LinkExpiredOrUnavailable__c');
			}
		}
	}

	@wire(getCommunityURL)
	getCommunityURL({ data: communityURL }) {
		if (communityURL) {
			this.imageUrls.enabledCheckboxUrl = "https://" + communityURL + "/img/iconCheckEnabled.png";
			this.imageUrls.disabledCheckboxUrl = "https://" + communityURL + "/img/iconCheckDisabled.png";
		}
	}

	handleInputChange({ target: { dataset: { key }, value } }) {
		this.formValues[key] = value;
		if (key == 'password') {
			this.validatePassword(this.formValues.password);
		}

		if (key == 'password' || key == 'password_confirm') {
			this.validatePasswordConfirmation(this.formValues.password, this.formValues.password_confirm);
		}

		this.disableButton = this.validateAllInputs(this.formValidations);
	}


	async handleSubmitButton() {
		this.showSpinner = true;
		const response = await resetPassword({formValues:{'userId': this.userId, 'password': this.formValues.password}})
		if (response?.success) {
			this.navigateToWebPage(response.loginURL);
		}
		else if (response?.message.includes('repeated password')) {
			this.showSpinner = false;
			this.formValidations.old_password = false;
			this.disableButton = true;
		}
	}

	handleChangeType({ target: { dataset: { id } } }) {
		// Find the input element using the key
		let htmlElement = this.template.querySelector(`input[data-key=${id}]`);

		// Toggle between "text" and "password" for the input type
		htmlElement.type = htmlElement.type === 'text' ? 'password' : 'text';
	}


	//Performs the validations of the password and confirmation password fields.
	validatePassword(password) {
		this.formValidations.password = true;
		this.formValidations.old_password = true;
		//Validations HTML
		let lowercase = this.template.querySelector('[data-id="lowercase"]');
		let uppercase = this.template.querySelector('[data-id="uppercase"]');
		let number = this.template.querySelector('[data-id="number"]');
		let special = this.template.querySelector('[data-id="special"]');
		let length = this.template.querySelector('[data-id="length"]');

		//Validations Regular Expressions
		this.validateRule(password, lowercase, /[a-z]/g);
		this.validateRule(password, uppercase, /[A-Z]/g);
		this.validateRule(password, number, /[0-9]/g);
		this.validateRule(password, length, /.{8,}/);
		this.validateRule(password, special, /[!@#$%^&*_=+\-~(){}|;:'",<.>?\/\[\]\\]/g);
	}

	//Updates the invalid/valid class based on the rules passed.
	validateRule(password, validation, regExp) {
		if (password.match(regExp)) {
			validation.src = this.imageUrls.enabledCheckboxUrl;
		}
		else {
			this.formValidations.password = false;
			validation.src = this.imageUrls.disabledCheckboxUrl;
		}
	}

	//Validates if the password and confirmation passsword match.
	validatePasswordConfirmation(password, passwordConfirmation) {

		if (password == passwordConfirmation) {
			this.formValidations.password_confirm = true;
			this.template.querySelector('img[data-id="password_confirm"]').src = this.imageUrls.enabledCheckboxUrl;

		} else if (passwordConfirmation != null && password != passwordConfirmation) {
			this.template.querySelector('img[data-id="password_confirm"]').src = this.imageUrls.disabledCheckboxUrl;

			this.formValidations.password_confirm = false;
		}
	}

	validateAllInputs(formValidations) {
		for (const key in this.formValidations) {
			if (formValidations[key] != true) {
				return true;
			}
		}
		return false;
	}

	navigateToWebPage(page) {
		window.location.href = page;
	}

	//Redirect the user to a community page. 
	navigateToCommunityPage(api_page) {
		this[NavigationMixin.Navigate]({
			type: "comm__namedPage",
			attributes: {
				name: api_page
			}
		});
	}

}