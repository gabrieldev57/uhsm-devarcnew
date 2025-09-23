@isTest
private class ARC_CreateOriginalPriceTest {

    @TestSetup
    static void makeData(){
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        for(Integer i = 0; i < 2; i++){
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

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(2);
        counter = 0;
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = accList[counter].PersonContactId;
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

        List<Contract> cont = ARC_TestUtility.createContractsAA(2);
        for (Integer i = 0; i < 2; i++) {
            cont[i].vlocity_ins__EnrollmentCensusId__c = censusData[0].vlocity_ins__CensusId__c;
            cont[i].vlocity_ins__EnrollmentCensusId__c = censusData[0].vlocity_ins__CensusId__c;
            cont[i].ARC_EffectiveDate__c = System.today();
            cont[i].AccountId = accList[0].Id;
        }
        insert cont;

        List<ChargentOrders__ChargentOrder__c> chargentList = new List<ChargentOrders__ChargentOrder__c>();
        for (Integer i = 0; i < 2; i++) {
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

        for (Integer i = 0; i < 2; i++) {
            cont[i].ARC_RecurringMonthlyOrder__c=chargentList[i].Id;
            cont[i].Status = 'Awaiting Approval';
        }
        update cont;

        List<Product2> prodList = ARC_TestUtility.createTestProducts(2);
        prodList[0].vlocity_ins__Type__c = 'Medical';
        prodList[1].vlocity_ins__Type__c = 'Dental';
        update prodList;

        List<vlocity_ins__ContractLineItem__c> cliList = new List<vlocity_ins__ContractLineItem__c>();
        for (Integer i = 0; i < 2; i++) {
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
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

        List<Healthy_Discount__c> hdList = new List<Healthy_Discount__c>();
        for (Integer i = 0; i < 2; i++) {
            Healthy_Discount__c hd = new Healthy_Discount__c();
            hd.Name = 'hd test' + i;
            hd.New_Order_Price__c = 500;
            hd.Healthy_Discount_Price__c = 1000;
            hd.Smoker_Fees__c = 100;
            hd.Extra_Dependent_Fee__c = 200;
            hd.Contract__c = cont[i].Id;
            hd.Is_Active__c = true;
            hdList.add(hd);
        }
        insert hdList;
    }

    @isTest
    static void ARC_CreateOriginalPriceBatchIdTest() {
        List<Contract> contracts = [SELECT Id FROM Contract WHERE Status != 'Draft'];
        Set<Id> contractIds = new Set<Id>();
        for (Contract cont : contracts) {
            contractIds.add(cont.Id);
        }

        Test.startTest();
        ARC_CreateOriginalPrice batch = new ARC_CreateOriginalPrice(contractIds);
        Database.executeBatch(batch);
        Test.stopTest();

        List<Contract> contractsAfter = [SELECT Id, ContractNumber, Status, ARC_TotalPrice__c, 
                                            (SELECT Id, vlocity_ins__UnitPrice__c, ARC_SmokerFee__c, ARC_ExtraDependentFee__c, ARC_OriginalPrice__c, vlocity_ins__ProductType__c, vlocity_ins__EffectiveStartDate__c, vlocity_ins__ContractId__r.StartDate, vlocity_ins__EffectiveEndDate__c, vlocity_ins__ContractId__r.EndDate FROM vlocity_ins__ContractLineItems__r),
                                            (SELECT Id, Name, Old_Medical_Price__c, Is_Active__c, New_Order_Price__c FROM Healthy_Discounts__r WHERE Is_Active__c = true)
                                            FROM Contract WHERE Status != 'Draft' AND Id IN:contractIds];
        for (Contract contractAfter : contractsAfter) {
            for (vlocity_ins__ContractLineItem__c item : contractAfter.vlocity_ins__ContractLineItems__r) {
                System.assertNotEquals(null, item.ARC_OriginalPrice__c, 'OriginalPrice was not correctly calculated');
                Decimal expectedOriginalPrice;
                if (item.vlocity_ins__ProductType__c == 'Medical') {
                    expectedOriginalPrice = contractAfter.Healthy_Discounts__r[0].Old_Medical_Price__c - (item.ARC_SmokerFee__c + item.ARC_ExtraDependentFee__c);
                } else {
                    expectedOriginalPrice = item.vlocity_ins__UnitPrice__c - (item.ARC_SmokerFee__c + item.ARC_ExtraDependentFee__c);
                }
                System.assertEquals(expectedOriginalPrice, item.ARC_OriginalPrice__c, 'OriginalPrice was not correctly calculated');
                System.assertEquals(null, item.vlocity_ins__EffectiveStartDate__c, 'EffectiveStartDate was not corrected');
            }
        }
    }

    @isTest
    static void ARC_CreateOriginalPriceBatchNoIdTest() {
        Test.startTest();
        ARC_CreateOriginalPrice batch = new ARC_CreateOriginalPrice();
        Database.executeBatch(batch);
        Test.stopTest();

        List<Contract> contractsAfter = [SELECT Id, ContractNumber, Status, ARC_TotalPrice__c, 
                                            (SELECT Id, vlocity_ins__UnitPrice__c, ARC_SmokerFee__c, ARC_ExtraDependentFee__c, ARC_OriginalPrice__c, vlocity_ins__ProductType__c, vlocity_ins__EffectiveStartDate__c, vlocity_ins__ContractId__r.StartDate, vlocity_ins__EffectiveEndDate__c, vlocity_ins__ContractId__r.EndDate FROM vlocity_ins__ContractLineItems__r),
                                            (SELECT Id, Name, Old_Medical_Price__c, Is_Active__c, New_Order_Price__c FROM Healthy_Discounts__r WHERE Is_Active__c = true)
                                            FROM Contract WHERE Status != 'Draft'];
        for (Contract contractAfter : contractsAfter) {
            for (vlocity_ins__ContractLineItem__c item : contractAfter.vlocity_ins__ContractLineItems__r) {
                Assert.areNotEqual(null, item.ARC_OriginalPrice__c, 'OriginalPrice was not correctly calculated');
                Decimal expectedOriginalPrice;
                if (item.vlocity_ins__ProductType__c == 'Medical') {
                    expectedOriginalPrice = contractAfter.Healthy_Discounts__r[0].Old_Medical_Price__c - (item.ARC_SmokerFee__c + item.ARC_ExtraDependentFee__c);
                } else {
                    expectedOriginalPrice = item.vlocity_ins__UnitPrice__c - (item.ARC_SmokerFee__c + item.ARC_ExtraDependentFee__c);
                }
                Assert.areEqual(expectedOriginalPrice, item.ARC_OriginalPrice__c, 'OriginalPrice was not correctly calculated');
                Assert.areEqual(null, item.vlocity_ins__EffectiveStartDate__c, 'EffectiveStartDate was not corrected');
            }
        }
    }
}