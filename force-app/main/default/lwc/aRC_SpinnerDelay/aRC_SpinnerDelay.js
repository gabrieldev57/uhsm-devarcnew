import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';


export default class ARC_SpinnerDelay extends OmniscriptBaseMixin(LightningElement) {
  @api delay = 10000;

  connectedCallback() {
    setTimeout(() => {
      this.omniNextStep();
    }, this.delay);
  }
}