@isTest
public without sharing class ARC_PersonAccount360viewTest {

    @TestSetup
    static void makeData(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        for(Integer i=0; i<2;i++){
            Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount'+i, LastName ='Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode='12345';
            acc.PersonEmail='test@email.com'+counter;
            acc.ARC_IsPrimaryMember__c = true;
            acc.ARC_E123MemberIdFromPolicy__c = 'W123456789'+counter;
            acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
            accList.add(acc);
        }
        insert accList;

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(2);
        counter = 0;
        List<Account> accountContacts = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%'];
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = accountContacts[counter].PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
            counter++;
        }
        update censusMemberList;

        List<vlocity_ins__GroupCensusMember__c> censusData =[SELECT Id, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c];
        accList[0].Census_Member__c = censusData[0].Id;
        accList[1].Census_Member__c = censusData[1].Id;
        accList[0].ARC_CensusMember__pc = censusData[0].Id;
        accList[1].ARC_CensusMember__pc = censusData[1].Id;
        accList[0].ARC_Census__c = censusData[0].vlocity_ins__CensusId__c;
        accList[1].ARC_Census__c = censusData[1].vlocity_ins__CensusId__c;
        update accList;

        List<Contract> cont = ARC_TestUtility.createContractsAA(4);
        for (Integer i = 0; i < 4; i++) {
            cont[i].Name = 'WeShare test ' + i;
            cont[i].vlocity_ins__EnrollmentCensusId__c = censusData[0].vlocity_ins__CensusId__c;
            //cont[i].AccountId = accList[0].Id;
        }
        insert cont;

        List<ChargentOrders__ChargentOrder__c> chargentList = new List<ChargentOrders__ChargentOrder__c>();
        for (Integer i = 0; i < 4; i++) {
            ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c();
            chargent.ARC_Contract__c = cont[i].Id;
            chargent.ChargentOrders__Shipping__c = 123;
            chargent.ChargentOrders__Tax__c  = 123;
            chargent.ChargentOrders__Charge_Amount__c = 123;
            chargent.ChargentOrders__Subtotal__c  = 123;
            chargent.ChargentOrders__Charge_Date__c =  '01';
            chargent.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
            chargent.ChargentOrders__Payment_Status__c = 'Recurring';
            chargent.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2021, 11, 12);
            chargent.ChargentOrders__Payment_Method__c = 'Credit Card';
            chargent.ChargentOrders__Card_Last_4__c = '1234';
            chargent.ChargentOrders__Card_Type__c = 'VISA';
            chargent.ChargentOrders__Card_Expiration_Month__c = '12';
            chargent.ChargentOrders__Card_Expiration_Year__c = '2024';
            chargent.ChargentOrders__Tokenization__c = '12345678';
            chargent.ChargentOrders__Description__c = 'Recurring Monthly Order';
            chargentList.add(chargent);
        }
        insert chargentList;

        //Avoid Execute Update Contract ON Effective Date
        cont[0].ARC_EffectiveDate__c = Date.today().addDays(1);
        cont[1].ARC_EffectiveDate__c = Date.today().addDays(1);
        cont[2].ARC_EffectiveDate__c = Date.today().addDays(1);
        cont[0].Status = 'Awaiting Activation';
        cont[1].Status = 'Awaiting Activation';
        cont[2].Status = 'Awaiting Activation';
        update cont;

        cont[0].Status = 'Terminated';
        cont[0].ARC_ContractReason__c = 'Add Newborn';
        cont[0].ARC_EffectiveDate__c = Date.newInstance(2020, 10, 10);
        cont[0].ARC_Inactive_Date__c = Date.newInstance(2021, 10, 10);
        cont[1].ARC_EffectiveDate__c = cont[0].ARC_Inactive_Date__c.addDays(2);
        cont[1].ARC_ContractReason__c = 'New Application';
        cont[1].Status = 'Activated';
        cont[2].Status = 'Terminated';
        cont[2].ARC_ContractReason__c = 'New Application';
        cont[2].ARC_EffectiveDate__c = Date.newInstance(2023, 10, 10);
        cont[2].ARC_Inactive_Date__c = Date.newInstance(2024, 10, 10);
        cont[3].ARC_ContractReason__c = 'Add Newborn';
        cont[3].ARC_EffectiveDate__c = Date.newInstance(2024, 10, 12);
        cont[3].Status = 'Activated';
        for (Integer i = 0; i < 4; i++) {
            cont[i].ARC_RecurringMonthlyOrder__c=chargentList[i].Id;
        }
        update cont;

        List<Product2> prodList = ARC_TestUtility.createTestProducts(4);
        for (Integer i = 0; i < 4; i++) {
            prodList[i].vlocity_ins__Type__c = 'Medical';
        }
        update prodList;

        List<vlocity_ins__ContractLineItem__c> cliList = new List<vlocity_ins__ContractLineItem__c>();
        for (Integer i = 0; i < 4; i++) {
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
            cli.Name = 'WeShare'+i;
            cli.ARC_SmokerFee__c = 100;
            cli.ARC_ExtraDependentFee__c = 200;
            cli.ARC_OriginalPrice__c = 0;
            cli.vlocity_ins__UnitPrice__c = 1000;
            cli.vlocity_ins__EffectiveStartDate__c = cont[i].StartDate.addDays(-1);
            cli.vlocity_ins__ContractId__c = cont[i].Id;
            cli.vlocity_ins__Product2Id__c = prodList[i].Id;
            cliList.add(cli);
        }
        insert cliList;

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for (Integer i = 0; i < 2; i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmp.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmp.vlocity_ins__GroupCensusMemberId__c = censusMemberList[0].Id;
            gcmpList.add(gcmp);
        }
        for (Integer i = 2; i < 4; i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmp.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmp.vlocity_ins__GroupCensusMemberId__c = censusMemberList[1].Id;
            gcmpList.add(gcmp);
        }
        insert gcmpList;

        //Create an Account to test availableStates
        Account testAccount = new Account(
            RecordTypeId = accRecordTypeId,
            FirstName = 'Test',
            LastName = 'User',
            BillingState = 'CA'
        );
        insert testAccount;
        
    }

    //Test for availableStates = TRUE
    @isTest 
    public static void testDentalAvailableState_True (){
        Account pa = [SELECT Id, BillingState FROM Account WHERE FirstName = 'Test' LIMIT 1];
        pa.BillingState = 'NY'; 
        update pa;

        Map<String, Object> inputMap = new Map<String, Object>{'personAccountId' => pa.Id};
        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
            new ARC_PersonAccount360view().invokeMethod('getPersonAccountDetails360FlexCard', inputMap, outputMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, outputMap.get('showDentalAvailableState'), 'Expected dentalAvailableState to be TRUE');
    }

    
    //Test for availableStates = FALSE
    @isTest 
    public static void testDentalAvailableState_False (){
        
        Account pa = [SELECT Id, BillingState FROM Account WHERE FirstName = 'Test' LIMIT 1];
        pa.BillingState = 'UT'; 
        update pa;

        Map<String, Object> inputMap = new Map<String, Object>{'personAccountId' => pa.Id};
        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
          new ARC_PersonAccount360view().invokeMethod('getPersonAccountDetails360FlexCard', inputMap, outputMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(false, outputMap.get('showDentalAvailableState'), 'Expected dentalAvailableState to be FALSE');
    }

    
    @isTest
    public static void getPersonAccountDetails360FlexCardContractTest() {
        Account pa = [SELECT Id,ARC_Census__c, Census_Member__r.vlocity_ins__CensusId__c FROM Account WHERE FirstName = 'PersonAccount0' LIMIT 1];
        
        Map<String,Object> inputMap = new Map<String,Object>{'personAccountId'=>pa.Id};
        Map<String,Object> outputMap = new Map<String,Object>();

        Test.startTest();
            new ARC_PersonAccount360view().invokeMethod('getPersonAccountDetails360FlexCard', inputMap, outputMap, new Map<String,Object>());
        Test.stopTest();

        Assert.areEqual(true, outputMap.get('ContractActive'));
    }

    @isTest
    public static void getPersonAccountDetails360FlexCardTerminatedContractTest() {
        Account pa = [SELECT Id,ARC_Census__c, Census_Member__r.vlocity_ins__CensusId__c FROM Account WHERE FirstName = 'PersonAccount0' LIMIT 1];
        List<Contract> contracts = [SELECT Id,ARC_RecurringMonthlyOrder__c FROM Contract WHERE vlocity_ins__EnrollmentCensusId__c =: pa.Census_Member__r.vlocity_ins__CensusId__c];

        Map<String,Object> inputMap = new Map<String,Object>{'personAccountId'=>pa.Id};
        Map<String,Object> outputMap = new Map<String,Object>();

        for(Contract cont : contracts) {
            cont.Status = 'Terminated';
        }
        update contracts;

        Test.startTest();
            new ARC_PersonAccount360view().invokeMethod('getPersonAccountDetails360FlexCard', inputMap, outputMap, new Map<String,Object>());
        Test.stopTest();

        Assert.areEqual(contracts[0].ARC_RecurringMonthlyOrder__c, outputMap.get('OrderId'));
    }


    @isTest
    public static void getPersonAccountDetails360FlexCardNoAccountTest() {
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();

        Test.startTest();
            new ARC_PersonAccount360view().invokeMethod('getPersonAccountDetails360FlexCard', inputMap, outputMap, new Map<String,Object>());
        Test.stopTest();

        Assert.areEqual(false, outputMap.get('success'));
        Assert.areEqual('Error in ARC_PersonAccount360view.getPersonAccountDetails360FlexCard(), No Person Account found', outputMap.get('errorMessage'));
    }


    @isTest
    public static void getPersonAccountDetails360FlexCardNoContractTest() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount2', LastName ='Test');
        acc.BillingStreet = '123 Avenue';
        acc.BillingState = 'NY';
        acc.BillingCity = 'New York';
        acc.BillingPostalCode='12345';
        acc.PersonEmail='test@email.com2';
        acc.ARC_IsPrimaryMember__c = true;
        acc.ARC_E123MemberIdFromPolicy__c = 'W1234567892';
        acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
        insert acc;

        Map<String,Object> inputMap = new Map<String,Object>{'personAccountId'=>acc.Id};
        Map<String,Object> outputMap = new Map<String,Object>();

        Test.startTest();
            new ARC_PersonAccount360view().invokeMethod('getPersonAccountDetails360FlexCard', inputMap, outputMap, new Map<String,Object>());
        Test.stopTest();

        Assert.areEqual(false, outputMap.get('success'));
        Assert.areEqual('Error in ARC_PersonAccount360view.getPersonAccountDetails360FlexCard(), No Contract found', outputMap.get('errorMessage'));
    }

    
    @isTest
    public static void stampPersonAccountInSpinOffMembersTest(){
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> outputMap = new Map<String,Object>();
        vlocity_ins__GroupCensusMember__c existingMember = [SELECT Id,vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        vlocity_ins__GroupCensusMember__c newMember = new vlocity_ins__GroupCensusMember__c(e123_member_id_from_policy__c='12345', vlocity_ins__CensusId__c= existingMember.vlocity_ins__CensusId__c, ARC_OldCensusMember__c=existingMember.Id);
        insert newMember;

        List<Object> inputTest = new List<Object>();
        Map<String, Object> censusMember  = new Map<String, Object>();
        censusMember.put('Id',newMember.Id);
        inputTest.add(censusMember);
        inputMap.put('censusMembers',inputTest);

        Test.startTest();
            Boolean objBool = new ARC_PersonAccount360view().invokeMethod('stampPersonAccountInSpinOffMembers', inputMap, outputMap, new Map<String,Object>());
        Test.stopTest();
        System.assertEquals(false, outputMap.get('success'));
        System.assertEquals(false, outputMap.get('spinOffUpdated'));
    }


    @isTest
    public static void getSSNDescryptedAccountTest(){
        Account account = [SELECT Id FROM Account WHERE FirstName LIKE 'PersonAccount%' LIMIT 1];
        List<ARC_PersonAccount360view.Results> ssnList = new List<ARC_PersonAccount360view.Results>();
        Test.startTest();
            ssnList = ARC_PersonAccount360view.getSSNDescrypted(new List<Id>{account.Id});
        Test.stopTest();
        System.assertEquals(account.Id, ssnList[0].recordId);
        System.assertEquals('123456789', ssnList[0].ssn);  
    }

    @isTest
    public static void testLastDateOfMonth(){
        Test.startTest();
            Date ldOfMonth = ARC_PersonAccount360view.lastDateOfMonth(Date.newInstance(2023,12,01));
        Test.stopTest();
        System.assertEquals(Date.newInstance(2023,12,31),ldOfMonth);
    }
}