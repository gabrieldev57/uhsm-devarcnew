import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

let docuSignData;
let isCancellationContract;
let isPrimaryChangeContract;
let isActiveContract;
let isAccountExecutive;
// users with "Account Executive" Role can only send emails when the user is the contract's selling agent.
// authorizedRoles can send email in all cases
let authorizedRoles = ['CEO', 'Director of Acquisitions', 'Acquisition Manager', 'Team Development Leader', 'Marketing Development Team Lead', 'Sales Development Rep']
// restricted contract statuses where users shouldnt be able to resend contract 
let restrictedContractStatuses = ['Awaiting First Payment', 'Awaiting Activation', 'Activated', 'Terminated', 'Voided'];

export default class ARC_DocuSignResendContractEnvelope extends OmniscriptBaseMixin(LightningElement) {
    @api recordId;
    @api hipaas;
    @api recipientEmail;
    @api recipients;
    @api sendingEnvelope = false;
    @api showSelect = false;
    @api enableComponent = false;
    @api disableButton = false;
    @api message;

    async connectedCallback() {
        this.enableComponent = true;
        this.disableButton = true;
        this.message = 'Validating user...';

        await this.getContractAndUserInfo()
        await this.getHipaaRecipients(this.inputData.Contract.vlocity_ins__EnrollmentCensusId__c)

        this.recipients = this.inputData.Recipients;
        console.log('primary change: ', isPrimaryChangeContract)
        if (isPrimaryChangeContract) {
            // New Primary is the only one that can be selected
            this.recipientEmail = this.recipients.find(recipient => recipient.templateRole === "Primary")?.signerEmail;
        } else {
            // Default Primary if not Parent if not Legal Guardian
            this.recipientEmail =
                this.hipaas.find(hipaa => hipaa.role === "Member")?.value ||
                this.hipaas.find(hipaa => hipaa.role === "Parent")?.value ||
                this.hipaas.find(hipaa => hipaa.role === "Legal Guardian")?.value;
        }
        
        if (!this.disableButton) {
            this.message = 'Email will be sent to: ' + this.recipientEmail;
        }
    }

    async getHipaaRecipients(censusId) {
        const { result: { IPResult: { HipaaRecipients } } } = await this.omniRemoteCall({
            input: { "CensusId": censusId },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'DocuSign_Recipients',
            options: '{}'
        }, true)

        this.hipaas = HipaaRecipients;
        console.log('hipaas: ', this.hipaas);
    }

    resendContract() {
        if (this.enableComponent) {
            this.disableButton = true;
            this.sendingEnvelope = true;
            this.message = 'Sending Envelope...'
            this.generateDocuSignData(this.inputData).then(() => {

                let recipients = this.recipients ? this.recipients : this.inputData.Recipients;
                let templateId = this.inputData.TemplateData.Template.vlocity_ins__TemplateIdentifier__c;
                let DRTransform = this.inputData.TemplateData.Settings.ARC_DRTransform__c;
                let contract = this.inputData.Contract;

                this.sendEnvelope(templateId, DRTransform, recipients, contract);
            });
        }

    }

    // Gets Dependents List, Recipients, corresponding DocuSign Template identifier
    async getContractAndUserInfo() {

        console.log('ContractData Input', { "contractId": this.recordId });

        const { result: { IPResult } } = await this.omniRemoteCall({
            input: { "contractId": this.recordId },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'Get_ContractData',
            options: '{}'
        }, true)

        console.log('ContractData Output', IPResult)

        this.assessUserAndContract(IPResult);

        if (!(IPResult.Contract.ARC_ContractReason__c.includes('New Application'))) {
            this.showSelect = true
        };

        this.inputData = {
            "Dependents": IPResult.Dependents,
            "Contract": IPResult.Contract,
            "TemplateData": IPResult.TemplateData,
            "Recipients": IPResult.Recipients,
        }

    }

