import { LightningElement, track, wire } from 'lwc';
import setUsernameAndPasswordController from "@salesforce/apex/ARC_CommunityController.setUsernameAndPasswordController";
import decryptText from "@salesforce/apex/ARC_EncryptionHelper.decryptText";
import validateUsername from "@salesforce/apex/ARC_CommunityController.validateUsername";
import getCommunityURL from "@salesforce/apex/ARC_CommunityController.getCommunityURL";
import validateLink from "@salesforce/apex/ARC_ExpirationLinksController.validateLink";
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import WESHARE_LOGO from "@salesforce/resourceUrl/WeShareLogo";

export default class ARC_CommunitySetUsernamePassword extends NavigationMixin(LightningElement) {
	@track formValues = {};
	@track formValidations = {
		username_availability: true,
		username_format: true,
		password: false,
		password_confirm: false,
		old_password: true
	};
	showSpinner = false;
	disableComponent = !true;
	disableButton = true;
	userId = null;
	communityURL;
	@track imageUrls = { enabledCheckboxUrl: null, disabledCheckboxUrl: null, weShareLogoUrl: WESHARE_LOGO }


	@wire(CurrentPageReference)
	async getURLParameters(currentPageReference) {
		if(currentPageReference){
			// console.log('currentPageReference ',currentPageReference);
			// console.log('decrypt Test ',decodeURIComponent(currentPageReference.state?.id).replaceAll(' ','+'));
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
		// console.log(communityURL);
		if (communityURL) {
			this.imageUrls.enabledCheckboxUrl = "https://" + communityURL + "/img/iconCheckEnabled.png";
			this.imageUrls.disabledCheckboxUrl = "https://" + communityURL + "/img/iconCheckDisabled.png";
		}
	}

	//Updates the formValues object with the key of the field and the value of the field.
	handleInputChange({ target: { dataset: { key }, value } }) { //event.target.dataset.key and event.target.value destructured into variables
		// console.log(this.imageUrls.disabledCheckboxUrl)
		// console.log(this.imageUrls.enabledCheckboxUrl)
		this.formValues[key] = value;
		if (key == 'password') {
			this.validatePassword(this.formValues.password);
		}
		if (key == 'password' || key == 'password_confirm') {
			this.validatePasswordConfirmation(this.formValues.password, this.formValues.password_confirm);
		}

		if (key == 'username') {
			this.validateUsernameFormat(this.formValues.username);
		}

		this.disableButton = this.validateAllInputs(this.formValidations);
	}

	//Called when form is submitted
	async handleSubmitButton() {
		this.showSpinner = true;
		let response = await this.validateUsernameAvailability(this.formValues.username);
		// Validate Username is Available
		if (response.success == false) {
			this.showSpinner = false;
			this.formValidations.username_availability = false;
			this.disableButton = true;
			return;
		}

		// Validate Password is not the same as old password
		response = await setUsernameAndPasswordController({ 'formValues': { ...this.formValues, 'userId': this.userId } });
		if (response.success == false && response.message.includes('repeated password')) {
			this.showSpinner = false;
			this.formValidations.old_password = false;
			this.disableButton = true;
			return;
		}

		this.navigateToWebPage(response.loginURL);
	}

	validateUsernameFormat(username) {
		const regExp = /^[a-zA-Z0-9\-_\.@]{8,30}$/ // No spaces allowed, 8 to 30 letters, numbers, or - _ . @
		// console.log('username =>', username);
		// console.log('!regExp.test(username) =>', !regExp.test(username));
		if (regExp.test(username)) {
			this.formValidations.username_format = true;
			this.formValidations.username_availability = true;
		} else if (username && username?.length >= 8 && !regExp.test(username)) {
			this.formValidations.username_format = false;
		}
	}

	//Validates password basic requirements are met against regular expression (N° characters,numbers,symbols,etc)
	validatePassword(password) {
		this.formValidations.password = true;
		this.formValidations.old_password = true;

		let lowercase = this.template.querySelector('img[data-id="lowercase"]');
		let uppercase = this.template.querySelector('img[data-id="uppercase"]');
		let number = this.template.querySelector('img[data-id="number"]');
		let special = this.template.querySelector('img[data-id="special"]');
		let length = this.template.querySelector('img[data-id="length"]');

		this.validateRule(password, lowercase, /[a-z]/g); // Lowercase letters
		this.validateRule(password, uppercase, /[A-Z]/g); // Upperscase letters
		this.validateRule(password, number, /[0-9]/g); // Numbers
		this.validateRule(password, special, /[!@#$%^&*_=+\-~(){}|;:'",<.>?\/\[\]\\]/g); // Special Characters
		this.validateRule(password, length, /.{8,}/); // Length 8
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

	//Validates password confirmation matches original password
	validatePasswordConfirmation(password, passwordConfirmation) {

		if (password == passwordConfirmation) {
			this.formValidations.password_confirm = true;
			this.template.querySelector('img[data-id="password_confirm"]').src = this.imageUrls.enabledCheckboxUrl;

		} else if (passwordConfirmation != null && password != passwordConfirmation) {
			this.template.querySelector('img[data-id="password_confirm"]').src = this.imageUrls.disabledCheckboxUrl;

			this.formValidations.password_confirm = false;
		}
	}

	//Validates ARC_PortalUsername__c does not exist already in the org
	async validateUsernameAvailability(username) {
		let response = await validateUsername({ 'username': username });
		return response;
	}

	validateAllInputs(formValidations) {
		// console.log('this.formValidations =>', JSON.parse(JSON.stringify(formValidations)));
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
	navigateToCommunityPage(api_name) {
		this[NavigationMixin.Navigate]({
			type: "comm__namedPage",
			attributes: {
				name: api_name
			}
		});
	}

	handleChangeType({ target: { dataset: { id } } }) {
		// Find the input element using the key
		let htmlElement = this.template.querySelector(`input[data-key=${id}]`);

		// Toggle between "text" and "password" for the input type
		htmlElement.type = htmlElement.type === 'text' ? 'password' : 'text';
	}

	// @wire(decryptText, { 'encodedEncryptedData': 'test' })
	// decryptText(text) {
	// 	return decryptText({ 'encodedEncryptedData': text }).then(result => { return result });
	// }

}