public class ARC_IncreasePreExAggregatorPOC implements Database.Batchable<SObject>, Schedulable {
    // Scheduler method from the Schedulable interface that triggers the batch execution periodically
    public void execute(SchedulableContext SC) {
        Database.executebatch(new ARC_IncreasePreExAggregatorPOC());
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

    // Individual & Family Record Type Id for Account
    Id accountIndividualAndFamilyRTId;

    // Constructor to initialize date-related variables
    public ARC_IncreasePreExAggregatorPOC() {
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
        this.accountIndividualAndFamilyRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Individual and Family Person Account').getRecordTypeId();
    }

    // Method to define the batch's starting query
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            [
               SELECT Id, Name, Census_Member__r.vlocity_ins__ContactId__c, Census_Member__r.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c,
                    (SELECT Id, 
                            Name,
                            ARC_StartDate__c, 
                            ARC_LimitValue__c, 
                            ARC_BenefitYear__c,
                            ARC_Member__r.Census_Member__r.vlocity_ins__ContactId__c
                     FROM Aggregators__r 
                     WHERE ARC_Code__c = :CODE_PREEX
                        AND ARC_IsInactive__c = false
                     ORDER BY ARC_StartDate__c DESC
                     LIMIT 1)
                FROM Account
                WHERE ARC_PreExistingResetDate__c IN (:todayMinus1Year, :todayMinus2Years)
                AND RecordTypeId = :accountIndividualAndFamilyRTId
                AND IsActive = true
            ]
        );
    }

    // Method to process each batch of policies
    public void execute(Database.BatchableContext context, List<Account> accounts) {
        // Save the retrieved accounts in a map to get the Ids easily
        Map<Id, Account> mapAccount = new Map<Id, Account>(accounts);
        coveragePeriods = ARC_SMBUtility.mapCoveragePeriods(new List<Id>(mapAccount.keySet()), CODE_PREEX);
        System.debug('Coverage Periods: ' + coveragePeriods);

        // Get Active Contracts related to the Accounts
        Set<Id> groupIds = new Set<Id>();

        for (Account accountTemp : accounts) {
            System.debug('Debug by Gabriel, list of Accounts found -------> ' + accountTemp.Name);
            System.debug('Debug by Gabriel, list of Account Ids found -------> ' + accountTemp.Id);

            groupIds.add(accountTemp.Census_Member__r.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c);
        }

        List<Contract> activeContracts = [SELECT Id, Account.Name,
                                                 AccountId,
                                                 (SELECT Id
                                                 FROM Insurance_Policies__r)
                                          FROM Contract
                                          WHERE AccountId IN :groupIds
                                          AND Status = 'Activated'];
        System.debug('Debug by Gabriel, groupIds found -----> ' + groupIds);
        
        // Get all Active Policies
        Set<Id> activePolicyIds = new Set<Id>();

        for (Contract contractTemp : activeContracts) {
            activePolicyIds.add(contractTemp.Insurance_Policies__r[0].Id);
        }

        // Map the Active Policies by Account Id
        for (Account accountTemp : accounts) {
            for (Contract contractTemp : activeContracts) {
                if (accountTemp.Census_Member__r.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c == contractTemp.AccountId) {
                    mapAccountIdToActivePolicy.put(accountTemp.Id, contractTemp.Insurance_Policies__r[0]);
                }
            }
        }

        System.debug('Debug by Gabriel, Active Policies -------> ' + activePolicyIds);
        // Get all Policy Participants
        List<InsurancePolicyParticipant> policyParticipantsList = [SELECT Id, 
                                                                          InsurancePolicyId,
                                                                          PrimaryParticipantContactId
                                                                   FROM InsurancePolicyParticipant
                                                                   WHERE InsurancePolicyId IN :activePolicyIds];

        // Store the Policy Participants in a Map with the AccountId as key
        for (InsurancePolicyParticipant policyParticipantTemp : policyParticipantsList) {
            mapContactIdToPolicyParticipant.put(policyParticipantTemp.PrimaryParticipantContactId, policyParticipantTemp);
        }

        // Iterate over each Account
        for (Account accountTemp : accounts) {
            // Get the Aggregators from the Account list
            List<ARC_Aggregator__c> oldAggregators = accountTemp.Aggregators__r;

            // Verify if is necessary to create a new Pre-Existing Aggregator
            for (ARC_Aggregator__c oldAggregatorTemp : oldAggregators) {
                // Get the expected Benefit Year from the Account
                List<String> calculateAggregators = ARC_SMBUtility.calculateAggregators(
                    coveragePeriods.get(oldAggregatorTemp.ARC_Member__c),
                    CODE_PREEX
                );

                if (calculateAggregators == null || calculateAggregators.isEmpty()) {
                    continue;
                }

                String lastBenefitYear = calculateAggregators[calculateAggregators.size() - 1].split('\\|\\|')[2];

                if (
                    (oldAggregatorTemp.ARC_BenefitYear__c == 'BY1' && lastBenefitYear == 'BY2') ||
                    (oldAggregatorTemp.ARC_BenefitYear__c == 'BY1' && lastBenefitYear == 'BY3') ||
                    (oldAggregatorTemp.ARC_BenefitYear__c == 'BY2' && lastBenefitYear == 'BY3')
                ) {
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

    @TestVisible
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
        newParticipantAggregator.ARC_ConsumedValue__c = 0;

        // Add the Aggregator and Participant Aggregators to their lists to be inserted
        aggregatorsToInsert.add(newAggregator);
        participantAggregatorsToInsert.add(newParticipantAggregator);
        mapParticipantAggregatorToAggregator.put(newParticipantAggregator, newAggregator);
    }

    // Final method to execute after all batches are processed
    public void finish(Database.BatchableContext context) {
        // Optional: Add logic to execute after batch completion (e.g., logging)
    }

    // Handle errors during batch processing
    private void handleBatchError(Exception e) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ 'francisco.caliaba@arcsona.com' });
        email.setSubject('Apex Batch Error - ARC_IncreasePreExAggregator');

        // Construct the email body with error details
        String body = 'An error occurred in the trigger ARC_IncreasePreExAggregator.\n\n';
        body += 'Error Message: ' + e.getMessage() + '\n';
        body += 'Stack Trace: ' + e.getStackTraceString() + '\n\n';
        body += 'Please review and take appropriate action.';
        email.setPlainTextBody(body);

        // Send the error notification email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
    }
}