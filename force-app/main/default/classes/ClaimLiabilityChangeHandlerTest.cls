@isTest
private class ClaimLiabilityChangeHandlerTest {
    
    @testSetup
    static void makeData() {
        // Create XML Counter custom settings
        ARC_XMLCounter__c xmlCounter = new ARC_XMLCounter__c(
            Name = 'ZelisXML',
            ARC_Date__c = Date.today(),
            ARC_Counter__c = '00.00'
        );
        insert xmlCounter;
        
        ARC_XMLCounter__c checkCounter = new ARC_XMLCounter__c(
            Name = 'ZelisCheck',
            ARC_CheckNumber__c = 1000
        );
        insert checkCounter;

        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accList = new List<Account>();
        Integer counter = 0;
        
        for(Integer i=0; i<2; i++){
            Account acc = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount'+i, LastName ='Test');
            acc.BillingStreet = '123 Avenue';
            acc.BillingState = 'NY';
            acc.BillingCity = 'New York';
            acc.BillingPostalCode='12345';
            acc.PersonEmail='test@email.com'+counter;
            acc.ARC_IsPrimaryMember__c = true;
            acc.ARC_E123MemberIdFromPolicy__c = 'W123456789'+counter;
            acc.PersonBirthdate = Date.newInstance(2000, 1, 1);
            accList.add(acc);
            counter++;
        }
        insert accList;
        
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(2);
        counter = 0;
        List<Account> accountContacts = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount%'];
        for(vlocity_ins__GroupCensusMember__c censusMember: censusMemberList){
            censusMember.vlocity_ins__ContactId__c = accountContacts[counter].PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = '123456789';
            counter++;
        }
        update censusMemberList;
        
        accList[0].Census_Member__c = censusMemberList[0].Id;
        accList[1].Census_Member__c = censusMemberList[1].Id;
        accList[0].ARC_CensusMember__pc = censusMemberList[0].Id;
        accList[1].ARC_CensusMember__pc = censusMemberList[1].Id;
        accList[0].ARC_Census__c = censusMemberList[0].vlocity_ins__CensusId__c;
        accList[1].ARC_Census__c = censusMemberList[1].vlocity_ins__CensusId__c;
        update accList;
        
        List<Contract> cont = ARC_TestUtility.createContractsAA(1);
        cont[0].Name = 'WeShare test';
        cont[0].vlocity_ins__EnrollmentCensusId__c = censusMemberList[0].vlocity_ins__CensusId__c;
        cont[0].AccountId = accList[0].Id;
        cont[0].ARC_ContractReason__c = 'New Application';
        insert cont;
        
        Id codeRT = Schema.SObjectType.vlocity_ins__VlocityCode__c.getRecordTypeInfosByDeveloperName().get('RARC').getRecordTypeId();
        vlocity_ins__VlocityCode__c code = new vlocity_ins__VlocityCode__c(Name = 'V0001', ARC_Status__c = 'Denied', RecordTypeId = codeRT);
        insert code;

        InsurancePolicy pol = ARC_TestUtility.createTestPolicies(1)[0];
        pol.ARC_Contract__c = cont[0].Id;
        upsert pol;

        List<InsurancePolicyParticipant> ippList = ARC_TestUtility.createTestPolicyParticipant(2);
        ippList[0].InsurancePolicyId = pol.Id;
        ippList[0].PrimaryParticipantContactId = censusMemberList[0].vlocity_ins__ContactId__c;
        ippList[1].InsurancePolicyId = pol.Id;
        ippList[1].PrimaryParticipantContactId = censusMemberList[1].vlocity_ins__ContactId__c;
        insert ippList;
                    
    }
    
