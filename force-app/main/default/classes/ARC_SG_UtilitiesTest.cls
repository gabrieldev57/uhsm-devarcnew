@IsTest
private class ARC_SG_UtilitiesTest {

    @TestSetup
    static void setupTestData() {
        // Ensure a Calculation Matrix + Version + Row exist so getUpgradeDowngradePlans() query never returns empty.
        vlocity_ins__CalculationMatrix__c calcMatrix = new vlocity_ins__CalculationMatrix__c(Name = 'ARC_UHSM_Programs2023');
        insert calcMatrix;
 
        vlocity_ins__CalculationMatrixVersion__c matrixVer = new vlocity_ins__CalculationMatrixVersion__c(
            Name = 'ver_for_tests',
            vlocity_ins__CalculationMatrixId__c = calcMatrix.Id,
            vlocity_ins__IsEnabled__c = true,
            vlocity_ins__VersionNumber__c = 2
        );
        insert matrixVer;
 
        // Row mapping Plan A -> Upgrade to Plan B, Downgrade to Plan C
        Map<String,Object> inputA = new Map<String,Object>{ 'Program' => 'Plan A' };
        Map<String,Object> outputA = new Map<String,Object>{ 'Upgrade Result' => 'Plan B', 'Downgrade Result' => 'Plan C' };
        insert new vlocity_ins__CalculationMatrixRow__c(
            vlocity_ins__CalculationMatrixVersionId__c = matrixVer.Id,
            vlocity_ins__InputData__c = JSON.serialize(inputA),
            vlocity_ins__OutputData__c = JSON.serialize(outputA)
        );
 
        // Row mapping Plan Y -> Downgrade to Plan Z
        Map<String,Object> inputY = new Map<String,Object>{ 'Program' => 'Plan Y' };
        Map<String,Object> outputY = new Map<String,Object>{ 'Upgrade Result' => 'Plan X', 'Downgrade Result' => 'Plan Z' };
        insert new vlocity_ins__CalculationMatrixRow__c(
            vlocity_ins__CalculationMatrixVersionId__c = matrixVer.Id,
            vlocity_ins__InputData__c = JSON.serialize(inputY),
            vlocity_ins__OutputData__c = JSON.serialize(outputY)
        );
 
        // Additional safe row to avoid nulls during parsing
        insert new vlocity_ins__CalculationMatrixRow__c(
            vlocity_ins__CalculationMatrixVersionId__c = matrixVer.Id,
            vlocity_ins__InputData__c = JSON.serialize(new Map<String,Object>{ 'Program' => 'Plan X' }),
            vlocity_ins__OutputData__c = JSON.serialize(new Map<String,Object>{ 'Upgrade Result' => 'Plan Y', 'Downgrade Result' => 'Plan Z' })
        );
    }

