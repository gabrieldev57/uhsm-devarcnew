public without sharing class ARC_DocuSignApiVoidEnvelope {

    @InvocableMethod(label='Void Envelope' description='Takes the Id from DocuSign and expires the given envelope')
    public static void FlowActionVoidEnvelope(List<String> envelopeId) {
        // Call an asynchronous method for the callout
        voidEnvelopeAsync(envelopeId);
    }

    @future(callout=true)
    public static void voidEnvelopeAsync(List<String> envelopeId) {

        String domain = [SELECT Domain FROM Domain WHERE HttpsOption = 'SitesAlt' LIMIT 1].Domain;
        String docuSignAccountId = ARC_DocuSignApi.getDocuSignAccountId();

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DocuSign/restapi/v2.1/accounts/'+docuSignAccountId+'/envelopes/'+ envelopeId[0]);
        req.setMethod('PUT');
        req.setBody('{"status": "voided","voidedReason": "Case has been closed."}');
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('Void Envelop Endpoint: ' + req.getEndpoint());    
        System.debug('Void Envelope Response: ' + res.getBody());
    }




}