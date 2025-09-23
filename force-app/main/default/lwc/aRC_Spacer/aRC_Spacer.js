import { LightningElement, api, track} from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';

import TopbarResources from '@salesforce/resourceUrl/ARC_TopbarResources';


export default class SimpleSpacer extends LightningElement {
    @api size = "";
    @api sizeM = "";
    @api sizeS = "";
    @api direction;

    @track negativeSpacer = false
    @track spacerSize;
    
    connectedCallback(){
        loadStyle(this, TopbarResources + '/spacer.css')
    }

    renderedCallback(){
        this.refs.spacer.style.setProperty('--spacer-size', this.size);
        this.refs.spacer.style.setProperty('--spacer-size-m', this.sizeM !== "" ? this.sizeM : this.size);
        this.refs.spacer.style.setProperty('--spacer-size-s', this.sizeS !== "" ? this.sizeS : this.size);

        // Detect if the spacer is negative
        const computedStyle = window.getComputedStyle(this.refs.spacer);
        this.spacerSize = computedStyle.getPropertyValue('--spacer-size');
        if(parseInt(this.spacerSize) < 0) this.negativeSpacer = true
        else this.negativeSpacer = false
    }
}