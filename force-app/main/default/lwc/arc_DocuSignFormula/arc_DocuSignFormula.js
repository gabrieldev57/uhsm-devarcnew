import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class Arc_DocuSignFormula extends OmniscriptBaseMixin(LightningElement) {
    @api contractid;
    @api contractIdList;

    connectedCallback(){
        console.log('contractIdList', JSON.stringify(this.contractIdList))
        console.log('contractidYES', JSON.stringify(this.contractid))
        console.log('envelopeId', this.envelopeid)
    }

    envelopeidfield;

    @api
    get envelopeid() {
        return this.envelopeidfield;
    }
    
    set envelopeid(value) {
        this.envelopeidfield = value;
        if(this.envelopeidfield != null && this.envelopeidfield != undefined){
            if(this.contractIdList != null && this.contractIdList != undefined){
                this.contractIdList.forEach( contractId => this.setEnvelopeIdOnContract(contractId) )
            }
            else if(this.contractid != null && this.contractid != undefined){
                this.setEnvelopeIdOnContract(this.contractid)
            }else{
                console.log("No ContractId found")
            }
        }
    }

    
    
    docusignformulafield;

    @api
    get docusignformula() {
        return this.docusignformulafield;
    }

    
    set docusignformula(value) {
        this.docusignformulafield = value;

        if(this.envelopeidfield != null && this.envelopeidfield != undefined){
            if(this.docusignformulafield == "sent"){
                let input = {
                    "envelopeId" : this.envelopeidfield,
                    "contractId" : this.contractid
                };
                
                const params = {
                    input: input,
                    sClassName: 'vlocity_ins.IntegrationProcedureService',
                    sMethodName: 'DocuSign_ContractEnvelopeId', 
                    options: '{}',
                };
                
                this.omniRemoteCall(params, true).then(response => {
                    window.console.log(response, 'response envelopeid sent');
                    this.omniUpdateDataJson(response);
                }).catch(error => {
                    window.console.log(error, 'error');
                });
            }
    
            if(this.docusignformulafield == "Completed"){
                let input = {
                    "envelopeId" : this.envelopeidfield,
                    "contractId" : this.contractid,
                    "docuSignStatus": "Completed"
                };
                
                const params = {
                    input: input,
                    sClassName: 'vlocity_ins.IntegrationProcedureService',
                    sMethodName: 'DocuSign_ContractEnvelopeId', 
                    options: '{}',
                };
                
                this.omniRemoteCall(params, true).then(response => {
                    window.console.log(response, 'response envelopeid completed');
                    this.omniUpdateDataJson(response);
                }).catch(error => {
                    window.console.log(error, 'error');
                });
            }
        }
    }    

    setEnvelopeIdOnContract(contractid){
        console.log(this.envelopeidfield)
        console.log(this.contractid)
        if(this.docusignformulafield == "sent"){
            let input = {
                "envelopeId" : this.envelopeidfield,
                "contractId" : contractid
            };
            
            const params = {
                input: input,
                sClassName: 'vlocity_ins.IntegrationProcedureService',
                sMethodName: 'DocuSign_ContractEnvelopeId', 
                options: '{}',
            };
            
            this.omniRemoteCall(params, true).then(response => {
                window.console.log(response, 'response envelopeid sent');
                this.omniUpdateDataJson(response);
            }).catch(error => {
                window.console.log(error, 'error');
            });
        }

        if(this.docusignformulafield == "Completed"){
            let input = {
                "envelopeId" : this.envelopeidfield,
                "contractId" : contractid,
                "docuSignStatus": "Completed"
            };
            
            const params = {
                input: input,
                sClassName: 'vlocity_ins.IntegrationProcedureService',
                sMethodName: 'DocuSign_ContractEnvelopeId', 
                options: '{}',
            };
            
            this.omniRemoteCall(params, true).then(response => {
                window.console.log(response, 'response envelopeid completed');
                this.omniUpdateDataJson(response);
            }).catch(error => {
                window.console.log(error, 'error');
            });
        }
    }


  
}