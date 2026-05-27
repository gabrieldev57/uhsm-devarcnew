/**
 * @description Controller for Business Details Section
 *              Retrieves picklist values and handles business details operations
 * @date 2024
 */
public with sharing class ARC_BusinessDetailsController {
    
    /**
     * @description Get business details from Account based on Opportunity
     * @param opportunityId The Opportunity Id
     * @return BusinessDetailsData wrapper with all business details
     */
    @AuraEnabled(cacheable=true)
    public static BusinessDetailsData getBusinessDetails(Id opportunityId) {
        try {
            if (opportunityId == null) {
                throw new AuraHandledException('Opportunity Id is required');
            }
            
            // Get Account Id and Requested Effective Date from Opportunity
            Opportunity opp = [
                SELECT Id, AccountId, ARC_RequestedEffectiveDate__c,ARC_OEStartDate__c,
                       ARC_OEEndDate__c
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            
            if (opp.AccountId == null) {
                throw new AuraHandledException('Account not found for this Opportunity');
            }
            
            // Query Account with all business detail fields
            Account account = [
                SELECT Id,
                       Name,
                       ARC_AccountManager__c,
                       ARC_AccountManager__r.Name,
                       ARC_LegalCompanyName__c,
                       BillingStreet,
                       BillingCity,
                       BillingState,
                       BillingPostalCode,
                       ARC_EmployeesInOtherStates__c,
                       ARC_OtherStates__c,
                       ARC_EmployeesInOtherStatesCount__c,
                       ARC_OfferSharingBenefitsDuringWaitingPer__c,
                       ARC_SubjectToCalCOBRA__c,
                       ARC_CalCOBRAEnrolleesCount__c,
                       ARC_SubjectToCOBRA__c,
                       ARC_COBRAEnrolleesCount__c,
                       ARC_Doing_Business_As_Name__c,
                       ARC_FederalEmployerTaxIDNumber__c,
                       Sic,
                       SicDesc,
                       ARC_NAICSCode__c,
                       ARC_TypeOfBusiness__c,
                       ARC_OtherTypeOfBusiness__c,
                       vlocity_ins__DateFounded__c,
                       ARC_MeetsSmallEmployerDefinition__c,
                       ARC_TotalEmployees__c,
                       ARC_AllowDependents__c,
                       ARC_NumberOfIneligibleEmployees__c,
                       ARC_IsNonProfit__c,
                       ARC_NewEmployeeWaitingPeriod__c,
                       ARC_Entity_Type__c,
                       ARC_OtherEntityType__c,
                       ARC_MemberOfAssociation__c,
                       ARC_AssociationName__c,
                       ARC_MedicalLeaveAllowedMonths__c,
                       ARC_PayPeriod__c,
                       ARC_OfferingOtherCoverage__c,
                       ARC_OtherCoverageCarrierName__c,
                       ARC_OtherCoverageRenewalMonth__c,
                       ARC_OtherCoverageEmployeesCovered__c
                FROM Account
                WHERE Id = :opp.AccountId
                LIMIT 1
            ];
            
            // Query Contract for Open Enrollment dates
            List<Contract> contracts = [
                SELECT Id, ARC_OEStartDate__c, ARC_OEEndDate__c, ARC_EffectiveDate__c
                FROM Contract
                WHERE AccountId = :opp.AccountId
                AND (Status = 'Activated' OR Status != 'Terminated')
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            // Build and return response
            BusinessDetailsData data = new BusinessDetailsData();
            data.requestedEffectiveDate = opp.ARC_RequestedEffectiveDate__c;
            data.companyName = account.Name;
            data.companyStreet = account.BillingStreet;
            data.companyCity = account.BillingCity;
            data.companyState = account.BillingState;
            data.companyZip = account.BillingPostalCode;
            data.employeesInOtherStates = account.ARC_EmployeesInOtherStates__c == true;
            data.otherStates = account.ARC_OtherStates__c;
            data.employeesInOtherStatesCount = account.ARC_EmployeesInOtherStatesCount__c != null ? Integer.valueOf(account.ARC_EmployeesInOtherStatesCount__c) : null;
            data.offerBenefitsDuringWaitingPeriod = account.ARC_OfferSharingBenefitsDuringWaitingPer__c == true;
            data.subjectToCalCOBRA = account.ARC_SubjectToCalCOBRA__c == true;
            data.calCOBRAEnrolleesCount = account.ARC_CalCOBRAEnrolleesCount__c != null ? Integer.valueOf(account.ARC_CalCOBRAEnrolleesCount__c) : null;
            data.subjectToCOBRA = account.ARC_SubjectToCOBRA__c == true;
            data.cobraEnrolleesCount = account.ARC_COBRAEnrolleesCount__c != null ? Integer.valueOf(account.ARC_COBRAEnrolleesCount__c) : null;
            data.openEnrollmentStartDate = opp.ARC_OEStartDate__c;
            data.openEnrollmentEndDate = opp.ARC_OEEndDate__c;
            // Contract fields
            if (!contracts.isEmpty()) {
                data.contractEffectiveDate = contracts[0].ARC_EffectiveDate__c;
            }
            data.accountManagerId = account.ARC_AccountManager__c;
            data.accountManagerName = account.ARC_AccountManager__r != null ? account.ARC_AccountManager__r.Name : null;
            
            data.federalTaxId = account.ARC_FederalEmployerTaxIDNumber__c;
            data.doingBusinessAs = account.ARC_Doing_Business_As_Name__c;
            data.sicCode = account.Sic;
            data.sicCodeDescription = account.SicDesc;
            data.naicsCode = account.ARC_NAICSCode__c;
            data.typeOfBusiness = account.ARC_TypeOfBusiness__c;
            data.otherTypeOfBusiness = account.ARC_OtherTypeOfBusiness__c;
            data.dateEstablished = account.vlocity_ins__DateFounded__c;
            data.organizationType = account.ARC_Entity_Type__c;
            data.otherOrganizationType = account.ARC_OtherEntityType__c;
            data.payPeriod = account.ARC_PayPeriod__c;
            data.medicalLeaveMonths = account.ARC_MedicalLeaveAllowedMonths__c;
            data.totalEmployees = account.ARC_TotalEmployees__c != null ? Integer.valueOf(account.ARC_TotalEmployees__c) : null;
            data.ineligibleEmployees = account.ARC_NumberOfIneligibleEmployees__c != null ? Integer.valueOf(account.ARC_NumberOfIneligibleEmployees__c) : null;
            data.newEmployeeWaitingPeriod = account.ARC_NewEmployeeWaitingPeriod__c;
            data.meetsSmallEmployerDefinition = account.ARC_MeetsSmallEmployerDefinition__c == true;
            data.allowDependentsToEnroll = account.ARC_AllowDependents__c == true;
            data.isNonProfit = account.ARC_IsNonProfit__c;
            data.isAssociationMember = account.ARC_MemberOfAssociation__c == true;
            data.associationName = account.ARC_AssociationName__c;
            data.hasOtherCoverage = account.ARC_OfferingOtherCoverage__c == true;
            data.carrierName = account.ARC_OtherCoverageCarrierName__c;
            data.renewalMonth = account.ARC_OtherCoverageRenewalMonth__c;
            data.employeesCovered = account.ARC_OtherCoverageEmployeesCovered__c != null ? String.valueOf(account.ARC_OtherCoverageEmployeesCovered__c.intValue()) : null;
            data.legalCompanyName = account.ARC_LegalCompanyName__c;
            
            return data;
            
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving business details: ' + e.getMessage());
        }
    }

    
    
    /**
     * @description Wrapper class for business details data
     */
    public class BusinessDetailsData {
        @AuraEnabled public Date requestedEffectiveDate;
        @AuraEnabled public String companyName;
        @AuraEnabled public Id accountManagerId;
        @AuraEnabled public String accountManagerName;
        @AuraEnabled public String companyStreet;
        @AuraEnabled public String companyCity;
        @AuraEnabled public String companyState;
        @AuraEnabled public String companyZip;
        @AuraEnabled public Date openEnrollmentStartDate;
        @AuraEnabled public Date openEnrollmentEndDate;
        @AuraEnabled public Date contractEffectiveDate;
        @AuraEnabled public Boolean employeesInOtherStates;
        @AuraEnabled public String otherStates;
        @AuraEnabled public Integer employeesInOtherStatesCount;
        @AuraEnabled public Boolean offerBenefitsDuringWaitingPeriod;
        @AuraEnabled public Boolean subjectToCalCOBRA;
        @AuraEnabled public Integer calCOBRAEnrolleesCount;
        @AuraEnabled public Boolean subjectToCOBRA;
        @AuraEnabled public Integer cobraEnrolleesCount;
        @AuraEnabled public String federalTaxId;
        @AuraEnabled public String doingBusinessAs;
        @AuraEnabled public String sicCode;
        @AuraEnabled public String sicCodeDescription;
        @AuraEnabled public String naicsCode;
        @AuraEnabled public String typeOfBusiness;
        @AuraEnabled public String otherTypeOfBusiness;
        @AuraEnabled public Date dateEstablished;
        @AuraEnabled public String organizationType;
        @AuraEnabled public String otherOrganizationType;
        @AuraEnabled public String payPeriod;
        @AuraEnabled public String medicalLeaveMonths;
        @AuraEnabled public Integer totalEmployees;
        @AuraEnabled public Integer ineligibleEmployees;
        @AuraEnabled public String newEmployeeWaitingPeriod;
        @AuraEnabled public Boolean meetsSmallEmployerDefinition;
        @AuraEnabled public Boolean allowDependentsToEnroll;
        @AuraEnabled public String isNonProfit;
        @AuraEnabled public Boolean isAssociationMember;
        @AuraEnabled public String associationName;
        @AuraEnabled public Boolean hasOtherCoverage;
        @AuraEnabled public String carrierName;
        @AuraEnabled public String renewalMonth;
        @AuraEnabled public String employeesCovered;
        @AuraEnabled public String legalCompanyName;
    }

    
    /**
     * @description Search SIC Codes from Custom Metadata
     * @param searchTerm The search term to filter by code or description
     * @param limitCount Maximum number of results
     * @return List of SIC Code records with code and description
     */
    @AuraEnabled(cacheable=true)
    public static List<SICCodeResult> searchSICCodes(String searchTerm, Integer limitCount) {
        List<SICCodeResult> results = new List<SICCodeResult>();
        String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        
        // Query all SIC Codes and filter in memory since custom metadata doesn't support OR in SOQL
        List<SIC_Code__mdt> allSicCodes = [
            SELECT ARC_SicCode__c, ARC_SicCodeDescription__c
            FROM SIC_Code__mdt
            ORDER BY ARC_SicCode__c
        ];
        
        // Filter in Apex to support searching both code and description
        for (SIC_Code__mdt sic : allSicCodes) {
            String code = sic.ARC_SicCode__c != null ? sic.ARC_SicCode__c.toLowerCase() : '';
            String description = sic.ARC_SicCodeDescription__c != null ? sic.ARC_SicCodeDescription__c.toLowerCase() : '';
            String search = searchTerm.toLowerCase();
            
            if (code.contains(search) || description.contains(search)) {
                results.add(new SICCodeResult(
                    sic.ARC_SicCode__c,
                    sic.ARC_SicCodeDescription__c
                ));
                
                if (results.size() >= limitCount) {
                    break;
                }
            }
        }
        
        return results;
    }

    /**
     * @description Search active Users
     * @param searchTerm The search term to filter by name or email
     * @param limitCount Maximum number of results
     * @return List of User records
     */
    @AuraEnabled(cacheable=true)
    public static List<UserResult> searchUsers(String searchTerm, Integer limitCount) {
        List<UserResult> results = new List<UserResult>();
        String searchPattern = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        
        // Query active Users
        List<User> users = [
            SELECT Id, Name, Email
            FROM User
            WHERE IsActive = true
            AND (Name LIKE :searchPattern OR Email LIKE :searchPattern)
            ORDER BY Name
            LIMIT :limitCount
        ];
        
        for (User u : users) {
            results.add(new UserResult(u.Id, u.Name, u.Email));
        }
        
        return results;
    }
    
    /**
     * @description Wrapper class for SIC Code search results
     */
    public class SICCodeResult {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Title;
        @AuraEnabled public String subtitle;
        @AuraEnabled public Map<String, String> record;
        
        public SICCodeResult(String code, String description) {
            this.Id = code;
            this.Name = code;
            this.Title = description;
            this.subtitle = description;
            this.record = new Map<String, String>{
                'code' => code,
                'description' => description
            };
        }
    }

    /**
     * @description Wrapper class for User search results
     */
    public class UserResult {
        @AuraEnabled public String Id;
        @AuraEnabled public String Name;
        @AuraEnabled public String Email;
        
        public UserResult(String id, String name, String email) {
            this.Id = id;
            this.Name = name;
            this.Email = email;
        }
    }
}