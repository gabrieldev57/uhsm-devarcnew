/**
 *  Created By : Nazar
 *  Description : To send Better Help Enrollment
 *  Created date : 19 May 2023
 *  Test Class : BetterHelpSendToEmailTest
 * */
global class BetterHelpEnrollmentNew implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    public String texts = 'WeShare'; 
    public String weShare = '%'+texts+'%';
    public string query = 'select Id,Contract_Effective_Date__c,Contract_Status__c,Contract_Inactive_Date__c,vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c,vlocity_ins__ContractLineId__r.Name,vlocity_ins__ContractLineId__r.vlocity_ins__EnrollmentEndDate__c,vlocity_ins__GroupCensusMemberId__r.Name, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c,vlocity_ins__GroupCensusMemberId__r.ARC_Age__c,vlocity_ins__ContractLineId__r.vlocity_ins__LineStatus__c,vlocity_ins__GroupCensusMemberId__r.ARC_OptOutEmail__c from vlocity_ins__GroupCensusMemberPlan__c where vlocity_ins__GroupCensusMemberId__r.ARC_Age__c>=18 AND vlocity_ins__GroupCensusMemberId__r.ARC_OptOutEmail__c=False AND vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c!=null AND Contract_Effective_Date__c= LAST_WEEK  AND vlocity_ins__ContractLineId__r.vlocity_ins__EnrollmentEndDate__c=null AND Contract_Inactive_Date__c=null AND vlocity_ins__ContractLineId__r.Name LIKE :weShare AND Contract_Status__c= \'Activated\'';
    public string header = 'Email \n'; //Created Header
    public string finalstr = header ;
    global database.querylocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<vlocity_ins__GroupCensusMemberPlan__c> scope){
       
        for(vlocity_ins__GroupCensusMemberPlan__c o:scope){
            string recordString = o.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c+'\n'; //Assigned Data
            finalstr = finalstr+recordString ;
        }
    
   }



   global void finish(Database.BatchableContext BC) {
    
        String emails=System.Label.BetterHelpSendToEmail;
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(finalstr);
        string csvname= 'CensusMemberNewEnrollment.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = new list<string> {emails};
        String subject ='Census Member New Enrollemnt CSV';
        email.setSubject(subject);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody('Census Member New EnrollmentCSV');
        email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
   }

   global void execute(SchedulableContext ctx){
	   BetterHelpEnrollmentNew BetterHelpEnrollmentNew=new BetterHelpEnrollmentNew();
	   Database.executeBatch(BetterHelpEnrollmentNew,1);
    } 
}