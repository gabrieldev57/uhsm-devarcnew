global with sharing class ARC_EFTForm implements vlocity_ins.VlocityOpenInterface{
    
        public Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        switch on methodName {
            when 'getData' {
                getData(input, outMap, options);
            }
            when 'updateCase' {
                updateCase(input, outMap, options);
            }
        }
        return true;
    }

    public static void getData(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){
        String caseId = (String) inputMap.get('caseId');
        Case caseRecord = [SELECT Id,ARC_LastDocuSignEnvelopeId__c, ARC_LastDocuSignEnvelopeStatus__c FROM Case WHERE Id =: caseId];
        Map<String,Object> docusignValuesMap = ARC_DocuSignApi.formatDocusignResponse(ARC_DocuSignApi.httpGetRecipientsTabs(caseRecord.ARC_LastDocuSignEnvelopeId__c));
        outMap.put('TXT_Email', docusignValuesMap.get('EmailAddress')); 
        outMap.put('RecipientName', docusignValuesMap.get('FullName')); 
        outMap.putAll(docusignValuesMap);
    }

    public static void updateCase(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options){
        Case caseRecord = new Case(
            Id = (String) inputMap.get('caseId'),
            ARC_LastDocuSignEnvelopeId__c = (String) inputMap.get('envelopeId'),
            ARC_LastDocuSignEnvelopeStatus__c = (String) inputMap.get('envelopeStatus')
        );
        update caseRecord;
    }


}