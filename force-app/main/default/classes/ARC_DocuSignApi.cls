global without sharing class ARC_DocuSignApi implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map <String, Object> inputMap, Map<String, Object> outputMap, Map <String, Object> options) {
        switch on methodName {
            when 'sendCompositeEnvelopeInvocable'{
                sendCompositeEnvelopeInvocable(inputMap, outputMap, options);
            }
        }
        return true;
    }

    private static final String VALID_CASE_TYPE = 'Contribution';
    private static final List<String> VALID_CASE_REASONS = new List<String>{'Method Change','App/Change Fee Decline','One Time Fee Decline','Recurring Decline','First Month Decline','CC Expiration Date'};

    private static String envelopeId;

    public static String getDocuSignAccountId() {
      String docuSignAccountId;
      String domain = [SELECT Domain FROM Domain WHERE HttpsOption = 'SitesAlt' LIMIT 1].Domain;
      List<DocuSign_Account_Id__mdt> dsAccountIds = [SELECT Environment_Name__c, Account_Id__c FROM DocuSign_Account_Id__mdt];

      Map<String, String> envToAccountId = new Map<String, String>();
      for (DocuSign_Account_Id__mdt dsAccId : dsAccountIds) {
        envToAccountId.put(dsAccId.Environment_Name__c.toLowerCase(), dsAccId.Account_Id__c);
      }
      
      if (domain.containsIgnoreCase('devarcnew')) {
        docuSignAccountId = envToAccountId.get('devarcnew'); 
      } else if (domain.containsIgnoreCase('devarc')) {
        docuSignAccountId = envToAccountId.get('devarc');
      } else if (domain.containsIgnoreCase('uat')) {
        docuSignAccountId = envToAccountId.get('uat');
      } else if (domain.containsIgnoreCase('qa')){
        docuSignAccountId = envToAccountId.get('qa');
      } else {
        docuSignAccountId = envToAccountId.get('prod');
      }
  
      return docuSignAccountId;
    }
  
    public static void handleDocuSignUpdates(Map<Id, Case> oldMap, Map<Id, Case> newMap) {
      for (Case c : newMap.values()) {
        System.debug('CASE HANDLE DOCUSIGN: ' + c);
        Case oldRecord = (Case) oldMap.get(c.Id);
  
        if (c.Case_Type__c == VALID_CASE_TYPE && VALID_CASE_REASONS.contains(c.ARC_Reason__c) && c.ARC_LastDocuSignEnvelopeId__c != null && oldRecord.ARC_LastDocuSignEnvelopeStatus__c != 'Completed' && c.ARC_LastDocuSignEnvelopeStatus__c == 'Completed') {
            ARC_UpdatePaymentMethod.updatePaymentMethodDocusign(c.Id);
        }
      }
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

    public static void sendCompositeEnvelopeInvocable(Map <String, Object> inputMap, Map<String, Object> outputMap, Map <String, Object> options) {
      //Prepare parameter variables for sendCompositeEnvelope method
      String subject = (String)inputMap.get('subject'); System.debug('Subject: ' +subject);
      String signerList = (String)inputMap.get('signerList'); System.debug('Signer List: ' + signerList);
      String templateIdList = (String)inputMap.get('templateIdList'); System.debug('Template Id List: ' + templateIdList);
      String tabs = (String)inputMap.get('tabs'); System.debug('Tabs: ' + tabs);
      String contractId = (String)inputMap.get('contractId'); System.debug('Contract Id: ' + contractId);

      // Call method that sends the envelope
      sendCompositeEnvelope(subject, signerList, templateIdList, tabs, contractId);
      
      // Get the response status and envelope Id
      outputMap.put('status', 'processing');
    }

    /**
     * @Description: Method to build and send a DocuSign envelope using Composite Templates and put the envelope id into the contract
     * @param subject: String to include into the DocuSign email that is sent
     * @param serializedSignerList: Serialized list of signers map
     * @param serializedTemplatesId: Serialized list of templates id to include into the envelope
     * @param serializedTabs: Serialized map of tabs
     * @param contractId: Contract id to be updated with the envelope id
     */
    @future(callout=true)
    // @AuraEnabled (cacheable=true)
    public static void sendCompositeEnvelope(String subject ,String serializedSignerList, String serializedTemplatesId, String serializedTabs, String contractId) {

      try {
          List<Object> signerList = (List<Object>)JSON.deserializeUntyped(serializedSignerList) ;
          List<Object> templateIdList = (List<Object>)JSON.deserializeUntyped(serializedTemplatesId);
          Map<String,Object> tabsMap = (Map<String,Object>)JSON.deserializeUntyped(serializedTabs);
          System.debug('template id list: ' + templateIdList);
          System.debug('signer list: ' + signerList);
          System.debug('signer list size: ' + signerList.size());
          for (Object signer : signerList) {
            Map<String,Object> signerMap = (Map<String,Object>)signer;
            String signerRole = (String)signerMap.get('roleName');
            System.debug('Signer Role: ' + signerRole);
            System.debug('Signer Map: ' + signerMap);
          }
          System.debug('tabs map: ' + tabsMap);

          String DOCUSIGN_BASE_URL = 'callout:DocuSign/restapi/v2.1/accounts/';
          // String ACCOUNT_ID = 'e532f30c-09d3-4c1a-bd19-402a3d4edcd7';
          String ACCOUNT_ID = ARC_DocuSignApi.getDocuSignAccountId();
          System.debug('Account Id: ' + ACCOUNT_ID);

          Http http = new Http();
          HttpRequest req = new HttpRequest();

          req.setEndpoint(DOCUSIGN_BASE_URL + ACCOUNT_ID + '/envelopes');
          req.setMethod('POST');
          req.setHeader('Content-Type', 'application/json');

          req.setTimeout(60000); // Increase default timeout to 60 seconds

          // Build tab map with the correct structure
          List<Map<String,Object>> checkboxTabs = new List<Map<String,Object>>();
          List<Map<String,Object>> textTabs = new List<Map<String,Object>>();
          for (String tabType : tabsMap.keySet()) {
              Map<String,Object> tempTabMap = (Map<String,Object>)tabsMap.get(tabType);
              for (String tempTab : tempTabMap.keySet()) {
                  Map<String,Object> tab = new Map<String,Object>{'tabLabel' => tempTab};
                  if (tabType == 'checkboxTabs') {
                    tab.put('selected', tempTabMap.get(tempTab)); // Key-Value for checkbox tabs
                    checkboxTabs.add(tab);
                  } else if (tabType == 'textTabs') {
                    tab.put('value', tempTabMap.get(tempTab)); // Key-Value for text tabs
                    textTabs.add(tab);
                  }
              }
          }
          Map<String,Object> finalTabMap = new Map<String,Object>{
              'checkboxTabs' => checkboxTabs,
              'textTabs' => textTabs
          };

          // Add tabs map to the primary signer
          for (Object signer : signerList) {
              if ((String)((Map<String,Object>)signer).get('roleName') == 'Primary') ((Map<String,Object>)signer).put('tabs', finalTabMap);
          }

          // Add signers to inline template
          Map<String, Object> inlineTemplate = new Map<String, Object>{
              'sequence' => 1,
              'recipients' => new Map<String, Object>{
                  'signers' => signerList
              }
          };

          // Create a composite template for each DocuSign template
          List<Object> compositeTemplates = new List<Object>();
          Integer index = 1;
          for (Object templateId : templateIdList) {
              String templateIdStr = (String)templateId;
              Map<String, Object> compositeTemplate = new Map<String, Object>{
                  // 'compositeTemplateId' => String.valueOf(index),
                  // 'compositeTemplateId' => '1',
                  'serverTemplates' => new List<Object>{
                      new Map<String, Object>{
                          'sequence' => 1,
                          'templateId' => templateIdStr
                      }
                  },
                  'inlineTemplates' => new List<Object>{
                      inlineTemplate
                  }
              };
              compositeTemplates.add(compositeTemplate);
              index++;
          }

          Map<String, Object> body = new Map<String, Object>{
              'status' => 'sent',
              'emailSubject' => subject,
              'compositeTemplates' => compositeTemplates
          };

          req.setBody(JSON.serialize(body));
          // System.debug('Request Body: ' + JSON.serializePretty(body));
          HttpResponse res = http.send(req);

          System.debug('Status Code => ' + res.getStatusCode());
          System.debug('Response => ' + res.getBody());

          Map<String,Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
          envelopeId = responseMap.containsKey('envelopeId') ? (String)responseMap.get('envelopeId') : null;

          // Populate envelope id in contract and update logic
          Integer retries = 3;
          Boolean success = false;
          // Get envelope Id from response to put it in the contract

          if (responseMap.containsKey('envelopeId') && responseMap.get('envelopeId') != null && contractId != null) {
            String envelopeId = (String)responseMap.get('envelopeId');
            System.debug('envelope id: ' + envelopeId);
            System.debug('contract id: ' + contractId);
            Contract contractToUpdate = new Contract();
            contractToUpdate.Id = contractId;
            contractToUpdate.vlocity_ins__LastDocuSignEnvelopeId__c = envelopeId;
            contractToUpdate.vlocity_ins__LastDocuSignEnvelopeStatus__c = 'Pending';
            while (!success && retries > 0) {
              try {
                update contractToUpdate;
                success = true;
              } catch (DmlException e) {
                Boolean isLockError = e.getMessage().contains('UNABLE_TO_LOCK_ROW');
                retries--;
                if (isLockError && retries > 0) continue;

                System.debug('Error updating envelope ID in contract: ' + e.getMessage() + e.getStackTraceString());

                Integer MAX_FIELD_SIZE = 131072-10;
                String errorMessage = e.getMessage() + ' | ' + e.getStackTraceString();

                Custom_Logs__c log = new Custom_Logs__c();
                log.Name = 'Exception while updating envelope ID in contract';
                log.OwnerId = UserInfo.getUserId();
                log.Status__c = 'New';
                if (errorMessage.length() > MAX_FIELD_SIZE) {
                    log.Log__c = errorMessage.substring(0, MAX_FIELD_SIZE);
                    Integer remainingLength = Math.min(errorMessage.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                    if (remainingLength > 0) log.Log_2__c = errorMessage.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                } else {
                    log.Log__c = errorMessage;
                }
                insert log;
                throw e;
              }
            }
          } else if (!responseMap.containsKey('envelopeId')) {
            System.debug('DocuSign API call did not return an envelopeId. Response: ' + res.getBody());
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification('Error in ARC_DocuSignApi.sendCompositeEnvelope: API call did not return an envelopeId. Response: ' + res.getBody(), 'ERROR ARC_DocuSignApi', apexErrorEmail);
            Custom_Logs__c log = new Custom_Logs__c();
            log.Name = 'Exception while updating envelope ID in contract Id: ' + contractId;
            log.OwnerId = UserInfo.getUserId();
            log.Status__c = 'New';
            log.Log__c =  res.getBody();
            insert log;
          }
      } catch (Exception e) {
          System.debug('Error in sendCompositeEnvelope: ' + e.getMessage() + e.getStackTraceString());
          String errorMessage = e.getMessage() + ' | ' + e.getStackTraceString();
          String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
          ARC_QueableSendFileBatch.sendEmailNotification('Error in ARC_DocuSignApi.sendCompositeEnvelope: ' + e.getMessage(), 'ERROR ARC_DocuSignApi', apexErrorEmail);
          Custom_Logs__c log = new Custom_Logs__c();
          log.Name = 'Exception while envelope in contract Id: ' + contractId;
          log.OwnerId = UserInfo.getUserId();
          log.Status__c = 'New';
          log.Log__c = errorMessage;
          insert log;
      }
    }

    /**
     * @Description: Method to build and send a DocuSign envelope using Composite Templates and put the envelope id into the contract
     * @param subject: String to include into the DocuSign email that is sent
     * @param serializedSignerList: Serialized list of signers map
     * @param serializedTemplatesId: Serialized list of templates id to include into the envelope
     * @param serializedTabs: Serialized map of tabs
     * @param contractId: Contract id to be updated with the envelope id
     */
    @future(callout=true)
    // @AuraEnabled (cacheable=true)
    public static void sendCompositeEnvelopeSmallGroup(String subject ,String serializedSignerList, String serializedTemplatesId, String serializedTabs, String policyOrCaseId) {
      System.debug('Executing sendCompositeEnvelopeSmallGroup...');
      try {
          // signerList: list of signer maps with roleName ('Primary' or 'Legacy'), name, email, recipientId
          // templateIdList: list of composite entries, each {templateId, signerRole, legacyIndex}
          // tabsMap: rich structure with 'global' (textTabs+checkboxTabs) and 'legacyMembers'
          //   (list of {textTabs, checkboxTabs}, one per Legacy member)
          List<Object> signerList = (List<Object>)JSON.deserializeUntyped(serializedSignerList);
          List<Object> templateIdList = (List<Object>)JSON.deserializeUntyped(serializedTemplatesId);
          Map<String,Object> tabsMap = (Map<String,Object>)JSON.deserializeUntyped(serializedTabs);
          System.debug('template id list: ' + templateIdList);
          System.debug('signer list: ' + signerList);
          System.debug('signer list size: ' + signerList.size());
          System.debug('tabs map: ' + tabsMap);

          String DOCUSIGN_BASE_URL = 'callout:DocuSign/restapi/v2.1/accounts/';
          String ACCOUNT_ID = ARC_DocuSignApi.getDocuSignAccountId();
          System.debug('Account Id: ' + ACCOUNT_ID);

          Http http = new Http();
          HttpRequest req = new HttpRequest();
          req.setEndpoint(DOCUSIGN_BASE_URL + ACCOUNT_ID + '/envelopes');
          req.setMethod('POST');
          req.setHeader('Content-Type', 'application/json');
          req.setTimeout(60000);

          // Pre-extract the global tabs and legacy member tabs from the rich tabs map.
          Map<String,Object> globalTabsBucket = (Map<String,Object>)tabsMap.get('global');
          List<Object> legacyMembersTabs = tabsMap.get('legacyMembers') != null
              ? (List<Object>)tabsMap.get('legacyMembers')
              : new List<Object>();

          // Locate the Primary signer and the Legacy signers in order. The Primary signer
          // is reused on every composite template that needs a Primary signature (and its
          // recipientId is reused across composites -- that is fine in DocuSign because each
          // composite template has its own recipient namespace).
          Map<String,Object> primarySigner = null;
          List<Map<String,Object>> legacySigners = new List<Map<String,Object>>();
          for (Object signer : signerList) {
              Map<String,Object> sm = (Map<String,Object>)signer;
              String rn = (String)sm.get('roleName');
              if (rn == 'Primary' && primarySigner == null) primarySigner = sm;
              else if (rn == 'Legacy') legacySigners.add(sm);
          }

          // Build the composite templates: one inlineTemplate per composite, scoped to the
          // right signer and tabs.
          List<Object> compositeTemplates = new List<Object>();
          for (Object compEntryObj : templateIdList) {
              Map<String,Object> compEntry = (Map<String,Object>)compEntryObj;
              String templateIdStr = (String)compEntry.get('templateId');
              String signerRole = (String)compEntry.get('signerRole');
              Integer legacyIndex = compEntry.get('legacyIndex') != null
                  ? Integer.valueOf(compEntry.get('legacyIndex'))
                  : null;

              // Choose which signer signs this composite.
              Map<String,Object> chosenSigner;
              if (signerRole == 'Legacy') {
                  if (legacyIndex == null || legacyIndex >= legacySigners.size()) {
                      System.debug('WARNING: legacy composite missing legacy signer at index ' + legacyIndex);
                      continue;
                  }
                  chosenSigner = legacySigners[legacyIndex];
              } else {
                  if (primarySigner == null) {
                      System.debug('WARNING: composite needs Primary signer but none was found');
                      continue;
                  }
                  chosenSigner = primarySigner;
              }

              // Choose which tab bucket to use. Global composites use the global bucket;
              // legacy composites use the global bucket plus the legacy member's own bucket
              // (so common tabs like EffectiveDate, Primary.*, Programs, etc., still appear).
              Map<String,Object> mergedTextTabs = new Map<String,Object>();
              Map<String,Object> mergedCheckboxTabs = new Map<String,Object>();
              if (globalTabsBucket != null) {
                  if (globalTabsBucket.get('textTabs') != null) {
                      mergedTextTabs.putAll((Map<String,Object>)globalTabsBucket.get('textTabs'));
                  }
                  if (globalTabsBucket.get('checkboxTabs') != null) {
                      mergedCheckboxTabs.putAll((Map<String,Object>)globalTabsBucket.get('checkboxTabs'));
                  }
              }
              if (legacyIndex != null && legacyIndex < legacyMembersTabs.size()) {
                  Map<String,Object> lBucket = (Map<String,Object>)legacyMembersTabs[legacyIndex];
                  if (lBucket.get('textTabs') != null) {
                      mergedTextTabs.putAll((Map<String,Object>)lBucket.get('textTabs'));
                  }
                  if (lBucket.get('checkboxTabs') != null) {
                      mergedCheckboxTabs.putAll((Map<String,Object>)lBucket.get('checkboxTabs'));
                  }
              }

              // Serialize tabs into the DocuSign array shape.
              List<Map<String,Object>> textTabArr = new List<Map<String,Object>>();
              for (String label : mergedTextTabs.keySet()) {
                  textTabArr.add(new Map<String,Object>{ 'tabLabel' => label, 'value' => mergedTextTabs.get(label) });
              }
              List<Map<String,Object>> checkboxTabArr = new List<Map<String,Object>>();
              for (String label : mergedCheckboxTabs.keySet()) {
                  checkboxTabArr.add(new Map<String,Object>{ 'tabLabel' => label, 'selected' => mergedCheckboxTabs.get(label) });
              }

              // Build a fresh signer map for this composite with its tabs attached. We clone
              // the original signer's properties so multiple composites don't share the same
              // 'tabs' object (otherwise we'd overwrite per composite).
              Map<String,Object> signerForComposite = new Map<String,Object>();
              for (String k : chosenSigner.keySet()) {
                  if (k == 'tabs') continue;
                  signerForComposite.put(k, chosenSigner.get(k));
              }
              signerForComposite.put('tabs', new Map<String,Object>{
                  'textTabs'     => textTabArr,
                  'checkboxTabs' => checkboxTabArr
              });

              Map<String,Object> inlineTemplate = new Map<String,Object>{
                  'sequence' => 1,
                  'recipients' => new Map<String,Object>{
                      'signers' => new List<Object>{ signerForComposite }
                  }
              };

              Map<String,Object> compositeTemplate = new Map<String,Object>{
                  'serverTemplates' => new List<Object>{
                      new Map<String,Object>{
                          'sequence' => 1,
                          'templateId' => templateIdStr
                      }
                  },
                  'inlineTemplates' => new List<Object>{ inlineTemplate }
              };
              compositeTemplates.add(compositeTemplate);
              System.debug('Composite for template ' + templateIdStr + ' -> signer ' + signerRole
                  + (legacyIndex != null ? ' (legacy ' + legacyIndex + ')' : '')
                  + ' textTabs=' + textTabArr.size() + ' checkboxTabs=' + checkboxTabArr.size());
          }

          Map<String,Object> body = new Map<String,Object>{
              'status' => 'sent',
              'emailSubject' => subject,
              'compositeTemplates' => compositeTemplates
          };

          System.debug('Final request body: ' + JSON.serializePretty(body));
          req.setBody(JSON.serialize(body));
          HttpResponse res = http.send(req);

          System.debug('Status Code => ' + res.getStatusCode());
          System.debug('Response => ' + res.getBody());

          Map<String,Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
          envelopeId = responseMap.containsKey('envelopeId') ? (String)responseMap.get('envelopeId') : null;

          // Populate envelope id in policy and update logic
          Integer retries = 3;
          Boolean success = false;

          if (responseMap.containsKey('envelopeId') && responseMap.get('envelopeId') != null && policyOrCaseId != null) {
            String envelopeId = (String)responseMap.get('envelopeId');
            System.debug('envelope id: ' + envelopeId);
            System.debug('policy or case id: ' + policyOrCaseId);

            Id recordToUpdateId = Id.valueOf(policyOrCaseId);
            InsurancePolicy policyToUpdate = new InsurancePolicy();
            Case caseToUpdate = new Case();
            Schema.SObjectType sObjType = recordToUpdateId.getSObjectType();
            if (sObjType == InsurancePolicy.getSObjectType()) {
              policyToUpdate.Id = policyOrCaseId;
              policyToUpdate.ARC_LastDocusignEnvelopeId__c = envelopeId;
              policyToUpdate.ARC_LastDocusignEnvelopeStatus__c = 'Pending';
            } else if (sObjType == Case.getSObjectType()) {
              caseToUpdate.Id = policyOrCaseId;
              caseToUpdate.ARC_LastDocuSignEnvelopeId__c = envelopeId;
              caseToUpdate.ARC_LastDocuSignEnvelopeStatus__c = 'Pending';
            }

            while (!success && retries > 0) {
              try {
                if (sObjType == InsurancePolicy.getSObjectType()) update policyToUpdate;
                else if (sObjType == Case.getSObjectType()) update caseToUpdate;
                success = true;
              } catch (DmlException e) {
                Boolean isLockError = e.getMessage().contains('UNABLE_TO_LOCK_ROW');
                retries--;
                if (isLockError && retries > 0) continue;

                System.debug('Error updating envelope ID in contract: ' + e.getMessage() + e.getStackTraceString());

                Integer MAX_FIELD_SIZE = 131072-10;
                String errorMessage = e.getMessage() + ' | ' + e.getStackTraceString();

                Custom_Logs__c log = new Custom_Logs__c();
                log.Name = 'Exception while updating envelope ID in contract';
                log.OwnerId = UserInfo.getUserId();
                log.Status__c = 'New';
                if (errorMessage.length() > MAX_FIELD_SIZE) {
                    log.Log__c = errorMessage.substring(0, MAX_FIELD_SIZE);
                    Integer remainingLength = Math.min(errorMessage.length() - MAX_FIELD_SIZE, MAX_FIELD_SIZE);
                    if (remainingLength > 0) log.Log_2__c = errorMessage.substring(MAX_FIELD_SIZE, MAX_FIELD_SIZE + remainingLength);
                } else {
                    log.Log__c = errorMessage;
                }
                insert log;
                throw e;
              }
            }
          } else if (!responseMap.containsKey('envelopeId')) {
            System.debug('DocuSign API call did not return an envelopeId. Response: ' + res.getBody());
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification('Error in ARC_DocuSignApi.sendCompositeEnvelopeSmallGroup: API call did not return an envelopeId. Response: ' + res.getBody(), 'ERROR ARC_DocuSignApi', apexErrorEmail);
            Custom_Logs__c log = new Custom_Logs__c();
            log.Name = 'Exception while updating envelope ID in policy or case: ' + policyOrCaseId;
            log.OwnerId = UserInfo.getUserId();
            log.Status__c = 'New';
            log.Log__c =  res.getBody();
            insert log;
          }
      } catch (Exception e) {
          System.debug('Error in sendCompositeEnvelopeSmallGroup: ' + e.getMessage() + e.getStackTraceString());
          String errorMessage = e.getMessage() + ' | ' + e.getStackTraceString();
          String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
          ARC_QueableSendFileBatch.sendEmailNotification('Error in ARC_DocuSignApi.sendCompositeEnvelopeSmallGroup: ' + e.getMessage(), 'ERROR ARC_DocuSignApi', apexErrorEmail);
          Custom_Logs__c log = new Custom_Logs__c();
          log.Name = 'Exception while envelope in policy or case Id: ' + policyOrCaseId;
          log.OwnerId = UserInfo.getUserId();
          log.Status__c = 'New';
          log.Log__c = errorMessage;
          insert log;
      }
    }

    /**
     * Decide which signer roleName should receive a given tab.
     * - If the tabLabel starts with "<roleName>." and that role is among the available
     *   signers, returns that role. (e.g. "Legacy1.FirstName" -> "Legacy1")
     * - Otherwise returns the fallback role (typically the first signer).
     */
    private static String resolveTabRole(String tabLabel, Set<String> availableRoles, String fallbackRole) {
        if (tabLabel == null) return fallbackRole;
        Integer dotIdx = tabLabel.indexOf('.');
        if (dotIdx > 0) {
            String prefix = tabLabel.substring(0, dotIdx);
            if (availableRoles.contains(prefix)) return prefix;
        }
        return fallbackRole;
    }

    private static List<Object> getSignerListWithoutPhone(List<Object> signerList) {
        List<Object> signerListWithoutPhone = new List<Object>();
        for (Object signer : signerList) {
          Map<String,Object> signerMap = (Map<String,Object>)signer;
          Map<String,Object> tmpSignerMap = new Map<String,Object>();
          for (String key : signerMap.keySet()) {
            if (key == 'additionalNotifications') continue;
            tmpSignerMap.put(key, signerMap.get(key));
          }
          signerListWithoutPhone.add(tmpSignerMap);
        }
        return signerListWithoutPhone;
    }

  }