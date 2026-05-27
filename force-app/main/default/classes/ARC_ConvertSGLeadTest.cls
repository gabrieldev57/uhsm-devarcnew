@IsTest
private class ARC_ConvertSGLeadTest {

    private static Lead buildTestLead() {
        Id leadRT = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Lead' 
            AND DeveloperName = 'ARC_SmallGroup' 
            LIMIT 1
        ].Id;

        return new Lead(
            RecordTypeId = leadRT,
            Bypass_Scoring__c = true,
            FirstName = 'Test',
            LastName = 'Company 2',
            Company_Name__c = 'Legal Company Name',
            Status = 'New',
            Estimated_Effective_Date__c = Date.today().addDays(15),
            Street = '456 Main St',
            City = 'Los Angeles',
            State = 'CA',
            PostalCode = '90001',
            ARC_CompanyContactFirstName__c = 'Will',
            ARC_CompanyContactLastName__c = 'Doe',
            ARC_CompanyContactTitle__c = 'Director',
            ARC_CompanyContactPhoneNumber__c = '555-9876',
            ARC_CompanyContactEmailAddress__c = 'test@test.com',
            ARC_MeetsSmallEmployerDefinition__c = true,
            ARC_TotalEmployees__c = 30,
            ARC_AllowDependents__c = false,
            ARC_NumberOfIneligibleEmployees__c = 5,
            ARC_NewEmployeeWaitingPeriod__c = 'First of the month following two months from hire date',
            ARC_OfferSharingBenefitsDuringWaitingPer__c = true,
            ARC_EmployeesInOtherStates__c = true,
            ARC_OtherStates__c = 'NV, AZ',
            ARC_EmployeesInOtherStatesCount__c = 10,
            ARC_SubjectToCalCOBRA__c = true,
            ARC_CalCOBRAEnrolleesCount__c = 3,
            ARC_SubjectToCOBRA__c = true,
            ARC_COBRAEnrolleesCount__c = 2,
            ARC_OfferingOtherCoverage__c = true,
            ARC_OtherCoverageCarrierName__c = 'Other Insurance',
            ARC_OtherCoverageRenewalMonth__c = 'January'
        );
    }
  
    @IsTest
    static void testConvertSGLead_Success() {
        Lead testLead = buildTestLead();
        insert testLead;
    
        ARC_ConvertSGLead.Input input = new ARC_ConvertSGLead.Input();
        input.leadId = testLead.Id;
        List<ARC_ConvertSGLead.Output> outputs = ARC_ConvertSGLead.createRecordsSGLead(
            new List<ARC_ConvertSGLead.Input>{ input }
        );
    
        System.assertEquals(null, outputs[0].errorMessage,
            'Error message should be null: ' + outputs[0].errorMessage);
        Lead updatedLead = [SELECT IsConverted FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(true, updatedLead.IsConverted, 'Lead should be converted');
        System.assertNotEquals(null, outputs[0].accountId, 'Account Id should not be null');
        System.assertNotEquals(null, outputs[0].contactId, 'Contact Id should not be null');
        System.assertNotEquals(null, outputs[0].opportunityId, 'Opportunity Id should not be null');
    }
    

    @IsTest
    static void testConvertSGLead_MissingRequiredField() {
        Test.startTest();
        Lead testLead = buildTestLead();
        testLead.ARC_CompanyContactLastName__c = null;
        insert testLead;

        ARC_ConvertSGLead.Input input = new ARC_ConvertSGLead.Input();
        input.leadId = testLead.Id;
        List<ARC_ConvertSGLead.Output> outputs = ARC_ConvertSGLead.createRecordsSGLead(
            new List<ARC_ConvertSGLead.Input>{ input }
        );
        Test.stopTest();

        System.assertNotEquals(null, outputs[0].errorMessage,
            'Error message should not be null');
        System.assert(outputs[0].errorMessage.contains('Required field missing'),
            'Unexpected error: ' + outputs[0].errorMessage);

        Lead updatedLead = [SELECT IsConverted FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(false, updatedLead.IsConverted, 'Lead should not be converted');
        System.assertEquals(null, outputs[0].accountId);
        System.assertEquals(null, outputs[0].contactId);
        System.assertEquals(null, outputs[0].opportunityId);
    }

    @IsTest
    static void testConvertSGLead_AllFieldsMappedCorrectly() {
        Test.startTest();
        Lead testLead = buildTestLead();
        insert testLead;

        ARC_ConvertSGLead.Input input = new ARC_ConvertSGLead.Input();
        input.leadId = testLead.Id;
        List<ARC_ConvertSGLead.Output> outputs = ARC_ConvertSGLead.createRecordsSGLead(
            new List<ARC_ConvertSGLead.Input>{ input }
        );
        Test.stopTest();

        System.assertEquals(null, outputs[0].errorMessage,
            'Error message should be null: ' + outputs[0].errorMessage);
        System.assertNotEquals(null, outputs[0].accountId, 'accountId should not be null');
        System.assertNotEquals(null, outputs[0].contactId, 'contactId should not be null');
        System.assertNotEquals(null, outputs[0].opportunityId, 'opportunityId should not be null');

        Account acc = [
            SELECT ARC_OtherCoverageCarrierName__c,
                   ARC_TotalEmployees__c,
                   ARC_AllowDependents__c,
                   Name,
                   BillingStreet,
                   BillingCity,
                   BillingState,
                   BillingPostalCode
            FROM Account
            WHERE Id = :outputs[0].accountId
        ];
        System.assertEquals('Legal Company Name', acc.Name, 'Account Name incorrect');
        System.assertEquals('Other Insurance', acc.ARC_OtherCoverageCarrierName__c, 'OtherCoverageCarrierName incorrect');
        System.assertEquals(30, acc.ARC_TotalEmployees__c, 'TotalEmployees incorrect');
        System.assertEquals(false, acc.ARC_AllowDependents__c, 'AllowDependents incorrect');
        System.assertEquals('456 Main St', acc.BillingStreet, 'BillingStreet incorrect');
        System.assertEquals('Los Angeles', acc.BillingCity, 'BillingCity incorrect');
        System.assertEquals('CA', acc.BillingState, 'BillingState incorrect');
        System.assertEquals('90001', acc.BillingPostalCode, 'BillingPostalCode incorrect');

        Contact con = [
            SELECT FirstName, LastName, Title, Phone, Email
            FROM Contact
            WHERE Id = :outputs[0].contactId
        ];
        System.assertEquals('Will', con.FirstName, 'FirstName incorrect');
        System.assertEquals('Doe', con.LastName, 'LastName incorrect');
        System.assertEquals('Director', con.Title, 'Title incorrect');
        System.assertEquals('555-9876', con.Phone, 'Phone incorrect');
        System.assertEquals('test@test.com', con.Email, 'Email incorrect');

        Opportunity opp = [
            SELECT Name, StageName, CloseDate, ARC_RequestedEffectiveDate__c
            FROM Opportunity
            WHERE Id = :outputs[0].opportunityId
        ];
        System.assertEquals('Legal Company Name', opp.Name, 'Opp Name incorrect');
        System.assertEquals('New', opp.StageName, 'StageName incorrect');
        System.assertEquals(Date.today().addDays(15), opp.CloseDate, 'CloseDate incorrect');
        System.assertEquals(Date.today().addDays(15), opp.ARC_RequestedEffectiveDate__c, 'RequestedEffectiveDate incorrect');
    }
}