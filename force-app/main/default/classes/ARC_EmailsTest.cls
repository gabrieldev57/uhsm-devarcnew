/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-23-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
global without sharing class ARC_EmailsTest {
    @TestSetup
    public static void makeData(){
           
        List<Contact> contact = ARC_TestUtility.createTestContact(1,'IndustriesIndividual');
        contact[0].Email = 'testEmail@uhsm.com';
        update contact;
     
        List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(1);
        censMemb[0].ARC_PhysicalAddressState__c = 'CA';
        censMemb[0].vlocity_ins__IsPrimaryMember__c = true;
        censMemb[0].ARC_ActiveMember__c = true;
        censMemb[0].vlocity_ins__ContactId__c = contact[0].Id; 
        censMemb[0].vlocity_ins__FirstName__c = 'TestFirstName';
        censMemb[0].vlocity_ins__Birthdate__c = Date.newInstance(1997, 11, 1);
        censMemb[0].e123_member_id_from_policy__c = 'asd123';
        censMemb[0].vlocity_ins__Email__c = 'test@test.com';

        update censMemb;
        
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account personAcc = new Account(RecordTypeId = accRecordTypeId,
                                    FirstName = 'PersonAccount', 
                                    LastName ='Test', 
                                    Census_Member__c =censMemb[0].Id,
                                    ARC_CensusMember__pc = censMemb[0].Id,
                                    ARC_Census__c = censMemb[0].vlocity_ins__CensusId__c,
                                    PersonEmail = 'test@test.com');
                                    
        insert personAcc;

        vlocity_ins__GroupCensus__c census = [SELECT Id,ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c WHERE Id = :censMemb[0].vlocity_ins__CensusId__c];
        // census.Id = censMemb[0].vlocity_ins__CensusId__c;
        census.ARC_PrimaryAccount__c = personAcc.Id;

        update census;

        List<Contract> contract = ARC_TestUtility.createContracts(1);
        contract[0].vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c;
        contract[0].ARC_EffectiveDate__c = System.today();

        insert contract;
        
        List<ChargentOrders__ChargentOrder__c> chargentOrdersList = new List<ChargentOrders__ChargentOrder__c>();

        ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c();
        chargent.ARC_Contract__c = contract[0].Id;
        chargent.ChargentOrders__Shipping__c = 232;
        chargent.ChargentOrders__Tax__c  = 232;
        chargent.ChargentOrders__Charge_Amount__c = 232;
        chargent.ChargentOrders__Subtotal__c  = 232;
        chargent.ChargentOrders__Charge_Date__c =  '01';
        chargent.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
        chargent.ChargentOrders__Payment_Status__c = 'Recurring';
        chargent.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
        chargent.ChargentOrders__Payment_Method__c = 'Credit Card';
        chargent.ChargentOrders__Card_Last_4__c = '1234';
        chargent.ChargentOrders__Card_Type__c = 'VISA';
        chargent.ChargentOrders__Card_Expiration_Month__c = '12';
        chargent.ChargentOrders__Card_Expiration_Year__c = '2024';
        chargent.ChargentOrders__Tokenization__c = '12345678';
        chargent.ChargentOrders__Description__c = 'Recurring Monthly Order';

        ChargentOrders__ChargentOrder__c chargent_BankAccount = new ChargentOrders__ChargentOrder__c();
        chargent_BankAccount.ARC_Contract__c = contract[0].Id;
        chargent_BankAccount.ChargentOrders__Shipping__c = 232;
        chargent_BankAccount.ChargentOrders__Tax__c  = 232;
        chargent_BankAccount.ChargentOrders__Charge_Amount__c = 232;
        chargent_BankAccount.ChargentOrders__Subtotal__c  = 232;
        chargent_BankAccount.ChargentOrders__Charge_Date__c =  '01';
        chargent_BankAccount.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
        chargent_BankAccount.ChargentOrders__Payment_Status__c = 'Complete';
        chargent_BankAccount.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
        chargent_BankAccount.ChargentOrders__Payment_Method__c = 'Bank Account';
        chargent_BankAccount.ChargentOrders__Bank_Account_Last_4__c = '1234';
        chargent_BankAccount.ChargentOrders__Card_Type__c = 'VISA';
        chargent_BankAccount.ChargentOrders__Card_Expiration_Month__c = '12';
        chargent_BankAccount.ChargentOrders__Card_Expiration_Year__c = '2024';
        chargent_BankAccount.ChargentOrders__Tokenization__c = '123123123';
        chargent_BankAccount.ChargentOrders__Description__c = 'One-Time Fee';

        chargentOrdersList.add(chargent);
        chargentOrdersList.add(chargent_BankAccount);

        insert chargentOrdersList;

        contract[0].ARC_RecurringMonthlyOrder__c = chargent.Id;
        contract[0].Status = 'Activated';

        update contract;

        Product2 product1 = new Product2();
        product1.Name = 'Parent Product';
        product1.ProductCode = 'CS_FinanceVisitsFramework';
        product1.vlocity_ins__Type__c = 'Medical';
        product1.vlocity_ins__SubType__c = 'AIDD';

        Product2 product2 = new Product2();
        product2.Name = 'Parent Product';
        product2.ProductCode = 'CS_FinanceVisitsFramework';
        product2.vlocity_ins__Type__c = 'Ancillary';
        product2.vlocity_ins__SubType__c = 'AIDD';

        List<Product2> products = new List<Product2>{product1,product2};

        insert products;
        
        vlocity_ins__ContractLineItem__c cli1 =ARC_TestUtility.createTestContractLineItem(1)[0];
        cli1.vlocity_ins__ContractId__c= contract[0].Id;
        cli1.vlocity_ins__Product2Id__c = product1.Id;
        cli1.ARC_SmokerFee__c = 50;
        cli1.ARC_ExtraDependentFee__c = 50;
        cli1.ARC_OriginalPrice__c = 100;
        cli1.vlocity_ins__Quantity__c  = 10;
        cli1.vlocity_ins__UnitPrice__c  = 70;

        vlocity_ins__ContractLineItem__c cli2 =ARC_TestUtility.createTestContractLineItem(1)[0];
        cli2.vlocity_ins__ContractId__c= contract[0].Id;
        cli2.vlocity_ins__Product2Id__c = product1.Id;
        cli2.ARC_SmokerFee__c = 50;
        cli2.ARC_ExtraDependentFee__c = 50;
        cli2.ARC_OriginalPrice__c = 100;
        cli2.vlocity_ins__Quantity__c  = 10;
        cli2.vlocity_ins__UnitPrice__c  = 70;

        List<vlocity_ins__ContractLineItem__c> clis = new List<vlocity_ins__ContractLineItem__c>{cli1,cli2};
        update clis;
            
        vlocity_ins__GroupCensusMemberPlan__c gcmp1 = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmp1.vlocity_ins__GroupCensusMemberId__c = censMemb[0].Id;
        gcmp1.vlocity_ins__ContractLineId__c = cli1.Id;

        vlocity_ins__GroupCensusMemberPlan__c gcmp2 = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmp2.vlocity_ins__GroupCensusMemberId__c = censMemb[0].Id;
        gcmp2.vlocity_ins__ContractLineId__c = cli2.Id;

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmps = new List<vlocity_ins__GroupCensusMemberPlan__c>{gcmp1,gcmp2};
        insert gcmps;

        List<ChargentOrders__Transaction__c> transactionsList = new List<ChargentOrders__Transaction__c>();
        ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = chargent.Id,
                Census__c = censMemb[0].vlocity_ins__CensusId__c ,
                ChargentOrders__Response_Status__c = 'Approved',
                ChargentOrders__Amount__c = 222,ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Gateway_Date__c = Date.newInstance(2022, 07, 02),
                ChargentOrders__Tokenization__c = '12345678'
            );
        
        ChargentOrders__Transaction__c transa_BankAccount = new ChargentOrders__Transaction__c(
                ChargentOrders__Order__c = chargent_BankAccount.Id,
                Census__c = censMemb[0].vlocity_ins__CensusId__c ,
                ChargentOrders__Response_Status__c = 'Approved',
                ChargentOrders__Amount__c = 222,ChargentOrders__Type__c = 'Charge',
                ChargentOrders__Gateway_Date__c = Date.newInstance(2022, 07, 02),
                ChargentOrders__Tokenization__c = '123123123'
            );    
        transactionsList.add(transa);
        transactionsList.add(transa_BankAccount);
        insert transactionsList;

        Id healthyDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();
         
        Id healthylDiscountCodeRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Healthy_Discount').getRecordTypeId();

        List<ARC_PromotionCode__c> promoCodes = new List<ARC_PromotionCode__c>();
        ARC_PromotionCode__c promoCode = new ARC_PromotionCode__c(
            Name = 'Healthy Discount',
            ARC_DiscountRate__c = 10,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = healthylDiscountCodeRecordTypeId,
            ARC_PromotionCode__c = 'Healthy Discount', 
            ARC_StartDate__c= Date.today()
        );
        promoCodes.add(promoCode);

        insert promoCodes;

        Date dateToday = Date.today(); 
        ARC_PromotionDiscount__c discountExpire90 = new ARC_PromotionDiscount__c(
                Name = 'Healthy Discount',
                ARC_StartDate__c = dateToday,
                ARC_Description__c = 'Testing', 
                ARC_EndDate__c = dateToday.addDays(90),
                ARC_Contract__c = contract[0].Id,
                ARC_PromoCode__c = promoCodes[0].Id,
                ARC_ApplyFirst__c = true,
                ARC_Status__c = 'Pending',
                ARC_DiscountRate__c = 10,
                ARC_PriceWithoutDiscount__c = 7.9,
                ARC_NumberOfTimesCanBeUsed__c = 0,
                ARC_PriceWithDiscount__c = 6.9,
                ARC_DiscountedAmount__c = 0,
                ARC_ApplyOver__c = 'Medical',
                RecordTypeId = healthyDiscountRecordTypeId
            );

        insert discountExpire90;

        ARC_PromotionDiscount__c discountExpire30 = new ARC_PromotionDiscount__c(
                Name = 'Healthy Discount',
                ARC_StartDate__c = dateToday,
                ARC_Description__c = 'Testing', 
                ARC_EndDate__c = dateToday.addDays(30),
                ARC_Contract__c = contract[0].Id,
                ARC_PromoCode__c = promoCodes[0].Id,
                ARC_ApplyFirst__c = true,
                ARC_Status__c = 'Pending',
                ARC_DiscountRate__c = 10,
                ARC_PriceWithoutDiscount__c = 7.9,
                ARC_NumberOfTimesCanBeUsed__c = 0,
                ARC_PriceWithDiscount__c = 6.9,
                ARC_DiscountedAmount__c = 0,
                ARC_ApplyOver__c = 'Medical',
                RecordTypeId = healthyDiscountRecordTypeId
            );

        insert discountExpire30;

    } 

    //Normal flow
    @isTest
    public static void handleEmailTest1() {
        Test.startTest();
        List<Account> personAcc = [SELECT Id, PersonEmail FROM Account LIMIT 1];
        System.debug(personAcc);
        Map<String,Object> email = new Map<String,Object>{
            'emailSubject'=>'Test Subject',
            'emailAddress'=> personAcc[0].PersonEmail ,
            'templateHtml'=> '<p>Hello World! This is a test email</p>',
            'recipientId'=> personAcc[0].Id,
            'templateHtml'=> '1'
        };
        
        Map<String, Object> inputMap = new Map <String,Object>{'emailListToSend'=> new List<Object>{email},
                                                               'recordId'=> personAcc[0].Id};
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Integer beforeInvocations = Limits.getEmailInvocations();
        ARC_Emails.invokeMethod('handleEmail', inputMap, outMap, options);
        Integer afterInvocations = Limits.getEmailInvocations();
        Test.stopTest();
    }

	@isTest
    public static void email_4() {
        
        List<ChargentOrders__Transaction__c> trans = [
            SELECT Id,
            ChargentOrders__Tokenization__c,
            ChargentOrders__Order__r.ChargentOrders__Charge_Amount__c,
            ChargentOrders__Amount__c
            FROM ChargentOrders__Transaction__c];

		List<Contract> cont = [
			SELECT Id,vlocity_ins__EnrollmentCensusId__c,Status,ARC_RecurringMonthlyOrder__r.ChargentOrders__Tokenization__c
			FROM Contract
			LIMIT 1
		];

		List<vlocity_ins__GroupCensusMember__c> censMemb = [
			SELECT Id,
            vlocity_ins__FirstName__c,
            vlocity_ins__ContactId__r.Email,
            e123_member_id_from_policy__c,
            Member_ID__c
			FROM vlocity_ins__GroupCensusMember__c
			LIMIT 1
		];

        Map<String, Object> inputMap = new Map<String, Object>{
            trans[0].Id => new Map<String,Object>{
                'censusMember'=> censMemb[0],
                'transaction'=> trans[0]
            }
        };

        Integer afterInvocations;

        test.startTest();
        ARC_Emails.invokeMethod('email_4', inputMap, new Map<String, Object>(), new Map<String, Object>());
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }

    @isTest
    public static void email_5() {
        
        vlocity_ins__GroupCensusMember__c censusMember = [
            SELECT Id,vlocity_ins__FirstName__c,vlocity_ins__ContactId__r.Email,vlocity_ins__CensusId__c
            FROM vlocity_ins__GroupCensusMember__c
            LIMIT 1];

		Contract cont = [SELECT Id FROM Contract LIMIT 1];

		ChargentOrders__ChargentOrder__c chargent = [
            SELECT Id,ChargentOrders__Next_Transaction_Date__c,ChargentOrders__Total__c
            FROM ChargentOrders__ChargentOrder__c
            LIMIT 1];

        List<Map<String,Object>> emailsInformation = new List<Map<String,Object>>();
        Map<String, Object> emailInformation = new Map<String, Object>();
        emailInformation.put('censusMember', censusMember);
        emailInformation.put('chargent', chargent);
        emailsInformation.add(emailInformation);
        
        Test.startTest();
        ARC_Emails.email_5(emailsInformation);
        Integer afterInvocations = Limits.getEmailInvocations();
        Test.stopTest();
    }

	@isTest
    public static void email_6() {

        List<ChargentOrders__Transaction__c> trans = [
            SELECT Id,ChargentOrders__Tokenization__c
            FROM ChargentOrders__Transaction__c];

		List<Contract> cont = [
			SELECT Id,vlocity_ins__EnrollmentCensusId__c,Status,ARC_RecurringMonthlyOrder__r.ChargentOrders__Tokenization__c
			FROM Contract
			LIMIT 1
		];

		List<vlocity_ins__GroupCensusMember__c> censMemb = [
			SELECT Id,
            (SELECT Id, Name, vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c, vlocity_ins__ContractLineId__r.Name, vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c
             FROM vlocity_ins__GroupCensusMemberPlan__r),
            vlocity_ins__FirstName__c,
            vlocity_ins__ContactId__r.Email,
            e123_member_id_from_policy__c,
            Member_ID__c
			FROM vlocity_ins__GroupCensusMember__c
			LIMIT 1
		];

        Map<String, Object> inputMap = new Map<String, Object>{
            trans[0].Id => new Map<String,Object>{
                'censusMember'=> censMemb[0],
                'transaction'=> trans[0]
            },
            trans[1].Id => new Map<String,Object>{
                'censusMember'=> censMemb[0],
                'transaction'=> trans[1]
            }
        };

        Integer afterInvocations;

        test.startTest();
        ARC_Emails.invokeMethod('email_6', inputMap, new Map<String, Object>(), new Map<String, Object>());
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }

	@isTest
	public static void email_7() {

		List<Contract> cont = [
			SELECT Id,vlocity_ins__EnrollmentCensusId__c,Status,ARC_RecurringMonthlyOrder__r.ChargentOrders__Tokenization__c
			FROM Contract
			LIMIT 1
		];

		List<vlocity_ins__GroupCensusMember__c> censMembList = [
			SELECT 
			Id,
			vlocity_ins__FirstName__c,
			vlocity_ins__ContactId__r.Email,
			vlocity_ins__CensusId__c
			FROM vlocity_ins__GroupCensusMember__c
			LIMIT 1
		];

		Set<Id> censusMemberIds = new Set<Id>();
		for (vlocity_ins__GroupCensusMember__c cm : censMembList) {
			censusMemberIds.add(cm.Id);
		}
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_7'; 
        
        inputMap.put('censusMemberIds', censusMemberIds);

        Integer afterInvocations;
        test.startTest();
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }

    @isTest
    public static void email_9() {
        
        List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id,Member_ID__c,vlocity_ins__ContactId__r.Email,vlocity_ins__FirstName__c,e123_member_id_from_policy__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
	    Contract cont = [SELECT Id FROM Contract LIMIT 1];
	    ChargentOrders__ChargentOrder__c chargent = [SELECT Id,ChargentOrders__Payment_Method__c,ChargentOrders__Card_Last_4__c,ChargentOrders__Card_Type__c,ChargentOrders__Card_Month_Indicator__c,ChargentOrders__Card_Year_Indicator__c FROM ChargentOrders__ChargentOrder__c LIMIT 1];
		List<Map<String,Object>> emailList = new List<Map<String,Object>>();
        Map<String, Object> emailInfo = new Map<String, Object>{'chargentOrder'=> chargent,'censusMember'=> censMembList[0]};
        emailList.add(emailInfo);
        Integer afterInvocations;
        test.startTest();
        Map<String, Object> inputMap = new Map <String,Object> ();
        inputMap.put('emails', emailList);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_9'; 
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }

    @isTest
    public static void email_11() {
	    Contract cont = [SELECT Id, vlocity_ins__EnrollmentCensusId__c 
                        FROM Contract LIMIT 1];

        List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id, 
                                                                    vlocity_ins__FirstName__c,
                                                                    vlocity_ins__ContactId__r.Email,
                                                                    vlocity_ins__IsPrimaryMember__c,
                                                                    vlocity_ins__IsSpouse__c,
                                                                    ARC_Relationship__c,
                                                                    (SELECT Name
                                                                    FROM vlocity_ins__GroupCensusMemberPlan__r
                                                                    WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
                                                                    AND vlocity_ins__ContractLineId__r.vlocity_ins__ParentItemId__c = NULL
                                                                    ORDER BY CreatedDate ASC
                                                                    LIMIT 1)
                                                                FROM vlocity_ins__GroupCensusMember__c];
        censMembList[0].vlocity_ins__IsPrimaryMember__c = true;
        // censMembList[0].ARC_Relationship__c = 'Primary';
        update censMembList;

        // List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
	    ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_11'; 
        
        List<Id> censMembsId = new List<Id>();
        
        for(vlocity_ins__GroupCensusMember__c censusMember: censMembList){
            censMembsId.add(censusMember.Id);
		}
        
        inputMap.put('censusMemberIds', censMembsId);
        inputMap.put('contractId', new List<Id>{cont.Id});

        Integer afterInvocations;
        test.startTest();
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }

    @isTest
    public static void email_12() {
        List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id,Name,Member_ID__c,vlocity_ins__ContactId__r.Email,vlocity_ins__FirstName__c,vlocity_ins__CensusId__c,vlocity_ins__Birthdate__c,ARC_PhysicalAddressState__c,vlocity_ins__RelatedCensusMemberId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
	    Contract cont = [SELECT Id FROM Contract LIMIT 1];
	    ChargentOrders__ChargentOrder__c chargent = [SELECT Id,ChargentOrders__Payment_Method__c,ChargentOrders__Card_Last_4__c,ChargentOrders__Card_Type__c,ChargentOrders__Card_Month_Indicator__c,ChargentOrders__Card_Year_Indicator__c FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_12'; 
        
        List<Id> censMembsId = new List<Id>();
        
        for(vlocity_ins__GroupCensusMember__c censusMember: censMembList){
            censMembsId.add(censusMember.Id);
		}

        Test.startTest();
        ARC_Emails.invokeMethod('email_12', new Map<String,Object>{'censusMember'=>censMembList[0]}, new Map<String,Object>(), new Map<String,Object>());

        censMembList[0].ARC_PhysicalAddressState__c = 'NY';
        update censMembList;

        ARC_Emails.invokeMethod('email_12', new Map<String,Object>{'censusMember'=>censMembList[0]}, new Map<String,Object>(), new Map<String,Object>());
        Test.stopTest();
    }
    @isTest
    public static void email_13() {
        List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];

	    Contract cont = [SELECT Id FROM Contract LIMIT 1];
	    ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        List<Id> censMembsId = new List<Id>();
        
        for(vlocity_ins__GroupCensusMember__c censusMember: censMembList){
            censMembsId.add(censusMember.Id);
		}
        
        Test.startTest();
        censMembList[0].ARC_PhysicalAddressState__c = 'NY';
        update censMembList;

        ARC_Emails.invokeMethod('email_13', new Map<String,Object>{'censusMemberIds'=>censMembsId}, new Map<String,Object>(), new Map<String,Object>());


        Test.stopTest();
    }
    @isTest
    public static void email_14() {
        List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
	    Contract cont = [SELECT Id FROM Contract LIMIT 1];
	    ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_14'; 
        
        List<Id> censMembsId = new List<Id>();
        
        for(vlocity_ins__GroupCensusMember__c censusMember: censMembList){
            censMembsId.add(censusMember.Id);
		}
        
        inputMap.put('censusMemberIds', censMembsId);

         Integer afterInvocations;
        test.startTest();
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }

	@isTest
    public static void email_21() {

        List<ChargentOrders__Transaction__c> trans = [
            SELECT Id,ChargentOrders__Tokenization__c
            FROM ChargentOrders__Transaction__c];

		List<Contract> cont = [
			SELECT Id,vlocity_ins__EnrollmentCensusId__c,Status,ARC_RecurringMonthlyOrder__r.ChargentOrders__Tokenization__c
			FROM Contract
			LIMIT 1
		];
		List<vlocity_ins__GroupCensusMember__c> censMemb = [
			SELECT Id,
            vlocity_ins__FirstName__c,
            vlocity_ins__ContactId__r.Email,
            e123_member_id_from_policy__c,
            Member_ID__c
			FROM vlocity_ins__GroupCensusMember__c
			LIMIT 1
		];

        Document testDocument = new Document(
            Name = 'EFTForm', 
            FolderId = UserInfo.getUserId()
        );
        insert testDocument;

        Map<String, Object> inputMap = new Map<String, Object>{
            trans[0].Id => new Map<String,Object>{
                'censusMember'=> censMemb[0],
                'transaction'=> trans[0]
            },
            'email' => censMemb[0].vlocity_ins__ContactId__r.Email
        };

        Integer afterInvocations;

        test.startTest();
        ARC_Emails.invokeMethod('email_21', inputMap, new Map<String, Object>(), new Map<String, Object>());
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }

    @isTest
    public static void email_22() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_22';

        List<Account> listFamAcc = new List<Account>();
        for (Integer i = 0; i < 1; i++) {
            Account acc = new Account(Name = 'FamilyAccount Test '+i);
            listFamAcc.add(acc);
        }
        insert listFamAcc;

        //PersonAccount creation
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> listPerAcc = new List<Account>();
        for (Integer i = 0; i < 1; i++) {
            Account accPrimary = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount Primary '+i, LastName ='Test');
            accPrimary.BillingStreet = '123 Avenue';
            accPrimary.BillingState = 'NY';
            accPrimary.BillingCity = 'New York';
            accPrimary.BillingPostalCode='12345';
            accPrimary.PersonEmail='test@email.com';
            accPrimary.PersonBirthdate=Date.Today().addYears(-65).addDays(60);
            accPrimary.ARC_IsPrimaryMember__c = true;
            accPrimary.ARC_E123MemberIdFromPolicy__c = 'W123456789';
            accPrimary.ARC_ContinuousMembershipStartDate__c = Date.Today().addYears(-1);
            accPrimary.IsActive = true;
            accPrimary.ARC_GroupAccount__c = listFamAcc[i].Id;
            listPerAcc.add(accPrimary);
        }
        insert listPerAcc;

        //CensusMember creation
        List <vlocity_ins__GroupCensusMember__c> groupCensusMemberList = new List<vlocity_ins__GroupCensusMember__c>();
        List <vlocity_ins__GroupCensus__c> groupCensusList = new List<vlocity_ins__GroupCensus__c>();
        for (Integer i = 0; i < 1; i++) {
            vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
            census.Name = 'census test '+i;
            census.vlocity_ins__GroupId__c = listFamAcc[i].Id;
            census.ARC_PrimaryAccount__c = listPerAcc[i].Id;
            groupCensusList.add(census);
        }
        insert groupCensusList;
        
        List <Account> accountListContactIdsPrimary = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount Primary%' ORDER BY FirstName];
        for (Integer i = 0; i < 1; i++) {
            vlocity_ins__GroupCensusMember__c censusMemberPrimary = new vlocity_ins__GroupCensusMember__c();
            censusMemberPrimary.Name = 'Test Census Member Primary ' + i;
            censusMemberPrimary.vlocity_ins__FirstName__c = 'Test';
            censusMemberPrimary.vlocity_ins__LastName__c = 'Census Member Primary ' + i;
            censusMemberPrimary.vlocity_ins__CensusId__c = groupCensusList[i].Id;
            censusMemberPrimary.vlocity_ins__ContactId__c = accountListContactIdsPrimary[i].PersonContactId;
            censusMemberPrimary.vlocity_ins__SocialSecurityNumber__c = '123456789';
            censusMemberPrimary.ARC_PhysicalAddressState__c = 'NY';
            groupCensusMemberList.add(censusMemberPrimary);
        }
        insert groupCensusMemberList;
        
        //Link PersonAccounts to CensusMember
        for (Integer i = 0; i < 1; i++) {
            listPerAcc[i].Census_Member__c = groupCensusMemberList[i].Id;
            listPerAcc[i].ARC_CensusMember__pc = groupCensusMemberList[i].Id;
            listPerAcc[i].ARC_Census__c = groupCensusMemberList[i].vlocity_ins__CensusId__c;
        }
        update listPerAcc;

        //ChargentOrder creation
        List<ChargentOrders__ChargentOrder__c> ordList = new List<ChargentOrders__ChargentOrder__c>();
        for (Integer i = 0; i < 1; i++) {
            ChargentOrders__ChargentOrder__c ord = new ChargentOrders__ChargentOrder__c();
            ord.ARC_FirstMonthPayed__c = true;
            ord.ChargentOrders__Description__c = 'Recurring Monthly Order';
            ord.ChargentOrders__Charge_Amount__c = 10;
            ordList.add(ord);
            ChargentOrders__ChargentOrder__c ordAppFee = new ChargentOrders__ChargentOrder__c();
            ordAppFee.ARC_FirstMonthPayed__c = true;
            ordAppFee.ChargentOrders__Description__c = 'App Fee';
            ordAppFee.ChargentOrders__Subtotal__c = 10;
            ordList.add(ordAppFee);
        }
        insert ordList;

        //Contracts creation
        List<Contract> contractList = new List<Contract>();
        for (Integer i = 0; i < 1; i++) {
            Contract con = new Contract();
            con.ContractTerm = 12;
            con.ARC_Selling_Agent__c = UserInfo.getUserId();
            con.AccountId = listFamAcc[i].Id;
            con.StartDate = Date.today();
            con.ARC_RecurringMonthlyOrder__c = ordList[i].Id;
            con.ARC_AppFeeOrder__c = ordList[i+1].Id;
            con.vlocity_ins__EnrollmentCensusId__c = groupCensusList[i].Id;
            contractList.add(con);
        }
        insert contractList;

        //ContractParticipant creation
        List<ARC_ContractParticipant__c> contractParticipantList = new List<ARC_ContractParticipant__c>();
        for (Integer i = 0; i < 1; i++) {
            ARC_ContractParticipant__c contractParticipantPrimary = new ARC_ContractParticipant__c();
            contractParticipantPrimary.ARC_Contract__c = contractList[i].Id;
            contractParticipantPrimary.ARC_PersonAccount__c = listPerAcc[i].Id;
            contractParticipantList.add(contractParticipantPrimary);
        }
        insert contractParticipantList;

        Ages_Up__c agesuprecord = new Ages_Up__c(
            Contract__c = contractList[0].Id,
            AgesUp_Birth_Date__c = Date.today()+60,
            ARC_EffectiveDate__c = Date.today()+60,
            Draft_Date__c = Date.today(),
            ARC_Account__c = listPerAcc[0].Id
        );
        insert agesuprecord;

        List<Account> accountList = [SELECT Id, FirstName, PersonBirthdate, ARC_IsPrimaryMember__c, ARC_Census__r.ARC_PrimaryAccount__r.FirstName, ARC_Census__r.ARC_PrimaryAccount__r.PersonEmail, 
                (SELECT Id, ARC_PriceBeforeAgeUp__c, ARC_PriceAfterAgeUp__c, ARC_EffectiveDate__c, ARC_ManualDelay__c,Contract__c, Name, Contract__r.ARC_EffectiveDate__c, ARC_Account__c, ARC_ReviewAgeUpPrice__c 
                FROM Age_Up__r WHERE Id = :agesuprecord.Id) 
            FROM Account WHERE Id = :listPerAcc[0].Id];
        inputMap.put(accountList[0].Id, accountList[0]);

        Test.startTest();
        // 60 days missing
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        // 30 days missing
        agesuprecord.AgesUp_Birth_Date__c = Date.today()+30;
        agesuprecord.ARC_EffectiveDate__c = Date.today()+30;
        update agesuprecord;
        accountList = [SELECT Id, FirstName, PersonBirthdate, ARC_IsPrimaryMember__c, ARC_Census__r.ARC_PrimaryAccount__r.FirstName, ARC_Census__r.ARC_PrimaryAccount__r.PersonEmail, 
                (SELECT Id, ARC_PriceBeforeAgeUp__c, ARC_PriceAfterAgeUp__c, ARC_EffectiveDate__c, ARC_ManualDelay__c,Contract__c, Name, Contract__r.ARC_EffectiveDate__c, ARC_Account__c, ARC_ReviewAgeUpPrice__c 
                FROM Age_Up__r WHERE Id = :agesuprecord.Id) 
            FROM Account WHERE Id = :listPerAcc[0].Id];
        inputMap.put(accountList[0].Id, accountList[0]);
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        // 14 days missing
        agesuprecord.AgesUp_Birth_Date__c = Date.today()+14;
        agesuprecord.ARC_EffectiveDate__c = Date.today()+14;
        update agesuprecord;
        accountList = [SELECT Id, FirstName, PersonBirthdate, ARC_IsPrimaryMember__c, ARC_Census__r.ARC_PrimaryAccount__r.FirstName, ARC_Census__r.ARC_PrimaryAccount__r.PersonEmail, 
                (SELECT Id, ARC_PriceBeforeAgeUp__c, ARC_PriceAfterAgeUp__c, ARC_EffectiveDate__c, ARC_ManualDelay__c,Contract__c, Name, Contract__r.ARC_EffectiveDate__c, ARC_Account__c, ARC_ReviewAgeUpPrice__c 
                FROM Age_Up__r WHERE Id = :agesuprecord.Id) 
            FROM Account WHERE Id = :listPerAcc[0].Id];
        inputMap.put(accountList[0].Id, accountList[0]);
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        Test.stopTest();
    }

    @isTest
    public static void email_23() {

        Map<String, Object> inputMap = new Map<String, Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_23';

        Date dateToday = date.today();

         Account personAccount = [SELECT Id, Name, PersonEmail, RecordType.Name FROM Account WHERE PersonEmail != '' LIMIT 1][0];
    
        List<ARC_PromotionDiscount__c> hdList = [SELECT Id, ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c
                                                 FROM ARC_PromotionDiscount__c  
                                                 WHERE RecordType.DeveloperName = 'Healthy_Discount'
                                                 AND ARC_ContractStatus__c = 'Activated' 
                                                 AND ARC_EndDate__c != null
                                                 AND (ARC_EndDate__c = :dateToday.addDays(30) OR ARC_EndDate__c = :dateToday.addDays(90))];
        
        List<vlocity_ins__GroupCensus__c> censusRelated = new List<vlocity_ins__GroupCensus__c>{
            new vlocity_ins__GroupCensus__c(Id = hdList[0].ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c, ARC_PrimaryAccount__c = personAccount.Id)
        };

        update censusRelated;

        hdList = [SELECT Id, ARC_EndDate__c, ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c,
                         ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.FirstName, 
                         ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonEmail 
                 FROM ARC_PromotionDiscount__c  
                 WHERE RecordType.DeveloperName = 'Healthy_Discount'
                 AND ARC_ContractStatus__c = 'Activated' 
                 AND ARC_EndDate__c != null
                 AND (ARC_EndDate__c = :dateToday.addDays(30) OR ARC_EndDate__c = :dateToday.addDays(90))];
 
        for (ARC_PromotionDiscount__c hd : hdList) {
            inputMap.put(hd.Id, hd);
        }

        Test.startTest();
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        Test.stopTest();
    }

    @isTest
    public static void sendMemberIdCardInternalTest() {
        vlocity_ins__GroupCensusMember__c member = [SELECT Id,Member_ID__c,vlocity_ins__ContactId__r.Email,vlocity_ins__FirstName__c,vlocity_ins__CensusId__c,vlocity_ins__Birthdate__c,ARC_PhysicalAddressState__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'sendMemberIdCardInternal'; 
        
        List<Object> EditBlockInput = new List<Object>();
        Map<String, Object> memberMap = new Map<String, Object>{
            'Id'=> [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1].Id,
            'Email' => 'test1@test1.com',
            'isSelected' => true
        };
        EditBlockInput.add(memberMap);
        inputMap.put('ContextId', member.Id);
        inputMap.put('email', 'test@test.com');
        inputMap.put('userEmail', 'test@test.com');
        inputMap.put('EB_SelectMembers', EditBlockInput);

        Test.startTest();
            ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        Test.stopTest();
    }

    @isTest
    public static void sendMemberIdCardCommunityTest() {
        vlocity_ins__GroupCensusMember__c member = [SELECT Id,Member_ID__c,vlocity_ins__ContactId__r.Email,vlocity_ins__FirstName__c,vlocity_ins__CensusId__c,vlocity_ins__Birthdate__c,ARC_PhysicalAddressState__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'sendMemberIdCardCommunity'; 
        
        inputMap.put('ContextId', member.Id);
        inputMap.put('email', 'test@test.com');
        inputMap.put('userEmail', 'test@test.com');

        Test.startTest();
            ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        Test.stopTest();
    }
    @isTest
    public static void sendChangePaymentMethodConfirmation() {
        vlocity_ins__GroupCensusMember__c member = [SELECT Id,Member_ID__c,vlocity_ins__ContactId__r.Email,vlocity_ins__FirstName__c,vlocity_ins__CensusId__c,vlocity_ins__Birthdate__c,ARC_PhysicalAddressState__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'sendChangePaymentMethodConfirmation'; 
        
        inputMap.put('ContextId', member.Id);
        inputMap.put('email', 'test@test.com');
        inputMap.put('MemberEmail', 'test@test.com');
        inputMap.put('MemberId',member.Id);
        Map<String, Object> method = new Map<String, Object>{'RAD_MethodOfPayment' => 'Credit Card'};
        inputMap.put('STEP_ChooseMethod', method);
        inputMap.put('Step_Instructions', new Map<String, Object>{
            'BLK_PaymentInfo' => new Map<String, Object>{
                'BLK_UpdateCreditCard' => new Map<String, Object>{
                    'TXT_CardNumber' => '4111 1111 1111 1111'
                },
                'BLK_BankAccount' => new Map<String, Object>{
                    'TXT_UpdateAccNumber' => '4111 1111 1111 1111'
                }
            }
        });
        inputMap.put('OldChargeDate', 15);

        Test.startTest();
            ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
            inputMap.put('firstName','John Doe');
            method.put('RAD_MethodOfPayment', 'Bank Account');
            inputMap.put('STEP_ChooseMethod', method);
            inputMap.put('OldChargeDate', null);
            inputMap.put('OldPaymentNextTransactionDate', Date.today());
            ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
            inputMap.put('OldPaymentNextTransactionDate', null);
            inputMap.put('OldPaymentStartDate', Date.today());
            ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
            inputMap.put('OldPaymentStartDate', null);
            ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        Test.stopTest();
    }

    @isTest
    public static void email_34() {
        List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
	    Contract cont = [SELECT Id FROM Contract LIMIT 1];
	    ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_34'; 
        
        List<Id> censMembsId = new List<Id>();
        
        for(vlocity_ins__GroupCensusMember__c censusMember: censMembList){
            censMembsId.add(censusMember.Id);
		}
        
        inputMap.put('censusMemberIds', censMembsId);

         Integer afterInvocations;
        test.startTest();
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }
    @isTest
    public static void email_35() {
        List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
	    Contract cont = [SELECT Id FROM Contract LIMIT 1];
	    ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_35'; 
        
        List<Id> censMembsId = new List<Id>();
        
        for(vlocity_ins__GroupCensusMember__c censusMember: censMembList){
            censMembsId.add(censusMember.Id);
		}
        
        inputMap.put('censusMemberIds', censMembsId);

        Integer afterInvocations;
        test.startTest();
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }
    
    @isTest
    public static void email_57() {
        List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
	    Contract cont = [SELECT Id FROM Contract LIMIT 1];
	    ChargentOrders__ChargentOrder__c chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_57'; 
        
        List<Id> censMembsId = new List<Id>();
        
        for(vlocity_ins__GroupCensusMember__c censusMember: censMembList){
            censMembsId.add(censusMember.Id);
		}
        
        inputMap.put('censusMemberIds', censMembsId);

        Integer afterInvocations;
        test.startTest();
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        afterInvocations = Limits.getEmailInvocations();
        test.stopTest();
    }

    @isTest
    public static void email_59() {
        Map<String, Object> inputMap = new Map <String,Object> {
            'firstName' => 'John',
            'email' => 'test@test.com'
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_59'; 

        test.startTest();
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        test.stopTest();
    }

    @isTest
    public static void email_60() {
        List<vlocity_ins__GroupCensusMember__c> censMembList = [SELECT Id,vlocity_ins__FirstName__c,vlocity_ins__ContactId__r.Email FROM vlocity_ins__GroupCensusMember__c LIMIT 1];       
        Map<String, Object> inputMap = new Map <String,Object> {
            'emails' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'censusMember' => censMembList[0]
                }
            }
        };
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'email_60'; 
        
       
        test.startTest();
        ARC_Emails.invokeMethod(methodName, inputMap, outMap, options);
        test.stopTest();
    }

    @IsTest
    public static void sendErrorMessageTest(){
        Test.startTest();
        try {
            Messaging.sendEmail(null);
        } catch (Exception e) {
            ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ClassName', 'Id');
        }
        Test.stopTest();
    }

    @IsTest
    public static void sendEmailConstructorTest(){
        List<vlocity_ins__GroupCensusMember__c> censMemb = [
			SELECT Id
			FROM vlocity_ins__GroupCensusMember__c
			LIMIT 1
		];
        Test.startTest();
        Map<String,Object> response1 = ARC_Emails.sendEmailConstructor('test@test.com', 'WeSharePortalWelcomeEmailInternal', new Map<String, Object>{
            '{!User.FirstName}' => 'TestUser Name'
        }, censMemb[0].Id);
        Assert.areEqual(true, (Boolean)response1.get('success'));

        Map<String,Object> response2 = ARC_Emails.sendEmailConstructor('', '', new Map<String, Object>{
            '{!User.FirstName}' => 'TestUser Name'
        }, censMemb[0].Id);
        Assert.areEqual(false, (Boolean)response2.get('success'));

        Test.stopTest();
    }

    @IsTest
    public static void sendResetUsernameAndPasswordEmailConstructorTest(){
        Test.startTest();

        User usr = new User(
            LastName = 'Test',
            FirstName = 'Test',
            Alias = 'testal',
            Email = 'testemail@uhsm.com',
            Username = 'test@uhsm.com',
            CommunityNickname = 'TestNick',
            ContactId = [SELECT Id FROM Contact WHERE Email = 'testEmail@uhsm.com'].Id,
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LocaleSidKey = 'en_US',
            ARC_PortalUsername__c = 'testportalusername@uhsm.com'
        );  
        insert usr;
        Map<Id,Id> userToMember = new Map<Id,Id>(); 
        List<vlocity_ins__GroupCensusMember__c> membs = [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__ContactId__c =: usr.ContactId]; 
        List<User> userList = new List<User>{usr};
        userToMember.put(usr.Id, membs[0].Id);
        Map<String,Object> response1 = ARC_Emails.sendResetUsernameAndPasswordEmailConstructor(userList, 'WeSharePortalWelcomeEmailInternal', new Map<String, String>{
            '{!User.FirstName}' => 'FirstName',
            '{!User.Username}' => 'Username'
        }, userToMember);
        Assert.areEqual(true, (Boolean)response1.get('success'));
        List<User> emptyUserList = new List<User>();
        Map<String,Object> response2 = ARC_Emails.sendResetUsernameAndPasswordEmailConstructor(emptyUserList, 'WeSharePortalWelcomeEmailInternal', new Map<String, String>{
            '{!User.FirstName}' => 'FirstName',
            '{!User.Username}' => 'Username'
        }, userToMember);

        Test.stopTest();
    }

    @IsTest
    static void sendWelcomeEmailTest(){
        User usr = new User(
            LastName = 'Test',
            FirstName = 'Test',
            Alias = 'testal',
            Email = 'testemail@uhsm.com',
            Username = 'test@uhsm.com',
            CommunityNickname = 'TestNick',
            ContactId = [SELECT Id FROM Contact WHERE Email = 'testEmail@uhsm.com'].Id,
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Member Community' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LocaleSidKey = 'en_US',
            ARC_PortalUsername__c = 'testportalusername@uhsm.com'
        );  
        insert usr;

        Test.startTest();
        ARC_Emails.sendWelcomeEmail(new List<Id>{[SELECT Id FROM Contact WHERE Email = 'testEmail@uhsm.com'].Id});
        Test.stopTest();
    }

    @IsTest
    static void sendPaymentReceiptsTest(){
        vlocity_ins__GroupCensusMember__c censusMember = [
			SELECT Id,vlocity_ins__Email__c
			FROM vlocity_ins__GroupCensusMember__c
			LIMIT 1
		];

        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('censusMemberId', censusMember.Id);
        inputMap.put('email', censusMember.vlocity_ins__Email__c);
        inputMap.put('CCString', 'testemail1@test.com,testemail2@test.com,testemail3@test.com');
        inputMap.put('MemberName', 'Testing Member');

        Test.startTest();
        ARC_Emails.sendPaymentReceipts(inputMap, new Map<String,Object>(), new Map<String,Object>());
        Test.stopTest();
    }

    @IsTest
    static void sendIdCardResendConfirmationTest(){
        Map<String, Object> inputMap = new Map<String, Object>{
			'senderFirstName' => 'John',
            'email' => 'test@test.com'            
		};
        Test.startTest();
        ARC_Emails.invokeMethod('sendIdCardResendConfirmation', inputMap, new Map<String,Object>(), new Map<String,Object>());
        Test.stopTest();
    }

    @IsTest
    static void sendWelcomeKitResendConfirmationTest(){
        Map<String, Object> inputMap = new Map<String, Object>{
			'senderFirstName' => 'John',
            'email' => 'test@test.com'            
		};
        Test.startTest();
        ARC_Emails.invokeMethod('sendWelcomeKitResendConfirmation', inputMap, new Map<String,Object>(), new Map<String,Object>());
        Test.stopTest();
    }
}