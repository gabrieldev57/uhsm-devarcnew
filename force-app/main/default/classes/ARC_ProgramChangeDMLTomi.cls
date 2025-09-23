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
public with sharing class ARC_ProgramChangeDMLTomi {
    private ARC_ProgramChangeInsertManagerTomi manager;
    

    /////Block for managing DML Operations
    /////////
    ////////////
    /////////////////   

    /**
     * @Description: Main method that manages DML operations based on selected actions
     * @param manager: The InsertManager instance containing records to process
     */
    public void manageDML(ARC_ProgramChangeInsertManagerTomi manager) {
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
                    //Medical Questions --> Update (?)
                    operations.add('upsertMedicalConditions');
                    operations.add('upsertConsumerDrugs');
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
                    //Medical Questions --> Insert (?)
                    operations.add('upsertMedicalConditions');
                    operations.add('upsertConsumerDrugs');
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
                    //Medical Questions --> Insert (?)
                    //Policy & related Object --> Insert
                    operations.add('insertPolicy');
                }
            }       
        }
        executeDML(operations);
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
        if (!manager.UWCaseMembersToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.UWCaseMembersToInsert, true);//All or none = true
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
    private void upsertCensusMembers() {
        if (!manager.censusMemberByTemporalId.isEmpty()) {            
            try {
                System.debug('censusMemberByTemporalId ' + manager.censusMemberByTemporalId);
                // First insert the census members                
                Database.SaveResult[] results = Database.insert(manager.censusMemberByTemporalId.values(), true);
                
                // Then create and insert accounts
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting census member: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('GroupCensusMember')) {
                            manager.allInsertedRecords.put('GroupCensusMember', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('GroupCensusMember').put(result.getId(), manager.censusMembersToInsert[i]);
 
                        // Create account and link it to the census member
                        Account newAcc = createPersonAccount((String)manager.censusMembersToInsert[i].vlocity_ins__LastName__c);
                        newAcc.Census_Member__c = result.getId();
                        newAcc.ARC_CensusMember__pc = result.getId();
                        newAcc.ARC_Census__c = manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;
                        manager.accountsToInsert.add(newAcc);
                        manager.censusMemberToAccount.put(result.getId(), newAcc);     

                        System.debug('allInsertedRecords.get(GroupCensusMember) ' + manager.allInsertedRecords.get('GroupCensusMember') );                        
                    }
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
            } catch (Exception e) {
                System.debug('Exception while upserting contracts: ' + e.getMessage());
                throw e;
            }
        }
    }
    private void upsertContractLineItems() {
        if (!manager.contractLineItemsToInsert.isEmpty()) {
            // Get the contract ID from the inserted records
            Set<Id> contractIds = manager.allInsertedRecords.get('Contract').keySet();
            if (!contractIds.isEmpty()) {
                Id newContractId = new List<Id>(contractIds)[0];
                for(vlocity_ins__ContractLineItem__c cli : manager.contractLineItemsToInsert) {
                    if(manager.CMIdToCLI.containsKey(cli.vlocity_ins__AccountId__c)) {
                        cli.vlocity_ins__ContractId__c = newContractId;
                    }
                }
            }
            try {
                Database.UpsertResult[] results = Database.upsert(manager.contractLineItemsToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract line item: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('ContractLineItem')) {
                            manager.allInsertedRecords.put('ContractLineItem', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('ContractLineItem').put(result.getId(), manager.contractLineItemsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting contract line items: ' + e.getMessage());
                throw e;
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
        if (!manager.contractParticipantsToInsert.isEmpty()) {
            try {
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
    private void upsertHipaaAuthorizations() {
        if (!manager.hipaaAuthorizationsToInsert.isEmpty()) {
            try {
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
            censusMembersToUpdateContactId.add(censusMember);
        }
        update censusMembersToUpdateContactId;
    }

}