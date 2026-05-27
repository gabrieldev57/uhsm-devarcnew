import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';



export default class ARC_DocuSignValidation extends OmniscriptBaseMixin(LightningElement) {
    @api osData;
    @api signError = false;
    @api sendError = false;
    @api agreementError = false;
    @api newstatus;
    @api execution;
    @api test;
    @api transformForEnvelope;
    @api contractId;
    @api sendEmailExecuted;

    @api userRole;
    noEmail = false;
    envelopeId;
    isMemberServiceManager = false;

    @track loadingNext = false;
    @track className = 'alert danger-alert none';
    @track nextBtnLabel = 'Next';
    @track nextBtnStyle = '';



    connectedCallback() {
        if (this.execution === 'Enroll' || this.execution === 'Program Change' || this.execution === 'Reprice Case' || this.execution === 'Spin Off') {
            this.nextBtnLabel = 'Send Email and Continue';
            this.nextBtnStyle = 'flex-basis: 100%; max-width: none;';
        }
        if (this.userRole == 'Member Service Manager' && this.execution != 'Enroll') {
            // console.log('this.isMemberServiceManager', this.isMemberServiceManager)
            this.isMemberServiceManager = true;
        }
    }

    noEmailChange() {
        this.noEmail = !this.noEmail;
        this.nextBtnLabel = this.noEmail ? 'Continue without sending Email' : 'Send Email and Continue';
    }


    handleNext(evt) {
        this.omniJsonData = JSON.parse(JSON.stringify(this.omniJsonData));
        if (!this.sendEmailExecuted) {
            this.sendEmailExecuted = !this.sendEmailExecuted;
            this.omniApplyCallResp({ "CHK_SendEmailExecuted": this.sendEmailExecuted })

            console.debug('execution: ',this.execution);
            if ((this.execution === 'Enroll' || this.execution === 'Program Change' || this.execution === 'Spin Off' || this.execution === 'Reprice Case') || (this.omniJsonData.STEP_SignTheDocument.FRML_SignatureStatus == "Completed" || this.omniJsonData.STEP_SignTheDocument.FRML_EnvelopeStatus == "sent" || this.newstatus == "sent")) {
                this.className = 'alert danger-alert none';
                if (this.execution === 'Enroll') {
                    this.sendDocuSignEnvelope(this.enrollNextStep);
                } else if (this.execution === 'Program Change') {
                    if (!this.noEmail) {
                        this.sendDocuSignEnvelope(this.pcNextStep);
                    } else {
                        this.pcNextStep();
                    }

                } else if (this.execution === 'Spin Off') {
                    if (!this.noEmail) {
                        this.sendDocuSignEnvelope(this.enrollNextStep);
                    } else {
                        this.enrollNextStep();
                    }
                } else if (this.execution === 'Reprice Case') {
                    if (!this.noEmail) {
                        // console.log('will send email');
                        this.sendDocuSignEnvelope(this.repriceNextStep);
                    } else {
                        // console.log('will NOT send email');
                        this.repriceNextStep();
                    }

                } else {
                    this.omniNextStep();
                }
            } else {
                this.className = 'alert danger-alert';
            }

        }

        this.checkErrorSign();
    }

    checkErrorSign() {

        if (this.omniJsonData.userProfile == 'Member Community' && this.omniJsonData.STEP_SignTheDocument.FRML_HasDependentsOver18 == false) {
            this.signError = true;
        }


        if (this.omniJsonData.STEP_SignTheDocument.FRML_SignViaEmail == true) {
            this.sendError = true;
        }
    }

    handlePrev() {
        this.omniPrevStep();
    }

    closeAlert() {
        this.className = 'alert danger-alert none';
    }

