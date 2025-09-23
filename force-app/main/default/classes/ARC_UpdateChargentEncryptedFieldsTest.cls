@isTest
public with sharing class ARC_UpdateChargentEncryptedFieldsTest {

@TestSetup
static void makeData(){

    //Create Person Account
    Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
    List<Account> accList = new List<Account>();
    Integer counter = 0;
    for(Integer i=0; i<1;i++){
        Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount'+i, LastName ='Test');
        acc.BillingStreet = '123 Avenue';
        acc.BillingState = 'NY';
        acc.BillingCity = 'New York';
        acc.BillingPostalCode='12345';
        acc.PersonEmail='test@email.com'+counter;
        acc.ARC_IsPrimaryMember__c = true;
        acc.ARC_E123MemberIdFromPolicy__c = 'W123456789'+counter;
        accList.add(acc);
    }
    insert accList;

    List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(1);
    counter = 0;
    for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
        censusMember.vlocity_ins__ContactId__c = accList[counter].PersonContactId;
        censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
        counter++;
    }
    update censusMemberList;
    
    vlocity_ins__GroupCensus__c census =[ SELECT Id FROM vlocity_ins__GroupCensus__c LIMIT 1];
    //List<vlocity_ins__GroupCensus__c> census = ARC_TestUtility.createTestCensus(2);

    List<Contract> contracts = ARC_TestUtility.createContracts(1);
    contracts[0].vlocity_ins__EnrollmentCensusId__c = census.Id;
    //contracts[1].vlocity_ins__EnrollmentCensusId__c = census[1].Id;
    //contracts[2].vlocity_ins__EnrollmentCensusId__c = census[0].Id;
    //contracts[3].vlocity_ins__EnrollmentCensusId__c = census[1].Id;

    insert contracts;
    Test.setCreatedDate(contracts[0].Id, Datetime.newInstance(2020, 7, 1));
    //Test.setCreatedDate(contracts[1].Id, Datetime.newInstance(2020, 7, 1));
    //Test.setCreatedDate(contracts[2].Id, Datetime.now());
    //Test.setCreatedDate(contracts[3].Id, Datetime.now());

    List<ChargentOrders__ChargentOrder__c> chargents = ARC_TestUtility.createChargentOrders(4);
    chargents[0].ChargentOrders__Description__c = 'Recurring Monthly Order';
    chargents[0].ChargentOrders__Payment_Method__c = 'Credit Card';
    chargents[0].ARC_Contract__c = contracts[0].Id;

    //chargents[1].ChargentOrders__Description__c = 'Recurring Monthly Order';
    //chargents[1].ChargentOrders__Payment_Method__c = 'Bank Account';
    //chargents[1].ARC_Contract__c = contracts[1].Id;

	insert chargents;

    //contracts[2].ARC_RecurringMonthlyOrder__c = chargents[2].Id;
    //contracts[3].ARC_RecurringMonthlyOrder__c = chargents[3].Id;

    //update contracts;
    
    List<RecordType> RT = [ SELECT Id FROM RecordType WHERE sObjectType='ChargentBase__Gateway__c' AND Name = 'Authorize.net' AND isActive=true ];
    ChargentBase__Gateway__c GW = new ChargentBase__Gateway__c();
    GW.name='Chargent Test Gateway';
    GW.recordtypeID = RT.get(0).Id;
    GW.ChargentBase__Active__c = true;
    GW.ChargentBase__Available_Payment_Methods__c = 'Credit Card';
    GW.ChargentBase__Default_Payment_Method_for_PC__c = 'Credit Card';
    insert GW;
}

@IsTest
static void testCreditCardChargentUpdate(){

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
			FROM ChargentOrders__ChargentOrder__c];
    
    ChargentBase__Gateway__c  creditGateway = [SELECT Id FROM ChargentBase__Gateway__c  WHERE ChargentBase__Active__c  = true AND Name = 'Chargent Test Gateway' LIMIT 1];
    List<Contract> contracts = [SELECT Id,CreatedDate,vlocity_ins__EnrollmentCensusId__c FROM Contract];
	
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
        'BLK_BankAccount'=> null,
      'BLK_UpdateCreditCard'=> new Map<String,Object>{
        'SLC_UpdateExpirationYear'=> '2028',
        'SLC_ExpirationMonth'=> '2',
        'TXT_CardNumber'=> '4242424242424242',
        'TXT_UpdateFirstNameOnCard'=> 'TestIvan',
        'TXT_UpdateLastNameOnCard'=> '1',
        'TXT_UpdateBillingAddress_Street'=> '123 Meadow Lane',
        'TXT_UpdateBillingAddress_ZipCode'=> '67337',
        'TXT_UpdateBillingAddress_State'=> 'KA',
        'TXT_UpdateBillingAddress_City'=> 'Coffeyville'
      }
    };
    inputMap.put('paymentInformation', paymentInformation);
    
    inputMap.put('creditCardGateway', (String)creditGateway.Id);
    
    inputMap.put('bankGateway', (String)creditGateway.Id);
    
    String setRecurring = null; 
    inputMap.put('setRecurring', setRecurring);
    
    Test.startTest();
    ARC_UpdateChargentEncryptedFields.updateChargentEncryptedFields(inputMap,outputMap,options);
    //ARC_UpdateChargentEncryptedFields.updateChargentEncryptedFields(list2);
    Test.stopTest();
    
}

