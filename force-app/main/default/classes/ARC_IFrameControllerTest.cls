@IsTest 
public without sharing class ARC_IFrameControllerTest {
    
    @IsTest 
    public static void ARC_IFrameControllerTest() {
        Case c = ARC_TestUtility.createTestCase(1, 'SMB')[0];

        Test.startTest();
        Case cresult = ARC_IFrameController.getSMBLegacyURL(String.valueOf(c.Id));
        System.assertEquals(true,cresult.ARC_SMBSearchUrl__c.contains(c.Subject));
        Test.stopTest();
    }

    @IsTest 
    public static void ARC_IFrameControllerTestTwo() {
        Test.startTest();
        try{
            Case cresult = ARC_IFrameController.getSMBLegacyURL(String.valueOf('123456'));
        } catch (Exception ex) {
            System.assertEquals(true, ex.getMessage() != null);
        }  
        Test.stopTest();
    }
}