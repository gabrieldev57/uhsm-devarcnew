@isTest
private class ARC_BusinessDetailsControllerTest {

    @testSetup
    static void setupData() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User mgr = new User(
            Alias = 'standt', 
            Email = 'manager@testorg.com',
            EmailEncodingKey = 'UTF-8', 
            LastName = 'ManagerUser', 
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', 
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles', 
            UserName = 'manager@testorg.com.arctest'
        );
        insert mgr;

        Account acc = new Account(
            Name = 'Test Legal Company',
            ARC_AccountManager__c = mgr.Id,
            ARC_LegalCompanyName__c = 'Test Legal Company Inc.',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingState = 'CA',
            BillingPostalCode = '90001',
            ARC_EmployeesInOtherStates__c = true,
            ARC_OtherStates__c = 'NV, AZ',
            ARC_EmployeesInOtherStatesCount__c = 5,
            ARC_OfferSharingBenefitsDuringWaitingPer__c = true,
            ARC_SubjectToCalCOBRA__c = true,
            ARC_CalCOBRAEnrolleesCount__c = 2,
            ARC_SubjectToCOBRA__c = false,
            ARC_COBRAEnrolleesCount__c = 0,
            ARC_Doing_Business_As_Name__c = 'Test DBA',
            ARC_FederalEmployerTaxIDNumber__c = '12-3456789',
            Sic = '1234',
            SicDesc = 'Test Sic Desc',
            ARC_NAICSCode__c = '541511',
            ARC_TypeOfBusiness__c = 'Logistics Technology',
            ARC_OtherTypeOfBusiness__c = 'AI Dev',
            vlocity_ins__DateFounded__c = Date.today().addYears(-10),
            ARC_MeetsSmallEmployerDefinition__c = true,
            ARC_TotalEmployees__c = 50,
            ARC_AllowDependents__c = true,
            ARC_NumberOfIneligibleEmployees__c = 5,
            ARC_IsNonProfit__c = 'No',
            ARC_NewEmployeeWaitingPeriod__c = 'First of the month following hire date',
            ARC_Entity_Type__c = 'Corporation',
            ARC_OtherEntityType__c = '',
            ARC_MemberOfAssociation__c = true,
            ARC_AssociationName__c = 'Tech Assoc',
            ARC_MedicalLeaveAllowedMonths__c = '3 Months',
            ARC_PayPeriod__c = 'Two Weeks', 
            ARC_OfferingOtherCoverage__c = true,
            ARC_OtherCoverageCarrierName__c = 'Other Carrier',
            ARC_OtherCoverageRenewalMonth__c = 'January',
            ARC_OtherCoverageEmployeesCovered__c = 10
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            ARC_RequestedEffectiveDate__c = Date.today().addDays(15),
            ARC_OEStartDate__c = Date.today().addDays(-5),
            ARC_OEEndDate__c = Date.today() 
        );
        insert opp;

        Contract con = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12,
            ARC_EffectiveDate__c = Date.today()
        );
        insert con;
    }

    @isTest
    static void testGetBusinessDetails_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        ARC_BusinessDetailsController.BusinessDetailsData result = ARC_BusinessDetailsController.getBusinessDetails(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('Test Legal Company', result.companyName);
        System.assertEquals('Test Legal Company Inc.', result.legalCompanyName);
        System.assertEquals('12-3456789', result.federalTaxId);
        System.assertEquals(5, result.employeesInOtherStatesCount);
        System.assertEquals('ManagerUser', result.accountManagerName);
        System.assertEquals(Date.today().addDays(15), result.requestedEffectiveDate);
        System.assertEquals(Date.today(), result.contractEffectiveDate);
    }

    @isTest
    static void testGetBusinessDetails_NullId() {
        Test.startTest();
        try {
            ARC_BusinessDetailsController.getBusinessDetails(null);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }
        Test.stopTest();
    }

    @isTest
    static void testGetBusinessDetails_NoAccount() {
        Opportunity orphanOpp = new Opportunity(
            Name = 'Orphan Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert orphanOpp;

        Test.startTest();
        try {
            ARC_BusinessDetailsController.getBusinessDetails(orphanOpp.Id);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }
        Test.stopTest();
    }

    @isTest
    static void testGetBusinessDetails_GeneralException() {
        Id fakeId = Opportunity.sObjectType.getDescribe().getKeyPrefix() + '000000000001';
        
        Test.startTest();
        try {
            ARC_BusinessDetailsController.getBusinessDetails(fakeId);
            System.assert(false, 'Should throw exception');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }
        Test.stopTest();
    }

    @isTest
    static void testSearchUsers() {
        Test.startTest();
        List<ARC_BusinessDetailsController.UserResult> results = ARC_BusinessDetailsController.searchUsers('ManagerUser', 10);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assert(results.size() > 0);
        System.assertEquals('manager@testorg.com', results[0].Email);
    }

    @isTest
    static void testSearchSICCodes() {
        Test.startTest();
        List<ARC_BusinessDetailsController.SICCodeResult> results = ARC_BusinessDetailsController.searchSICCodes('a', 10);
        Test.stopTest();

        System.assertNotEquals(null, results);
    }
}