    // Executes Enrollment last IPs
    async enrollNextStep(context = this) {
        context.loadingNext = true;

        let paramsIFPEnrollment_SubmitUserInfo = {
            input: { ...context.omniJsonData, execution: context.execution },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'IFPEnrollment_SubmitUserInfo',
            options: '{}',
        };

        let IsSpinOffOmniscript = context.execution == 'Spin Off';
        let paramsARC_PolicyCreation = {
            input: {
                "contractId": context.omniJsonData.ContractId,
                "IsSpinOffOmniscript": IsSpinOffOmniscript,
                "IsUpgradedSpinOff": context.omniJsonData.isUpgradeReEnrollment
            },
            sClassName: 'ARC_PolicyCreation',
            sMethodName: 'createAllPolicyRecords',
            options: {}
        };

        await context.omniRemoteCall(paramsIFPEnrollment_SubmitUserInfo, true)
            .then(response => {
                console.log(response);
            })
            .catch(error => {
                window.console.log(error, 'error');
            });

        await context.omniRemoteCall(paramsARC_PolicyCreation, true)
            .then(response => {
                console.log(response);
                context.omniNextStep();
            })
            .catch(error => {
                window.console.log(error, 'error');
            });
    }

    // Executes Program Change last IPs
    async pcNextStep(context = this) {
        console.log('PC NEXT STEP');
        context.loadingNext = true;
        let params;
        let reasonForPC = context.omniJsonData.STEP_ChangeReason.SEL_ChangeReason;
        if (!context.omniJsonData.Cancellation) {
            console.log('PC NEXT STEP - No Cancellation');
            if (reasonForPC.includes('Program Upgrade') || reasonForPC.includes('Add Member')
                || reasonForPC.includes('Add Newborn') || reasonForPC.includes('Add Existing Member')) {
                // Calling the ProgramChange_SubmitMedicalQuestions Integration Procedure

                params = {
                    input: {
                        "censusId": context.omniJsonData.censusId,
                        "STEP_HIPAAAuthorizationForm": context.omniJsonData.STEP_HIPAAAuthorizationForm,
                        "TXT_MedicationId": context.omniJsonData.TXT_MedicationId,
                        "STEP_MedicalQuestions": context.omniJsonData.STEP_MedicalQuestions,
                        "UnderwritingCase": context.omniJsonData.UnderwritingCase,
                        "reason": context.omniJsonData.STEP_ChangeReason.SEL_ChangeReason,
                        "userInputs2": context.omniJsonData.FilterProgramsToUpdate.userInputs2
                    },
                    sClassName: 'vlocity_ins.IntegrationProcedureService',
                    sMethodName: 'ProgramChange_SubmitMedicalQuestions',
                    options: {},
                };
                console.log('Submit Medical Questions - Input', JSON.parse(JSON.stringify(params.input)));
                context.omniRemoteCall(params, true).then(response => {
                    // console.log("------------SUBMIT MEDICAL QUESTIONS (2.2) --------------", Date.now())
                }).catch(error => {
                    window.console.log(error, 'error');
                });

            }

            if (context.omniJsonData.UnderwritingCase/*  != null && context.omniJsonData.UnderwritingCase != undefined && context.omniJsonData.UnderwritingCase != ''  */) {
                // Calling the ProgramChange_UCMembers Integration Procedure
                console.log('PC NEXT STEP - Underwriting Case');
                params = {
                    input: {
                        "reason": context.omniJsonData.STEP_ChangeReason.SEL_ChangeReason,
                        "censusId": context.omniJsonData.censusId,
                        "UnderwritingCase": context.omniJsonData.UnderwritingCase,
                        "RemovedMembers": context.omniJsonData.FilterProgramsToUpdate.RemovedMembers,
                        "auxSavedMembers": context.omniJsonData.FilterProgramsToUpdate.auxSavedMembers,
                        "changesForContracts": context.omniJsonData.changesForContracts,
                        "userInputs2": context.omniJsonData.FilterProgramsToUpdate.userInputs2,
                        "includeNewMembersInUpgrade": context.omniJsonData.includeNewMembersInUpgrade
                    },
                    sClassName: 'vlocity_ins.IntegrationProcedureService',
                    sMethodName: 'ProgramChange_UCMembers',
                    options: {}
                };
                console.log('PC NEXT STEP - Underwriting Case - params', JSON.parse(JSON.stringify(params)));
                try {
                    const ProgramChange_UCMembersResponse = await context.omniRemoteCall(params, true);
                    console.log('PC NEXT STEP - Underwriting Case - ProgramChange_UCMembersResponse', JSON.parse(JSON.stringify(ProgramChange_UCMembersResponse)));
                } catch (error) {
                    window.console.log(error, 'error');
                }

            }

            // Calling the Update_ContractStatusPCAncillary Integration Procedure
            params = {
                input: {
                    "changesForContracts": context.omniJsonData.changesForContracts,
                },
                sClassName: 'vlocity_ins.IntegrationProcedureService',
                sMethodName: 'Update_ContractStatusPCAncillary',
                options: {}
            };
            console.log('PC NEXT STEP - Update_ContractStatusPCAncillary - params', JSON.parse(JSON.stringify(params)));

            context.omniRemoteCall(params, true).then(response => {
                // console.log("------------SUBMIT CONTRACT STATUS (2.4) --------------", Date.now())
                console.log('Response from Update_ContractStatusPCAncillary', JSON.parse(JSON.stringify(response)));
            }).catch(error => {
                window.console.log(error, 'error');
            });

        }

        // Calling createAllPolicyRecords from ARC_PolicyCreation
        params = {
            input: {
                "contractId": context.omniJsonData.changesForContracts[0].Id,
            },
            sClassName: 'ARC_PolicyCreation',
            sMethodName: 'createAllPolicyRecords',
            options: {}
        };

        context.omniRemoteCall(params, true).then(response => {
            // console.log("------------SUBMIT POLICIES (2.5) --------------", Date.now())
            //// console.log('Response from createAllPolicyRecords', response);
        }).catch(error => {
            window.console.log(error, 'error');
        });

        context.omniNextStep();
    }

