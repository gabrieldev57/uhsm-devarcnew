public class CallLeadScoreAPI {
    private static final String NAMED_CREDENTIAL = 'callout:Lead_Scoring_API';
    private static final String ENDPOINT_PATH = '/score/';
    
    @InvocableMethod(label='Get Lead Score' description='Calls the lead scoring API and updates the Lead')
    public static List<LeadScoreResult> getLeadScore(List<Id> leadIds) {
        List<LeadScoreResult> results = new List<LeadScoreResult>();
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Id leadId : leadIds) {
            LeadScoreResult result = new LeadScoreResult();
            result.leadId = leadId;
            
            try {
                HttpRequest req = new HttpRequest();
                req.setEndpoint(NAMED_CREDENTIAL + ENDPOINT_PATH + leadId);
                req.setMethod('GET');
                req.setTimeout(30000);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                
                if (res.getStatusCode() == 200) {
                    Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    
                    Decimal score = (Decimal) responseMap.get('score');
                    Decimal scoreUncalibrated = (Decimal) responseMap.get('score_uncalibrated');
                    String modelVersion = (String) responseMap.get('model_version');
                    String scoredAtStr = (String) responseMap.get('scored_at');
                    
                    Datetime scoredAt = parseIsoDatetime(scoredAtStr);
                    
                    Lead leadToUpdate = new Lead(
                        Id = leadId,
                        Conversion_Probability__c = score * 100,
                        Conversion_Probability_Uncalibrated__c = scoreUncalibrated * 100,
                        Score_Generated_Date__c = scoredAt,
                        Model_Used_for_Score__c = modelVersion
                    );
                    leadsToUpdate.add(leadToUpdate);
                    
                    result.score = score;
                    result.success = true;
                    result.message = 'Lead scored successfully: ' + (score * 100).setScale(2) + '%';
                } else {
                    result.success = false;
                    result.message = 'API returned status: ' + res.getStatusCode() + ' - ' + res.getBody();
                }
            } catch (Exception e) {
                result.success = false;
                result.message = 'Error calling API: ' + e.getMessage();
            }
            
            results.add(result);
        }
        
        // Move DML inside its own try/catch
        if (!leadsToUpdate.isEmpty()) {
            try {
                update leadsToUpdate;
            } catch (Exception e) {
                for (LeadScoreResult result : results) {
                    if (result.success) {
                        result.success = false;
                        result.message = 'Score retrieved (' + (result.score * 100).setScale(2) + '%) but failed to update Lead: ' + e.getMessage();
                    }
                }
            }
        }
                
        return results;
    }
    
    private static Datetime parseIsoDatetime(String isoString) {
        if (String.isBlank(isoString)) {
            return null;
        }
        
        try {
            String trimmed = isoString;
            Integer dotIndex = isoString.lastIndexOf('.');
            if (dotIndex > 0 && isoString.length() > dotIndex + 4) {
                trimmed = isoString.substring(0, dotIndex + 4);
            }
            trimmed = trimmed.replace('T', ' ');
            return Datetime.valueOf(trimmed);
        } catch (Exception e) {
            return Datetime.valueOf(isoString.substring(0, 10) + ' 00:00:00');
        }
    }
    
    public class LeadScoreResult {
        @InvocableVariable(label='Lead ID')
        public Id leadId;
        
        @InvocableVariable(label='Score')
        public Decimal score;
        
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Message')
        public String message;
    }
}