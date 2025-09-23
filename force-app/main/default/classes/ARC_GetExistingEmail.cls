global without sharing class ARC_GetExistingEmail implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'getExistingEmail') {
            ARC_GetExistingEmail(inputMap, outputMap, options);
        }
        return true;
    }

    public static void ARC_GetExistingEmail(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {

        String email = (String)inputMap.get('email');
        String phone = '+1'+(String)inputMap.get('phone');

        List<Account> matchingAccounts = [
            SELECT Id,Census_Member__c 
            FROM Account 
            WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' 
            AND ( PersonEmail =: email OR Phone =: phone )];

        Set<Id> censusMemberIds = new Set<Id>();
        for ( Account a : matchingAccounts) {
            censusMemberIds.add(a.Census_Member__c);
        }

        List<vlocity_ins__GroupCensusMemberPlan__c> matchingPlans = [
        SELECT Id,
        vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c,
        vlocity_ins__GroupCensusMemberId__r.ARC_Phone__c
        FROM vlocity_ins__GroupCensusMemberPlan__c
        WHERE vlocity_ins__GroupCensusMemberId__c IN: censusMemberIds
        AND (vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status LIKE '%Awaiting%' OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated')
        AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
        AND vlocity_ins__ContractLineId__r.vlocity_ins__ParentItemId__c = null];

        outputMap.put('existingPhone', false);
        outputMap.put('existingEmail', false);

        for (vlocity_ins__GroupCensusMemberPlan__c p : matchingPlans) {
            System.debug(p.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c == email);
            if (p.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c == email) {
                outputMap.put('existingEmail', true);
            }
            System.debug(p.vlocity_ins__GroupCensusMemberId__r.ARC_Phone__c);
            System.debug(phone);
            if (p.vlocity_ins__GroupCensusMemberId__r.ARC_Phone__c == phone){
                outputMap.put('existingPhone', true);
            }
        }
    }
}