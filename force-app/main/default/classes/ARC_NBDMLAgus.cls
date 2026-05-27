/**
 * @Description: This class is responsible for managing all DML operations related to newborn processing.
 * It handles the insertion, update, and deletion of records across multiple objects in the correct order
 * to maintain referential integrity and data consistency.
 * 
 * @Author: [Developer Name]
 * @Date: [Current Date]
 * @Version: 1.0
 */

 public with sharing class ARC_NBDMLAgus {
    
    private ARC_NBManagerAgus manager;
    
    /**
     * @Description: Main method to manage all DML operations for newborns
     * @param manager: The ARC_NBManager instance containing all the data to be processed
     */
    public void manageDML(ARC_NBManagerAgus manager) {
        this.manager = manager;
        
        try {
            this.manager = manager;
            Set<String> operations = new Set<String>();

            operations.add('insertGCM');
            operations.add('insertAccount');
            operations.add('insertGCMPlan');
            operations.add('insertPolPart');
            operations.add('updateContMembership');
            operations.add('insertAggregators');

            if (manager.isPermanentNewborn) {
                operations.add('upsertContract_Permanent'); 
                operations.add('insertCLI_Permanent'); 
                operations.add('insertGCMPlan_Permanent'); 
                operations.add('insertCntPart_Permanent');
                operations.add('insertPolicy_Permanent');
                operations.add('insertMedicalConditions');
                operations.add('insertConsumerDrugs');
                operations.add('insertPhysicianMemberData');
                operations.add('insertChargentOrder_Permanent');
                operations.add('insertCaseFeeSkypped_Permanent');
                operations.add('insertUWCaseAndUWCM_Permanent');
            }

            try{
                System.debug('Operations to Execute: ' + operations);
                executeDML(operations);
            } catch(Exception e) {
                System.debug('Exception while executing DMLOperations the changes will be rolled back: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
            
            // Suggested execution order (to be implemented):
            // 1. Insert/Update Accounts (Group and Person)
            // 2. Insert/Update Guardians
            // 3. Insert/Update Group Census
            // 4. Insert/Update Group Census Members
            // 5. Insert/Update Contracts
            // 6. Insert/Update Contract Line Items
            // 7. Insert/Update Contract Participants
            // 8. Insert/Update Chargent Orders
            // 9. Insert/Update HIPAA Authorizations
            // 10. Insert/Update Medical Conditions
            // 11. Insert/Update Consumer Drugs
            // 12. Insert/Update Cases
            // 13. Insert/Update Case Members
            // 14. Insert/Update Promotion Discounts
            
        } catch (Exception e) {
            System.debug('Error in manageDML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing DML operations for newborns: ' + e.getMessage());
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
                when 'insertGCM' {
                    manageGCM_DML();
                }
                when 'insertAccount' {
                    manageAccount_DML();
                }
                when 'insertGCMPlan' {
                    manageGCMPlan_DML();
                }
                when 'insertPolPart' {
                   managePolPart_DML();
                }
                when 'updateContMembership' {
                   manageContMembership_DML();
                }
                when 'insertAggregators' {
                    manageAggregators_DML();
                }
                when 'upsertContract_Permanent' {
                    manageContract_PermanentDML();
                }
                when 'insertCLI_Permanent' {
                    manageCLI_PermanentDML();
                }
                when 'insertGCMPlan_Permanent' {
                    manageGCMPlan_PermanentDML();
                }
                when 'insertCntPart_Permanent' {
                    manageCntPart_PermanentDML();
                }
                when 'insertPolicy_Permanent' {
                    insertPolicy_PermanentDML();
                }   
                when 'insertChargentOrder_Permanent' {
                    manageChargentOrder_PermanentDML();
                }
                when 'insertCaseFeeSkypped_Permanent' {
                    manageCaseFeeSkypped_PermanentDML();
                }
                when 'insertUWCaseAndUWCM_Permanent' {
                    manageUWCaseAndUWCM_PermanentDML();
                }
                when 'insertMedicalConditions' {
                    manageMedicalConditionDML();
                }
                when 'insertConsumerDrugs' {
                    manageConsumerDrugDML();
                } 
                when 'insertPhysicianMemberData' {
                    managePhysicianMemberData();
                }
            }
        } 
    }
    
    /**
     * @Description: Manages account-related DML operations for newborns
     */
    private void manageAccount_DML() {
        try {
            if (!manager.accountFakeIdToInsertNB.isEmpty()) {

                Map<String, vlocity_ins__GroupCensusMember__c> censusActiveToGCM = (Map<String, vlocity_ins__GroupCensusMember__c>)manager.censusGroupToGCM.get(manager.lastCensusId);

                for (String fakeId : manager.accountFakeIdToInsertNB.keySet()) {
                    Account acc = (Account)manager.accountFakeIdToInsertNB.get(fakeId);

                    acc.Census_Member__c = ((vlocity_ins__GroupCensusMember__c)censusActiveToGCM.get(fakeId)).Id;
                    acc.ARC_CensusMember__pc = ((vlocity_ins__GroupCensusMember__c)censusActiveToGCM.get(fakeId)).Id;
                    
                    manager.accountFakeIdToInsertNB.put(fakeId, acc);
                }

                try {
                    Database.SaveResult[] results = Database.insert(manager.accountFakeIdToInsertNB.values(), true); 
                    System.debug('accounts: ' + manager.accountFakeIdToInsertNB);

                    List<Account> personAccounts = [SELECT Id, PersonContactId FROM Account WHERE Id IN :manager.accountFakeIdToInsertNB.values()];
                    
                    System.debug('accounts retrieve: ' + personAccounts);

                    for (Account personAccount : personAccounts) {
                        for (String fakeId : manager.accountFakeIdToInsertNB.keySet()) {
                            if (personAccount.Id == manager.accountFakeIdToInsertNB.get(fakeId).Id) {
                                manager.fakeIdToPersonContactId.put(fakeId, personAccount.PersonContactId);

                                System.debug('insertedAccount: ' + manager.accountFakeIdToInsertNB.get(fakeId).Id); 
                            }
                        }
                    }
                    updateRelatedCensusMembers();
                } catch (Exception e) {
                    System.debug('Exception while upserting person accounts: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                }
            }
        } catch (Exception e) {
            System.debug('Error in manageAccount_DML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing account DML for newborns: ' + e.getMessage());
        }
    }
    
    /**
     * @Description: Manages census member-related DML operations for newborns
     */
    private void manageGCM_DML() {
        try {
            if (!manager.censusGroupToGCM.isEmpty()) {
                try {
                    List<vlocity_ins__GroupCensusMember__c> allGcms = new List<vlocity_ins__GroupCensusMember__c>();
                    for (Id censusId : manager.censusGroupToGCM.keySet()) {
                        allGcms.addAll(manager.censusGroupToGCM.get(censusId).values());
                    }
                    
                    Database.SaveResult[] results = Database.insert(allGcms, true); 
               
                    for (String cKey : manager.censusGroupToGCM.keySet()) {
                        Map<String, vlocity_ins__GroupCensusMember__c> perCensus = manager.censusGroupToGCM.get(cKey);
                        for (vlocity_ins__GroupCensusMember__c g : perCensus.values()) {
                            System.debug('inserted gcm: ' + g.Id + ' with census id: ' + cKey);
                        }
                    }

                } catch (Exception e) {
                    System.debug('Exception while upserting Group Census Members: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                } 
            }
        } catch (Exception e) {
            System.debug('Error in manageGCM_DML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing census member DML for newborns: ' + e.getMessage());
        }
    }

    /**
     * @Description: Manages group census member plan-related DML operations for newborns
     */
    private void manageGCMPlan_DML() {
        try {
            if (!manager.listContractsTNB.isEmpty()) {
                List<vlocity_ins__GroupCensusMemberPlan__c> listGCMP = new List<vlocity_ins__GroupCensusMemberPlan__c>();

                for (String cntId : manager.contractIdToGCMP.keySet()) { 
                    for (String cKey : manager.censusGroupToGCM.keySet()) {
                        if (manager.cntIdtoCensusId.get(cntId) == cKey) {
                            Map<String, vlocity_ins__GroupCensusMemberPlan__c> fakeIdToGCMP = manager.contractIdToGCMP.get(cntId);
                            Map<String, vlocity_ins__GroupCensusMember__c> mapGCM = manager.censusGroupToGCM.get(cKey);

                            for (String fakeId : fakeIdToGCMP.keySet()) {
                                vlocity_ins__GroupCensusMemberPlan__c gcmPlan = (vlocity_ins__GroupCensusMemberPlan__c)fakeIdToGCMP.get(fakeId);
                                gcmPlan.vlocity_ins__GroupCensusMemberId__c = ((vlocity_ins__GroupCensusMember__c)mapGCM.get(fakeId)).Id;
                            
                                listGCMP.add(gcmPlan);
                            }
                        }
                    }
                }
                
                try {
                    Database.SaveResult[] results = Database.insert(listGCMP, true);
                    for (vlocity_ins__GroupCensusMemberPlan__c gcmPlan : listGCMP) {
                        System.debug('insertedCensusMemberPlan: ' + gcmPlan.Id);
                    }
                } catch (Exception e) {
                    System.debug('Exception while upserting Group Census Member Plan: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                } 
            }
        } catch (Exception e) {
            System.debug('Error in manageGCMPlan_DML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing census member plan DML for newborns: ' + e.getMessage());
        }
    }

    /**
     * @Description: Manages policy participants-related DML operations for newborns
     */
    private void managePolPart_DML() {
        try {
            if (!manager.listContractsTNB.isEmpty()) {

                Map<String, InsurancePolicyParticipant> mapToPolPart = new Map<String, InsurancePolicyParticipant>();
                Map<String, Map<String, InsurancePolicyParticipant>> contractIdToMapPolPart = new Map<String, Map<String, InsurancePolicyParticipant>>();

                List<InsurancePolicyParticipant> toInsert = new List<InsurancePolicyParticipant>();

                for (String contractId : manager.contractIdToPolPart.keySet()) {
                    Map<String, InsurancePolicyParticipant> fakeIdToPolPart = manager.contractIdToPolPart.get(contractId);
                    
                    Map<String, InsurancePolicyParticipant> fakeIdToPolPartForThisContract = new Map<String, InsurancePolicyParticipant>();

                    for (String fakeId : fakeIdToPolPart.keySet()) {
                        InsurancePolicyParticipant polPart = (InsurancePolicyParticipant)fakeIdToPolPart.get(fakeId);
                        polPart.PrimaryParticipantContactId = (String)manager.fakeIdToPersonContactId.get(fakeId);

                        fakeIdToPolPartForThisContract.put(fakeId, polPart);
                        toInsert.add(polPart);
                    }

                    contractIdToMapPolPart.put(contractId, fakeIdToPolPartForThisContract);
                }

                try {
                    Database.SaveResult[] results = Database.insert(toInsert, true);
                    for (InsurancePolicyParticipant policyPart : toInsert) {
                        System.debug('insertedPolicyParticipant: ' + policyPart.Id);
                    }
                } catch (Exception e) {
                    System.debug('Exception while inserted Insurance Policy Participant: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                } 


                List<ARC_CoverageParticipant__c> listPolPart = new List<ARC_CoverageParticipant__c>();
            
                for (String contractId : manager.contractIdToCoverPart.keySet()) {
                    Map<String, ARC_CoverageParticipant__c> fakeIdToCovPart = manager.contractIdToCoverPart.get(contractId);
                    for (String fakeId : fakeIdToCovPart.keySet()) {
                        ARC_CoverageParticipant__c covPart = (ARC_CoverageParticipant__c)fakeIdToCovPart.get(fakeId);
                        Map<String, InsurancePolicyParticipant> polPart = contractIdToMapPolPart.get(contractId);
                        covPart.ARC_PolicyParticipant__c = ((InsurancePolicyParticipant)polPart.get(fakeId)).Id;

                        System.debug('Coverage Particant ROLE before insert: ' + covPart.ARC_CoverageRole__c);
                        listPolPart.add(covPart);
                    }
                }
                
                try {
                    Database.SaveResult[] results = Database.insert(listPolPart, true);
                    for (ARC_CoverageParticipant__c covPart : listPolPart) {
                        System.debug('insertedCoverageParticipant: ' + covPart.Id);
                        System.debug('Coverage Particant ROLE After insert: ' + covPart.ARC_CoverageRole__c);

                    }
                } catch (Exception e) {
                    System.debug('Exception while inserted Coverage Participant: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                    throw e;
                } 
            }
        } catch (Exception e) {
            System.debug('Error in managePolPart_DML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing policy participants DML for newborns: ' + e.getMessage());
        }
    }

    /**
     * @Description: Manages Continuous Coverage Date / Last Aggregator Reset / Continuous Membership Date DML operations for temporary newborns
     */
    private void manageContMembership_DML() {
        try {
            if (!manager.accountFakeIdToInsertNB.isEmpty()) {
                List<Account> personAccounts = manager.accountFakeIdToInsertNB.values();
                ARC_ContinuousMembershipDateBulk.RequestsVariables personAccountIds = new ARC_ContinuousMembershipDateBulk.RequestsVariables();
                personAccountIds.listRecordIds = new List<Id>();
                for (Account personAccount : personAccounts) {
                    personAccountIds.listRecordIds.add(personAccount.Id);
                }
                ARC_ContinuousMembershipDateBulk.updateContinuousMembershipStartDateBulk(
                    new List<ARC_ContinuousMembershipDateBulk.RequestsVariables>{ personAccountIds }
                );
            }
        } catch (Exception e) {
            System.debug('Error in manageContMembership_DML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing Continuous Membership DML for newborns: ' + e.getMessage());
        }
    }

    /**
     * @Description: Manages aggregators-related DML operations for temporary newborns
     */
    private void manageAggregators_DML() {
        try {
            if (!manager.listContractsTNB.isEmpty()) {
                List<String> policyIds = new List<String>();
                for (Contract contract : manager.listContractsTNB) {
                    policyIds.add('\'' + contract.Insurance_Policies__r[0].Id + '\'');
                }
                String whereClause = 'Id IN (' + String.join(policyIds, ', ') + ')';
                System.debug('whereClause: ' + whereClause);
                ARC_CreateMissingAggregators aggregatorsBatch = new ARC_CreateMissingAggregators(whereClause, true, false);
                Database.executeBatch(aggregatorsBatch, 100);
            }
        } catch (Exception e) {
            System.debug('Error in manageAggregators_DML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing aggregators DML for newborns: ' + e.getMessage());
        }
    }

    /**
     * @Description: Manages contract-related DML operations for permanent newborns
     */
    private void manageContract_PermanentDML() {
        if (manager.contractsToUpsert.containsKey('PermanentNewborn')) {
            try {
                Database.UpsertResult[] results = Database.upsert(manager.contractsToUpsert.values(), true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract: ' + error.getMessage());
                        }
                    } else {
                        System.debug('Upserted contract: ' + manager.contractsToUpsert.values()[i].Id);
                    }
                }
            } catch (Exception e) {
                System.debug('Error in manageContract_PermanentDML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw new AuraHandledException('Error managing contract DML for newborns: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @Description: Manages contract line item-related DML operations for permanent newborns
     */
    private void manageCLI_PermanentDML() {
        try {
            if(!manager.indexToParentCLI.isEmpty() && !manager.indexToChildCLI.isEmpty()){
                
                for(Integer index : manager.indexToParentCLI.keySet()){
                    manager.indexToParentCLI.get(index).vlocity_ins__ContractId__c = ((Contract)manager.contractsToUpsert.get('PermanentNewborn')).Id;
                }

                for(Integer index : manager.indexToChildCLI.keySet()){
                    for(vlocity_ins__ContractLineItem__c childCLI : manager.indexToChildCLI.get(index)){    
                        childCLI.vlocity_ins__ContractId__c = ((Contract)manager.contractsToUpsert.get('PermanentNewborn')).Id;
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
                        System.debug('Upserted contract line item: ' + result.getId());
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
                        System.debug('Upserted contract line item: ' + result.getId());
                    }
                } 
            }    
        } catch (Exception e) {
            System.debug('Error in manageCLI_PermanentDML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing contract line item DML for newborns: ' + e.getMessage());
        }
    }
    
    /**
     * @Description: Manages group census member plan-related DML operations for permanent newborns
     */
    private void manageGCMPlan_PermanentDML() {
        if (!manager.indexToParentCLI.isEmpty() && !manager.indexToCLIGCM.isEmpty()) {
            try {
                List<vlocity_ins__GroupCensusMemberPlan__c> gcmpListToUpsert = new List<vlocity_ins__GroupCensusMemberPlan__c> ();

                Map<String, vlocity_ins__GroupCensusMember__c> censusActiveToGCM = manager.cnsIdSpinOff != null ? (Map<String, vlocity_ins__GroupCensusMember__c>)manager.censusGroupToGCM.get(manager.cnsIdSpinOff) : (Map<String, vlocity_ins__GroupCensusMember__c>)manager.censusGroupToGCM.get(manager.lastCensusId);

                for(Integer index : manager.indexToParentCLI.keySet()){
                    for(String gcmId : manager.indexToCLIGCM.get(index)){
                        String censusMemberId;
                        if(gcmId.startsWith('MEM-')){
                            censusMemberId = ((vlocity_ins__GroupCensusMember__c)censusActiveToGCM.get(gcmId)).Id;
                        }
                        else{
                            censusMemberId = gcmId;
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
                                System.debug('Error upserting group census member plan (permanent newborn): ' + error.getMessage());
                            }
                        }
                        else {
                            System.debug('Inserted Group Census Member plan (Permanent Newborn): ' + gcmpListToUpsert[i].Id);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error in manageGCMPlan_PermanentDML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw new AuraHandledException('Error managing census member plan DML for permanent newborns: ' + e.getMessage());
            }
        }
    }

    /**
     * @Description: Manages contract participant-related DML operations for permanent newborns
     */
    private void manageCntPart_PermanentDML() {
        if (!manager.fakeIdToContractPart.values().isEmpty()) {
            try {
                List<ARC_ContractParticipant__c> listCntPart = new List<ARC_ContractParticipant__c>();
                for (String fakeId : manager.fakeIdToContractPart.keySet()) {
                    ARC_ContractParticipant__c cntPart = manager.fakeIdToContractPart.get(fakeId);
                    if (cntPart.ARC_PersonAccount__c == null) {
                        cntPart.ARC_PersonAccount__c = manager.accountFakeIdToInsertNB.get(fakeId).Id;
                    }
                    cntPart.ARC_Contract__c = ((Contract)manager.contractsToUpsert.get('PermanentNewborn')).Id;

                    listCntPart.add(cntPart);
                }
                
                Database.UpsertResult[] results = Database.upsert(listCntPart, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.UpsertResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error upserting contract participant: ' + error.getMessage());
                        }
                    } else {
                        System.debug('Inserted contract participant: ' + listCntPart[i].Id);
                    }
                }
            } catch (Exception e) {
                System.debug('Error in manageCntPart_PermanentDML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
                throw new AuraHandledException('Error managing contract participant DML for newborns: ' + e.getMessage());
            }
        }
    }
    
    /**
     * @Description: Manages Chargent order-related DML operations for newborns
     */
    private void manageChargentOrder_PermanentDML() {
       try {
            if (!manager.chargentOrdersToInsert.values().isEmpty()) {
                Id newContractId = ((Contract)manager.contractsToUpsert.get('PermanentNewborn')).Id;

                for(ChargentOrders__ChargentOrder__c co : manager.chargentOrdersToInsert.values()){
                    co.ARC_Contract__c = newContractId;
                }

                Database.SaveResult[] results = Database.insert(manager.chargentOrdersToInsert.values(), true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error inserting Chargent Order: ' + error.getMessage());
                        }
                    } else {
                        System.debug('Inserted Chargent Order Id: ' + result.getId());
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error in manageChargentOrderDML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing Chargent order DML for newborns: ' + e.getMessage());
        }
    }
    
    /**
     * @Description: Manages HIPAA authorization-related DML operations for newborns
     */
    private void manageHipaaAuthorizationDML() {
        try {
            // TODO: Implement HIPAA authorization DML logic for newborns
            // This method should handle HIPAA authorization insertions/updates
            
            // Placeholder for actual implementation
            System.debug('Managing HIPAA authorization DML for newborns - implementation pending');
            
        } catch (Exception e) {
            System.debug('Error in manageHipaaAuthorizationDML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing HIPAA authorization DML for newborns: ' + e.getMessage());
        }
    }
    
    /**
     * @Description: Manages medical condition-related DML operations for newborns
     */
    private void manageMedicalConditionDML() {
        if(!manager.mapMedicalConditionsToInsert.isEmpty()) {
            try {
                Map<String, vlocity_ins__GroupCensusMember__c> censusActiveToGCM = (Map<String, vlocity_ins__GroupCensusMember__c>)manager.censusGroupToGCM.get(manager.lastCensusId);

                for (String memberId : manager.mapMedicalConditionsToInsert.keySet()) {
                    Id accountId;
                    Id censusId;

                    accountId = manager.accountFakeIdToInsertNB.containsKey(memberId) ? manager.accountFakeIdToInsertNB.get(memberId).Id : null;

                    censusId = censusActiveToGCM.containsKey(memberId) ? censusActiveToGCM.get(memberId).Id : null;
                    
                    List<ARC_MedicalConditions__c> medicalConditionsList = manager.mapMedicalConditionsToInsert.get(memberId);

                    if (medicalConditionsList != null && !medicalConditionsList.isEmpty()) {
                        for (ARC_MedicalConditions__c mc : medicalConditionsList) {
                            mc.ARC_CensusMember__c = censusId;
                            mc.ARC_PersonAccount__c = accountId;

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
                }
            } catch (Exception e) {
                System.debug('Exception while upsert Medical Conditions: ' + e.getLineNumber() + ' ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }
    
    /**
     * @Description: Manages consumer drug-related DML operations for newborns
     */
    private void manageConsumerDrugDML() {
        if(!manager.mapConsumerDrugsToInsert.isEmpty()) {
            try {
                Map<String, vlocity_ins__GroupCensusMember__c> censusActiveToGCM = (Map<String, vlocity_ins__GroupCensusMember__c>)manager.censusGroupToGCM.get(manager.lastCensusId);

                for (String memberId : manager.mapConsumerDrugsToInsert.keySet()) {
                    Id accountId;
                    Id censusId;

                    accountId = manager.accountFakeIdToInsertNB.containsKey(memberId) ? manager.accountFakeIdToInsertNB.get(memberId).Id : null;

                    censusId = censusActiveToGCM.containsKey(memberId) ? censusActiveToGCM.get(memberId).Id : null;
                    
                    List<vlocity_ins__ConsumerDrug__c> consumerDurgsList = manager.mapConsumerDrugsToInsert.get(memberId);
                    
                    if (consumerDurgsList != null && !consumerDurgsList.isEmpty()) {
                        for (vlocity_ins__ConsumerDrug__c mc : consumerDurgsList) {
                            mc.ARC_CensusMember__c = censusId;
                            mc.ARC_PersonAccount__c = accountId;

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
    private void managePhysicianMemberData() {
        List<vlocity_ins__GroupCensusMember__c> physicianGCMToUpdateList = new List<vlocity_ins__GroupCensusMember__c>();
        List<Account> physicianAccountToUpdateList = new List<Account>();

        if(!manager.mapPhysicianDataToUpdate.isEmpty()) {
            try {
                Map<String, vlocity_ins__GroupCensusMember__c> censusActiveToGCM = (Map<String, vlocity_ins__GroupCensusMember__c>)manager.censusGroupToGCM.get(manager.lastCensusId);

                for (String memberId : manager.mapPhysicianDataToUpdate.keySet()) {

                    Id censusId = censusActiveToGCM.containsKey(memberId) ? censusActiveToGCM.get(memberId).Id : null;
                    Id accountId = manager.accountFakeIdToInsertNB.containsKey(memberId) ? manager.accountFakeIdToInsertNB.get(memberId).Id : null;
                    Map<String, Object> physicianMemberInfo = manager.mapPhysicianDataToUpdate.get(memberId);
    
                    if(censusId != null){
                        vlocity_ins__GroupCensusMember__c phGCM = new vlocity_ins__GroupCensusMember__c();
                        phGCM.Id = censusId;
                        phGCM.ARC_PhysicianName__c = (String)physicianMemberInfo.get('ARC_PhysicianName__c');
                        phGCM.ARC_PhysicianCity__c = (String)physicianMemberInfo.get('ARC_PhysicianCity__c');
                        phGCM.ARC_PhysicianPhone__c = (String)physicianMemberInfo.get('ARC_PhysicianPhone__c');
                        physicianGCMToUpdateList.add(phGCM);
                    }

                    if(accountId != null){
                        Account phAcc = new Account();
                        phAcc.Id = accountId;
                        phAcc.ARC_PhysicianName__c = (String)physicianMemberInfo.get('ARC_PhysicianName__c');
                        phAcc.ARC_PhysicianCity__c = (String)physicianMemberInfo.get('ARC_PhysicianCity__c');
                        phAcc.ARC_PhysicianPhone__c = (String)physicianMemberInfo.get('ARC_PhysicianPhone__c');
                        physicianAccountToUpdateList.add(phAcc);
                    }

                }
            } catch (Exception e) {
                System.debug('Exception while upserting managePhysicianMemberData: ' + e.getMessage() + e.getStackTraceString());
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
                            System.debug('Error updating physician Census Member data: ' + error.getMessage());
                        }
                    }        
                }
            } catch (Exception e) {
                System.debug('Exception while updating physician Census Member data: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }

        if (!physicianAccountToUpdateList.isEmpty()) {
            try {
                Database.SaveResult[] results = Database.update(physicianAccountToUpdateList, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error updating physician Account data: ' + error.getMessage());
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while updating physician Account data: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        } 
    }

    /**
     * @Description: Processes fee waived cases.
     * This method:
     * 1. Creates add newborn fee waived cases
     * 2. Links cases to contracts
     * 
     * @throws Exception If case operations fail
     */
    private void manageCaseFeeSkypped_PermanentDML() {
        if (!manager.casesFeeWaivedToInsert.isEmpty()) {
            try {
                for (Case c : manager.casesFeeWaivedToInsert) {
                    c.ARC_Contract__c = manager.contractsToUpsert.containsKey('PermanentNewborn') ? ((Contract)manager.contractsToUpsert.get('PermanentNewborn')).Id : null;
                }

                Database.SaveResult[] results = Database.insert(manager.casesFeeWaivedToInsert, true);
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult result = results[i];
                    if (!result.isSuccess()) {
                        for (Database.Error error : result.getErrors()) {
                            System.debug('Error inserting Case Fee Waived: ' + error.getMessage());
                        }
                    } else {
                        System.debug('Inserted Case Fee Waived (Permanent Newborn): ' + manager.casesFeeWaivedToInsert[i].Id);
                    }
                }
            } catch (Exception e) {
                System.debug('Exception while upserting Case Fee Waived: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
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
    private void manageUWCaseAndUWCM_PermanentDML() {
        if (!manager.casesUWToInsert.isEmpty()) {
            try {
                // Get Chargent Orders if they exist and Contract Id
                Id coAppFeeID = manager.chargentOrdersToInsert.containsKey('coAppFee') ? ((ChargentOrders__ChargentOrder__c)manager.chargentOrdersToInsert.get('coAppFee')).Id : null;
                Id coRecurringId = manager.chargentOrdersToInsert.containsKey('coRecurring') ? ((ChargentOrders__ChargentOrder__c)manager.chargentOrdersToInsert.get('coRecurring')).Id : null;
                Id newContractId = manager.contractsToUpsert.containsKey('PermanentNewborn') ? ((Contract)manager.contractsToUpsert.get('PermanentNewborn')).Id : null;

                // Prepare UW Case data
                Case uwCase = manager.casesUWToInsert[0];
                uwCase.ARC_Contract__c = newContractId;
                uwCase.ARC_CensusMember__c = (String)manager.primaryCensusMember.get('Id');
                uwCase.ContactId = (String)manager.primaryCensusMember.get('vlocity_ins__ContactId__c'); 
                uwCase.ARC_PersonAccount__c = manager.primaryAccountId;
                List<Case> listUWCase = new List<Case> {uwCase};

                Map<String, vlocity_ins__GroupCensusMember__c> censusActiveToGCM = (Map<String, vlocity_ins__GroupCensusMember__c>)manager.censusGroupToGCM.get(manager.lastCensusId);

                // Prepare UW Case Member data
                List<ARC_UnderwritingCaseMember__c> listUWCaseMember = new  List<ARC_UnderwritingCaseMember__c>();
                for (String key : manager.censusMemberIdOrFakeIdToUWCM.keySet()) {
                    ARC_UnderwritingCaseMember__c uwCaseMember = manager.censusMemberIdOrFakeIdToUWCM.get(key);
                    
                    if (key.startsWith('MEM-')) {
                        uwCaseMember.ARC_Member__c = ((vlocity_ins__GroupCensusMember__c)censusActiveToGCM.get(key)).Id;
                        uwCaseMember.ARC_PersonAccount__c = ((Account)manager.accountFakeIdToInsertNB.get(key)).Id;
                    } else {
                        uwCaseMember.ARC_Member__c = key;
                    }
                    listUWCaseMember.add(uwCaseMember);
                }
                
                // Serialize all the data for future processing
                String jsonUWCaseMembers = JSON.serialize(listUWCaseMember);
                String jsonUWCase = JSON.serialize(listUWCase);
                //////////////////////////////////////////////////////////////

                String jsonPromotionDiscount = '';

                if(!manager.promotionDiscountToInsert.isEmpty()){
                    jsonPromotionDiscount = JSON.serialize(manager.promotionDiscountToInsert);
                }

                // Call the future method with all necessary data
                handleUWCaseAndMembersFuture(newContractId, coAppFeeID, coRecurringId, jsonUWCase, jsonUWCaseMembers, jsonPromotionDiscount);
                
            } catch (Exception e) {
                System.debug('Exception while preparing UW case for future processing: ' + e.getMessage() + e.getStackTraceString());
                throw e;
            }
        }
    }
    
    /**
     * @Description: Manages promotion discount-related DML operations for newborns
     */
    private void managePromotionDiscountDML() {
        try {
            // TODO: Implement promotion discount DML logic for newborns
            // This method should handle promotion discount insertions/updates
            
            // Placeholder for actual implementation
            System.debug('Managing promotion discount DML for newborns - implementation pending');
            
        } catch (Exception e) {
            System.debug('Error in managePromotionDiscountDML for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Error managing promotion discount DML for newborns: ' + e.getMessage());
        }
    }
    
    /**
     * @Description: Handles rollback operations in case of DML failures for newborns
     */
    private void handleRollback() {
        try {
            // TODO: Implement rollback logic for newborns
            // This method should handle rolling back any successful DML operations in case of failure
            
            // Placeholder for actual implementation
            System.debug('Handling rollback for newborns - implementation pending');
            
        } catch (Exception e) {
            System.debug('Error in handleRollback for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            // Don't throw exception here as this is error handling
        }
    }
    
    /**
     * @Description: Validates data before DML operations for newborns
     */
    private void validateData() {
        try {
            // TODO: Implement data validation logic for newborns
            // This method should validate all data before performing DML operations
            
            // Placeholder for actual implementation
            System.debug('Validating data for newborns - implementation pending');
            
        } catch (Exception e) {
            System.debug('Error in validateData for newborns: ' + e.getMessage() + ' ' + e.getStackTraceString());
            throw new AuraHandledException('Data validation failed for newborns: ' + e.getMessage());
        }
    }

    @future
    public static void handleUWCaseAndMembersFuture(Id contractId, Id feeOrderId, Id recurringOrderId, String jsonUWCase, String jsonUWCaseMembers, String jsonPromotionDiscount) {
        try {
            // Create a list for the upsert
            List<Case> listCaseToUpsert = (List<Case>)JSON.deserialize(jsonUWCase, List<Case>.class);
            
            // Perform the upsert
            Database.UpsertResult[] results = Database.upsert(listCaseToUpsert, true);
            
            // Store the new case ID for contract update and UW Case Members
            Id newCaseId = null;

            // Process results and log any errors
            for (Database.UpsertResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        System.debug('DML Error upserting UW case in future context: ' + error.getMessage());
                    }
                } else if (newCaseId == null) {
                    newCaseId = result.getId();
                }
            }

            List<ARC_PromotionDiscount__c> promotionDiscounts = new List<ARC_PromotionDiscount__c>();
            if(jsonPromotionDiscount != null && jsonPromotionDiscount != ''){
                promotionDiscounts = (List<ARC_PromotionDiscount__c>)JSON.deserialize(jsonPromotionDiscount, List<ARC_PromotionDiscount__c>.class);
            }

            // Update the contract with the new case and orders
            if (contractId != null) {
                Contract contractToUpdate = new Contract();

                contractToUpdate.Status = 'Awaiting Signature';
                if (contractId != null) contractToUpdate.Id = contractId;
                if (feeOrderId != null) contractToUpdate.ARC_AppFeeOrder__c = feeOrderId;
                if (recurringOrderId != null) contractToUpdate.ARC_RecurringMonthlyOrder__c = recurringOrderId;
                if (newCaseId != null) contractToUpdate.ARC_Case__c = newCaseId;

                update contractToUpdate;
            }

            // Handle UW Case Members if we have a successful case creation
            if (newCaseId != null) {
                List<ARC_UnderwritingCaseMember__c> listUWCaseMemberToInsert = (List<ARC_UnderwritingCaseMember__c>)JSON.deserialize(jsonUWCaseMembers, List<ARC_UnderwritingCaseMember__c>.class);
                
                for (ARC_UnderwritingCaseMember__c member : listUWCaseMemberToInsert) {    
                    member.ARC_Contract__c = contractId;
                    member.ARC_UnderwritingCase__c = newCaseId;
                }

                if (!listUWCaseMemberToInsert.isEmpty()) {
                    Database.UpsertResult[] memberResults = Database.upsert(listUWCaseMemberToInsert, true);
                    for (Database.UpsertResult result : memberResults) {
                        if (!result.isSuccess()) {
                            for (Database.Error error : result.getErrors()) {
                                System.debug('Error upserting UW Case Member in future context: ' + error.getMessage());
                            }
                        } else {
                            System.debug('Successfully inserted UW Case Member: ' + result.getId());
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

        } catch (Exception e) {
            System.debug('Exception while processing UW case and members in future context: ' + e.getMessage() + e.getStackTraceString());
        }
    }

    /**
    * @Description: Inserts a new Policy for the new Contract, including its Insurance Policy Participants, Insurance Policy Coverage and Coverage Participants
    */
    private void insertPolicy_PermanentDML() {
        try {
            Id newContractId = ((Contract)manager.contractsToUpsert.get('PermanentNewborn')).Id;
            Map<String, Object> inputMap = new Map<String, Object>();
            Map<String, Object> outMap = new Map<String, Object>();
            inputMap.put('contractId', newContractId);
            System.debug('manager.newbornsDOB: ' + manager.newbornsDOB);
            inputMap.put('NewbornsDOB', manager.newbornsDOB);
            ARC_PolicyCreation.createAllPolicyRecords(inputMap, outMap);
        } catch (Exception e) {
            System.debug('Exception while inserting policy: ' + e.getMessage() + e.getStackTraceString() + 'for Contract Id: ' + ((Contract)manager.contractsToUpsert.get('PermanentNewborn')).Id);
            throw e;
        }
    }

    ///////////////////////
    // Auxiliary Methods //
    ///////////////////////

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

        Map<Id, Map<String, String>> personAccountToCM = new Map<Id, Map<String, String>> ();

        for (String cnsId : manager.censusGroupToGCM.keySet()) {
            Map<String, vlocity_ins__GroupCensusMember__c> cnsIdToGCM = (Map<String, vlocity_ins__GroupCensusMember__c>)manager.censusGroupToGCM.get(cnsId);
            for (String fakeId : cnsIdToGCM.keySet()) {
                vlocity_ins__GroupCensusMember__c gcm = (vlocity_ins__GroupCensusMember__c)cnsIdToGCM.get(fakeId);
        
                gcm.vlocity_ins__ContactId__c = (String)manager.fakeIdToPersonContactId.get(fakeId);
                gcm.vlocity_ins__SocialSecurityNumber__c = ((vlocity_ins__GroupCensusMember__c)cnsIdToGCM.get(fakeId)).vlocity_ins__SocialSecurityNumber__c;
                gcm.vlocity_ins__RelatedCensusMemberId__c = ((vlocity_ins__GroupCensusMember__c)cnsIdToGCM.get(fakeId)).vlocity_ins__RelatedCensusMemberId__c;
                
                if (personAccountToCM.containsKey(gcm.vlocity_ins__ContactId__c)) {
                    if (manager.cnsIdSpinOff != null && manager.cnsIdSpinOff == gcm.vlocity_ins__CensusId__c) {
                        personAccountToCM.get(gcm.vlocity_ins__ContactId__c).put('spinOff', gcm.Id);
                    }
                    else {
                        personAccountToCM.get(gcm.vlocity_ins__ContactId__c).put('original', gcm.Id);
                    }
                }
                else {
                    if (manager.cnsIdSpinOff != null && manager.cnsIdSpinOff == gcm.vlocity_ins__CensusId__c) {
                        Map<String, String> aux = new Map<String, String> {
                            'spinOff' => gcm.Id
                        };
                        personAccountToCM.put(gcm.vlocity_ins__ContactId__c, aux);
                    }
                    else {
                        Map<String, String> aux = new Map<String, String> {
                            'original' => gcm.Id
                        };
                        personAccountToCM.put(gcm.vlocity_ins__ContactId__c, aux);
                    }
                }

                censusMembersToUpdateContactId.add(gcm);
            }
        }

        for (vlocity_ins__GroupCensusMember__c gcm : censusMembersToUpdateContactId) {
            if (personAccountToCM.containsKey(gcm.vlocity_ins__ContactId__c)) {
                Map<String, String> members = (Map<String, String>)personAccountToCM.get(gcm.vlocity_ins__ContactId__c);
                if (manager.cnsIdSpinOff != null && manager.cnsIdSpinOff == gcm.vlocity_ins__CensusId__c) {
                    gcm.ARC_OldCensusMember__c = members.containsKey('original') ? (Id)members.get('original') : null;
                }
                else if (manager.cnsIdSpinOff != null) {
                    gcm.ARC_NewCensusMember__c =  members.containsKey('spinOff') ? (Id)members.get('spinOff') : null;
                }
            }
        }
        update censusMembersToUpdateContactId;
    }
}