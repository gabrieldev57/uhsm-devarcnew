import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ARC_ResetPasswordInternal extends OmniscriptBaseMixin(LightningElement) {

	@api recordId;
	async handlePasswordReset() {
		const params = {
			input: JSON.stringify({ 'personAccountId': this.recordId }),
			sClassName: 'ARC_CreateMemberUserGuest',
			sMethodName: 'resetPasswordPersonAccount',
			options: '{}',
		};

		const { result: { resetPassword } } = await this.omniRemoteCall(params, true);
		this.displaySuccessOrErrorMessage(resetPassword);
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