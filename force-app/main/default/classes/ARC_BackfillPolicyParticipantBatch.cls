public with sharing class ARC_BackfillPolicyParticipantBatch implements Database.Batchable<SObject> {

    public final List<String> InsurancePolicyIdsToQuery;

    public ARC_BackfillPolicyParticipantBatch(List<String> insurancePolicyIds){
        InsurancePolicyIdsToQuery = insurancePolicyIds;
    }

    public ARC_BackfillPolicyParticipantBatch(){
        InsurancePolicyIdsToQuery = new List<String>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT ARC_EffectiveDate__c, ARC_ExpirationDate__c, ' + 
                            '(SELECT PrimaryParticipantContact.Birthdate, EffectiveDate, ExpirationDate ' + 
                            'FROM InsurancePolicyParticipants) ' + 
                       'FROM InsurancePolicy ' +
                       'WHERE ARC_Contract__r.Status = \'Activated\'';

        if (!InsurancePolicyIdsToQuery.isEmpty()) {
            String idList = '(\'' + String.join(InsurancePolicyIdsToQuery, '\',\'') + '\')';
            query += ' AND Id IN ' + idList;
        }

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<InsurancePolicy> ipList){
        
        List<InsurancePolicyParticipant> ippToUpdate = new List<InsurancePolicyParticipant>();

        for (InsurancePolicy tmpIp : ipList) {
            Date ipEffectiveDate = Date.valueOf(tmpIp.ARC_EffectiveDate__c);
            Date ipExpirationDate = Date.valueOf(tmpIp.ARC_ExpirationDate__c);
            
            for (InsurancePolicyParticipant tmpIpp : tmpIp.InsurancePolicyParticipants) {
                Date ippContactBirthdate = Date.valueOf(tmpIpp.PrimaryParticipantContact.Birthdate);
                
                // Update the Effective Date in the Insurance Policy Participant record
                if (ippContactBirthdate > ipEffectiveDate) {
                    tmpIpp.EffectiveDate = ippContactBirthdate;
                } else {
                    tmpIpp.EffectiveDate = ipEffectiveDate;
                }
                
                // Update the Expiration Date in the Insurance Policy Participant record
                tmpIpp.ExpirationDate = ipExpirationDate;
                
                ippToUpdate.add(tmpIpp);
            } 
        }

        update ippToUpdate;
    }

    public void finish(Database.BatchableContext bc){
        // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob WHERE Id =
            :bc.getJobId()];
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Apex Sharing Recalculation ' + a.Status);
        mail.setPlainTextBody
        ('The batch Apex job processed ' + a.TotalJobItems +
        ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

}