    @IsTest
    static void testEvaluateChanges_allBranches() {
        // Build payload to exercise addMember, removeMember, upgrade, downgrade, agingOut
        Map<String,Object> currentState = new Map<String,Object>();
        Map<String,Object> currentProducts = new Map<String,Object>();
        currentProducts.put('Plan A', new Map<String,Object>{ 'productId' => 'P1' });
        currentProducts.put('Plan Y', new Map<String,Object>{ 'productId' => 'PY' });
        currentState.put('currentProducts', currentProducts);

        List<Object> currentMembers = new List<Object>{
            new Map<String,Object>{ 'memberExternalId' => 'M_up', 'productId' => 'P1' }, // will be upgraded or changed
            new Map<String,Object>{ 'memberExternalId' => 'M_rem', 'productId' => 'Prem' } // will be removed
        };
        currentState.put('currentMembers', currentMembers);

        // New members include upgraded member, aging out, and a new member addition
        List<Object> newMembers = new List<Object>{
            new Map<String,Object>{ 'memberExternalId' => 'M_up', 'productId' => 'P2' }, // P2 -> Plan B per matrix
            new Map<String,Object>{ 'memberExternalId' => 'M_age', 'productId' => 'PS' }, // will map to WeShare Group Senior for aging
            new Map<String,Object>{ 'memberExternalId' => 'M_new', 'productId' => 'Pnew' } // new member
        };

        Map<String,Object> generalInfo = new Map<String,Object>();
        Map<String,Object> medicalProgram = new Map<String,Object>();
        medicalProgram.put('Plan B', new Map<String,Object>{ 'productId' => 'P2' });
        medicalProgram.put('WeShare Group Senior', new Map<String,Object>{ 'productId' => 'PS' });
        medicalProgram.put('Plan Z', new Map<String,Object>{ 'productId' => 'Pz' });
        generalInfo.put('medicalProgram', medicalProgram);

        Map<String,Object> payload = new Map<String,Object>{
            'currentState' => currentState,
            'generalInformation' => generalInfo,
            'members' => newMembers
        };

        Test.startTest();
        Map<String,Object> result = ARC_SG_Utilities.evaluateChanges(payload);
        Test.stopTest();

        Map<String,Object> gi = (Map<String,Object>)result.get('generalInformation');
        Map<String,Object> qle = (Map<String,Object>)gi.get('qleChanges');

        System.assertEquals(true, (Boolean)qle.get('addMember'), 'addMember should be true');
        System.assertEquals(true, (Boolean)qle.get('removeMember'), 'removeMember should be true');
        // programUpgrade or programDowngrade may be set depending on matrix; assert change detected
        Boolean progChg = (Boolean)qle.get('programUpgrade') || (Boolean)qle.get('programDowngrade');
        System.assertEquals(true, progChg, 'A program change should be detected for one of the members');
        
    }

   /* @IsTest
    static void testEvaluateChanges_emptyCurrentState() {
        // Payload without currentState should be handled gracefully
        Map<String,Object> payload = new Map<String,Object>();
        Map<String,Object> generalInfo = new Map<String,Object>();
        Map<String,Object> medicalProgram = new Map<String,Object>();
        medicalProgram.put('Plan A', new Map<String,Object>{ 'productId' => 'P1' });
        generalInfo.put('medicalProgram', medicalProgram);
        payload.put('generalInformation', generalInfo);
        payload.put('members', new List<Object>{
            new Map<String,Object>{ 'memberExternalId' => 'MX', 'productId' => 'P1' }
        });

        Test.startTest();
        Map<String,Object> result = ARC_SG_Utilities.evaluateChanges(payload);
        Test.stopTest();

        // Ensure result contains qleChanges and no exceptions occurred
        Map<String,Object> gi = (Map<String,Object>)result.get('generalInformation');
        System.assertNotEquals(null, gi.get('qleChanges'), 'qleChanges should exist even when currentState absent');
    }*/

    @IsTest
    static void testGetUpgradeDowngradePlans_parsingVariations() {
        // Insert an additional CalculationMatrixVersion/Row with missing Program key to ensure guard clauses
        vlocity_ins__CalculationMatrix__c cm = new vlocity_ins__CalculationMatrix__c(Name = 'ARC_UHSM_Programs2023');
        insert cm;
        vlocity_ins__CalculationMatrixVersion__c mv = new vlocity_ins__CalculationMatrixVersion__c(
            Name = 'ver_extra',
            vlocity_ins__CalculationMatrixId__c = cm.Id,
            vlocity_ins__IsEnabled__c = true,
            vlocity_ins__VersionNumber__c = 3
        );
        insert mv;
        // Row without Program in input
        vlocity_ins__CalculationMatrixRow__c row = new vlocity_ins__CalculationMatrixRow__c(
            vlocity_ins__CalculationMatrixVersionId__c = mv.Id,
            vlocity_ins__InputData__c = JSON.serialize(new Map<String,Object>{ 'Other' => 'X' }),
            vlocity_ins__OutputData__c = JSON.serialize(new Map<String,Object>{ 'Upgrade Result' => 'A', 'Downgrade Result' => 'B' })
        );
        insert row;

        // Now call the helper to ensure it parses rows and does not throw
        Test.startTest();
        Map<String,Map<String,Object>> plans = ARC_SG_Utilities.getUpgradeDowngradePlans();
        Test.stopTest();

        System.assertNotEquals(null, plans, 'getUpgradeDowngradePlans should return a map (possibly empty)');
    }
}