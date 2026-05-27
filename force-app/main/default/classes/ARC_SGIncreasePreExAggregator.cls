public with sharing class ARC_SGIncreasePreExAggregator implements Database.Batchable<SObject>, Schedulable {

    // Scheduler method from the Schedulable interface that triggers the batch execution periodically
    public void execute(SchedulableContext SC) {
        Database.executebatch(new ARC_SGIncreasePreExAggregator());
    }

    // Constants for benefit tier limits
    private static final Integer LIMIT_TIER_1 = 15000;
    private static final Integer LIMIT_TIER_2 = 25000;
    private static final Integer LIMIT_TIER_3 = 50000;
    
    // Codes used for identification of aggregator types
    private static final String CODE_PREEX = 'PREEX__c';

    // Date variables to hold the current date and calculated past dates
    private final Date today;
    private final Date todayMinus1Year;
    private final Date todayMinus2Years;
    private final Date todayMinus3Years;

    // Map to hold the Account's Coverage Periods
    Map<Id, List<Map<String,Object>>> coveragePeriods;

    // Map to hold the Insurance Policy Participants by its Policy Id
    Map<Id, List<InsurancePolicyParticipant>> mapPolicyIdToPolicyParticipant;
    Map<Id, InsurancePolicyParticipant> mapContactIdToPolicyParticipant;

    // Map to hold the Participant Aggregators and their corresponding Aggregators
    Map<ARC_ParticipantAggregator__c, ARC_Aggregator__c> mapParticipantAggregatorToAggregator;

    // Lists to hold the Aggregators and Participant Aggregators to insert
    List<ARC_Aggregator__c> aggregatorsToInsert;
    List<ARC_ParticipantAggregator__c> participantAggregatorsToInsert;

    // Map to hold the Active Policy by Account Id
    Map<Id, InsurancePolicy> mapAccountIdToActivePolicy;

    // Variable to hold the Id of Individual record type for Aggregators
    Id individualRecordTypeId;

    // Small Group Record Type Id for Accounts
    Id smallGroupRTIdAccount;

    // Constructor to initialize date-related variables
    public ARC_SGIncreasePreExAggregator() {
        this.today = Date.today();
        this.todayMinus1Year = today.addYears(-1);
        this.todayMinus2Years = today.addYears(-2);
        this.todayMinus3Years = today.addYears(-3);
        this.coveragePeriods = new Map<Id, List<Map<String,Object>>>();
        this.individualRecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Individual' AND SobjectType = 'ARC_Aggregator__c' LIMIT 1].Id;
        this.mapPolicyIdToPolicyParticipant = new Map<Id, List<InsurancePolicyParticipant>>();
        this.mapContactIdToPolicyParticipant = new Map<Id, InsurancePolicyParticipant>();
        this.mapParticipantAggregatorToAggregator = new Map<ARC_ParticipantAggregator__c, ARC_Aggregator__c>();
        this.aggregatorsToInsert = new List<ARC_Aggregator__c>();
        this.participantAggregatorsToInsert = new List<ARC_ParticipantAggregator__c>();
        this.mapAccountIdToActivePolicy = new Map<Id, InsurancePolicy>();
        this.smallGroupRTIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Small Group Person Account').getRecordTypeId();
    }

    // Method to define the batch's starting query
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            [
               SELECT Id, Name, Census_Member__r.vlocity_ins__ContactId__c, ARC_PrimaryMemberAccount__c,
                    (SELECT Id, 
                            Name,
                            ARC_StartDate__c, 
                            ARC_LimitValue__c, 
                            ARC_BenefitYear__c,
                            ARC_Member__c,
                            ARC_Member__r.Census_Member__r.vlocity_ins__ContactId__c
                     FROM Aggregators__r 
                     WHERE ARC_Code__c = :CODE_PREEX
                        AND ARC_IsInactive__c = false
                     ORDER BY ARC_StartDate__c DESC
                     LIMIT 1)
                FROM Account
                WHERE ARC_PreExistingResetDate__c IN (:todayMinus1Year, :todayMinus2Years)
                AND RecordTypeId = :smallGroupRTIdAccount
                AND IsActive = true
            ]
        );
    }

    // Method to process each batch of policies
    public void execute(Database.BatchableContext context, List<Account> accounts) {
        // Save the retrieved accounts in a map to get the Ids easily
        Map<Id, Account> mapAccount = new Map<Id, Account>(accounts);
        coveragePeriods = ARC_SMBUtility.mapCoveragePeriods(new List<Id>(mapAccount.keySet()), CODE_PREEX);

        // Get employee Account Id
        Set<String> employeeAccountIds = new Set<String>();
        System.debug('Accounts found: ' + accounts);
        for (Account accountTemp : accounts) {
            System.debug('Account name: ' + accountTemp.Name);
            System.debug('Account ARC_PrimaryMemberAccount__c: ' + accountTemp.ARC_PrimaryMemberAccount__c);
            if (accountTemp.ARC_PrimaryMemberAccount__c != null) {
                employeeAccountIds.add(String.valueOf(accountTemp.ARC_PrimaryMemberAccount__c));
            } else {
                employeeAccountIds.add(String.valueOf(accountTemp.Id));
            }
        }
        System.debug('employeeAccountIds: '+ employeeAccountIds);
        
        Map<Id, InsurancePolicy> activePolicies = new Map<Id, InsurancePolicy> (
                                                  [SELECT Id, NameInsuredId
                                                   FROM InsurancePolicy
                                                   WHERE NameInsuredId IN :employeeAccountIds
                                                   AND Status = 'Activated']
                                                   );

        System.debug('activePolicies: '+ activePolicies);

        // Map the Active Policies by Account Id
        for (Account accountTemp : accounts) {
            for (InsurancePolicy policyTemp : activePolicies.values()) {
                if (accountTemp.Id == policyTemp.NameInsuredId || accountTemp.ARC_PrimaryMemberAccount__c == policyTemp.NameInsuredId) {
                    mapAccountIdToActivePolicy.put(accountTemp.Id, policyTemp);
                }
            }
        }
        System.debug('mapAccountIdToActivePolicy: '+ mapAccountIdToActivePolicy);

        // Get all Policy Participants
        List<InsurancePolicyParticipant> policyParticipantsList = [SELECT Id, 
                                                                          InsurancePolicyId,
                                                                          PrimaryParticipantContactId
                                                                   FROM InsurancePolicyParticipant
                                                                   WHERE InsurancePolicyId IN :activePolicies.keySet()];

        // Store the Policy Participants in a Map with the Primary Participant Contact Id as key
        for (InsurancePolicyParticipant policyParticipantTemp : policyParticipantsList) {
            mapContactIdToPolicyParticipant.put(policyParticipantTemp.PrimaryParticipantContactId, policyParticipantTemp);
        }

        // Iterate over each Account
        for (Account accountTemp : accounts) {
            // Get the Aggregators from the Account list
            List<ARC_Aggregator__c> oldAggregators = accountTemp.Aggregators__r;

            // Verify if it is necessary to create a new Pre-Existing Aggregator
            for (ARC_Aggregator__c oldAggregatorTemp : oldAggregators) {
                // Get the expected Benefit Year from the Account
                List<String> calculateAggregators = ARC_SMBUtility.calculateAggregators(coveragePeriods.get(oldAggregatorTemp.ARC_Member__c), CODE_PREEX);
                String lastBenefitYear = calculateAggregators[calculateAggregators.size() - 1].split('\\|\\|')[2];
                System.debug('lastBenefitYear: ' + lastBenefitYear);

                if (
                    (oldAggregatorTemp.ARC_BenefitYear__c == 'BY1' && lastBenefitYear == 'BY2') ||
                    (oldAggregatorTemp.ARC_BenefitYear__c == 'BY1' && lastBenefitYear == 'BY3') ||
                    (oldAggregatorTemp.ARC_BenefitYear__c == 'BY2' && lastBenefitYear == 'BY3')
                    ) 
                {
                    createNewPreExistingAggregators(oldAggregatorTemp, lastBenefitYear);
                }
            }
        }

        // Insert the new Pre-Existing Aggregators
        if (!aggregatorsToInsert.isEmpty()) {
            System.debug('Inserting new Pre-Existing Aggregators: ' + aggregatorsToInsert);
            insert aggregatorsToInsert;
        }

        // Insert the new Participant Aggregators
        if (!participantAggregatorsToInsert.isEmpty()) {
            System.debug('Inserting new Participant Aggregators: ' + participantAggregatorsToInsert);
            // Set the Participant Aggregators' Parent Aggregator
            for (ARC_ParticipantAggregator__c participantAggregator : mapParticipantAggregatorToAggregator.keySet()) {
                participantAggregator.ARC_Aggregator__c = mapParticipantAggregatorToAggregator.get(participantAggregator).Id;
            }
            insert participantAggregatorsToInsert;
        }
    }

    // Method to create the new Pre-Existing Aggregators and Participant Aggregators and store them in a list
    private void createNewPreExistingAggregators(ARC_Aggregator__c oldAggregatorTemp, String lastBenefitYear) {
        // New Pre-Existing Aggregator
        ARC_Aggregator__c newAggregator = new ARC_Aggregator__c();
        newAggregator.Name = 'Pre Existing Conditions';
        newAggregator.ARC_Code__c = CODE_PREEX;
        newAggregator.ARC_Member__c = oldAggregatorTemp.ARC_Member__c;
        // Create Aggregator in Active Policy
        newAggregator.ARC_CreatedIn__c = mapAccountIdToActivePolicy.get(oldAggregatorTemp.ARC_Member__c).Id;
        newAggregator.RecordTypeId = individualRecordTypeId;
        newAggregator.ARC_Type__c = 'Currency';
        newAggregator.ARC_StartDate__c = today;
        newAggregator.ARC_EndDate__c = today.addYears(1).addDays(-1);

        newAggregator.ARC_BenefitYear__c = lastBenefitYear;

        if (lastBenefitYear == 'BY2') {
            newAggregator.ARC_LimitValue__c = LIMIT_TIER_2;
        } else if (lastBenefitYear == 'BY3') {
            newAggregator.ARC_LimitValue__c = LIMIT_TIER_3;
        }

        // New Participant Aggregator
        ARC_ParticipantAggregator__c newParticipantAggregator = new ARC_ParticipantAggregator__c();
        newParticipantAggregator.Name = 'Pre Existing Conditions';
        // Get the Active Policy and the corresponding Policy Participant
        InsurancePolicyParticipant currentPolicyParticipant = mapContactIdToPolicyParticipant.get(oldAggregatorTemp.ARC_Member__r.Census_Member__r.vlocity_ins__ContactId__c);
        newParticipantAggregator.ARC_Policy__c = currentPolicyParticipant.InsurancePolicyId;
        newParticipantAggregator.ARC_PolicyParticipant__c = currentPolicyParticipant.Id;

        // Add the Aggregator and Participant Aggregators to their lists to be inserted
        aggregatorsToInsert.add(newAggregator);
        participantAggregatorsToInsert.add(newParticipantAggregator);
        mapParticipantAggregatorToAggregator.put(newParticipantAggregator, newAggregator);
    }

    // Final method to execute after all batches are processed
    public void finish(Database.BatchableContext context) {
        // Optional: Add logic to execute after batch completion (e.g., logging)
    }
}