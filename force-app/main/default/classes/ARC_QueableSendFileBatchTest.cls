@isTest
public class ARC_QueableSendFileBatchTest {

    @isTest
    static void testZelisFile() {
        String testContent = 'Test content for Zelis';
        String testFileName = 'zelis_test_file.txt';
        Integer testSegments = 10;
        Boolean isTest = true;
        Decimal testTransactionId = 12345.67;
        String testFileType = 'Zelis';

        ARC_QueableSendFileBatch job = new ARC_QueableSendFileBatch(testContent, testFileName, testSegments, isTest, testTransactionId, testFileType);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    @isTest
    static void testCVSFile() {
        String testContent = 'Test content for CVS';
        String testFileName = 'cvs_test_file.txt';
        Boolean sendFilesToTestSites = true;
        Boolean isFirst = true;
        Boolean isFinish = false;
        Integer lastLine = 100;
        String testFileType = 'CVS';

        ARC_QueableSendFileBatch job = new ARC_QueableSendFileBatch(testContent, testFileName, testFileType, sendFilesToTestSites, isFirst, isFinish, lastLine);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    @isTest
    static void testSureCoFile() {
        String testContent = 'Test content for SureCo';
        String testFileName = 'sureco_test_file.txt';
        Integer testMemberCount = 50;
        String testFileType = 'Eligibility';

        ARC_QueableSendFileBatch job = new ARC_QueableSendFileBatch(testContent, testFileName, testFileType, testMemberCount);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }

    @isTest
    static void testQwikPayFile() {
        String testContent = 'Test content for QwikPay';
        String testFileName = 'qwikpay_test_file.txt';
        Boolean isFirst = true;
        Boolean isFinish = false;
        String testSiteName = 'SiteName';
        String testMoveToSite = 'MoveToSite';
        String testMoveToPath = 'MoveToPath';
        String testFileType = 'QwikPay';

        ARC_QueableSendFileBatch job = new ARC_QueableSendFileBatch(testContent, testFileName, testFileType, isFirst, isFinish, testSiteName, testMoveToSite, testMoveToPath);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();
    }
}