    // enables/disables component visibility and 'send' button
    assessUserAndContract(IPResult) {
        let agentRole = IPResult.RunningUser.AgentRole;
        let contractStatus = IPResult.Contract.Status;
        isActiveContract = contractStatus == 'Activated';
        isAccountExecutive = IPResult.RunningUser.IsAccountExecutive;
        // isSellingAgent = IPResult.RunningUser.IsSellingAgent;
        isCancellationContract = IPResult.Contract.ARC_SingleReasonForPC__c == 'Cancellation';
        let reasonList = IPResult.Contract.ARC_ContractReason__c.split(';');
        isPrimaryChangeContract = reasonList.some(reason => reason === 'Primary Change');

        if (restrictedContractStatuses.includes(contractStatus) && !isCancellationContract) {
            this.enableComponent = false;
            this.disableButton = true;
            this.message = "This contract is already " + contractStatus;
        } else {
            if (isCancellationContract && (isActiveContract || !restrictedContractStatuses.includes(contractStatus)) || !isCancellationContract) {
                if (authorizedRoles.includes(agentRole) || isAccountExecutive) {
                    this.enableComponent = true;
                    this.disableButton = false;
                } else {
                    this.enableComponent = false;
                }
            }
        }
    }

    async generateDocuSignData(inputData) {
        this.message = 'Getting contract information...'
        let contract = inputData.Contract;
        let dependents = inputData.Dependents;

        let response = await this.omniRemoteCall({
            input: {
                "accountId": contract.AccountId,
                "contractReason": contract.ARC_ContractReason__c,
                "contractId": contract.Id,
                "censusId": contract.vlocity_ins__EnrollmentCensusId__c,
                "chargentOrderId": contract.ARC_AppFeeOrder__c != null ? contract.ARC_AppFeeOrder__c : contract.ARC_RecurringMonthlyOrder__c,
                "userId": contract.ARC_Selling_Agent__c,
                "contractDependents": dependents,
                "contractTotalPrice": contract.ARC_TotalPrice__c,
            },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'DocuSign_ExtractInformation',
            options: '{}'
        }, true)

        docuSignData = response.result.IPResult.DocuSignData;
        console.log('DocuSignData: ', docuSignData);

        const { result: { IPResult: { Output } } } = await this.omniRemoteCall({
            input: { "contractId": contract.Id },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'DocuSign_ListMembersOnPrograms',
            options: '{}'
        }, true);

        docuSignData.Info = { ...docuSignData.Info, "MembersPerProgram": Output };

        // PROGRAM CHANGE
        if (contract.vlocity_ins__ExpiredContractId__c && !isCancellationContract) {
            this.message = 'Getting previous contract information...'

            const { result: { IPResult: { MembersPerProgramOld, CurrentProgram, ReasonForChange, RequestedChanges } } } = await this.omniRemoteCall({
                input: { "contract": contract },
                sClassName: 'vlocity_ins.IntegrationProcedureService',
                sMethodName: 'DocuSign_ContractChanges',
                options: '{}'
            }, true)

            docuSignData.Info = {
                ...docuSignData.Info,
                "MembersPerProgramOld": MembersPerProgramOld,
                "CurrentProgram": CurrentProgram,
                "ReasonForChange": ReasonForChange,
                "RequestedChanges": RequestedChanges,
            };

        }

        this.message = 'Merging Medical Questions...'

        if (this.hipaas) {
            docuSignData.hipaas = this.hipaas;
        }
        
        console.log('penultimo docusigndata change:', docuSignData);

        response = await this.omniRemoteCall({
            input: {
                "InvolvedMembers": [...dependents, docuSignData.Spouse, docuSignData.Primary],
                "DocuSignData": docuSignData,
                "reason": contract.ARC_ContractReason__c.includes('New Application') || contract.ARC_ContractReason__c.includes('Spin Off') ? 'Program Upgrade' : contract.ARC_ContractReason__c,
                "contractId": contract.Id
            },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'DocuSign_GetAndProcessMedicalQuestions',
            options: '{}'
        }, true)

        docuSignData = response.result.IPResult.Response;
        console.log('last docusigndata change:', docuSignData);
    }


