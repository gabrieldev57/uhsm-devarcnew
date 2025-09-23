@isTest
private class ARC_AgeUpTest {

    @testSetUp
    static void makeData() {
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount', LastName ='Test');
        acc.BillingStreet = '123 Avenue';
        acc.BillingState = 'NY';
        acc.BillingCity = 'New York';
        acc.BillingPostalCode='12345';
        acc.PersonEmail='test@email.com';
        acc.ARC_IsPrimaryMember__c = true;
        acc.ARC_E123MemberIdFromPolicy__c = 'W123456789';
        acc.IsActive = True;
        insert acc;

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(1);
        vlocity_ins__GroupCensusMember__c member = censusMemberList[0];
        List <Account> accountListContactIds = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%' ORDER BY FirstName];
        member.vlocity_ins__ContactId__c = accountListContactIds[0].PersonContactId;
        member.vlocity_ins__SocialSecurityNumber__c = '123456789';
        member.ARC_PhysicalAddressState__c = 'NY';
        member.vlocity_ins__AccountId__c = acc.Id;
        System.debug(member.vlocity_ins__AccountId__c);
        member.vlocity_ins__Birthdate__c = Date.newInstance(Date.today().year()-18, Date.today().month(), Date.today().day()).addDays(1);
        update member;

        acc.Census_Member__c = member.Id;
        acc.ARC_CensusMember__pc = member.Id;
        acc.ARC_Census__c = member.vlocity_ins__CensusId__c;
        update acc;
        
        List<Contract> contList = ARC_TestUtility.createContractsAA(1);
        Contract cont = contList[0];
        cont.vlocity_ins__EnrollmentCensusId__c = member.vlocity_ins__CensusId__c;
        System.debug(member.vlocity_ins__CensusId__c);
        System.debug(member.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c);
        List<vlocity_ins__GroupCensusMember__c> memberGId = [SELECT Id, vlocity_ins__CensusId__r.vlocity_ins__GroupId__c FROM vlocity_ins__GroupCensusMember__c];
        cont.AccountId = memberGId[0].vlocity_ins__CensusId__r.vlocity_ins__GroupId__c;
        cont.StartDate = Date.today();
        cont.ARC_EffectiveDate__c = Date.today();
        insert cont;

        ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c();
        chargent.ARC_Contract__c = cont.Id;
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
        insert chargent;

        cont.ARC_RecurringMonthlyOrder__c = chargent.Id;
        cont.Status = 'Awaiting Activation';
        cont.ARC_EffectiveDate__c = Date.Today().addDays(2);
        update cont;

        cont.ARC_EffectiveDate__c = Date.Today().addMonths(-3);
        cont.Status = 'Activated';
        update cont;

        ARC_ContractParticipant__c cp = new ARC_ContractParticipant__c();
        cp.ARC_Contract__c = cont.Id;
        cp.ARC_PersonAccount__c = acc.Id;
        insert cp;

        List<Product2> prodList = ARC_TestUtility.createTestProducts(1);
        prodList[0].vlocity_ins__Type__c = 'Medical';
        Product2 prod = prodList[0];
        prod.ProductCode = 'PROG_UHSM_WeShare1k';
        Id rtProduct = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        prod.RecordTypeId = rtProduct;
        prod.vlocity_ins__RatingProcedureType__c = 'Calculation Procedure';
        prod.vlocity_ins__RatingCalcProcedureName__c = 'ARC_UHSMCalculationProcedure_Individual';
        prod.vlocity_ins__PricingFormula__c = 'Price';
        prod.vlocity_ins__AttributeDefaultValues__c = '{"AMCS":"1k/2k","MedicalMaxShareLimits":"No lifetime or annual share maximums, except where explicitly noted","OutOfNetworkServices":"Only in the case of an emergency or when pre-authorized","PharmacyMemberCareShare":250,"PharmacyShareMaximum":3500,"familyAMCS":2000,"individualAMCS":1000}';
        update prod;

        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
        cli.Name = 'WeShare test';
        cli.ARC_SmokerFee__c = 100;
        cli.ARC_ExtraDependentFee__c = 200;
        cli.ARC_OriginalPrice__c = 1000;
        cli.vlocity_ins__UnitPrice__c = 1000;
        cli.vlocity_ins__EffectiveStartDate__c = cont.StartDate;
        cli.vlocity_ins__ContractId__c = cont.Id;
        cli.vlocity_ins__Product2Id__c = prod.Id;
        insert cli;
        System.debug('ID CLI '+cli.Id);

        vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmp.vlocity_ins__ContractLineId__c = cli.Id;
        gcmp.vlocity_ins__GroupCensusMemberId__c = member.Id;
        insert gcmp;
        System.debug('ID GCMP '+gcmp.Id);
    }

