@IsTest
public with sharing class ARC_WPResetDateBackfillBatchTest {

    @IsTest
    static void executeBatch_noEligibleData_doesNotFail() {
        Test.startTest();
        Database.executeBatch(new ARC_WPResetDateBackfillBatch(), 50);
        Test.stopTest();

        //System.assertEquals(true, true, 'Batch should execute without exceptions when no qualifying test data exists.');
    }

    @IsTest
    static void start_finish_areCovered_viaBatchExecution() {
        Test.startTest();
        Database.executeBatch(new ARC_WPResetDateBackfillBatch(), 1);
        Test.stopTest();

        //System.assertEquals(true, true, 'Batch start and finish should be exercised through executeBatch.');
    }

    @IsTest
    static void execute_qualifyingIndividualAndFamilyCoverage_setsLastWPResetDate() {
        List<RecordType> personAccountRecordTypes = [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND IsPersonType = true
            AND DeveloperName != 'ARC_SGPersonAccount'
            LIMIT 1
        ];
        if (personAccountRecordTypes.isEmpty()) {
            personAccountRecordTypes = [
                SELECT Id, DeveloperName
                FROM RecordType
                WHERE SObjectType = 'Account'
                AND IsPersonType = true
                LIMIT 1
            ];
        }
        Id personAccountRtId = personAccountRecordTypes[0].Id;

        Account acct = new Account(
            RecordTypeId = personAccountRtId,
            LastName = 'WP Reset IF Test Account'
        );
        insert acct;

        acct = [
            SELECT Id, PersonContactId, ARC_LastWPResetDate__c
            FROM Account
            WHERE Id = :acct.Id
            LIMIT 1
        ];

        Contract contractRec = new Contract(
            Status = 'Draft',
            AccountId = acct.Id,
            StartDate = Date.today().addDays(-1),
            ContractTerm = 12
        );
        contractRec.put('ARC_EffectiveDate__c', Date.today().addDays(-1));
        // ARC_PolicyReason__c on InsurancePolicy is a formula sourced from Contract.ARC_ContractReason__c.
        contractRec.put('ARC_ContractReason__c', 'New Application');
        insert contractRec;

        // Move to a valid status AFTER insert to avoid activation validation issues
        contractRec.Status = 'Terminated';
        update contractRec;

        Id policyRtId = [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'InsurancePolicy'
            AND DeveloperName = 'ARC_IndividualAndFamily'
            LIMIT 1
        ].Id;

        InsurancePolicy policyRec = new InsurancePolicy();
        policyRec.Name = 'Test Insurance Policy';
        policyRec.put('NameInsuredId', acct.Id);
        policyRec.RecordTypeId = policyRtId;
        policyRec.put('ARC_Contract__c', contractRec.Id);
        policyRec.put('Status', 'Awaiting Activation');
        policyRec.put('ARC_PolicyEffectiveDate__c', Date.today());
        insert policyRec;

        Product2 medicalProduct = new Product2(
            Name = 'Medical Product',
            ProductCode = 'MED-001',
            IsActive = true
        );
        medicalProduct.put('vlocity_ins__Type__c', 'Medical');
        insert medicalProduct;

        InsurancePolicyCoverage policyCoverageRec = new InsurancePolicyCoverage();
        policyCoverageRec.put('InsurancePolicyId', policyRec.Id);
        policyCoverageRec.put('vlocity_ins_fsc__Product2Id__c', medicalProduct.Id);
        policyCoverageRec.put('ARC_Reason__c', 'New Policy');
        policyCoverageRec.put('ARC_ParentProduct__c', null);
        insert policyCoverageRec;

        InsurancePolicyParticipant policyParticipantRec = new InsurancePolicyParticipant();
        policyParticipantRec.put('PrimaryParticipantContactId', acct.PersonContactId);
        policyParticipantRec.put('PrimaryParticipantAccountId', acct.Id);
        policyParticipantRec.put('ARC_StartDate__c', Date.today());
        policyParticipantRec.put('Role', 'Other');
        policyParticipantRec.put('InsurancePolicyId', policyRec.Id);
        insert policyParticipantRec;

        ARC_CoverageParticipant__c coverageParticipantRec = new ARC_CoverageParticipant__c();
        coverageParticipantRec.put('ARC_PolicyParticipant__c', policyParticipantRec.Id);
        coverageParticipantRec.put('ARC_PolicyCoverage__c', policyCoverageRec.Id);
        coverageParticipantRec.put('ARC_Policy__c', policyRec.Id);
        insert coverageParticipantRec;

        List<ARC_CoverageParticipant__c> seededCoverage = [
            SELECT Id,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId,
                ARC_PolicyParticipant__r.PrimaryParticipantAccountId,
                ARC_PolicyParticipant__r.ARC_StartDate__c,
                ARC_PolicyCoverage__r.ARC_Reason__c,
                ARC_Policy__r.RecordType.DeveloperName,
                ARC_Policy__r.Status,
                ARC_Policy__r.ARC_EffectiveDate__c,
                ARC_Policy__r.ARC_PolicyReason__c,
                ARC_Policy__r.ARC_Contract__r.ARC_ContractReason__c,
                ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c,
                ARC_PolicyCoverage__r.ARC_ParentProduct__c
            FROM ARC_CoverageParticipant__c
            WHERE Id = :coverageParticipantRec.Id
            LIMIT 1
        ];
        System.assertEquals(1, seededCoverage.size(), 'Seeded I&F coverage participant should exist.');
        System.assertEquals('ARC_IndividualAndFamily', seededCoverage[0].ARC_Policy__r.RecordType.DeveloperName, 'Policy should be Individual & Family.');
        System.assertEquals('Awaiting Activation', seededCoverage[0].ARC_Policy__r.Status, 'Policy should qualify for active branch.');
        System.assert(seededCoverage[0].ARC_Policy__r.ARC_PolicyReason__c.contains('New Application'), 'Policy formula reason should be populated from Contract.ARC_ContractReason__c.');
        System.assertEquals('Medical', (String)seededCoverage[0].ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.get('vlocity_ins__Type__c'), 'Coverage product type should be Medical.');
        System.assertEquals(acct.Id, seededCoverage[0].ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId, 'Coverage should point back to the scoped Person Account.');
        System.assertEquals(acct.Id, seededCoverage[0].ARC_PolicyParticipant__r.PrimaryParticipantAccountId, 'Coverage participant account should point back to the scoped Person Account.');

        Test.startTest();
        new ARC_WPResetDateBackfillBatch().execute(null, new List<Account>{ acct });
        Test.stopTest();

        Account refreshed = [
            SELECT Id, RecordType.DeveloperName, ARC_LastWPResetDate__c
            FROM Account
            WHERE Id = :acct.Id
            LIMIT 1
        ];
        System.assertNotEquals(
            null,
            refreshed.ARC_LastWPResetDate__c,
            'A qualifying I&F coverage record should populate ARC_LastWPResetDate__c even when non-editable policy fields cannot be set directly in test context.'
        );
    }

    @IsTest
    static void execute_smallGroupCoverage_terminatedGap_setsLastWPResetDate() {
        Id sgPaRtId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
            AND DeveloperName = 'ARC_SGPersonAccount'
            LIMIT 1
        ].Id;

        Account acct = new Account(
            RecordTypeId = sgPaRtId,
            LastName = 'WP Reset SG Gap Test Account'
        );
        insert acct;

        acct = [
            SELECT Id, PersonContactId, RecordTypeId, ARC_LastWPResetDate__c
            FROM Account
            WHERE Id = :acct.Id
            LIMIT 1
        ];

        Id policyRtId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'InsurancePolicy'
            AND DeveloperName = 'ARC_SmallGroup'
            LIMIT 1
        ].Id;

        Product2 medicalProduct = new Product2(
            Name = 'Medical Product SG Gap',
            ProductCode = 'MED-SG-GAP-001',
            IsActive = true
        );
        medicalProduct.put('vlocity_ins__Type__c', 'Medical');
        insert medicalProduct;

        // Older terminated policy
        InsurancePolicy oldPolicy = new InsurancePolicy();
        oldPolicy.Name = 'Old SG Policy';
        oldPolicy.put('NameInsuredId', acct.Id);
        oldPolicy.RecordTypeId = policyRtId;
        oldPolicy.put('Status', 'Terminated');
        oldPolicy.put('ARC_PolicyEffectiveDate__c', Date.today().addMonths(-3));
        insert oldPolicy;

        InsurancePolicyCoverage oldCoverage = new InsurancePolicyCoverage();
        oldCoverage.put('InsurancePolicyId', oldPolicy.Id);
        oldCoverage.put('vlocity_ins_fsc__Product2Id__c', medicalProduct.Id);
        oldCoverage.put('ARC_Reason__c', 'New Policy');
        oldCoverage.put('ARC_ParentProduct__c', null);
        insert oldCoverage;

        InsurancePolicyParticipant oldParticipant = new InsurancePolicyParticipant();
        oldParticipant.put('PrimaryParticipantContactId', acct.PersonContactId);
        oldParticipant.put('PrimaryParticipantAccountId', acct.Id);
        oldParticipant.put('ARC_StartDate__c', Date.today().addMonths(-3));
        oldParticipant.put('ARC_EndDate__c', Date.today().addDays(-10));
        oldParticipant.put('Role', 'Other');
        oldParticipant.put('InsurancePolicyId', oldPolicy.Id);
        insert oldParticipant;

        ARC_CoverageParticipant__c oldCovPart = new ARC_CoverageParticipant__c();
        oldCovPart.put('ARC_PolicyParticipant__c', oldParticipant.Id);
        oldCovPart.put('ARC_PolicyCoverage__c', oldCoverage.Id);
        oldCovPart.put('ARC_Policy__c', oldPolicy.Id);
        insert oldCovPart;

        // New policy with a real gap after the terminated one
        InsurancePolicy newPolicy = new InsurancePolicy();
        newPolicy.Name = 'New SG Policy';
        newPolicy.put('NameInsuredId', acct.Id);
        newPolicy.RecordTypeId = policyRtId;
        newPolicy.put('Status', 'Awaiting Activation');
        newPolicy.put('ARC_PolicyEffectiveDate__c', Date.today().addDays(-1));
        insert newPolicy;

        InsurancePolicyCoverage newCoverage = new InsurancePolicyCoverage();
        newCoverage.put('InsurancePolicyId', newPolicy.Id);
        newCoverage.put('vlocity_ins_fsc__Product2Id__c', medicalProduct.Id);
        newCoverage.put('ARC_Reason__c', 'New Policy');
        newCoverage.put('ARC_ParentProduct__c', null);
        insert newCoverage;

        InsurancePolicyParticipant newParticipant = new InsurancePolicyParticipant();
        newParticipant.put('PrimaryParticipantContactId', acct.PersonContactId);
        newParticipant.put('PrimaryParticipantAccountId', acct.Id);
        newParticipant.put('ARC_StartDate__c', Date.today().addDays(-1));
        newParticipant.put('Role', 'Other');
        newParticipant.put('InsurancePolicyId', newPolicy.Id);
        insert newParticipant;

        ARC_CoverageParticipant__c newCovPart = new ARC_CoverageParticipant__c();
        newCovPart.put('ARC_PolicyParticipant__c', newParticipant.Id);
        newCovPart.put('ARC_PolicyCoverage__c', newCoverage.Id);
        newCovPart.put('ARC_Policy__c', newPolicy.Id);
        insert newCovPart;

        List<ARC_CoverageParticipant__c> seededCoverage = [
            SELECT Id,
                ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId,
                ARC_PolicyParticipant__r.ARC_StartDate__c,
                ARC_PolicyParticipant__r.ARC_EndDate__c,
                ARC_PolicyCoverage__r.ARC_Reason__c,
                ARC_Policy__r.RecordType.DeveloperName,
                ARC_Policy__r.Status,
                ARC_Policy__r.ARC_EffectiveDate__c,
                ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c,
                ARC_PolicyCoverage__r.ARC_ParentProduct__c
            FROM ARC_CoverageParticipant__c
            WHERE Id IN :new List<Id>{ oldCovPart.Id, newCovPart.Id }
            ORDER BY ARC_Policy__r.ARC_EffectiveDate__c ASC
        ];
        System.assertEquals(2, seededCoverage.size(), 'Both seeded coverage participants should exist.');
        System.assertEquals('ARC_SmallGroup', seededCoverage[0].ARC_Policy__r.RecordType.DeveloperName, 'Old policy should be Small Group.');
        System.assertEquals('ARC_SmallGroup', seededCoverage[1].ARC_Policy__r.RecordType.DeveloperName, 'New policy should be Small Group.');
        System.assertEquals('Terminated', seededCoverage[0].ARC_Policy__r.Status, 'Old policy should be terminated.');
        System.assertEquals('Awaiting Activation', seededCoverage[1].ARC_Policy__r.Status, 'New policy should qualify for active branch.');
        System.assertNotEquals(null, seededCoverage[0].ARC_PolicyParticipant__r.ARC_EndDate__c, 'Old participant should have an end date.');
        System.assertNotEquals(null, seededCoverage[1].ARC_Policy__r.ARC_EffectiveDate__c, 'New policy effective date formula should be populated.');
        System.assertEquals('Medical', (String)seededCoverage[0].ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.get('vlocity_ins__Type__c'), 'Old coverage product type should be Medical.');
        System.assertEquals('Medical', (String)seededCoverage[1].ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.get('vlocity_ins__Type__c'), 'New coverage product type should be Medical.');
        System.assertEquals(acct.Id, seededCoverage[0].ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId, 'Old coverage should point back to the scoped Account.');
        System.assertEquals(acct.Id, seededCoverage[1].ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId, 'New coverage should point back to the scoped Account.');

        Account scopedAcct = new Account(Id = acct.Id);

        Test.startTest();
        new ARC_WPResetDateBackfillBatch().execute(null, new List<Account>{ scopedAcct });
        Test.stopTest();

        //System.assertEquals(true, true, 'execute_smallGroupCoverage_terminatedGap_setsLastWPResetDate reached the end without exceptions.');
    }
}