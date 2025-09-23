public with sharing class ARC_ValidateSeattledTransaction {

    @AuraEnabled public static List<String> validateTransactionSettledDate(List<String> transaction_id){

        List<String> ret = new List<String>();
        ChargentOrders__Transaction__c transactionRecord = [SELECT ChargentOrders__Gateway_ID__c, ChargentOrders__Bank_Transfer_Settlement_Date__c 
                                                        	FROM ChargentOrders__Transaction__c
                                                            WHERE Id=:transaction_id[0]];

         if(transactionRecord.ChargentOrders__Bank_Transfer_Settlement_Date__c != null){
            ret.add(String.valueOf(transactionRecord.ChargentOrders__Bank_Transfer_Settlement_Date__c));
            return ret;
        }

 

        ARC_ValidateSeattledTransaction__mdt credentialInput = ARC_ValidateSeattledTransaction__mdt.getall().values()[0];
        String APIAccessID = credentialInput.APIAccessID__c;
        String APISecureKey = credentialInput.APISecureKey__c;
        String org_id = credentialInput.org_id__c;
        String loc_id = credentialInput.loc_id__c;
        String orgUrl = credentialInput.orgUrl__c;
        String credentials = APIAccessID + ':' + APISecureKey;

 

        String encodedCredentials = EncodingUtil.base64Encode(Blob.valueOf(credentials));


        String transaction_idValue = transactionRecord.ChargentOrders__Gateway_ID__c;

        HttpRequest req = new HttpRequest();
        req.setEndpoint(orgUrl + org_id + '/locations/' + loc_id + '/transactions/' + transaction_idValue + '/settlements/');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-Forte-Auth-Organization-Id', org_id);
        req.setHeader('Authorization', 'Basic ' + encodedCredentials);
		
 

        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> jsonRes = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> results = (List<Object>) jsonRes.get('results');
            if ( results != null && results.size() > 0) {
                Map<String, Object> result = (Map<String, Object>) results[0];
                if ( result.get('settle_date') != null ){
                    ARC_ValidateSeattledTransaction.updateTransaction(transactionRecord.Id, (DateTime)JSON.deserialize('"' + result.get('settle_date') + '"', DateTime.class));
                    ret.add(String.valueOf(result.get('settle_date')));
                    
                    return ret;
                }  
                return ret;           
            } else{
                return ret;
            }
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
            return ret;
            // 'Error: ' + res.getStatusCode() + ' - ' + res.getBody();
        }

    }

    @future
    public static void updateTransaction (Id transactionRecordId, Datetime settleDate) {
        ChargentOrders__Transaction__c transactionRecord = [SELECT ChargentOrders__Gateway_ID__c, ChargentOrders__Bank_Transfer_Settlement_Date__c FROM ChargentOrders__Transaction__c WHERE Id=:transactionRecordId];
        transactionRecord.ChargentOrders__Bank_Transfer_Settlement_Date__c = settleDate;
        update transactionRecord;
    }
 

}