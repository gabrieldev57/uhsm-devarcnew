import { LightningElement } from 'lwc';

export default class aRC_PageChangeDetector extends LightningElement {

    connectedCallback(){
        const event = new Event('pageChange');
        window.dispatchEvent(event);
    }
}