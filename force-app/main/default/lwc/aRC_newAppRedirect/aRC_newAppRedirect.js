import { LightningElement } from 'lwc';

export default class ARC_newAppRedirect extends LightningElement {

        connectedCallback() {
        const host = window.location.hostname;
        const isBuilder = host.includes('live-preview');


        if (isBuilder) {    
            console.log('Redirect disabled in Builder mode');
            return;
        }

        if (host.includes('sandbox')) {
            window.location.replace('https://enroll-uat.weshare.org');
        } else {
            window.location.replace('https://enroll.weshare.org');
        }
    }


}