@isTest
public class ARC_UpdatePaymentMethod_API_Test {
    
    @isTest
    static void testIdentifyCardType_ValidInput() {
        // Create a sample JSON body that matches the wrapper class
        // Using test Discover card number
        String jsonInput = '{"cardNumber": "6011000990139424"}';

        // Set up mock REST request context
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/API/ARC_UpdatePaymentMethod/IdentifyCardType';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInput);

        RestResponse res = new RestResponse();

        // Assign to static context
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        System.debug('responseBody = ' +res.responseBody);
        String responseBody = ARC_UpdatePaymentMethod_API.postHandler();
        Test.stopTest();
		System.debug(responseBody);
        // Assert expected output
        System.assertEquals('Discover', responseBody);
    }
    
    @isTest
    static void testIdentifyCardType_InvalidCard() {
        // Create a sample JSON body that matches the wrapper class
        // Using bad card number
        String jsonInput = '{"cardNumber": "8675309"}';

        // Set up mock REST request context
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/API/ARC_UpdatePaymentMethod/IdentifyCardType';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInput);

        RestResponse res = new RestResponse();

        // Assign to static context
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        System.debug('responseBody = ' +res.responseBody);
        String responseBody = ARC_UpdatePaymentMethod_API.postHandler();
        Test.stopTest();
		System.debug(responseBody);
        // Assert expected output
        System.assertEquals('Unknown card type', responseBody);
    }
    
    @isTest
    static void testIdentifyCardType_InvalidJSON() {
        // Create a sample JSON body that matches the wrapper class
        // Using bad card number
        String jsonInput = '{"6011000990139424"}';

        // Set up mock REST request context
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/API/ARC_UpdatePaymentMethod/IdentifyCardType';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInput);

        RestResponse res = new RestResponse();

        // Assign to static context
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the method
        Test.startTest();
        System.debug('responseStatus = ' +res.statusCode);
        String responseBody = ARC_UpdatePaymentMethod_API.postHandler();
        Test.stopTest();
		System.debug(responseBody);
        // Assert expected output
        System.assertEquals('Invalid JSON format:', responseBody.left(20));
    }
}