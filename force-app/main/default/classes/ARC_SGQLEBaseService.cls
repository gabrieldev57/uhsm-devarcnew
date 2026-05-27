global without sharing class ARC_SGQLEBaseService implements vlocity_ins.VlocityOpenInterface{

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'processSmallGroupQLE') {
            System.debug('methodName  processSmallGroupQLE 1');
            processSmallGroupQLE(inputMap, outputMap);
        }
        return true;
    }

    public static void processSmallGroupQLE(Map<String,Object> inputMap, Map<String,Object> outputMap) {
        try {
            System.debug('methodName  processSmallGroupQLE 2');
            Id caseId = (Id) inputMap.get('caseId');
            String oldStatus = (String) inputMap.get('oldStatus');
            System.debug('methodName  processSmallGroupQLE 3');
            execute(caseId, oldStatus);
            outputMap.put('success', true);
        } catch (Exception e) {
            outputMap.put('success', false);
            outputMap.put('errorMessage', e.getMessage());
            outputMap.put('errorStackTrace', e.getStackTraceString());
        }
    }

    @future
    public static void executeAsync(Id caseId, String oldStatus) {
        execute(caseId, oldStatus);
    }

    public static void execute(Id caseId, String oldStatus) {
        Case qleCase = [SELECT Id, Status, ARC_QLE_RequestPayload__c, ARC_QLE_ExecutionStatus__c, ARC_QLE_LastExecutionError__c, ARC_QLEType__c, ARC_QLESubType__c, ARC_PersonAccount__c, ARC_QLEEffectiveDate__c
                        FROM Case 
                        WHERE Id = :caseId LIMIT 1];

        if (qleCase.ARC_QLE_ExecutionStatus__c == 'Success') {
            return; 
        }

        try {
            System.debug('is here in the ARC_SGQLEBaseService');
            qleCase.ARC_QLE_ExecutionStatus__c = 'In Progress';

            Boolean isFallbackPayload = String.isBlank(qleCase.ARC_QLE_RequestPayload__c);
            Map<String, Object> payload = isFallbackPayload
                ? buildFallbackPayloadFromCase(qleCase)
                : (Map<String, Object>) JSON.deserializeUntyped(qleCase.ARC_QLE_RequestPayload__c);

            payload.put('qleType',(String)qleCase.ARC_QLEType__c);
            payload.put('qleSubtype',(String)qleCase.ARC_QLESubType__c);
            System.debug('qleType ' + (String)payload.get('qleType'));
            System.debug('qleSubtype ' + (String)payload.get('qleSubtype'));
            
            // Evaluate reasons and changes based on Payload
            Map<String,Object> updatedPayload = new Map<String,Object>();
            if (payload != null && !payload.isEmpty() && !isFallbackPayload) {
               updatedPayload = ARC_SG_Utilities.evaluateChanges(payload);
            } else if (payload != null && !payload.isEmpty()) {
                updatedPayload = payload;
            }
            Map<String,Object> getChangesMap =
                updatedPayload != null
                && !updatedPayload.isEmpty()
                && updatedPayload.containsKey('generalInformation')
                && updatedPayload.get('generalInformation') != null
                && ((Map<String,Object>)updatedPayload.get('generalInformation')).containsKey('qleChanges')
                && ((Map<String,Object>)updatedPayload.get('generalInformation')).get('qleChanges') != null
                    ? (Map<String,Object>)((Map<String,Object>)updatedPayload.get('generalInformation')).get('qleChanges')
                    : new Map<String,Object>();

            if (!isFallbackPayload && getChangesMap.containsKey('noChanges') && getChangesMap.get('noChanges') == true) {
                qleCase.Status = 'Closed Voided';
                update qleCase;
            } else {
                System.debug('IN Manager');
                ARC_SGQLEManager handler = new ARC_SGQLEManager(updatedPayload);
                handler.executeQLE();
                System.debug('OUT Manager');
                qleCase.ARC_QLE_ExecutionStatus__c = 'Success';
                qleCase.ARC_QLE_AppliedDateTime__c = Datetime.now();
                qleCase.Status = 'Closed Approved';
                qleCase.ARC_QLE_LastExecutionError__c = null;
            }  

        } catch (Exception e) {
            System.debug('Error en ARC_QLE_BaseService: ' + e.getMessage() + '\n' + e.getStackTraceString());
            
            qleCase.ARC_QLE_ExecutionStatus__c = 'Failed';
            if (String.isNotBlank(oldStatus)) {
                qleCase.Status = oldStatus;
            }
            qleCase.ARC_QLE_LastExecutionError__c = 'Message: ' + e.getMessage() + '\nTrace: ' + e.getStackTraceString();
            
            sendErrorEmail(e, qleCase);
        }

        update qleCase;
    }

    private static Map<String, Object> buildFallbackPayloadFromCase(Case qleCase) {
        if (qleCase == null || qleCase.ARC_PersonAccount__c == null) {
            throw new QLEExecutionException('No valid payload and no ARC_PersonAccount__c on Case to infer QLE context');
        }

        String qleType = qleCase.ARC_QLEType__c;
        String qleSubType = qleCase.ARC_QLESubType__c;
        Boolean reinstatementLike = isReinstatementLike(qleType, qleSubType);

        List<InsurancePolicy> policies = [
            SELECT Id, Status, ARC_GroupAccount__c, ARC_Contract__c, ARC_PolicyEffectiveDate__c, ARC_EffectiveDate__c, NameInsuredId
            FROM InsurancePolicy
            WHERE NameInsuredId = :qleCase.ARC_PersonAccount__c
            AND Status IN ('Activated', 'Terminated', 'Awaiting Activation', 'Awaiting Signature')
            ORDER BY CreatedDate DESC
        ];

        InsurancePolicy selected = null;
        if (!policies.isEmpty()) {
            if (reinstatementLike) {
                for (InsurancePolicy p : policies) {
                    if (p.Status == 'Terminated') {
                        selected = p;
                        break;
                    }
                }
            }
            if (selected == null) {
                for (InsurancePolicy p : policies) {
                    if (p.Status == 'Activated' || (p.Status != null && p.Status.startsWith('Awaiting'))) {
                        selected = p;
                        break;
                    }
                }
            }
            if (selected == null) {
                selected = policies[0];
            }
        }

        // For no-JSON processing, prefer Case ARC_QLEEffectiveDate__c.
        Date effectiveDate = qleCase.ARC_QLEEffectiveDate__c;
        if (effectiveDate == null) {
            effectiveDate = selected != null
                ? (selected.ARC_PolicyEffectiveDate__c != null ? selected.ARC_PolicyEffectiveDate__c : selected.ARC_EffectiveDate__c)
                : Date.today();
        }

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('qleType', qleType);
        payload.put('qleSubtype', qleSubType);
        payload.put('qle', new Map<String, Object>{
            'qleType' => qleType,
            'qleSubtype' => qleSubType
        });
        payload.put('generalInformation', new Map<String, Object>{
            'accountId' => qleCase.ARC_PersonAccount__c,
            'groupAccountId' => selected != null ? selected.ARC_GroupAccount__c : null,
            'contractId' => selected != null ? selected.ARC_Contract__c : null,
            'effectiveDate' => effectiveDate == null ? null : String.valueOf(effectiveDate)
        });
        payload.put('members', new List<Object>());
        payload.put('currentState', new Map<String, Object>{
            'currentPolicy' => new Map<String, Object>{
                'policyId' => selected != null ? selected.Id : null,
                'status' => selected != null && selected.Status == 'Activated' ? 'Active' : (selected != null ? selected.Status : null),
                'effectiveDate' => effectiveDate == null ? null : String.valueOf(effectiveDate),
                'groupAccountId' => selected != null ? selected.ARC_GroupAccount__c : null,
                'contractId' => selected != null ? selected.ARC_Contract__c : null,
                'employeeAccountId' => qleCase.ARC_PersonAccount__c
            },
            'currentProducts' => new Map<String, Object>(),
            'currentMembers' => new List<Object>()
        });
        return payload;
    }

    private static Boolean isReinstatementLike(String qleType, String qleSubType) {
        String typeVal = qleType == null ? '' : qleType;
        String subTypeVal = qleSubType == null ? '' : qleSubType;
        Boolean cond1 = typeVal.contains('Medicare/Medicaid') || typeVal.contains('Medicaid or CHIP Subsidy') || typeVal.contains('Other Coverage');
        Boolean cond2 = typeVal.contains('Military Leave') || typeVal.contains('Family and Medical Leave (FMLA)');
        return ((cond1) && subTypeVal.contains('Lose Eligibility'))
            || ((cond2) && subTypeVal.contains('Return'))
            || typeVal.contains('Court Order');
    }

    private static void sendErrorEmail(Exception e, Case qleCase) {
        try {
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            String emailBody = 'Error in ARC_SGQLEBaseService.processSmallGroupQLE, with Case ID: ' + qleCase.Id + 
                               '\n\nError: ' + e.getMessage() +
                               '\n\nStack Trace: ' + e.getStackTraceString();
            ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in Small Group QLE Service Execution', apexErrorEmail);
        } catch (Exception ex) {
            System.debug('The error email could not be sent:' + ex.getMessage());
        }
    }

    public class QLEExecutionException extends Exception {}

    public static Map<String, Object> saveQLERequestSnapshot(Id caseId, String payloadJson) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            if (caseId == null) {
                throw new QLEExecutionException('Case ID is required');
            }
            if (String.isBlank(payloadJson)) {
                throw new QLEExecutionException('Payload JSON is required');
            }
        
            Case qleCase = [
                SELECT Id,
                    Status,
                    ARC_QLE_RequestPayload__c,
                    ARC_QLE_SubmittedDateTime__c,
                    ARC_PersonAccount__r.ARC_GroupAccount__c,
                    ARC_PersonAccount__r.ARC_GroupAccount__r.Name
                FROM Case
                WHERE Id = :caseId
                LIMIT 1
            ];
        
            // Evaluate QLE Changes and then call the QLE DocuSign class to build all the required information for the envelope based on the payload
            // Evaluate reasons and changes based on Payload
            Map<String,Object> payloadMap = (Map<String,Object>) JSON.deserializeUntyped(payloadJson);
            Map<String,Object> updatedPayload = ARC_SG_Utilities.evaluateChanges(payloadMap);

            ARC_SGQLE_DocuSign docuSignHandler = new ARC_SGQLE_DocuSign();
            docuSignHandler.getDocuSignData(updatedPayload);

            String subject = docuSignHandler.subject;
            String signerListJson = JSON.serialize(docuSignHandler.signerList);
            String docuSignTemplatesJson = JSON.serialize(docuSignHandler.docuSignTemplates);
            String tabsMapJson = JSON.serialize(docuSignHandler.tabsMap);

            ARC_DocuSignApi.sendCompositeEnvelopeSmallGroup(subject, signerListJson, docuSignTemplatesJson, tabsMapJson, caseId);

            qleCase.ARC_QLE_RequestPayload__c = JSON.serialize(updatedPayload);
            qleCase.ARC_QLE_SubmittedDateTime__c = System.now();
            qleCase.Status = 'Awaiting Signature';
            Set<String> allowedStatuses = new Set<String>{'Awaiting Signature'};
            if (!allowedStatuses.contains(qleCase.Status)) {
                throw new QLEExecutionException(
                    'Case must be in an allowed status before saving the QLE snapshot. Current status: ' + qleCase.Status
                );
            }
            update qleCase;
        
            response = new Map<String, Object>{
                'success' => true,
                'caseId' => qleCase.Id,
                'caseStatus' => qleCase.Status,
                'submittedDateTime' => qleCase.ARC_QLE_SubmittedDateTime__c,
                'groupAccountId' => qleCase.ARC_PersonAccount__r != null
                    ? qleCase.ARC_PersonAccount__r.ARC_GroupAccount__c
                    : null,
                'groupAccountName' => qleCase.ARC_PersonAccount__r != null &&
                    qleCase.ARC_PersonAccount__r.ARC_GroupAccount__r != null
                    ? qleCase.ARC_PersonAccount__r.ARC_GroupAccount__r.Name
                    : null
            };
        } catch (Exception e) {
            System.debug('Error occurred while processing QLE data: ' + e.getMessage());
            response = new Map<String, Object>{
                'success' => false,
                'errorMessage' => e.getMessage(),
                'errorStackTrace' => e.getStackTraceString()
            };
        }
        return response;
    }

    public class ReprocessQLEResult {
        @InvocableVariable(label='Is Success' description='Indicates if the reprocess finished successfully')
        public Boolean isSuccess;
    }

    @InvocableMethod(label='Reprocess QLE' description='This method will reprocess the QLE')
    public static List<ReprocessQLEResult> reprocessQLE(List<Id> setCaseId) {
        List<ReprocessQLEResult> results = new List<ReprocessQLEResult>();

        for (Id caseId : setCaseId) {
            execute(caseId, null);

            ReprocessQLEResult result = new ReprocessQLEResult();
            Case processedCase = [SELECT ARC_QLE_ExecutionStatus__c, ARC_QLE_LastExecutionError__c 
                                  FROM Case 
                                  WHERE Id = :caseId LIMIT 1];
            
            if (processedCase.ARC_QLE_ExecutionStatus__c == 'Failed') {
                result.isSuccess = false;
            } else {
                result.isSuccess = true;
            }
            
            results.add(result);
        }
        return results;
    }

    /**
     * Saves an invalid QLE payload and its validation errors on the Case.
     * The business status and submitted datetime are not updated for invalid payloads.
     */
    public static Map<String, Object> saveInvalidQLEPayload(Id caseId, String payloadJson, List<String> validationErrors) {
        if (caseId == null) {
            throw new QLEExecutionException('Case ID is required.');
        }

        Case qleCase = [
            SELECT Id,
                   Status,
                   ARC_QLE_InvalidPayload__c,
                   ARC_QLE_LastExecutionError__c,
                   ARC_QLE_ExecutionStatus__c,
                   ARC_QLE_SubmittedDateTime__c,
                   ARC_PersonAccount__r.ARC_GroupAccount__c,
                   ARC_PersonAccount__r.ARC_GroupAccount__r.Name
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];

        qleCase.ARC_QLE_InvalidPayload__c = payloadJson;
        qleCase.ARC_QLE_LastExecutionError__c = ARC_SGQLEHelper.buildValidationErrorMessage(validationErrors);
        qleCase.ARC_QLE_ExecutionStatus__c = 'Failed';

        update qleCase;

        return new Map<String, Object>{
            'success' => false,
            'caseId' => qleCase.Id,
            'caseStatus' => qleCase.Status,
            'executionStatus' => qleCase.ARC_QLE_ExecutionStatus__c,
            'groupAccountId' => qleCase.ARC_PersonAccount__r != null ? qleCase.ARC_PersonAccount__r.ARC_GroupAccount__c : null,
            'groupAccountName' => qleCase.ARC_PersonAccount__r != null && qleCase.ARC_PersonAccount__r.ARC_GroupAccount__r != null
                ? qleCase.ARC_PersonAccount__r.ARC_GroupAccount__r.Name
                : null
        };
    }
}