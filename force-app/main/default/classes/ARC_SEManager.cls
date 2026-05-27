/**
 * @Description: Manager class for handling Self Enrollment Flow operations.
 * This class orchestrates the enrollment process by coordinating between mapper and DML operations.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-01-27
 * @Version: 1.0
 */
global without sharing class ARC_SEManager {
    
    private static final Integer MAX_FIELD_SIZE = 131072; // Salesforce Long Text Area limit
    
    // Properties to store enrollment data
    public Map<String, Object> enrollmentInfo { get; set; }
    // public Map<String, Object> memberData { get; set; }
    // public Map<String, Object> planData { get; set; }
    
    // Properties to store created record IDs
    // public Id censusId { get; set; }
    // public Id personAccountId { get; set; }
    // public Id groupAccountId { get; set; }
    public Id contractId { get; set; }
    // public Id contractLineItemId { get; set; }
    // public Id groupCensusMemberPlanId { get; set; }
    // public Id externalInsurancePolicyMemberId { get; set; } 
    // public Id contractParticipantId { get; set; }
    // public Id chargentOrderId { get; set; }
    // public Id uwCaseId { get; set; }
    // public Id uwCaseMemberId { get; set; }
    // public Id hippaId { get; set; }
    // public Id medicalQuestionId { get; set; }
    
    // Account related variables
    public Map<String, vlocity_ins__GroupCensusMember__c> memberIdToCensusMemberMap = new Map<String, vlocity_ins__GroupCensusMember__c>();
    public vlocity_ins__GroupCensus__c census;
    public Map<String, Account> memberIdToAccountMap = new Map<String, Account>();
    public Account groupAccount;
    public Map<String, Id> memberIdToPersonContactId = new Map<String, Id>();

    // Contract related variables
    public Contract contract;
    public Map<String, vlocity_ins__ContractLineItem__c> indexToParentCLIToInsert = new Map<String, vlocity_ins__ContractLineItem__c>();
    public Map<String, List<vlocity_ins__ContractLineItem__c>> indexToChildCLIToInsert = new Map<String, List<vlocity_ins__ContractLineItem__c>>();
    public Map<String, List<String>> indexToMemberIds = new Map<String, List<String>>();
    public Map<String, ARC_ContractParticipant__c> memberIdtoContractParticipantMap = new Map<String, ARC_ContractParticipant__c>();

    // Guardian related variables
    public Account guardianToInsert;
    public Id guardianInserted;
    //Selling Agent
    public Id sellingAgentId;

    // Hipaa related variables
    public Map<String, ARC_HipaaAuthorization__c> hipaaCensusMember = new Map<String, ARC_HipaaAuthorization__c>();
    public Map<String, ARC_HipaaAuthorization__c> hipaaLegalGuardian = new Map<String, ARC_HipaaAuthorization__c>();
    public Map<String, ARC_HipaaAuthorization__c> hipaaThirdParty = new Map<String, ARC_HipaaAuthorization__c>();

    // Contact related variables
    public Map<String, Contact> hippaExternalContact = new Map<String, Contact>();

    // Chargent order related variables
    public ChargentOrders__ChargentOrder__c appFeeOrderToInsert = new ChargentOrders__ChargentOrder__c();
    public Id appFeeOrderInserted;

    // External Policy And Policy Members related variables
    public Map<String, ARC_ExternalInsurancePolicy__c> externalPoliciesToInsert = new Map<String, ARC_ExternalInsurancePolicy__c>();
    public List<ARC_ExternalInsurancePolicyMember__c> externalPolicyMembersToInsert = new List<ARC_ExternalInsurancePolicyMember__c>();
    public Map<String,List<String>> policyKeyToMemberIds = new Map<String,List<String>>();

    // Case related variables
    public Case uwCase;
    public Map<String, ARC_UnderwritingCaseMember__c> uwCaseMembers = new Map<String, ARC_UnderwritingCaseMember__c>();
    //Case Onboarding
    public Case onboardingCase;

    // Promotion Discount related variables
    public List<ARC_PromotionDiscount__c> promotionDiscountToInsert = new List<ARC_PromotionDiscount__c>();

    // Medical Questions related variables
    public Map<String, List<ARC_MedicalConditions__c>> medicalConditionsByMemberToInsert = new Map<String, List<ARC_MedicalConditions__c>>();
    public Map<String, List<vlocity_ins__ConsumerDrug__c>> consumerDrugsByMemberToInsert = new Map<String, List<vlocity_ins__ConsumerDrug__c>>();

    // DocuSign related variables
    public Map<String,Object> docuSignData = new Map<String,Object>();
    public String serializedSignerList;
    public String serializedTemplatesId;
    public String serializedTabsMap;

    // Beneficiaries related variables
    public Map<String, Object> memberIdToBeneficiaries = new Map<String, Object>();
    public Map<String, Object> contactIdToBeneficiaries = new Map<String, Object>();

    // Ancillary discount related variables
    public Map<String, Map<String, String>> memberIdToCriticalCareBundle = new Map<String, Map<String, String>>();
    public Map<String, Map<String, Id>> memberIdToBundleGcmpIds = new Map<String, Map<String, Id>>();

    /**
     * @Description: Constructor for ARC_SEManager
     * @param enrollmentInfo: Map containing enrollment information
     * @param memberData: Map containing member data
     * @param planData: Map containing plan data
     */
    public ARC_SEManager(Map<String, Object> enrollmentInfo) {
        this.enrollmentInfo = enrollmentInfo;
    } 
    
    /**
     * @Description: Main method to execute the complete self enrollment process
     */
    public void executeEnrollment() {
        System.debug('Starting Self Enrollment Process');
        
        try {
            // Step 1: Map the data
            ARC_SEMapper mapper = new ARC_SEMapper();
            mapper.mapEnrollmentData(this);
            
            // Step 2: Execute DML operations (only if mapping succeeds)
            ARC_SEDML dmlHandler = new ARC_SEDML();
            dmlHandler.processEnrollment(this);
            
            // Step 3: Store the created record IDs
            /*
            this.censusId = dmlHandler.censusId;
            this.personAccountId = dmlHandler.personAccountId;
            this.groupAccountId = dmlHandler.groupAccountId;
            this.contractId = dmlHandler.contractId;
            this.contractLineItemId = dmlHandler.contractLineItemId;
            this.groupCensusMemberPlanId = dmlHandler.groupCensusMemberPlanId;
            this.externalInsurancePolicyMemberId = dmlHandler.externalInsurancePolicyMemberId;
            this.contractParticipantId = dmlHandler.contractParticipantId;
            this.chargentOrderId = dmlHandler.chargentOrderId;
            this.uwCaseId = dmlHandler.uwCaseId;
            this.uwCaseMemberId = dmlHandler.uwCaseMemberId;
            this.hippaId = dmlHandler.hippaId;
            this.medicalQuestionId = dmlHandler.medicalQuestionId;
            */
            
            System.debug('Self Enrollment Process Completed Successfully');
            
        } catch (Exception e) {
            // Determine the failure stage for logging
            String logName = 'Enrollment Process Failed';
            String errorContext = e.getMessage();
            
            // Try to determine if it's a mapping or DML failure based on the error context
            if (errorContext != null && errorContext.containsIgnoreCase('mapping')) {
                logName = 'Mapping Failed';
            } else if (errorContext != null && errorContext.containsIgnoreCase('DML')) {
                logName = 'DML Failed';
            }
            
            try {
                Custom_Logs__c log = createSplitLog(logName, this.enrollmentInfo, null);
                insert log;
                System.debug(e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            } catch (Exception ex) {
                System.debug('Exception while inserting log: ' + ex.getMessage() + ex.getStackTraceString());
                throw ex;
            }
        }
    }
    
    /**
     * @Description: Creates a log record with the input data, splitting between Log__c and Log_2__c if needed
     * @param name: Name of the log
     * @param inputData: Data to be logged
     * @param accountId: Related account ID
     * @return Custom_Logs__c: The created log record
     */
    private Custom_Logs__c createSplitLog(String name, Map<String,Object> inputData, Id accountId) {
        String serializedData = JSON.serialize(inputData);
        Custom_Logs__c log = new Custom_Logs__c();
        log.Name = name;
        log.Account__c = accountId;
        log.OwnerId = UserInfo.getUserId();
        log.Status__c = 'New';
        
        // If data exceeds max field size, split it between Log__c and Log_2__c
        if(serializedData.length() > MAX_FIELD_SIZE) {
            log.Log__c = serializedData.substring(0, MAX_FIELD_SIZE);
            if(serializedData.length() > MAX_FIELD_SIZE) {
                Integer remainingLength = Math.min(serializedData.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                log.Log_2__c = serializedData.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
            }
        } else {
            log.Log__c = serializedData;
        }
        
        return log;
    }
}