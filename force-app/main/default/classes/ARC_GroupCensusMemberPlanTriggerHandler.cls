//public class ARC_GroupCensusMemberPlanTriggerHandler {
global without sharing class ARC_GroupCensusMemberPlanTriggerHandler{

    public static final String CALCULATION_PROCEDURE_NAME = 'ARC_UHSMCalculationProcedure_Individual';
    public static final String EXTRA_MEMBER_PROPERTY = 'AmountPerExtraMember';
    public static final String SMOKER_PROPERTY = 'SmokerAditional';
    public static final Integer MAX_CHILD_DEPENDENTS = 3;
    
    //This method populates the Fees fields of the related Contract Line Items of the Medical Plan.
    public static void updateRelatedContractLineItemFees(Map<Id, vlocity_ins__GroupCensusMemberPlan__c> gcmpNewMap) {
        Map<Id,List<vlocity_ins__GroupCensusMember__c>> cliMap = new Map<Id,List<vlocity_ins__GroupCensusMember__c>>();
        Map<Id, vlocity_ins__ContractLineItem__c> clisToUpdateMap = new Map<Id, vlocity_ins__ContractLineItem__c>();
        Map<Id, Contract> contractsToUpdateMap = new Map<Id, Contract>();
        Map<Id, Integer> smokersMap = new Map<Id, Integer>();
        Map<Id, Integer> childrenMap = new Map<Id, Integer>();
        Map<String, Decimal> fees = setExtraMemberAndSmokerFees();

        for (vlocity_ins__GroupCensusMemberPlan__c g : gcmpNewMap.values()) {
            if(g.ARC_IsTemporaryNewborn__c) continue;
            cliMap.put(g.vlocity_ins__ContractLineId__c, new List<vlocity_ins__GroupCensusMember__c>());
        }

        for (vlocity_ins__GroupCensusMemberPlan__c g : [SELECT Id, vlocity_ins__ContractLineId__c, vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__r.vlocity_ins__RatingCalcProcedureName__c, vlocity_ins__ContractLineId__r.ARC_OriginalPrice__c ,vlocity_ins__ContractLineId__r.vlocity_ins__UnitPrice__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__IsPrimaryMember__c, vlocity_ins__GroupCensusMemberId__r.ARC_Smoker__c, vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__IsSpouse__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c, ARC_IsTemporaryNewborn__c, vlocity_ins__GroupCensusMemberId__r.ARC_GroupCensusRecordTypeName__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__c IN :cliMap.keySet() AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical' AND vlocity_ins__GroupCensusMemberId__c != null]) {
            // Skip if is not Individual And Family or if is a temporary newborn
            if (g.vlocity_ins__GroupCensusMemberId__r.ARC_GroupCensusRecordTypeName__c != 'ARC_IndividualAndFamily') continue;
            if(g.ARC_IsTemporaryNewborn__c) continue;

            Id cliId = g.vlocity_ins__ContractLineId__c;
            Id contractId = g.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c;
      
            if (!clisToUpdateMap.containsKey(cliId)) {
                clisToUpdateMap.put(cliId, new vlocity_ins__ContractLineItem__c(Id = cliId));
            }
            //Stamp the Medical Plan in the Contract
            if(!contractsToUpdateMap.containsKey(contractId)){
                contractsToUpdateMap.put(contractId, new Contract(Id = contractId, ARC_MedicalPlan__c = cliId));
            }
            vlocity_ins__ContractLineItem__c cli = clisToUpdateMap.get(cliId);
            cli.vlocity_ins__UnitPrice__c = g.vlocity_ins__ContractLineId__r.vlocity_ins__UnitPrice__c;
            //Extra dependent fee
            if(!childrenMap.containsKey(cliId)){
                childrenMap.put(cliId, 0);
            }
            if(!g.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__IsSpouse__c &&  !g.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__IsPrimaryMember__c){
                childrenMap.put(cliId, childrenMap.get(cliId) + 1);
            }
            if (childrenMap.get(cliId) > MAX_CHILD_DEPENDENTS) {
                cli.ARC_ExtraDependentFee__c = (childrenMap.get(cliId) - MAX_CHILD_DEPENDENTS) * fees.get(EXTRA_MEMBER_PROPERTY);
            }
            //Smoker fee
            if (g.vlocity_ins__GroupCensusMemberId__r.ARC_Smoker__c) {
                if (!smokersMap.containsKey(cliId)) {
                    smokersMap.put(cliId, 0);
                }
                smokersMap.put(cliId, smokersMap.get(cliId) + 1);
                cli.ARC_SmokerFee__c = smokersMap.get(cliId) * fees.get(SMOKER_PROPERTY);
            }
        }

        for(Id cliId: clisToUpdateMap.keySet()){
            vlocity_ins__ContractLineItem__c cli = clisToUpdateMap.get(cliId);
            Decimal totalFees =0;
            if(cli.ARC_SmokerFee__c != null) totalFees = totalFees + cli.ARC_SmokerFee__c;
            if(cli.ARC_ExtraDependentFee__c != null) totalFees += cli.ARC_ExtraDependentFee__c;
            cli.ARC_OriginalPrice__c = cli.vlocity_ins__UnitPrice__c != null? (cli.vlocity_ins__UnitPrice__c - totalFees):null;
        }
        if (contractsToUpdateMap != null && !contractsToUpdateMap.isEmpty()) {
            try {
                update contractsToUpdateMap.values();
            } catch (DmlException e) {
                String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
                ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_GroupCensusMemberPlanTriggerHandler Stamp Medical Plan '+e.getMessage()), 'ERROR in ARC_GroupCensusMemberPlanTriggerHandler', apexErrorEmail);
            }
        }
        if (clisToUpdateMap != null || !clisToUpdateMap.isEmpty()) {
            try {
                update clisToUpdateMap.values();
            } catch (DmlException e) {
                String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
                ARC_QueableSendFileBatch.sendEmailNotification(('Error in ARC_GroupCensusMemberPlanTriggerHandler.updateRelatedContractLineItemFees stamp medical plan '+e.getMessage()), 'ERROR in ARC_GroupCensusMemberPlanTriggerHandler', apexErrorEmail);
            }
        }
    }

    // This method gets the fees from the Calculation Procedure and returns a map of fee names and amounts.
    public static Map<String, Decimal> setExtraMemberAndSmokerFees() {
        Map<String, Decimal> fees = new Map<String, Decimal>();
        List<vlocity_ins__CalculationProcedureVersion__c> calProcedure = [SELECT vlocity_ins__Constants__c FROM vlocity_ins__CalculationProcedureVersion__c WHERE vlocity_ins__CalculationProcedureId__r.Name = :CALCULATION_PROCEDURE_NAME AND vlocity_ins__IsEnabled__c = TRUE LIMIT 1];
        if (calProcedure.size() > 0) {
            List<Object> constants = (List<Object>)JSON.deserializeUntyped(calProcedure[0].vlocity_ins__Constants__c);
            for (Object con : constants) {
                Map<String,Object> c = (Map<String,Object>)con;
                String name = (String)c.get('name');
                if (name == EXTRA_MEMBER_PROPERTY || name == SMOKER_PROPERTY) {
                    fees.put(name, Decimal.valueOf((String)c.get('value')));
                }
            }
        }
        return fees;
    }

    /*******************************************************************
    * @MethodName         :   smokerAndExtraFees
    * @Description        :   Invocable Method that is called during the recalculate of all the related Age Up’s/Discounts when there is change on the (Smoker | Extra Dependent) Fee.
    ********************************************************************/
    @InvocableMethod(label='Smoker and Extra Dependent Fees Handler' description='Update Contract Price and recalculate all the related Age Ups/Discounts when there is change on the Smoker or Extra Dependent Fees' category='Plan')

    global static List<SmokerOutput> smokerAndExtraFees() {

        SmokerOutput result = new SmokerOutput();
        //ARC_GroupCensusMemberPlanTriggerHandler triggerHandlerSmoker = new ARC_GroupCensusMemberPlanTriggerHandler();
        Decimal smokerField = ARC_GroupCensusMemberPlanTriggerHandler.setExtraMemberAndSmokerFees().get('SmokerAditional');
        result.output = smokerField;
        return new List<SmokerOutput> {result};
    }
  
    global class SmokerOutput {
        @InvocableVariable(label = 'Output') global Decimal output;
    }
    
    
     
}