public with sharing class aRC_JsonTreeController {
    
    @AuraEnabled(cacheable = true)
    public static Claim getJSONInput(Id claimId) {
        Claim clm = [ SELECT Id, ARC_InputJSON__c, Name, ARC_ClaimInput__c FROM Claim WHERE Id = :claimId ];
        if ( clm.ARC_ClaimInput__c != null ) {
            ARC_ClaimInput__c cInput = [ SELECT Id, ARC_ExternalId__c, ARC_InputJSON__c FROM ARC_ClaimInput__c WHERE Id = :clm.ARC_ClaimInput__c ];
            clm.ARC_InputJSON__c = cInput.ARC_InputJSON__c;
        }
        return clm;
    }
}