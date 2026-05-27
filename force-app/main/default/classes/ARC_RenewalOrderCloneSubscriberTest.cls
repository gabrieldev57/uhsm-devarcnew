@IsTest
private class ARC_RenewalOrderCloneSubscriberTest {

    // Covers the trigger via EventBus.publish — PE fires synchronously inside startTest/stopTest
    @IsTest
    static void testTriggerViaPlatformEvent() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c sourceOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c        = acc.Id,
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Payment_Status__c = 'Stopped',
            ChargentOrders__Payment_Stop__c   = 'Unending',
            ChargentOrders__Tokenization__c   = 'tok_trigger_test',
            ChargentOrders__Bank_Routing_Number__c = '021000021',
            ChargentOrders__Bank_Account_Number__c = '987654321'
        );
        insert sourceOrder;

        ChargentOrders__ChargentOrder__c newOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c        = acc.Id,
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Payment_Status__c = 'Stopped',
            ChargentOrders__Payment_Stop__c   = 'Unending',
            ChargentOrders__Description__c    = 'Recurring Monthly Order'
        );
        insert newOrder;

        Test.startTest();
        EventBus.publish(new ARC_RenewalOrderClone__e(
            SourceOrderId__c = sourceOrder.Id,
            NewOrderId__c    = newOrder.Id
        ));
        Test.stopTest();

        ChargentOrders__ChargentOrder__c result = [
            SELECT ChargentOrders__Tokenization__c,
                   ChargentOrders__Bank_Routing_Number__c,
                   ChargentOrders__Bank_Account_Number__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :newOrder.Id
        ];

        System.assertEquals('tok_trigger_test', result.ChargentOrders__Tokenization__c, 'Tokenization should be copied via trigger');
        System.assertEquals('021000021', result.ChargentOrders__Bank_Routing_Number__c, 'Routing number should be copied via trigger');
        System.assertEquals('987654321', result.ChargentOrders__Bank_Account_Number__c, 'Account number should be copied via trigger');
    }

    @IsTest
    static void testCopiesEncryptedFieldsFromSourceToNew() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ChargentOrders__ChargentOrder__c sourceOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c       = acc.Id,
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Payment_Status__c = 'Stopped',
            ChargentOrders__Payment_Stop__c   = 'Unending',
            ChargentOrders__Tokenization__c   = 'tok_test_123',
            ChargentOrders__Bank_Routing_Number__c  = '021000021',
            ChargentOrders__Bank_Account_Number__c  = '987654321'
        );
        insert sourceOrder;

        ChargentOrders__ChargentOrder__c newOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c        = acc.Id,
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Payment_Status__c = 'Stopped',
            ChargentOrders__Payment_Stop__c   = 'Unending',
            ChargentOrders__Description__c    = 'Recurring Monthly Order'
        );
        insert newOrder;

        Test.startTest();
        ARC_RenewalOrderCloneSubscriber.run(new List<ARC_RenewalOrderClone__e>{
            new ARC_RenewalOrderClone__e(
                SourceOrderId__c = sourceOrder.Id,
                NewOrderId__c    = newOrder.Id
            )
        });
        Test.stopTest();

        ChargentOrders__ChargentOrder__c result = [
            SELECT ChargentOrders__Tokenization__c,
                   ChargentOrders__Bank_Routing_Number__c,
                   ChargentOrders__Bank_Account_Number__c,
                   ChargentOrders__Card_Number__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :newOrder.Id
        ];

        System.assertEquals('tok_test_123', result.ChargentOrders__Tokenization__c, 'Tokenization should be copied');
        System.assertEquals('021000021',    result.ChargentOrders__Bank_Routing_Number__c, 'Routing number should be copied');
        System.assertEquals('987654321',    result.ChargentOrders__Bank_Account_Number__c, 'Account number should be copied');
        System.assertEquals(null,           result.ChargentOrders__Card_Number__c, 'Card number should remain null');
    }

    @IsTest
    static void testSkipsEventsWithNullIds() {
        Test.startTest();
        ARC_RenewalOrderCloneSubscriber.run(new List<ARC_RenewalOrderClone__e>{
            new ARC_RenewalOrderClone__e(SourceOrderId__c = null, NewOrderId__c = null)
        });
        Test.stopTest();

        System.assert(true, 'No exception expected for null ID events');
    }

    @IsTest
    static void testCopiesCreditCardFields() {
        Account acc = new Account(Name = 'CC Account');
        insert acc;

        ChargentOrders__ChargentOrder__c sourceOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c        = acc.Id,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Payment_Status__c = 'Stopped',
            ChargentOrders__Payment_Stop__c   = 'Unending',
            ChargentOrders__Tokenization__c   = 'card_tok_456',
            ChargentOrders__Card_Number__c    = '4111111111111111'
        );
        insert sourceOrder;

        ChargentOrders__ChargentOrder__c newOrder = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c        = acc.Id,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Payment_Status__c = 'Stopped',
            ChargentOrders__Payment_Stop__c   = 'Unending',
            ChargentOrders__Description__c    = 'Recurring Monthly Order'
        );
        insert newOrder;

        Test.startTest();
        ARC_RenewalOrderCloneSubscriber.run(new List<ARC_RenewalOrderClone__e>{
            new ARC_RenewalOrderClone__e(
                SourceOrderId__c = sourceOrder.Id,
                NewOrderId__c    = newOrder.Id
            )
        });
        Test.stopTest();

        ChargentOrders__ChargentOrder__c result = [
            SELECT ChargentOrders__Tokenization__c, ChargentOrders__Card_Number__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id = :newOrder.Id
        ];

        System.assertEquals('card_tok_456',     result.ChargentOrders__Tokenization__c, 'Tokenization should be copied');
        System.assertEquals('4111111111111111', result.ChargentOrders__Card_Number__c, 'Card number should be copied');
    }
}