global class BatchNoomEligibilityFile implements Database.Batchable<sObject>,Schedulable,Database.AllowsCallouts,Database.Stateful{
   
    public string header = 'ORGANIZATION_ID,FIRST_NAME,LAST_NAME,EMAIL,PARTICIPANT_ID,DOB  \n'; //Created Header
    public string finalstr = header ;
 
    /**
    * Returns a query locator for selecting relevant Census Member Group Plan whose status is 
    * activated and plan type is Medical records to be processed in the batch job.
    * The query selects the necessary fields from the Census Member Group Plan object based on specific filtering conditions.
    *
    * @param BC The batchable context for the batch job.
    * @return A query locator for retrieving the Census Member Group Plan records.
    */

	//Add Schedulable method
    global void execute(SchedulableContext ctx) {
        BatchNoomEligibilityFile Noom = new BatchNoomEligibilityFile();
        Database.executeBatch(Noom);
    }
    
    global BatchNoomEligibilityFile(){
        finalstr = header;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT id,vlocity_ins__GroupCensusMemberId__r.Member_ID__c,vlocity_ins__GroupCensusMemberId__r.ARC_Age__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c,vlocity_ins__GroupCensusMemberId__c,
            vlocity_ins__GroupCensusMemberId__r.Name,vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c 
            FROM vlocity_ins__GroupCensusMemberPlan__c 
            WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status='Activated' 
            	AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c='Medical'
            	AND vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c <= today 
            	AND vlocity_ins__GroupCensusMemberId__r.ARC_Age__c>=1
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<vlocity_ins__GroupCensusMemberPlan__c> scope){
        
        String recordString = '';
        for(vlocity_ins__GroupCensusMemberPlan__c groupCensus:scope){  
            Date myDate = Date.newInstance(
            groupCensus.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c.year(),
            groupCensus.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c.month(),
            groupCensus.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c.day()
        );

       // Convert the Date to DateTime by adding a time component (set to midnight)
        DateTime myDateTime = DateTime.newInstance(myDate, Time.newInstance(0, 0, 0, 0));

        // Format the DateTime to remove the time and get only the date part
        String formattedDate = myDateTime.format('yyyy-MM-dd');

        String lastName = groupCensus.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c;
        String lastNameFormatted = '"' + lastName + '"';
        String email = groupCensus.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c;

        // Build a string for the record
		recordString = 'UHSM Inc,' +
            groupCensus.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c + ',' +
            lastNameFormatted+ ',' +
            groupCensus.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c+ ',' +
            groupCensus.vlocity_ins__GroupCensusMemberId__r.Member_ID__c + ',' +
            formattedDate+ '\n';
              
        // Append the record string to the final string
        finalstr = finalstr + recordString ;  
        }       
    }

    global void finish(Database.BatchableContext BC) {
        Datetime now = Datetime.now();
        String todaysDate = now.format('MMddyyyy');
        
		system.debug(Blob.valueOf(finalstr));
        
        if(Test.isRunningTest()){
            String emailsToSend = 'integrations@uhsm.org';
            Messaging.EmailFileAttachment objMsgEmailAttach = new Messaging.EmailFileAttachment();
            objMsgEmailAttach.setFileName('UHSM_Noom Eligibility file _'+todaysDate + '.csv');
            objMsgEmailAttach.setBody(Blob.valueOf(finalstr));
            objMsgEmailAttach.setContentType('text/csv');
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            String[] toAddresses = new list<string> {emailsToSend};
            String subject ='Noom SFTP';
            email.setSubject(subject);
            email.setToAddresses(toAddresses);
            email.setPlainTextBody('Noom SFTP');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{objMsgEmailAttach});
            
       		Messaging.SendEmailResult [] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});

            for(Messaging.SendEmailResult r:results){
                     if(!r.isSuccess()){
                        system.debug(r);
                     } else {
                         system.debug('success - email sent');
                         system.debug(finalstr);
                    }
            }
        } else {
          	try {
            	FTP2SF.FTP.Response ftp_response = FTP2SF.FTP.put('UHSM','noom/' + 
                                                              		'UHSM_Noom_Eligibility_file_'+todaysDate + '.csv',Blob.valueOf(finalstr));
            System.debug(ftp_response);
        	} catch (Exception e) {
            	System.debug(e);
        	}
        }
        
    }
}