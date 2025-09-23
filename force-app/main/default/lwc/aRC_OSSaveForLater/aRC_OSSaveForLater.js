// Replace the omniscriptStep component instead
import OmniscriptStep from 'vlocity_ins/omniscriptStep';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class YourCustomStep extends OmniscriptBaseMixin(OmniscriptStep) {
	connectedCallback() {
		super.connectedCallback();
        console.log('Custom Step Connected');
        window.addEventListener('header-save-for-later', (e) => this.handleSaveForLater(e));
    }

	disconnectedCallback() {
		super.disconnectedCallback();
		window.removeEventListener('header-save-for-later', (e) => this.handleSaveForLater(e));
	}

    handleSaveForLater(e) {
        console.log("HEHHE")
        this.handleSaveForLater(e);
    }
}