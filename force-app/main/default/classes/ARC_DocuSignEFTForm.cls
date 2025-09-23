public with sharing class ARC_DocuSignEFTForm {

    @InvocableMethod(label='Send EFT Form' description='Takes the Cases and sends a DocuSign EFT Form')
    public static void flowActionSendEFTFormEnvelope(List<Id> casesInput) {
        List<Case> casesToUpdate = [SELECT Id, ARC_Reason__c, ARC_LastDocuSignEnvelopeId__c, ARC_CensusMember__c, (SELECT Id, ChargentOrders__Amount__c FROM Transactions__r ORDER BY LastModifiedDate DESC LIMIT 1) FROM Case WHERE Id IN :casesInput];
        List<vlocity_ins__VlocityDocuSignTemplate__c> envelope = [SELECT Id,Name,vlocity_ins__TemplateIdentifier__c FROM vlocity_ins__VlocityDocuSignTemplate__c WHERE Name = 'WeShare healthcare by UHSM EFT Form' ORDER BY LastModifiedDate DESC];
        Map<Id, String> caseToEnvelopeMap = new Map<Id, String>();
        Set<Id> censusMemberIds = new Set<Id>();
        for (Case case_i : casesToUpdate) {
            censusMemberIds.add(case_i.ARC_CensusMember__c);
        }
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id,vlocity_ins__CensusId__c, vlocity_ins__Birthdate__c, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, Name, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressState__c, ARC_PhysicalAddressZipCode__c, ARC_PhysicalAddressStreet__c, vlocity_ins__Email__c, ARC_Phone__c, Member_ID__c,vlocity_ins__ContactId__r.AccountId FROM vlocity_ins__GroupCensusMember__c WHERE Id IN: censusMemberIds];
        Map<Id,vlocity_ins__GroupCensusMember__c> censusMembersMap = new Map<Id,vlocity_ins__GroupCensusMember__c>();
        Set<Id> censusIds = new Set<Id>();
        for(vlocity_ins__GroupCensusMember__c member : members) {
            censusMembersMap.put(member.Id, member);
            censusIds.add(member.vlocity_ins__CensusId__c);
        }

        for (Case case_i : casesToUpdate) {
            vlocity_ins__GroupCensusMember__c member = censusMembersMap.containsKey(case_i.ARC_CensusMember__c)? censusMembersMap.get(case_i.ARC_CensusMember__c):null;
            if(member == null) continue;
            Map<String, Object> inputMap = new Map<String, Object> {
                'templateId' => envelope[0].vlocity_ins__TemplateIdentifier__c,
                'status' => 'sent',
                'sendJSONNode' => null,
                'sendJSONPath' => null,
                'templateRoles' => new List<Map<String, Object>> { new Map<String, Object>{
                    'iterKey' => 'iterkey-0',
                    'routingOrder' => '1',
                    'email' => member.vlocity_ins__Email__c,
                    'name' => member.Name,
                    'roleName' => 'Primary',
                    'tabs' => new Map<String, Object> {
                    'textTabs' => new List<Map<String, Object>> { 
                        new Map<String, Object> {'tabLabel' => 'EmailAddress', 'value' => member.vlocity_ins__Email__c},
                        new Map<String, Object> {'tabLabel' => 'FirstName', 'value' => member.vlocity_ins__FirstName__c},
                        new Map<String, Object> {'tabLabel' => 'FullName', 'value' => member.Name},
                        new Map<String, Object> {'tabLabel' => 'ID', 'value' => member.Member_ID__c},
                        new Map<String, Object> {'tabLabel' => 'LastName', 'value' => member.vlocity_ins__LastName__c},
                        new Map<String, Object> {'tabLabel' => 'Phone', 'value' => member.ARC_Phone__c?.replace('+1', '')},
                        new Map<String, Object> {'tabLabel' => 'State', 'value' => member.ARC_PhysicalAddressState__c},
                        new Map<String, Object> {'tabLabel' => 'City', 'value' => member.ARC_PhysicalAddressCity__c},
                        new Map<String, Object> {'tabLabel' => 'Street', 'value' => member.ARC_PhysicalAddressStreet__c},
                        new Map<String, Object> {'tabLabel' => 'ZipCode', 'value' => member.ARC_PhysicalAddressZipCode__c},
                        new Map<String, Object> {'tabLabel' => 'DOB', 'value' => member.vlocity_ins__Birthdate__c}
                    }
                    }
                }}
            };
            List<Map<String, Object>> textTabs = (List<Map<String, Object>>) ((Map<String, Object>)((Map<String, Object>) ((List<Map<String, Object>>) inputMap.get('templateRoles'))[0]).get('tabs')).get('textTabs');
            ChargentOrders__Transaction__c failedTransaction = case_i.Transactions__r.size()>0 ? case_i.Transactions__r[0]:null;
            // if (case_i.ARC_Reason__c == 'App/Change Fee Decline') {
            //     textTabs.add(new Map<String, Object> {'tabLabel' => 'PaymentAmount', 'value' => contract.ARC_AppFeeOrder__r.ChargentOrders__Total__c});
            // } else {
            //     textTabs.add(new Map<String, Object> {'tabLabel' => 'PaymentAmount', 'value' => contract.ARC_TotalPrice__c});
            // }
            if (failedTransaction != null) {
                textTabs.add(new Map<String, Object> {'tabLabel' => 'PaymentAmount', 'value' =>failedTransaction?.ChargentOrders__Amount__c });
            }
            else{
            }
            
            String inputJson = JSON.serialize(inputMap);
            caseToEnvelopeMap.put(case_i.Id, inputJson);
        }

        // flowActionSendEFTFormEnvelope is used both inside a schedulable batch and a trigger so depending on the context it runs async or not
        if (System.isBatch()){
            makeDocuSignCallout(caseToEnvelopeMap, envelope[0].vlocity_ins__TemplateIdentifier__c);
        } else {
            makeDocuSignCalloutAsync(caseToEnvelopeMap, envelope[0].vlocity_ins__TemplateIdentifier__c);
        }
    }

    @future(callout=true)
    public static void makeDocuSignCalloutAsync(Map<Id, String> caseToEnvelopeMap, String templateId) {
        makeDocuSignCallout(caseToEnvelopeMap, templateId);
    }


    public static void makeDocuSignCallout(Map<Id, String> caseToEnvelopeMap, String templateId) {
        List<Case> casesToUpdate = new List<Case>();
        String docuSignAccountId = ARC_DocuSignApi.getDocuSignAccountId();
        for (Id caseId : caseToEnvelopeMap.keySet()) {
            String inputJson = caseToEnvelopeMap.get(caseId);
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:DocuSign/restapi/v2.1/accounts/' + docuSignAccountId + '/envelopes');
            req.setMethod('POST');
            req.setBody(inputJson);
            
            try {
                Http http = new Http();
                System.debug(req);
                HttpResponse res = http.send(req);
                System.debug(res);
                System.debug(res.getBody());
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                String envelopeId = (String) responseMap.get('envelopeId');
                
                Case caseToUpdate = new Case(Id = caseId, ARC_LastDocuSignEnvelopeId__c = envelopeId, ARC_LastDocuSignEnvelopeStatus__c = 'Pending');
                casesToUpdate.add(caseToUpdate);
            } catch (Exception e) {
                System.debug('Error in callout: ' + e.getMessage());
            }
        }
        update casesToUpdate;
    }
}