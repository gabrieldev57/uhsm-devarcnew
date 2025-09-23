global class BatchAgeUpPTSFileShare implements Database.Batchable<sObject>,Schedulable,Database.AllowsCallouts,Database.Stateful{
 
    Public String header = 'PrimaryFirstName,AgeupMember,AgeupBirthdate,CurrentMonthlyContribution,NewMonthlyContribution,DraftDate,Primary Name,Street,City,State,Zip  \n'; //Created Header;
    Public String finalstr;
    Public Integer recordCount;

/**
* Returns a query locator for selecting relevant Ages_Up__c records to be processed in the batch job.
* The query selects the necessary fields from the Ages_Up__c object based on specific filtering conditions.
*
* @param BC The batchable context for the batch job.
* @return A query locator for retrieving the Ages_Up__c records.
*/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query the relevant Ages_Up__c records for processing in the batch job
        system.debug('AgeUpPTSFileShare - start method');
        return Database.getQueryLocator([
            SELECT 	Id, Name, AgesUp_Census_Member_Name__c,vlocity_Ins_CensusMemberId__r.vlocity_ins__FirstName__c,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.Name,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__FirstName__c ,
            vlocity_Ins_CensusMemberId__r.Name, Contract__c, AgesUp_Birth_Date__c,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingStreet,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingPostalCode,
            Draft_Date__c, Age_up_in_sixty_Days__c, Old_Price__c, Effective_Date_Anniversary__c,
            Contract_Status__c, Contract__r.Ages_Up_Manuel_Delay__c, Contract__r.CreatedDate, Contract__r.ARC_EffectiveDate__c,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.Name,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingState,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingCity,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingStreet,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingPostalCode,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.Account.Name,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingState,
            vlocity_Ins_CensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingCity
            FROM Ages_Up__c 
            WHERE AgesUp_Birth_Date__c != null 
            AND Contract_Status__c ='Activated' 
            AND Draft_Date__c >= :System.today()]);
    }    
    
    global BatchAgeUpPTSFileShare(){
        finalstr = header;
        recordCount = 0;
        system.debug('AgeUpPTSFileShare - Constructor');  
    }
    
