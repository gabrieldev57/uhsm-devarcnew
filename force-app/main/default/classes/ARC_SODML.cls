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
public with sharing class ARC_SODML {
    private ARC_SOManager manager;
    

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
    public void manageDML(ARC_SOManager manager) {
        this.manager = manager;
        Set<String> operations = new Set<String>();
        Set<String> actionsToPerform = manager.actionsToPerform;        
        
        // Determine required operations based on action type
        for(String action : actionsToPerform){
            switch on action {
                when 'ancillaryChange' {
                    
                }
                when 'removeMember' {
                    
                }
                when 'addMember' {                           
                }
                when 'agingOut' {
                    
                }
                when 'programDowngrade' {
                    
                }
                when 'programUpgrade' {                 
                    
                }
                when 'spinOff' {     
                    operations.add('insertGroupAccounts');                    
                    operations.add('insertCensusGroups');                    
                    operations.add('insertPersonAccounts');
                    operations.add('insertCensusMembers');
                    operations.add('insertGuardians');
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');
                    operations.add('insertContractParticipants');
                    operations.add('insertChargentOrders');
                    operations.add('insertHipaaAuthorization');
                    operations.add('upsertMedicalConditions');                    
                    operations.add('upsertConsumerDrugs');                    
                    operations.add('updatePhysicianMemberData');                     
                    operations.add('upsertUWCaseAndMembers');  
                    operations.add('insertCasesPC');                   
                    operations.add('insertPolicy');
                    //Always execute 'sendNotificationEmail' LAST
                    operations.add('sendNotificationEmail');  
                }
                when 'multiSpinOff' {
                  
                    operations.add('insertGroupAccounts');                     
                    operations.add('insertCensusGroups');
                    operations.add('insertCensusMembers'); 
                    operations.add('insertContracts');
                    operations.add('insertContractLineItems');
                    operations.add('insertGroupCensusMemberPlans');        
                    operations.add('insertChargentOrders');
                    operations.add('insertContractParticipants');
                    operations.add('upsertUWCaseAndMembers');
                    operations.add('insertPolicy');
                    operations.add('sendNotificationEmail');        
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
        for(String operation : operations){
            switch on operation {
                when 'insertGroupAccounts' {
                    try{
                        insertAccounts('groupAccountsToInsert');
                        
                    }
                    catch(Exception e){
                        System.debug('Exception while upserting personAccounts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'insertCensusGroups' {
                    try{
                        insertCensusGroups();
                    }
                    catch(Exception e){
                        System.debug('Exception while upserting census groups: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'insertCensusMembers' {
                    try{
                        insertCensusMembers();
                    }
                    catch(Exception e){
                        System.debug('Exception while upserting census members: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'insertPersonAccounts' {
                    try{
                        insertAccounts('personAccountsToInsert');
                    }
                    catch(Exception e){
                        System.debug('Exception while upserting person accounts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'insertContracts' {
                    try{
                        insertContracts();
                    }
                    catch(Exception e){
                        System.debug('Exception while inserting contracts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'insertGuardians' {
                    try{
                        insertGuardians();
                    }
                    catch(Exception e){
                        System.debug('Exception while inserting guardians: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'insertContractLineItems' {
                    try{
                        insertContractLineItems();
                    }
                    catch(Exception e){
                        System.debug('Exception while inserting contract line items: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'insertGroupCensusMemberPlans' {
                    try{
                        insertGroupCensusMemberPlans();
                    }
                    catch(Exception e){
                        System.debug('Exception while inserting group census member plans: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'insertContractParticipants' {
                    try {
                        upsertContractParticipants();
                    } catch (Exception e) {
                        System.debug('Exception while upserting contract participants: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'insertChargentOrders' {
                    try {
                        upsertChargentOrders();
                    } catch (Exception e) {
                        System.debug('Exception while upserting chargent orders: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'upsertMedicalConditions' {
                    try{
                        upsertMedicalConditions();
                    }
                    catch(Exception e){
                        System.debug('Exception while upsert Medical Conditions: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'upsertConsumerDrugs' {
                    try{
                        upsertConsumerDrugs();
                    }
                    catch(Exception e){
                        System.debug('Exception while upsert Consumer Drugs: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }
                when 'updatePhysicianMemberData' {
                    try{
                        updatePhysicianMemberData();
                    }
                    catch(Exception e){
                        System.debug('Exception while update Physician Member Data: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                    }
                }   
                when 'insertHipaaAuthorization'{
                    try {
                        upsertHipaaAuthorizations();
                    } catch (Exception e) {
                        System.debug('error in DML hipaa' + e.getMessage() + e.getStackTraceString());
                    }
                }
                when 'upsertUWCaseAndMembers'{
                    try {
                        upsertUWCaseAndMembers();
                    } catch (Exception e) {
                        System.debug('error in DML UWCaseAndMembers' + e.getMessage() + e.getStackTraceString());
                    }
                }
                when 'insertCasesPC' {
                    try {
                        upsertCasesPC();
                    } catch (Exception e) {
                        System.debug('Exception while upserting PC cases: ' + e.getMessage() + e.getStackTraceString());
                    }
                }
                when 'insertPolicy' {
                    try {
                        insertPolicy();
                    } catch (Exception e) {
                        System.debug('Exception while inserting Policys: ' + e.getMessage() + e.getStackTraceString());
                    }
                }
                when 'sendNotificationEmail' {
                    try {
                        Object inputDataObj = manager.inputMap.get('inputData');       
                        String fullJson;

                    if (inputDataObj != null) {
                        fullJson = String.valueOf(inputDataObj);
                    } else {
                        // Use complete inputMap if inputData dont exist
                        fullJson = JSON.serialize(manager.inputMap);
                    }
        
                        sendSpinOffNotificationEmail(fullJson);
                    } catch (Exception e) {
                        System.debug('Exception while sending notification email: ' + e.getMessage() + e.getStackTraceString());
                        throw e;
                        
                    }
                }
            }
        }        
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
    private void insertAccounts(String action) {
        if(action == 'groupAccountsToInsert'){
            if (!manager.groupAccountsToInsertMap.isEmpty()) {
                try {                    
                    Database.UpsertResult[] results = Database.upsert(manager.groupAccountsToInsertMap.values(), true);
                    if(results.size() > 0){
                        for (Integer index = 1; index < results.size(); index++) {
                            Database.UpsertResult result = results[index];
                            if (result.isSuccess()) {
                                System.debug('insertAccountsId: ' + manager.groupAccountsToInsertMap.get(index).Id);  
                            }
                        }
                    }
                } 
                catch (Exception e) {
                    System.debug('Exception while upserting accounts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                } 
            }
        }
        else if(action == 'personAccountsToInsert'){
            if(!manager.personAccountsToInsertMap.isEmpty()){
                List<Account> personAccountsToUpsert = new List<Account>();
                Map<Account, Integer> accountToFamilyIndexMap = new Map<Account, Integer>();
                try{
                    Database.UpsertResult[] results = Database.upsert(manager.fictionalMemberIdToPersonAccount.values(), true);
                    for (Account acc : manager.fictionalMemberIdToPersonAccount.values()) {
                        System.debug('insertAccounts manager.fictionalMemberIdToPersonAccount.get(acc.Id): ' + acc.Id);
                    }
                }
                catch(Exception e){
                    System.debug('Exception while upserting person accounts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                }
            }
        }
    }

   /**
     * @Description: Inserts census groups
     * This method:
     * 1. Inserts census groups
     * 
     * @throws Exception If census groups insertion fails
     */
    private void insertCensusGroups() { 
        if(!manager.groupCensusToFictionalId.isEmpty()) {
            Map<vlocity_ins__GroupCensus__c,List<String>> groupCensusToFictionalIdTransformed = new Map<vlocity_ins__GroupCensus__c,List<String>>();
            Map<List<String>,vlocity_ins__GroupCensus__c> groupCensusListToUpsert = new Map<List<String>,vlocity_ins__GroupCensus__c>();
            
            Integer familyIndex = 1;
            for(vlocity_ins__GroupCensus__c groupCensus : manager.groupCensusToFictionalId.keySet()){
                vlocity_ins__GroupCensus__c groupCensusTransformed = new vlocity_ins__GroupCensus__c();
                groupCensusTransformed.vlocity_ins__GroupId__c = manager.groupAccountsToInsertMap.get(familyIndex).Id;
                groupCensusTransformed.Name = groupCensus.Name;
                groupCensusTransformed.ARC_PrimaryAccount__c = groupCensus.ARC_PrimaryAccount__c;
                groupCensusToFictionalIdTransformed.put(groupCensusTransformed, manager.groupCensusToFictionalId.get(groupCensus));
                familyIndex++;
            }
            for(vlocity_ins__GroupCensus__c groupCensusTransformed : groupCensusToFictionalIdTransformed.keySet()){
                List<String> fictionalIds = groupCensusToFictionalIdTransformed.get(groupCensusTransformed);                
                if(fictionalIds != null && !fictionalIds.isEmpty()) {
                    groupCensusListToUpsert.put(fictionalIds, groupCensusTransformed);
                }
            }            
            try {
                Database.UpsertResult[] results = Database.upsert(groupCensusListToUpsert.values(), true);
                Map<vlocity_ins__GroupCensus__c,List<String>> auxiliaryGroupCensusToFictionalId = new Map<vlocity_ins__GroupCensus__c,List<String>>();
                for(List<String> fictionalIds : groupCensusListToUpsert.keySet()){                    
                    for (vlocity_ins__GroupCensus__c groupCensus : manager.groupCensusToFictionalId.keySet()){
                        if(fictionalIds == manager.groupCensusToFictionalId.get(groupCensus)){
                            auxiliaryGroupCensusToFictionalId.put(groupCensusListToUpsert.get(fictionalIds),fictionalIds);
                        }                        
                    }
                }
                manager.groupCensusToFictionalId = auxiliaryGroupCensusToFictionalId;
                for(Integer i = 0; i < results.size(); i++){
                    Database.UpsertResult result = results[i];
                    if(result.isSuccess()){
                        System.debug('insertCensusGroupsId: ' + result.getId());
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting census groups: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /** 
    * @Description: Inserts census members
    * @throws Exception if census members insertion fails
    */ 
    private void insertCensusMembers() {        
        if (!manager.fictionalMemberIdToGCM.isEmpty()) {
            try {
                manager.fictionalMemberIdToGCMListToUpsert = mapGroupCensusMembers(manager.fictionalMemberIdToGCM, manager.groupCensusToFictionalId, manager.fictionalMemberIdToPersonAccount);
                
                List<vlocity_ins__GroupCensusMember__c> gcmListToUpsertList = new List<vlocity_ins__GroupCensusMember__c>();
                
                if(!manager.fictionalMemberIdToGCMListToUpsert.isEmpty()){
                    for(String fictionalId : manager.fictionalMemberIdToGCMListToUpsert.keySet()){
                        gcmListToUpsertList.add(manager.fictionalMemberIdToGCMListToUpsert.get(fictionalId));                                                                                     
                    }
                }
                Database.SaveResult[] results = Database.insert(manager.fictionalMemberIdToGCMListToUpsert.values(), true);

                List<vlocity_ins__GroupCensusMember__c> gcmListToUpdateNewMember = new List<vlocity_ins__GroupCensusMember__c>();

                for(String gcm : manager.fictionalMemberIdToGCMListToUpsert.keySet()){                    
                    if(manager.fictionalMemberIdToGCMListToUpsert.get(gcm).ARC_OldCensusMember__c != null){ 
                        vlocity_ins__GroupCensusMember__c gcmToUpdate = new vlocity_ins__GroupCensusMember__c();
                        gcmToUpdate.Id = manager.fictionalMemberIdToGCMListToUpsert.get(gcm).ARC_OldCensusMember__c;
                        gcmToUpdate.ARC_NewCensusMember__c = manager.fictionalMemberIdToGCMListToUpsert.get(gcm).Id;
                        gcmListToUpdateNewMember.add(gcmToUpdate);
                    }
                }
                Database.SaveResult[] updateResults = Database.update(gcmListToUpdateNewMember, true);
                //This block is for populating the related Census memebr but will be handled by the flow Handler_PC_Contract_Activation
                /*
                Set<vlocity_ins__GroupCensusMember__c> gcmToUpdateSet = new Set<vlocity_ins__GroupCensusMember__c>();
                System.debug('insertCensusMembers 0 2 manager.fictionalMemberIdToGCM: ' + manager.groupCensusToFictionalId.keySet());
                for(vlocity_ins__GroupCensus__c gC : manager.groupCensusToFictionalId.keySet()){
                    System.debug('insertCensusMembers 1 gC: ' + gC);
                    Id primaryMemberId = null;
                    vlocity_ins__GroupCensusMember__c primaryMember = null;
                    for(String fictionalId : manager.groupCensusToFictionalId.get(gC)){
                        System.debug('insertCensusMembers 2 fictionalId: ' + fictionalId);
                        vlocity_ins__GroupCensusMember__c gcm = manager.fictionalMemberIdToGCMListToUpsert.get(fictionalId);
                        if(gcm.vlocity_ins__IsPrimaryMember__c == true){
                            System.debug('insertCensusMembers 3 gcm.Id: ' + gcm.Id);
                            primaryMemberId = gcm.Id;
                            primaryMember = gcm;
                        }
                    }
                    for(String fictionalId : manager.groupCensusToFictionalId.get(gC)){
                        vlocity_ins__GroupCensusMember__c gcmtoUpdate = manager.fictionalMemberIdToGCMListToUpsert.get(fictionalId);                        
                        if(gcmtoUpdate.vlocity_ins__IsPrimaryMember__c == false){
                            System.debug('insertCensusMembers 4 gcmtoUpdate.ARC_ActiveMember__c: ' + gcmtoUpdate.ARC_ActiveMember__c);
                            gcmtoUpdate.vlocity_ins__RelatedCensusMemberId__c = primaryMember.Id;
                            gcmToUpdateSet.add(gcmtoUpdate);
                        }                        
                    }
                }

                List<vlocity_ins__GroupCensusMember__c> gcmListToUpdate = new List<vlocity_ins__GroupCensusMember__c>();
                System.debug('insertCensusMembers 7 gcmToUpdateSet: ' + gcmToUpdateSet);
                gcmListToUpdate.addAll(gcmToUpdateSet);
                for(vlocity_ins__GroupCensusMember__c gcm : gcmListToUpdate){
                    System.debug('insertCensusMembers 8 gcm: ' + gcm.vlocity_ins__RelatedCensusMemberId__c);
                }
                Database.SaveResult[] updateResults = Database.update(gcmListToUpdate, true);      
                */
            } catch (Exception e) {
                System.debug('Exception while upserting Group Census Members: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
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
    private void insertGuardians() {
        Id censusId = null;
        for (vlocity_ins__GroupCensus__c groupCensus : manager.groupCensusToFictionalId.keySet()) {
            censusId = groupCensus.Id;      
        }
        if (!manager.guardiansToInsert.isEmpty()) {
            try {
                manager.guardiansToInsert[0].ARC_Census__c = censusId;
                Database.UpsertResult[] results = Database.upsert(manager.guardiansToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting guardian: ' + error.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while inserting guardian: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
        /*
        try {
            if (manager.allInsertedRecords.containsKey('Guardian')) {
                //Get census Id
                vlocity_ins__GroupCensus__c updatedCensus = new vlocity_ins__GroupCensus__c();
                updatedCensus.Id = manager.inputMap.containsKey('CensusId') ? (Id)manager.inputMap.get('CensusId') : null;

                // Get Guardian Id
                Map<Id, sObject> guardians = manager.allInsertedRecords.get('Guardian');
                Set<Id> guardiansIds = guardians.KeySet();
                Id guardianId = new List<Id>(guardiansIds)[0];
                
                updatedCensus.ARC_GuardianAccount__c = guardianId;
            
                update updatedCensus;
            }
        }
        catch (Exception e) {
            System.debug('Exception while updating contract: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
        */
    }

    /**
     * @Description: Handles contract record creation and updates.
     * @throws Exception If contract operations fail
     */
    private void insertContracts() {
        try{
            for (Integer familyIndex : manager.contractsToInsertMap.keySet()) {
                Contract contract = manager.contractsToInsertMap.get(familyIndex);
                System.debug('insertContracts contract: '+ familyIndex + ' ' + contract.Id + 'Expired Contract Id: ' + contract.vlocity_ins__ExpiredContractId__c);
                List<Map<String, Object>> membersInGroup = (List<Map<String, Object>>)manager.censusMembersMap.get(familyIndex);
                for (Map<String, Object> member : membersInGroup) {
                    manager.fictionalMemberIdToContract.put((String)member.get('Id'), contract);
                }
                if (familyIndex == 0) {
                    manager.removeMemberContract = contract;
                } else if (familyIndex == 1) {
                    manager.singleSpinOffContract = contract;
                }
                if (familyIndex != 0 && contract.AccountId == null && contract.vlocity_ins__EnrollmentCensusId__c == null) {
                    contract.AccountId = manager.groupAccountsToInsertMap.get(familyIndex).Id;
                    contract.Account_Name_Text__c = manager.groupAccountsToInsertMap.get(familyIndex).Name;
                    Id censusId;
                    String fictionalMemberId = (String)membersInGroup[0].get('Id');
                    for (vlocity_ins__GroupCensus__c gc : manager.groupCensusToFictionalId.keySet()) {
                        List<String> memberIds = manager.groupCensusToFictionalId.get(gc);
                        if (memberIds != null && memberIds.contains(fictionalMemberId)) {
                            censusId = gc.Id;
                            break;
                        }
                    }
                    contract.vlocity_ins__EnrollmentCensusId__c = censusId;
                    if (!manager.guardiansToInsert.isEmpty()) {
                        contract.ARC_Guardian__c = manager.guardiansToInsert[0].Id;
                    }
                }
            }
            if (!manager.contractsToInsertMap.isEmpty()) {
                try {
                    Database.UpsertResult[] results = Database.upsert(manager.contractsToInsertMap.values(), true);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results[i];
                        if (!result.isSuccess()) {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting contract: ' + error.getMessage());
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('Exception while inserting contracts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                }
            }
            if (!manager.contractsToVoid.isEmpty()) {  
                try {
                    Database.UpsertResult[] results = Database.upsert(manager.contractsToVoid, true);
                }
                catch (Exception e) {
                    System.debug('Exception while voiding contracts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                }
            }
        }
        catch (Exception e) {
            System.debug('Exception while upserting contracts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
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
    private void insertContractLineItems() {
        Map<String, vlocity_ins__ContractLineItem__c> mapAllParentCLI = new Map<String, vlocity_ins__ContractLineItem__c>();
        List<vlocity_ins__ContractLineItem__c> listAllParentCLI = new List<vlocity_ins__ContractLineItem__c>();
        List<vlocity_ins__ContractLineItem__c> listAllChildCLI = new List<vlocity_ins__ContractLineItem__c>();
        // Assign CLI to Contract
        for (Integer familyIndex = 0; familyIndex < 2; familyIndex++) {
            Id newContractId;
            if (familyIndex == 0) {
                newContractId = manager.removeMemberContract.Id;
            } else if (familyIndex == 1) {
                newContractId = manager.singleSpinOffContract.Id;
            }
            if (manager.indexToParentCLI.containsKey(familyIndex)
                && !manager.indexToParentCLI.get(familyIndex).isEmpty() 
                && manager.indexToChildCLI.containsKey(familyIndex)
                && !manager.indexToChildCLI.get(familyIndex).isEmpty()
            ) {
                for (Integer index : manager.indexToParentCLI.get(familyIndex).keySet()) {
                    manager.indexToParentCLI.get(familyIndex).get(index).vlocity_ins__ContractId__c = newContractId;
                    String mapAllParentCLIKey = familyIndex + '-' + index;
                    mapAllParentCLI.put(mapAllParentCLIKey, manager.indexToParentCLI.get(familyIndex).get(index));
                    listAllParentCLI.add(manager.indexToParentCLI.get(familyIndex).get(index));
                }
                for (Integer index : manager.indexToChildCLI.get(familyIndex).keySet()) {
                    for (vlocity_ins__ContractLineItem__c childCLI : manager.indexToChildCLI.get(familyIndex).get(index)) {    
                        childCLI.vlocity_ins__ContractId__c = newContractId;
                    }
                }
            }
        }

        // Upsert CLI Parent
        Database.UpsertResult[] results = Database.upsert(listAllParentCLI, true);
        for (Integer i = 0; i < results.size(); i++) {
            Database.UpsertResult result = results[i];
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    System.debug('Error upserting contract line item: ' + error.getMessage());
                }
            } else {
                vlocity_ins__ContractLineItem__c parentCLI = listAllParentCLI[i];
                for (String key : mapAllParentCLI.keySet()) {
                    if (mapAllParentCLI.get(key) == parentCLI) {
                        List<String> keyParts = key.split('-');
                        Integer familyIndex = Integer.valueOf(keyParts[0]);
                        Integer index = Integer.valueOf(keyParts[1]);
                        for (vlocity_ins__ContractLineItem__c childCLI : manager.indexToChildCLI.get(familyIndex).get(index)) {
                            childCLI.vlocity_ins__ParentItemId__c = result.getId();
                            listAllChildCLI.add(childCLI);
                        }
                        break;
                    }
                }
            }
        }
        
        // Upsert CLI Child
        Database.UpsertResult[] resultsChild = Database.upsert(listAllChildCLI, true);
        for (Integer i = 0; i < resultsChild.size(); i++) {
            Database.UpsertResult result = resultsChild[i];
            if (!result.isSuccess()) {
                for (Database.Error error : result.getErrors()) {
                    System.debug('Error upserting contract line item: ' + error.getMessage());
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
    private void insertGroupCensusMemberPlans() {
        if (!manager.indexToParentCLI.isEmpty() && !manager.indexToCLIGCM.isEmpty()) {
            try {
                List<vlocity_ins__GroupCensusMemberPlan__c> gcmpListToInsert = new List<vlocity_ins__GroupCensusMemberPlan__c> ();
                for (Integer familyIndex : manager.indexToParentCLI.keySet()) {
                    if (!manager.indexToCLIGCM.containsKey(familyIndex)) continue;
                    for (Integer index : manager.indexToParentCLI.get(familyIndex).keySet()) {
                        for (String gcmId : manager.indexToCLIGCM.get(familyIndex).get(index)) {
                            String censusMemberId;
                            if (familyIndex == 0) {
                                censusMemberId = gcmId;
                            } else {
                                censusMemberId = manager.fictionalMemberIdToGCMListToUpsert.containsKey(gcmId) ? manager.fictionalMemberIdToGCMListToUpsert.get(gcmId).Id : null;
                            }
                            vlocity_ins__GroupCensusMemberPlan__c newGCMP = new vlocity_ins__GroupCensusMemberPlan__c();
                            newGCMP.Name = manager.indexToParentCLI.get(familyIndex).get(index)?.Name;
                            newGCMP.vlocity_ins__GroupCensusMemberId__c = censusMemberId;
                            newGCMP.vlocity_ins__ContractLineId__c = manager.indexToParentCLI.get(familyIndex).get(index).Id;
                            gcmpListToInsert.add(newGCMP);
                            if (!manager.fictionalMemberIdToGCMP.containsKey(gcmId)) {
                                manager.fictionalMemberIdToGCMP.put(gcmId, new List<vlocity_ins__GroupCensusMemberPlan__c>());
                            }
                            manager.fictionalMemberIdToGCMP.get(gcmId).add(newGCMP);
                        }                    
                    }
                }
                if (!gcmpListToInsert.isEmpty()) {
                    Database.UpsertResult[] results = Database.upsert(gcmpListToInsert, true);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results[i];
                        if (!result.isSuccess()) {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting group census member plan: ' + error.getMessage());
                            }
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting group census member plans: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
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
        if (!manager.fictionalMemberIdToContractParticipant.values().isEmpty()) {
            try {
                for (String censusMemberId : manager.fictionalMemberIdToContractParticipant.keySet()) {
                    ARC_ContractParticipant__c contractParticipant = manager.fictionalMemberIdToContractParticipant.get(censusMemberId);
                    Contract familyMemberContract = manager.fictionalMemberIdToContract.get(censusMemberId); 
                    contractParticipant.ARC_Contract__c = familyMemberContract.Id;

                    // Update of Person Account ID
                    if (censusMemberId.startsWith('MEM-')) {
                        Account newPersonAccount = manager.fictionalMemberIdToPersonAccount.get(censusMemberId);
                        contractParticipant.ARC_PersonAccount__c = newPersonAccount.Id;
                    }
                }
                Database.UpsertResult[] results = Database.upsert(manager.fictionalMemberIdToContractParticipant.values(), true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract participant: ' + error.getMessage());
                        }
                    }
                    else {
                        System.debug('Contract participant inserted: ' + manager.fictionalMemberIdToContractParticipant.values()[i].Id);
                    }
                }
            }
            catch (Exception e) {
                System.debug('Exception while upserting contract participants: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
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
        if (!manager.chargentOrdersToInsertMap.keySet().isEmpty()) {
            for (String chargentOrderType : manager.chargentOrdersToInsertMap.keySet()) {
                ChargentOrders__ChargentOrder__c chargentOrder = manager.chargentOrdersToInsertMap.get(chargentOrderType);
                if (chargentOrderType == 'recurringRemoveMemberChargent') {
                    //Populate the contract ID
                    chargentOrder.ARC_Contract__c = manager.removeMemberContract.Id;
                } 
                else if (chargentOrderType == 'recurringSpinOffChargent') {
                    // Get and populate group account if is empty
                    if (chargentOrder.ChargentOrders__Account__c == null && manager.groupAccountsToInsertMap.containsKey(1)) {
                        Account spinOffGroupAccount = manager.groupAccountsToInsertMap.get(1);
                        chargentOrder.ChargentOrders__Account__c = spinOffGroupAccount.Id;
                    }
                    // Populate the contract ID
                    chargentOrder.ARC_Contract__c = manager.singleSpinOffContract.Id;
                } 
                else if (chargentOrderType == 'changeFeeSpinOffChargent') {
                    // Get and populate group account if is empty
                    if (chargentOrder.ChargentOrders__Account__c == null && manager.groupAccountsToInsertMap.containsKey(1)) {
                        Account spinOffGroupAccount = manager.groupAccountsToInsertMap.get(1);
                        chargentOrder.ChargentOrders__Account__c = spinOffGroupAccount.Id;
                    }
                    // Populate the contract ID
                    chargentOrder.ARC_Contract__c = manager.singleSpinOffContract.Id;
                }
            }
        }


        try {
            Database.UpsertResult[] results = Database.upsert(manager.chargentOrdersToInsertMap.values(), true);
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult result = results[i];
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('Error upserting chargent order: ' + error.getMessage());
                    }
                } else {
                    System.debug(manager.chargentOrdersToInsertMap.values()[i].Id);
                }
            }                
        } catch (Exception e) {
            System.debug('Exception while upserting chargent orders: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @Description: Updates contract records with payment and case information.
     * This method:updateContractFieldGuardian
     * 1. Links payment orders to contracts
     * 2. Updates contract status
     * 3. Associates cases with contracts
     * 4. Maintains contract relationships
     * 
     * @throws Exception If contract update fails
     */
    private void updateContract(){
        /*
        try{
            //Get the fee order and the recurring order from the chargent orders
            ChargentOrders__ChargentOrder__c feeOrder = null;
            ChargentOrders__ChargentOrder__c recurringOrder = null;
            
            Set<Id> chargentOrderIds = manager.allInsertedRecords.get('ChargentOrder').keySet();
            for(Id coId : chargentOrderIds){
                ChargentOrders__ChargentOrder__c co = (ChargentOrders__ChargentOrder__c)manager.allInsertedRecords.get('ChargentOrder').get(coId);
                if(co.ChargentOrders__Payment_Frequency__c == 'Monthly'){
                    recurringOrder = (ChargentOrders__ChargentOrder__c)manager.allInsertedRecords.get('ChargentOrder').get(coId);
                }
                else{
                    feeOrder = (ChargentOrders__ChargentOrder__c)manager.allInsertedRecords.get('ChargentOrder').get(coId);
                }
            }

            //Get UW case Id
            Id newCaseId = null;
            if(manager.allInsertedRecords.containsKey('CaseUW')){   
                Map<Id, sObject> caseMap = manager.allInsertedRecords.get('CaseUW');
                Set<Id> caseIds = caseMap.keySet();
                newCaseId = new List<Id>(caseIds)[0];
            }
            
            //Get contract Id
            Set<Id> contractIds = manager.allInsertedRecords.get('Contract').keySet();
            Id newContractId = new List<Id>(contractIds)[0];
            Contract insertedContract = (Contract)manager.allInsertedRecords.get('Contract').get(newContractId);
            insertedContract.ARC_AppFeeOrder__c = feeOrder != null ? feeOrder.Id : null;
            insertedContract.ARC_RecurringMonthlyOrder__c = recurringOrder.Id;
            insertedContract.ARC_Case__c = newCaseId;
            insertedContract.Status = 'Awaiting Signature';

            update insertedContract;
        }
        catch(Exception e){
            System.debug('Exception while updating contract: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
        */
    }

    /**
     * @Description: Updates contract ARC_Guardian__c field 
     * This method:
     * 1. Links Guardian Id to contracts
     * 
     * @throws Exception If contract ARC_Guardian__c field update fails
     */
    private void updateContractFieldGuardian(){
        /*
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
            System.debug('Exception while updating contract: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
        }
        */
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
    private void upsertUWCaseAndMembers() {
        if (!manager.casesUWToInsert.isEmpty()) { 
            try {
                // Prepare UW Cases data
                Map<String, Case> listUWCases = new Map<String, Case>();

                if(manager.casesUWToInsert.containsKey('0')){
                    Id rcCensusMember;
                    Id rcPersonAccount;
                    // UW Case (Remove Member Contract)
                    for (Map<String,Object> member : manager.censusMembersRemoveContract) {
                        if (member != null && member.containsKey('ARC_Relationship__c') && (String)member.get('ARC_Relationship__c') == 'Primary') {
                            rcCensusMember = member.containsKey('Id') ? (String)member.get('Id') : null;
                            rcPersonAccount = member.containsKey('PersonAccountId') ? (String)member.get('PersonAccountId') : null;
                        }
                    }

                    Case uwCaseRC = manager.casesUWToInsert.get('0');
                    uwCaseRC.ARC_Contract__c = manager.removeMemberContract.Id; 
                    uwCaseRC.ARC_CensusMember__c = rcCensusMember != null ? rcCensusMember : null;
                    uwCaseRC.ARC_PersonAccount__c = rcPersonAccount != null ? rcPersonAccount : null;
                    listUWCases.put('0', uwCaseRC); // UW Case (Remove Member - Contract)
                }
                
                if(manager.casesUWToInsert.containsKey('1')){
                    // UW Case (Spin Off Contract)
                   
                    Set<Map<String,Object>> primaryList = manager.spinnedCensusMembersGroupedByPrimary.keySet();
                    List<Map<String,Object>> primaryListValues = new List<Map<String,Object>>();
                    String primaryId;
                    primaryListValues.addAll(primaryList);

                    if(primaryListValues.size() == 1){
                        primaryId = primaryListValues[0].containsKey('Id') ? (String)primaryListValues[0].get('Id') : null;                        
                    }

                    Id primaryPersonAccount = manager.fictionalMemberIdToPersonAccount.containsKey(primaryId) ? manager.fictionalMemberIdToPersonAccount.get(primaryId).Id : null;
                    Id primaryCensusMember = manager.fictionalMemberIdToGCMListToUpsert.containsKey(primaryId) ? manager.fictionalMemberIdToGCMListToUpsert.get(primaryId).Id : null;
                    
                    Case uwCaseSO = manager.casesUWToInsert.get('1');
                    uwCaseSO.ARC_Contract__c = manager.singleSpinOffContract.Id;
                    uwCaseSO.AccountId = manager.groupAccountsToInsertMap.containsKey(1) ? manager.groupAccountsToInsertMap.get(1).Id : null;
                    uwCaseSO.ARC_CensusMember__c = primaryCensusMember != null ? primaryCensusMember : null;
                    uwCaseSO.ARC_PersonAccount__c = primaryPersonAccount != null ? primaryPersonAccount : null;

                    listUWCases.put('1', uwCaseSO); // UW Case (Spin Off - Contract)
                }

                
                // Prepare UW Case Members data
                Map<String, List<ARC_UnderwritingCaseMember__c>> mapListUWCM = new Map<String, List<ARC_UnderwritingCaseMember__c>>();
                
                if(!manager.censusMemberIdOrFakeIdToUWCM_RC.isEmpty()){
                    // UW Case Members (Remove Member Contract)
                    List<ARC_UnderwritingCaseMember__c> listUWCM_RC = new  List<ARC_UnderwritingCaseMember__c>();
                    for (String key : manager.censusMemberIdOrFakeIdToUWCM_RC.keySet()) {
                        ARC_UnderwritingCaseMember__c rcUWCM = manager.censusMemberIdOrFakeIdToUWCM_RC.get(key);
                        rcUWCM.ARC_Member__c = key;
                        listUWCM_RC.add(rcUWCM);
                    }
                    mapListUWCM.put('0', listUWCM_RC);
                }

                if(!manager.censusMemberIdOrFakeIdToUWCM_SP.isEmpty()){
                    // UW Case Members (Spin-Off Contract)
                    List<ARC_UnderwritingCaseMember__c> listUWCM_SO = new  List<ARC_UnderwritingCaseMember__c>();
                    for (String key : manager.censusMemberIdOrFakeIdToUWCM_SP.keySet()) {
                        ARC_UnderwritingCaseMember__c spUWCM = manager.censusMemberIdOrFakeIdToUWCM_SP.get(key);
                        
                        if (key.startsWith('MEM-')) {
                            spUWCM.ARC_PersonAccount__c = manager.fictionalMemberIdToPersonAccount.containsKey(key) ? manager.fictionalMemberIdToPersonAccount.get(key).Id : null;
                            
                        } 
                        spUWCM.ARC_Member__c = manager.fictionalMemberIdToGCMListToUpsert.containsKey(key) ? manager.fictionalMemberIdToGCMListToUpsert.get(key).Id : null;
                        
                        listUWCM_SO.add(spUWCM);
                    }                    
                    mapListUWCM.put('1', listUWCM_SO);
                }

                

                // Get the necessary data for contract update
                Id contractIdRC = manager.removeMemberContract.Id; 
                Id contractIdSO = manager.singleSpinOffContract.Id;
                
                // Serialize all the data for future processing
                String jsonUWCase = JSON.serialize(listUWCases);
                String jsonUWCaseMembers = JSON.serialize(mapListUWCM);
                String fullJson = String.valueOf(manager.inputMap.get('inputData'));
                String chargentsMap =  JSON.serialize(manager.chargentOrdersToInsertMap);
                Id contextId = (Id)manager.inputMap.get('ContextId');

                String jsonPromotionDiscount = '';

                if(!manager.promotionDiscountToInsert.isEmpty()){
                    jsonPromotionDiscount = JSON.serialize(manager.promotionDiscountToInsert);
                }

                // Call the future method with all necessary data
                handleUWCaseAndMembersFuture(jsonUWCase, contractIdRC, contractIdSO, chargentsMap, jsonUWCaseMembers, fullJson, contextId,jsonPromotionDiscount);
                
            } catch (Exception e) {
                System.debug('Exception while preparing UW case for future processing: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    @future
    public static void handleUWCaseAndMembersFuture(String jsonUWCase,  Id contractIdRC, Id contractIdSO, String chargentsMap, String jsonUWCaseMembers,String fullJson,Id contextId,String jsonPromotionDiscount) {
        try {
            // Map UW Cases to upsert
            Map<String, Case> casesToUpsert = (Map<String, Case>)JSON.deserialize(jsonUWCase, Map<String, Case>.class);

            Map<String,ChargentOrders__ChargentOrder__c> chargentOrdersToInsertMap = (Map<String,ChargentOrders__ChargentOrder__c>)JSON.deserialize(chargentsMap, Map<String,ChargentOrders__ChargentOrder__c>.class);

            // Store the new UW Cases IDs for contract update and UW Case Members, ([0] UW Case Remove Member - Contract, [1] UW Case Spin Off - Contract)
            //List<Id> ListNewCaseId = new List<Id>();
            List<ARC_PromotionDiscount__c> promotionDiscounts = new List<ARC_PromotionDiscount__c>();
            if(jsonPromotionDiscount != null && jsonPromotionDiscount != ''){
                //Deserialize the promotion discount
                promotionDiscounts = (List<ARC_PromotionDiscount__c>)JSON.deserialize(jsonPromotionDiscount, List<ARC_PromotionDiscount__c>.class);
            }
            
            // try {
                // Process results and log any errors
                Database.UpsertResult[] resultsCases = Database.upsert(casesToUpsert.values(), true);
                for (Database.UpsertResult result : resultsCases) {
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting UW case in future context: ' + error.getMessage());
                        }
                    } 
                    // else {
                    //     ListNewCaseId.add(result.getId());
                    // }
                }
            // } catch (Exception e) {
            //     System.debug('Exception while processing UW Cases in future context: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            // }

            // try {
                // Update the contract with the new case and orders
                List<Contract> contractsToUpdate = new List<Contract>();
                if (contractIdRC != null) {  // (Remove Member - Contract)
                    Contract contractToUpdate = new Contract(
                        Id = contractIdRC,
                        ARC_RecurringMonthlyOrder__c = chargentOrdersToInsertMap.get('recurringRemoveMemberChargent').Id,
                        ARC_Case__c = casesToUpsert.containsKey('0') && casesToUpsert.get('0').Id != null ? casesToUpsert.get('0').Id : null,
                        Status = 'Awaiting Activation'
                    );
                    contractsToUpdate.add(contractToUpdate);
                }
    
                if (contractIdSO != null && casesToUpsert.containsKey('1') && casesToUpsert.get('1').Id != null) { // (Spin Off - Contract)
                    Contract contractToUpdate = new Contract(
                        Id = contractIdSO,
                        ARC_AppFeeOrder__c =  chargentOrdersToInsertMap.containsKey('changeFeeSpinOffChargent') && chargentOrdersToInsertMap.get('changeFeeSpinOffChargent').Id != null ? chargentOrdersToInsertMap.get('changeFeeSpinOffChargent').Id : null,
                        ARC_RecurringMonthlyOrder__c = chargentOrdersToInsertMap.get('recurringSpinOffChargent').Id,
                        ARC_Case__c = casesToUpsert.get('1').Id,
                        Status = 'Awaiting Signature'
                    );
                    contractsToUpdate.add(contractToUpdate);
                }
                if (!contractsToUpdate.isEmpty()) update contractsToUpdate;
                
            // } catch (Exception e) {
            //     System.debug('Exception while updating contracts in future context: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            // }
            if (!promotionDiscounts.isEmpty()) {     
                // try {
    
                    for(ARC_PromotionDiscount__c d : promotionDiscounts) {
                        d.ARC_Contract__c = contractIdSO != null ? contractIdSO : null;
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
                // } catch (Exception e) {
                //     System.debug('Exception while upserting promotion discount: ' + e.getMessage() + e.getStackTraceString());
                //     throw e;
                // }
            } 

            // try {
                // Handle UW Case Members if we have a successful case creation
                if (!casesToUpsert.isEmpty()) {
                    List<ARC_UnderwritingCaseMember__c> listUWCMToUpsert = new List<ARC_UnderwritingCaseMember__c>();
    
                    Map<String, List<ARC_UnderwritingCaseMember__c>> mapListUWCM = (Map<String, List<ARC_UnderwritingCaseMember__c>>)JSON.deserialize(jsonUWCaseMembers, Map<String, List<ARC_UnderwritingCaseMember__c>>.class);

                    List<ARC_UnderwritingCaseMember__c> listUWCM_RC = mapListUWCM.get('0'); // List of UW Case Members of the (Remove Member - Contract)
                    List<ARC_UnderwritingCaseMember__c> listUWCM_SO = mapListUWCM.get('1'); // List of UW Case Members of the (Spin Off - Contract)

                    if(listUWCM_RC != null){
                        // Link UW Case Members to the Contract ID and its UW Case (Remove Member - Contract)
                        for (ARC_UnderwritingCaseMember__c member : listUWCM_RC) { 
                            member.ARC_Contract__c = contractIdRC;
                            member.ARC_UnderwritingCase__c = casesToUpsert.containsKey('0') && casesToUpsert.get('0').Id != null ? casesToUpsert.get('0').Id : null;
                        }
                        listUWCMToUpsert.addAll(listUWCM_RC);
                    }

                    if (listUWCM_SO != null) {
                        // Link UW Case Members to the Contract ID and its UW Case (Spin Off - Contract)
                        for (ARC_UnderwritingCaseMember__c member : listUWCM_SO) {
                            member.ARC_Contract__c = contractIdSO;
                            member.ARC_UnderwritingCase__c = casesToUpsert.containsKey('1') && casesToUpsert.get('1').Id != null ? casesToUpsert.get('1').Id : null;
                        }
                        listUWCMToUpsert.addAll(listUWCM_SO);
                        
                    }
    
                    if (!mapListUWCM.values().isEmpty()) {
                        Database.UpsertResult[] memberResults = Database.upsert(listUWCMToUpsert, true);
    
                        for (Database.UpsertResult result : memberResults) {
                            if (!result.isSuccess()) {
                                for (Database.Error error : result.getErrors()) {
                                    System.debug('Error upserting UW Case Member in future context: ' + error.getMessage());
                                }
                            }
                        }
                    }
                }
                
            // } catch (Exception e) {
            //     System.debug('Exception while processing UW case members in future context: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            // }
            
        } catch (Exception e) {
            Integer MAX_FIELD_SIZE = 131072-10;

            String serializedData = fullJson;
            Custom_Logs__c log = new Custom_Logs__c();
            log.Name = 'Exception UW case, UW case members or Contract update in future context';
            log.Account__c = contextId;
            log.OwnerId = UserInfo.getUserId();
            log.Status__c = 'New';
            
            if(serializedData.length() > MAX_FIELD_SIZE) {
                log.Log__c = serializedData.substring(0, MAX_FIELD_SIZE);
                if(serializedData.length() > MAX_FIELD_SIZE) {
                    Integer remainingLength = Math.min(serializedData.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                    log.Log_2__c = serializedData.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                }
            } else {
                log.Log__c = serializedData;
            }
            
            insert log;
            System.debug('Exception while processing UW case and members in future context: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
            throw e;
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
    private void upsertHipaaAuthorizations() {

        if (!manager.fakeIdToHipaaAuth.isEmpty() || manager.hippaExternalContact != null || manager.guardianHippa != null) {
            try {
                Id censusId;
                for(vlocity_ins__GroupCensus__c groupCensus : manager.groupCensusToFictionalId.keySet()){
                    censusId = groupCensus.Id;
                }

                List<ARC_HipaaAuthorization__c> listAuthToInsert = new List<ARC_HipaaAuthorization__c>();


                // Process regular member HIPAA authorizations
                if(!manager.fakeIdToHipaaAuth.isEmpty()){
                    for (String key : manager.fakeIdToHipaaAuth.keySet()) {
                        ARC_HipaaAuthorization__c hipaaAuth = manager.fakeIdToHipaaAuth.get(key);
                        hipaaAuth.ARC_AuthorizedMember__c = manager.fictionalMemberIdToGCMListToUpsert.get(key).Id;
                        hipaaAuth.ARC_Census__c = censusId;

                        listAuthToInsert.add(hipaaAuth);
                    }
                }

                // Process external contact
                if (manager.hippaExternalContact != null) {

                    manager.hippaExternalContact.AccountId = manager.groupAccountsToInsertMap.get(1).Id;
                    Database.UpsertResult result = Database.upsert(manager.hippaExternalContact, true);
                    if (result.isSuccess()) {
                        ARC_HipaaAuthorization__c newHipaa = new ARC_HipaaAuthorization__c();
                        newHipaa.Name = manager.hippaExternalContact.FirstName + ' ' + manager.hippaExternalContact.LastName;
                        newHipaa.ARC_ExternalPersonAuthorized__c = result.getId();
                        newHipaa.ARC_Census__c = censusId;

                        listAuthToInsert.add(newHipaa);
                    }
                } 
            
                // Process Guardian
                if (manager.guardianHippa != null) {
                    manager.guardianHippa.ARC_Census__c = censusId; 
                    if(manager.guardianHippa.ARC_ExternalPersonAuthorized__c == null && manager.guardiansToInsert != null && !manager.guardiansToInsert.isEmpty()){
                        // Get PersonContactId from Guardian's inserted Account
                        Id guardianAccountId = manager.guardiansToInsert[0].Id;
                        Account guardianWithContact = [SELECT PersonContactId FROM Account WHERE Id = :guardianAccountId LIMIT 1];
                        
                        manager.guardianHippa.ARC_ExternalPersonAuthorized__c  = guardianWithContact.PersonContactId;
                    }

                    listAuthToInsert.add(manager.guardianHippa);
                }
            
                // Perform the upsert
                if (!listAuthToInsert.isEmpty()) {
                    Database.UpsertResult[] results = Database.upsert(listAuthToInsert, true);
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.UpsertResult result = results[i];
                        if (!result.isSuccess()) {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting HIPAA authorization: ' + error.getMessage());
                            }
                        } else {
                            System.debug('Successfully upserted HIPAA authorization at index ' + i);
                        }
                    }
                }
            
            } catch (Exception e) { 
                System.debug('Exception in upsertHipaaAuthorizations: ' + e.getMessage() + ' at line ' + e.getLineNumber());
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
    private void upsertMedicalConditions() {

        if(!manager.mapMedicalConditionsToInsert.isEmpty()) {
            try {
                for (String memberId : manager.mapMedicalConditionsToInsert.keySet()) {
                    Id accountId;
                    Id censusId;

                    if(memberId.startsWith('MEM-')){
                        accountId = manager.fictionalMemberIdToPersonAccount.containsKey(memberId) ? manager.fictionalMemberIdToPersonAccount.get(memberId).Id : null;
                    }

                    censusId = manager.fictionalMemberIdToGCMListToUpsert.containsKey(memberId) ? manager.fictionalMemberIdToGCMListToUpsert.get(memberId).Id : null;
                    
                    List<ARC_MedicalConditions__c> medicalConditionsList = manager.mapMedicalConditionsToInsert.get(memberId);

                    if (medicalConditionsList != null && !medicalConditionsList.isEmpty()) {
                        for (ARC_MedicalConditions__c mc : medicalConditionsList) {
                            mc.ARC_CensusMember__c = censusId;
                            if(memberId.startsWith('MEM-')){
                                mc.ARC_PersonAccount__c = accountId;
                            }

                            manager.medicalConditionsToUpsertList.add(mc);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting mapMedicalConditionsToInsert: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }


        if (!manager.medicalConditionsToUpsertList.isEmpty()) {
            try {

                Database.UpsertResult[] results = Database.upsert(manager.medicalConditionsToUpsertList, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting medical condition: ' + error.getMessage());
                        }
                    } 
                    // else {
                    //     if (!manager.allInsertedRecords.containsKey('MedicalCondition')) {
                    //         manager.allInsertedRecords.put('MedicalCondition', new Map<Id, SObject>());
                    //     }
                    //     manager.allInsertedRecords.get('MedicalCondition').put(result.getId(), manager.medicalConditionsToUpsert[i]);
                    // }
                }
            } catch (Exception e) {
                System.debug('Exception while upsert Medical Conditions: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
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
    private void upsertConsumerDrugs() {

        if(!manager.mapConsumerDrugsToInsert.isEmpty()) {
            try {
                for (String memberId : manager.mapConsumerDrugsToInsert.keySet()) {
                    Id accountId;
                    Id censusId;

                    if(memberId.startsWith('MEM-')){
                        accountId = manager.fictionalMemberIdToPersonAccount.containsKey(memberId) ? manager.fictionalMemberIdToPersonAccount.get(memberId).Id : null;
                    }

                    censusId = manager.fictionalMemberIdToGCMListToUpsert.containsKey(memberId) ? manager.fictionalMemberIdToGCMListToUpsert.get(memberId).Id : null;
                    
                    List<vlocity_ins__ConsumerDrug__c> consumerDurgsList = manager.mapConsumerDrugsToInsert.get(memberId);
                    
                    if (consumerDurgsList != null && !consumerDurgsList.isEmpty()) {
                        for (vlocity_ins__ConsumerDrug__c mc : consumerDurgsList) {
                            mc.ARC_CensusMember__c = censusId;
                            if(memberId.startsWith('MEM-')){
                                mc.ARC_PersonAccount__c = accountId;
                            }

                            manager.consumerDrugsToUpsertList.add(mc);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting mapConsumerDrugsToInsert: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }

        if (!manager.consumerDrugsToUpsertList.isEmpty()) {
            try {

               Database.UpsertResult[] results = Database.upsert(manager.consumerDrugsToUpsertList, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error inserting consumer drugs: ' + error.getMessage());
                        }
                    } 
                    // else {
                    //     if (!manager.allInsertedRecords.containsKey('MedicalCondition')) {
                    //         manager.allInsertedRecords.put('MedicalCondition', new Map<Id, SObject>());
                    //     }
                    //     manager.allInsertedRecords.get('MedicalCondition').put(result.getId(), manager.medicalConditionsToUpsert[i]);
                    // }
                }
            } catch (Exception e) {
                System.debug('Exception while upsert Consumer Drugs: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
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
    private void updatePhysicianMemberData() {

        //List<Account> physicianAccountToUpdateList = new List<Account>();
        List<vlocity_ins__GroupCensusMember__c> physicianGCMToUpdateList = new List<vlocity_ins__GroupCensusMember__c>();

        if(!manager.mapPhysicianDataToUpdate.isEmpty()) {
            try {
                for (String memberId : manager.mapPhysicianDataToUpdate.keySet()) {

                    Id censusId = manager.fictionalMemberIdToGCMListToUpsert.containsKey(memberId) ? manager.fictionalMemberIdToGCMListToUpsert.get(memberId).Id : null;
                    Map<String, Object> physicianMemberInfo = manager.mapPhysicianDataToUpdate.get(memberId);
    
                    if(censusId != null){
                        vlocity_ins__GroupCensusMember__c phGCM = new vlocity_ins__GroupCensusMember__c();
                        phGCM.Id = censusId;
                        phGCM.ARC_PhysicianName__c = (String)physicianMemberInfo.get('ARC_PhysicianName__c');
                        phGCM.ARC_PhysicianCity__c = (String)physicianMemberInfo.get('ARC_PhysicianCity__c');
                        phGCM.ARC_PhysicianPhone__c = (String)physicianMemberInfo.get('ARC_PhysicianPhone__c');
                        physicianGCMToUpdateList.add(phGCM);
                    }

                }
            } catch (Exception e) {
                System.debug('Exception while upserting updatePhysicianMemberData: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
                
        if (!physicianGCMToUpdateList.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(physicianGCMToUpdateList, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error updateing physician census member data: ' + error.getMessage());
                        }
                    }               
                    // else {
                    //     if (!manager.allInsertedRecords.containsKey('physicianGCMToUpdate')) {
                    //         manager.allInsertedRecords.put('physicianGCMToUpdate', new Map<Id, SObject>());
                    //     }
                    //     manager.allInsertedRecords.get('physicianGCMToUpdate').put(result.getId(), manager.physicianGCMToUpdate[i]);
                    // }
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
    private void upsertCasesPC() {
        if (!manager.casesPCToInsert.isEmpty()) {
            try {
                manager.casesPCToInsert[0].ARC_Contract__c = manager.singleSpinOffContract.Id;
                manager.casesPCToInsert[0].AccountId =  manager.groupAccountsToInsertMap.containsKey(1) ? manager.groupAccountsToInsertMap.get(1).Id : null;

                if(!manager.FakeIdToCasePc.values().isEmpty()) {    
                    for (String key : manager.FakeIdToCasePc.keySet()) {
                        Case caseFee = manager.FakeIdToCasePc.get(key);
                        if (key.startsWith('MEM-')) {
                            caseFee.ARC_PersonAccount__c =  manager.fictionalMemberIdToPersonAccount.containsKey(key) ? manager.fictionalMemberIdToPersonAccount.get(key).Id : null;
                            caseFee.ARC_CensusMember__c =  manager.fictionalMemberIdToGCMListToUpsert.containsKey(key) ? manager.fictionalMemberIdToGCMListToUpsert.get(key).Id : null;
                    
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
                    } /* else {
                        if (!manager.allInsertedRecords.containsKey('CasePC')) {
                            manager.allInsertedRecords.put('CasePC', new Map<Id, SObject>());
                        }
                        manager.allInsertedRecords.get('CasePC').put(result.getId(), manager.casesPCToInsert[i]);
                    } */
                }
            } catch (Exception e) {
                System.debug('Exception while upserting PC cases: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }

    /**
     * @Description: Handles promotion discount records.
     * This method:
     * 1. Creates discount records
     * 2. Links discounts to contracts
     * 3. Sets discount details
     * 4. Maintains discount relationships
     * 
     * @throws Exception If discount operations fail
     */
    private void insertPromotionDiscount() {
        /*
        if (!manager.promotionDiscountToInsert.isEmpty()) {
     
            try {
                Set<Id> contractIds = manager.allInsertedRecords.get('Contract').keySet();

                if (!contractIds.isEmpty()) {
                    Id newContractId = new List<Id>(contractIds)[0];
                    for(ARC_PromotionDiscount__c d : manager.promotionDiscountToInsert) {
                            d.ARC_Contract__c = newContractId;
                    }
                }


                Database.UpsertResult[] results = Database.upsert(manager.promotionDiscountToInsert, true);//All or none = true
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error promotion disocunt: ' + error.getMessage());
                        }
                    } else {
                        if (!manager.allInsertedRecords.containsKey('PromotionDiscount')) {
                            manager.allInsertedRecords.put('PromotionDiscount', new Map<Id, SObject>());
                        }                      
                        manager.allInsertedRecords.get('PromotionDiscount').put(result.getId(), manager.promotionDiscountToInsert[i]);                        
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting promotion discount: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }    
        */
    }

    /**
    * @Description: Inserts a new Policy for the new Contract, including its Insurance Policy Participants, Insurance Policy Coverage and Coverage Participants
    */
    private void insertPolicy() {
        try {
            Contract removeMemberContract = manager.removeMemberContract;
            Map<String, Object> inputMapRemove = new Map<String, Object>();
            Map<String, Object> outMapRemove = new Map<String, Object>();
            inputMapRemove.put('contractId', removeMemberContract.Id);
            ARC_PolicyCreation.createAllPolicyRecords(inputMapRemove, outMapRemove);
            // Single Spin Off
            if (manager.contractsToInsertMap.size() == 2) {
                Contract singleSpinOffContract = manager.singleSpinOffContract;
                Map<String, Object> inputMapSpinOff = new Map<String, Object>();
                Map<String, Object> outMapSpinOff = new Map<String, Object>();
                inputMapSpinOff.put('contractId', singleSpinOffContract.Id);
                ARC_PolicyCreation.createAllPolicyRecords(inputMapSpinOff, outMapSpinOff);
            }
        } catch (Exception e) {
            System.debug('Exception while inserting policy: ' + e.getMessage() + e.getStackTraceString() );
            throw e;
        }
    }

    /**
     * @Description: Sends SpinOff notification email asynchronously to avoid SOQL limits
     * @param fullJson Complete JSON data from the SpinOff flow
     * @param accountId Account ID for logging purposes
     * This method:
     * 1. Extracts accountId from input data
     * 2. Calls ARC_Emails.sendNotificationEmailSpinOffFlowCompletion
     * 
     * @throws Exception If email sending fails
     */
    
    @future
    private static void sendSpinOffNotificationEmail(String fullJson) {
        Id accountId = null;
        try {
            
            // Deserialize JSON and extract account ID
            Map<String, Object> inputData = (Map<String, Object>) JSON.deserializeUntyped(fullJson);
            
            // Extract required data
            Map<String, Object> extractedData = extractSpinOffDataFromJson(inputData);
            // Get extracted values
            String primaryMemberName = (String) extractedData.get('primaryMemberName');
            String primaryMemberEmail = (String) extractedData.get('primaryMemberEmail');
            accountId = (Id) extractedData.get('accountId');


            List<String> spinOffMemberNames = (List<String>) extractedData.get('spinOffMemberNames');
            String effectiveDate = (String) extractedData.get('effectiveDate');

            // LOGS

            // Call optimized email method
            ARC_Emails.sendNotificationEmailSpinOffFlowCompletionOptimized(
                accountId,
                primaryMemberName,
                primaryMemberEmail,
                spinOffMemberNames,
                effectiveDate
            );

        } catch (Exception e) {
            System.debug('EXCEPTION in @future method: ' + e.getMessage());
            System.debug('STACK TRACE: ' + e.getStackTraceString());

            // Error handling
            final Integer MAX_FIELD_SIZE = 131072 - 10;
            Custom_Logs__c log = new Custom_Logs__c(
                Name = 'Exception in sendSpinOffNotificationEmail @future',
                Account__c = accountId,
                OwnerId = UserInfo.getUserId(),
                Status__c = 'New'
            );

            if (fullJson.length() > MAX_FIELD_SIZE) {
                log.Log__c = fullJson.substring(0, MAX_FIELD_SIZE);
                if (fullJson.length() > MAX_FIELD_SIZE) {
                    Integer remainingLength = Math.min(fullJson.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                    log.Log_2__c = fullJson.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                }
            } else {
                log.Log__c = fullJson;
            }

            try {
                insert log;
            } catch (DmlException dmlEx) {
                System.debug('Error inserting log: ' + dmlEx.getMessage());
            }
        }
    }

    ///////////////////////
    // Auxiliary Methods //
    ///////////////////////

    /**
    //  * @Description: Extract all spin-off related data from JSON in one unified method
    //  * @param inputData Deserialized JSON data
    //  * @return Map<String, Object> containing all extracted information
    //  */
    private static Map<String, Object> extractSpinOffDataFromJson(Map<String, Object> inputData) {
        Map<String, Object> result = new Map<String, Object>{
            'primaryMemberName' => null,
            'primaryMemberEmail' => null,
            'spinOffMemberNames' => new List<String>(),
            'effectiveDate' => null
        };
        
        try {
            // 1. Extract Primary Member Name and Email
            Map<String, Object> primaryMember = (Map<String, Object>) inputData.get('PrimaryMember');
            if (primaryMember != null) {
                String name = (String) primaryMember.get('Name');
                String email = (String) primaryMember.get('Email');
                String accountId = (String) primaryMember.get('Id');

                if (String.isNotBlank(name)) {
                    result.put('primaryMemberName', name);
                }

                if (String.isNotBlank(email)) {
                    result.put('primaryMemberEmail', email);
                }

                if(String.isNotBlank(accountId)){
                    result.put('accountId', accountId);
                }
            }
            
            // Extract Effective Date && Spin-off Members
            Map<String, Object> stepData = (Map<String, Object>) inputData.get('STEP_AccountSelection');
            if (stepData != null) {
                
                // Extract Effective Date
                try {
                    if (inputData.containsKey('STEP_AccountSelection')) {
                        Map<String, Object> STEP_AccountSelection = (Map<String, Object>)inputData.get('STEP_AccountSelection');
                        Map<String, Object> aRC_DatePicker = (Map<String, Object>)STEP_AccountSelection.get('aRC_DatePicker');
                        String effectiveDate = (String)aRC_DatePicker.get('DATE_SubscriberEffectiveDate');
                        
                        if (String.isNotBlank(effectiveDate)) {
                            result.put('effectiveDate', effectiveDate);
                        }
                    } else {
                        System.debug('EffectiveDate not found in JSON');
                    }
                } catch (Exception e) {
                    System.debug('Error extracting effective date: ' + e.getMessage());
                }
                
                // Extract Spin-off Members
                List<Object> membersTable = (List<Object>) stepData.get('LWC_SpinOffCensusMembersTable');
                if (membersTable != null) {
                    List<String> spinOffNames = (List<String>) result.get('spinOffMemberNames');
                    
                    for (Object memberObj : membersTable) {
                        Map<String, Object> member = (Map<String, Object>) memberObj;
                        String firstName = (String) member.get('TXT_FirstName');
                        String lastName = (String) member.get('TXT_LastName');
                        
                        Integer familyNumber = (Integer) member.get('NUM_assignToFamily');
                        
                        // Spin-off members have NUM_assignToFamily != 1
                        if (familyNumber != null && familyNumber != 1) {
                            String fullName = firstName + ' ' + lastName;
                            spinOffNames.add(fullName);
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in extractSpinOffDataFromJson LINE: ' + e.getLineNumber() + ' ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
        
        return result;
    }

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
    * @Description: Updates census member records with contact IDs.
    * This method:
    * 1. Links census members to contacts
    * 2. Updates member information
    * 3. Maintains record relationships
    * 4. Ensures data consistency
    * 
    * @throws Exception If member update fails
    */
    private void updateRelatedCensusMembers() {
        /*
        List<vlocity_ins__GroupCensusMember__c> censusMembersToUpdateContactId = new List<vlocity_ins__GroupCensusMember__c>();
        List<Account> accContacts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE Id IN :manager.accountIdToMemberId.keySet()]);
        for(Account acc : accContacts) {
            vlocity_ins__GroupCensusMember__c censusMember = (vlocity_ins__GroupCensusMember__c)manager.allInsertedRecords.get('GroupCensusMember').get(manager.accountIdToMemberId.get(acc.Id));
            censusMember.vlocity_ins__ContactId__c = acc.PersonContactId;
            censusMember.vlocity_ins__SocialSecurityNumber__c = censusMember.vlocity_ins__SocialSecurityNumber__c;
            censusMembersToUpdateContactId.add(censusMember);
        }
        update censusMembersToUpdateContactId;
        */
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
            
            if(serializedData.length() > MAX_FIELD_SIZE) {
                log.Log__c = serializedData.substring(0, MAX_FIELD_SIZE);
                if(serializedData.length() > MAX_FIELD_SIZE) {
                    Integer remainingLength = Math.min(serializedData.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                    log.Log_2__c = serializedData.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                }
            } else {
                log.Log__c = serializedData;
            }
            
            insert log;

            throw e;
        }
    }
 
    private static Map<String,vlocity_ins__GroupCensusMember__c> mapGroupCensusMembers(Map<String,vlocity_ins__GroupCensusMember__c> groupCensusMembersToInsertMap, Map<vlocity_ins__GroupCensus__c,List<String>> groupCensusToFictionalId, Map<String,Account> personAccountsToInsertMap){
        Map<String,String> pAFictionalIdToPersonContactId = new Map<String,String>();

        Set<Id> personAccountIds = new Set<Id>();
        for(String fictionalId : personAccountsToInsertMap.keySet()){
            personAccountIds.add(personAccountsToInsertMap.get(fictionalId).Id);
        }

        List<Account> personAccounts = [SELECT Id, PersonContactId FROM Account WHERE Id IN :personAccountIds];
        for(Account personAccount : personAccounts){
            for(String fictionalId : personAccountsToInsertMap.keySet()){
                if(personAccount.Id == personAccountsToInsertMap.get(fictionalId).Id){
                    pAFictionalIdToPersonContactId.put(fictionalId, personAccount.PersonContactId);
                }
            }
        }
        
        Map<String,vlocity_ins__GroupCensusMember__c> groupCensusMembersToInsert = new Map<String,vlocity_ins__GroupCensusMember__c>();
        Map<String,String> groupCensusIdToGCMFictionalId = new Map<String,String>();
        for(vlocity_ins__GroupCensus__c groupCensus : groupCensusToFictionalId.keySet()){
            if(groupCensus.Id != null){
                for(String fictionalId : groupCensusToFictionalId.get(groupCensus)){
                    groupCensusIdToGCMFictionalId.put(fictionalId, groupCensus.Id);
                }
            }
        }

        for(String fictionalId : groupCensusMembersToInsertMap.keySet()){            
            vlocity_ins__GroupCensusMember__c groupCensusMember = new vlocity_ins__GroupCensusMember__c();
            
            groupCensusMember.Name = groupCensusMembersToInsertMap.get(fictionalId).Name;
            groupCensusMember.vlocity_ins__FirstName__c =groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__FirstName__c;
            groupCensusMember.vlocity_ins__LastName__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__LastName__c;
            groupCensusMember.vlocity_ins__Gender__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__Gender__c;
            groupCensusMember.vlocity_ins__Email__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__Email__c;
            groupCensusMember.ARC_PhysicalAddressZipCode__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_PhysicalAddressZipCode__c;
            groupCensusMember.ARC_PhysicalAddressStreet__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_PhysicalAddressStreet__c;
            groupCensusMember.ARC_PhysicalAddressState__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_PhysicalAddressState__c;
            groupCensusMember.ARC_PhysicalAddressCity__c =groupCensusMembersToInsertMap.get(fictionalId).ARC_PhysicalAddressCity__c;
            groupCensusMember.ARC_isPregnant__c =  groupCensusMembersToInsertMap.get(fictionalId).ARC_isPregnant__c;
            groupCensusMember.ARC_UseParentAddress__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_UseParentAddress__c;
            groupCensusMember.ARC_Phone__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_Phone__c;
            groupCensusMember.vlocity_ins__IsPrimaryMember__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__IsPrimaryMember__c;
            groupCensusMember.ARC_Smoker__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_Smoker__c;
            groupCensusMember.ARC_Weight__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_Weight__c;
            groupCensusMember.ARC_HeightInches__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_HeightInches__c;
            groupCensusMember.ARC_HeightFeet__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_HeightFeet__c;
            groupCensusMember.vlocity_ins__SocialSecurityNumber__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__SocialSecurityNumber__c;
            groupCensusMember.vlocity_ins__Birthdate__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__Birthdate__c;                    
            groupCensusMember.ARC_MiddleInitial__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_MiddleInitial__c;
            groupCensusMember.vlocity_ins__PrimaryMemberIdentifier__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__PrimaryMemberIdentifier__c;
            groupCensusMember.vlocity_ins__MemberIdentifier__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__MemberIdentifier__c;
            groupCensusMember.vlocity_ins__CensusId__c = (Id)groupCensusIdToGCMFictionalId.get(fictionalId);
            groupCensusMember.vlocity_ins__ContactId__c = (Id)pAFictionalIdToPersonContactId.get(fictionalId);
            groupCensusMember.vlocity_ins__RelatedCensusMemberId__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__RelatedCensusMemberId__c;
            groupCensusMember.vlocity_ins__IsSpouse__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__IsSpouse__c;
            groupCensusMember.vlocity_ins__HasSpouse__c = groupCensusMembersToInsertMap.get(fictionalId).vlocity_ins__HasSpouse__c;
            groupCensusMember.ARC_DependentRelationship__c = groupCensusMembersToInsertMap.get(fictionalId).ARC_DependentRelationship__c;
        
            if(groupCensusMembersToInsertMap.get(fictionalId).Id != null){
                groupCensusMember.ARC_OldCensusMember__c = groupCensusMembersToInsertMap.get(fictionalId).Id;

            }
            
            //vlocity_ins__RelatedCensusMemberId__c
        
            groupCensusMembersToInsert.put(fictionalId, groupCensusMember);
        }
        
        return groupCensusMembersToInsert;
    }
}