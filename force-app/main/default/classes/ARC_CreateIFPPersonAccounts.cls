global without sharing class ARC_CreateIFPPersonAccounts implements vlocity_ins.VlocityOpenInterface2{
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'createPersonAccounts') {
            createPersonAccounts(inputMap, outputMap, options);
        }        
        return true;
    }

    public static void createPersonAccounts(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        List<Object> oldMembers = (List<Object>)inputMap.get('oldMembers');    
        List<Object> newMembers = (List<Object>)inputMap.get('newMembers'); 
        Set<String> oldMemberIds = new Set<String>();
        List<Account> accToCreate = new List <Account>();
        RecordType personAccRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_IFPPersonAccount' AND SobjectType = 'Account' LIMIT 1];

        for (Object om : oldMembers) {
            Map<String, Object> oldMemb = (Map<String, Object>)om;
            oldMemberIds.add((String)oldMemb.get('Id'));
        }
        for (Object nm : newMembers) {
            Map<String, Object> newMemb = (Map<String, Object>)nm;
            if (!oldMemberIds.contains((String)newMemb.get('CensusMemberId')) && newMemb.get('contact') == null) {
                Account acc = new Account();
                acc.RecordTypeId = personAccRT.Id;
                acc.FirstName = (String)newMemb.get('CensusMemberFirstName'); 
                acc.LastName = (String)newMemb.get('CensusMemberLastName'); 
                acc.ARC_CensusMember__pc = (String)newMemb.get('CensusMemberId');
                acc.PersonEmail = (String)newMemb.get('CensusEmail');
                acc.vlocity_ins__Email__c = (String)newMemb.get('CensusEmail') == null ? (String)newMemb.get('Email') : (String)newMemb.get('CensusEmail');
                acc.PersonBirthdate = Date.valueOf((String)newMemb.get('Birthdate'));
                accToCreate.add(acc);
            }
        }

        try {

            insert accToCreate;
            List<vlocity_ins__GroupCensusMember__c> membersToUpdate = ARC_CreateIFPPersonAccounts.relateMembersToAccount(accToCreate);
            update membersToUpdate;
            outMap.put('userInputs2', addContactIdToNewMembers(newMembers, membersToUpdate));
        } catch (Exception e) {
            outMap.put('result', 'error, ' + e.getMessage());
        }
    }
    
    public static List<vlocity_ins__GroupCensusMember__c> relateMembersToAccount(List<Account> accountsCreated) {
        Set<Id> accIds = new Set<Id>(new Map<Id, Account>(accountsCreated).keySet());
        List<Account> accList = [ SELECT Id, PersonContactId, ARC_CensusMember__pc FROM Account WHERE Id IN :accIds ];
        List<vlocity_ins__GroupCensusMember__c> membersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();
        for ( Account acc : accList ) {
            vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c();
            member.Id = acc.ARC_CensusMember__pc;
            member.vlocity_ins__ContactId__c = acc.PersonContactId;
            membersToUpdate.add(member);
        }
        return membersToUpdate;
    }

    public static List<Object> addContactIdToNewMembers(List<Object> userInputs2, List<vlocity_ins__GroupCensusMember__c> membersToUpdate) {
        for (Object member : userInputs2) {
            for (vlocity_ins__GroupCensusMember__c memberRecord : membersToUpdate) {
                if (((Map<String, Object>)member).get('Id') == memberRecord.Id) {
                    ((Map<String, Object>)member).put('contactId', memberRecord.vlocity_ins__ContactId__c);
                }
            }
        }
        return userInputs2;
    }
}