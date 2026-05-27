@isTest
public with sharing class ARC_IndividualEnrollmentHelperTest {
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

    @isTest
    public static void validateEnrollmentDataTest_PositiveScenario(){
        Map<String, Object> inputMap = generateInputMap();
        Map<String, Object> expectedOutputMap = new Map<String, Object>{
            'isValid' => true,
            'errors' => new List<Object>(),
            'errorCount' => 0,
            'PrimaryName' => ''
        };

        Test.startTest();
        Map<String, Object> results = ARC_IndividualEnrollmentHelper.validateEnrollmentData(inputMap);
        // Positive scenario
        ARC_IndividualEnrollmentHelper.upsertLeadSourceReferral((Map<String, Object>)inputMap.get('generalInformation'), new Map<String, Object>(), new Map<String, Object>());
        // Catch scenario
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('leadId', '');
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('email', 'emailtest@emailtest.com');
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('phone', '19191919191');
        ARC_IndividualEnrollmentHelper.upsertLeadSourceReferral((Map<String, Object>)inputMap.get('generalInformation'), new Map<String, Object>(), new Map<String, Object>());
        // Negative scenario
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('birthdate', '2000-01-01');
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('city', 'Los Angeles');
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('firstName', 'FN Test');
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('gender', 'Male');
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('lastName', 'LN Test');
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('state', 'CA');
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('street', '100 Main Street');
        ((Map<String, Object>)((Map<String, Object>) inputMap.get('generalInformation'))).put('zipCode', '12345');
        ARC_IndividualEnrollmentHelper.upsertLeadSourceReferral((Map<String, Object>)inputMap.get('generalInformation'), new Map<String, Object>(), new Map<String, Object>());
        Test.stopTest();

        Assert.areEqual(expectedOutputMap, results);
    }

    @isTest
    public static void validateEnrollmentData_NegativeScenarios(){
        Map<String, Object> outputs = new Map<String, Object>();

        Test.startTest();
        // 1. null
        outputs.put('scenario1', ARC_IndividualEnrollmentHelper.validateEnrollmentData(null));
        // 2. empty map
        outputs.put('scenario2', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>()));
        // 3. generalInformation not a map
        outputs.put('scenario3', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'generalInformation' => 'not a map'}));
        // 4. effectiveDate and medicalProgram nodes missing
        outputs.put('scenario4', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'generalInformation' => new Map<String, Object>()}));
        // 5. medicalProgram not an object
        outputs.put('scenario5', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'generalInformation' => new Map<String, Object>{'medicalProgram' => 'not an object'}}));
        // 6. productId not in medicalProgram
        outputs.put('scenario6', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'generalInformation' => new Map<String, Object>{'medicalProgram' => new Map<String, Object>()}}));
        // 7. payment node is not an object
        outputs.put('scenario7', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'generalInformation' => new Map<String, Object>{'payment' => 'not an object'}}));
        // 8. paymentMethod node missing
        outputs.put('scenario8', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'generalInformation' => new Map<String, Object>{'payment' => new Map<String, Object>()}}));
        // 9. creditCard node is empty
        outputs.put('scenario9', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'generalInformation' => new Map<String, Object>{'payment' => new Map<String, Object>{'paymentMethod' => 'credit_card'}}}));
        // 10. bankAccount node is empty
        outputs.put('scenario10', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'generalInformation' => new Map<String, Object>{'payment' => new Map<String, Object>{'paymentMethod' => 'bank_account'}}}));
        // 11. membersNode is not an array
        outputs.put('scenario11', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => 'not an array'}));
        // 12. membersNode is empty
        outputs.put('scenario12', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>()}));
        // 13. membersNode content is not a map
        outputs.put('scenario13', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{'not a map'}}));
        // 14. membersNode content does not have a role
        outputs.put('scenario14', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>()}}));
        // 15. membersNode content does have a primary role
        outputs.put('scenario15', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'role' => 'Primary'}}}));
        // 16. person node is not an object
        outputs.put('scenario16', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'person' => 'not an object'}}}));
        // 17. person node is empty
        outputs.put('scenario17', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'person' => new Map<String, Object>()}}}));
        // 18. address node is empty
        outputs.put('scenario18', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'person' => new Map<String, Object>{'address' => 'null'}}}}));
        // 19. address node is not empty
        outputs.put('scenario19', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'person' => new Map<String, Object>{'address' => 'not empty'}}}}));
        // 20. address node is not an object
        outputs.put('scenario20', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'person' => new Map<String, Object>{'address' => 1234}}}}));
        // 21. address node is an empty map
        outputs.put('scenario21', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'person' => new Map<String, Object>{'address' => new Map<String, Object>()}}}}));
        // 22. sameAddressAsPrimary is true
        outputs.put('scenario22', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'person' => new Map<String, Object>{'sameAddressAsPrimary' => true}}}}));
        // 23. sameAddressAsPrimary is true as string
        outputs.put('scenario23', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'person' => new Map<String, Object>{'sameAddressAsPrimary' => 'true'}}}}));
        // 24. sameAddressAsPrimary is a number
        outputs.put('scenario24', ARC_IndividualEnrollmentHelper.validateEnrollmentData(new Map<String, Object>{'members' => new List<Object>{new Map<String, Object>{'person' => new Map<String, Object>{'sameAddressAsPrimary' => 1}}}}));
        Test.stopTest();
    }

    @isTest
    public static void getMembersDataFromPrimaryTest_PositiveScenario(){
        Map<String, Object> inputMap = generateInputMap();
        vlocity_ins__GroupCensusMember__c gcm = ARC_TestUtility.createTestCensusMember(1)[0];
        Map<String, Object> output = new Map<String, Object>();

        Test.startTest();
        output = ARC_IndividualEnrollmentHelper.getMembersDataFromPrimary(String.valueOf(gcm.Id));
        Test.stopTest();
    }

    @isTest
    public static void createIntegrationLogAndupdateIntegrationLogTests_PositiveScenarios(){
        String operation = 'GET';
        Map<String,Object> inputData = generateInputMap();
        String output = '';

        Test.startTest();
        output = ARC_IndividualEnrollmentHelper.createIntegrationLog(operation, inputData);

        Id groupAccountId = ARC_TestUtility.createTestAccount(1, 'StandardAccount')[0].Id;
        String groupAccountName = '';
        ARC_IndividualEnrollmentHelper.updateIntegrationLog(output, false, 404, 'errorCode Test', 'errorMessage Test', Datetime.now(), 10000, groupAccountId, groupAccountName);
        Test.stopTest();
    }

    @isTest
    public static void logErrorTest_PositiveScenario() {
        String errorContext = 'errorContext test';
        String requestData = 'Request Test';

        Test.startTest();
        try {
            Integer x = 1 / 0;
        } catch (Exception ex) {
            ARC_IndividualEnrollmentHelper.logError(errorContext, ex, requestData);
        }
        Test.stopTest();
    }

    @isTest
    public static void validateLeadDataTest_AllScenarios() {
        Map<String, Object> leadData = new Map<String, Object>();

        Test.startTest();
        // 1. null scenario
        ARC_IndividualEnrollmentHelper.validateLeadData(null);
        // 2. emtpy scenario
        ARC_IndividualEnrollmentHelper.validateLeadData(leadData);
        // 3. Wrong email, phone, birthdate, gender and address fields
        leadData.put('email', 'not an email');
        leadData.put('phone', 'not a phone');
        leadData.put('birthdate', 'not a date');
        leadData.put('gender', 'not a gender');
        leadData.put('street', '');
        leadData.put('city', '');
        leadData.put('state', 'Not a valid state.');
        leadData.put('zipCode', 'ABCD');
        ARC_IndividualEnrollmentHelper.validateLeadData(leadData);
        Test.stopTest();
    }

    @isTest
    public static void validatePromotionCodeDataTest_AllScenarios() {
        Map<String, Object> promotionCodeData = new Map<String, Object>();

        Test.startTest();
        // 1. null scenario
        ARC_IndividualEnrollmentHelper.validatePromotionCodeData(null);
        // 2. empty scenario
        ARC_IndividualEnrollmentHelper.validatePromotionCodeData(promotionCodeData);
        // 3. promotionCode node is empty
        promotionCodeData.put('promotionCode', 'AB');
        ARC_IndividualEnrollmentHelper.validatePromotionCodeData(promotionCodeData);
        Test.stopTest();
    }

    @isTest
    public static void validatePromotionCodeTest_AllScenarios() {
        ARC_PromotionCode__c promotionTest = new ARC_PromotionCode__c();
        promotionTest.Name = 'App Fee 50';
        promotionTest.ARC_PromotionCode__c = 'AppFee50';
        promotionTest.ARC_DiscountedAmount__c = 50;
        promotionTest.ARC_StartDate__c = Date.valueOf('2025-10-01');
        promotionTest.ARC_ApplyOver__c = 'App Fee';
        insert promotionTest;

        // 1. empty scenario
        ARC_IndividualEnrollmentHelper.validatePromotionCode('');
        // 2. valid scenario
        ARC_IndividualEnrollmentHelper.validatePromotionCode('AppFee50');
        // 3. invalid scenario
        ARC_PromotionCode__c invalidPromotionTest = new ARC_PromotionCode__c();
        invalidPromotionTest.Name = 'App Fee 1';
        invalidPromotionTest.ARC_PromotionCode__c = 'AppFee1';
        invalidPromotionTest.ARC_DiscountedAmount__c = 50;
        invalidPromotionTest.ARC_StartDate__c = Date.valueOf('2050-10-01');
        invalidPromotionTest.ARC_EndDate__c = Date.valueOf('1999-10-01');
        invalidPromotionTest.ARC_ApplyOver__c = 'App Fee';
        invalidPromotionTest.ARC_NumberOfTimesCanBeUsed__c = 1;
        insert invalidPromotionTest;

        ARC_IndividualEnrollmentHelper.validatePromotionCode('AppFee1');
    }

}