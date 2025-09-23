/**
 * @Description: This class is responsible for mapping and transforming input data into Salesforce objects.
 * It handles different types of program changes and prepares the data for database operations.
 * The class follows a modular approach where each type of change (primary change, address change, etc.)
 * triggers specific actions that are executed in sequence.
 * 
 * 
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-06-24
 * @Version: 1.0
 */

public with sharing class  ARC_SOManager {
 

   
    public ARC_SOManager(Map<String,Object> soReasons, Map<String,Object> inputMap) {
        this.soReasons = soReasons;
        this.inputMap = inputMap;
    } 
   


    private static final Integer MAX_FIELD_SIZE = 131072; // Salesforce Long Text Area limit

    // Input and Control Variables
    public Map<String, Object> soReasons;  // Stores the reasons for program changes
    public Map<String,Object> inputMap;    // Stores the input data
    public List<String> ActionsSelected = new List<String>();  // Tracks selected actions
    public Set<String> actionsToPerform = new Set<String>();
    
    // Account Related Variables
    public Map<Integer,Account> groupAccountsToInsertMap = new Map<Integer,Account>();
    public Map<Integer,List<Account>> personAccountsToInsertMap = new Map<Integer,List<Account>>();
    public Map<String,Account> fictionalMemberIdToPersonAccount = new Map<String,Account>();
    // public List<Account> accountsToInsert = new List<Account>();  // NOT USED in SO implementation
    public List<Account> guardiansToInsert = new List<Account>();
    public Id guardianInserted;
    // public List<Account> physicianAccountToUpdate = new List<Account>(); // NOT USED in SO implementation
    public Map<Id, Account> censusMemberToAccount = new Map<Id, Account>();
    public Map<Id,Id> accountIdToMemberId = new Map<Id,Id>();
    public Map<Map<String,Object>,List<Map<String,Object>>> spinnedCensusMembersGroupedByPrimary = new Map<Map<String,Object>,List<Map<String,Object>>>();
    
    // Contact Related Variables
    public Contact hippaExternalContact;
    

    //Census Groups to create
    public List<vlocity_ins__GroupCensus__c> groupCensusToInsert = new List<vlocity_ins__GroupCensus__c>();
    public Map<vlocity_ins__GroupCensus__c,List<String>> groupCensusToFictionalId = new Map<vlocity_ins__GroupCensus__c,List<String>>();
    public Map<Integer,vlocity_ins__GroupCensus__c> groupCensusToInsertMap = new Map<Integer,vlocity_ins__GroupCensus__c>();
    public Map<String,vlocity_ins__GroupCensus__c> groupCensusByTemporalId = new Map<String,vlocity_ins__GroupCensus__c>();//change to maps
    
    // Group Census Member Related Variables
    public Map<Integer,List<vlocity_ins__GroupCensusMember__c>> groupCensusMembersToInsertMap = new Map<Integer,List<vlocity_ins__GroupCensusMember__c>>();
    public List<vlocity_ins__GroupCensusMember__c> censusMembersToInsert = new List<vlocity_ins__GroupCensusMember__c>();
    public Map<String,vlocity_ins__GroupCensusMember__c> censusMemberByTemporalId = new Map<String,vlocity_ins__GroupCensusMember__c>();
    public Map<String,vlocity_ins__GroupCensusMember__c> temporalIdToCensusMembers = new Map<String,vlocity_ins__GroupCensusMember__c>();
    public vlocity_ins__GroupCensusMember__c primaryCensusMemberWithId = new vlocity_ins__GroupCensusMember__c();
    public Map<String,vlocity_ins__GroupCensusMember__c> fictionalMemberIdToGCM = new Map<String,vlocity_ins__GroupCensusMember__c>();
    public Map<String,vlocity_ins__GroupCensusMember__c> fictionalMemberIdToGCMListToUpsert = new Map<String,vlocity_ins__GroupCensusMember__c>();
    // public List<vlocity_ins__GroupCensusMember__c> physicianGCMToUpdate = new List<vlocity_ins__GroupCensusMember__c>(); // NOT USED in SO implementation
    
    // Contract Related Variables
    public Map<Integer, Contract> contractsToInsertMap = new Map<Integer, Contract>();
    public Map<String, Contract> fictionalMemberIdToContract = new Map<String, Contract>();
    public Contract removeMemberContract;
    public Contract singleSpinOffContract;
    public List<Contract> contractsToVoid = new List<Contract>();
    // public List<Contract> contractsToInsert = new List<Contract>(); // NOT USED in SO implementation
    // public List<Contract> contractsToUpdate = new List<Contract>(); // NOT USED in SO implementation
    // public Id newContractId; // NOT USED in SO implementation
    
    // Contract Line Item Related Variables 
    public Map<Integer,Map<Integer, vlocity_ins__ContractLineItem__c>> indexToParentCLI = new Map<Integer, Map<Integer, vlocity_ins__ContractLineItem__c>>();
    public Map<Integer, Map<Integer, List<vlocity_ins__ContractLineItem__c>>> indexToChildCLI = new Map<Integer, Map<Integer, List<vlocity_ins__ContractLineItem__c>>>();
    public Map<Integer, Map<Integer, List<String>>> indexToCLIGCM = new Map<Integer, Map<Integer, List<String>>>();
    public Map<String, List<vlocity_ins__ContractLineItem__c>> CMIdToCLI = new Map<String, List<vlocity_ins__ContractLineItem__c>>();
    
    // Group Census Member Plan Related Variables
    public Map<String, List<vlocity_ins__GroupCensusMemberPlan__c>> fictionalMemberIdToGCMP = new Map<String, List<vlocity_ins__GroupCensusMemberPlan__c>>();

    // Contract Participant Related Variables
    public List<ARC_ContractParticipant__c> contractParticipantsToInsert = new List<ARC_ContractParticipant__c>();
    public Map<String, ARC_ContractParticipant__c> fictionalMemberIdToContractParticipant = new Map<String, ARC_ContractParticipant__c>();
    
    // Case Related Variables
    public Map<String, Case> casesUWToInsert = new Map<String, Case>();
    public List<Case> casesPCToInsert = new List<Case>(); 
    public Map<String, Case> FakeIdToCasePc = new Map<String, Case>();
    
    // Underwriting Case Member Related Variables
    public Map<String, ARC_UnderwritingCaseMember__c> censusMemberIdOrFakeIdToUWCM_SP = new Map<String, ARC_UnderwritingCaseMember__c>(); //Map of censusMemberId or fake Id to UW Case Members of Spin Off - contract
    public Map<String, ARC_UnderwritingCaseMember__c> censusMemberIdOrFakeIdToUWCM_RC = new Map<String, ARC_UnderwritingCaseMember__c>(); //Map of censusMemberId or fake Id to UW Case Members of Remove Member - contract
    
    // Medical Conditions Related Variables
    public Map<String, List<ARC_MedicalConditions__c>> mapMedicalConditionsToInsert = new Map<String, List<ARC_MedicalConditions__c>>();
    public List<ARC_MedicalConditions__c> medicalConditionsToUpsertList = new List<ARC_MedicalConditions__c>(); 
    
    // Consumer Drug Related Variables
    public Map<String, List<vlocity_ins__ConsumerDrug__c>> mapConsumerDrugsToInsert = new Map<String, List<vlocity_ins__ConsumerDrug__c>>(); 
    public List<vlocity_ins__ConsumerDrug__c> consumerDrugsToUpsertList = new List<vlocity_ins__ConsumerDrug__c>();
    
    // Physican Data on Medical Questions Related Variables
    public Map<String, Map<String,Object>> mapPhysicianDataToUpdate = new Map<String, Map<String,Object>>();

    // HIPAA Authorization Related Variables
    public ARC_HipaaAuthorization__c guardianHippa; 
    public Map<String, ARC_HipaaAuthorization__c> fakeIdToHipaaAuth = new Map<String, ARC_HipaaAuthorization__c>();
    
    // Chargent Order Related Variables
    // public List<ChargentOrders__ChargentOrder__c> chargentOrdersChangeFee = new List<ChargentOrders__ChargentOrder__c>(); // NOT USED in SO implementation
    // public List<ChargentOrders__ChargentOrder__c> chargentOrdersRecurringOrder = new List<ChargentOrders__ChargentOrder__c>(); // NOT USED in SO implementation
    public Map<String,ChargentOrders__ChargentOrder__c> chargentOrdersToInsertMap = new Map<String,ChargentOrders__ChargentOrder__c>();
    
    // Promotion Discount Related Variables
     public List<ARC_PromotionDiscount__c> promotionDiscountToInsert = new List<ARC_PromotionDiscount__c>(); // NOT USED in SO implementation
    
    // Data Mapping and Processing Variables
    public List<Map<String,Object>> censusMembersInSOContract = new List<Map<String,Object>>();
    //public Map<String, Map<String,Object>> physicianNewMemberDataToUpdate = new Map<String, Map<String,Object>>(); // NOT USED in SO implementation
    public Map<Integer, List<Map<String,Object>>> censusMembersMap = new Map<Integer, List<Map<String,Object>>>();
    public List<Map<String,Object>> censusMembersInSpinOffContract = new List<Map<String,Object>>();
    public List<Map<String,Object>> censusMembersRemoveContract = new List<Map<String,Object>>();
    public List<Map<String, String>> spinOffmembersIds = new List<Map<String, String>>();

    /**
     * @Description: Main execution method that coordinates the entire single Spin Off process
     * It first maps the data using the DataMapper, then performs DML operations
     * 
     * @throws Exception if there is an error during execution
     */
    public void executeSingleSpinOff() {        
        try{ 
            // Mapping 
            ARC_SOMapper mapper = new ARC_SOMapper();
            mapper.mapSingleSpinOffData(this);
        }
        catch(Exception e){
            try {
                Custom_Logs__c log = createSplitLog('Mapping failed', this.inputMap, (Id)this.inputMap.get('ContextId'));
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
            ARC_SODML dml = new ARC_SODML();
            dml.manageDML(this);             
        }
        catch(Exception e){
            try{
                Custom_Logs__c log = createSplitLog('Spin Off DML Failed', this.inputMap, (Id)this.inputMap.get('ContextId'));
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