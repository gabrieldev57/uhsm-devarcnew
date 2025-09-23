@isTest
public class ARC_ProgramChangeReportControllerTest {

    @TestSetup
    static void makeData(){
        //Create Contract
        List<Contract> cont = ARC_TestUtility.createContractsAA(2);
        //Create Census
        List<vlocity_ins__GroupCensus__c> censuses = new List<vlocity_ins__GroupCensus__c>();
        for(integer i=0;i<2; i++){
            vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
            census.Name = 'Test Census' +' ' + i;
            census.vlocity_ins__GroupId__c = cont[0].AccountId;
            censuses.add(census);
        }
        insert censuses;
        insert cont;
        
        cont[0].vlocity_ins__EnrollmentCensusId__c = censuses[0].Id;
        cont[0].Status ='Awaiting Activation';
        cont[0].ARC_EffectiveDate__c = Date.today().addMonths(1);
        cont[0].ARC_ContractReason__c = 'Add Member';
        cont[0].ARC_SingleReasonForPC__c = 'Add Member';
        update cont;
        cont[0].Status = 'Activated';
        cont[0].vlocity_ins__ExpiredContractId__c = cont[1].Id;
        update cont;
        
        //Create Product Test Data
        Product2 productParent = new Product2();
        productParent.Name = 'Parent Product';
        productParent.ProductCode = 'CS_FinanceVisitsFramework';
        productParent.vlocity_ins__Type__c = 'Medical';
        Product2 productChild = new Product2();
        productChild.Name = 'Child Product';
        productChild.ProductCode = 'CS_FinanceVisitsFramework';
        productChild.vlocity_ins__AttributeDefaultValues__c = '{"Urgent_Care_Visitations":"No Max","Urgent_Care_Consult_Fee":50,"Minute_Clinic":"$10 / No Maximum on Visits Allowed","Specialist_Visits":"No Max","Specialists_Consult_Fee":75,"PCP_Visits_Allowed":"No Max","PCP_Consult_Fee":25,"PCP_Network":"PHCS PPO Network","Surgery":100,"Hospitalization":100,"ER_Care_Consult_Fee":500,"Additional_Dep_Fee":"4 or more children: +$50 per child per month","AMCS":null}';
        insert productParent;
        insert productChild;
        //Create Product child
        vlocity_ins__ProductChildItem__c coverageChild = new vlocity_ins__ProductChildItem__c();
        coverageChild.vlocity_ins__ChildLineNumber__c='1';
        coverageChild.vlocity_ins__ParentProductId__c=productParent.Id;
        coverageChild.vlocity_ins__ChildProductId__c=productChild.Id;
        insert coverageChild;     
        //Create Contract Line Items
        List<vlocity_ins__ContractLineItem__c> cli =ARC_TestUtility.createTestContractLineItem(2);
        cli[0].vlocity_ins__ContractId__c= cont[0].Id;
        cli[0].vlocity_ins__Product2Id__c = productParent.Id;
        cli[1].vlocity_ins__Product2Id__c = productParent.Id;
        cli[1].vlocity_ins__ContractId__c= cont[1].Id;
        update cli;
        
    }
    
    
    @isTest
    static void ARC_ProgramChangeReportControllerTest() {
        Test.startTest();
            ARC_ProgramChangeReportController.getContracts();
        Test.stopTest();
        //System.assertEquals(true, contractList.size()>0);
    }
}