    @isTest
    static void ARC_AgeUpMethodAgeUpBatchFailTest() {
        ARC_AgeUp.AgeUpRequest request = new ARC_AgeUp.AgeUpRequest();
        request.methodName = 'ageUpBatch';
        List<ARC_AgeUp.AgeUpRequest> ageUpRequests = new List<ARC_AgeUp.AgeUpRequest>();
        ageUpRequests.add(request);

        Test.startTest();
        ARC_AgeUp.invocableAgeUp(ageUpRequests);
        Test.stopTest();
    }

    @isTest
    static void ARC_AgeUpMethodApplyAgeUpFailTest() {
        List<Contract> contList = [SELECT Id FROM Contract];
        Contract cont = contList[0];
        List<Account> accList = [SELECT Id FROM Account WHERE FirstName LIKE 'PersonAccount%'];
        Account acc = accList[0];
        List<Product2> prodList = [SELECT Id FROM Product2];
        Product2 prod = prodList[0];
        List<vlocity_ins__ContractLineItem__c> cliList = [SELECT Id FROM vlocity_ins__ContractLineItem__c];
        vlocity_ins__ContractLineItem__c cli = cliList[0];

        Ages_Up__c ageup = new Ages_Up__c();
        ageup.Name = 'PersonAccount Test - Age Up';
        ageup.Contract__c = cont.Id;
        ageup.ARC_Account__c = acc.Id;
        ageup.ARC_EffectiveDate__c = Date.today();
        ageup.ARC_PriceAfterAgeUp__c = 200;
        ageup.ARC_PriceBeforeAgeUp__c = 100;
        insert ageup;

        ARC_AgeUp.AgeUpRequest request = new ARC_AgeUp.AgeUpRequest();
        request.methodName = 'applyAgeUp';
        request.ageUp = ageup;
        List<ARC_AgeUp.AgeUpRequest> ageUpRequests = new List<ARC_AgeUp.AgeUpRequest>();
        ageUpRequests.add(request);

        Test.startTest();
        ARC_AgeUp.invocableAgeUp(ageUpRequests);
        Test.stopTest();

        List<Ages_Up__c> ages = [SELECT Id, ARC_PriceBeforeAgeUp__c, ARC_PriceAfterAgeUp__c FROM Ages_Up__c];

        Assert.areEqual(ages.size(), 1);
        Assert.areEqual(ages[0].ARC_PriceBeforeAgeUp__c, 100, 'ARC_PriceBeforeAgeUp__c should not be modified');
        Assert.areEqual(ages[0].ARC_PriceAfterAgeUp__c, 200, 'ARC_PriceAfterAgeUp__c should not be modified');
    }

