@isTest
public with sharing class ARC_TemporaryNewborn_UtilitiesTest {
    

    @isTest
    private static void testPopulateMedicalQuestions() {
    

        Map<String, Object> newbornMember = new Map<String, Object>{
            'Id' => 'a01xx0000001AAA',
            'vlocity_ins__FirstName__c' => 'Baby',
            'vlocity_ins__LastName__c' => 'Smith',
            'vlocity_ins__Birthdate__c' => '2025-01-01'
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'EB_TemporaryNewborn' => new List<Object>{newbornMember}
        };
        Map<String, Object> inputMap = new Map<String, Object>{
            'STEP_AddNewborn' => censusComponent
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        ARC_TemporaryNewborn_Utilities.populateMedicalQuestions(inputMap, outputMap, new Map<String, Object>());

        System.assert(outputMap.containsKey('STEP_MedicalQuestions'), 'STEP_MedicalQuestions should be present');
        System.assert(outputMap.containsKey('CensusMember'), 'CensusMember should be present');
        List<Object> censusMembers = (List<Object>)outputMap.get('CensusMember');
        System.assertEquals(1, censusMembers.size(), 'Should have one census member');
    }

    
    @isTest
    private static void testTransformCensusMemberToUserInputs() {
    

        Account acc = new Account(Name='Test Account');
        insert acc;
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            Name = 'Test Census ',
            vlocity_ins__GroupId__c = acc.Id
        );
        insert census;
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        Account pa = new Account(
                RecordTypeId = accRecordTypeId,
                LastName = 'Test Member',
                PersonEmail = 'test@example.com',
                PersonBirthdate = Date.newInstance(1980,1,1),
                ARC_IsPrimaryMember__c = true,
                vlocity_ins__SocialSecurityNumber__pc = '123456789',
                IsActive = true,
                ARC_DependentRelationship__c = 'Spouse',
                ARC_GroupAccount__c = acc.Id
            );
        insert pa;
        Contact c = [SELECT Id, AccountId FROM Contact WHERE AccountId = :pa.Id LIMIT 1];
        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c='John',
            vlocity_ins__LastName__c='Doe',
            vlocity_ins__Birthdate__c=Date.newInstance(1980,1,1),
            ARC_PhysicalAddressState__c='CA',
            ARC_PhysicalAddressCity__c='Los Angeles',
            ARC_PhysicalAddressStreet__c='123 Main St',
            ARC_PhysicalAddressZipCode__c='90001',
            vlocity_ins__ContactId__c=c.Id,
            vlocity_ins__CensusId__c=census.Id
        );
        insert censusMember;
        
        Map<String, Object> product = new Map<String, Object>{
            'productId' => 'p01xx0000001AAA',
            'Type__c' => 'Ancillary',
            'census_members' => new List<Object>{censusMember},
            'ProductCode' => 'WeShare Premier 6k'
        };
        // Simulate Contract and Participant
        List<Contract> contracts = ARC_TestUtility.createContractsAA(1);
        insert contracts;
        Contract contract = contracts[0];
        ARC_ContractParticipant__c cp = new ARC_ContractParticipant__c(
            ARC_Contract__c=contract.Id,
            ARC_PersonAccount__c=pa.Id,
            ARC_Relationship__c='Primary'
        );
        insert cp;

        Map<String, Object> eligibleContractInfo = new Map<String, Object>{
            'CensusId' => census.Id,
            'Id' => contract.Id,
            'Reasons' => 'Spin Off',
            'Status' => 'Awaiting Signature'
        };
        Map<String, Object> newborn = new Map<String, Object>{
            'Id' => 'a01xx0000001BBB',
            'vlocity_ins__FirstName__c' => 'Baby',
            'vlocity_ins__LastName__c' => 'Doe',
            'vlocity_ins__Birthdate__c' => '2025-01-01'
        };
        Map<String, Object> inputMap = new Map<String, Object>{
            'EligibleContractInfo' => eligibleContractInfo,
            'ActiveCensusId' => 'a01xx0000001ZZZ',
            'EffectiveDate' => String.valueOf(Date.today()),
            'addedNewborn' => newborn,
            'oldProducts' => new List<Object>{product}
                
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Test.startTest();
        ARC_TemporaryNewborn_Utilities.TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, new Map<String, Object>());
        Test.stopTest();

        System.assert(outputMap.containsKey('userInputs'), 'userInputs should be present');
        System.assert(outputMap.containsKey('census_members'), 'census_members should be present');
        List<Object> userInputs = (List<Object>)outputMap.get('userInputs');
        System.assert(userInputs.size() > 0, 'Should have user inputs');
    }

    
    @isTest
    private static void testTransformChooseProductSelectionData() {

        Map<String, Object> userInput = new Map<String, Object>{
            'Id' => 'a01xx0000001AAA',
            'RF_Census.CM_Age' => 44,
            'RF_Census.CM_Relationship' => 'Primary'
        };
        Map<String, Object> censusMember = new Map<String, Object>{
            'Id' => 'a01xx0000001AAA'
        };
        Map<String, Object> product = new Map<String, Object>{
            'productId' => 'p01xx0000001AAA',
            'Type__c' => 'Ancillary',
            'census_members' => new List<Object>{censusMember},
            'ProductCode' => 'WeShare Premier 6k'
        };
        Map<String, Object> inputMap = new Map<String, Object>{
            'oldProducts' => new List<Object>{product},
            'userInputs' => new List<Object>{userInput}
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        ARC_TemporaryNewborn_Utilities.TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, new Map<String, Object>());
        System.assert(outputMap.containsKey('LWC_ChooseProductSelectionOutput'), 'Should have LWC_ChooseProductSelectionOutput');
    }

    @isTest
    private static void testPopulateReasons() {
    
        ChargentBase__Chargent_Settings__c settings = new ChargentBase__Chargent_Settings__c(
            Name='Default',
            ARC_UpgradeChangeFee__c=10,
            ARC_AddMemberChangeFee__c=20,
            ARC_DowngradeChangeFee__c=5,
            ARC_AppFee__c=30
        );
        insert settings;
        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ARC_FirstMonthPayed__c = true,
            ChargentOrders__Description__c = 'Recurring Monthly Order',
            ChargentOrders__Charge_Amount__c = 10
        );
        insert order;

        Map<String, Object> inputMap = new Map<String, Object>{
            'ContractStatus' => 'Awaiting',
            'ContractReasons' => 'Add Member;Program Upgrade;New Application',
            'RecurringMonthlyOrderId' => order.Id,
            'CarryOverAppFee' => true,
            'AppFeeOrderId' => order.Id
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        ARC_TemporaryNewborn_Utilities.populateReasons(inputMap, outputMap, new Map<String, Object>());
        System.assert(outputMap.containsKey('nbChanges'), 'Should have nbChanges');
        System.assert(outputMap.containsKey('mapChargentOrders'), 'Should have mapChargentOrders');
        System.debug(outputMap);
    }

    @isTest
    private static void testGetDocuSignDataNew() {
        // Mock census_members
        Map<String, Object> censusMember = new Map<String, Object>{
            'Id' => 'a01xx0000001AAA',
            'vlocity_ins__FirstName__c' => 'John',
            'vlocity_ins__LastName__c' => 'Doe',
            'ARC_Relationship__c' => 'Primary',
            'ARC_Age__c' => 35,
            'ARC_PhysicalAddressState__c' => 'CA',
            'vlocity_ins__Email__c' => 'john.doe@example.com',
            'ARC_MiddleInitial__c' => 'A',
            'ARC_Phone__c' => '1234567890',
            'ARC_PhysicalAddressCity__c' => 'Los Angeles',
            'ARC_PhysicalAddressStreet__c' => '123 Main St',
            'ARC_PhysicalAddressZipCode__c' => '90001',
            'ARC_Weight__c' => '180',
            'ARC_HeightFeet__c' => '5',
            'ARC_HeightInches__c' => '10',
            'vlocity_ins__Birthdate__c' => '1990-01-01',
            'ARC_isPregnant__c' => false,
            'ARC_Smoker__c' => false,
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'vlocity_ins__Gender__c' => 'M',
            'vlocity_ins__SocialSecurityNumber__c' => '123456789'
        };
        Map<String, Object> censusMember2 = new Map<String, Object>{
            'Id' => 'a01xx0000001AAA',
            'vlocity_ins__FirstName__c' => 'John',
            'vlocity_ins__LastName__c' => 'Doe jr',
            'ARC_Relationship__c' => 'Child',
            'ARC_Age__c' => 35,
            'ARC_PhysicalAddressState__c' => 'CA',
            'vlocity_ins__Email__c' => 'john.doejr@example.com',
            'ARC_MiddleInitial__c' => 'A',
            'ARC_Phone__c' => '1234567890',
            'ARC_PhysicalAddressCity__c' => 'Los Angeles',
            'ARC_PhysicalAddressStreet__c' => '123 Main St',
            'ARC_PhysicalAddressZipCode__c' => '90001',
            'ARC_Weight__c' => '80',
            'ARC_HeightFeet__c' => '5',
            'ARC_HeightInches__c' => '10',
            'vlocity_ins__Birthdate__c' => '2025-01-01',
            'ARC_isPregnant__c' => false,
            'ARC_Smoker__c' => false,
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'vlocity_ins__Gender__c' => 'M',
            'vlocity_ins__SocialSecurityNumber__c' => '123456789'
        };
        List<Object> censusMembers = new List<Object>{censusMember, censusMember2};
        Map<String, Object> userInput1 = new Map<String, Object>{
            'FirstName' => 'John',
            'LastName' => 'Doe'
        };
        Map<String, Object> userInput2 = new Map<String, Object>{
            'FirstName' => 'John',
            'LastName' => 'Doe jr'
        };
        // Mock DocuSign Map
       
            
         Map<String, Object> OldProductList  = new Map<String, Object>{
            'Type__c' => 'Medical',
            'TXT_PlanSelected' => 'WeShare 5k'
        };
            
        Map<String, Object> selectedProduct  = new Map<String, Object>{
            'Type__c' => 'Medical',
            'TXT_PlanSelected' => 'WeShare 5k',
            'selectedProduct' => 'WeShare 5k',
            'Name' => 'WeShare Legacy',
            'TXT_MonthlyPrice' => '100'
        };
        Map<String, Object> product = new Map<String, Object>{
            'OldProductList' => OldProductList,
            'userInputs' => new List<Object>{userInput1, userInput2}
        };
        Map<String, Object> BLK_ProductsPrices = new Map<String, Object>{
            'BLK_IndividualProducts' => new List<Object>{selectedProduct}
        };
        

        // Insert required template for query
        ARC_DocuSignTemplates__c customTemplate = new ARC_DocuSignTemplates__c(
            ARC_Template_Name__c = 'Custom Template',
            ARC_Contract_Reasons__c = 'Spin Off',
            ARC_Min_Dependents__c = 0,
            ARC_Max_Dependents__c = 10,
            ARC_State__c = 'CA',
            ARC_DRTransform__c = 'Some Value',
            Name = 'Custom Template'
        );
        insert customTemplate;
        vlocity_ins__VlocityDocuSignTemplate__c template = new vlocity_ins__VlocityDocuSignTemplate__c(
            Name = 'Custom Template',
            vlocity_ins__templateidentifier__c = 'tmpl-123'
        );
        insert template;

        // MembersInfo structure
        Map<String, Object> primaryMember = new Map<String, Object>{
            'Id' => 'a01xx0000001AAA',
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'DOB' => '1990-01-01',
            'Gender' => 'M',
            'Pregnant' => false,
            'Smoker' => false
        };
        Map<String, Object> membersInfo = new Map<String, Object>{
            'primaryMember' => primaryMember,
            'dependentMembers' => new List<Object>()
        };

        // pcChanges structure
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasonsString' => 'Add Member',
            'feeAmount' => 0,
            'createNewContract' => false,
            'feeApplicable' => false
        };

        List<Contract> contracts = ARC_TestUtility.createContractsAA(1);
        insert contracts;
        Contract contract = contracts[0];

        // Insert a Chargent Order linked to the contract
        ChargentOrders__ChargentOrder__c order = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = contract.Id,
            ARC_FirstMonthPayed__c = true,
            ChargentOrders__Description__c = 'Recurring Monthly Order',
            ChargentOrders__Charge_Amount__c = 10
        );
        insert order;
        
        Map<String, Object> BLK_ProductSummary = new Map<String, Object>{
    		'TXT_MonthlyPrice' => '100'
						};
        Map<String, Object> PlanSummary = new Map<String, Object>{
    			'BLK_ProductSummary' => BLK_ProductSummary
												};
                                                    
       	System.debug('Plan Summary1: ' + PlanSummary);
       	System.debug('Plan Summary2: ' + (Map<String, Object>) PlanSummary.get('BLK_ProductSummary'));
        Map<String, Object> blkSummary = (Map<String, Object>) PlanSummary.get('BLK_ProductSummary');
      	System.debug('Plan Summary3: ' + blkSummary.get('TXT_MonthlyPrice'));
        
        

        Map<String, Object> DocuSignMap = new Map<String, Object>{
            'PlansSummary' => PlanSummary,
            'NewProductList' => new List<Object>{product},
            'pcChanges' => pcChanges,
            'OldProductList' => new List<Object>(),
            'SelectedContractInfo' => new Map<String, Object>{
                'ContractID' => contract.Id
            },
            'Step_PaymentChangeFee' => new Map<String, Object>(),
            'Hipaa' => new List<Object>(),
            'Medicare' => null,
            'userId' => UserInfo.getUserId()
        };

        List<Object> allMembersInfo = new List<Object>{censusMember, censusMember2};

        // Add newMedicalProduct
        Map<String, Object> newMedicalProduct = new Map<String, Object>{
            'selectedProduct' => selectedProduct
        };
            
        Map<String, Object> oldMedicalProduct = new Map<String, Object>{
            'selectedProduct' => selectedProduct
        };
        
         Map<String, Object> productWrapper = new Map<String, Object>{
    	'selectedProduct' => selectedProduct,
         'userInputs' => new List<Object>{userInput1}};
             
		List<Object> newProductList = new List<Object>{ productWrapper };
                
       
        Map<String, Object> inputMap = new Map<String, Object>{
            'census_members' => censusMembers,
            'PlansSummary' => PlanSummary,
            'userId' => UserInfo.getUserId(),
            'DocuSign' => DocuSignMap,
            'effectiveDate' => '2025-01-01',
            'allMembersInfo' => allMembersInfo,
            'primaryState' => 'CA',
            'newMedicalProduct' => newMedicalProduct,
            'oldMedicalProduct' => oldMedicalProduct,
            'NewProductList' => newProductList,
            'nbChanges' => new Map<String,Object>{
                'nbReasonsString' => 'Add Member',
                'nbReasons' => 'Reason',
                'feeApplicable' => false,
                'feeAmount' => 0,
                'newFeeAmount' => 0
            },
            'EligibleContract' => new Map<String,Object>{
                'ContractInfo' => new Map<String,Object>{
                    'Id' => contract.Id
                }
            },
            'STEP_MedicalQuestions' => new Map<String,Object>(),
            'STEP_SignTheDocument' => new Map<String,Object>(),
            'Step_PaymentChangeFee' => new Map<String,Object>(),
            'OldProductList' => new List<Object>()
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String,Object> options = new Map<String,Object>();
        System.debug('inputMap:'+inputMap);
        Test.startTest();
        ARC_TemporaryNewborn_Utilities.getDocuSignDataNew(inputMap, outputMap, options);
        Test.stopTest();
        System.assert(outputMap.containsKey('EnvelopeInformation'));
		Map<String,Object> envelope =(Map<String,Object>) outputMap.get('EnvelopeInformation');
		System.assertNotEquals(null, envelope);
        System.assert(envelope.containsKey('signerList'));
        System.assert(envelope.containsKey('templateIdList'));
        System.assert(envelope.containsKey('tabs'));
        System.assertNotEquals(null, outputMap.get('recipientStepLabel'));
            }
    
    @IsTest
    static void testTransformMemberMapKeys() {

        // Step 1: Create mock input map
        Map<String, Object> inputMap = new Map<String, Object>{
            'Id' => 'a01xx0000001AAA',
            'vlocity_ins__FirstName__c' => 'John',
            'ARC_MiddleInitial__c' => 'A',
            'vlocity_ins__LastName__c' => 'Doe',
            'vlocity_ins__Birthdate__c' => '1990-01-01',
            'ARC_Age__c' => 35,
            'vlocity_ins__Gender__c' => 'Male',
            'ARC_Phone__c' => '1234567890',
            'vlocity_ins__Email__c' => 'john@test.com',
            'vlocity_ins__SocialSecurityNumber__c' => '123456789',
            'ARC_HeightFeet__c' => 5,
            'ARC_HeightInches__c' => 10,
            'ARC_Weight__c' => 180,
            'ARC_isPregnant__c' => false,
            'ARC_Smoker__c' => true,
            'ARC_PhysicalAddressStreet__c' => '123 Main St',
            'ARC_PhysicalAddressCity__c' => 'Toronto',
            'ARC_PhysicalAddressState__c' => 'ON',
            'ARC_PhysicalAddressZipCode__c' => 'A1A1A1',
            'ARC_Relationship__c' => 'Self',
            'IsRemoveMember' => false,
            'IsNewMember' => true
        };

        Test.startTest();

        Map<String,Object> result =
            ARC_TemporaryNewborn_Utilities.transformMemberMapKeys(inputMap);
        Test.stopTest();

        // Step 2: Assertions

        System.assertEquals('John', result.get('FirstName'));
        System.assertEquals('A', result.get('MI'));
        System.assertEquals('Doe', result.get('LastName'));
        System.assertEquals(35, result.get('Age'));
        System.assertEquals('Male', result.get('Gender'));

        // Height formatting check
        System.assertEquals('5\'10\"', result.get('Height'));

        // SSN masking check
        System.assertEquals('XXX-XX-6789', result.get('SocialSecurity'));
        System.assertEquals('123456789', result.get('SSN'));

        // Boolean checks
        System.assertEquals(false, result.get('Pregnant'));
        System.assertEquals(true, result.get('Smoker'));

        // Address checks
        System.assertEquals('Toronto', result.get('City'));
        System.assertEquals('ON', result.get('State'));

        // Flags
        System.assertEquals(false, result.get('IsRemoveMember'));
        System.assertEquals(true, result.get('IsNewMember'));
    }
    
     @IsTest
    static void testGetMemberBeneficiaries() {
        
        List<Contract> cont = ARC_TestUtility.createContractsAA(1);
        insert cont;
        Contract contract = cont[0];

        Product2 prod = new Product2(
            Name = 'Medical Product',
            IsActive = true,
            vlocity_ins__Type__c = 'Medical'
        );
        insert prod;
        
        Account personAcc = new Account(
            FirstName = 'John',
            LastName = 'Doe',
            PersonEmail = 'john@test.com'
        );
        insert personAcc;

       
        InsurancePolicy  policy = new InsurancePolicy (
            Name = 'Test Policy',
            ARC_Contract__c = contract.Id,
            NameInsuredId = personAcc.Id
        );
        insert policy;

       
        InsurancePolicyCoverage  coverage = new InsurancePolicyCoverage (
            InsurancePolicyId = policy.Id,
            vlocity_ins_fsc__Product2Id__c = prod.Id
        );
        insert coverage;

        
        Contact c = [SELECT Id, AccountId FROM Contact WHERE AccountId = :personAcc.Id LIMIT 1];

       
        InsurancePolicyParticipant  participant = new InsurancePolicyParticipant (
            InsurancePolicyId  = policy.Id,
            PrimaryParticipantContactId = c.Id,
            Role = 'Primary'
        );
        insert participant;

       
        ARC_CoverageParticipant__c covPart = new ARC_CoverageParticipant__c(
            ARC_Policy__c = policy.Id,
            ARC_PolicyCoverage__c = coverage.Id,
            ARC_PolicyParticipant__c = participant.Id,
            ARC_PrimaryBeneficiaryName__c = 'Jane Doe',
            ARC_PrimaryBeneficiaryBirthdate__c = Date.today(),
            ARC_PrimaryBeneficiaryPhone__c = '1234567890',
            ARC_PrimaryBeneficiaryRelationship__c = 'Spouse',
            ARC_SecondaryBeneficiaryName__c = 'Bob Doe',
            ARC_SecondaryBeneficiaryBirthdate__c = Date.today(),
            ARC_SecondaryBeneficiaryPhone__c = '9876543210',
            ARC_SecondaryBeneficiaryRelationship__c = 'Other',
            ARC_SecondaryBeneficiaryOther__c = 'Friend'
        );
        insert covPart;

        
        Map<String,Object> contractInfo = new Map<String,Object>{
            'Id' => contract.Id
        };

        Map<String,Object> memberMap = new Map<String,Object>{
            'PersonAccountId' => personAcc.Id
        };

        List<Object> censusMembers = new List<Object>();
        censusMembers.add(memberMap);

        Map<String,Object> inputMap = new Map<String,Object>{
            'ContractInfo' => contractInfo,
            'census_members' => censusMembers
        };

        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        
        Test.startTest();
        Map<String,Object> result = ARC_TemporaryNewborn_Utilities.getMemberBeneficiaries(inputMap, outputMap, options);
        Test.stopTest();

        List<Object> resultMembers =
            (List<Object>)result.get('census_members');

        System.assertEquals(1, resultMembers.size());

        Map<String,Object> resultMember =
            (Map<String,Object>)resultMembers[0];

        List<Object> beneficiaries =
            (List<Object>)resultMember.get('beneficiaries');

        System.assertEquals(2, beneficiaries.size());

        Map<String,Object> primary =
            (Map<String,Object>)beneficiaries[0];

        System.assertEquals('Primary Beneficiary', primary.get('Label'));
        System.assertEquals('Jane Doe', primary.get('BeneficiaryName'));

        Map<String,Object> secondary =
            (Map<String,Object>)beneficiaries[1];

        System.assertEquals(true, secondary.get('isOtherRelationship'));
    }
    
     @isTest
    static void testPrimaryAccount_NewbornWithoutContractParticipant() {

        // Create Primary Account
        Account primary = new Account(Name = 'Primary Account');
        insert primary;

        // Create Temporary Newborn (created today = within 1 year)
        Account newborn = new Account(
            FirstName = 'Baby',
            LastName = 'One',
            ARC_PrimaryMemberAccount__c = primary.Id,
            ARC_DependentRelationship__c = 'Temporary Newborn'
        );
        insert newborn;

        Map<String,Object> inputMap = new Map<String,Object>{
            'ContextId' => primary.Id
        };
        Map<String,Object> outputMap = new Map<String,Object>();

        Test.startTest();
        ARC_TemporaryNewborn_Utilities.hasTemporaryNewBornMember(
            inputMap, outputMap, new Map<String,Object>()
        );
        Test.stopTest();
        System.assertEquals(true, outputMap.get('hasTemporaryNewBornMember'));
        System.assertEquals('Baby', outputMap.get('NBFirstName'));
        System.assertEquals('One', outputMap.get('NBLastName'));
    }
    
    @isTest
    static void testNoNewbornFound() {

        Account primary = new Account(Name = 'Primary Account');
        insert primary;

        Map<String,Object> inputMap = new Map<String,Object>{
            'ContextId' => primary.Id
        };
        Map<String,Object> outputMap = new Map<String,Object>();

        Test.startTest();
        ARC_TemporaryNewborn_Utilities.hasTemporaryNewBornMember(
            inputMap, outputMap, new Map<String,Object>()
        );
        Test.stopTest();

        System.assertEquals(false, outputMap.get('hasTemporaryNewBornMember'));
        System.assertEquals(null, outputMap.get('NBFirstName'));
        System.assertEquals(null, outputMap.get('NBLastName'));
    }
    
    @isTest
    static void testDependentAccountPath() {

        // Create Primary
        Account primary = new Account(Name = 'Primary Account');
        insert primary;

        // Create dependent account (this will trigger ELSE branch)
        Account dependent = new Account(
            Name = 'Dependent Account',
            ARC_PrimaryMemberAccount__c = primary.Id
        );
        insert dependent;

        // Create newborn under primary
        Account newborn = new Account(
            FirstName = 'Baby',
            LastName = 'Three',
            ARC_PrimaryMemberAccount__c = primary.Id,
            ARC_DependentRelationship__c = 'Temporary Newborn'
        );
        insert newborn;

        Map<String,Object> inputMap = new Map<String,Object>{
            'ContextId' => dependent.Id
        };
        Map<String,Object> outputMap = new Map<String,Object>();

        Test.startTest();
        ARC_TemporaryNewborn_Utilities.hasTemporaryNewBornMember(
            inputMap, outputMap, new Map<String,Object>()
        );
        Test.stopTest();

        System.assertEquals(true, outputMap.get('hasTemporaryNewBornMember'));
        System.assertEquals('Baby', outputMap.get('NBFirstName'));
    }
    
    @IsTest
    static void testMergeMedicalQuestions_AllBranches() {
        
        Account acc = new Account (Name ='Group Account');
        insert acc;
        
        vlocity_ins__GroupCensus__c  census = new vlocity_ins__GroupCensus__c(
            Name = 'Test Census',
            vlocity_ins__GroupId__c = acc.Id
        );
        insert census;

        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(
            Name = 'Test Member',
            ARC_PhysicianName__c = 'Dr Smith',
            ARC_PhysicianCity__c = 'Toronto',
            ARC_PhysicianPhone__c = '1234567890',
            vlocity_ins__CensusId__c = census.Id
        );
        insert censusMember;

        ARC_MedicalConditions__c mc = new ARC_MedicalConditions__c(
            ARC_Active__c = true,
            ARC_CensusMember__c = censusMember.Id,
            ARC_ParentsOrSiblingsDiagnosed__c = true,
            ARC_UnexplainedConditions__c = true,
            ARC_Tests__c = true,
            ARC_IllegalDrugsAlcohol__c = true,
            ARC_LicenceSuspended__c = true,
            ARC_Condition__c = 'Asthma',
            ARC_Type_Of_Cancer__c = 'Lung',
            ARC_Year_Diagnosed_Cancer__c = Date.today().addYears(-1),
            ARC_Currently_Under_Treatment__c = true
        );
        insert mc;

        vlocity_ins__ConsumerDrug__c drug = new vlocity_ins__ConsumerDrug__c(
            Name = 'Tylenol',
            ARC_Active__c = true,
            ARC_CensusMember__c = censusMember.Id,
            vlocity_ins__PrescribedBy__c = 'Dr Smith',
            vlocity_ins__MedicationStartDate__c = Date.today().addMonths(-1),
            ARC_Reason__c = 'Pain'
        );
        insert drug;

        Map<String,Object> memberMap = new Map<String,Object>{
            'Id' => censusMember.Id,
            'IsNewMember' => false
        };

        Map<String,Object> inputMap = new Map<String,Object>{
            'censusMembers' => new List<Object>{ memberMap },
            'STEP_MedicalQuestions' => new Map<String,Object>()
        };

        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Test.startTest();
        ARC_TemporaryNewborn_Utilities.mergeMedicalQuestions(inputMap, outputMap, options);
        Test.stopTest();
        System.assert(outputMap.containsKey('carryOverMedicalQuestions'));

        Map<String,Object> result =
            (Map<String,Object>) outputMap.get('carryOverMedicalQuestions');
        System.assertEquals('Yes', result.get('RAD_ParentSiblingDiagnosed'));
        System.assertEquals('Yes', result.get('RAD_UnexplainedSymptoms'));
        System.assertEquals('Yes', result.get('RAD_PendingTests'));
        System.assertEquals('Yes', result.get('RAD_Addictions'));
        System.assertEquals('Yes', result.get('RAD_LicenceSuspended'));
        System.assertEquals('Yes', result.get('RAD_PastConditions'));
        System.assertEquals('Yes', result.get('RAD_Cancer'));
        System.assertEquals('Yes', result.get('RAD_PrescriptionMedications'));
    }
    
    

  
}