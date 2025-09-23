public class LeadTriggerHandler {

    public void sendFive9SMSOptIn(List<Lead> newLeads) {
		Outbound_Dialer_Settings__mdt domain_record = Outbound_Dialer_Settings__mdt.getInstance('Five9DomainId');
        String domain_id = domain_record.value__c;
        String opt_in_path = '/opt-in/v1/domains/'+ domain_id + '/smsoptinlist/entries/';  
		system.debug('opt_in_path = ' + opt_in_path);
        
        for (Lead lead : newLeads) {

            if (lead.Add_To_Autodialer__c == True){
                // Construct the URL of the external system
                String endpoint = 'callout:Five9_API'+ opt_in_path + lead.Phone;
                system.debug('Phone = ' + lead.Phone);
                sendRequest(endpoint);
            }
        }
    }
    
    @future (callout=true)
    private static void sendRequest(String endpoint){
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        
        Http http = new Http();
        
        // Set the HTTP request parameters
        req.setEndpoint(endpoint);
        req.setMethod('PUT');
        req.setHeader('Content-Length', '0');
        
        // Make the HTTP request
        try {
            res = http.send(req);
            System.debug('HTTP Response Code: ' + res.getStatusCode());
        } catch (Exception e) {
            System.debug('Error making HTTP request: ' + e.getMessage());
        }
    }
}