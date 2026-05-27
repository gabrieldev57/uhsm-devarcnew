import { LightningElement, track, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import pubsub from 'vlocity_ins/pubsub';

export default class Arc_MemberCardIFrame extends OmniscriptBaseMixin(LightningElement) {
    @track cardURL;
    @track sendingMethod;

    _omniJsonData;
    jsonData;
    sendingMethodValue;

    @api
    get omniJsonData() {
        return this._omniJsonData;
    }
    set omniJsonData(value) {
        this._omniJsonData = value;
        this.jsonData = value ? JSON.parse(JSON.stringify(value)) : {};
        this.sendingMethod = this.jsonData?.RAD_SendingMethod;
        this.redirectIframe();
    }

    connectedCallback() {
        pubsub.register('omniscript_step', { data: this.handleOmniAction.bind(this) });
    }

    handleOmniAction(data) {
        if (this.sendingMethodValue !== data.sendingMethod) {
            this.jsonData = this.omniJsonData ? JSON.parse(JSON.stringify(this.omniJsonData)) : {};
            this.redirectIframe();
        }
    }

    redirectIframe() {
        try {
               this.cardURL = '';

        const isCommunitySite =
            window.location.pathname.includes('/employerportal') ||
            window.location.pathname.includes('/members') ||
            window.location.hostname.includes('.site.com');

        let urlToReturn;
        console.log('isCommunitySite:', window.location.pathname);
        const fullBaseUrl = window.location.origin + '/' + window.location.pathname.split('/')[1];
        if (isCommunitySite) {
            urlToReturn = fullBaseUrl + '/servlet/servlet.FileDownload?file=';
        } else {
            urlToReturn = this.jsonData?.isProduction
                ? this.jsonData?.iframeHostURLProduction
                : this.jsonData?.iframeHostURLSalesforce;
        }

        let fileId;
        if (this.jsonData?.UHSM_Member_ID_Card) {
            fileId = this.jsonData.UHSM_Member_ID_Card;
        } else if (this.jsonData?.Access_Member_ID_Card) {
            fileId = this.jsonData.Access_Member_ID_Card;
        } else if (this.jsonData?.WeShare_Member_ID_Card) {
            fileId = this.jsonData.WeShare_Member_ID_Card;
        } else if (this.jsonData?.Legacy_Member_ID_Card) {
            fileId = this.jsonData.Legacy_Member_ID_Card;
        } else if (this.jsonData?.Proof_Of_Membership_Letter) {
            fileId = this.jsonData.Proof_Of_Membership_Letter;
        }

        if (urlToReturn && fileId) {
            this.cardURL = urlToReturn + fileId;
        }

        console.log('json data:', this.jsonData);
        console.log('urlToReturn:', urlToReturn);
        console.log('fileId:', fileId);
        console.log('cardURL:', this.cardURL);
    }
         catch (error) {
            console.error('Error occurred while redirecting iframe:', error);
        }}
     
}