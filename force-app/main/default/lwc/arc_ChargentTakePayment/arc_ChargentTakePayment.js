import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
import { OmniscriptActionCommonUtil } from "vlocity_ins/omniscriptActionUtils";


export default class arc_ChargentTakePayment extends OmniscriptBaseMixin(LightningElement) {
    commurl = '';
    @track isCreditCard= false;
    gatewayForConsole;
    
    connectedCallback() {
        let communityUrl;
        var jsonData = JSON.parse(JSON.stringify(this.omniJsonData));
        console.log('Chargent Order Id: ' + jsonData.ChargentOrderId);
        // if ( jsonData.ChargentOrderId != null ) {
        // }
        var profile = jsonData.userProfile;
        var isChangingPaymentMethod = jsonData.ChangePaymentMethod;
        if ( jsonData.STEP_ChargentPayment != null ){
            if ( jsonData.STEP_ChargentPayment.RAD_MethodOfPayment != null && jsonData.STEP_ChargentPayment.RAD_MethodOfPayment == 'Credit Card' ){
                this.isCreditCard = true;
                this.gatewayForConsole= jsonData.CreditCardGateway;
            }
            else {
                this.gatewayForConsole=jsonData.BankAccountGateway
            }
          }
       

        this._actionUtilClass = new OmniscriptActionCommonUtil();
        this.IPInput = {};
        console.log(jsonData);
        const params = {
            input: JSON.stringify(this.IPInput),
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'Community_URL',
            options: '{}'
        };
        this._actionUtilClass
        .executeAction(params, null, this, null, null)
        .then( (response)=> {
            communityUrl =  response.result.IPResult.communityUrl;
            
            // this._actionUtilClass = new OmniscriptActionCommonUtil();
            
            // console.log(jsonData);
            // const params = {
            //     input: JSON.stringify({"ContractId":jsonData.ContractId}),
            //     sClassName: 'vlocity_ins.IntegrationProcedureService',
            //     sMethodName: 'PaymentRequest_CreateIfExpired',
            //     options: '{}'
            // };
            // this._actionUtilClass
            // .executeAction(params, null, this, null, null)
            // .then((resp) => { 
            //         console.log('resp');
            //         console.log(resp);
            //         this.commurl = resp.result.IPResult.Link;
            //     })
            //     .catch((error) => {
            //     console.error(error);
            // });


            console.log(communityUrl);
            console.log('chnage ', isChangingPaymentMethod);
            if (isChangingPaymentMethod == undefined && (profile == 'Member Community' || profile == 'Partner Community')) {
                let path;
                
                let origin = window.location.origin;
                console.log("origin: "+origin)
                
                let firstPath = window.location.pathname.split('/')[1];


                if(firstPath.charAt(0) != '/'){
                    path = '/' + firstPath  + '/s/';
                } else {
                    path = firstPath + '/s/';
                }

                console.log("final de firstPath: "+path);
                // let path = window.location.pathname.split('/')[1] != 's' ? 
                let page = `chargent-payment?recordId=${jsonData.ContractId}&gatewayId=${this.gatewayForConsole}`;
                
                console.log("communityURL: "+origin + path + page);

                this.commurl=  origin + path + page;
            } else if (isChangingPaymentMethod == true && profile == 'Member Community' ) {
                let origin = window.location.origin;

                // let path = window.location.pathname.split('/')[1] != 's' ? '/' + window.location.pathname.split('/')[1] + '/s/' : '/s/';

                let firstPath = window.location.pathname.split('/')[1];
                if(firstPath.charAt(0) != '/'){
                    path = '/' + firstPath  + '/s/';
                } else {
                    path = firstPath + '/s/';
                }

                let page = `change-payment-method?recordId=${jsonData.ContractId}&gatewayId=${this.gatewayForConsole}`;
                console.log(origin + path + page);

                this.commurl=  origin + path + page;
                
            } else {
                console.log("Internal");
                this.commurl=jsonData.PaymentLinkForInternalUse;
                console.log(this.commurl)
                console.log(JSON.stringify(jsonData))
            }
        })
        .catch((error) => {
            console.error(error);
        });
        


    }

}