    @isTest
    static void ARC_AgeUpPriceCalculationQueableSuccessTest() {
        List<Contract> contList = [SELECT Id FROM Contract];
        Contract cont = contList[0];
        List<Account> accList = [SELECT Id FROM Account WHERE FirstName LIKE 'PersonAccount%'];
        Account acc = accList[0];
        List<Product2> prodList = [SELECT Id FROM Product2];
        Product2 prod = prodList[0];
        List<vlocity_ins__ContractLineItem__c> cliList = [SELECT Id FROM vlocity_ins__ContractLineItem__c];
        vlocity_ins__ContractLineItem__c cli = cliList[0];

        Ages_Up__c ageup = new Ages_Up__c();
        ageup.Name = 'PersonAccount Test - Age Up';
        ageup.Contract__c = cont.Id;
        ageup.ARC_Account__c = acc.Id;
        ageup.ARC_EffectiveDate__c = Date.today();
        ageup.ARC_PriceAfterAgeUp__c = 200;
        ageup.ARC_PriceBeforeAgeUp__c = 200;
        insert ageup;

        List<Ages_Up__c> ageUps = new List<Ages_Up__c>();
        ageUps.add(ageup);
        ARC_PriceCalculation.PlanPricingResult result = new ARC_PriceCalculation.PlanPricingResult();
        result.planId = cli.Id;
        result.productId = prod.Id;
        result.contractId = cont.Id;
        result.price = 500;
        result.priceBeforeAgeUp = 100;
        result.plan = [SELECT Id, vlocity_ins__UnitPrice__c, vlocity_ins__ContractId__c, ARC_OriginalPrice__c, ARC_SmokerFee__c, ARC_ExtraDependentFee__c, vlocity_ins__ProductType__c FROM vlocity_ins__ContractLineItem__c LIMIT 1];

        result.success = true;
        List<ARC_PriceCalculation.PlanPricingResult> results = new List<ARC_PriceCalculation.PlanPricingResult>();
        results.add(result);

        Test.startTest();
        ARC_AgeUpPriceCalculationQueable queableInstance = new ARC_AgeUpPriceCalculationQueable(ageUps);
        queableInstance.processPriceCalculationResults(results, ageUps);
        Test.stopTest();

        List<Ages_Up__c> ages = [SELECT Id, ARC_PriceBeforeAgeUp__c, ARC_PriceAfterAgeUp__c FROM Ages_Up__c];

        Assert.areEqual(ages.size(), 1);
        Assert.areEqual(ages[0].ARC_PriceBeforeAgeUp__c, 100, 'ARC_PriceBeforeAgeUp__c should be updated with the result.priceBeforeAgeUp');
        Assert.areEqual(ages[0].ARC_PriceAfterAgeUp__c, 500, 'ARC_PriceAfterAgeUp__c should be updated with the result.price');
    }

    @isTest
    static void ARC_PriceCalculationTestError() {
        List<ARC_PriceCalculation.PlanPricingInput> inputs = new List<ARC_PriceCalculation.PlanPricingInput>();
        
        ARC_PriceCalculation.PlanPricingInput input = new ARC_PriceCalculation.PlanPricingInput();
        input.planId = 'TestPlan123';
        input.productId = 'TestProduct456';
        input.contractId = 'TestContract789';
        input.priceBeforeAgeUp = 100.00;
        input.plan = [SELECT Id, vlocity_ins__UnitPrice__c, vlocity_ins__ContractId__c, ARC_OriginalPrice__c, ARC_SmokerFee__c, ARC_ExtraDependentFee__c, vlocity_ins__ProductType__c FROM vlocity_ins__ContractLineItem__c LIMIT 1];
        input.userInputs = new List<Map<String, Object>>{
            new Map<String, Object>{'field1' => 'value1'}
        };
        inputs.add(input);
        
        ARC_PriceCalculation priceCalc = new ARC_PriceCalculation(inputs);
        
        Test.startTest();
        List<ARC_PriceCalculation.PlanPricingResult> results = priceCalc.calculatePrices();
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'List of size 1 was expected');
        
        ARC_PriceCalculation.PlanPricingResult result = results[0];
        
        System.assert(result.errorMessage.contains('Error calculating price'), 'Error message should be "Error calculating price"');
        System.assert(!result.success, 'The result should not have been successful');
    }
}