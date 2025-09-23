import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ARC_CreateUserInternal extends OmniscriptBaseMixin(LightningElement) {

	@api recordId;
	user; // Boolean, set to true if the person account has a user already created, else false.
	usernameWasReset; // Boolean, set to true if the user already set the username in the community experience site, else false.
	// displayComponent = false;

	connectedCallback() {
		this.retrieveUserInfo()
	}


	async handleClick() {
		if (!this.user) {
			const { result: { createUser } } = await this.omniRemoteCall({ input: JSON.stringify({ 'personAccountId': this.recordId }), sClassName: 'ARC_CreateMemberUserGuest', sMethodName: 'createUserFromPersonAccount360', options: '{}', }, true);
			this.displaySuccessOrErrorMessage(createUser);
		}
		if (this.user && this.usernameWasReset == false) {
			const { result: { resetUsernameAndPassword } } = await this.omniRemoteCall({ input: JSON.stringify({ 'personAccountId': this.recordId }), sClassName: 'ARC_CreateMemberUserGuest', sMethodName: 'resetUsernameAndPassword360', options: '{}', }, true);
			this.displaySuccessOrErrorMessage(resetUsernameAndPassword);
		}

		this.retrieveUserInfo()
	}

	async retrieveUserInfo() {
		const { result: { user, usernameWasReset } } = await this.omniRemoteCall({ input: JSON.stringify({ 'personAccountId': this.recordId }), sClassName: 'ARC_CreateMemberUserGuest', sMethodName: 'checkPortalUsernameWasSet', options: '{}', }, true);
		this.usernameWasReset = usernameWasReset;
		this.user = user
	}

	displaySuccessOrErrorMessage(response) {
		if (response == null) return;
		let toastEvent = {};
		switch (response.success) {
			case true:
				toastEvent.title = 'Success'
				toastEvent.variant = 'success'
				break;
			case false:
				toastEvent.title = 'Error'
				toastEvent.variant = 'error'
				break;
		}

		toastEvent.message = response.message.toString();
		toastEvent.mode = 'sticky';

		const evt = new ShowToastEvent(toastEvent);
		this.dispatchEvent(evt);
	}

	showHelpText() {
		const helpText = this.template.querySelector('.custom-help-text');
		helpText.classList.remove('slds-hide');
	}

	hideHelpText() {
		const helpText = this.template.querySelector('.custom-help-text');
		helpText.classList.add('slds-hide');
	}

}