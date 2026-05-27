public with sharing class ARC_ConvertSGLead {

    public class Input {
        @InvocableVariable(required=true)
        public String leadId;
    }
    
    public class Output {
        @InvocableVariable
        public String errorMessage;
        
        @InvocableVariable
        public String accountId;
        
        @InvocableVariable
        public String opportunityId;
        
        @InvocableVariable
        public String contactId;
    }

    @InvocableMethod(label='Convert SG Lead' description='Converts a Small Group Lead and creates related records')
    public static List<Output> createRecordsSGLead(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        Output output = new Output();
        
        try {
            String leadId = inputs[0].leadId;

            Lead leadRecord = [
                SELECT Id, LastName, Company_Name__c, Estimated_Effective_Date__c, Address, Street, City, State, PostalCode,
                ARC_CompanyContactFirstName__c, ARC_CompanyContactTitle__c, ARC_CompanyContactPhoneNumber__c, ARC_CompanyContactEmailAddress__c,
                ARC_MeetsSmallEmployerDefinition__c, ARC_TotalEmployees__c, ARC_AllowDependents__c, ARC_NumberOfIneligibleEmployees__c, 
                ARC_NewEmployeeWaitingPeriod__c, ARC_OfferSharingBenefitsDuringWaitingPer__c,
                ARC_OtherStates__c, ARC_EmployeesInOtherStatesCount__c, ARC_SubjectToCalCOBRA__c, ARC_CalCOBRAEnrolleesCount__c,
                ARC_SubjectToCOBRA__c, ARC_COBRAEnrolleesCount__c, ARC_OfferingOtherCoverage__c, ARC_OtherCoverageCarrierName__c,
                ARC_OtherCoverageRenewalMonth__c, ARC_CompanyContactLastName__c, ARC_EmployeesInOtherStates__c
                FROM Lead
                WHERE Id = :leadId
                LIMIT 1
            ];
            
            //========================validation of required fields=========================//
            if (String.isBlank(leadRecord.ARC_CompanyContactLastName__c)) {
                output.errorMessage = 'Required field missing: Company Contact Last Name.';
                outputs.add(output);
                return outputs;
            }
            if (leadRecord.Estimated_Effective_Date__c == null) {
                output.errorMessage = 'Required field missing: Estimated Effective Date.';
                outputs.add(output);
                return outputs;
            }
            if (String.isBlank(leadRecord.Company_Name__c)) {
                output.errorMessage = 'Required field missing: Company Name.';
                outputs.add(output);
                return outputs;
            }
            //================================================================================//

            Map<String, RecordType> rtByKey = new Map<String, RecordType>();
            for (RecordType rt : [
                SELECT Id, SObjectType, DeveloperName
                FROM RecordType
                WHERE SObjectType IN ('Opportunity', 'Contact', 'Account')
                AND DeveloperName IN ('ARC_SmallGroup')
            ]) {
                String key = rt.SObjectType + '_' + rt.DeveloperName;
                rtByKey.put(key, rt);
            }

            RecordType oppRecordType = rtByKey.get('Opportunity_ARC_SmallGroup');
            RecordType conRecordType = rtByKey.get('Contact_ARC_SmallGroup');
            RecordType accRecordType = rtByKey.get('Account_ARC_SmallGroup');

            Account acc = new Account();
            acc.Name = leadRecord.Company_Name__c;
            acc.ARC_LegalCompanyName__c = leadRecord.Company_Name__c;
            acc.BillingStreet = leadRecord.Street;
            acc.BillingCity = leadRecord.City;
            acc.BillingState = leadRecord.State;   
            acc.BillingPostalCode = leadRecord.PostalCode;
            acc.ARC_MeetsSmallEmployerDefinition__c = leadRecord.ARC_MeetsSmallEmployerDefinition__c;
            acc.ARC_TotalEmployees__c = leadRecord.ARC_TotalEmployees__c;
            acc.ARC_AllowDependents__c = leadRecord.ARC_AllowDependents__c;
            acc.ARC_NumberOfIneligibleEmployees__c = leadRecord.ARC_NumberOfIneligibleEmployees__c;
            acc.ARC_NewEmployeeWaitingPeriod__c = leadRecord.ARC_NewEmployeeWaitingPeriod__c;
            acc.ARC_OfferSharingBenefitsDuringWaitingPer__c = leadRecord.ARC_OfferSharingBenefitsDuringWaitingPer__c;
            acc.ARC_EmployeesInOtherStates__c = leadRecord.ARC_EmployeesInOtherStates__c;
            acc.ARC_OtherStates__c = leadRecord.ARC_OtherStates__c;
            acc.ARC_EmployeesInOtherStatesCount__c = leadRecord.ARC_EmployeesInOtherStatesCount__c;
            acc.ARC_SubjectToCalCOBRA__c = leadRecord.ARC_SubjectToCalCOBRA__c;
            acc.ARC_CalCOBRAEnrolleesCount__c = leadRecord.ARC_CalCOBRAEnrolleesCount__c;
            acc.ARC_SubjectToCOBRA__c = leadRecord.ARC_SubjectToCOBRA__c;
            acc.ARC_COBRAEnrolleesCount__c = leadRecord.ARC_COBRAEnrolleesCount__c;
            acc.ARC_OfferingOtherCoverage__c = leadRecord.ARC_OfferingOtherCoverage__c;
            acc.ARC_OtherCoverageCarrierName__c = leadRecord.ARC_OtherCoverageCarrierName__c;
            acc.ARC_OtherCoverageRenewalMonth__c = leadRecord.ARC_OtherCoverageRenewalMonth__c;
            acc.RecordTypeId = accRecordType.Id;
            insert acc;

            Contact con = new Contact();
            con.FirstName = leadRecord.ARC_CompanyContactFirstName__c;
            con.LastName = leadRecord.ARC_CompanyContactLastName__c;
            con.Title = leadRecord.ARC_CompanyContactTitle__c;
            con.Phone = leadRecord.ARC_CompanyContactPhoneNumber__c;
            con.Email = leadRecord.ARC_CompanyContactEmailAddress__c;
            con.RecordTypeId = conRecordType.Id;
            insert con;

            Opportunity opp = new Opportunity();
            opp.Name = leadRecord.Company_Name__c;
            opp.StageName = 'New';
            opp.RecordTypeId = oppRecordType.Id;
            opp.AccountId = acc.Id;
            opp.CloseDate = leadRecord.Estimated_Effective_Date__c;
            opp.ARC_RequestedEffectiveDate__c = leadRecord.Estimated_Effective_Date__c;
            insert opp;

            //acc.HealthCloudGA__PrimaryContact__c = con.Id;
            con.AccountId = acc.Id;
            opp.AccountId = acc.Id;

            update new List<SObject>{ acc, con, opp };

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(leadId);
            lc.setConvertedStatus('Converted');
            lc.setAccountId(acc.Id);
            lc.setContactId(con.Id);
            lc.setDoNotCreateOpportunity(true);

            Database.convertLead(lc);
            
            
            output.accountId = acc.Id;
            output.opportunityId = opp.Id;
            output.contactId = con.Id;
            output.errorMessage = null; 
            
        } catch (Exception e) {
            output.errorMessage = 'Error converting lead: ' + e.getMessage();
            output.accountId = null;
            output.opportunityId = null;
            output.contactId = null;
        }

        List<AccountContactRelation> contactInserted = [
            SELECT Roles 
            FROM AccountContactRelation 
            WHERE ContactId = :output.contactId 
            AND AccountId = :output.accountId];
        
            if(!contactInserted.isEmpty()){
                AccountContactRelation acr = contactInserted[0];
                acr.Roles = 'Primary Business Contact';
                update acr;
            }
        
        outputs.add(output);
        return outputs;
    }
}