@IsTest
public class ARC_SGSEMapperTest {

    /**
     * Test: Basic mapping with minimal data
     */
    @isTest
    static void test_mapEnrollmentData_minimalPath() {
        // Setup
        Account groupAcc = new Account(
            Name = 'Test Group',
            ARC_NewEmployeeWaitingPeriod__c = 'None – effective date of hire'
        );
        insert groupAcc;

        Account primaryAcc = new Account(
            LastName = 'Primary',
            ARC_HireDate__c = Date.today().addMonths(-1)
        );
        insert primaryAcc;

        Product2 parentProduct = new Product2(Name = 'Parent Product', IsActive = true);
        insert parentProduct;

        // Add child product with Coverage Spec record type to prevent NullPointerException in mapPolicyCoverages
        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;
        
        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        generalInfo.put('medicalProgram', new Map<String, Object>{
            'PlanA' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 100.0,
                'employeeSplit' => 50.0,
                'employerSplit' => 50.0,
                'basePrice' => 200.0
            }
        });

        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'dob' => '1990-01-01',
            'gender' => 'Male',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '123 Main',
                'city' => 'Toronto',
                'state' => 'ON',
                'zip' => 'M1M1M1'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => person
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
    }

    /**
     * Test: Multiple members with spouse and dependents
     */
    @isTest
    static void test_mapEnrollmentData_withMultipleMembers() {
        // Setup
        Account groupAcc = new Account(
            Name = 'Test Group Multi',
            ARC_NewEmployeeWaitingPeriod__c = 'First of the month following hire date'
        );
        insert groupAcc;

        Account primaryAcc = new Account(
            LastName = 'Primary Multi',
            ARC_HireDate__c = Date.today().addMonths(-2)
        );
        insert primaryAcc;

        Product2 parentProduct = new Product2(Name = 'Parent Product Multi', IsActive = true);
        insert parentProduct;

        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct1 = new Product2(
            Name = 'Child Product 1',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct1;

        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct1.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        generalInfo.put('medicalProgram', new Map<String, Object>{
            'WeShare Group Enhanced' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 150.0,
                'employeeSplit' => 75.0,
                'employerSplit' => 75.0,
                'basePrice' => 300.0
            }
        });

        Map<String, Object> primaryPerson = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'dob' => '1980-01-01',
            'gender' => 'Male',
            'isLegacy' => false,
            'email' => 'john@test.com',
            'phone' => '1234567890',
            'ssn' => '123456789',
            'heightFeet' => '6',
            'heightInches' => '2',
            'weightLbs' => '180',
            'smoker' => false,
            'pregnant' => false,
            'address' => new Map<String, Object>{
                'street' => '123 Main St',
                'city' => 'Toronto',
                'state' => 'ON',
                'zip' => 'M1M1M1'
            }
        };

        Map<String, Object> spousePerson = new Map<String, Object>{
            'firstName' => 'Jane',
            'lastName' => 'Doe',
            'middleInitial' => 'M',
            'dob' => '1982-02-02',
            'gender' => 'Female',
            'isLegacy' => false,
            'sameAddressAsPrimary' => true,
            'address' => new Map<String, Object>{
                'sameAddressAsPrimary' => true
            }
        };

        Map<String, Object> childPerson = new Map<String, Object>{
            'firstName' => 'Jimmy',
            'lastName' => 'Doe',
            'dob' => '2010-03-03',
            'gender' => 'Male',
            'isLegacy' => false,
            'sameAddressAsPrimary' => true,
            'address' => new Map<String, Object>{
                'sameAddressAsPrimary' => true
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => primaryPerson
            },
            new Map<String,Object>{
                'memberExternalId' => 'M2',
                'role' => 'Spouse',
                'person' => spousePerson
            },
            new Map<String,Object>{
                'memberExternalId' => 'M3',
                'role' => 'Child',
                'person' => childPerson
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
        System.assertEquals(3, mapper.manager.memberIdToCensusMemberMap.size(), 'Should have 3 census members');
    }

    /**
     * Test: Legacy member with Senior coverage
     */
    @isTest
    static void test_mapEnrollmentData_withLegacyMember() {
        // Setup
        Account groupAcc = new Account(
            Name = 'Test Group Legacy',
            ARC_NewEmployeeWaitingPeriod__c = 'First of the month following one month from hire date'
        );
        insert groupAcc;

        Account primaryAcc = new Account(
            LastName = 'Primary Legacy',
            ARC_HireDate__c = Date.today().addMonths(-3)
        );
        insert primaryAcc;

        Product2 seniorProduct = new Product2(Name = 'WeShare Group Senior Product', IsActive = true);
        insert seniorProduct;

        // Add child product with Coverage Spec record type to prevent NullPointerException in mapPolicyCoverages
        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage Legacy',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;
        
        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = seniorProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        generalInfo.put('medicalProgram', new Map<String, Object>{
            'WeShare Group Senior' => new Map<String, Object>{
                'productId' => seniorProduct.Id,
                'individualPrice' => 200.0,
                'employeeSplit' => 100.0,
                'employerSplit' => 100.0,
                'basePrice' => 400.0
            }
        });

        Map<String, Object> legacyPerson = new Map<String, Object>{
            'firstName' => 'Senior',
            'lastName' => 'Member',
            'dob' => '1950-01-01',
            'gender' => 'Male',
            'isLegacy' => true,
            'address' => new Map<String, Object>{
                'street' => '456 Oak St',
                'city' => 'Vancouver',
                'state' => 'BC',
                'zip' => 'V1V1V1'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => legacyPerson
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
    }

    /**
     * Test: Guardian mapping
     */
    @isTest
    static void test_mapEnrollmentData_withGuardian() {
        // Setup
        Account groupAcc = new Account(
            Name = 'Test Group Guardian',
            ARC_NewEmployeeWaitingPeriod__c = 'First of the month following two months from hire date'
        );
        insert groupAcc;

        Account primaryAcc = new Account(
            LastName = 'Primary Guardian',
            ARC_HireDate__c = Date.today().addMonths(-4)
        );
        insert primaryAcc;

        Product2 parentProduct = new Product2(Name = 'Parent Product Guardian', IsActive = true);
        insert parentProduct;

        // Add child product with Coverage Spec record type to prevent NullPointerException in mapPolicyCoverages
        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage Guardian',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;
        
        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        
        // Add guardian information
        generalInfo.put('guardian', new Map<String, Object>{
            'firstName' => 'Guardian',
            'lastName' => 'Smith',
            'middleInitial' => 'R',
            'relationship' => 'Parent',
            'phone' => '9876543210',
            'email' => 'guardian@test.com',
            'gender' => 'Female',
            'dob' => '1960-05-05',
            'ssn' => '987654321',
            'address' => new Map<String, Object>{
                'street' => '789 Pine St',
                'city' => 'Calgary',
                'state' => 'AB',
                'zip' => 'T1T1T1'
            }
        });

        generalInfo.put('medicalProgram', new Map<String, Object>{
            'PlanB' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 120.0,
                'employeeSplit' => 60.0,
                'employerSplit' => 60.0,
                'basePrice' => 240.0
            }
        });

        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'Minor',
            'lastName' => 'Child',
            'dob' => '2015-06-06',
            'gender' => 'Male',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '789 Pine St',
                'city' => 'Calgary',
                'state' => 'AB',
                'zip' => 'T1T1T1'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => person
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
        System.assertNotEquals(null, mapper.manager.guardianToInsert, 'Guardian should be mapped');
    }

    /**
     * Test: HIPAA authorization mapping - Census Member
     */
    @isTest
    static void test_mapEnrollmentData_withHIPAACensusMember() {
        // Setup
        Account groupAcc = new Account(Name = 'Test Group HIPAA');
        insert groupAcc;

        Account primaryAcc = new Account(LastName = 'Primary HIPAA');
        insert primaryAcc;

        Product2 parentProduct = new Product2(Name = 'Parent Product HIPAA', IsActive = true);
        insert parentProduct;

        // Add child product with Coverage Spec record type to prevent NullPointerException in mapPolicyCoverages
        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage HIPAA',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;
        
        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        generalInfo.put('medicalProgram', new Map<String, Object>{
            'PlanC' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 130.0,
                'employeeSplit' => 65.0,
                'employerSplit' => 65.0,
                'basePrice' => 260.0
            }
        });

        // Add HIPAA authorizations
        generalInfo.put('hipaa', new List<Object>{
            new Map<String, Object>{
                'memberExternalId' => 'M1',
                'firstName' => 'John',
                'lastName' => 'Doe',
                'dob' => '1990-01-01',
                'relationship' => 'Self',
                'CHK_Authorized' => true
            }
        });

        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'dob' => '1990-01-01',
            'gender' => 'Male',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '111 Elm St',
                'city' => 'Ottawa',
                'state' => 'ON',
                'zip' => 'K1K1K1'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => person
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
        System.assertEquals(1, mapper.manager.hipaaCensusMember.size(), 'Should have 1 census member HIPAA');
    }

    /**
     * Test: HIPAA authorization mapping - Third Party
     */
    @isTest
    static void test_mapEnrollmentData_withHIPAAThirdParty() {
        // Setup
        Account groupAcc = new Account(Name = 'Test Group HIPAA TP');
        insert groupAcc;

        Account primaryAcc = new Account(LastName = 'Primary HIPAA TP');
        insert primaryAcc;

        Product2 parentProduct = new Product2(Name = 'Parent Product HIPAA TP', IsActive = true);
        insert parentProduct;

        // Add child product with Coverage Spec record type to prevent NullPointerException in mapPolicyCoverages
        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage HIPAA TP',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;
        
        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        generalInfo.put('medicalProgram', new Map<String, Object>{
            'PlanD' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 140.0,
                'employeeSplit' => 70.0,
                'employerSplit' => 70.0,
                'basePrice' => 280.0
            }
        });

        // Add Third Party HIPAA
        generalInfo.put('hipaa', new List<Object>{
            new Map<String, Object>{
                'firstName' => 'Third',
                'lastName' => 'Party',
                'DAT_DOB' => '1985-07-07',
                'email' => 'thirdparty@test.com',
                'phone' => '5555555555',
                'relationship' => 'Third Party',
                'CHK_Authorized' => true,
                'address' => new Map<String, Object>{
                    'street' => '222 Maple St',
                    'city' => 'Montreal',
                    'state' => 'QC',
                    'zip' => 'H1H1H1'
                }
            }
        });

        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'dob' => '1990-01-01',
            'gender' => 'Male',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '111 Elm St',
                'city' => 'Ottawa',
                'state' => 'ON',
                'zip' => 'K1K1K1'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => person
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
        System.assertEquals(1, mapper.manager.hipaaThirdParty.size(), 'Should have 1 third party HIPAA');
        System.assertEquals(1, mapper.manager.hipaaExternalContact.size(), 'Should have 1 external contact');
    }

    /**
     * Test: HIPAA authorization mapping - Legal Guardian
     */
    @isTest
    static void test_mapEnrollmentData_withHIPAALegalGuardian() {
        // Setup
        Account groupAcc = new Account(Name = 'Test Group HIPAA LG');
        insert groupAcc;

        Account primaryAcc = new Account(LastName = 'Primary HIPAA LG');
        insert primaryAcc;

        Product2 parentProduct = new Product2(Name = 'Parent Product HIPAA LG', IsActive = true);
        insert parentProduct;

        // Add child product with Coverage Spec record type to prevent NullPointerException in mapPolicyCoverages
        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage HIPAA LG',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;
        
        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        
        // Add guardian
        generalInfo.put('guardian', new Map<String, Object>{
            'firstName' => 'Legal',
            'lastName' => 'Guardian',
            'dob' => '1970-08-08',
            'relationship' => 'Parent',
            'address' => new Map<String, Object>{
                'street' => '333 Cedar St',
                'city' => 'Winnipeg',
                'state' => 'MB',
                'zip' => 'R1R1R1'
            }
        });

        generalInfo.put('medicalProgram', new Map<String, Object>{
            'PlanE' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 110.0,
                'employeeSplit' => 55.0,
                'employerSplit' => 55.0,
                'basePrice' => 220.0
            }
        });

        // Add Legal Guardian HIPAA - matching guardian details
        generalInfo.put('hipaa', new List<Object>{
            new Map<String, Object>{
                'firstName' => 'Legal',
                'lastName' => 'Guardian',
                'dob' => '1970-08-08',
                'relationship' => 'Parent',
                'CHK_Authorized' => true
            }
        });

        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'Minor',
            'lastName' => 'Child',
            'dob' => '2016-09-09',
            'gender' => 'Female',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '333 Cedar St',
                'city' => 'Winnipeg',
                'state' => 'MB',
                'zip' => 'R1R1R1'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => person
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
        System.assertEquals(1, mapper.manager.hipaaLegalGuardian.size(), 'Should have 1 legal guardian HIPAA');
    }

    /**
     * Test: External insurance policy mapping
     */
    @isTest
    static void test_mapEnrollmentData_withExternalCoverage() {
        // Setup
        Account groupAcc = new Account(Name = 'Test Group Ext');
        insert groupAcc;

        Account primaryAcc = new Account(LastName = 'Primary Ext');
        insert primaryAcc;

        Product2 parentProduct = new Product2(Name = 'Parent Product Ext', IsActive = true);
        insert parentProduct;

        // Add child product with Coverage Spec record type to prevent NullPointerException in mapPolicyCoverages
        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage Ext',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;
        
        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        generalInfo.put('medicalProgram', new Map<String, Object>{
            'PlanF' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 160.0,
                'employeeSplit' => 80.0,
                'employerSplit' => 80.0,
                'basePrice' => 320.0
            }
        });

        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            'dob' => '1990-01-01',
            'gender' => 'Male',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '444 Willow St',
                'city' => 'Edmonton',
                'state' => 'AB',
                'zip' => 'T2T2T2'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => person,
                'currentCoverage' => new List<Object>{
                    new Map<String, Object>{
                        'carrier' => 'Blue Cross',
                        'policyNumber' => 'BC123456',
                        'carrierPhone' => '1-800-123-4567',
                        'effectiveDate' => '2023-01-01',
                        'expirationDate' => '2024-12-31',
                        'coverageSource' => 'Employer'
                    }
                }
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
        System.assertEquals(1, mapper.manager.externalPoliciesToInsert.size(), 'Should have 1 external policy');
        System.assertEquals(1, mapper.manager.policyKeyToMemberIds.size(), 'Should have 1 policy key mapping');
    }

    /**
     * Test: Check policy deletion for existing enrollment
     */
    @isTest
    static void test_mapEnrollmentData_withExistingPolicy() {
        // Setup existing policy structure
        Account groupAcc = new Account(Name = 'Test Group Existing');
        insert groupAcc;

        Account primaryAcc = new Account(LastName = 'Primary Existing', ARC_HireDate__c = Date.today());
        insert primaryAcc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            Name = 'Test Census',
            vlocity_ins__GroupId__c = groupAcc.Id
        );
        insert census;

        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'Existing',
            vlocity_ins__LastName__c = 'Member',
            vlocity_ins__CensusId__c = census.Id
        );
        insert censusMember;

        Product2 parentProduct = new Product2(Name = 'Parent Product Existing', IsActive = true);
        insert parentProduct;

        // Add child product with Coverage Spec record type to prevent NullPointerException in mapPolicyCoverages
        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage Existing',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;
        
        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('primaryCensusMemberId', censusMember.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        generalInfo.put('medicalProgram', new Map<String, Object>{
            'PlanG' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 170.0,
                'employeeSplit' => 85.0,
                'employerSplit' => 85.0,
                'basePrice' => 340.0
            }
        });

        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'Existing',
            'lastName' => 'Member',
            'dob' => '1985-10-10',
            'gender' => 'Male',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '555 Birch St',
                'city' => 'Halifax',
                'state' => 'NS',
                'zip' => 'B1B1B1'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => person
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        manager.primaryCensusMemberId = censusMember.Id;
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
    }

    /**
     * Test: Effective date calculation with null contract date
     */
    @isTest
    static void test_mapEnrollmentData_nullEffectiveDate() {
        Account groupAcc = new Account(
            Name = 'Test Group Null Date',
            ARC_NewEmployeeWaitingPeriod__c = 'None – effective date of hire'
        );
        insert groupAcc;

        Account primaryAcc = new Account(
            LastName = 'Primary Null Date',
            ARC_HireDate__c = Date.today()
        );
        insert primaryAcc;

        Product2 parentProduct = new Product2(Name = 'Parent Product Null', IsActive = true);
        insert parentProduct;

        // Add child product with Coverage Spec record type to prevent NullPointerException in mapPolicyCoverages
        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage Null',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;
        
        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        // No effectiveDate provided
        generalInfo.put('medicalProgram', new Map<String, Object>{
            'PlanH' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 90.0,
                'employeeSplit' => 45.0,
                'employerSplit' => 45.0,
                'basePrice' => 180.0
            }
        });

        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'Test',
            'lastName' => 'NullDate',
            'dob' => '1992-11-11',
            'gender' => 'Female',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '666 Spruce St',
                'city' => 'Quebec City',
                'state' => 'QC',
                'zip' => 'G1G1G1'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String,Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => person
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager, 'Manager should be set');
        System.assertNotEquals(null, mapper.manager.effectiveDate, 'Effective date should be calculated');
    }

    /**
     * Test: Error handling - exception during mapping
     */
    @isTest
    static void test_mapEnrollmentData_exceptionHandling() {
        // Setup with invalid/incomplete data to trigger exception
        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        // Missing required fields
        generalInfo.put('groupAccountId', null);
        enrollmentInfo.put('generalInformation', generalInfo);

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
            ARC_SGSEMapper mapper = new ARC_SGSEMapper();
            mapper.mapEnrollmentData(manager);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'Exception should be thrown for invalid data');
    }

    //* Test: Existing policy is detected from the primary census member and reused as renewal
    @isTest
    static void testMapEnrollmentData_existingPolicy_setsRenewalAndReusesPolicy() {
        Account groupAcc = new Account(
            Name = 'Test Group Existing Policy Renewal',
            ARC_NewEmployeeWaitingPeriod__c = 'None – effective date of hire'
        );
        insert groupAcc;

        Account primaryAcc = new Account(
            LastName = 'Primary Renewal',
            ARC_HireDate__c = Date.today().addMonths(-6)
        );
        insert primaryAcc;

        primaryAcc = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE Id = :primaryAcc.Id
        ];

        Contract contractRecord = new Contract(
            AccountId = groupAcc.Id,
            Status = 'Draft',
            StartDate = Date.today().addMonths(-1),
            ContractTerm = 12
        );
        insert contractRecord;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            Name = 'Test Census Existing Policy Renewal',
            vlocity_ins__GroupId__c = groupAcc.Id
        );
        insert census;

        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__FirstName__c = 'Primary',
            vlocity_ins__LastName__c = 'Renewal',
            vlocity_ins__CensusId__c = census.Id,
            vlocity_ins__ContactId__c = primaryAcc.PersonContactId
        );
        insert censusMember;

        Product2 parentProduct = new Product2(Name = 'Parent Product Renewal', IsActive = true);
        insert parentProduct;

        Id coverageSpecRT = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get('CoverageSpec').getRecordTypeId();
        Product2 childProduct = new Product2(
            Name = 'Child Coverage Renewal',
            IsActive = true,
            RecordTypeId = coverageSpecRT
        );
        insert childProduct;

        vlocity_ins__ProductChildItem__c pci = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ParentProductId__c = parentProduct.Id,
            vlocity_ins__ChildProductId__c = childProduct.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert pci;

        Map<String, Object> priorGeneralInfo = new Map<String, Object>();
        priorGeneralInfo.put('groupAccountId', groupAcc.Id);
        priorGeneralInfo.put('accountId', primaryAcc.Id);
        priorGeneralInfo.put('contractId', contractRecord.Id);
        priorGeneralInfo.put('primaryCensusMemberId', censusMember.Id);
        priorGeneralInfo.put('effectiveDate', String.valueOf(Date.today().addMonths(-1)));
        priorGeneralInfo.put('medicalProgram', new Map<String, Object>{
            'Renewal Plan' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 100.0,
                'employeeSplit' => 50.0,
                'employerSplit' => 50.0,
                'basePrice' => 200.0
            }
        });

        Map<String, Object> priorPerson = new Map<String, Object>{
            'firstName' => 'Primary',
            'lastName' => 'Renewal',
            'dob' => '1985-01-01',
            'gender' => 'Male',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '777 Renewal St',
                'city' => 'Toronto',
                'state' => 'ON',
                'zip' => 'M1M1M1'
            }
        };

        Map<String, Object> priorEnrollmentInfo = new Map<String, Object>();
        priorEnrollmentInfo.put('generalInformation', priorGeneralInfo);
        priorEnrollmentInfo.put('members', new List<Object>{
            new Map<String, Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => priorPerson
            }
        });

        InsurancePolicy priorPolicy = new InsurancePolicy(
            Name = 'Prior Renewal Policy',
            NameInsuredId = primaryAcc.Id
        );
        priorPolicy.put('ARC_Contract__c', contractRecord.Id);
        priorPolicy.put('ARC_JsonSESG__c', JSON.serialize(priorEnrollmentInfo));
        insert priorPolicy;

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        Map<String, Object> generalInfo = new Map<String, Object>();
        generalInfo.put('groupAccountId', groupAcc.Id);
        generalInfo.put('accountId', primaryAcc.Id);
        generalInfo.put('contractId', contractRecord.Id);
        generalInfo.put('primaryCensusMemberId', censusMember.Id);
        generalInfo.put('effectiveDate', String.valueOf(Date.today()));
        generalInfo.put('medicalProgram', new Map<String, Object>{
            'Renewal Plan' => new Map<String, Object>{
                'productId' => parentProduct.Id,
                'individualPrice' => 100.0,
                'employeeSplit' => 50.0,
                'employerSplit' => 50.0,
                'basePrice' => 200.0
            }
        });

        Map<String, Object> person = new Map<String, Object>{
            'firstName' => 'Primary',
            'lastName' => 'Renewal',
            'dob' => '1985-01-01',
            'gender' => 'Male',
            'isLegacy' => false,
            'address' => new Map<String, Object>{
                'street' => '777 Renewal St',
                'city' => 'Toronto',
                'state' => 'ON',
                'zip' => 'M1M1M1'
            }
        };

        enrollmentInfo.put('generalInformation', generalInfo);
        enrollmentInfo.put('members', new List<Object>{
            new Map<String, Object>{
                'memberExternalId' => 'M1',
                'role' => 'Primary',
                'person' => person
            }
        });

        Test.startTest();
        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);
        ARC_SGSEMapper mapper = new ARC_SGSEMapper();
        mapper.mapEnrollmentData(manager);
        Test.stopTest();

        System.assertNotEquals(null, mapper.manager.priorPolicy, 'Existing policy should be detected');
        System.assertEquals(priorPolicy.Id, mapper.manager.policy.Id, 'Mapped policy should reuse the existing policy Id');
        System.assertNotEquals(null, mapper.manager.policy.ARC_Reason__c, 'Policy reason should be populated');
    }
}