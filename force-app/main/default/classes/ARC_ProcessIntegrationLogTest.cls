@IsTest
private class ARC_ProcessIntegrationLogTest {

    // Generate the input
    private static Map<String, Object> generateInputMap(){
        // Variables
        Map<String, Object> generalInformation = new Map<String, Object>();
        List<Object> members = new List<Object>();
        Map<String, Object> inputMap = new Map<String, Object>(); 

        // Test data generation
        List<Product2> productTest = ARC_TestUtility.createTestProducts(6);
        User userTest = ARC_TestUtility.createTestUsers(1, 'Standard User')[0];
        Lead leadTest = ARC_TestUtility.createTestLeads(1)[0];
        insert leadTest;

        vlocity_ins__ProductChildItem__c productChildItemTest = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = productTest[0].Id,
            vlocity_ins__ChildProductId__c = productTest[2].Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        vlocity_ins__ProductChildItem__c productChildItemTest2 = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = productTest[1].Id,
            vlocity_ins__ChildProductId__c = productTest[3].Id,
            vlocity_ins__ChildLineNumber__c = '2'
        );
        vlocity_ins__ProductChildItem__c productChildItemTest3 = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = productTest[4].Id,
            vlocity_ins__ChildProductId__c = productTest[5].Id,
            vlocity_ins__ChildLineNumber__c = '3'
        );
        List<vlocity_ins__ProductChildItem__c> productChildItemsList = new List<vlocity_ins__ProductChildItem__c>();
        productChildItemsList.add(productChildItemTest);
        productChildItemsList.add(productChildItemTest2);
        productChildItemsList.add(productChildItemTest3);
        insert productChildItemsList;

        ARC_PromotionCode__c promotionTest = new ARC_PromotionCode__c();
        promotionTest.Name = 'App Fee 50';
        promotionTest.ARC_PromotionCode__c = 'AppFee50';
        promotionTest.ARC_DiscountedAmount__c = 50;
        promotionTest.ARC_StartDate__c = Date.valueOf('2025-10-01');
        promotionTest.ARC_ApplyOver__c = 'App Fee';
        // promotionTest.ARC_Active__c = true;
        insert promotionTest;

        // Insert required template for query
        ARC_DocuSignTemplates__c customTemplate = new ARC_DocuSignTemplates__c(
            ARC_Template_Name__c = 'Custom Template',
            ARC_PlanType__c = 'WeShare',
            ARC_Contract_Reasons__c = 'New Application',
            ARC_Min_Dependents__c = 0,
            ARC_Max_Dependents__c = 10,
            ARC_State__c = 'CA',
            ARC_DRTransform__c = 'Some Value',
            Name = 'Custom Template'
        );
        insert customTemplate;
        
        vlocity_ins__VlocityDocuSignTemplate__c template = new vlocity_ins__VlocityDocuSignTemplate__c(
            Name = 'Custom Template',
            vlocity_ins__templateidentifier__c = 'tmpl-123'
        );
        insert template;
        

        // Test data modifications
        Product2 childProduct = productTest[2];
        childProduct.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Coverage Spec').getRecordTypeId();
        Product2 childProduct2 = productTest[3];
        childProduct2.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Coverage Spec').getRecordTypeId();
        Product2 childProduct3 = productTest[5];
        childProduct3.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Coverage Spec').getRecordTypeId();
        List<Product2> productsList = new List<Product2>();
        productsList.add(childProduct);
        productsList.add(childProduct2);
        productsList.add(childProduct3);
        update productsList;        

        //generalInformation node
        generalInformation.put('effectiveDate', '2025-11-01');

        generalInformation.put('medicalProgram', new Map<String, Object> {
            'productId' => productTest[0].Id, 
            'name' => 'WeShare 6k',
            'productCode' => 'PROG_UHSM_WeShare6k',
            'type' => 'Medical',
            'price' => 896
        });

        generalInformation.put('guardian', new Map<String, Object> {
            'firstName' => 'Paul',
            'middleInitial' => 'A',
            'lastName' => 'Perez',
            'dob' => '1990-06-15',
            'ssn' => '111111111',
            'gender' => 'Male',
            'email' => 'paul.perez@email.com',
            'phone' => '+1-555-123-1111',
            'relationship' => 'Legal Guardian',
            'address' => new Map<String, Object> {
                'street' => '5th avenue',
                'city' => 'New York',
                'state' => 'NY',
                'zip' => '12345'
            }
        });

        generalInformation.put('hipaa', new List<Object> {
            new Map<String, Object> {
                'CHK_Authorized' => true,
                'DAT_DOB' => '2002-09-18',
                'dob' => '2002-09-18',
                'ssn' => '222334444',
                'phone' => '7778987877',
                'relationship' => 'Third Party',
                'lastName' => 'Damian',
                'middleInitial' => 'J',
                'firstName' => 'Juan',
                'email' => 'juan.damian@email.com',
                'address' => new Map<String, Object> {
                    'street' => '123 Main St',
                    'city' => 'Austin',
                    'state' => 'TX',
                    'zip' => '78701'
                }
            },
            new Map<String, Object> {
                'memberExternalId' => 'MEM-002',
                'CHK_Authorized' => true,
                'dob' => '1985-06-15',
                'ssn' => '333445555',
                'phone' => '+1-555-123-4567',
                'relationship' => 'primary',
                'lastName' => 'Doe',
                'middleInitial' => 'A',
                'firstName' => 'John',
                'email' => 'john.doe@email.com',
                'address' => new Map<String, Object> {
                    'street' => '123 Main St',
                    'city' => 'Austin',
                    'state' => 'TX',
                    'zip' => '78701'
                }
            },
            new Map<String, Object> {
                'CHK_Authorized' => true,
                'dob' => '1990-06-15',
                'ssn' => '111111111',
                'phone' => '+1-555-123-1111',
                'relationship' => 'Legal Guardian',
                'lastName' => 'Perez',
                'middleInitial' => 'A',
                'firstName' => 'Paul',
                'email' => 'paul.perez@email.com',
                'address' => new Map<String, Object> {
                    'street' => '5th avenue',
                    'city' => 'New York',
                    'state' => 'NY',
                    'zip' => '12345'
                }
            }
        });

        generalInformation.put('payment', new Map<String, Object> {
            'paymentMethod' => 'credit_card',
            'fee' => 149,
            'discountPrice' => 149,
            'promoCode' => promotionTest.Id,
            'promoName' => 'Promotion Test',
            'discountAmount' => 50,
            'numberOfPayments' => 1,
            'creditCard' => new Map<String, Object> {
                'firstName' => 'John',
                'lastName' => 'Smith',
                'cardNumber' => '4111111111111111',
                'expirationMonth' => '12',
                'expirationYear' => '2027',
                'cvv' => '123',
                'billingAddress' => new Map<String, Object> {
                    'street' => '123 Main Street',
                    'unit' => 'Apt 4B',
                    'city' => 'Austin',
                    'state' => 'TX',
                    'zip' => '78701'
                }
            }
        });

        generalInformation.put('hadAssistance', new Map<String, Object> {
            'agentName' => 'Test User',
            'agentId' => userTest.Id,
            'agentEmail' => 'user.0@mail.com'
        });

        generalInformation.put('leadId', leadTest.Id);

        generalInformation.put('totalMonthlyPremium', 1161);
        generalInformation.put('signerEmail', 'john.doe@email.com');
        
        // members node
        members.add(
            // Member #1
            new Map<String, Object> {
                'memberExternalId' => 'MEM-001',
                'role' => 'Primary',
                'person' => new Map<String, Object> {
                    'firstName' => 'John',
                    'middleInitial' => 'A',
                    'lastName' => 'Doe',
                    'dob' => '1985-06-15',
                    'gender' => 'Male',
                    'email' => 'john.doe@email.com',
                    'phone' => '+1-555-123-4567',
                    'ssn' => '123456987',
                    'heightFeet' => 5,
                    'heightInches' => 6,
                    'weightLbs' => 140,
                    'pregnant' => false,
                    'smoker' => false,
                    'medicareId' => '',
                    'medicarePartA' => false,
                    'medicarePartB' => false,
                    'medicarePartC' => false,
                    'medicarePartD' => false,
                    'medicareEffectiveDate A' => '',
                    'medicareEffectiveDate B' => '',
                    'medicareEffectiveDate C' => '',
                    'medicareEffectiveDate D' => '',
                    'medicareNotEnrolled' => false,
                    'address' => new Map<String, Object> {
                        'street' => '123 Main St',
                        'city' => 'Austin',
                        'state' => 'TX',
                        'zip' => '78701'
                    }
                },
                'ancillaryCarePrograms' => new List<Object> {
                    new Map<String, Object> {
                        'id' => productTest[1].Id,
                        'productCode' => 'PROG_SMART_20000',
                        'type' => 'SMART',
                        'planName' => 'SMART Share 20000',
                        'basePrice' => 120,
                        'share' => true,
                        'role' => 'Primary',
                        'relatedTo' => ''
                    },
                    new Map<String, Object> {
                        'id' => productTest[4].Id,
                        'productCode' => 'PROG_AIDD_10000',
                        'type' => 'AIDD',
                        'planName' => 'AIDD 10000',
                        'basePrice' => 50,
                        'share' => false,
                        'role' => 'Primary',
                        'relatedTo' => ''
                    }
                },
                'medicalQuestions' => new Map<String, Object>{
                    'familyHistory' => new Map<String, Object> {
                        'answer' => 'no',
                        'date' => '',
                        'notes' => ''
                    },
                    'symptoms' => new Map<String, Object> {
                        'answer' => 'no',
                        'date' => '',
                        'notes' => ''
                    },
                    'consulted' => new Map<String, Object> {
                        'answer' => 'no',
                        'date' => '',
                        'notes' => ''
                    },
                    'cancer' => new List<Object> {
                        new Map<String, Object> {
                            'answer' => 'no',
                            'cancerType' => '',
                            'notes' => '',
                            'underTreatment' => false,
                            'diagnoseDate' => ''
                        }
                    },
                    'substance' => new Map<String, Object> {
                        'answer' => 'no',
                        'notes' => ''
                    },
                    'dui' => new Map<String, Object> {
                        'answer' => 'no',
                        'notes' => ''
                    },
                    'otherDx' => new Map<String, Object> {
                        'answer' => 'no',
                        'selectedDiagnoses' => new List<Object>(),
                        'otherText' => ''
                    },
                    'prescriptions' => new Map<String, Object> {
                        'answer' => 'no',
                        'medications' => new List<Object>()
                    },
                    'pcp' => new Map<String, Object> {
                        'hasPcp' => 'yes',
                        'name' => 'Dr. Sarah Johnson',
                        'city' => 'Austin, TX',
                        'phone' => '(512) 555-9999'
                    }
                },
                'currentCoverage' => new List<Object> {
                    new Map<String, Object> {
                        'carrier' => 'BlueCross',
                        'policyNumber' => 'EXT-12345',
                        'coverageType' => 'Medical',
                        'status' => 'Active',
                        'effectiveDate' => '2024-11-30',
                        'expirationDate' => '2025-12-31',
                        'coverageSource' => 'Employer',
                        'carrierPhone' => '+1-333-321-7654'
                    }
                }
            }
        );
        members.add(
            // Member #2
            new Map<String, Object> {
                'memberExternalId' => 'MEM-002',
                'role' => 'Spouse',
                'person' => new Map<String, Object> {
                    'firstName' => 'Jane',
                    'middleInitial' => 'A',
                    'lastName' => 'Doe',
                    'dob' => '1987-02-20',
                    'gender' => 'Female',
                    'email' => 'jane.doe@email.com',
                    'phone' => '+1-555-123-4567',
                    'ssn' => '987654321',
                    'heightFeet' => 5,
                    'heightInches' => 6,
                    'weightLbs' => 140,
                    'pregnant' => false,
                    'smoker' => false,
                    'sameAddressAsPrimary' => false,
                    'address' => new Map<String, Object> {
                        'street' => '2nd Avenue',
                        'city' => 'New York',
                        'state' => 'NY',
                        'zip' => '12345'
                    }
                },
                'ancillaryCarePrograms' => new List<Object> {
                    new Map<String, Object> {
                        'id' => productTest[1].Id,
                        'productCode' => 'PROG_SMART_20000',
                        'type' => 'SMART',
                        'planName' => 'SMART Share 20000',
                        'basePrice' => 120,
                        'share' => false,
                        'role' => 'Spouse',
                        'relatedTo' => ''
                    }
                },
                'medicalQuestions' => new Map<String, Object>{
                    'familyHistory' => new Map<String, Object> {
                        'answer' => 'yes',
                        'date' => '2023-06-15',
                        'notes' => 'Father had heart disease'
                    },
                    'symptoms' => new Map<String, Object> {
                        'answer' => 'no',
                        'date' => '',
                        'notes' => ''
                    },
                    'consulted' => new Map<String, Object> {
                        'answer' => 'yes',
                        'date' => '2024-01-10',
                        'notes' => 'Annual physical exam'
                    },
                    'cancer' => new List<Object> {
                        new Map<String, Object> {
                            'answer' => 'no',
                            'cancerType' => '',
                            'notes' => '',
                            'underTreatment' => false,
                            'diagnoseDate' => ''
                        }
                    },
                    'substance' => new Map<String, Object> {
                        'answer' => 'no',
                        'notes' => ''
                    },
                    'dui' => new Map<String, Object> {
                        'answer' => 'no',
                        'notes' => ''
                    },
                    'otherDx' => new Map<String, Object> {
                        'answer' => 'yes',
                        'selectedDiagnoses' => new List<Object>{
                            'Diabetes, Type 2 when taking 2 heart medications, or have kidney/liver disease',
                            'Chronic Obstructive Pulmonary Disease (COPD)'
                        },
                        'otherText' => ''
                    },
                    'prescriptions' => new Map<String, Object> {
                        'answer' => 'yes',
                        'medications' => new List<Object>{
                            new Map<String, Object> {
                                'name' => 'Metformin',
                                'dosage' => '500mg twice daily',
                                'prescribedFor' => 'Type 2 Diabetes'
                            },
                            new Map<String, Object> {
                                'name' => 'Lisinopril',
                                'dosage' => '10mg once daily',
                                'prescribedFor' => 'Blood Pressure'
                            }
                        }
                    },
                    'pcp' => new Map<String, Object> {
                        'hasPcp' => 'yes',
                        'name' => 'Dr. Sarah Johnson',
                        'city' => 'Austin, TX',
                        'phone' => '(512) 555-9999'
                    }
                },
                'currentCoverage' => new List<Object>()
            }
        );
        members.add(
            // Member #3
            new Map<String, Object> {
                'memberExternalId' => 'MEM-003',
                'role' => 'Child',
                'person' => new Map<String, Object> {
                    'firstName' => 'Mark',
                    'middleInitial' => 'A',
                    'lastName' => 'Doe',
                    'dob' => '2008-02-20',
                    'gender' => 'Male',
                    'email' => '',
                    'phone' => '',
                    'ssn' => '123456789',
                    'heightFeet' => 2,
                    'heightInches' => 3,
                    'weightLbs' => 120,
                    'pregnant' => false,
                    'smoker' => false,
                    'sameAddressAsPrimary' => true
                },
                'ancillaryCarePrograms' => new List<Object> {
                    new Map<String, Object> {
                        'id' => productTest[1].Id,
                        'productCode' => 'PROG_SMART_20000',
                        'type' => 'SMART',
                        'planName' => 'SMART Share 20000',
                        'basePrice' => 120,
                        'share' => true,
                        'role' => 'Dependent',
                        'relatedTo' => 'Primary'
                    }
                },
                'medicalQuestions' => new Map<String, Object>{
                    'familyHistory' => new Map<String, Object> {
                        'answer' => 'yes',
                        'date' => '2023-06-15',
                        'notes' => 'Father had heart disease'
                    },
                    'symptoms' => new Map<String, Object> {
                        'answer' => 'no',
                        'date' => '',
                        'notes' => ''
                    },
                    'consulted' => new Map<String, Object> {
                        'answer' => 'yes',
                        'date' => '2024-01-10',
                        'notes' => 'Annual physical exam'
                    },
                    'cancer' => new List<Object> {
                        new Map<String, Object> {
                            'answer' => 'no',
                            'cancerType' => '',
                            'notes' => '',
                            'underTreatment' => false,
                            'diagnoseDate' => ''
                        }
                    },
                    'substance' => new Map<String, Object> {
                        'answer' => 'no',
                        'notes' => ''
                    },
                    'dui' => new Map<String, Object> {
                        'answer' => 'no',
                        'notes' => ''
                    },
                    'otherDx' => new Map<String, Object> {
                        'answer' => 'yes',
                        'selectedDiagnoses' => new List<Object>{
                            'Diabetes, Type 2 when taking 2 heart medications, or have kidney/liver disease',
                            'Chronic Obstructive Pulmonary Disease (COPD)'
                        },
                        'otherText' => ''
                    },
                    'prescriptions' => new Map<String, Object> {
                        'answer' => 'yes',
                        'medications' => new List<Object>{
                            new Map<String, Object> {
                                'name' => 'Metformin',
                                'dosage' => '500mg twice daily',
                                'prescribedFor' => 'Type 2 Diabetes'
                            },
                            new Map<String, Object> {
                                'name' => 'Lisinopril',
                                'dosage' => '10mg once daily',
                                'prescribedFor' => 'Blood Pressure'
                            }
                        }
                    },
                    'pcp' => new Map<String, Object> {
                        'hasPcp' => 'yes',
                        'name' => 'Dr. Sarah Johnson',
                        'city' => 'Austin, TX',
                        'phone' => '(512) 555-9999'
                    }
                },
                'currentCoverage' => new List<Object>()
            }
        );

        // Return inputMap
        inputMap.put('generalInformation', generalInformation);
        inputMap.put('members', members);
        return inputMap;
    }


    @IsTest
    static void testProcess_Success() {
        // Prepare input JSON 
        String inputJson = JSON.serialize(generateInputMap());
        Integer mid = inputJson.length() / 2;
        List<String> splitJson = splitByIndex(inputJson, mid);

        ARC_IntegrationLog__c log = new ARC_IntegrationLog__c(
            Name = 'Test Log',
            RawJSON_Part1__c = splitJson[0],
            RawJSON_Part2__c = splitJson[1]
        );
        insert log;

        
        Test.startTest();
        ARC_ProcessIntegrationLog.Result result = ARC_ProcessIntegrationLog.process(log.Id);
        Test.stopTest();

        System.debug('ARC_ProcessIntegrationLog result.success: ' + result.success);
        System.debug('ARC_ProcessIntegrationLog result.httpStatus: ' + result.httpStatus);
        System.debug('ARC_ProcessIntegrationLog result.errorCode: ' + result.errorCode);
        System.debug('ARC_ProcessIntegrationLog result.errorMessage: ' + result.errorMessage);

        System.assertEquals(true, result.success, 'Should be success. ErrorCode=' + result.errorCode + ', ErrorMessage=' + result.errorMessage);
        System.assertEquals(200, result.httpStatus, 'Should be 200');
        System.assertEquals(null, result.errorCode, 'Should be null');
        System.assertEquals(null, result.errorMessage, 'Successful result should not have an error message');

        ARC_IntegrationLog__c updatedLog = [SELECT Success__c, HttpStatus__c, ErrorCode__c, ErrorMessage__c FROM ARC_IntegrationLog__c WHERE Id = :log.Id];
        System.assertEquals(true, updatedLog.Success__c, 'Log should be marked success');
        System.assertEquals(200, updatedLog.HttpStatus__c, 'Log should have 200');
        System.assertEquals(null, updatedLog.ErrorCode__c, 'Log error code should be null');
        System.assertEquals(null, updatedLog.ErrorMessage__c, 'Successful log should not have an error message');
    }

    @IsTest
    static void testProcess_InvalidJson() {
        ARC_IntegrationLog__c log = new ARC_IntegrationLog__c(
            Name = 'Test Log Invalid JSON',
            RawJSON_Part1__c = '{"enrollmentId":' // Invalid JSON
        );
        insert log;

        Test.startTest();
        ARC_ProcessIntegrationLog.Result result = ARC_ProcessIntegrationLog.process(log.Id);
        Test.stopTest();
        ARC_IntegrationLog__c updatedLog = [SELECT Success__c, HttpStatus__c, ErrorCode__c, ErrorMessage__c FROM ARC_IntegrationLog__c WHERE Id = :log.Id];

        System.assertEquals(false, updatedLog.Success__c, 'Should be failure');
    }

    @IsTest
    static void testProcess_NullRecordId() {
        Test.startTest();
        try {
            ARC_ProcessIntegrationLog.process(null);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e != null, 'Should have error');
        }
        Test.stopTest();
    }

    public static List<String> splitByIndex(String s, Integer index) {
        if (s == null) return null;
        if (index <= 0) return new List<String>{ '', s };
        if (index >= s.length()) return new List<String>{ s, '' };
        return new List<String>{ s.substring(0, index), s.substring(index) };
    }
}