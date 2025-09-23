global without sharing class ARC_BackfillAEMasterCommission implements Database.Batchable<sObject>, Database.Stateful {

    public Set<Id> contractIds = new Set<Id>();
    public static Id rtCommAccExecutive = Schema.SObjectType.ARC_Commission__c.getRecordTypeInfosByDeveloperName().get('ARC_AccountExecutive').getRecordTypeId();
    Date oneYearBack = Date.today().addYears(-1);
    Integer newCommissionsCounter = 0;
    
    global ARC_BackfillAEMasterCommission(Set<Id> contractIds){
        if(contractIds != null) this.contractIds = contractIds;
    }

    global ARC_BackfillAEMasterCommission(){}

    global Database.QueryLocator start(Database.BatchableContext BC){
        // Question 1) Filtering by reason = New Application will I get the reprice contracts as well? 
        if(!this.contractIds.isEmpty()){
            return Database.getQueryLocator([SELECT Id,vlocity_ins__EnrollmentCensusId__c, (SELECT Id FROM Commissions__r),(SELECT Id FROM CommissionsPrime__r), Status FROM Contract WHERE ARC_Selling_Agent__c != null  AND ARC_EffectiveDate__c <= TODAY AND ARC_ContractReason__c ='New Application' AND (Status = 'Activated' OR Status = 'Terminated' OR Status = 'Voided') AND ARC_Selling_Agent__r.Profile.Name != 'Member Community Profile' AND Id IN: this.contractIds ORDER BY ARC_EffectiveDate__c ASC]);
        }
        else {
            return Database.getQueryLocator([SELECT Id,vlocity_ins__EnrollmentCensusId__c, (SELECT Id FROM CommissionsPrime__r),(SELECT Id FROM Commissions__r)  FROM Contract WHERE ARC_Selling_Agent__c != null AND  ARC_ContractReason__c = 'New Application' AND ARC_EffectiveDate__c >=: oneYearBack AND ARC_EffectiveDate__c <= TODAY AND (Status = 'Activated' OR Status = 'Terminated' OR Status = 'Voided') AND ARC_Selling_Agent__r.Profile.Name != 'Member Community Profile' ORDER BY ARC_EffectiveDate__c ASC]);
        }
    }

    global void execute(Database.BatchableContext BC, List<Contract> contractList){
        System.debug('Inside the execute');
        Set<Id> censusIds = new Set<Id>();
        for(Contract cont:contractList){
            if(cont.CommissionsPrime__r.isEmpty() && cont.Commissions__r.isEmpty()) {
                censusIds.add(cont.vlocity_ins__EnrollmentCensusId__c);
            }
        }
        
        List<vlocity_ins__GroupCensus__c> censusList = [SELECT Id, (SELECT Id, CreatedDate,ChargentOrders__Type__c,ChargentOrders__Order__r.ARC_Contract__c,ChargentOrders__Order__r.ARC_Contract__r.ARC_TotalPrice__c,ChargentOrders__Order__r.ARC_Contract__r.ARC_Selling_Agent__c, ChargentOrders__Order__r.ARC_Contract__r.ARC_Selling_Agent__r.Agent_Role__c, ChargentOrders__Order__r.ARC_Contract__r.Status FROM Transactions__r WHERE ChargentOrders__Response_Status__c = 'Approved' AND ChargentOrders__Order__r.ChargentOrders__Description__c ='Recurring Monthly Order' AND (ARC_Reason__c= 'Recurring Monthly Order' OR ARC_Reason__c= 'Refund') Order By CreatedDate ASC)  FROM vlocity_ins__GroupCensus__c WHERE Id IN: censusIds];

        Map<Id,ARC_Commission__c> contractIdCommissionMap = new  Map<Id,ARC_Commission__c>();

        for(vlocity_ins__GroupCensus__c census: censusList){

            ChargentOrders__Transaction__c firstTransaction;
            ChargentOrders__Transaction__c lastTransaction;
            Integer contributions=0;

            //There must be at least one contribution, else this family is skipped
            if(census.Transactions__r.size()>0){
                for(ChargentOrders__Transaction__c t: census.Transactions__r){
                    if(t.ChargentOrders__Type__c == 'Charge') {
                        contributions++;
                        //This skip the voided contract to get the correct one on the original contract master commmission field
                        if(t.ChargentOrders__Order__r.ARC_Contract__r.Status == 'Terminated' || t.ChargentOrders__Order__r.ARC_Contract__r.Status =='Activated'){
                            if(firstTransaction == null) firstTransaction=t;
                            lastTransaction = t;
                        }
                    }
                    else if(t.ChargentOrders__Type__c == 'Refund') contributions--;
                }
            }
            //Crate the Master Commission if the first transaction & last transactions are not null and total contributions are less than 12.
            if(firstTransaction != null && lastTransaction!= null && contributions < 12){
                ARC_Commission__c commission = new ARC_Commission__c(
                    OwnerId = firstTransaction?.ChargentOrders__Order__r?.ARC_Contract__r?.ARC_Selling_Agent__c,
                    ARC_Agent_Role__c = firstTransaction?.ChargentOrders__Order__r?.ARC_Contract__r?.ARC_Selling_Agent__r?.Agent_Role__c,
                    Original_Contract__c = firstTransaction.ChargentOrders__Order__r.ARC_Contract__c,
                    Contract__c = lastTransaction.ChargentOrders__Order__r.ARC_Contract__c,
                    ARC_InitialCommission__c = 0, 
                    ARC_RecurringCommission__c = firstTransaction?.ChargentOrders__Order__r?.ARC_Contract__r?.ARC_Selling_Agent__r?.Agent_Role__c == 'Senior Account Executive' ? (0.05 * lastTransaction?.ChargentOrders__Order__r?.ARC_Contract__r.ARC_TotalPrice__c) :(0.03 * lastTransaction?.ChargentOrders__Order__r?.ARC_Contract__r.ARC_TotalPrice__c),
                    RecordTypeId = rtCommAccExecutive,
                    ARC_ExistingContributions__c =contributions
                );
                contractIdCommissionMap.put(commission.Contract__c,commission);
            }
        }
        
        //Check that the contracts related to the new commissions don't have any existing commission.
        List<ARC_Commission__c> existingCommissions = [SELECT Id,Contract__c FROM ARC_Commission__c WHERE Contract__c IN:contractIdCommissionMap.keySet()];
        if(existingCommissions.size()>0){
            for(ARC_Commission__c comm: existingCommissions){
                contractIdCommissionMap.remove(comm.Contract__c);
            }
        }

        try{
            List<ARC_Commission__c> commToInsert = contractIdCommissionMap.values();
            this.newCommissionsCounter = this.newCommissionsCounter + commToInsert.size();
            insert commToInsert;
        }
        catch (Exception e){
            System.debug('Expection in ARC_BackfillAEMasterCommission create Commissions'+ e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC){
        System.debug('Finished running batch job');
        ARC_QueableSendFileBatch.sendEmailNotification(('contractsToCreateCommissions: '+this.newCommissionsCounter), 'Backfill Master Commissions', 'christian.fortunato@arcsona.com');}

}