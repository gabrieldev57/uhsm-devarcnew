public with sharing class LeadConvertToExistingAccount {

    @InvocableMethod(label='Convert Lead to Existing Person Account')
    public static void convertLeads(List<Request> requests) {
        List<Database.LeadConvert> conversions = new List<Database.LeadConvert>();

        for (Request req : requests) {
            if (req.leadId == null || req.accountId == null) {
                continue; // skip bad inputs
            }

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(req.leadId);
            lc.setAccountId(req.accountId); // existing Person Account
            lc.setDoNotCreateOpportunity(true);
            lc.setConvertedStatus(getConvertedStatus());

            conversions.add(lc);
        }

        List<Database.LeadConvertResult> results = Database.convertLead(conversions, false);

        // optional: you can add error handling here
        for (Database.LeadConvertResult res : results) {
            if (!res.isSuccess()) {
                System.debug('Lead conversion failed: ' + res.getErrors()[0].getMessage());
            }
        }
    }

    public class Request {
        @InvocableVariable(required=true)
        public Id leadId;

        @InvocableVariable(required=true)
        public Id accountId; // must be a Person Account
    }

    private static String getConvertedStatus() {
        return [SELECT MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel;
    }
}