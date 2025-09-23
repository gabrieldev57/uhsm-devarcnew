@isTest
public with sharing class ARC_HealthProgramRecordsTest {
    @TestSetup
    static void makeData(){
        Integer recordsToCreate = 1;

        List<ARC_HealthProgram__c> hpl = ARC_TestUtility.createTestHealthProgram(recordsToCreate, 'Gold', true,'Vacation');
        insert hpl;
        
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body');
        List<ContentVersion> cvl = ARC_TestUtility.createTestContentVersion(recordsToCreate, bodyBlob, 'Picture','H', '/Picture.jpg');
        insert cvl;
        
        List<ContentVersion> insertedContentVersions = [SELECT contentDocumentId FROM ContentVersion];
        List<Id> contentDocumentIds = new List<Id>();
        for(ContentVersion cv: insertedContentVersions){
            contentDocumentIds.add(cv.contentDocumentId);
        }

        Map<SObject, Id> insertedHealthPrograms = new Map<SObject, Id>();
        for(ARC_HealthProgram__c hp : hpl){
            insertedHealthPrograms.put(hp, contentDocumentIds[hpl.indexOf(hp)]);
        }
        
        List<ContentDocumentLink> cdl = ARC_TestUtility.createTestContentDocumentLink(insertedHealthPrograms, 'V', 'AllUsers' ); 
        insert cdl;

        List<ARC_HealthProgramSpec__c> hpsl = ARC_TestUtility.createTestHealthProgramSpecs(hpl);
        for (Integer i = 0; i < hpsl.size(); i++){
            ARC_HealthProgramSpec__c hps = hpsl[i];
            hps.ARC_Order__c = i;
        }
        insert hpsl;
    }

    @isTest
    static void testWithData() {
        System.debug('testWithData');
        Test.startTest();
        System.debug('test start');
        List<ARC_HealthProgram__c> programList = ARC_TestUtility.createTestHealthProgram(1,'TestProgram',true,'Vacation');
        insert programList;
        System.debug('ProgramListId');
        System.debug(programList[0].Id);
        List<ContentVersion> contentVersionList = ARC_TestUtility.createTestContentVersion(1,Blob.valueof('test'),'title','origin', 'pathOnClient' );
        insert contentVersionList;
        System.debug('contentVersionList');
        System.debug(contentVersionList[0].Id);
        System.debug('contentVersionDocumentId');
        System.debug([SELECT ContentDocumentId from ContentVersion WHERE Id = :contentVersionList[0].Id ].ContentDocumentId);
        Map<SObject, String> mappedVersion = new Map<SObject, String>();
        mappedVersion.put(programList[0],[SELECT ContentDocumentId from ContentVersion WHERE Id = :contentVersionList[0].Id ].ContentDocumentId);
        List<ContentDocumentLink> documentList = ARC_TestUtility.createTestContentDocumentLink(mappedVersion,'V','AllUsers' );
        System.debug('documentList');
        System.debug(documentList[0].Id);
        insert documentList;
        List<Object> healthRecords = ARC_HealthProgramRecords.getContentVersionInfo('Vacation');
        System.debug(healthRecords);
        List<ARC_HealthProgramSpec__c> healthProgramSpecs = ARC_HealthProgramRecords.getHealthProgramSpecs();
        System.debug(healthProgramSpecs);
        System.assertEquals(2, healthRecords.size());
        System.assertEquals(1, healthProgramSpecs.size());
        Test.stopTest();
    }

    @isTest
    static void testNoData() {
        Test.startTest();

        List<ARC_HealthProgramSpec__c> gethealthProgramSpecs = ARC_HealthProgramRecords.getHealthProgramSpecs();
        Test.stopTest();
    }
}