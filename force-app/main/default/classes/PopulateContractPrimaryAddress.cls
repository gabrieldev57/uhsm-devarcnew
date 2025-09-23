public class PopulateContractPrimaryAddress implements Database.Batchable <SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.BillingStreet,
          vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.BillingCity, 
          vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.BillingState, 
          vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.BillingPostalCode 
          FROM Contract WHERE Status != 'Draft' AND vlocity_ins__EnrollmentCensusId__c != NULL AND vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__c != null AND vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.BillingStreet != NULL AND ARC_PrimaryAddress__Street__s = NULL]);
    }

    public void execute(Database.BatchableContext BC, List<Contract> contracts){
        List<Contract> contractsToUpdate = new List<Contract>();
        
        for(Contract c: contracts){
                Account acc = c.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r;
                
            
                if(acc != null) {
                    c.ARC_PrimaryAddress__CountryCode__s = 'US';
                    c.ARC_PrimaryAddress__Street__s = acc.BillingStreet;
                    c.ARC_PrimaryAddress__City__s = acc.BillingCity;
                    c.ARC_PrimaryAddress__StateCode__s = acc.BillingState;
                    c.ARC_PrimaryAddress__PostalCode__s = acc.BillingPostalCode;
                    
                    
                    contractsToUpdate.add(c);
                }  
            
        }
            Database.SaveResult[] results = Database.update(contractsToUpdate, false);
				for (Database.SaveResult result : results) {
    				if (!result.isSuccess()) {
        				for (Database.Error err : result.getErrors())
            			System.debug('ERROR IN UPDATE '+ err.getMessage());
    			}
			}
    	}

    public void finish(Database.BatchableContext BC){
        System.debug('Batch process completed successfully.');
    }
}