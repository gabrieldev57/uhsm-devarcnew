@isTest
public with sharing class ARC_TestUtilityTest {
    @isTest
    public static void testCreateTestAccount(){
        Test.startTest();
        List<Account> expectedAccounts =  ARC_TestUtility.createTestAccount(1,'IndustriesBusiness');
        Test.stopTest();

        System.AssertEquals(true,expectedAccounts.size() > 0 );
    }

    @isTest
    public static void testCreateTestContact(){
        Test.startTest();
        List<Contact> expectedContacts =  ARC_TestUtility.createTestContact(1,'Producer');
        Test.stopTest();
        System.AssertEquals(true,expectedContacts.size() > 0 );

    }
        
    @isTest
    public static void testCreateTestEmailCampaign(){
        Test.startTest();
        List<ARC_EmailCampaign__c> expectedEmailCampaigns =  ARC_TestUtility.createTestEmailCampaign(1);
        Test.stopTest();

        System.AssertEquals(true,expectedEmailCampaigns.size() > 0 );

    }
    
	@isTest
    public static void testCreateTestEmail(){
        Test.startTest();
        List<ARC_EmailCampaign__c> expectedEmailCampaigns =  ARC_TestUtility.createTestEmailCampaign(1);
        List<ARC_Email__c> expectedEmails =  ARC_TestUtility.createTestEmail(1,expectedEmailCampaigns[0]);
        Test.stopTest();

        System.AssertEquals(true,expectedEmailCampaigns.size() > 0 );
        System.AssertEquals(true,expectedEmails.size() > 0 );

    }
    
    @isTest
    public static void testCreateTestOS(){
        Test.startTest();
        List<vlocity_ins__OmniScript__c> expectedOS = ARC_TestUtility.createTestOmniscript(1);
        Test.stopTest();

        System.AssertEquals(true,expectedOS.size() > 0 );

    }
    @isTest
    public static void testCreateTestPolicies(){
        Test.startTest();
        List<InsurancePolicy>  expected = ARC_TestUtility.createTestPolicies(1);
        Test.stopTest();
        System.AssertEquals(true,expected.size() > 0 );
    }
    @isTest
    public static void testCreateTestContractLineItem(){
        Test.startTest();
        List<vlocity_ins__ContractLineItem__c> expected= ARC_TestUtility.createTestContractLineItem(1);
        Test.stopTest();
        System.AssertEquals(true,expected.size() > 0 );
    }
    @isTest
    public static void testCreateTestOSDef(){
        Test.startTest();
        List<vlocity_ins__OmniScript__c> expectedOS = ARC_TestUtility.createTestOmniscript(1);
        List<vlocity_ins__OmniScriptDefinition__c> expectedOSDef = ARC_TestUtility.createTestOmniscriptDefinition(1, expectedOS[0]);
        Test.stopTest();

        System.AssertEquals(true,expectedOS.size() > 0 );
        System.AssertEquals(true,expectedOSDef.size() > 0 );

    }
    
    @isTest
    public static void testCreateTestStaticResource(){
        Test.startTest();
        List<StaticResource> expectedStaticResource = ARC_TestUtility.createTestStaticResource(1);
        Test.stopTest();

        System.AssertEquals(true,expectedStaticResource.size() > 0 );

    }
    
    @isTest
    public static void testCreateTestUsers(){
        Test.startTest();
        List<User> expectedUser = ARC_TestUtility.createTestUsers(1, 'Standard User');
        Test.stopTest();

        System.AssertEquals(true,expectedUser.size() > 0 );

    }
    
    @isTest
    public static void testCreateTestLeads(){
        Test.startTest();
        List<Lead> expectedLeads = ARC_TestUtility.createTestLeads(1);
        Test.stopTest();

        System.AssertEquals(true,expectedLeads.size() > 0 );

    }
    
    @isTest
    public static void testCreateTestBenefitCards(){
        Test.startTest();
        Map<BenefitCard__c, ContentVersion> expectedBC = ARC_TestUtility.createTestBenefitCards(1);
        Test.stopTest();

        System.AssertEquals(true,expectedBC.size() > 0 );

    }
    
    @isTest
    public static void testCreateTestQuote(){
        Test.startTest();
        Quote expectedQuote = ARC_TestUtility.createTestQuoteForCampaigns('Quote1');
        Test.stopTest();

        List<Quote> quoteList = new List<Quote>{expectedQuote};

        System.AssertEquals(true, quoteList.size() > 0 );

    }
    
    @isTest
    public static void testCreateHealthProgram(){
        Test.startTest();
    	List<ARC_HealthProgram__c> hpl = ARC_TestUtility.createTestHealthProgram(1, 'Gold', true,'Vacation');
        Test.stopTest();
    
        System.AssertEquals(true,hpl.size() > 0 );

    }

    @isTest
    public static void testCreateHealthProgramSpec(){
        Test.startTest();
    	List<ARC_HealthProgram__c> hpl = ARC_TestUtility.createTestHealthProgram(1, 'Gold', true,'Vacation');
        List<ARC_HealthProgramSpec__c> hplspec = ARC_TestUtility.createTestHealthProgramSpecs(hpl);
        Test.stopTest();

        System.AssertEquals(true,hpl.size() > 0 );
        System.AssertEquals(true,hplspec.size() > 0 );

    }
    
    @isTest
    public static void testCreateContract(){
        Test.startTest();
    	List<Contract> expectedContract = ARC_TestUtility.createContracts(1);
        Test.stopTest();

        System.AssertEquals(true,expectedContract.size() > 0 );
    }
    
    @isTest
    public static void testCreateContractsUniqueAccounts(){
    	Test.startTest();
        List<Contract> expectedContract = ARC_TestUtility.createContractsUniqueAccounts(1);
        Test.stopTest();
        
        System.AssertEquals(true,expectedContract.size() > 0 );
    }
    
    @isTest
    public static void testCreateEmailTemplate(){
    	Test.startTest();
        List <Account> testAccounts = ARC_TestUtility.createTestAccountForCampaigns('TestAccount', 'testtest@uhsm.org.test');
        insert testAccounts;
        EmailTemplate expectedTemplate = ARC_TestUtility.createEmailTemplate(testAccounts);
        Test.stopTest();
        
        System.AssertEquals(true,expectedTemplate.Id !='');
    }
        
    @isTest
    public static void testCreateTestCampaigns(){
    	Test.startTest();
        ARC_EmailCampaign__c expectedCampaign = ARC_TestUtility.createTestCampaigns('', '', '', '', '', '');
        Test.stopTest();
        
        System.AssertEquals(true,expectedCampaign.Id !='' );
    }
    
    @isTest
    public static void testCreateEmails(){
        Test.startTest();
        List<ARC_EmailCampaign__c> expectedEmailCampaigns =  ARC_TestUtility.createTestEmailCampaign(1);
        List<Contract> expectedContract = ARC_TestUtility.createContracts(1);
    	List<ARC_Email__c> expectedEmail = ARC_TestUtility.createEmails(expectedEmailCampaigns[0],expectedContract[0].Id);
        Test.stopTest();

        System.AssertEquals(true,expectedEmailCampaigns.size() > 0 );
        System.AssertEquals(true,expectedContract.size() > 0 );
        System.AssertEquals(true,expectedEmail.size() > 0 );

    }

    @isTest
    public static void testCreateSavedOsFromObject(){
        Test.startTest();
        List<Account> expectedAccounts =  ARC_TestUtility.createAccountsWithOpps(1,1);
        List<vlocity_ins__OmniScriptInstance__c> expectedSavedOs =  ARC_TestUtility.createSavedOsFromObject(expectedAccounts,1);
        Test.stopTest();

        System.AssertEquals(true,expectedAccounts.size() > 0 );
        System.AssertEquals(true,expectedSavedOs.size() > 0 );
    }

    @isTest
    public static void testCreateAccountsWithOpps(){
        Test.startTest();
        List<Account> expectedAccounts =  ARC_TestUtility.createAccountsWithOpps(1,1);
        Test.stopTest();

        System.AssertEquals(true,expectedAccounts.size() > 0 );

    }

    @isTest
    public static void testCreateCase(){
        Test.startTest();
        List<Case> expectedCase =  ARC_TestUtility.createTestCase(1,'Admission');
        Test.stopTest();

        System.AssertEquals(true,expectedCase.size() > 0 );

    }

    @isTest
    public static void testRetrieveMdt(){
        Test.startTest();
        List<ARC_Settings__mdt> expectedMetadata = ARC_TestUtility.getAllMetadataSettingsFromOrg();
        Test.stopTest();

        System.AssertEquals(true,expectedMetadata.size() > 0 );

    }

    @isTest
    public static void testcreateTestAccountForCampaigns(){
        Test.startTest();
        List<Account> expectedAccount = ARC_TestUtility.createTestAccountForCampaigns('Test Account', 'emailtest@example.com');
        Test.stopTest();

        System.AssertEquals(true,expectedAccount.size() > 0 );

    }

    @isTest
    public static void testcreateTestClaims(){
        Test.startTest();
        List<Claim> expectedClaim = ARC_TestUtility.createTestClaims(1);
        Test.stopTest();

        System.AssertEquals(true,expectedClaim.size() > 0 );

    }

    @isTest
    public static void testcreateTestCensusMember(){
        Test.startTest();
        List<vlocity_ins__GroupCensusMember__c> expectedCensusMembers = ARC_TestUtility.createTestCensusMember(1);
        Test.stopTest();

        System.AssertEquals(true,expectedCensusMembers.size() > 0 );
    }

    @isTest
    public static void testcreateTestUndCaseMember(){
        Test.startTest();
        List<ARC_UnderwritingCaseMember__c> expectedUnderwritingCaseMember = ARC_TestUtility.createTestUndCaseMember(1);
        Test.stopTest();

        System.AssertEquals(true,expectedUnderwritingCaseMember.size() > 0 );

    }

    @isTest
    public static void createTestCensusMemPlan(){
        Test.startTest();
        List<vlocity_ins__GroupCensusMemberPlan__c> expectedGroupCensusMemberPlan = ARC_TestUtility.createTestCensusMemPlan(1);
        Test.stopTest();

        System.AssertEquals(1, expectedGroupCensusMemberPlan.size());

    }

    @isTest
    public static void createChargentTransactions(){
        Test.startTest();
        List<ChargentOrders__Transaction__c> expectedTransactions = ARC_TestUtility.createChargentTransactions(1);
        Test.stopTest();

        System.AssertEquals(1, expectedTransactions.size());

    }

    @isTest
    public static void testCreateTestAttributes() {
        Integer numAtt = 5;
        
        Test.startTest();
        List<vlocity_ins__Attribute__c> attributes = ARC_TestUtility.createTestAttributes(numAtt);
        Test.stopTest();
        
        System.assertEquals(numAtt, attributes.size());
    }

    @isTest
    public static void testCreateTestProducts() {
        Integer numProd = 10;
        
        Test.startTest();
        List<Product2> products = ARC_TestUtility.createTestProducts(numProd);
        Test.stopTest();

        System.assertEquals(numProd, products.size());
    }

    @isTest 
    public static void testCreateChargentOrders() {
        Test.startTest();
        List<ChargentOrders__ChargentOrder__c> orders = ARC_TestUtility.createChargentOrders(3);
        Test.stopTest();
        System.assertEquals(3, orders.size());
    }
  
    @isTest
    public static void testCreateContractsAA(){
        Test.startTest();
        List<Contract>  contracts = ARC_TestUtility.createContractsAA(3);
        Test.stopTest();
        System.AssertEquals(3,contracts.size());
    }

    @isTest
    public static void testCreateCompleteEnrollments(){
        Test.startTest();
        List<Contract>  contracts = ARC_TestUtility.createCompleteEnrollments(10);
        Test.stopTest();
        System.AssertEquals(10,contracts.size());
    }
}