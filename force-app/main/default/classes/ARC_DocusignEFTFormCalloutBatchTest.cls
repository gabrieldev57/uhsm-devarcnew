@isTest
public without sharing class ARC_DocusignEFTFormCalloutBatchTest{

    @TestSetup
    static void makeData(){


        Id PROCESSING_QUEUE_ID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperNAME = 'ProcessingQueue']?.Id;
        Id SERVICE_CASE_RECORDTYPE_ID = [SELECT Id FROM RecordType WHERE DeveloperName = 'Service' AND SObjectType = 'Case' LIMIT 1]?.Id;
        Id INTEGRATION_USER = [SELECT Id FROM User WHERE Name = 'Integration User' LIMIT 1]?.Id;
        Id PERSON_ACCOUNT_RT_ID = [SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_IFPPersonAccount'].Id;

        vlocity_ins__VlocityDocuSignTemplate__c test_docusign_template = new vlocity_ins__VlocityDocuSignTemplate__c();
        test_docusign_template.Name = 'WeShare healthcare by UHSM EFT Form';
        insert test_docusign_template;

        Account group_account = new Account(Name = 'Test Group Account');
        insert group_account;

        Account test_person_account = new Account();
        test_person_account.RecordTypeId = PERSON_ACCOUNT_RT_ID;
        test_person_account.FirstName = 'Test';
        test_person_account.LastName = 'Member';
        // test_person_account.Census_Member__c = test_census_member.Id;
        insert test_person_account;

        vlocity_ins__GroupCensus__c test_census = new vlocity_ins__GroupCensus__c();
        test_census.Name = 'Test Census';
        test_census.vlocity_ins__GroupId__c = group_account.Id;
        test_census.ARC_PrimaryAccount__c = test_person_account.Id;
        insert test_census;

        //Create vlocity_ins__GroupCensusMember__c
		vlocity_ins__GroupCensusMember__c test_census_member = new vlocity_ins__GroupCensusMember__c();
        test_census_member.Name = 'Test Census Member';
        test_census_member.vlocity_ins__FirstName__c = 'Test';
        test_census_member.vlocity_ins__LastName__c = 'Census Member';
        test_census_member.vlocity_ins__CensusId__c = test_census.Id;
		test_census_member.ARC_PhysicalAddressState__c = 'CA';
		test_census_member.vlocity_ins__IsPrimaryMember__c = true;
		test_census_member.ARC_ActiveMember__c = true;
		test_census_member.vlocity_ins__FirstName__c = 'TestFirstName';
		test_census_member.vlocity_ins__Birthdate__c = Date.newInstance(1997, 11, 1);
        test_census_member.vlocity_ins__ContactId__c = [SELECT PersonContactId FROM Account WHERE Id =: test_person_account.Id].PersonContactId;
		insert test_census_member;

        Contact test_contact = [SELECT Id FROM Contact WHERE Id =: [SELECT PersonContactId FROM Account WHERE Id =: test_person_account.Id].PersonContactId];
        test_contact.ARC_CensusMember__c = test_census_member.Id;
        update test_contact;

        test_person_account.ARC_CensusMember__pc = test_census_member.Id;
        test_person_account.ARC_Census__c = test_census.Id;
        update test_person_account;

        Id censusmemberid = [SELECT Census_Member__c FROM Account WHERE Id =: test_person_account.Id].Census_Member__c;

        System.debug(test_census_member.vlocity_ins__ContactId__c);
        System.debug(censusmemberid);
        //Create Contract
		Contract test_contract = ARC_TestUtility.createContractsAA(1)[0];
		test_contract.vlocity_ins__EnrollmentCensusId__c = test_census.Id;
		test_contract.ARC_EffectiveDate__c = System.today();
		insert test_contract;


        Date expirationDate = Date.today().addMonths(1);
        
        //Create Chargent Orders 
        System.debug(test_contract.Id);
        ChargentOrders__ChargentOrder__c test_chargent_order =new ChargentOrders__ChargentOrder__c();
        test_chargent_order.ARC_Contract__c = test_contract.Id;
        test_chargent_order.ChargentOrders__Shipping__c = 232;
        test_chargent_order.ChargentOrders__Tax__c  = 232;
        test_chargent_order.ChargentOrders__Charge_Amount__c = 232;
        test_chargent_order.ChargentOrders__Subtotal__c  = 232;
        test_chargent_order.ChargentOrders__Charge_Date__c =  '01';
        test_chargent_order.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
        test_chargent_order.ChargentOrders__Payment_Status__c = 'Recurring';
        test_chargent_order.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
        test_chargent_order.ChargentOrders__Payment_Method__c = 'Credit Card';
        test_chargent_order.ChargentOrders__Card_Last_4__c = '1234';
        test_chargent_order.ChargentOrders__Card_Type__c = 'VISA';
        test_chargent_order.ChargentOrders__Card_Expiration_Month__c = String.valueOf(expirationDate.month());
        test_chargent_order.ChargentOrders__Card_Month_Indicator__c = String.valueOf(expirationDate.month());
        test_chargent_order.ChargentOrders__Card_Expiration_Year__c = String.valueOf(expirationDate.year());
        test_chargent_order.ChargentOrders__Card_Year_Indicator__c = String.valueOf(expirationDate.year());
        test_chargent_order.ChargentOrders__Tokenization__c = '12345678';
        test_chargent_order.ChargentOrders__Description__c = 'Recurring Monthly Order';
        insert test_chargent_order;

        test_contract.Status = 'Activated';
        test_contract.ARC_RecurringMonthlyOrder__c = test_chargent_order.Id;
		update test_contract;

        Case test_case = new Case();
        test_case.RecordTypeId = SERVICE_CASE_RECORDTYPE_ID;
        test_case.OwnerId = PROCESSING_QUEUE_ID;
        test_case.CreatedById = INTEGRATION_USER;
        test_case.LastModifiedById = INTEGRATION_USER;
        test_case.Status = 'New';
        test_case.Case_Type__c = 'Contribution';
        test_case.ARC_Reason__c = 'CC Expiration Date';
        test_case.Origin = 'System';
        test_case.ARC_Type__c = 'Member';
        test_case.Subject = 'CC expiring ' + test_chargent_order.ChargentOrders__Card_Month_Indicator__c + '/' + test_chargent_order.ChargentOrders__Card_Year_Indicator__c;
        test_case.Description = 'CC expiring ' + test_chargent_order.ChargentOrders__Card_Month_Indicator__c + '/' + test_chargent_order.ChargentOrders__Card_Year_Indicator__c;
        test_case.ARC_Contract__c = test_chargent_order.ARC_Contract__r.Id;
        test_case.ARC_PersonAccount__c = [SELECT Id FROM Account WHERE RecordTypeId =: PERSON_ACCOUNT_RT_ID LIMIT 1].Id;
        test_case.ARC_CensusMember__c = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1].Id;
        insert test_case;

    }

    @isTest
    public static void testDocusignFormCalloutBatch(){
        Case test_case = [SELECT Id FROM Case LIMIT 1];
        Database.executeBatch(new ARC_DocusignEFTFormCalloutBatch(new List<Id> {test_case.Id}));
    }

}