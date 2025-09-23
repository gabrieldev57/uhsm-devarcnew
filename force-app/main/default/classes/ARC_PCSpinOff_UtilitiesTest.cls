@isTest
public with sharing class ARC_PCSpinOff_UtilitiesTest {
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

    @isTest
    public static void TRANSFORM_CensusMemberToUserInputsTest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> enrollmentData = new Map<String, Object>();

        getContractIdAndCensusMembersFromEnrollment(enrollmentData);

        List<Object> censusMembers_InputMap = (List<Object>)enrollmentData.get('censusMembers');

        // Set the test data into the inputMap 
        inputMap.put('census_component', new Map<String, Object> {
            'census_members' => censusMembers_InputMap
        });
        inputMap.put('EffectiveDate', '2025-06-15');

        // Run the test
        ARC_PCSpinOff_Utilities.TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options);

        Map<String, Object> primaryMemberData = (Map<String, Object>) ((List<Object>)enrollmentData.get('censusMembers'))[0];
        Map<String, Object> spouseMemberData = (Map<String, Object>) ((List<Object>)enrollmentData.get('censusMembers'))[1];
        Map<String, Object> childMemberData = (Map<String, Object>) ((List<Object>)enrollmentData.get('censusMembers'))[2];

        // Prepare the expectedOutput 
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'userInputs' => new List<Object> {
                new Map<String, Object> {
                    'RF_Census.CM_Age' => primaryMemberData.get('ARC_Age__c'),
                    'RF_Census.CRF_PrimaryMemberDOB' => primaryMemberData.get('vlocity_ins__Birthdate__c'),
                    'RF_Census.CM_State' => primaryMemberData.get('ARC_PhysicalAddressState__c'),
                    'RF_Census.CM_IsPrimary' => true,
                    'RF_Census.CM_Relationship' => primaryMemberData.get('ARC_Relationship__c'),
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_FirstName' => primaryMemberData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_LastName' => primaryMemberData.get('vlocity_ins__LastName__c'),
                    'IsRemoveMember' => false,
                    'IsNewMember' => false,
                    'IsAddExistingMember' => false,
                    'Id' => primaryMemberData.get('Id'),
                    'RF_Census.CRF_Coverage' => 'Family',
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_PrimaryMemberAge' => primaryMemberData.get('ARC_Age__c'),
                    'RF_Census.CRF_Dependants' => 2
                },
                new Map<String, Object> {
                    'RF_Census.CM_Age' => spouseMemberData.get('ARC_Age__c'),
                    'RF_Census.CRF_PrimaryMemberDOB' => primaryMemberData.get('vlocity_ins__Birthdate__c'),
                    'RF_Census.CM_State' => spouseMemberData.get('ARC_PhysicalAddressState__c'),
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_Relationship' => spouseMemberData.get('ARC_Relationship__c'),
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_FirstName' => spouseMemberData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_LastName' => spouseMemberData.get('vlocity_ins__LastName__c'),
                    'IsRemoveMember' => false,
                    'IsNewMember' => false,
                    'IsAddExistingMember' => false,
                    'Id' => spouseMemberData.get('Id'),
                    'RF_Census.CRF_Coverage' => 'Family',
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_PrimaryMemberAge' => primaryMemberData.get('ARC_Age__c'),
                    'RF_Census.CRF_Dependants' => 2
                },
                new Map<String, Object> {
                    'RF_Census.CM_Age' => childMemberData.get('ARC_Age__c'),
                    'RF_Census.CRF_PrimaryMemberDOB' => primaryMemberData.get('vlocity_ins__Birthdate__c'),
                    'RF_Census.CM_State' => childMemberData.get('ARC_PhysicalAddressState__c'),
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_Relationship' => childMemberData.get('ARC_Relationship__c'),
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_FirstName' => childMemberData.get('vlocity_ins__FirstName__c'),
                    'RF_Census.CM_LastName' => childMemberData.get('vlocity_ins__LastName__c'),
                    'IsRemoveMember' => false,
                    'IsNewMember' => false,
                    'IsAddExistingMember' => false,
                    'Id' => childMemberData.get('Id'),
                    'RF_Census.CRF_Coverage' => 'Family',
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_PrimaryMemberAge' => primaryMemberData.get('ARC_Age__c'),
                    'RF_Census.CRF_Dependants' => 2
                }
            }
        };

        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));

        // Scenario #2
        inputMap.clear();
        outputMap.clear();
        inputMap.put('census_component', new Map<String, Object> {
            'census_members' => null
        });

        // Run the test
        ARC_PCSpinOff_Utilities.TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options);

        // Prepare the outputMap
        outputMap.put('userInputs', new List<Object>());

        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(outputMap));

        // Scenario #3
        inputMap.clear();
        outputMap.clear();

        // Set the test data into the inputMap 
        inputMap.put('census_component', new Map<String, Object> {
            'census_members' => new List<Object> {
                censusMembers_InputMap[0]
            }
        });

        // Run the test
        ARC_PCSpinOff_Utilities.TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options);

        // Asserts
        

        // Scenario #4
        inputMap.clear();
        outputMap.clear();

        // Set the test data into the inputMap 
        inputMap.put('census_component', new Map<String, Object> {
            'census_members' => new List<Object> {
                censusMembers_InputMap[0],
                censusMembers_InputMap[1]
            }
        });

        // Run the test
        ARC_PCSpinOff_Utilities.TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options);

        // Asserts

        // Scenario #5
        inputMap.clear();
        outputMap.clear();

        // Set the test data into the inputMap 
        inputMap.put('census_component', new Map<String, Object> {
            'census_members' => new List<Object> {
                censusMembers_InputMap[0],
                censusMembers_InputMap[2]
            }
        });

        // Run the test
        ARC_PCSpinOff_Utilities.TRANSFORM_CensusMemberToUserInputs(inputMap, outputMap, options);

        // Asserts
        
    }
}