global without sharing class ARC_UpdateAccountQuestionsGuestUsers implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'UpdateAccountQuestions') {
            UpdateAccountQuestions(inputMap, outputMap, options);
        }
        return true;
    }
    public static void UpdateAccountQuestions(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {

        String AccountId = String.valueOf(inputMap.get('AccountId'));
        String MedicalConditions = String.valueOf(inputMap.get('MedicalConditions'));
        String RAD_Airplane = String.valueOf(inputMap.get('RAD_Airplane'));
        String TXT_DangerousSport = String.valueOf(inputMap.get('TXT_DangerousSport'));
        String TXT_Substances = String.valueOf(inputMap.get('TXT_Substances'));

        Account acc = [SELECT ARC_Disease__c, ARC_AirplanePilot__c, ARC_DangerousSports__c, ARC_SubstancesWP__c FROM Account WHERE Id = :AccountId];

        acc.ARC_Disease__c = MedicalConditions;
        acc.ARC_AirplanePilot__c = RAD_Airplane;
        acc.ARC_DangerousSports__c = TXT_DangerousSport;
        acc.ARC_SubstancesWP__c = TXT_Substances;
        
        update acc;

        outputMap.put('Account updated', acc.Id);

    }
}