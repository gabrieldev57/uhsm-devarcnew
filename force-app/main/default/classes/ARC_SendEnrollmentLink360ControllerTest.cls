@isTest
public with sharing class ARC_SendEnrollmentLink360ControllerTest {
    @TestSetup
    static void makeData(){
        // 1. Create group Account
        Id groupRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Group').getRecordTypeId();
        Account groupAcc = new Account(
            RecordTypeId = groupRT,
            Name = 'SG Group Account'
        );
        insert groupAcc;
    
        // 2. Create the Person Account
        Id sgPersonAccountRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId();
        Account personAcc = new Account(
            RecordTypeId = sgPersonAccountRT,
            FirstName = 'FN Test',
            LastName = 'LN Test',
            PersonEmail = 'fntestlntest@yopmail.com',
            IsActive = true,
            ARC_GroupAccount__c = groupAcc.Id
        );
        insert personAcc;
    
        // 3. Create the Contract
        Date todayDate = Date.today();
        Id sgContractRT = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Contract contractTest = new Contract(
            RecordTypeId = sgContractRT,
            AccountId = groupAcc.Id,
            ARC_ContractReason__c = 'Renewal',
            ARC_OEStartDate__c = todayDate
        );
        insert contractTest;
    
        // 4. EmailTemplate en contexto separado para evitar MIXED_DML
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(currentUser) {
            EmailTemplate et = new EmailTemplate(
                Name = 'Complete Your WeShare Enrollment Today',
                DeveloperName = 'Complete_Your_WeShare_Enrollment_Today',
                TemplateType = 'custom',   // ← cambio clave
                Subject = 'Complete Your Enrollment',
                HtmlValue = '<p>Hi {!Account.FirstName}, from {!Account.ARC_GroupAccount__c}. Click [enrollment_link]</p>',
                Body = 'Hi, Click the enrollment link.',  // ← requerido para custom
                FolderId = UserInfo.getUserId(),
                IsActive = true
            );
            insert et;
        }
    }

    @isTest
    public static void sendRenewalEnrollmentLinksTest() {
        Contract contractTest = [SELECT Id FROM Contract WHERE ARC_ContractReason__c = 'Renewal' LIMIT 1];
        Test.startTest();
        ARC_SendEnrollmentLink360Controller.sendRenewalEnrollmentLinks(new List<Id>{contractTest.Id});
        Test.stopTest();
    }
}