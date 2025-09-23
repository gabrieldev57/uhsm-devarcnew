global without sharing class ARC_ProgramChangeHandlerAgustina implements vlocity_ins.VlocityOpenInterface {

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'upsertGuardian') {
            upsertGuardian(inputMap, outputMap, options);
        } else if (methodName == 'insertCaseForFeedSkipped') {
            insertCaseForFeedSkipped(inputMap, outputMap, options);
        }
        
        return true;
    }

   /*******************************************************************
    * @MethodName         :   upsertGuardian
    * @Description        :   insert or update a guardian
    ********************************************************************/
    private void upsertGuardian(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {

        Map<String, Object> guardianInfo = (Map<String, Object>) inputMap.get('STEP_GuardiansInfo');
        String GuardianPhysicalStreetApt = (String)inputMap.get('GuardianPhysicalStreetApt');
        
        if (guardianInfo != null) {
            Map<String, Object> ssnMap = (Map<String, Object>) guardianInfo.get('TXT_GuardianSSN');

            Account newGuardian = new Account();
    
            if (guardianInfo.containsKey('Id') && guardianInfo.get('Id') != null) {
                newGuardian.Id = (Id)guardianInfo.get('Id');
            }
    
            newGuardian.FirstName = (String)guardianInfo.get('TXT_GuardianFirstName');
            newGuardian.LastName = (String)guardianInfo.get('TXT_GuardianLastName');
            newGuardian.Phone = (String)guardianInfo.get('TXT_GuardianPhone');
            newGuardian.PersonEmail = (String)guardianInfo.get('EMAIL_GuardianEmail');
            newGuardian.PersonGender = (String)guardianInfo.get('SEL_GuardianGender');
            newGuardian.PersonBirthdate = (Date)Date.valueOf((String)guardianInfo.get('DATE_GuardianBirthdate'));
            newGuardian.ARC_SocialSecurityNumber__c = (String) ssnMap.get('response');
            newGuardian.BillingStreet = GuardianPhysicalStreetApt;
            Map<String, Object> addressBlock = (Map<String, Object>)guardianInfo.get('THEADBLK_GuardianAddress-Block');
            if (addressBlock != null) {
                newGuardian.BillingCity = (String)addressBlock.get('TXT_GuardianCity');
                newGuardian.BillingPostalCode = (String)addressBlock.get('TXT_GuardianZipCode');
                newGuardian.BillingState = (String)addressBlock.get('TXT_GuardianState');
            }
            newGuardian.ARC_GuardianRelationshipToChild__c = (String)guardianInfo.get('SEL_GuardianRelationship');
    
            //upsert newGuardian;
            //System.debug(JSON.serialize(newGuardian));
            outputMap.put('guardian', newGuardian);
        }
    }

   /*******************************************************************
    * @MethodName         :   insertCaseForFeedSkipped
    * @Description        :   create and insert a case if the fee was skipped
    ********************************************************************/
    private void insertCaseForFeedSkipped(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (inputMap.containsKey('Step_PaymentChangeFee')) {
            Map<String, Object> paymentFee = (Map<String, Object>)inputMap.get('Step_PaymentChangeFee');
            if ('No'.equals((String)paymentFee.get('RAD_ChargeAppFeeDefTrue'))) {
                Case newCase = new Case();
    
                Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'Processing' LIMIT 1].Id;
                Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
    
                newCase.RecordTypeId = recordTypeId;
                newCase.Case_Type__c = 'Program';
                newCase.ARC_Reason__c = 'Change Fee Waived';
                newCase.ARC_Type__c = 'member';
                newCase.Origin = 'system';
                newCase.Subject = 'Program change fee waived';
    
                Map<String, Object> caseDetails = (Map<String, Object>)paymentFee.get('BLK_CaseCreationDetails');
                if (caseDetails != null) {
                    newCase.Description = (String)caseDetails.get('TXT_NoChargeChangeFeeReason');
                }
    
                newCase.Status = 'New';
                newCase.OwnerId = queueId;
    
                //insert newCase;
                //System.debug(JSON.serialize(newCase));
                outputMap.put('newCase', newCase);
                outputMap.put('queueId', queueId);
                outputMap.put('recordTypeId', recordTypeId);
            }
        }
    }

}