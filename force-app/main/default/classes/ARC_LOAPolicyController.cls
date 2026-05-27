public without sharing class ARC_LOAPolicyController {

    private static final String LOA = 'Leave of Absence';

    public class LOARecord {
        @AuraEnabled public Id policyId;
        @AuraEnabled public Date submittedDate;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String reason;
        @AuraEnabled public String policyNumber;
      //  @AuraEnabled public Id memberAccountId;
      //  @AuraEnabled public String employeeName;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<LOARecord> getPoliciesWithQLE(Id memberAccountId) {
        List<LOARecord> results = new List<LOARecord>();

        try {
            List<InsurancePolicy> policies = [
                SELECT Id, Name, NameInsuredId,
                    ARC_Reason__c, CreatedDate,
                    ARC_PolicyEffectiveDate__c, ARC_PolicyExpirationDate__c, OriginalPolicyId, Status
                FROM InsurancePolicy
                WHERE ARC_Reason__c = 'Reinstatement'
                AND NameInsuredId = :memberAccountId
                AND Status != 'Voided'
                ORDER BY CreatedDate DESC
            ];

            if (policies.isEmpty()) return results;

            List<Case> allQLEs = [
                SELECT Id, ARC_Reason__c, arcsona__EventDate__c,
                    ARC_QLEEffectiveDate__c, CreatedDate,
                    ARC_PersonAccount__c, Subject, ARC_QLEType__c
                FROM Case
                WHERE ARC_PersonAccount__c = :memberAccountId
                AND ARC_Reason__c = :LOA
                AND RecordType.DeveloperName = 'ARC_QualifyEvent'
                AND ARC_QLEType__c = :LOA
                AND Subject = :LOA
                ORDER BY CreatedDate DESC
            ];

            Set<Id> usedQleIds = new Set<Id>();

            for (InsurancePolicy policy : policies) {
                Datetime policyCreatedDatetime = policy.CreatedDate;

                Case closest;
                Long minDiff;

                for (Case qle : allQLEs) {
                    if (usedQleIds.contains(qle.Id)) continue;
                    Long diff = Math.abs(
                        policyCreatedDatetime.getTime() - qle.CreatedDate.getTime()
                    );

                    if (minDiff == null || diff < minDiff) {
                        minDiff = diff;
                        closest = qle;
                    }
                }

                if (closest == null) continue;

                if (minDiff > 60000) {
                    System.debug('Warning: No close QLE found for policy ' + policy.Id + ', closest diff was ' + minDiff + 'ms');
                    continue;
                }

                usedQleIds.add(closest.Id);
                LOARecord record = new LOARecord();
                record.policyId      = policy.Id;
                record.policyNumber  = policy.Name;
                record.submittedDate = closest.CreatedDate.date();
                record.startDate     = closest.arcsona__EventDate__c;   
                record.endDate       = closest.ARC_QLEEffectiveDate__c; 
                record.reason        = closest.ARC_Reason__c;

                results.add(record);
            }

            return results;

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage() + ' - ' + e.getStackTraceString());
            throw new AuraHandledException('Error getting data: ' + e.getMessage());
        }
    }
    public class LOAUpdateRequest {
        @AuraEnabled public Id policyId;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate ;
    }
    
    @AuraEnabled
    public static void updateLOADates(Map<String, Object> payload) {
        
        if (payload == null || !payload.containsKey('updates') || !payload.containsKey('memberAccountId')) {
            throw new AuraHandledException('Invalid payload structure');
        }
        
        Id memberAccountId;
        try {
            memberAccountId = Id.valueOf((String) payload.get('memberAccountId'));
        } catch (Exception e) {
            throw new AuraHandledException('Invalid memberAccountId: ' + e.getMessage());
        }
        
        List<LOAUpdateRequest> updates = new List<LOAUpdateRequest>();
        
        Object updatesObj = payload.get('updates');
        
        if (updatesObj instanceof List<Object>) {
            List<Object> updatesList = (List<Object>) updatesObj;
            
            for (Object obj : updatesList) {
                Map<String, Object> updateMap = new Map<String, Object>();
                
                if (obj instanceof Map<String, Object>) {
                    updateMap = (Map<String, Object>) obj;
                } else if (obj instanceof Map<Object, Object>) {
                    Map<Object, Object> tempMap = (Map<Object, Object>) obj;
                    for (Object key : tempMap.keySet()) {
                        if (key != null) {
                            updateMap.put(String.valueOf(key), tempMap.get(key));
                        }
                    }
                } else {
                    System.debug('Unexpected type: ' + obj);
                    continue;
                }
                
                LOAUpdateRequest req = new LOAUpdateRequest();
                
                if (updateMap.containsKey('policyId') && updateMap.get('policyId') != null) {
                    req.policyId = Id.valueOf((String) updateMap.get('policyId'));
                } else {
                    throw new AuraHandledException('policyId is required');
                }
                
                if (updateMap.containsKey('startDate') && updateMap.get('startDate') != null) {
                    req.startDate = Date.valueOf((String) updateMap.get('startDate'));
                } else {
                    throw new AuraHandledException('startDate is required');
                }
                
                if (updateMap.containsKey('endDate') && updateMap.get('endDate') != null) {
                    req.endDate = Date.valueOf((String) updateMap.get('endDate'));
                } else {
                    throw new AuraHandledException('endDate is required');
                }
                
                updates.add(req);
            }
        }
        
        
        if (updates.isEmpty()) {
            throw new AuraHandledException('No valid updates found');
        }

        if (updates == null || updates.isEmpty()) return;

        Map<Id, LOAUpdateRequest> requestByPolicy = new Map<Id, LOAUpdateRequest>();
        for (LOAUpdateRequest r : updates) {
            requestByPolicy.put(r.policyId, r);
        }

        List<InsurancePolicy> reinstatementPolicies = [
            SELECT Id, CreatedDate, ARC_PolicyEffectiveDate__c,  ARC_PolicyExpirationDate__c, OriginalPolicyId, NameInsuredId
            FROM InsurancePolicy
            WHERE Id IN :requestByPolicy.keySet()
        ];

        System.debug('founded policies: ' + reinstatementPolicies.size());
        System.debug('policies: ' + JSON.serialize(reinstatementPolicies));

        Set<Id> originalPoliciesIds = new Set<Id>();

        for (InsurancePolicy p : reinstatementPolicies) {
            originalPoliciesIds.add(p.OriginalPolicyId);
        }

        Map<Id, InsurancePolicy> originalPolicies = new Map<Id, InsurancePolicy>();

        for (InsurancePolicy p : [
            SELECT Id, Name, NameInsuredId, ARC_PolicyExpirationDate__c, CreatedDate
            FROM InsurancePolicy
            WHERE Id IN :originalPoliciesIds
        ]) {
            originalPolicies.put(p.Id, p);
        }

        Map<Id, List<Case>> qlesByMember = new Map<Id, List<Case>>();

        for (Case c : [
            SELECT Id, ARC_PersonAccount__c,
                arcsona__EventDate__c,
                ARC_QLEEffectiveDate__c,
                CreatedDate, Subject, ARC_QLEType__c
            FROM Case
            WHERE ARC_PersonAccount__c = :memberAccountId
            AND ARC_Reason__c = :LOA
            AND RecordType.DeveloperName = 'ARC_QualifyEvent'
            AND Subject = :LOA
            AND ARC_QLEType__c = :LOA
        ]) {

            if (!qlesByMember.containsKey(c.ARC_PersonAccount__c)) {
                qlesByMember.put(c.ARC_PersonAccount__c, new List<Case>());
            }

            qlesByMember.get(c.ARC_PersonAccount__c).add(c);
        }

        Map<Id, InsurancePolicy> originalsToUpdate = new Map<Id, InsurancePolicy>();
        Map<Id, InsurancePolicy> reinstatementsToUpdate = new Map<Id, InsurancePolicy>();
        Map<Id, Case> qlesToUpdate = new Map<Id, Case>();

        for (InsurancePolicy policy : reinstatementPolicies) {

            LOAUpdateRequest req = requestByPolicy.get(policy.Id);
        
            if (req.startDate == null || req.endDate == null) {
                continue;
            }

            InsurancePolicy original = originalPolicies.get(policy.OriginalPolicyId);

            if (original == null) continue;
            
            
            Date expiration =
                Date.newInstance(
                    req.startDate.year(),
                    req.startDate.month(),
                    Date.daysInMonth(req.startDate.year(), req.startDate.month())
                );


            Date effective =
                Date.newInstance(req.endDate.year(), req.endDate.month(), 1)
                .addMonths(1);

            original.ARC_PolicyExpirationDate__c = expiration;
            originalsToUpdate.put(original.Id, original);

            policy.ARC_PolicyEffectiveDate__c = effective;
            //policy.ARC_StartDate__c = req.startDate;
           // policy.ARC_PolicyExpirationDate__c = req.endDate;
            reinstatementsToUpdate.put(policy.Id, policy);

            List<Case> memberQLEs = qlesByMember.get(policy.NameInsuredId);
            if (memberQLEs == null) continue;

            Case closest;
            Long minDiff; 

            Set<Id> usedQleIdsForUpdate = new Set<Id>(); 

            for (Case q : memberQLEs) {
                if (usedQleIdsForUpdate.contains(q.Id)) continue;
                Long diff = Math.abs(policy.CreatedDate.getTime() - q.CreatedDate.getTime());
                if (minDiff == null || diff < minDiff) {
                    minDiff = diff;
                    closest = q;
                }
            }

            if (closest != null && minDiff <= 60000) { 
                usedQleIdsForUpdate.add(closest.Id);
                closest.arcsona__EventDate__c = req.startDate;
                closest.ARC_QLEEffectiveDate__c = req.endDate;
                qlesToUpdate.put(closest.Id, closest);
            }
        }

        Savepoint sp = Database.setSavepoint();

        try {

            if (!originalsToUpdate.isEmpty())
                update originalsToUpdate.values();

            if (!reinstatementsToUpdate.isEmpty())
                update reinstatementsToUpdate.values();

            if (!qlesToUpdate.isEmpty())
                update qlesToUpdate.values();

        } catch (Exception e) {

            Database.rollback(sp);
            throw e;

        }
    }
}