public class ARC_HAXClaimCheckNumberUpdaterBatch implements Database.Batchable<SObject>{
    private List<AggregateResult> aggregated_results;

    // Constructor to receive the list
    public ARC_HAXClaimCheckNumberUpdaterBatch(List<AggregateResult> aggregated_results_parameter) {
        this.aggregated_results = aggregated_results_parameter;
    }

    // start method to return an iterable of the discounts
    public Iterable<AggregateResult> start(Database.BatchableContext bc) {
        return aggregated_results;
    }

    // Execute method to aggregate duplicate claims
    public void execute(Database.BatchableContext BC, List<AggregateResult> scope) {

        Set<String> duplicated_check_numbers = new Set<String>();
        for (AggregateResult ar : scope) {
            duplicated_check_numbers.add((String) ar.get('ARC_CheckNumber__c'));
        }

        List<Claim> duplicated_claims = [SELECT Id, ARC_CheckNumber__c FROM Claim WHERE ARC_CheckNumber__c IN: duplicated_check_numbers];

        Map<String, List<Claim>> checkNumberMap = new Map<String,List<Claim>>();
        for (Claim c : duplicated_claims) {
            if (checkNumberMap.containsKey(c.ARC_CheckNumber__c) == false) {
                checkNumberMap.put(c.ARC_CheckNumber__c, new List<Claim>());
            }
            checkNumberMap.get(c.ARC_CheckNumber__c).add(c);
        }

        // Recorro el mapa y pongo el numero de serial _1 _2 _3
        List<Claim> claimsToUpdate = new List<Claim>();

        for (String key : checkNumberMap.keySet()) {
            List<Claim> claims_with_same_checkNumber = checkNumberMap.get(key);
            if (claims_with_same_checkNumber.size() > 1) {
                for (Integer i = 0; i < claims_with_same_checkNumber.size(); i++) {
                    Claim c = claims_with_same_checkNumber[i];
                    c.ARC_CheckNumber__c = c.ARC_CheckNumber__c + '-' + (i + 1);
                    claimsToUpdate.add(c);
                }
            }
        }

        if (!claimsToUpdate.isEmpty()) {
            update claimsToUpdate;
        }

    }

    // Finish method to process duplicates and update records
    public void finish(Database.BatchableContext BC) {
    }
}