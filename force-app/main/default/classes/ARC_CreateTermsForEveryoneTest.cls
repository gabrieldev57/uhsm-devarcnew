@isTest
public class ARC_CreateTermsForEveryoneTest {

    @IsTest(seeAllData=true)
    static void testMethodName() {
        List<Claim> contList = [SELECT Id FROM Claim LIMIT 1];
        if(contList.size() == 0) return;

        Test.startTest();
        Database.executeBatch(new ARC_CreateTermsForEveryone('Id = \'' + contList[0].Id + '\'', true));
        Test.stopTest();
    }
}