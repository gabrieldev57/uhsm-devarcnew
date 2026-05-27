public with sharing  class ARC_PCSOManager {
       
    private static final Integer MAX_FIELD_SIZE = 131072; // Salesforce Long Text Area limit

    // Variables to store records for different operations
    public Map<String, Object> soReasons;  // Stores the reasons for program changes
    public Map<String, Object> soChanges; // Stores the changes to be made
    public Map<String, Object> sTEP_ChargentPayment;
    public Map<String, Object> selectedContractInfo;
    public Map<String,Object> inputMap;    // Stores the input data
    public List<String> ActionsSelected = new List<String>();  // Tracks selected actions
    
    // Lists to store records for different objects
    public List<vlocity_ins__GroupCensusMember__c> censusMembersToInsert = new List<vlocity_ins__GroupCensusMember__c>();
    public List<vlocity_ins__GroupCensusMember__c> censusMembersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();
    public Map<String,vlocity_ins__GroupCensusMember__c> censusMemberByTemporalId = new Map<String,vlocity_ins__GroupCensusMember__c>();
    public vlocity_ins__GroupCensusMember__c primaryCensusMemberWithId = new vlocity_ins__GroupCensusMember__c();
    public List<vlocity_ins__GroupCensusMember__c> censusMembersDemographicChange = new List<vlocity_ins__GroupCensusMember__c>();
    public List<Account> accountsToInsert = new List<Account>(); 
    public Map<String, ARC_UnderwritingCaseMember__c> censusMemberIdOrFakeIdToUWCM = new Map<String, ARC_UnderwritingCaseMember__c>();
    public List<Map<String,Object>> censusMembersInPcContract = new List<Map<String,Object>>();
    public List<Account> guardiansToInsert = new List<Account>();
    public Contact hippaExternalContact;
    public ARC_HipaaAuthorization__c guardianHippa;
    public Map<String, ARC_HipaaAuthorization__c> fakeIdToHipaaAuth = new Map<String, ARC_HipaaAuthorization__c>();
    public List<Contract> contractsToInsert = new List<Contract>();
    public List<Contract> contractToUpdateEffectiveDate = new List<Contract>();
    public List<Ages_Up__c> agesUpToInsert = new List<Ages_Up__c>();
    
    public Map<Integer,vlocity_ins__ContractLineItem__c> indexToParentCLI = new Map<Integer,vlocity_ins__ContractLineItem__c>();
    public Map<Integer,List<vlocity_ins__ContractLineItem__c>> indexToChildCLI = new Map<Integer,List<vlocity_ins__ContractLineItem__c>>();
    public Map<Integer,List<String>> indexToCLIGCM = new Map<Integer,List<String>>();
    public List<ARC_ContractParticipant__c> contractParticipantsToInsert = new List<ARC_ContractParticipant__c>();
    public List<ChargentOrders__ChargentOrder__c> chargentOrdersChangeFee = new List<ChargentOrders__ChargentOrder__c>();
    public List<ChargentOrders__ChargentOrder__c> chargentOrdersRecurringOrder = new List<ChargentOrders__ChargentOrder__c>(); 
    public Map<String, List<Case>> casesUWToInsert = new Map<String, List<Case>>();
    public List<ARC_MedicalConditions__c> medicalConditionsToUpsert = new List<ARC_MedicalConditions__c>();
    public List<vlocity_ins__ConsumerDrug__c> consumerDrugsToUpsert = new List<vlocity_ins__ConsumerDrug__c>();
    public Map<String, List<ARC_MedicalConditions__c>> newMembersMapMedicalConditionsToInsert = new Map<String, List<ARC_MedicalConditions__c>>();
    public Map<String, List<vlocity_ins__ConsumerDrug__c>> NewMembersMapConsumerDrugsToInsert = new Map<String, List<vlocity_ins__ConsumerDrug__c>>();
    public List<Account> physicianAccountToUpdate = new List<Account>();
    public List<vlocity_ins__GroupCensusMember__c> physicianGCMToUpdate = new List<vlocity_ins__GroupCensusMember__c>();
    public Map<String, Map<String,Object>> physicianNewMemberDataToUpdate = new Map<String, Map<String,Object>>();
    public List<Case> casesPCToInsert = new List<Case>();
    public Map<String, ARC_ContractParticipant__c> personAccIdOrFakeIdToContractPart = new Map<String, ARC_ContractParticipant__c>();
    public List<ARC_ContractParticipant__c> contractParticipantsToDelete = new List<ARC_ContractParticipant__c>();
    public Map<String, Case> FakeIdToCasePc = new Map<String, Case>();
    public List<ARC_PromotionDiscount__c> promotionDiscountToInsert = new List<ARC_PromotionDiscount__c>();
    public Id newContractId;
    
    // Beneficiaries related variables
    public Map<String,Object> contactOrFakeIdToBeneficiaries = new Map<String,Object>();
    
    // Maps to maintain relationships between records
    public Map<Id, Account> censusMemberToAccount = new Map<Id, Account>();
    public Map<String, String> censusMemberToPersonAccount = new Map<String, String>();
    public Map<String, Account> insertedCensusMemberToPersonAccount = new Map<String, Account>();

    // Map to store all inserted records by their type
    public Map<String, Map<Id, SObject>> allInsertedRecords = new Map<String, Map<Id, SObject>>();

    // Ancillary discount related variables
    public Map<String, Map<String, String>> memberIdToCriticalCareBundle = new Map<String, Map<String, String>>();
    public Map<String, Map<String, Id>> memberIdToBundleGcmpIds = new Map<String, Map<String, Id>>();
    
    /**
     * @Description: Constructor that initializes the manager with program change reasons and input data
     * @param pcReasons: Map containing reasons for program changes
     * @param inputMap: Map containing input data for processing
     */
    public ARC_PCSOManager(Map<String, Object> soReasons, Map<String,Object> inputMap) {
        this.soChanges = inputMap.containsKey('soChanges') && (Map<String, Object>)inputMap.get('soChanges') != null ? (Map<String, Object>)inputMap.get('soChanges') : null;
        this.soReasons = soReasons;
        this.sTEP_ChargentPayment = inputMap.containsKey('STEP_ChargentPayment') && (Map<String, Object>)inputMap.get('STEP_ChargentPayment') != null ? (Map<String, Object>)inputMap.get('STEP_ChargentPayment') : null;
        this.selectedContractInfo = inputMap.containsKey('SelectedContractInfo') && (Map<String, Object>)inputMap.get('SelectedContractInfo') != null ? (Map<String, Object>)inputMap.get('SelectedContractInfo') : null;
        this.inputMap = inputMap;
    }   

   

    /**
     * @Description: Main execution method that coordinates the entire program change process
     * It first maps the data using the DataMapper, then performs DML operations
     */
    public void executeAll() {        
        try{
            // Mapping 
            ARC_PCSOMapper mapper = new ARC_PCSOMapper();
            mapper.executeChanges(this);
        }
        catch(Exception e){
            try {
                Custom_Logs__c log = createSplitLog('PC SO Mapping failed', this.inputMap, (Id)this.inputMap.get('ContextId'));
                insert log;
                System.debug(e.getMessage() + ' ' + e.getStackTraceString());
                throw e;
            }
            catch(Exception ex){
                System.debug('Exception while inserting log: ' + ex.getMessage() + ex.getStackTraceString());
                throw ex;
            }
        }
        try{    
            // DML       
            ARC_PCSODML dml = new ARC_PCSODML();
            dml.manageDML(this);
        }
        catch(Exception e){
            try{
                System.debug('DML Failed 1');
                Custom_Logs__c log = createSplitLog('PC SO DML Failed', this.inputMap, (Id)this.inputMap.get('ContextId'));
                System.debug('DML Failed 2 ' + log);
                insert log;
                System.debug(e.getMessage() + ' ' + e.getStackTraceString());
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