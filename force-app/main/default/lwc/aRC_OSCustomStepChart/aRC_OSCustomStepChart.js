import { LightningElement, api, track } from "lwc";


export default class aRC_OSCustomStepChart extends LightningElement {
	// MARK: Steps data
	@api
	get stepDef(){
		return this._stepDef
	}
	set stepDef(value){
		console.log("SETTED STEPDEF")
		value = JSON.parse(JSON.stringify(value)) // Clone the array
		let activeIndex = value.findIndex(o => o.bAccordionActive = true) // Find current step index
		// Before setting new stepDef, set which steps where completed before current one
		value.forEach((step, index) => {
			var stepStatus = "pristine" // Default, non-touched step
			if(step.bAccordionActive) stepStatus = "active" // If step is currently shown
			else if(index < activeIndex) stepStatus = "completed" // If step is before current
			else if(step.bInit) stepStatus = "nonpristine" // If step was shown but user went back
			step.status = stepStatus
		});
		// Set stepDef
		this._stepDef = value;
		console.log(JSON.parse(JSON.stringify(this._stepDef)))
		console.log(JSON.parse(JSON.stringify(this.stepDef)))
		// Update progress bar
		this.calculateProgressBar(activeIndex)
	}

	@track _stepDef = []

	afterEveryStepDefSet(){

	}

	// MARK: Progress Bar
	@track stepProgressValue = 0
	calculateProgressBar(activeIndex){
		this.stepProgressValue = (activeIndex/this.stepDef.length)*100
	}
}