    private static Claim createLiabilityClaim(String name, Decimal amount, Id policyId, Id participantId, Id codeId) {
        Claim clm = new Claim();
        clm.Name = name;
        clm.Status = 'AA Approved';
        clm.ARC_CheckRunApproval__c = 'Approved';
        clm.HaxSMB__c = false;
        clm.ARC_CheckRun__c = null;
        clm.ARC_AuditorValidation__c = 'Approved';
        clm.ARC_TotalNetPaidAmount__c = amount;
       // clm.ARC_CheckNumber__c = '1234';
        clm.ARC_ReasonCode__c = codeId;
        clm.PolicyNumberId = policyId;
        clm.ARC_ParticipantPolicyParticipant__c = participantId;
        clm.ARC_DOSFrom__c = System.Today();
        clm.ARC_DOSTo__c = System.Today();
        
        return clm;
    }
    
    private static Claim createNonLiabilityClaim(String name, Decimal amount, Id policyId, Id participantId, Id codeId) {
        Claim clm = new Claim();
        clm.Name = name;
        clm.Status = 'AA Approved';
        clm.ARC_CheckRunApproval__c = 'Pending'; // Doesn't meet criteria
        clm.HaxSMB__c = false;
        clm.ARC_CheckRun__c = null;
        clm.ARC_AuditorValidation__c = 'Approved';
        clm.ARC_TotalNetPaidAmount__c = amount;
        clm.ARC_CheckNumber__c = '1234';
        clm.ARC_ReasonCode__c = codeId;
        clm.PolicyNumberId = policyId;
        clm.ARC_ParticipantPolicyParticipant__c = participantId;
        clm.ARC_DOSFrom__c = System.Today();
        clm.ARC_DOSTo__c = System.Today();
        
        return clm;
    }
    
