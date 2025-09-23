@isTest
public class ARC_ScheduleExpiringCreditCardsTest {

    @TestSetup
    static void makeData(){

        vlocity_ins__VlocityDocuSignTemplate__c test_docusign_template = new vlocity_ins__VlocityDocuSignTemplate__c();
        test_docusign_template.Name = 'WeShare healthcare by UHSM EFT Form';
        insert test_docusign_template;

        Account group_account = new Account(Name = 'Test Group Account');
        insert group_account;

        Account test_person_account = new Account();
        test_person_account.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_IFPPersonAccount'].Id;
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

        test_contract.Status = 'Awaiting Activation';
        test_contract.ARC_EffectiveDate__c = Date.today().addDays(2);
        update test_contract;

        test_contract.Status = 'Activated';
        test_contract.ARC_RecurringMonthlyOrder__c = test_chargent_order.Id;
		update test_contract;
    }

    @isTest
    static void testBatchMethod(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseForDocuSign());
        ARC_ScheduleExpiringCreditCards scheduledClass = new ARC_ScheduleExpiringCreditCards();
        Database.executeBatch(scheduledClass,50);
        Test.stopTest();
    }

    @IsTest
    static void testSchedulerMethod(){
        Test.startTest();
        ARC_ScheduleExpiringCreditCards schedulable_class = new ARC_ScheduleExpiringCreditCards();
        Id jobId = System.schedule('ARC_ScheduleExpiringCreditCardsTest', '0 0 2 * * ?', schedulable_class);
        Test.stopTest();
    }

    public class MockHttpResponseForDocuSign implements HttpCalloutMock {
        // Implement the respond method
        public HTTPResponse respond(HTTPRequest request) {
            // Create a new HTTPResponse
            HttpResponse response = new HttpResponse();
            
            // Set a status code
            response.setStatusCode(200);
            
            // Mock response body
            String responseBody = JSON.serialize(new Map<String, Object>{
                'textTabs' => new Map<String, Object>{
                    'FullName' => 'Test Test',
                    'DOB' => '1997-01-01',
                    'ID' => 'W400159700',
                    'FirstName' => 'Test',
                    'LastName' => 'Test',
                    'Street' => '123 Haverly Street',
                    'City' => 'Crested Butte',
                    'State' => 'CO',
                    'ZipCode' => '81224',
                    'EmailAddress' => 'test@test.com',
                    'PaymentAmount' => null,
                    'CardName' => 'Test Test',
                    'CardNumber' => '4345697042449388',
                    'CardExpiration' => '1/2028',
                    'CardBilling' => 'Test Address'
                },
                'checkboxTabs' => new Map<String, Object>{
                    'CreditCard' => true,
                    'Visa' => true
                }
            });
            
            // Set the response body
            response.setBody(responseBody);
            
            // Set the content type
            response.setHeader('Content-Type', 'application/json');
            
            return response;
        }
    }

}