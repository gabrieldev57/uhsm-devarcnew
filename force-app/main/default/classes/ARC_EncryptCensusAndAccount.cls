global without sharing class ARC_EncryptCensusAndAccount implements vlocity_ins.VlocityOpenInterface{

    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){

        Boolean result = false;
        if (methodName == 'ARC_EncryptCensusAndAccount') {
            ARC_EncryptCensusAndAccount(inputMap, outMap);
        }
        result = true;
        return result;

    }

    public static void ARC_EncryptCensusAndAccount(Map<String,Object> inputMap, Map<String,Object> outMap) {
        String encryptedCensusId = (String)inputMap.get('CensusId');
        // String encryptedAccountId = (String)inputMap.get('AccountId');
        // String encryptedOpportunityId = (String)inputMap.get('OpportunityId');
        // String encryptedCensusMemberId = (String)inputMap.get('CensusMemberId');
        // String encryptedContractRecordTypeId = (String)inputMap.get('ContractRecordTypeId');
        // String encryptedContractId = (String)inputMap.get('ContractId');
        String userId = (String)inputMap.get('UserId');

        outMap.put('CensusId', vlocity_ins.UserSecurity.encryptForUser(encryptedCensusId, userId));
        // outMap.put('AccountId', vlocity_ins.UserSecurity.encryptForUser(encryptedAccountId, userId));
        // outMap.put('OpportunityId', vlocity_ins.UserSecurity.encryptForUser(encryptedOpportunityId, userId));
        // outMap.put('CensusMemberId', vlocity_ins.UserSecurity.encryptForUser(encryptedAccountId, userId));
        // outMap.put('ContractRecordTypeId', vlocity_ins.UserSecurity.encryptForUser(encryptedContractRecordTypeId, userId));
        // outMap.put('ContractId', vlocity_ins.UserSecurity.encryptForUser(encryptedContractId, userId));
    }
}