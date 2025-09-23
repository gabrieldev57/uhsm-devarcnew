@isTest
public with sharing class ARC_PCAncillaryUserInputsTest {

    @TestSetup
    static void makeData(){

        ARC_TestUtility.createTestProducts(1);

        Date oggi = Date.today();
        Date effDate = Date.newInstance(2022, 08, 15);

        String Ancillary = 'Ancillary';
        Account acc = new Account(Name = 'Test');
        insert acc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;

        vlocity_ins__GroupCensusMember__c censusMem1 = new vlocity_ins__GroupCensusMember__c();
        censusMem1.Name = 'Test Census Member';
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        censusMem1.vlocity_ins__IsPrimaryMember__c = true;
        censusMem1.vlocity_ins__Email__c = 'soyunMail@cc.com'; 
        censusMem1.vlocity_ins__SocialSecurityNumber__c = '654654654';
        censusMem1.ARC_Weight__c = '120';
        censusMem1.vlocity_ins__FirstName__c = 'Member';
        censusMem1.vlocity_ins__LastName__c = 'Test Census';
        censusMem1.vlocity_ins__Birthdate__c = oggi;
        censusMem1.ARC_ActiveMember__c = true;
        // censusMem1.isNew = true;
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        insert censusMem1;
        censusMem1.vlocity_ins__MemberIdentifier__c = censusMem1.Id;
        update censusMem1;
        
        vlocity_ins__GroupCensusMember__c censusMem2 = new vlocity_ins__GroupCensusMember__c();
        censusMem2.Name = 'Test Census Member';
        censusMem2.vlocity_ins__CensusId__c = census.Id;
        censusMem2.vlocity_ins__IsPrimaryMember__c = false;
        censusMem2.ARC_DependentRelationship__c = 'Spouse';
        censusMem2.vlocity_ins__IsSpouse__c = true;
        censusMem2.vlocity_ins__Email__c = 'soyunMail@cc.com'; 
        censusMem2.vlocity_ins__SocialSecurityNumber__c = '654654654';
        censusMem2.ARC_Weight__c = '120';
        censusMem2.vlocity_ins__FirstName__c = 'Member';
        censusMem2.vlocity_ins__LastName__c = 'Test Census';
        censusMem2.vlocity_ins__Birthdate__c = oggi;
        censusMem2.ARC_ActiveMember__c = true;
        // censusMem2.isNew = true;
        censusMem2.vlocity_ins__CensusId__c = census.Id;
        insert censusMem2;
        censusMem2.vlocity_ins__MemberIdentifier__c = censusMem2.Id;
        update censusMem2;
        
        List<Contract> lCon = ARC_TestUtility.createContracts(2);
        Contract con = lCon[0];
        con.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con.Status = 'Draft';
        con.AccountId = acc.Id;
        con.ARC_EffectiveDate__c = Date.today().addDays(1);
        // con.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        upsert con;

        Contract con1 = lCon[1];
        con1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con1.Status = 'Draft';
        con1.AccountId = acc.Id;
        con1.ARC_EffectiveDate__c = Date.today().addDays(1);
        // con1.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        upsert con1;

        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c();
        order.ARC_FirstMonthPayed__c = true;
        order.ChargentOrders__Description__c = 'Recurring Monthly Order';
        order.ChargentOrders__Charge_Amount__c = 10;
        insert order;

        con.ARC_RecurringMonthlyOrder__c    = order.Id;
        con1.ARC_RecurringMonthlyOrder__c= order.Id;
        con.Status = 'Awaiting Activation';
        update con;

        con1.Status = 'Awaiting Activation';
        update con1;

        con.Status = 'Activated';
        update con;

        con1.Status = 'Activated';
        update con1;
    }

    @isTest
    public static void updateAndRepriceMultiContractsAncillary(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();              
        Map<String,Object> inputMap = generateInputForUpdateAndRepriceMultiContracts('Add Ancillary Product;Remove Member;Program Upgrade;Add Member;Remove Ancillary');

        Test.startTest();
            ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
            // testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
            testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);
            // testClass.invokeMethod('updateAndRepriceMultiContractsCase', inputMap, outputMap, options);
        Test.stopTest();
    }
    @isTest
    public static void updateAndRepriceMultiContractsCase(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();              
        Map<String,Object> inputMap = generateInputForUpdateAndRepriceMultiContractsCase('Add Ancillary Product;Remove Member;Program Upgrade;Add Member;Remove Ancillary');

        Test.startTest();
            ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
            // testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
            // testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);
            testClass.invokeMethod('updateAndRepriceMultiContractsCase', inputMap, outputMap, options);
        Test.stopTest();
    }
    @isTest
    public static void updateAndRepriceMultiContractsNoAncillary(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();              
        Map<String,Object> inputMap = generateInputForUpdateAndRepriceMultiContracts('Remove Member;Program Upgrade;Add Member');

        Test.startTest();
            ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
            // testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
            testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);
            // testClass.invokeMethod('updateAndRepriceMultiContractsCase', inputMap, outputMap, options);
        Test.stopTest();
    }
    @isTest
    public static void updateAndRepriceMultiContractsNoAncillaryKeepAIDD(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();              
        Map<String,Object> inputMap = generateInputForUpdateAndRepriceMultiContracts('Remove Member;Program Upgrade;Add Member');
        inputMap.put('showAddAncillaryChooseProductsKeepAIDD', true);

        Test.startTest();
            ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
            // testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
            testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);
            // testClass.invokeMethod('updateAndRepriceMultiContractsCase', inputMap, outputMap, options);
        Test.stopTest();
    }
    @isTest
    public static void updateAndRepriceMultiContractsAncillaryKeepAIDD(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();              
        Map<String,Object> inputMap = generateInputForUpdateAndRepriceMultiContracts('Remove Member;Program Upgrade;Add Member;Add Ancillary');
        inputMap.put('showAddAncillaryChooseProductsKeepAIDD', true);

        Test.startTest();
            ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
            // testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
            testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);
            // testClass.invokeMethod('updateAndRepriceMultiContractsCase', inputMap, outputMap, options);
        Test.stopTest();
    }
    @isTest
    public static void updateAndRepriceMultiContractsCaseAncillaryKeepAIDD(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();              
        Map<String,Object> inputMap = generateInputForUpdateAndRepriceMultiContractsCase('Remove Member;Program Upgrade;Add Member;Add Ancillary');
        inputMap.put('showAddAncillaryChooseProductsKeepAIDD', true);

        Test.startTest();
            ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
            // testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
            testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);
            // testClass.invokeMethod('updateAndRepriceMultiContractsCase', inputMap, outputMap, options);
        Test.stopTest();
    }
    @isTest
    public static void updateAndRepriceMultiContractsUpgrade(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();              
        Map<String,Object> inputMap = generateInputForUpdateAndRepriceMultiContracts('Program Upgrade');

        Test.startTest();
            ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
            // testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
            testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);
            // testClass.invokeMethod('updateAndRepriceMultiContractsCase', inputMap, outputMap, options);
        Test.stopTest();
    }

    

    @isTest
    public static void getInputForChooseProducts(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        Map<String,Object> inputMap = generateInputForChooseProducts('Add Ancillary Product;Remove Member;Program Upgrade;Add Member');
        Test.startTest();
            ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
            testClass.invokeMethod('getInputForChooseProducts', inputMap, outputMap, options);
        Test.stopTest();  
    }

    @isTest
    public static void updateAndRepriceContracts(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        Map<String,Object> inputMap = generateInputForUpdateAndRepriceContracts('Add Ancillary Product;Remove Member;Program Upgrade;Add Member');
        Test.startTest();
            ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
            testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
        Test.stopTest();  
    }




    private static Map<String,Object> generateInputForChooseProducts(String reasons){
        Map<String,Object> input = new Map<String,Object>();
        input.put('showAddAncillaryChooseProductsKeepSMART', true);
        input.put('showAddAncillaryChooseProductsKeepAIDD', false);
        input.put('removedParentWithDependents', false);
        input.put('primaryId', [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__IsPrimaryMember__c = true LIMIT 1].Id);
        input.put('primaryEmail', [SELECT vlocity_ins__Email__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__IsPrimaryMember__c = true LIMIT 1].vlocity_ins__Email__c);
        input.put('membersWithoutPrimary','');
        input.put('dependants',generateDependants([SELECT Id FROM vlocity_ins__GroupCensus__c LIMIT 1].Id));
        input.put('contractId', [SELECT Id FROM Contract LIMIT 1].Id);
        input.put('changesForContracts',generateChangesForContracts(reasons));
        input.put('CensusId', [SELECT Id FROM vlocity_ins__GroupCensus__c LIMIT 1].Id);

        return input;
    }


    private static Map<String,Object> generateInputForUpdateAndRepriceContracts(String reasons){
        Map<String,Object> input = generateInputForChooseProducts(reasons);
        input.put('EffectiveDate', '2022-08-15');
        input.put('auxSavedMembers', generateAuxSavedMembers());
        input.put('RemovedMembers', generateRemovedMembers());
        return input;
    }


    private static List<Map<String,Object>> generateDependants(String censusId){
        List<Map<String,Object>> dependants = new List<Map<String,Object>>();
        List<Product2> products = [SELECT Id FROM Product2];

        for (vlocity_ins__GroupCensusMember__c member : [SELECT Id,vlocity_ins__FirstName__c, vlocity_ins__LastName__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :censusId]) {
            Map<String,Object> dependant = new Map<String,Object>();
            List<String> pIds = new List<String>();
            dependant.put('Id', member.Id);
            dependant.put('FirstName', member.vlocity_ins__FirstName__c);
            dependant.put('LastName', member.vlocity_ins__LastName__c);
            dependant.put('Age', 23);
            for (Product2 product : products) {
                pIds.add(product.Id);
            }
            dependant.put('productsIds', pIds);
            dependants.add(dependant);
        }
        return dependants;
    }

    private static List<Map<String,Object>> generateChangesForContracts(String reasons){
        List<Map<String,Object>> changesForContracts = new List<Map<String,Object>>();
        Map<String,Object> changeForContract = new Map<String,Object>();
        changeForContract.put('SingleReasonToDisplay', reasons);
        changeForContract.put('SingleReason', reasons);
        changeForContract.put('Reason', reasons);
        changeForContract.put('caseId', null);
        changeForContract.put('censusId', [SELECT Id FROM vlocity_ins__GroupCensus__c LIMIT 1].Id);
        changeForContract.put('accountId', [SELECT Id FROM Account LIMIT 1].Id);
        changeForContract.put('ProductsToUpdate', generateSelectedProducts());
        changeForContract.put('RemovedMembers', generateRemovedMembers());
        changeForContract.put('auxSavedMembers', generateAuxSavedMembers());
        changeForContract.put('selectedProducts', generateSelectedProducts());
        changeForContract.put('EffDate', Date.today().addMonths(1));
        changeForContract.put('Id', [SELECT Id FROM Contract LIMIT 1].Id);
        changesForContracts.add(changeForContract);
        return changesForContracts;
    }

    private static List<Map<String,Object>> generateSelectedProducts(){
        List<Map<String,Object>> selectedProducts = new List<Map<String,Object>>();
        Map<String,Object> selectedProduct = new Map<String,Object>();
        selectedProduct.put('displaySequence', -1);
        selectedProduct.put('Id',[SELECT Id FROM Product2 LIMIT 1].Id);
        selectedProduct.put('Name', 'UHSM Vital $10K');
        selectedProduct.put('ProductCode', 'PROG_UHSMVital');
        selectedProduct.put('MarketSegment__c', 'Individual');
        selectedProduct.put('Type__c', 'Medical');
        selectedProduct.put('SubType__c', 'HMO');
        selectedProduct.put('IsRecommended__c', false);
        selectedProduct.put('PricingSource__c', 'Price');
        selectedProduct.put('RecordTypeName__c', 'Product');
        selectedProduct.put('IsConfigurable__c', false);
        selectedProduct.put('PricingFormula__c', 'Price');
        selectedProduct.put('productId', [SELECT Id FROM Product2 LIMIT 1].Id);
        selectedProduct.put('currencyCode', 'USD');
        selectedProduct.put('currencySymbol', '$');
        selectedProduct.put('Price', 614.61);
        selectedProducts.add(selectedProduct);

        // Map<String,Object> selectedProductSMART = new Map<String,Object>();
        // selectedProduct.put('displaySequence', -1);
        // selectedProduct.put('Id', [SELECT Id FROM Product2][1].Id);
        // selectedProduct.put('Name', 'UHSM Vital $10K');
        // selectedProduct.put('ProductCode', 'PROG_UHSMVital');
        // selectedProduct.put('MarketSegment__c', 'Individual');
        // selectedProduct.put('Type__c', 'SMART');
        // selectedProduct.put('SubType__c', 'HMO');
        // selectedProduct.put('IsRecommended__c', false);
        // selectedProduct.put('PricingSource__c', 'Price');
        // selectedProduct.put('RecordTypeName__c', 'Product');
        // selectedProduct.put('IsConfigurable__c', false);
        // selectedProduct.put('PricingFormula__c', 'Price');
        // selectedProduct.put('productId', [SELECT Id FROM Product2][1].Id);
        // selectedProduct.put('currencyCode', 'USD');
        // selectedProduct.put('currencySymbol', '$');
        // selectedProduct.put('Price', 614.61);
        // selectedProducts.add(selectedProductSMART);
        return selectedProducts;
    }

    private static List<Map<String,Object>> generateAuxSavedMembers(){
        List<Map<String,Object>> auxSavedMembers = new List<Map<String,Object>>();
        for (vlocity_ins__GroupCensusMember__c member : [SELECT Id,vlocity_ins__IsPrimaryMember__c FROM vlocity_ins__GroupCensusMember__c]) {
            Map<String,Object> auxSavedMember = new Map<String,Object>();
            auxSavedMember.put('Id', member.Id);
            auxSavedMember.put('ARC_isPregnant__c', false);
            auxSavedMember.put('ARC_ActiveMember__c', true);
            auxSavedMember.put('ARC_Phone__c', '+11234567890');
            auxSavedMember.put('ARC_HeightInches__c', '11');
            auxSavedMember.put('ARC_HeightFeet__c', '11');
            auxSavedMember.put('ARC_Weight__c', '11');
            auxSavedMember.put('ARC_Smoker__c', false);
            auxSavedMember.put('ARC_MiddleInitial__c', null);
            auxSavedMember.put('isNew', true);
            
            auxSavedMember.put('ARC_UseParentAddress__c', false);
            auxSavedMember.put('ARC_PhysicalAddressZipCode__c', '12345');
            auxSavedMember.put('ARC_PhysicalAddressStreet__c', '1234 Zombie Road');
            auxSavedMember.put('ARC_PhysicalAddressState__c', 'OH');
            auxSavedMember.put('ARC_PhysicalAddressCity__c', 'Racoon City');
            auxSavedMember.put('ARC_DependentRelationship__c', null);
            auxSavedMember.put('vlocity_ins__SocialSecurityNumber__c', '111111111');
            auxSavedMember.put('vlocity_ins__PrimaryMemberIdentifier__c', null);
            auxSavedMember.put('vlocity_ins__MemberIdentifier__c', member.Id);
            auxSavedMember.put('vlocity_ins__LastName__c', 'Kennedy');
            auxSavedMember.put('vlocity_ins__IsSpouse__c', false);
            auxSavedMember.put('vlocity_ins__IsPrimaryMember__c', member.vlocity_ins__IsPrimaryMember__c);
            auxSavedMember.put('vlocity_ins__HasSpouse__c', true);
            auxSavedMembers.add(auxSavedMember);
        }
        return auxSavedMembers;
    }

    private static List<Map<String,Object>> generateRemovedMembers(){
        List<Map<String,Object>> removedMembers = new List<Map<String,Object>>();
        
        // Create removed member 1
        Map<String,Object> removedMember1 = new Map<String,Object>();
        removedMember1.put('TXT_Birthdate', '1992-08-05');
        removedMember1.put('NUM_Age', 31);
        removedMember1.put('Email', 'susan@rik.com');
        removedMember1.put('CensusMemberIdentifier', '2023-08-28T16:20:16.863Z');
        removedMember1.put('CHK_isPrimary', true);
        removedMember1.put('CHK_IsMinor', false);
        removedMember1.put('CHK_Delete', true);
        removedMember1.put('FRML_primarySelected', true);
        removedMember1.put('FRML_nonPrimarySelected', false);
        removedMember1.put('FRML_MinorUnselected', false);
        removedMember1.put('TXT_Relationships', 'Spouse');
        removedMember1.put('TXT_LastNameEB', 'Rik');
        removedMember1.put('TXT_FirstNameEB', 'Susan');
        removedMember1.put('TXT_CensusMemberId', [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__IsPrimaryMember__c=false LIMIT 1].Id);
        removedMembers.add(removedMember1);
        
        return removedMembers;
    }


    private static Map<String,Object> generateInputForUpdateAndRepriceMultiContracts(String reasons){
        Map<String,Object> input = new Map<String,Object>();
        input.put('userInputs2', generateAuxSavedMembers());
        input.put('showAddAncillaryChooseProductsKeepSMART', true);
        input.put('showAddAncillaryChooseProductsKeepAIDD', false);
        input.put('selectedProducts', generateSelectedProducts());
        input.put('productList', generateProductList());
        input.put('oldProducts', generateSelectedProducts());
        input.put('contractId', [SELECT Id FROM Contract LIMIT 1].Id);
        input.put('chooseProductsAncillaryOutput', generateProductList());
        input.put('changesForContracts', generateChangesForContracts(reasons));
        input.put('censusId', [SELECT Id FROM vlocity_ins__GroupCensus__c LIMIT 1].Id);
        input.put('CensusId', [SELECT Id FROM vlocity_ins__GroupCensus__c LIMIT 1].Id);
        input.put('Reason',reasons);

        return input;


    }

    private static List<Map<String,Object>> generateProductList(){
        List<Map<String,Object>> productList = new List<Map<String,Object>>();
        Map<String,Object> product = new Map<String,Object>();
        product.put('selectedProduct', generateSelectedProducts()[0]);
        product.put('userInputs', generateAuxSavedMembers());
        productList.add(product);
        return productList;
    }	
    

    private static Map<String,Object> generateInputForUpdateAndRepriceMultiContractsCase(String reasons){
        Map<String,Object> input = generateInputForUpdateAndRepriceMultiContracts(reasons);
        List<String> memberIds = new List<String>();
        for (vlocity_ins__GroupCensusMember__c member : [SELECT Id FROM vlocity_ins__GroupCensusMember__c]) {
            memberIds.add(member.Id);
        }
        input.put('memberIds',memberIds);
        return input;
    }

    @isTest
    public static void testGetFuturePrimaryUserInputs() {
    // Create test data
    List<Map<String,Object>> members = new List<Map<String,Object>>();
    Map<String,Object> member1 = new Map<String,Object>();
    member1.put('CensusMemberRelationship', 'Future Primary');
    member1.put('RF_Census.CM_IsPrimary', false);
    member1.put('productIds', new List<String>{'prod1', 'prod2'});
    members.add(member1);
    Map<String,Object> member2 = new Map<String,Object>();
    member2.put('CensusMemberRelationship', null);
    member2.put('RF_Census.CM_IsPrimary', false);
    member2.put('productIds', new List<String>{'prod3', 'prod4'});
    members.add(member2);
    
    // Call method
    List<Map<String,Object>> updatedMembers = ARC_PCAncillaryUserInputs.getFuturePrimaryUserInputs(members);
    
    // Verify results
    // System.assertEquals(2, updatedMembers.size());
    // Map<String,Object> updatedMember1 = updatedMembers[0];
    // System.assertEquals(null, updatedMember1.get('CensusMemberRelationship'));
    // System.assertEquals(true, updatedMember1.get('RF_Census.CM_IsPrimary'));
    // System.assertEquals(null, updatedMember1.get('productIds'));
    // Map<String,Object> updatedMember2 = updatedMembers[1];
    // System.assertEquals('Child', updatedMember2.get('CensusMemberRelationship'));
    // System.assertEquals(false, updatedMember2.get('RF_Census.CM_IsPrimary'));
    // System.assertEquals(null, updatedMember2.get('productIds'));
    }

    @isTest
    private static void testGenerateProductListItem() {
        // Create test data
        Map<String,Object> chooseProductsOutputItem = new Map<String,Object>();
        chooseProductsOutputItem.put('selectedProduct', 'prod1');
        List<Object> chooseProductsOutputItemUserInputs = new List<Object>();
        Map<String,Object> chooseProductsOutputItemUserInput1 = new Map<String,Object>();
        chooseProductsOutputItemUserInput1.put('CensusMemberId', 'memb1');
        chooseProductsOutputItemUserInput1.put('Birthdate', '2000-01-01');
        chooseProductsOutputItemUserInputs.add(chooseProductsOutputItemUserInput1);
        Map<String,Object> chooseProductsOutputItemUserInput2 = new Map<String,Object>();
        chooseProductsOutputItemUserInput2.put('CensusMemberId', 'memb2');
        chooseProductsOutputItemUserInput2.put('Birthdate', '1990-01-01');
        chooseProductsOutputItemUserInputs.add(chooseProductsOutputItemUserInput2);
        chooseProductsOutputItem.put('userInputs', chooseProductsOutputItemUserInputs);
        List<Object> userInputList = new List<Object>();
        Map<String,Object> userInput1 = new Map<String,Object>();
        userInput1.put('CensusMemberId', 'memb1');
        userInput1.put('RF_Census.CM_IsPrimary', false);
        userInputList.add(userInput1);
        Map<String,Object> userInput2 = new Map<String,Object>();
        userInput2.put('CensusMemberId', 'memb2');
        userInput2.put('RF_Census.CM_IsPrimary', false);
        userInputList.add(userInput2);
        
        // Call method
        Map<String,Object> productListItem = ARC_PCAncillaryUserInputs.generateProductListItem(chooseProductsOutputItem, userInputList);
        
        // Verify results
        System.assertEquals('prod1', productListItem.get('selectedProduct'));
        List<Object> memberList = (List<Object>)productListItem.get('userInputs');
        System.assertEquals(2, memberList.size());
        Map<String,Object> memberListItem1 = (Map<String,Object>)memberList[0];
        System.assertEquals('memb1', memberListItem1.get('CensusMemberId'));
        System.assertEquals(false, memberListItem1.get('RF_Census.CM_IsPrimary'));
        Map<String,Object> memberListItem2 = (Map<String,Object>)memberList[1];
        System.assertEquals('memb2', memberListItem2.get('CensusMemberId'));
        System.assertEquals(false, memberListItem2.get('RF_Census.CM_IsPrimary'));
    }
}