    // DocuSign Envelope Methods
    async sendDocuSignEnvelope(nextStepFunction) {
        this.loadingNext = true;

        console.log('ARC_DocusignJSON input:', this.omniJsonData.DocuSignData)
        let response = await this.omniRemoteCall({
            input: {
                "DocuSignData": this.omniJsonData.DocuSignData
            },
            sClassName: 'ARC_DocusignJSON',
            sMethodName: 'transformInformationForDocusign',
            options: '{}'
        }, true)

        console.log('ARC_DocusignJSON response:', JSON.stringify(response))
        console.log('ARC_DocusignJSON response:', response?.result)
        // params for DS Envelope
        response = await this.omniRemoteCall({
            input: {},
            sClassName: 'vlocity_ins.DefaultDocuSignOmniScriptIntegration',
            sMethodName: 'sendEnvelope',
            options: {
                "docuSignTemplatesGroup": [
                    {
                        "docuSignTemplate": this.omniJsonData.DocuSignTemplate.TemplateId,
                        "sendJSONPath": null,
                        "sendJSONNode": null,
                        "includeToSend": true,
                        "signerList": this.omniJsonData.Recipients,
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

        console.log('Template Information:', JSON.parse(JSON.stringify(this.omniJsonData.DocuSignTemplate)))
        console.log('DS_EnvelopeAction response:', response?.result)

        let params = {
            input: {
                "IP_ContractCreation": { "changesForContracts": [{ "Id": this.contractId }] },
                "envelopeId": response?.result?.DS_EnvelopeAction?.envelopeId,
                "signerEmail": this.omniJsonData.Recipients[0].signerEmail,
                "signerName": this.omniJsonData.Recipients[0].signerName
            },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'DocuSign_ContractEnvelopeIdProgramChange',
            options: '{}'
        };


        this.omniRemoteCall(params, true).then(response => {
            nextStepFunction(this);
            this.loadingNext = false;
        }).catch(error => {
            window.console.log(error, 'error');
            this.loadingNext = false;
        });

    }

    // Executes Reprice Case last IPs
    async repriceNextStep(context = this) {
        context.loadingNext = true;

        console.log("IsRepriceOmniscript: ", context.omniJsonData.IsRepriceOmniscript);
        const paramsPolicy = {
            input: {
                "contractId": context.omniJsonData.changesForContracts[0].Id,
                "IsRepriceOmniscript": context.omniJsonData.IsRepriceOmniscript,
                "OldContractReason": context.omniJsonData.OldContractReason,
            },
            sClassName: 'ARC_PolicyCreation',
            sMethodName: 'createAllPolicyRecords',
            options: {}
        };
        const paramsSubmitMedicalQuestions = {
            input: {
                "censusId": context.omniJsonData.censusId,
                "STEP_HIPAAAuthorizationForm": context.omniJsonData.STEP_HIPAAAuthorizationForm,
                "TXT_MedicationId": context.omniJsonData.TXT_MedicationId,
                "STEP_MedicalQuestions": context.omniJsonData.STEP_MedicalQuestions,
                "UnderwritingCase": context.omniJsonData.UnderwritingCase,
                "reason": context.omniJsonData.STEP_ChangeReason.SEL_ChangeReason,
                "userInputs2": context.omniJsonData.FilterProgramsToUpdate.userInputs2,
                "execution": context.execution
            },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'ProgramChange_SubmitMedicalQuestions',
            options: {},
        };
        const paramsContractStatusPCAncillary = {
            input: {
                "changesForContracts": context.omniJsonData.changesForContracts,
            },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'Update_ContractStatusPCAncillary',
            options: {}
        };
        const paramsFinishRepriceCase = {
            input: {
                "OldContractId": context.omniJsonData.OldContractId,
                "NewContractId": context.omniJsonData.FirstContract.Id,
                "CaseId": context.omniJsonData.ContextId,
                "OldContractSingleReason": context.omniJsonData.OldContractSingleReason,
                "OldContractReason": context.omniJsonData.OldContractReason,
                "OldContractSubReason": context.omniJsonData.OldContractSubReason,
                "OldContractOtherSubReason": context.omniJsonData.OldContractOtherSubReason,
                "censusId": context.omniJsonData.censusId,
                "userInputs2": context.omniJsonData.userInputs2,
                "isNewEnrollment": context.omniJsonData.isNewEnrollment,
                "ChargentOrderId": context.omniJsonData.ChargentOrderId
            },
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'RepriceCase_FinishRepriceCase',
            options: {}
        };

        try {
            // Policy creation
            console.log('Starting createAllPolicyRecords');
            await context.omniRemoteCall(paramsPolicy, true);
            console.log('Finished createAllPolicyRecords');

            context.loadingNext = true;

            // Submit medical questions
            console.log('Starting SubmitMedicalQuestions');
            await context.omniRemoteCall(paramsSubmitMedicalQuestions, true);
            console.log('Finished SubmitMedicalQuestions');

            // Finish reprice case
            console.log('Starting FinishRepriceCase');
            await context.omniRemoteCall(paramsFinishRepriceCase, true);
            console.log('Finished FinishRepriceCase');

            // MUST BE LAST
            console.log('Starting Update_ContractStatusPCAncillary');
            await context.omniRemoteCall(paramsContractStatusPCAncillary,true);
            console.log('Finished Update_ContractStatusPCAncillary');
        
            // Only after EVERYTHING is done
            await new Promise(resolve => setTimeout(resolve, 300));
            context.omniNextStep();

            console.log('SPINNER = ' + context.loadingNext);
            context.loadingNext = false;
            console.log('SPINNER = ' + context.loadingNext);

        } catch (error) {
            console.error('Error during repriceNextStep execution', error);
        }
    }
}