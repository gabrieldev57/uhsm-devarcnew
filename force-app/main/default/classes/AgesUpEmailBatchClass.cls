global class AgesUpEmailBatchClass implements Database.Batchable<sObject>,Schedulable{

    //Add Schedulable method
    global void execute(SchedulableContext ctx) {
        AgesUpEmailBatchClass AgesUpEmail = new AgesUpEmailBatchClass();
        Database.executeBatch(AgesUpEmail, 1);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT Id,
                    AgesUp_Census_Member_Name__c,
                    vlocity_Ins_CensusMemberId__c,
                    Contract__c,
                    AgesUp_Birth_Date__c,
                    Draft_Date__c,
                    Effective_Date_Anniversary__c,
                    Is_Created_Date_Today__c 
                    FROM Ages_Up__c 
                    WHERE Contract__r.Status = : 'Activated' 
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Ages_Up__c> members){

       
        List<Contract> contracts = [
			SELECT Id, ARC_EffectiveDate__c,vlocity_ins__EnrollmentCensusId__c,Status,ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c,Ages_Up_Manuel_Delay__c,CreatedDate
			FROM Contract 
			WHERE Id = : members[0].Contract__c];

        String ContractIds;
        Date ageUpManualDelay;
        Date manualDelay;
        Date memberBirthdate,memberContractAnniversary;
        Date birthdate,ContractAnniversary;
        Integer daysUntilDate,year;
        Date today = Date.today(); 
        Date createdDateLimit = Date.newInstance(2023,08,01);
        Date contractCreatedDate;
        Datetime contractCreatedDateRaw;

        memberBirthdate=members[0].AgesUp_Birth_Date__c; 
        // Boolean isNewYear = today.addDays(60).year() == today.year() + 1 ? true : false;
        // Integer year = isNewYear ? today.year() + 1 : today.year();
        for (Contract c : contracts) {
            System.debug('Contract:'+ c );
            ContractIds=c.Id;
            ageUpManualDelay=c.Ages_Up_Manuel_Delay__c;
            contractCreatedDateRaw=c.CreatedDate;
            contractCreatedDate=Date.newInstance(contractCreatedDateRaw.year(), contractCreatedDateRaw.month(), contractCreatedDateRaw.day());    
        }
       //Contract created After 8/1
        if (ageUpManualDelay==null && contractCreatedDate > createdDateLimit && memberBirthdate != null) { 
          if (memberBirthdate.month() >= today.month() ) {
                year=Date.today().year();
            }else {
                year=Date.today().year() + 1;
            }
    		System.debug('year:'+ year );
            birthdate = Date.newInstance(year, memberBirthdate.month(), memberBirthdate.day());
            daysUntilDate = today.daysBetween(birthdate);

         //Contract created Before 8/1   
        } else if (ageUpManualDelay==null && contractCreatedDate < createdDateLimit && members[0].Effective_Date_Anniversary__c != null) {
            memberContractAnniversary=members[0].Effective_Date_Anniversary__c;
            ContractAnniversary= Date.newInstance(memberContractAnniversary.year(), memberContractAnniversary.month(), memberContractAnniversary.day());
            daysUntilDate = today.daysBetween(ContractAnniversary);

         //Manual delay exist   
        }else if (ageUpManualDelay!=null) {
            manualDelay=Date.newInstance(ageUpManualDelay.year(), ageUpManualDelay.month(), ageUpManualDelay.day());
            daysUntilDate = today.daysBetween(manualDelay);

        }
        System.debug('daysUntilBirthday' + daysUntilDate);
        
        if (daysUntilDate == 60 || daysUntilDate == 30 || daysUntilDate == 14)  {
            try {
                ARC_Emails.email_22(new Map<String,Object>{'agesUp'=>members[0]}, new Map<String,Object>(), new Map<String,Object>());
                } catch (Exception e) {
                    System.debug(e);
                    ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'AgesUpEmailBatchClass.email_22',String.valueOf(members));
                    }

        }
                                  
    }

    global void finish(Database.BatchableContext BC){
    }

}