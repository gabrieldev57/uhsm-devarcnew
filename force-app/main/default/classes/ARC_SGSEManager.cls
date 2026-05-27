/**
 * @Description: Manager class for handling Self Enrollment Flow operations for Small Groups.
 * This class orchestrates the enrollment process by coordinating between mapper and DML operations.
 * 
 * @Author: Agustin Garay
 * @Date: 2025-10-09
 * @Version: 1.0
 */
global without sharing class ARC_SGSEManager {

    // Properties to store enrollment data
    public Map<String, Object> enrollmentInfo { get; set; }
    
    // Properties to store created record IDs
    
    // Account related variables
    public Map<String, vlocity_ins__GroupCensusMember__c> memberIdToCensusMemberMap = new Map<String, vlocity_ins__GroupCensusMember__c>();
    public Map<String, Account> memberIdToAccountMap = new Map<String, Account>();
    public Map<String, Id> memberIdToPersonContactId = new Map<String, Id>();
    /** JSON family role per member key (Primary / Spouse / Child) */
    public Map<String, String> memberIdToFamilyRole = new Map<String, String>();
    /** DOB from JSON for oldest-dependent resolution */
    public Map<String, Date> memberIdToBirthdate = new Map<String, Date>();
    public Id primaryCensusMemberId;
    public Id groupAccountId;
    public Id accountId;
    public Id censusId;
    
    // Contract related variables
    public Id contractId;
    public Date effectiveDate;
    
    // Guardian related variables
    public Account guardianToInsert;
    public Id guardianInserted;
    
    // External Policy And Policy Members related variables
    public Map<String, ARC_ExternalInsurancePolicy__c> externalPoliciesToInsert = new Map<String, ARC_ExternalInsurancePolicy__c>();
    public List<ARC_ExternalInsurancePolicyMember__c> externalPolicyMembersToInsert = new List<ARC_ExternalInsurancePolicyMember__c>();
    public Map<String,List<String>> policyKeyToMemberIds = new Map<String,List<String>>();
    
    // Insurance Policy related variables
    public InsurancePolicy policy;
    /** Prior policy under the current contract, if one exists. Populated by checkPolicy(). Null for new enrollments. */
    public InsurancePolicy priorPolicy;
    public Map<String, InsurancePolicyParticipant> memberIdToPolicyParticipant = new Map<String, InsurancePolicyParticipant>();
    public Map<String, InsurancePolicyCoverage> indexToParentCovToInsert = new Map<String, InsurancePolicyCoverage>();
    public Map<String, List<InsurancePolicyCoverage>> indexToChildCovToInsert = new Map<String, List<InsurancePolicyCoverage>>();
    public Map<String, List<String>> indexToMemberIds = new Map<String, List<String>>();

    // Hipaa related variables
    public Map<String, ARC_HipaaAuthorization__c> hipaaCensusMember = new Map<String, ARC_HipaaAuthorization__c>();
    public Map<String, ARC_HipaaAuthorization__c> hipaaLegalGuardian = new Map<String, ARC_HipaaAuthorization__c>();
    public Map<String, ARC_HipaaAuthorization__c> hipaaThirdParty = new Map<String, ARC_HipaaAuthorization__c>();

    // Contact related variables
    public Map<String, Contact> hipaaExternalContact = new Map<String, Contact>();

    // Beneficiaries related variables
    public Map<String, Object> memberIdToBeneficiaries = new Map<String, Object>();

    // DocuSign related variables
    public Map<String,Object> docuSignData = new Map<String,Object>();
    public String serializedSignerList;
    public String serializedTemplatesId;
    public String serializedTabsMap;

    /**
     * @Description: Constructor for ARC_SGSEManager
     * @param enrollmentInfo: Map containing enrollment information
     * @param memberData: Map containing member data
     * @param planData: Map containing plan data
     */
    public ARC_SGSEManager(Map<String, Object> enrollmentInfo) {
        this.enrollmentInfo = enrollmentInfo;
    }

    /**
     * @Description: Main method to execute the complete self enrollment process
     */
    public void executeEnrollment() {
        try {
            System.debug('Small Group Starting Self Enrollment Process');
            
            // Step 1: Map the data
            ARC_SGSEMapper mapper = new ARC_SGSEMapper();
            mapper.mapEnrollmentData(this);
            
            // Step 2: Execute DML operations
            ARC_SGSEDML dmlHandler = new ARC_SGSEDML();
            dmlHandler.processEnrollment(this);
            
            System.debug('Small Group Self Enrollment Process Completed Successfully');
            
        } catch (Exception e) {
            System.debug('Error in executeEnrollment: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
}