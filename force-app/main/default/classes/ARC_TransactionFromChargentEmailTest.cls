@isTest
private class ARC_TransactionFromChargentEmailTest {
    
    @TestSetup
    static void makeData(){
        // Create ChargentOrders
        List<ChargentOrders__ChargentOrder__c> orders = ARC_TestUtility.createChargentOrders(2);
        insert orders;
        
        // Create Email Notifications with JSON data
        List<ChargentOrders__Email_Notification__c> notifications = new List<ChargentOrders__Email_Notification__c>();
        
        // Create notification with approved transaction
        ChargentOrders__Email_Notification__c notification1 = new ChargentOrders__Email_Notification__c();
        notification1.ChargentOrders__ChargentOrder__c = orders[0].Id;
        notification1.ChargentOrders__Status__c = 'Received';
        notification1.ChargentOrders__Unresolved_Transaction__c = true;
        notification1.ChargentOrders__Notification_Message__c = 'Test Message';
        notification1.ChargentOrders__Transaction_JSON__c = createTransactionJSON('Approved', orders[0].Id);
        notifications.add(notification1);
        
        // Create notification with declined transaction
        ChargentOrders__Email_Notification__c notification2 = new ChargentOrders__Email_Notification__c();
        notification2.ChargentOrders__ChargentOrder__c = orders[1].Id;
        notification2.ChargentOrders__Status__c = 'Received';
        notification2.ChargentOrders__Unresolved_Transaction__c = true;
        notification2.ChargentOrders__Notification_Message__c = 'Test Message';
        notification2.ChargentOrders__Transaction_JSON__c = createTransactionJSON('Declined', orders[1].Id);
        notifications.add(notification2);
        
        insert notifications;
    }
    
    // Helper method to create JSON for transaction
    private static String createTransactionJSON(String status, Id orderId) {
        Map<String, Object> jsonMap = new Map<String, Object>{
            'ChargentOrders__Response_Status__c' => status,
            'ChargentOrders__Credit_Card_Type__c' => 'Visa',
            'ChargentOrders__Response__c' => 'Test Response',
            'ChargentOrders__Amount__c' => 100.00,
            'ChargentOrders__Billing_First__c' => 'Test',
            'ChargentOrders__Response_Message__c' => 'Test Message',
            'ChargentOrders__Description__c' => 'Test Description',
            'ChargentOrders__Gateway_ID__c' => '12345',
            'ChargentOrders__Authorization__c' => 'AUTH123',
            'ChargentOrders__Payment_Method__c' => 'Credit Card',
            'ChargentOrders__Billing_Province__c' => 'CA',
            'ChargentOrders__Billing_City__c' => 'Test City',
            'ChargentOrders__Gateway_Date__c' => '2023-01-01T12:00:00.000Z',
            'ChargentOrders__AVS_International__c' => 'Test',
            'ChargentOrders__Billing_Email__c' => 'test@example.com',
            'ChargentOrders__Reason_Code__c' => 0,
            'ChargentOrders__AVS_Zip__c' => '12345',
            'ChargentOrders__Billing_Phone__c' => '555-1234',
            'ChargentOrders__Card_Code_Response__c' => 'M',
            'ChargentOrders__Order__c' => orderId,
            'ChargentOrders__Billing_Country__c' => 'US',
            'ChargentOrders__Card_Last_4__c' => '1234',
            'ChargentOrders__Billing_Company__c' => 'Test Company',
            'ChargentOrders__Gateway_Response__c' => 'Test Gateway Response',
            'ChargentOrders__Gateway__c' => null,
            'ChargentOrders__Type__c' => 'Charge',
            'ChargentOrders__Billing_Address_Line_2__c' => 'Suite 100',
            'ChargentOrders__Recurring__c' => true,
            'ChargentOrders__Currency__c' => 'USD',
            'ChargentOrders__Billing_Last__c' => 'LastName',
            'ChargentOrders__Credit_Card_Name__c' => 'Test Card',
            'ChargentOrders__Billing_Fax__c' => '555-5678',
            'ChargentOrders__Billing_Address__c' => '123 Test St',
            'ChargentOrders__Amount_available_for_Refund__c' => 100.00,
            'ChargentOrders__Tokenization__c' => 'TOKEN123',
            'ChargentOrders__Reason_Text__c' => 'Test Reason',
            'ChargentOrders__Billing_Postal_Code__c' => '12345',
            'ChargentOrders__Billing_State__c' => 'CA',
            'ChargentOrders__AVS_Response_Code__c' => 'Y'
        };
        
        return JSON.serialize(jsonMap);
    }
    
    @isTest
    static void testBatchWithSpecificIds() {
        // Query the notification we created
        List<ChargentOrders__Email_Notification__c> notifications = [
            SELECT Id FROM ChargentOrders__Email_Notification__c 
        ];
        
        Set<Id> notificationIds = new Set<Id>();
        for(ChargentOrders__Email_Notification__c notification : notifications) {
            notificationIds.add(notification.Id);
        }
        
        Test.startTest();
        ARC_TransactionFromChargentEmailBatch batch = new ARC_TransactionFromChargentEmailBatch(notificationIds);
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that a transaction was created
        List<ChargentOrders__Transaction__c> transactions = [
            SELECT Id, ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
        ];
        
        System.assertEquals(1, transactions.size(), 'One transaction should be created');
        System.assertEquals('Approved', transactions[0].ChargentOrders__Response_Status__c, 'The transaction should be Approved');
    }
    
    @isTest
    static void testBatchWithAllUnresolvedTransactions() {
        Test.startTest();
        ARC_TransactionFromChargentEmailBatch batch = new ARC_TransactionFromChargentEmailBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that only approved transactions were created
        List<ChargentOrders__Transaction__c> transactions = [
            SELECT Id, ChargentOrders__Response_Status__c
            FROM ChargentOrders__Transaction__c
        ];
        
        System.assertEquals(1, transactions.size(), 'One transaction should be created');
        System.assertEquals('Approved', transactions[0].ChargentOrders__Response_Status__c, 'The transaction should be Approved');
    }
    
    @isTest
    static void testBatchWithNoData() {
        // Delete all notification records
        delete [SELECT Id FROM ChargentOrders__Email_Notification__c];
        
        Test.startTest();
        ARC_TransactionFromChargentEmailBatch batch = new ARC_TransactionFromChargentEmailBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify that no transactions were created
        List<ChargentOrders__Transaction__c> transactions = [
            SELECT Id FROM ChargentOrders__Transaction__c
        ];
        
        System.assertEquals(0, transactions.size(), 'No transactions should be created');
    }
    
}