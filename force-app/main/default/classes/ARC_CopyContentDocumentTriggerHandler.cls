/*******************************************************************
* @ClassName          :   ARC_CopyContentDocumentTriggerHandler
* @Description        :   Helper that holds the logic for the CopyContentDocumentTrigger.
* @MethodName         :   onBefore,onAfter,findContractForCase,findCensusMemberForContract,copyContentDocumentLink,shareFilesWithinPersonAccountAndCensusMember
********************************************************************/

public with sharing class ARC_CopyContentDocumentTriggerHandler {

    /*******************************************************************
    * @MethodName         :   onBefore
    * @Description        :   Its called before the content document link is created. 
    ********************************************************************/
    public static void onBefore(List<ContentDocumentLink> cdList) {
        Set<Id> contentDocumentIds = new Set<Id>();
        String objectLinkedEntityId;
        Boolean isCase = false;
        Boolean isTask = false;
        Boolean isContract = false;
        List<ContentDocumentLink> cdListfromCMAndPA = new List<ContentDocumentLink>();

        for(ContentDocumentLink cd : cdList){
            contentDocumentIds.add(cd.ContentDocumentId);
            objectLinkedEntityId = cd.LinkedEntityId;
            Schema.SObjectType sObjType = cd.LinkedEntityId?.getSobjectType();
            if(sObjType?.getDescribe().getName() == 'Case'){
                isCase = true;
            } else if(sObjType?.getDescribe().getName() == 'Task') {
                isTask = true;
            } else if(sObjType?.getDescribe().getName() == 'Contract') {
                isContract = true;
            } 
        }
        
        if(isTask){ 
            Task taskFound = [SELECT Id, WhatId FROM Task WHERE Id = :objectLinkedEntityId];
            Schema.SObjectType sObjTypeWhatId = taskFound.WhatId.getSobjectType();
            if(sObjTypeWhatId.getDescribe().getName() == 'Case'){
                Case caseFound = [SELECT Id, ARC_Contract__c, ARC_CaseType__c,ARC_Reason__c, ARC_CensusMember__c, Case_Type__c, ARC_PersonAccount__c FROM Case WHERE Id = :taskFound.WhatId];
                findContractForCase(caseFound, contentDocumentIds);
            }

        } else if(isCase){
            Case caseFound = [SELECT Id, ARC_Reason__c, ARC_PersonAccount__c, ARC_Contract__c, ARC_CaseType__c, ARC_CensusMember__c,Case_Type__c FROM Case WHERE Id = :objectLinkedEntityId];
            findContractForCase(caseFound, contentDocumentIds);

        } else if(isContract){
            Contract contractFound = [SELECT Id, vlocity_ins__EnrollmentCensusId__c FROM Contract WHERE Id = :objectLinkedEntityId];
            findCensusMemberForContract(contractFound, contentDocumentIds);
        }
    }

    /*******************************************************************
    * @MethodName         :   onAfter
    * @Description        :   Its called after the content document link is created. 
    ********************************************************************/
    public static void onAfter(List<ContentDocumentLink> cdList) {
        List<ContentDocumentLink> cdListfromCMAndPA = new List<ContentDocumentLink>();

        for(ContentDocumentLink cd : cdList){
            Schema.SObjectType sObjType = cd.LinkedEntityId.getSobjectType();
            System.debug(sObjType);
            if(sObjType.getDescribe().getName() == 'Account' || sObjType.getDescribe().getName() == 'vlocity_ins__GroupCensusMember__c'){
                cdListfromCMAndPA.add(cd);
            }
        }

        if(cdListfromCMAndPA.size()>0) shareFilesWithinPersonAccountAndCensusMember(cdListfromCMAndPA);
    }

    //Private methods
    /*******************************************************************
    * @MethodName         :   findContractForCase
    * @Description        :   Get the contract related to the Case and call another mehtod to attach the files to the Census Member.
    ********************************************************************/
    public static void findContractForCase(Case caseFound, Set<Id> contentDocumentIds) {
        Contract contractFound;
    
        // Fetch contract if associated
        if (caseFound.ARC_Contract__c != null) {
            contractFound = [SELECT Id, vlocity_ins__EnrollmentCensusId__c FROM Contract WHERE Id = :caseFound.ARC_Contract__c];
        }
    
        // Handle Underwriting Cases
        if (caseFound.ARC_CaseType__c == 'Underwriting' && contractFound?.vlocity_ins__EnrollmentCensusId__c != null) {
            findCensusMemberForContract(contractFound, contentDocumentIds);
        } 
        // Handle Payment Method and Cancellation Cases and Reimbursement Cases
        else if (
            (caseFound.Case_Type__c == 'Contribution' && caseFound.ARC_PersonAccount__c != null && 
                (caseFound.ARC_Reason__c == 'Method Change' || 
                 caseFound.ARC_Reason__c == 'App/Change Fee Decline' || 
                 caseFound.ARC_Reason__c == 'One Time Fee Decline' || 
                 caseFound.ARC_Reason__c == 'Recurring Decline' || 
                 caseFound.ARC_Reason__c == 'First Month Decline')) ||
            caseFound.ARC_Reason__c == 'Cancellation' ||
            caseFound.ARC_Reason__c == 'Reimbursement' || caseFound.ARC_Reason__c == 'Amendment' || caseFound.Case_Type__c == 'Bring Back'
        ) {
            Id censusId = [SELECT ARC_Census__c FROM Account WHERE Id = :caseFound.ARC_PersonAccount__c].ARC_Census__c;
    
            if (censusId != null) {
                List<vlocity_ins__GroupCensusMember__c> cm = [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :censusId];
                copyContentDocumentLink(contentDocumentIds, cm);
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   findCensusMemberForContract
    * @Description        :   Get a the census members related to the Census of the contract and call another method to attached the files to the Census Members.
    ********************************************************************/
    public static void findCensusMemberForContract(Contract contractFound, Set<Id> contentDocumentIds ){
		vlocity_ins__GroupCensus__c censusFound = null;
		if (contractFound.vlocity_ins__EnrollmentCensusId__c != null) {
			censusFound = [SELECT Id FROM vlocity_ins__GroupCensus__c WHERE Id = :contractFound.vlocity_ins__EnrollmentCensusId__c];
		}

		Id censusId = null;
		List<vlocity_ins__GroupCensusMember__c> cm = new List<vlocity_ins__GroupCensusMember__c>();
		if (censusFound != null) {
			censusId = censusFound.Id;
			cm = [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :censusId];
		}

        copyContentDocumentLink(contentDocumentIds, cm);
    }

    /*******************************************************************
    * @MethodName         :   copyContentDocumentLink
    * @Description        :   Attaches the content document to the Census Members.
    ********************************************************************/
    public static void copyContentDocumentLink(Set<Id> contentDocumentIds, List<vlocity_ins__GroupCensusMember__c> cm){
        List<ContentDocumentLink> newListCD = new List<ContentDocumentLink>();
        vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c();

        Set<Id> existingCMIds = new Set<Id>();
        for(vlocity_ins__GroupCensusMember__c cm2 : cm){
            existingCMIds.add(cm2.Id);
        }

        List<ContentDocumentLink> existingCD = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN :existingCMIds];

        Set<Id> existingCDIds = new Set<Id>();
        for(ContentDocumentLink cd2 : existingCD){
            existingCDIds.add(cd2.Id);
        }

        for(Id cdId : contentDocumentIds){
            if(!existingCDIds.contains(cdId)){
                for(vlocity_ins__GroupCensusMember__c cm2 : cm){
                ContentDocumentLink cd = new ContentDocumentLink();
                cd.LinkedEntityId = cm2.Id;
                cd.ContentDocumentId = cdId;
                newListCD.add(cd);
                }
                
            }
        }
        if (newListCD.size() > 0){
            insert newListCD;
        }
    }

    /*******************************************************************
    * @MethodName         :   shareFilesWithinPersonAccountAndCensusMember
    * @Description        :   Attaches the files within Person Account and Census Member records.
    ********************************************************************/
    public static void shareFilesWithinPersonAccountAndCensusMember (List<ContentDocumentLink> contentDocuments){
        Set<Id> censusMemberIds = new Set<Id>();
        Set<Id> personAccountIds = new Set<Id>();
        Set<Id> contentDocumentIds = new Set<Id>();
        List<ContentDocumentLink> cdlToCreate = new List<ContentDocumentLink>();
        for(ContentDocumentLink contentDocument: contentDocuments){
            if(contentDocument.LinkedEntityId.getSobjectType().getDescribe().getName() == 'vlocity_ins__GroupCensusMember__c'){
                censusMemberIds.add(contentDocument.LinkedEntityId);
                contentDocumentIds.add(contentDocument.ContentDocumentId);
                cdlToCreate.add(contentDocument);
            } 
            else if(contentDocument.LinkedEntityId.getSobjectType().getDescribe().getName() == 'Account') {
                personAccountIds.add(contentDocument.LinkedEntityId);
                contentDocumentIds.add(contentDocument.ContentDocumentId);
                cdlToCreate.add(contentDocument);
            }
        }

        if(cdlToCreate.size() >0){
            List<ContentDocumentLink> existingContentDocumentLinks = [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN : contentDocumentIds];
            Map<Id,Set<Id>> contentDocumentIdLinkedEntityIdMap = new Map<Id,Set<Id>>();
            for(ContentDocumentLink cd: existingContentDocumentLinks){
                Set<Id> relatedRecordIds = contentDocumentIdLinkedEntityIdMap.get(cd.ContentDocumentId) != null ? contentDocumentIdLinkedEntityIdMap.get(cd.ContentDocumentId) : new Set<Id>();
                relatedRecordIds.add(cd.LinkedEntityId);
                contentDocumentIdLinkedEntityIdMap.put(cd.ContentDocumentId,relatedRecordIds);

            } 

            List<ContentDocumentLink> cdlToInsert = new List<ContentDocumentLink>();
            Map<Id,vlocity_ins__GroupCensusMember__c> censusMemberPersonAccountMapMap = new Map<Id,vlocity_ins__GroupCensusMember__c>();
            Map<Id,Account> personAccounCensusMemberMap = new Map <Id,Account>();
            if(censusMemberIds.size()>0) censusMemberPersonAccountMapMap = new Map<Id,vlocity_ins__GroupCensusMember__c>([SELECT Id, vlocity_ins__ContactId__r.AccountId FROM vlocity_ins__GroupCensusMember__c WHERE Id IN:censusMemberIds]);
            if(personAccountIds.size()>0) personAccounCensusMemberMap = new Map <Id,Account>([SELECT Id, ARC_CensusMember__pr.Id FROM Account WHERE Id IN:personAccountIds]);
            for(ContentDocumentLink contentDocument: cdlToCreate){
                System.debug('censusMemberPersonAccountMapMap'+censusMemberPersonAccountMapMap);
                System.debug('personAccounCensusMemberMap'+personAccounCensusMemberMap);
                if(censusMemberIds.contains(contentDocument.LinkedEntityId) && (contentDocumentIdLinkedEntityIdMap.get(contentDocument.ContentDocumentId) == null || !contentDocumentIdLinkedEntityIdMap.get(contentDocument.ContentDocumentId).contains(censusMemberPersonAccountMapMap.get(contentDocument.LinkedEntityId).vlocity_ins__ContactId__r.AccountId))){
                    System.debug('inside one');
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = censusMemberPersonAccountMapMap.get(contentDocument.LinkedEntityId).vlocity_ins__ContactId__r.AccountId;
                    cdl.ContentDocumentId = contentDocument.ContentDocumentId;
                    cdlToInsert.add(cdl);
                } 
                else if(personAccountIds.contains(contentDocument.LinkedEntityId) && (contentDocumentIdLinkedEntityIdMap.get(contentDocument.ContentDocumentId) == null || !contentDocumentIdLinkedEntityIdMap.get(contentDocument.ContentDocumentId).contains(personAccounCensusMemberMap.get(contentDocument.LinkedEntityId).ARC_CensusMember__pr.Id))){
                    System.debug('inside Two');
                    ContentDocumentLink cdl = new ContentDocumentLink();
                    cdl.LinkedEntityId = personAccounCensusMemberMap.get(contentDocument.LinkedEntityId).ARC_CensusMember__pr.Id;
                    cdl.ContentDocumentId = contentDocument.ContentDocumentId;
                    cdlToInsert.add(cdl);
                }
            }
            if(cdlToInsert.size()>0) {
                try{
                    insert cdlToInsert;
                }catch(Exception e){
                    System.debug('Error in Class: ARC_CopyContentDocumentTriggerHandler.shareFilesWithinPersonAccountAndCensusMember: '+e.getMessage());
                }
            }
        }
    }



}