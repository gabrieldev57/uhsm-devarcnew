public abstract class ARC_BaseProgramChangeHandler {
    // Shared variables 
    public Map<String, Object> pcReasons;
    public Map<String,Object> inputMap;
    public List<String> ActionsSelected = new List<String>();
    public List<vlocity_ins__GroupCensusMember__c> censusMembersToInsert = new List<vlocity_ins__GroupCensusMember__c>();
    public List<vlocity_ins__GroupCensusMember__c> censusMembersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();        
    public List<vlocity_ins__GroupCensus__c> groupCensusToInsert = new List<vlocity_ins__GroupCensus__c>();
    public List<Account> accountsToInsert = new List<Account>();
    public List<Contact> contactsToInsert = new List<Contact>();
    public List<Contract> contractsToInsert = new List<Contract>();
    public List<vlocity_ins__ContractLineItem__c> contractLineItemsToInsert = new List<vlocity_ins__ContractLineItem__c>();    
    public List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlansToInsert = new List<vlocity_ins__GroupCensusMemberPlan__c>();
    public List<ARC_ContractParticipant__c> contractParticipantsToInsert = new List<ARC_ContractParticipant__c>();
    public List<ChargentOrders__ChargentOrder__c> chargentOrdersToInsert = new List<ChargentOrders__ChargentOrder__c>();
    public List<Case> casesUWToInsert = new List<Case>();
    public List<ARC_HipaaAuthorization__c> hipaaAuthorizationsToInsert = new List<ARC_HipaaAuthorization__c>();
    public List<ARC_MedicalConditions__c> medicalConditionsToInsert = new List<ARC_MedicalConditions__c>();
    public List<vlocity_ins__ConsumerDrug__c> consumerDrugsToInsert = new List<vlocity_ins__ConsumerDrug__c>();
    public List<Case> casesPCToInsert = new List<Case>();
    public Map<Id, Account> censusMemberToAccount = new Map<Id, Account>();
    public Map<Id,Id> accountIdToMemberId = new Map<Id,Id>();
    public Map<String, Map<Id, SObject>> allInsertedRecords = new Map<String, Map<Id, SObject>>();

    public ARC_BaseProgramChangeHandler(Map<String, Object> pcReasons, Map<String,Object> inputMap) {
        this.pcReasons = pcReasons;
        this.inputMap = inputMap;
    }
    
    protected Account createPersonAccount(String LastName) {
        Account newPA = new Account();
        newPA.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        newPA.LastName = LastName;
        newPA.ARC_Census__c = this.inputMap.containsKey('CensusId') ? (Id)this.inputMap.get('CensusId') : null;
        return newPA;        
    }
}