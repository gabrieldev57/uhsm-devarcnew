@RestResource(urlMapping='/api/v1/individual-enrollment/*')
global with sharing class ARC_IndividualEnrollmentEndpoint {

    // ---- Router helpers ----
    private static String basePath() { return '/services/apexrest/api/v1/individual-enrollment'; }
    private static String pathAfterBase() {
        String uri = RestContext.request.requestURI; // e.g. /api/v1/individual-enrollment/reprice-family
        System.debug('Full URI: ' + uri);
        
        // Get everything after the last '/'
        Integer lastSlash = uri.lastIndexOf('/');
        if (lastSlash != -1 && lastSlash < uri.length() - 1) {
            String pathAfter = uri.substring(lastSlash);
            System.debug('Path after last slash: ' + pathAfter);
            
            // Extract the route name (remove leading '/')
            String route = pathAfter.startsWith('/') ? pathAfter.substring(1) : pathAfter;
            System.debug('Route: ' + route);
            return route;
        }
        
        return '';
    }
    private static void json(Integer code, Object body) {
        RestResponse res = RestContext.response;
        res.statusCode = code;
        res.addHeader('Content-Type', 'application/json; charset=UTF-8');
        res.responseBody = Blob.valueOf(JSON.serialize(body));
    }

    //Declared methods for the endpoints to return the response in the correct format   
    //200 - OK
    //201 - Created
    //204 - No Content
    //400 - Bad Request
    //404 - Not Found
    //500 - Internal Server Error
    private static void ok(Object data){ json(200, new Map<String,Object>{ 'status'=>'ok', 'data'=>data }); }
    private static void created(Object data){ json(201, new Map<String,Object>{ 'status'=>'ok', 'data'=>data }); }
    private static void noContent(){ json(204, new Map<String,Object>{ 'status'=>'ok', 'message'=>'Success' }); }
    private static void bad(String msg){ json(400, new Map<String,Object>{ 'status'=>'error', 'message'=>msg }); }
    private static void notFound(String msg){ json(404, new Map<String,Object>{ 'status'=>'error', 'message'=>msg }); }
    private static void fail(Exception e){ json(500, new Map<String,Object>{ 'status'=>'error', 'message'=>e.getMessage() }); }

    // ---- GET: e.g. /.../group-data/{memberId} or /.../get-agents
    @HttpGet
    global static void get() {
        try {
            String route = pathAfterBase(); // e.g. group-data/003XXXXXXXXXXXX or get-agents
            List<String> seg = route.split('/');
            
            if (route == 'get-agents') {
                try {
                    // Get query parameters
                    Map<String, String> params = RestContext.request.params;
                    String agentName = params.get('agentName');
                    
                    // Prepare input map for ARC_Agents
                    Map<String, Object> inputMap = new Map<String, Object>();
                    if (String.isNotBlank(agentName)) {
                        inputMap.put('AgentName', agentName);
                    }
                    
                    // Call ARC_Agents class to get agents
                    Map<String, Object> outputMap = new Map<String, Object>();
                    ARC_Agents.readAgents(inputMap, outputMap, new Map<String, Object>());
                    
                    List<User> agents = (List<User>)outputMap.get('agents');
                    
                    if (agents != null) {
                        // Format response with Id and Name for each agent
                        List<Map<String, Object>> agentList = new List<Map<String, Object>>();
                        for (User agent : agents) {
                            Map<String, Object> agentData = new Map<String, Object>();
                            agentData.put('id', agent.Id);
                            agentData.put('name', agent.Name);
                            agentList.add(agentData);
                        }
                        
                        ok(new Map<String,Object>{ 
                            'Status'=>'200', 
                            'StatusMessage'=>'Agents retrieved successfully',
                            'agents' => agentList
                        });
                    } else {
                        ok(new Map<String,Object>{ 
                            'Status'=>'200', 
                            'StatusMessage'=>'No agents found',
                            'agents' => new List<Map<String, Object>>()
                        });
                    }
                } catch (Exception e) {
                    // Log error for debugging purposes
                    ARC_IndividualEnrollmentHelper.logError('ARC_IndividualEnrollmentEndpoint.get-agents', e, 'GET request');
                    bad('Error retrieving agents: ' + e.getMessage());
                    return;
                }
                return;
            }
            
            bad('Unknown GET route');
        } catch (Exception e) { fail(e); }
    }

    // ---- POST: e.g. /.../reprice-family
    @HttpPost
    global static void post() {
        try {
            DateTime startTime = DateTime.now();    
            Map<String, Object> serviceResponse = new Map<String, Object>();        
            String route = pathAfterBase(); // e.g. reprice-family (already cleaned)
            Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
            System.debug('body: '+body);
            
            
            // Fallback: check query parameters if path parsing fails
            Map<String, String> params = RestContext.request.params;
            
            // Check if the route is 'reprice-family'
            if (route == 'reprice-family') {
                // Create integration log record
                //String logId = createIntegrationLog('reprice-family', body);
                //Need to call pricing IP or logic


                system.debug('body 75 : '+body);

                if(body != null) {

                    try{ 
                        String procedureAPIName = 'IFPShop_GetProducts';
                        Map<String, Object> ipOutput = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, body, new Map<String, Object>());
                        System.debug('ipOutput: '+ipOutput);

                        //This needs to be excecuted in a future context
                        if(ipOutput != null) {
                            // TODO: call save enrollment logic with 'body'
                            ok(new Map<String,Object>{ 
                                'Status'=>'200', 
                                'StatusMessage'=>'Success', 
                                'ipOutput' => ipOutput 
                            });
                            return;
                        }
                        
                        else {
                            bad('Error calling integration procedure: smallGroup_GetProducts');
                            return;
                        }
                    }
                    catch(Exception e) {
                        // Log error to Custom_Logs__c for debugging purposes
                        ARC_IndividualEnrollmentHelper.logError('ARC_IndividualEnrollmentEndpoint.reprice-family', e, JSON.serialize(body));
                        bad('Error calling integration procedure: '+e.getMessage());
                        return;
                    }                    
                }
            }
            else if (route == 'reprice-ancillaries') {
                // Create integration log record
                //String logId = createIntegrationLog('reprice-ancillaries', body);
                //Need to call pricing IP or logic


                system.debug('body reprice-ancillaries : '+body);

                if(body != null) {

                    try{
                        //call the integration Procedure
                        String procedureAPIName = 'IFPShop_GetAncillaries';
                        Map<String, Object> ipOutput = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, body, new Map<String, Object>());
                        System.debug('ipOutput: '+ipOutput);

                        //This needs to be excecuted in a future context
                        if(ipOutput != null) {
                            // TODO: call save enrollment logic with 'body'
                            ok(new Map<String,Object>{ 
                                'Status'=>'200', 
                                'StatusMessage'=>'Success', 
                                'ipOutput' => ipOutput 
                            });
                            return;
                        }
                        
                        else {
                            bad('Error calling integration procedure: smallGroup_GetAncillaries');
                            return;
                        }
                    }
                    catch(Exception e) {
                        // Log error to Custom_Logs__c for debugging purposes
                        ARC_IndividualEnrollmentHelper.logError('ARC_IndividualEnrollmentEndpoint.reprice-ancillaries', e, JSON.serialize(body));
                        bad('Error calling integration procedure: '+e.getMessage());
                        return;
                    }                    
                }
            } 
            else if (route == 'create-lead') {
                if (body == null) {
                    bad('Lead data is required');
                    return;
                }
                
                // Step 1: Validate lead data
                Map<String, Object> validationResult = ARC_IndividualEnrollmentHelper.validateLeadData(body);
                if (!(Boolean)validationResult.get('isValid')) {
                    List<String> errors = (List<String>)validationResult.get('errors');
                    String errorMessage = 'Lead validation failed with ' + validationResult.get('errorCount') + ' error(s): ' + String.join(errors, '; ');
                    System.debug('Lead validation failed: ' + errorMessage);
                    bad(errorMessage);
                    return;
                }
                
                System.debug('Lead data validation passed successfully');
                
                // Step 2: Create lead and lead source
                Map<String, Object> leadResult = new Map<String, Object>();
                try {
                    Map<String, Object> outputMap = new Map<String, Object>();
                    ARC_IndividualEnrollmentHelper.upsertLeadSourceReferral(body, outputMap, new Map<String, Object>());
                    
                    if (outputMap.containsKey('LeadId')) {
                        leadResult.put('leadId', outputMap.get('LeadId'));
                        leadResult.put('leadSourceId', outputMap.get('LeadSourceId'));
                        leadResult.put('success', true);
                        
                        created(new Map<String,Object>{ 
                            'Status'=>'201', 
                            'StatusMessage'=>'Lead created successfully',
                            'data' => leadResult
                        });
                        return;
                    } else {
                        bad('Failed to create lead');
                        return;
                    }
                } catch (Exception e) {
                    // Log error for debugging purposes
                    ARC_IndividualEnrollmentHelper.logError('ARC_IndividualEnrollmentEndpoint.create-lead', e, JSON.serialize(body));
                    bad('Error creating lead: ' + e.getMessage());
                    return;
                }
            }
            else if (route == 'save-enrollment') {
                if (body == null) {
                    bad('Enrollment data is required');
                    return;
                }
                
                
                String logId = ARC_IndividualEnrollmentHelper.createIntegrationLog('save-enrollment', body);
                
                // Step 1: Validate enrollment data
                Map<String, Object> validationResult = ARC_IndividualEnrollmentHelper.validateEnrollmentData(body);
                String primaryName = (String)validationResult.get('PrimaryName');
                if (!(Boolean)validationResult.get('isValid')) {
                    List<String> errors = (List<String>)validationResult.get('errors');
                    String errorMessage = 'Validation failed with ' + validationResult.get('errorCount') + ' error(s): ' + String.join(errors, '; ');
                    System.debug('Enrollment validation failed: ' + errorMessage);
                    bad(errorMessage);
                    return;
                }                
                
                ok(new Map<String,Object>{ 
                    'Status'=>'200', 
                    'StatusMessage'=>'Enrollment data validated successfully. Processing will continue in background.'
                });             

                
                if (logId == null) {
                    System.debug('Error creating integration log record after response');
                    return;
                }
                
    
             
                try {
                    Map<String, Object> outputMap = new Map<String, Object>();
                    serviceResponse = new ARC_SEBaseService().invokeMethod('processSelfEnrollment', body, outputMap, new Map<String, Object>());
                    System.debug('serviceResponse: ' + serviceResponse);
                } catch (Exception e) {
                    System.debug('Error calling ARC_SEBaseService.invokeMethod: ' + e.getMessage());
                    serviceResponse.put('success', false);
                    serviceResponse.put('errorMessage', e.getMessage());
                    serviceResponse.put('errorStackTrace', e.getStackTraceString());
                }
                Id groupAccountId = serviceResponse.containsKey('groupAccountId') ? (Id)serviceResponse.get('groupAccountId') : null ;
                String groupAccountName = serviceResponse.containsKey('groupAccountId') ? (String)serviceResponse.get('groupAccountName') : 'Not Found.';



                
                // Update integration log with results
                DateTime endTime = DateTime.now();
                Long durationMs = endTime.getTime() - startTime.getTime();
                serviceResponse.put('processedAt', endTime);
                
                try {
                    Boolean isSuccess = (Boolean)serviceResponse.get('success');
                    if (isSuccess == true) {
                        ARC_IndividualEnrollmentHelper.updateIntegrationLog(logId, true, 200, null, null, endTime, durationMs, groupAccountId, groupAccountName);
                        System.debug('Enrollment processing completed successfully after response');
                    } else {
                        String errorMessage = (String)serviceResponse.get('errorMessage');
                        ARC_IndividualEnrollmentHelper.updateIntegrationLog(logId, false, 500, 'SERVICE_ERROR', errorMessage, endTime, durationMs, groupAccountId, groupAccountName);
                        System.debug('Error processing self enrollment data save after response: ' + errorMessage);
                    }
                } catch (Exception e) {
                    ARC_IndividualEnrollmentHelper.updateIntegrationLog(logId, false, 500, 'EXCEPTION', e.getMessage(), endTime, durationMs, groupAccountId, groupAccountName);
                    System.debug('Exception during enrollment processing after response: ' + e.getMessage());
                }
            }
            else if (route == 'validate-promotion') {
                if (body == null) {
                    bad('Promotion code data is required'); 
                    return;
                }
                
                // Step 1: Validate promotion code data
                Map<String, Object> validationResult = ARC_IndividualEnrollmentHelper.validatePromotionCodeData(body);
                if (!(Boolean)validationResult.get('isValid')) {
                    List<String> errors = (List<String>)validationResult.get('errors');
                    String errorMessage = 'Validation failed with ' + validationResult.get('errorCount') + ' error(s): ' + String.join(errors, '; ');
                    System.debug('Promotion code validation failed: ' + errorMessage);
                    bad(errorMessage);
                    return;
                }
                
                System.debug('Promotion code data validation passed successfully');
                
                // Step 2: Validate promotion code and return discount percentage
                try {
                    String promotionCode = (String)body.get('promotionCode');
                    Map<String, Object> promotionResult = ARC_IndividualEnrollmentHelper.validatePromotionCode(promotionCode);
                    
                    if ((Boolean)promotionResult.get('isValid')) {
                        // Include all promotion fields in the response
                        Map<String, Object> responseData = new Map<String, Object>();
                        responseData.put('Status', '200');
                        responseData.put('StatusMessage', 'Promotion code is valid');
                        responseData.put('promotionCode', promotionCode);
                        
                        // Add all promotion fields from the validation result
                        for (String key : promotionResult.keySet()) {
                            if (key != 'isValid' && key != 'message') {
                                responseData.put(key, promotionResult.get(key));
                            }
                        }
                        
                        ok(responseData);
                    } else {
                        bad((String)promotionResult.get('message'));
                    }
                } catch (Exception e) {
                    // Log error for debugging purposes
                    ARC_IndividualEnrollmentHelper.logError('ARC_IndividualEnrollmentEndpoint.validate-promotion', e, JSON.serialize(body));
                    bad('Error validating promotion code: ' + e.getMessage());
                    return;
                }
            }
            else if (route == 'qualify-lead') {
                if (body == null) {
                    bad('Lead qualification data is required');
                    return;
                }
                
                try {
                    // Call ARC_LeadHandler class to qualify lead
                    Map<String, Object> outputMap = new Map<String, Object>();
                    ARC_LeadHandler.qualifyLead(body, outputMap, new Map<String, Object>());
                    
                    Boolean success = (Boolean)outputMap.get('success');
                    
                    if (success == true) {
                        ok(new Map<String,Object>{ 
                            'Status'=>'200', 
                            'StatusMessage'=>'Lead qualified successfully'
                        });
                    } else {
                        bad('Failed to qualify lead');
                    }
                } catch (Exception e) {
                    // Log error for debugging purposes
                    ARC_IndividualEnrollmentHelper.logError('ARC_IndividualEnrollmentEndpoint.qualify-lead', e, JSON.serialize(body));
                    bad('Error qualifying lead: ' + e.getMessage());
                    return;
                }
            }
            else if(route == 'reprice-assigned-ancillaries'){
				if (body == null) {
					bad('Assigned ancillaries data is required');
					return;
				}
				
				try {
					// Expecting shape: { "plans": [ { "selectedProduct": { "Id": "<productId>" }, "userInputs": [ ... ] }, ... ] }
					Object plansObj = body.get('plans');
					if (plansObj == null) {
						bad('Missing required node: plans');
						return;
					}
					
					if (!(plansObj instanceof List<Object>)) {
						bad('Invalid format: plans must be an array');
						return;
					}
					
					List<Object> plans = (List<Object>)plansObj;
					if (plans.isEmpty()) {
						bad('No plans provided to price');
						return;
					}
					
					// Directly invoke getRatedProducts for each plan and return only productId and userInputs
					Boolean anyValid = false;
					List<Map<String, Object>> responseResults = new List<Map<String, Object>>();
					
					for (Object planObj : plans) {
						if (!(planObj instanceof Map<String, Object>)) {
							continue;
						}
						Map<String, Object> plan = (Map<String, Object>)planObj;
						
						// selectedProduct.Id
						String productId = null;
						if (plan.containsKey('selectedProduct') && plan.get('selectedProduct') instanceof Map<String, Object>) {
							Map<String, Object> selectedProduct = (Map<String, Object>)plan.get('selectedProduct');
							productId = (String)selectedProduct.get('Id');
						}
						if (String.isBlank(productId)) {
							// Skip plans without a product id
							continue;
						}
						
						// userInputs array for this plan
						List<Map<String, Object>> userInputs = new List<Map<String, Object>>();
						if (plan.containsKey('userInputs') && plan.get('userInputs') instanceof List<Object>) {
							List<Object> rawUserInputs = (List<Object>)plan.get('userInputs');
							for (Object ui : rawUserInputs) {
								if (ui instanceof Map<String, Object>) {
									userInputs.add((Map<String, Object>)ui);
								}
							}
						}
						
						// We have a valid plan with a productId; call getRatedProducts (ignore response payload details)
						anyValid = true;
						Map<String, Object> rMap = new Map<String, Object>();
						rMap.put('productId', productId);
						rMap.put('userInputs', userInputs);
						
						try {
							Map<String, Object> inputMap = new Map<String, Object>();
							Map<String, Object> outMap = new Map<String, Object>();
							Map<String, Object> options = new Map<String, Object>();
							
							inputMap.put('userInputs', userInputs);
							options.put('whereClause', 'Id = \'' + productId + '\'');
							
							Type classType = Type.forName('vlocity_ins', 'InsProductService');
							vlocity_ins.VlocityOpenInterface2 obj = (vlocity_ins.VlocityOpenInterface2) classType.newInstance();
							obj.invokeMethod('getRatedProducts', inputMap, outMap, options);
							
							// Include full JSON result from getRatedProducts in response
							Object rawResult = outMap.get('result');
							if (rawResult != null) {
								Map<String, Object> safeResult = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(rawResult));
								rMap.put('result', safeResult);
							}
						} catch (Exception exPerPlan) {
							rMap.put('errorMessage', exPerPlan.getMessage());
						}
						
						responseResults.add(rMap);
					}
					
					if (!anyValid) {
						bad('No valid plans with productId and userInputs were found');
						return;
					}
					
					// Respond with only productId and userInputs (and errorMessage if present)
					
					ok(new Map<String, Object>{
						'Status' => '200',
						'StatusMessage' => 'Success',
						'results' => responseResults
					});
					return;
				} catch (Exception e) {
					ARC_IndividualEnrollmentHelper.logError('ARC_IndividualEnrollmentEndpoint.reprice-assigned-ancillaries', e, JSON.serialize(body));
					bad('Error calculating prices: ' + e.getMessage());
					return;
				}
			}
			else{
				bad('Unknown POST route');
				return;
			}
        } catch (Exception e) { fail(e); }
    }
 
    // ---- PUT: e.g. /.../enrollments/{id}
    @HttpPut
    global static void put() {
        try {
            String route = RestContext.request.requestURI;
            String path = route.substring(basePath().length()); // /enrollments/{id}
            List<String> seg = path.split('/');
            if (seg.size() >= 3 && seg[1] == 'enrollments') {
                String id = seg[2];
                if (!isValidId(id)) { bad('Invalid or missing enrollmentId'); return; }
                Map<String,Object> body = (Map<String,Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());
                String status = (String)body.get('status');

                // TODO: update logic
                ok(new Map<String,Object>{ 'message'=>'Enrollment updated', 'enrollmentId'=>id, 'newStatus'=>status });
                return;
            }
            bad('Unknown PUT route');
        } catch (Exception e) { fail(e); }
    }

    // ---- Helpers ----
    private static Boolean isValidId(String s) {
        if (String.isBlank(s)) return false;
        if (!Pattern.matches('^[a-zA-Z0-9]{15,18}$', s)) return false;
        // Optional: ensure it exists
        try { Id tmp = (Id)s; return true; } catch (Exception ex) { return false; }
    }
}