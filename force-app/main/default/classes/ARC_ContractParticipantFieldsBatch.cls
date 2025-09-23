public with sharing class ARC_ContractParticipantFieldsBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, 
                ARC_Relationship__c,
                ARC_PersonAccount__c,
                ARC_FirstName__c,
                ARC_LastName__c,
                ARC_BirthDate__c,
                ARC_Email__c,
                ARC_Height__c,
                ARC_Weight__c,
                ARC_Address__c,
                ARC_Phone__c,
                ARC_Gender__c,
                ARC_Smoker__c,
                ARC_PersonAccount__r.FirstName,
                ARC_PersonAccount__r.LastName,
                ARC_PersonAccount__r.PersonBirthdate,
                ARC_PersonAccount__r.PersonEmail,
                ARC_PersonAccount__r.ARC_Height__c,
                ARC_PersonAccount__r.ARC_Weight__c,
                ARC_PersonAccount__r.BillingStreet,
                ARC_PersonAccount__r.BillingCity,
                ARC_PersonAccount__r.BillingState,
                ARC_PersonAccount__r.BillingPostalCode,
                ARC_PersonAccount__r.et4ae5__Mobile_Country_Code__pc,
                ARC_PersonAccount__r.Phone,
                ARC_PersonAccount__r.vlocity_ins__SocialSecurityNumber__pc,
                ARC_PersonAccount__r.PersonGender,
                ARC_PersonAccount__r.ARC_Smoker__c,
                ARC_PersonAccount__r.ARC_DependentRelationship__c,
                ARC_PersonAccount__r.IsPersonAccount,
                ARC_PersonAccount__r.ARC_IsPrimaryMember__c
            FROM ARC_ContractParticipant__c
            WHERE ARC_Relationship__c = null
            AND ARC_PersonAccount__c !=null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<ARC_ContractParticipant__c> scope) {
        List<ARC_ContractParticipant__c> toUpdate = new List<ARC_ContractParticipant__c>();

        for (ARC_ContractParticipant__c cp : scope) {
            Account acct = cp.ARC_PersonAccount__r;

            if (acct == null || !acct.IsPersonAccount){
                System.debug('No associated Account');
                continue;
            } 

            cp.ARC_FirstName__c = acct.FirstName;
            cp.ARC_LastName__c = acct.LastName;
            cp.Name = acct.FirstName + ' ' + acct.LastName;
            cp.ARC_BirthDate__c = acct.PersonBirthdate;
            cp.ARC_Email__c = acct.PersonEmail;
            cp.ARC_Height__c = acct.ARC_Height__c;
            cp.ARC_Weight__c = acct.ARC_Weight__c;
            //Address
            cp.ARC_Address__Street__s = acct.BillingStreet;
            cp.ARC_Address__City__s = acct.BillingCity;
            cp.ARC_Address__StateCode__s = acct.BillingState;
            cp.ARC_Address__PostalCode__s = acct.BillingPostalCode;
            cp.ARC_Address__CountryCode__s = acct.et4ae5__Mobile_Country_Code__pc;

            cp.ARC_Phone__c = acct.Phone;
            cp.ARC_SocialSecurityNumber__c = acct.vlocity_ins__SocialSecurityNumber__pc;
            cp.ARC_Gender__c = acct.PersonGender;
            cp.ARC_Smoker__c = acct.ARC_Smoker__c;
            cp.ARC_Relationship__c = acct.ARC_DependentRelationship__c;

            if(acct.ARC_IsPrimaryMember__c == true && acct.ARC_DependentRelationship__c == null){
                cp.ARC_Relationship__c = 'Primary';
            }

            toUpdate.add(cp);
        }

        try {
            if (!toUpdate.isEmpty()) {
                update toUpdate;
                System.debug('Updated ' + toUpdate.size() + ' Contract Participants');
            } else {
                System.debug('No Contract Participants to update');
            }
        } catch (Exception e) {
            System.debug('Error updating Contract Participants: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch job finished for ARC_ContractParticipantFieldsBatch');
    }
}