@isTest
private class ARC_QwikPayEligibilityFileTest {
        @TestSetup
    static void makeData(){
        //Create ElibleFiless
        List<String> fileNameList = new List<String>{'SureCo', 'Fulfillment', 'ReFulfillment', 'ANSI834', 'HAX'};
        Integer fileNamesLength = fileNameList.size();
        List<ARC_Eligible_Files__c> filesToInsert = new List<ARC_Eligible_Files__c>();
        for ( Integer i = 0; i < fileNamesLength; i++ ) {
            ARC_Eligible_Files__c elegibileFile = new ARC_Eligible_Files__c();
            elegibileFile.ARC_LastSent_Datetime__c = Datetime.now().addDays(-10);
            elegibileFile.Name = fileNameList.get(i);
            elegibileFile.ARC_EmailsToNotify__c = 'test@test.com';
            filesToInsert.add(elegibileFile);
        }
        insert filesToInsert;
        
        List<Case> caseTest = ARC_TestUtility.createTestCase(1,'Service');
        //Create Contract
        List<Contract> cont = ARC_TestUtility.createContracts(2);
        
        ChargentOrders__ChargentOrder__c changOrd = new ChargentOrders__ChargentOrder__c();
        changOrd.ChargentOrders__Description__c = 'Recurring Monthly Order';
        insert changOrd; 
        
        ChargentOrders__Transaction__c changTrans = new ChargentOrders__Transaction__c();
        changTrans.ChargentOrders__Type__c = 'Charge';
        changTrans.ChargentOrders__Order__c = changOrd.Id;
        insert changTrans;
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
        cont[0].ARC_EffectiveDate__c = Date.today().addMonths(-1);
        cont[0].ARC_AwaitingActivationDate__c = Datetime.now().addMonths(-1);
        cont[0].ARC_ContractReason__c = 'Add Member';
        cont[0].ARC_SingleReasonForPC__c = 'Add Member';
        cont[0].ARC_RecurringMonthlyOrder__c = changOrd.Id;
		update cont;
        cont[0].Status = 'Activated';
        update cont;

        
        //Create Product Test Data
        Product2 productParent = new Product2();
        productParent.Name = 'Parent Product';
        productParent.ProductCode = 'CS_General';
        productParent.vlocity_ins__Type__c = 'Medical';
        Product2 productChild = new Product2();
        productChild.Name = 'Child Product';
        productChild.ProductCode = 'CS_General';
        productChild.vlocity_ins__AttributeDefaultValues__c = '{"Urgent_Care_Visitations":"No Max","Urgent_Care_Consult_Fee":50,"Minute_Clinic":"$10 / No Maximum on Visits Allowed","Specialist_Visits":"No Max","Specialists_Consult_Fee":75,"PCP_Visits_Allowed":"No Max","PCP_Consult_Fee":25,"PCP_Network":"PHCS PPO Network","Surgery":100,"Hospitalization":100,"ER_Care_Consult_Fee":500,"Additional_Dep_Fee":"4 or more children: +$50 per child per month","AMCS":5000}';
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


                vlocity_ins__GroupCensus__c census = [SELECT Id, Name FROM vlocity_ins__GroupCensus__c WHERE Name = 'Test Census 0' LIMIT 1];
        System.debug(census);
        vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c();
        member.vlocity_ins__IsPrimaryMember__c = true;
        member.ARC_ActiveMember__c = true;
        member.vlocity_ins__CensusId__c = census.Id;
        insert member;
        
        
        Contract cont1 = [SELECT Id,ARC_AwaitingActivationDate__c, vlocity_ins__EnrollmentCensusId__c,CreatedDate,ARC_EffectiveDate__c,ContractNumber,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c FROM Contract LIMIT 1];
        cont1.ARC_RecurringMonthlyOrder__c = changOrd.Id;
        cont1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        update cont1;
        
        changOrd.ARC_Contract__c = cont1.Id;
        update changOrd;

        vlocity_ins__ContractLineItem__c cliObj = [SELECT Id,vlocity_ins__ContractId__c, vlocity_ins__Product2Id__c, vlocity_ins__ProductCode__c FROM vlocity_ins__ContractLineItem__c LIMIT 1];
        vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c(
            vlocity_ins__ContractLineId__c = cliObj.Id,
            vlocity_ins__GroupCensusMemberId__c = member.Id
        );
        insert gcmp;
        
    } 
    
    @isTest
    static void testGenerateCSV() {

        Test.startTest();
        ARC_QwikPayEligibilityFile eligibilityFile = new ARC_QwikPayEligibilityFile();
        eligibilityFile.testEmail = 'a@a.com';
        Database.executeBatch(eligibilityFile);
        Test.stopTest();
    }
}