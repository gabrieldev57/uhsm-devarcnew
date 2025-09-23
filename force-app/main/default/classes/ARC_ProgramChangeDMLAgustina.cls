/**
 * @Description: This class handles all database operations for program changes.
 * It manages the insertion, update, and upsert operations for all objects involved
 * in the program change process, ensuring proper error handling and maintaining
 * relationships between records.
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-04-15
 * @Version: 1.0
 */
public with sharing class ARC_ProgramChangeDMLAgustina {
    private ARC_ProgramChangeInsertManagerAgustina manager;
    

    /////Block for managing DML Operations
    /////////
    ////////////
    /////////////////   

    /**
     * @Description: Main method that manages DML operations based on selected actions
     * @param manager: The InsertManager instance containing records to process
     */
    public void manageDML(ARC_ProgramChangeInsertManagerAgustina manager) {
        this.manager = manager;
        Set<String> operations = new Set<String>();
        for(String action : manager.ActionsSelected){
            switch on action {
                when 'primaryChange' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    // operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //operations.add('insertHIPAA');
                    //Medical Questions --> Insert (?)
                    //operations.add('insertMedicalQuestions');
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'addressStateChange' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');   
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'relationshipToPrimaryChange' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');  
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'dateOfBirthChange' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'programUpgrade' {
                    //Census Member --> N/A
                    //Census --> N/A
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert
                    operations.add('insertCasesPC');
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert/Update
                    operations.add('upsertMedicalConditions');
                    operations.add('upsertConsumerDrugs');
                    // Physician Member Data --> Update
                    operations.add('updatePhysicianMemberData');
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'programDowngrade' {
                    //Census Member --> N/A
                    //Census --> N/A
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> ?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> ?
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'ancillaryChange' {                    
                    //Census Member --> N/A
                    //Census --> N/A
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> ?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> ?
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'removeAllAncillary' {
                    //Census Member --> N/A
                    //Census --> N/A
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> ?
                    //Case (PC) --> Insert/Update
                    //HIPAA -->  (?)
                    //Medical Questions --> ?
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'effectiveDateChange' {
                    //Census Member --> N/A
                    //Census --> Not needed on PC
                    //Person Account --> N/A
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');    
                    //HIPAA -->  (?)
                    //Medical Questions -->  (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'addMember' {
                    //Census Member --> Insert
                    operations.add('upsertCensusMembers');                    
                    //Census --> Not needed on PC
                    //Person Account --> Insert
                    operations.add('insertAccounts');                     
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert
                    operations.add('insertCasesPC');
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    operations.add('insertHipaaAuthorization');
                    //Medical Questions --> Insert/Update
                    operations.add('upsertMedicalConditions');
                    operations.add('upsertConsumerDrugs');
                    // Physician Member Data --> Update
                    operations.add('updatePhysicianMemberData');
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
                when 'removeMember' {
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //operations.add('insertCasesPC');
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                } 
                when 'addExistingMember' {                    
                    //Census Member --> Update
                    operations.add('upsertCensusMembers');
                    //Census --> Not needed on PC
                    //Person Account --> Update
                    operations.add('insertAccounts');
                    //Contract --> Insert
                    operations.add('insertContracts');
                    //Contract Line Item --> Insert
                    operations.add('insertContractLineItems');
                    //Group Census Member Plan --> Insert
                    operations.add('insertGroupCensusMemberPlans');
                    //Contract Participant --> Insert
                    operations.add('insertContractParticipants');   
                    //Chargent Orders --> Insert
                    operations.add('insertChargentOrders');
                    //Case (UW) --> Insert
                    operations.add('insertCasesUW');
                    //UW Case Members --> Insert?
                    //Case (PC) --> Insert/Update
                    operations.add('insertCasesPC');
                    //HIPAA --> Insert (?)
                    operations.add('insertHipaaAuthorization');
                    //Medical Questions --> Insert/Update
                    operations.add('upsertMedicalConditions');
                    operations.add('upsertConsumerDrugs');
                    // Physician Member Data --> Update
                    operations.add('updatePhysicianMemberData');
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
            }       
        }
        Savepoint sp = Database.setSavepoint();
        try{
            executeDML(operations);
        }
        catch(Exception e){
            Database.rollback(sp);
            System.debug('Exception while executing DMLOperations: ' + e.getMessage());
            throw e;
        }
    }

    /**
     * @Description: Executes DML operations based on the specified operations set
     * @param operations: Set of operations to execute
     */
    private void executeDML(Set<String> operations) {        
        if(operations.contains('updateCensusMembers')) {
            upsertCensusMembers();
        }
        if(operations.contains('upsertCensusMembers')) {
            upsertCensusMembers();
        }
        if(operations.contains('insertAccounts')) {
            insertAccounts();
            updateRelatedCensusMembers();
        }
        if(operations.contains('insertContracts')) {
            upsertContracts();
        }
        if(operations.contains('insertContractLineItems')) {
            upsertContractLineItems();
        }
        if(operations.contains('insertGroupCensusMemberPlans')) {
            upsertGroupCensusMemberPlans();
        }
        if(operations.contains('insertContractParticipants')) {
            upsertContractParticipants();
        }
        if(operations.contains('insertChargentOrders')) {
            upsertChargentOrders();
        }
        if(operations.contains('insertCasesUW')) {
            upsertCasesUW();
            upsertUWCaseMembers();
        }
        if(operations.contains('insertCasesPC')) {
            upsertCasesPC();
        }
        if(operations.contains('insertPolicy')) {
            // TODO: Implement policy insertion logic
        }
        if(operations.contains('upsertMedicalConditions')) {
            upsertMedicalConditions();
        }
        if(operations.contains('upsertConsumerDrugs')) {
            upsertConsumerDrugs();
        }
        if(operations.contains('updatePhysicianMemberData')) {
            updatePhysicianMemberData();
        }
        if(operations.contains('insertHipaaAuthorization')) {
            try {
                upsertHipaaAuthorizations();
            } catch (Exception e) {
                System.debug('error in DML hipaa');
            }
           
        }
    }    
    
    /**
     * @Description: Inserts or updates Account records
     */
    private void insertAccounts() {
        if (!manager.accountsToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.accountsToInsert, true);//All or none = true
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting account: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('Account')) {
                            manager.allInsertedRecords.put('Account', new Map<Id, SObject>());
                        }                      
                        manager.allInsertedRecords.get('Account').put(result.getId(), manager.accountsToInsert[i]);                        
                        
                        manager.accountIdToMemberId.put(result.getId(), manager.accountsToInsert[i].Census_Member__c);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting accounts: ' + e.getMessage());
                throw e;
            }
        }
        if (!manager.guardiansToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.guardiansToInsert, true);//All or none = true
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting Guardian: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('Guardian')) {
                            manager.allInsertedRecords.put('Guardian', new Map<Id, SObject>());
                        }                      
                        manager.allInsertedRecords.get('Guardian').put(result.getId(), manager.guardiansToInsert[i]);                        
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting Guardians: ' + e.getMessage());
                throw e;
            }
        }
        
    }
    private void upsertCensusMembers() {
        if (!manager.censusMemberByTemporalId.isEmpty()) {            
            try {
                System.debug('censusMemberByTemporalId ' + manager.censusMemberByTemporalId);
                // First insert the census members         
                System.debug('censusMemberByTemporalId values ' + manager.censusMemberByTemporalId.values());      
                Database.SaveResult[] results = Database.insert(manager.censusMemberByTemporalId.values(), true);
                
                // Then create and insert accounts
                for (vlocity_ins__GroupCensusMember__c cm : manager.censusMemberByTemporalId.values()) {

                    if (!manager.allInsertedRecords.containsKey('GroupCensusMember')) {
                        manager.allInsertedRecords.put('GroupCensusMember', new Map<Id, SObject>());
                    }
                    manager.allInsertedRecords.get('GroupCensusMember').put(cm.Id, cm);

                    // Create account and link it to the census member
                    Account newAcc = createPersonAccount(cm.vlocity_ins__LastName__c);
                    newAcc.Census_Member__c = cm.Id;
                    newAcc.ARC_CensusMember__pc = cm.Id;
                    newAcc.ARC_Census__c = cm.vlocity_ins__CensusId__c;
                    manager.accountsToInsert.add(newAcc);
                    manager.censusMemberToAccount.put(cm.Id, newAcc);
                    
                    if (cm.ARC_DependentRelationship__c == null || cm.ARC_DependentRelationship__c == 'Future Primary') {
                        manager.primaryCensusMemberWithId = cm;
                    }

                    System.debug('allInsertedRecords.get(GroupCensusMember) ' + manager.allInsertedRecords.get('GroupCensusMember') );                        
                    
                }
                System.debug('censusMemberByTemporalId After Insert ' + manager.censusMemberByTemporalId);                
            } catch (Exception e) {
                System.debug('Exception while upserting census members: ' + e.getMessage());
                throw e;
            }
        }      
        if (!manager.censusMembersToUpdate.isEmpty()) {
            System.debug('censusMembersToUpdateDML: ' + manager.censusMembersToUpdate);
            try {
                Database.SaveResult[] results = Database.update(manager.censusMembersToUpdate, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error updating census member: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('GroupCensusMemberUpdated')) {
                            manager.allInsertedRecords.put('GroupCensusMemberUpdated', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('GroupCensusMemberUpdated').put(result.getId(), manager.censusMembersToUpdate[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while updating census members: ' + e.getMessage());
                throw e;
            }
        }      
    }
    private void upsertContracts() {
        if (!manager.contractsToInsert.isEmpty()) {
            for(Contract c : manager.contractsToInsert) {
                System.debug('contract Status ' + c.Status + ' ' + c.Account_Name_Text__c);
                System.debug('RecordTypeContract ' + c.RecordTypeId);  
            }
            try {
                Database.UpsertResult[] results = Database.upsert(manager.contractsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('Contract')) {
                            manager.allInsertedRecords.put('Contract', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('Contract').put(result.getId(), manager.contractsToInsert[i]);
                    }
                }
                /*
                for(Contract c : manager.contractsToInsert){
                    c.Status = 'Awaiting Signature';
                }
                Database.UpsertResult[] resultsUpdated = Database.upsert(manager.contractsToInsert, true);
                */
            } catch (Exception e) {
                System.debug('Exception while upserting contracts: ' + e.getMessage());
                throw e;
            }
        }
    }

    private void upsertContractLineItems() {
        if(!manager.indexToParentCLI.isEmpty() && !manager.indexToChildCLI.isEmpty()){
            Set<Id> contractIds = manager.allInsertedRecords.get('Contract').keySet();
            Id newContractId = new List<Id>(contractIds)[0];            
            for(Integer index : manager.indexToParentCLI.keySet()){
                manager.indexToParentCLI.get(index).vlocity_ins__ContractId__c = newContractId;
            }
            for(Integer index : manager.indexToChildCLI.keySet()){
                for(vlocity_ins__ContractLineItem__c childCLI : manager.indexToChildCLI.get(index)){
                    childCLI.vlocity_ins__ContractId__c = newContractId;
                }
            }
            Database.UpsertResult[] results = Database.upsert(manager.indexToParentCLI.values(), true);
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult result = results[i];
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error upserting contract line item: ' + error.getMessage());
                    }
                } 
                else {
                    if (!manager.allInsertedRecords.containsKey('ContractLineItem')) {
                        manager.allInsertedRecords.put('ContractLineItem', new Map<Id, SObject>());
                    }
                    manager.allInsertedRecords.get('ContractLineItem').put(result.getId(), manager.indexToParentCLI.get(i));
                    for(vlocity_ins__ContractLineItem__c childCLI : manager.indexToChildCLI.get(i)){
                        childCLI.vlocity_ins__ParentItemId__c = result.getId();
                    }
                }
            }
            List<vlocity_ins__ContractLineItem__c> childCLIList = new List<vlocity_ins__ContractLineItem__c>();
            for(List<vlocity_ins__ContractLineItem__c> childCLIS : manager.indexToChildCLI.values()){
                childCLIList.addAll(childCLIS);
            }
            Database.UpsertResult[] resultsChild = Database.upsert(childCLIList, true);
            for (Integer i = 0; i < resultsChild.size(); i++) {
                Database.UpsertResult result = resultsChild[i];
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error upserting contract line item: ' + error.getMessage());
                    }
                } else {
                    if (!manager.allInsertedRecords.containsKey('ContractLineItem')) {
                        manager.allInsertedRecords.put('ContractLineItem', new Map<Id, SObject>());
                    }
                    manager.allInsertedRecords.get('ContractLineItem').put(result.getId(), childCLIList[i]);
                }
            } 
        }
    }

    private void upsertGroupCensusMemberPlans() {
        if (!manager.groupCensusMemberPlansToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.groupCensusMemberPlansToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting group census member plan: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('GroupCensusMemberPlan')) {
                            manager.allInsertedRecords.put('GroupCensusMemberPlan', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('GroupCensusMemberPlan').put(result.getId(), manager.groupCensusMemberPlansToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting group census member plans: ' + e.getMessage());
                throw e;
            }
        }
    }

    private void upsertContractParticipants() {
        if (!manager.personAccIdOrFakeIdToContractPart.values().isEmpty()) {
            try {
                for (String key : manager.personAccIdOrFakeIdToContractPart.keySet()) {
                    ARC_ContractParticipant__c contractParticipant = manager.personAccIdOrFakeIdToContractPart.get(key);
                    if (key.startsWith('MEM-')) {
                        contractParticipant.ARC_PersonAccount__c = manager.censusMemberToAccount.get(manager.censusMemberByTemporalId.get(key).Id).Id;
                    }
                    contractParticipant.ARC_Contract__c = manager.allInsertedRecords.get('Contract').keySet().isEmpty() ? null : manager.allInsertedRecords.get('Contract').keySet().iterator().next();
                }
                manager.contractParticipantsToInsert = manager.personAccIdOrFakeIdToContractPart.values();

                Database.UpsertResult[] results = Database.upsert(manager.contractParticipantsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract participant: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('ContractParticipant')) {
                            manager.allInsertedRecords.put('ContractParticipant', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('ContractParticipant').put(result.getId(), manager.contractParticipantsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting contract participants: ' + e.getMessage());
                throw e;
            }
        }
    }

    private void upsertChargentOrders() {
        if (!manager.chargentOrdersToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.chargentOrdersToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting chargent order: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('ChargentOrder')) {
                            manager.allInsertedRecords.put('ChargentOrder', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('ChargentOrder').put(result.getId(), manager.chargentOrdersToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting chargent orders: ' + e.getMessage());
                throw e;
            }
        }
    }

    private void upsertCasesUW() {

        if (!manager.casesUWToInsert.isEmpty()) {
            try {
                manager.casesUWToInsert[0].ARC_Contract__c = manager.allInsertedRecords.get('Contract').keySet().iterator().next();
                //Populate information related to Primary
                manager.casesUWToInsert[0].ARC_CensusMember__c = manager.primaryCensusMemberWithId.Id; 
                manager.casesUWToInsert[0].ContactId = manager.primaryCensusMemberWithId.vlocity_ins__ContactId__c; 
                manager.casesUWToInsert[0].ARC_PersonAccount__c = manager.censusMemberToAccount.get(manager.primaryCensusMemberWithId.Id).Id;                 

                Database.UpsertResult[] results = Database.upsert(manager.casesUWToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting UW case: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('CaseUW')) {
                            manager.allInsertedRecords.put('CaseUW', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('CaseUW').put(result.getId(), manager.casesUWToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting UW cases: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertUWCaseMembers() {
    
        if (!manager.censusMemberIdOrFakeIdToUWCM.values().isEmpty()) {
            try {
                for (String key : manager.censusMemberIdOrFakeIdToUWCM.keySet()) {
                    ARC_UnderwritingCaseMember__c uwCaseMember = manager.censusMemberIdOrFakeIdToUWCM.get(key);
                    if (key.startsWith('MEM-')) {
                        uwCaseMember.ARC_Member__c = manager.censusMemberByTemporalId.get(key).Id;
                        uwCaseMember.ARC_PersonAccount__c = manager.censusMemberToAccount.get(manager.censusMemberByTemporalId.get(key).Id).Id;
                    }
                    uwCaseMember.ARC_Contract__c = manager.allInsertedRecords.get('Contract').keySet().isEmpty() ? null : manager.allInsertedRecords.get('Contract').keySet().iterator().next();
                    uwCaseMember.ARC_UnderwritingCase__c = manager.allInsertedRecords.get('CaseUW').keySet().isEmpty() ? null : manager.allInsertedRecords.get('CaseUW').keySet().iterator().next();
                }
                manager.UWCaseMembersToInsert = manager.censusMemberIdOrFakeIdToUWCM.values();

                Database.UpsertResult[] results = Database.upsert(manager.UWCaseMembersToInsert, true); //All or none = true
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting UW Case Member: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('UWCaseMember')) {
                            manager.allInsertedRecords.put('UWCaseMember', new Map<Id, SObject>());
                        }                      
                        manager.allInsertedRecords.get('UWCaseMember').put(result.getId(), manager.UWCaseMembersToInsert[i]);                        
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting UWCaseMember: ' + e.getMessage());
                throw e;
            }
        }
    }

    private void upsertHipaaAuthorizations() {
        System.debug('before if hipaa dml');
        System.debug('son null?: ' + manager.hippaExternalContact);
        if (!manager.fakeIdToHipaaAuth.isEmpty() || manager.hippaExternalContact != null) {
            System.debug('after if hipaa dml');
            try {
                // for to recorrer el map
                for (String key : manager.fakeIdToHipaaAuth.keySet()) {
                    ARC_HipaaAuthorization__c hipaaAuth = manager.fakeIdToHipaaAuth.get(key);

                    if (key.startsWith('MEM-')) {
                        hipaaAuth.ARC_AuthorizedMember__c = manager.censusMemberByTemporalId.get(key).Id;
                    }
                }
                manager.hipaaAuthorizationsToInsert = manager.fakeIdToHipaaAuth.values();
                if (manager.hippaExternalContact != null) {
                    Database.UpsertResult result = Database.upsert(manager.hippaExternalContact, true);

                    if (result.isSuccess()) {
                        Id contactId = result.getId();
                        ARC_HipaaAuthorization__c newHipaa = new ARC_HipaaAuthorization__c();
                        newHipaa.Name = manager.hippaExternalContact.FirstName + ' ' + manager.hippaExternalContact.LastName;
                        newHipaa.ARC_ExternalPersonAuthorized__c = contactId;
                        newHipaa.ARC_Census__c =  manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;
                        manager.hipaaAuthorizationsToInsert.add(newHipaa);
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting Contact to external Hipaa: ' + error.getMessage());
                        }
                    }
                }
                
                System.debug('hipaa debug: ' + manager.hipaaAuthorizationsToInsert);
                Database.UpsertResult[] results = Database.upsert(manager.hipaaAuthorizationsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting HIPAA authorization: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('HipaaAuthorization')) {
                            manager.allInsertedRecords.put('HipaaAuthorization', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('HipaaAuthorization').put(result.getId(), manager.hipaaAuthorizationsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting HIPAA authorizations: ' + e.getMessage());
                throw e;
            }
        }
    }

    private void upsertMedicalConditions() {
        
        if(!manager.newMembersMapMedicalConditionsToInsert.isEmpty()) {
            try {
                for (String fakeId : manager.newMembersMapMedicalConditionsToInsert.keySet()) {
                    Id censusId = manager.censusMemberByTemporalId.containsKey(fakeId) ? manager.censusMemberByTemporalId.get(fakeId).Id : null;
                    Id accountId = manager.censusMemberToAccount.containsKey(censusId) ? manager.censusMemberToAccount.get(censusId).Id : null;
                    
                    system.debug('censusId ' + censusId);
                    system.debug('accountId ' + accountId);

                    List<ARC_MedicalConditions__c> medicalConditionsList = manager.newMembersMapMedicalConditionsToInsert.get(fakeId);
                    if (medicalConditionsList != null && !medicalConditionsList.isEmpty()) {
                        for (ARC_MedicalConditions__c mc : medicalConditionsList) {
                            mc.ARC_CensusMember__c = censusId;
                            mc.ARC_PersonAccount__c = accountId;

                            manager.medicalConditionsToUpsert.add(mc);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting newMembersMapMedicalConditionsToInsert: ' + e.getMessage());
                throw e;
            }
        }
        
        if (!manager.medicalConditionsToUpsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.medicalConditionsToUpsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting medical condition: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('MedicalCondition')) {
                            manager.allInsertedRecords.put('MedicalCondition', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('MedicalCondition').put(result.getId(), manager.medicalConditionsToUpsert[i]);
                    }
                }

                system.debug('upsertMedicalConditions allInsertedRecords ' + manager.allInsertedRecords.get('MedicalCondition'));

            } catch (Exception e) {
                System.debug('Exception while upserting medical conditions: ' + e.getMessage());
                throw e;
            }
        }
    }

    private void upsertConsumerDrugs() {

        if(!manager.NewMembersMapConsumerDrugsToInsert.isEmpty()) {
            try {
                for (String fakeId : manager.NewMembersMapConsumerDrugsToInsert.keySet()) {
                    Id censusId = manager.censusMemberByTemporalId.containsKey(fakeId) ? manager.censusMemberByTemporalId.get(fakeId).Id : null;
                    Id accountId = manager.censusMemberToAccount.containsKey(censusId) ? manager.censusMemberToAccount.get(censusId).Id : null;
                    
                    system.debug('censusId ' + censusId);
                    system.debug('accountId ' + accountId);

                    List<vlocity_ins__ConsumerDrug__c> consumerDrugList = manager.NewMembersMapConsumerDrugsToInsert.get(fakeId);
                    if (consumerDrugList != null && !consumerDrugList.isEmpty()) {
                        for (vlocity_ins__ConsumerDrug__c cd : consumerDrugList) {
                            
                            cd.ARC_CensusMember__c = censusId;
                            cd.ARC_PersonAccount__c = accountId;

                            manager.consumerDrugsToUpsert.add(cd);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting NewMembersMapConsumerDrugsToInsert: ' + e.getMessage());
                throw e;
            }
        }



        if (!manager.consumerDrugsToUpsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.consumerDrugsToUpsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting consumer drug: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('ConsumerDrug')) {
                            manager.allInsertedRecords.put('ConsumerDrug', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('ConsumerDrug').put(result.getId(), manager.consumerDrugsToUpsert[i]);
                    }
                }
                system.debug('upsertConsumerDrugs allInsertedRecords ' + manager.allInsertedRecords.get('ConsumerDrug'));
            } catch (Exception e) {
                System.debug('Exception while upserting consumer drugs: ' + e.getMessage());
                throw e;
            }
        }
    }

    private void updatePhysicianMemberData() {
        if(!manager.physicianNewMemberDataToUpdate.isEmpty()) {
            try {
                for (String fakeId : manager.physicianNewMemberDataToUpdate.keySet()) {
                    Id censusId = manager.censusMemberByTemporalId.containsKey(fakeId) ? manager.censusMemberByTemporalId.get(fakeId).Id : null;
                    Id accountId = manager.censusMemberToAccount.containsKey(censusId) ? manager.censusMemberToAccount.get(censusId).Id : null;
                    
                    system.debug('censusId ' + censusId);
                    system.debug('accountId ' + accountId);

                    Map<String, Object> physicianMemberInfo = manager.physicianNewMemberDataToUpdate.get(fakeId);

                    Account phA = new Account();
                    phA.Id = accountId;
                    phA.ARC_PhysicianName__c = (String)physicianMemberInfo.get('ARC_PhysicianName__c');
                    phA.ARC_PhysicianCity__c = (String)physicianMemberInfo.get('ARC_PhysicianCity__c');
                    phA.ARC_PhysicianPhone__c = (String)physicianMemberInfo.get('ARC_PhysicianPhone__c');
    
                    vlocity_ins__GroupCensusMember__c phGCM = new vlocity_ins__GroupCensusMember__c();
                    phGCM.Id = censusId;
                    phGCM.ARC_PhysicianName__c = (String)physicianMemberInfo.get('ARC_PhysicianName__c');
                    phGCM.ARC_PhysicianCity__c = (String)physicianMemberInfo.get('ARC_PhysicianCity__c');
                    phGCM.ARC_PhysicianPhone__c = (String)physicianMemberInfo.get('ARC_PhysicianPhone__c');

                    manager.physicianAccountToUpdate.add(phA);
                    manager.physicianGCMToUpdate.add(phGCM);
                }
            } catch (Exception e) {
                System.debug('Exception while upserting updatePhysicianMemberData: ' + e.getMessage());
                throw e;
            }
        }

        if (!manager.physicianAccountToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(manager.physicianAccountToUpdate, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error updateing physician account data: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('physicianAccountToUpdate')) {
                            manager.allInsertedRecords.put('physicianAccountToUpdate', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('physicianAccountToUpdate').put(result.getId(), manager.physicianAccountToUpdate[i]);
                    }
                }
                system.debug('physicianAccountToUpdate allInsertedRecords ' + manager.allInsertedRecords.get('physicianAccountToUpdate'));
            } catch (Exception e) {
                System.debug('Exception while updateing physician account data: ' + e.getMessage());
                throw e;
            }
        }

        if (!manager.physicianGCMToUpdate.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(manager.physicianGCMToUpdate, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error updateing physician census member data: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('physicianGCMToUpdate')) {
                            manager.allInsertedRecords.put('physicianGCMToUpdate', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('physicianGCMToUpdate').put(result.getId(), manager.physicianGCMToUpdate[i]);
                    }
                }
                system.debug('physicianGCMToUpdate allInsertedRecords ' + manager.allInsertedRecords.get('physicianGCMToUpdate'));
            } catch (Exception e) {
                System.debug('Exception while updateing physician census member data: ' + e.getMessage());
                throw e;
            }
        }
    }

    private void upsertCasesPC() {
        if (!manager.casesPCToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.casesPCToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting PC case: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('CasePC')) {
                            manager.allInsertedRecords.put('CasePC', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('CasePC').put(result.getId(), manager.casesPCToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting PC cases: ' + e.getMessage());
                throw e;
            }
        }
    }

    ///////////////////////
    // Auxiliary Methods //
    ///////////////////////

    /**
     * @Description: Creates a new Person Account record
     * @param LastName: The last name for the account
     * @return Account: The newly created account
     */
    private Account createPersonAccount(String LastName) {
        Account newPA = new Account();
        newPA.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        newPA.LastName = LastName;
        newPA.ARC_Census__c = manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;
        return newPA;        
    }

    /**
     * @Description: Updates related Census Member records with Contact IDs
    */
    private void updateRelatedCensusMembers() {
        List<vlocity_ins__GroupCensusMember__c> censusMembersToUpdateContactId = new List<vlocity_ins__GroupCensusMember__c>();
        List<Account> accContacts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE Id IN :manager.accountIdToMemberId.keySet()]);
        for(Account acc : accContacts) {
            vlocity_ins__GroupCensusMember__c censusMember = (vlocity_ins__GroupCensusMember__c)manager.allInsertedRecords.get('GroupCensusMember').get(manager.accountIdToMemberId.get(acc.Id));
            censusMember.vlocity_ins__ContactId__c = acc.PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = censusMember.vlocity_ins__SocialSecurityNumber__c;
            censusMembersToUpdateContactId.add(censusMember);
        }
        update censusMembersToUpdateContactId;
    }


}