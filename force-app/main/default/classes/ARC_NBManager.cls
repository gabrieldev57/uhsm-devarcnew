/**
 * @Description: This class is responsible for managing and coordinating newborn-related operations.
 * It handles different types of newborn changes and prepares the data for database operations.
 * The class follows a modular approach where each type of change triggers specific actions 
 * that are executed in sequence.
 * 
 * @Author: [Developer Name]
 * @Date: [Current Date]
 * @Version: 1.0
 */

 public with sharing class ARC_NBManager {

    /**
     * Constructor for ARC_NBManager
     * @param nbReasons: Map containing the reasons for newborn changes 
     * @param inputMap: Map containing the input data
     */
    public ARC_NBManager(Map<String,Object> nbReasons, Map<String,Object> inputMap) {
        this.nbReasons = nbReasons;
        this.inputMap = inputMap;
    } 

    private static final Integer MAX_FIELD_SIZE = 131072; // Salesforce Long Text Area limit

    // Input and Control Variables
    public Map<String, Object> nbReasons;  // Stores the reasons for newborn changes
    public Map<String,Object> inputMap;    // Stores the input data
    public List<String> ActionsSelected = new List<String>();  // Tracks selected actions
    public Set<String> actionsToPerform = new Set<String>();
    public Boolean isPermanentNewborn = false;
    public Boolean allContractsTerminated = false; // Flag to check if all contracts are terminated
    
    // Object Lists for DML Operations
    public List<Account> accountsToUpsert = new List<Account>();
    public List<Contact> contactsToUpsert = new List<Contact>();
    public List<vlocity_ins__GroupCensus__c> groupCensusToUpsert = new List<vlocity_ins__GroupCensus__c>();
    public List<vlocity_ins__GroupCensusMember__c> groupCensusMembersToUpsert = new List<vlocity_ins__GroupCensusMember__c>();
    public Map<String, Contract> contractsToUpsert = new Map<String, Contract>();
    public List<vlocity_ins__ContractLineItem__c> contractLineItemsToUpsert = new List<vlocity_ins__ContractLineItem__c>();
    public List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlansToUpsert = new List<vlocity_ins__GroupCensusMemberPlan__c>();
    public List<ARC_ContractParticipant__c> contractParticipantsToUpsert = new List<ARC_ContractParticipant__c>();
    public List<Case> casesToUpsert = new List<Case>();
    public List<Case> casesUWToInsert = new List<Case>();
    // public List<ARC_UnderwritingCaseMember__c> underwritingCaseMembersToUpsert = new List<ARC_UnderwritingCaseMember__c>();
    public Map<String, ARC_UnderwritingCaseMember__c> censusMemberIdOrFakeIdToUWCM = new Map<String, ARC_UnderwritingCaseMember__c>();
    public List<ARC_MedicalConditions__c> medicalConditionsToUpsert = new List<ARC_MedicalConditions__c>();
    public List<vlocity_ins__ConsumerDrug__c> consumerDrugsToUpsert = new List<vlocity_ins__ConsumerDrug__c>();
    public List<ARC_HipaaAuthorization__c> hipaaAuthorizationsToUpsert = new List<ARC_HipaaAuthorization__c>();
    //public List<ChargentOrders__ChargentOrder__c> chargentOrdersToUpsert = new List<ChargentOrders__ChargentOrder__c>();
    public Map<String, ChargentOrders__ChargentOrder__c> chargentOrdersToInsert = new Map<String, ChargentOrders__ChargentOrder__c>();
    public List<ARC_PromotionDiscount__c> promotionDiscountsToUpsert = new List<ARC_PromotionDiscount__c>();

    // Data Mapping and Processing Variables
    public List<Map<String,Object>> censusMembersInNBContract = new List<Map<String,Object>>();
    public List<Map<String,Object>> censusMembersInNewBornContract = new List<Map<String,Object>>();
    public List<Map<String,Object>> censusMembersRemoveContract = new List<Map<String,Object>>();
    public List<Map<String, String>> newBornMembersIds = new List<Map<String, String>>();
    public List<Map<String,Object>> censusMembersMap = new List<Map<String,Object>>(); // List of Map of Newborns
    public List<Map<String,Object>> allMembersToContPart = new List<Map<String,Object>>(); // List of Map Of ALL MEMBERS to Contract Participant
    public Map<String, vlocity_ins__GroupCensusMember__c> gcmFakeIdToInsertNB = new Map<String, vlocity_ins__GroupCensusMember__c>(); // Map of fake Id to actual record
    public Map<String, Account> accountFakeIdToInsertNB = new Map<String, Account>(); // Map of fake Id to actual record

    public Map<String, Map<String, vlocity_ins__GroupCensusMemberPlan__c>> contractIdToGCMP = new Map<String, Map<String, vlocity_ins__GroupCensusMemberPlan__c>>();
    public Map<String, Map<String, InsurancePolicyParticipant>> contractIdToPolPart = new Map<String, Map<String, InsurancePolicyParticipant>>();
    public Map<String, Map<String, ARC_CoverageParticipant__c>> contractIdToCoverPart = new Map<String, Map<String, ARC_CoverageParticipant__c>>();
    
    public List<Contract> listContractsTNB = new List<Contract>();
    public Map<String, String> fakeIdToPersonContactId = new Map<String, String>();

    public vlocity_ins__GroupCensusMember__c primaryCensusMemberAddress = new vlocity_ins__GroupCensusMember__c();
    public vlocity_ins__GroupCensusMember__c primaryCensusMember = new vlocity_ins__GroupCensusMember__c();
    public Id primaryAccountId; 
    public Boolean isMotherInActualContract = false; 

    public List<vlocity_ins__ContractLineItem__c> contractLineItemsToInsert = new List<vlocity_ins__ContractLineItem__c>();
    public Map<Integer,List<String>> indexToCLIGCM = new Map<Integer,List<String>>();
    public Map<Integer,vlocity_ins__ContractLineItem__c> indexToParentCLI = new Map<Integer,vlocity_ins__ContractLineItem__c>();
    public Map<Integer,List<vlocity_ins__ContractLineItem__c>> indexToChildCLI = new Map<Integer,List<vlocity_ins__ContractLineItem__c>>();
    public Map<String,List<vlocity_ins__ContractLineItem__c>> CMIdToCLI = new Map<String,List<vlocity_ins__ContractLineItem__c>>();
    public Map<String, ARC_ContractParticipant__c> fakeIdToContractPart = new Map<String, ARC_ContractParticipant__c>();

    public List<Date> newbornsDOB = new List<Date>();

    // Medical Conditions Related Variables
    public Map<String, List<ARC_MedicalConditions__c>> mapMedicalConditionsToInsert = new Map<String, List<ARC_MedicalConditions__c>>();
    public List<ARC_MedicalConditions__c> medicalConditionsToUpsertList = new List<ARC_MedicalConditions__c>(); 

    // Consumer Drug Related Variables
    public Map<String, List<vlocity_ins__ConsumerDrug__c>> mapConsumerDrugsToInsert = new Map<String, List<vlocity_ins__ConsumerDrug__c>>(); 
    public List<vlocity_ins__ConsumerDrug__c> consumerDrugsToUpsertList = new List<vlocity_ins__ConsumerDrug__c>();
    
    // Physican Data on Medical Questions Related Variables
    public Map<String, Map<String,Object>> mapPhysicianDataToUpdate = new Map<String, Map<String,Object>>();

    /**
     * @Description: Main execution method that coordinates the entire single NewBorn process
     * It first maps the data using the DataMapper, then performs DML operations
     * 
     * @throws Exception if there is an error during execution
     */
    public void executeSingleNewBorn() {        
        try{ 
            // Mapping 
            ARC_NBMapper mapper = new ARC_NBMapper();
            mapper.mapSingleNewBornData(this);
        }
        catch(Exception e){
            try {
                Custom_Logs__c log = createSplitLog('NewBorn Mapping failed', this.inputMap, (Id)this.inputMap.get('ContextId'));
                insert log;
                throw e;
            }
            catch(Exception ex){
                System.debug('Exception while inserting log: ' + ex.getMessage() + ex.getStackTraceString());
                throw ex;
            }
        }
        try{    
            // DML       
            ARC_NBDML dml = new ARC_NBDML();
            dml.manageDML(this);             
        }
        catch(Exception e){
            try{
                Custom_Logs__c log = createSplitLog('NewBorn DML Failed', this.inputMap, (Id)this.inputMap.get('ContextId'));
                insert log; 
                throw e;
            }
            catch(Exception ex){
                System.debug('Exception while inserting log: ' + ex.getMessage() + ex.getStackTraceString());
            }
            throw e;
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