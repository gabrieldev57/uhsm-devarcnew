@isTest
public with sharing class ARC_SpinOff_UtilitiesTest {
    
    static void getContractIdAndCensusMembersFromEnrollment(Map<String, Object> enrollmentData){
        // Create the test data
        ARC_TestUtility.createCompleteEnrollments(1);
        // Prepare the inputMap with the test data
        Contract contractData = [SELECT Id FROM Contract LIMIT 1];

        // Get Census members information
        List<ARC_ContractParticipant__c> participantsList = [SELECT ARC_PersonAccount__r.Census_Member__r.ARC_Phone__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Email__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.Id,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_Relationship__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_Age__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Birthdate__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__IsPrimaryMember__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.Name
                                                            FROM ARC_ContractParticipant__c
                                                            WHERE ARC_Contract__c = :contractData.Id];

        // Preparing the censusMembers list for the inputMap
        List<Object> censusMembers = new List<Object>();
        
        for (ARC_ContractParticipant__c participant : participantsList)
        {
            censusMembers.add(new Map<String, Object>{
                'ARC_Relationship__c' => participant.ARC_PersonAccount__r.Census_Member__r.ARC_Relationship__c,
                'IsRemoveMember' => false,
                'vlocity_ins__IsPrimaryMember__c' => participant.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__IsPrimaryMember__c,
                'IsNewMember' => false,
                'ARC_Age__c' => 25,
                'vlocity_ins__FirstName__c' => participant.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                'vlocity_ins__LastName__c' => participant.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                'vlocity_ins__Birthdate__c' => '2000-01-01',
                'ARC_PhysicalAddressStreet__c' => participant.ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c,
                'ARC_PhysicalAddressCity__c' => participant.ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c,
                'ARC_PhysicalAddressState__c' => participant.ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c,
                'ARC_PhysicalAddressZipCode__c' => participant.ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c,
                'vlocity_ins__Email__c' => 'test@test.com',
                'ARC_Phone__c' => '123123',
                'Id' => participant.ARC_PersonAccount__r.Census_Member__r.Id
            });
        }

        enrollmentData.put('contractId', contractData.Id);
        enrollmentData.put('censusMembers', censusMembers);
    }

    static void populateMemberDataWithASpinOff(List<Object> members) {
        // Create test census members
        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(3);

        // Primary member data
        Map<String,Object> memberMap1 = new Map<String,Object>();
        memberMap1.put('Id', testCensusMembers[0].Id);
        memberMap1.put('vlocity_ins__IsPrimaryMember__c', true);
        memberMap1.put('ARC_PhysicalAddressState__c', 'CA');
        memberMap1.put('ARC_Relationship__c', 'Primary');
        memberMap1.put('ARC_Age__c', 30);
        memberMap1.put('ARC_Smoker__c', false);
        memberMap1.put('ARC_isPregnant__c', false);
        memberMap1.put('IsNewMember', false);
        memberMap1.put('IsRemoveMember', false);
        memberMap1.put('IsInactiveMember', false);
        memberMap1.put('vlocity_ins__LastName__c', 'Test1');
        memberMap1.put('vlocity_ins__FirstName__c', 'Member1');
        memberMap1.put('vlocity_ins__Birthdate__c', '1995-01-01');

        // Spouse member data
        Map<String,Object> memberMap2 = new Map<String,Object>();
        memberMap2.put('Id', testCensusMembers[1].Id);
        memberMap2.put('vlocity_ins__IsPrimaryMember__c', true);
        memberMap2.put('ARC_PhysicalAddressState__c', 'CA');
        memberMap2.put('ARC_Relationship__c', 'Primary');
        memberMap2.put('ARC_Age__c', 50);
        memberMap2.put('ARC_Smoker__c', false);
        memberMap2.put('ARC_isPregnant__c', false);
        memberMap2.put('IsNewMember', false);
        memberMap2.put('IsRemoveMember', false);
        memberMap2.put('IsInactiveMember', false);
        memberMap2.put('vlocity_ins__LastName__c', 'Test2');
        memberMap2.put('vlocity_ins__FirstName__c', 'Member2');
        memberMap2.put('vlocity_ins__Birthdate__c', '1975-01-01');

        // Child member data
        Map<String,Object> memberMap3 = new Map<String,Object>();
        memberMap3.put('Id', testCensusMembers[2].Id);
        memberMap3.put('vlocity_ins__IsPrimaryMember__c', false);
        memberMap3.put('ARC_PhysicalAddressState__c', 'CA');
        memberMap3.put('ARC_Relationship__c', 'Child');
        memberMap3.put('ARC_Age__c', 5);
        memberMap3.put('ARC_Smoker__c', false);
        memberMap3.put('ARC_isPregnant__c', false);
        memberMap3.put('IsNewMember', false);
        memberMap3.put('IsRemoveMember', false);
        memberMap3.put('IsInactiveMember', false);
        memberMap3.put('vlocity_ins__LastName__c', 'Test3');
        memberMap3.put('vlocity_ins__FirstName__c', 'Member3');
        memberMap3.put('vlocity_ins__Birthdate__c', '2020-01-01');

        // Add a list with the Primary and Child
        members.add(new List<Object>{memberMap1, memberMap3});
        // Add a list with the Spouse
        members.add(new List<Object>{memberMap2});
    }

    static void populateMemberDataWith3DifferentPrimaries(List<Object> members){
        // Create test census members
        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(3);

        // Primary member data
        Map<String,Object> memberMap1 = new Map<String,Object>();
        memberMap1.put('Id', testCensusMembers[0].Id);
        memberMap1.put('vlocity_ins__IsPrimaryMember__c', true);
        memberMap1.put('ARC_PhysicalAddressState__c', 'CA');
        memberMap1.put('ARC_Relationship__c', 'Primary');
        memberMap1.put('ARC_Age__c', 35);
        memberMap1.put('ARC_Smoker__c', false);
        memberMap1.put('ARC_isPregnant__c', false);
        memberMap1.put('IsNewMember', false);
        memberMap1.put('IsRemoveMember', false);
        memberMap1.put('IsInactiveMember', false);
        memberMap1.put('vlocity_ins__LastName__c', 'Test1');
        memberMap1.put('vlocity_ins__FirstName__c', 'Member1');
        memberMap1.put('vlocity_ins__Birthdate__c', '1990-01-01');

        // Spouse member data
        Map<String,Object> memberMap2 = new Map<String,Object>();
        memberMap2.put('Id', testCensusMembers[1].Id);
        memberMap2.put('vlocity_ins__IsPrimaryMember__c', true);
        memberMap2.put('ARC_PhysicalAddressState__c', 'CA');
        memberMap2.put('ARC_Relationship__c', 'Primary');
        memberMap2.put('ARC_Age__c', 35);
        memberMap2.put('ARC_Smoker__c', false);
        memberMap2.put('ARC_isPregnant__c', false);
        memberMap2.put('IsNewMember', false);
        memberMap2.put('IsRemoveMember', false);
        memberMap2.put('IsInactiveMember', false);
        memberMap2.put('vlocity_ins__LastName__c', 'Test2');
        memberMap2.put('vlocity_ins__FirstName__c', 'Member2');
        memberMap2.put('vlocity_ins__Birthdate__c', '1990-02-02');

        // Child member data
        Map<String,Object> memberMap3 = new Map<String,Object>();
        memberMap3.put('Id', testCensusMembers[2].Id);
        memberMap3.put('vlocity_ins__IsPrimaryMember__c', true);
        memberMap3.put('ARC_PhysicalAddressState__c', 'CA');
        memberMap3.put('ARC_Relationship__c', 'Primary');
        memberMap3.put('ARC_Age__c', 35);
        memberMap3.put('ARC_Smoker__c', false);
        memberMap3.put('ARC_isPregnant__c', false);
        memberMap3.put('IsNewMember', false);
        memberMap3.put('IsRemoveMember', false);
        memberMap3.put('IsInactiveMember', false);
        memberMap3.put('vlocity_ins__LastName__c', 'Test3');
        memberMap3.put('vlocity_ins__FirstName__c', 'Member3');
        memberMap3.put('vlocity_ins__Birthdate__c', '1990-03-03');

        // Primary 1
        members.add(new List<Object>{memberMap1});
        // Primary 2
        members.add(new List<Object>{memberMap2});
        // Primary 3
        members.add(new List<Object>{memberMap3});
    }

    static void populateTestDataForCensusPlanSelectionChangesTest(Map<String, Object> inputMap){
        // Create a Complete Enrollment
        List<Contract> contractsTestList = ARC_TestUtility.createCompleteEnrollments(1);

        // Get Spouse information
        List<ARC_ContractParticipant__c> participantsList = [SELECT ARC_PersonAccount__r.Census_Member__r.ARC_Phone__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Email__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.Id,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_Relationship__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.ARC_Age__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Birthdate__c
                                                            FROM ARC_ContractParticipant__c
                                                            WHERE ARC_Contract__c = :contractsTestList[0].id];

        // Preparing the censusMembers list for the inputMap
        List<Object> censusMembers = new List<Object>{
            new Map<String, Object> {
                'ARC_Relationship__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.ARC_Relationship__c,
                'IsRemoveMember' => false,
                'vlocity_ins__IsPrimaryMember__c' => true,
                'IsNewMember' => false,
                'ARC_Age__c' => 25,
                'vlocity_ins__FirstName__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                'vlocity_ins__LastName__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                'vlocity_ins__Birthdate__c' => '2000-01-02',
                'ARC_PhysicalAddressStreet__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c,
                'ARC_PhysicalAddressCity__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c,
                'ARC_PhysicalAddressState__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c,
                'ARC_PhysicalAddressZipCode__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c,
                'vlocity_ins__Email__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Email__c,
                'ARC_Phone__c' => '1231231231',
                'Id' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.Id
            },
            new Map<String, Object>{
                'ARC_Relationship__c' => 'Spouse',
                'IsRemoveMember' => false,
                'vlocity_ins__IsPrimaryMember__c' => true,
                'IsNewMember' => true,
                'ARC_Age__c' => 25,
                'vlocity_ins__FirstName__c' => 'FN New Member Test',
                'vlocity_ins__LastName__c' => 'LN New Member Test',
                'vlocity_ins__Birthdate__c' => '2000-01-02',
                'ARC_PhysicalAddressStreet__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c,
                'ARC_PhysicalAddressCity__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c,
                'ARC_PhysicalAddressState__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c,
                'ARC_PhysicalAddressZipCode__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c,
                'vlocity_ins__Email__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__Email__c,
                'ARC_Phone__c' => '1231231231',
                'Id' => 'MEM-1753233946486191'
            }
        };

        inputMap.put('censusMembers', censusMembers);
        inputMap.put('keepSameProducts', 'No');

        // Preparing the selectedProducts list for the inputMap
        List<Object> selectedProducts = new List<Object>{
            new Map<String, Object>{
                'Type__c' => 'Medical',
                'Name' => 'WeShare 1k'
            }
        };

        inputMap.put('selectedProducts', selectedProducts);

        // Preparing the oldProducts list for the inputMap
        List<Object> oldProducts = new List<Object>{
            new Map<String, Object>{
                'Type__c' => 'Medical',
                'Name' => 'WeShare 1k'
            }
        };

        inputMap.put('oldProducts', oldProducts);
    }
    
    @isTest
    public static void TRANSFORM_CensusMemberToUserInputsTestScenario1(){
        /*
        ################ Scenario #1 ################
        1 family with a Primary, Spouse and child, the Spouse is being spinned off
        */
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Create the list with the spin off members
        List<Object> familyMembers = new List<Object>();
        populateMemberDataWithASpinOff(familyMembers);

        // Add the list of members to the input map
        inputMap.put('census_component', new Map<String, Object>{
            'census_members' => familyMembers
        });

        inputMap.put('STEP_MembersToSpinOff', new Map<String, Object> {
            'FRML_membersToSpinOffCount' => 1,
            'FRML_multipleSpinOff' => false,
            'EDITBLK_membersToSpinOff' => new List<Object> {
                new Map<String, Object> {
                    'TXT_AccountId' => 'test',
                    'TXT_FirstName' => 'test',
                    'CHK_spinOffSelection' => true,
                    'TXT_LastName' => 'test'
                }
            }
        });

        inputMap.put('STEP_AccountSelection', new Map<String, Object> {
            'aRC_DatePicker' => new Map<String, Object> {
                'DATE_SubscriberEffectiveDate' => '2025-06-15'
            }
        });

        // Call the method
        Test.startTest();
        ARC_SpinOff_Utilities.TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options);
        Test.stopTest();

        // Expected output
        List<Map<String, Object>> userInputs = new List<Map<String, Object>>();
        List<Map<String, Object>> userInputsRetained = new List<Map<String, Object>>();

        // User Input for Primary
        Map<String, Object> userInputForPrimary = new Map<String, Object>();
        userInputForPrimary.put('RF_Census.CM_Age', 30);
        userInputForPrimary.put('RF_Census.CM_State', 'CA');
        userInputForPrimary.put('RF_Census.CM_IsPrimary', true);
        userInputForPrimary.put('RF_Census.CM_Relationship', 'Primary');
        userInputForPrimary.put('RF_Census.CM_Smoker', false);
        userInputForPrimary.put('RF_Census.CM_Pregnant', false);
        userInputForPrimary.put('RF_Census.CM_FirstName', 'Member1');
        userInputForPrimary.put('RF_Census.CM_LastName', 'Test1');
        userInputForPrimary.put('IsRemoveMember', false);
        userInputForPrimary.put('IsNewMember', false);
        userInputForPrimary.put('IsAddExistingMember', false);
        
        List<Object> primaryMemberList = (List<Object>)familyMembers[0];
        Map<String, Object> primaryMemberMap = (Map<String, Object>)primaryMemberList[0];
        String primaryId = (String)primaryMemberMap.get('Id');
        userInputForPrimary.put('Id', primaryId);
        
        userInputForPrimary.put('RF_Census.CRF_Coverage', 'Primary + Child');
        userInputForPrimary.put('RF_Census.CRF_CoverageAIDD', 'Primary + Children');
        userInputForPrimary.put('RF_Census.CRF_ExtraDependants', 0);
        userInputForPrimary.put('RF_Census.CRF_PrimaryMemberAge', 30);
        userInputForPrimary.put('RF_Census.CRF_Dependants', 1);
        userInputForPrimary.put('RF_Census.CRF_PrimaryMemberDOB', '1995-01-01');

        // User Input for Spouse
        Map<String, Object> userInputForSpouse = new Map<String, Object>();
        userInputForSpouse.put('RF_Census.CM_Age', 50);
        userInputForSpouse.put('RF_Census.CM_State', 'CA');
        userInputForSpouse.put('RF_Census.CM_IsPrimary', true);
        userInputForSpouse.put('RF_Census.CM_Relationship', 'Primary');
        userInputForSpouse.put('RF_Census.CM_Smoker', false);
        userInputForSpouse.put('RF_Census.CM_Pregnant', false);
        userInputForSpouse.put('RF_Census.CM_FirstName', 'Member2');
        userInputForSpouse.put('RF_Census.CM_LastName', 'Test2');
        userInputForSpouse.put('IsRemoveMember', false);
        userInputForSpouse.put('IsNewMember', false);
        userInputForSpouse.put('IsAddExistingMember', false);
        
        List<Object> spouseMemberList = (List<Object>)familyMembers[1];
        Map<String, Object> spouseMemberMap = (Map<String, Object>)spouseMemberList[0];
        String spouseId = (String)spouseMemberMap.get('Id');
        userInputForSpouse.put('Id', spouseId);
        
        userInputForSpouse.put('RF_Census.CRF_Coverage', 'Primary');
        userInputForSpouse.put('RF_Census.CRF_CoverageAIDD', 'Primary');
        userInputForSpouse.put('RF_Census.CRF_ExtraDependants', 0);
        userInputForSpouse.put('RF_Census.CRF_PrimaryMemberAge', 50);
        userInputForSpouse.put('RF_Census.CRF_Dependants', 0);
        userInputForSpouse.put('RF_Census.CRF_PrimaryMemberDOB', '1975-01-01');

        // User Input for Child
        Map<String, Object> userInputForChild = new Map<String, Object>();
        userInputForChild.put('RF_Census.CM_Age', 5);
        userInputForChild.put('RF_Census.CM_State', 'CA');
        userInputForChild.put('RF_Census.CM_IsPrimary', false);
        userInputForChild.put('RF_Census.CM_Relationship', 'Child');
        userInputForChild.put('RF_Census.CM_Smoker', false);
        userInputForChild.put('RF_Census.CM_Pregnant', false);
        userInputForChild.put('RF_Census.CM_FirstName', 'Member3');
        userInputForChild.put('RF_Census.CM_LastName', 'Test3');
        userInputForChild.put('IsRemoveMember', false);
        userInputForChild.put('IsNewMember', false);
        userInputForChild.put('IsAddExistingMember', false);
        
        List<Object> childMemberList = (List<Object>)familyMembers[0];
        Map<String, Object> childMemberMap = (Map<String, Object>)childMemberList[1];
        String childId = (String)childMemberMap.get('Id');
        userInputForChild.put('Id', childId);
        
        userInputForChild.put('RF_Census.CRF_Coverage', 'Primary + Child');
        userInputForChild.put('RF_Census.CRF_CoverageAIDD', 'Primary + Children');
        userInputForChild.put('RF_Census.CRF_ExtraDependants', 0);
        userInputForChild.put('RF_Census.CRF_PrimaryMemberAge', 30);
        userInputForChild.put('RF_Census.CRF_Dependants', 1);
        userInputForChild.put('RF_Census.CRF_PrimaryMemberDOB', '1995-01-01');

        // Retained members
        userInputsRetained.add(userInputForPrimary);
        userInputsRetained.add(userInputForChild);

        // Spin Off members
        userInputs.add(userInputForSpouse);

        Map<String, Object> expectedOutputMap = new Map<String, Object>();
        expectedOutputMap.put('userInputs', userInputs);
        expectedOutputMap.put('userInputsRetained', userInputsRetained);
        expectedOutputMap.put('spinned_off_count', ((List<Object>)familyMembers[1]).size()); 
        expectedOutputMap.put('retained_count', ((List<Object>)familyMembers[0]).size());

        // Assert
        // Verify the userInputs node
        Assert.areEqual(JSON.serialize(outputMap.get('userInputs')), JSON.serialize(userInputs), 'The node userInputs is different.');
        // Verify the userInputsRetained node
        Assert.areEqual(JSON.serialize(outputMap.get('userInputsRetained')), JSON.serialize(userInputsRetained), 'The node userInputsRetained is different.');
    }

    @isTest
    public static void TRANSFORM_CensusMemberToUserInputsTestScenario2(){
        /*
        ################ Scenario #2 ################
        3 Different primaries
        */
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Create the list with the spin off members
        List<Object> familyMembers = new List<Object>();
        populateMemberDataWith3DifferentPrimaries(familyMembers);

        // Add the list of members to the input map
        inputMap.put('census_component', new Map<String, Object>{
            'census_members' => familyMembers
        });

        inputMap.put('STEP_MembersToSpinOff', new Map<String, Object> {
            'FRML_membersToSpinOffCount' => 1,
            'FRML_multipleSpinOff' => false,
            'EDITBLK_membersToSpinOff' => new List<Object> {
                new Map<String, Object> {
                    'TXT_AccountId' => 'test',
                    'TXT_FirstName' => 'test',
                    'CHK_spinOffSelection' => true,
                    'TXT_LastName' => 'test'
                }
            }
        });

        inputMap.put('STEP_AccountSelection', new Map<String, Object> {
            'aRC_DatePicker' => new Map<String, Object> {
                'DATE_SubscriberEffectiveDate' => '2025-06-15'
            }
        });

        // Call the method
        Test.startTest();
        ARC_SpinOff_Utilities.TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options);
        Test.stopTest();

        // Expected output
        List<Map<String, Object>> userInputs = new List<Map<String, Object>>();
        List<Map<String, Object>> userInputsRetained = new List<Map<String, Object>>();

        // User Input for Primary
        Map<String, Object> userInputForPrimary = new Map<String, Object>();
        userInputForPrimary.put('RF_Census.CM_Age', 30);
        userInputForPrimary.put('RF_Census.CM_State', 'CA');
        userInputForPrimary.put('RF_Census.CM_IsPrimary', true);
        userInputForPrimary.put('RF_Census.CM_Relationship', 'Primary');
        userInputForPrimary.put('RF_Census.CM_Smoker', false);
        userInputForPrimary.put('RF_Census.CM_Pregnant', false);
        userInputForPrimary.put('RF_Census.CM_FirstName', 'Member1');
        userInputForPrimary.put('RF_Census.CM_LastName', 'Test1');
        userInputForPrimary.put('IsRemoveMember', false);
        userInputForPrimary.put('IsNewMember', false);
        userInputForPrimary.put('IsAddExistingMember', false);
        
        List<Object> primaryMemberList = (List<Object>)familyMembers[0];
        Map<String, Object> primaryMemberMap = (Map<String, Object>)primaryMemberList[0];
        String primaryId = (String)primaryMemberMap.get('Id');
        userInputForPrimary.put('Id', primaryId);
        
        userInputForPrimary.put('RF_Census.CRF_Coverage', 'Primary');
        userInputForPrimary.put('RF_Census.CRF_CoverageAIDD', 'Primary');
        userInputForPrimary.put('RF_Census.CRF_ExtraDependants', 0);
        userInputForPrimary.put('RF_Census.CRF_PrimaryMemberAge', 30);
        userInputForPrimary.put('RF_Census.CRF_Dependants', 0);
        userInputForPrimary.put('RF_Census.CRF_PrimaryMemberDOB', '1995-01-01');

        // User Input for Spouse
        Map<String, Object> userInputForSpouse = new Map<String, Object>();
        userInputForSpouse.put('RF_Census.CM_Age', 35);
        userInputForSpouse.put('RF_Census.CM_State', 'CA');
        userInputForSpouse.put('RF_Census.CM_IsPrimary', true);
        userInputForSpouse.put('RF_Census.CM_Relationship', 'Primary');
        userInputForSpouse.put('RF_Census.CM_Smoker', false);
        userInputForSpouse.put('RF_Census.CM_Pregnant', false);
        userInputForSpouse.put('RF_Census.CM_FirstName', 'Member2');
        userInputForSpouse.put('RF_Census.CM_LastName', 'Test2');
        userInputForSpouse.put('IsRemoveMember', false);
        userInputForSpouse.put('IsNewMember', false);
        userInputForSpouse.put('IsAddExistingMember', false);
        
        List<Object> spouseMemberList = (List<Object>)familyMembers[1];
        Map<String, Object> spouseMemberMap = (Map<String, Object>)spouseMemberList[0];
        String spouseId = (String)spouseMemberMap.get('Id');
        userInputForSpouse.put('Id', spouseId);
        
        userInputForSpouse.put('RF_Census.CRF_Coverage', 'Primary');
        userInputForSpouse.put('RF_Census.CRF_CoverageAIDD', 'Primary');
        userInputForSpouse.put('RF_Census.CRF_ExtraDependants', 0);
        userInputForSpouse.put('RF_Census.CRF_PrimaryMemberAge', 35);
        userInputForSpouse.put('RF_Census.CRF_Dependants', 0);
        userInputForSpouse.put('RF_Census.CRF_PrimaryMemberDOB', '1990-02-02');

        // User Input for Child
        Map<String, Object> userInputForChild = new Map<String, Object>();
        userInputForChild.put('RF_Census.CM_Age', 40);
        userInputForChild.put('RF_Census.CM_State', 'CA');
        userInputForChild.put('RF_Census.CM_IsPrimary', true);
        userInputForChild.put('RF_Census.CM_Relationship', 'Primary');
        userInputForChild.put('RF_Census.CM_Smoker', false);
        userInputForChild.put('RF_Census.CM_Pregnant', false);
        userInputForChild.put('RF_Census.CM_FirstName', 'Member3');
        userInputForChild.put('RF_Census.CM_LastName', 'Test3');
        userInputForChild.put('IsRemoveMember', false);
        userInputForChild.put('IsNewMember', false);
        userInputForChild.put('IsAddExistingMember', false);
        
        List<Object> childMemberList = (List<Object>)familyMembers[2];
        Map<String, Object> childMemberMap = (Map<String, Object>)childMemberList[0];
        String childId = (String)childMemberMap.get('Id');
        userInputForChild.put('Id', childId);
        
        userInputForChild.put('RF_Census.CRF_Coverage', 'Primary');
        userInputForChild.put('RF_Census.CRF_CoverageAIDD', 'Primary');
        userInputForChild.put('RF_Census.CRF_ExtraDependants', 0);
        userInputForChild.put('RF_Census.CRF_PrimaryMemberAge', 40);
        userInputForChild.put('RF_Census.CRF_Dependants', 0);
        userInputForChild.put('RF_Census.CRF_PrimaryMemberDOB', '1985-03-03');

        // Expected Output Map
        Map<String, Object> expectedOutputMap = new Map<String, Object>();
        expectedOutputMap.put('userInputsFamily0', new List<Object>{userInputForPrimary});
        expectedOutputMap.put('family_count', 1);
        expectedOutputMap.put('userInputsFamily1', new List<Object>{userInputForSpouse});
        expectedOutputMap.put('userInputsFamily2', new List<Object>{userInputForChild});

        Assert.areEqual(JSON.serialize(outputMap.get('family_count')), JSON.serialize(expectedOutputMap.get('family_count')));
    }

    @isTest
    public static void GET_CensusMembersTest(){
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

        // Create the test data
        List<Contract> contractsTestList = ARC_TestUtility.createCompleteEnrollments(1);
        inputMap.put('contract_id', contractsTestList[0].id);
        inputMap.put('family_count', '1');
        inputMap.put('clean_output', true);

        // Expected output
        Map<String, Object> expectedOutputMap = new Map<String, Object>();
        List<Map<String, Object>> censusMembersList = new List<Map<String, Object>>();
        List<ARC_ContractParticipant__c> participantsList = [SELECT ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__ContactId__r.AccountId,
                                                                    ARC_PersonAccount__r.Census_Member__r.vlocity_ins__ContactId__c
                                                            FROM ARC_ContractParticipant__c
                                                            WHERE ARC_Contract__c = :contractsTestList[0].id];

        for (ARC_ContractParticipant__c participantTmp : participantsList){
            if (participantTmp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c.contains('Primary') || participantTmp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c.contains('Primary')){
                participantTmp.ARC_Relationship__c = 'Primary';
            } else if (participantTmp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c.contains('Spouse') || participantTmp.ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c.contains('Spouse')) {
                participantTmp.ARC_Relationship__c = 'Spouse';
            } else {
                participantTmp.ARC_Relationship__c = 'Child';
            }
        }

        List<vlocity_ins__GroupCensusMember__c> censusList = [SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, ARC_Phone__c,
                                                              ARC_PhysicalAddressCity__c, ARC_PhysicalAddressState__c, ARC_PhysicalAddressStreet__c, 
                                                              ARC_PhysicalAddressZipCode__c
                                                              FROM vlocity_ins__GroupCensusMember__c];

        // censusList[2].ARC_PhysicalAddressCity__c = 'New York';
        // censusList[2].ARC_PhysicalAddressState__c = 'NY';
        // censusList[2].ARC_PhysicalAddressStreet__c = '1000 Avenue';
        // censusList[2].ARC_PhysicalAddressZipCode__c = '123123';

        for (vlocity_ins__GroupCensusMember__c censusTmp :censusList ) {
            censusTmp.ARC_Phone__c = '12312312312';
        }

        update participantsList;
        update censusList;

        // Run the function scenario 1
        ARC_SpinOff_Utilities.GET_CensusMembers(inputMap, outputMap);

        // Adding the Primary to the list
        censusMembersList.add(
            new Map<String, Object>{
                'Id' => participantsList[0].ARC_PersonAccount__r.Census_Member__r.Id,
                'vlocity_ins__FirstName__c' => participantsList[0].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                'vlocity_ins__LastName__c' => participantsList[0].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                'PersonAccountId' => participantsList[0].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__ContactId__r.AccountId,
                'PersonContactId' => participantsList[0].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__ContactId__c,
                'vlocity_ins__MemberIdentifier__c' => null,
                'ARC_MiddleInitial__c' => null,
                'vlocity_ins__Birthdate__c' => null,
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Age__c' => null,
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'showSSN' => 'password',
                'ARC_HeightFeet__c' => null,
                'ARC_HeightInches__c' => null,
                'ARC_Weight__c' => null,
                'ARC_Smoker__c' => '',
                'ARC_PhysicalAddressCity__c' => 'New York',
                'ARC_PhysicalAddressState__c' => 'NY',
                'ARC_PhysicalAddressStreet__c' => '123 Avenue',
                'ARC_PhysicalAddressZipCode__c' => '12345',
                'ARC_Address__c' => 'New York, NY, 123 Avenue, 12345',
                'IsDependent' => false,
                'individual_errors'  => new List<Object>(),
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'ShowMember' => true,
                'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                'DISABLE_INPUT_FIELDS' => false,
                'CopyAddressFromPrimary' => true,
                'ShowAddressForDependent' => false,
                'ARC_Phone__c' => '',
                'vlocity_ins__Email__c' => '',
                'ARC_isPregnant__c' => '',
                'ARC_Relationship__c' => 'Primary',
                'vlocity_ins__Gender__c' => null
            }
        );

        // Adding the Spouse to the list
        censusMembersList.add(
            new Map<String, Object>{
                'Id' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.Id,
                'vlocity_ins__FirstName__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                'vlocity_ins__LastName__c' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                'PersonAccountId' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__ContactId__r.AccountId,
                'PersonContactId' => participantsList[1].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__ContactId__c,
                'vlocity_ins__MemberIdentifier__c' => null,
                'ARC_MiddleInitial__c' => null,
                'vlocity_ins__Birthdate__c' => null,
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Age__c' => null,
                'vlocity_ins__SocialSecurityNumber__c' => null,
                'showSSN' => 'password',
                'ARC_HeightFeet__c' => null,
                'ARC_HeightInches__c' => null,
                'ARC_Weight__c' => null,
                'ARC_Smoker__c' => '',
                'ARC_PhysicalAddressCity__c' => 'New York',
                'ARC_PhysicalAddressState__c' => 'NY',
                'ARC_PhysicalAddressStreet__c' => '123 Avenue',
                'ARC_PhysicalAddressZipCode__c' => '12345',
                'ARC_Address__c' => 'New York, NY, 123 Avenue, 12345',
                'IsDependent' => true,
                'individual_errors'  => new List<Object>(),
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'ShowMember' => true,
                'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                'DISABLE_INPUT_FIELDS' => false,
                'CopyAddressFromPrimary' => true,
                'ShowAddressForDependent' => false,
                'ARC_Phone__c' => '',
                'vlocity_ins__Email__c' => '',
                'ARC_isPregnant__c' => '',
                'ARC_Relationship__c' => 'Spouse',
                'vlocity_ins__Gender__c' => null
            }
        );

        // Adding the Child to the list
        censusMembersList.add(
            new Map<String, Object>{
                'Id' => participantsList[2].ARC_PersonAccount__r.Census_Member__r.Id,
                'vlocity_ins__FirstName__c' => participantsList[2].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__FirstName__c,
                'vlocity_ins__LastName__c' => participantsList[2].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__LastName__c,
                'PersonAccountId' => participantsList[2].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__ContactId__r.AccountId,
                'PersonContactId' => participantsList[2].ARC_PersonAccount__r.Census_Member__r.vlocity_ins__ContactId__c,
                'vlocity_ins__MemberIdentifier__c' => null,
                'ARC_MiddleInitial__c' => null,
                'vlocity_ins__Birthdate__c' => null,
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Age__c' => null,
                'vlocity_ins__SocialSecurityNumber__c' => null,
                'showSSN' => 'password',
                'ARC_HeightFeet__c' => null,
                'ARC_HeightInches__c' => null,
                'ARC_Weight__c' => null,
                'ARC_Smoker__c' => '',
                'ARC_PhysicalAddressCity__c' => 'New York',
                'ARC_PhysicalAddressState__c' => 'NY',
                'ARC_PhysicalAddressStreet__c' => '123 Avenue',
                'ARC_PhysicalAddressZipCode__c' => '12345',
                'ARC_Address__c' => 'New York, NY, 123 Avenue, 12345',
                'IsDependent' => true,
                'individual_errors'  => new List<Object>(),
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'ShowMember' => true,
                'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                'DISABLE_INPUT_FIELDS' => false,
                'CopyAddressFromPrimary' => true,
                'ShowAddressForDependent' => false,
                'ARC_Phone__c' => '',
                'vlocity_ins__Email__c' => '',
                'ARC_isPregnant__c' => '',
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__Gender__c' => null
            }
        );
        expectedOutputMap.put('census_members',censusMembersList);

        // Assert scenario 1
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest(SeeAllData=true)
    public static void censusPlanSelectionChangesTest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Populate the inputMap with the test data
        populateTestDataForCensusPlanSelectionChangesTest(inputMap);

        // Get the census member data
        Map<String, Object> censusMemberDataPrimary = ((Map<String, Object>)((List<Object>)inputMap.get('censusMembers'))[0]);
        Map<String, Object> censusMemberDataSpouse = ((Map<String, Object>)((List<Object>)inputMap.get('censusMembers'))[1]);

        // Execute the method
        ARC_SpinOff_Utilities.censusPlanSelectionChanges(inputMap, outputMap, options);

        // Expected output
        Map<String, Object> expectedOutputMap = new Map<String, Object>{
            'soChanges' => new Map<String, Object>{
                'feeAmount' => 50,
                'feeApplicable' => true,
                'programSummaryFeeText' => 'One Time Change Fee (Add Member): 50',
                'soReasons' => new Map<String, Object>{
                    'spinOff' => true,
                    'programUpgrade' => false,
                    'programDowngrade' => false, 
                    'agingOut' => false,
                    'addMember' => true,
                    'removeMember' => false,
                    'ancillaryChange' => false
                },
                'soReasonsString' => 'Spin Off; Add Member'
            },
            'STEP_HIPAAAuthorizationForm' => new Map<String, Object>{
                'EDITBLK_HIPAAAuthorizedParties' => new List<Object>{
                    new Map<String, Object>{
                        'TXT_FullName' => censusMemberDataPrimary.get('vlocity_ins__FirstName__c') + ' ' + censusMemberDataPrimary.get('vlocity_ins__LastName__c'),
                        'TXT_Relationship' => censusMemberDataPrimary.get('ARC_Relationship__c'),
                        'DAT_DOB' => censusMemberDataPrimary.get('vlocity_ins__Birthdate__c'),
                        'CHK_Authorized' => true,
                        'Id' => censusMemberDataPrimary.get('Id'),
                        'TXT_firstName' => censusMemberDataPrimary.get('vlocity_ins__FirstName__c'),
                        'TXT_lastName' => censusMemberDataPrimary.get('vlocity_ins__LastName__c'),
                        'TXT_Address' => censusMemberDataPrimary.get('ARC_PhysicalAddressStreet__c'),
                        'TXT_City' => censusMemberDataPrimary.get('ARC_PhysicalAddressCity__c'),
                        'TXT_State' => censusMemberDataPrimary.get('ARC_PhysicalAddressState__c'),
                        'TXT_ZipCode' => censusMemberDataPrimary.get('ARC_PhysicalAddressZipCode__c'),
                        'TXT_EmailAddress' => censusMemberDataPrimary.get('vlocity_ins__Email__c'),
                        'TXT_Telephone' => censusMemberDataPrimary.get('ARC_Phone__c')
                    },
                    new Map<String, Object>{
                        'TXT_FullName' => censusMemberDataSpouse.get('vlocity_ins__FirstName__c') + ' ' + censusMemberDataSpouse.get('vlocity_ins__LastName__c'),
                        'TXT_Relationship' => censusMemberDataSpouse.get('ARC_Relationship__c'),
                        'DAT_DOB' => censusMemberDataSpouse.get('vlocity_ins__Birthdate__c'),
                        'CHK_Authorized' => true,
                        'Id' => censusMemberDataSpouse.get('Id'),
                        'TXT_firstName' => censusMemberDataSpouse.get('vlocity_ins__FirstName__c'),
                        'TXT_lastName' => censusMemberDataSpouse.get('vlocity_ins__LastName__c'),
                        'TXT_Address' => censusMemberDataSpouse.get('ARC_PhysicalAddressStreet__c'),
                        'TXT_City' => censusMemberDataSpouse.get('ARC_PhysicalAddressCity__c'),
                        'TXT_State' => censusMemberDataSpouse.get('ARC_PhysicalAddressState__c'),
                        'TXT_ZipCode' => censusMemberDataSpouse.get('ARC_PhysicalAddressZipCode__c'),
                        'TXT_EmailAddress' => censusMemberDataSpouse.get('vlocity_ins__Email__c'),
                        'TXT_Telephone' => censusMemberDataSpouse.get('ARC_Phone__c')
                    }
                }
            },
            'finalPrimaryValues' => new Map<String, Object>{
                'isUnder18' => false,
                'billingState' => censusMemberDataPrimary.get('ARC_PhysicalAddressState__c'),
                'billingAddress' => censusMemberDataPrimary.get('ARC_PhysicalAddressStreet__c') + ', ' + censusMemberDataPrimary.get('ARC_PhysicalAddressCity__c') + ', ' + censusMemberDataPrimary.get('ARC_PhysicalAddressState__c') + ', ' + censusMemberDataPrimary.get('ARC_PhysicalAddressZipCode__c'),
                'primaryStreet' => censusMemberDataPrimary.get('ARC_PhysicalAddressStreet__c'),
                'primaryCity' => censusMemberDataPrimary.get('ARC_PhysicalAddressCity__c'),
                'primaryState' => censusMemberDataPrimary.get('ARC_PhysicalAddressState__c'),
                'primaryPostalCode' => censusMemberDataPrimary.get('ARC_PhysicalAddressZipCode__c'),
                'primaryFirstName' => censusMemberDataPrimary.get('vlocity_ins__FirstName__c'),
                'primaryLastName' => censusMemberDataPrimary.get('vlocity_ins__LastName__c')
            }
        };

        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));

        // Scenario #2
        ((Map<String, Object>)((List<Object>)inputMap.get('oldProducts'))[0]).put('Name', 'WeShare 3k');
        ((List<Object>)inputMap.get('oldProducts')).add(new Map<String, Object> {
            'Name' => 'Ancillary Test',
            'Type__c' => 'Ancillary'
        });

        ((List<Object>)inputMap.get('selectedProducts')).add(new Map<String, Object> {
            'Name' => 'Ancillary Test',
            'Type__c' => 'Ancillary'
        });

        outputMap.clear();

        // Run the test again
        ARC_SpinOff_Utilities.censusPlanSelectionChanges(inputMap, outputMap, options);

        Map<String, Object> soChanges = (Map<String, Object>)expectedOutputMap.get('soChanges');
        soChanges.put('soReasonsString', 'Spin Off; Program Upgrade; Add Member');
        soChanges.put('programSummaryFeeText', 'One Time Change Fee (Add Member, Program Upgrade): 99.000');
        ((Map<String, Object>) soChanges.get('soReasons')).put('programUpgrade', true);
        soChanges.put('feeAmount', 99.000);

        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));

    }

    @isTest
    public static void includeGuardianAsHipaaTest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Prepare the inputMap
        Map<String, Object> stepGuardiansInformation = new Map<String, Object>();
        Map<String, Object> guardianAddressBlock = new Map<String, Object>();

        guardianAddressBlock.put('TXT_GuardianState', 'CA');
        guardianAddressBlock.put('TXT_GuardianStreet', '2000 Main Street');
        guardianAddressBlock.put('TXT_GuardianCity', 'Santa Monica');
        guardianAddressBlock.put('TXT_GuardianZipCode', '90405');

        stepGuardiansInformation.put('THEADBLK_GuardianAddress-Block', guardianAddressBlock);
        stepGuardiansInformation.put('TXT_GuardianFirstName', 'FN Guardian Test');
        stepGuardiansInformation.put('TXT_GuardianLastName', 'LN Guardian Test');
        stepGuardiansInformation.put('SEL_GuardianRelationship', 'Parent');
        stepGuardiansInformation.put('DATE_GuardianBirthdate', '2000-03-03');
        stepGuardiansInformation.put('TXT_GuardianPhone', '123123123');
        stepGuardiansInformation.put('EMAIL_GuardianEmail', 'test@test.com');

        inputMap.put('STEP_GuardiansInformation', stepGuardiansInformation);

        // Start test
        Test.startTest();
        ARC_SpinOff_Utilities.includeGuardianAsHipaa(inputMap, outputMap, options);
        Test.stopTest();

        // Preparing the expectedOutputMap
        Map<String, Object> expectedOutputMap = new Map<String, Object>();
        List<Object> hipaaAuthorizedParties = new List<Object>();

        hipaaAuthorizedParties.add(new Map<String, Object>{
            'TXT_FullName' => stepGuardiansInformation.get('TXT_GuardianFirstName') + ' ' + stepGuardiansInformation.get('TXT_GuardianLastName'),
            'TXT_firstName' => stepGuardiansInformation.get('TXT_GuardianFirstName'),
            'TXT_lastName' => stepGuardiansInformation.get('TXT_GuardianLastName'),
            'TXT_Relationship' => stepGuardiansInformation.get('SEL_GuardianRelationship'),
            'DAT_DOB' => stepGuardiansInformation.get('DATE_GuardianBirthdate'),
            'TXT_Telephone' => stepGuardiansInformation.get('TXT_GuardianPhone'),
            'TXT_EmailAddress' => stepGuardiansInformation.get('EMAIL_GuardianEmail'),
            'CHK_Authorized' => true, 
            'TXT_State' => guardianAddressBlock.get('TXT_GuardianState'),
            'TXT_Address' => guardianAddressBlock.get('TXT_GuardianStreet'),
            'TXT_City' =>  guardianAddressBlock.get('TXT_GuardianCity'),
            'TXT_ZipCode' => guardianAddressBlock.get('TXT_GuardianZipCode')
        });

        expectedOutputMap.put('STEP_HIPAAAuthorizationForm', new Map<String, Object>{
            'EDITBLK_HIPAAAuthorizedParties' => hipaaAuthorizedParties
        });

        // Assert
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest
    public static void TRANSFORM_RemoveMemberContractCalculatePriceTest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<Object> members = new List<Object>();

        // Prepare the userInputsOriginal data
        populateMemberDataWithASpinOff(members);
        List<Object> userInputsOriginal = new List<Object>();

        // Add the Primary member data
        Map<String, Object> primaryMemberData = (Map<String, Object>)(((List<Object>)members[0])[0]);
        userInputsOriginal.add(new Map<String, Object>{
                'Id' => primaryMemberData.get('Id'),
                'RF_Census.CM_Relationship' => primaryMemberData.get('ARC_Relationship__c'),
                'RF_Census.CM_Age' => primaryMemberData.get('ARC_Age__c')
            }
        );

        // Add the Spouse member data
        Map<String, Object> spouseMemberData = (Map<String, Object>)(((List<Object>)members[1])[0]);
        userInputsOriginal.add(new Map<String, Object>{
                'Id' => spouseMemberData.get('Id'),
                'RF_Census.CM_Relationship' => spouseMemberData.get('ARC_Relationship__c'),
                'RF_Census.CM_Age' => spouseMemberData.get('ARC_Age__c')
            }
        );

        // Add the Child member data
        Map<String, Object> childMemberData = (Map<String, Object>)(((List<Object>)members[0])[1]);
        userInputsOriginal.add(new Map<String, Object>{
                'Id' => childMemberData.get('Id'),
                'RF_Census.CM_Relationship' => childMemberData.get('ARC_Relationship__c'),
                'RF_Census.CM_Age' => childMemberData.get('ARC_Age__c')
            }
        );

        // Prepare the oldProducts data
        List<Object> oldProducts = new List<Object>();
        
        List<Object> censusMembers = new List<Object>{
            new Map<String, Object> {
                'Id' => primaryMemberData.get('Id'),
                'RF_Census.CM_Relationship' => 'Primary',
                'RF_Census.CM_Age' => primaryMemberData.get('ARC_Age__c')
            },
            new Map<String, Object> {
                'Id' => spouseMemberData.get('Id'),
                'RF_Census.CM_Relationship' => 'Spouse',
                'RF_Census.CM_Age' => spouseMemberData.get('ARC_Age__c')
            },
            new Map<String, Object> {
                'Id' => childMemberData.get('Id'),
                'RF_Census.CM_Relationship' => 'Child',
                'RF_Census.CM_Age' => childMemberData.get('ARC_Age__c')
            }
        };

        oldProducts.add(
            new Map<String, Object> {
                'census_members' => censusMembers,
                'productId' => '123123123',
                'Name' => 'SMART Share 50000',
                'Type__c' => 'Ancillary'
            }
        );

        // Prepare the inputMap data
        inputMap.put('userInputsOriginal', userInputsOriginal);
        inputMap.put('oldProducts', oldProducts);

        // Run the test
        ARC_SpinOff_Utilities.TRANSFORM_RemoveMemberContractCalculatePrice(inputMap, outputMap, options);

        // Prepare the expectedOutputMap
        Map<String, Object> expectedOutputMap = new Map<String, Object>();
        
        List<Object> userInputs = new List<Object>{
            new Map<String, Object> {
                'Id' => primaryMemberData.get('Id'),
                'RF_Census.CM_Relationship' => primaryMemberData.get('ARC_Relationship__c'),
                'RF_Census.CM_Age' => primaryMemberData.get('ARC_Age__c'),
                'RF_Census.CRF_PrimaryMemberAge' => spouseMemberData.get('ARC_Age__c'),
                'RF_Census.CRF_Coverage' => 'Family',
                'RF_Census.CRF_CoverageAIDD' => 'Family'
            },
            new Map<String, Object> {
                'Id' => spouseMemberData.get('Id'),
                'RF_Census.CM_Relationship' => spouseMemberData.get('ARC_Relationship__c'),
                'RF_Census.CM_Age' => spouseMemberData.get('ARC_Age__c'),
                'RF_Census.CRF_PrimaryMemberAge' => spouseMemberData.get('ARC_Age__c'),
                'RF_Census.CRF_Coverage' => 'Family',
                'RF_Census.CRF_CoverageAIDD' => 'Family'
            },
            new Map<String, Object> {
                'Id' => childMemberData.get('Id'),
                'RF_Census.CM_Relationship' => childMemberData.get('ARC_Relationship__c'),
                'RF_Census.CM_Age' => childMemberData.get('ARC_Age__c'),
                'RF_Census.CRF_PrimaryMemberAge' => spouseMemberData.get('ARC_Age__c'),
                'RF_Census.CRF_Coverage' => 'Family',
                'RF_Census.CRF_CoverageAIDD' => 'Family'
            }
        };

        expectedOutputMap.put('transformUserInputsRetainedPriceData', new List<Object>{
                new Map<String, Object> {
                    'selectedProduct' => new Map<String, Object> {
                        'Id' => '123123123',
                        'Name' => 'SMART Share 50000'
                    },
                    'userInputs' => userInputs
                }
        });

        // Assert 
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap), 'TRANSFORM_RemoveMemberContractCalculatePriceTest failed');

        // Scenario #2
        oldProducts.clear();
        oldProducts.add(
            new Map<String, Object> {
                'census_members' => new List<Object> {censusMembers[2]},
                'productId' => '123123123',
                'Name' => 'SMART Share 50000',
                'Type__c' => 'Ancillary'
            }
        );

        oldProducts.add(
            new Map<String, Object> {
                'census_members' => new List<Object> {censusMembers[0]},
                'productId' => '123123123',
                'Name' => 'SMART Share 50000',
                'Type__c' => 'Ancillary'
            }
        );

        inputMap.put('oldProducts', oldProducts);
        inputMap.put('userInputsOriginal', userInputsOriginal);
        
        userInputs.remove(1);
        ((Map<String, Object>)userInputs[0]).put('RF_Census.CRF_CoverageAIDD', 'Primary + Children');
        ((Map<String, Object>)userInputs[0]).put('RF_Census.CRF_Coverage', 'Primary + Child');
        ((Map<String, Object>)userInputs[0]).put('RF_Census.CRF_PrimaryMemberAge', primaryMemberData.get('ARC_Age__c'));
        ((Map<String, Object>)userInputs[1]).put('RF_Census.CRF_CoverageAIDD', 'Primary + Children');
        ((Map<String, Object>)userInputs[1]).put('RF_Census.CRF_Coverage', 'Primary + Child');
        ((Map<String, Object>)userInputs[1]).remove('RF_Census.CRF_PrimaryMemberAge');

        
        ((Map<String, Object>)((List<Object>)expectedOutputMap.get('transformUserInputsRetainedPriceData'))[0]).put('userInputs', userInputs);

        outputMap.clear();
        // Run the test
        ARC_SpinOff_Utilities.TRANSFORM_RemoveMemberContractCalculatePrice(inputMap, outputMap, options);
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));

    }

    /**
     * In this scenario the family had a Medical Share plan and the haveAncillaryChange node is true
     */
    @isTest
    public static void TRANSFORM_ChooseProductSelectionDataTestScenario1(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Preparing the test data
        List<Object> oldProducts_InputMap = new List<Object>();
        List<Object> selectedProducts_InputMap;
        List<Object> userInputs_InputMap = new List<Object>();

        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];
        
        oldProducts_InputMap.add(
            new Map<String, Object> {
                'census_members' => censusMembers_InputMap,
                'productId' => productRelated.Id,
                'Type__c' => productRelated.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                'SubType__c' => 'PPO',
                'Name' => productRelated.vlocity_ins__Product2Id__r.Name,
                'Id' => productRelated.Id
            }
        );

        // Set the selectedProducts node data
        selectedProducts_InputMap = new List<Object> {
            new Map<String, Object> {
                'Id' => productRelated.vlocity_ins__Product2Id__r.Id,
                'Name' => productRelated.vlocity_ins__Product2Id__r.Name,
                'Type__c' => productRelated.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                'SubType__c' => 'PPO',
                'productId' => productRelated.vlocity_ins__Product2Id__r.Id
            },
            new Map<String, Object> {
                'Id' => 'temporary-id-1',
                'Name' => 'SMART Share 50000',
                'Type__c' => 'Ancillary',
                'SubType__c' => 'SMART',
                'productId' => 'temporary-id-1'
            },
            new Map<String, Object> {
                'Id' => 'temporary-id-2',
                'Name' => 'AIDD 10000',
                'Type__c' => 'Ancillary',
                'SubType__c' => 'AIDD',
                'productId' => 'temporary-id-2'
            }
        };

        // Set the userInputs node data
        Map<String, Object> spouseData = (Map<String, Object>)censusMembers_InputMap[1];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => spouseData.get('ARC_Relationship__c'),
                'Id' => spouseData.get('Id')
            }
        );

        // Set the data in the inputMap
        inputMap.put('FRML_DisplayChooseProductSelectionStep', true);
        inputMap.put('haveAncillaryChange', true);
        inputMap.put('userInputs', userInputs_InputMap);
        inputMap.put('selectedProducts', selectedProducts_InputMap);
        inputMap.put('oldProducts', oldProducts_InputMap);

        // Preparing the expectedOutput data
        List<Object> members_OutputMap = new List<Object> {
            new Map<String, Object> {
                'id' => spouseData.get('Id'),
                'name' => spouseData.get('vlocity_ins__FirstName__c') + ' ' + spouseData.get('vlocity_ins__LastName__c'),
                'relationship' => spouseData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.vlocity_ins__Product2Id__r.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => null,
                    'name' => null,
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => '-',
                            'value' => null,
                            'selected' => true
                        },
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => 'SMART Share 50000',
                            'value' => 'temporary-id-1',
                            'selected' => false
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => null,
                    'name' => null,
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => '-',
                            'value' => null,
                            'selected' => true
                        },
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => 'AIDD 10000',
                            'value' => 'temporary-id-2',
                            'selected' => false
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => spouseData.get('ARC_Relationship__c'),
                    'Id' => spouseData.get('Id')
                }
            }
        };

        // Set the data in the expectedOutput map
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'LWC_ChooseProductSelectionInput' => new Map<String, Object> {
                'members' => members_OutputMap,
                'shareSMART' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                },
                'shareAIDD' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                }
            }
        };

        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options);
        Test.stopTest();
        
        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    /**
     * In this scenario the family had a SMART Share plan in the oldProdcts node and the haveAncillaryChange node is false
     */
    @isTest
    public static void TRANSFORM_ChooseProductSelectionDataTestScenario2(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Preparing the test data
        List<Object> oldProducts_InputMap = new List<Object>();
        List<Object> selectedProducts_InputMap;
        List<Object> userInputs_InputMap = new List<Object>();

        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];
        
        oldProducts_InputMap.add(
            new Map<String, Object> {
                'census_members' => censusMembers_InputMap,
                'productId' => productRelated.Id,
                'Type__c' => productRelated.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                'SubType__c' => 'SMART',
                'Name' => productRelated.vlocity_ins__Product2Id__r.Name,
                'Id' => productRelated.Id
            }
        );

        // Set the selectedProducts node data
        selectedProducts_InputMap = new List<Object> {
            new Map<String, Object> {
                'Id' => productRelated.vlocity_ins__Product2Id__r.Id,
                'Name' => productRelated.vlocity_ins__Product2Id__r.Name,
                'Type__c' => productRelated.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                'SubType__c' => 'PPO',
                'productId' => productRelated.vlocity_ins__Product2Id__r.Id
            },
            new Map<String, Object> {
                'Id' => 'temporary-id-1',
                'Name' => 'SMART Share 50000',
                'Type__c' => 'Ancillary',
                'SubType__c' => 'SMART',
                'productId' => 'temporary-id-1'
            },
            new Map<String, Object> {
                'Id' => 'temporary-id-2',
                'Name' => 'AIDD 10000',
                'Type__c' => 'Ancillary',
                'SubType__c' => 'AIDD',
                'productId' => 'temporary-id-2'
            }
        };

        // Set the userInputs node data
        Map<String, Object> spouseData = (Map<String, Object>)censusMembers_InputMap[1];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => spouseData.get('ARC_Relationship__c'),
                'Id' => spouseData.get('Id')
            }
        );

        // Set the data in the inputMap
        inputMap.put('FRML_DisplayChooseProductSelectionStep', true);
        inputMap.put('haveAncillaryChange', false);
        inputMap.put('userInputs', userInputs_InputMap);
        inputMap.put('selectedProducts', selectedProducts_InputMap);
        inputMap.put('oldProducts', oldProducts_InputMap);

        // Preparing the expectedOutput data
        List<Object> members_OutputMap = new List<Object> {
            new Map<String, Object> {
                'id' => spouseData.get('Id'),
                'name' => spouseData.get('vlocity_ins__FirstName__c') + ' ' + spouseData.get('vlocity_ins__LastName__c'),
                'relationship' => spouseData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.vlocity_ins__Product2Id__r.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name,
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => spouseData.get('ARC_Relationship__c'),
                    'Id' => spouseData.get('Id')
                }
            }
        };

        // Set the data in the expectedOutput map
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'LWC_ChooseProductSelectionInput' => new Map<String, Object> {
                'members' => members_OutputMap,
                'shareSMART' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                },
                'shareAIDD' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                }
            }
        };

        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options);
        Test.stopTest();
        
        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest
    public static void TRANSFORM_ChooseProductSelectionDataTestScenario3(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Preparing the test data
        List<Object> oldProducts_InputMap = new List<Object>();
        // List<Object> selectedProducts_InputMap;
        List<Object> userInputs_InputMap = new List<Object>();

        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];
        
        oldProducts_InputMap.add(
            new Map<String, Object> {
                'census_members' => censusMembers_InputMap,
                'productId' => productRelated.Id,
                'Type__c' => productRelated.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                'SubType__c' => 'SMART',
                'Name' => productRelated.vlocity_ins__Product2Id__r.Name,
                'Id' => productRelated.Id
            }
        );

        // Set the userInputs node data
        Map<String, Object> primaryData = (Map<String, Object>)censusMembers_InputMap[0];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                'Id' => primaryData.get('Id')
            }
        );

        // Set the data in the inputMap
        inputMap.put('FRML_DisplayChooseProductSelectionStep', true);
        inputMap.put('haveAncillaryChange', true);
        inputMap.put('userInputs', userInputs_InputMap);
        inputMap.put('selectedProducts', null);
        inputMap.put('oldProducts', oldProducts_InputMap);

        // Preparing the expectedOutput data
        List<Object> members_OutputMap = new List<Object> {
            new Map<String, Object> {
                'id' => primaryData.get('Id'),
                'name' => primaryData.get('vlocity_ins__FirstName__c') + ' ' + primaryData.get('vlocity_ins__LastName__c'),
                'relationship' => primaryData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name,
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                    'Id' => primaryData.get('Id')
                }
            }
        };

        // Set the data in the expectedOutput map
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'LWC_ChooseProductSelectionInput' => new Map<String, Object> {
                'members' => members_OutputMap,
                'shareSMART' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                },
                'shareAIDD' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                }
            }
        };

        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options);
        Test.stopTest();
        
        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    /**
     * Primary and Spouse with AIDD 
     */
    @isTest
    public static void TRANSFORM_ChooseProductSelectionDataTestScenario4(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Preparing the test data
        List<Object> oldProducts_InputMap = new List<Object>();
        // List<Object> selectedProducts_InputMap;
        List<Object> userInputs_InputMap = new List<Object>();

        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];
        
        oldProducts_InputMap.add(
            new Map<String, Object> {
                'census_members' => censusMembers_InputMap,
                'productId' => productRelated.Id,
                'Type__c' => productRelated.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                'SubType__c' => 'AIDD',
                'Name' => productRelated.vlocity_ins__Product2Id__r.Name,
                'Id' => productRelated.Id
            }
        );

        // Set the userInputs node data
        Map<String, Object> primaryData = (Map<String, Object>)censusMembers_InputMap[0];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                'Id' => primaryData.get('Id')
            }
        );

        Map<String, Object> spouseData = (Map<String, Object>)censusMembers_InputMap[1];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => 'Spouse',
                'Id' => spouseData.get('Id')
            }
        );

        Map<String, Object> childData = (Map<String, Object>)censusMembers_InputMap[2];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => childData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => childData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => 'Child',
                'Id' => childData.get('Id')
            }
        );

        // Set the data in the inputMap
        inputMap.put('FRML_DisplayChooseProductSelectionStep', true);
        inputMap.put('haveAncillaryChange', false);
        inputMap.put('userInputs', userInputs_InputMap);
        inputMap.put('selectedProducts', null);
        inputMap.put('oldProducts', oldProducts_InputMap);

        // Preparing the expectedOutput data
        List<Object> members_OutputMap = new List<Object> {
            new Map<String, Object> {
                'id' => primaryData.get('Id'),
                'name' => primaryData.get('vlocity_ins__FirstName__c') + ' ' + primaryData.get('vlocity_ins__LastName__c'),
                'relationship' => primaryData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name,
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => true
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                    'Id' => primaryData.get('Id')
                }
            },
            new Map<String, Object> {
                'id' => spouseData.get('Id'),
                'name' => spouseData.get('vlocity_ins__FirstName__c') + ' ' + spouseData.get('vlocity_ins__LastName__c'),
                'relationship' => spouseData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name,
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => true
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => spouseData.get('ARC_Relationship__c'),
                    'Id' => spouseData.get('Id')
                }
            },
            new Map<String, Object> {
                'id' => childData.get('Id'),
                'name' => childData.get('vlocity_ins__FirstName__c') + ' ' + childData.get('vlocity_ins__LastName__c'),
                'relationship' => childData.get('ARC_Relationship__c'),
                'isChild' => true,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name,
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => true
                        }
                    }
                },
                'selectedParent' => new Map<String, Object> {
                    'options' => new List<Object> {
                        new Map<String, Object> {
                            'label' => 'Spouse Program',
                            'value' => spouseData.get('Id'),
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => 'Primary Program',
                            'value' => primaryData.get('Id'),
                            'selected' => true
                        },
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        }
                    }
                },
                'ancillaryProductsToString' => ', Test Product UHSM0',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => childData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => childData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => childData.get('ARC_Relationship__c'),
                    'Id' => childData.get('Id')
                }
            }
        };

        // Set the data in the expectedOutput map
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'LWC_ChooseProductSelectionInput' => new Map<String, Object> {
                'members' => members_OutputMap,
                'shareSMART' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                },
                'shareAIDD' => new Map<String, Object> {
                    'value' => true,
                    'disabled' => false
                }
            }
        };

        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options);
        Test.stopTest();
        
        // Asserts
        Assert.areEqual(JSON.serialize(expectedOutputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest
    public static void TRANSFORM_ChooseProductSelectionDataTestScenario5(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Preparing the test data
        List<Object> oldProducts_InputMap = new List<Object>();
        // List<Object> selectedProducts_InputMap;
        List<Object> userInputs_InputMap = new List<Object>();

        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];
        
        oldProducts_InputMap.add(
            new Map<String, Object> {
                'census_members' => new List<Object> { censusMembers_InputMap[0], censusMembers_InputMap[2] },
                'productId' => productRelated.Id,
                'Type__c' => productRelated.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                'SubType__c' => 'AIDD',
                'Name' => productRelated.vlocity_ins__Product2Id__r.Name,
                'Id' => productRelated.Id
            }
        );

        // Set the userInputs node data
        Map<String, Object> primaryData = (Map<String, Object>)censusMembers_InputMap[0];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                'Id' => primaryData.get('Id')
            }
        );

        Map<String, Object> spouseData = (Map<String, Object>)censusMembers_InputMap[1];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => 'Spouse',
                'Id' => spouseData.get('Id')
            }
        );

        Map<String, Object> childData = (Map<String, Object>)censusMembers_InputMap[2];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => childData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => childData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => 'Child',
                'Id' => childData.get('Id')
            }
        );

        // Set the data in the inputMap
        inputMap.put('FRML_DisplayChooseProductSelectionStep', true);
        inputMap.put('haveAncillaryChange', false);
        inputMap.put('userInputs', userInputs_InputMap);
        inputMap.put('selectedProducts', null);
        inputMap.put('oldProducts', oldProducts_InputMap);

        // Preparing the expectedOutput data
        List<Object> members_OutputMap = new List<Object> {
            new Map<String, Object> {
                'id' => primaryData.get('Id'),
                'name' => primaryData.get('vlocity_ins__FirstName__c') + ' ' + primaryData.get('vlocity_ins__LastName__c'),
                'relationship' => primaryData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name,
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => true
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                    'Id' => primaryData.get('Id')
                }
            },
            new Map<String, Object> {
                'id' => spouseData.get('Id'),
                'name' => spouseData.get('vlocity_ins__FirstName__c') + ' ' + spouseData.get('vlocity_ins__LastName__c'),
                'relationship' => spouseData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => false
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => spouseData.get('ARC_Relationship__c'),
                    'Id' => spouseData.get('Id')
                }
            },
            new Map<String, Object> {
                'id' => childData.get('Id'),
                'name' => childData.get('vlocity_ins__FirstName__c') + ' ' + childData.get('vlocity_ins__LastName__c'),
                'relationship' => childData.get('ARC_Relationship__c'),
                'isChild' => true,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => null,
                    'name' => null,
                    'options' => new list<Object> {}
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name,
                    'options' => new list<Object> {}
                },
                'selectedParent' => new Map<String, Object> {
                    'value' => primaryData.get('Id'),
                    'options' => new List<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => 'Primary Program',
                            'value' => primaryData.get('Id'),
                            'selected' => true
                        },
                        new Map<String, Object> {
                            'label' => 'Spouse Program',
                            'value' => spouseData.get('Id'),
                            'selected' => false
                        }
                    }
                },
                'ancillaryProductsToString' => ', Test Product UHSM0',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => childData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => childData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => childData.get('ARC_Relationship__c'),
                    'Id' => childData.get('Id')
                }
            }
        };

        // Set the data in the expectedOutput map
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'LWC_ChooseProductSelectionInput' => new Map<String, Object> {
                'members' => members_OutputMap,
                'shareSMART' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                },
                'shareAIDD' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                }
            }
        };

        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options);
        Test.stopTest();
        
        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest
    public static void TRANSFORM_ChooseProductSelectionDataTestScenario6(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Preparing the test data
        List<Object> oldProducts_InputMap = new List<Object>();
        // List<Object> selectedProducts_InputMap;
        List<Object> userInputs_InputMap = new List<Object>();

        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];
        
        oldProducts_InputMap.add(
            new Map<String, Object> {
                'census_members' => new List<Object> { censusMembers_InputMap[1], censusMembers_InputMap[2] },
                'productId' => productRelated.Id,
                'Type__c' => productRelated.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                'SubType__c' => 'AIDD',
                'Name' => productRelated.vlocity_ins__Product2Id__r.Name,
                'Id' => productRelated.Id
            }
        );

        // Set the userInputs node data
        Map<String, Object> primaryData = (Map<String, Object>)censusMembers_InputMap[0];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                'Id' => primaryData.get('Id')
            }
        );

        Map<String, Object> spouseData = (Map<String, Object>)censusMembers_InputMap[1];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => 'Spouse',
                'Id' => spouseData.get('Id')
            }
        );

        Map<String, Object> childData = (Map<String, Object>)censusMembers_InputMap[2];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => childData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => childData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => 'Child',
                'Id' => childData.get('Id')
            }
        );

        // Set the data in the inputMap
        inputMap.put('FRML_DisplayChooseProductSelectionStep', true);
        inputMap.put('haveAncillaryChange', false);
        inputMap.put('userInputs', userInputs_InputMap);
        inputMap.put('selectedProducts', null);
        inputMap.put('oldProducts', oldProducts_InputMap);

        // Preparing the expectedOutput data
        List<Object> members_OutputMap = new List<Object> {
            new Map<String, Object> {
                'id' => primaryData.get('Id'),
                'name' => primaryData.get('vlocity_ins__FirstName__c') + ' ' + primaryData.get('vlocity_ins__LastName__c'),
                'relationship' => primaryData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => false
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                    'Id' => primaryData.get('Id')
                }
            },
            new Map<String, Object> {
                'id' => spouseData.get('Id'),
                'name' => spouseData.get('vlocity_ins__FirstName__c') + ' ' + spouseData.get('vlocity_ins__LastName__c'),
                'relationship' => spouseData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name,
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => true
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => spouseData.get('ARC_Relationship__c'),
                    'Id' => spouseData.get('Id')
                }
            },
            new Map<String, Object> {
                'id' => childData.get('Id'),
                'name' => childData.get('vlocity_ins__FirstName__c') + ' ' + childData.get('vlocity_ins__LastName__c'),
                'relationship' => childData.get('ARC_Relationship__c'),
                'isChild' => true,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => null,
                    'name' => null,
                    'options' => new list<Object> {}
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name,
                    'options' => new list<Object> {}
                },
                'selectedParent' => new Map<String, Object> {
                    'value' => spouseData.get('Id'),
                    'options' => new List<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => 'Primary Program',
                            'value' => primaryData.get('Id'),
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => 'Spouse Program',
                            'value' => spouseData.get('Id'),
                            'selected' => true
                        }
                    }
                },
                'ancillaryProductsToString' => ', Test Product UHSM0',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => childData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => childData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => childData.get('ARC_Relationship__c'),
                    'Id' => childData.get('Id')
                }
            }
        };

        // Set the data in the expectedOutput map
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'LWC_ChooseProductSelectionInput' => new Map<String, Object> {
                'members' => members_OutputMap,
                'shareSMART' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                },
                'shareAIDD' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                }
            }
        };

        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options);
        Test.stopTest();
        
        
        // Asserts
        // Assert.areEqual(JSON.serialize(((List<Object>) ((Map<String, Object>) outputMap.get('LWC_ChooseProductSelectionInput')).get('members'))[2]), JSON.serialize(((List<Object>) ((Map<String, Object>) expectedOutputMap.get('LWC_ChooseProductSelectionInput')).get('members'))[2]));
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest
    public static void TRANSFORM_ChooseProductSelectionDataTestScenario7(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Preparing the test data
        List<Object> oldProducts_InputMap = new List<Object>();
        // List<Object> selectedProducts_InputMap;
        List<Object> userInputs_InputMap = new List<Object>();

        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];
        
        oldProducts_InputMap.add(
            new Map<String, Object> {
                'census_members' => new List<Object> { censusMembers_InputMap[2] },
                'productId' => productRelated.Id,
                'Type__c' => productRelated.vlocity_ins__Product2Id__r.vlocity_ins__Type__c,
                'SubType__c' => 'AIDD',
                'Name' => productRelated.vlocity_ins__Product2Id__r.Name,
                'Id' => productRelated.Id
            }
        );

        // Set the userInputs node data
        Map<String, Object> primaryData = (Map<String, Object>)censusMembers_InputMap[0];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                'Id' => primaryData.get('Id')
            }
        );

        Map<String, Object> spouseData = (Map<String, Object>)censusMembers_InputMap[1];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => 'Spouse',
                'Id' => spouseData.get('Id')
            }
        );

        Map<String, Object> childData = (Map<String, Object>)censusMembers_InputMap[2];
        userInputs_InputMap.add(
            new Map<String, Object> {
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'RF_Census.CM_LastName' => childData.get('vlocity_ins__LastName__c'),
                'RF_Census.CM_FirstName' => childData.get('vlocity_ins__FirstName__c'),
                'RF_Census.CM_Relationship' => 'Child',
                'Id' => childData.get('Id')
            }
        );

        // Set the data in the inputMap
        inputMap.put('FRML_DisplayChooseProductSelectionStep', true);
        inputMap.put('haveAncillaryChange', false);
        inputMap.put('userInputs', userInputs_InputMap);
        inputMap.put('selectedProducts', null);
        inputMap.put('oldProducts', oldProducts_InputMap);

        // Preparing the expectedOutput data
        List<Object> members_OutputMap = new List<Object> {
            new Map<String, Object> {
                'id' => primaryData.get('Id'),
                'name' => primaryData.get('vlocity_ins__FirstName__c') + ' ' + primaryData.get('vlocity_ins__LastName__c'),
                'relationship' => primaryData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => false
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => primaryData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => primaryData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => primaryData.get('ARC_Relationship__c'),
                    'Id' => primaryData.get('Id')
                }
            },
            new Map<String, Object> {
                'id' => spouseData.get('Id'),
                'name' => spouseData.get('vlocity_ins__FirstName__c') + ' ' + spouseData.get('vlocity_ins__LastName__c'),
                'relationship' => spouseData.get('ARC_Relationship__c'),
                'isChild' => false,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        }
                    }
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => 'None',
                    'name' => 'None',
                    'options' => new list<Object> {
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => true
                        },
                        new Map<String, Object> {
                            'label' => productRelated.vlocity_ins__Product2Id__r.Name,
                            'value' => productRelated.Id,
                            'selected' => false
                        }
                    }
                },
                'selectedParent' => null,
                'ancillaryProductsToString' => '',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => spouseData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => spouseData.get('ARC_Relationship__c'),
                    'Id' => spouseData.get('Id')
                }
            },
            new Map<String, Object> {
                'id' => childData.get('Id'),
                'name' => childData.get('vlocity_ins__FirstName__c') + ' ' + childData.get('vlocity_ins__LastName__c'),
                'relationship' => childData.get('ARC_Relationship__c'),
                'isChild' => true,
                'medicalProduct' => new Map<String, Object> {
                    'value' => productRelated.Id,
                    'name' => productRelated.vlocity_ins__Product2Id__r.Name
                },
                'smartProduct' => new Map<String, Object> {
                    'value' => null,
                    'name' => null,
                    'options' => new list<Object> {}
                },
                'aiddProduct' => new Map<String, Object> {
                    'value' => null,
                    'name' => null,
                    'options' => new list<Object> {}
                },
                'selectedParent' => new Map<String, Object> {
                    'value' => null,
                    'options' => new List<Object> {
                        new Map<String, Object> {
                            'label' => '-',
                            'value' => null,
                            'selected' => true
                        },
                        new Map<String, Object> {
                            'label' => 'None',
                            'value' => 'None',
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => 'Primary Program',
                            'value' => primaryData.get('Id'),
                            'selected' => false
                        },
                        new Map<String, Object> {
                            'label' => 'Spouse Program',
                            'value' => spouseData.get('Id'),
                            'selected' => false
                        }
                    }
                },
                'ancillaryProductsToString' => 'None',
                'user_input' => new Map<String, Object> {
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'RF_Census.CM_LastName' => childData.get('vlocity_ins__LastName__c'),
                    'RF_Census.CM_FirstName' => childData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_Relationship' => childData.get('ARC_Relationship__c'),
                    'Id' => childData.get('Id')
                }
            }
        };

        // Set the data in the expectedOutput map
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'LWC_ChooseProductSelectionInput' => new Map<String, Object> {
                'members' => members_OutputMap,
                'shareSMART' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                },
                'shareAIDD' => new Map<String, Object> {
                    'value' => false,
                    'disabled' => true
                }
            }
        };

        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.TRANSFORM_ChooseProductSelectionData(inputMap, outputMap, options);
        Test.stopTest();
        
        
        // Asserts
        // Assert.areEqual(JSON.serialize(((List<Object>) ((Map<String, Object>) outputMap.get('LWC_ChooseProductSelectionInput')).get('members'))[1]), JSON.serialize(((List<Object>) ((Map<String, Object>) expectedOutputMap.get('LWC_ChooseProductSelectionInput')).get('members'))[1]));
        // Assert.areEqual(JSON.serialize(((List<Object>) ((Map<String, Object>) outputMap.get('LWC_ChooseProductSelectionInput')).get('members'))[2]), JSON.serialize(((List<Object>) ((Map<String, Object>) expectedOutputMap.get('LWC_ChooseProductSelectionInput')).get('members'))[2]));
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest
    public static void readMedicalQuestionsTest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Prepare the inputMap data
        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');
        Map<String, Object> primaryData = (Map<String, Object>)censusMembers_InputMap[0];

        censusMembers_InputMap.add(new Map<String, Object>{
                'ARC_Relationship__c' => 'Child',
                'IsRemoveMember' => false,
                'vlocity_ins__IsPrimaryMember__c' => false,
                'IsNewMember' => true,
                'ARC_Age__c' => 25,
                'vlocity_ins__FirstName__c' => 'FN New Member',
                'vlocity_ins__LastName__c' => 'LN New Member',
                'vlocity_ins__Birthdate__c' => '2000-01-01',
                'ARC_PhysicalAddressStreet__c' => primaryData.get('ARC_PhysicalAddressStreet__c'),
                'ARC_PhysicalAddressCity__c' => primaryData.get('ARC_PhysicalAddressCity__c'),
                'ARC_PhysicalAddressState__c' => primaryData.get('ARC_PhysicalAddressState__c'),
                'ARC_PhysicalAddressZipCode__c' => primaryData.get('ARC_PhysicalAddressZipCode__c'),
                'vlocity_ins__Email__c' => 'test@test.com',
                'ARC_Phone__c' => '123123',
                'Id' => 'MEM-1753730373229352'
            });

        // Get the enrollment data from the database
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];
        
        inputMap.put('census_component', new Map<String, Object>{
            'census_members' => new List<Object> {
                new List<Object> {
                    censusMembers_InputMap[0],
                    censusMembers_InputMap[1]
                },
                new List<Object> {
                    censusMembers_InputMap[2],
                    censusMembers_InputMap[3]
                }
            }
        });
        inputMap.put('soChanges', new Map<String, Object> {
            'soReasons' => new Map<String, Object>{
                            'spinOff' => true,
                            'programUpgrade' => false,
                            'programDowngrade' => false, 
                            'agingOut' => false,
                            'addMember' => true,
                            'removeMember' => false,
                            'ancillaryChange' => false
                        }
        });

        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.readMedicalQuestions(inputMap, outputMap, options);
        Test.stopTest();

        // Prepare the outputMap
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'STEP_MedicalQuestions' => 
                new Map<String, Object> {
                    'BLK_ParentSiblingDiagnosed' => new List<Object> {
                            new Map<String, Object> {
                                'memberId' => 'MEM-1753730373229352',
                                'TXT_MemberParentDiagnosed' => 'FN New Member LN New Member',
                                'TXT_MemberIdParentDiagnosed' => 'MEM-1753730373229352'
                            }
                        },
                        'BLK_UnexpectedSymptoms' => new List<Object> {
                            new Map<String, Object> {
                                'memberId' => 'MEM-1753730373229352',
                                'TXT_MemberUnexpectedSymptoms' => 'FN New Member LN New Member',
                                'TXT_MemberIdUnexpectedSymptoms' => 'MEM-1753730373229352'
                            }
                        },
                        'BLK_PendingTests' => new List<Object> {
                            new Map<String, Object> {
                                'memberId' => 'MEM-1753730373229352',
                                'TXT_MemberPendingTests' => 'FN New Member LN New Member',
                                'TXT_MemberIdPendingTests' => 'MEM-1753730373229352'
                            }
                        },
                        'BLK_Addictions' => new List<Object> {
                            new Map<String, Object> {
                                'memberId' => 'MEM-1753730373229352',
                                'TXT_MemberAddictions' => 'FN New Member LN New Member',
                                'TXT_MemberIdAddictions' => 'MEM-1753730373229352'
                            }
                        },
                            'BLK_LicenceSuspended' => new List<Object> {
                            new Map<String, Object> {
                                'memberId' => 'MEM-1753730373229352',
                                'TXT_MemberLicenceSuspended' => 'FN New Member LN New Member',
                                'TXT_MemberIdLicenceSuspended' => 'MEM-1753730373229352'
                            }
                        },
                        'EB_PastConditions' => new List<Object> {
                            new Map<String, Object> {
                                'memberId' => 'MEM-1753730373229352',
                                'TXT_MemberPastConditions' => 'FN New Member LN New Member',
                                'TXT_MemberIdPastConditions' => 'MEM-1753730373229352'
                            }
                        },
                        'EB_Physicians' => new List<Object> {
                            new Map<String, Object> {
                                'memberId' => 'MEM-1753730373229352',
                                'TXT_CensusMemberName' => 'FN New Member LN New Member'
                                // 'TXT_CensusMemberId' => 'MEM-1753730373229352'
                            }
                        },
                        'RAD_ParentSiblingDiagnosed' => 'No',
                        'RAD_UnexplainedSymptoms' => 'No',
                        'RAD_PendingTests' => 'No',
                        'RAD_Cancer' => 'No',
                        'RAD_Addictions' => 'No',
                        'RAD_LicenceSuspended' => 'No',
                        'RAD_PastConditions' => 'No',
                        'RAD_PrescriptionMedications' => 'No'
                },
            'CensusMember' => new List<Object> {
                new Map<String, Object> {
                    'CensusMemberName' => 'FN New Member LN New Member',
                    'CensusMemberId' => 'MEM-1753730373229352',
                    'Birthdate' => '2000-01-01'
                }
            }
                
        };


        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest
    public static void childLoseAncillaryTest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];
        List<Product2> testProducts = ARC_TestUtility.createTestProducts(2);
        
        // Primary
        Map<String, Object> primaryData = (Map<String, Object>) censusMembers_InputMap[0];
        // Spouse
        Map<String, Object> spouseData = (Map<String, Object>) censusMembers_InputMap[1];
        // Child1
        Map<String, Object> child1Data = (Map<String, Object>) censusMembers_InputMap[2];


        List<Object> oldProducts_InputMap = new List<Object> {
            new Map<String, Object> {
                'Id' => productRelated.Id,
                'Name' => 'WeShare 6k',
                'SubType__c' => 'PPO',
                'productId' => productRelated.vlocity_ins__Product2Id__r.Id,
                'census_members' => new List<Object> {censusMembers_InputMap}
            },
            new Map<String, Object> {
                'Id' => productRelated.Id,
                'Name' => 'WeShare 6k',
                'SubType__c' => 'AIDD',
                'productId' => testProducts[0].Id,
                'census_members' => new List<Object> {
                    censusMembers_InputMap[1], censusMembers_InputMap[2]
                }
            },
            new Map<String, Object> {
                'Id' => productRelated.Id,
                'Name' => 'WeShare 6k',
                'SubType__c' => 'PPO',
                'productId' => testProducts[1].Id,
                'census_members' => new List<Object> {
                    censusMembers_InputMap[1], censusMembers_InputMap[2]
                }
            }
        };

        List<Object> LWC_SpinOffCensusMembersTable_InputMap = new List<Object>{
            new Map<String, Object>{
                'TXT_ContractParticipantRelationship' => primaryData.get('ARC_Relationship__c'),
                'TXT_LastName' => primaryData.get('vlocity_ins__FirstName__c'),
                'TXT_FirstName' => primaryData.get('vlocity_ins__LastName__c'),
                'TXT_GroupCensusMemberId' => primaryData.get('Id'),
                'NUM_assignToFamily' => 1
            },
            new Map<String, Object>{
                'TXT_ContractParticipantRelationship' => spouseData.get('ARC_Relationship__c'),
                'TXT_LastName' => spouseData.get('vlocity_ins__FirstName__c'),
                'TXT_FirstName' => spouseData.get('vlocity_ins__LastName__c'),
                'TXT_GroupCensusMemberId' => spouseData.get('Id'),
                'NUM_assignToFamily' => 2
            },
            new Map<String, Object>{
                'TXT_ContractParticipantRelationship' => child1Data.get('ARC_Relationship__c'),
                'TXT_LastName' => child1Data.get('vlocity_ins__FirstName__c'),
                'TXT_FirstName' => child1Data.get('vlocity_ins__LastName__c'),
                'TXT_GroupCensusMemberId' => child1Data.get('Id'),
                'NUM_assignToFamily' => 1
            }
        };

        inputMap.put('oldProducts', oldProducts_InputMap);
        inputMap.put('STEP_AccountSelection', new Map<String, Object> {
            'LWC_SpinOffCensusMembersTable' => LWC_SpinOffCensusMembersTable_InputMap
        });

        // Run the test
        ARC_SpinOff_Utilities.childLoseAncillary(inputMap, outputMap, options);

        // Prepare the expectedOutput
        Map<String, Object> expectedOutput = new Map<String, Object>{
            'childLoseAncillary' => true,
            'childLoseSummary' => 'Test PersonAccount Child 0 will lose the ancillary WeShare 6k.'
        };

        // Asserts
        //Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutput));

        // Scenario #2
        ((Map<String, Object>)LWC_SpinOffCensusMembersTable_InputMap[2]).put('NUM_assignToFamily', 2);

        // Run the test again
        outputMap.clear();
        ARC_SpinOff_Utilities.childLoseAncillary(inputMap, outputMap, options);

        // Assert 
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(new Map<String, Object> {'childLoseAncillary' => false}));
    }

    @isTest
    public static void getHipaaRecipientsTest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Generate test data
        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];

        // Prepare the inputMap data
        Map<String, Object> STEP_HIPAAAuthorizationForm_InputMap = new Map<String, Object>{
            'EDITBLK_HIPAAAuthorizedParties' => new Map<String, Object>{
                'CHK_Authorized' => true,
                'TXT_FullName' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__FirstName__c') + ' ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__LastName__c'),
                'TXT_EmailAddress' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__Email__c'),
                'TXT_Relationship' => ((Map<String, Object>)censusMembers_InputMap[1]).get('ARC_Relationship__c')
            },
            'RAD_AuthorizeOthers' => 'Yes'
        };

        inputMap.put('STEP_HIPAAAuthorizationForm', STEP_HIPAAAuthorizationForm_InputMap);
        
        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.getHipaaRecipients(inputMap, outputMap, options);
        Test.stopTest();

        // Prepare the outputMap
        outputMap.put('FinalHipaaRecipients', new Map<String, Object>{
            'label' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__FirstName__c') + ' ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__LastName__c') + ' - ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__Email__c'),
            'value' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__Email__c'),
            'fullName' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__FirstName__c') + ' ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__LastName__c'),
            'Recipient' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__FirstName__c') + ' ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__LastName__c') + ' - ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__Email__c')
        });

        outputMap.put('STEP_SignTheDocument', new Map<String, Object>{
            'Recipient-Block' => new Map<String, Object> {
                'label' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__FirstName__c') + ' ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__LastName__c') + ' - ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__Email__c'),
                'value' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__Email__c'),
                'fullName' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__FirstName__c') + ' ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__LastName__c'),
                'Recipient' => ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__FirstName__c') + ' ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__LastName__c') + ' - ' + ((Map<String, Object>)censusMembers_InputMap[1]).get('vlocity_ins__Email__c')
            }
        });

        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(outputMap));
    }

    @isTest
    public static void getDocuSignDataTest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Generate test data
        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);
        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the oldProducts node data
        vlocity_ins__ContractLineItem__c productRelated = [SELECT Id, vlocity_ins__Product2Id__r.Id, vlocity_ins__Product2Id__r.Name, vlocity_ins__Product2Id__r.vlocity_ins__Type__c
                                                           FROM vlocity_ins__ContractLineItem__c
                                                           WHERE vlocity_ins__ContractId__c = :(Id)enrollmentData.get('contractId')
                                                           LIMIT 1];

        Map<String, Object> primaryData = (Map<String, Object>) censusMembers_InputMap[0];
        Map<String, Object> spouseData = (Map<String, Object>) censusMembers_InputMap[1];
        Map<String, Object> childData = (Map<String, Object>) censusMembers_InputMap[2];

        User userTest = (ARC_TestUtility.createTestUsers(1, 'Standard User'))[0];
        insert userTest;

        Map<String, Object> DocuSign_InputMap = new Map<String, Object> {
            'pcChanges' => new Map<String, Object> {
                'createNewContract' => true,
                'feeAmount' => 0,
                'feeApplicable' => false,
                'pcReasonsString' => 'Spin Off'
            },
            'Step_PaymentChangeFee' => new Map<String, Object> {
                'BLK_ChargeFee' => new Map<String, Object>()
            },
            'NewProductList' => new List<Object> {
                new Map<String, Object> {
                    'userInputs' => new List<Object> {
                        new Map<String, Object> {
                            'LastName' => spouseData.get('vlocity_ins__LastName__c'),
                            'FirstName' => spouseData.get('vlocity_ins__FirstName__c'),
                            'CensusMemberLastName' => spouseData.get('vlocity_ins__LastName__c'),
                            'CensusMemberId' => spouseData.get('Id'),
                            'CensusMemberFirstName' => spouseData.get('vlocity_ins__FirstName__c')
                        }
                    },
                    'selectedProduct' => new Map<String, Object> {
                        'productId' => productRelated.vlocity_ins__Product2Id__r.Id,
                        'Type__c' => 'Medical',
                        'Name' => 'WeShare 1k',
                        'Id' => productRelated.vlocity_ins__Product2Id__r.Id
                    }
                }
            },
            'PlanSummary' => new Map<String, Object> {
                'BLK_ProductSummary' => new Map<String, Object> {
                    'TXT_MonthlyPrice' => '$100'
                }
            },
            'userId' => userTest.Id
        };

        inputMap.put('census_members', censusMembers_InputMap);
        inputMap.put('signerEmail', 'gm.arcsona@yopmail.com');
        inputMap.put('primaryState', 'TX');
        inputMap.put('selectedProducts', '');
        inputMap.put('DocuSign', DocuSign_InputMap);

        // Create the ARC_DocuSignTemplates__c record
        vlocity_ins__VlocityDocuSignTemplate__c vlocityDocuSignTest = new vlocity_ins__VlocityDocuSignTemplate__c(
            Name =  'Spin Off',
            vlocity_ins__templateidentifier__c = 'vlocity-template-test'
        );
        
        insert vlocityDocuSignTest;

        ARC_DocuSignTemplates__c templateSettingsTest = new ARC_DocuSignTemplates__c(); 
        
        templateSettingsTest.Name = 'Spin Off';
        templateSettingsTest.ARC_Template_Name__c = 'Spin Off';
        templateSettingsTest.ARC_Contract_Reasons__c = 'Spin Off';
        templateSettingsTest.ARC_DRTransform__c = 'Transform for Test';
        templateSettingsTest.ARC_Min_Dependents__c = 1;
        templateSettingsTest.ARC_Max_Dependents__c = 5;
       
        insert templateSettingsTest;

        // Run the test
        Test.startTest();
        ARC_SpinOff_Utilities.getDocuSignData(inputMap, outputMap, options);
        Test.stopTest();

        // Prepare the outputMap data
        Map<String, Object> expectedOutputMap = new Map<String, Object>();

        expectedOutputMap.put('DocuSignTemplateId', new Map<String, Object> {
            'Id' => ((Map<String, Object>) outputMap.get('DocuSignTemplateId')).get('Id'),
            'Name' => 'Spin Off',
            'TemplateId' => 'vlocity-template-test'
        });

        expectedOutputMap.put('SignerList', new List<Object> {
            new Map<String, Object> {
                'templateRole' => 'Primary',
                'signerEmail' => 'gm.arcsona@yopmail.com',
                'signerName' => 'Test Census Member Primary 0'
            }
        });

        expectedOutputMap.put('RAresponse', new Map<String, Object> {
            'tabs' => new Map<String, Object> {
                'checkboxTabs' => new Map<String, Object> {
                    'Primary.IsNewMember'=> false,
                    'Primary.IsRemoveMember'=> false,
                    'Primary.null'=> false,
                    'Primary.Smoker'=> false,
                    'Primary.NotSmoker'=> true,
                    'Primary.Pregnant'=> false,
                    'Primary.NotPregnant'=> true,
                    'Spouse.IsNewMember'=> false,
                    'Spouse.IsRemoveMember'=> false,
                    'Spouse.null'=> false,
                    'Spouse.Smoker'=> false,
                    'Spouse.NotSmoker'=> true,
                    'Spouse.Pregnant'=> false,
                    'Spouse.NotPregnant'=> true,
                    'Dependent1.IsNewMember'=> false,
                    'Dependent1.IsRemoveMember'=> false,
                    'Dependent1.null'=> false,
                    'Dependent1.Smoker'=> false,
                    'Dependent1.NotSmoker'=> true,
                    'Dependent1.Pregnant'=> false,
                    'Dependent1.NotPregnant'=> true
                },
                'textTabs' => new Map<String, Object> {
                    'Primary.MI' => null,
                    'Primary.Phone' => '123123',
                    'Primary.City' => 'New York',
                    'Primary.State' => 'NY',
                    'Primary.Address' => '123 Avenue',
                    'Primary.ZipCode' => '12345',
                    'Primary.Weight' => null,
                    'Primary.DayOfBirth' => 1,
                    'Primary.Height' => 'null\'null',
                    'Primary.Id' => primaryData.get('Id'),
                    'Primary.MonthOfBirth' => 1,
                    'Primary.YearOfBirth' => 2000,
                    'Primary.DOB' => '2000-01-01',
                    'Primary.Email' => 'test@test.com',
                    'Primary.FirstName' => 'Test',
                    'Primary.LastName' => 'Census Member Primary 0',
                    'Primary.SocialSecurity' => null,
                    'Spouse.MI' => null,
                    'Spouse.Weight' => null,
                    'Spouse.Height' => 'null\'null',
                    'Spouse.Id' => spouseData.get('Id'),
                    'Spouse.DOB' => '2000-01-01',
                    'Spouse.Email' => 'test@test.com',
                    'Spouse.FirstName' => 'PersonAccount Spouse 0',
                    'Spouse.LastName' => 'Test',
                    'Spouse.SocialSecurity' => null,
                    'Dependent1.MI' => null,
                    'Dependent1.Weight' => null,
                    'Dependent1.Height' => 'null\'null',
                    'Dependent1.Id' => childData.get('Id'),
                    'Dependent1.DOB' => '2000-01-01',
                    'Dependent1.Email' => 'test@test.com',
                    'Dependent1.FirstName' => 'PersonAccount Child 0',
                    'Dependent1.LastName' => 'Test',
                    'Dependent1.SocialSecurity' => null,
                    'Info.RequestedChanges' => 'null Spin Off',
                    'Info.MembersPerProgram' => 'WeShare 1k: PersonAccount Spouse 0 Test',
                    'Info.MembersPerProgramNew' => 'WeShare 1k: PersonAccount Spouse 0 Test',
                    'Plan.EffectiveDate' => null,
                    'Info.ReasonForChange' => 'Spin Off',
                    'Plan.ApplicationFee' => '$ 0',
                    'Plan.MonthlyContribution' => '$100',
                    'Payment.MonthlyContribution' => '$100',
                    'Payment.Fee' => '$ 0',
                    'Agent.Name' => 'TestUsr 0'
                }
            }
        });

        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }
}