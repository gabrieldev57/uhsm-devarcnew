@isTest
public with sharing class ARC_MultiSpinOff_BaseServiceTest {
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

        // Run the test
        ARC_MultiSpinOff_BaseService multiSpinOffBaseServiceInstance = new ARC_MultiSpinOff_BaseService();
        multiSpinOffBaseServiceInstance.invokeMethod('TRANSFORM_CensusMemberToUserInputs', inputMap, outputMap, options);

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
        multiSpinOffBaseServiceInstance.invokeMethod('TRANSFORM_CensusMemberToUserInputs', inputMap, outputMap, options);

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
        multiSpinOffBaseServiceInstance.invokeMethod('TRANSFORM_CensusMemberToUserInputs', inputMap, outputMap, options);

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
        multiSpinOffBaseServiceInstance.invokeMethod('TRANSFORM_CensusMemberToUserInputs', inputMap, outputMap, options);

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
        multiSpinOffBaseServiceInstance.invokeMethod('TRANSFORM_CensusMemberToUserInputs', inputMap, outputMap, options);
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
        // Run the test
        ARC_MultiSpinOff_BaseService multiSpinOffBaseServiceInstance = new ARC_MultiSpinOff_BaseService();
        multiSpinOffBaseServiceInstance.invokeMethod('censusPlanSelectionChanges', inputMap, outputMap, options);

        // Expected output
        Map<String, Object> expectedOutputMap = new Map<String, Object>{
            'soChanges' => new Map<String, Object>{
                'feeAmount' => 50,
                'feeApplicable' => true,
                'programSummaryFeeText' => 'One Time Change Fee (Add Member): 50',
                'canAddBeneficiary' => false,
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
        multiSpinOffBaseServiceInstance.invokeMethod('censusPlanSelectionChanges', inputMap, outputMap, options);

        Map<String, Object> soChanges = (Map<String, Object>)expectedOutputMap.get('soChanges');
        soChanges.put('soReasonsString', 'Spin Off; Program Upgrade; Add Member');
        soChanges.put('programSummaryFeeText', 'One Time Change Fee (Add Member, Program Upgrade): 99.000');
        ((Map<String, Object>) soChanges.get('soReasons')).put('programUpgrade', true);
        soChanges.put('feeAmount', 99.000);

        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));

    }

    @isTest
    public static void spinOffMethodBTest(){
        // Run the test
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_MultiSpinOff_BaseService multiSpinOffBaseServiceInstance = new ARC_MultiSpinOff_BaseService();
        multiSpinOffBaseServiceInstance.invokeMethod('spinOffMethodB', inputMap, outputMap, options);

        ARC_MultiSpinOff_BaseService.spinOffMethodB(inputMap, outputMap);

        
    }
}