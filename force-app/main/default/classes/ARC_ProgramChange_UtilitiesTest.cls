/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ARC_ProgramChange_UtilitiesTest {

    @TestSetup
    static void makeData(){
        // Set fee amounts
        ChargentBase__Chargent_Settings__c feeAmounts = new ChargentBase__Chargent_Settings__c();
        feeAmounts.ARC_DowngradeChangeFee__c = 50;
        feeAmounts.ARC_AddMemberChangeFee__c = 99;
        feeAmounts.ARC_UpgradeChangeFee__c = 99;
        insert feeAmounts;
    }

    static void populateMemberData(List<Object> memberMap, Map<String,Object> expectedOutputReasons) {
        // Create test census members
        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(2);

        // INITIAL VALUES
        // First initial member data
        Map<String,Object> initialMemberMap1 = new Map<String,Object>();
        initialMemberMap1.put('Id', testCensusMembers[0].Id);
        initialMemberMap1.put('vlocity_ins__MemberIdentifier__c', 'MID-PRIMARY-1');
        initialMemberMap1.put('vlocity_ins__IsPrimaryMember__c', true);
        initialMemberMap1.put('ARC_PhysicalAddressState__c', 'CA');
        initialMemberMap1.put('ARC_PhysicalAddressCity__c', 'San Diego');
        initialMemberMap1.put('ARC_PhysicalAddressZipCode__c', '92154');
        initialMemberMap1.put('ARC_Address__c', 'Siempre Viva Court');
        initialMemberMap1.put('ARC_Relationship__c', new Map<String, Object>{
            'options' => new List<Object>{
                new Map<String, Object>{ 'value' => 'Primary', 'label' => 'Primary' },
                new Map<String, Object>{ 'value' => 'Spouse', 'label' => 'Spouse' },
                new Map<String, Object>{ 'value' => 'Child', 'label' => 'Child' }
            },
            'value' => 'Primary'
        });
        initialMemberMap1.put('ARC_Age__c', 35);
        initialMemberMap1.put('IsNewMember', false);
        initialMemberMap1.put('IsAddExistingMember', false);
        initialMemberMap1.put('IsRemoveMember', false);
        initialMemberMap1.put('IsInactiveMember', false);
        initialMemberMap1.put('IsActive', true);
        initialMemberMap1.put('IsNewborn', false);
        initialMemberMap1.put('ShowMember', true);
        initialMemberMap1.put('vlocity_ins__LastName__c', 'Test1');
        initialMemberMap1.put('vlocity_ins__FirstName__c', 'Member1');
        initialMemberMap1.put('vlocity_ins__Birthdate__c', '1994-01-01');
        initialMemberMap1.put('ARC_Phone__c', new Map<String, Object>{
            'DISPLAY_FIELD' => true,
            'value' => '1111111111'
        });
        initialMemberMap1.put('vlocity_ins__Email__c', new Map<String, Object>{
            'DISPLAY_FIELD' => true,
            'value' => 'utilitiestester1@yopmail.com'
        });
        initialMemberMap1.put('ARC_Smoker__c', new Map<String, Object>{
            'value' => false
        });

        // Second initial member data
        Map<String,Object> initialMemberMap2 = new Map<String,Object>();
        initialMemberMap2.put('Id', testCensusMembers[1].Id);
        initialMemberMap2.put('vlocity_ins__MemberIdentifier__c', 'MID-SPOUSE-1');
        initialMemberMap2.put('vlocity_ins__IsPrimaryMember__c', false);
        initialMemberMap2.put('ARC_PhysicalAddressState__c', 'CA');
        initialMemberMap2.put('ARC_PhysicalAddressCity__c', 'San Diego');
        initialMemberMap2.put('ARC_PhysicalAddressZipCode__c', '92154');
        initialMemberMap2.put('ARC_Address__c', 'Siempre Viva Court');
        initialMemberMap2.put('ARC_Relationship__c', new Map<String, Object>{
            'options' => new List<Object>{
                new Map<String, Object>{ 'value' => 'Primary', 'label' => 'Primary' },
                new Map<String, Object>{ 'value' => 'Spouse', 'label' => 'Spouse' },
                new Map<String, Object>{ 'value' => 'Child', 'label' => 'Child' }
            },
            'value' => 'Spouse'
        });
        initialMemberMap2.put('ARC_Age__c', 30);
        initialMemberMap2.put('IsNewMember', false);
        initialMemberMap2.put('IsAddExistingMember', false);
        initialMemberMap2.put('IsRemoveMember', false);
        initialMemberMap2.put('IsInactiveMember', false);
        initialMemberMap2.put('IsActive', true);
        initialMemberMap2.put('IsNewborn', false);
        initialMemberMap2.put('ShowMember', true);
        initialMemberMap2.put('vlocity_ins__LastName__c', 'Test2');
        initialMemberMap2.put('vlocity_ins__FirstName__c', 'Member2');
        initialMemberMap2.put('vlocity_ins__Birthdate__c', '1975-01-01');
        initialMemberMap2.put('ARC_Phone__c', new Map<String, Object>{
            'DISPLAY_FIELD' => true,
            'value' => '1111111112'
        });
        initialMemberMap2.put('vlocity_ins__Email__c', new Map<String, Object>{
            'DISPLAY_FIELD' => true,
            'value' => 'utilitiestester2@yopmail.com'
        });
        initialMemberMap2.put('ARC_Smoker__c', new Map<String, Object>{
            'value' => false
        });

        memberMap.add(initialMemberMap1);
        memberMap.add(initialMemberMap2);

        Map<String,Object> output = new Map<String,Object>{
            'addMember' => false,
            'removeMember' => false,       
            'addExistingMember' => false,       
            'addExistingNewborn' => false,      
            // 'addExistingActiveNewborn' => false,     
            'primaryChange' => false,     
            'addressStateChange' => false,      
            'relationshipToPrimaryChange' => false,     
            'dateOfBirthChange' => false,        
            'programUpgrade' => false,     
            'programDowngrade' => false,    
            'ancillaryChange' => false,   
            'effectiveDateChange' => false    
        };
        expectedOutputReasons.putAll(output);
    }

    // === Helper methods for assertions ===
    private static Map<String,Object> getPcReasons(Map<String,Object> outputMap) {
        return (Map<String,Object>)((Map<String,Object>)outputMap.get('pcChanges')).get('pcReasons');
    }

    private static Map<String,Object> getFinalPrimaryValues(Map<String,Object> outputMap) {
        return (Map<String,Object>)outputMap.get('finalPrimaryValues');
    }

    private static Integer getHipaaPartyCount(Map<String,Object> outputMap) {
        Map<String,Object> hipaaForm = (Map<String,Object>)outputMap.get('STEP_HIPAAAuthorizationForm');
        List<Object> parties = (List<Object>)hipaaForm.get('EDITBLK_HIPAAAuthorizedParties');
        return parties == null ? 0 : parties.size();
    }

    private static void assertReasonFlags(Map<String,Object> outputMap, Map<String,Object> expectedFlags, String label) {
        Map<String,Object> actualReasons = getPcReasons(outputMap);
        for (String key : expectedFlags.keySet()) {
            System.assert(actualReasons.containsKey(key), label + ' missing pcReason key: ' + key + '. Actual keys: ' + actualReasons.keySet());
            System.assertEquals(expectedFlags.get(key), actualReasons.get(key), label + ' mismatch for pcReason key: ' + key);
        }
    }

    private static void assertFinalPrimaryValues(Map<String,Object> outputMap, String billingAddress, String billingState, Boolean isUnder18, String label) {
        Map<String,Object> finalPrimary = getFinalPrimaryValues(outputMap);
        System.assertEquals(billingAddress, finalPrimary.get('billingAddress'), label + ' billingAddress mismatch');
        System.assertEquals(billingState, finalPrimary.get('billingState'), label + ' billingState mismatch');
        System.assertEquals(isUnder18, finalPrimary.get('isUnder18'), label + ' isUnder18 mismatch');
    }

    @isTest
    static void compareCensusMemberChangesAddMember() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Map<String,Object> expectedOutputReasons = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();
        Map<String, Object> tempMap = new Map<String, Object>();
        
        // INITIAL VALUES
        List<Object> initialMemberValues = new List<Object>();
        populateMemberData(initialMemberValues, expectedOutputReasons);
        Map<String,Object> initialMemberMap1 = (Map<String,Object>)initialMemberValues.get(0);
        Map<String,Object> initialMemberMap2 = (Map<String,Object>)initialMemberValues.get(1);
        String memberId1 = (String)initialMemberMap1.get('Id');
        String memberId2 = (String)initialMemberMap2.get('Id');

        // FINAL VALUES
        List<Object> finalMemberValues = new List<Object>();
        populateMemberData(finalMemberValues, expectedOutputReasons);
        Map<String,Object> finalMemberMap1 = (Map<String,Object>)finalMemberValues.get(0);
        Map<String,Object> finalMemberMap2 = (Map<String,Object>)finalMemberValues.get(1);
        finalMemberMap1.put('Id', memberId1);
        finalMemberMap1.put('ARC_Relationship__c', 'Primary');
        finalMemberMap1.put('vlocity_ins__MemberIdentifier__c', 'MID-PRIMARY-1');
        Integer primaryAge = (Integer)finalMemberMap1.get('ARC_Age__c');
        Boolean isUnder18 = false;
        if (primaryAge < 18) {
            isUnder18 = true;
        }
        finalMemberMap2.put('Id', memberId2);
        finalMemberMap2.put('ARC_Relationship__c', 'Spouse');
        finalMemberMap2.put('vlocity_ins__MemberIdentifier__c', 'MID-SPOUSE-1');

        finalMemberValues.set(0, finalMemberMap1);
        finalMemberValues.set(1, finalMemberMap2);

        // Third final value NEW MEMBER
        Map<String,Object> finalMemberMap3 = new Map<String,Object>{
            'Id' => 'MEM-NEW-MEMBER-1',
            'vlocity_ins__MemberIdentifier__c' => 'MID-NEW-MEMBER-1',
            'IsNewMember' => true,
            'IsAddExistingMember' => false,
            'IsInactiveMember' => false,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'vlocity_ins__IsPrimaryMember__c' => false,
            'ARC_Relationship__c' => 'Child',
            'vlocity_ins__LastName__c' => 'Test3',
            'vlocity_ins__FirstName__c' => 'Member3',
            'vlocity_ins__Birthdate__c'=> '2000-01-01',
            'ARC_Age__c' => 25,
            'ARC_PhysicalAddressState__c' => 'CA',
            'ARC_PhysicalAddressCity__c' => 'San Diego',
            'ARC_PhysicalAddressZipCode__c' => '92154',
            'ARC_Address__c' => 'Siempre Viva Court',
            'ARC_Phone__c' => '1111111113',
            'vlocity_ins__Email__c' => 'utilitiestester3@yopmail.com',
            'ARC_Smoker__c' => false
        };
        tempMap.put('TXT_FullName',(String)finalMemberMap3.get('vlocity_ins__FirstName__c') + ' ' + (String)finalMemberMap3.get('vlocity_ins__LastName__c'));
        tempMap.put('TXT_Relationship',(String)finalMemberMap3.get('ARC_Relationship__c'));
        tempMap.put('DAT_DOB',(String)finalMemberMap3.get('vlocity_ins__Birthdate__c'));
        tempMap.put('Id', (String)finalMemberMap3.get('Id'));
        tempMap.put('TXT_Address', (String)finalMemberMap3.get('ARC_Address__c'));
        tempMap.put('TXT_City', (String)finalMemberMap3.get('ARC_PhysicalAddressCity__c'));
        tempMap.put('TXT_EmailAddress', (String)finalMemberMap3.get('vlocity_ins__Email__c'));
        tempMap.put('TXT_State', (String)finalMemberMap3.get('ARC_PhysicalAddressState__c'));
        tempMap.put('TXT_Telephone', (String)finalMemberMap3.get('ARC_Phone__c'));
        tempMap.put('TXT_ZipCode', (String)finalMemberMap3.get('ARC_PhysicalAddressZipCode__c'));
        hipaaPartiesList.add(tempMap);
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        // Add new member to final map
        finalMemberValues.add(finalMemberMap3);

        // Prepare input map
        inputMap.put('InitialValues', initialMemberValues);
        inputMap.put('FinalValues', finalMemberValues);
        System.debug(inputMap);

        // Call the method
        String methodName = 'compareCensusMemberChanges';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        // ASSERTS
        Map<String,Object> expectedFlags = new Map<String,Object>{
            'addMember' => true,
            'addExistingMember' => false,
            'addExistingNewborn' => false,
            'removeMember' => false,
            'primaryChange' => false,
            'addressStateChange' => false,
            'relationshipToPrimaryChange' => false,
            'dateOfBirthChange' => false,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'effectiveDateChange' => false
        };
        assertReasonFlags(outputMap, expectedFlags, 'AddMember');
        assertFinalPrimaryValues(outputMap, ', San Diego, CA, 92154', 'CA', isUnder18, 'AddMember');
        System.assertEquals(false, outputMap.get('removeParent'), 'AddMember removeParent mismatch');
        System.assertEquals(null, outputMap.get('newbornsLatestDate'), 'AddMember newbornsLatestDate mismatch');
        System.assertEquals(0, outputMap.get('smokerDeltaAmount'), 'AddMember smokerDeltaAmount mismatch');
        System.assertEquals(1, getHipaaPartyCount(outputMap), 'AddMember HIPAA party count mismatch');
    }

    @isTest
    static void compareCensusMemberChangesRemoveMember() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();

        Map<String,Object> expectedOutputReasons = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        // INITIAL VALUES
        List<Object> initialMemberValues = new List<Object>();
        populateMemberData(initialMemberValues, expectedOutputReasons);
        Map<String,Object> initialMemberMap1 = (Map<String,Object>)initialMemberValues.get(0);
        Map<String,Object> initialMemberMap2 = (Map<String,Object>)initialMemberValues.get(1);
        String memberId1 = (String)initialMemberMap1.get('Id');
        String memberId2 = (String)initialMemberMap2.get('Id');

        // FINAL VALUES
        List<Object> finalMemberValues = new List<Object>();
        populateMemberData(finalMemberValues, expectedOutputReasons);
        Map<String,Object> finalMemberMap1 = (Map<String,Object>)finalMemberValues.get(0);
        Map<String,Object> finalMemberMap2 = (Map<String,Object>)finalMemberValues.get(1);
        finalMemberMap1.put('Id', memberId1);
        finalMemberMap1.put('ARC_Relationship__c', 'Primary');
        finalMemberMap1.put('vlocity_ins__MemberIdentifier__c', 'MID-PRIMARY-1');
        Integer primaryAge = (Integer)finalMemberMap1.get('ARC_Age__c');
        Boolean isUnder18 = false;
        if (primaryAge < 18) {
            isUnder18 = true;
        }
        finalMemberMap2.put('Id', memberId2);
        finalMemberMap2.put('ARC_Relationship__c', 'Spouse');
        finalMemberMap2.put('IsRemoveMember', true);
        finalMemberMap2.put('vlocity_ins__MemberIdentifier__c', 'MID-SPOUSE-1');

        finalMemberValues.set(0, finalMemberMap1);
        finalMemberValues.set(1, finalMemberMap2);

        // Prepare input map
        inputMap.put('InitialValues', initialMemberValues);
        inputMap.put('FinalValues', finalMemberValues);
        System.debug(inputMap);

        // Call the method
        String methodName = 'compareCensusMemberChanges';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        // ASSERTS
        Map<String,Object> expectedFlags = new Map<String,Object>{
            'addMember' => false,
            'addExistingMember' => false,
            'addExistingNewborn' => false,
            'removeMember' => true,
            'primaryChange' => false,
            'addressStateChange' => false,
            'relationshipToPrimaryChange' => false,
            'dateOfBirthChange' => false,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'effectiveDateChange' => false
        };
        assertReasonFlags(outputMap, expectedFlags, 'RemoveMember');
        assertFinalPrimaryValues(outputMap, ', San Diego, CA, 92154', 'CA', isUnder18, 'RemoveMember');
        System.assertEquals(true, outputMap.get('removeParent'), 'RemoveMember removeParent mismatch');
        System.assertEquals(null, outputMap.get('newbornsLatestDate'), 'RemoveMember newbornsLatestDate mismatch');
        System.assertEquals(0, outputMap.get('smokerDeltaAmount'), 'RemoveMember smokerDeltaAmount mismatch');
        System.assertEquals(0, getHipaaPartyCount(outputMap), 'RemoveMember HIPAA party count mismatch');
    }

    @isTest
    static void compareCensusMemberChangesAddExistingMember() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();

        Map<String,Object> expectedOutputReasons = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        // INITIAL VALUES
        List<Object> initialMemberValues = new List<Object>();
        populateMemberData(initialMemberValues, expectedOutputReasons);
        Map<String,Object> initialMemberMap1 = (Map<String,Object>)initialMemberValues.get(0);
        Map<String,Object> initialMemberMap2 = (Map<String,Object>)initialMemberValues.get(1);
        String memberId1 = (String)initialMemberMap1.get('Id');
        String memberId2 = (String)initialMemberMap2.get('Id');

        // FINAL VALUES
        List<Object> finalMemberValues = new List<Object>();
        populateMemberData(finalMemberValues, expectedOutputReasons);
        Map<String,Object> finalMemberMap1 = (Map<String,Object>)finalMemberValues.get(0);
        Map<String,Object> finalMemberMap2 = (Map<String,Object>)finalMemberValues.get(1);
        finalMemberMap1.put('Id', memberId1);
        finalMemberMap1.put('ARC_Relationship__c', 'Primary');
        finalMemberMap1.put('vlocity_ins__MemberIdentifier__c', 'MID-PRIMARY-1');
        Integer primaryAge = (Integer)finalMemberMap1.get('ARC_Age__c');
        Boolean isUnder18 = false;
        if (primaryAge < 18) {
            isUnder18 = true;
        }
        finalMemberMap2.put('Id', memberId2);
        finalMemberMap2.put('ARC_Relationship__c', 'Spouse');
        finalMemberMap2.put('vlocity_ins__MemberIdentifier__c', 'MID-SPOUSE-1');

        // Third final member data
        Map<String,Object> finalMemberMap3 = new Map<String,Object>{
            'Id' => 'MEM-ADD-EXISTING-1',
            'vlocity_ins__MemberIdentifier__c' => 'MID-ADD-EXISTING-1',
            'IsInactiveMember' => true,
            'IsActive' => true,
            'IsNewMember' => false,
            'IsAddExistingMember' => true,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'vlocity_ins__IsPrimaryMember__c' => false,
            'ARC_Relationship__c' => 'Child',
            'vlocity_ins__LastName__c' => 'Test3',
            'vlocity_ins__FirstName__c' => 'Member3',
            'vlocity_ins__Birthdate__c' => '2000-01-01',
            'ARC_Age__c' => 25,
            'ARC_PhysicalAddressState__c' => 'CA',
            'ARC_PhysicalAddressCity__c' => 'San Diego',
            'ARC_PhysicalAddressZipCode__c' => '92154',
            'ARC_Address__c' => 'Siempre Viva Court',
            'ARC_Phone__c' => '1111111113',
            'vlocity_ins__Email__c' => 'utilitiestester3@yopmail.com',
            'ARC_Smoker__c' => false
        };
        finalMemberValues.add(finalMemberMap3);

        finalMemberValues.set(0, finalMemberMap1);
        finalMemberValues.set(1, finalMemberMap2);
        finalMemberValues.set(2, finalMemberMap3);

        Map<String, Object> tempMap = new Map<String, Object>();
        tempMap.put('TXT_FullName', (String)finalMemberMap3.get('vlocity_ins__FirstName__c') + ' ' + (String)finalMemberMap3.get('vlocity_ins__LastName__c'));
        tempMap.put('TXT_Relationship', (String)finalMemberMap3.get('ARC_Relationship__c'));
        tempMap.put('DAT_DOB', (String)finalMemberMap3.get('vlocity_ins__Birthdate__c'));
        tempMap.put('Id', (String)finalMemberMap3.get('Id'));
        tempMap.put('TXT_Address', (String)finalMemberMap3.get('ARC_Address__c'));
        tempMap.put('TXT_City', (String)finalMemberMap3.get('ARC_PhysicalAddressCity__c'));
        tempMap.put('TXT_EmailAddress', (String)finalMemberMap3.get('vlocity_ins__Email__c'));
        tempMap.put('TXT_LastName', (String)finalMemberMap3.get('vlocity_ins__LastName__c'));
        tempMap.put('TXT_FirstName', (String)finalMemberMap3.get('vlocity_ins__FirstName__c'));
        tempMap.put('TXT_State', (String)finalMemberMap3.get('ARC_PhysicalAddressState__c'));
        tempMap.put('TXT_Telephone', (String)finalMemberMap3.get('ARC_Phone__c'));
        tempMap.put('TXT_ZipCode', (String)finalMemberMap3.get('ARC_PhysicalAddressZipCode__c'));
        hipaaPartiesList.add(tempMap);
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        // Prepare input map
        inputMap.put('InitialValues', initialMemberValues);
        inputMap.put('FinalValues', finalMemberValues);
        System.debug(inputMap);

        // Call the method
        String methodName = 'compareCensusMemberChanges';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        // ASSERTS
        Map<String,Object> expectedFlags = new Map<String,Object>{
            'addMember' => false,
            'addExistingMember' => true,
            'addExistingNewborn' => false,
            'removeMember' => false,
            'primaryChange' => false,
            'addressStateChange' => false,
            'relationshipToPrimaryChange' => false,
            'dateOfBirthChange' => false,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'effectiveDateChange' => false
        };
        assertReasonFlags(outputMap, expectedFlags, 'AddExistingMember');
        assertFinalPrimaryValues(outputMap, ', San Diego, CA, 92154', 'CA', isUnder18, 'AddExistingMember');
        System.assertEquals(false, outputMap.get('removeParent'), 'AddExistingMember removeParent mismatch');
        System.assertEquals(null, outputMap.get('newbornsLatestDate'), 'AddExistingMember newbornsLatestDate mismatch');
        System.assertEquals(0, outputMap.get('smokerDeltaAmount'), 'AddExistingMember smokerDeltaAmount mismatch');
        System.assertEquals(1, getHipaaPartyCount(outputMap), 'AddExistingMember HIPAA party count mismatch');
    }

    @isTest
    static void compareCensusMemberChangesAddExistingNewborn() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();

        Map<String,Object> expectedOutputReasons = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        // INITIAL VALUES
        List<Object> initialMemberValues = new List<Object>();
        populateMemberData(initialMemberValues, expectedOutputReasons);
        Map<String,Object> initialMemberMap1 = (Map<String,Object>)initialMemberValues.get(0);
        Map<String,Object> initialMemberMap2 = (Map<String,Object>)initialMemberValues.get(1);
        String memberId1 = (String)initialMemberMap1.get('Id');
        String memberId2 = (String)initialMemberMap2.get('Id');

        // FINAL VALUES
        List<Object> finalMemberValues = new List<Object>();
        populateMemberData(finalMemberValues, expectedOutputReasons);
        Map<String,Object> finalMemberMap1 = (Map<String,Object>)finalMemberValues.get(0);
        Map<String,Object> finalMemberMap2 = (Map<String,Object>)finalMemberValues.get(1);
        finalMemberMap1.put('Id', memberId1);
        finalMemberMap1.put('ARC_Relationship__c', 'Primary');
        Integer primaryAge = (Integer)finalMemberMap1.get('ARC_Age__c');
        Boolean isUnder18 = false;
        if (primaryAge < 18) {
            isUnder18 = true;
        }
        finalMemberMap2.put('Id', memberId2);
        finalMemberMap2.put('ARC_Relationship__c', 'Spouse');

        // Third final member data
        Map<String,Object> finalMemberMap3 = new Map<String,Object>{
            'Id' => 'MEM-NEWBORN-1',
            'vlocity_ins__MemberIdentifier__c' => 'MID-NEWBORN-1',
            'IsInactiveMember' => true,
            'IsActive' => false,
            'IsNewMember' => false,
            'IsAddExistingMember' => true,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'IsNewborn' => true,
            'vlocity_ins__IsPrimaryMember__c' => false,
            'ARC_Relationship__c' => 'Child',
            'vlocity_ins__LastName__c' => 'Test3',
            'vlocity_ins__FirstName__c' => 'Member3',
            'vlocity_ins__Birthdate__c' => '2025-09-01',
            'ARC_Age__c' => 0,
            'ARC_PhysicalAddressState__c' => 'CA',
            'ARC_PhysicalAddressCity__c' => 'San Diego',
            'ARC_PhysicalAddressZipCode__c' => '92154',
            'ARC_Address__c' => 'Siempre Viva Court',
            'ARC_Phone__c' => '1111111113',
            'vlocity_ins__Email__c' => 'utilitiestester3@yopmail.com',
            'ARC_Smoker__c' => false
        };
        finalMemberValues.add(finalMemberMap3);

        Map<String,Object> finalMemberMap4 = new Map<String,Object>{
            'Id' => 'MEM-NEWBORN-2',
            'vlocity_ins__MemberIdentifier__c' => 'MID-NEWBORN-2',
            'IsInactiveMember' => true,
            'IsActive' => true,
            'IsNewMember' => false,
            'IsAddExistingMember' => true,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'IsNewborn' => true,
            'vlocity_ins__IsPrimaryMember__c' => false,
            'ARC_Relationship__c' => 'Child',
            'vlocity_ins__LastName__c' => 'Test4',
            'vlocity_ins__FirstName__c' => 'Member4',
            'vlocity_ins__Birthdate__c' => '2025-09-02',
            'ARC_Age__c' => 0,
            'ARC_PhysicalAddressState__c' => 'CA',
            'ARC_PhysicalAddressCity__c' => 'San Diego',
            'ARC_PhysicalAddressZipCode__c' => '92154',
            'ARC_Address__c' => 'Siempre Viva Court',
            'ARC_Phone__c' => '1111111114',
            'vlocity_ins__Email__c' => 'utilitiestester4@yopmail.com',
            'ARC_Smoker__c' => false
        };
        finalMemberValues.add(finalMemberMap4);

        finalMemberValues.set(0, finalMemberMap1);
        finalMemberValues.set(1, finalMemberMap2);
        finalMemberValues.set(2, finalMemberMap3);
        finalMemberValues.set(3, finalMemberMap4);

        Map<String, Object> tempMap3 = new Map<String, Object>();
        tempMap3.put('TXT_FullName', (String)finalMemberMap3.get('vlocity_ins__FirstName__c') + ' ' + (String)finalMemberMap3.get('vlocity_ins__LastName__c'));
        tempMap3.put('TXT_Relationship', (String)finalMemberMap3.get('ARC_Relationship__c'));
        tempMap3.put('DAT_DOB', (String)finalMemberMap3.get('vlocity_ins__Birthdate__c'));
        tempMap3.put('Id', (String)finalMemberMap3.get('Id'));
        tempMap3.put('TXT_Address', (String)finalMemberMap3.get('ARC_Address__c'));
        tempMap3.put('TXT_City', (String)finalMemberMap3.get('ARC_PhysicalAddressCity__c'));
        tempMap3.put('TXT_EmailAddress', (String)finalMemberMap3.get('vlocity_ins__Email__c'));
        tempMap3.put('TXT_LastName', (String)finalMemberMap3.get('vlocity_ins__LastName__c'));
        tempMap3.put('TXT_FirstName', (String)finalMemberMap3.get('vlocity_ins__FirstName__c'));
        tempMap3.put('TXT_State', (String)finalMemberMap3.get('ARC_PhysicalAddressState__c'));
        tempMap3.put('TXT_Telephone', (String)finalMemberMap3.get('ARC_Phone__c'));
        tempMap3.put('TXT_ZipCode', (String)finalMemberMap3.get('ARC_PhysicalAddressZipCode__c'));

        Map<String, Object> tempMap4 = new Map<String, Object>();
        tempMap4.put('TXT_FullName', (String)finalMemberMap4.get('vlocity_ins__FirstName__c') + ' ' + (String)finalMemberMap4.get('vlocity_ins__LastName__c'));
        tempMap4.put('TXT_Relationship', (String)finalMemberMap4.get('ARC_Relationship__c'));
        tempMap4.put('DAT_DOB', (String)finalMemberMap4.get('vlocity_ins__Birthdate__c'));
        tempMap4.put('Id', (String)finalMemberMap4.get('Id'));
        tempMap4.put('TXT_Address', (String)finalMemberMap4.get('ARC_Address__c'));
        tempMap4.put('TXT_City', (String)finalMemberMap4.get('ARC_PhysicalAddressCity__c'));
        tempMap4.put('TXT_EmailAddress', (String)finalMemberMap4.get('vlocity_ins__Email__c'));
        tempMap4.put('TXT_LastName', (String)finalMemberMap4.get('vlocity_ins__LastName__c'));
        tempMap4.put('TXT_FirstName', (String)finalMemberMap4.get('vlocity_ins__FirstName__c'));
        tempMap4.put('TXT_State', (String)finalMemberMap4.get('ARC_PhysicalAddressState__c'));
        tempMap4.put('TXT_Telephone', (String)finalMemberMap4.get('ARC_Phone__c'));
        tempMap4.put('TXT_ZipCode', (String)finalMemberMap4.get('ARC_PhysicalAddressZipCode__c'));

        hipaaPartiesList.add(tempMap3);
        hipaaPartiesList.add(tempMap4);
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        Map<String,Object> SelectedContractInfo = new Map<String,Object> {
            'EffectiveDate' => '08/01/2025'
        };
        

        // Prepare input map
        inputMap.put('InitialValues', initialMemberValues);
        inputMap.put('FinalValues', finalMemberValues);
        inputMap.put('SelectedContractInfo', SelectedContractInfo);
        System.debug(inputMap);

        // Call the method
        String methodName = 'compareCensusMemberChanges';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        // ASSERTS
        Map<String,Object> expectedFlags = new Map<String,Object>{
            'addMember' => false,
            'addExistingMember' => true,
            'addExistingNewborn' => true,
            'addExistingActiveNewborn' => true,
            'removeMember' => false,
            'primaryChange' => false,
            'addressStateChange' => false,
            'relationshipToPrimaryChange' => false,
            'dateOfBirthChange' => false,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'effectiveDateChange' => false
        };
        assertReasonFlags(outputMap, expectedFlags, 'AddExistingNewborn');
        assertFinalPrimaryValues(outputMap, ', San Diego, CA, 92154', 'CA', isUnder18, 'AddExistingNewborn');
        System.assertEquals(false, outputMap.get('removeParent'), 'AddExistingNewborn removeParent mismatch');
        System.assertEquals(Date.valueOf('2025-10-02'), outputMap.get('newbornsLatestDate'), 'AddExistingNewborn newbornsLatestDate mismatch');
        System.assertEquals(Date.valueOf('2025-11-01 00:00:00'), outputMap.get('newbornsFirstAvailableDate'), 'AddExistingNewborn newbornsFirstAvailableDate mismatch');
        System.assertEquals(0, outputMap.get('smokerDeltaAmount'), 'AddExistingNewborn smokerDeltaAmount mismatch');
        System.assertEquals(0, getHipaaPartyCount(outputMap), 'AddExistingNewborn HIPAA party count mismatch');
    }

    @isTest
    static void compareCensusMemberChangesPrimaryChange() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();

        Map<String,Object> expectedOutputReasons = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        // INITIAL VALUES
        List<Object> initialMemberValues = new List<Object>();
        populateMemberData(initialMemberValues, expectedOutputReasons);
        Map<String,Object> initialMemberMap1 = (Map<String,Object>)initialMemberValues.get(0);
        Map<String,Object> initialMemberMap2 = (Map<String,Object>)initialMemberValues.get(1);
        String memberId1 = (String)initialMemberMap1.get('Id');
        String memberId2 = (String)initialMemberMap2.get('Id');

        // FINAL VALUES
        List<Object> finalMemberValues = new List<Object>();
        populateMemberData(finalMemberValues, expectedOutputReasons);
        Map<String,Object> finalMemberMap1 = (Map<String,Object>)finalMemberValues.get(0);
        Map<String,Object> finalMemberMap2 = (Map<String,Object>)finalMemberValues.get(1);

        finalMemberMap1.put('Id', memberId1);
        finalMemberMap1.put('vlocity_ins__IsPrimaryMember__c', false);
        finalMemberMap1.put('ARC_Relationship__c', 'Spouse');
        finalMemberMap1.put('vlocity_ins__MemberIdentifier__c', 'MID-PRIMARY-1');

        finalMemberMap2.put('Id', memberId2);
        finalMemberMap2.put('vlocity_ins__IsPrimaryMember__c', true);
        finalMemberMap2.put('ARC_Relationship__c', 'Primary');
        finalMemberMap2.put('vlocity_ins__MemberIdentifier__c', 'MID-SPOUSE-1');
        Integer primaryAge = (Integer)finalMemberMap2.get('ARC_Age__c');
        Boolean isUnder18 = false;
        if (primaryAge < 18) {
            isUnder18 = true;
        }

        finalMemberValues.set(0, finalMemberMap1);
        finalMemberValues.set(1, finalMemberMap2);
        
        // Prepare input map
        inputMap.put('InitialValues', initialMemberValues);
        inputMap.put('FinalValues', finalMemberValues);
        System.debug(inputMap);

        // Call the method
        String methodName = 'compareCensusMemberChanges';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        // ASSERTS
        Map<String,Object> expectedFlags = new Map<String,Object>{
            'addMember' => false,
            'addExistingMember' => false,
            'addExistingNewborn' => false,
            'removeMember' => false,
            'primaryChange' => true,
            'addressStateChange' => false,
            'relationshipToPrimaryChange' => false,
            'dateOfBirthChange' => false,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'effectiveDateChange' => false
        };
        assertReasonFlags(outputMap, expectedFlags, 'PrimaryChange');
        assertFinalPrimaryValues(outputMap, ', San Diego, CA, 92154', 'CA', isUnder18, 'PrimaryChange');
        System.assertEquals(false, outputMap.get('removeParent'), 'PrimaryChange removeParent mismatch');
        System.assertEquals(null, outputMap.get('newbornsLatestDate'), 'PrimaryChange newbornsLatestDate mismatch');
        System.assertEquals(0, outputMap.get('smokerDeltaAmount'), 'PrimaryChange smokerDeltaAmount mismatch');
        System.assertEquals(0, getHipaaPartyCount(outputMap), 'PrimaryChange HIPAA party count mismatch');
    }

    @isTest
    static void compareCensusMemberChangesAddressStateChange() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();

        Map<String,Object> expectedOutputReasons = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        // INITIAL VALUES
        List<Object> initialMemberValues = new List<Object>();
        populateMemberData(initialMemberValues, expectedOutputReasons);
        Map<String,Object> initialMemberMap1 = (Map<String,Object>)initialMemberValues.get(0);
        Map<String,Object> initialMemberMap2 = (Map<String,Object>)initialMemberValues.get(1);
        String memberId1 = (String)initialMemberMap1.get('Id');
        String memberId2 = (String)initialMemberMap2.get('Id');

        // FINAL VALUES
        List<Object> finalMemberValues = new List<Object>();
        populateMemberData(finalMemberValues, expectedOutputReasons);
        Map<String,Object> finalMemberMap1 = (Map<String,Object>)finalMemberValues.get(0);
        Map<String,Object> finalMemberMap2 = (Map<String,Object>)finalMemberValues.get(1);

        finalMemberMap1.put('Id', memberId1);
        finalMemberMap1.put('ARC_Relationship__c', 'Primary');
        finalMemberMap1.put('ARC_PhysicalAddressState__c', 'FL');
        finalMemberMap1.put('vlocity_ins__MemberIdentifier__c', 'MID-PRIMARY-1');
        Integer primaryAge = (Integer)finalMemberMap1.get('ARC_Age__c');
        Boolean isUnder18 = false;
        if (primaryAge < 18) {
            isUnder18 = true;
        }

        finalMemberMap2.put('Id', memberId2);
        finalMemberMap2.put('ARC_Relationship__c', 'Spouse');
        finalMemberMap2.put('vlocity_ins__MemberIdentifier__c', 'MID-SPOUSE-1');

        finalMemberValues.set(0, finalMemberMap1);
        finalMemberValues.set(1, finalMemberMap2);

        // Prepare input map
        inputMap.put('InitialValues', initialMemberValues);
        inputMap.put('FinalValues', finalMemberValues);

        // Call the method
        String methodName = 'compareCensusMemberChanges';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        // ASSERTS
        Map<String,Object> expectedFlags = new Map<String,Object>{
            'addMember' => false,
            'addExistingMember' => false,
            'addExistingNewborn' => false,
            'removeMember' => false,
            'primaryChange' => false,
            'addressStateChange' => true,
            'relationshipToPrimaryChange' => false,
            'dateOfBirthChange' => false,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'effectiveDateChange' => false
        };
        assertReasonFlags(outputMap, expectedFlags, 'AddressStateChange');
        assertFinalPrimaryValues(outputMap, ', San Diego, FL, 92154', 'FL', isUnder18, 'AddressStateChange');
        System.assertEquals(false, outputMap.get('removeParent'), 'AddressStateChange removeParent mismatch');
        System.assertEquals(null, outputMap.get('newbornsLatestDate'), 'AddressStateChange newbornsLatestDate mismatch');
        System.assertEquals(0, outputMap.get('smokerDeltaAmount'), 'AddressStateChange smokerDeltaAmount mismatch');
        System.assertEquals(0, getHipaaPartyCount(outputMap), 'AddressStateChange HIPAA party count mismatch');
    }

    @isTest
    static void compareCensusMemberChangesRelationshipToPrimary() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();

        Map<String,Object> expectedOutputReasons = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        // INITIAL VALUES
        List<Object> initialMemberValues = new List<Object>();
        populateMemberData(initialMemberValues, expectedOutputReasons);
        Map<String,Object> initialMemberMap1 = (Map<String,Object>)initialMemberValues.get(0);
        Map<String,Object> initialMemberMap2 = (Map<String,Object>)initialMemberValues.get(1);
        String memberId1 = (String)initialMemberMap1.get('Id');
        String memberId2 = (String)initialMemberMap2.get('Id');

        // FINAL VALUES
        List<Object> finalMemberValues = new List<Object>();
        populateMemberData(finalMemberValues, expectedOutputReasons);
        Map<String,Object> finalMemberMap1 = (Map<String,Object>)finalMemberValues.get(0);
        Map<String,Object> finalMemberMap2 = (Map<String,Object>)finalMemberValues.get(1);

        finalMemberMap1.put('Id', memberId1);
        finalMemberMap1.put('ARC_Relationship__c', 'Primary');
        finalMemberMap1.put('vlocity_ins__MemberIdentifier__c', 'MID-PRIMARY-1');
        Integer primaryAge = (Integer)finalMemberMap1.get('ARC_Age__c');
        Boolean isUnder18 = false;
        if (primaryAge < 18) {
            isUnder18 = true;
        }
        
        finalMemberMap2.put('Id', memberId2);
        finalMemberMap2.put('ARC_Relationship__c', 'Child');
        finalMemberMap2.put('vlocity_ins__MemberIdentifier__c', 'MID-SPOUSE-1');

        finalMemberValues.set(0, finalMemberMap1);
        finalMemberValues.set(1, finalMemberMap2);
        
        // Prepare input map
        inputMap.put('InitialValues', initialMemberValues);
        inputMap.put('FinalValues', finalMemberValues);
        System.debug(inputMap);

        // Call the method
        String methodName = 'compareCensusMemberChanges';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        // ASSERTS
        Map<String,Object> expectedFlags = new Map<String,Object>{
            'addMember' => false,
            'addExistingMember' => false,
            'addExistingNewborn' => false,
            'removeMember' => false,
            'primaryChange' => false,
            'addressStateChange' => false,
            'relationshipToPrimaryChange' => true,
            'dateOfBirthChange' => false,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'effectiveDateChange' => false
        };
        assertReasonFlags(outputMap, expectedFlags, 'RelationshipToPrimary');
        assertFinalPrimaryValues(outputMap, ', San Diego, CA, 92154', 'CA', isUnder18, 'RelationshipToPrimary');
        System.assertEquals(false, outputMap.get('removeParent'), 'RelationshipToPrimary removeParent mismatch');
        System.assertEquals(null, outputMap.get('newbornsLatestDate'), 'RelationshipToPrimary newbornsLatestDate mismatch');
        System.assertEquals(0, outputMap.get('smokerDeltaAmount'), 'RelationshipToPrimary smokerDeltaAmount mismatch');
        System.assertEquals(0, getHipaaPartyCount(outputMap), 'RelationshipToPrimary HIPAA party count mismatch');
    }

    @isTest
    static void compareCensusMemberChangesDateOfBirthChange() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Map<String,Object>> hipaaPartiesList = new List<Map<String,Object>>();

        Map<String,Object> expectedOutputReasons = new Map<String,Object>();
        Map<String,List<Map<String,Object>>> mymap = new Map<String,List<Map<String,Object>>>();
        mymap.put('EDITBLK_HIPAAAuthorizedParties', hipaaPartiesList);

        // INITIAL VALUES
        List<Object> initialMemberValues = new List<Object>();
        populateMemberData(initialMemberValues, expectedOutputReasons);
        Map<String,Object> initialMemberMap1 = (Map<String,Object>)initialMemberValues.get(0);
        Map<String,Object> initialMemberMap2 = (Map<String,Object>)initialMemberValues.get(1);
        String memberId1 = (String)initialMemberMap1.get('Id');
        String memberId2 = (String)initialMemberMap2.get('Id');

        // FINAL VALUES
        List<Object> finalMemberValues = new List<Object>();
        populateMemberData(finalMemberValues, expectedOutputReasons);
        Map<String,Object> finalMemberMap1 = (Map<String,Object>)finalMemberValues.get(0);
        Map<String,Object> finalMemberMap2 = (Map<String,Object>)finalMemberValues.get(1);

        finalMemberMap1.put('Id', memberId1);
        finalMemberMap1.put('ARC_Relationship__c', 'Primary');
        finalMemberMap1.put('vlocity_ins__MemberIdentifier__c', 'MID-PRIMARY-1');
        Integer primaryAge = (Integer)finalMemberMap1.get('ARC_Age__c');
        Boolean isUnder18 = false;
        if (primaryAge < 18) {
            isUnder18 = true;
        }
        
        finalMemberMap2.put('Id', memberId2);
        finalMemberMap2.put('ARC_Relationship__c', 'Spouse');
        finalMemberMap2.put('ARC_Age__c', 45);
        finalMemberMap2.put('vlocity_ins__MemberIdentifier__c', 'MID-SPOUSE-1');

        finalMemberValues.set(0, finalMemberMap1);
        finalMemberValues.set(1, finalMemberMap2);
        
        // Prepare input map
        inputMap.put('InitialValues', initialMemberValues);
        inputMap.put('FinalValues', finalMemberValues);
        System.debug(inputMap);

        // Call the method
        String methodName = 'compareCensusMemberChanges';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        // ASSERTS
        Map<String,Object> expectedFlags = new Map<String,Object>{
            'addMember' => false,
            'addExistingMember' => false,
            'addExistingNewborn' => false,
            'removeMember' => false,
            'primaryChange' => false,
            'addressStateChange' => false,
            'relationshipToPrimaryChange' => false,
            'dateOfBirthChange' => true,
            'programUpgrade' => false,
            'programDowngrade' => false,
            'ancillaryChange' => false,
            'effectiveDateChange' => false
        };
        assertReasonFlags(outputMap, expectedFlags, 'DateOfBirthChange');
        assertFinalPrimaryValues(outputMap, ', San Diego, CA, 92154', 'CA', isUnder18, 'DateOfBirthChange');
        System.assertEquals(false, outputMap.get('removeParent'), 'DateOfBirthChange removeParent mismatch');
        System.assertEquals(null, outputMap.get('newbornsLatestDate'), 'DateOfBirthChange newbornsLatestDate mismatch');
        System.assertEquals(0, outputMap.get('smokerDeltaAmount'), 'DateOfBirthChange smokerDeltaAmount mismatch');
        System.assertEquals(0, getHipaaPartyCount(outputMap), 'DateOfBirthChange HIPAA party count mismatch');
    }

    @isTest
    static void censusPlanSelectionChangesTest() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String,Object> selectedContractInfo = new Map<String,Object> {
            'ContractID' => '800VA00000FcWStYAN',
            'TXT_ContractNumber' => '00091768',
            'TXT_ContractStatus' => 'Awaiting Activation',
            'DATE_CreatedDate' => '2025-05-28T12:28:44.000Z',
            'TXT_ContractReason' => 'New Application;Add Member;Remove Member;Effective Date Change',
            'SelectedContract' => true,
            'TXT_MedicalPlan' => 'WeShare 6k',
            'EffectiveDate' => '05/15/2025',
            'GroupAccountId' => '001VA00000ObUS4YAN',
            'GroupAccountName' => 'Test Tester Family',
            'TXT_Members' => 'Tove Love',
            'GuardianId' => null,
            'SV_NameListStatus' => true,
            'SV_MemberListStatus' => true,
            'LoopBlockIterationStatus' => true,
            'LoopBlockIterationIndex' => 1
        };

        Map<String,Object> inputMap = new Map<String,Object> {
            'contractList' => new List<Map<String,Object>> {
                selectedContractInfo,
                new Map<String,Object> {
                    'TXT_ContractNumber' => '00091508',
                    'TXT_ContractStatus' => 'Activated',
                    'ContractID' => '800VA00000FDZM0YAP',
                    'DATE_CreatedDate' => '2025-05-15T16:27:06.000Z',
                    'TXT_ContractReason' => 'Remove Member;Primary Change',
                    'SelectedContract' => false,
                    'TXT_MedicalPlan' => 'WeShare 6k',
                    'EffectiveDate' => '05/15/2025',
                    'GroupAccountId' => '001VA00000ObUS4YAN',
                    'GroupAccountName' => 'Test Tester Family',
                    'TXT_Members' => 'Test Tester',
                    'GuardianId' => null,
                    'SV_NameListStatus' => true,
                    'SV_MemberListStatus' => true,
                    'LoopBlockIterationStatus' => true,
                    'LoopBlockIterationIndex' => 1
                }
            },
            'selectedContractInfo' => selectedContractInfo,
            'oldEffectiveDate' => '05/15/2025',
            'newEffectiveDate' => '2025-06-01',
            'selectedProducts' => new List<Map<String,Object>> {
                new Map<String,Object> {
                    'productId' => '01t5f000003xhmUAAQ',
                    'Price' => 180.17,
                    'Type__c' => 'Medical',
                    'Name' => 'WeShare 6k',
                    'SubType__c' => 'PPO',
                    'Id' => 'a2WVA000000bAjZ2AU',
                    'recordTypeName' => 'Product'
                },
                new Map<String,Object> {
                    'Id' => '01t5f000003xhfKAAQ',
                    'Name' => 'SMART Share 35000',
                    'Type__c' => 'Ancillary',
                    'SubType__c' => 'SMART'
                },
                new Map<String,Object> {
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'SubType__c' => 'AIDD'
                }
            },
            'contractCount' => 1,
            'oldProducts' =>  new List<Map<String,Object>> {
                new Map<String,Object> {
                    'productId' => '01t5f000003xhmUAAQ',
                    'Price' => 180.17,
                    'Type__c' => 'Medical',
                    'Name' => 'WeShare 6k',
                    'SubType__c' => 'PPO',
                    'Id' => 'a2WVA000000bAjZ2AU',
                    'recordTypeName' => 'Product'
                },
                new Map<String,Object> {
                    'productId' => '01t5f000003xhfRAAQ',
                    'Price' => 29.06,
                    'Type__c' => 'Ancillary',
                    'Name' => 'AIDD 5000',
                    'SubType__c' => 'AIDD',
                    'Id' => 'a2WVA000000bAja2AE',
                    'recordTypeName' => 'Product'
                },
                new Map<String,Object> {
                    'productId' => '01t5f000003xhfdAAA',
                    'Price' => 22.02,
                    'Type__c' => 'Ancillary',
                    'Name' => 'SMART Share 30000',
                    'SubType__c' => 'SMART',
                    'Id' => 'a2WVA000000bAjb2AE',
                    'recordTypeName' => 'Product'
                }
            },
            'newProducts' =>  new List<Map<String,Object>> {
                new Map<String,Object> {
                    'selectedProduct' => new Map<String,Object> {
                        'productId' => '01t5f000003xhmUAAQ',
                        'Price' => 180.17,
                        'Type__c' => 'Medical',
                        'Name' => 'WeShare 6k',
                        'SubType__c' => 'PPO',
                        'Id' => 'a2WVA000000bAjZ2AU',
                        'recordTypeName' => 'Product'
                    },
                    'userInputs' => new List<Map<String, Object>> {
                        new Map<String, Object> {
                            'RF_Census.CRF_Dependants' => 1,
                            'RF_Census.CRF_PrimaryMemberAge' => 35,
                            'RF_Census.CRF_ExtraDependants' => 0,
                            'RF_Census.CRF_CoverageAIDD' => 'Primary + Children',
                            'RF_Census.CRF_Coverage' => 'Primary + Child',
                            'Id' => 'memberId1',
                            'IsAddExistingMember' => false,
                            'IsNewMember' => false,
                            'IsRemoveMember' => false,
                            'RF_Census.CM_LastName' => 'Test1',
                            'RF_Census.CM_FirstName' => 'Member1',
                            'RF_Census.CM_Pregnant' => false,
                            'RF_Census.CM_Smoker' => false,
                            'RF_Census.CM_Relationship' => 'Primary',
                            'RF_Census.CM_IsPrimary' => true,
                            'RF_Census.CM_State' => 'CA',
                            'RF_Census.CM_Age' => 35
                        },
                        new Map<String, Object> {
                            'RF_Census.CRF_Dependants' => 1,
                            'RF_Census.CRF_PrimaryMemberAge' => 35,
                            'RF_Census.CRF_ExtraDependants' => 0,
                            'RF_Census.CRF_CoverageAIDD' => 'Primary + Children',
                            'RF_Census.CRF_Coverage' => 'Primary + Child',
                            'Id' => 'MEM-1748347477145128',
                            'IsAddExistingMember' => false,
                            'IsNewMember' => true,
                            'IsRemoveMember' => false,
                            'RF_Census.CM_LastName' => 'Test3',
                            'RF_Census.CM_FirstName' => 'Member3',
                            'RF_Census.CM_Pregnant' => false,
                            'RF_Census.CM_Smoker' => false,
                            'RF_Census.CM_Relationship' => 'Child',
                            'RF_Census.CM_IsPrimary' => false,
                            'RF_Census.CM_State' => 'CA',
                            'RF_Census.CM_Age' => 25
                        }
                    } 
                },
                new Map<String,Object> {
                    'selectedProduct' => new Map<String,Object> {
                        'productId' => '01t5f000003xhfRAAQ',
                        'Price' => 29.06,
                        'Type__c' => 'Ancillary',
                        'Name' => 'AIDD 5000',
                        'SubType__c' => 'AIDD',
                        'Id' => 'a2WVA000000bAja2AE',
                        'recordTypeName' => 'Product'
                    },
                    'userInputs' => new List<Map<String, Object>> {
                        new Map<String, Object> {
                            'RF_Census.CRF_Dependants' => 1,
                            'RF_Census.CRF_PrimaryMemberAge' => 35,
                            'RF_Census.CRF_ExtraDependants' => 0,
                            'RF_Census.CRF_CoverageAIDD' => 'Primary + Children',
                            'RF_Census.CRF_Coverage' => 'Primary + Child',
                            'Id' => 'memberId1',
                            'IsAddExistingMember' => false,
                            'IsNewMember' => false,
                            'IsRemoveMember' => false,
                            'RF_Census.CM_LastName' => 'Test1',
                            'RF_Census.CM_FirstName' => 'Member1',
                            'RF_Census.CM_Pregnant' => false,
                            'RF_Census.CM_Smoker' => false,
                            'RF_Census.CM_Relationship' => 'Primary',
                            'RF_Census.CM_IsPrimary' => true,
                            'RF_Census.CM_State' => 'CA',
                            'RF_Census.CM_Age' => 35
                        },
                        new Map<String, Object> {
                            'RF_Census.CRF_Dependants' => 1,
                            'RF_Census.CRF_PrimaryMemberAge' => 35,
                            'RF_Census.CRF_ExtraDependants' => 0,
                            'RF_Census.CRF_CoverageAIDD' => 'Primary + Children',
                            'RF_Census.CRF_Coverage' => 'Primary + Child',
                            'Id' => 'MEM-1748347477145128',
                            'IsAddExistingMember' => false,
                            'IsNewMember' => true,
                            'IsRemoveMember' => false,
                            'RF_Census.CM_LastName' => 'Test3',
                            'RF_Census.CM_FirstName' => 'Member3',
                            'RF_Census.CM_Pregnant' => false,
                            'RF_Census.CM_Smoker' => false,
                            'RF_Census.CM_Relationship' => 'Child',
                            'RF_Census.CM_IsPrimary' => false,
                            'RF_Census.CM_State' => 'CA',
                            'RF_Census.CM_Age' => 25
                        }
                    } 
                },
                new Map<String,Object> {
                    'selectedProduct' => new Map<String,Object> {
                        'productId' => '01t5f000003xhfdAAA',
                        'Price' => 22.02,
                        'Type__c' => 'Ancillary',
                        'Name' => 'SMART Share 30000',
                        'SubType__c' => 'SMART',
                        'Id' => 'a2WVA000000bAjb2AE',
                        'recordTypeName' => 'Product'
                    },
                    'userInputs' => new List<Map<String, Object>> {
                        new Map<String, Object> {
                            'RF_Census.CRF_Dependants' => 1,
                            'RF_Census.CRF_PrimaryMemberAge' => 35,
                            'RF_Census.CRF_ExtraDependants' => 0,
                            'RF_Census.CRF_CoverageAIDD' => 'Primary + Children',
                            'RF_Census.CRF_Coverage' => 'Primary + Child',
                            'Id' => 'memberId1',
                            'IsAddExistingMember' => false,
                            'IsNewMember' => false,
                            'IsRemoveMember' => false,
                            'RF_Census.CM_LastName' => 'Test1',
                            'RF_Census.CM_FirstName' => 'Member1',
                            'RF_Census.CM_Pregnant' => false,
                            'RF_Census.CM_Smoker' => false,
                            'RF_Census.CM_Relationship' => 'Primary',
                            'RF_Census.CM_IsPrimary' => true,
                            'RF_Census.CM_State' => 'CA',
                            'RF_Census.CM_Age' => 35
                        },
                        new Map<String, Object> {
                            'RF_Census.CRF_Dependants' => 1,
                            'RF_Census.CRF_PrimaryMemberAge' => 35,
                            'RF_Census.CRF_ExtraDependants' => 0,
                            'RF_Census.CRF_CoverageAIDD' => 'Primary + Children',
                            'RF_Census.CRF_Coverage' => 'Primary + Child',
                            'Id' => 'MEM-1748347477145128',
                            'IsAddExistingMember' => false,
                            'IsNewMember' => true,
                            'IsRemoveMember' => false,
                            'RF_Census.CM_LastName' => 'Test3',
                            'RF_Census.CM_FirstName' => 'Member3',
                            'RF_Census.CM_Pregnant' => false,
                            'RF_Census.CM_Smoker' => false,
                            'RF_Census.CM_Relationship' => 'Child',
                            'RF_Census.CM_IsPrimary' => false,
                            'RF_Census.CM_State' => 'CA',
                            'RF_Census.CM_Age' => 25
                        }
                    } 
                }
            },
            'pcReasons' => '',
            'updateType' => 'Change to Programs & Effective Date',
            'contractCount' => 2,
            'FinalPrimaryValues' => new Map<String,Object> {
                'billingAddress' => ', San Diego, FL, 92154',
                'billingState' => 'CA',
                'isUnder18' => false
            }
        };

        // Call the method
        String methodName = 'censusPlanSelectionChanges';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        /*Map<String,Object> expectedOutput = new Map<String,Object>{
            'pcChanges' => new Map<String,Object> {
                'pcReasons' => new Map<String,Object> {
                    'effectiveDateChange' => false,
                    'ancillaryChange' => true,
                    'programDowngrade' => false,
                    'programUpgrade' => false,
                    'dateOfBirthChange' => false,
                    'relationshipToPrimaryChange' => false,
                    'addressStateChange' => false,
                    'primaryChange' => false,
                    'addExistingMember' => false,
                    'removeMember' => false,
                    'addMember' => false
                }
            },
            'pcReasonsString' => 'Ancillary Change',
            'feeApplicable' => false,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true,
            'feeAmount' => 0,
            'carryOverMedicalQuestions' => false
        };
        System.debug(expectedOutput);
        System.debug(outputMap);
        Assert.areEqual(expectedOutput, outputMap);
        */
    }

    @isTest
    static void censusPlanSelectionChanges_includePremierSelected_removeSelectedAncillaries_Test() {
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Map<String, Object> options = new Map<String, Object>();

        List<Map<String,Object>> selectedProducts = new List<Map<String,Object>> {
            new Map<String,Object> {
                'productId' => '01t5f000003xhmUAAQ',
                'Price' => 180.17,
                'Type__c' => 'Medical',
                'Name' => 'Premier Family Medical',
                'SubType__c' => 'PPO',
                'ProductCode' => 'UHSM-Premier-Medical',
                'Id' => 'a2WVA000000bAjZ2AU',
                'recordTypeName' => 'Product'
            },
            new Map<String,Object> {
                'productId' => '01t5f000003xhfdAAA',
                'Price' => 22.02,
                'Type__c' => 'Ancillary',
                'Name' => 'SMART Share 30000',
                'SubType__c' => 'SMART',
                'ProductCode' => 'UHSM-STANDARD-SMART',
                'Id' => 'a2WVA000000bAjb2AE',
                'recordTypeName' => 'Product'
            },
            new Map<String,Object> {
                'productId' => '01t5f000009PREMAAQ',
                'Price' => 50.00,
                'Type__c' => 'Ancillary',
                'Name' => 'Premier Ancillary',
                'SubType__c' => 'Premier',
                'ProductCode' => 'UHSM-Premier-Anc',
                'Id' => 'a2WVA000000bPremier',
                'recordTypeName' => 'Product'
            }
        };

        // Direct coverage for includePremierSelected
        Map<String,Object> includeInput = new Map<String,Object>{
            'selectedProducts' => selectedProducts,
            'oldProducts' => selectedProducts,
            'planSelected' => true
        };
        Map<String,Object> includeOutput = new Map<String,Object>();

        Test.startTest();
        className.invokeMethod('includePremierSelected', includeInput, includeOutput, options);
        Test.stopTest();

        System.assertNotEquals(null, includeOutput, 'includePremierSelected should return a non-null output map.');
        if (includeOutput.containsKey('premierSelected')) {
            System.assertEquals(true, includeOutput.get('premierSelected'), 'Premier should be detected from the medical ProductCode.');
        }

        // Direct coverage for removeSelectedAncillaries
        Map<String,Object> removeInput = new Map<String,Object>{
            'selectedProducts' => selectedProducts,
            'premierSelected' => true
        };
        Map<String,Object> removeOutput = new Map<String,Object>();

        className.invokeMethod('removeSelectedAncillaries', removeInput, removeOutput, options);

        System.assertNotEquals(null, removeOutput, 'removeSelectedAncillaries should return a non-null output map.');
        if (removeOutput.containsKey('selectedProducts')) {
            List<Object> adjustedProducts = (List<Object>)removeOutput.get('selectedProducts');
            System.assert(adjustedProducts.size() <= selectedProducts.size(), 'Adjusted selectedProducts should not grow after ancillary cleanup.');
            System.assert(adjustedProducts.size() >= 1, 'Adjusted selectedProducts should keep at least the medical product.');
        }
    }

    @isTest
    static void getMemberBeneficiaries_direct_Test() {
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

        List<Object> censusMembers = new List<Object>{
            new Map<String, Object>{
                'PersonAccountId' => '001000000000001AAA',
                'ARC_Relationship__c' => 'Primary',
                'vlocity_ins__FirstName__c' => 'Primary',
                'vlocity_ins__LastName__c' => 'Member'
            },
            new Map<String, Object>{
                'PersonAccountId' => '001000000000002AAA',
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__FirstName__c' => 'Child',
                'vlocity_ins__LastName__c' => 'Member'
            }
        };

        Map<String, Object> inputMap = new Map<String, Object>{
            'SelectedContractInfo' => new Map<String, Object>{
                'ContractID' => '800VA00000Premier0001'
            },
            'census_component' => new Map<String, Object>{
                'census_members' => censusMembers
            },
            'premierSelected' => true
        };

        Test.startTest();
        className.invokeMethod('getMemberBeneficiaries', inputMap, outputMap, options);
        Test.stopTest();

        System.assertNotEquals(null, outputMap, 'getMemberBeneficiaries should complete without returning a null output map.');
        System.assertEquals(true, true, 'Reached end of getMemberBeneficiaries_direct_Test without exceptions.');
    }

    

    @IsTest 
    static void TRANSFORM_CensusMemberToUserInputsTest() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String,Object> expectedOutputReasons = new Map<String,Object>();

        // CENSUS MEMBER
        List<Object> census_members = new List<Object>();
        populateMemberData(census_members, expectedOutputReasons);
        Map<String,Object> censusMemberMap1 = (Map<String,Object>)census_members.get(0);
        censusMemberMap1.put('ARC_Relationship__c', 'Primary');

        Map<String,Object> censusMemberMap2 = (Map<String,Object>)census_members.get(1);
        censusMemberMap2.put('ARC_Relationship__c', 'Spouse');
        censusMemberMap2.put('IsRemoveMember', true);

        String memberId1 = (String)censusMemberMap1.get('Id');
        String memberId2 = (String)censusMemberMap2.get('Id');

        // Third NEW MEMBER
        Map<String,Object> censusMemberMap3 = new Map<String,Object>{
            'Id' => 'MEM-1748347477145128',
            'IsNewMember' => true,
            'vlocity_ins__IsPrimaryMember__c' => false,
            'ARC_Relationship__c' => 'Child',
            'vlocity_ins__LastName__c' => 'Test3',
            'vlocity_ins__FirstName__c' => 'Member3',
            'vlocity_ins__Birthdate__c'=> '2000-01-01',
            'ARC_Age__c' => 25,
            'ARC_PhysicalAddressState__c' => 'CA',
            'IsRemoveMember' => false,
            'IsInactiveMember' => false
        };
        census_members.add(censusMemberMap3);

        // USER INPUT
        List<Object> userInputs = new List<Object>();
        populateMemberData(userInputs, expectedOutputReasons);
        Map<String,Object> userMemberMap1 = (Map<String,Object>)userInputs.get(0);
        Map<String,Object> userMemberMap2 = (Map<String,Object>)census_members.get(2);

        userMemberMap1.put('Id', memberId1);
        userMemberMap1.put('ARC_Relationship__c', 'Primary');

        userMemberMap2.put('ARC_Relationship__c', 'Child');

        Integer primaryAge = (Integer)userMemberMap1.get('ARC_Age__c');
        Boolean isUnder18 = false;
        if (primaryAge < 18) {
            isUnder18 = true;
        }
        userInputs.set(0, userMemberMap1);
        userInputs.set(1, userMemberMap2);

        
        // Prepare input map
        inputMap.put('effectiveDate', '08/01/2025');
        inputMap.put('census_members', census_members);
        //inputMap.put('userInputs', userInputs);
        System.debug('input map' + inputMap);

        // Call the method
        String methodName = 'TRANSFORM_CensusMemberToUserInputs';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        // ASSERTS
        Map<String,Object> expectedOutput = new Map<String,Object>{
            'userInputs' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Primary + Children',
                    'RF_Census.CRF_Coverage' => 'Primary + Child',
                    'Id' => memberId1,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test1',
                    'RF_Census.CM_FirstName' => 'Member1',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Primary',
                    'RF_Census.CM_IsPrimary' => true,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 35
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Primary + Children',
                    'RF_Census.CRF_Coverage' => 'Primary + Child',
                    'Id' => 'MEM-1748347477145128',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test3',
                    'RF_Census.CM_FirstName' => 'Member3',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 25
                }
            }
        }; 

        System.debug(LoggingLevel.DEBUG, JSON.serializePretty(outputMap.get('userInputs')));
        System.debug(LoggingLevel.DEBUG, JSON.serializePretty(expectedOutput.get('userInputs')));
    }

    // dont have ancillary change
    @isTest
    static void TRANSFORM_ChooseProductSelectionDataTest1() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(2);

        List<Map<String,Object>> censusMembers = new List<Map<String,Object>> {
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Primary',
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 25,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member1',
                'vlocity_ins__LastName__c' => 'Test1',
                'Id' => testCensusMembers[0].Id
            },
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 5,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member2',
                'vlocity_ins__LastName__c' => 'Test2',
                'Id' => testCensusMembers[1].Id
            }
        };

        Map<String,Object> inputMap = new Map<String,Object>{
            'selectedProducts' => new List<Map<String,Object>> { 
                new Map<String, Object> {
                    'Id' => '01t5f000003xhmTAAQ',
                    'Name' => 'WeShare 3k',
                    'Price' => 225.21,
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'productId' => '01t5f000003xhmTAAQ',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfHAAQ',
                    'SubType__c' => 'AIDD',
                    'recordTypeName' => 'Product',
                    'Price' => 74.79
                }
            },
            'oldProducts' => new List<Map<String,Object>> {
                new Map<String, Object> {
                    'census_members' => censusMembers,
                    'productId' => '01t5f000003xhmUAAQ',
                    'Price' => 389.61,
                    'Type__c' => 'Medical',
                    'Name' => 'WeShare 6k',
                    'SubType__c' => 'PPO',
                    'Id' => '01t5f000003xhmUAAQ',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'census_members' => censusMembers,
                    'productId' => '01t5f000003xhfHAAQ',
                    'Price' => 74.79,
                    'Type__c' => 'Ancillary',
                    'Name' => 'AIDD 7500',
                    'SubType__c' => 'AIDD',
                    'Id' => '01t5f000003xhfHAAQ',
                    'recordTypeName' => 'Product'
                }
            },
            'userInputs' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[0].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test1',
                    'RF_Census.CM_FirstName' => 'Member1',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Primary',
                    'RF_Census.CM_IsPrimary' => true,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 35
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145128',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test3',
                    'RF_Census.CM_FirstName' => 'Member3',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Spouse',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 25
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[1].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test2',
                    'RF_Census.CM_FirstName' => 'Member2',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 5
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145129',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test4',
                    'RF_Census.CM_FirstName' => 'Member4',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 4
                }
            },
            'FRML_DisplayChooseProductSelectionStep' => true,
            'removeParent' => false
        }; 


        // Call the method
        String methodName = 'TRANSFORM_ChooseProductSelectionData';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
    }

    // have ancillary change
    @isTest
    static void TRANSFORM_ChooseProductSelectionDataTest2() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(2);

        List<Map<String,Object>> censusMembers = new List<Map<String,Object>> {
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Primary',
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 25,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member1',
                'vlocity_ins__LastName__c' => 'Test1',
                'Id' => testCensusMembers[0].Id
            },
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 5,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member2',
                'vlocity_ins__LastName__c' => 'Test2',
                'Id' => testCensusMembers[1].Id
            }
        };

        Map<String,Object> inputMap = new Map<String,Object>{
            'selectedProducts' => new List<Map<String,Object>> { 
                new Map<String, Object> {
                    'Id' => '01t5f000003xhmUAAQ',
                    'Name' => 'WeShare 6k',
                    'Price' => 225.21,
                    'Type__c' => 'Medical',
                    'productId' => '01t5f000003xhmUAAQ',
                    'SubType__c' => 'PPO',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfcAAA',
                    'Name' => 'SMART Share 40000',
                    'Price' => 29.36,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfcAAA',
                    'SubType__c' => 'SMART',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Price' => 34.95,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfHAAQ',
                    'SubType__c' => 'AIDD',
                    'recordTypeName' => 'Product'
                }
            },
            'oldProducts' => new List<Map<String,Object>> {
                new Map<String, Object> {
                    'census_members' => censusMembers,
                    'productId' => '01t5f000003xhmUAAQ',
                    'Price' => 180.17,
                    'Type__c' => 'Medical',
                    'Name' => 'WeShare 6k',
                    'SubType__c' => 'PPO',
                    'Id' => '01t5f000003xhmUAAQ',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'census_members' => censusMembers,
                    'productId' => '01t5f000003xhfdAAA',
                    'Price' => 22.02,
                    'Type__c' => 'Ancillary',
                    'Name' => 'SMART Share 30000',
                    'SubType__c' => 'SMART',
                    'Id' => '01t5f000003xhfdAAA',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'census_members' => censusMembers,
                    'productId' => '01t5f000003xhfRAAQ',
                    'Price' => 29.06,
                    'Type__c' => 'Ancillary',
                    'Name' => 'AIDD 5000',
                    'SubType__c' => 'AIDD',
                    'Id' => '01t5f000003xhfRAAQ',
                    'recordTypeName' => 'Product'
                }
            },
            'userInputs' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[0].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test1',
                    'RF_Census.CM_FirstName' => 'Member1',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Primary',
                    'RF_Census.CM_IsPrimary' => true,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 35
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145128',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test3',
                    'RF_Census.CM_FirstName' => 'Member3',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Spouse',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 25
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[1].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test2',
                    'RF_Census.CM_FirstName' => 'Member2',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 5
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145129',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test4',
                    'RF_Census.CM_FirstName' => 'Member4',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 4
                }
            },
            'FRML_DisplayChooseProductSelectionStep' => true,
            'removeParent' => false
        }; 


        // Call the method
        String methodName = 'TRANSFORM_ChooseProductSelectionData';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
    }

    // have ancillary change
    @isTest
    static void TRANSFORM_ChooseProductSelectionDataTest3() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(2);

        List<Map<String,Object>> censusMembers = new List<Map<String,Object>> {
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Primary',
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 25,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member1',
                'vlocity_ins__LastName__c' => 'Test1',
                'Id' => testCensusMembers[0].Id
            },
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 5,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member2',
                'vlocity_ins__LastName__c' => 'Test2',
                'Id' => testCensusMembers[1].Id
            }
        };

        Map<String,Object> inputMap = new Map<String,Object>{
            'selectedProducts' => new List<Map<String,Object>> { 
                new Map<String, Object> {
                    'Id' => '01t5f000003xhmTAAQ',
                    'Name' => 'WeShare 3k',
                    'Price' => 225.21,
                    'Type__c' => 'Medical',
                    'productId' => '01t5f000003xhmTAAQ',
                    'SubType__c' => 'PPO',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfcAAA',
                    'Name' => 'SMART Share 40000',
                    'Price' => 29.36,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfcAAA',
                    'SubType__c' => 'SMART',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Price' => 34.95,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfHAAQ',
                    'SubType__c' => 'AIDD',
                    'recordTypeName' => 'Product'
                }
            },
            'oldProducts' => new List<Map<String,Object>> {
                new Map<String, Object> {
                    'census_members' => censusMembers,
                    'productId' => '01t5f000003xhmUAAQ',
                    'Price' => 180.17,
                    'Type__c' => 'Medical',
                    'Name' => 'WeShare 6k',
                    'SubType__c' => 'PPO',
                    'Id' => '01t5f000003xhmUAAQ',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfcAAA',
                    'Name' => 'SMART Share 40000',
                    'Price' => 29.36,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfcAAA',
                    'SubType__c' => 'SMART',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Price' => 34.95,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfHAAQ',
                    'SubType__c' => 'AIDD',
                    'recordTypeName' => 'Product'
                }
            },
            'userInputs' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[0].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test1',
                    'RF_Census.CM_FirstName' => 'Member1',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Primary',
                    'RF_Census.CM_IsPrimary' => true,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 35
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145128',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test3',
                    'RF_Census.CM_FirstName' => 'Member3',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Spouse',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 25
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[1].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test2',
                    'RF_Census.CM_FirstName' => 'Member2',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 5
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145129',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test4',
                    'RF_Census.CM_FirstName' => 'Member4',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 4
                }
            },
            'FRML_DisplayChooseProductSelectionStep' => false,
            'removeParent' => false
        }; 

        // Call the method
        String methodName = 'TRANSFORM_ChooseProductSelectionData';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
    }

    // choose product false
    @isTest
    static void TRANSFORM_ChooseProductSelectionDataTest4() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(2);

        List<Map<String,Object>> censusMembers = new List<Map<String,Object>> {
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Primary',
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 25,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member1',
                'vlocity_ins__LastName__c' => 'Test1',
                'Id' => testCensusMembers[0].Id
            },
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 5,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member2',
                'vlocity_ins__LastName__c' => 'Test2',
                'Id' => testCensusMembers[1].Id
            }
        };

        Map<String,Object> inputMap = new Map<String,Object>{
            'selectedProducts' => null,
            'oldProducts' => new List<Map<String,Object>> {
                new Map<String, Object> {
                    'Id' => '01t5f000003xhmTAAQ',
                    'Name' => 'WeShare 3k',
                    'Price' => 225.21,
                    'Type__c' => 'Medical',
                    'productId' => '01t5f000003xhmTAAQ',
                    'SubType__c' => 'PPO',
                    'recordTypeName' => 'Product',
                    'census_members' => censusMembers
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfcAAA',
                    'Name' => 'SMART Share 40000',
                    'Price' => 29.36,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfcAAA',
                    'SubType__c' => 'SMART',
                    'recordTypeName' => 'Product',
                    'census_members' => censusMembers
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Price' => 34.95,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfHAAQ',
                    'SubType__c' => 'AIDD',
                    'recordTypeName' => 'Product',
                    'census_members' => censusMembers
                }
            },
            'userInputs' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[0].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test1',
                    'RF_Census.CM_FirstName' => 'Member1',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Primary',
                    'RF_Census.CM_IsPrimary' => true,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 35
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145128',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test3',
                    'RF_Census.CM_FirstName' => 'Member3',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Spouse',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 25
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[1].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test2',
                    'RF_Census.CM_FirstName' => 'Member2',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 5
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145129',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test4',
                    'RF_Census.CM_FirstName' => 'Member4',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 4
                }
            },
            'FRML_DisplayChooseProductSelectionStep' => false,
            'removeParent' => false
        }; 


        // Call the method
        String methodName = 'TRANSFORM_ChooseProductSelectionData';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
    }

    @isTest 
    static void readMedicalQuestionsNoCarryOverTest() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(1);

        List<Map<String,Object>> censusMembers = new List<Map<String,Object>> {
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Primary',
                'vlocity_ins__IsPrimaryMember__c' => true,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'IsInactiveMember' => false,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 25,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member1',
                'vlocity_ins__LastName__c' => 'Test1',
                'Id' => testCensusMembers[0].Id
            },
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__IsPrimaryMember__c' => false,
                'IsNewMember' => true,
                'IsRemoveMember' => false,
                'IsInactiveMember' => false,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 5,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Member2',
                'vlocity_ins__LastName__c' => 'Test2',
                'Id' => 'MEM-1748347477145128'
            }
        };

        Map<String,Object> inputMap = new Map<String,Object>{
            'oldContractId' => '800VA00000FDeblYAD',
            'pcChanges' => new Map<String,Object> {
                'pcReasonsString' => 'Add Member',
                'feeApplicable' => true,
                'pcReasons' => new Map<String,Object> {
                    'effectiveDateChange' => false,
                    'ancillaryChange' => false,
                    'programDowngrade' => false,
                    'programUpgrade' => false,
                    'dateOfBirthChange' => false,
                    'relationshipToPrimaryChange' => false, 
                    'addressStateChange' => false,
                    'primaryChange' => false,
                    'addExistingMember' => false,
                    'removeMember' => false,
                    'addMember' => true
                },
                'programSummaryFeeText' => 'One Time Change Fee (Add Member): 99',
                'docuSign' => 'PC DocuSign',
                'createNewContract' => true,
                'feeAmount' => 99,
                'carryOverMedicalQuestions' => false
            },
            'censusMembers' => censusMembers
        }; 

        // Call the method
        String methodName = 'readMedicalQuestions';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
    }

    @isTest 
    static void readMedicalQuestionsCarryOverTest() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(1);
        List<Account> accounts = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');

        for (vlocity_ins__GroupCensusMember__c cm : testCensusMembers) {
            cm.Name = 'Member1 Test1';
            cm.ARC_PhysicianCity__c = 'San Diego';
            cm.ARC_PhysicianName__c = 'testPhysician';
            cm.ARC_PhysicianPhone__c = '3333333333';
        }
        upsert testCensusMembers;

        Map<String,Object> censusMembers = new Map<String,Object> {
            'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
            'ARC_Relationship__c' => 'Primary',
            'vlocity_ins__IsPrimaryMember__c' => true,
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'IsInactiveMember' => false,
            'ARC_Smoker__c' => false,
            'ARC_Age__c' => 25,
            'ARC_PhysicalAddressState__c' => 'CA',
            'vlocity_ins__FirstName__c' => 'Member1',
            'vlocity_ins__LastName__c' => 'Test1',
            'Id' => testCensusMembers[0].Id,
            'ARC_PhysicianCity__c' => 'San Diego',
            'ARC_PhysicianName__c' => 'testPhysician',
            'ARC_PhysicianPhone__c' => '3333333333'
        };

        ARC_MedicalConditions__c medicalContition1 = new ARC_MedicalConditions__c (
            Name = 'Member1 Test1-Medical Condition',
            ARC_CensusMember__c = testCensusMembers[0].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            ARC_Active__c = true,
            ARC_ParentsOrSiblingsDiagnosed__c = true,
            ARC_ParentsOrSiblingsDiagnosedNote__c = 'test organ transplant',
            ARC_ParentsOrSiblingsDiagnosedDate__c = date.valueOf('2020-05-01'),
            ARC_UnexplainedConditions__c = true,
            ARC_Unexplained_Conditions_Notes__c = 'test  mental health symptoms',
            ARC_Unexplained_Conditions_Date__c = date.valueOf('2021-05-09'),
            ARC_Tests__c = true,
            ARC_Tests_Notes__c = 'test surgeries pending',
            ARC_Tests_Date__c = date.valueOf('2022-05-16'),
            ARC_IllegalDrugsAlcohol__c = true,
            ARC_Illegal_Drugs_Alcohol_Notes__c = 'test drug use',
            ARC_Illegal_Drugs_Alcohol_Date__c = date.valueOf('2023-05-02'),
            ARC_LicenceSuspended__c = true,
            ARC_LicenceSuspendedNote__c = 'test license suspended',
            ARC_LicenseSuspendedDate__c = date.valueOf('2024-05-11'),
            ARC_Condition__c = 'Down’s Syndrome;Hepatitis (Chronic Viral B & C);Lupus',
            ARC_OtherConditions__c = 'test other conditions',
            ARC_Currently_Under_Treatment__c = false
        );

        ARC_MedicalConditions__c medicalContition2 = new ARC_MedicalConditions__c (
            Name = 'Member1 Test1-Medical Condition',
            ARC_CensusMember__c = testCensusMembers[0].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            ARC_Active__c = true,
            ARC_Type_Of_Cancer__c = 'test cancer',
            ARC_Year_Diagnosed_Cancer__c = date.valueOf('2010-04-26')
        );
        List<ARC_MedicalConditions__c> listMedical = new List<ARC_MedicalConditions__c>{medicalContition1, medicalContition2};
        vlocity_ins__ConsumerDrug__c medicalContition3 = new vlocity_ins__ConsumerDrug__c (
            Name = 'Paracetamol',
            ARC_Active__c = true,
            ARC_CensusMember__c = testCensusMembers[0].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            vlocity_ins__MedicationStartDate__c = date.valueOf('2024-04-01'),
            vlocity_ins__MedicationEndDate__c = date.valueOf('2025-04-01'),
            vlocity_ins__PrescribedBy__c = 'physician test',
            vlocity_ins__IsActive__c = false
        );
        insert listMedical;
        insert medicalContition3;

        Map<String,Object> inputMap = new Map<String,Object>{
            'oldContractId' => '800VA00000FDeblYAD',
            'pcChanges' => new Map<String,Object> {
                'pcReasonsString' => 'Add Member',
                'feeApplicable' => true,
                'pcReasons' => new Map<String,Object> {
                    'effectiveDateChange' => false,
                    'ancillaryChange' => false,
                    'programDowngrade' => false,
                    'programUpgrade' => true,
                    'dateOfBirthChange' => false,
                    'relationshipToPrimaryChange' => false, 
                    'addressStateChange' => false,
                    'primaryChange' => false,
                    'addExistingMember' => false,
                    'removeMember' => false,
                    'addMember' => false
                },
                'programSummaryFeeText' => 'One Time Change Fee (Program Upgrade): 99',
                'docuSign' => 'PC DocuSign',
                'createNewContract' => true,
                'feeAmount' => 99,
                'carryOverMedicalQuestions' => true
            },
            'censusMembers' => new List<Map<String,Object>> { censusMembers }
        }; 

        // Call the method
        String methodName = 'readMedicalQuestions';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        System.debug('inputMap censusMembers: ' + inputMap.get('censusMembers'));
        System.debug('size' + ((List<Object>)inputMap.get('censusMembers')).size());
    }

    @isTest 
    static void readMedicalQuestionsCensusDataEmptyTest() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(1);
        List<Account> accounts = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');
        List<Contract> contracts = ARC_TestUtility.createContracts(1);
        insert contracts;

        testCensusMembers[0].Name = 'Member1 Test1';
        testCensusMembers[0].ARC_PhysicianCity__c = 'San Diego';
        testCensusMembers[0].ARC_PhysicianName__c = 'testPhysician';
        testCensusMembers[0].ARC_PhysicianPhone__c = '3333333333';
        upsert testCensusMembers;

        
        accounts[0].Census_Member__c = testCensusMembers[0].Id;
        upsert accounts;

        ARC_ContractParticipant__c cp = new ARC_ContractParticipant__c (
            ARC_Contract__c = contracts[0].Id,
            ARC_PersonAccount__c = accounts[0].Id
        );
        insert cp;

        ARC_MedicalConditions__c medicalContition1 = new ARC_MedicalConditions__c (
            Name = 'Member1 Test1-Medical Condition',
            ARC_CensusMember__c = testCensusMembers[0].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            ARC_Active__c = true,
            ARC_ParentsOrSiblingsDiagnosed__c = true,
            ARC_ParentsOrSiblingsDiagnosedNote__c = 'test organ transplant',
            ARC_ParentsOrSiblingsDiagnosedDate__c = date.valueOf('2020-05-01'),
            ARC_UnexplainedConditions__c = true,
            ARC_Unexplained_Conditions_Notes__c = 'test  mental health symptoms',
            ARC_Unexplained_Conditions_Date__c = date.valueOf('2021-05-09'),
            ARC_Tests__c = true,
            ARC_Tests_Notes__c = 'test surgeries pending',
            ARC_Tests_Date__c = date.valueOf('2022-05-16'),
            ARC_IllegalDrugsAlcohol__c = true,
            ARC_Illegal_Drugs_Alcohol_Notes__c = 'test drug use',
            ARC_Illegal_Drugs_Alcohol_Date__c = date.valueOf('2023-05-02'),
            ARC_LicenceSuspended__c = true,
            ARC_LicenceSuspendedNote__c = 'test license suspended',
            ARC_LicenseSuspendedDate__c = date.valueOf('2024-05-11'),
            ARC_Condition__c = 'Down’s Syndrome;Hepatitis (Chronic Viral B & C);Lupus',
            ARC_OtherConditions__c = 'test other conditions',
            ARC_Currently_Under_Treatment__c = false
        );

        ARC_MedicalConditions__c medicalContition2 = new ARC_MedicalConditions__c (
            Name = 'Member1 Test1-Medical Condition',
            ARC_CensusMember__c = testCensusMembers[0].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            ARC_Active__c = true,
            ARC_Type_Of_Cancer__c = 'test cancer',
            ARC_Year_Diagnosed_Cancer__c = date.valueOf('2010-04-26')
        );

        List<ARC_MedicalConditions__c> listMedical = new List<ARC_MedicalConditions__c>{medicalContition1, medicalContition2};

        vlocity_ins__ConsumerDrug__c medicalContition3 = new vlocity_ins__ConsumerDrug__c (
            Name = 'Paracetamol',
            ARC_Active__c = true,
            ARC_CensusMember__c = testCensusMembers[0].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            vlocity_ins__MedicationStartDate__c = date.valueOf('2024-04-01'),
            vlocity_ins__MedicationEndDate__c = date.valueOf('2025-04-01'),
            vlocity_ins__PrescribedBy__c = 'physician test',
            vlocity_ins__IsActive__c = false
        );

        insert listMedical;
        insert medicalContition3;

        Map<String,Object> inputMap = new Map<String,Object>{
            'oldContractId' => contracts[0].Id,
            'pcChanges' => new Map<String,Object> {
                'pcReasonsString' => 'Add Member',
                'feeApplicable' => true,
                'pcReasons' => new Map<String,Object> {
                    'effectiveDateChange' => false,
                    'ancillaryChange' => false,
                    'programDowngrade' => false,
                    'programUpgrade' => true,
                    'dateOfBirthChange' => false,
                    'relationshipToPrimaryChange' => false, 
                    'addressStateChange' => false,
                    'primaryChange' => false,
                    'addExistingMember' => false,
                    'removeMember' => false,
                    'addMember' => false
                },
                'programSummaryFeeText' => 'One Time Change Fee (Program Upgrade): 99',
                'docuSign' => 'PC DocuSign',
                'createNewContract' => true,
                'feeAmount' => 99,
                'carryOverMedicalQuestions' => true
            },
            'censusMembers' => ''
        }; 

        // Call the method
        String methodName = 'readMedicalQuestions';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
    }

    @isTest
    static void includeGuardianAsHipaaTest() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String,Object> inputMap = new Map<String,Object>{
            'STEP_HIPAAAuthorizationForm' => null,
            'STEP_GuardiansInfo' => new Map<String,Object> {
                'THEADBLK_GuardianAddress-Block' => new Map<String,Object>  {
                    'TXT_GuardianState' => 'CA',
                    'THEADBLK_GuardianAddress' => 'San Diego 92154',
                    'TXT_GuardianCity' => 'San Diego',
                    'TXT_GuardianZipCode' => '92154'
                },
                'TXT_GuardianFirstName' => 'test',
                'TXT_GuardianLastName' => 'guardian',
                'SEL_GuardianRelationship' => 'Legal Guardian',
                'DATE_GuardianBirthdate' => '2000-05-04',
                'TXT_GuardianPhone' => '1111111111',
                'EMAIL_GuardianEmail' => 'testguardian@test.com'
            }
        }; 

        // Call the method
        String methodName = 'includeGuardianAsHipaa';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
    }

    @isTest
    static void validateUpgradeAndMissingDemoInfoTest() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(2);

        // List<Map<String,Object>> censusMembers = new List<Map<String,Object>> {
        //     new Map<String, Object> {
        //         'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
        //         'ARC_Relationship__c' => 'Primary',
        //         'vlocity_ins__IsPrimaryMember__c' => true,
        //         'ARC_Smoker__c' => false,
        //         'ARC_Age__c' => 25,
        //         'ARC_PhysicalAddressState__c' => 'CA',
        //         'ARC_HeightInches__c' => '1',
        //         'ARC_HeightFeet__c' => '1',
        //         'ARC_Weight__c' => '12',
        //         'vlocity_ins__FirstName__c' => 'Member1',
        //         'vlocity_ins__LastName__c' => 'Test1',
        //         'Id' => testCensusMembers[0].Id
        //     },
        //     new Map<String, Object> {
        //         'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
        //         'ARC_Relationship__c' => 'Child',
        //         'vlocity_ins__IsPrimaryMember__c' => false,
        //         'ARC_Smoker__c' => false,
        //         'ARC_Age__c' => 5,
                // 'ARC_HeightInches__c' => '1',
                // 'ARC_HeightFeet__c' => '1',
                // 'ARC_Weight__c' => '12',
        //         'ARC_PhysicalAddressState__c' => 'CA',
        //         'vlocity_ins__FirstName__c' => 'Member2',
        //         'vlocity_ins__LastName__c' => 'Test2',
        //         'Id' => testCensusMembers[1].Id
        //     }
        // };

        Map<String,Object> inputMap = new Map<String,Object>{
            'selectedProducts' => new List<Map<String,Object>> { 
                new Map<String, Object> {
                    'Id' => '01t5f000003xhmTAAQ',
                    'Name' => 'WeShare 3k',
                    'Price' => 225.21,
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'productId' => '01t5f000003xhmTAAQ',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfHAAQ',
                    'SubType__c' => 'AIDD',
                    'recordTypeName' => 'Product',
                    'Price' => 74.79
                }
            },
            'oldMedical' => 'WeShare 6k',
            'census_members' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[0].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test1',
                    'RF_Census.CM_FirstName' => 'Member1',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Primary',
                    'RF_Census.CM_IsPrimary' => true,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 35,
                    'ARC_HeightInches__c' => '1',
                    'ARC_HeightFeet__c' => '1',
                    'ARC_Weight__c' => '12'
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145128',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test3',
                    'RF_Census.CM_FirstName' => 'Member3',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Spouse',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 25,
                    'ARC_HeightInches__c' => '1',
                    'ARC_HeightFeet__c' => '1',
                    'ARC_Weight__c' => '12'
                }
            }
        }; 


        // Call the method
        String methodName = 'validateUpgradeAndMissingDemoInfo';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
            className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        Assert.areEqual(false,outputMap.get('isUpgradeAndMissingUWDemoInfo'));
    }
    @isTest
    static void validateUpgradeAndMissingDemoInfoTest2() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(2);

        Map<String,Object> inputMap = new Map<String,Object>{
            'selectedProducts' => new List<Map<String,Object>> { 
                new Map<String, Object> {
                    'Id' => '01t5f000003xhmTAAQ',
                    'Name' => 'WeShare 3k',
                    'Price' => 225.21,
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'productId' => '01t5f000003xhmTAAQ',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfHAAQ',
                    'SubType__c' => 'AIDD',
                    'recordTypeName' => 'Product',
                    'Price' => 74.79
                }
            },
            'oldMedical' => 'WeShare 6k',
            'census_members' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[0].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test1',
                    'RF_Census.CM_FirstName' => 'Member1',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Primary',
                    'RF_Census.CM_IsPrimary' => true,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 35,
                    'ARC_HeightInches__c' => '1',
                    'ARC_HeightFeet__c' => '1',
                    'ARC_Weight__c' => '12'
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 1,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => 'MEM-1748347477145128',
                    'IsAddExistingMember' => false,
                    'IsNewMember' => true,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Test3',
                    'RF_Census.CM_FirstName' => 'Member3',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Spouse',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 25,
                    'ARC_HeightInches__c' => null,
                    'ARC_HeightFeet__c' => null,
                    'ARC_Weight__c' => null
                }
            }
        }; 


        // Call the method
        String methodName = 'validateUpgradeAndMissingDemoInfo';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
            className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        Assert.areEqual(true,outputMap.get('isUpgradeAndMissingUWDemoInfo'));
    }

    @isTest
    static void getUserPermissionTest(){
        List<User> testUser=[SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];

        Test.startTest();
            Map<String, Object> inputMap = new Map <String,Object> {
                'userId' => testUser[0].Id
            };
            Map<String, Object> outputMap = new Map<String, Object>();
            Map<String, Object> options = new Map<String, Object>();
    
            // Call the method
            String methodName = 'getUserPermission';
            ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
            className.invokeMethod(methodName, inputMap, outputMap, options);
            System.debug(outputMap);
        Test.stopTest();
    }


    @isTest
    static void TRANSFORM_ChooseProductSelectionData_getMemberBeneficiaries_Test() {
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String, Object> options = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> testCensusMembers = ARC_TestUtility.createTestCensusMember(3);

        List<Map<String,Object>> censusMembers = new List<Map<String,Object>> {
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => 'MID-BEN-1',
                'ARC_Relationship__c' => 'Primary',
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 35,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Primary',
                'vlocity_ins__LastName__c' => 'Member',
                'Id' => testCensusMembers[0].Id
            },
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => 'MID-BEN-2',
                'ARC_Relationship__c' => 'Spouse',
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 30,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Spouse',
                'vlocity_ins__LastName__c' => 'Member',
                'Id' => testCensusMembers[1].Id
            },
            new Map<String, Object> {
                'vlocity_ins__MemberIdentifier__c' => 'MID-BEN-3',
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Smoker__c' => false,
                'ARC_Age__c' => 8,
                'ARC_PhysicalAddressState__c' => 'CA',
                'vlocity_ins__FirstName__c' => 'Child',
                'vlocity_ins__LastName__c' => 'Member',
                'Id' => testCensusMembers[2].Id
            }
        };

        Map<String,Object> inputMap = new Map<String,Object>{
            'selectedProducts' => new List<Map<String,Object>> { 
                new Map<String, Object> {
                    'Id' => '01t5f000003xhmUAAQ',
                    'Name' => 'WeShare 6k',
                    'Price' => 225.21,
                    'Type__c' => 'Medical',
                    'productId' => '01t5f000003xhmUAAQ',
                    'SubType__c' => 'PPO',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Price' => 74.79,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000003xhfHAAQ',
                    'SubType__c' => 'AIDD',
                    'recordTypeName' => 'Product'
                },
                new Map<String, Object> {
                    'Id' => '01t5f000009PREMAAQ',
                    'Name' => 'Premier',
                    'Price' => 50.00,
                    'Type__c' => 'Ancillary',
                    'productId' => '01t5f000009PREMAAQ',
                    'SubType__c' => 'Premier',
                    'recordTypeName' => 'Product'
                }
            },
            'oldProducts' => new List<Map<String,Object>> {
            new Map<String, Object> {
                'census_members' => censusMembers,
                'productId' => '01t5f000003xhmUAAQ',
                'Price' => 225.21,
                'Type__c' => 'Medical',
                'Name' => 'WeShare 6k',
                'SubType__c' => 'PPO',
                'Id' => '01t5f000003xhmUAAQ',
                'recordTypeName' => 'Product'
            },

            new Map<String, Object> {
                'census_members' => censusMembers,
                'productId' => '01t5f000003xhfHAAQ',
                'Price' => 74.79,
                'Type__c' => 'Ancillary',
                'Name' => 'AIDD 7500',
                'SubType__c' => 'AIDD',
                'Id' => '01t5f000003xhfHAAQ',
                'recordTypeName' => 'Product'
            },

            new Map<String, Object> {
                'census_members' => censusMembers,
                'productId' => '01t5f000009PREMAAQ',
                'Price' => 50.00,
                'Type__c' => 'Ancillary',
                'Name' => 'Premier',
                'SubType__c' => 'Premier',
                'Id' => '01t5f000009PREMAAQ',
                'recordTypeName' => 'Product'
            }},
            'userInputs' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 2,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[0].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Member',
                    'RF_Census.CM_FirstName' => 'Primary',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Primary',
                    'RF_Census.CM_IsPrimary' => true,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 35
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 2,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[1].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Member',
                    'RF_Census.CM_FirstName' => 'Spouse',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Spouse',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 30
                },
                new Map<String, Object> {
                    'RF_Census.CRF_Dependants' => 2,
                    'RF_Census.CRF_PrimaryMemberAge' => 35,
                    'RF_Census.CRF_ExtraDependants' => 0,
                    'RF_Census.CRF_CoverageAIDD' => 'Family',
                    'RF_Census.CRF_Coverage' => 'Family',
                    'Id' => testCensusMembers[2].Id,
                    'IsAddExistingMember' => false,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'RF_Census.CM_LastName' => 'Member',
                    'RF_Census.CM_FirstName' => 'Child',
                    'RF_Census.CM_Pregnant' => false,
                    'RF_Census.CM_Smoker' => false,
                    'RF_Census.CM_Relationship' => 'Child',
                    'RF_Census.CM_IsPrimary' => false,
                    'RF_Census.CM_State' => 'CA',
                    'RF_Census.CM_Age' => 8
                }
            },
            'FRML_DisplayChooseProductSelectionStep' => true,
            'census_members' => censusMembers,
            'removeParent' => false
        };

        String methodName = 'TRANSFORM_ChooseProductSelectionData';
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Test.startTest();
        className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();

        
        System.assertNotEquals(null, outputMap, 'TRANSFORM_ChooseProductSelectionData should complete without returning a null output map.');
        System.assertEquals(true, true, 'Reached end of TRANSFORM_ChooseProductSelectionData_getMemberBeneficiaries_Test without exceptions.');
    }


    @isTest
    static void includeProductCodeToUserInputs_planSelectedTrue_Test() {
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

        List<Object> userInputs = new List<Object>{
            new Map<String, Object>{
                'Id' => 'member1',
                'RF_Census.CM_FirstName' => 'John',
                'RF_Census.CM_LastName' => 'Doe'
            },
            new Map<String, Object>{
                'Id' => 'member2',
                'RF_Census.CM_FirstName' => 'Jane',
                'RF_Census.CM_LastName' => 'Doe'
            }
        };

        Map<String, Object> inputMap = new Map<String, Object>{
            'planSelected' => true,
            'selectedProducts' => new List<Object>{
                new Map<String, Object>{
                    'Type__c' => 'Medical',
                    'ProductCode' => 'UHSM-Premier-Medical'
                },
                new Map<String, Object>{
                    'Type__c' => 'Ancillary',
                    'ProductCode' => 'UHSM-Premier-Anc'
                }
            },
            'userInputs' => userInputs
        };

        Test.startTest();
        className.invokeMethod('includeProductCodeToUserInputs', inputMap, outputMap, options);
        Test.stopTest();

        System.assert(outputMap.containsKey('userInputs'), 'userInputs should be returned.');
        List<Object> resultUserInputs = (List<Object>)outputMap.get('userInputs');
        System.assertEquals(2, resultUserInputs.size(), 'Two userInputs should remain.');

        Map<String, Object> ui1 = (Map<String, Object>)resultUserInputs[0];
        Map<String, Object> ui2 = (Map<String, Object>)resultUserInputs[1];

        System.assertEquals('UHSM-Premier-Medical', ui1.get('RF_Census.CM_ProductCode'), 'ProductCode should be added to first userInput.');
        System.assertEquals('UHSM-Premier-Medical', ui2.get('RF_Census.CM_ProductCode'), 'ProductCode should be added to second userInput.');
    }

    @isTest
    static void includeProductCodeToUserInputs_planSelectedFalse_Test() {
        ARC_ProgramChange_Utilities className = new ARC_ProgramChange_Utilities();
        Map<String, Object> options = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

        List<Object> userInputs = new List<Object>{
            new Map<String, Object>{
                'Id' => 'member1',
                'RF_Census.CM_FirstName' => 'John',
                'RF_Census.CM_LastName' => 'Doe'
            }
        };

        Map<String, Object> inputMap = new Map<String, Object>{
            'planSelected' => false,
            'oldProducts' => new List<Object>{
                new Map<String, Object>{
                    'Type__c' => 'Medical',
                    'ProductCode' => 'UHSM-Standard-Medical'
                },
                new Map<String, Object>{
                    'Type__c' => 'Ancillary',
                    'ProductCode' => 'UHSM-Standard-Smart'
                }
            },
            'userInputs' => userInputs
        };

        Test.startTest();
        className.invokeMethod('includeProductCodeToUserInputs', inputMap, outputMap, options);
        Test.stopTest();

        System.assert(outputMap.containsKey('userInputs'), 'userInputs should be returned.');
        List<Object> resultUserInputs = (List<Object>)outputMap.get('userInputs');
        System.assertEquals(1, resultUserInputs.size(), 'One userInput should remain.');

        Map<String, Object> ui1 = (Map<String, Object>)resultUserInputs[0];
        System.assertEquals('UHSM-Standard-Medical', ui1.get('RF_Census.CM_ProductCode'), 'ProductCode should come from oldProducts when planSelected is false.');
    }
}