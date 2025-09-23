@isTest
public with sharing class ARC_UpdateAccountQuestionsGuestUsersTest {
    @isTest
    public static void ARC_UpdateAccountQuestionsGuestUsersTest() {

        Map<String, Object> inputMap = new Map<String, Object>();
        Account acc = new Account(Name = 'newAccount');
        insert acc;
        inputMap.put('AccountId', acc.Id);
        inputMap.put('MedicalConditions', 'Stroke;Diabetes');
        inputMap.put('RAD_Airplane', 'Yes');
        inputMap.put('TXT_DangerousSport', 'Free Diving');
        inputMap.put('TXT_Substances', 'subs');

        ARC_UpdateAccountQuestionsGuestUsers updateAccountQuestions = new ARC_UpdateAccountQuestionsGuestUsers();
        updateAccountQuestions.invokeMethod('UpdateAccountQuestions', inputMap, new Map<String, Object>(), new Map<String, Object>());
    }
}