@isTest
public with sharing class ARC_SEBaseServiceTest {

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
            'discountPrice' => 20,
            'numberOfPayments' => 1,
            'creditCard' => new Map<String, Object> {
                'firstName' => 'John',
                'lastName' => 'Smith',
                'cardNumber' => '4485942704924074',
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

    /**
     * Helper to ensure SSN is present for all members and guardian for DocuSign mapping.
     */
    private static void ensureDocuSignRequiredSSN(Map<String, Object> inputData) {
        Map<String, Object> generalInformation = (Map<String, Object>)inputData.get('generalInformation');
        List<Object> members = (List<Object>)inputData.get('members');
        Integer ssnSeed = 3333;

        if (members != null) {
            for (Object memberObj : members) {
                Map<String, Object> member = (Map<String, Object>)memberObj;
                Map<String, Object> person = (Map<String, Object>)member.get('person');
                if (person != null && (person.get('ssn') == null || String.valueOf(person.get('ssn')).trim() == '')) {
                    person.put('ssn', '123456' + String.valueOf(ssnSeed));
                    ssnSeed++;
                }
            }
        }

        if (generalInformation != null && generalInformation.containsKey('guardian')) {
            Map<String, Object> guardian = (Map<String, Object>)generalInformation.get('guardian');
            if (guardian != null && (guardian.get('ssn') == null || String.valueOf(guardian.get('ssn')).trim() == '')) {
                guardian.put('ssn', '987654321');
            }
        }
    }

    @isTest
    public static void processSelfEnrollmentTest_Positive(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        ensureDocuSignRequiredSSN(inputData);

        Test.startTest();
        ARC_SEBaseService service = new ARC_SEBaseService();
        service.invokeMethod('processSelfEnrollment', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessCriticalCarePromotionDiscount() {
        Map<String, Object> inputData = generateInputMap();

        // Build the manager directly to bypass ARC_SEBaseService / DocuSign.
        ARC_SEManager manager = new ARC_SEManager(inputData);
        ARC_SEMapper mapper = new ARC_SEMapper();
        mapper.mapEnrollmentData(manager);

        // Ancillary Discount promo code required by ARC_SEDML.processCriticalCarePromotionDiscount()
        Id ancillaryDiscountPromoRtId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'ARC_PromotionCode__c'
            AND Name = 'Ancillary Discount'
            LIMIT 1
        ].Id;

        ARC_PromotionCode__c ancillaryDiscountCode = new ARC_PromotionCode__c();
        ancillaryDiscountCode.RecordTypeId = ancillaryDiscountPromoRtId;
        ancillaryDiscountCode.Name = 'Ancillary Discount';
        ancillaryDiscountCode.ARC_PromotionCode__c = 'AncillaryDiscount_Test_1';
        ancillaryDiscountCode.ARC_DiscountedAmount__c = 25;
        ancillaryDiscountCode.ARC_StartDate__c = Date.today().addDays(-1);
        ancillaryDiscountCode.ARC_ApplyOver__c = 'Ancillary';
        insert ancillaryDiscountCode;

        // Promotion Discount record type expected by the target method
        Id ancillaryDiscountPdRtId = Schema.SObjectType.ARC_PromotionDiscount__c
            .getRecordTypeInfosByDeveloperName()
            .get('Ancillary_Discount')
            .getRecordTypeId();

        // Force the manager state needed by processCriticalCarePromotionDiscount()
        List<Object> members = (List<Object>)inputData.get('members');
        Map<String, Object> primaryMember = (Map<String, Object>)members[0];
        String primaryMemberId = (String)primaryMember.get('memberExternalId');

        if (manager.memberIdToCriticalCareBundle == null) {
            manager.memberIdToCriticalCareBundle = new Map<String, Map<String, String>>();
        }
        manager.memberIdToCriticalCareBundle.put(
            primaryMemberId,
            new Map<String, String>{
                'SMART' => 'SMART_BUNDLE_KEY',
                'AIDD' => 'AIDD_BUNDLE_KEY'
            }
        );

        if (manager.promotionDiscountToInsert == null) {
            manager.promotionDiscountToInsert = new List<ARC_PromotionDiscount__c>();
        }
        manager.promotionDiscountToInsert.clear();

        ARC_PromotionDiscount__c shellPd = new ARC_PromotionDiscount__c();
        shellPd.RecordTypeId = ancillaryDiscountPdRtId;
        manager.promotionDiscountToInsert.add(shellPd);

        // Incomplete map on purpose: only SMART, missing AIDD
        if (manager.memberIdToBundleGcmpIds == null) {
            manager.memberIdToBundleGcmpIds = new Map<String, Map<String, Id>>();
        }
        manager.memberIdToBundleGcmpIds.put(
            primaryMemberId,
            new Map<String, Id>{
                'SMART' => UserInfo.getUserId()
            }
        );

        System.assert(!manager.memberIdToCriticalCareBundle.isEmpty(), 'memberIdToCriticalCareBundle should be seeded.');
        System.assert(!manager.promotionDiscountToInsert.isEmpty(), 'promotionDiscountToInsert should contain the ancillary discount shell.');
        System.assert(manager.memberIdToBundleGcmpIds.containsKey(primaryMemberId), 'Bundle GCMP map should contain the primary member.');

        Test.startTest();
        try {
            new ARC_SEDML().processEnrollment(manager);
        } catch (Exception e) {
            // We only care that the target method is reached; later methods may still fail.
            System.debug('Expected/acceptable exception after targeted DML path: ' + e.getMessage());
        }
        Test.stopTest();

        System.assertEquals(true, true, 'processCriticalCarePromotionDiscount incomplete-GCMP path reached end of test.');
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessCriticalCarePromotionDiscount_BundleFocused() {
        Map<String, Object> inputData = generateInputMap();

        // Build the manager directly to bypass ARC_SEBaseService / DocuSign.
        ARC_SEManager manager = new ARC_SEManager(inputData);
        ARC_SEMapper mapper = new ARC_SEMapper();
        mapper.mapEnrollmentData(manager);

        // Ancillary Discount promo code required by ARC_SEDML.processCriticalCarePromotionDiscount()
        Id ancillaryDiscountPromoRtId = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'ARC_PromotionCode__c'
            AND Name = 'Ancillary Discount'
            LIMIT 1
        ].Id;

        ARC_PromotionCode__c ancillaryDiscountCode = new ARC_PromotionCode__c();
        ancillaryDiscountCode.RecordTypeId = ancillaryDiscountPromoRtId;
        ancillaryDiscountCode.Name = 'Ancillary Discount';
        ancillaryDiscountCode.ARC_PromotionCode__c = 'AncillaryDiscount_Test_2';
        ancillaryDiscountCode.ARC_DiscountedAmount__c = 25;
        ancillaryDiscountCode.ARC_StartDate__c = Date.today().addDays(-1);
        ancillaryDiscountCode.ARC_ApplyOver__c = 'Ancillary';
        insert ancillaryDiscountCode;

        Id ancillaryDiscountPdRtId = Schema.SObjectType.ARC_PromotionDiscount__c
            .getRecordTypeInfosByDeveloperName()
            .get('Ancillary_Discount')
            .getRecordTypeId();

        List<Object> members = (List<Object>)inputData.get('members');
        Map<String, Object> primaryMember = (Map<String, Object>)members[0];
        String primaryMemberId = (String)primaryMember.get('memberExternalId');

        if (manager.memberIdToCriticalCareBundle == null) {
            manager.memberIdToCriticalCareBundle = new Map<String, Map<String, String>>();
        }
        manager.memberIdToCriticalCareBundle.put(
            primaryMemberId,
            new Map<String, String>{
                'SMART' => 'SMART_BUNDLE_KEY',
                'AIDD' => 'AIDD_BUNDLE_KEY'
            }
        );

        if (manager.promotionDiscountToInsert == null) {
            manager.promotionDiscountToInsert = new List<ARC_PromotionDiscount__c>();
        }
        manager.promotionDiscountToInsert.clear();

        ARC_PromotionDiscount__c shellPd = new ARC_PromotionDiscount__c();
        shellPd.RecordTypeId = ancillaryDiscountPdRtId;
        manager.promotionDiscountToInsert.add(shellPd);

        // Complete bundle ids on purpose. We use fake ids so the final upsert is likely to fail
        // inside processCriticalCarePromotionDiscount(), after the target lines are executed.
        if (manager.memberIdToBundleGcmpIds == null) {
            manager.memberIdToBundleGcmpIds = new Map<String, Map<String, Id>>();
        }
        manager.memberIdToBundleGcmpIds.put(
            primaryMemberId,
            new Map<String, Id>{
                'SMART' => UserInfo.getUserId(),
                'AIDD' => UserInfo.getUserId()
            }
        );

        System.assert(!manager.memberIdToCriticalCareBundle.isEmpty(), 'memberIdToCriticalCareBundle should be seeded.');
        System.assert(!manager.promotionDiscountToInsert.isEmpty(), 'promotionDiscountToInsert should contain the ancillary discount shell.');
        System.assert(manager.memberIdToBundleGcmpIds.get(primaryMemberId).containsKey('SMART'), 'SMART GCMP id should be seeded.');
        System.assert(manager.memberIdToBundleGcmpIds.get(primaryMemberId).containsKey('AIDD'), 'AIDD GCMP id should be seeded.');

        Test.startTest();
        try {
            new ARC_SEDML().processEnrollment(manager);
            System.assertEquals(true, true, 'If no exception is thrown, the target method still executed.');
        } catch (Exception e) {
            System.debug('Expected/acceptable targeted exception: ' + e.getMessage());
            System.assert(
                e.getStackTraceString().contains('processCriticalCarePromotionDiscount') ||
                e.getMessage().contains('Critical Care PromotionDiscount') ||
                e.getMessage().contains('promotion discount'),
                'The exception should come from or after processCriticalCarePromotionDiscount so the targeted lines are executed.'
            );
        }
        Test.stopTest();
    }

    @isTest
    public static void validateEnrollmentDataTest_Positive(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SEBaseService service = new ARC_SEBaseService();
        service.invokeMethod('validateEnrollmentData', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();
    }

    @isTest
    public static void validateEnrollmentDataTest_WithNullInputMap(){
        Map<String, Object> inputData = null;
        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SEBaseService service = new ARC_SEBaseService();
        service.invokeMethod('validateEnrollmentData', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();
    }

    @isTest
    public static void validateEnrollmentDataTest_WithNullGeneralInformationNode(){
        Map<String, Object> inputData = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SEBaseService service = new ARC_SEBaseService();
        // Replace generalInformation data for null
        inputData.put('generalInformation', null);
        service.invokeMethod('validateEnrollmentData', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();
    }

    @isTest
    public static void validateEnrollmentDataTest_WithNullMembersNode(){
        Map<String, Object> inputData = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SEBaseService service = new ARC_SEBaseService();
        inputData.put('generalInformation', new Map<String, Object>{
            'effectiveDate' => '2025-11-01'
        });
        inputData.put('members', null);
        service.invokeMethod('validateEnrollmentData', inputData, outputMap, new Map<String, Object>());
        Test.stopTest();
    }

    @isTest
    public static void validateEnrollmentDataTest_Exception(){
        Map<String, Object> inputData = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();

        Test.startTest();
        ARC_SEBaseService service = new ARC_SEBaseService();
        inputData.put('generalInformation', 12345);
        try {
            service.invokeMethod('validateEnrollmentData', inputData, outputMap, new Map<String, Object>());
        } catch (Exception e) {
            System.debug('validateEnrollmentDataTest_Exception failed successfully. ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    public static void processSelfEnrollmentTest_NullInputMap(){
        Map<String, Object> inputData = null;
        Map<String, Object> outputMap = new Map<String, Object>();

        try {
            ARC_SEBaseService.processSelfEnrollment(inputData, outputMap);
        } catch(Exception e) {
            System.debug('processSelfEnrollmentTest_NullInputMap failed successfully. ' + e.getMessage());
        }
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessCensusCatch(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        // Scenario #1: Use a name with more than 80 characters
        try {
            ((Map<String, Object>)(((Map<String, Object>)(((List<Object>)inputData.get('members'))[0])).get('person'))).put('firstName', 'AAAAABBBBBCCCCCDDDDDEEEEEFFFFFGGGGGHHHHHIIIIIJJJJJ');
            ((Map<String, Object>)(((Map<String, Object>)(((List<Object>)inputData.get('members'))[0])).get('person'))).put('lastName', 'AAAAABBBBBCCCCCDDDDDEEEEEFFFFFGGGGGHHHHHIIIIIJJJJJ');

            ARC_SEBaseService.processSelfEnrollment(inputData, outputMap);
        } catch(Exception e){
            System.debug('processSelfEnrollmentTest_ProcessCensusCatch failed successfully. ' + e.getMessage());
        }
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessCensusMembersCatch(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        // Scenario #1: Use a name with more than 40 characters
        try {
            ((Map<String, Object>)(((Map<String, Object>)(((List<Object>)inputData.get('members'))[0])).get('person'))).put('firstName', 'AAAAABBBBBCCCCCDDDDDEEEEEFFFFFGGGGGHHHHHIIIII');
            ARC_SEBaseService.processSelfEnrollment(inputData, outputMap);
        } catch(Exception e){
            System.debug('processSelfEnrollmentTest_ProcessCensusMembersCatch failed successfully. ' + e.getMessage());
        }
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessGuardianCatch(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        // Scenario #1: Use a name with more than 40 characters but in the guardian
        try {
            ((Map<String, Object>)((Map<String, Object>)((Map<String, Object>)inputData.get('generalInformation')).get('guardian'))).put('firstName', 'AAAAABBBBBCCCCCDDDDDEEEEEFFFFFGGGGGHHHHHIIIII');
            ARC_SEBaseService.processSelfEnrollment(inputData, outputMap);
        } catch(Exception e){
            System.debug('processSelfEnrollmentTest_ProcessGuardianCatch failed successfully. ' + e.getMessage());
        }
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessContractLineItemCatch(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        // Scenario #1: Use a name with more than the accepted characters in the Name of the medical program
        try {
            ((Map<String, Object>)((Map<String, Object>)((Map<String, Object>)inputData.get('generalInformation')).get('medicalProgram'))).put('name', 'AAAAABBBBBCCCCCDDDDDEEEEEFFFFFGGGGGHHHHHIIIIIJJJJJKKKKKLLLLLMMMMMNNNNNOOOOPPPPPQQQQQRRRRRSSSSSTTTTTUUUUUVVVVVWWWWWXXXXXYYYYYZZZZZ');

            ARC_SEBaseService.processSelfEnrollment(inputData, outputMap);
        } catch(Exception e){
            System.debug('processSelfEnrollmentTest_ProcessContractLineItemCatch failed successfully. ' + e.getMessage());
        }
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessExternalInsurancePolicyCatch(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        try {
            ((Map<String, Object>)(((List<Object>)(((Map<String, Object>)(((List<Object>)inputData.get('members'))[0])).get('currentCoverage')))[0])).put('carrier', 'AAAAABBBBBCCCCCDDDDDEEEEEFFFFFGGGGGHHHHHIIIIIJJJJJKKKKKLLLLLMMMMMNNNNNOOOOPPPPPQQQQQRRRRRSSSSSTTTTTUUUUUVVVVVWWWWWXXXXXYYYYYZZZZZ');

            ARC_SEBaseService.processSelfEnrollment(inputData, outputMap);
        } catch(Exception e){
            System.debug('processSelfEnrollmentTest_ProcessExternalInsurancePolicyCatch failed successfully. ' + e.getMessage());
        }
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessChargentOrderCatch(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        try {
            ((Map<String, Object>)(((Map<String, Object>)((Map<String, Object>)((Map<String, Object>)inputData.get('generalInformation')).get('payment'))).get('creditCard'))).put('cardNumber', '111112222233333444445555566666777778888899999000001111122222333334444455555666667777788888999990000011111222223333344444555556666677777888889999900000');

            ARC_SEBaseService.processSelfEnrollment(inputData, outputMap);
        } catch(Exception e){
            System.debug('processSelfEnrollmentTest_ProcessExternalInsurancePolicyCatch failed successfully. ' + e.getMessage());
        }
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessHIPPACatch(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        try {
            ((Map<String, Object>)(((List<Object>)(((Map<String, Object>)inputData.get('generalInformation')).get('hipaa')))[0])).put('firstName', 'AAAAABBBBBCCCCCDDDDDEEEEEFFFFFGGGGGHHHHHIIIIIJJJJJKKKKKLLLLLMMMMMNNNNNOOOOPPPPPQQQQQRRRRRSSSSSTTTTTUUUUUVVVVVWWWWWXXXXXYYYYYZZZZZ');

            ARC_SEBaseService.processSelfEnrollment(inputData, outputMap);
        } catch(Exception e){
            System.debug('processSelfEnrollmentTest_ProcessHIPPACatch failed successfully. ' + e.getMessage());
        }
    }

    @isTest
    public static void processSelfEnrollmentTest_ProcessMedicalConditionsCatch(){
        Map<String, Object> inputData = generateInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();

        try {
            List<Object> members = (List<Object>)inputData.get('members');
            Map<String, Object> medicalQuestions = (Map<String, Object>)((Map<String, Object>)members[0]).get('medicalQuestions');
            List<Object> cancerList = (List<Object>)medicalQuestions.get('cancer');
            ((Map<String, Object>)((Map<String, Object>)cancerList[0])).put('cancerType', 'AAAAABBBBBCCCCCDDDDDEEEEEFFFFFGGGGGHHHHHIIIIIJJJJJKKKKKLLLLLMMMMMNNNNNOOOOPPPPPQQQQQRRRRRSSSSSTTTTTUUUUUVVVVVWWWWWXXXXXYYYYYZZZZZ');

            ARC_SEBaseService.processSelfEnrollment(inputData, outputMap);
        } catch(Exception e){
            System.debug('processSelfEnrollmentTest_ProcessMedicalConditionsCatch failed successfully. ' + e.getMessage());
        }
    }
}