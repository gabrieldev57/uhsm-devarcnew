import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class Arc_DocuSignFormulaField extends OmniscriptBaseMixin(LightningElement) {
    @api envelopeid;
    @api contractid;
    
    docusignformulafield;

    @api
    get docusignformula() {
        return this.docuSignFormulaField;
    }

    
    set docusignformula(value) {
        this.docuSignFormulaField = value;
        console.log("docuSignDone: " + this.docuSignFormulaField);
        console.log("envelope ID: " + this.envelopeid);

        if(this.docuSignFormulaField == true){
            let input = {
                "envelopeId" : this.envelopeid,
                "contractId" : this.contractid
            };
            
            const params = {
                input: input,
                sClassName: 'vlocity_ins.IntegrationProcedureService',
                sMethodName: 'DocuSign_ContractEnvelopeId', 
                options: '{}',
            };
            
            this.omniRemoteCall(params, true).then(response => {
                console.log("response: " + response);
                window.console.log(response, 'response');
                this.omniUpdateDataJson(response);
            }).catch(error => {
                window.console.log(error, 'error');
            });
        }
    }

}