/**
* Executes the batch processing logic for the Ages_Up__c records.
* Filters the records based on the specified criteria and builds a comma-separated string of selected record data.
*
* @param BC       The batchable context for the batch job.
* @param records   The list of Ages_Up__c records to be processed.
*/    
    global void execute(Database.BatchableContext BC, List<Ages_Up__c> records) {
        //Retrieve the number of days before the draftdate/birthdate that we want to send the file to PTS
        
        Integer daysBefore = Integer.valueof(System.Label.daysBefore);
        system.debug('AgeUpPTSFileShare - daysBefore: '+System.Label.daysBefore);
        
        // Variables for processing and string building
        Integer daysDifference;
        String recordString = '';
        Date draftDates;
        String ageUpMember;
        Date nextBirthday;
        Date nextEffectiveAnniversary;
        Date contractCreated;
        Date createdDateLimit = Date.newInstance(2023,08,01);
        
        for(Ages_Up__c ages : records){
            contractCreated = ages.Contract__r.CreatedDate.date();
             // Calculate the days difference based on whether the Contract has a Manual Delay date currently
             // and the date the contract was created.
			
            //Manually Dealyed Contracts
            if(ages.Contract__r.Ages_Up_Manuel_Delay__c!=null) {
                daysDifference = system.today().daysBetween(ages.Draft_Date__c);
                
            //Contract Created On/After 8/1/2023
            } else if (contractCreated >= createdDateLimit) {
                nextBirthday = AgeUpUtilityClass.findNextAnniversary(ages.AgesUp_Birth_Date__c);
                daysDifference = system.today().daysBetween(nextBirthday);
            
            //Contract Created Before 8/1/2023
            } else {
               nextEffectiveAnniversary = AgeUpUtilityClass.findNextAnniversary(ages.Effective_Date_Anniversary__c);
               daysDifference = system.today().daysBetween(nextEffectiveAnniversary);
            }
            system.debug('AgeUpPTSFileShare - daysDifference: '+String.valueOf(daysDifference));
            // Check if the today is the correct number of days before the triggering date
            
            if(daysDifference == daysBefore) {
                
                // Add 1 day to the Order Update Date value
                draftDates = ages.Draft_Date__c.addDays(1);
                Date myDate = Date.newInstance(
                    draftDates.year(),
                    draftDates.month(),
                    draftDates.day());
                
                // Convert the Date to DateTime by adding a time component (set to midnight)
                DateTime myDateTime = DateTime.newInstance(myDate, Time.newInstance(0, 0, 0, 0));
                
                // Format the DateTime to remove the time and get only the date part
                String formattedDate = myDateTime.format('yyyy-MM-dd');
                
                Date myAges = Date.newInstance(
                    ages.AgesUp_Birth_Date__c.year(),
                    ages.AgesUp_Birth_Date__c.month(),
                    ages.AgesUp_Birth_Date__c.day());
                
                // Convert the Date to DateTime by adding a time component (set to midnight)
                DateTime myAgesDateTime = DateTime.newInstance(myAges, Time.newInstance(0, 0, 0, 0));
                
                // Format the DateTime to remove the time and get only the date part
                String formattedAgeDate = myAgesDateTime.format('yyyy-MM-dd');
                //If not the primary member
                if(ages.vlocity_Ins_CensusMemberId__r.vlocity_ins__RelatedCensusMemberId__r.Name!=null){
                        ageUpMember= ages.vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.Name+'\'s';
                }else{
                        ageUpMember='your';
					 }
                recordString = ages.vlocity_Ins_CensusMemberId__r.vlocity_ins__FirstName__c + ',' +
                        ageUpMember + ',' +
                        formattedAgeDate + ',' +
                        ages.Old_Price__c + ',' +
                        ages.Age_up_in_sixty_Days__c + ',' +
                        formattedDate+','+
                        ages.vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.Name +','+
                        ages.vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingStreet+','+
                        ages.vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingCity+','+
                        ages.vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingState+','+
                        ages.vlocity_Ins_CensusMemberId__r.vlocity_ins__ContactId__r.Account.BillingPostalCode+'\n';                
   
                recordCount = recordCount + 1;
                // Append the record string to the final string
                finalstr = finalstr + recordString;   
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        Date myDate = Date.newInstance(
            system.today().year(),
            system.today().month(),
            system.today().day());
        
        // Convert the Date to DateTime by adding a time component (set to midnight)
        DateTime myDateTime = DateTime.newInstance(myDate, Time.newInstance(0, 0, 0, 0));
        
        // Format the DateTime to remove the time and get only the date part
        String formattedDate = myDateTime.format('yyyy-MM-dd');
        
        String title = 'AgeUpLetters'+formattedDate;
        
        if(Test.isRunningTest()){
            String emailsToSend = 'integrations@uhsm.org';
            Messaging.EmailFileAttachment objMsgEmailAttach = new Messaging.EmailFileAttachment();
            objMsgEmailAttach.setFileName('TEST'+ title +'.csv');
            objMsgEmailAttach.setBody(Blob.valueOf(finalstr));
            objMsgEmailAttach.setContentType('text/csv');
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] toAddresses = new list<string> {emailsToSend};
            String subject ='Age Up PTS Test File';
            email.setSubject(subject);
            email.setToAddresses(toAddresses);
            email.setPlainTextBody('Age Up PTS Test File');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{objMsgEmailAttach});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});   
        }else{            
            if(recordCount > 0){
                system.debug('size'+finalstr);
                FTP2SF.FTP.put('UHSM', 'pts/AgeUpLetters/'+title + '.csv', Blob.valueOf(finalstr));
            }
        }
    }
    
    global void execute(SchedulableContext ctx){
        BatchAgeUpPTSFileShare BatchJob = new BatchAgeUpPTSFileShare();
        Database.executeBatch(BatchJob,10);
    } 
}