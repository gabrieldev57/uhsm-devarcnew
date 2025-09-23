@isTest
public class ARC_CreateRecurringOrderTest {
    @isTest
    public static void testRecurring(){
        ChargentOrders__ChargentOrder__c oldCharg = new ChargentOrders__ChargentOrder__c();
        insert oldCharg;
        List<ChargentOrders__ChargentOrder__c> newList = new List<ChargentOrders__ChargentOrder__c>{oldCharg};
        Test.startTest();
        ARC_CreateRecurringOrder.createChargentOrder(newList);
        Test.stopTest();
        
    }
    

}