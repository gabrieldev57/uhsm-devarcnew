@isTest
public with sharing class ARC_TransactionsBatchTest {
	@TestSetup
	public static void makeData(){
		
		List<Contact> conta = ARC_TestUtility.createTestContact(1,'IndustriesIndividual');
		conta[0].Email = 'testEmail@email.com';
		update conta; 
			
		List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(1);
		censMemb[0].ARC_PhysicalAddressState__c = 'CA';
		censMemb[0].vlocity_ins__IsPrimaryMember__c = true;
		censMemb[0].ARC_ActiveMember__c = true;
		censMemb[0].vlocity_ins__ContactId__c = conta[0].Id; 
		censMemb[0].vlocity_ins__FirstName__c = 'TestFirstName';
		censMemb[0].vlocity_ins__Birthdate__c = Date.newInstance(1997, 11, 1);
		update censMemb;
				
		Contract cont = ARC_TestUtility.createContractsAA(1)[0];
		cont.vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c;
		cont.ARC_EffectiveDate__c = System.today();
		insert cont;
		cont.Status = 'Activated';
		update cont;

		Product2 p = new Product2();
        p.Name = 'Test Product';
        p.ProductCode = 'Test Product Code';
		p.vlocity_ins__Type__c = 'Medical';
        insert p;

        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
		cli.Name = 'Test';
        cli.vlocity_ins__Product2Id__c = p.Id;
        cli.vlocity_ins__ContractId__c = cont.Id;
        insert cli;

        vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmp.vlocity_ins__GroupCensusMemberId__c = censMemb[0].Id;
        gcmp.vlocity_ins__ContractLineId__c = cli.Id;
		insert gcmp;
		

		ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c();
		chargent.ARC_Contract__c = cont.Id;
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
		chargent.ChargentOrders__Card_Month_Indicator__c = '12';
		chargent.ChargentOrders__Card_Expiration_Year__c = '2024';
		chargent.ChargentOrders__Card_Year_Indicator__c = '2024';
		chargent.ChargentOrders__Description__c = 'Recurring Monthly Order';
		chargent.ChargentOrders__Tokenization__c = '504939913-507845985';

		insert chargent;

		ChargentOrders__ChargentOrder__c chargent2 = new ChargentOrders__ChargentOrder__c();
		chargent2.ARC_Contract__c = cont.Id;
		chargent2.ChargentOrders__Shipping__c = 232;
		chargent2.ChargentOrders__Tax__c  = 232;
		chargent2.ChargentOrders__Charge_Amount__c = 232;
		chargent2.ChargentOrders__Subtotal__c  = 232;
		chargent2.ChargentOrders__Charge_Date__c =  '01';
		chargent2.ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3);
		chargent2.ChargentOrders__Payment_Status__c = 'Completed';
		chargent2.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
		chargent2.ChargentOrders__Payment_Method__c = 'Credit Card';
		chargent2.ChargentOrders__Card_Last_4__c = '1234';
		chargent2.ChargentOrders__Card_Type__c = 'VISA';
		chargent2.ChargentOrders__Card_Expiration_Month__c = '12';
		chargent2.ChargentOrders__Card_Month_Indicator__c = '12';
		chargent2.ChargentOrders__Card_Expiration_Year__c = '2024';
		chargent2.ChargentOrders__Card_Year_Indicator__c = '2024';
		chargent2.ChargentOrders__Description__c = 'App Fee';
		chargent2.ChargentOrders__Tokenization__c = '504939933-507845933';

		insert chargent2;


		cont.ARC_RecurringMonthlyOrder__c = chargent.Id;

		update cont;

		System.debug(chargent.ChargentOrders__Tokenization__c);

		ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c();
		transa.ChargentOrders__Order__c = chargent.Id;
		transa.ChargentOrders__Amount__c = 222;
		transa.ChargentOrders__Type__c = 'Charge';
		transa.ChargentOrders__Gateway_Date__c = Date.newInstance(2022, 07, 02);
		transa.ChargentOrders__Response_Status__c = 'Approved';


		insert transa;

		ChargentOrders__Transaction__c transa2 = new ChargentOrders__Transaction__c();
		transa2.ChargentOrders__Order__c = chargent2.Id;
		transa2.ChargentOrders__Amount__c = 222;
		transa2.ChargentOrders__Type__c = 'Charge';
		transa2.ChargentOrders__Gateway_Date__c = Date.newInstance(2022, 07, 02);
		transa2.ChargentOrders__Response_Status__c = 'Declined';
		transa2.Census__c = censMemb[0].vlocity_ins__CensusId__c;


		insert transa2;

		ChargentOrders__Transaction__c transa3 = new ChargentOrders__Transaction__c();
		transa3.ChargentOrders__Order__c = chargent.Id;
		transa3.ChargentOrders__Amount__c = 222;
		transa3.ChargentOrders__Type__c = 'Charge';
		transa3.ChargentOrders__Gateway_Date__c = Date.newInstance(2022, 07, 02);
		transa3.ChargentOrders__Response_Status__c = 'Declined';
		transa3.Census__c = censMemb[0].vlocity_ins__CensusId__c;
		insert transa3;

		Datetime yesterday = Datetime.now().addDays(-1);
		Test.setCreatedDate(transa.id, yesterday);
		Test.setCreatedDate(transa2.id, yesterday);
		Test.setCreatedDate(transa3.id, yesterday);

	}

	@IsTest
	public static void ARC_MonthlyContributionReceivedTest(){
		List<ChargentOrders__ChargentOrder__c> chargent = [SELECT Id FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];
		List<ChargentOrders__Transaction__c> transa = [SELECT Census__c,ChargentOrders__Type__c,ChargentOrders__Response_Status__c FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Response_Status__c = 'Approved' LIMIT 2];
        List<vlocity_ins__GroupCensusMember__c> censusMember = [SELECT Id,vlocity_ins__FirstName__c,vlocity_ins__ContactId__r.Email,vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
		censusMember[0].vlocity_ins__IsPrimaryMember__c = true;
		update censusMember;
		Test.startTest();
		transa[0].Census__c = censusMember[0].vlocity_ins__CensusId__c;
		update transa;
        ARC_TransactionsBatch t = new ARC_TransactionsBatch();
        Database.executeBatch(t);
		Test.stopTest();
	}

	@isTest
	public static void ARC_MonthlyContributionDeclinedTest(){
		List<ChargentOrders__ChargentOrder__c> chargent2 = [SELECT Id,ChargentOrders__Payment_Method__c FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'Recurring Monthly Order' LIMIT 1];
		List<ChargentOrders__Transaction__c> transa2 = [SELECT Id,Census__c,ChargentOrders__Type__c,ChargentOrders__Response_Status__c FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Response_Status__c = 'Declined' LIMIT 1];
        List<vlocity_ins__GroupCensusMember__c> censusMember2 = [SELECT Id,vlocity_ins__FirstName__c,vlocity_ins__ContactId__r.Email,vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
		censusMember2[0].vlocity_ins__IsPrimaryMember__c = true;
		update censusMember2;
		Test.startTest();
		transa2[0].Census__c = censusMember2[0].vlocity_ins__CensusId__c;
		update transa2;
        ARC_TransactionsBatch t = new ARC_TransactionsBatch();
        Database.executeBatch(t);
		Test.stopTest();
	}

	@isTest
	public static void ARC_InitialContributionDeclinedTest(){
		List<ChargentOrders__ChargentOrder__c> chargent3 = [SELECT Id,ChargentOrders__Payment_Method__c FROM ChargentOrders__ChargentOrder__c WHERE ChargentOrders__Description__c = 'App Fee' LIMIT 1];
		List<ChargentOrders__Transaction__c> transa3 = [SELECT Census__c,ChargentOrders__Type__c,ChargentOrders__Response_Status__c FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Response_Status__c = 'Declined' AND ChargentOrders__Order__c =: chargent3[0].Id LIMIT 1];
        List<vlocity_ins__GroupCensusMember__c> censusMember3 = [SELECT Id,vlocity_ins__FirstName__c,vlocity_ins__ContactId__r.Email,vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
		censusMember3[0].vlocity_ins__IsPrimaryMember__c = true;
		update censusMember3;
		Test.startTest();
		transa3[0].Census__c = censusMember3[0].vlocity_ins__CensusId__c;
		update transa3;
        ARC_TransactionsBatch t = new ARC_TransactionsBatch();
        Database.executeBatch(t);
		Test.stopTest();
	}


}