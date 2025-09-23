@isTest
public class ARC_CounterXMLFileTest {

    @isTest
    static void testOne() {

        ARC_XMLCounter__c xmlCounter = new ARC_XMLCounter__c(Name='ZelisXML',ARC_Date__c=Date.today(),ARC_Counter__c='00.00');
        insert xmlCounter;

        Test.startTest();
            ARC_CounterXMLFile.generateCounter();
        Test.stopTest();
    }

    @isTest
    static void testTwo() {

        ARC_XMLCounter__c xmlCounter = new ARC_XMLCounter__c(Name='ZelisXML',ARC_Date__c=Date.today().addDays(-1),ARC_Counter__c='00.00');
        insert xmlCounter;

        Test.startTest();
            ARC_CounterXMLFile.generateCounter();
        Test.stopTest();
    }

    @isTest
    static void testThree() {

        ARC_XMLCounter__c xmlCounter = new ARC_XMLCounter__c(Name='ZelisXML',ARC_Date__c=Date.today(),ARC_Counter__c='00.90');
        insert xmlCounter;

        Test.startTest();
            ARC_CounterXMLFile.generateCounter();
        Test.stopTest();
    }
}