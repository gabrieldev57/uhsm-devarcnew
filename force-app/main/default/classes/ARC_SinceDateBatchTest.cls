@isTest
private class ARC_SinceDateBatchTest {
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
            acc.IsActive = True;
            accList.add(acc);
        }
        insert accList;

        List <vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(2);
        List <Account> accountListContactIds = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%' ORDER BY FirstName];
        counter = 0;
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = accountListContactIds[counter].PersonContactId;
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
            cont[i].AccountId = accList[0].Id;
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

        cont[0].Status = 'Terminated';
        cont[0].ARC_ContractReason__c = 'Add Newborn';
        cont[0].ARC_EffectiveDate__c = Date.newInstance(2020, 10, 10);
        cont[0].ARC_Inactive_Date__c = Date.newInstance(2021, 10, 10);
        cont[1].ARC_EffectiveDate__c = Date.today().addDays(2);
        cont[1].ARC_ContractReason__c = 'New Application';
        cont[1].Status = 'Awaiting Activation';
        cont[2].Status = 'Terminated';
        cont[2].ARC_ContractReason__c = 'New Application';
        cont[2].ARC_EffectiveDate__c = Date.newInstance(2023, 10, 10);
        cont[2].ARC_Inactive_Date__c = Date.newInstance(2024, 10, 10);
        cont[3].ARC_ContractReason__c = 'Add Newborn';
        cont[3].ARC_EffectiveDate__c = Date.today().addDays(2);
        cont[3].Status = 'Awaiting Activation';
        for (Integer i = 0; i < 4; i++) {
            cont[i].ARC_RecurringMonthlyOrder__c=chargentList[i].Id;
        }
        update cont;

        //cont[0].ARC_EffectiveDate__c = Date.newInstance(2020, 10, 10);
        cont[1].ARC_EffectiveDate__c = cont[0].ARC_Inactive_Date__c.addDays(2);
        cont[1].Status = 'Activated';
        //cont[2].ARC_EffectiveDate__c = Date.newInstance(2023, 10, 10);
        cont[3].ARC_EffectiveDate__c = Date.newInstance(2024, 10, 12);
        cont[3].Status = 'Activated';
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
    }

    @isTest
    static void ARC_SinceDateBatchNoIdTest() {
        Test.startTest();
        ARC_SinceDateBatch batch = new ARC_SinceDateBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        List<Account> paUpdated = [SELECT Id, ARC_ContinuousMembershipStartDate__c FROM Account WHERE FirstName LIKE 'PersonAccount%' ORDER BY ARC_ContinuousMembershipStartDate__c ASC];
        Assert.areEqual(2, paUpdated.size(), 'Error with the number of accounts retrieved');
        Assert.areEqual(Date.newInstance(2024, 01, 01), paUpdated[0].ARC_ContinuousMembershipStartDate__c, 'Error updating the date of account with sinceDate before firstRenewalDate');
        //Assert.areEqual(Date.today(), paUpdated[1].ARC_ContinuousMembershipStartDate__c, 'Error updating the date of account with sinceDate after firstRenewalDate');
    }
}