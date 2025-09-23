public with sharing class ARC_CheckForDuplicateClaimHandler {
    
    @AuraEnabled
    public static String CheckForDuplicateClaim(List<Id> claimList) {
        String returnMessage = 'noDuplicates';
        List<Claim> claimFields = [
            SELECT Id, Name, ARC_MemberContact__c, PolicyNumberId, ARC_ClaimTotalAmount__c, ARC_DOSFrom__c, ARC_Vendor__r.Name, ARC_PlaceOfService__c, ARC_PartialDuplicate__c, ARC_Duplicate__c, ARC_Duplicate_SMB__c
            FROM Claim
            WHERE Id IN: claimList AND ARC_Copied__c = false AND ARC_Adjust__c = false];
        if(claimFields.size() == 0) return returnMessage;

        // GET MEMBERS AND POLICIES
        Set<Id> memberIds = new Set<Id>();
        Set<Id> policyIds = new Set<Id>();
        for(Claim claim : claimFields) {
            memberIds.add(claim.ARC_MemberContact__c);
            policyIds.add(claim.PolicyNumberId);
        }

        // GET CLAIMS WITH SAME MEMBER AND POLICY
        List<Claim> claimsToCheck = [
            SELECT Id, ARC_Vendor__r.Name, ARC_DOSFrom__c, ARC_ClaimTotalAmount__c, ARC_PlaceOfService__c, ARC_MemberContact__c, PolicyNumberId 
            FROM Claim 
            WHERE ARC_MemberContact__c = :memberIds AND ARC_MemberContact__c != null AND
            PolicyNumberId = :policyIds AND PolicyNumberId != null AND
            Id NOT IN: claimList AND ARC_Copied__c = false AND ARC_Adjust__c = false];
        if(claimsToCheck.size() == 0) return returnMessage;

        // CHECK IF CLAIMS ARE DUPLICATES
        List<Claim> claimsToUpdate = new List<Claim>();
        for (Claim claim : claimFields) {            
            Boolean partDuplicate = false;
            Boolean duplicate = false;
            Id duplicateId = null;

            for(Claim c : claimsToCheck) {
                if(
                    c.ARC_MemberContact__c != claim.ARC_MemberContact__c || // MEMBER
                    c.PolicyNumberId != claim.PolicyNumberId // POLICY
                ) continue; 

                if(c.ARC_DOSFrom__c != claim.ARC_DOSFrom__c) continue; 
                partDuplicate = true;
                returnMessage = 'partialDuplicate';
                duplicateId = c.Id;

                if(
                    c.ARC_ClaimTotalAmount__c == claim.ARC_ClaimTotalAmount__c && // TOTAL AMOUNT
                    c.ARC_Vendor__r.Name == claim.ARC_Vendor__r.Name // VENDOR NAME
                ) {
                    duplicate = true;
                    returnMessage = 'duplicate';
                    break;
                }
            }
            
            // FLAG IT AS DUPLICATE
            claim.ARC_PartialDuplicate__c = partDuplicate;
            claim.ARC_Duplicate__c = duplicate;
            claim.De_Duplicate_Flag__c = true;

            if(claim.Name.contains(' - (PARTIAL DUPLICATE)')) claim.Name = claim.Name.replace(' - (PARTIAL DUPLICATE)', '');
            else if(claim.Name.contains(' - (DUPLICATE)')) claim.Name = claim.Name.replace(' - (DUPLICATE)', '');
            claim.Name = claim.Name + (duplicate ? ' - (DUPLICATE)' : partDuplicate ? ' - (PARTIAL DUPLICATE)' : '');

            claim.ARC_Duplicate_SMB__c = duplicateId;
            claimsToUpdate.add(claim);
        }

        update claimsToUpdate;
        return returnMessage;
    }
    
    @AuraEnabled
    public static Claim getDuplicateClaims(String clmId){
        return [SELECT Name, Id FROM Claim WHERE Id =: clmId LIMIT 1];
    }
}