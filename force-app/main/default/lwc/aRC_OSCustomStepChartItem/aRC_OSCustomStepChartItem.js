import { LightningElement, api } from "lwc";

import OSResources from "@salesforce/resourceUrl/ARC_OSResources"


export default class aRC_OSCustomStepChartItem extends LightningElement {
	@api step


	iconCheck = OSResources + "/check.svg#svg"

	get bIsPristine(){
		return this.step.status == "pristine"
	}
	get bIsActive(){
		return this.step.status == "active"
	}
	get bIsCompleted(){
		return this.step.status == "completed"
	}
	get bIsNonPristine(){
		return this.step.status == "nonpristine"
	}

	///////////////////////////////////////////////////////////////////
	// MARK: Navigate
	///////////////////////////////////////////////////////////////////
	handleStepClick(e){
		window.dispatchEvent(
			new CustomEvent('header-step-click', {
				detail: { 
					index: this.step.indexInParent
				}
			})
		);
	}
}