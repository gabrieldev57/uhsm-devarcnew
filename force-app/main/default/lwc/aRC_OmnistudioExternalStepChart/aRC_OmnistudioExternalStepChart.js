import { LightningElement, api, track } from 'lwc';

import OSResources from '@salesforce/resourceUrl/ARC_OSResources'


export default class aRC_OmnistudioExternalStepChart extends LightningElement {
    @api vertical = false;
    @api useLabels = false;

    iconCheck = OSResources + '/icon-check.svg#svg';

    // MARK: Steps data
    @api
    get steps(){
        return this._steps
    }
    set steps(value){
        value = JSON.parse(JSON.stringify(value)) // Clone the array
        this.activeIndex = value.findLastIndex(o => o.bAccordionActive == true) // Find current step index
        if(this.activeIndex >= this.lastActiveIndex) this.lastActiveIndex = this.activeIndex
        // Set steps
        this._steps = value;
        // Update progress bar
        this.updateProgressBar()
    }
    @track _steps = []

    renderedCallback(){
        // Apply styles required to override lightning-tooltip
        if(!this.isRendered){
            this.refs.styles.innerHTML = `<style>
                .ushm-step-chart lightning-helptext button{
                    cursor: default;
                    border: none !important;
                    box-shadow: none !important;
                }
                .ushm-step-chart [data-status="completed"] lightning-helptext button{
                    cursor: pointer;
                }
                .ushm-step-chart lightning-primitive-icon{
                    opacity: 0;
                }
            </style>`
        }
        this.isRendered = true

        this.updateProgressBar()
    }

    // MARK: Progress Bar
    lastActiveIndex = -1
    get bIsFirstStep(){
        return this.activeIndex == 0 && this.lastActiveIndex == -1
    }
    @track stepProgressValue = 0
    updateProgressBar(){
        if(!this.isRendered) return
        this.refs.container.style.setProperty("--step-count", this.steps.length)
        this.refs.container.style.setProperty("--current-step", this.activeIndex)
        this.refs.container.style.setProperty("--last-active-step", this.lastActiveIndex)

        // Get max height from labels to know how much margin to add to bottom
        // since labels are absolute and don't modify the container height
        this.processLabelHeights()
    }

    processLabelHeights(){
        let maxHeight = 0
        this.template.querySelectorAll(".ushm-sc-item-label").forEach(element => {
            if(element.offsetHeight > maxHeight) maxHeight = element.offsetHeight
        })
        this.refs.container.style.setProperty("--label-height", maxHeight+"px")
    }

    @api
    getActiveElement(){
        return this.template.querySelector('[data-status="active"]')
    }

	///////////////////////////////////////////////////////////////////
	// MARK: Navigate Step
	///////////////////////////////////////////////////////////////////
	navigateOmniscriptToStep(e){
		// Prevent navigating from history to a step ahead of current
		if(e.currentTarget.dataset.index >= this.activeIndex) return

		this.dispatchEvent(
			new CustomEvent('stepclick', {
				detail: { 
					index: e.currentTarget.dataset.index
				}
			})
		);
	}
}