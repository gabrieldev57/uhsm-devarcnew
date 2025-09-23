@isTest
private class ARC_UpdatePaymentMethodTest {
    private static Integer requestCount = 0;
    private class MockCreditCardResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            requestCount++;
            
            // Create a mock response for credit card scenario
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"dateTabs":[{"tabLabel":"IssueDate","value":"01/01/2024"},{"tabLabel":"ExpirationDate","value":"01/01/2030"}],"textTabs":[{"tabLabel":"FirstName","value":"Test"},{"tabLabel":"LastName","value":"Test"},{"tabLabel":"FirstName","value":"John"},{"tabLabel":"LastName","value":"Doe"},{"tabLabel":"CardNumber","value":"4111111111111111"},{"tabLabel":"CardExpiration","value":"01/30"}],"checkboxTabs":[{"tabLabel":"CreditCard","selected":"true"},{"tabLabel":"ACH","selected":"false"}]}');            return res;
        }
    }

    // Mock class for bank account scenario
    private class MockBankAccountResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            requestCount++;
            
            // Create a mock response for bank account scenario
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"dateTabs":[{"tabLabel":"FirstName","value":"Test"}],"textTabs":[{"tabLabel":"FirstName","value":"Test"},{"tabLabel":"LastName","value":"Test"},{"tabLabel":"AccountName","value":"John Doe"},{"tabLabel":"BankName","value":"Test Bank"},{"tabLabel":"AccountNumber","value":"1234567890"}],"checkboxTabs":[{"tabLabel":"ACH","selected":"true"},{"tabLabel":"Checking","selected":"true"},{"tabLabel":"Savings","selected":"false"},{"tabLabel":"CreditCard","selected":"false"}]}');
            return res;
        }
    }

    public static Integer getRequestCount() {
        return requestCount;
    }
    @testSetup
    static void setup() {
        // Create test data
        vlocity_ins__ContractLineItem__c cli = ARC_TestUtility.createTestContractLineItem(1)[0];
        
        // create member plans
        List<vlocity_ins__GroupCensusMemberPlan__c> memberPlans = ARC_TestUtility.createTestCensusMemPlan(1);

        for(vlocity_ins__GroupCensusMemberPlan__c memberPlan : memberPlans){
            memberPlan.vlocity_ins__ContractLineId__c = cli.Id;
        }
        update memberPlans;

        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        
        contract.Status = 'Awaiting Signature';
        update contract;

        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        Account pa = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount')[0];
        members[0].vlocity_ins__FirstName__c = 'Test';
        members[0].vlocity_ins__LastName__c = 'User';
        update members;
        members[0].vlocity_ins__ContactId__c = [SELECT Id FROM Contact LIMIT 1].Id;
        
        update members;
        
        ChargentOrders__ChargentOrder__c order = ARC_TestUtility.createChargentOrders(1)[0];
        order.ARC_Contract__c = contract.Id;
        insert order;
        contract.ARC_RecurringMonthlyOrder__c = order.Id;
        update contract;

        pa.Census_Member__c = members[0].Id;
        update pa;
    }

    @isTest
    static void testInvokeMethod() {
        ARC_UpdatePaymentMethod updater = new ARC_UpdatePaymentMethod();
        
        // Prepare input maps
        Map<String, Object> input = new Map<String, Object>{
            'PersonAccountId' => [SELECT Id FROM Account LIMIT 1].Id
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Test getPayorForSelect method
        Boolean result = updater.invokeMethod('getPayorForSelect', input, outMap, options);
        System.assert(result, 'Method should return true');
        System.assert(outMap.containsKey('payorOptions'), 'Output map should contain payorOptions');
        
        // Test other methods similarly...
    }
    
    @isTest
    static void testGetPayorForSelect() {
        // Prepare input maps
        Map<String, Object> input = new Map<String, Object>{
            'PersonAccountId' => [SELECT Id FROM Account LIMIT 1].Id
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Call the method
        ARC_UpdatePaymentMethod.getPayorForSelect(input, outMap, options);
        
        // Assertions
        System.assert(outMap.containsKey('payorOptions'), 'Output map should contain payorOptions');
        System.assert(outMap.containsKey('censusId'), 'Output map should contain censusId');
    }
    
    @isTest
    static void testUpsertCase() {
        Map<String, Object> input = new Map<String, Object>{
            'ContextId' => [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount'].Id,
            'RAD_ETFRequired' => 'Yes',
            'setRecurring' => 'Yes',
            'RAD_AddressInformationFor' => 'Only for selected payor',
            'STEP_CaseRecord' => new Map<String, Object>{
                'TXT_RecordType' => 'Service',
                'TXT_Subject' => 'TestSubject',
                'TXT_Description' => 'TestDescription',
                'SEL_CaseOrigin' => 'Caller',
                'TXT_Reason' => 'Method Change',
                'SEL_Caller' => 'Member',
                'SEL_Status' => 'New'
            },
            'PersonAccountId' => [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount'].Id
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Call the method
        Test.startTest();
        ARC_UpdatePaymentMethod.upsertCase(input, outMap, options);
        Test.stopTest();
        
        // Assertions
        Case caseRecord = [SELECT Id, ARC_SetRecurringOnSign__c FROM Case LIMIT 1];
        System.assertEquals(true, caseRecord.ARC_SetRecurringOnSign__c, 'Case ARC_SetRecurringOnSign__c should be true');
    }
    
    @isTest
    static void testGetExecutionOrigin() {
        // Prepare input maps
        Map<String, Object> input = new Map<String, Object>{
            'ContextId' => [SELECT Id FROM Account LIMIT 1].Id
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Call the method
        ARC_UpdatePaymentMethod.getExecutionOrigin(input, outMap, options);
        
        // Assertions
        System.assert(outMap.containsKey('executionOrigin'), 'Output map should contain executionOrigin');
    }
    
    @isTest
    static void testUpdateAddresses() {
        // Prepare input maps
        Map<String, Object> input = new Map<String, Object>{
            'PersonAccountId' => [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount'].Id,
            'addressInformationFor' => 'Only for selected payor',
            'state' => 'CA',
            'city' => 'San Francisco',
            'street' => '123 Market St',
            'zip' => '94105',
            'censusId' => 'TestCensusId'
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Call the method
        Test.startTest();
        ARC_UpdatePaymentMethod.updateAddresses(input, outMap, options);
        Test.stopTest();
        
        // Assertions
        Account updatedAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' LIMIT 1];
        // System.assertEquals('CA', updatedAccount.BillingState, 'BillingState should be CA');
        // System.assertEquals('San Francisco', updatedAccount.BillingCity, 'BillingCity should be San Francisco');
        // System.assertEquals('123 Market St', updatedAccount.BillingStreet, 'BillingStreet should be 123 Market St');
        // System.assertEquals('94105', updatedAccount.BillingPostalCode, 'BillingPostalCode should be 94105');
    }
    
    @isTest
    static void testUpdatePaymentMethodCC() {
        List<vlocity_ins__GroupCensus__c> census = ARC_TestUtility.createTestCensus(2);
        List<Contract> contracts = ARC_TestUtility.createContracts(1);
        contracts[0].vlocity_ins__EnrollmentCensusId__c = census[0].Id;
        insert contracts;
        Test.setCreatedDate(contracts[0].Id, Datetime.newInstance(2020, 7, 1));
        List<ChargentOrders__ChargentOrder__c> chargents = ARC_TestUtility.createChargentOrders(4);
        chargents[0].ChargentOrders__Description__c = 'Recurring Monthly Order';
        chargents[0].ChargentOrders__Payment_Method__c = 'Credit Card';
        chargents[0].ARC_Contract__c = contracts[0].Id;
        insert chargents;
        List<RecordType> RT = [ SELECT Id FROM RecordType WHERE sObjectType='ChargentBase__Gateway__c' AND Name = 'Authorize.net' AND isActive=true ];
        ChargentBase__Gateway__c GW = new ChargentBase__Gateway__c();
        GW.name='Chargent Test Gateway';
        GW.recordtypeID = RT.get(0).Id;
        GW.ChargentBase__Active__c = true;
        GW.ChargentBase__Available_Payment_Methods__c = 'Credit Card';
        GW.ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card';
        insert GW;


        List<ChargentOrders__ChargentOrder__c> chargentOrders = [SELECT ARC_Contract__c,ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c,
            ChargentOrders__Account__c,ChargentOrders__Bank_Account_Last_4__c,ChargentOrders__Bank_Account_Name__c,
            ChargentOrders__Bank_Account_Type__c,ChargentOrders__Bank_Name__c,ChargentOrders__Billing_Address__c,
            ChargentOrders__Billing_City__c,ChargentOrders__Billing_Email__c,ChargentOrders__Billing_First_Name__c,
            ChargentOrders__Billing_Last_Name__c,ChargentOrders__Billing_State__c,ChargentOrders__Billing_Zip_Postal__c,
            ChargentOrders__Card_Last_4__c,ChargentOrders__Card_Month_Indicator__c,ChargentOrders__Card_Type__c,
            ChargentOrders__Card_Year_Indicator__c,ChargentOrders__Charge_Amount__c,ChargentOrders__Description__c,
            ChargentOrders__Gateway__c,ChargentOrders__Payment_Frequency__c,ChargentOrders__Payment_Method__c,
            ChargentOrders__Payment_Status__c,ChargentOrders__Payment_Stop__c,ChargentOrders__Subtotal__c,
            ChargentOrders__Tokenization__c, ARC_Contract__r.ARC_TotalPrice__c, ChargentOrders__Card_Number__c,ChargentOrders__Payment_Start_Date__c,
            ChargentOrders__Bank_Account_Number__c,ChargentOrders__Bank_Routing_Number__c,
            (SELECT Id, ChargentOrders__Response_Status__c 
            FROM ChargentOrders__Transactions__r 
            ORDER BY CreatedDate DESC LIMIT 1)  
			FROM ChargentOrders__ChargentOrder__c
        ];

        Map<String,Object> inputMap  = new Map<String,Object>();  
        Map<String,Object> outputMap  = new Map<String,Object>();
        Map<String,Object> options  = new Map<String,Object>();
        List<Map<String, Object>> ordersList = new List<Map<String, Object>>();
        for (ChargentOrders__ChargentOrder__c order : chargentOrders) {
            Map<String, Object> orderMap = new Map<String, Object>{
            'BillingAddress'=> order.ChargentOrders__Billing_Address__c,
            'BillingCity'=> order.ChargentOrders__Billing_City__c,
            'BillingFirstName'=> order.ChargentOrders__Billing_First_Name__c,
            'BillingState'=> order.ChargentOrders__Billing_State__c,
            'BillingZipCode'=> order.ChargentOrders__Billing_Zip_Postal__c,
            'LastName'=> order.ChargentOrders__Billing_Last_Name__c,
            'Subtotal'=> 539.29,
            'Frequency'=> 'Monthly',
            'PaymentStartDate'=> order.ChargentOrders__Payment_Start_Date__c,
            'PaymentStatus'=> order.ChargentOrders__Payment_Status__c,
            'PaymentStop'=> 'Unending',
            'Tax'=> 0,
            'ChargeDate'=> '5',
            'Description'=> order.ChargentOrders__Description__c,
            'FirstMonthPayed'=> false,
            'Account'=> order.ChargentOrders__Account__c,
            'Id'=> order.Id
            };
            ordersList.add(orderMap);
        }
        inputMap.put('orders', ordersList);
                ChargentBase__Gateway__c  creditGateway = [SELECT Id FROM ChargentBase__Gateway__c  WHERE ChargentBase__Active__c  = true AND Name = 'Chargent Test Gateway' LIMIT 1];

        Map<String,Object> paymentInformation = new Map<String,Object>{
            'BLK_BankAccount'=> null,
            'BLK_UpdateCreditCard'=> new Map<String,Object>{
                'SLC_UpdateExpirationYear'=> '2028',
                'SLC_ExpirationMonth'=> '2',
                'TXT_CardNumber'=> '4242424242424242'
            },
            'TXT_FirstName'=> 'TestIvan',
            'TXT_LastName'=> '1',
            'TXT_UpdateBillingAddress_Street'=> '123 Meadow Lane',
            'TXT_UpdateBillingAddress_ZipCode'=> '67337',
            'TXT_UpdateBillingAddress_State'=> 'KA',
            'TXT_UpdateBillingAddress_City'=> 'Coffeyville'
        };
        inputMap.put('paymentInformation', paymentInformation);
        
        inputMap.put('creditCardGateway', (String)creditGateway.Id);
        
        inputMap.put('bankGateway', (String)creditGateway.Id);
        
        String setRecurring = null; 
        inputMap.put('setRecurring', setRecurring);
        
        Test.startTest();
        ARC_UpdatePaymentMethod.updatePaymentMethod(inputMap,outputMap,options);
        //ARC_UpdateChargentEncryptedFields.updateChargentEncryptedFields(list2);
        Test.stopTest();
    }

    @isTest
    static void testUpdatePaymentMethodBA() {
        List<vlocity_ins__GroupCensus__c> census = ARC_TestUtility.createTestCensus(2);
        List<Contract> contracts = ARC_TestUtility.createContracts(1);
        contracts[0].vlocity_ins__EnrollmentCensusId__c = census[0].Id;
        insert contracts;
        Test.setCreatedDate(contracts[0].Id, Datetime.newInstance(2020, 7, 1));
        List<ChargentOrders__ChargentOrder__c> chargents = ARC_TestUtility.createChargentOrders(4);
        chargents[0].ChargentOrders__Description__c = 'Recurring Monthly Order';
        chargents[0].ChargentOrders__Payment_Method__c = 'Credit Card';
        chargents[0].ARC_Contract__c = contracts[0].Id;
        insert chargents;
        List<RecordType> RT = [ SELECT Id FROM RecordType WHERE sObjectType='ChargentBase__Gateway__c' AND Name = 'Authorize.net' AND isActive=true ];
        ChargentBase__Gateway__c GW = new ChargentBase__Gateway__c();
        GW.name='Chargent Test Gateway';
        GW.recordtypeID = RT.get(0).Id;
        GW.ChargentBase__Active__c = true;
        GW.ChargentBase__Available_Payment_Methods__c = 'Credit Card';
        GW.ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card';
        insert GW;

        List<ChargentOrders__ChargentOrder__c> chargentOrders = [SELECT ARC_Contract__c,ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c,
            ChargentOrders__Account__c,ChargentOrders__Bank_Account_Last_4__c,ChargentOrders__Bank_Account_Name__c,
            ChargentOrders__Bank_Account_Type__c,ChargentOrders__Bank_Name__c,ChargentOrders__Billing_Address__c,
            ChargentOrders__Billing_City__c,ChargentOrders__Billing_Email__c,ChargentOrders__Billing_First_Name__c,
            ChargentOrders__Billing_Last_Name__c,ChargentOrders__Billing_State__c,ChargentOrders__Billing_Zip_Postal__c,
            ChargentOrders__Card_Last_4__c,ChargentOrders__Card_Month_Indicator__c,ChargentOrders__Card_Type__c,
            ChargentOrders__Card_Year_Indicator__c,ChargentOrders__Charge_Amount__c,ChargentOrders__Description__c,
            ChargentOrders__Gateway__c,ChargentOrders__Payment_Frequency__c,ChargentOrders__Payment_Method__c,
            ChargentOrders__Payment_Status__c,ChargentOrders__Payment_Stop__c,ChargentOrders__Subtotal__c,
            ChargentOrders__Tokenization__c, ARC_Contract__r.ARC_TotalPrice__c, ChargentOrders__Card_Number__c,ChargentOrders__Payment_Start_Date__c,
            ChargentOrders__Bank_Account_Number__c,ChargentOrders__Bank_Routing_Number__c,
            (SELECT Id, ChargentOrders__Response_Status__c 
            FROM ChargentOrders__Transactions__r 
            ORDER BY CreatedDate DESC LIMIT 1)  
			FROM ChargentOrders__ChargentOrder__c
        ];
        ChargentBase__Gateway__c  creditGateway = [SELECT Id FROM ChargentBase__Gateway__c  WHERE ChargentBase__Active__c  = true AND Name = 'Chargent Test Gateway' LIMIT 1];
        Map<String,Object> inputMap  = new Map<String,Object>();  
        Map<String,Object> outputMap  = new Map<String,Object>();
        Map<String,Object> options  = new Map<String,Object>();
        List<Map<String, Object>> ordersList = new List<Map<String, Object>>();
        for (ChargentOrders__ChargentOrder__c order : chargentOrders) {
            Map<String, Object> orderMap = new Map<String, Object>{
            'BillingAddress'=> order.ChargentOrders__Billing_Address__c,
            'BillingCity'=> order.ChargentOrders__Billing_City__c,
            'BillingFirstName'=> order.ChargentOrders__Billing_First_Name__c,
            'BillingState'=> order.ChargentOrders__Billing_State__c,
            'BillingZipCode'=> order.ChargentOrders__Billing_Zip_Postal__c,
            'LastName'=> order.ChargentOrders__Billing_Last_Name__c,
            'Subtotal'=> 539.29,
            'Frequency'=> 'Monthly',
            'PaymentStartDate'=> order.ChargentOrders__Payment_Start_Date__c,
            'PaymentStatus'=> order.ChargentOrders__Payment_Status__c,
            'PaymentStop'=> 'Unending',
            'Tax'=> 0,
            'ChargeDate'=> '5',
            'Description'=> order.ChargentOrders__Description__c,
            'FirstMonthPayed'=> false,
            'Account'=> order.ChargentOrders__Account__c,
            'Id'=> order.Id
            };
            ordersList.add(orderMap);
        }
        inputMap.put('orders', ordersList);
        
        Map<String,Object> paymentInformation = new Map<String,Object>{
            'BLK_BankAccount'=> new Map<String,Object>{
                'SLC_UpdateAccType'=> 'Checking',
                'TXT_UpdateBankName'=> '23231',
                'TXT_UpdateAccNumber'=> '23232',
                'TXT_UpdateRoutingNumber'=> '232322323'
            },
            'BLK_UpdateCreditCard'=> null,
            'TXT_FirstName'=> 'Test',
            'TXT_LastName'=> '1'
        };
        inputMap.put('paymentInformation', paymentInformation);
        
        inputMap.put('creditCardGateway', (String)creditGateway.Id);
        
        inputMap.put('bankGateway', (String)creditGateway.Id);
        
        String setRecurring = null; 
        inputMap.put('setRecurring', setRecurring);
        
        Test.startTest();
        ARC_UpdatePaymentMethod.updatePaymentMethod(inputMap,outputMap,options);
        //ARC_UpdateChargentEncryptedFields.updateChargentEncryptedFields(list2);
        Test.stopTest();
    }
    @isTest
    static void testUpdatePaymentMethodCCDocusign() {
        List<vlocity_ins__GroupCensus__c> census = ARC_TestUtility.createTestCensus(2);
        List<Contract> contracts = ARC_TestUtility.createContracts(1);
        contracts[0].vlocity_ins__EnrollmentCensusId__c = census[0].Id;
        insert contracts;
        Test.setCreatedDate(contracts[0].Id, Datetime.newInstance(2020, 7, 1));
        List<ChargentOrders__ChargentOrder__c> chargents = ARC_TestUtility.createChargentOrders(4);
        chargents[0].ChargentOrders__Description__c = 'Recurring Monthly Order';
        chargents[0].ChargentOrders__Payment_Method__c = 'Credit Card';
        chargents[0].ARC_Contract__c = contracts[0].Id;
        insert chargents;
        List<RecordType> RT = [ SELECT Id FROM RecordType WHERE sObjectType='ChargentBase__Gateway__c' AND Name = 'Authorize.net' AND isActive=true ];
        ChargentBase__Gateway__c GW = new ChargentBase__Gateway__c();
        GW.name='Chargent Test Gateway';
        GW.recordtypeID = RT.get(0).Id;
        GW.ChargentBase__Active__c = true;
        GW.ChargentBase__Available_Payment_Methods__c = 'Credit Card';
        GW.ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card';
        insert GW;

        Case caseRecord = new Case(
            Case_Type__c = 'Contribution',
            ARC_Reason__c = 'Method Change',
            ARC_LastDocuSignEnvelopeId__c = 'test-envelope-id',
            ARC_LastDocuSignEnvelopeStatus__c = 'Completed',
            Description = 'test-description',
            Subject = 'test-subject',
            ARC_PersonAccount__c = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount'].Id,
            ARC_UPMSelectedPayor__c = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount'].Id
        );
        insert caseRecord;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockCreditCardResponseGenerator());
        ARC_UpdatePaymentMethod.updatePaymentMethodDocusign(caseRecord.Id);
        //ARC_UpdateChargentEncryptedFields.updateChargentEncryptedFields(list2);
        Test.stopTest();
    }

    @isTest
    static void testUpdatePaymentMethodBADocusign() {
        List<vlocity_ins__GroupCensus__c> census = ARC_TestUtility.createTestCensus(2);
        List<Contract> contracts = ARC_TestUtility.createContracts(1);
        contracts[0].vlocity_ins__EnrollmentCensusId__c = census[0].Id;
        insert contracts;
        Test.setCreatedDate(contracts[0].Id, Datetime.newInstance(2020, 7, 1));
        List<ChargentOrders__ChargentOrder__c> chargents = ARC_TestUtility.createChargentOrders(4);
        chargents[0].ChargentOrders__Description__c = 'Recurring Monthly Order';
        chargents[0].ChargentOrders__Payment_Method__c = 'Credit Card';
        chargents[0].ARC_Contract__c = contracts[0].Id;
        insert chargents;
        List<RecordType> RT = [ SELECT Id FROM RecordType WHERE sObjectType='ChargentBase__Gateway__c' AND Name = 'Authorize.net' AND isActive=true ];
        ChargentBase__Gateway__c GW = new ChargentBase__Gateway__c();
        GW.name='Chargent Test Gateway';
        GW.recordtypeID = RT.get(0).Id;
        GW.ChargentBase__Active__c = true;
        GW.ChargentBase__Available_Payment_Methods__c = 'Credit Card';
        GW.ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card';
        insert GW;

                Case caseRecord = new Case(
            Case_Type__c = 'Contribution',
            ARC_Reason__c = 'Method Change',
            ARC_LastDocuSignEnvelopeId__c = 'test-envelope-id',
            ARC_LastDocuSignEnvelopeStatus__c = 'Completed',
            Description = 'test-description',
            Subject = 'test-subject',
            ARC_PersonAccount__c = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount'].Id,
            ARC_UPMSelectedPayor__c = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount'].Id
        );
        insert caseRecord;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockBankAccountResponseGenerator());
        ARC_UpdatePaymentMethod.updatePaymentMethodDocusign(caseRecord.Id);
        //ARC_UpdateChargentEncryptedFields.updateChargentEncryptedFields(list2);
        Test.stopTest();

    }

    @isTest
    static void testUpdateAccountData() {
        // Prepare input maps
        Map<String, Object> inputMap = new Map<String, Object>{
            'PersonAccountId' => [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount'].Id,
            'firstName' => 'John',
            'lastName' => 'Doe',
            'phone' => '1234567890',
            'email' => 'john.doe@example.com'
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Call the method
        Test.startTest();
        ARC_UpdatePaymentMethod.updateAccountData(inputMap, outputMap, options);
        Test.stopTest();
        
        // Assertions
        Account updatedAccount = [SELECT Id,FirstName, LastName, Phone, PersonEmail FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' LIMIT 1];
        System.assertEquals('John', updatedAccount.FirstName, 'FirstName should be John');
        System.assertEquals('Doe', updatedAccount.LastName, 'LastName should be Doe');
        System.assertEquals('john.doe@example.com', updatedAccount.PersonEmail, 'PersonEmail should be john.doe@example.com');
    }

    @isTest
    static void getCardTypeTest() {
        Test.startTest();
        //Visa
        ARC_UpdatePaymentMethod.getCardType(new Map<String,Object>{'cardNumber' => '4111111111111111'}, new Map<String,Object>{}, new Map<String,Object>{});
        //MasterCard
        ARC_UpdatePaymentMethod.getCardType(new Map<String,Object>{'cardNumber' => '5555555555554444'}, new Map<String,Object>{}, new Map<String,Object>{});
        //American Express
        ARC_UpdatePaymentMethod.getCardType(new Map<String,Object>{'cardNumber' => '378282246310005'}, new Map<String,Object>{}, new Map<String,Object>{});
        //Discover
        ARC_UpdatePaymentMethod.getCardType(new Map<String,Object>{'cardNumber' => '6011111111111117'}, new Map<String,Object>{}, new Map<String,Object>{});

        Test.stopTest();
    }
}