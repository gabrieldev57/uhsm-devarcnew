global class ARC_CreateOriginalPrice implements Database.Batchable<sObject> {

    public Set<Id> contractIds = new Set<Id>();

    global ARC_CreateOriginalPrice (Set<Id> contractIds){
        System.debug('EXECUTE BATCH FOR SPECIFIC Contracts');
        this.contractIds = contractIds;
    }

    global ARC_CreateOriginalPrice(){}

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (this.contractIds.size() > 0) {
            return  Database.getQueryLocator([SELECT Id, ContractNumber, Status, ARC_TotalPrice__c, 
            (SELECT Id, vlocity_ins__UnitPrice__c, ARC_SmokerFee__c, ARC_ExtraDependentFee__c, ARC_OriginalPrice__c, vlocity_ins__ProductType__c, vlocity_ins__EffectiveStartDate__c, vlocity_ins__ContractId__r.StartDate, vlocity_ins__EffectiveEndDate__c, vlocity_ins__ContractId__r.EndDate FROM vlocity_ins__ContractLineItems__r WHERE vlocity_ins__UnitPrice__c != null AND vlocity_ins__UnitPrice__c != 0 AND (ARC_OriginalPrice__c = null OR  ARC_OriginalPrice__c = 0)), 
            (SELECT Id, Name, Old_Medical_Price__c, Is_Active__c, New_Order_Price__c FROM Healthy_Discounts__r WHERE Is_Active__c = true)      
            FROM Contract WHERE Status != 'Draft' AND Id IN:contractIds]);
        } 
        else return Database.getQueryLocator([
            SELECT Id, ContractNumber, Status, ARC_TotalPrice__c, 
            (SELECT Id, vlocity_ins__UnitPrice__c, ARC_SmokerFee__c, ARC_ExtraDependentFee__c, ARC_OriginalPrice__c, vlocity_ins__ProductType__c, vlocity_ins__EffectiveStartDate__c, vlocity_ins__ContractId__r.StartDate, vlocity_ins__EffectiveEndDate__c, vlocity_ins__ContractId__r.EndDate FROM vlocity_ins__ContractLineItems__r WHERE vlocity_ins__UnitPrice__c != null AND vlocity_ins__UnitPrice__c != 0 AND (ARC_OriginalPrice__c = null OR  ARC_OriginalPrice__c = 0)), 
            (SELECT Id, Name, Old_Medical_Price__c, Is_Active__c, New_Order_Price__c FROM Healthy_Discounts__r WHERE Is_Active__c = true)      
            FROM Contract WHERE Status != 'Draft']);
    }

    global void execute(Database.BatchableContext bc, List<Contract> records){
    
        List<vlocity_ins__ContractLineItem__c> listToUpdate = new List<vlocity_ins__ContractLineItem__c>();
        Boolean errorsFound = false;
        String errorMessage = '';
        for(Contract record: records) {            
            Decimal originalPriceHD = 0;
            for(Healthy_Discount__c hd: record.Healthy_Discounts__r) {
                originalPriceHD = hd.Old_Medical_Price__c;
            }

            for(vlocity_ins__ContractLineItem__c cli: record.vlocity_ins__ContractLineItems__r){

                //It has discount and cli is medical - original price is equal to old medical price minus smoker and extra fees
                if(cli.vlocity_ins__ProductType__c == 'Medical' && originalPriceHD != 0){

                    Decimal smokerFeeHD = 0;
                    Decimal extraFeeHD = 0;

                    if(cli.ARC_SmokerFee__c != null){
                        smokerFeeHD = cli.ARC_SmokerFee__c;
                    }
                    if(cli.ARC_ExtraDependentFee__c != null){
                        extraFeeHD = cli.ARC_ExtraDependentFee__c;
                    }

                    cli.ARC_OriginalPrice__c = originalPriceHD - (smokerFeeHD + extraFeeHD);
                }
                //It doesn't have discount - original price is equal to unit price minus smoker and extra fees
                else{
                    
                    Decimal smokerFee = 0;
                    Decimal extraFee = 0;
                    
                    if(cli.ARC_SmokerFee__c != null){
                        smokerFee = cli.ARC_SmokerFee__c;
                    }
                    if(cli.ARC_ExtraDependentFee__c != null){
                        extraFee = cli.ARC_ExtraDependentFee__c;
                    }
                    
                    cli.ARC_OriginalPrice__c = cli.vlocity_ins__UnitPrice__c - (smokerFee + extraFee);
                }
                if(cli.vlocity_ins__EffectiveStartDate__c < cli.vlocity_ins__ContractId__r.StartDate){
                    cli.vlocity_ins__EffectiveStartDate__c = null;
                }
                if(cli.vlocity_ins__EffectiveEndDate__c != null && cli.vlocity_ins__ContractId__r.EndDate != null && cli.vlocity_ins__EffectiveEndDate__c > cli.vlocity_ins__ContractId__r.EndDate){
                    cli.vlocity_ins__EffectiveEndDate__c = null;
                }
                listToUpdate.add(cli);
            }
        }
        try{
            Database.SaveResult[] srList = Database.update(listToUpdate,false);
            for (Database.SaveResult sr : srList) {
                if(!sr.isSuccess()){
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = errorMessage + 'ErrorCode '+ err.getStatusCode() + ': ' + err.getMessage()+ ' ErrorFields:' + err.getFields() +'\n';
                    }
                    errorsFound = true;
                } 
            }
        }catch(Exception e){
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in Backifll Original Price: '+e.getMessage()), 'ERROR in Backfill Original Price', apexErrorEmail);
        }
        if(errorsFound) {
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Backill Original Price error : '+errorMessage), 'ERROR in Backfill Original Price', apexErrorEmail);
        }
        
    }

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
    
}