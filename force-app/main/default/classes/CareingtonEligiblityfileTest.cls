@isTest
global with sharing class CareingtonEligiblityfileTest {
    @TestSetup
    static void makeData(){
        Date oggi = Date.today();
        Integer year = System.today().year() - 31;
        Date birthDate = Date.newInstance(year, System.today().month(), System.today().day());
        
       // Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Individual and Family Person Account').getRecordTypeId();
       // String contactrecordTypeId= [select Id from RecordType where (Name='Standard Contact') and (SobjectType='Contact')].Id;
       String recordTypeId= [select Id from RecordType where (developername ='ARC_IFPPersonAccount') and (SobjectType='Account')].Id;
       
        //Create account
        Account account=new Account();
        account.LastName='TestAccount';
        account.RecordTypeId = recordTypeId;
        account.PersonBirthdate=birthDate;
        account.BillingPostalCode='17105';
        account.BillingState='PA';
        insert account;
		
        account=[Select id,PersonContactId from Account where id = :account.id LIMIT 1];
        
         //     //Create Contact
         Contact contactRecord = new Contact(FirstName = 'Jack', LastName = 'Sparrow', Email = 'testemailcensusmember@membertest.com');
         insert contactRecord;
 
        //Create contract
        Contract cont = new Contract(Name = 'Test', AccountId = account.id, ARC_EffectiveDate__c = Date.newInstance(2023, 10, 1));
        insert cont;

        //Create Order
        ChargentOrders__ChargentOrder__c chargent=new ChargentOrders__ChargentOrder__c();
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
	   chargent.ChargentOrders__Card_Expiration_Year__c = '2024';
	   chargent.ChargentOrders__Tokenization__c = '12345678';
       chargent.ChargentOrders__Description__c = 'Recurring Monthly Order';
    
        insert chargent;
        
        Product2 product=new Product2(Name='WeShare',vlocity_ins__Type__c='Medical',vlocity_ins__SubType__c='PPO',ProductCode='PROG_UHSM_WeShare1k');
        insert product;
        vlocity_ins__ContractLineItem__c CLI=new vlocity_ins__ContractLineItem__c(Name = 'WeShare',vlocity_ins__ContractId__c=cont.Id,vlocity_ins__Product2Id__c=product.Id);
       	insert CLI;

        cont.Status = 'Activated';
        cont.ARC_RecurringMonthlyOrder__c=chargent.Id;
        
        update cont;
        
        System.debug('PersonContactId' + account.PersonContactId );

        InsurancePolicy InsurancePolicy=new InsurancePolicy();
        InsurancePolicy.Name='test';
        InsurancePolicy.NameInsuredId=account.Id;
        InsurancePolicy.ARC_Contract__c=cont.Id;
        insert InsurancePolicy;
        
        InsurancePolicyCoverage InsurancePolicyCoverage=new InsurancePolicyCoverage();
        InsurancePolicyCoverage.vlocity_ins_fsc__Product2Id__c=product.Id;
        InsurancePolicyCoverage.InsurancePolicyId=InsurancePolicy.id;
        insert InsurancePolicyCoverage;
    
       

        InsurancePolicyParticipant InsurancePolicyParticipant=new InsurancePolicyParticipant();
        InsurancePolicyParticipant.PrimaryParticipantContactId=account.PersonContactId;
        InsurancePolicyParticipant.Role='Primary';
        InsurancePolicyParticipant.InsurancePolicyId=InsurancePolicy.Id;
        insert InsurancePolicyParticipant;

        ARC_CoverageParticipant__c coverageParticipant=new ARC_CoverageParticipant__c();
        coverageParticipant.ARC_PolicyCoverage__c=InsurancePolicyCoverage.Id;
        coverageParticipant.ARC_PolicyParticipant__c=InsurancePolicyParticipant.Id;
        coverageParticipant.ARC_Policy__c=InsurancePolicy.Id;
        insert coverageParticipant;

        System.debug('PersonContactId' + account.PersonContactId );
        Id contactId =contactRecord.id;
        Map<Id, String> seqNumMap = new Map<Id, String>();
        seqNumMap.put(account.PersonContactId, '01');
    //    String retrievedSequenceNumber = seqNumMap.get(contactId);
        System.debug('eligiblityclass careington :' + seqNumMap.keySet());
}
@isTest
    static void test(){
        String error;
        Test.startTest();
        try{
            CareingtonEligiblityFile testBatch = new CareingtonEligiblityFile();
            Database.executeBatch(testBatch);
        }catch(Exception e){
            error = e.getMessage();
        }
        Test.stopTest();
        
    }
}