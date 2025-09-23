@isTest
public class ARC_RetrieveBenefitCardsTest {
   
    
    @TestSetup
    static void makeData(){
        Integer bcCreated = 3;
        Map<BenefitCard__c, ContentVersion> benefitCards = ARC_TestUtility.createTestBenefitCards(bcCreated);
        System.debug(benefitCards);
        List<BenefitCard__c> BCList = new List<BenefitCard__c>(); 
        List<ContentVersion> CVList = new List<ContentVersion>();
        for(BenefitCard__c bc : benefitCards.keySet()){
            BCList.add(bc);
            CVList.add(benefitCards.get(bc));
        }
        insert BCList;
        insert CVList;
        
        for(BenefitCard__c bc : BCList) bc.ARC_CardsList__c = 'Vacation';
        upsert BCList;

        List<ContentVersion> insertedContentVersions = [SELECT contentDocumentId FROM ContentVersion];
        List<Id> contentDocumentIds = new List<Id>();
        for(ContentVersion cv: insertedContentVersions){
            contentDocumentIds.add(cv.contentDocumentId);
        }

        Map<SObject, Id> insertedBenefitCards = new Map<SObject, Id>();
        for(BenefitCard__c bc : BCList){
            insertedBenefitCards.put(bc, contentDocumentIds[BCList.indexOf(bc)]);
        }

        List<ContentDocumentLink> CDLList = ARC_TestUtility.createTestContentDocumentLink(insertedBenefitCards, 'V', 'AllUsers'); 
        System.debug(CDLList);
        insert CDLList;
    }

    @isTest
    static void benefitCardsTestMethod() {
        Integer bcCreated = 3;
        Test.startTest();
        List<Object> benefitCardRecordList = ARC_RetrieveBenefitCards.getBenefitCards();
        List<Object> contentVersionInfo = ARC_RetrieveBenefitCards.getContentVersionInfo('Vacation');
        System.assertEquals(benefitCardRecordList.size(), bcCreated);
        Test.stopTest();
    }
    
    @isTest
    static void benefitCardsTestMethodTwo() {
        Integer bcCreated = 4;
        Test.startTest();
            List<Object> benefitCardRecordList = ARC_RetrieveBenefitCards.getBenefitCards();
            List<Object> contentVersionInfo = ARC_RetrieveBenefitCards.getContentVersionInfo('Vacation');
            System.assertEquals(benefitCardRecordList.size(), contentVersionInfo.size());
        Test.stopTest();
    }
}