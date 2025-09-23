/**
 * @Description: This class serves as the orchestrator for program change operations.
 * It manages the entire process of inserting and updating records across multiple objects,
 * coordinating between data mapping and DML operations.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-04-15
 * @Version: 1.0
 */
public with sharing class ARC_ProgramChangeInsertManagerAgustinaV2 {
    

    // Variables to store records for different operations
    public Map<String, Object> pcReasons;  // Stores the reasons for program changes
    public Map<String,Object> inputMap;    // Stores the input data
    public List<String> ActionsSelected = new List<String>();  // Tracks selected actions
    
    // Lists to store records for different objects
    public List<vlocity_ins__GroupCensusMember__c> censusMembersToInsert = new List<vlocity_ins__GroupCensusMember__c>();
    public Map<Account,vlocity_ins__GroupCensusMember__c> accountToCensusMember = new Map<Account,vlocity_ins__GroupCensusMember__c>();
    public List<vlocity_ins__GroupCensusMember__c> censusMembersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();        
    public List<vlocity_ins__GroupCensus__c> groupCensusToInsert = new List<vlocity_ins__GroupCensus__c>();
    public Map<String,vlocity_ins__GroupCensusMember__c> censusMemberByTemporalId = new Map<String,vlocity_ins__GroupCensusMember__c>();
    public Map<String,vlocity_ins__GroupCensusMember__c> temporalIdToCensusMembers = new Map<String,vlocity_ins__GroupCensusMember__c>();
    public vlocity_ins__GroupCensusMember__c primaryCensusMemberWithId = new vlocity_ins__GroupCensusMember__c();
    public List<Account> accountsToInsert = new List<Account>();
    public Map<String, ARC_UnderwritingCaseMember__c> censusMemberIdOrFakeIdToUWCM = new Map<String, ARC_UnderwritingCaseMember__c>();
    public List<ARC_UnderwritingCaseMember__c> UWCaseMembersToInsert = new List<ARC_UnderwritingCaseMember__c>();
    public List<Account> guardiansToInsert = new List<Account>();
    public List<Contact> contactsToInsert = new List<Contact>();
    public List<Contract> contractsToInsert = new List<Contract>();
    public List<vlocity_ins__ContractLineItem__c> contractLineItemsToInsert = new List<vlocity_ins__ContractLineItem__c>();    
    public List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlansToInsert = new List<vlocity_ins__GroupCensusMemberPlan__c>();
    public List<ARC_ContractParticipant__c> contractParticipantsToInsert = new List<ARC_ContractParticipant__c>();
    public List<ChargentOrders__ChargentOrder__c> chargentOrdersToInsert = new List<ChargentOrders__ChargentOrder__c>();
    public List<Case> casesUWToInsert = new List<Case>();
    public List<ARC_HipaaAuthorization__c> hipaaAuthorizationsToInsert = new List<ARC_HipaaAuthorization__c>();
    public List<ARC_MedicalConditions__c> medicalConditionsToInsert = new List<ARC_MedicalConditions__c>();
    public List<ARC_MedicalConditions__c> medicalConditionsToUpdate = new List<ARC_MedicalConditions__c>();
    public List<vlocity_ins__ConsumerDrug__c> consumerDrugsToInsert = new List<vlocity_ins__ConsumerDrug__c>();
    public List<vlocity_ins__ConsumerDrug__c> consumerDrugsToUpdate = new List<vlocity_ins__ConsumerDrug__c>();
    public List<Case> casesPCToInsert = new List<Case>(); 
    public Map<Id,List<vlocity_ins__ContractLineItem__c>> CMIdToCLI = new Map<Id,List<vlocity_ins__ContractLineItem__c>>();
    
    // Maps to maintain relationships between records
    public Map<Id, Account> censusMemberToAccount = new Map<Id, Account>();
    public Map<Id,Id> accountIdToMemberId = new Map<Id,Id>();

    // Map to store all inserted records by their type
    public Map<String, Map<Id, SObject>> allInsertedRecords = new Map<String, Map<Id, SObject>>();

    /**
     * @Description: Constructor that initializes the manager with program change reasons and input data
     * @param pcReasons: Map containing reasons for program changes
     * @param inputMap: Map containing input data for processing
     */
    public ARC_ProgramChangeInsertManagerAgustinaV2(Map<String, Object> pcReasons, Map<String,Object> inputMap) {
        this.pcReasons = pcReasons;
        this.inputMap = inputMap;
    }   

    /**
     * @Description: Main execution method that coordinates the entire program change process
     * It first maps the data using the DataMapper, then performs DML operations
     */
    public void executeAll() {        
        try{
            // Mapping 
            ARC_ProgramChangeDataMapperAgustinaV2 mapper = new ARC_ProgramChangeDataMapperAgustinaV2();
            mapper.executeChanges(this);
        }
        catch(Exception e){
            System.debug('Exception in executeAllMapper: ' + e.getMessage());
            throw e;
        }
        try{    
            // DML       
            ARC_ProgramChangeDMLAgustinaV2 dml = new ARC_ProgramChangeDMLAgustinaV2();
            dml.manageDML(this);
            System.debug('allInsertedRecordsManager: ' + allInsertedRecords);
            for(String key : allInsertedRecords.keySet()){
                System.debug('key ' + key);            
            }
        }
        catch(Exception e){
            System.debug('Exception in executeAllDML: ' + e.getMessage());
            throw e;
        }
    }
}