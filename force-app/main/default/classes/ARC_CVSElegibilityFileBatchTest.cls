@isTest
public class ARC_CVSElegibilityFileBatchTest {
    
    @TestSetup
    static void makeData(){
        //Create ElibleFiles
        List<String> fileNameList = new List<String>{'SureCo', 'Fulfillment', 'ReFulfillment', 'ANSI834', 'HAX'};
        Integer fileNamesLength = fileNameList.size();
        List<ARC_Eligible_Files__c> filesToInsert = new List<ARC_Eligible_Files__c>();
        for ( Integer i = 0; i < fileNamesLength; i++ ) {
            ARC_Eligible_Files__c elegibileFile = new ARC_Eligible_Files__c();
            elegibileFile.ARC_LastSent_Datetime__c = Datetime.now().addDays(-10);
            elegibileFile.Name = fileNameList.get(i);
            filesToInsert.add(elegibileFile);
        }
        insert filesToInsert;
        
        List<Case> caseTest = ARC_TestUtility.createTestCase(1,'Service');
        //Create Contract
        List<Contract> cont = ARC_TestUtility.createContractsAA(1);
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
        cont[0].ARC_Case__c = caseTest[0].Id;
        cont[0].ARC_EffectiveDate__c = Date.today().addMonths(1);
        cont[0].ARC_ContractReason__c = 'Add Member';
        cont[0].ARC_SingleReasonForPC__c = 'Add Member';
		update cont;
        cont[0].Status = 'Activated';
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
        List<vlocity_ins__ContractLineItem__c> cli =ARC_TestUtility.createTestContractLineItem(1);
        cli[0].vlocity_ins__ContractId__c= cont[0].Id;
        cli[0].vlocity_ins__Product2Id__c = productParent.Id;
        update cli;
        
    } 
    
    @isTest
    static void ARC_CVSElegibilityFileBatchMethodTest() {
       
        List<Contract> cont = [SELECT Id,vlocity_ins__EnrollmentCensusId__c,CreatedDate,ARC_EffectiveDate__c,ContractNumber,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c FROM Contract LIMIT 1];
        cont[0].ARC_CancellationReason__c = 'Health Issues';
        cont[0].ARC_OtherCancellationReason__c = 'Other Health Issues';
        update cont;
        
        Product2 prod2 = [SELECT Id, Name, ProductCode FROM Product2 WHERE Name = 'Parent Product' LIMIT 1];
        
        String stringTXT = '';
        
        ChargentOrders__ChargentOrder__c changOrd = new ChargentOrders__ChargentOrder__c();
        insert changOrd;
        
        Map<Id, Datetime> dateMap = new Map<Id, Datetime>();
        
        Boolean futureCancellation = true;
        DateTime contractApprovedDate = system.today();
        DateTime lastPayment= contractApprovedDate.addMonths(6);
        
        vlocity_ins__ContractLineItem__c cliObj = [SELECT Id,vlocity_ins__ContractId__c, vlocity_ins__Product2Id__c, vlocity_ins__ProductCode__c FROM vlocity_ins__ContractLineItem__c LIMIT 1];
                
        List<vlocity_ins__GroupCensusMember__c> member = ARC_TestUtility.createTestCensusMember(1);
        member[0].vlocity_ins__IsPrimaryMember__c = true;
        member[0].ARC_ActiveMember__c = true;
        member[0].vlocity_ins__Birthdate__c = Date.newInstance(system.today().year()-25, system.today().month(), system.today().Day());
        cont[0].vlocity_ins__EnrollmentCensusId__c =  member[0].vlocity_ins__CensusId__c;
        update cont;
        update member;

		test.startTest();
        ARC_CVSElegibilityFileBatch batchName = new ARC_CVSElegibilityFileBatch();
         DataBase.executeBatch(batchName); 
		
		test.stopTest();        

        
    }

}