    @isTest
    static void testClaimAddedAsLiability() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Test.startTest();
        Claim claim = createLiabilityClaim('TEST-001', 1000.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c, Net_Paid_Amount__c, Shareable_Medical_Bill__c 
                                                   FROM SMB_Liability_Change__c];
        System.assertEquals(1, changes.size(), 'Should create one change record');
        System.assertEquals('Added', changes[0].Change_Type__c, 'Should be Added type');
        System.assertEquals(1000.00, changes[0].Net_Paid_Amount__c, 'Should record the amount');
        System.assertEquals(claim.Id, changes[0].Shareable_Medical_Bill__c, 'Should link to claim');
    }
    
    @isTest
    static void testClaimAddedNotLiability() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Test.startTest();
        Claim claim = createNonLiabilityClaim('TEST-002', 1000.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id FROM SMB_Liability_Change__c];
        System.assertEquals(0, changes.size(), 'Should not create change record for non-liable claim');
    }
    
    @isTest
    static void testClaimAddedToCheckRun() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createLiabilityClaim('TEST-003', 1500.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        ARC_CheckRun__c checkRun = new ARC_CheckRun__c();
        checkRun.ARC_Status__c = 'Open';
        checkRun.Name = 'Test checkRun CHK-001';    
        insert checkRun;
        
        Test.startTest();
        claim.ARC_CheckRun__c = checkRun.Id;
        update claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c, Net_Paid_Amount__c 
                                                   FROM SMB_Liability_Change__c 
                                                   ORDER BY CreatedDate];
        System.assertEquals(2, changes.size(), 'Should have Added and Added to Check Run records');
        System.assertEquals('Added', changes[0].Change_Type__c, 'First should be Added');
        System.assertEquals('Added to Check Run', changes[1].Change_Type__c, 'Second should be Added to Check Run');
        System.assertEquals(-1500.00, changes[1].Net_Paid_Amount__c, 'Should be negative amount');
    }
    
    @isTest
    static void testClaimDisapproved() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createLiabilityClaim('TEST-004', 2000.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        Test.startTest();
        claim.ARC_CheckRunApproval__c = 'Pending';
        claim.ARC_CheckRun__c = null;
        update claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c, Net_Paid_Amount__c, Notes__c 
                                                   FROM SMB_Liability_Change__c 
                                                   ORDER BY CreatedDate];
        System.assertEquals(2, changes.size(), 'Should have Added and Disapproved records');
        System.assertEquals('Disapproved', changes[1].Change_Type__c, 'Second should be Disapproved');
        System.assertEquals(-2000.00, changes[1].Net_Paid_Amount__c, 'Should be negative amount');
        System.assert(changes[1].Notes__c.contains('Check Run Approval'), 'Should explain reason');
    }
    
    @isTest
    static void testClaimAmountAdjusted() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createLiabilityClaim('TEST-005', 1000.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        Test.startTest();
        claim.ARC_TotalNetPaidAmount__c = 1250.00;
        update claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c, Net_Paid_Amount__c 
                                                   FROM SMB_Liability_Change__c 
                                                   ORDER BY CreatedDate];
        System.assertEquals(2, changes.size(), 'Should have Added and Adjusted records');
        System.assertEquals('Adjusted', changes[1].Change_Type__c, 'Second should be Adjusted');
        System.assertEquals(250.00, changes[1].Net_Paid_Amount__c, 'Should be the difference');
    }
    
    @isTest
    static void testPreventLiabilityDeletion() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createLiabilityClaim('TEST-006', 3000.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        Test.startTest();
        Boolean exceptionThrown = false;
        String exceptionMessage = '';
        try {
            delete claim;
        } catch (DmlException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
            System.debug('Full exception message: ' + exceptionMessage);
            // Check for key part of the custom error message
            System.assert(exceptionMessage.contains('Cannot delete a claim') || 
                         exceptionMessage.contains('currently counted as liability'), 
                         'Error message should mention deletion prevention. Actual message: ' + exceptionMessage);
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should prevent deletion of liability claim');
        
        // Verify claim still exists
        List<Claim> existingClaims = [SELECT Id FROM Claim WHERE Id = :claim.Id];
        System.assertEquals(1, existingClaims.size(), 'Claim should still exist');
    }
    
    @isTest
    static void testAllowDeletionOfNonLiabilityClaim() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createLiabilityClaim('TEST-007', 3000.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        ARC_CheckRun__c checkRun = new ARC_CheckRun__c();
        checkRun.ARC_Status__c = 'Open';
        checkRun.Name = 'Test checkRun CHK-001';    
        insert checkRun;
        
        // Remove from liability by adding to check run
        claim.ARC_CheckRun__c = checkRun.Id;
        update claim;
        
        Test.startTest();
        delete claim;
        Test.stopTest();
        
        // Verify claim was deleted
        List<Claim> existingClaims = [SELECT Id FROM Claim WHERE Id = :claim.Id];
        System.assertEquals(0, existingClaims.size(), 'Non-liability claim should be deleted');
    }
    
    @isTest
    static void testClaimNowMeetsCriteria() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createNonLiabilityClaim('TEST-008', 1800.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        Test.startTest();
        claim.ARC_CheckRunApproval__c = 'Approved';
        update claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c, Net_Paid_Amount__c 
                                                   FROM SMB_Liability_Change__c];
        System.assertEquals(1, changes.size(), 'Should create one change record');
        System.assertEquals('Added', changes[0].Change_Type__c, 'Should be Added type');
        System.assertEquals(1800.00, changes[0].Net_Paid_Amount__c, 'Should record the amount');
    }
    
    @isTest
    static void testMultipleFieldChanges() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createLiabilityClaim('TEST-009', 2500.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        Test.startTest();
        // Change status to invalid status
        claim.Status = 'Closed';
        update claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c, Net_Paid_Amount__c, Notes__c 
                                                   FROM SMB_Liability_Change__c 
                                                   ORDER BY CreatedDate];
        System.assertEquals(2, changes.size(), 'Should have Added and Disapproved records');
        System.assertEquals('Disapproved', changes[1].Change_Type__c, 'Should be Disapproved');
        System.assert(changes[1].Notes__c.contains('Status changed'), 'Should explain status change');
    }
    
    @isTest
    static void testHaxSMBChange() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createLiabilityClaim('TEST-010', 1200.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        Test.startTest();
        claim.HaxSMB__c = true;
        update claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c, Net_Paid_Amount__c, Notes__c 
                                                   FROM SMB_Liability_Change__c 
                                                   ORDER BY CreatedDate];
        System.assertEquals(2, changes.size(), 'Should have Added and Disapproved records');
        System.assertEquals('Disapproved', changes[1].Change_Type__c, 'Should be Disapproved');
        System.assert(changes[1].Notes__c.contains('HaxSMB'), 'Should explain HaxSMB change');
    }
    
    @isTest
    static void testAuditorValidationChange() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createLiabilityClaim('TEST-011', 1500.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        Test.startTest();
        claim.ARC_AuditorValidation__c = 'Pending';
        claim.ARC_CheckRunApproval__c = 'Pending';
        claim.ARC_CheckRun__c = null;
        update claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c, Net_Paid_Amount__c, Notes__c 
                                                   FROM SMB_Liability_Change__c 
                                                   ORDER BY CreatedDate];
        System.assertEquals(2, changes.size(), 'Should have Added and Disapproved records');
        System.assertEquals('Disapproved', changes[1].Change_Type__c, 'Should be Disapproved');
        System.assert(changes[1].Notes__c.contains('Auditor Validation'), 'Should explain validation change');
    }
    
    @isTest
    static void testBulkOperations() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        List<Claim> claims = new List<Claim>();
        for (Integer i = 0; i < 50; i++) {
            claims.add(createLiabilityClaim('BULK-' + i, 100.00 * i, pol.Id, ipp.Id, code.Id));
        }
        
        Test.startTest();
        insert claims;
        
        // Create check runs for updates
        List<ARC_CheckRun__c> checkRuns = new List<ARC_CheckRun__c>();
        for (Integer i = 0; i < 25; i++) {
            ARC_CheckRun__c checkRun = new ARC_CheckRun__c();
            checkRun.ARC_Status__c = 'Open';
            checkRun.Name = 'Test checkRun CHK-BULK-' + i;
            checkRuns.add(checkRun);
        }
        insert checkRuns;
        
        // Update half of them to add to check run
        for (Integer i = 0; i < 25; i++) {
            claims[i].ARC_CheckRun__c = checkRuns[i].Id;
        }
        update claims;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c FROM SMB_Liability_Change__c];
        System.assertEquals(75, changes.size(), 'Should create 50 Added + 25 Added to Check Run records');
    }
    
    @isTest
    static void testAmountDecreaseWhileLiable() {
        InsurancePolicy pol = [SELECT Id FROM InsurancePolicy LIMIT 1];
        InsurancePolicyParticipant ipp = [SELECT Id FROM InsurancePolicyParticipant LIMIT 1];
        vlocity_ins__VlocityCode__c code = [SELECT Id FROM vlocity_ins__VlocityCode__c LIMIT 1];
        
        Claim claim = createLiabilityClaim('TEST-012', 5000.00, pol.Id, ipp.Id, code.Id);
        insert claim;
        
        Test.startTest();
        claim.ARC_TotalNetPaidAmount__c = 3000.00;
        update claim;
        Test.stopTest();
        
        List<SMB_Liability_Change__c> changes = [SELECT Id, Change_Type__c, Net_Paid_Amount__c, Notes__c 
                                                   FROM SMB_Liability_Change__c 
                                                   ORDER BY CreatedDate];
        System.assertEquals(2, changes.size(), 'Should have Added and Adjusted records');
        System.assertEquals('Adjusted', changes[1].Change_Type__c, 'Should be Adjusted');
        System.assertEquals(-2000.00, changes[1].Net_Paid_Amount__c, 'Should be negative for decrease');
        System.assert(changes[1].Notes__c.contains('5000'), 'Should show original amount');
        System.assert(changes[1].Notes__c.contains('3000'), 'Should show new amount');
    }
}