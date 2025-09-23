public class AirSlateApi {


    private static final String authorizationToken = 'TcE4GNCODjvEECBle1DcXX96tiaaJ8uLuLQ36ecLSUAzYl6fXxyKmhgMRxAV';
    private static final String callbackUrl = 'http://apicallbacks.pdffiller.com/handle?hash=a75cb8d8';

    public static void createSlate() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint('https://bots.airslate.com/slate-creation-from-event-bot/create-slate');
        request.setMethod('POST');
        
        request.setHeader('Authorization', authorizationToken);
        request.setHeader('Content-Type', 'application/json');
        
        String postData = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'type' => 'slate_creation_requests',
                'attributes' => new Map<String, Object>{
                    'callback_url' => callbackUrl
                }
            },
            'meta' => new Map<String, Object>{
                'fields' => new List<Map<String, Object>>{
                    new Map<String, Object>{ 'id' => 'companyAddress', 'value' => 'St. Juan Ave 1520, 40001, VA' },
                    new Map<String, Object>{ 'id' => 'companyName', 'value' => 'Hello Moto' },
                    new Map<String, Object>{ 'id' => 'memberName', 'value' => 'Tomas Di Luca' },
                    new Map<String, Object>{ 'id' => 'memberEmail', 'value' => 'tomas.diluca@arcsona.com' },
                    new Map<String, Object>{ 'id' => 'memberBirthdate', 'value' => '1990-05-02' },
                    new Map<String, Object>{ 'id' => 'name', 'value' => new List<String>{ 'Tomas', 'Maria', 'Alfonsina', 'Francisco', 'Julieta' } },
                    new Map<String, Object>{ 'id' => 'dob', 'value' => new List<String>{ '1990-05-02', '1995-10-02', '2025-07-31', '2027-11-12', '2028-10-01' } },
                    new Map<String, Object>{ 'id' => 'ssn', 'value' => new List<String>{ '123-45', '987-65', '456-78', '321-54', '654-32' } },
                    new Map<String, Object>{ 'id' => 'email', 'value' => new List<String>{ 'tomas@rt.com', 'maria@rt.com', 'alfonsina@rt.com', 'diego@rt.com', 'julieta@rt.com' } },
                    new Map<String, Object>{ 'id' => 'gender', 'value' => new List<String>{ 'Male', 'Female', 'Female', 'Male', 'Female' } },
                    new Map<String, Object>{ 'id' => 'pregnant', 'value' => new List<String>{ 'No', 'Yes', 'No', 'No', 'No' } },
                    new Map<String, Object>{ 'id' => 'weight', 'value' => new List<String>{ '90kg', '65kg', '40kg', '30kg', '20kg' } },
                    new Map<String, Object>{ 'id' => 'height', 'value' => new List<String>{ '180cm', '165cm', '100cm', '90cm', '70cm' } }
                }
            }
        });
        
        request.setBody(postData);
        
        try {

            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 201 || response.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                System.debug('responseMap ' + responseMap);
                if (responseMap.containsKey('data')) {
                    Map<String, Object> data = (Map<String, Object>) responseMap.get('data');
                    System.debug('data ' + data);
                    String requestId = (String) data.get('id');
                    System.debug('Slate created on request_id: ' + requestId);
                }
            } else {
                System.debug('Error Response: ' + response.getStatusCode() + ' - ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Error POST: ' + e.getMessage());
        }
    }
 
}