global with sharing class ARC_SmokerFeeHandler {
    @InvocableMethod(label='Smoker Handler')
    global static void applySmokerFeeLogic(List<SmokerInput> inputs) {
        Decimal smokerFee = ARC_GroupCensusMemberPlanTriggerHandler.setExtraMemberAndSmokerFees().get('SmokerAditional');
        Set<Id> contractIds = new Set<Id>();
        Set<Id> memberIds = new Set<Id>();
        Map<Id,Decimal> memberIdSmokerFee = new Map<Id,Decimal>();
        Map<Id,Decimal> cliUpdateAmountMap = new Map<Id,Decimal>();

        for (SmokerInput input : inputs) {
            System.debug('Record Id: ' + input.Id);
            System.debug('ARC_Smoker__c: ' + input.isSmoker);

            Decimal memberSmokerFee = input.isSmoker == true ? smokerFee : - smokerFee;
            System.debug('memberSmokerFee ' + memberSmokerFee);

            memberIds.add(input.Id);
            memberIdSmokerFee.put(input.Id, memberSmokerFee);  

        }

        List<vlocity_ins__GroupCensusMemberPlan__c> relatedGCMPList = [SELECT Id, vlocity_ins__GroupCensusMemberId__c, vlocity_ins__ContractLineId__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__GroupCensusMemberId__c IN :memberIds AND Contract_Status__c != 'Terminated' AND Contract_Status__c != 'Voided'];
    
        if (!relatedGCMPList.isEmpty()) {
            for (vlocity_ins__GroupCensusMemberPlan__c gcmp : relatedGCMPList) {
                Id contractLineId = gcmp.vlocity_ins__ContractLineId__c;
                Id contractId     = gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c;
                Id memberId       = gcmp.vlocity_ins__GroupCensusMemberId__c;

                System.debug('memberIds in map: ' + memberIdSmokerFee.keySet());
                System.debug('Looking for memberId: ' + memberId);
                System.debug('Fee found: ' + memberIdSmokerFee.get(memberId));

                if (contractId != null) {
                    contractIds.add(contractId);
                }

                if (contractLineId != null) {
                    Decimal memberFee = memberIdSmokerFee.get(memberId);

                    if (cliUpdateAmountMap.containsKey(contractLineId)) {
                        cliUpdateAmountMap.put(contractLineId, cliUpdateAmountMap.get(contractLineId) + memberFee);
                    } else {
                        cliUpdateAmountMap.put(contractLineId, memberFee);
                    }
                }
            }
        }
        System.debug('contractIds ' + contractIds);

        if(!contractIds.isEmpty()){
            List<vlocity_ins__ContractLineItem__c> contractLineItemsList = [SELECT Id, vlocity_ins__UnitPrice__c, ARC_SmokerFee__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c IN :contractIds AND vlocity_ins__ProductType__c = 'Medical' AND vlocity_ins__RecordTypeName__c != 'CoverageSpec'];
    
            if (!contractLineItemsList.isEmpty()) {

                List<vlocity_ins__ContractLineItem__c> clisToUpdate = new List<vlocity_ins__ContractLineItem__c>();

                for (vlocity_ins__ContractLineItem__c cli : contractLineItemsList) {
                    if (cliUpdateAmountMap.containsKey(cli.Id)) {
                        Decimal delta = cliUpdateAmountMap.get(cli.Id);

                        cli.ARC_SmokerFee__c = (cli.ARC_SmokerFee__c == null ? 0 : cli.ARC_SmokerFee__c) + delta;

                        cli.vlocity_ins__UnitPrice__c = (cli.vlocity_ins__UnitPrice__c == null ? 0 : cli.vlocity_ins__UnitPrice__c) + delta;

                        clisToUpdate.add(cli);
                    }

                }

                if (!clisToUpdate.isEmpty()) {
                    update clisToUpdate;
                }

                ARC_Discounts.applyDiscounts(contractIds, true);

            }

        }
        

        
    }

    global class SmokerInput {
        @InvocableVariable(label='Id') global Id Id;
        @InvocableVariable(label='ARC_Smoker__c') global Boolean isSmoker;
    }
}