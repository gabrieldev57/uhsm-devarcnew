import { LightningElement, track } from "lwc";

import OSResources from '@salesforce/resourceUrl/ARC_OSResources'
import Id from '@salesforce/user/Id'; //gets Id of running user
import isGuest from '@salesforce/user/isGuest'; //true if unauthenticated, otherwise false



export default class Arc_externalheaderfran extends LightningElement {
	@track title = ""

	backgroundImage = OSResources + '/header-background.png'

    connectedCallback() {
        console.log('debug 1');

        console.log('debug 1.2');
        this.handleStepUpdate = evt => {
            if (evt.type !== 'omni-step-chart') return;

			let { jsonDef, stepDef, currentIndex } = evt.detail

			this.chartSteps = stepDef
			this.processHeader()
        };
        window.addEventListener('omni-step-chart', this.handleStepUpdate.bind(this));
        //build the event detail object in a structure that works for Google Analytics 
    let payload = { detail: 
        { 
            'user_id': Id, 
            'user_properties': {
                'user_id': Id,
                'user_type': (isGuest) ? 'Unauthenticated' : 'Authenticated',
                'account_rating': 'Silver'
            }
        }
    };
    //publish custom event for the listener in the head markup to handle
    document.dispatchEvent(new CustomEvent('analyticsSupport', payload));
		
    }
    disconnectedCallback() {
        console.log('debug 2');
        window.removeEventListener('omni-step-chart', this.handleStepUpdate.bind(this));
    }

	renderedCallback(){
        console.log('debug 3 ');
		this.refs.header.style.setProperty("--bg-image", `url(${this.backgroundImage})`)
	}

	processHeader(){
        document.addEventListener("updateGTMdataLayer", function(e) {
            console.log("Evento recibido:", e.detail.event);
            // Acá podés hacer, por ejemplo, un push al dataLayer de GTM
            window.dataLayer.push({ event: e.detail.event });
        });
        console.log('debug 4 ');
		this.chartSteps.forEach(step => {
			if(step.bAccordionActive){
				this.title = step.propSetMap.label
			}
		});
        console.log('debug 5 ');
        try {
            if (window.dataLayer && Array.isArray(window.dataLayer)) {
                window.dataLayer.push({
                    event: 'formStep',
                    stepName: 'Step inicial'
                });
                console.log('Evento empujado a dataLayer');
            } else {
                console.warn('dataLayer no está definido aún');
            }
        } catch (error) {
            console.error('Error al empujar evento a dataLayer:', error);
        }
            
	}
    

	testNavigation(e) {
		window.dispatchEvent(
			new CustomEvent('header-step-click', {
				detail: { 
					index: 0
				}
			})
		);
	}
}