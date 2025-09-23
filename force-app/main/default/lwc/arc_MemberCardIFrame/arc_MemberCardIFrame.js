import { LightningElement, track, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import pubsub from 'vlocity_ins/pubsub';
export default class Arc_MemberCardIFrame extends OmniscriptBaseMixin(LightningElement) {
    
    jsonData;
    @track cardURL;
    @track sendingMethod; 
    sendingMethodValue; 
    @api omniJsonData;


    connectedCallback(){
        this.jsonData = JSON.parse(JSON.stringify(this.omniJsonData));
        console.log('json data: ', this.jsonData); 
        this.sendingMethod = this.omniJsonData.RAD_SendingMethod;
        console.log('this.sendingMethod: ', this.sendingMethod);
        this.redirectIframe();
    }

    renderedCallback(){
        pubsub.register('omniscript_step', { data: this.handleOmniAction.bind(this), }); 
    }

    handleOmniAction(data){
        console.log('Refresh Card');
        console.log('json data refresh: ', data); 
        console.log('sending method after click: ', this.sendingMethod); 
        if (this.sendingMethodValue != data.sendingMethod ){
            this.redirectIframe(); 
        }
    }

    redirectIframe() {
        this.cardURL = "";
        let url = 'https://'+  window.location.hostname +'/';
        let urlToReturn;

        if(url != null) {
            if(this.jsonData.userProfile == "Member Community" ) {
                if(this.jsonData.isProduction){
                    urlToReturn = this.jsonData.iframeHostURLCommunityProduction;
                } else {
                    urlToReturn = this.jsonData.iframeHostURLCommunity;
                }
            } else {
                if(this.jsonData.isProduction) {
                    urlToReturn = this.jsonData.iframeHostURLProduction;
                } else {
                   urlToReturn = this.jsonData.iframeHostURLSalesforce;  
                }
            }
            if ( this.jsonData.UHSM_Member_ID_Card ) {
                this.cardURL =  urlToReturn + this.jsonData.UHSM_Member_ID_Card;
			} else if ( this.jsonData.Access_Member_ID_Card) {
				this.cardURL =  urlToReturn + this.jsonData.Access_Member_ID_Card;
            } else if ( this.jsonData.WeShare_Member_ID_Card ) {
                this.cardURL =  urlToReturn + this.jsonData.WeShare_Member_ID_Card;
            } else if ( this.jsonData.Legacy_Member_ID_Card ) {
                this.cardURL =  urlToReturn + this.jsonData.Legacy_Member_ID_Card;
            }
            else if (this.jsonData.Proof_Of_Membership_Letter){
                this.cardURL =  urlToReturn + this.jsonData.Proof_Of_Membership_Letter;
            }
            console.log(JSON.stringify(this.cardURL));
        }
    }
}