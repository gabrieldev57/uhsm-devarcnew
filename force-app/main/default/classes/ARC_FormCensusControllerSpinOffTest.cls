@isTest
public with sharing class ARC_FormCensusControllerSpinOffTest{

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
                                                            WHERE ARC_Contract__c =  :contractData.Id];

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

    private class GET_AddressSuggestionsFromGoogleMapsAPI_HttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            Map<String, Object> responseMap = new Map<String, Object> {
                'message' => 'success',
                'predictions' => new List<Object> {
                    new Map<String, Object> {
                        'description' => '1000 Main Street, Houston, TX, USA',
                        'place_id' => '11111111111'
                    },
                    new Map<String, Object> {
                        'description' => '1000 Main Street East, Hamilton, ON, Canada',
                        'place_id' => '222222222222'
                    },
                    new Map<String, Object> {
                        'description' => '1000 Main Street, Woodland, CA, USA',
                        'place_id' => '33333333333'
                    }
                }
            };
            res.setBody(JSON.serialize(responseMap));
            res.setStatusCode(200);
            return res;
        }
    }

    private class GET_AddressDetailsFromGoogleMapsAPI_HttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            Map<String, Object> responseMap = new Map<String, Object> {
                'message' => 'success',
                'result' => new Map<String, Object> {
                    'address_components' => new List<Object> {
                        new Map<String, Object> {
                            'types' => new List<Object> {
                                'administrative_area_level_1'
                            },
                            'short_name' => 'Physical Address short name',
                            'long_name' => 'Physical Address long name'
                        },
                        new Map<String, Object> {
                            'types' => new List<Object> {
                                'locality'
                            },
                            'short_name' => 'Address City short name',
                            'long_name' => 'Address City long name'
                        },
                        new Map<String, Object> {
                            'types' => new List<Object> {
                                'postal_code'
                            },
                            'short_name' => 'Address ZIP Code short name',
                            'long_name' => 'Address ZIP Code long name'
                        },
                        new Map<String, Object> {
                            'types' => new List<Object> {
                                'route'
                            },
                            'short_name' => 'Address Street short name',
                            'long_name' => 'Address Street long name'
                        }
                    }
                }
            };
            res.setBody(JSON.serialize(responseMap));
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    public static void GET_CensusMembersPerCensusTest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Prepare the inputMap data
        Map<String, Object> enrollmentData = new Map<String, Object>();
        getContractIdAndCensusMembersFromEnrollment(enrollmentData);

        List<Object> censusMembers = (List<Object>) enrollmentData.get('censusMembers');
        Map<String, Object> primaryMemberData = (Map<String, Object>) censusMembers[0];
        Map<String, Object> spouseMemberData = (Map<String, Object>) censusMembers[1];
        Map<String, Object> childMemberData = (Map<String, Object>) censusMembers[2];

        inputMap.put('memberAssignment', new List<Object> {
            new Map<String, Object> {
                'TXT_GroupCensusMemberId' => primaryMemberData.get('Id'),
                'NUM_assignToFamily' => 1,
                'CHK_spinOffSelection' => false,
                'TXT_ContractParticipantRelationship' => primaryMemberData.get('ARC_Relationship__c')
            },
            new Map<String, Object> {
                'TXT_GroupCensusMemberId' => spouseMemberData.get('Id'),
                'NUM_assignToFamily' => 1,
                'CHK_spinOffSelection' => false,
                'TXT_ContractParticipantRelationship' => spouseMemberData.get('ARC_Relationship__c')
            },
            new Map<String, Object> {
                'TXT_GroupCensusMemberId' => childMemberData.get('Id'),
                'NUM_assignToFamily' => 1,
                'CHK_spinOffSelection' => false,
                'TXT_ContractParticipantRelationship' => childMemberData.get('ARC_Relationship__c')
            }
        });

        inputMap.put('clean_output', true);

        // Run the test
        Test.startTest();
        ARC_FormCensusControllerSpinOff.invokeMethod('GET_CensusMembersPerCensus', inputMap, outputMap, options);
        Test.stopTest();

        List<vlocity_ins__GroupCensusMember__c> censusMembersUpdated = new List<vlocity_ins__GroupCensusMember__c>([
            SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, ARC_MiddleInitial__c, vlocity_ins__Birthdate__c, 
                   vlocity_ins__Gender__c, ARC_Relationship__c, vlocity_ins__Email__c, ARC_Phone__c, vlocity_ins__SocialSecurityNumber__c, 
                   ARC_HeightFeet__c, ARC_HeightInches__c, ARC_Weight__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressState__c, 
                   ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressZipCode__c, ARC_UpdateAllAddress__c, ARC_Age__c, ARC_Smoker__c, 
                   vlocity_ins__IsPrimaryMember__c,ARC_isPregnant__c, vlocity_ins__ContactId__r.AccountId, vlocity_ins__ContactId__c, vlocity_ins__MemberIdentifier__c
            FROM vlocity_ins__GroupCensusMember__c
            ORDER BY vlocity_ins__IsPrimaryMember__c DESC, vlocity_ins__IsSpouse__c DESC, vlocity_ins__Birthdate__c ASC
        ]);

        // Prepare the expectedOutput data
        Map<String, Object> expectedOutputMap = new Map<String, Object> {
            'census_members' => new List<Object> {
                new List<Object> {
                    new Map<String, Object> {
                        'Id' => censusMembersUpdated[0].Id,
                        'vlocity_ins__FirstName__c' => censusMembersUpdated[0].vlocity_ins__FirstName__c,
                        'vlocity_ins__LastName__c' => censusMembersUpdated[0].vlocity_ins__LastName__c,
                        'PersonAccountId' => censusMembersUpdated[0].vlocity_ins__ContactId__r.AccountId,
                        'PersonContactId' => censusMembersUpdated[0].vlocity_ins__ContactId__c,
                        'vlocity_ins__MemberIdentifier__c' => censusMembersUpdated[0].vlocity_ins__MemberIdentifier__c,
                        'ARC_MiddleInitial__c' => censusMembersUpdated[0].ARC_MiddleInitial__c,
                        'vlocity_ins__Birthdate__c' => censusMembersUpdated[0].vlocity_ins__Birthdate__c,
                        'vlocity_ins__IsPrimaryMember__c' => censusMembersUpdated[0].vlocity_ins__IsPrimaryMember__c,
                        'ARC_Age__c' => censusMembersUpdated[0].ARC_Age__c,
                        'vlocity_ins__SocialSecurityNumber__c' => censusMembersUpdated[0].vlocity_ins__SocialSecurityNumber__c,
                        'showSSN' => 'password',
                        'ARC_HeightFeet__c' => censusMembersUpdated[0].ARC_HeightFeet__c,
                        'ARC_HeightInches__c' => censusMembersUpdated[0].ARC_HeightInches__c,
                        'ARC_Weight__c' => censusMembersUpdated[0].ARC_Weight__c,
                        'ARC_Smoker__c' => '',
                        'ARC_PhysicalAddressCity__c' => censusMembersUpdated[0].ARC_PhysicalAddressCity__c,
                        'ARC_PhysicalAddressState__c' => censusMembersUpdated[0].ARC_PhysicalAddressState__c,
                        'ARC_PhysicalAddressStreet__c' => censusMembersUpdated[0].ARC_PhysicalAddressStreet__c,
                        'ARC_PhysicalAddressZipCode__c' => censusMembersUpdated[0].ARC_PhysicalAddressZipCode__c,
                        'ARC_Address__c' => 'New York, NY, 123 Avenue, 12345',
                        'IsDependent' => false,
                        'individual_errors' => new List<Object>(),
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
                        'ARC_Relationship__c' => censusMembersUpdated[0].ARC_Relationship__c,
                        'vlocity_ins__Gender__c' => censusMembersUpdated[0].vlocity_ins__Gender__c
                    },
                    new Map<String, Object> {
                        'Id' => censusMembersUpdated[1].Id,
                        'vlocity_ins__FirstName__c' => censusMembersUpdated[1].vlocity_ins__FirstName__c,
                        'vlocity_ins__LastName__c' => censusMembersUpdated[1].vlocity_ins__LastName__c,
                        'PersonAccountId' => censusMembersUpdated[1].vlocity_ins__ContactId__r.AccountId,
                        'PersonContactId' => censusMembersUpdated[1].vlocity_ins__ContactId__c,
                        'vlocity_ins__MemberIdentifier__c' => censusMembersUpdated[1].vlocity_ins__MemberIdentifier__c,
                        'ARC_MiddleInitial__c' => censusMembersUpdated[1].ARC_MiddleInitial__c,
                        'vlocity_ins__Birthdate__c' => censusMembersUpdated[1].vlocity_ins__Birthdate__c,
                        'vlocity_ins__IsPrimaryMember__c' => censusMembersUpdated[1].vlocity_ins__IsPrimaryMember__c,
                        'ARC_Age__c' => censusMembersUpdated[1].ARC_Age__c,
                        'vlocity_ins__SocialSecurityNumber__c' => censusMembersUpdated[1].vlocity_ins__SocialSecurityNumber__c,
                        'showSSN' => 'password',
                        'ARC_HeightFeet__c' => censusMembersUpdated[1].ARC_HeightFeet__c,
                        'ARC_HeightInches__c' => censusMembersUpdated[1].ARC_HeightInches__c,
                        'ARC_Weight__c' => censusMembersUpdated[1].ARC_Weight__c,
                        'ARC_Smoker__c' => '',
                        'ARC_PhysicalAddressCity__c' => censusMembersUpdated[1].ARC_PhysicalAddressCity__c,
                        'ARC_PhysicalAddressState__c' => censusMembersUpdated[1].ARC_PhysicalAddressState__c,
                        'ARC_PhysicalAddressStreet__c' => censusMembersUpdated[1].ARC_PhysicalAddressStreet__c,
                        'ARC_PhysicalAddressZipCode__c' => censusMembersUpdated[1].ARC_PhysicalAddressZipCode__c,
                        'ARC_Address__c' => 'New York, NY, 123 Avenue, 12345',
                        'IsDependent' => true,
                        'individual_errors' => new List<Object>(),
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
                        'ARC_Relationship__c' => censusMembersUpdated[1].ARC_Relationship__c,
                        'vlocity_ins__Gender__c' => censusMembersUpdated[1].vlocity_ins__Gender__c
                    },
                    new Map<String, Object> {
                        'Id' => censusMembersUpdated[2].Id,
                        'vlocity_ins__FirstName__c' => censusMembersUpdated[2].vlocity_ins__FirstName__c,
                        'vlocity_ins__LastName__c' => censusMembersUpdated[2].vlocity_ins__LastName__c,
                        'PersonAccountId' => censusMembersUpdated[2].vlocity_ins__ContactId__r.AccountId,
                        'PersonContactId' => censusMembersUpdated[2].vlocity_ins__ContactId__c,
                        'vlocity_ins__MemberIdentifier__c' => censusMembersUpdated[2].vlocity_ins__MemberIdentifier__c,
                        'ARC_MiddleInitial__c' => censusMembersUpdated[2].ARC_MiddleInitial__c,
                        'vlocity_ins__Birthdate__c' => censusMembersUpdated[2].vlocity_ins__Birthdate__c,
                        'vlocity_ins__IsPrimaryMember__c' => censusMembersUpdated[2].vlocity_ins__IsPrimaryMember__c,
                        'ARC_Age__c' => censusMembersUpdated[2].ARC_Age__c,
                        'vlocity_ins__SocialSecurityNumber__c' => censusMembersUpdated[2].vlocity_ins__SocialSecurityNumber__c,
                        'showSSN' => 'password',
                        'ARC_HeightFeet__c' => censusMembersUpdated[2].ARC_HeightFeet__c,
                        'ARC_HeightInches__c' => censusMembersUpdated[2].ARC_HeightInches__c,
                        'ARC_Weight__c' => censusMembersUpdated[2].ARC_Weight__c,
                        'ARC_Smoker__c' => '',
                        'ARC_PhysicalAddressCity__c' => censusMembersUpdated[2].ARC_PhysicalAddressCity__c,
                        'ARC_PhysicalAddressState__c' => censusMembersUpdated[2].ARC_PhysicalAddressState__c,
                        'ARC_PhysicalAddressStreet__c' => censusMembersUpdated[2].ARC_PhysicalAddressStreet__c,
                        'ARC_PhysicalAddressZipCode__c' => censusMembersUpdated[2].ARC_PhysicalAddressZipCode__c,
                        'ARC_Address__c' => 'New York, NY, 123 Avenue, 12345',
                        'IsDependent' => true,
                        'individual_errors' => new List<Object>(),
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
                        'ARC_Relationship__c' => censusMembersUpdated[2].ARC_Relationship__c,
                        'vlocity_ins__Gender__c' => censusMembersUpdated[2].vlocity_ins__Gender__c
                    }
                }
            }
        };

        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest
    public static void GET_AddressSuggestionsFromGoogleMapsAPITest(){
        // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Setting the mock
        Test.setMock(HttpCalloutMock.class, new GET_AddressSuggestionsFromGoogleMapsAPI_HttpMock());

        // Set the inputMap data
        inputMap.put('input', '1000 main street');

        // Start the test
        Test.startTest();
        ARC_FormCensusControllerSpinOff.invokeMethod('GET_AddressSuggestionsFromGoogleMapsAPI', inputMap, outputMap, options);
        Test.stopTest();

        // Setting the expectedOutputMap
        Map<String, Object> expectedOutputMap = new map<String, Object> {
            'suggestions' => new Map<String, Object> {
                '1000 Main Street, Houston, TX, USA' => '11111111111',
                '1000 Main Street East, Hamilton, ON, Canada' => '222222222222',
                '1000 Main Street, Woodland, CA, USA' => '33333333333'
            }
        };

        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }

    @isTest
    public static void GET_AddressDetailsFromGoogleMapsAPITest(){
         // Variables
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        // Setting the mock
        Test.setMock(HttpCalloutMock.class, new GET_AddressDetailsFromGoogleMapsAPI_HttpMock());

        // Set the inputMap data
        inputMap.put('place_id', '1000 main street');

        // Start the test
        Test.startTest();
        ARC_FormCensusControllerSpinOff.invokeMethod('GET_AddressDetailsFromGoogleMapsAPI', inputMap, outputMap, options);
        Test.stopTest();

        // Setting the expectedOutputMap
        Map<String, Object> expectedOutputMap = new map<String, Object> {
            'ARC_PhysicalAddressState__c' => 'Physical Address short name',
            'ARC_PhysicalAddressCity__c' => 'Address City long name',
            'ARC_PhysicalAddressZipCode__c' => 'Address ZIP Code long name',
            'ARC_PhysicalAddressStreet__c' => 'Address Street long name'
        };

        // Asserts
        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(expectedOutputMap));
    }
}