@RestResource(urlMapping='/api/v1/individual-enrollment')
global with sharing class ARC_IndividualEnrollmentEndpoint {

    // ---------------------------
    // GET: fetch enrollment data
    // ---------------------------
    @HttpGet
    global static void getIndividualEnrollmentData() {
        try {
            Map<String, String> params   = RestContext.request.params;
            String methodName            = params.get('methodName');
            String memberId              = params.get('memberId');
           

            if (methodName == 'getGroupDataFromPrimary') {
                if (String.isBlank(memberId) || !isValidId(memberId)) {
                    writeJson(new Map<String, Object>{ 'error' => 'Invalid or missing memberId.' }, 400);
                    return;
                }

                Map<String, Object> membersData = getMembersDataFromPrimary(memberId);

                Map<String, Object> response = new Map<String, Object>{
                    'enrollmentId' => memberId,
                    'members'      => membersData
                };
                writeJson(response, 200);
            } else {
                writeJson(new Map<String, Object>{ 'error' => 'Invalid methodName.' }, 400);
            }
        } catch (Exception e) {
            writeJson(new Map<String, Object>{ 'error' => e.getMessage() }, 500);
        }
    }

    /**
     * POST endpoint for creating individual enrollment data
     */
    @HttpPost
    global static void createIndividualEnrollmentData() {
        try {
            // https://uhsm--devarc.sandbox.my.salesforce.com/services/apexrest/api/v1/individual-enrollment?methodName=repriceFamily

            Map<String, String> params   = RestContext.request.params;
            String methodName            = params.get('methodName');

            String requestBody = RestContext.request.requestBody.toString();
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            System.debug('bodyData: ' + data);



            if (methodName == 'repriceFamily') {
                Map<String, Object> response = new Map<String, Object>{
                    'Status' => '200',
                    'StatusMessage'      => 'Success'
                };
                writeJson(response, 200);                
            } else {
                writeJson(new Map<String, Object>{ 'error' => 'Invalid methodName.' }, 400);
            }
            
        } catch (Exception e) {
            writeJson(new Map<String, Object>{ 'error' => e.getMessage() }, 500);
        }
    }

    /**
     * PUT endpoint for updating individual enrollment data
     */
    @HttpPut
    global static String updateIndividualEnrollmentData() {
        try {
            // Set content type to avoid JSON escaping issues
            RestContext.response.addHeader('Content-Type', 'application/json');
            
            String requestBody = RestContext.request.requestBody.toString();
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            String enrollmentId = (String) data.get('enrollmentId');
            String updatedStatus = (String) data.get('status');

            if (String.isBlank(enrollmentId) || !isValidId(enrollmentId)) {
                return JSON.serialize(new Map<String, String>{
                    'error' => 'Invalid or missing Enrollment ID.'
                });
            }

            // Simulate update logic here
            Map<String, Object> response = new Map<String, Object>{
                'message' => 'Enrollment updated successfully',
                'enrollmentId' => enrollmentId,
                'newStatus' => updatedStatus
            };
            
            return JSON.serialize(response);
        } catch (Exception e) {
            return JSON.serialize(new Map<String, String>{
                'error' => e.getMessage()
            });
        }
    }

    /**
     * DELETE endpoint for removing individual enrollment data
     */
    @HttpDelete
    global static String deleteIndividualEnrollmentData() {
        try {
            // Set content type to avoid JSON escaping issues
            RestContext.response.addHeader('Content-Type', 'application/json');
            
            String requestBody = RestContext.request.requestBody.toString();
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            String enrollmentId = (String) data.get('enrollmentId');

            if (String.isBlank(enrollmentId) || !isValidId(enrollmentId)) {
                return JSON.serialize(new Map<String, String>{
                    'error' => 'Invalid or missing Enrollment ID.'
                });
            }

            // Simulate delete logic here
            Map<String, Object> response = new Map<String, Object>{
                'message' => 'Enrollment deleted successfully',
                'enrollmentId' => enrollmentId
            };
            
            return JSON.serialize(response);
        } catch (Exception e) {
            return JSON.serialize(new Map<String, String>{
                'error' => e.getMessage()
            });
        }
    }

    // Helper method to validate Salesforce IDs
    private static Boolean isValidId(String id) {
        return true;
    }

    //Helper Methods

    // Write JSON response
    private static void writeJson(Object obj, Integer statusCode) {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json; charset=UTF-8');
        res.statusCode   = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(obj));
    }

    // Fetch members for a primary member
    private static Map<String, Object> getMembersDataFromPrimary(String memberId) {
        Map<String, Object> membersData = new Map<String, Object>();

        List<vlocity_ins__GroupCensusMember__c> members = [
            SELECT Id, Name, vlocity_ins__Gender__c, ARC_Age__c, vlocity_ins__Birthdate__c,
                   ARC_Smoker__c, vlocity_ins__Email__c, ARC_Weight__c, ARC_Height__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__RelatedCensusMemberId__c = :memberId OR Id = :memberId
        ];

        for (vlocity_ins__GroupCensusMember__c m : members) {
            Map<String, Object> cleanMember = new Map<String, Object>{
                'id'        => m.Id,
                'name'      => m.Name,
                'gender'    => m.vlocity_ins__Gender__c,
                'age'       => m.ARC_Age__c,
                'birthdate' => m.vlocity_ins__Birthdate__c,
                'smoker'    => m.ARC_Smoker__c,
                'email'     => m.vlocity_ins__Email__c,
                'weight'    => m.ARC_Weight__c,
                'height'    => m.ARC_Height__c
            };
            membersData.put(m.Id, cleanMember);
        }
        return membersData;
    }
}