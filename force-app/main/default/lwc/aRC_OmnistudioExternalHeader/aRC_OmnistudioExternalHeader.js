import { LightningElement, wire, api, track } from "lwc";
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';

import OSResources from '@salesforce/resourceUrl/ARC_OSResources'


export default class aRC_OSCustomHeader extends NavigationMixin(LightningElement) {
	@api overrideTitle;
	@track stepDef;


	// Header background image
	backgroundImage = OSResources + '/header-background.png'
	// Product background image
	productBackgroundImage = OSResources + '/product-background.png'
	productBackgroundImageTwo = OSResources + '/product-background-2.png'
	productBackgroundImageThree = OSResources + '/product-background-3.png'


	///////////////////////////////////////////////////////////////////
	// MARK: Conn & Rend
	///////////////////////////////////////////////////////////////////
    connectedCallback() {
        window.addEventListener('omni-step-chart', (evt) => this.handleStepUpdate(evt));
		loadStyle(this, OSResources + '/OSWithCustomHeader.css')
	}
    disconnectedCallback() {
        window.removeEventListener('omni-step-chart', (evt) => this.handleStepUpdate(evt));
    }
	renderedCallback(){
		this.refs.header.style.setProperty("--bg-image", `url(${this.backgroundImage})`)
		this.refs.css.innerHTML = `
		<style>
			body{
				--product-bg-image: url(${this.productBackgroundImage});
				--product-bg-image-2: url(${this.productBackgroundImageTwo});
				--product-bg-image-3: url(${this.productBackgroundImageThree});
			}
		</style>
		`
	}

	///////////////////////////////////////////////////////////////////
	// MARK: PageRef Wire
	///////////////////////////////////////////////////////////////////
    currentPageRef;

	get bIsInExperienceBuilder(){
		return window.location.search.includes("view=editor")
			|| window.location.search.includes("picasso/core/config")
	}

    // always have the latest PageReference
    @wire(CurrentPageReference)
    setPageRef(pr) {
        this.currentPageRef = pr;
		// If this LWC is running on Experience builder, ignore this logic
		if(this.bIsInExperienceBuilder) return
		// If URL changed by step update, don't do anything else
		if(this.urlChangesFromStepUpdate) return this.urlChangesFromStepUpdate = false
		
		// If URL changed from browser history
        let stepLabelFromURL = pr.state?.c__step?.replaceAll("-_-", " ");
        if (this.stepUpdated && stepLabelFromURL && stepLabelFromURL !== this.lastStepLabel) {
			let stepIndex = this.stepDef.findIndex(o => o.propSetMap.label)
			if(stepIndex != -1) this.navigateOmniscriptToStep({currentTarget: {dataset: {index: stepIndex}}})
        }
    }
    lastActiveIndex = -1
	processURL(){
		// If this LWC is running on Experience builder, ignore this logic
		if(this.bIsInExperienceBuilder) return
		// If step hasn't changed, return
		if(this.lastStepLabel == this.currentStepLabel) return

		// Send GTAG event of finished step
		if(this.previousActiveIndex != undefined && !this.stepDef[this.previousActiveIndex].isEditing) this.gtagStepFinished(this.stepDef[this.previousActiveIndex])

		// Time when this step started
        this.stepStartTime = Date.now();
		// Send GTAG event on viewed step
		this.gtagStepViewed(this.stepDef[this.activeIndex])

		// Set URL parameter and push to history
		this.urlChangesFromStepUpdate = true
        const target = {
			...this.currentPageRef,
            state: { ...this.currentPageRef.state, c__step: this.currentStepLabel.replaceAll(" ", "-_-") }
        };
        this[NavigationMixin.Navigate](target); // pushes new history entry
		
		// Window datalayer
		window.dataLayer = window.dataLayer || [];
		window.dataLayer.push({
			event: 'formStep',
			stepName: this.headerTitle
		});
		console.log("PROCESS URL FINISHED")
	}

