public class ARC_IncreasePreExAggregator implements Database.Batchable<SObject>, Schedulable {
    // Scheduler method from the Schedulable interface that triggers the batch execution periodically
    public void execute(SchedulableContext SC) {
        Database.executebatch(new ARC_IncreasePreExAggregator());
    }

    // Constants for benefit tier limits
    private static final Integer LIMIT_TIER_1 = 15000;
    private static final Integer LIMIT_TIER_2 = 25000;
    private static final Integer LIMIT_TIER_3 = 50000;
    private static final Integer LIMIT_MAX = 99999999;
    
    // Codes used for identification of aggregator types
    private static final String CODE_PREEX = 'PREEX__c';
    private static final String CODE_MAT = 'MAT__c';

    // Date variables to hold the current date and calculated past dates
    private final Date today;
    private final Date todayMinus1Year;
    private final Date todayMinus2Years;
    private final Date todayMinus3Years;
    
    // Strings to hold current and next year
    private final String currentYear;
    private final String nextYear;

    // Constructor to initialize date-related variables
    public ARC_IncreasePreExAggregator() {
        this.today = Date.today();
        this.todayMinus1Year = today.addYears(-1);
        this.todayMinus2Years = today.addYears(-2);
        this.todayMinus3Years = today.addYears(-3);
        this.currentYear = String.valueOf(today.year());
        this.nextYear = String.valueOf(today.year() + 1);
    }

    // Method to define the batch's starting query
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    ARC_Contract__r.Status,
                    (SELECT Id FROM RenewedInsurancePolicies WHERE ARC_isActive__c = TRUE),
                    (
                        SELECT
                            Id,
                            ARC_LimitValue__c,
                            ARC_Code__c,
                            ARC_CreatedIn__r.ARC_EffectiveDate__c,
                            ARC_BY1_Date__c,
                            ARC_BY1_Current__c,
                            ARC_BY1_Limit__c,
                            ARC_BY2_Date__c,
                            ARC_BY2_Current__c,
                            ARC_BY2_Limit__c,
                            ARC_BY3_Date__c,
                            ARC_BY3_Current__c,
                            ARC_BY3_Limit__c,
                            ARC_CurrentValue__c
                        FROM Aggregators__r
                        WHERE ARC_Code__c IN (:CODE_PREEX, :CODE_MAT) 
                          AND ARC_Year__c IN (:currentYear, :nextYear)
                    )
                FROM InsurancePolicy
                WHERE ARC_EffectiveDate__c IN (:todayMinus1Year, :todayMinus2Years, :todayMinus3Years) 
                  AND ARC_Contract__r.Status != 'Voided'
            ]
        );
    }

    // Method to process each batch of policies
    public void execute(Database.BatchableContext context, List<InsurancePolicy> policiesForTierUpgrade) {
        List<ARC_Aggregator__c> aggregatorsToUpdate = new List<ARC_Aggregator__c>();

        // Iterate through each insurance policy in the batch
        for (InsurancePolicy policy : policiesForTierUpgrade) {
            Boolean contractIsTerminated = policy.ARC_Contract__r.Status == 'Terminated';
            Boolean contractIsVoided = policy.ARC_Contract__r.Status == 'Voided';
            Boolean hasActiveRenewContract = !policy.RenewedInsurancePolicies.isEmpty();
            Boolean hasAggregators = !policy.Aggregators__r.isEmpty();

            // Determine if the aggregator benefit tier limits should increase
            if (((contractIsTerminated && hasActiveRenewContract) || (!contractIsVoided && !contractIsTerminated)) && hasAggregators) {
                List<ARC_Aggregator__c> aggregatorsForBenefitTierUpgrade = policy.Aggregators__r;
                try {
                    for (ARC_Aggregator__c aggregator : aggregatorsForBenefitTierUpgrade) {
                        if (aggregator.ARC_Code__c == CODE_PREEX) {
                            // Increase limits for pre-existing conditions based on current tier
                            updatePreExAggregatorLimit(aggregator);
                        } else if (
                            // For maternity, increase to max amount after 2 years
                            aggregator.ARC_Code__c == CODE_MAT &&
                            aggregator?.ARC_CreatedIn__r?.ARC_EffectiveDate__c != null &&
                            aggregator?.ARC_CreatedIn__r?.ARC_EffectiveDate__c == todayMinus2Years
                        ) {
                            aggregator.ARC_LimitValue__c = LIMIT_MAX; // Set limit to max
                        }
                    }
                    aggregatorsToUpdate.addAll(aggregatorsForBenefitTierUpgrade);
                } catch (Exception e) {
                    handleBatchError(e); // Handle any errors during processing
                }
            }
        }

        // Update the aggregators with new limit values
        if (!aggregatorsToUpdate.isEmpty()) {
            update aggregatorsToUpdate;
        }
    }

    // Final method to execute after all batches are processed
    public void finish(Database.BatchableContext context) {
        // Optional: Add logic to execute after batch completion (e.g., logging)
    }

    // Handle errors during batch processing
    private void handleBatchError(Exception e) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ 'ignacio.ferreiro@arcsona.com', 'agustin.garay@arcsona.com' });
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

    // Update the limit value for pre-existing condition aggregators based on their current tier
    private void updatePreExAggregatorLimit(ARC_Aggregator__c aggregator) {
        if (aggregator.ARC_LimitValue__c == LIMIT_TIER_1 && aggregator.ARC_BY1_Limit__c == null && aggregator.ARC_BY1_Date__c == null && aggregator.ARC_BY1_Current__c == null) {
            increaseBenefitTierLimit(LIMIT_TIER_2, aggregator);
        } else if (aggregator.ARC_LimitValue__c == LIMIT_TIER_2 && aggregator.ARC_BY2_Limit__c == null && aggregator.ARC_BY2_Date__c == null && aggregator.ARC_BY2_Current__c == null) {
            increaseBenefitTierLimit(LIMIT_TIER_3, aggregator);
        } else if (aggregator.ARC_LimitValue__c == LIMIT_TIER_3 && aggregator.ARC_BY3_Limit__c == null && aggregator.ARC_BY3_Date__c == null && aggregator.ARC_BY3_Current__c == null) {
            increaseBenefitTierLimit(LIMIT_MAX, aggregator);
        }
    }

    // Method to increase the benefit tier limit for the aggregator
    private void increaseBenefitTierLimit(Integer newTier, ARC_Aggregator__c aggregator) {
        if (newTier == LIMIT_TIER_2) {
            aggregator.ARC_BY1_Limit__c = aggregator.ARC_LimitValue__c;
            aggregator.ARC_LimitValue__c = LIMIT_TIER_2;
            aggregator.ARC_BY1_Date__c = today;
            aggregator.ARC_BY1_Current__c = aggregator.ARC_CurrentValue__c;
        } else if (newTier == LIMIT_TIER_3) {
            aggregator.ARC_BY2_Limit__c = aggregator.ARC_LimitValue__c;
            aggregator.ARC_LimitValue__c = LIMIT_TIER_3;
            aggregator.ARC_BY2_Date__c = today;
            aggregator.ARC_BY2_Current__c = aggregator.ARC_CurrentValue__c;
        } else if (newTier == LIMIT_MAX) {
            aggregator.ARC_BY3_Limit__c = aggregator.ARC_LimitValue__c;
            aggregator.ARC_LimitValue__c = LIMIT_MAX;
            aggregator.ARC_BY3_Date__c = today;
            aggregator.ARC_BY3_Current__c = aggregator.ARC_CurrentValue__c;
        }
    }
}