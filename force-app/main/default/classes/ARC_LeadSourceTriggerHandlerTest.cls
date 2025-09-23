@isTest
public with sharing class ARC_LeadSourceTriggerHandlerTest {

    @TestSetup
    static void makeData(){
    
        Lead firstLead = new Lead();
        firstLead.Status = 'New';
        firstLead.LastName = 'Dude';
        insert firstLead;

        Profile memberCommunityProfile = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1];
        User accountOwner = [SELECT Id FROM User WHERE UserRoleId != null AND Profile.Name ='System Administrator' LIMIT 1 ];
        RecordType personAccRT = [SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_IFPPersonAccount' AND SobjectType = 'Account' LIMIT 1];
        Account perAcc = new Account(FirstName = 'Dude', LastName = 'Test', OwnerId = accountOwner.Id, RecordTypeId = personAccRT.Id);
        insert perAcc;
        Contact contactId = [SELECT Id FROM Contact WHERE AccountId = :perAcc.Id];
        User testUser = new User(
            Username = 'testuser@yourorg.com',
            Email = 'testuser@yourorg.com',
            LastName = 'Test',
            FirstName = 'User',
            Alias = 'TU',
            ContactId = contactId.Id,
            CommunityNickname = 'testuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ARC_PortalUsername__c = 'testuser@yourorg.com',
            ProfileId = memberCommunityProfile.Id 
        );
        insert testUser;
    }

    @isTest
    static void leadToSelfEnrollingStatusTest() {
        Lead leadParent = [SELECT Id, Status, Status_Category__c FROM Lead WHERE Status != 'Self Enrolling' LIMIT 1];
        Lead_Source__c leadSrcToInsert = new Lead_Source__c();
        leadSrcToInsert.Source_Name__c ='Self Enroll';
        leadSrcToInsert.Lead__c = leadParent.Id ;
        leadSrcToInsert.Lead_Email__c = 'testuser@yourorg.com' ;
        Test.startTest();
            insert leadSrcToInsert;
        Test.stopTest();
        Lead leadParentAfter = [SELECT Id, Status, Status_Category__c FROM Lead WHERE Id = :leadParent.Id LIMIT 1];
        Assert.areEqual('Self Enrolling', leadParentAfter.Status, 'Status should change to Self Enrolling');
    }
    
    @isTest
    static void parseMarketingURLTest() {
        String SourceURL = 'https://www.testtest.org/lp-open-enrollment2024/'
             + '?utm_source=google&utm_medium=paid-search'
             + '&utm_campaign=oe23_brand_lp-cost-lf&utm_term=testtest'
             + '&utm_content=testtest_pm&utm_medium=cpc'
             + '&utm_source=google&utm_campaign=testtest_oe23_brand'
             + '&utm_term=testtest&campaignid=20775258388'
             + '&adgroupid=156407363958&targetid=kwd-301375548442'
             + '&loc_interest_ms=&loc_physical_ms=1024543&matchtype=p'
             + '&network=g&device=m&devicemodel=&creative=680646494134'
             + '&keyword=testtest&placement=%&adposition=123456&gc_id=20775258388'
             + '&ad_id=680646494134';
        
        Lead_Source__c leadSrcToInsert = new Lead_Source__c();
        leadSrcToInsert.Source_Name__c ='Marketing URL Test leadSrcToInsert';
        leadSrcToInsert.Lead_Phone__c = '17178675309';
        leadSrcToInsert.Landing_Page_Full__c = SourceURL;
        System.Debug('Query String: ' + leadSrcToInsert.Landing_Page_Full__c);
        Test.startTest();
            insert leadSrcToInsert;
        Test.stopTest();
        Lead_Source__c leadSourceAfter = [SELECT Id, Source_Name__c, Ad_Id__c, First_Source__c FROM Lead_Source__c
                          WHERE Lead_Phone__c =: '17178675309' LIMIT 1];
      	System.Debug('After Id: ' + leadSourceAfter.Id);
        System.Debug('After first_source__c: ' +leadSourceAfter.first_source__c);
       	Assert.areEqual('680646494134', leadSourceAfter.Ad_Id__c, 'Ad Id does not match utm param');       
    }
    
}