	gtagStepViewed(step) {
		// if (typeof window.gtag !== 'function') return;

		// Prevent this running multiple times on a single step change
		if(this.debounceStepViewed) return
		this.debounceStepViewed = true
		setTimeout(() => {
			this.debounceStepViewed = false;
		}, 100);
		
        // Use dataLayer instead of gtag (more reliable in Salesforce)
        if (typeof window.dataLayer === 'undefined') {
			console.warn('dataLayer not found');
            return;
        }

		let stepName = step.propSetMap.chartLabel
		const virtualPath = `${window.location.pathname}?step=${stepName}`;
		console.log(`GTAG SENDING ON VIEW: ${window.location.origin}${virtualPath}`)
		
		// // Built-in page_view event - works immediately
		// window.gtag('event', 'page_view', {
		// 	page_title: `OmniScript - ${stepName}${ + (step.isEditing ? " (Edit)" : "")}`,
		// 	page_location: `${window.location.origin}${virtualPath}`,
		// 	page_path: virtualPath
		// });
			
        // Push virtual page view to dataLayer
        window.dataLayer.push({
			event: 'virtual_page_view',
            page_title: `OmniScript - ${step.propSetMap.chartLabel + (step.isEditing ? " (Edit)" : "")}`,
            page_location: `${window.location.origin}${virtualPath}`,
            page_path: virtualPath,
            step_name: step.propSetMap.chartLabel + (step.isEditing ? " (Edit)" : ""),
        });
	}

	gtagStepFinished(step, currentStep) {
		// if (typeof window.gtag !== 'function') return;

		// Prevent this running multiple times on a single step change
		if(this.debounceStepFinished) return
		this.debounceStepFinished = true
		setTimeout(() => {
			this.debounceStepFinished = false;
		}, 100);

        // Use dataLayer instead of gtag (more reliable in Salesforce)
        if (typeof window.dataLayer === 'undefined') {
            console.warn('dataLayer not found');
            return;
        }

		console.log(`GTAG SENDING ON COMPLETE: ${step.propSetMap.chartLabel + (step.isEditing ? " (Edit)" : "")}`)
		
		const timeSpentSeconds = Math.round((Date.now() - this.stepStartTime) / 1000);

		// // Built-in select_content event - good for step interactions
		// window.gtag('event', 'select_content', {
		// 	content_type: 'omniscript_step',
		// 	content_id: step.propSetMap.chartLabel + (step.isEditing ? " (Edit)" : ""),
		// 	value: timeSpentSeconds  // Built-in parameter for numeric value
		// });

		// // Built-in user_engagement event - designed for engagement time
		// window.gtag('event', 'user_engagement', {
		// 	engagement_time_msec: timeSpentSeconds * 1000
		// });

        // Push step completion to dataLayer
        window.dataLayer.push({
            event: 'step_completed',
            event_category: 'OmniScript',
            event_label: step.propSetMap.chartLabel + (step.isEditing ? " (Edit)" : ""),
            step_duration_seconds: timeSpentSeconds,
            step_name: step.propSetMap.chartLabel + (step.isEditing ? " (Edit)" : ""),
            value: timeSpentSeconds
        });

        // Also push engagement time
        window.dataLayer.push({
            event: 'user_engagement',
            engagement_time_msec: timeSpentSeconds * 1000,
            step_name: step.propSetMap.chartLabel + (step.isEditing ? " (Edit)" : ""),
        });
		
	}
    // handlePopState(e){
    //     const state = e.state;
    //     if (state && typeof state.stepIndex === 'number') {
    //         const stepChart = this.template.querySelector('c-omniscript-step-chart');
    //         if (stepChart?.navigateToStep) {
    //             stepChart.navigateToStep(state.stepIndex);
    //         }
    //     }
    // };

	///////////////////////////////////////////////////////////////////
	// MARK: Header
	///////////////////////////////////////////////////////////////////
	@track headerTitle = ""
	get sHeaderTitle(){
		return this.overrideTitle || this.headerTitle
	}


