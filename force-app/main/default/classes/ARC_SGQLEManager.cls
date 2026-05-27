global without sharing class ARC_SGQLEManager {
    public Map<String, Object> enrollmentInfo { get; set; }

    // QLE Changes
    public Map<String,Boolean> qleChanges = new Map<String,Boolean>();
    public String qleType = null;
    public String qleSubType = null;

    // List of actions to be executed
    public Set<String> ActionsSelected = new Set<String>();
    
    // Account related variables
    public Map<String, vlocity_ins__GroupCensusMember__c> memberIdToCensusMemberMap = new Map<String, vlocity_ins__GroupCensusMember__c>();
    public Map<String, Account> memberIdToAccountMap = new Map<String, Account>();
    public Map<String, Id> memberIdToPersonContactId = new Map<String, Id>();
    public Map<String, String> memberIdToFamilyRole = new Map<String, String>();
    public Map<String, Date> memberIdToBirthdate = new Map<String, Date>();
    public Id primaryCensusMemberId;
    public Id groupAccountId;
    public Id censusId; 
    public Id accountId;

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
    public Map<String, InsurancePolicyParticipant> memberIdToPolicyParticipant = new Map<String, InsurancePolicyParticipant>();
    public Map<String, InsurancePolicyCoverage> indexToParentCovToInsert = new Map<String, InsurancePolicyCoverage>();
    public Map<String, List<InsurancePolicyCoverage>> indexToChildCovToInsert = new Map<String, List<InsurancePolicyCoverage>>();
    public Map<String, List<String>> indexToMemberIds = new Map<String, List<String>>();

    // Reinstatement and Disenrollment related variables
    public InsurancePolicy reinstatementPolicy;
    public Map<Id, InsurancePolicyParticipant> reinstatementParticipants;
    public Map<Id, InsurancePolicyCoverage> reinstatementCoverages;
    public List<ARC_CoverageParticipant__c> reinstatementCovParts;
    public List<InsurancePolicy> policiesToDisenroll;

    // Hipaa related variables
    public Map<String, ARC_HipaaAuthorization__c> hipaaCensusMember = new Map<String, ARC_HipaaAuthorization__c>();
    public Map<String, ARC_HipaaAuthorization__c> hipaaLegalGuardian = new Map<String, ARC_HipaaAuthorization__c>();
    public Map<String, ARC_HipaaAuthorization__c> hipaaThirdParty = new Map<String, ARC_HipaaAuthorization__c>();

    // Contact related variables
    public Map<String, Contact> hipaaExternalContact = new Map<String, Contact>();

    // DocuSign related variables
    public Map<String,Object> docuSignData = new Map<String,Object>();
    public String serializedSignerList;
    public String serializedTemplatesId;
    public String serializedTabsMap;

    public ARC_SGQLEManager(Map<String, Object> enrollmentInfo) {
        this.enrollmentInfo = enrollmentInfo;
    }

    public void executeQLE() {
        try {
            System.debug('Small Group Starting QLE Process');
            qleType = (String)this.enrollmentInfo.get('qleType');

            ARC_SGQLEMapper mapper = new ARC_SGQLEMapper();
            mapper.mapEnrollmentData(this);

            System.debug('Small Group Mapper OK');

            ARC_SGQLEDML dmlHandler = new ARC_SGQLEDML();
            dmlHandler.processEnrollment(this);

            System.debug('Small Group QLE Process Completed Successfully');
        } catch (Exception e) {
            System.debug('Error in executeQLE: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
}