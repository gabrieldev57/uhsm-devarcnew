@isTest
public class EmailDeclineToSureCoTest {

      public testMethod static void testMethodstoSendEmail(){
       List<Contact> conta = ARC_TestUtility.createTestContact(1,'IndustriesIndividual');
		conta[0].Email = 'testEmail@email.com';
		update conta; 
			
		List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(1);
		censMemb[0].ARC_PhysicalAddressState__c = 'CA';
		censMemb[0].vlocity_ins__IsPrimaryMember__c = true;
		censMemb[0].ARC_ActiveMember__c = true;
		censMemb[0].vlocity_ins__ContactId__c = conta[0].Id; 
		censMemb[0].vlocity_ins__FirstName__c = 'TestFirstName';
		censMemb[0].vlocity_ins__Birthdate__c = Date.newInstance(2010, 11, 1);
		update censMemb;
				
		Contract cont = ARC_TestUtility.createContracts(1)[0];
		cont.vlocity_ins__EnrollmentCensusId__c = censMemb[0].vlocity_ins__CensusId__c;
		cont.ARC_EffectiveDate__c = System.today();
		insert cont;


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
		chargent.ChargentOrders__Payment_Status__c = 'Completed';
		chargent.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12);
		chargent.ChargentOrders__Payment_Method__c = 'Credit Card';
		chargent.ChargentOrders__Card_Last_4__c = '1234';
		chargent.ChargentOrders__Card_Type__c = 'VISA';
		chargent.ChargentOrders__Card_Expiration_Month__c = '12';
		chargent.ChargentOrders__Card_Month_Indicator__c = '12';
		chargent.ChargentOrders__Card_Expiration_Year__c = '2024';
		chargent.ChargentOrders__Card_Year_Indicator__c = '2024';
		chargent.ChargentOrders__Description__c = 'App Fee';
        //chargent.Most_Recent_Transaction_Created__c=TRUE;
		insert chargent;

		ChargentOrders__Transaction__c transa = new ChargentOrders__Transaction__c();
		transa.ChargentOrders__Order__c = chargent.Id;
		transa.ChargentOrders__Amount__c = 222;
        transa.ChargentOrders__Type__c = 'Charge';
		transa.ChargentOrders__Gateway_Date__c = Date.newInstance(2022, 07, 02);
		transa.ChargentOrders__Response_Status__c = 'Rejected';
        //transa.Last_Transaction_On_Order__c=true;

		insert transa;


        
        Test.startTest();  
       
        EmailDeclineToSureCo EmailDeclineToSureCo = new EmailDeclineToSureCo();
        Database.executeBatch(EmailDeclineToSureCo);
       Test.stopTest(); 
      }
}