	processHeader(){
		// If step hasn't changed, return
		if(this.lastStepLabel == this.currentStepLabel) return

		// Set header title
		this.headerTitle = this.currentStepLabel

		setTimeout(() => {
			// Center step-chart scrolling on active step
			let activeElement = this.refs.stepChart.getActiveElement()
			if(this.refs.stepChart) this.refs.stepChartScroll.scrollToElement(activeElement)
		}, 100);
	}

	///////////////////////////////////////////////////////////////////
	// MARK: On Step Updt
	///////////////////////////////////////////////////////////////////
	handleStepUpdate(evt){
		if (evt.type !== 'omni-step-chart') return;
		this.stepUpdated = true // Track if step was updated at least once

		let { jsonDef, stepDef, currentIndex } = evt.detail

		// Find and store current step label
		this.previousActiveIndex = this.activeIndex
        this.activeIndex = stepDef.findLastIndex(o => o.bAccordionActive == true) // Find current step index
		if(this.activeIndex == -1) return // Stop if no step is active

		// Before setting new steps, set which steps where completed before current one
        let value = JSON.parse(JSON.stringify(stepDef))
		value.forEach((step, index) => {
			var stepStatus = "pristine" // Default, non-touched step
            if(index == this.activeIndex) stepStatus = "active" // If step is currently shown
            else if(index < this.activeIndex) stepStatus = "completed" // If step is before current
            else if(step.bInit) stepStatus = "nonpristine" // If step was shown but user went back
            step.status = stepStatus
			// Track if the user went back and is editing step, for GTAG
			if(this.lastActiveIndex > index) step.isEditing = true
        });

		this.stepDef = value // STEPS data
		console.log(this.activeIndex)
		console.log(JSON.parse(JSON.stringify(this.stepDef)))

		this.currentStepLabel = this.stepDef[this.activeIndex].propSetMap.label
		// Update visuals
		this.processURL() // Push to history
		this.processHeader() // Update visuals
		// Save index of last step completed
        if(this.activeIndex >= this.lastActiveIndex) this.lastActiveIndex = this.activeIndex
		// After comparing to previous label, update previous label to current one
		this.lastStepLabel = this.currentStepLabel

		if(this.refs.stepChartScroll) this.refs.stepChartScroll.recheckOverflow()
	}

	///////////////////////////////////////////////////////////////////
	// MARK: Navigate Step
	///////////////////////////////////////////////////////////////////
	get goBackLabel(){
		// return this.activeIndex > 0 && this.stepDef[this.activeIndex].propSetMap.previousLabel
		return this.activeIndex > 0 && this.stepDef[this.activeIndex].propSetMap.previousLabel && this.stepDef[this.activeIndex].propSetMap.previousWidth
	}
	get bCanSave(){
		return this.activeIndex > 0 && this.stepDef[this.activeIndex].propSetMap.allowSaveForLater && this.stepDef[this.activeIndex].propSetMap.saveLabel
	}
	get bShowActionBar(){
		return this.goBackLabel || this.bCanSave
	}

	navigateOmniscriptToStep(e){
		// Prevent navigating from history to a step ahead of current
		if(e.currentTarget.dataset.index >= this.activeIndex) return

		// Navigate to previous steps on dot click or history
		window.dispatchEvent(
			new CustomEvent('header-step-click', {
				detail: { 
					index: this.stepDef[e.currentTarget.dataset.index].indexInParent
				}
			})
		);
	}

	handleDotBack(e){
		if(!this.goBackLabel) return
		this.navigateOmniscriptToStep({currentTarget: {dataset: {index: e.detail.index}}})
	}
	handleBack(e){
		if(!this.goBackLabel) return
		this.navigateOmniscriptToStep({currentTarget: {dataset: {index: this.activeIndex - 1}}})
	}
	
	// ///////////////////////////////////////////////////////////////////
	// // MARK: Save for Later
	// ///////////////////////////////////////////////////////////////////
	// handleSaveForLater(e){
	// 	// Fire save for later event
	// 	window.dispatchEvent(
	// 		new CustomEvent('header-save-for-later', {
	// 			detail: {index: 0}
	// 		})
	// 	);
	// }
}