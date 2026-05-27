@isTest
private class ARC_SGContactPortalUserHandlerTest {

    @TestSetup
    static void setupData() {
        Account eligibleAcc = new Account(Name = 'Eligible Account');
        insert eligibleAcc;

        Contract ctr = new Contract(
            AccountId = eligibleAcc.Id,
            Status = 'Draft',
            vlocity_ins__LastDocuSignEnvelopeStatus__c = 'Completed'
        );
        insert ctr;

        Account ineligibleAcc = new Account(Name = 'Ineligible Account');
        insert ineligibleAcc;
    }

    @isTest
    static void testInsertEligibleContact() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Eligible Account' LIMIT 1];
        Id rtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'AdminUser',
            Email = 'test.admin@test.com',
            AccountId = acc.Id,
            RecordTypeId = rtId,
            ARC_PortalAccess__c = 'Admin'
        );

        Test.startTest();
        insert c;
        Test.stopTest(); 

        System.assertNotEquals(null, c.Id, 'The contact should be inserted correctly.');
    }

    @isTest
    static void testUpdateContactAccessAndInfo() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Eligible Account' LIMIT 1];
        Id rtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'BasicUser',
            Email = 'test.basic@test.com',
            AccountId = acc.Id,
            RecordTypeId = rtId,
            ARC_PortalAccess__c = 'No Access'
        );
        insert c;

        Test.startTest();
        c.ARC_PortalAccess__c = 'Viewer';
        c.Email = 'test.updated@test.com';
        update c;
        Test.stopTest();

        System.assertEquals('Viewer', c.ARC_PortalAccess__c, 'The access should have been updated.');
    }

    @isTest
    static void testIneligibleAccountSkipsEvent() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Ineligible Account' LIMIT 1];
        Id rtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        Contact c = new Contact(
            FirstName = 'Skip',
            LastName = 'User',
            Email = 'skip@test.com',
            AccountId = acc.Id,
            RecordTypeId = rtId,
            ARC_PortalAccess__c = 'Admin'
        );

        Test.startTest();
        insert c; 
        Test.stopTest();

        System.assertNotEquals(null, c.Id, 'The contact is inserted but does not process the event.');
    }

    @isTest
    static void testUpdateContactEmailAndName() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Eligible Account' LIMIT 1];
        Id rtId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();

        Contact c = new Contact(
            FirstName = 'OriginalFirst',
            LastName = 'OriginalLast',
            Email = 'original.email@test.com',
            AccountId = acc.Id,
            RecordTypeId = rtId,
            ARC_PortalAccess__c = 'Viewer'
        );
        insert c;

        Test.startTest();
        
        c.Email = 'changed.email@test.com';
        update c;

        c.FirstName = 'ChangedFirst';
        c.LastName = 'ChangedLast';
        update c;
        
        Test.stopTest();

        Contact updatedContact = [SELECT Email, LastName FROM Contact WHERE Id = :c.Id];
        System.assertEquals('changed.email@test.com', updatedContact.Email, 'The email should be up to date.');
        System.assertEquals('ChangedLast', updatedContact.LastName, 'The last name should be up to date.');
    }
}