public with sharing class ARC_ProgramChangeReportController {


    @AuraEnabled(cacheable=true)
    public static List<Map<String,List<sObject>>> getContracts(){
        try {
            List<Map<String,List<sObject>>> mapToList = new List<Map<String,List<sObject>>> (); 
            Map<Id, Map<String,List<sObject>>> generalMapMain = new Map<Id, Map<String,List<sObject>>>(); 
		
        Date todayDate = Date.today();
        Map<Id, sObject> contractsPC = new Map<Id, sObject>([SELECT Id, ContractNumber, vlocity_ins__EnrollmentCensusId__c,(SELECT Name FROM vlocity_ins__ContractLineItems__r LIMIT 50000),ARC_ContractReason__c, ARC_EffectiveDate__c, 
           													vlocity_ins__ExpiredContractId__c,vlocity_ins__ExpiredContractId__r.ContractNumber FROM Contract WHERE vlocity_ins__ExpiredContractId__c != '' AND (Status = 'Activated' OR Status = 'Awaiting Activation' OR Status = 'Awaiting Approval' OR Status = 'Approved' OR Status = 'Awaiting Signature And Payment') LIMIT 50000]);
        
		Set<Id> expiredContractsId = new Set<Id>();
        Set<Id> censusIds = new Set<Id>();
        
        for (Id id : contractsPC.keyset()) {
            Contract c = (Contract)contractsPC.get(id);
            expiredContractsId.add(c.vlocity_ins__ExpiredContractId__c);
        }
        
        for (Id id : contractsPC.keyset()) {
            Contract cont = (Contract)contractsPC.get(id);
            censusIds.add(cont.vlocity_ins__EnrollmentCensusId__c);
        }
        
        List<vlocity_ins__GroupCensusMember__c> censusMembers = [SELECT Id,Name, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c IN: censusIds AND vlocity_ins__IsPrimaryMember__c = true LIMIT 50000];

        List<vlocity_ins__ContractLineItem__c> clis = [SELECT Id,vlocity_ins__ContractId__c,vlocity_ins__ProductName__c  FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c IN: expiredContractsId  LIMIT 50000];

		Map<Id,List<vlocity_ins__ContractLineItem__c>> clisMap = new Map<Id,List<vlocity_ins__ContractLineItem__c>>();
        for(vlocity_ins__ContractLineItem__c cli: clis){
            List<vlocity_ins__ContractLineItem__c> listCli = clisMap.get(cli.vlocity_ins__ContractId__c);
            if(listCli == null){
               List<vlocity_ins__ContractLineItem__c> newcliList = new List<vlocity_ins__ContractLineItem__c>{cli};
               clisMap.put(cli.vlocity_ins__ContractId__c, newcliList);    
             }else{
                listCli.add(cli);
                clisMap.put(cli.vlocity_ins__ContractId__c, listCli);
              }
		}
        
        Map<Id,List<vlocity_ins__GroupCensusMember__c>> censMembMap = new Map<Id,List<vlocity_ins__GroupCensusMember__c>>();
        for(vlocity_ins__GroupCensusMember__c memb: censusMembers){
            List<vlocity_ins__GroupCensusMember__c> listCensusMem = censMembMap.get(memb.Id);
            if(listCensusMem == null){
               List<vlocity_ins__GroupCensusMember__c> newMembList = new List<vlocity_ins__GroupCensusMember__c>{memb};
               censMembMap.put(memb.vlocity_ins__CensusId__c, newMembList);    
             }else{
                listCensusMem.add(memb);
                censMembMap.put(memb.vlocity_ins__CensusId__c, listCensusMem);
              }
		}

		for(Id id : contractsPC.keySet()){ 
            Contract cont = (Contract)contractsPC.get(id);
            List<Contract> contList = new List<Contract>{cont};
           	List<vlocity_ins__ContractLineItem__c> listCli = clisMap.get(cont.vlocity_ins__ExpiredContractId__c);
            List<vlocity_ins__GroupCensusMember__c> listMembers = censMembMap.get(cont.vlocity_ins__EnrollmentCensusId__c);
            Map<String,List<sObject>> contsMap = new Map<String,List<sObject>>();
            contsMap.put('ProgramChange',contList);
            contsMap.put('ExpiredPrograms',listCli);
            contsMap.put('PrimaryMember',listMembers);
            mapToList.add(contsMap);
        }

        return mapToList;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
                    
    }
}