@IsTest
static void testBankCardChargentUpdate(){

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
			FROM ChargentOrders__ChargentOrder__c];
    
    ChargentBase__Gateway__c  creditGateway = [SELECT Id FROM ChargentBase__Gateway__c  WHERE ChargentBase__Active__c  = true AND Name = 'Chargent Test Gateway' LIMIT 1];
    List<Contract> contracts = [SELECT Id,CreatedDate,vlocity_ins__EnrollmentCensusId__c FROM Contract];
	
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
        'BLK_UpdateCreditCard'=> null,
      'BLK_BankAccount'=> new Map<String,Object>{
        'SLC_UpdateAccType'=> 'Checking',
        'TXT_UpdateBankName'=> '23231',
        'TXT_UpdateFirstNameOnAccount'=> 'asda',
        'TXT_UpdateLastNameOnAccount'=> 'ads',
        'TXT_UpdateAccNumber'=> '23232',
        'TXT_UpdateRoutingNumber'=> '232322323'
      }
    };
    inputMap.put('paymentInformation', paymentInformation);
    
    inputMap.put('creditCardGateway', (String)creditGateway.Id);
    
    inputMap.put('bankGateway', (String)creditGateway.Id);
    
    String setRecurring = null; 
    inputMap.put('setRecurring', setRecurring);
    
    Test.startTest();
    ARC_UpdateChargentEncryptedFields.updateChargentEncryptedFields(inputMap,outputMap,options);
    //ARC_UpdateChargentEncryptedFields.updateChargentEncryptedFields(list2);
    Test.stopTest();
    
}
    
    @IsTest
    static void testCreditCardCommUserChargentUpdate(){
    

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
                FROM ChargentOrders__ChargentOrder__c];
        
        ChargentBase__Gateway__c  creditGateway = [SELECT Id FROM ChargentBase__Gateway__c  WHERE ChargentBase__Active__c  = true AND Name = 'Chargent Test Gateway' LIMIT 1];
        List<Contract> contracts = [SELECT Id,CreatedDate,vlocity_ins__EnrollmentCensusId__c FROM Contract];
        
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
            'BLK_BankAccount'=> null,
        'BLK_UpdateCreditCard'=> new Map<String,Object>{
            'SLC_UpdateExpirationYear'=> '2028',
            'SLC_ExpirationMonth'=> '2',
            'TXT_CardNumber'=> '4242424242424242',
            'TXT_UpdateFirstNameOnCard'=> 'TestIvan',
            'TXT_UpdateLastNameOnCard'=> '1',
            'TXT_UpdateBillingAddress_Street'=> '123 Meadow Lane',
            'TXT_UpdateBillingAddress_ZipCode'=> '67337',
            'TXT_UpdateBillingAddress_State'=> 'KA',
            'TXT_UpdateBillingAddress_City'=> 'Coffeyville'
        }
        };
        inputMap.put('paymentInformation', paymentInformation);
        
        inputMap.put('creditCardGateway', (String)creditGateway.Id);
        
        inputMap.put('bankGateway', (String)creditGateway.Id);
        
        String setRecurring = null; 
        inputMap.put('setRecurring', setRecurring);
        
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1];

        
        List<Account> acc = ARC_TestUtility.createTestAccount(1,'ARC_IFPPersonAccount');
        acc[0].PersonBirthdate = Date.newInstance(1997, 11, 1); 
        acc[0].ARC_IsPrimaryMember__c = true;
        acc[0].IsActive = true;
        acc[0].vlocity_ins__Email__c = 'testEmail@email.com';
        update acc;
        
        Contact cont = [Select Id, Email From Contact WHERE AccountId =: acc[0].Id];

        List<Case> methodUpdateCase = ARC_TestUtility.createTestCase(1,'Service');
        methodUpdateCase[0].Status = 'New';
        methodUpdateCase[0].Case_Type__c = 'Contribution';
        methodUpdateCase[0].ARC_Reason__c = 'First Month Decline';
        methodUpdateCase[0].ARC_PersonAccount__c = acc[0].Id;
        update methodUpdateCase;


        User usr = new User(
                    LastName = 'lastName',
                    FirstName = 'firstName',
                    Alias = 'alias',
                    Email = 'email@aa.com',
                    Username = 'testUS@uhsm.com',
                    Phone = '13213131',
                    City = 'city',
                    Street = 'street',
                    State = 'TX',
                    PostalCode = 'zipCode',
                    CommunityNickname = 'nickName',
                    ContactId = cont.Id,
                    ProfileId = profile.Id,
                    TimeZoneSidKey = 'America/New_York',
                    LanguageLocaleKey = 'en_US',
                    EmailEncodingKey = 'ISO-8859-1',
                    LocaleSidKey = 'en_US',
                    ARC_PortalUsername__c = 'test@uhsm.com'
                );  
        insert usr;
        
        Test.startTest();
        system.RunAs(usr){
            ARC_UpdateChargentEncryptedFields.updateChargentEncryptedFields(inputMap,outputMap,options);
        }
        Test.stopTest();
        List<Case> methodUpdated = [SELECT Id, Status FROM Case WHERE Id =:methodUpdateCase[0].Id];  
        Assert.areEqual('In Progress', methodUpdated[0].Status);  
    }
}