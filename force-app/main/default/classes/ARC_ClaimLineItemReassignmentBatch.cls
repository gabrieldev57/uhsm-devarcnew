global class ARC_ClaimLineItemReassignmentBatch 
    implements Database.Batchable<sObject>, Database.Stateful {

    private Set<Id> aggregatorIds;
    private Boolean updateRecords;
    private List<String> reportLines = new List<String>();
    private List<String> errorLines = new List<String>();


    global ARC_ClaimLineItemReassignmentBatch(Set<Id> aggregatorIds, Boolean updateRecords) {
        this.aggregatorIds = aggregatorIds;
        this.updateRecords = updateRecords;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        list<ARC_ParticipantAggregator__c> partAggsList = [SELECT ARC_Policy__c, ARC_PolicyParticipant__r.Participant_Account_Id__c FROM ARC_ParticipantAggregator__c WHERE ARC_Aggregator__c IN :aggregatorIds];

        Set<Id> scopedPolicies = new Set<Id>();
        Set<Id> scopedAccounts = new Set<Id>();
        for (ARC_ParticipantAggregator__c partagg :partAggsList) {
            scopedPolicies.add(partagg.ARC_Policy__c);
            scopedAccounts.add(partagg.ARC_PolicyParticipant__r.Participant_Account_Id__c);
        }   
        return Database.getQueryLocator([
            SELECT Id, ARC_Deductible__c, ARC_Coinsurance__c, ARC_ProcedureCodeName__c,
                   ARC_Claim__r.Id, ARC_Claim__r.PolicyNumberId, ARC_Claim__r.ARC_DOSFrom__c
            FROM ClaimCoveragePaymentDetail
            WHERE ARC_Claim__r.PolicyNumberId != NULL
              AND ARC_Claim__r.ARC_DOSFrom__c != NULL
              AND ARC_ProcedureCodeName__c IN ('99211','99212','99213','99214','99215')
              AND ARC_Deductible__c > 0
              AND ARC_Claim__r.PolicyNumberId IN :scopedPolicies
              AND ARC_Claim__r.ARC_MemberContact__r.AccountId IN :scopedAccounts
        ]);
    }

    global void execute(Database.BatchableContext bc, List<ClaimCoveragePaymentDetail> scope) {
        List<ClaimCoveragePaymentDetail> smbToUpdate = new List<ClaimCoveragePaymentDetail>(); 
        List<ARC_ParticipantAggregator__c> partAggToUpdate = new List<ARC_ParticipantAggregator__c>(); 
        Map<String, ARC_ParticipantAggregator__c> participantAggsMap = new Map<String, ARC_ParticipantAggregator__c>();


        // preload participant aggregators for this scope
        Set<Id> policyIds = new Set<Id>();
        Set<String> years = new Set<String>();
        for (ClaimCoveragePaymentDetail smb : scope) {
            policyIds.add(smb.ARC_Claim__r.PolicyNumberId);
            years.add(String.valueOf(smb.ARC_Claim__r.ARC_DOSFrom__c.year()));
        }

        List<ARC_ParticipantAggregator__c> participantAggs = [
            SELECT Id, ARC_Aggregator__r.ARC_Code__c, ARC_Aggregator__r.ARC_Year__c,
                   ARC_ConsumedValue__c, ARC_Policy__c
            FROM ARC_ParticipantAggregator__c
            WHERE ARC_Policy__c IN :policyIds
              AND ARC_Aggregator__r.ARC_Year__c IN :years
              AND ARC_Aggregator__r.ARC_Code__c IN ('AMCS__c','SHAMCS__c')
        ];
        for (ARC_ParticipantAggregator__c pa : participantAggs) {
            String key = pa.ARC_Policy__c + '-' + pa.ARC_Aggregator__r.ARC_Code__c + '-' + pa.ARC_Aggregator__r.ARC_Year__c;
            participantAggsMap.put(key, pa);
        }

        for (ClaimCoveragePaymentDetail smb : scope) {
            Decimal x = smb.ARC_Deductible__c;
            if (x == null || x == 0) continue;

            String yearStr = String.valueOf(smb.ARC_Claim__r.ARC_DOSFrom__c.year());
            String policyId = smb.ARC_Claim__r.PolicyNumberId;

            // Keys for participant aggregators
            String amcsKey = policyId + '-AMCS__c-' + yearStr;
            String shamcsKey = policyId + '-SHAMCS__c-' + yearStr;

            ARC_ParticipantAggregator__c amcs = participantAggsMap.get(amcsKey);
            ARC_ParticipantAggregator__c shamcs = participantAggsMap.get(shamcsKey);

            if (amcs == null || shamcs == null) {
                errorLines.add('Missing aggregator for SMB Id ' + smb.Id + 
                               ' (Policy=' + policyId + ', Year=' + yearStr + ')');
                continue;
            }

            // Report line
            reportLines.add('SMB ' + smb.Id + ' move ' + x + ' from Deductible to Coinsurance. ' + 'AMCS Agg ' + amcs.Id + ' -' + x + ', SHAMCS Agg ' + shamcs.Id + ' +' + x);

            if (updateRecords) {
                smb.ARC_Deductible__c = 0;
                smb.ARC_Coinsurance__c = (smb.ARC_Coinsurance__c == null ? 0 : smb.ARC_Coinsurance__c) + x;
                smbToUpdate.add(smb);

                amcs.ARC_ConsumedValue__c -= x;
                shamcs.ARC_ConsumedValue__c += x;
                partAggToUpdate.add(amcs);
                partAggToUpdate.add(shamcs);
            }
        }

        if (updateRecords) {
            update smbToUpdate;
            update partAggToUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        String body = 'Report Mode: ' + updateRecords + '\n\n--- Updates ---\n' +
                      String.join(reportLines, '\n') +
                      '\n\n--- Errors ---\n' +
                      String.join(errorLines, '\n');

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { 'ignacio.ferreiro@arcsona.com' });
        email.setSubject('SMB Item Reassignment Batch Report');
        email.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}