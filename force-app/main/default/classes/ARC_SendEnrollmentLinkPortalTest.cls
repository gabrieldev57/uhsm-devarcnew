@IsTest
private class ARC_SendEnrollmentLinkPortalTest {

    // Utility to create minimal metadata-like records needed for queries in controller
    private static void setupData(Boolean withEmail) {
        // Create Group Account (parent) and Person Account (child)
        Account grp = new Account(Name = 'Test Group');
        insert grp;

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_SGPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        for(Integer i=0; i<1;i++){
            Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount'+i, LastName ='Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode='12345';
            acc.PersonEmail=withEmail ? 'john.doe@example.com' : null;
            acc.vlocity_ins__Email__c='test@email.com'+counter;
            acc.FirstName='John';
            acc.LastName='Doe';
            acc.PersonBirthdate=Date.newInstance(1994,12,07);
            acc.ARC_IsPrimaryMember__c = true;
            acc.Phone = '123456789';
            acc.ARC_GroupAccount__c = grp.Id;
            
            accList.add(acc);
        }
        insert accList;

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(1);
        counter = 0;
        List<Account> perAccList = [SELECT Id, PersonContactId FROM Account];
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = perAccList[counter].PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
            censusMember.vlocity_ins__FirstName__c = 'Portal';
            censusMember.vlocity_ins__LastName__c = 'User';
            counter++;
        }
        update censusMemberList;

        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        accList[0].Census_Member__c = censusMemberList[0].Id;
        accList[0].ARC_CensusMember__pc = censusMemberList[0].Id;
        accList[0].ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        update accList;


        // Create a user to own the template/org wide email
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'jsmith',
            Email = 'jsmith@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Smith',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'jsmith.' + System.currentTimeMillis() + '@example.com',
            ProfileId = p.Id
        );
        insert u;

        System.runAs(u) {
            // Email Template (Name must match controller query). Use Text template to avoid Letterhead requirement
            EmailTemplate et = new EmailTemplate(
                Name = 'Complete Your Enrollment Today',
                DeveloperName = 'Complete_Your_Enrollment_Today',
                FolderId = UserInfo.getUserId(),
                TemplateType = 'text',
                Subject = 'Complete Your Enrollment',
                Body = 'Hello {Account.FirstName}, please complete: [enrollment_link]. OE ends [OE_END_DATE]'
            );
            insert et;
        }

        // Contract for the Group Account to provide ARC_OEEndDate__c
        Contract c = new Contract(
            AccountId = grp.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12,
            ARC_OEEndDate__c = Date.today().addDays(7)
        );
        insert c;
    }

    @IsTest static void test_sendEmail_success_singlePerson() {
        setupData(true);
        Account person = [SELECT Id, Census_Member__c FROM Account WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
      

        ARC_SendEnrollmentLinkPortalController.Request req = new ARC_SendEnrollmentLinkPortalController.Request();
        req.personAccountIds = new List<Id>{ person.Id };

        Test.startTest();
        List<ARC_SendEnrollmentLinkPortalController.Response> res = ARC_SendEnrollmentLinkPortalController.sendEmail(new List<ARC_SendEnrollmentLinkPortalController.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size(), 'One response expected');
        ARC_SendEnrollmentLinkPortalController.Response r = res[0];
        System.assertNotEquals(null, r.totalEmailsAttempted, 'totalEmailsAttempted should be set');
        System.assertEquals(true, r.totalEmailsAttempted >= 1, 'At least one email attempted');
        System.assertEquals(true, r.numberOfEmailsSent >= 0, 'Sent count set');
        System.assertEquals(true, r.numberOfEmailsFailed >= 0, 'Failed count set');
        System.assertEquals(r.numberOfEmailsSent > 0, r.emailsSent, 'emailsSent flag should reflect sent count');

        Integer emCount = [SELECT count() FROM EmailMessage WHERE ToAddress LIKE '%@example.com%'];
        System.assert(emCount > 0, 'EmailMessage records should be inserted');
    }

    @IsTest static void test_sendEmail_noRequests() {
        Test.startTest();
        List<ARC_SendEnrollmentLinkPortalController.Response> res = ARC_SendEnrollmentLinkPortalController.sendEmail(new List<ARC_SendEnrollmentLinkPortalController.Request>());
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].emailsSent, 'No emails when no requests');
        System.assertEquals(0, res[0].numberOfEmailsSent);
    }

    @IsTest static void test_sendEmail_noEmailOnPerson() {
        setupData(false);

        Account person = [SELECT Id FROM Account WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];

        ARC_SendEnrollmentLinkPortalController.Request req = new ARC_SendEnrollmentLinkPortalController.Request();
        req.personAccountIds = new List<Id>{ person.Id };

        Test.startTest();
        List<ARC_SendEnrollmentLinkPortalController.Response> res = ARC_SendEnrollmentLinkPortalController.sendEmail(new List<ARC_SendEnrollmentLinkPortalController.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(false, res[0].emailsSent, 'No emails should be sent when person email is null');
        System.assertEquals(0, res[0].numberOfEmailsSent);
    }

    @IsTest static void test_checkEnrollmentPermission_executes() {
        Test.startTest();
        Boolean hasPerm = ARC_SendEnrollmentLinkPortalController.checkEnrollmentPermission(new List<Id>());
        Test.stopTest();
        System.assertNotEquals(null, hasPerm);
    }
}