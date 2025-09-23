import { LightningElement } from 'lwc';

export default class ARC_BackToTop extends LightningElement {
    handleClick() {
        window.scrollTo({
            left: 0,
            top: 0,
            behavior: 'smooth'});
    }
}