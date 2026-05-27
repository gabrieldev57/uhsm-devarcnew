/**
 * @Description: Manager class for handling Self Enrollment Flow operations.
 * This class orchestrates the enrollment process by coordinating between mapper and DML operations.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-01-27
 * @Version: 1.0
 */
global without sharing class ARC_SEManagerNico {
    
    // Properties to store enrollment data
    public Map<String, Object> enrollmentInfo { get; set; }
    public Map<String, Object> memberData { get; set; }
    public Map<String, Object> planData { get; set; }
    
    // Properties to store created record IDs
    public Id censusId { get; set; }
    public Id personAccountId { get; set; }
    public Id groupAccountId { get; set; }
    public Id contractId { get; set; }
    public Id contractLineItemId { get; set; }
    public Id groupCensusMemberPlanId { get; set; }
    public Id externalInsurancePolicyMemberId { get; set; } 
    public Id contractParticipantId { get; set; }
    public Id chargentOrderId { get; set; }
    public Id uwCaseId { get; set; }
    public Id uwCaseMemberId { get; set; }
    public Id hippaId { get; set; }
    public Id medicalQuestionId { get; set; }
    
    public Map<String, vlocity_ins__GroupCensusMember__c> memberIdToCensusMemberMap = new Map<String, vlocity_ins__GroupCensusMember__c>();
    public vlocity_ins__GroupCensus__c census;
    public Map<String, Account> memberIdToAccountMap = new Map<String, Account>();
    public Account groupAccount;
    public Map<String, Id> memberIdToPersonContactId = new Map<String, Id>();

    // Guardian related variables
    public Account guardianToInsert = new Account();
    public Id guardianInserted;

    // Chargent order related variables
    public ChargentOrders__ChargentOrder__c appFeeOrderToInsert = new ChargentOrders__ChargentOrder__c();
    public Id appFeeOrderInserted;

    /**
     * @Description: Constructor for ARC_SEManagerNico
     * @param enrollmentInfo: Map containing enrollment information
     * @param memberData: Map containing member data
     * @param planData: Map containing plan data
     */
    public ARC_SEManagerNico(Map<String, Object> enrollmentInfo) {
        this.enrollmentInfo = enrollmentInfo;
    } 
    
    /**
     * @Description: Main method to execute the complete self enrollment process
     */
    public void executeEnrollment() {
        try {
            System.debug('Starting Self Enrollment Process');
            
            // Step 1: Map the data
            ARC_SEMapperNico mapper = new ARC_SEMapperNico();
            mapper.mapEnrollmentData(this);
            
            // // Step 2: Execute DML operations
            // ARC_SEDMLNico dmlHandler = new ARC_SEDMLNico();
            // dmlHandler.processEnrollment(this);
            
            
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
            System.debug('Error in executeEnrollment: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }
    
    /**
     * @Description: Validates the enrollment data before processing
     * @return Boolean: True if validation passes, false otherwise
     */
    public Boolean validateEnrollmentData() {
        try {
            // Add validation logic here
            System.debug('Validating enrollment data');
            
            // Placeholder validation - implement actual validation logic
            return true;
            
        } catch (Exception e) {
            System.debug('Error in validateEnrollmentData: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @Description: Gets the enrollment summary for logging/debugging
     * @return Map<String, Object>: Summary of the enrollment process
     */
    public Map<String, Object> getEnrollmentSummary() {
        Map<String, Object> summary = new Map<String, Object>();
        
        summary.put('enrollmentInfo', this.enrollmentInfo);
        summary.put('memberData', this.memberData);
        summary.put('planData', this.planData);
        summary.put('censusId', this.censusId);
        summary.put('personAccountId', this.personAccountId);
        summary.put('groupAccountId', this.groupAccountId);
        summary.put('contractId', this.contractId);
        summary.put('contractLineItemId', this.contractLineItemId);
        summary.put('groupCensusMemberPlanId', this.groupCensusMemberPlanId);
        summary.put('externalInsurancePolicyMemberId', this.externalInsurancePolicyMemberId);
        summary.put('contractParticipantId', this.contractParticipantId);
        summary.put('chargentOrderId', this.chargentOrderId);
        summary.put('uwCaseId', this.uwCaseId);
        summary.put('uwCaseMemberId', this.uwCaseMemberId);
        summary.put('hippaId', this.hippaId);
        summary.put('medicalQuestionId', this.medicalQuestionId);
        
        return summary;
    }
}