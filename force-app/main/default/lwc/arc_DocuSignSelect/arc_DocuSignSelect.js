import { LightningElement, wire, track, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class  extends OmniscriptBaseMixin(LightningElement) {
    recipient = '';
    role = ''; 
    email = ''; 

    @api hipaas;
    
    // recipients
    @api recipients;
    @api removedMembers;

    connectedCallback() {
        // console.log("----------DocuSignSelect ConnectedCallback----------");
        let osData = JSON.parse(JSON.stringify(this.omniJsonData));
        // console.log(osData);
        // console.log(osData.Recipients);

        // console.log('this.removedMembers', this.removedMembers);
        if ( this.removedMembers && this.removedMembers.length ) {
            // console.log('In removedMembers');
            let hipaasAux = this.hipaas.filter(recipient => !this.removedMembers.filter(member => member.CHK_Delete && member.NUM_Age > 18).map(m => { return m.TXT_CensusMemberId }).includes(recipient.Id));
            this.hipaas = hipaasAux.length == 0 ? this.hipaas : hipaasAux; 
        
        }

        // hipaasAux prevents error in set property on Proxy element (this.hipaas)
        let hipaasAux = JSON.parse(JSON.stringify(this.hipaas))
        let hipaas = [...hipaasAux]
        console.log(hipaas)
        hipaas.forEach(h => {
            h['email'] = h.value
            h.value = h.Id
        })
        this.hipaas = hipaas
        // console.log('AFTER', JSON.stringify(this.hipaas))

        let hipaasJson = JSON.parse(JSON.stringify(this.hipaas));
        if (hipaasJson[0] != "") {
            const splitLabel = this.hipaas[0].label.split(" - ");
            this.recipient = this.hipaas[0].value;
            this.role = this.hipaas[0].role;
            this.email = this.hipaas[0].email;

            let map = {
                "label": splitLabel[0],
                "value": this.recipient,
                "role": this.role,
                "email": this.email
            };

            // console.log('map', map);
            this.setRecipients(map);
            this.omniUpdateDataJson(map);
        }
        
        // console.log(this.hipaas)

    }

    handleChange(evt) {
        // console.log("----------DocuSignSelect handleChange----------");
        
        // console.log('SELECTED VALUE', evt.detail.value)
        // console.log(JSON.stringify(evt.target.options))
        
        let label = evt.target.options.find(opt => opt.value === evt.detail.value).label;


        // console.log('label TEEST'+' '+ evt.target.options.find(opt => opt.value === evt.detail.value).label);
        const splitLabel = label.split(" - ");
        let value = evt.detail.value;
        // console.log('value TEEST'+' '+ evt.detail.value);
        let role = this.hipaas.find(opt => opt.label == label).role;
        // console.log('role TEEST'+' '+ this.hipaas.find(opt => opt.label == label).role);
        let email = this.hipaas.find(opt => opt.label == label).email;
        // console.log('role TEEST'+' '+ this.hipaas.find(opt => opt.label == label).email);
        let map = {
            "label": splitLabel[0],
            "value": value,
            "role": role,
            "email": email
        };

        // console.log('map TEEST'+' '+ map);


        this.setRecipients(map)
        this.omniUpdateDataJson(map);


        this.recipient = evt.detail.value;
        this.role = evt.detail.role;

        // console.log("----------RECIPIENTS CHANGED----------");
        let osData = JSON.parse(JSON.stringify(this.omniJsonData));
        // console.log(osData);
        // console.log(osData.Recipients);

    }


    setRecipients(map){
        // console.log("----------DocuSignSelect SetRecipients----------");
        if(this.recipients){
            // console.log("--------------------pass this.recipients----------");
            let recipientsJson = JSON.parse(JSON.stringify(this.recipients));
            recipientsJson.forEach(recipient => {
                if(recipient.templateRole == "Primary"){ recipient.signerName = map.label;}
                recipient.signerEmail = map.email
            });
            this.recipients = recipientsJson 
            JSON.parse(JSON.stringify(this.omniJsonData)).Recipients = this.recipients;
            
            let recipientsData = {
                Recipients: this.recipients
            }
            
            this.omniApplyCallResp(recipientsData);
            // console.log("--------------------this.recipients result----------", this.recipients);
        }
    }

}