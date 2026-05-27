public with sharing class ARC_ClaimMemberLayoutController {
    
    @AuraEnabled
    public static Map<String, Object> getPolicyParticipants(String name, Date birthdate, String street, Date dosFrom, Date dosTo) {
        Map<String, Object> result = new Map<String, Object>();
    
        List<InsurancePolicyParticipant> firstQueryResults = [
            SELECT Id, Role, PrimaryParticipantContact.Name, PrimaryParticipantContact.Birthdate, PrimaryParticipantContact.Account.BillingStreet, PrimaryParticipantContact.Account.BillingCity, PrimaryParticipantContact.Account.BillingPostalCode, PrimaryParticipantContact.Account.BillingState, InsurancePolicy.ARC_EffectiveDate__c, InsurancePolicy.ARC_ExpirationDate__c, IsActiveParticipant, InsurancePolicy.ARC_Contract__r.Status 
            FROM InsurancePolicyParticipant 
            WHERE (PrimaryParticipantContact.Name = :name OR PrimaryParticipantContact.Birthdate = :birthdate OR PrimaryParticipantContact.Account.BillingStreet = :street)
                AND InsurancePolicy.ARC_EffectiveDate__c <= :dosFrom
                AND ((InsurancePolicy.ARC_ExpirationDate__c = null AND InsurancePolicy.ARC_isActive__c = true) OR InsurancePolicy.ARC_ExpirationDate__c >= :dosTo) 
            ORDER BY InsurancePolicy.ARC_EffectiveDate__c DESC LIMIT 100
        ];
    
        List<InsurancePolicyParticipant> secondQueryResults = [
            SELECT Id, Role, PrimaryParticipantContact.Name, PrimaryParticipantContact.Birthdate, PrimaryParticipantContact.Account.BillingStreet, PrimaryParticipantContact.Account.BillingCity, PrimaryParticipantContact.Account.BillingPostalCode, PrimaryParticipantContact.Account.BillingState, InsurancePolicy.ARC_EffectiveDate__c, InsurancePolicy.ARC_ExpirationDate__c, IsActiveParticipant, InsurancePolicy.ARC_Contract__r.Status 
            FROM InsurancePolicyParticipant 
            WHERE (PrimaryParticipantContact.Name = :name OR PrimaryParticipantContact.Birthdate = :birthdate OR PrimaryParticipantContact.Account.BillingStreet = :street)
            ORDER BY InsurancePolicy.ARC_EffectiveDate__c DESC LIMIT 100
        ];
    
        if (secondQueryResults.size() == 0) {
            result.put('message', 'NoPP');
        } else if (firstQueryResults.size() == 0) {
            result.put('message', 'InvalidPP');
        } else if (secondQueryResults.size() > firstQueryResults.size()) {
            result.put('message', 'SomeInvalidPP');
        } else {
            result.put('message', 'OKPP');
        }
    
        result.put('polparts1', firstQueryResults);
        result.put('polparts2', secondQueryResults);
    
        return result;
    }


    @AuraEnabled
    public static String selectPolParticipant(String claimId, String participantId) {
        String output = 'Not updated';

        Claim clm = [SELECT Name, ARC_PatientCensusMember__c, ARC_MemberContact__c, ARC_PrimaryMemberCM__c, ARC_Primary_Member__c, ARC_ParticipantPolicyParticipant__c, PolicyNumberId, ARC_DOSFrom__c, ARC_DOSTo__c, ARC_ClaimInput__c, ARC_CCToCompare__c FROM Claim WHERE Id=: claimId];

        InsurancePolicyParticipant polPart = [
            SELECT Id, InsurancePolicyId, PrimaryParticipantContactId, PrimaryParticipantContact.AccountId, InsurancePolicy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c , InsurancePolicy.RecordType.Name,
            (
                SELECT ARC_PolicyCoverage__c
                FROM Coverage_Participants__r
                WHERE ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
                    AND ARC_PolicyCoverage__r.ARC_ParentProduct__c = null
            )
            FROM InsurancePolicyParticipant 
            WHERE Id =: participantId
        ];

        List<vlocity_ins__GroupCensusMember__c> censusMembers = [
            SELECT Id, vlocity_ins__ContactId__c, vlocity_ins__RelatedCensusMemberId__c, 
                vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c, vlocity_ins__CensusId__c 
            FROM vlocity_ins__GroupCensusMember__c 
            WHERE vlocity_ins__ContactId__c =: polPart.PrimaryParticipantContactId
        ];
        
        // POPULATE CLAIM
        for (vlocity_ins__GroupCensusMember__c cm : censusMembers) {
            if (polPart.InsurancePolicy.RecordType.Name == 'Individual And Family' && cm.vlocity_ins__CensusId__c != polPart.InsurancePolicy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c) continue;

            clm.ARC_PatientCensusMember__c = cm.Id;
            clm.ARC_MemberContact__c = polPart.PrimaryParticipantContactId;
            clm.ARC_ParticipantPolicyParticipant__c = polPart.Id;
            clm.PolicyNumberId = polPart.InsurancePolicyId;
            if (!polPart.Coverage_Participants__r.isEmpty())
                clm.ARC_PatientMedicalPolicyCoverage__c = polPart.Coverage_Participants__r[0].ARC_PolicyCoverage__c;

            if (cm.vlocity_ins__RelatedCensusMemberId__c == null) {
                clm.ARC_PrimaryMemberCM__c = cm.Id;
                clm.ARC_Primary_Member__c = polPart.PrimaryParticipantContactId;
            } else {
                clm.ARC_PrimaryMemberCM__c = cm.vlocity_ins__RelatedCensusMemberId__c;
                clm.ARC_Primary_Member__c = cm.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c; 
            }
        }

        try {
            update clm;
            output = 'Updated';
            // AFTER UPDATE THE CLAIM CHECK IF IT'S A DUPLICATE ONLY IF WAS CREATED WITH MAPPING
            if (clm.ARC_CCToCompare__c != null) ARC_CheckForDuplicateClaimHandler.CheckForDuplicateClaim(new List<Id>{clm.Id});
        } catch (Exception e) {
            output = 'Update error';
            throw new AuraHandledException('An error occurred while updating the claim: ' + e.getMessage());
        }

        return output;
    }


    @AuraEnabled
    public static String resetPatient(String claimId) {
        // RESET CLAIM ITEMS
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('claimId', claimId);
        ARC_CoveragePaymentsTableController reset = new ARC_CoveragePaymentsTableController();
        reset.invokeMethod('uncommitAllChanges', input, output, options);

        Claim clm = new Claim();
        clm.Id = claimId;
        clm.ARC_PatientCensusMember__c = null;
        clm.ARC_MemberContact__c = null;
        clm.ARC_PrimaryMemberCM__c = null;
        clm.ARC_Primary_Member__c = null;
        clm.ARC_ParticipantPolicyParticipant__c = null;
        clm.PolicyNumberId = null;
        clm.ARC_PatientMedicalPolicyCoverage__c = null;

        try {
            update clm;    
            return 'updated';
        } catch (Exception e) {
            System.debug('Error ' + e.getMessage());
            return 'error';
        }
    }
    

    @AuraEnabled
    public static String policyAssignment(String member, String policy, String claimId) {
        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id, Name, vlocity_ins__RelatedCensusMemberId__c, vlocity_ins__ContactId__c, vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE Id =: member];
        Claim clm = new Claim();
        clm.Id = claimId;

        // CHECK FOR POLICY
        if (policy != null) {
            InsurancePolicyParticipant polPart = [
                SELECT Id, 
                (
                    SELECT ARC_PolicyCoverage__c
                    FROM Coverage_Participants__r
                    WHERE ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
                        AND ARC_PolicyCoverage__r.ARC_ParentProduct__c = null
                )
                FROM InsurancePolicyParticipant 
                WHERE InsurancePolicyId =: policy AND PrimaryParticipantContact.ARC_CensusMember__c =: censusMember.Id
            ];
            
            clm.PolicyNumberId = policy;
            clm.ARC_ParticipantPolicyParticipant__c = polPart.Id;
            if (!polPart.Coverage_Participants__r.isEmpty())
                clm.ARC_PatientMedicalPolicyCoverage__c = polPart.Coverage_Participants__r[0].ARC_PolicyCoverage__c;
        }

        // POPULATE CLAIM
        clm.ARC_PatientCensusMember__c = censusMember.Id;
        clm.ARC_MemberContact__c = censusMember.vlocity_ins__ContactId__c;
        clm.ARC_PrimaryMemberCM__c = censusMember.vlocity_ins__RelatedCensusMemberId__c == null ? censusMember.Id : censusMember.vlocity_ins__RelatedCensusMemberId__c;
        clm.ARC_Primary_Member__c = censusMember.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c == null ? censusMember.vlocity_ins__ContactId__c : censusMember.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__c;
        
        try {
            update clm;
            return 'updated';
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            return 'error';
        }
    }
}