public with sharing class ARC_DocuSignApi {

    private static final String VALID_CASE_TYPE = 'Contribution';
    private static final List<String> VALID_CASE_REASONS = new List<String>{'Method Change','App/Change Fee Decline','One Time Fee Decline','Recurring Decline','First Month Decline','CC Expiration Date'};

    public static String getDocuSignAccountId() {
      String domain = [SELECT Domain FROM Domain WHERE HttpsOption = 'SitesAlt' LIMIT 1].Domain;
      String docuSignAccountId;
  
      if (domain.containsIgnoreCase('devarc')) {
        docuSignAccountId = 'a65373de-cff7-4894-a564-3b5cdf0497ce';
      } else if (domain.containsIgnoreCase('uat')) {
        docuSignAccountId = '8b799ddd-b7bc-4e9d-add9-97f15299532f';
      } else {
        docuSignAccountId = '685c69bd-4cc1-495a-a267-5f79bfe2030e';
      }
  
      return docuSignAccountId;
    }
  
    public static void handleDocuSignUpdates(Map<Id, Case> oldMap, Map<Id, Case> newMap) {
      // Case & task list to update in Contract Amendment OS
      // list<Case> caseToUpdate = new list<Case> ();
      // list<Task> taskToCreate = new list<Task> ();
      // Group CaseOwner = [SELECT Id, type, Related.Name,DeveloperName, name FROM Group WHERE Type = 'Queue' AND DeveloperName ='ProcessingQueue' LIMIT 1];

      for (Case c : newMap.values()) {
        System.debug('CASE HANDLE DOCUSIGN: ' + c);
        Case oldRecord = (Case) oldMap.get(c.Id);
        
        // Condition to update Payment method cases
        if (c.Case_Type__c == VALID_CASE_TYPE && VALID_CASE_REASONS.contains(c.ARC_Reason__c) && c.ARC_LastDocuSignEnvelopeId__c != null && oldRecord.ARC_LastDocuSignEnvelopeStatus__c != 'Completed' && c.ARC_LastDocuSignEnvelopeStatus__c == 'Completed') {
            ARC_UpdatePaymentMethod.updatePaymentMethodDocusign(c.Id);
        }

        // Update of contract amendmente flow after signature
        // if  (c.Case_Type__c == 'Program' && c.ARC_Reason__c == 'Amendment' && c.ARC_LastDocuSignEnvelopeId__c != null && oldRecord.ARC_LastDocuSignEnvelopeStatus__c != 'Completed' && c.ARC_LastDocuSignEnvelopeStatus__c == 'Completed') {
        //   c.Status = 'In Progress';
        //   c.OwnerId = CaseOwner.Id;
        //   caseToUpdate.add(c);
        //   Task newTask = new Task();
        //   newTask.Case__c = c.Id;
        //   newTask.Subject = 'Member has signed the amendment form';
        //   newTask.Description = 'Member has signed the amendment form';
        //   newTask.ActivityDate = Date.today();
        //   taskToCreate.add(newTask);
        }
      // }
      // if (caseToUpdate != null && taskToCreate != null) {
      //     insert taskToCreate;
      //     update caseToUpdate;
      // }
    }
  
    // @future (callout=true)
    public static Map<String, Object> httpGetRecipientsTabs(String envelopeId) {
      HttpRequest req = new HttpRequest();
      //type: documents, recipients
      req.setEndpoint('callout:DocuSign/restapi/v2.1/accounts/' + getDocuSignAccountId() + '/envelopes/' + envelopeId + '/recipients/1/tabs');
      req.setMethod('GET');
      req.setBody('{}');
      System.debug(req.getEndpoint());
      Http http = new Http();
      HttpResponse res = http.send(req);
  
      Map<String, Object> responseMap = new Map<String, Object>();
      // Check for successful response
      if (res.getStatusCode() == 200) {
        // Parse the JSON response
        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        // Access the textTabs list
      } else {
        return new Map<String, Object>{ 'error' => res.getStatusCode() };
      }
      // return responseMap;
    }
  
    public static Map<String, Object> httpGetDocumentsTabs(String envelopeId) {
      Integer retries = 0;
      Integer maxRetries = 3;
      Integer delayInMillis = 2000;
  
      while (retries < maxRetries) {
        // Create an HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DocuSign/restapi/v2.1/accounts/' + getDocuSignAccountId() + '/envelopes/' + envelopeId + '/documents/1/tabs');
        req.setMethod('GET');
        req.setBody('{}');
  
        Http http = new Http();
        HttpResponse response = http.send(req);
  
        // Check for successful response
        List<Object> checkboxTabs = ((List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(response.getBody())).get('checkboxTabs'));
        List<Object> textTabs = ((List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(response.getBody())).get('textTabs'));
  
        if (response.getStatusCode() == 200 && checkboxTabs != null && textTabs != null) {
          // Return JSON response
          return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        } else {
          // Increment retry count
          retries++;
          System.debug('Retrying... (' + retries + '/' + maxRetries + ')');
          // Delay before the next retry
          if (retries < maxRetries) {
            pauseExecution(delayInMillis);
          }
        }
      }
  
      // If we reach here, all 3 retries failed
      throw new CalloutException('Failed to fetch from API after ' + maxRetries + ' attempts.');
    }
  
    // Helper method to pause execution for a specified number of milliseconds
    private static void pauseExecution(Integer millis) {
      Long start = System.currentTimeMillis();
      while (System.currentTimeMillis() - start < millis) {
        // Busy-wait loop (avoid heavy processing here)
      }
    }
  
    public static Map<String, Object> formatDocusignResponse(Map<String, Object> responseMap) {
      Map<String, Object> formattedResponse = new Map<String, Object>();
      List<Object> textTabs = (List<Object>) responseMap.get('textTabs');
      List<Object> checkboxTabs = (List<Object>) responseMap.get('checkboxTabs');
  
      if (textTabs != null) {
        for (Object tabObj : textTabs) {
          Map<String, Object> tab = (Map<String, Object>) tabObj;
          formattedResponse.put((String) tab.get('tabLabel'), (String) tab.get('value'));
        }
      } else {
        throw new HandledException('DocuSign API request failed, didn\'t return a JSON response missing textTabs');
      }
  
      if (checkboxTabs != null) {
        for (Object tabObj : checkboxTabs) {
          Map<String, Object> tab = (Map<String, Object>) tabObj;
          formattedResponse.put((String) tab.get('tabLabel'), (String) tab.get('selected'));
        }
      } else {
        throw new HandledException('DocuSign API request failed, didn\'t return a JSON response missing checkboxTabs');
      }
      return formattedResponse;
    }
  
    public static void voidEnvelope(String envelopeId) {
      if (envelopeId != null) {
        String docuSignAccountId = getDocuSignAccountId();
  
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:DocuSign/restapi/v2.1/accounts/' + docuSignAccountId + '/envelopes/' + envelopeId);
        req.setMethod('PUT');
        req.setBody('{"status": "voided","voidedReason": "Case has been closed."}');
        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug('Void Envelop Endpoint: ' + req.getEndpoint());
        System.debug('Void Envelope Response: ' + res.getBody());
      }
    }
  }