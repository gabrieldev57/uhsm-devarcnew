@isTest
global with sharing class ARC_GenerateElegibilityFilesTest {
    
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
            elegibileFile.ARC_EmailsToNotify__c = 'integrations@uhsm.org';
            filesToInsert.add(elegibileFile);
        }
        insert filesToInsert;
        RecordType refullfilmentRecordType = [ SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_ResendMemberIdCard' AND SobjectType = 'Case' LIMIT 1 ] ;
        List<Case> caseTest = ARC_TestUtility.createTestCase(4,'Service');
        //Create Contract
        List<Contract> cont = ARC_TestUtility.createContractsUniqueAccounts(5);
        insert cont;
        
        List<ChargentOrders__ChargentOrder__c> chargentOrders = new List<ChargentOrders__ChargentOrder__c>();
        for (integer i = 0; i < 4; i++){
            ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c(
                ARC_Contract__c = cont[i].Id,
                ChargentOrders__Shipping__c = 194.2,
                ChargentOrders__Tax__c = 194.2,
                ChargentOrders__Charge_Amount__c = 194.2,
                ChargentOrders__Subtotal__c = 194.2,
                ChargentOrders__Charge_Date__c = '01',
                ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3),
                ChargentOrders__Payment_Status__c = 'Recurring',
                ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12),
                ChargentOrders__Payment_Method__c = 'Credit Card',
                ChargentOrders__Card_Last_4__c = '1234',
                ChargentOrders__Card_Type__c = 'VISA',
                ChargentOrders__Card_Expiration_Month__c = '12',
                ChargentOrders__Card_Month_Indicator__c = '12',
                ChargentOrders__Card_Expiration_Year__c = '2024',
                ChargentOrders__Card_Year_Indicator__c = '2024',
                ChargentOrders__Description__c = 'Recurring Monthly Order',
                ChargentOrders__Tokenization__c = '504939913-507845985'                
            );
            chargentOrders.add(chargent);
        }
        insert chargentOrders;
        
        List<ChargentOrders__Transaction__c> transactions = new List<ChargentOrders__Transaction__c>();
        for (integer i=0;i<4;i++){
            ChargentOrders__Transaction__c changTrans = new ChargentOrders__Transaction__c();
            changTrans.ChargentOrders__Type__c = 'Charge';
            changTrans.ChargentOrders__Response_Status__c = 'Approved';
            changTrans.ChargentOrders__Order__c = chargentOrders[i].Id;
            changTrans.ChargentOrders__Amount__c = chargentOrders[i].ChargentOrders__Charge_Amount__c;
            changTrans.ChargentOrders__Gateway_Date__c = System.today();
            changTrans.ARC_Reason__c = 'New Application';
            transactions.add(changTrans);
        }        
        insert transactions;
        
        //Create Census
        List<vlocity_ins__GroupCensus__c> censuses = new List<vlocity_ins__GroupCensus__c>();
        for(integer i=0; i<4; i++){
            vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
            census.Name = 'Test Census' +' ' + string.valueof(i);
            census.vlocity_ins__GroupId__c = cont[i].AccountId;
            censuses.add(census);
        }
        insert censuses;
		
        System.debug('--------------------------------------');
        System.debug('censuses size: '+censuses.size());
        System.debug('cont size: '+cont.size());
        System.debug('chargentOrders size: '+chargentOrders.size());
        System.debug('caseTest size: '+caseTest.size());
        System.debug('--------------------------------------');
        
        //Set Contract Data
        for (integer i=0;i<4;i++){
            System.debug('Contract id: '+cont[i].id);
            cont[i].vlocity_ins__EnrollmentCensusId__c = censuses[i].Id;
            cont[i].Status ='Awaiting Activation';
            cont[i].ARC_Case__c = caseTest[i].Id;
            cont[i].ARC_EffectiveDate__c = Date.today().addMonths(-1);
            cont[i].ARC_AwaitingActivationDate__c = Datetime.now().addMonths(-1);
            cont[i].ARC_ContractReason__c = 'Add Member';
            cont[i].ARC_SingleReasonForPC__c = 'Add Member';
            cont[i].ARC_RecurringMonthlyOrder__c = chargentOrders[i].Id;
            cont[i].vlocity_ins__LastDocuSignEnvelopeId__c = 'eligibilityfiletestdata';
        }
        update cont;
        
        //Activate Contracts
        for (integer i=0;i<3;i++){
            cont[i].Status = 'Activated';
            update cont[i];
        }
        
        
        //Create Product Test Data
        Product2 productParent = new Product2();
        productParent.Name = 'Parent Product';
        productParent.ProductCode = 'CS_General';
        productParent.vlocity_ins__Type__c = 'Medical';
        insert productParent;
        
        //Create Product Test Data
        Product2 smartProduct = new Product2();
        smartProduct.Name = 'SMART Share 50000';
        smartProduct.ProductCode = 'PROG_SMART_50000-1';
        smartProduct.vlocity_ins__Type__c = 'Ancillary';
        insert smartProduct;
        
        //Create Product Test Data
        Product2 aiddProduct = new Product2();
        aiddProduct.Name = 'AIDD 7500';
        aiddProduct.ProductCode = 'PROG_AIDD_7500-1';
        aiddProduct.vlocity_ins__Type__c = 'Ancillary';
        insert aiddProduct;
        
        //Create Product child
        Product2 productChild = new Product2();
        productChild.Name = 'Child Product';
        productChild.ProductCode = 'CS_General';
        productChild.vlocity_ins__AttributeDefaultValues__c = '{"Urgent_Care_Visitations":"No Max","Urgent_Care_Consult_Fee":50,"Minute_Clinic":"$10 / No Maximum on Visits Allowed","Specialist_Visits":"No Max","Specialists_Consult_Fee":75,"PCP_Visits_Allowed":"No Max","PCP_Consult_Fee":25,"PCP_Network":"PHCS PPO Network","Surgery":100,"Hospitalization":100,"ER_Care_Consult_Fee":500,"Additional_Dep_Fee":"4 or more children: +$50 per child per month","AMCS":5000}'; 
        insert productChild;        
        
        vlocity_ins__ProductChildItem__c coverageChild = new vlocity_ins__ProductChildItem__c();
        coverageChild.vlocity_ins__ChildLineNumber__c='1';
        coverageChild.vlocity_ins__ParentProductId__c=productParent.Id;
        coverageChild.vlocity_ins__ChildProductId__c=productChild.Id;
        insert coverageChild;
        
        //Create WeShare Test Product
        Product2 weshareProduct = new Product2();
        weshareProduct.Name = 'WeShare Product';
        weshareProduct.ProductCode = 'WeShare Test';
        weshareProduct.vlocity_ins__Type__c = 'Medical';
        insert weshareProduct;
        
        vlocity_ins__ProductChildItem__c coverageChild2 = new vlocity_ins__ProductChildItem__c();
        coverageChild2.vlocity_ins__ChildLineNumber__c='1';
        coverageChild2.vlocity_ins__ParentProductId__c=weshareProduct.Id;
        coverageChild2.vlocity_ins__ChildProductId__c=productChild.Id;
        insert coverageChild2;
        
        //Create Access Product
        Product2 accessProduct = new Product2();
        accessProduct.Name = 'Access TestProduct';
        accessProduct.ProductCode = 'Access_TestProduct';
        accessProduct.vlocity_ins__Type__c = 'Medical';
        insert accessProduct;
        
        vlocity_ins__ProductChildItem__c coverageChild3 = new vlocity_ins__ProductChildItem__c();
        coverageChild3.vlocity_ins__ChildLineNumber__c='1';
        coverageChild3.vlocity_ins__ParentProductId__c=accessProduct.Id;
        coverageChild3.vlocity_ins__ChildProductId__c=productChild.Id;
        insert coverageChild3;
        
        //Create Legacy Product
        Product2 legacyProduct = new Product2();
        legacyProduct.Name = 'Legacy TestProduct';
        legacyProduct.ProductCode = 'WeShare_Legacy_TestProduct';
        legacyProduct.vlocity_ins__Type__c = 'Medical';
        insert legacyProduct;
        
        vlocity_ins__ProductChildItem__c coverageChild4 = new vlocity_ins__ProductChildItem__c();
        coverageChild4.vlocity_ins__ChildLineNumber__c='1';
        coverageChild4.vlocity_ins__ParentProductId__c=legacyProduct.Id;
        coverageChild4.vlocity_ins__ChildProductId__c=productChild.Id;
        insert coverageChild4;
        
        //Create Contract Line Items
        List<vlocity_ins__ContractLineItem__c> cli = ARC_TestUtility.createTestContractLineItem(7);
        cli[0].vlocity_ins__ContractId__c = cont[0].Id;
        cli[0].vlocity_ins__Product2Id__c = productParent.Id;
        cli[1].vlocity_ins__ContractId__c = cont[1].Id;
        cli[1].vlocity_ins__Product2Id__c = weshareProduct.Id;
        cli[2].vlocity_ins__ContractId__c = cont[2].Id;
        cli[2].vlocity_ins__Product2Id__c = accessProduct.Id;
        
        cli[3].vlocity_ins__ContractId__c = cont[3].Id;
        cli[3].vlocity_ins__Product2Id__c = legacyProduct.Id;
        
        cli[4].vlocity_ins__ContractId__c = cont[0].Id;
        cli[4].vlocity_ins__Product2Id__c = smartProduct.Id;
        cli[5].vlocity_ins__ContractId__c = cont[1].Id;
        cli[5].vlocity_ins__Product2Id__c = smartProduct.Id;
        cli[6].vlocity_ins__ContractId__c = cont[2].Id;
        cli[6].vlocity_ins__Product2Id__c = aiddProduct.Id;
        
        update cli;

        List<vlocity_ins__GroupCensusMember__c> censusMemberList = new List<vlocity_ins__GroupCensusMember__c>();
         for (Integer i=0;i<4;i++) {
            vlocity_ins__GroupCensusMember__c cm = new vlocity_ins__GroupCensusMember__c();
			cm.Name = 'Test CensusMember1';
            cm.vlocity_ins__CensusId__c = censuses[i].Id;
            censusMemberList.add(cm);
        }
        insert censusMemberList;
        
        caseTest[3].RecordTypeId = refullfilmentRecordType.Id;
        caseTest[3].Status = 'New';
        caseTest[3].ARC_CensusMember__c = censusMemberList[3].Id;
        update caseTest[3];
              
        List<vlocity_ins__GroupCensusMemberPlan__c> gCMPList= new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for (Integer i=0;i<4;i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
            vlocity_ins__GroupCensusMemberPlan__c gcmpA = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmp.Name = 'Test Plan ' + String.valueof(i);
            gcmp.vlocity_ins__ContractLineId__c = cli[i].Id;
            gcmp.vlocity_ins__GroupCensusMemberId__c = censusMemberList[i].Id;
            gCMPList.add(gcmp);
            if (i < 3){
                gcmpA.Name = 'Test Smart '+ String.valueof(i);
                gcmpA.vlocity_ins__ContractLineId__c = cli[i+4].Id;
                gcmpA.vlocity_ins__GroupCensusMemberId__c = censusMemberList[i].Id;
	            gCMPList.add(gcmpA);
            }
        }
        insert gCMPList;
        
        //vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c (Name = 'Test CensusMember1', vlocity_ins__CensusId__c = censuses[0].Id, vlocity_ins__IsPrimaryMember__c= false, ARC_PhysicalAddressCity__c = 'New York', ARC_PhysicalAddressState__c = 'NY', ARC_PhysicalAddressStreet__c = '13th Street', ARC_PhysicalAddressZipCode__c = '10024');
        //insert censusMember;
        //Case refulfillmentCase = new Case(
        //    Status = 'New',
        //    RecordTypeId = ([SELECT Id, Name, DeveloperName FROM RecordType WHERE DeveloperName = 'ARC_ResendMemberIdCard' LIMIT 1]).Id,
        //    ARC_CensusMember__c = censusMember.Id
        //);
        //insert refulfillmentCase;
    }
    
    @isTest
    static void ARC_UHSMFulfillmentTest() {
        
        List<Contract> contList = [SELECT Id,ARC_EffectiveDate__c,vlocity_ins__EnrollmentCensusId__c,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c FROM Contract];
        List<vlocity_ins__ContractLineItem__c> cli = [SELECT Id,vlocity_ins__ContractId__c,vlocity_ins__Product2Id__r.vlocity_ins__AttributeDefaultValues__c, vlocity_ins__Product2Id__c, vlocity_ins__ProductCode__c, vlocity_ins__Product2Id__r.ProductCode
                                                      FROM vlocity_ins__ContractLineItem__c];
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = new List<vlocity_ins__GroupCensusMember__c>();
        
        System.debug('contList[0].vlocity_ins__EnrollmentCensusId__c: '+contList[0].vlocity_ins__EnrollmentCensusId__c);
        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c (Name = 'Test CensusMember1', vlocity_ins__CensusId__c = contList[0].vlocity_ins__EnrollmentCensusId__c, 
                                                                                                vlocity_ins__IsPrimaryMember__c= True, ARC_PhysicalAddressCity__c = 'New York', ARC_PhysicalAddressState__c = 'NY', 
                                                                                                ARC_PhysicalAddressStreet__c = '13th Street', ARC_PhysicalAddressZipCode__c = '10024');
        vlocity_ins__GroupCensusMember__c childMember = new vlocity_ins__GroupCensusMember__c (Name = 'Test ChildCensusMember', vlocity_ins__CensusId__c = contList[0].vlocity_ins__EnrollmentCensusId__c, 
                                                                                               vlocity_ins__IsPrimaryMember__c= False, ARC_PhysicalAddressCity__c = 'New York', ARC_PhysicalAddressState__c = 'NY', 
                                                                                               ARC_PhysicalAddressStreet__c = '13th Street', ARC_PhysicalAddressZipCode__c = '10024');
		insert censusMember;
        insert childMember;
        censusMemberList.add(censusMember);
        censusMemberList.add(childMember);
        
        List<vlocity_ins__ProductChildItem__c> products = [SELECT vlocity_ins__ChildProductId__c, vlocity_ins__ParentProductId__c FROM vlocity_ins__ProductChildItem__c];
        Map<String,String> coverage_product = new Map<String,String>();
        String financeVisitCoverage = '1000';
        for(vlocity_ins__ProductChildItem__c product :products){
            coverage_product.put(String.valueOf(product.vlocity_ins__ChildProductId__c),String.valueOf(product.vlocity_ins__ParentProductId__c));
        }
        
        Test.startTest();
        	ARC_UHSMFulfillment.generate('', contList[0], cli[0],censusMemberList,'','',financeVisitCoverage);
        Test.stopTest();        
    }
    

    
    @isTest
    static void ARC_ElegibilityFileSureCoTest() {
       
        Contract cont = [SELECT Id,vlocity_ins__EnrollmentCensusId__c,ARC_Inactive_Date__c,vlocity_ins__EnrollmentEndDate__c,CreatedDate,ARC_EffectiveDate__c,ContractNumber,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c 
                         FROM Contract LIMIT 1];
        cont.ARC_CancellationReason__c = 'Health Issues';
        cont.ARC_OtherCancellationReason__c = 'Other Health Issues';
        cont.Status = 'Activated';
        update cont;
        
        Product2 prod2 = [SELECT Id, Name, ProductCode FROM Product2 WHERE Name = 'Parent Product' LIMIT 1];
        
        String stringTXT = '';
        
        ChargentOrders__ChargentOrder__c changOrd = new ChargentOrders__ChargentOrder__c();
        insert changOrd;
        
        Map<Id, Datetime> dateMap = new Map<Id, Datetime>();
        
        Boolean futureCancellation = true;
        DateTime contractApprovedDate = system.today();
        DateTime lastPayment= contractApprovedDate.addMonths(6);
        
        vlocity_ins__ContractLineItem__c cliObj = [SELECT Id,vlocity_ins__ContractId__c, vlocity_ins__Product2Id__c, vlocity_ins__ProductCode__c 
                                                   FROM vlocity_ins__ContractLineItem__c LIMIT 1];
                
        List<vlocity_ins__GroupCensusMember__c> member = ARC_TestUtility.createTestCensusMember(1);
        member[0].vlocity_ins__IsPrimaryMember__c = true;
        member[0].ARC_ActiveMember__c = true;
        cont.vlocity_ins__EnrollmentCensusId__c =  member[0].vlocity_ins__CensusId__c;
        update cont;
        Map<Id, Set<Id>> contractMemberIds = new Map<Id, Set<Id>>();
        contractMemberIds.put(cont.Id, new Set<Id>{member[0].Id});
		test.startTest();
        
        ARC_ElegibilityFileSureCo.generate(stringTXT,cont, cliObj,member,futureCancellation,contractApprovedDate,lastPayment,changOrd,dateMap, new InsurancePolicy(Name = '2022101200000008'), contractMemberIds, new Map<Id, Map<String, Object>>());
		
		test.stopTest();        
    }
     
    @isTest
    static void ARC_SureCoElegibilityFileBatchTest() {  
        ChargentOrders__ChargentOrder__c changOrd = new ChargentOrders__ChargentOrder__c();
        insert changOrd; 
        
        ChargentOrders__Transaction__c changTrans = new ChargentOrders__Transaction__c();
        changTrans.ChargentOrders__Type__c = 'Charge';
        changTrans.ChargentOrders__Order__c = changOrd.Id;
                changTrans.ARC_Reason__c = 'New Application';

        insert changTrans;
        
        vlocity_ins__GroupCensus__c census = [SELECT Id, Name FROM vlocity_ins__GroupCensus__c WHERE Name = 'Test Census 0' LIMIT 1];
        System.debug(census);
        vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c();
        member.vlocity_ins__IsPrimaryMember__c = true;
        member.ARC_ActiveMember__c = true;
        member.vlocity_ins__CensusId__c = census.Id;
        insert member;
        
        
        Contract cont = [SELECT Id,ARC_AwaitingActivationDate__c, vlocity_ins__EnrollmentCensusId__c,CreatedDate,ARC_EffectiveDate__c,ContractNumber,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c 
                         FROM Contract LIMIT 1];
		System.debug(cont.Status);
		System.debug(cont.ARC_AwaitingActivationDate__c);
        cont.ARC_RecurringMonthlyOrder__c = changOrd.Id;
        cont.vlocity_ins__EnrollmentCensusId__c = census.Id;
        update cont;
		System.debug(cont.vlocity_ins__EnrollmentCensusId__c);
        
        changOrd.ARC_Contract__c = cont.Id;
        update changOrd;

        vlocity_ins__ContractLineItem__c cliObj = [SELECT Id,vlocity_ins__ContractId__c, vlocity_ins__Product2Id__c, vlocity_ins__ProductCode__c FROM vlocity_ins__ContractLineItem__c LIMIT 1];
        vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c(
            vlocity_ins__ContractLineId__c = cliObj.Id,
            vlocity_ins__GroupCensusMemberId__c = member.Id
        );
        insert gcmp;
	    test.startTest();
            ARC_SureCoElegibilityFileBatch t = new ARC_SureCoElegibilityFileBatch();
            Database.executeBatch(t);
        test.stopTest();                
    }

        @isTest
    static void ARC_SureCoElegibilityFileBatchTestFullData() {  
        ChargentOrders__ChargentOrder__c changOrd = new ChargentOrders__ChargentOrder__c();
        insert changOrd; 
        
        ChargentOrders__Transaction__c changTrans = new ChargentOrders__Transaction__c();
        changTrans.ChargentOrders__Type__c = 'Charge';
        changTrans.ChargentOrders__Order__c = changOrd.Id;
                changTrans.ARC_Reason__c = 'New Application';

        insert changTrans;
        
        vlocity_ins__GroupCensus__c census = [SELECT Id, Name FROM vlocity_ins__GroupCensus__c WHERE Name = 'Test Census 0' LIMIT 1];
        
        vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c();
        member.vlocity_ins__IsPrimaryMember__c = true;
        member.ARC_ActiveMember__c = true;
        member.vlocity_ins__CensusId__c = census.Id;
        insert member;
        
        
        Contract cont = [SELECT Id,vlocity_ins__EnrollmentCensusId__c,CreatedDate,ARC_EffectiveDate__c,ContractNumber,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c FROM Contract LIMIT 1];
		cont.ARC_RecurringMonthlyOrder__c = changOrd.Id;
        cont.vlocity_ins__EnrollmentCensusId__c = census.Id;
        update cont;
        
        changOrd.ARC_Contract__c = cont.Id;
        update changOrd;

	    vlocity_ins__ContractLineItem__c cliObj = [SELECT Id,vlocity_ins__ContractId__c, vlocity_ins__Product2Id__c, vlocity_ins__ProductCode__c FROM vlocity_ins__ContractLineItem__c LIMIT 1];
        vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c(
            vlocity_ins__ContractLineId__c = cliObj.Id,
            vlocity_ins__GroupCensusMemberId__c = member.Id
        );
        insert gcmp;
	    test.startTest();
            ARC_SureCoElegibilityFileBatch t = new ARC_SureCoElegibilityFileBatch(true);
            t.sendToTestSite = true;
            Database.executeBatch(t);
        test.stopTest();                
    }

    @isTest
    static void testAddMember_PTS() {
        generateDataPTS();
        // ARC_Eligible_Files__c efPriorUpdate = [SELECT Id, ARC_LastSent__c, Name FROM ARC_Eligible_Files__c ORDER BY Name ASC LIMIT 1];
        Test.startTest();
            ARC_PTSElegibilityFileBatch.runPTSBatch();
        Test.stopTest();
        
        // ARC_Eligible_Files__c efAfterUpdate = [SELECT Id, ARC_LastSent__c, Name FROM ARC_Eligible_Files__c ORDER BY Name ASC LIMIT 1];
        // System.assertEquals(true, efPriorUpdate.ARC_LastSent__c == efAfterUpdate.ARC_LastSent__c);  
    }
    
    @isTest
    static void testNewApplication_Zelis() {
        List<Contract> contList = [SELECT Id,vlocity_ins__EnrollmentCensusId__c,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c FROM Contract];
        contList[0].ARC_ContractReason__c = 'New Application';
        update contList;
        
        Test.startTest();
            Database.executeBatch(new ARC_ZelisElegibilityFileBatch());
        Test.stopTest();
    }
    
    @isTest
    static void testNewApplication_PTS() {
        List<Contract> contList = [SELECT Id,vlocity_ins__EnrollmentCensusId__c,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c FROM Contract];
        contList[0].ARC_ContractReason__c = 'New Application';
        update contList;
        generateDataPTS();
        Test.startTest();
            Database.executeBatch(new ARC_PTSElegibilityFileBatch());
        Test.stopTest();
    }
    
    @isTest
    static void ARC_GenerateElegibilityFilesTestTwo_Zelis() {
		List<Contract> contList = [SELECT Id, AccountId, ARC_EffectiveDate__c,vlocity_ins__EnrollmentCensusId__c,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c
                                  FROM Contract
                                  WHERE Status = 'Draft'
                                  LIMIT 2];	
        System.debug('ARC_GenerateElegibilityFilesTestTwo_Zelis>contList size: ' + contList.size());
        Contract contOne = contList[0];
        Contract contTwo = contList[1];

        ChargentOrders__ChargentOrder__c changOrd = new ChargentOrders__ChargentOrder__c();
        changOrd.ARC_Contract__c = contList[1].Id;
        changOrd.ARC_FirstMonthPayed__c = true;
        changOrd.ChargentOrders__Description__c = 'Recurring Monthly Order';
        changOrd.ChargentOrders__Payment_Start_Date__c = Date.today().addMonths(2);
        insert changOrd;
        contList[1].ARC_RecurringMonthlyOrder__c = changOrd.Id;
        update contList;

        contList[1].vlocity_ins__EnrollmentCensusId__c = contOne.vlocity_ins__EnrollmentCensusId__c;
        contList[1].ARC_EffectiveDate__c = Date.today().addMonths(2);
        contList[1].Status = 'Awaiting Activation';
        contList[1].ARC_ContractReason__c = 'New Application';
        contList[1].ARC_SingleReasonForPC__c = 'Add Member';
        update contList;

        //contList[1].Status = 'Activated';
        update contList[1];
        
        test.startTest();
            Database.executeBatch(new ARC_ZelisElegibilityFileBatch());
        test.stopTest();
    }
    
    @isTest
    static void ARC_GenerateElegibilityFilesTestTwo_PTS() {
		generateDataPTS();
        
        test.startTest();
            Database.executeBatch(new ARC_PTSElegibilityFileBatch());
            //Database.executeBatch(new ARC_PTSFileBatch());
        test.stopTest();
    }
    
    @isTest
    static void ARC_ANSI834_PTS() {   
        List<Contract> contList = [SELECT Id, AccountId, ARC_EffectiveDate__c,vlocity_ins__EnrollmentCensusId__c,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c 
                                   FROM Contract
                                   WHERE vlocity_ins__LastDocuSignEnvelopeId__c LIKE 'eligibilityfiletestdata'];
        System.debug('ARC_ANSI834_PTS > contList.size: '+contList.size());

        ARC_Eligible_Files__c eligFile =  [SELECT Id, Name FROM ARC_Eligible_Files__c WHERE Name = 'Fulfillment'];
        //The below seem to not be used
        //List<Product2> plist = [SELECT Id,Name, vlocity_ins__Type__c,RecordTypeId,ProductCode FROM Product2 WHERE Name = 'Parent Product' OR Name = 'Child Product' ORDER BY Name Desc];
        //vlocity_ins__ContractLineItem__c cliOnly = [SELECT Id, vlocity_ins__ProductType__c ,vlocity_ins__ContractId__r.vlocity_ins__EnrollmentCensusId__c FROM vlocity_ins__ContractLineItem__c LIMIT 1];
        
        List <vlocity_ins__GroupCensusMember__c> censusMembers = new List <vlocity_ins__GroupCensusMember__c>();
        for(integer i=0;i<3;i++){
			vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c (Name = 'Test CensusMember1',vlocity_ins__Birthdate__c = Date.newInstance(1994,07,12),vlocity_ins__Gender__c='Female', 
                                                                                                vlocity_ins__SocialSecurityNumber__c='12345284',vlocity_ins__LastName__c='King',vlocity_ins__FirstName__c = 'Rusher',
                                                                                                ARC_ActiveMember__c = true, vlocity_ins__CensusId__c = contList[i].vlocity_ins__EnrollmentCensusId__c, 
                                                                                                vlocity_ins__IsPrimaryMember__c= True,vlocity_ins__IsSpouse__c = false ,ARC_PhysicalAddressCity__c = 'New York', 
                                                                                                ARC_PhysicalAddressState__c = 'NY', ARC_PhysicalAddressStreet__c = '13th Street', 
                                                                                                ARC_PhysicalAddressZipCode__c = '10024',ARC_Phone__c = '3244242424',vlocity_ins__Email__c = 'testemail@email.com');
        	censusMembers.add(censusMember);
        }
        insert censusMembers;
        
        vlocity_ins__GroupCensusMember__c childMember = new vlocity_ins__GroupCensusMember__c (Name = 'Child Member2',vlocity_ins__Birthdate__c = Date.newInstance(1994,07,12),vlocity_ins__Gender__c='Male', 
                                                                                                vlocity_ins__SocialSecurityNumber__c='12334284',vlocity_ins__LastName__c='King',vlocity_ins__FirstName__c = 'Burger',
                                                                                                ARC_ActiveMember__c = true, vlocity_ins__CensusId__c = contList[0].vlocity_ins__EnrollmentCensusId__c, 
                                                                                                vlocity_ins__IsPrimaryMember__c= True,vlocity_ins__IsSpouse__c = false ,ARC_PhysicalAddressCity__c = 'New York', 
                                                                                                ARC_PhysicalAddressState__c = 'NY', ARC_PhysicalAddressStreet__c = '13th Street', 
                                                                                                ARC_PhysicalAddressZipCode__c = '10024',ARC_Phone__c = '3244242424',vlocity_ins__Email__c = 'testemail@email.com');
       	insert childMember;
        
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = new List<vlocity_ins__GroupCensusMember__c>();
        censusMemberList.add(censusMembers[0]);
        censusMemberList.add(childMember);
        /*    Testing this:
         *     refullfilmentRecordType = [ SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_ResendMemberIdCard' AND SobjectType = 'Case' LIMIT 1 ] ;
         *     List<Case> refulfillmentCases = [ 
         *     SELECT Id, ARC_CensusMember__r.vlocity_ins__CensusId__c, ARC_WelcomeKit__c
         *     FROM Case 
         *     WHERE Status = 'New' AND 
         *     RecordTypeId = :refullfilmentRecordType.Id
    	 *     ];
         */
        List<Case> cases = [SELECT Id FROM Case Where Subject = 'Test' LIMIT 3];

        for(integer i=0;i<3;i++){
            ARC_UnderwritingCaseMember__c uwCaseMem = new ARC_UnderwritingCaseMember__c();
            uwCaseMem.ARC_UnderwritingCase__c = cases[i].Id;
            uwCaseMem.ARC_Member__c = censusMembers[i].Id;
            uwCaseMem.ARC_Contract__c = contList[i].Id;
            uwCaseMem.ARC_ApprovalResolution__c = 'Approved';
            insert uwCaseMem;
        }
        
        RecordType refulfillmentRecordType = [SELECT Id, Name, DeveloperName FROM RecordType WHERE DeveloperName = 'ARC_ResendMemberIdCard' LIMIT 1];
        RecordType dentalRecordType = [SELECT Id, Name, DeveloperName FROM RecordType WHERE DeveloperName = 'ARC_ResendDentalCard' LIMIT 1];
        
        List<Case> refulfillmentCases = New List<Case>();
        for(integer i=0;i<3;i++){
            Case refulfillmentCase = new Case(
                Status = 'New',
                RecordTypeId = refulfillmentRecordType.Id,
                ARC_CensusMember__c = censusMembers[i].Id,
                Subject = 'Test',
                Description = 'Test'
        	);
            refulfillmentCases.add(refulfillmentCase);
        	
        }
        insert refulfillmentCases;
        
        Task openTask = new Task(
        	WhatId = refulfillmentCases[0].Id,
            Subject = 'test task',
            Status = 'Not Started'
        	);
        insert openTask;
        
        Case dentalCase = new Case(
            Status = 'New',
            RecordTypeId = dentalRecordType.Id,
            ARC_CensusMember__c = censusMembers[0].Id,
            Subject = 'Test',
            Description = 'Test'
        );
        insert dentalCase;
        
        List <ChargentOrders__ChargentOrder__c> orders = new List <ChargentOrders__ChargentOrder__c>();
        for(integer i=0;i<3;i++){
            ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c(
                ARC_Contract__c = contList[i].Id,
                ChargentOrders__Shipping__c = 194.2,
                ChargentOrders__Tax__c = 194.2,
                ChargentOrders__Charge_Amount__c = 194.2,
                ChargentOrders__Subtotal__c = 194.2,
                ChargentOrders__Charge_Date__c = '01',
                ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3),
                ChargentOrders__Payment_Status__c = 'Recurring',
                ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12),
                ChargentOrders__Payment_Method__c = 'Credit Card',
                ChargentOrders__Card_Last_4__c = '1234',
                ChargentOrders__Card_Type__c = 'VISA',
                ChargentOrders__Card_Expiration_Month__c = '12',
                ChargentOrders__Card_Month_Indicator__c = '12',
                ChargentOrders__Card_Expiration_Year__c = '2024',
                ChargentOrders__Card_Year_Indicator__c = '2024',
                ChargentOrders__Description__c = 'Recurring Monthly Order',
                ChargentOrders__Tokenization__c = '504939913-507845985'
            );
            orders.add(chargent);
        }
        insert orders;

        List<ChargentOrders__Transaction__c> transactionsToInsert = new List<ChargentOrders__Transaction__c>(); 
        
        for(integer i=0;i<3;i++){
            ChargentOrders__Transaction__c changTrans = new ChargentOrders__Transaction__c();
            changTrans.ChargentOrders__Type__c = 'Charge';
            changTrans.ChargentOrders__Response_Status__c = 'Approved';
            changTrans.ChargentOrders__Order__c = orders[i].Id;
            changTrans.ChargentOrders__Amount__c =  orders[i].ChargentOrders__Charge_Amount__c;
            changTrans.ChargentOrders__Gateway_Date__c = System.today();
            changTrans.ARC_Reason__c = 'New Application';
            transactionsToInsert.add(changTrans);
        }
        insert transactionsToInsert;
        
        Test.startTest();
            Database.executeBatch(new ARC_PTSElegibilityFileBatch());
        Test.stopTest();        
    }
    @isTest
    static void testAddMember_Zelis() {
        // ARC_Eligible_Files__c efPriorUpdate = [SELECT Id, ARC_LastSent__c, Name FROM ARC_Eligible_Files__c ORDER BY Name ASC LIMIT 1];
        Test.startTest();
            Database.executeBatch(new ARC_ZelisElegibilityFileBatch());
        Test.stopTest();
        
        // ARC_Eligible_Files__c efAfterUpdate = [SELECT Id, ARC_LastSent__c, Name FROM ARC_Eligible_Files__c ORDER BY Name ASC LIMIT 1];
        // System.assertEquals(true, efPriorUpdate.ARC_LastSent__c == efAfterUpdate.ARC_LastSent__c);  
    }
        @isTest
    static void ARC_ANSI834_Zelis() {
        
        List<Contract> contList = [SELECT Id, AccountId, ARC_EffectiveDate__c,vlocity_ins__EnrollmentCensusId__c,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c FROM Contract];
        ARC_Eligible_Files__c eligFile =  [SELECT Id, Name FROM ARC_Eligible_Files__c WHERE Name  = 'Fulfillment'];
        List<Product2> plist = [SELECT Id,Name, vlocity_ins__Type__c,RecordTypeId,ProductCode FROM Product2 WHERE Name = 'Parent Product' OR Name = 'Child Product' ORDER BY Name Desc];
        
        vlocity_ins__ContractLineItem__c cliOnly = [SELECT Id, vlocity_ins__ProductType__c ,vlocity_ins__ContractId__r.vlocity_ins__EnrollmentCensusId__c FROM vlocity_ins__ContractLineItem__c LIMIT 1];
        
		vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c (Name = 'Test CensusMember1',vlocity_ins__Birthdate__c = Date.newInstance(1994,07,12),vlocity_ins__Gender__c='Female', 
                                                                                                vlocity_ins__SocialSecurityNumber__c='12345284',vlocity_ins__LastName__c='King',vlocity_ins__FirstName__c = 'Rusher',
                                                                                                ARC_ActiveMember__c = true, vlocity_ins__CensusId__c = contList[0].vlocity_ins__EnrollmentCensusId__c, 
                                                                                                vlocity_ins__IsPrimaryMember__c= True,vlocity_ins__IsSpouse__c = false ,ARC_PhysicalAddressCity__c = 'New York', 
                                                                                                ARC_PhysicalAddressState__c = 'NY', ARC_PhysicalAddressStreet__c = '13th Street', 
                                                                                                ARC_PhysicalAddressZipCode__c = '10024',ARC_Phone__c = '3244242424',vlocity_ins__Email__c = 'testemail@email.com');
       	insert censusMember;
        
        vlocity_ins__GroupCensusMember__c childMember = new vlocity_ins__GroupCensusMember__c (Name = 'Child Member2',vlocity_ins__Birthdate__c = Date.newInstance(1994,07,12),vlocity_ins__Gender__c='Male', 
                                                                                                vlocity_ins__SocialSecurityNumber__c='12334284',vlocity_ins__LastName__c='King',vlocity_ins__FirstName__c = 'Burger',
                                                                                                ARC_ActiveMember__c = true, vlocity_ins__CensusId__c = contList[0].vlocity_ins__EnrollmentCensusId__c, 
                                                                                                vlocity_ins__IsPrimaryMember__c= True,vlocity_ins__IsSpouse__c = false ,ARC_PhysicalAddressCity__c = 'New York', 
                                                                                                ARC_PhysicalAddressState__c = 'NY', ARC_PhysicalAddressStreet__c = '13th Street', 
                                                                                                ARC_PhysicalAddressZipCode__c = '10024',ARC_Phone__c = '3244242424',vlocity_ins__Email__c = 'testemail@email.com');
       	insert childMember;
        
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = new List<vlocity_ins__GroupCensusMember__c>();
        censusMemberList.add(censusMember);
        censusMemberList.add(childMember);
        
        Case caseTest = [SELECT Id FROM Case LIMIT 1];
        ARC_UnderwritingCaseMember__c uwCaseMem = new ARC_UnderwritingCaseMember__c();
        uwCaseMem.ARC_UnderwritingCase__c = caseTest.Id;
        uwCaseMem.ARC_Member__c = censusMember.Id;
        uwCaseMem.ARC_Contract__c = contList[0].Id;
        uwCaseMem.ARC_ApprovalResolution__c = 'Approved';
        insert uwCaseMem;        
        
        ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = contList[0].Id,
            ChargentOrders__Shipping__c = 194.2,
            ChargentOrders__Tax__c = 194.2,
            ChargentOrders__Charge_Amount__c = 194.2,
            ChargentOrders__Subtotal__c = 194.2,
            ChargentOrders__Charge_Date__c = '01',
            ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3),
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12),
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Last_4__c = '1234',
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Expiration_Month__c = '12',
            ChargentOrders__Card_Month_Indicator__c = '12',
            ChargentOrders__Card_Expiration_Year__c = '2024',
            ChargentOrders__Card_Year_Indicator__c = '2024',
            ChargentOrders__Description__c = 'Recurring Monthly Order',
            ChargentOrders__Tokenization__c = '504939913-507845985'
        );
        insert chargent;
        
        ChargentOrders__Transaction__c changTrans = new ChargentOrders__Transaction__c();
        changTrans.ChargentOrders__Type__c = 'Charge';
        changTrans.ChargentOrders__Response_Status__c = 'Approved';
        changTrans.ChargentOrders__Order__c = chargent.Id;
        changTrans.ChargentOrders__Amount__c = chargent.ChargentOrders__Charge_Amount__c;
        changTrans.ChargentOrders__Gateway_Date__c = System.today();
        changTrans.ARC_Reason__c = 'New Application';
        insert changTrans;
        
        Test.startTest();
            Database.executeBatch(new ARC_ZelisElegibilityFileBatch());
        Test.stopTest();        
    }

    public static String randomEmail(){
        String orgId = UserInfo.getOrganizationId();  
        String dateString = '';
        String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');  
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));  
        String uniqueName = orgId + dateString + randomInt;  
        String email = uniqueName + '@test' + orgId + '.org';  
        return email;  
    }

    private static void generateDataPTS(){
        Contract cont = [SELECT Id,vlocity_ins__EnrollmentCensusId__c,CreatedDate,ARC_EffectiveDate__c,ContractNumber,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c FROM Contract LIMIT 1];
        ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = cont.Id,
            ChargentOrders__Shipping__c = 194.2,
            ChargentOrders__Tax__c = 194.2,
            ChargentOrders__Charge_Amount__c = 194.2,
            ChargentOrders__Subtotal__c = 194.2,
            ChargentOrders__Charge_Date__c = '01',
            ChargentOrders__Next_Transaction_Date__c = System.today().addDays(3),
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Start_Date__c = Date.newInstance(2022, 11, 12),
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Last_4__c = '1234',
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Expiration_Month__c = '12',
            ChargentOrders__Card_Month_Indicator__c = '12',
            ChargentOrders__Card_Expiration_Year__c = '2024',
            ChargentOrders__Card_Year_Indicator__c = '2024',
            ChargentOrders__Description__c = 'Recurring Monthly Order',
            ChargentOrders__Tokenization__c = '504939913-507845985'
        );
        insert chargent;
        cont.ARC_RecurringMonthlyOrder__c = chargent.Id;
        update cont;
        ChargentOrders__Transaction__c changTrans = new ChargentOrders__Transaction__c();
        changTrans.ChargentOrders__Type__c = 'Charge';
        changTrans.ChargentOrders__Response_Status__c = 'Approved';
        changTrans.ChargentOrders__Order__c = chargent.Id;
        changTrans.ChargentOrders__Amount__c = chargent.ChargentOrders__Charge_Amount__c;
        changTrans.ChargentOrders__Gateway_Date__c = System.today();
        changTrans.ARC_Reason__c = 'New Application';
        
        insert changTrans;
    }

    @isTest
    static void ARC_QueableSendFileBatchTest(){

        ARC_QueableSendFileBatch sendJobCVSFirst = new ARC_QueableSendFileBatch('Test text', 'testname', 'CVS', true, true, false,1);
        ARC_QueableSendFileBatch sendJobCVSMiddle = new ARC_QueableSendFileBatch('Test text', 'testname', 'CVS', true, false, false,1);
        ARC_QueableSendFileBatch sendJobCVSFinish = new ARC_QueableSendFileBatch('Test text', 'testname', 'CVS', true, false, true,1);
        ARC_QueableSendFileBatch sendJobEligibility = new ARC_QueableSendFileBatch('Test text', 'testname', 'Eligibility', 1);
        ARC_QueableSendFileBatch sendJobQwikPay = new ARC_QueableSendFileBatch('Test text', 'testname','QwikPay', true, false, 'test', 'test', 'test');

        

        test.startTest();
        ID jobIDCVS = System.enqueueJob(sendJobCVSFirst);
        ID jobIDCVS2 = System.enqueueJob(sendJobCVSMiddle);
        ID jobIDCVS3 = System.enqueueJob(sendJobCVSFinish);
        ID jobIDEligibility = System.enqueueJob(sendJobEligibility);
        ID jobIDQwickPay = System.enqueueJob(sendJobQwikPay);
        test.stopTest();

        System.assertEquals(true, (jobIDCVS != null));
        System.assertEquals(true, (jobIDCVS2 != null));
        System.assertEquals(true, (jobIDEligibility != null));
        

    }
}