/**
 * @Description: This class handles all database operations for program changes.
 * It manages the insertion, update, and upsert operations for all objects involved
 * in the program change process, ensuring proper error handling and maintaining
 * relationships between records.
 * 
 * Key Responsibilities:
 * - Manages DML operations for all program change-related objects
 * - Handles record relationships and dependencies
 * - Provides error handling and transaction management
 * - Supports various program change scenarios (upgrades, downgrades, member changes)
 * 
 * @Author: Felipe Cladera
 * @Date: 2025-04-15
 * @Version: 1.0
 */
public without sharing class ARC_PCDML{
    @TestVisible
    private ARC_PCManager manager;
    

    /////Block for managing DML Operations
    /////////
    ////////////
    /////////////////   

    /**
     * @Description: Main method that manages DML operations based on selected actions.
     * This method orchestrates the entire DML process by:
     * 1. Determining required operations based on program change type
     * 2. Creating a transaction savepoint for rollback if needed
     * 3. Executing operations in the correct sequence
     * 
     * @param manager The InsertManager instance containing records to process
     * @throws Exception If any DML operation fails, allowing for transaction rollback
     */
    public void manageDML(ARC_PCManager manager) {
        this.manager = manager;
        Set<String> operations = new Set<String>();
        
        // Determine required operations based on action type
        for(String action : manager.ActionsSelected){
            switch on action {
                when 'primaryChange' {
                    operations.add('upsertCensusMembers');
                    operations.add('insertAccounts');
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                }
                when 'addressStateChange' {
                    operations.add('upsertCensusMembers');
                    operations.add('insertAccounts');   
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertCasesPC');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                    operations.add('updateLegacyAccount');
                }
                when 'relationshipToPrimaryChange' {
                    operations.add('upsertCensusMembers');  
                    operations.add('insertAccounts');
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertCasesPC');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                }
                when 'dateOfBirthChange' {
                    operations.add('upsertCensusMembers');
                    operations.add('insertAccounts');
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertChargentOrders');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertCasesPC');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                    operations.add('updateLegacyAccount');
                }
                when 'programUpgrade' {
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertCasesPC');
                    operations.add('upsertMedicalConditions');
                    operations.add('upsertConsumerDrugs');
                    operations.add('updatePhysicianMemberData');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                }
                when 'programDowngrade' {
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertChargentOrders');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertCasesPC');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                }
                when 'ancillaryChange' {                    
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertCasesPC');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                }
                when 'removeAllAncillary' {
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertCasesPC');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                }
                when 'effectiveDateChange' {
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('upsertChargentOrders');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertCasesPC');    
                    operations.add('insertPolicy');
                    operations.add('updateLegacyAccount');

                }
                when 'addMember' {
                    operations.add('upsertCensusMembers');                    
                    operations.add('insertAccounts');                     
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertCasesUW');
                    operations.add('insertCasesPC');
                    operations.add('insertHipaaAuthorization');
                    operations.add('upsertMedicalConditions');
                    operations.add('upsertConsumerDrugs');
                    operations.add('updatePhysicianMemberData');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                }
                when 'removeMember' {
                    operations.add('upsertCensusMembers');
                    operations.add('insertAccounts');
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertCasesUW');
                    operations.add('insertCasesPC');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                } 
                when 'addExistingMember' {                    
                    operations.add('upsertCensusMembers');                    
                    operations.add('insertAccounts');
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');   
                    operations.add('insertCasesUW');
                    operations.add('insertCasesPC');
                    operations.add('insertHipaaAuthorization');
                    operations.add('upsertMedicalConditions');
                    operations.add('upsertConsumerDrugs');
                    operations.add('updatePhysicianMemberData');
                    operations.add('insertPolicy');
                    operations.add('upsertChargentOrders');
                }
                when 'agingOut' {
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('upsertChargentOrders');
                    operations.add('insertCasesUW');
                    operations.add('insertHipaaAuthorization');
                    operations.add('insertCasesPC');    
                    operations.add('insertPolicy');
                    operations.add('updateLegacyAccount');
                }
                when 'demographicChange' {
                    operations.add('demographicChange');
                    operations.add('insertHipaaAuthorization');
                    operations.add('updateLegacyAccount');

                }
                when 'updateEffectiveDateChange' {
                    operations.add('insertContracts');
                    operations.add('upsertChargentOrders');
                    operations.add('insertHipaaAuthorization');
                }
                when 'addExistingActiveNewborn' {
                    operations.add('updatePolicyParticipantForNewborns');
                }
            }       
        }
        
        // Create savepoint and execute operations
        Savepoint sp = Database.setSavepoint();
        try{
            executeDML(operations);
        } catch(Exception e) {
            Database.rollback(sp);
            System.debug('Exception while executing DMLOperations the changes will be rolled back: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Executes DML operations in the correct sequence based on dependencies.
     * This method ensures that all operations are executed in the proper order to maintain
     * data integrity and referential relationships.
     * 
     * @param operations Set of operation names to execute
     * @throws Exception If any DML operation fails
     */
    private void executeDML(Set<String> operations) {        
        if(operations.contains('updateCensusMembers')) {
            try {
                upsertCensusMembers('updateCensusMembers');
            } catch (Exception e) {
                System.debug('Exception while upserting census members: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('upsertCensusMembers')) {
            try {
                upsertCensusMembers('updateCensusMembers');
            } catch (Exception e) {
                System.debug('Exception while upserting census members: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('insertAccounts')) {
            try {
                insertAccounts();
                updateRelatedCensusMembers();
            } catch (Exception e) {
                System.debug('Exception while inserting accounts: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('insertContracts')) {
            try {
                upsertContracts();
            } catch (Exception e) {
                System.debug('Exception while upserting contracts: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('insertContractLineItems')) {
            try {
                upsertContractLineItems();
            } catch (Exception e) {
                System.debug('Exception while upserting contract line items: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('insertGroupCensusMemberPlans')) {
            try {
                upsertGroupCensusMemberPlans();
                processCriticalCarePromotionDiscount();
            } catch (Exception e) {
                System.debug('Exception while upserting group census member plans: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('insertContractParticipants')) {
            upsertContractParticipants();
        }
        if(operations.contains('upsertChargentOrders')) {
            try {
                upsertChargentOrders();
            } catch (Exception e) {
                System.debug('Exception while upserting chargent orders: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('insertCasesUW')) {
            try {
                upsertCasesUW();
                //upsertUWCaseMembers();
            } catch (Exception e) {
                System.debug('Exception while upserting UW cases: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('insertCasesPC')) {
            try {
                upsertCasesPC();
            } catch (Exception e) {
                System.debug('Exception while upserting PC cases: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('insertPolicy')) {
            try {
                insertPolicy();
            } catch (Exception e) {
                System.debug('Exception while inserting policy: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('upsertMedicalConditions')) {
            try {
                upsertMedicalConditions();
            } catch (Exception e) {
                System.debug('Exception while upserting medical conditions: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('upsertConsumerDrugs')) {
            try {
                upsertConsumerDrugs();
            } catch (Exception e) {
                System.debug('Exception while upserting consumer drugs: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('updatePhysicianMemberData')) {
            try {
                updatePhysicianMemberData();
            } catch (Exception e) {
                System.debug('Exception while updating physician member data: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('insertHipaaAuthorization')) {
            try {
                upsertHipaaAuthorizations();
            } catch (Exception e) {
                System.debug('error in DML hipaa' + e.getMessage() + e.getStackTraceString());
            }
        }
        if(operations.contains('demographicChange')) {
            try {
                upsertCensusMembers('demographicChange');
            } catch (Exception e) {
                System.debug('Exception while upserting census members: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('updateLegacyAccount')) {
            try {
                updateLegacyAccount();
            } catch (Exception e) {
                System.debug('Exception while updating legacy account: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        if(operations.contains('updatePolicyParticipantForNewborns')){
            try {
                updatePolicyParticipantForNewborns();
            } catch (Exception e) {
                System.debug('Exception while updating policy participants for newborns: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        completeOmniScriptInstancesForAccountContext();
    }    

    /**
     * @Description: Inserts or updates Account records including Person Accounts and Guardians.
     * This method:
     * 1. Processes standard accounts and person accounts
     * 2. Handles guardian relationships
     * 3. Updates related census member records
     * 
     * @throws Exception if account operations fail
     */
    private void insertAccounts() {
        if (!manager.accountsToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.accountsToInsert, true);
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
                System.debug('Exception while upserting accounts: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        processGuardians();
    }

    /**
     * @Description: Processes guardian records separately from standard accounts.
     * @throws Exception if guardian processing fails
     */
    private void processGuardians() {
        if (!manager.guardiansToInsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.guardiansToInsert, true);
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
                        if(!manager.pcReasons.containsKey('primaryChange') || (manager.pcReasons.containsKey('primaryChange') && !((Boolean) manager.pcReasons.get('primaryChange')))){
                            updateCensusFieldGuardian();
                        }
                        
                    }
                }
            //    updateContract();
            } catch (Exception e) {
                System.debug('Exception while upserting Guardians: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }    
    }

    /**
     * @Description: Updates census ARC_GuardianAccount__c field 
     * This method:
     * 1. Links Guardian Id to census
     * 
     * @throws Exception If census ARC_GuardianAccount__c field update fails
     */
    private void updateCensusFieldGuardian() {
        try {
            if (manager.allInsertedRecords.containsKey('Guardian')) {
                //Get census Id
                vlocity_ins__GroupCensus__c updatedCensus = new vlocity_ins__GroupCensus__c();
                updatedCensus.Id = manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;
                updatedCensus.ARC_IsChildFamily__c = true;

                // Get Guardian Id
                Map<Id, sObject> guardians = manager.allInsertedRecords.get('Guardian');
                Set<Id> guardiansIds = guardians.KeySet();
                Id guardianId = new List<Id>(guardiansIds)[0];
                
                updatedCensus.ARC_GuardianAccount__c = guardianId;
            
                update updatedCensus;
            }
        }
        catch (Exception e) {
            System.debug('Exception while updating contract: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Manages census member records through insert and update operations.
     * This method handles:
     * 1. New census member creation
     * 2. Existing member updates
     * 3. Demographic changes
     * 4. Relationship updates
     * 
     * @throws Exception If census member operations fail
     */
    private void upsertCensusMembers(String operation) {
        if(operation == 'updateCensusMembers'){
            System.debug('Check sync Census Members to update: ' + manager.censusMembersToUpdate);
            if (!manager.censusMemberByTemporalId.isEmpty()) {
                System.debug('Check sync Census Members to insert: ' + manager.censusMemberByTemporalId.values());
                try {
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
                    }                                    
                } catch (Exception e) {
                    System.debug('Exception while upserting census members: ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                }
            }      
            if (!manager.censusMembersToUpdate.isEmpty()) {
                System.debug('Check sync Census Members to update: ' + manager.censusMembersToUpdate);
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
                    System.debug('Exception while updating census members: ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                }
            }
        }
        if(operation == 'demographicChange'){
            if(!manager.censusMembersDemographicChange.isEmpty()) {
                System.debug('Check sync  DEM Census Members to update: ' + manager.censusMembersDemographicChange);
                
                // Get the IDs and serialize the records for the future call
                List<Id> censusMemberIds = new List<Id>();
                for(vlocity_ins__GroupCensusMember__c member : manager.censusMembersDemographicChange) {
                    if(member.Id != null) {
                        censusMemberIds.add(member.Id);
                    }
                }
                
                String jsonCensusMembers = JSON.serialize(manager.censusMembersDemographicChange);
                String fullJson = JSON.serialize(manager.inputMap);
                Id contextId = (Id)manager.inputMap.get('ContextId');
                
                // Call the future method
                handleDemographicChangeFuture(censusMemberIds, jsonCensusMembers, fullJson,contextId);
                
                // Since we can't get the results back from the future method,
                // we'll need to query for the records to update allInsertedRecords
            }
        }      
    }

    /**
     * @Description: Handles contract record creation and updates.
     * This method processes:
     * 1. New contract creation
     * 2. Contract status updates
     * 3. Contract relationship management
     * 4. Contract field population
     * 
     * @throws Exception If contract operations fail
     */
    @TestVisible
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
                        manager.newContractId = result.getId();
                    }
                }
                updateContractFieldGuardian();
                System.debug('manager.contractsToUpdate: ' + manager.contractsToUpdate);
                if(!manager.contractsToUpdate.isEmpty()){
                    try{
                        Database.update(manager.contractsToUpdate, true);
                    }
                    catch(Exception e){
                        System.debug('Exception while voiding contracts: ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting contracts: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }

        if (!manager.agesUpToInsert.isEmpty()) {

            try {

                Database.SaveResult[] results = Database.insert(manager.agesUpToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error inserting age ups: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('AgeUps')) {
                            manager.allInsertedRecords.put('AgeUps', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('AgeUps').put(result.getId(), manager.agesUpToInsert[i]);
                    }
                }
                
            } catch (Exception e) {
                System.debug('Exception while insertig age ups on effective date changes contracts: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Manages contract line item records and their relationships.
     * This method:
     * 1. Creates parent and child line items
     * 2. Maintains product relationships
     * 3. Sets pricing and quantity information
     * 4. Links line items to contracts
     * 
     * @throws Exception If line item operations fail
     */
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

    /**
     * @Description: Handles group census member plan records.
     * This method:
     * 1. Creates plan associations
     * 2. Links members to plans
     * 3. Maintains plan relationships
     * 4. Updates plan details
     * 
     * @throws Exception If plan operations fail
     */
    private void upsertGroupCensusMemberPlans() {
        if (!manager.indexToParentCLI.isEmpty() && !manager.indexToCLIGCM.isEmpty()) {
            try {
                List<vlocity_ins__GroupCensusMemberPlan__c> gcmpListToUpsert = new List<vlocity_ins__GroupCensusMemberPlan__c> ();
                for(Integer index : manager.indexToParentCLI.keySet()){
                    for(String gcmId : manager.indexToCLIGCM.get(index)){
                        String censusMemberId;
                        if(gcmId.startsWith('MEM-')){
                            censusMemberId =manager.temporalIdToCensusMembers.get(gcmId).Id;
                        }
                        else{
                            censusMemberId =gcmId;
                        }
                        vlocity_ins__GroupCensusMemberPlan__c newGCMP = new vlocity_ins__GroupCensusMemberPlan__c();
                        newGCMP.Name = manager.indexToParentCLI.get(index)?.Name;
                        newGCMP.vlocity_ins__GroupCensusMemberId__c = censusMemberId;
                        newGCMP.vlocity_ins__ContractLineId__c = manager.indexToParentCLI.get(index).Id;
                        gcmpListToUpsert.add(newGCMP);
                    }                    
                }
                if(!gcmpListToUpsert.isEmpty()){
                    Database.UpsertResult[] results = Database.upsert(gcmpListToUpsert, true);
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
                            manager.allInsertedRecords.get('GroupCensusMemberPlan').put(result.getId(), gcmpListToUpsert[i]);

                            // ── Ancillary bundle GCMP resolution ──────────────────────────────
                            vlocity_ins__GroupCensusMemberPlan__c insertedGcmp = gcmpListToUpsert[i];
                            Id gcmpCliId = insertedGcmp.vlocity_ins__ContractLineId__c;

                            for (String memberId : manager.memberIdToCriticalCareBundle.keySet()) {
                                Map<String, Integer> bundleIndexes = manager.memberIdToCriticalCareBundle.get(memberId);

                                for (String bundleType : bundleIndexes.keySet()) { // 'SMART' or 'AIDD'
                                    Integer ancIndex = bundleIndexes.get(bundleType);
                                    vlocity_ins__ContractLineItem__c matchCli = manager.indexToParentCLI.get(ancIndex);

                                    if (matchCli != null && matchCli.Id == gcmpCliId) {
                                        // Verify this GCMP belongs to the right member
                                        // gcmpListToUpsert was built from indexToCLIGCM which uses census member IDs
                                        // The census member ID is stored in vlocity_ins__GroupCensusMemberId__c
                                        String expectedCensusMemberId = memberId.startsWith('MEM-')
                                            ? (manager.temporalIdToCensusMembers.containsKey(memberId) 
                                                ? manager.temporalIdToCensusMembers.get(memberId).Id 
                                                : null)
                                            : memberId;

                                        if (insertedGcmp.vlocity_ins__GroupCensusMemberId__c == expectedCensusMemberId) {
                                            if (!manager.memberIdToBundleGcmpIds.containsKey(memberId)) {
                                                manager.memberIdToBundleGcmpIds.put(memberId, new Map<String, Id>());
                                            }
                                            manager.memberIdToBundleGcmpIds.get(memberId).put(bundleType, result.getId());
                                            System.debug('Bundle GCMP resolved (PC) | member: ' + memberId + ' | type: ' + bundleType + ' | GCMP Id: ' + result.getId());
                                        }
                                    }
                                }
                            }
                            // ── End bundle resolution ──────────────────────────────────────────
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting group census member plans: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Links resolved GCMP IDs (SMART / AIDD) to the
     * ARC_PromotionDiscount__c shells created for the Critical Care bundle,
     * then upserts them. Mirrors processCriticalCarePromotionDiscount in ARC_SEDML.
     */
    @TestVisible
    private void processCriticalCarePromotionDiscount() {
        try {
            System.debug('Processing Critical Care Promotion Discount DML (PC)');

            if (manager.memberIdToCriticalCareBundle.isEmpty()) return;

            List<ARC_PromotionDiscount__c> bundleDiscounts = new List<ARC_PromotionDiscount__c>();

            ARC_PromotionCode__c ancillaryCode = [
                SELECT Id FROM ARC_PromotionCode__c
                WHERE Name = 'Ancillary Discount'
                LIMIT 1
            ];

            Id ancillaryDiscountRT = Schema.SObjectType.ARC_PromotionDiscount__c
                .getRecordTypeInfosByDeveloperName()
                .get('Ancillary_Discount')
                .getRecordTypeId();

            for (String memberId : manager.memberIdToCriticalCareBundle.keySet()) {

                ARC_PromotionDiscount__c targetPd = new ARC_PromotionDiscount__c();
                targetPd.RecordTypeId = ancillaryDiscountRT;

                Map<String, Id> gcmpIds = manager.memberIdToBundleGcmpIds.get(memberId);
                if (gcmpIds == null || !gcmpIds.containsKey('SMART') || !gcmpIds.containsKey('AIDD')) {
                    System.debug('Incomplete GCMP IDs for bundle member: ' + memberId + ' | resolved: ' + gcmpIds);
                    continue;
                }

                Id newContractId = manager.allInsertedRecords.containsKey('Contract') 
                    && !manager.allInsertedRecords.get('Contract').keySet().isEmpty()
                    ? manager.allInsertedRecords.get('Contract').keySet().iterator().next()
                    : null;

                targetPd.ARC_Contract__c = newContractId;
                targetPd.ARC_SMART__c    = gcmpIds.get('SMART');
                targetPd.ARC_AIDD__c     = gcmpIds.get('AIDD');
                targetPd.ARC_PromoCode__c = ancillaryCode.Id;

                bundleDiscounts.add(targetPd);
            }

            if (!bundleDiscounts.isEmpty()) {
                Database.UpsertResult[] results = Database.upsert(bundleDiscounts, true);
                for (Database.UpsertResult result : results) {
                    if (result.isSuccess()) {
                        System.debug('Critical Care PromotionDiscount upserted (PC): ' + result.getId());
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting Critical Care PromotionDiscount (PC): ' + error.getMessage());
                        }
                        throw new DmlException('Failed to upsert Critical Care PromotionDiscount: ' + result.getErrors());
                    }
                }
            }

        } catch (Exception e) {
            System.debug('Error in processCriticalCarePromotionDiscount (PC): ' 
                + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Processes contract participant records.
     * This method:
     * 1. Creates participant records
     * 2. Links participants to contracts
     * 3. Sets participant roles and relationships
     * 4. Updates participant information
     * 
     * @throws Exception If participant operations fail
     */
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
                List<ARC_ContractParticipant__c> contractParticipantsToInsert = new List<ARC_ContractParticipant__c>();
                contractParticipantsToInsert = manager.personAccIdOrFakeIdToContractPart.values();

                Database.UpsertResult[] results = Database.upsert(contractParticipantsToInsert, true);
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
                        manager.allInsertedRecords.get('ContractParticipant').put(result.getId(), contractParticipantsToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting contract participants: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Manages Chargent order records for payment processing.
     * This method handles:
     * 1. Payment order creation
     * 2. Recurring payment setup
     * 3. Payment method configuration
     * 4. Order status management
     * 
     * @throws Exception If payment order operations fail
     */
    private void upsertChargentOrders() {
        List<ChargentOrders__ChargentOrder__c> chargentOrdersToUpsert = new List<ChargentOrders__ChargentOrder__c>();
        chargentOrdersToUpsert.addAll(manager.chargentOrdersRecurringOrder);
        chargentOrdersToUpsert.addAll(manager.chargentOrdersChangeFee);
        System.debug('Chargent orders to upsert: ' + chargentOrdersToUpsert);

        Set<Id> contractIds = manager.allInsertedRecords.get('Contract').keySet();
        Id newContractId = new List<Id>(contractIds)[0]; 

        for(ChargentOrders__ChargentOrder__c co : chargentOrdersToUpsert){
            co.ARC_Contract__c = newContractId;
        }        
        if (!chargentOrdersToUpsert.isEmpty()) {
            try {
                Database.UpsertResult[] results = Database.upsert(chargentOrdersToUpsert, true);
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
                        manager.allInsertedRecords.get('ChargentOrder').put(result.getId(), chargentOrdersToUpsert[i]);
                    }
                }                
            } catch (Exception e) {
                System.debug('Exception while upserting chargent orders: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Updates contract ARC_Guardian__c field 
     * This method:
     * 1. Links Guardian Id to contracts
     * 
     * @throws Exception If contract ARC_Guardian__c field update fails
     */
    private void updateContractFieldGuardian(){
        try{
            if(manager.allInsertedRecords.containsKey('Guardian')) {
                //Get contract Id
                Set<Id> contractIds = manager.allInsertedRecords.get('Contract').keySet();
                Id newContractId = new List<Id>(contractIds)[0];
                Contract insertedContract = (Contract)manager.allInsertedRecords.get('Contract').get(newContractId);

                // Get Guardian Id
                Map<Id, sObject> guardians = manager.allInsertedRecords.get('Guardian');
                Set<Id> guardiansIds = guardians.KeySet();
                Id guardianId = new List<Id>(guardiansIds)[0];
                
                insertedContract.ARC_Guardian__c = guardianId;
            

                update insertedContract;
            }
        }
        catch(Exception e){
            System.debug('Exception while updating contract: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Processes underwriting case records.
     * This method:
     * 1. Creates underwriting cases
     * 2. Links cases to contracts and members
     * 3. Sets case status and details
     * 4. Manages case relationships
     * 
     * @throws Exception If case operations fail
     */
    private void upsertCasesUW() {
        if (!manager.casesUWToInsert.isEmpty()) {
            try {
                // Prepare the data for the future call
                Case uwCase = manager.casesUWToInsert[0];
                uwCase.ARC_Contract__c = manager.allInsertedRecords.get('Contract').keySet().iterator().next();
                uwCase.ARC_CensusMember__c = manager.primaryCensusMemberWithId.Id;
                uwCase.ContactId = manager.primaryCensusMemberWithId.vlocity_ins__ContactId__c;
                uwCase.ARC_PersonAccount__c = manager.censusMemberToAccount.get(manager.primaryCensusMemberWithId.Id).Id;
                
                // Get the necessary data for contract update
                Id contractId = manager.allInsertedRecords.get('Contract').keySet().iterator().next();
                
                // Get Chargent Orders if they exist
                Id feeOrderId = null;
                Id recurringOrderId = null;
                if (manager.allInsertedRecords.containsKey('ChargentOrder')) {
                    for(Id coId : manager.allInsertedRecords.get('ChargentOrder').keySet()) {
                        ChargentOrders__ChargentOrder__c co = (ChargentOrders__ChargentOrder__c)manager.allInsertedRecords.get('ChargentOrder').get(coId);
                        if(co.ChargentOrders__Payment_Frequency__c == 'Monthly') {
                            recurringOrderId = co.Id;
                        } else {
                            feeOrderId = co.Id;
                        }
                    }
                }

                // Prepare UW Case Member data
                List<ARC_UnderwritingCaseMember__c> UWCaseMembersList = new  List<ARC_UnderwritingCaseMember__c>();
                for (String key : manager.censusMemberIdOrFakeIdToUWCM.keySet()) {
                    ARC_UnderwritingCaseMember__c uwCaseMember = manager.censusMemberIdOrFakeIdToUWCM.get(key);
                    
                    if (key.startsWith('MEM-')) {
                        uwCaseMember.ARC_Member__c = manager.censusMemberByTemporalId.get(key).Id;
                        uwCaseMember.ARC_PersonAccount__c = manager.censusMemberToAccount.get(manager.censusMemberByTemporalId.get(key).Id).Id;
                    } else {
                        uwCaseMember.ARC_Member__c = key;
                    }
                    UWCaseMembersList.add(uwCaseMember);
                }
                
                // Serialize all the data for future processing
                String jsonUWCaseMembers = JSON.serialize(UWCaseMembersList);
                String jsonUWCase = JSON.serialize(manager.casesUWToInsert);
                String fullJson = JSON.serialize(manager.inputMap);
                Id contextId = (Id)manager.inputMap.get('ContextId');
                String jsonTasksToInsert = JSON.serialize(manager.tasksToInsert);
                String jsonTasksToUpdate = JSON.serialize(manager.tasksToUpdate);
                String paymentStartDate = manager.paymentStartDate != null? String.valueOf(manager.paymentStartDate):null;
                String jsonFeeItems = !manager.chargeFeeItems.isEmpty() ? JSON.serialize(manager.chargeFeeItems) : '';

                
                //////////////////////////////////////////////////////////////

                String jsonPromotionDiscount = '';

                if(!manager.promotionDiscountToInsert.isEmpty()){
                    jsonPromotionDiscount = JSON.serialize(manager.promotionDiscountToInsert);
                }

                // Call the future method with all necessary data
                handleUWCaseAndMembersFuture(jsonUWCase, contractId, feeOrderId, recurringOrderId, jsonUWCaseMembers, fullJson, contextId, jsonPromotionDiscount, jsonTasksToInsert, jsonTasksToUpdate, paymentStartDate, jsonFeeItems);
                
            } catch (Exception e) {
                System.debug('Exception while preparing UW case for future processing: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    @future
    public static void handleUWCaseAndMembersFuture(String jsonUWCase, Id contractId, Id feeOrderId, Id recurringOrderId, String jsonUWCaseMembers,String fullJson,Id contextId,String jsonPromotionDiscount, String jsonTasksToInsert, String jsonTasksToUpdate, String paymentStartDate, String jsonFeeItems) {
        try {
            //Deseerialize the open tasks to Update
            if(jsonTasksToUpdate != null && jsonTasksToUpdate != ''){
                List<Task> tasksToUpdate = (List<Task>)JSON.deserialize(jsonTasksToUpdate, List<Task>.class);
                Database.UpsertResult[] taskResults = Database.upsert(tasksToUpdate, true);
                for (Database.UpsertResult result : taskResults) {
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error Closing Open Tasks: ' + error.getMessage());
                        }
                    }
                }
            }
            // Create a list for the upsert
            List<Case> casesToUpsert = (List<Case>)JSON.deserialize(jsonUWCase, List<Case>.class);
            
            // Perform the upsert
            Database.UpsertResult[] results = Database.upsert(casesToUpsert, true);
            
            // Store the new case ID for contract update and UW Case Members
            Id newCaseId = null;
            List<ARC_PromotionDiscount__c> promotionDiscounts = new List<ARC_PromotionDiscount__c>();
            if(jsonPromotionDiscount != null && jsonPromotionDiscount != ''){
                //Deserialize the promotion discount
                promotionDiscounts = (List<ARC_PromotionDiscount__c>)JSON.deserialize(jsonPromotionDiscount, List<ARC_PromotionDiscount__c>.class);
            }

            // Process results and log any errors
            for (Database.UpsertResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error upserting UW case in future context: ' + error.getMessage());
                    }
                } else if (newCaseId == null) {
                    newCaseId = result.getId();
                }
            }


            // Update the contract with the new case and orders
            if (contractId != null) {
                Contract contractToUpdate = new Contract(
                    Id = contractId,
                    ARC_AppFeeOrder__c = feeOrderId,
                    ARC_RecurringMonthlyOrder__c = recurringOrderId,
                    ARC_Case__c = newCaseId,
                    Status = 'Awaiting Signature'
                );
                
                update contractToUpdate;
            }
            //UPDATE PAYMENT START DATE
            if(paymentStartDate != null && recurringOrderId != null){
                Date recurringPaymentStartDate =  Date.valueOf(paymentStartDate);
                ChargentOrders__ChargentOrder__c recurringOrder = new ChargentOrders__ChargentOrder__c();
                recurringOrder.Id = recurringOrderId;
                recurringOrder.ChargentOrders__Payment_Start_Date__c = recurringPaymentStartDate;
                update recurringOrder;
            }

            // Handle UW Case Members if we have a successful case creation
            if (newCaseId != null) {
                List<ARC_UnderwritingCaseMember__c> uwCaseMembersToInsert = (List<ARC_UnderwritingCaseMember__c>)JSON.deserialize(jsonUWCaseMembers, List<ARC_UnderwritingCaseMember__c>.class);
                //Deseerialize the tasks to Insert
                if(jsonTasksToInsert != null && jsonTasksToInsert != ''){
                    List<Task> tasksToInsert = (List<Task>)JSON.deserialize(jsonTasksToInsert, List<Task>.class);
                    for(Task t : tasksToInsert){
                        t.whatId = newCaseId;
                    }
                    Database.UpsertResult[] taskResults = Database.upsert(tasksToInsert, true);
                    for (Database.UpsertResult result : taskResults) {
                        if (!result.isSuccess()) {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error Upserting Tasks: ' + error.getMessage());
                            }
                        }
                    }
                }               
                for (ARC_UnderwritingCaseMember__c member : uwCaseMembersToInsert) {    
                    member.ARC_Contract__c = contractId;
                    member.ARC_UnderwritingCase__c = newCaseId;
                    System.debug('Uw Member in future ' + member);
                }

                if (!uwCaseMembersToInsert.isEmpty()) {
                    Database.UpsertResult[] memberResults = Database.upsert(uwCaseMembersToInsert, true);
                    for (Database.UpsertResult result : memberResults) {
                        if (!result.isSuccess()) {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting UW Case Member in future context: ' + error.getMessage());
                            }
                        }
                    }
                }
            }

            if (!promotionDiscounts.isEmpty()) {     
                try {
    
                    for(ARC_PromotionDiscount__c d : promotionDiscounts) {
                        d.ARC_Contract__c = contractId;
                    }
    
                    Database.UpsertResult[] resultsPD   = Database.upsert(promotionDiscounts, true);//All or none = true
                    for (Integer i = 0; i < resultsPD.size(); i++) {
                        Database.UpsertResult result = resultsPD[i];
                        if (!result.isSuccess()) {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error promotion disocunt: ' + error.getMessage());
                            }
                        } else {                                               
                            System.debug('Promotion discount upserted successfully');                
                        }
                    }
                } catch (Exception e) {
                    System.debug('Exception while upserting promotion discount: ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                }
            } 

            List<ARC_FeeItem__c> feeItemsToInsert = new List<ARC_FeeItem__c>();
            if(jsonFeeItems != null && jsonFeeItems != ''){
                //Deserialize the promotion discount
                feeItemsToInsert = (List<ARC_FeeItem__c>)JSON.deserialize(jsonFeeItems, List<ARC_FeeItem__c>.class);
            }

            if (!feeItemsToInsert.isEmpty()) { 

                try {
    
                    for(ARC_FeeItem__c f : feeItemsToInsert) {
                        f.ARC_ChargentOrder__c = feeOrderId;
                    }
    
                    Database.UpsertResult[] resultsFI   = Database.upsert(feeItemsToInsert, true);//All or none = true
                    for (Integer i = 0; i < resultsFI.size(); i++) {
                        Database.UpsertResult result = resultsFI[i];
                        if (!result.isSuccess()) {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error pfee items: ' + error.getMessage());
                            }
                        } else {                                               
                            System.debug('Fee Items Inserted successfully');                
                        }
                    }
                } catch (Exception e) {
                    System.debug('Exception while inserting fee items: ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                }

            }

            
        } catch (Exception e) {
            Integer MAX_FIELD_SIZE = 131072-10;

            String serializedData = fullJson;
            Custom_Logs__c log = new Custom_Logs__c();
            log.Name = 'Exception while processing UW case and members in future context';
            log.Account__c = contextId;
            log.OwnerId = UserInfo.getUserId();
            log.Status__c = 'New';
            
            if(serializedData != null && serializedData.length() > MAX_FIELD_SIZE) {
                log.Log__c = serializedData.substring(0, MAX_FIELD_SIZE);
                if(serializedData.length() > MAX_FIELD_SIZE) {
                    Integer remainingLength = Math.min(serializedData.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                    log.Log_2__c = serializedData.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                }
            } else if(serializedData != null) {
                log.Log__c = serializedData;
            } else {
                log.Log__c = 'No serialized data available';
            }
            try {
                insert log;
            } catch (Exception logException) {
                System.debug('Failed to insert log record: ' + logException.getMessage());
            }
            
            System.debug('Exception while processing UW case and members in future context: ' + e.getMessage() + e.getStackTraceString());
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail; 
            String inputDataString = JSON.serialize(fullJson);
            String emailBody = 'Error in ARC_PCDML.cls handleUWCaseAndMembersFuture: ' +e.getLineNumber()+' - '+ e.getMessage() + 
                                '\n\nInput Data: ' + inputDataString + 
                                '\n\nStack Trace: ' + e.getStackTraceString();
            ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in DML while running future method', apexErrorEmail);
            // throw e;
        }
    }

    /**
     * @Description: Handles underwriting case member records.
     * This method:
     * 1. Creates case member associations
     * 2. Links members to cases
     * 3. Sets member status and details
     * 4. Maintains member relationships
     * 
     * @throws Exception If case member operations fail
     */
    @TestVisible
    private void upsertUWCaseMembers() {
    
        if (!manager.censusMemberIdOrFakeIdToUWCM.values().isEmpty()) {
            List<ARC_UnderwritingCaseMember__c> UWCaseMembersToInsert = new List<ARC_UnderwritingCaseMember__c>();
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
                UWCaseMembersToInsert = manager.censusMemberIdOrFakeIdToUWCM.values();

                Database.UpsertResult[] results = Database.upsert(UWCaseMembersToInsert, true); //All or none = true
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
                        manager.allInsertedRecords.get('UWCaseMember').put(result.getId(), UWCaseMembersToInsert[i]);                        
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting UWCaseMember: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Processes HIPAA authorization records.
     * This method:
     * 1. Creates authorization records
     * 2. Links authorizations to members
     * 3. Handles external contacts
     * 4. Handles guardian hipaas
     * 5. Maintains authorization relationships
     * 
     * @throws Exception If authorization operations fail
     */
    @TestVisible
    private void upsertHipaaAuthorizations() {
        if (!manager.fakeIdToHipaaAuth.isEmpty() || manager.hippaExternalContact != null || manager.guardianHippa != null) {
            try {
                List<ARC_HipaaAuthorization__c> listAuthToInsert = new List<ARC_HipaaAuthorization__c>();

                for (String key : manager.fakeIdToHipaaAuth.keySet()) {
                    ARC_HipaaAuthorization__c hipaaAuth = manager.fakeIdToHipaaAuth.get(key);

                    if (key.startsWith('MEM-')) {
                        hipaaAuth.ARC_AuthorizedMember__c = manager.censusMemberByTemporalId.get(key).Id;
                    }
                }
                listAuthToInsert = manager.fakeIdToHipaaAuth.values();

                if (manager.hippaExternalContact != null) {
                    Database.UpsertResult result = Database.upsert(manager.hippaExternalContact, true);

                    if (result.isSuccess()) {
                        Id contactId = result.getId();
                        ARC_HipaaAuthorization__c newHipaa = new ARC_HipaaAuthorization__c();
                        newHipaa.Name = manager.hippaExternalContact.FirstName + ' ' + manager.hippaExternalContact.LastName;
                        newHipaa.ARC_ExternalPersonAuthorized__c = contactId;
                        newHipaa.ARC_Census__c =  manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;
                        listAuthToInsert.add(newHipaa);
                    } else {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting Contact to external Hipaa: ' + error.getMessage());
                        }
                    }
                }

                if (manager.guardianHippa != null) {
                    Map<Id, sObject> guardians = manager.allInsertedRecords.get('Guardian');
                    Set<Id> guardiansIds = guardians.KeySet();
                    if (!guardiansIds.isEmpty()) {
                        Id guardianId = new List<Id>(guardiansIds)[0];
                        Account guardian = [SELECT PersonContactId FROM Account WHERE Id =: guardianId LIMIT 1];
                        ARC_HipaaAuthorization__c guardianHippa = manager.guardianHippa;
                        guardianHippa.ARC_ExternalPersonAuthorized__c = guardian.PersonContactId;
                        listAuthToInsert.add(guardianHippa);
                    }
                }
                
                Database.UpsertResult[] results = Database.upsert(listAuthToInsert, true);
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
                        manager.allInsertedRecords.get('HipaaAuthorization').put(result.getId(), listAuthToInsert[i]);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting HIPAA authorizations: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Manages medical condition records.
     * This method:
     * 1. Creates condition records
     * 2. Links conditions to members
     * 3. Updates condition status
     * 4. Maintains condition relationships
     * 
     * @throws Exception If condition operations fail
     */
    @TestVisible
    private void upsertMedicalConditions() {
        
        if(!manager.newMembersMapMedicalConditionsToInsert.isEmpty()) {
            try {
                for (String fakeId : manager.newMembersMapMedicalConditionsToInsert.keySet()) {
                    Id censusId = manager.censusMemberByTemporalId.containsKey(fakeId) ? manager.censusMemberByTemporalId.get(fakeId).Id : null;
                    Id accountId = manager.censusMemberToAccount.containsKey(censusId) ? manager.censusMemberToAccount.get(censusId).Id : null;

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
                System.debug('Exception while upserting newMembersMapMedicalConditionsToInsert: ' + e.getMessage() + e.getStackTraceString());
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
            } catch (Exception e) {
                System.debug('Exception while upserting medical conditions: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Processes consumer drug records.
     * This method:
     * 1. Creates drug records
     * 2. Links drugs to members
     * 3. Updates drug status
     * 4. Maintains drug relationships
     * 
     * @throws Exception If drug operations fail
     */
    @TestVisible
    private void upsertConsumerDrugs() {

        if(!manager.NewMembersMapConsumerDrugsToInsert.isEmpty()) {
            try {
                for (String fakeId : manager.NewMembersMapConsumerDrugsToInsert.keySet()) {
                    Id censusId = manager.censusMemberByTemporalId.containsKey(fakeId) ? manager.censusMemberByTemporalId.get(fakeId).Id : null;
                    Id accountId = manager.censusMemberToAccount.containsKey(censusId) ? manager.censusMemberToAccount.get(censusId).Id : null;
                    
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
                System.debug('Exception while upserting NewMembersMapConsumerDrugsToInsert: ' + e.getMessage() + e.getStackTraceString());
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
           } catch (Exception e) {
                System.debug('Exception while upserting consumer drugs: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Updates physician data for members.
     * This method:
     * 1. Updates physician information
     * 2. Links physicians to members
     * 3. Maintains physician relationships
     * 4. Updates related records
     * 
     * @throws Exception If physician data update fails
     */
    @TestVisible
    private void updatePhysicianMemberData() {
        if(!manager.physicianNewMemberDataToUpdate.isEmpty()) {
            try {
                for (String fakeId : manager.physicianNewMemberDataToUpdate.keySet()) {
                    Id censusId = manager.censusMemberByTemporalId.containsKey(fakeId) ? manager.censusMemberByTemporalId.get(fakeId).Id : null;
                    Id accountId = manager.censusMemberToAccount.containsKey(censusId) ? manager.censusMemberToAccount.get(censusId).Id : null;

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
                System.debug('Exception while upserting updatePhysicianMemberData: ' + e.getMessage() + e.getStackTraceString());
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
            } catch (Exception e) {
                System.debug('Exception while updateing physician account data: ' + e.getMessage() + e.getStackTraceString());
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
            } catch (Exception e) {
                System.debug('Exception while updateing physician census member data: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Processes program change cases.
     * This method:
     * 1. Creates program change cases
     * 2. Links cases to contracts
     * 3. Sets case status and details
     * 4. Maintains case relationships
     * 
     * @throws Exception If case operations fail
     */
    @TestVisible
    private void upsertCasesPC() {
        if (!manager.casesPCToInsert.isEmpty()) {
            try {

                if(!manager.FakeIdToCasePc.values().isEmpty()) {
                    for (String key : manager.FakeIdToCasePc.keySet()) {
                        Case caseFee = manager.FakeIdToCasePc.get(key);
                        if (key.startsWith('MEM-')) {
                            caseFee.AccountId = manager.censusMemberToAccount.get(manager.censusMemberByTemporalId.get(key).Id).Id;
                            caseFee.ARC_PersonAccount__c = manager.censusMemberToAccount.get(manager.censusMemberByTemporalId.get(key).Id).Id;
                            manager.casesPCToInsert = manager.FakeIdToCasePc.values();
                        }
                    }
                    
                }

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
                System.debug('Exception while upserting PC cases: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

  

    /**
    * @Description: Inserts a new Policy for the new Contract, including its Insurance Policy Participants, Insurance Policy Coverage and Coverage Participants
    */
    @TestVisible
    private void insertPolicy() {
        try {
            Set<Id> contractIds = manager.allInsertedRecords.get('Contract').keySet();
            Id newContractId = new List<Id>(contractIds)[0];
            Map<String, Object> inputMap = new Map<String, Object>();
            Map<String, Object> outMap = new Map<String, Object>();

            Map<String,Object> contactOrFakeIdToBeneficiaries = manager.contactOrFakeIdToBeneficiaries; // Map with beneficiaries per member mapped in PCMapper
            Map<String,Object> beneficiariesMap = new Map<String,Object>(); // Map with beneficiaries per member to be sent to ARC_PolicyCreation
            // Replace the fake Id with contact Id
            for (String key : contactOrFakeIdToBeneficiaries.keySet()) {
                vlocity_ins__GroupCensusMember__c newCM = manager.censusMemberByTemporalId.containsKey(key) && manager.censusMemberByTemporalId.get(key) != null ? manager.censusMemberByTemporalId.get(key) : new vlocity_ins__GroupCensusMember__c();
                beneficiariesMap.put(key.startsWith('MEM-') ? newCM.vlocity_ins__ContactId__c : key, contactOrFakeIdToBeneficiaries.get(key));
            }
            inputMap.put('contactIdToBeneficiaries', beneficiariesMap);
            inputMap.put('contractId', newContractId);
            ARC_PolicyCreation.createAllPolicyRecords(inputMap, outMap);
        } catch (Exception e) {
            System.debug('Exception while inserting policy: ' + e.getMessage() + e.getStackTraceString() );
            System.debug(manager.allInsertedRecords.get('Contract').keySet());
            throw e;
        }
    }
    /**
     * @Description: Updated the Medicare information of the person account
    */
    @TestVisible
    private void updateLegacyAccount(){
        try {
            if (manager.legacyAccountToUpdate != null) {
                List<Account> legacyAccountList = new List<Account>();
                legacyAccountList.add(manager.legacyAccountToUpdate);
                Database.UpsertResult[] results = Database.upsert(legacyAccountList, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error updating Legacy person account: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('legacyPersonAccount')) {
                            manager.allInsertedRecords.put('legacyPersonAccount', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('legacyPersonAccount').put(result.getId(), legacyAccountList[i]);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Exception while updating legacy person account: ' + e.getMessage() + e.getStackTraceString() );
            throw e;
        }
        
        try {
            if (manager.allInsertedRecords.containsKey('AgeUps') && manager.allInsertedRecords.get('AgeUps') != null) {

                Map<Id,SObject> ageUpsMap = manager.allInsertedRecords.get('AgeUps');
                List<Ages_Up__c> ageUpsList = new List<Ages_Up__c>();

                for (SObject sobj : ageUpsMap.values()) {
                    ageUpsList.add((Ages_Up__c)sobj);
                }

                if (!ageUpsList.isEmpty()) {
                    System.debug('ageUpsList ' + ageUpsList);
                    ARC_AgeUpPriceCalculationQueable ageUpPriceCalculationQueable = new ARC_AgeUpPriceCalculationQueable(ageUpsList);
                    System.enqueueJob(ageUpPriceCalculationQueable);
                }

            }
        } catch (Exception e) {
            System.debug('Exception while calculating age up prices: ' + e.getMessage() + e.getStackTraceString() );
            throw e;
        }
    }

    ///////////////////////
    ///////////////////////

    /**
    * @Description: Creates a new Person Account record with required fields
    * @param LastName The last name for the account
    * @return Account The newly created account record 
    */
    private Account createPersonAccount(String LastName) {
        Account newPA = new Account();
        newPA.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        newPA.LastName = LastName;
        newPA.ARC_Census__c = manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;
        return newPA;        
    }

/**
 * @Description: Updates OS Instances 'Resume -> Completed'.
 * This method:
 * 1. Retrieves the Account Id from the input parameters.
 * 2. Queries all OmniScript Instances related to that Account that are in 'Resume' status.
 * 3. Updates their ARC_ResumeStatus__c field to 'Completed'.
 * 4. Performs a bulk DML update (Database.update) using the same pattern
 *    as other DML operations in the class, capturing any errors and storing successful
 *    updates in manager.allInsertedRecords.
 * 5. Handles any exceptions during the update process and logs relevant information.
 */
    private void completeOmniScriptInstancesForAccountContext() {
        Id accountId = (Id) manager.inputMap.get('ContextId');
        if (accountId == null) {
            return;
        }

        List<vlocity_ins__OmniScriptInstance__c> toUpdate = [SELECT Id, ARC_ResumeStatus__c FROM 
        vlocity_ins__OmniScriptInstance__c 
        WHERE vlocity_ins__ObjectId__c = :accountId 
        AND (ARC_ResumeStatus__c = 'Resume' OR ARC_ResumeStatus__c = null OR ARC_ResumeStatus__c = '')];

        if (toUpdate.isEmpty()) {
            System.debug('No OmniScript instances in Resume for Account ' + accountId);
            return;
        }

        for (vlocity_ins__OmniScriptInstance__c os : toUpdate) {
            os.ARC_ResumeStatus__c = 'Completed';
        }

        try {
            Database.SaveResult[] results = Database.update(toUpdate, true);

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results[i];
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error completing OmniScript instance ' + toUpdate[i].Id + ': ' + error.getMessage());
                    }
                } else {
                    if (!manager.allInsertedRecords.containsKey('OmniScriptInstance')) {
                        manager.allInsertedRecords.put('OmniScriptInstance', new Map<Id, SObject>());
                    }
                    manager.allInsertedRecords.get('OmniScriptInstance').put(result.getId(), toUpdate[i]);
                }
            }
        } catch (Exception e) {
            System.debug('Exception while completing OmniScript instances: ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
    * @Description: Updates census member records with contact IDs.
    * This method:
    * 1. Links census members to contacts
    * 2. Updates member information
    * 3. Maintains record relationships
    * 4. Ensures data consistency
    * 
    * @throws Exception If member casesUWToInsert fails
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

    /**
    * @Description: Updates Policy Participant records for newborn members.
    */
    private void updatePolicyParticipantForNewborns(){
        List<InsurancePolicyParticipant> policyParticipantsToUpdate = new List<InsurancePolicyParticipant>();
        policyParticipantsToUpdate.addAll(manager.policyParticipantToUpdate);
        if(!policyParticipantsToUpdate.isEmpty()){
            update policyParticipantsToUpdate;
        }
    }

    @future
    public static void handleDemographicChangeFuture(List<Id> censusMemberIds, String jsonCensusMembers,String fullJson,Id contextId) {
        List<vlocity_ins__GroupCensusMember__c> censusMembersDemographicChange = (List<vlocity_ins__GroupCensusMember__c>)JSON.deserialize(jsonCensusMembers, List<vlocity_ins__GroupCensusMember__c>.class);
        
        try {                   
            List<Database.UpsertResult> results = Database.upsert(censusMembersDemographicChange, true); 
            
            // Note: We can't update the manager.allInsertedRecords here since this is a future context
            // The calling code will need to handle this differently
                     
        } catch (Exception e) {
            System.debug('Exception while upserting census members in future context: ' + e.getMessage() + e.getStackTraceString());


            Integer MAX_FIELD_SIZE = 131072;

            String serializedData = fullJson;
            Custom_Logs__c log = new Custom_Logs__c();
            log.Name = 'Exception while upserting census members in future context';
            log.Account__c = contextId;
            log.OwnerId = UserInfo.getUserId();
            log.Status__c = 'New';
            
            if(serializedData != null && serializedData.length() > MAX_FIELD_SIZE) {
                log.Log__c = serializedData.substring(0, MAX_FIELD_SIZE);
                if(serializedData.length() > MAX_FIELD_SIZE) {
                    Integer remainingLength = Math.min(serializedData.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                    log.Log_2__c = serializedData.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                }
            } else if(serializedData != null) {
                log.Log__c = serializedData;
            }
            else {
                log.Log__c = 'No serialized data available';
            }
            try {
                insert log;
            } catch (Exception logException) {
                System.debug('Failed to insert log record: ' + logException.getMessage());
            }
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail; 
            String inputDataString = JSON.serialize(fullJson);
            String emailBody = 'Error in ARC_PCDML.cls handleDemographicChangeFuture: ' +e.getLineNumber()+' - '+ e.getMessage() + 
                                '\n\nInput Data: ' + inputDataString + 
                                '\n\nStack Trace: ' + e.getStackTraceString();
            ARC_QueableSendFileBatch.sendEmailNotification(emailBody, 'ERROR in DML while running future method ', apexErrorEmail);
            //
            //throw e;
        }
    }
}