    async sendEnvelope(templateId, DRTransform, recipients, contract) {
        console.log('DRTransform:', DRTransform);
        this.message = 'Sending Envelope...';
        console.log('sendenvelope:', docuSignData);
        try {
            let response = await this.omniRemoteCall({ //Apex Class to transform data into Docusign JSON format
                input: {
                    "DocuSignData": docuSignData?.DocuSignData
                },
                sClassName: 'ARC_DocusignJSON',
                sMethodName: (DRTransform == 'ARC_DocuSignEnrollmentFormC' || DRTransform == 'ARC_DocuSignProgramChangeFormC' || DRTransform == 'ARC_DocuSignAmendment') ? 'transformInformationForDocusign' : 'transformInformationForDocusignCancellation',
                options: '{}'
            }, true)

            console.log('Response:', response)

            response = await this.omniRemoteCall({ // Docusign envelope remote call
                input: {},
                sClassName: 'vlocity_ins.DefaultDocuSignOmniScriptIntegration',
                sMethodName: 'sendEnvelope',
                options: {
                    "docuSignTemplatesGroup": [
                        {
                            "docuSignTemplate": templateId,
                            "sendJSONPath": null,
                            "sendJSONNode": null,
                            "includeToSend": true,
                            "signerList": JSON.parse(JSON.stringify(recipients)),
                            "TFDRresp": response?.result
                        }
                    ],
                    "elementName": "DS_EnvelopeAction",
                    "useQueueableApexRemoting": false,
                    "ignoreCache": false,
                    "vlcClass": "vlocity_ins.DefaultDocuSignOmniScriptIntegration",
                    "useContinuation": false
                },
            }, true)

            console.log('Response 2:', response);

            console.log('Recipients:', recipients);

            this.message = 'Updating Contract...';

            response = await this.omniRemoteCall({ // Remote call Integration Procedure to update Contract
                input: {
                    "ContractId": contract.Id,
                    "Status": contract.Status == "Awaiting Signature" ? "Awaiting Signature" : null,
                    "LastDocuSignEnvelopeStatus": "Pending",
                    "CancellationSigned": false,
                    "envelopeId": response.result.DS_EnvelopeAction.envelopeId,
                    "signerEmail": recipients[0].signerEmail,
                    "signerName": recipients[0].signerName,
                },
                sClassName: 'vlocity_ins.IntegrationProcedureService',
                sMethodName: 'DocuSign_UpdateContractFieldsResendEnvelope',
                options: '{}'
            }, true)
            this.sendingEnvelope = false;
            this.disableButton = false;
            this.message = 'Envelope sent and contract updated succesfully.';
        } catch (error) {
            this.sendingEnvelope = false;
            this.message = JSON.stringify(error.message);
            this.disableButton = false;
        }
    }


    handleChange(evt) {
        let label = evt.target.options.find(opt => opt.value === evt.detail.value).label;

        const splitLabel = label.split(" - ");
        let value = evt.detail.value;
        let role = this.hipaas.find(opt => opt.label == label).role;
        let email = this.hipaas.find(opt => opt.label == label).value;

        let map = {
            "label": splitLabel[0],
            "value": value,
            "role": role,
            "email": email
        };

        this.setRecipients(map);
        this.recipientEmail = evt.detail.value;
        this.message = 'Email will be sent to: ' + this.recipientEmail;

    }

    setRecipients(map) {
        let recipientsJson = JSON.parse(JSON.stringify(this.recipients));
        recipientsJson.forEach(recipient => {
            recipient.signerEmail = map.email
            if (recipient.templateRole == "Primary") recipient.signerName = map.label
        });
        this.recipients = recipientsJson;
    }

    get enableComboboxRecipientButton() {
        return isPrimaryChangeContract;
    }

}