import OmniscriptStepChart from 'vlocity_ins/omniscriptStepChart';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import tmpl from './aRC_OSCommunicator.html';


export default class aRC_OSCommunicator extends OmniscriptBaseMixin(OmniscriptStepChart) {
	connectedCallback() {
		super.connectedCallback();
		window.addEventListener('header-step-click', (e) => this.onHeaderStepChartNavigation(e));
    }

	disconnectedCallback() {
		super.disconnectedCallback();
		window.removeEventListener('header-step-click', (e) => this.onHeaderStepChartNavigation(e));
	}

	onHeaderStepChartNavigation(e){
		this.omniNavigateTo(e.detail.index)
	}

    // 1) first paint – jsonDef exists but chart props don’t
    renderedCallback() {
        super.renderedCallback();
        this.postStepUpdate();          // now stepChartProps is ready
    }

    // 2) every time OmniScript moves to a new step
    handleStepChange(...args) {
        super.handleStepChange(...args);
        this.postStepUpdate();
    }

    postStepUpdate() {
        // Send step update notification only if moved to another step
        // if((this.lastStepIndex != undefined && this.lastStepIndex == this.currentIndex) || (this.stepDef && this.stepCount == this.stepDef?.length || 0)) return
        this.lastStepIndex = this.currentIndex
        this.stepCount = this.stepDef.length || 0
        window.dispatchEvent(
            new CustomEvent('omni-step-chart', {
                detail: {
                    jsonDef: this.jsonDef, // Full OS JSON
                    stepDef: this.stepDef, // Step info
                    currentIndex: this.currentIndex // Current element active index (not step, element in OS timeline)
                }
            })
        );
    }

    render(){
        return tmpl;
    }
}