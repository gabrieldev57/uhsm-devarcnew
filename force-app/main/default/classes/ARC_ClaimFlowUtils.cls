public with sharing class ARC_ClaimFlowUtils {


    public class RecalculateTotalsInput {
        @InvocableVariable(label = 'Claim Id' required=true)
        public String claimId;
    }
    //String claimId
    @InvocableMethod(label='Recalculate Claim Totals' description='Recalculate claim totals based on claim coverage payment details.')
    public static void recalculateTotals(List<RecalculateTotalsInput> inputs) {
        Set<Id> clmIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();

        for (RecalculateTotalsInput input : inputs) {
            clmIds.add(input.claimId);
        }

        ARC_ClaimLineItemTriggersHandler.recalculateTotals(clmIds);

        Database.executeBatch(new ARC_ZelisClaimsFileBatch(clmIds, false, null));

    }

}