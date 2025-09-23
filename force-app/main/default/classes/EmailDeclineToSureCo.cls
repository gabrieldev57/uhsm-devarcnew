global class EmailDeclineToSureCo implements Database.Batchable<sObject>,Database.Stateful, Database.AllowsCallouts,Schedulable{
    
    public string header = 'Name,Member Id,Individual Member Id \n'; //Created Header
    public string finalstr = header ;
    public string query;
    public Map<Id,String> mapOfMemberId = new Map<Id,String>();
    /**
* Returns a query locator for selecting relevant Account records to be processed in the batch job.
* The query selects the necessary fields from the Account object based on specific filtering conditions.
*
* @param BC The batchable context for the batch job.
* @return A query locator for retrieving the Account records.
*/
    global database.querylocator start(Database.BatchableContext BC)
    {
        Set<Id> rejectsOrderId = new Set<Id>();
        Set<Id> DelinquentPolicyContacts = new Set<Id>();
        Set<Id> contactAccountIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
      
        List<ChargentOrders__Transaction__c> Rejected_Order_Ids = [SELECT ChargentOrders__Order__c 
                                                                   FROM ChargentOrders__Transaction__c
                                                                   WHERE Last_Transaction_On_Order__c = TRUE AND
                                                                   ChargentOrders__Response_Status__c != 'Approved' AND
                                                                   ChargentOrders__Order__r.Current_Recurring_Order__c=TRUE AND
                                                                  (ChargentOrders__Order__r.ARC_Contract__r.Status='Activated' OR ChargentOrders__Order__r.ARC_Contract__r.Status='Awaiting Activation')];
        
        for(ChargentOrders__Transaction__c chargenRejectedTransaction : Rejected_Order_Ids){
          rejectsOrderId.add(chargenRejectedTransaction.ChargentOrders__Order__c);  
        }
        
        List<InsurancePolicyParticipant> Delinquent_Policy_Contacts = [SELECT PrimaryParticipantContactId,ARC_MemberID__c,
                                                                       PrimaryParticipantContact.AccountId,PrimaryParticipantContact.Account.Name
                                                                       FROM InsurancePolicyParticipant 
                                                                       WHERE (InsurancePolicy.ARC_Contract__r.Status = 'Activated' OR InsurancePolicy.ARC_Contract__r.Status = 'Awaiting Activation') AND
                                                                       InsurancePolicy.Product.vlocity_ins__Type__c = 'Medical' AND
                                                                       (NOT InsurancePolicy.Product.Name LIKE '%Access%') AND
                                                                       InsurancePolicy.ARC_Contract__r.ARC_RecurringMonthlyOrder__c IN:rejectsOrderId];
        
       
        
        for(InsurancePolicyParticipant i:Delinquent_Policy_Contacts){
            contactAccountIds.add(i.PrimaryParticipantContactId);
            mapOfMemberId.put(i.PrimaryParticipantContact.AccountId,i.ARC_MemberID__c);
        }
        List<Contact> Delinquent_Account_Ids = [SELECT AccountId
                                                FROM CONTACT
                                                WHERE Id IN :contactAccountIds];


        for(Contact con:Delinquent_Account_Ids){
            accountIds.add(con.AccountId);
        }
       
        return Database.getQueryLocator([SELECT Id,ARC_Member_Id__c,Name from Account WHERE ID IN :accountIds]);
    }
    
    
    /**
* Executes the batch processing logic for the Accoun records.
* Filters the records based on the specified criteria and builds a comma-separated string of selected record data.
*
* @param BC       The batchable context for the batch job.
* @param agesUp   The list of Account records to be processed.
*/ 
    global void execute(Database.BatchableContext BC, List<Account> scope){
        
        String recordString = '';
        for(Account accounts:scope){
             // Build a string for the record
              recordString = accounts.Name+ ',' +
                             accounts.ARC_Member_Id__c +','+mapOfMemberId.get(accounts.id)+'\n';
              
              // Append the record string to the final string
              finalstr = finalstr + recordString ;  
        }
        
    }
    
    global void finish(Database.BatchableContext BC) {

        //Get Label to send an Email
        String title='UHSM Decline'+system.today();
        if(!Test.isRunningTest()){
        FTP2SF.FTP.put('UHSM', 'UAT/SureCo/Test/'+title + '.csv', Blob.valueOf(finalstr));
        }
        String emailsToSend = system.label.Send_Report_To_User;
        Messaging.EmailFileAttachment objMsgEmailAttach = new Messaging.EmailFileAttachment();
        objMsgEmailAttach.setFileName('UHSM Decline.csv');
        objMsgEmailAttach.setBody(Blob.valueOf(finalstr));
        objMsgEmailAttach.setContentType('text/csv');
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddresses = new list<string> {emailsToSend};
        String subject ='UHSM Decline';
        email.setSubject(subject);
        email.setToAddresses(toAddresses);
        email.setPlainTextBody('UHSM Decline');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{objMsgEmailAttach});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});   
        
    }
     global void execute(SchedulableContext ctx){
        EmailDeclineToSureCo EmailDeclineToSureCo=new EmailDeclineToSureCo();
        Database.executeBatch(EmailDeclineToSureCo,1);
    } 
    
}