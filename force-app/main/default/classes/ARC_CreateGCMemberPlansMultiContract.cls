global without sharing class ARC_CreateGCMemberPlansMultiContract implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'generateGroupCensusMemberPlansMultiContracts') {
            generateGroupCensusMemberPlansMultiContracts(inputMap,outputMap);
        }          
        return true;
    }
    public static void generateGroupCensusMemberPlansMultiContracts(Map<String,Object> inputMap,Map<String,Object> outputMap){
        List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        Map<String, Set<String>> contract_CLI = new Map<String, Set<String>>();
        for (Object cliContract : (List<Object>)inputMap.get('contractLineItems')) {
            Set<String> cliSet = new Set<String>();
            for (Object cli : (List<Object>)inputMap.get('contractLineItems')) {
                if ((String)((Map<String,Object>)cli).get('ContractId')==(String)((Map<String,Object>)cliContract).get('ContractId')) {
                    cliSet.add((String)((Map<String,Object>)cli).get('ContractLineItemId'));
                }
            }
            contract_CLI.put((String)((Map<String,Object>)cliContract).get('ContractId'),cliSet);
        }

        for (Object change : (List<Object>)inputMap.get('changesForContracts')) {
            for (Object member : (List<Object>)((Map<String,Object>)change).get('userInputs2')) {
                for (String cliId : contract_CLI.get((String)((Map<String,Object>)change).get('Id'))) {
                    vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c(vlocity_ins__GroupCensusMemberId__c=(String)((Map<String,Object>)member).get('CensusMemberId'), vlocity_ins__ContractLineId__c=cliId);
                    groupCensusMemberPlans.add(gcmp);                    
                }
            }
            
        }
        insert groupCensusMemberPlans;
        outputMap.put('groupCensusMemberPlans',groupCensusMemberPlans);
    }
}