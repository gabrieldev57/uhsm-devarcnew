@RestResource(urlMapping='/API/ARC_UpdatePaymentMethod/*')
global with sharing class ARC_UpdatePaymentMethod_API 
{
    @HttpPost
    global static String postHandler() {
        String result = '404';
        switch on RestContext.request.requestURI.substringAfterLast('/'){                
            when 'IdentifyCardType' {
                // Read the raw JSON body from the request
                RestRequest req = RestContext.request;
                String requestBody = req.requestBody.toString();
                
                // Parse the JSON into an Apex object;
                IdentifyCardTypeWrapper input;
                try {
                    input = (IdentifyCardTypeWrapper) JSON.deserialize(requestBody, IdentifyCardTypeWrapper.class);
                } catch (Exception e) {
                    // Handle bad JSON
                    RestContext.response.statusCode = 400;
                    return 'Invalid JSON format: ' + e.getMessage();
                }
        		result = ARC_UpdatePaymentMethod.identifyCardType(input.cardNumber);
            }
        }
        return result;
    }
        
    global class IdentifyCardTypeWrapper {
        public String cardNumber;
    }
}