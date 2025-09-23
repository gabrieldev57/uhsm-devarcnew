@isTest
global without sharing class ARC_EmailTemplatesOnDemandControllerTest {
    
    @isTest
    static void invokeMethodTest(){
        String methodName = 'getTemplateInformation';
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Contract> cont = ARC_TestUtility.createContractsAA(1);
        insert cont;
        Date oggi = Date.today();
        Integer year = System.today().year() - 65;
        List<vlocity_ins__GroupCensusMember__c> censMemb = ARC_TestUtility.createTestCensusMember(1);
        censMemb[0].ARC_ActiveMember__c = true;
        censMemb[0].vlocity_ins__IsPrimaryMember__c = true;
        censMemb[0].vlocity_ins__Birthdate__c = Date.newInstance(year, System.today().month(), System.today().day());
        update censMemb;
		cont[0].vlocity_ins__EnrollmentCensusId__c =  censMemb[0].vlocity_ins__CensusId__c;
		cont[0].ARC_EffectiveDate__c =  Date.newInstance(oggi.year(),oggi.month(),15);
        cont[0].Status = 'Activated';
		update cont;
        
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account personAcc = new Account(RecordTypeId = accRecordTypeId,
                                    FirstName = 'PersonAccount', 
                                    LastName ='Test', 
                                    Census_Member__c =censMemb[0].Id,
                                    ARC_CensusMember__pc = censMemb[0].Id,
                                    ARC_Census__c = censMemb[0].vlocity_ins__CensusId__c);
        insert personAcc;
		inputMap.put('recordId', personAcc.Id);
        inputMap.put('isInitialization', true);
        ChargentOrders__ChargentOrder__c charg = new ChargentOrders__ChargentOrder__c();
        charg.ARC_Contract__c = cont[0].Id;
        charg.ChargentOrders__Payment_Start_Date__c = system.today();
        charg.ChargentOrders__Card_Month_Indicator__c = '12';
        charg.ChargentOrders__Card_Year_Indicator__c = '29';
        charg.ChargentOrders__Payment_Status__c = 'Recurring';
        charg.ChargentOrders__Payment_Frequency__c= 'Monthly';
        insert charg;
        List<vlocity_ins__ContractLineItem__c> cli = ARC_TestUtility.createTestContractLineItem(1);
        cli[0].vlocity_ins__ContractId__c = cont[0].Id;
        update cli;
        vlocity_ins__GroupCensusMemberPlan__c censPlan = new vlocity_ins__GroupCensusMemberPlan__c(vlocity_ins__GroupCensusMemberId__c = censMemb[0].Id , vlocity_ins__ContractLineId__c = cli[0].Id);
        insert censPlan;

        Document d = new Document();
        d.Name = 'EFTForm';
        d.FolderId = [select id from folder where name = 'Shared Documents'].id;
        insert d;

        ARC_HipaaAuthorization__c hipaa = new ARC_HipaaAuthorization__c(ARC_Census__c = censMemb[0].vlocity_ins__CensusId__c, ARC_AuthorizedMember__c = censMemb[0].Id);
        insert hipaa;
        
        test.startTest();
        List<vlocity_ins__GroupCensusMember__c> cmlist = [SELECT Id, ARC_Relationship__c FROM vlocity_ins__GroupCensusMember__c];
        ARC_EmailTemplatesOnDemandController emailTemplateonDemand = new ARC_EmailTemplatesOnDemandController();
        emailTemplateonDemand.invokeMethod(methodName,inputMap,outputMap,options);
        test.stopTest();
    }

}