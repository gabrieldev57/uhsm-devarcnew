/**
 * @Description: This class is responsible for managing all DML
 * operations related to temporary newborn processing. It executes inserts and updates 
 * sequentially to respect database relationships and dependencies.
 */
public with sharing class ARC_SGNBDML {
    private ARC_SGNBManager manager;

    /**
     * @Description: Main method to manage all DML operations for newborns sequentially.
     * Rollbacks are managed by the OmniScript/Platform if an unhandled exception bubbles up.
     * @param manager: The ARC_SGNBManager instance containing all the prepared data.
     */
    public void manageDML(ARC_SGNBManager manager) {
        this.manager = manager;
        
        try { 
            manageGCM_DML();
            manageAccount_DML();
            managePolRelatedRecords_DML();

            manageContMembership_DML();
            manageMatAndPreexResetDates_DML();
            manageAggregators_DML();
        } catch (Exception e) {
            throw e;
        }
    }

    /**
     * @Description: Inserts temporary newborn census members (vlocity_ins__GroupCensusMember__c).
     */
    private void manageGCM_DML() {
        try {
            if (!manager.mapGCMToInsert.isEmpty()) {
                List<vlocity_ins__GroupCensusMember__c> allGcms = manager.mapGCMToInsert.values();
                
                Database.SaveResult[] results = Database.insert(allGcms, true); 
           
                for (vlocity_ins__GroupCensusMember__c g : allGcms) {
                    System.debug('inserted gcm: ' + g.Id + ' with census id: ' + g.vlocity_ins__CensusId__c);
                }
            }
        } catch (Exception e) {
            throw new IllegalArgumentException('Error inserting Group Census Members: ' + e.getMessage());
        }
    }

    /**
     * @Description: Inserts Person Accounts for newborns, retrieves their new ContactIds, 
     * and links them back to their respective Group Census Member records.
     */
    private void manageAccount_DML() {
        try {
            if (!manager.mapAccToInsert.isEmpty()) {

                for (String fakeId : manager.mapAccToInsert.keySet()) {
                    Account acc = manager.mapAccToInsert.get(fakeId);
                    vlocity_ins__GroupCensusMember__c gcm = manager.mapGCMToInsert.get(fakeId);

                    if (gcm != null && gcm.Id != null) {
                        acc.Census_Member__c = gcm.Id;
                        acc.ARC_CensusMember__pc = gcm.Id;
                    }
                    
                    manager.mapAccToInsert.put(fakeId, acc);
                }

                Database.SaveResult[] results = Database.insert(manager.mapAccToInsert.values(), true); 
                System.debug('accounts: ' + manager.mapAccToInsert);

                List<Account> personAccounts = [SELECT Id, PersonContactId FROM Account WHERE Id IN :manager.mapAccToInsert.values()];
                System.debug('accounts retrieve: ' + personAccounts);

                for (Account personAccount : personAccounts) {
                    for (String fakeId : manager.mapAccToInsert.keySet()) {
                        if (personAccount.Id == manager.mapAccToInsert.get(fakeId).Id) {
                            manager.mapAccIdToContactId.put(fakeId, personAccount.PersonContactId);
                            System.debug('insertedAccount: ' + manager.mapAccToInsert.get(fakeId).Id); 
                        }
                    }
                }
                
                //---------------------------------------------
                // Update GCM with the news contact ids
                //---------------------------------------------
                updateRelatedCensusMembers();
            }
        } catch (Exception e) {
            throw new IllegalArgumentException('Error inserting Person Accounts: ' + e.getMessage());
        }
    }
    
    /**
     * @Description: Inserts Policy Participants and Coverage Participants for the newborns 
     * utilizing the Contact Ids generated in the Account DML step.
     */
    private void managePolRelatedRecords_DML() {
        try {
            if (manager.listPol.isEmpty()) return;

            for (Map<String, InsurancePolicyParticipant> tempMemberIdToPolPart : manager.mapPolIdToPolPart.values()) {
                for (String tempMemberId : tempMemberIdToPolPart.keySet()) {
                    InsurancePolicyParticipant polPart = tempMemberIdToPolPart.get(tempMemberId);
                    polPart.PrimaryParticipantContactId = manager.mapAccIdToContactId.get(tempMemberId);
                    manager.listPolPartToInsert.add(polPart);
                }
            }

            Database.insert(manager.listPolPartToInsert, true);
        
            for (String polId : manager.mapPolIdToCovPart.keySet()) {
                Map<String, ARC_CoverageParticipant__c> tempMemberIdToCovPart = manager.mapPolIdToCovPart.get(polId);
                Map<String, InsurancePolicyParticipant> tempMemberIdToPolPart = manager.mapPolIdToPolPart.get(polId);
                
                for (String tempMemberId : tempMemberIdToCovPart.keySet()) {
                    ARC_CoverageParticipant__c covPart = tempMemberIdToCovPart.get(tempMemberId);
                    
                    covPart.ARC_PolicyParticipant__c = tempMemberIdToPolPart.get(tempMemberId).Id;
                    manager.listCovPartToInsert.add(covPart);
                }
            }
            
            Database.insert(manager.listCovPartToInsert, true);

        } catch (Exception e) {
            throw new IllegalArgumentException('Error inserting Policy/Coverage Participants: ' + e.getMessage());
        }
    }

    /**
     * @Description: Manages Continuous Coverage Date / Last Aggregator Reset / Continuous Membership Date DML operations for temporary newborns
     */
    private void manageContMembership_DML() {
        try {
            if (!manager.mapAccToInsert.isEmpty()) {
                List<Account> personAccounts = manager.mapAccToInsert.values();
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
            throw new IllegalArgumentException('Error managing Continuous Membership DML for newborns: ' + e.getMessage());
        }
    }

     /**
     * @Description: Manages Pre-Existing Conditions Reset Date & Maternity Reset Date DML operations for temporary newborns
     */
    private void manageMatAndPreexResetDates_DML() {
        try {
            if (!manager.mapAccToInsert.isEmpty()) {
                List<Account> personAccounts = manager.mapAccToInsert.values();
                ARC_AccountBenefitDates.RequestsVariables personAccountIds = new ARC_AccountBenefitDates.RequestsVariables();
                personAccountIds.listRecordIds = new List<Id>();
                for (Account personAccount : personAccounts) {
                    personAccountIds.listRecordIds.add(personAccount.Id);
                }
                ARC_AccountBenefitDates.updateAccountBenefitDates(
                    new List<ARC_AccountBenefitDates.RequestsVariables>{ personAccountIds }
                );
            }
        } catch (Exception e) {
            throw new IllegalArgumentException('Error managing Mat & Preex Benefit Dates DML for newborns: ' + e.getMessage());
        }
    }

    /**
     * @Description: Manages aggregators-related DML operations for temporary newborns
     */
    private void manageAggregators_DML() {
        try {
            if (!manager.listPol.isEmpty()) {
                List<String> policyIds = new List<String>();
                for (InsurancePolicy pol : manager.listPol) {
                    policyIds.add('\'' + pol.Id + '\'');
                }
                String whereClause = 'Id IN (' + String.join(policyIds, ', ') + ')';
                System.debug('whereClause: ' + whereClause);
                ARC_CreateMissingAggregatorsV2 aggregatorsBatch = new ARC_CreateMissingAggregatorsV2(whereClause, true, false);
                Database.executeBatch(aggregatorsBatch, 100);
            }
        } catch (Exception e) {
           throw new IllegalArgumentException('Error managing aggregators DML for newborns: ' + e.getMessage());
        }
    }

    ///////////////////////
    // Auxiliary Methods //
    ///////////////////////

    /**
     * @Description: Updates inserted Census Member records with the newly created Contact IDs.
     */
    private void updateRelatedCensusMembers() {
        List<vlocity_ins__GroupCensusMember__c> censusMembersToUpdateContactId = new List<vlocity_ins__GroupCensusMember__c>();

        for (String fakeId : manager.mapGCMToInsert.keySet()) {
            vlocity_ins__GroupCensusMember__c gcm = manager.mapGCMToInsert.get(fakeId);
            String contactId = manager.mapAccIdToContactId.get(fakeId);
            
            if (contactId != null) {
                gcm.vlocity_ins__ContactId__c = contactId;
                censusMembersToUpdateContactId.add(gcm);
            }
        }

        if (!censusMembersToUpdateContactId.isEmpty()) {
            update censusMembersToUpdateContactId;
        }
    }
}