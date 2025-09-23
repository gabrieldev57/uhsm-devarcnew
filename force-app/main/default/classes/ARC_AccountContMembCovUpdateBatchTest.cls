@isTest
public without sharing class ARC_AccountContMembCovUpdateBatchTest {

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

        List<Product2> prodList = ARC_TestUtility.createTestProducts(4);
        for (Integer i = 0; i < 4; i++) {
            prodList[i].vlocity_ins__Type__c = 'Medical';
            prodList[i].Name = 'WeShare';        
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

        //contrato 1
        cont[0].Status = 'Terminated';
        cont[0].ARC_ContractReason__c = 'New Application';
        cont[0].ARC_EffectiveDate__c = Date.newInstance(2020, 10, 10);
        // awaiting activation date
        cont[0].ARC_AwaitingActivationDate__c = Date.newInstance(2020, 10, 10);
        cont[0].ARC_Inactive_Date__c = Date.newInstance(2021, 10, 10);
        cont[0].vlocity_ins__ExpiredContractId__c = null;
        cont[0].ARC_MedicalPlan__c = cliList[0].Id;

        // contrato 2
        cont[1].Status = 'Terminated';
        cont[1].ARC_ContractReason__c = 'Program Upgrade';
        cont[1].ARC_EffectiveDate__c = Date.newInstance(2021, 10, 11);
        // awaiting activation date
        cont[1].ARC_AwaitingActivationDate__c = Date.newInstance(2021, 10, 11);
        cont[1].ARC_Inactive_Date__c = Date.newInstance(2023, 10, 10);
        cont[1].vlocity_ins__ExpiredContractId__c = cont[0].Id;
        cont[1].ARC_MedicalPlan__c = cliList[0].Id;
        
        // contrato 3
        cont[2].Status = 'Terminated';
        cont[2].ARC_ContractReason__c = 'Add Newborn';
        cont[2].ARC_EffectiveDate__c = Date.newInstance(2023, 10, 11);
        // awaiting activation date
        cont[2].ARC_AwaitingActivationDate__c = Date.newInstance(2023, 10, 11);
        cont[2].ARC_Inactive_Date__c = Date.today();
        cont[2].vlocity_ins__ExpiredContractId__c = cont[1].Id;
        cont[2].ARC_MedicalPlan__c = cliList[2].Id;

        // contrato 4
        cont[3].Status = 'Awaiting Activation';
        cont[3].ARC_ContractReason__c = 'Program Downgrade';
        cont[3].ARC_EffectiveDate__c = Date.today().addDays(1);
        // awaiting activation date
        cont[3].ARC_AwaitingActivationDate__c = Date.newInstance(2024, 10, 20);
        cont[3].ARC_Inactive_Date__c = null;
        cont[3].vlocity_ins__ExpiredContractId__c = cont[2].Id;
        cont[3].ARC_MedicalPlan__c = cliList[3].Id;


        for (Integer i = 0; i < 4; i++) {
            cont[i].ARC_RecurringMonthlyOrder__c=chargentList[i].Id;
        }
        update cont;

        // cont[2].Status = 'Terminated';
        cont[2].ARC_Inactive_Date__c = Date.today();
        cont[3].Status = 'Activated';
        update cont;

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for (Integer i = 0; i < 4; i++) {
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
    public static void updateContinuousMembershipBatch(){
        List<String> recordIds = new List<String>();
        List<Account> accounts = [SELECT Id, FirstName,ARC_ContinuousMembershipStartDate__c, ARC_ContinuousCoverageStartDate__c FROM Account WHERE FirstName Like 'PersonAccount%'];
        String condition = 'Id IN (\'';
        List<Id> ids = new List<Id>(); 
        for (Account acc : accounts) {
            recordIds.add(acc.Id);
        }
        condition += String.join(recordIds,'\',\'');
        condition += '\')';
        System.debug(condition);
        Test.startTest();
            Database.executeBatch(new ARC_AccountContMembCovUpdateBatch(condition, true));
        Test.stopTest();
            List<Account> resultList = [SELECT Id, FirstName,ARC_Last_Aggregator_Reset_Date__c, ARC_ContinuousCoverageStartDate__c FROM Account WHERE FirstName Like 'PersonAccount%' AND Id IN :recordIds ORDER BY FirstName ASC];
            
            Assert.areEqual(2, resultList.size(), 'Error with the number of accounts retrieved');
            Assert.areEqual(Date.newInstance(2020, 10, 10), resultList[0].ARC_ContinuousCoverageStartDate__c, 'Error calculating the Continuous Coverage Start Date of the first member');
            Assert.areEqual(Date.newInstance(2021, 10, 11), resultList[0].ARC_Last_Aggregator_Reset_Date__c, 'Error calculating the Continuous Coverage Start Date of the first member');
    
            Assert.areEqual(Date.newInstance(2000, 1, 1), resultList[1].ARC_ContinuousCoverageStartDate__c, 'Error calculating the Continuous Coverage Start Date of the second member');
            Assert.areEqual(Date.newInstance(2000, 1, 1), resultList[1].ARC_Last_Aggregator_Reset_Date__c, 'Error calculating the Continuous Coverage Start Date of the second member');
        
    }
}