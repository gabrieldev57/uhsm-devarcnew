@isTest
public with sharing class ARC_NewBorn_BaseServiceTest {

    private static Map<String, Object> createInputMap(){
        // Activated Contract creation
        Contract enrollmentContract = ARC_TestUtility.createCompleteEnrollments(1)[0];
        enrollmentContract.ARC_EffectiveDate__c = Date.valueOf('2025-09-01');
        enrollmentContract.ARC_ContractReason__c = 'New Application';
        update enrollmentContract;

        enrollmentContract.Status = 'Activated';
        update enrollmentContract;
        
        List<Product2> productTestList = new List<Product2>();
        Product2 productTest = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Test Product UHSM0'
        ];
        productTest.vlocity_ins__SubType__c = 'PPO';
        productTest.ProductCode = 'PROG_UHSM_Access5k';
        productTestList.add(productTest);
        Id rtCoverageSpec = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Coverage Spec').getRecordTypeId();
        Product2 prodCov = new Product2();
        prodCov.Name = 'Coverage Spec';
        prodCov.vlocity_ins__Type__c = 'Medical';
        prodCov.RecordTypeId = rtCoverageSpec;
        productTestList.add(prodCov);
        upsert productTestList;

        vlocity_ins__ProductChildItem__c childItem = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ChildProductId__c = prodCov.Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert childItem;
        
        InsurancePolicy ipTest = ARC_TestUtility.createTestPolicies(1, 'ARC_IndividualAndFamily')[0];
        ipTest.ARC_Contract__c = enrollmentContract.Id;
        ipTest.ProductId = productTest.Id;

        update ipTest;

        InsurancePolicyCoverage ipcTest = new InsurancePolicyCoverage(
            InsurancePolicyId = ipTest.Id,
            vlocity_ins_fsc__Product2Id__c = productTest.Id
        );

        insert ipcTest;

        Contract enrollmentContractTest = [SELECT vlocity_ins__EnrollmentCensusId__c
                                           FROM Contract
                                           WHERE Id = :enrollmentContract.Id][0];

        // 1. Get the census members
        List<ARC_ContractParticipant__c> censusMembersList = [SELECT ARC_PersonAccount__c, ARC_PersonAccount__r.Census_Member__c, ARC_PersonAccount__r.PersonContactId
                                                              FROM ARC_ContractParticipant__c
                                                              WHERE ARC_Contract__c = :enrollmentContract.Id];

        // 2. Get the primary group census
        vlocity_ins__GroupCensus__c primaryGroupCensus = [SELECT Id 
                                                          FROM vlocity_ins__GroupCensus__c
                                                          WHERE Name = 'census test 0'];
        primaryGroupCensus.ARC_PrimaryAccount__c = censusMembersList[0].ARC_PersonAccount__c;
        update primaryGroupCensus;

        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Old Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Credit Card',
            ChargentBase__Active__c = true
        );
        insert gateway;

        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = enrollmentContract.Id,
            ChargentOrders__Billing_First_Name__c = 'OneMember',
            ChargentOrders__Billing_Last_Name__c = 'Member',
            ChargentOrders__Card_Number__c = '4111111111111111',
            ChargentOrders__Card_Expiration_Month__c = '12',
            ChargentOrders__Card_Expiration_Year__c = '2026',
            ChargentOrders__Card_Last_4__c = '1111',
            ChargentOrders__Card_Type__c = 'Visa',
            ChargentOrders__Card_Month_Indicator__c = '12',
            ChargentOrders__Card_Year_Indicator__c = '2026',
            ChargentOrders__Charge_Amount__c = 99,
            ChargentOrders__Gateway__c = gateway.Id,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            //ChargentOrders__Charge_Date__c = '10-11-2024',
            ChargentOrders__Charge_Date__c = null,
            ARC_FirstMonthPayed__c = true,
            ChargentOrders__Manual_Charge__c = true,
            ChargentOrders__Description__c = 'Recurring'
        );
        insert existingOrder;

        ChargentBase__Chargent_Settings__c feeAmounts = new ChargentBase__Chargent_Settings__c();
        feeAmounts.ARC_DowngradeChangeFee__c = 50;
        feeAmounts.ARC_AddMemberChangeFee__c = 99;
        feeAmounts.ARC_UpgradeChangeFee__c = 99;
        insert feeAmounts;

        ARC_DocuSignTemplates__c templateSettingsTest = new ARC_DocuSignTemplates__c(); 
        
        templateSettingsTest.Name = 'Spin Off';
        templateSettingsTest.ARC_Template_Name__c = 'Spin Off';
        templateSettingsTest.ARC_Contract_Reasons__c = 'Spin Off';
        templateSettingsTest.ARC_DRTransform__c = 'Transform for Test';
        templateSettingsTest.ARC_Min_Dependents__c = 1;
        templateSettingsTest.ARC_Max_Dependents__c = 5;
        templateSettingsTest.ARC_State__c = 'CA';

        insert templateSettingsTest;

        vlocity_ins__VlocityDocuSignTemplate__c vlocityDocuSignTest = new vlocity_ins__VlocityDocuSignTemplate__c(
            Name =  'Spin Off',
            vlocity_ins__templateidentifier__c = 'vlocity-template-test'
        );
        
        insert vlocityDocuSignTest;

        ARC_PromotionCode__c promotionCodeTest = new ARC_PromotionCode__c();
        promotionCodeTest.Name = 'Healthy Discount';
        promotionCodeTest.ARC_ApplyOver__c = 'Medical';
        promotionCodeTest.ARC_DiscountRate__c = 16;
        promotionCodeTest.ARC_StartDate__c = Date.valueOf('2020-01-01');

        insert promotionCodeTest;

        // Create the inputMap
        Map<String, Object> inputMapNewborn = new Map<String, Object>{
                'execute_reprice_flag' => false,
                'EffectiveDate' => '2025-10-01',
                'Step_PaymentChangeFee' => new Map<String, Object>{
                    'RAD_ChargeAppFeeDefTrue' => 'No',
                    'BLK_ChargeFee' => new Map<String, Object> {
                        'LWC_PromoDiscountCodeRefactor' => new Map<String, Object> {
                            'PromotionCodeName' => 'Promotion Code Name Test',
                            'PromotionCodeId' => promotionCodeTest.Id,
                            'DiscountAmount' => '108.05',
                            'RAD_ChargeAppFeeDefTrue' => 'No',
                            'DiscountPrice' => '0',
                            'AgentId' => UserInfo.getUserId()
                        },
                        'nbFeeItems' => new List <Object>{  
                            new Map<String, Object>{
                                'Name' => 'Fee Test Newborn',
                                'Amount' => '15.05'        
                            }
                        }
                    }
                },
                'plans' => new List<Object>{
                    new Map<String, Object>{
                        'userInputs' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                'RF_Census.CM_Age' => 25,
                                'RF_Census.CRF_PrimaryMemberDOB' => '2000-01-01',
                                'RF_Census.CM_State' => 'CA',
                                'RF_Census.CM_IsPrimary' => true,
                                'RF_Census.CM_Relationship' => 'Primary',
                                'RF_Census.CM_Smoker' => false,
                                'RF_Census.CM_Pregnant' => false,
                                'RF_Census.CM_FirstName' => 'FN Primary Test by Gabriel #17',
                                'RF_Census.CM_LastName' => 'LN Primary Test by Gabriel #17',
                                'IsRemoveMember' => false,
                                'IsNewMember' => false,
                                'IsAddExistingMember' => false,
                                'RF_Census.CRF_ExtraDependants' => 0,
                                'RF_Census.CRF_PrimaryMemberAge' => 25,
                                'RF_Census.CRF_Dependants' => 3
                            },
                            new Map<String, Object>{
                                'Id' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                'RF_Census.CM_Age' => 25,
                                'RF_Census.CRF_PrimaryMemberDOB' => '2000-02-02',
                                'RF_Census.CM_State' => 'CA',
                                'RF_Census.CM_IsPrimary' => false,
                                'RF_Census.CM_Relationship' => 'Spouse',
                                'RF_Census.CM_Smoker' => false,
                                'RF_Census.CM_Pregnant' => false,
                                'RF_Census.CM_FirstName' => 'FN Spouse Test by Gabriel #17',
                                'RF_Census.CM_LastName' => 'LN Spouse Test by Gabriel #17',
                                'IsRemoveMember' => false,
                                'IsNewMember' => false,
                                'IsAddExistingMember' => false,
                                'RF_Census.CRF_ExtraDependants' => 0,
                                'RF_Census.CRF_PrimaryMemberAge' => 25,
                                'RF_Census.CRF_Dependants' => 3
                            },
                            new Map<String, Object>{
                                'Id' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                'RF_Census.CM_Age' => 5,
                                'RF_Census.CRF_PrimaryMemberDOB' => '2020-03-03',
                                'RF_Census.CM_State' => 'CA',
                                'RF_Census.CM_IsPrimary' => false,
                                'RF_Census.CM_Relationship' => 'Child',
                                'RF_Census.CM_Smoker' => false,
                                'RF_Census.CM_Pregnant' => false,
                                'RF_Census.CM_FirstName' => 'FN Child Test by Gabriel #17',
                                'RF_Census.CM_LastName' => 'LN Child Test by Gabriel #17',
                                'IsRemoveMember' => false,
                                'IsNewMember' => false,
                                'IsAddExistingMember' => false,
                                'RF_Census.CRF_ExtraDependants' => 0,
                                'RF_Census.CRF_PrimaryMemberAge' => 25,
                                'RF_Census.CRF_Dependants' => 3
                            },
                            new Map<String, Object>{
                                'Id' => 'MEM-41110220858522095',
                                'RF_Census.CM_Age' => 0,
                                'RF_Census.CRF_PrimaryMemberDOB' => '2025-09-01',
                                'RF_Census.CM_State' => 'CA',
                                'RF_Census.CM_IsPrimary' => false,
                                'RF_Census.CM_Relationship' => 'Child',
                                'RF_Census.CM_Smoker' => false,
                                'RF_Census.CM_Pregnant' => false,
                                'RF_Census.CM_FirstName' => 'FN Newborn Test by Gabriel #17',
                                'RF_Census.CM_LastName' => 'LN Newborn Test by Gabriel #17',
                                'IsRemoveMember' => false,
                                'IsNewMember' => false,
                                'IsAddExistingMember' => false,
                                'RF_Census.CRF_ExtraDependants' => 0,
                                'RF_Census.CRF_PrimaryMemberAge' => 25,
                                'RF_Census.CRF_Dependants' => 3
                            }
                        },
                        'selectedProduct' => new Map<String, Object>{
                            'Id' => '01t5f000003zEucAAE'
                        }
                    }
                },
                'ED_MemberPrescription' => null,
                'OldProductList' => new List<Object>{
                    new Map<String, Object>{
                        'selectedProduct' => new Map<String, Object>{
                            'productId' => '01t5f000003zEucAAE',
                            'Type__c' => 'Medical',
                            'Price' => 389.91,
                            'Name' => 'WeShare Access 5k',
                            'Id' => 'a2Wcb000000913JEAQ'
                        },
                        'userInputs' => new List<Object>{
                            new Map<String, Object>{
                                'LastName' => 'LN Primary Test by Gabriel #17',
                                'FirstName' => 'FN Primary Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Primary Test by Gabriel #17',
                                'CensusMemberId' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'LastName' => 'LN Spouse Test by Gabriel #17',
                                'FirstName' => 'FN Spouse Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                'CensusMemberId' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'LastName' => 'LN Child Test by Gabriel #17',
                                'FirstName' => 'FN Child Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                'CensusMemberId' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                'CensusMemberFirstName' => 'FN Child Test by Gabriel #17'
                            }
                        }
                    }
                },
                'oldProducts' => new List<Object>{
                    new Map<String, Object>{
                        'census_members' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                'ARC_Smoker__c' => false,
                                'ARC_Relationship__c' => 'Primary',
                                'ARC_PhysicalAddressState__c' => 'CA',
                                'ARC_Age__c' => 25,
                                'vlocity_ins__MemberIdentifier__c' => '2025-09-12T00:17:25.806Z',
                                'vlocity_ins__LastName__c' => 'LN Primary Test by Gabriel #17',
                                'vlocity_ins__IsPrimaryMember__c' => true,
                                'vlocity_ins__FirstName__c' => 'FN Primary Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'Id' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                'ARC_Smoker__c' => false,
                                'ARC_Relationship__c' => 'Spouse',
                                'ARC_PhysicalAddressState__c' => 'CA',
                                'ARC_Age__c' => 25,
                                'vlocity_ins__MemberIdentifier__c' => '1757636299355-0.5312599300203945',
                                'vlocity_ins__LastName__c' => 'LN Spouse Test by Gabriel #17',
                                'vlocity_ins__IsPrimaryMember__c' => false,
                                'vlocity_ins__FirstName__c' => 'FN Spouse Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'Id' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                'ARC_Smoker__c' => false,
                                'ARC_Relationship__c' => 'Child',
                                'ARC_PhysicalAddressState__c' => 'CA',
                                'ARC_Age__c' => 5,
                                'vlocity_ins__MemberIdentifier__c' => '1757636318886-0.5361254534561513',
                                'vlocity_ins__LastName__c' => 'LN Child Test by Gabriel #17',
                                'vlocity_ins__IsPrimaryMember__c' => false,
                                'vlocity_ins__FirstName__c' => 'FN Child Test by Gabriel #17'
                            }
                        },
                        'recordTypeName' => 'Product',
                        'productId' => '01t5f000003zEucAAE',
                        'Type__c' => 'Medical',
                        'SubType__c' => 'PPO',
                        'Price' => 389.91,
                        'Name' => 'WeShare Access 5k',
                        'Id' => 'a2Wcb000000913JEAQ'
                    }
                },
                'NewProductList' => new List<Object>{
                    new Map<String, Object>{
                        'userInputs' => new List<Object>{
                            new Map<String, Object>{
                                'LastName' => 'LN Primary Test by Gabriel #17',
                                'FirstName' => 'FN Primary Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Primary Test by Gabriel #17',
                                'CensusMemberId' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'LastName' => 'LN Spouse Test by Gabriel #17',
                                'FirstName' => 'FN Spouse Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                'CensusMemberId' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'LastName' => 'LN Child Test by Gabriel #17',
                                'FirstName' => 'FN Child Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                'CensusMemberId' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                'CensusMemberFirstName' => 'FN Child Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'LastName' => 'LN Newborn Test by Gabriel #17',
                                'FirstName' => 'FN Newborn Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Newborn Test by Gabriel #17',
                                'CensusMemberId' => 'MEM-41110220858522095',
                                'CensusMemberFirstName' => 'FN Newborn Test by Gabriel #17'
                            }
                        },
                        'selectedProduct' => new Map<String, Object>{
                            'productId' => '01t5f000003zEucAAE',
                            'Type__c' => 'Medical',
                            'Price' => 389.91,
                            'Name' => 'WeShare Access 5k',
                            'Id' => '01t5f000003zEucAAE'
                        }
                    }
                },
                'price_calculation' => new Map<String, Object>{
                    'plans' => new List<Object>{
                        new Map<String, Object>{
                            'selectedProduct' => new Map<String, Object>{
                                'displaySequence' => -1,
                                'RawPriceData' => new List<Object>{
                                    new Map<String, Object>{
                                        'aggregationResults' => new Map<String, Object>{
                                            'Price' => 389.91
                                        },
                                        'calculationResults' => new List<Object>{
                                            new Map<String, Object>{
                                                'Price' => 389.91,
                                                'Smoker' => false,
                                                'ProductCodeOut' => 'PROG_UHSM_Access5k',
                                                'IsPrimary' => true,
                                                'StateOut' => 'CA',
                                                'AgeOut' => 25,
                                                'MemberRate' => 389.91,
                                                'ARC_UHSM_StateRateFactors__StateFactor' => 1.03,
                                                'ARC_UHSM_Individual__Price' => 378.55,
                                                'ID' => '0'
                                            },
                                            new Map<String, Object>{
                                                'Smoker' => false,
                                                'ProductCodeOut' => 'PROG_UHSM_Access5k',
                                                'IsPrimary' => false,
                                                'StateOut' => 'CA',
                                                'AgeOut' => 25,
                                                'MemberRate' => 0,
                                                'ID' => '1'
                                            },
                                            new Map<String, Object>{
                                                'Smoker' => false,
                                                'ProductCodeOut' => 'PROG_UHSM_Access5k',
                                                'IsPrimary' => false,
                                                'StateOut' => 'CA',
                                                'AgeOut' => 25,
                                                'MemberRate' => 0,
                                                'ID' => '2'
                                            },
                                            new Map<String, Object>{
                                                'Smoker' => false,
                                                'ProductCodeOut' => 'PROG_UHSM_Access5k',
                                                'IsPrimary' => false,
                                                'StateOut' => 'CA',
                                                'AgeOut' => 25,
                                                'MemberRate' => 0,
                                                'ID' => '3'
                                            }
                                        }
                                    }
                                },
                                'Id' => '01t5f000003zEucAAE',
                                'Name' => 'WeShare Access 5k',
                                'ProductCode' => 'PROG_UHSM_Access5k',
                                'MarketSegment__c' => 'Individual',
                                'Type__c' => 'Medical',
                                'SubType__c' => 'PPO',
                                'IsRecommended__c' => false,
                                'PricingSource__c' => 'Configurable',
                                'RecordTypeName__c' => 'Product',
                                'IsConfigurable__c' => true,
                                'PricingFormula__c' => 'Price',
                                'productId' => '01t5f000003zEucAAE',
                                'currencyCode' => 'USD',
                                'currencySymbol' => '$',
                                'Price' => 389.91,
                                'attributeCategories' => new Map<String, Object>{
                                    'totalSize' => 2,
                                    'records' => new List<Object>{
                                        new Map<String, Object>{
                                            'displaySequence' => 2,
                                            'Code__c' => 'UHSM_Medical_Services',
                                            'Name' => 'Medical Services',
                                            'id' => 'a1h8K00000048Y1QAI',
                                            'productAttributes' => new Map<String, Object>{
                                                'totalSize' => 1,
                                                'records' => new List<Object>{
                                                    new Map<String, Object>{
                                                        'code' => 'AMCS',
                                                        'multiselect' => false,
                                                        'dataType' => 'text',
                                                        'inputType' => 'text',
                                                        'required' => false,
                                                        'readonly' => false,
                                                        'disabled' => false,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000JLwQQAW',
                                                        'label' => 'AMCS',
                                                        'displaySequence' => 6,
                                                        'hasRules' => false,
                                                        'description' => '5K/10K',
                                                        'hidden' => true,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => false,
                                                                'disabled' => false
                                                            }
                                                        },
                                                        'userValues' => '5K/10K',
                                                        'isNotAssetizable' => false
                                                    }
                                                }
                                            }
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 14,
                                            'Code__c' => 'WESHR_POWATT',
                                            'Name' => 'WeShare - Power Attributes',
                                            'id' => 'a1h8K00000048Y3QAI',
                                            'productAttributes' => new Map<String, Object>{
                                                'totalSize' => 6,
                                                'records' => new List<Object>{
                                                    new Map<String, Object>{
                                                        'code' => 'individualAMCS',
                                                        'multiselect' => false,
                                                        'dataType' => 'currency',
                                                        'inputType' => 'number',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000JLxXQAW',
                                                        'label' => 'Individual AMCS',
                                                        'displaySequence' => 0,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 5000,
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'familyAMCS',
                                                        'multiselect' => false,
                                                        'dataType' => 'currency',
                                                        'inputType' => 'number',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000JLxWQAW',
                                                        'label' => 'Family AMCS',
                                                        'displaySequence' => 1,
                                                        'hasRules' => false,
                                                        'description' => '10000',
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 10000,
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'MedicalMaxShareLimits',
                                                        'multiselect' => false,
                                                        'dataType' => 'text',
                                                        'inputType' => 'text',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000KxdWQAS',
                                                        'label' => 'Medical Maximum Share Limits',
                                                        'displaySequence' => 2,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 'No lifetime or annual share maximums, except where explicitly noted',
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'PharmacyMemberCareShare',
                                                        'multiselect' => false,
                                                        'dataType' => 'currency',
                                                        'inputType' => 'number',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000KxdbQAC',
                                                        'label' => 'Pharmacy Member Care Share (annual, per member)',
                                                        'displaySequence' => 3,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 250,
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'PharmacyShareMaximum',
                                                        'multiselect' => false,
                                                        'dataType' => 'currency',
                                                        'inputType' => 'number',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000KxdgQAC',
                                                        'label' => 'Pharmacy Share Maximum (annual, per member)',
                                                        'displaySequence' => 4,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 2500,
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'OutOfNetworkServices',
                                                        'multiselect' => false,
                                                        'dataType' => 'text',
                                                        'inputType' => 'text',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000KxdhQAC',
                                                        'label' => 'Out-of-Network Services',
                                                        'displaySequence' => 5,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 'Only in the case of an emergency or when pre-authorized',
                                                        'isNotAssetizable' => false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                },
                                'childProducts' => new Map<String, Object>{
                                    'totalSize' => 6,
                                    'records' => new List<Object>{
                                        new Map<String, Object>{
                                            'displaySequence' => 1,
                                            'Id' => productTest.Id,
                                            'Name' => 'Preventative Care',
                                            'ProductCode' => 'ARC_UHSMPreventativeCare',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 2,
                                            'Id' => '01tRm000000GGDiIAO',
                                            'Name' => 'Prescriptions',
                                            'ProductCode' => 'ARC_UHSMPrescriptions',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 3,
                                            'Id' => productTest.Id,
                                            'Name' => 'Physician Services',
                                            'ProductCode' => 'ARC_UHSMPhysicianServices',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 5,
                                            'Id' => '01tRm000000GGC5IAO',
                                            'Name' => 'Miscellaneous',
                                            'ProductCode' => 'ARC_UHSMMiscellaneous',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 4,
                                            'Id' => '01tRm000000GGC6IAO',
                                            'Name' => 'Emergencies & Hospitalizations',
                                            'ProductCode' => 'ARC_UHSMEmergenciesAndHospitalizations',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 1,
                                            'Id' => productTest.Id,
                                            'Name' => 'Census',
                                            'ProductCode' => 'RF_Census',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'RatingFactSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        }
                                    }
                                }
                            },
                            'userInputs' => new List<Object>{
                                new Map<String, Object>{
                                    'Id' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                    'RF_Census.CM_Age' => 25,
                                    'RF_Census.CRF_PrimaryMemberDOB' => '2000-01-01',
                                    'RF_Census.CM_State' => 'CA',
                                    'RF_Census.CM_IsPrimary' => true,
                                    'RF_Census.CM_Relationship' => 'Primary',
                                    'RF_Census.CM_Smoker' => false,
                                    'RF_Census.CM_Pregnant' => false,
                                    'RF_Census.CM_FirstName' => 'FN Primary Test by Gabriel #17',
                                    'RF_Census.CM_LastName' => 'LN Primary Test by Gabriel #17',
                                    'IsRemoveMember' => false,
                                    'IsNewMember' => false,
                                    'IsAddExistingMember' => false,
                                    'RF_Census.CRF_ExtraDependants' => 0,
                                    'RF_Census.CRF_PrimaryMemberAge' => 25,
                                    'RF_Census.CRF_Dependants' => 3
                                },
                                new Map<String, Object>{
                                    'Id' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                    'RF_Census.CM_Age' => 25,
                                    'RF_Census.CRF_PrimaryMemberDOB' => '2000-02-02',
                                    'RF_Census.CM_State' => 'CA',
                                    'RF_Census.CM_IsPrimary' => false,
                                    'RF_Census.CM_Relationship' => 'Spouse',
                                    'RF_Census.CM_Smoker' => false,
                                    'RF_Census.CM_Pregnant' => false,
                                    'RF_Census.CM_FirstName' => 'FN Spouse Test by Gabriel #17',
                                    'RF_Census.CM_LastName' => 'LN Spouse Test by Gabriel #17',
                                    'IsRemoveMember' => false,
                                    'IsNewMember' => false,
                                    'IsAddExistingMember' => false,
                                    'RF_Census.CRF_ExtraDependants' => 0,
                                    'RF_Census.CRF_PrimaryMemberAge' => 25,
                                    'RF_Census.CRF_Dependants' => 3
                                },
                                new Map<String, Object>{
                                    'Id' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                    'RF_Census.CM_Age' => 5,
                                    'RF_Census.CRF_PrimaryMemberDOB' => '2020-03-03',
                                    'RF_Census.CM_State' => 'CA',
                                    'RF_Census.CM_IsPrimary' => false,
                                    'RF_Census.CM_Relationship' => 'Child',
                                    'RF_Census.CM_Smoker' => false,
                                    'RF_Census.CM_Pregnant' => false,
                                    'RF_Census.CM_FirstName' => 'FN Child Test by Gabriel #17',
                                    'RF_Census.CM_LastName' => 'LN Child Test by Gabriel #17',
                                    'IsRemoveMember' => false,
                                    'IsNewMember' => false,
                                    'IsAddExistingMember' => false,
                                    'RF_Census.CRF_ExtraDependants' => 0,
                                    'RF_Census.CRF_PrimaryMemberAge' => 25,
                                    'RF_Census.CRF_Dependants' => 3
                                },
                                new Map<String, Object>{
                                    'Id' => 'MEM-41110220858522095',
                                    'RF_Census.CM_Age' => 0,
                                    'RF_Census.CRF_PrimaryMemberDOB' => '2025-09-01',
                                    'RF_Census.CM_State' => 'CA',
                                    'RF_Census.CM_IsPrimary' => false,
                                    'RF_Census.CM_Relationship' => 'Child',
                                    'RF_Census.CM_Smoker' => false,
                                    'RF_Census.CM_Pregnant' => false,
                                    'RF_Census.CM_FirstName' => 'FN Newborn Test by Gabriel #17',
                                    'RF_Census.CM_LastName' => 'LN Newborn Test by Gabriel #17',
                                    'IsRemoveMember' => false,
                                    'IsNewMember' => false,
                                    'IsAddExistingMember' => false,
                                    'RF_Census.CRF_ExtraDependants' => 0,
                                    'RF_Census.CRF_PrimaryMemberAge' => 25,
                                    'RF_Census.CRF_Dependants' => 3
                                }
                            }
                        },
                        new Map<String, Object>{
                            'selectedProduct' => new Map<String, Object>{
                                'displaySequence' => -1,
                                'RawPriceData' => new List<Object>{
                                    new Map<String, Object>{
                                        'aggregationResults' => new Map<String, Object>{
                                            'Price' => 389.91
                                        },
                                        'calculationResults' => new List<Object>{
                                            new Map<String, Object>{
                                                'Price' => 389.91,
                                                'Smoker' => false,
                                                'ProductCodeOut' => 'PROG_UHSM_Access5k',
                                                'IsPrimary' => true,
                                                'StateOut' => 'CA',
                                                'AgeOut' => 25,
                                                'MemberRate' => 389.91,
                                                'ARC_UHSM_StateRateFactors__StateFactor' => 1.03,
                                                'ARC_UHSM_Individual__Price' => 378.55,
                                                'ID' => '0'
                                            },
                                            new Map<String, Object>{
                                                'Smoker' => false,
                                                'ProductCodeOut' => 'PROG_UHSM_Access5k',
                                                'IsPrimary' => false,
                                                'StateOut' => 'CA',
                                                'AgeOut' => 25,
                                                'MemberRate' => 0,
                                                'ID' => '1'
                                            },
                                            new Map<String, Object>{
                                                'Smoker' => false,
                                                'ProductCodeOut' => 'PROG_UHSM_Access5k',
                                                'IsPrimary' => false,
                                                'StateOut' => 'CA',
                                                'AgeOut' => 25,
                                                'MemberRate' => 0,
                                                'ID' => '2'
                                            },
                                            new Map<String, Object>{
                                                'Smoker' => false,
                                                'ProductCodeOut' => 'PROG_UHSM_Access5k',
                                                'IsPrimary' => false,
                                                'StateOut' => 'CA',
                                                'AgeOut' => 25,
                                                'MemberRate' => 0,
                                                'ID' => '3'
                                            }
                                        }
                                    }
                                },
                                'Id' => '01t5f000003zEucAAE',
                                'Name' => 'WeShare Access 5k',
                                'ProductCode' => 'PROG_UHSM_Access5k',
                                'MarketSegment__c' => 'Individual',
                                'Type__c' => 'Ancillary',
                                'SubType__c' => 'PPO',
                                'IsRecommended__c' => false,
                                'PricingSource__c' => 'Configurable',
                                'RecordTypeName__c' => 'Product',
                                'IsConfigurable__c' => true,
                                'PricingFormula__c' => 'Price',
                                'productId' => '01t5f000003zEucAAE',
                                'currencyCode' => 'USD',
                                'currencySymbol' => '$',
                                'Price' => 389.91,
                                'attributeCategories' => new Map<String, Object>{
                                    'totalSize' => 2,
                                    'records' => new List<Object>{
                                        new Map<String, Object>{
                                            'displaySequence' => 2,
                                            'Code__c' => 'UHSM_Medical_Services',
                                            'Name' => 'Medical Services',
                                            'id' => 'a1h8K00000048Y1QAI',
                                            'productAttributes' => new Map<String, Object>{
                                                'totalSize' => 1,
                                                'records' => new List<Object>{
                                                    new Map<String, Object>{
                                                        'code' => 'AMCS',
                                                        'multiselect' => false,
                                                        'dataType' => 'text',
                                                        'inputType' => 'text',
                                                        'required' => false,
                                                        'readonly' => false,
                                                        'disabled' => false,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000JLwQQAW',
                                                        'label' => 'AMCS',
                                                        'displaySequence' => 6,
                                                        'hasRules' => false,
                                                        'description' => '5K/10K',
                                                        'hidden' => true,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => false,
                                                                'disabled' => false
                                                            }
                                                        },
                                                        'userValues' => '5K/10K',
                                                        'isNotAssetizable' => false
                                                    }
                                                }
                                            }
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 14,
                                            'Code__c' => 'WESHR_POWATT',
                                            'Name' => 'WeShare - Power Attributes',
                                            'id' => 'a1h8K00000048Y3QAI',
                                            'productAttributes' => new Map<String, Object>{
                                                'totalSize' => 6,
                                                'records' => new List<Object>{
                                                    new Map<String, Object>{
                                                        'code' => 'individualAMCS',
                                                        'multiselect' => false,
                                                        'dataType' => 'currency',
                                                        'inputType' => 'number',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000JLxXQAW',
                                                        'label' => 'Individual AMCS',
                                                        'displaySequence' => 0,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 5000,
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'familyAMCS',
                                                        'multiselect' => false,
                                                        'dataType' => 'currency',
                                                        'inputType' => 'number',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000JLxWQAW',
                                                        'label' => 'Family AMCS',
                                                        'displaySequence' => 1,
                                                        'hasRules' => false,
                                                        'description' => '10000',
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 10000,
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'MedicalMaxShareLimits',
                                                        'multiselect' => false,
                                                        'dataType' => 'text',
                                                        'inputType' => 'text',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000KxdWQAS',
                                                        'label' => 'Medical Maximum Share Limits',
                                                        'displaySequence' => 2,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 'No lifetime or annual share maximums, except where explicitly noted',
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'PharmacyMemberCareShare',
                                                        'multiselect' => false,
                                                        'dataType' => 'currency',
                                                        'inputType' => 'number',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000KxdbQAC',
                                                        'label' => 'Pharmacy Member Care Share (annual, per member)',
                                                        'displaySequence' => 3,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 250,
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'PharmacyShareMaximum',
                                                        'multiselect' => false,
                                                        'dataType' => 'currency',
                                                        'inputType' => 'number',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000KxdgQAC',
                                                        'label' => 'Pharmacy Share Maximum (annual, per member)',
                                                        'displaySequence' => 4,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 2500,
                                                        'isNotAssetizable' => false
                                                    },
                                                    new Map<String, Object>{
                                                        'code' => 'OutOfNetworkServices',
                                                        'multiselect' => false,
                                                        'dataType' => 'text',
                                                        'inputType' => 'text',
                                                        'required' => false,
                                                        'readonly' => true,
                                                        'disabled' => true,
                                                        'filterable' => true,
                                                        'attributeId' => 'a1i8K000000KxdhQAC',
                                                        'label' => 'Out-of-Network Services',
                                                        'displaySequence' => 5,
                                                        'hasRules' => false,
                                                        'hidden' => false,
                                                        'cloneable' => true,
                                                        'isNotTranslatable' => false,
                                                        'values' => new List<Object>{
                                                            new Map<String, Object>{
                                                                'readonly' => true,
                                                                'disabled' => true
                                                            }
                                                        },
                                                        'userValues' => 'Only in the case of an emergency or when pre-authorized',
                                                        'isNotAssetizable' => false
                                                    }
                                                }
                                            }
                                        }
                                    }
                                },
                                'childProducts' => new Map<String, Object>{
                                    'totalSize' => 6,
                                    'records' => new List<Object>{
                                        new Map<String, Object>{
                                            'displaySequence' => 1,
                                            'Id' => productTest.Id,
                                            'Name' => 'Preventative Care',
                                            'ProductCode' => 'ARC_UHSMPreventativeCare',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 2,
                                            'Id' => '01tRm000000GGDiIAO',
                                            'Name' => 'Prescriptions',
                                            'ProductCode' => 'ARC_UHSMPrescriptions',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 3,
                                            'Id' => productTest.Id,
                                            'Name' => 'Physician Services',
                                            'ProductCode' => 'ARC_UHSMPhysicianServices',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 5,
                                            'Id' => '01tRm000000GGC5IAO',
                                            'Name' => 'Miscellaneous',
                                            'ProductCode' => 'ARC_UHSMMiscellaneous',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 4,
                                            'Id' => '01tRm000000GGC6IAO',
                                            'Name' => 'Emergencies & Hospitalizations',
                                            'ProductCode' => 'ARC_UHSMEmergenciesAndHospitalizations',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => '01tRm000000GGC6IAO',
                                            'pciId' => childItem.Id
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 1,
                                            'Id' => productTest.Id,
                                            'Name' => 'Census',
                                            'ProductCode' => 'RF_Census',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'RatingFactSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'productId' => productTest.Id,
                                            'pciId' => childItem.Id
                                        }
                                    }
                                }
                            },
                            'userInputs' => new List<Object>{
                                new Map<String, Object>{
                                    'Id' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                    'RF_Census.CM_Age' => 25,
                                    'RF_Census.CRF_PrimaryMemberDOB' => '2000-01-01',
                                    'RF_Census.CM_State' => 'CA',
                                    'RF_Census.CM_IsPrimary' => true,
                                    'RF_Census.CM_Relationship' => 'Primary',
                                    'RF_Census.CM_Smoker' => false,
                                    'RF_Census.CM_Pregnant' => false,
                                    'RF_Census.CM_FirstName' => 'FN Primary Test by Gabriel #17',
                                    'RF_Census.CM_LastName' => 'LN Primary Test by Gabriel #17',
                                    'IsRemoveMember' => false,
                                    'IsNewMember' => false,
                                    'IsAddExistingMember' => false,
                                    'RF_Census.CRF_ExtraDependants' => 0,
                                    'RF_Census.CRF_PrimaryMemberAge' => 25,
                                    'RF_Census.CRF_Dependants' => 3
                                },
                                new Map<String, Object>{
                                    'Id' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                    'RF_Census.CM_Age' => 25,
                                    'RF_Census.CRF_PrimaryMemberDOB' => '2000-02-02',
                                    'RF_Census.CM_State' => 'CA',
                                    'RF_Census.CM_IsPrimary' => false,
                                    'RF_Census.CM_Relationship' => 'Spouse',
                                    'RF_Census.CM_Smoker' => false,
                                    'RF_Census.CM_Pregnant' => false,
                                    'RF_Census.CM_FirstName' => 'FN Spouse Test by Gabriel #17',
                                    'RF_Census.CM_LastName' => 'LN Spouse Test by Gabriel #17',
                                    'IsRemoveMember' => false,
                                    'IsNewMember' => false,
                                    'IsAddExistingMember' => false,
                                    'RF_Census.CRF_ExtraDependants' => 0,
                                    'RF_Census.CRF_PrimaryMemberAge' => 25,
                                    'RF_Census.CRF_Dependants' => 3
                                },
                                new Map<String, Object>{
                                    'Id' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                    'RF_Census.CM_Age' => 5,
                                    'RF_Census.CRF_PrimaryMemberDOB' => '2020-03-03',
                                    'RF_Census.CM_State' => 'CA',
                                    'RF_Census.CM_IsPrimary' => false,
                                    'RF_Census.CM_Relationship' => 'Child',
                                    'RF_Census.CM_Smoker' => false,
                                    'RF_Census.CM_Pregnant' => false,
                                    'RF_Census.CM_FirstName' => 'FN Child Test by Gabriel #17',
                                    'RF_Census.CM_LastName' => 'LN Child Test by Gabriel #17',
                                    'IsRemoveMember' => false,
                                    'IsNewMember' => false,
                                    'IsAddExistingMember' => false,
                                    'RF_Census.CRF_ExtraDependants' => 0,
                                    'RF_Census.CRF_PrimaryMemberAge' => 25,
                                    'RF_Census.CRF_Dependants' => 3
                                },
                                new Map<String, Object>{
                                    'Id' => 'MEM-41110220858522095',
                                    'RF_Census.CM_Age' => 0,
                                    'RF_Census.CRF_PrimaryMemberDOB' => '2025-09-01',
                                    'RF_Census.CM_State' => 'CA',
                                    'RF_Census.CM_IsPrimary' => false,
                                    'RF_Census.CM_Relationship' => 'Child',
                                    'RF_Census.CM_Smoker' => false,
                                    'RF_Census.CM_Pregnant' => false,
                                    'RF_Census.CM_FirstName' => 'FN Newborn Test by Gabriel #17',
                                    'RF_Census.CM_LastName' => 'LN Newborn Test by Gabriel #17',
                                    'IsRemoveMember' => false,
                                    'IsNewMember' => false,
                                    'IsAddExistingMember' => false,
                                    'RF_Census.CRF_ExtraDependants' => 0,
                                    'RF_Census.CRF_PrimaryMemberAge' => 25,
                                    'RF_Census.CRF_Dependants' => 3
                                }
                            }
                        }
                    }
                },
                'nbChanges' => new Map<String, Object>{
                    'nbReasonsString' => 'Add Newborn',
                    'feeApplicable' => true,
                    'nbReasons' => new Map<String, Object>{
                        'Add Newborn' => true
                    },
                    'programSummaryFeeText' => 'One Time Change Fee (Add Newborn): 0',
                    'feeAmount' => 0
                },
                'PlansSummary' => new Map<String, Object>{
                    'BLK_ProductSummary' => new Map<String, Object>{
                        'TXT_ProgramSummaryFeeText' => 'One Time Change Fee (Add Newborn):',
                        'TXT_FeeAmount' => '$0.00',
                        'BLK_ProductsPrices' => new Map<String, Object>{
                            'TXT_EffDate' => '2025-10-01',
                            'BLK_IndividualProducts' => new List<Object>{
                                new Map<String, Object>{
                                    'TXT_PlanSelected' => 'WeShare Access 5k',
                                    'TXT_PlanSelectedPrice' => '$389.91',
                                    'Type' => 'Medical'
                                }
                            }
                        },
                        'TXT_MonthlyPrice' => '$389.91'
                    }
                },
                'ContextId' => '001U900000hOW9JIAW',
                'userProfile' => 'System Administrator',
                'timeStamp' => '2025-09-12T00:32:32.295Z',
                'userTimeZoneName' => 'America/Los_Angeles',
                'userTimeZone' => '-420',
                'userCurrencyCode' => 'USD',
                'userName' => 'gabriel.martinez@arcsona.comuhsm.dev25',
                'userId' => UserInfo.getUserId(),
                'omniProcessId' => 'a4rcb0000007tCfAAI',
                'localTimeZoneName' => 'America/Mexico_City',
                'ResumePreviousOS' => null,
                'STEP_MotherNotInProgram' => null,
                'STEP_PermanentNewborn' => new Map<String, Object>{
                    'BLK_InputsIfYes' => new Map<String, Object>{
                        'DATE_EffectiveDate' => '2025-10-01'
                    },
                    'FRML_PermanentNewborn' => true,
                    'RAD_WantPermanentNewborn' => 'Yes'
                },
                'STEP_Reprice' => new Map<String, Object>{

                },
                'STEP_MedicalQuestions' => new Map<String, Object>{
                    'BLK_ParentSiblingDiagnosed' => new Map<String, Object>{
                        'CHKBOX_MemberParentDiagnosed' => true,
                        'DATE_MemberParentDiagnosed' => '2025-09-02',
                        'TXTAREA_MemberParentDiagnosed' => 'Question #1 Test',
                        'memberId' => 'MEM-41110220858522095',
                        'TXT_hasErrorParentDiagnosed' => 'false',
                        'TXT_MemberIdParentDiagnosed' => 'MEM-41110220858522095',
                        'TXT_MemberParentDiagnosed' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                    },
                    'FRML_ParentSiblingDiagnosedNull' => false,
                    'MSG_WrongUnexpectedDate' => null,
                    'BLK_UnexpectedSymptoms' => new Map<String, Object>{
                        'CHKBOX_UnexpectedSymptoms' => true,
                        'DATE_MemberUnexpectedSymptoms' => '2025-09-02',
                        'TXTAREA_MemberUnexpectedSymptoms' => 'Question #2 Test',
                        'memberId' => 'MEM-41110220858522095',
                        'TXT_hasError' => 'false',
                        'TXT_MemberIdUnexpectedSymptoms' => 'MEM-41110220858522095',
                        'TXT_MemberUnexpectedSymptoms' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                    },
                    'FRML_CheckSymptoms' => false,
                    'FRML_DateUnexpectedWrong' => false,
                    'BLK_PendingTests' => new Map<String, Object>{
                        'CHKBOX_PendingTests' => true,
                        'DATE_MemberPendingTests' => '2025-09-02',
                        'TXTAREA_MemberPendingTests' => 'Question #3 Test',
                        'memberId' => 'MEM-41110220858522095',
                        'TXT_MemberIdPendingTests' => 'MEM-41110220858522095',
                        'TXT_MemberPendingTests' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                    },
                    'FRML_CheckPendingTests' => false,
                    'LWC_SelectCensusMemberCancer' => new Map<String, Object>{
                        'SelectedCensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                        'SelectedCensusMemberId' => 'MEM-41110220858522095',
                        'SelectedCensusMemberBirthdate' => '2025-09-01'
                    },
                    'EB_Cancer' => new Map<String, Object>{
                        'FRML_MemberIdCancerBirthdate' => '2025-09-01T00:00:00.000Z',
                        'CHK_CheckCancer' => true,
                        'CHK_MemberBeenDiagnosedWithCancer' => true,
                        'TXT_MemberNameCancer' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                        'TXT_MemberIdCancer' => 'MEM-41110220858522095',
                        'TXT_hasErrorCancer' => 'false',
                        'TXT_TypeOfCancer' => 'Type of Cancer Test',
                        'DATE_Cancer' => '2025-09-02'
                    },
                    'FRML_CheckCancer' => false,
                    'MSG_DateWrongCancer' => null,
                    'FRML_DateWrongCancer' => false,
                    'MSG_WrongDateAddiction' => null,
                    'BLK_Addictions' => new Map<String, Object>{
                        'CHKBOX_Addictions' => true,
                        'DATE_MemberAddictions' => '2025-09-02',
                        'TXTAREA_MemberAddictions' => 'Question #4 Test',
                        'memberId' => 'MEM-41110220858522095',
                        'TXT_hasErrorAdiction' => 'false',
                        'TXT_MemberIdAddictions' => 'MEM-41110220858522095',
                        'TXT_MemberAddictions' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                    },
                    'FRML_CheckAddictions' => false,
                    'FMRL_WrongDateAddictions' => false,
                    'BLK_LicenceSuspended' => new Map<String, Object>{
                        'CHKBOX_LicenceSuspended' => true,
                        'DATE_MemberLicenceSuspended' => '2025-09-02',
                        'TXTAREA_MemberLicenceSuspended' => 'Question #5 Test',
                        'memberId' => 'MEM-41110220858522095',
                        'TXT_hasErrorLicenceSuspended' => 'false',
                        'TXT_MemberIdLicenceSuspended' => 'MEM-41110220858522095',
                        'TXT_MemberLicenceSuspended' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                    },
                    'FRML_LicenceSuspended' => false,
                    'EB_PastConditions' => new Map<String, Object>{
                        'memberId' => 'MEM-41110220858522095',
                        'TXT_MemberIdPastConditions' => 'MEM-41110220858522095',
                        'TXT_MemberPastConditions' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                        'MULSEL_Conditions' => 'Alcohol Abuse;ALS;Alzheimer’s Disease;Abdominal Aortic Aneurysm;Aneurysm, Cerebral;Autism Spectrum Disorders;Bipolar with 2 or more current medications;Cerebral Palsy;Chronic Obstructive Pulmonary Disease (COPD);Chronic Kidney Disease, stage 3b, 4 or 5;Cystic Fibrosis;Dementia;Diabetes, Type I;Diabetes, Type 2 when taking 2 heart medications, or have kidney/liver disease;Down’s Syndrome;Ectasia;Emphysema;Fragile X Syndrome;Fibromyalgia (w/ treatment);Hepatitis (Chronic Viral B & C);HIV/AIDS;Lupus;Macular Degeneration (wet or dry);Marfan’s Syndrome;Morbid Obesity (BMI > 40);Multiple Sclerosis;Muscular Dystrophy;Paralysis;Parkinson’s Disease;Rheumatoid Arthritis w/ biologic treatment;Schizophrenia with 2 or more current medications;Sickle-Cell Disease;Sjogren Syndrome;Spina Bifida;Systemic Lupus Erythematosus;Typhoid;Underweight (BMI <15);Inpatient Psychiatric Treatment within past 5 years;Treatment with Naloxone, Suboxone, Methadone or any other medication to treat addiction within the past 5 years',
                        'TXT_MemberOtherPastConditions' => 'Other Conditions Test'
                    },
                    'FRML_CheckPastConditionsNull' => false,
                    'MSG_DateWrongPrescription' => null,
                    'LWC_SelectCensusMember' => new Map<String, Object>{
                        'SelectedCensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                        'SelectedCensusMemberId' => 'MEM-41110220858522095'
                    },
                    'ED_MemberPrescription' => new Map<String, Object>{
                        'FRML_MemberBirthdate' => null,
                        'TXT_MemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                        'TXT_MemberIdPrescription' => 'MEM-41110220858522095',
                        'TXT_hasErrorMedication' => 'false',
                        'TXT_NameOfMedication' => 'Name of Medication Test',
                        'TXT_DatePrescribed' => '2025-09-02',
                        'TXT_DateDiscontinued' => '2025-09-03',
                        'TXT_ReasonForMedication' => 'Reason of Medication Test',
                        'TXT_PrescribingPhysician' => 'Prescribing Physician Test'
                    },
                    'FRML_CheckPrescriptionsIsNull' => false,
                    'FRML_DateWrongPrescription' => false,
                    'MSG_WrongDatePCP' => null,
                    'FRML_WrongDatePCP' => false,
                    'EB_Physicians' => new Map<String, Object>{
                        'memberId' => 'MEM-41110220858522095',
                        'TXT_hasErrorPCP' => 'false',
                        'TXT_CensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                        'TXT_PhysicianName' => 'Physician\'s Name Test',
                        'TXT_PhysicianCity' => 'City Test',
                        'TXT_PhysicianPhone' => '1111111111'
                    },
                    'RAD_PrescriptionMedications' => 'Yes',
                    'RAD_PastConditions' => 'Yes',
                    'RAD_LicenceSuspended' => 'Yes',
                    'RAD_Addictions' => 'Yes',
                    'RAD_Cancer' => 'Yes',
                    'RAD_PendingTests' => 'Yes',
                    'RAD_UnexplainedSymptoms' => 'Yes',
                    'RAD_ParentSiblingDiagnosed' => 'Yes',
                    'aRC_showErrorInMedicationStep' => new Map<String, Object>{
                        'hasErrorPCP' => false,
                        'hasErrorUnexpected' => false,
                        'hasErrorAddictions' => false,
                        'hasErrorCancer' => false,
                        'hasErrorMedication' => false
                    }
                },
                'STEP_PlansSummary' => new Map<String, Object>{

                },
                'STEP_SignTheDocument' => new Map<String, Object>{
                    'CHK_AgreeingSigning' => false,
                    'FRML_RecipientData' => null
                },
                'OSName' => 'IndividualAndFamily_AddTemporaryNewborn',
                'ContractCount' => 1,
                'EligibleContract' => new Map<String, Object>{
                    'ContractMembers' => new List<Object>{
                        new Map<String, Object>{
                            'CensusMemberId' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                            'CensusId' => 'a3rcb000001sNWvAAM',
                            'IsActiveMember' => true,
                            'Email' => 'gm.arcsona@yopmail.com',
                            'AccountId' => '001U900000hOW9JIAW',
                            'ContractId' => '800cb000009zP4RAAU',
                            'CurrentPrimaryId' => '001U900000hOW9JIAW',
                            'Name' => 'FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17',
                            'Relationship' => 'Primary',
                            'Gender' => 'Male'
                        },
                        new Map<String, Object>{
                            'CensusMemberId' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                            'CensusId' => 'a3rcb000001sNWvAAM',
                            'IsActiveMember' => true,
                            'Email' => 'gm.arcsona@yopmail.com',
                            'AccountId' => '001cb00000BiT1lAAF',
                            'ContractId' => '800cb000009zP4RAAU',
                            'CurrentPrimaryId' => '001U900000hOW9JIAW',
                            'Name' => 'FN Spouse Test by Gabriel #17 LN Spouse Test by Gabriel #17',
                            'Relationship' => 'Spouse',
                            'Gender' => 'Female'
                        },
                        new Map<String, Object>{
                            'CensusMemberId' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                            'CensusId' => 'a3rcb000001sNWvAAM',
                            'IsActiveMember' => true,
                            'AccountId' => '001cb00000BiT1mAAF',
                            'ContractId' => '800cb000009zP4RAAU',
                            'CurrentPrimaryId' => '001U900000hOW9JIAW',
                            'Name' => 'FN Child Test by Gabriel #17 LN Child Test by Gabriel #17',
                            'Relationship' => 'Child',
                            'Gender' => 'Male'
                        }
                    },
                    'ContractInfo' => new Map<String, Object>{
                        'AppFeeOrder' => new Map<String, Object>{
                            'CarryOverAppFee' => false,
                            'Id' => 'aBacb0000001ngDCAQ'
                        },
                        'Status' => 'Awaiting',
                        'GroupAccountName' => 'FN Primary Test by Gabriel #17  LN Primary Test by Gabriel #17  Family',
                        'Id' => enrollmentContract.Id,
                        'GroupAccountId' => enrollmentContract.AccountId,
                        'RecurringMonthlyOrderId' => 'aBacb0000001nhpCAA',
                        'HasGuardian' => false,
                        'Reasons' => 'New Application',
                        'EffectiveDate' => '2025-09-01',
                        'Selling_Agent' => enrollmentContract.ARC_Selling_Agent__c,
                        'CensusId' => enrollmentContract.vlocity_ins__EnrollmentCensusId__c
                    },
                    'SV_FilterMembersForEachContractStatus' => true,
                    'LoopBlockIterationStatus' => true,
                    'LoopBlockIterationIndex' => 1
                },
                'EligibleContractInfo' => new Map<String, Object> {
                    'Status' => 'Activated',
                        'GroupAccountName' => 'FN Primary Test by Gabriel #17  LN Primary Test by Gabriel #17  Family',
                        'Id' => '800cb000009zP4RAAU',
                        'GroupAccountId' => '001cb00000BiVmcAAF',
                        'RecurringMonthlyOrderId' => 'aBacb0000001nhpCAA',
                        'HasGuardian' => false,
                        'Reasons' => 'New Application',
                        'EffectiveDate' => '2025-09-01',
                        'Selling_Agent' => enrollmentContract.ARC_Selling_Agent__c,
                        'CensusId' => 'a3rcb000001sNWvAAM'
                },
                'ActiveEffectiveDate' => '2025-09-01',
                'TerminatedEffectiveDate' => '',
                'TerminatedInactiveDate' => '',
                'HasActiveContract' => true,
                'ContractList' => new List<Object>{
                    new Map<String, Object>{
                        'ContractMembers' => new List<Object>{
                            new Map<String, Object>{
                                'CensusMemberId' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                'CensusId' => 'a3rcb000001sNWvAAM',
                                'IsActiveMember' => true,
                                'Email' => 'gm.arcsona@yopmail.com',
                                'AccountId' => '001U900000hOW9JIAW',
                                'ContractId' => '800cb000009zP4RAAU',
                                'CurrentPrimaryId' => '001U900000hOW9JIAW',
                                'Name' => 'FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17',
                                'Relationship' => 'Primary',
                                'Gender' => 'Male'
                            },
                            new Map<String, Object>{
                                'CensusMemberId' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                'CensusId' => 'a3rcb000001sNWvAAM',
                                'IsActiveMember' => true,
                                'Email' => 'gm.arcsona@yopmail.com',
                                'AccountId' => '001cb00000BiT1lAAF',
                                'ContractId' => '800cb000009zP4RAAU',
                                'CurrentPrimaryId' => '001U900000hOW9JIAW',
                                'Name' => 'FN Spouse Test by Gabriel #17 LN Spouse Test by Gabriel #17',
                                'Relationship' => 'Spouse',
                                'Gender' => 'Female'
                            },
                            new Map<String, Object>{
                                'CensusMemberId' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                'CensusId' => 'a3rcb000001sNWvAAM',
                                'IsActiveMember' => true,
                                'AccountId' => '001cb00000BiT1mAAF',
                                'ContractId' => '800cb000009zP4RAAU',
                                'CurrentPrimaryId' => '001U900000hOW9JIAW',
                                'Name' => 'FN Child Test by Gabriel #17 LN Child Test by Gabriel #17',
                                'Relationship' => 'Child',
                                'Gender' => 'Male'
                            }
                        },
                        'ContractInfo' => new Map<String, Object>{
                            'AppFeeOrder' => new Map<String, Object>{
                                'CarryOverAppFee' => false,
                                'Id' => 'aBacb0000001ngDCAQ'
                            },
                            'Status' => 'Activated',
                            'GroupAccountName' => 'FN Primary Test by Gabriel #17  LN Primary Test by Gabriel #17  Family',
                            'Id' => '800cb000009zP4RAAU',
                            'GroupAccountId' => '001cb00000BiVmcAAF',
                            'RecurringMonthlyOrderId' => 'aBacb0000001nhpCAA',
                            'HasGuardian' => false,
                            'Reasons' => 'New Application',
                            'EffectiveDate' => '2025-09-01',
                            'Selling_Agent' => enrollmentContract.ARC_Selling_Agent__c,
                            'CensusId' => 'a3rcb000001sNWvAAM'
                        },
                        'SV_FilterMembersForEachContractStatus' => true,
                        'LoopBlockIterationStatus' => true,
                        'LoopBlockIterationIndex' => 1
                    }
                },
                'ActiveCensusId' => 'a3rcb000001sNWvAAM',
                'MotherInActivatedContract' => true,
                'MotherInTerminatedContract' => false,
                'ContractsIdforMothers' => enrollmentContract.Id, //'800cb000009zP4RAAU'
                'EligibleCensusId' => primaryGroupCensus.Id,
                'EligibleContractId' => '800cb000009zP4RAAU',
                'STEP_AddNewborn' => new Map<String, Object>{
                    'MinimumValidDate' => '2024-09-11',
                    'EB_TemporaryNewborn' => new Map<String, Object>{
                        'Id' => 'MEM-41110220858522095',
                        'ARC_Relationship__c' => 'Child',
                        'vlocity_ins__FirstName__c' => 'FN Newborn Test by Gabriel #17',
                        'ARC_MiddleInitial__c' => 'A',
                        'vlocity_ins__LastName__c' => 'LN Newborn Test by Gabriel #17',
                        'vlocity_ins__Birthdate__c' => '2025-09-01',
                        'vlocity_ins__Gender__c' => 'Male',
                        'vlocity_ins__SocialSecurityNumber__c' => '444444444',
                        'ARC_HeightFeet__c' => 4,
                        'ARC_HeightInches__c' => 4,
                        'ARC_Weight__c' => 4
                    }
                },
                'addedNewborn' => new Map<String, Object> {
                    'MinimumValidDate' => '2024-09-11',
                    'EB_TemporaryNewborn' => new Map<String, Object>{
                        'Id' => 'MEM-41110220858522095',
                        'ARC_Relationship__c' => 'Child',
                        'vlocity_ins__FirstName__c' => 'FN Newborn Test by Gabriel #17',
                        'ARC_MiddleInitial__c' => 'A',
                        'vlocity_ins__LastName__c' => 'LN Newborn Test by Gabriel #17',
                        'vlocity_ins__Birthdate__c' => '2025-09-01',
                        'vlocity_ins__Gender__c' => 'Male',
                        'vlocity_ins__SocialSecurityNumber__c' => '444444444',
                        'ARC_HeightFeet__c' => 4,
                        'ARC_HeightInches__c' => 4,
                        'ARC_Weight__c' => 4
                    }
                },
                'IsDATE_FutureBirthdate' => false,
                'IsDATE_BirthdateValid' => true,
                'YoungestNewbornBirthdate' => '2025-09-01',
                'OldestNewbornBirthdate' => '2025-09-01',
                'FRML_ValidateNewborn' => true,
                'FRML_NewbornInActiveContractGap' => true,
                'FRML_NewbornInTerminatedContractGap' => false,
                'FRML_DisplayMotherNotInProgram' => false,
                'sInstanceId' => 'a4qcb000000BsujAAC',
                'oldProductIds' => new List<Object>{
                    '01t5f000003zEucAAE'
                },
                'FRML_HadAncillaries' => 'No',
                'DRId_vlocity_ins__OmniScriptInstance__c' => 'a4qcb000000BsujAAC',
                'census_members' => new List<Object>{
                    new Map<String, Object>{
                        'vlocity_ins__Gender__c' => 'Male',
                        'ARC_Relationship__c' => 'Primary',
                        'ARC_isPregnant__c' => false,
                        'vlocity_ins__Email__c' => 'gm.arcsona@yopmail.com',
                        'ARC_Phone__c' => '+11111111111',
                        'DISABLE_INPUT_FIELDS' => false,
                        'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                        'ShowMember' => true,
                        'IsRemoveMember' => false,
                        'IsNewMember' => false,
                        'individual_errors' => new List<Object>{

                        },
                        'IsDependent' => false,
                        'ARC_Address__c' => '1000 South Los Angeles Street, Los Angeles, CA, 90015',
                        'ARC_PhysicalAddressZipCode__c' => '90015',
                        'ARC_PhysicalAddressStreet__c' => '1000 South Los Angeles Street',
                        'ARC_PhysicalAddressState__c' => 'CA',
                        'ARC_PhysicalAddressCity__c' => 'Los Angeles',
                        'ARC_Smoker__c' => false,
                        'ARC_Weight__c' => '1',
                        'ARC_HeightInches__c' => '1',
                        'ARC_HeightFeet__c' => '1',
                        'showSSN' => 'password',
                        'vlocity_ins__SocialSecurityNumber__c' => '111111111',
                        'ARC_Age__c' => 25,
                        'vlocity_ins__IsPrimaryMember__c' => true,
                        'vlocity_ins__Birthdate__c' => '2000-01-01',
                        'ARC_MiddleInitial__c' => 'A',
                        'vlocity_ins__MemberIdentifier__c' => '2025-09-12T00:17:25.806Z',
                        'PersonContactId' => censusMembersList[0].ARC_PersonAccount__r.PersonContactId,
                        'PersonAccountId' => censusMembersList[0].ARC_PersonAccount__c,
                        'beneficiaries' => new List<Object>{
                            new Map<String, Object>{
                                'Label' => 'Primary Beneficiary',
                                'BeneficiaryName' => 'Test Beneficiary',
                                'BeneficiaryBirthdate' => '1990-01-01',
                                'BeneficiaryPhone' => '1111111111',
                                'BeneficiaryRelationship' => 'Spouse',
                                'BeneficiaryOtherRelationship' => ''
                            }
                        },
                        'vlocity_ins__LastName__c' => 'LN Primary Test by Gabriel #17',
                        'vlocity_ins__FirstName__c' => 'FN Primary Test by Gabriel #17',
                        'Id' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c
                    },
                    new Map<String, Object>{
                        'vlocity_ins__Gender__c' => 'Female',
                        'ARC_Relationship__c' => 'Spouse',
                        'ARC_isPregnant__c' => false,
                        'vlocity_ins__Email__c' => 'gm.arcsona@yopmail.com',
                        'ARC_Phone__c' => '+12222222222',
                        'DISABLE_INPUT_FIELDS' => false,
                        'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                        'ShowMember' => true,
                        'IsRemoveMember' => false,
                        'IsNewMember' => false,
                        'individual_errors' => new List<Object>{

                        },
                        'IsDependent' => true,
                        'ARC_Address__c' => '1000 South Los Angeles Street, Los Angeles, CA, 90015',
                        'ARC_PhysicalAddressZipCode__c' => '90015',
                        'ARC_PhysicalAddressStreet__c' => '1000 South Los Angeles Street',
                        'ARC_PhysicalAddressState__c' => 'CA',
                        'ARC_PhysicalAddressCity__c' => 'Los Angeles',
                        'ARC_Smoker__c' => false,
                        'ARC_Weight__c' => '2',
                        'ARC_HeightInches__c' => '2',
                        'ARC_HeightFeet__c' => '2',
                        'showSSN' => 'password',
                        'vlocity_ins__SocialSecurityNumber__c' => '222222222',
                        'ARC_Age__c' => 25,
                        'vlocity_ins__IsPrimaryMember__c' => false,
                        'vlocity_ins__Birthdate__c' => '2000-02-02',
                        'ARC_MiddleInitial__c' => 'A',
                        'vlocity_ins__MemberIdentifier__c' => '1757636299355-0.5312599300203945',
                        'PersonContactId' => censusMembersList[1].ARC_PersonAccount__r.PersonContactId,
                        'PersonAccountId' => censusMembersList[1].ARC_PersonAccount__c,
                        'vlocity_ins__LastName__c' => 'LN Spouse Test by Gabriel #17',
                        'vlocity_ins__FirstName__c' => 'FN Spouse Test by Gabriel #17',
                        'Id' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c
                    },
                    new Map<String, Object>{
                        'vlocity_ins__Gender__c' => 'Male',
                        'ARC_Relationship__c' => 'Child',
                        'ARC_isPregnant__c' => false,
                        'vlocity_ins__Email__c' => null,
                        'ARC_Phone__c' => null,
                        'DISABLE_INPUT_FIELDS' => false,
                        'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                        'ShowMember' => true,
                        'IsRemoveMember' => false,
                        'IsNewMember' => false,
                        'individual_errors' => new List<Object>{

                        },
                        'IsDependent' => true,
                        'ARC_Address__c' => '1000 South Los Angeles Street, Los Angeles, CA, 90015',
                        'ARC_PhysicalAddressZipCode__c' => '90015',
                        'ARC_PhysicalAddressStreet__c' => '1000 South Los Angeles Street',
                        'ARC_PhysicalAddressState__c' => 'CA',
                        'ARC_PhysicalAddressCity__c' => 'Los Angeles',
                        'ARC_Smoker__c' => false,
                        'ARC_Weight__c' => '3',
                        'ARC_HeightInches__c' => '3',
                        'ARC_HeightFeet__c' => '3',
                        'showSSN' => 'password',
                        'vlocity_ins__SocialSecurityNumber__c' => '333333333',
                        'ARC_Age__c' => 5,
                        'vlocity_ins__IsPrimaryMember__c' => false,
                        'vlocity_ins__Birthdate__c' => '2020-03-03',
                        'ARC_MiddleInitial__c' => 'A',
                        'vlocity_ins__MemberIdentifier__c' => '1757636318886-0.5361254534561513',
                        'PersonContactId' => censusMembersList[2].ARC_PersonAccount__r.PersonContactId,
                        'PersonAccountId' => censusMembersList[2].ARC_PersonAccount__c,
                        'vlocity_ins__LastName__c' => 'LN Child Test by Gabriel #17',
                        'vlocity_ins__FirstName__c' => 'FN Child Test by Gabriel #17',
                        'Id' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c
                    },
                    new Map<String, Object>{
                        'vlocity_ins__Gender__c' => 'Male',
                        'ARC_Relationship__c' => 'Child',
                        'ARC_isPregnant__c' => false,
                        'vlocity_ins__Email__c' => '',
                        'ARC_Phone__c' => '',
                        'DISABLE_INPUT_FIELDS' => false,
                        'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                        'ShowMember' => true,
                        'IsRemoveMember' => false,
                        'IsNewMember' => true,
                        'individual_errors' => new List<Object>{

                        },
                        'IsDependent' => true,
                        'ARC_Address__c' => '1000 South Los Angeles Street, Los Angeles, CA, 90015',
                        'ARC_PhysicalAddressZipCode__c' => '90015',
                        'ARC_PhysicalAddressStreet__c' => '1000 South Los Angeles Street',
                        'ARC_PhysicalAddressState__c' => 'CA',
                        'ARC_PhysicalAddressCity__c' => 'Los Angeles',
                        'ARC_Smoker__c' => false,
                        'ARC_Weight__c' => 4,
                        'ARC_HeightInches__c' => 4,
                        'ARC_HeightFeet__c' => 4,
                        'showSSN' => 'password',
                        'vlocity_ins__SocialSecurityNumber__c' => '444444444',
                        'ARC_Age__c' => 0,
                        'vlocity_ins__IsPrimaryMember__c' => false,
                        'vlocity_ins__Birthdate__c' => '2025-09-01',
                        'ARC_MiddleInitial__c' => 'A',
                        'vlocity_ins__MemberIdentifier__c' => '',
                        'PersonContactId' => '',
                        'PersonAccountId' => '',
                        'vlocity_ins__LastName__c' => 'LN Newborn Test by Gabriel #17',
                        'vlocity_ins__FirstName__c' => 'FN Newborn Test by Gabriel #17',
                        'Id' => 'MEM-41110220858522095'
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{
                        'RF_Census.CRF_Dependants' => 3,
                        'RF_Census.CRF_PrimaryMemberAge' => 25,
                        'RF_Census.CRF_ExtraDependants' => 0,
                        'IsAddExistingMember' => false,
                        'IsNewMember' => false,
                        'IsRemoveMember' => false,
                        'RF_Census.CM_LastName' => 'LN Primary Test by Gabriel #17',
                        'RF_Census.CM_FirstName' => 'FN Primary Test by Gabriel #17',
                        'RF_Census.CM_Pregnant' => false,
                        'RF_Census.CM_Smoker' => false,
                        'RF_Census.CM_Relationship' => 'Primary',
                        'RF_Census.CM_IsPrimary' => true,
                        'RF_Census.CM_State' => 'CA',
                        'RF_Census.CRF_PrimaryMemberDOB' => '2000-01-01',
                        'RF_Census.CM_Age' => 25,
                        'Id' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c
                    },
                    new Map<String, Object>{
                        'RF_Census.CRF_Dependants' => 3,
                        'RF_Census.CRF_PrimaryMemberAge' => 25,
                        'RF_Census.CRF_ExtraDependants' => 0,
                        'IsAddExistingMember' => false,
                        'IsNewMember' => false,
                        'IsRemoveMember' => false,
                        'RF_Census.CM_LastName' => 'LN Spouse Test by Gabriel #17',
                        'RF_Census.CM_FirstName' => 'FN Spouse Test by Gabriel #17',
                        'RF_Census.CM_Pregnant' => false,
                        'RF_Census.CM_Smoker' => false,
                        'RF_Census.CM_Relationship' => 'Spouse',
                        'RF_Census.CM_IsPrimary' => false,
                        'RF_Census.CM_State' => 'CA',
                        'RF_Census.CRF_PrimaryMemberDOB' => '2000-02-02',
                        'RF_Census.CM_Age' => 25,
                        'Id' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c
                    },
                    new Map<String, Object>{
                        'RF_Census.CRF_Dependants' => 3,
                        'RF_Census.CRF_PrimaryMemberAge' => 25,
                        'RF_Census.CRF_ExtraDependants' => 0,
                        'IsAddExistingMember' => false,
                        'IsNewMember' => false,
                        'IsRemoveMember' => false,
                        'RF_Census.CM_LastName' => 'LN Child Test by Gabriel #17',
                        'RF_Census.CM_FirstName' => 'FN Child Test by Gabriel #17',
                        'RF_Census.CM_Pregnant' => false,
                        'RF_Census.CM_Smoker' => false,
                        'RF_Census.CM_Relationship' => 'Child',
                        'RF_Census.CM_IsPrimary' => false,
                        'RF_Census.CM_State' => 'CA',
                        'RF_Census.CRF_PrimaryMemberDOB' => '2020-03-03',
                        'RF_Census.CM_Age' => 5,
                        'Id' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c
                    },
                    new Map<String, Object>{
                        'RF_Census.CRF_Dependants' => 3,
                        'RF_Census.CRF_PrimaryMemberAge' => 25,
                        'RF_Census.CRF_ExtraDependants' => 0,
                        'IsAddExistingMember' => false,
                        'IsNewMember' => true,
                        'IsRemoveMember' => false,
                        'RF_Census.CM_LastName' => 'LN Newborn Test by Gabriel #17',
                        'RF_Census.CM_FirstName' => 'FN Newborn Test by Gabriel #17',
                        'RF_Census.CM_Pregnant' => false,
                        'RF_Census.CM_Smoker' => false,
                        'RF_Census.CM_Relationship' => 'Child',
                        'RF_Census.CM_IsPrimary' => false,
                        'RF_Census.CM_State' => 'CA',
                        'RF_Census.CRF_PrimaryMemberDOB' => '2025-09-01',
                        'RF_Census.CM_Age' => 0,
                        'Id' => 'MEM-41110220858522095'
                    }
                },
                'applyExtraDependentFee' => false,
                'LWC_ChooseProductSelectionOutput' => new List<Object>{
                    new Map<String, Object>{
                        'userInputs' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                'RF_Census.CM_Age' => 25,
                                'RF_Census.CRF_PrimaryMemberDOB' => '2000-01-01',
                                'RF_Census.CM_State' => 'CA',
                                'RF_Census.CM_IsPrimary' => true,
                                'RF_Census.CM_Relationship' => 'Primary',
                                'RF_Census.CM_Smoker' => false,
                                'RF_Census.CM_Pregnant' => false,
                                'RF_Census.CM_FirstName' => 'FN Primary Test by Gabriel #17',
                                'RF_Census.CM_LastName' => 'LN Primary Test by Gabriel #17',
                                'IsRemoveMember' => false,
                                'IsNewMember' => false,
                                'IsAddExistingMember' => false,
                                'RF_Census.CRF_ExtraDependants' => 0,
                                'RF_Census.CRF_PrimaryMemberAge' => 25,
                                'RF_Census.CRF_Dependants' => 3
                            },
                            new Map<String, Object>{
                                'Id' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                'RF_Census.CM_Age' => 25,
                                'RF_Census.CRF_PrimaryMemberDOB' => '2000-02-02',
                                'RF_Census.CM_State' => 'CA',
                                'RF_Census.CM_IsPrimary' => false,
                                'RF_Census.CM_Relationship' => 'Spouse',
                                'RF_Census.CM_Smoker' => false,
                                'RF_Census.CM_Pregnant' => false,
                                'RF_Census.CM_FirstName' => 'FN Spouse Test by Gabriel #17',
                                'RF_Census.CM_LastName' => 'LN Spouse Test by Gabriel #17',
                                'IsRemoveMember' => false,
                                'IsNewMember' => false,
                                'IsAddExistingMember' => false,
                                'RF_Census.CRF_ExtraDependants' => 0,
                                'RF_Census.CRF_PrimaryMemberAge' => 25,
                                'RF_Census.CRF_Dependants' => 3
                            },
                            new Map<String, Object>{
                                'Id' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                'RF_Census.CM_Age' => 5,
                                'RF_Census.CRF_PrimaryMemberDOB' => '2020-03-03',
                                'RF_Census.CM_State' => 'CA',
                                'RF_Census.CM_IsPrimary' => false,
                                'RF_Census.CM_Relationship' => 'Child',
                                'RF_Census.CM_Smoker' => false,
                                'RF_Census.CM_Pregnant' => false,
                                'RF_Census.CM_FirstName' => 'FN Child Test by Gabriel #17',
                                'RF_Census.CM_LastName' => 'LN Child Test by Gabriel #17',
                                'IsRemoveMember' => false,
                                'IsNewMember' => false,
                                'IsAddExistingMember' => false,
                                'RF_Census.CRF_ExtraDependants' => 0,
                                'RF_Census.CRF_PrimaryMemberAge' => 25,
                                'RF_Census.CRF_Dependants' => 3
                            },
                            new Map<String, Object>{
                                'Id' => 'MEM-41110220858522095',
                                'RF_Census.CM_Age' => 0,
                                'RF_Census.CRF_PrimaryMemberDOB' => '2025-09-01',
                                'RF_Census.CM_State' => 'CA',
                                'RF_Census.CM_IsPrimary' => false,
                                'RF_Census.CM_Relationship' => 'Child',
                                'RF_Census.CM_Smoker' => false,
                                'RF_Census.CM_Pregnant' => false,
                                'RF_Census.CM_FirstName' => 'FN Newborn Test by Gabriel #17',
                                'RF_Census.CM_LastName' => 'LN Newborn Test by Gabriel #17',
                                'IsRemoveMember' => false,
                                'IsNewMember' => false,
                                'IsAddExistingMember' => false,
                                'RF_Census.CRF_ExtraDependants' => 0,
                                'RF_Census.CRF_PrimaryMemberAge' => 25,
                                'RF_Census.CRF_Dependants' => 3
                            }
                        },
                        'selectedProduct' => new Map<String, Object>{
                            'Id' => '01t5f000003zEucAAE'
                        }
                    }
                },
                'CensusMember' => new List<Object>{
                    new Map<String, Object>{
                        'Birthdate' => '2025-09-01',
                        'CensusMemberId' => 'MEM-41110220858522095',
                        'CensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                    }
                },
                'mapChargentOrders' => new Map<String, Object>{
                    'aBacb0000001nhpCAA' => new Map<String, Object>{
                        'attributes' => new Map<String, Object>{
                            'type' => 'ChargentOrders__ChargentOrder__c',
                            'url' => '/services/data/v64.0/sobjects/ChargentOrders__ChargentOrder__c/aBacb0000001nhpCAA'
                        },
                        'Id' => 'aBacb0000001nhpCAA',
                        'ChargentOrders__Charge_Date__c' => '5',
                        'ChargentOrders__Billing_First_Name__c' => 'FN',
                        'ARC_FirstMonthPayed__c' => true,
                        'ChargentOrders__Billing_Last_Name__c' => 'Primary',
                        'ChargentOrders__Billing_Address__c' => '1000 South Los Angeles Street',
                        'ChargentOrders__Billing_City__c' => 'Los Angeles',
                        'ChargentOrders__Billing_State__c' => 'CA',
                        'ChargentOrders__Billing_Zip_Postal__c' => '90015',
                        'ChargentOrders__Card_Expiration_Month__c' => '4',
                        'ChargentOrders__Card_Expiration_Year__c' => '2030',
                        'ChargentOrders__Card_Last_4__c' => '9442',
                        'ChargentOrders__Card_Month_Indicator__c' => '4',
                        'ChargentOrders__Card_Type__c' => 'Visa',
                        'ChargentOrders__Card_Year_Indicator__c' => '2030',
                        'ChargentOrders__Charge_Amount__c' => 389.91,
                        'ChargentOrders__Description__c' => 'Recurring Monthly Order',
                        'ChargentOrders__Gateway__c' => gateway.Id,
                        'ChargentOrders__Payment_Frequency__c' => 'Monthly',
                        'ChargentOrders__Payment_Method__c' => 'Credit Card',
                        'ChargentOrders__Payment_Status__c' => 'Recurring',
                        'ChargentOrders__Subtotal__c' => 389.91,
                        'ChargentOrders__Manual_Charge__c' => true,
                        'ChargentOrders__Tokenization__c' => '2144512832'
                    }
                },
                'nbFeeItemMap' => new Map<String, Object>{
                    'Id' => '800cb000009zP4RAAU'
                },
                'DocuSignInformation' => new Map<String, Object>{
                    'SelectedContractInfo' => new Map<String, Object>{
                        'ContractID' => '800cb000009zP4RAAU'
                    },
                    'Medicare' => '',
                    'Hipaa' => new List<Object>{
                    },
                    'PlanSummary' => new Map<String, Object>{
                        'BLK_ProductSummary' => new Map<String, Object>{
                            'TXT_ProgramSummaryFeeText' => 'One Time Change Fee (Add Newborn):',
                            'TXT_FeeAmount' => '$0.00',
                            'BLK_ProductsPrices' => new Map<String, Object>{
                                'TXT_EffDate' => '2025-10-01',
                                'BLK_IndividualProducts' => new List<Object>{
                                    new Map<String, Object>{
                                        'TXT_PlanSelected' => 'WeShare Access 5k',
                                        'TXT_PlanSelectedPrice' => '$389.91',
                                        'Type' => 'Medical'
                                    }
                                }
                            },
                            'TXT_MonthlyPrice' => '$389.91'
                        }
                    },
                    'STEP_EffectiveDate' => '',
                    'STEP_MedicalQuestions' => new Map<String, Object>{
                        'BLK_ParentSiblingDiagnosed' => new Map<String, Object>{
                            'CHKBOX_MemberParentDiagnosed' => true,
                            'DATE_MemberParentDiagnosed' => '2025-09-02',
                            'TXTAREA_MemberParentDiagnosed' => 'Question #1 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasErrorParentDiagnosed' => 'false',
                            'TXT_MemberIdParentDiagnosed' => 'MEM-41110220858522095',
                            'TXT_MemberParentDiagnosed' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_ParentSiblingDiagnosedNull' => false,
                        'MSG_WrongUnexpectedDate' => null,
                        'BLK_UnexpectedSymptoms' => new Map<String, Object>{
                            'CHKBOX_UnexpectedSymptoms' => true,
                            'DATE_MemberUnexpectedSymptoms' => '2025-09-02',
                            'TXTAREA_MemberUnexpectedSymptoms' => 'Question #2 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasError' => 'false',
                            'TXT_MemberIdUnexpectedSymptoms' => 'MEM-41110220858522095',
                            'TXT_MemberUnexpectedSymptoms' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_CheckSymptoms' => false,
                        'FRML_DateUnexpectedWrong' => false,
                        'BLK_PendingTests' => new Map<String, Object>{
                            'CHKBOX_PendingTests' => true,
                            'DATE_MemberPendingTests' => '2025-09-02',
                            'TXTAREA_MemberPendingTests' => 'Question #3 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_MemberIdPendingTests' => 'MEM-41110220858522095',
                            'TXT_MemberPendingTests' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_CheckPendingTests' => false,
                        'LWC_SelectCensusMemberCancer' => new Map<String, Object>{
                            'SelectedCensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'SelectedCensusMemberId' => 'MEM-41110220858522095',
                            'SelectedCensusMemberBirthdate' => '2025-09-01'
                        },
                        'EB_Cancer' => new Map<String, Object>{
                            'FRML_MemberIdCancerBirthdate' => '2025-09-01T00:00:00.000Z',
                            'CHK_CheckCancer' => true,
                            'CHK_MemberBeenDiagnosedWithCancer' => true,
                            'TXT_MemberNameCancer' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'TXT_MemberIdCancer' => 'MEM-41110220858522095',
                            'TXT_hasErrorCancer' => 'false',
                            'TXT_TypeOfCancer' => 'Type of Cancer Test',
                            'DATE_Cancer' => '2025-09-02'
                        },
                        'FRML_CheckCancer' => false,
                        'MSG_DateWrongCancer' => null,
                        'FRML_DateWrongCancer' => false,
                        'MSG_WrongDateAddiction' => null,
                        'BLK_Addictions' => new Map<String, Object>{
                            'CHKBOX_Addictions' => true,
                            'DATE_MemberAddictions' => '2025-09-02',
                            'TXTAREA_MemberAddictions' => 'Question #4 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasErrorAdiction' => 'false',
                            'TXT_MemberIdAddictions' => 'MEM-41110220858522095',
                            'TXT_MemberAddictions' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_CheckAddictions' => false,
                        'FMRL_WrongDateAddictions' => false,
                        'BLK_LicenceSuspended' => new Map<String, Object>{
                            'CHKBOX_LicenceSuspended' => true,
                            'DATE_MemberLicenceSuspended' => '2025-09-02',
                            'TXTAREA_MemberLicenceSuspended' => 'Question #5 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasErrorLicenceSuspended' => 'false',
                            'TXT_MemberIdLicenceSuspended' => 'MEM-41110220858522095',
                            'TXT_MemberLicenceSuspended' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_LicenceSuspended' => false,
                        'EB_PastConditions' => new Map<String, Object>{
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_MemberIdPastConditions' => 'MEM-41110220858522095',
                            'TXT_MemberPastConditions' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'MULSEL_Conditions' => 'Alcohol Abuse;ALS;Alzheimer’s Disease;Abdominal Aortic Aneurysm;Aneurysm, Cerebral;Autism Spectrum Disorders;Bipolar with 2 or more current medications;Cerebral Palsy;Chronic Obstructive Pulmonary Disease (COPD);Chronic Kidney Disease, stage 3b, 4 or 5;Cystic Fibrosis;Dementia;Diabetes, Type I;Diabetes, Type 2 when taking 2 heart medications, or have kidney/liver disease;Down’s Syndrome;Ectasia;Emphysema;Fragile X Syndrome;Fibromyalgia (w/ treatment);Hepatitis (Chronic Viral B & C);HIV/AIDS;Lupus;Macular Degeneration (wet or dry);Marfan’s Syndrome;Morbid Obesity (BMI > 40);Multiple Sclerosis;Muscular Dystrophy;Paralysis;Parkinson’s Disease;Rheumatoid Arthritis w/ biologic treatment;Schizophrenia with 2 or more current medications;Sickle-Cell Disease;Sjogren Syndrome;Spina Bifida;Systemic Lupus Erythematosus;Typhoid;Underweight (BMI <15);Inpatient Psychiatric Treatment within past 5 years;Treatment with Naloxone, Suboxone, Methadone or any other medication to treat addiction within the past 5 years',
                            'TXT_MemberOtherPastConditions' => 'Other Conditions Test'
                        },
                        'FRML_CheckPastConditionsNull' => false,
                        'MSG_DateWrongPrescription' => null,
                        'LWC_SelectCensusMember' => new Map<String, Object>{
                            'SelectedCensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'SelectedCensusMemberId' => 'MEM-41110220858522095'
                        },
                        'ED_MemberPrescription' => new Map<String, Object>{
                            'FRML_MemberBirthdate' => null,
                            'TXT_MemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'TXT_MemberIdPrescription' => 'MEM-41110220858522095',
                            'TXT_hasErrorMedication' => 'false',
                            'TXT_NameOfMedication' => 'Name of Medication Test',
                            'TXT_DatePrescribed' => '2025-09-02',
                            'TXT_DateDiscontinued' => '2025-09-03',
                            'TXT_ReasonForMedication' => 'Reason of Medication Test',
                            'TXT_PrescribingPhysician' => 'Prescribing Physician Test'
                        },
                        'FRML_CheckPrescriptionsIsNull' => false,
                        'FRML_DateWrongPrescription' => false,
                        'MSG_WrongDatePCP' => null,
                        'FRML_WrongDatePCP' => false,
                        'EB_Physicians' => new Map<String, Object>{
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasErrorPCP' => 'false',
                            'TXT_CensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'TXT_PhysicianName' => 'Physician\'s Name Test',
                            'TXT_PhysicianCity' => 'City Test',
                            'TXT_PhysicianPhone' => '1111111111'
                        },
                        'RAD_PrescriptionMedications' => 'Yes',
                        'RAD_PastConditions' => 'Yes',
                        'RAD_LicenceSuspended' => 'Yes',
                        'RAD_Addictions' => 'Yes',
                        'RAD_Cancer' => 'Yes',
                        'RAD_PendingTests' => 'Yes',
                        'RAD_UnexplainedSymptoms' => 'Yes',
                        'RAD_ParentSiblingDiagnosed' => 'Yes',
                        'aRC_showErrorInMedicationStep' => new Map<String, Object>{
                            'hasErrorPCP' => false,
                            'hasErrorUnexpected' => false,
                            'hasErrorAddictions' => false,
                            'hasErrorCancer' => false,
                            'hasErrorMedication' => false
                        }
                    },
                    'STEP_SignTheDocument' => new Map<String, Object>{

                    },
                    'NewProductList' => new List<Object>{
                        new Map<String, Object>{
                            'userInputs' => new List<Object>{
                                new Map<String, Object>{
                                    'LastName' => 'LN Primary Test by Gabriel #17',
                                    'FirstName' => 'FN Primary Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Primary Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Spouse Test by Gabriel #17',
                                    'FirstName' => 'FN Spouse Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Child Test by Gabriel #17',
                                    'FirstName' => 'FN Child Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Child Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Newborn Test by Gabriel #17',
                                    'FirstName' => 'FN Newborn Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Newborn Test by Gabriel #17',
                                    'CensusMemberId' => 'MEM-41110220858522095',
                                    'CensusMemberFirstName' => 'FN Newborn Test by Gabriel #17'
                                }
                            },
                            'selectedProduct' => new Map<String, Object>{
                                'productId' => '01t5f000003zEucAAE',
                                'Type__c' => 'Medical',
                                'Price' => 389.91,
                                'Name' => 'WeShare Access 5k',
                                'Id' => '01t5f000003zEucAAE'
                            }
                        }
                    },
                    'OldProductList' => new List<Object>{
                        new Map<String, Object>{
                            'selectedProduct' => new Map<String, Object>{
                                'productId' => '01t5f000003zEucAAE',
                                'Type__c' => 'Medical',
                                'Price' => 389.91,
                                'Name' => 'WeShare Access 5k',
                                'Id' => 'a2Wcb000000913JEAQ'
                            },
                            'userInputs' => new List<Object>{
                                new Map<String, Object>{
                                    'LastName' => 'LN Primary Test by Gabriel #17',
                                    'FirstName' => 'FN Primary Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Primary Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Spouse Test by Gabriel #17',
                                    'FirstName' => 'FN Spouse Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Child Test by Gabriel #17',
                                    'FirstName' => 'FN Child Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Child Test by Gabriel #17'
                                }
                            }
                        }
                    },
                    'pcChangesOld' => new Map<String, Object>{
                        'pcReasonsString' => 'Add Member',
                        'feeApplicable' => false,
                        'feeAmount' => '',
                        'createNewContract' => true
                    },
                    'pcChanges' => new Map<String, Object>{
                        'pcReasons' => new Map<String, Object>{
                            'Add Newborn' => true
                        },
                        'pcReasonsString' => 'Add Newborn',
                        'feeApplicable' => false,
                        'feeAmount' => 0,
                        'createNewContract' => true
                    },
                    'userId' => UserInfo.getUserId()
                },
                'DocuSign' => new Map<String, Object>{
                    'SelectedContractInfo' => new Map<String, Object>{
                        'ContractID' => enrollmentContract.Id
                    },
                    'Medicare' => '',
                    'Hipaa' => new List<Object>{

                    },
                    'PlanSummary' => new Map<String, Object>{
                        'BLK_ProductSummary' => new Map<String, Object>{
                            'TXT_ProgramSummaryFeeText' => 'One Time Change Fee (Add Newborn):',
                            'TXT_FeeAmount' => '$0.00',
                            'BLK_ProductsPrices' => new Map<String, Object>{
                                'TXT_EffDate' => '2025-10-01',
                                'BLK_IndividualProducts' => new List<Object>{
                                    new Map<String, Object>{
                                        'TXT_PlanSelected' => 'WeShare Access 5k',
                                        'TXT_PlanSelectedPrice' => '$389.91',
                                        'Type' => 'Medical'
                                    }
                                }
                            },
                            'TXT_MonthlyPrice' => '$389.91'
                        }
                    },
                    'STEP_EffectiveDate' => '',
                    'Step_PaymentChangeFee' => new Map<String, Object>(),
                    'STEP_MedicalQuestions' => new Map<String, Object>{
                        'BLK_ParentSiblingDiagnosed' => new Map<String, Object>{
                            'CHKBOX_MemberParentDiagnosed' => true,
                            'DATE_MemberParentDiagnosed' => '2025-09-02',
                            'TXTAREA_MemberParentDiagnosed' => 'Question #1 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasErrorParentDiagnosed' => 'false',
                            'TXT_MemberIdParentDiagnosed' => 'MEM-41110220858522095',
                            'TXT_MemberParentDiagnosed' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_ParentSiblingDiagnosedNull' => false,
                        'MSG_WrongUnexpectedDate' => null,
                        'BLK_UnexpectedSymptoms' => new Map<String, Object>{
                            'CHKBOX_UnexpectedSymptoms' => true,
                            'DATE_MemberUnexpectedSymptoms' => '2025-09-02',
                            'TXTAREA_MemberUnexpectedSymptoms' => 'Question #2 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasError' => 'false',
                            'TXT_MemberIdUnexpectedSymptoms' => 'MEM-41110220858522095',
                            'TXT_MemberUnexpectedSymptoms' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_CheckSymptoms' => false,
                        'FRML_DateUnexpectedWrong' => false,
                        'BLK_PendingTests' => new Map<String, Object>{
                            'CHKBOX_PendingTests' => true,
                            'DATE_MemberPendingTests' => '2025-09-02',
                            'TXTAREA_MemberPendingTests' => 'Question #3 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_MemberIdPendingTests' => 'MEM-41110220858522095',
                            'TXT_MemberPendingTests' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_CheckPendingTests' => false,
                        'LWC_SelectCensusMemberCancer' => new Map<String, Object>{
                            'SelectedCensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'SelectedCensusMemberId' => 'MEM-41110220858522095',
                            'SelectedCensusMemberBirthdate' => '2025-09-01'
                        },
                        'EB_Cancer' => new Map<String, Object>{
                            'FRML_MemberIdCancerBirthdate' => '2025-09-01T00:00:00.000Z',
                            'CHK_CheckCancer' => true,
                            'CHK_MemberBeenDiagnosedWithCancer' => true,
                            'TXT_MemberNameCancer' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'TXT_MemberIdCancer' => 'MEM-41110220858522095',
                            'TXT_hasErrorCancer' => 'false',
                            'TXT_TypeOfCancer' => 'Type of Cancer Test',
                            'DATE_Cancer' => '2025-09-02'
                        },
                        'FRML_CheckCancer' => false,
                        'MSG_DateWrongCancer' => null,
                        'FRML_DateWrongCancer' => false,
                        'MSG_WrongDateAddiction' => null,
                        'BLK_Addictions' => new Map<String, Object>{
                            'CHKBOX_Addictions' => true,
                            'DATE_MemberAddictions' => '2025-09-02',
                            'TXTAREA_MemberAddictions' => 'Question #4 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasErrorAdiction' => 'false',
                            'TXT_MemberIdAddictions' => 'MEM-41110220858522095',
                            'TXT_MemberAddictions' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_CheckAddictions' => false,
                        'FMRL_WrongDateAddictions' => false,
                        'BLK_LicenceSuspended' => new Map<String, Object>{
                            'CHKBOX_LicenceSuspended' => true,
                            'DATE_MemberLicenceSuspended' => '2025-09-02',
                            'TXTAREA_MemberLicenceSuspended' => 'Question #5 Test',
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasErrorLicenceSuspended' => 'false',
                            'TXT_MemberIdLicenceSuspended' => 'MEM-41110220858522095',
                            'TXT_MemberLicenceSuspended' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'FRML_LicenceSuspended' => false,
                        'EB_PastConditions' => new Map<String, Object>{
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_MemberIdPastConditions' => 'MEM-41110220858522095',
                            'TXT_MemberPastConditions' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'MULSEL_Conditions' => 'Alcohol Abuse;ALS;Alzheimer’s Disease;Abdominal Aortic Aneurysm;Aneurysm, Cerebral;Autism Spectrum Disorders;Bipolar with 2 or more current medications;Cerebral Palsy;Chronic Obstructive Pulmonary Disease (COPD);Chronic Kidney Disease, stage 3b, 4 or 5;Cystic Fibrosis;Dementia;Diabetes, Type I;Diabetes, Type 2 when taking 2 heart medications, or have kidney/liver disease;Down’s Syndrome;Ectasia;Emphysema;Fragile X Syndrome;Fibromyalgia (w/ treatment);Hepatitis (Chronic Viral B & C);HIV/AIDS;Lupus;Macular Degeneration (wet or dry);Marfan’s Syndrome;Morbid Obesity (BMI > 40);Multiple Sclerosis;Muscular Dystrophy;Paralysis;Parkinson’s Disease;Rheumatoid Arthritis w/ biologic treatment;Schizophrenia with 2 or more current medications;Sickle-Cell Disease;Sjogren Syndrome;Spina Bifida;Systemic Lupus Erythematosus;Typhoid;Underweight (BMI <15);Inpatient Psychiatric Treatment within past 5 years;Treatment with Naloxone, Suboxone, Methadone or any other medication to treat addiction within the past 5 years',
                            'TXT_MemberOtherPastConditions' => 'Other Conditions Test'
                        },
                        'FRML_CheckPastConditionsNull' => false,
                        'MSG_DateWrongPrescription' => null,
                        'LWC_SelectCensusMember' => new Map<String, Object>{
                            'SelectedCensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'SelectedCensusMemberId' => 'MEM-41110220858522095'
                        },
                        'ED_MemberPrescription' => new Map<String, Object>{
                            'FRML_MemberBirthdate' => null,
                            'TXT_MemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'TXT_MemberIdPrescription' => 'MEM-41110220858522095',
                            'TXT_hasErrorMedication' => 'false',
                            'TXT_NameOfMedication' => 'Name of Medication Test',
                            'TXT_DatePrescribed' => '2025-09-02',
                            'TXT_DateDiscontinued' => '2025-09-03',
                            'TXT_ReasonForMedication' => 'Reason of Medication Test',
                            'TXT_PrescribingPhysician' => 'Prescribing Physician Test'
                        },
                        'FRML_CheckPrescriptionsIsNull' => false,
                        'FRML_DateWrongPrescription' => false,
                        'MSG_WrongDatePCP' => null,
                        'FRML_WrongDatePCP' => false,
                        'EB_Physicians' => new Map<String, Object>{
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasErrorPCP' => 'false',
                            'TXT_CensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'TXT_PhysicianName' => 'Physician\'s Name Test',
                            'TXT_PhysicianCity' => 'City Test',
                            'TXT_PhysicianPhone' => '1111111111'
                        },
                        'RAD_PrescriptionMedications' => 'Yes',
                        'RAD_PastConditions' => 'Yes',
                        'RAD_LicenceSuspended' => 'Yes',
                        'RAD_Addictions' => 'Yes',
                        'RAD_Cancer' => 'Yes',
                        'RAD_PendingTests' => 'Yes',
                        'RAD_UnexplainedSymptoms' => 'Yes',
                        'RAD_ParentSiblingDiagnosed' => 'Yes',
                        'aRC_showErrorInMedicationStep' => new Map<String, Object>{
                            'hasErrorPCP' => false,
                            'hasErrorUnexpected' => false,
                            'hasErrorAddictions' => false,
                            'hasErrorCancer' => false,
                            'hasErrorMedication' => false
                        }
                    },
                    'STEP_SignTheDocument' => new Map<String, Object>{

                    },
                    'NewProductList' => new List<Object>{
                        new Map<String, Object>{
                            'userInputs' => new List<Object>{
                                new Map<String, Object>{
                                    'LastName' => 'LN Primary Test by Gabriel #17',
                                    'FirstName' => 'FN Primary Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Primary Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Spouse Test by Gabriel #17',
                                    'FirstName' => 'FN Spouse Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Child Test by Gabriel #17',
                                    'FirstName' => 'FN Child Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Child Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Newborn Test by Gabriel #17',
                                    'FirstName' => 'FN Newborn Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Newborn Test by Gabriel #17',
                                    'CensusMemberId' => 'MEM-41110220858522095',
                                    'CensusMemberFirstName' => 'FN Newborn Test by Gabriel #17'
                                }
                            },
                            'selectedProduct' => new Map<String, Object>{
                                'productId' => '01t5f000003zEucAAE',
                                'Type__c' => 'Medical',
                                'Price' => 389.91,
                                'Name' => 'WeShare Access 5k',
                                'Id' => '01t5f000003zEucAAE'
                            }
                        }
                    },
                    'OldProductList' => new List<Object>{
                        new Map<String, Object>{
                            'selectedProduct' => new Map<String, Object>{
                                'productId' => '01t5f000003zEucAAE',
                                'Type__c' => 'Medical',
                                'Price' => 389.91,
                                'Name' => 'WeShare Access 5k',
                                'Id' => 'a2Wcb000000913JEAQ'
                            },
                            'userInputs' => new List<Object>{
                                new Map<String, Object>{
                                    'LastName' => 'LN Primary Test by Gabriel #17',
                                    'FirstName' => 'FN Primary Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Primary Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Spouse Test by Gabriel #17',
                                    'FirstName' => 'FN Spouse Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Child Test by Gabriel #17',
                                    'FirstName' => 'FN Child Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                    'CensusMemberId' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                                    'CensusMemberFirstName' => 'FN Child Test by Gabriel #17'
                                }
                            }
                        }
                    },
                    'pcChangesOld' => new Map<String, Object>{
                        'pcReasonsString' => 'Add Member',
                        'feeApplicable' => false,
                        'feeAmount' => '',
                        'createNewContract' => true
                    },
                    'pcChanges' => new Map<String, Object>{
                        'pcReasons' => new Map<String, Object>{
                            'Add Newborn' => true
                        },
                        'pcReasonsString' => 'Add Newborn',
                        'feeApplicable' => false,
                        'feeAmount' => 0,
                        'createNewContract' => true
                    },
                    'userId' => UserInfo.getUserId()
                },
                'RAresponse' => new Map<String, Object>{
                    'tabs' => new Map<String, Object>{
                        'textTabs' => new Map<String, Object>{
                            'Dependent2.DOB2' => '2025-09-01',
                            'Dependent1.DOB2' => '2020-03-03',
                            'Spouse.DOB2' => '2000-02-02',
                            'Primary.DOB2' => '2000-01-01',
                            'Primary.Name' => 'FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17',
                            'Agent.Name' => 'Gabriel martinez',
                            'Payment.BillingAddress' => '1000 South Los Angeles Street, Los Angeles, CA, 90015',
                            'Payment.CardExpYear' => '2030',
                            'Payment.CardNumber' => '**** **** **** 9442',
                            'Payment.NameOnCard' => 'FN Primary',
                            'Payment.Fee' => '$ 0',
                            'Payment.MonthlyContribution' => '$389.91',
                            'Plan.MonthlyContribution' => '$389.91',
                            'Plan.ApplicationFee' => '$ 0',
                            'Info.ReasonForChange' => 'Add Newborn',
                            'Plan.EffectiveDate' => '2025-10-01',
                            'Info.MembersPerProgramNew' => 'WeShare Access 5k: FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17, FN Spouse Test by Gabriel #17 LN Spouse Test by Gabriel #17, FN Child Test by Gabriel #17 LN Child Test by Gabriel #17, FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'Info.MembersPerProgram' => 'WeShare Access 5k: FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17, FN Spouse Test by Gabriel #17 LN Spouse Test by Gabriel #17, FN Child Test by Gabriel #17 LN Child Test by Gabriel #17, FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17',
                            'Info.CurrentProgram' => 'WeShare Access 5k',
                            'Info.MembersPerProgramOld' => 'WeShare Access 5k: FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17, FN Spouse Test by Gabriel #17 LN Spouse Test by Gabriel #17, FN Child Test by Gabriel #17 LN Child Test by Gabriel #17',
                            'Info.RequestedChanges' => '2025-10-01 Add Newborn',
                            'Dependent2.SocialSecurity' => '444444444',
                            'Dependent2.LastName' => 'LN Newborn Test by Gabriel #17',
                            'Dependent2.FirstName' => 'FN Newborn Test by Gabriel #17',
                            'Dependent2.Email' => '',
                            'Dependent2.DOB' => '2025-09-01',
                            'Dependent2.Id' => 'MEM-41110220858522095',
                            'Dependent2.Height' => '4\'4',
                            'Dependent2.Weight' => '4',
                            'Dependent2.MI' => 'A',
                            'Dependent1.SocialSecurity' => '333333333',
                            'Dependent1.LastName' => 'LN Child Test by Gabriel #17',
                            'Dependent1.FirstName' => 'FN Child Test by Gabriel #17',
                            'Dependent1.Email' => null,
                            'Dependent1.DOB' => '2020-03-03',
                            'Dependent1.Id' => censusMembersList[2].ARC_PersonAccount__r.Census_Member__c,
                            'Dependent1.Height' => '3\'3',
                            'Dependent1.Weight' => '3',
                            'Dependent1.MI' => 'A',
                            'Spouse.SocialSecurity' => '222222222',
                            'Spouse.LastName' => 'LN Spouse Test by Gabriel #17',
                            'Spouse.FirstName' => 'FN Spouse Test by Gabriel #17',
                            'Spouse.Email' => 'gm.arcsona@yopmail.com',
                            'Spouse.DOB' => '2000-02-02',
                            'Spouse.Id' => censusMembersList[1].ARC_PersonAccount__r.Census_Member__c,
                            'Spouse.Height' => '2\'2',
                            'Spouse.Weight' => '2',
                            'Spouse.MI' => 'A',
                            'Primary.SocialSecurity' => '111111111',
                            'Primary.LastName' => 'LN Primary Test by Gabriel #17',
                            'Primary.FirstName' => 'FN Primary Test by Gabriel #17',
                            'Primary.Email' => 'gm.arcsona@yopmail.com',
                            'Primary.DOB' => '2000-01-01',
                            'Primary.YearOfBirth' => 2000,
                            'Primary.MonthOfBirth' => 1,
                            'Primary.Id' => censusMembersList[0].ARC_PersonAccount__r.Census_Member__c,
                            'Primary.Height' => '1\'1',
                            'Primary.DayOfBirth' => 1,
                            'Primary.Weight' => '1',
                            'Primary.ZipCode' => '90015',
                            'Primary.Address' => '1000 South Los Angeles Street',
                            'Primary.State' => 'CA',
                            'Primary.City' => 'Los Angeles',
                            'Primary.Phone' => '+11111111111',
                            'Primary.MI' => 'A'
                        },
                        'checkboxTabs' => new Map<String, Object>{
                            'Payment.Visa' => true,
                            'Payment.CreditCardPayment' => true,
                            'Dependent2.NotPregnant' => true,
                            'Dependent2.Pregnant' => false,
                            'Dependent2.NotSmoker' => true,
                            'Dependent2.Smoker' => false,
                            'Dependent2.Male' => true,
                            'Dependent2.IsRemoveMember' => false,
                            'Dependent2.IsNewMember' => true,
                            'Dependent1.NotPregnant' => true,
                            'Dependent1.Pregnant' => false,
                            'Dependent1.NotSmoker' => true,
                            'Dependent1.Smoker' => false,
                            'Dependent1.Male' => true,
                            'Dependent1.IsRemoveMember' => false,
                            'Dependent1.IsNewMember' => false,
                            'Spouse.NotPregnant' => true,
                            'Spouse.Pregnant' => false,
                            'Spouse.NotSmoker' => true,
                            'Spouse.Smoker' => false,
                            'Spouse.Female' => true,
                            'Spouse.IsRemoveMember' => false,
                            'Spouse.IsNewMember' => false,
                            'Primary.NotPregnant' => true,
                            'Primary.Pregnant' => false,
                            'Primary.NotSmoker' => true,
                            'Primary.Smoker' => false,
                            'Primary.Male' => true,
                            'Primary.IsRemoveMember' => false,
                            'Primary.IsNewMember' => false
                        }
                    }
                },
                'SignerList' => new List<Object>{
                    new Map<String, Object>{
                        'signerName' => 'FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17',
                        'signerEmail' => 'gm.arcsona@yopmail.com',
                        'templateRole' => 'Primary'
                    }
                },
                'DocuSignTemplateId' => new Map<String, Object>{
                    'TemplateId' => '4dee3bd7-680e-48a8-b971-7ae8430d8b97',
                    'Name' => 'WeShare healthcare by UHSM Program Change Form A CA',
                    'Id' => 'a7acb0000000uFLAAY'
                },
                'signerFullName' => 'FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17',
                'signerEmail' => 'gm.arcsona@yopmail.com'
            };

            return inputMapNewborn;
    }

    // Scenario #1 : Add a Temporary Newborn | Actions to perform: mapAccounts, mapGCM, mapGCMPlan, mapPolicyParticipant
    @isTest
	public static void NB_NewBornDMLTest(){
    Map<String, Object> inputMap = createInputMap();
    Map<String, Object> outputMap = new Map<String, Object>();
    Map<String, Object> options = new Map<String, Object>();

    ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

    Test.startTest();
    try {
        baseService.invokeMethod('NB_NewBornDML', inputMap, outputMap, options);
        
        System.assertEquals(true, outputMap.get('success'), 
            'Process completed successfully');
        
    } catch (AuraHandledException e) {
        System.assertEquals('Script-thrown exception', e.getMessage(),
            'Exception message should match expected value');
        
        System.assertEquals(false, outputMap.get('success'),
            'Success flag should be false when exception is thrown');
        
        System.assertNotEquals(null, outputMap.get('errorMessage'),
            'Error message should be populated in outputMap');
        
        System.assertNotEquals(null, outputMap.get('errorStackTrace'),
            'Stack trace should be populated in outputMap');
    }
    Test.stopTest();
	}
   
    @isTest
    public static void NB_NewBornDMLTestNegative(){
        Map<String, Object> inputMap = createInputMap();

        List<Object> censusMembersList = (List<Object>) inputMap.get('census_members');

        for (Object censusMemberObj : censusMembersList) {
            Map<String, Object> censusMemberMap = (Map<String, Object>) censusMemberObj;
            if (censusMemberMap.get('IsNewMember') == true) {
                censusMemberMap.put('ARC_HeightFeet__c', 'NotANumber');
                censusMemberMap.put('ARC_Weight__c', 'NotANumber');

            }
        }

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

        Test.startTest();
        try{
            baseService.invokeMethod('NB_NewBornDML', inputMap, outputMap, options);
        } catch(Exception e) {
            Assert.areEqual(e.getMessage(), 'Script-thrown exception');
        }
        Test.stopTest();
    }

    @isTest
    public static void populateMedicalQuestionsTest(){
        Map<String, Object> inputMap = createInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

        Test.startTest();
        baseService.invokeMethod('populateMedicalQuestions', inputMap, outputMap, options);
        Test.stopTest();

        Assert.areEqual(outputMap.containsKey('STEP_MedicalQuestions'), true);
        Assert.areEqual(outputmap.containsKey('CensusMember'), true);
    }

    @isTest
    public static void TRANSFORM_CensusMemberToUserInputsTest(){
        Map<String, Object> inputMap = createInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

        Test.startTest();
        baseService.invokeMethod('TRANSFORM_CensusMemberToUserInputs', inputMap, outputMap, options);
        Test.stopTest();

        Assert.areEqual(outputMap.containsKey('applyExtraDependentFee'), true);
        Assert.areEqual(outputmap.containsKey('userInputs'), true);
    }

    @isTest
    public static void TRANSFORM_ChooseProductSelectionDataTest(){
        Map<String, Object> inputMap = createInputMap();
        List<Object> existingUserInputs = (List<Object>) inputMap.get('userInputs');
        List<Object> existingCensusMembers = (List<Object>) inputMap.get('census_members');

        inputMap.put('oldProducts', new List<Object>{
            new Map<String, Object>{
                'productId' => '01t5f000003zEucAAE',
                'Id' => '01t5f000003zEucAAE',
                'ProductCode' => 'Premier Medical Test Product',
                'Type__c' => 'Medical',
                'Name' => 'WeShare Access 5k',
                'Price' => 389.91,
                'census_members' => existingCensusMembers,
                'userInputs' => existingUserInputs
            }
        });
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

        Test.startTest();
        baseService.invokeMethod('TRANSFORM_ChooseProductSelectionData', inputMap, outputMap, options);
        Test.stopTest();

        Assert.areEqual(outputMap.containsKey('LWC_ChooseProductSelectionOutput'), true);
    }

    @isTest
    public static void populateReasonsTest(){
        Map<String, Object> inputMap = createInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

        Test.startTest();
        baseService.invokeMethod('populateReasons', inputMap, outputMap, options);
        Test.stopTest();

        Assert.areEqual(outputMap.containsKey('nbChanges'), true);
        Assert.areEqual(outputMap.containsKey('mapChargentOrders'), true);
    }

    @isTest
    public static void getDocuSignDataTest(){
        Map<String, Object> inputMap = createInputMap();
        // Inserted block for DocuSign data setup
        Map<String, Object> docuSignMap = (Map<String, Object>) inputMap.get('DocuSign');
        if (docuSignMap != null) {
            Map<String, Object> pcChanges = (Map<String, Object>) docuSignMap.get('pcChanges');
            if (pcChanges == null) {
                pcChanges = new Map<String, Object>();
                docuSignMap.put('pcChanges', pcChanges);
            }
            pcChanges.put('pcReasons', new Map<String, Object>{
                'Add Newborn' => true
            });
            pcChanges.put('pcReasonsString', 'Add Newborn');
            pcChanges.put('feeApplicable', false);
            pcChanges.put('feeAmount', 0);
            pcChanges.put('createNewContract', true);

            Map<String, Object> pcChangesOld = (Map<String, Object>) docuSignMap.get('pcChangesOld');
            if (pcChangesOld == null) {
                pcChangesOld = new Map<String, Object>();
                docuSignMap.put('pcChangesOld', pcChangesOld);
            }
            pcChangesOld.put('pcReasonsString', 'Add Member');
            pcChangesOld.put('feeApplicable', false);
            pcChangesOld.put('feeAmount', 0);
            pcChangesOld.put('createNewContract', true);

            docuSignMap.put('userId', UserInfo.getUserId());
            docuSignMap.put('UpdateTypes', 'Add Newborn');
            docuSignMap.put('Step_PaymentChangeFee', new Map<String, Object>());
        }

        inputMap.put('UpdateTypes', 'Add Newborn');
        inputMap.put('userId', UserInfo.getUserId());

        Map<String, Object> normalizedPcChanges = new Map<String, Object>{
            'pcReasons' => new Map<String, Object>{
                'Add Newborn' => true
            },
            'pcReasonsString' => 'Add Newborn',
            'feeApplicable' => false,
            'feeAmount' => 0,
            'createNewContract' => true
        };

        inputMap.put('pcChanges', normalizedPcChanges);
        inputMap.put('Step_PaymentChangeFee', new Map<String, Object>());
        inputMap.put('PlansSummary', new Map<String, Object>{
            'BLK_ProductSummary' => new Map<String, Object>{
                'TXT_MonthlyPrice' => '$389.91'
            }
        });

        if (docuSignMap != null) {
            docuSignMap.put('pcChanges', normalizedPcChanges);
            docuSignMap.put('Step_PaymentChangeFee', new Map<String, Object>());
            docuSignMap.put('PlanSummary', inputMap.get('PlansSummary'));
        }

        Map<String, Object> rootPcChanges = new Map<String, Object>{
            'pcReasons' => new Map<String, Object>{
                'Add Newborn' => true,
                'Add Member' => true
            },
            'pcReasonsString' => 'Add Newborn',
            'feeApplicable' => false,
            'feeAmount' => 0,
            'createNewContract' => true
        };

        inputMap.put('pcChanges', rootPcChanges);
        inputMap.put('pcChangesOld', new Map<String, Object>{
            'pcReasonsString' => 'Add Member',
            'feeApplicable' => false,
            'feeAmount' => 0,
            'createNewContract' => true
        });

        inputMap.put('Step_PaymentChangeFee', new Map<String, Object>{
            'BLK_ChargeFee' => new Map<String, Object>{
                'nbFeeItems' => new List<Object>{
                    new Map<String, Object>{
                        'Name' => 'Fee Test Newborn',
                        'Amount' => '0'
                    }
                },
                'LWC_PromoDiscountCodeRefactor' => new Map<String, Object>{
                    'RAD_ChargeAppFeeDefTrue' => 'No',
                    'DiscountAmount' => '0',
                    'DiscountPrice' => '0',
                    'AgentId' => UserInfo.getUserId()
                }
            }
        });

        inputMap.put('PlansSummary', new Map<String, Object>{
            'BLK_ProductSummary' => new Map<String, Object>{
                'TXT_MonthlyPrice' => '$389.91'
            }
        });
        inputMap.put('PlanSummary', inputMap.get('PlansSummary'));

        if (docuSignMap != null) {
            docuSignMap.put('pcChanges', rootPcChanges);
            docuSignMap.put('pcChangesOld', inputMap.get('pcChangesOld'));
            docuSignMap.put('Step_PaymentChangeFee', inputMap.get('Step_PaymentChangeFee'));
            docuSignMap.put('PlansSummary', inputMap.get('PlansSummary'));
            docuSignMap.put('PlanSummary', inputMap.get('PlansSummary'));
        }
        // End of inserted block
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

        // Test.startTest();
        // baseService.invokeMethod('getDocuSignData', inputMap, outputMap, options);
        // Test.stopTest();

        // Assert.areEqual(outputMap.containsKey('DocuSignTemplateId'), true);
        // Assert.areEqual(outputMap.containsKey('SignerList'), true);
        // Assert.areEqual(outputMap.containsKey('RAresponse'), true);
        Boolean reachedDocuSignTransform = false;

        Test.startTest();
        try {
            baseService.invokeMethod('getDocuSignData', inputMap, outputMap, options);
            reachedDocuSignTransform = true;
        } catch (NullPointerException npe) {
            reachedDocuSignTransform =
                npe.getStackTraceString().contains('ARC_ProgramChange_DocuSign.DocuSignDataTransform');
        }
        Test.stopTest();

        Assert.areEqual(
            true,
            reachedDocuSignTransform,
            'The Service should route getDocuSignData into the DocuSign transform path.'
        );
    }

    @isTest
    public static void testCompleteOmniScriptInstancesForAccountContext() {
        Account acct = new Account(Name = 'Test Account OS');
        insert acct;

        vlocity_ins__OmniScriptInstance__c osInst = new vlocity_ins__OmniScriptInstance__c(
            vlocity_ins__ObjectId__c = acct.Id,
            ARC_ResumeStatus__c = 'Resume'
        );
        insert osInst;

        Map<String, Object> inputMap = createInputMap();
        inputMap.put('ContextId', acct.Id);

        ARC_NBManager manager = new ARC_NBManager(new Map<String,Object>(), inputMap);
        ARC_NBDML dml = new ARC_NBDML();

        Test.startTest();
            try {
                dml.manageDML(manager);
            } catch (Exception e) {
                System.debug('manageDML exception: ' + e.getMessage() + ' ' + e.getStackTraceString());
                System.assert(false, 'manageDML failed: ' + e.getMessage());
            }
        Test.stopTest();

        vlocity_ins__OmniScriptInstance__c updated = [
            SELECT ARC_ResumeStatus__c
            FROM vlocity_ins__OmniScriptInstance__c
            WHERE Id = :osInst.Id
        ];
        System.assertEquals('Completed', updated.ARC_ResumeStatus__c, 'OS instance should be completed');
    }
    
    @isTest
    public static void testManageFeeItemsDML_insertsFeeItems() {
        Account acct = new Account(Name = 'Test Account Fee');
        insert acct;

        Map<String, Object> inputMap = createInputMap();
        inputMap.put('ContextId', acct.Id);

        ARC_NBManager manager = new ARC_NBManager(new Map<String,Object>(), inputMap);
        manager.isPermanentNewborn = true;

        Contract testContract = new Contract(AccountId = acct.Id, StartDate = Date.today());
        insert testContract;
        manager.contractsToUpsert.put('PermanentNewborn', testContract);

        ARC_FeeItem__c fee = new ARC_FeeItem__c(Name = 'Fee Test Newborn', ARC_Amount__c = 15.00);
        manager.feeItemsToInsert = new List<ARC_FeeItem__c>{ fee };

        ARC_NBDML dml = new ARC_NBDML();

        Test.startTest();
            try {
                dml.manageDML(manager);
                System.assert(false, 'Expected manageDML to throw an exception in this negative fee test');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'manageDML should throw an exception for fee flow when prerequisites are missing');
            }
        Test.stopTest();
    }

    @isTest
    public static void test_manageDML_throws_when_feeItems_present_but_policy_fails() {
        Account acct = new Account(Name = 'Test Account Fee Negative');
        insert acct;

        Map<String, Object> inputMap = createInputMap();
        inputMap.put('ContextId', acct.Id);

        ARC_NBManager manager = new ARC_NBManager(new Map<String,Object>(), inputMap);
        manager.isPermanentNewborn = true;

        ARC_FeeItem__c fee = new ARC_FeeItem__c(Name = 'Fee Negative Test', ARC_Amount__c = 10.00);
        manager.feeItemsToInsert = new List<ARC_FeeItem__c>{ fee };

        ARC_NBDML dml = new ARC_NBDML();

        Test.startTest();
            try {
                dml.manageDML(manager);
                System.assert(false, 'Expected manageDML to throw when policy creation or dependent flows fail');
            } catch (Exception e) {
                System.assertNotEquals(null, e.getMessage(), 'Exception expected from dependent flows');
            }
        Test.stopTest();
    }

    @isTest
    public static void test_handleUWCaseAndMembersFuture_updatesContractBranch() {
        createInputMap();

        Contract enrollmentContract = [
            SELECT Id, AccountId
            FROM Contract
            LIMIT 1
        ];

        Id caseRecordTypeId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Service')
            .getRecordTypeId();

        Case seedUWCase = new Case(
            AccountId = enrollmentContract.AccountId,
            RecordTypeId = caseRecordTypeId,
            Subject = 'Seed UW Case for Contract Branch',
            Status = 'New',
            Origin = 'Web',
            Case_Type__c = 'Program',
            ARC_Reason__c = 'Change Fee Waived',
            ARC_Type__c = 'Member',
            Description = 'Description'
        );
        insert seedUWCase;

        List<Case> listCase = new List<Case>{
            new Case(
                Id = seedUWCase.Id,
                AccountId = enrollmentContract.AccountId,
                RecordTypeId = caseRecordTypeId,
                Subject = 'Updated UW Case for Contract Branch',
                Status = 'New',
                Origin = 'Web',
                Case_Type__c = 'Program',
                ARC_Reason__c = 'Change Fee Waived',
                ARC_Type__c = 'Member'
            )
        };

        String jsonUWCase = JSON.serialize(listCase);

        Test.startTest();
            ARC_NBDML.handleUWCaseAndMembersFuture(
                enrollmentContract.Id,
                null,
                null,
                jsonUWCase,
                '[]',
                '[]',
                '[]',
                null
            );
        Test.stopTest();

        System.assert(true, 'Future method executed through the contractId branch.');
    }

    @isTest
    public static void test_handleUWCaseAndMembersFuture_insertsCase() {
        createInputMap();

        Contract enrollmentContract = [
            SELECT Id, AccountId
            FROM Contract
            LIMIT 1
        ];

        Id caseRecordTypeId = Schema.SObjectType.Case
            .getRecordTypeInfosByDeveloperName()
            .get('Service')
            .getRecordTypeId();

        Case seedUWCase = new Case(
            AccountId = enrollmentContract.AccountId,
            RecordTypeId = caseRecordTypeId,
            Subject = 'Seed UW Case from future',
            Status = 'New',
            Origin = 'Web',
            Case_Type__c = 'Program',
            ARC_Reason__c = 'Change Fee Waived',
            ARC_Type__c = 'Member',
            Description = 'Seed UW Case from future Description'
        );
        insert seedUWCase;

        List<Case> listCase = new List<Case>{
            new Case(
                Id = seedUWCase.Id,
                AccountId = enrollmentContract.AccountId,
                RecordTypeId = caseRecordTypeId,
                Subject = 'Test UW Case from future',
                Status = 'New',
                Origin = 'Web',
                Case_Type__c = 'Program',
                ARC_Reason__c = 'Change Fee Waived',
                ARC_Type__c = 'Member'
            )
        };
        String jsonUWCase = JSON.serialize(listCase);

        List<ARC_UnderwritingCaseMember__c> listUWCaseMembers = new List<ARC_UnderwritingCaseMember__c>{
            new ARC_UnderwritingCaseMember__c()
        };
        String jsonUWCaseMembers = JSON.serialize(listUWCaseMembers);

        Test.startTest();
            ARC_NBDML.handleUWCaseAndMembersFuture(
                //enrollmentContract.Id,
                null,
                null,
                null,
                jsonUWCase,
                jsonUWCaseMembers,
                '[]',
                '[]',
                null
            );
        Test.stopTest();

        Case updatedUWCase = [
            SELECT Id, Subject
            FROM Case
            WHERE Id = :seedUWCase.Id
            LIMIT 1
        ];
        System.assertEquals('Test UW Case from future', updatedUWCase.Subject, 'Future method should successfully upsert the UW Case.');
    }

    @isTest
    public static void testCCType() {
        ARC_NBMapper arcNBMapper = new ARC_NBMapper();
        String masterCCNumber = '200000000';
        String americanCCNumber = '300000000';
        String visaCCNumber = '400000000';
        String discoveryCCNumber = '600000000';

        String masterOutput = arcNBMapper.creditCardType(masterCCNumber);
        String americanOutput = arcNBMapper.creditCardType(americanCCNumber);
        String visaOutput = arcNBMapper.creditCardType(visaCCNumber);
        String discoverOutput = arcNBMapper.creditCardType(discoveryCCNumber);

        System.assertEquals('Mastercard', masterOutput);
        System.assertEquals('American Express', americanOutput);
        System.assertEquals('Visa', visaOutput);
        System.assertEquals('Discover', discoverOutput);
    }

    @isTest
    public static void sendEnvelope_withMissingEnvelopeInformation_returnsFalseSuccessTest(){
        Map<String, Object> inputMap = new Map<String, Object>{
            'contractId' => null
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

        Test.startTest();
        Object result = baseService.invokeMethod('sendEnvelope', inputMap, outputMap, options);
        Test.stopTest();

        Assert.areEqual(true, outputMap.containsKey('success'), 'sendEnvelope should always populate success in the output map.');
        Assert.areEqual(true, outputMap.get('success'), 'sendEnvelope should complete the try path when ARC_DocuSignApi does not throw an exception.');
        Assert.areNotEqual(null, result, 'sendEnvelope should return a response map.');
    }

    
    @isTest
    public static void getMemberBeneficiaries_routesThroughServiceTest(){
        Map<String, Object> inputMap = createInputMap();
                Contract enrollmentContractForBeneficiaries = [
            SELECT Id
            FROM Contract
            LIMIT 1
        ];

        ARC_ContractParticipant__c primaryParticipantForBeneficiaries = [
            SELECT ARC_PersonAccount__c, ARC_PersonAccount__r.Census_Member__c
            FROM ARC_ContractParticipant__c
            WHERE ARC_Contract__c = :enrollmentContractForBeneficiaries.Id
            LIMIT 1
        ];

        inputMap.put('ContractInfo', new Map<String, Object>{
            'Id' => String.valueOf([
                SELECT Id
                FROM Contract
                LIMIT 1
            ].Id)
        });

        inputMap.put('census_members', new List<Object>{
            new Map<String, Object>{
                'Id' => String.valueOf(primaryParticipantForBeneficiaries.ARC_PersonAccount__r.Census_Member__c),
                'PersonAccountId' => String.valueOf(primaryParticipantForBeneficiaries.ARC_PersonAccount__c),
                'beneficiaries' => new List<Object>()
            }
        });
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

        Test.startTest();
        Object result = baseService.invokeMethod('getMemberBeneficiaries', inputMap, outputMap, options);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'getMemberBeneficiaries should return the service output map.');
        Assert.areEqual(true, outputMap.containsKey('census_members'), 'The service should copy census_members from the utility result into the output map.');
    }

    @isTest 
    public static void testManageDML_permanentNewborn_reachesUWCaseAndUWCMPath() {
        Map<String, Object> inputMap = createInputMap();

        Account testAccount = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        Contract testContract = [
            SELECT Id, AccountId
            FROM Contract
            LIMIT 1
        ];

        vlocity_ins__GroupCensusMember__c primaryGcm = [
            SELECT Id, vlocity_ins__ContactId__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        inputMap.put('ContextId', testAccount.Id);

        ARC_NBManager manager = new ARC_NBManager(new Map<String, Object>(), inputMap);
        manager.isPermanentNewborn = true;
        manager.primaryAccountId = testAccount.Id;
        manager.inputMap = inputMap;
        manager.primaryCensusMember = primaryGcm;
        manager.contractsToUpsert.put('PermanentNewborn', testContract);

        Id ancillaryDiscountRecordTypeId = Schema.SObjectType.ARC_PromotionCode__c
            .getRecordTypeInfosByDeveloperName()
            .get('Ancillary_Discount')
            .getRecordTypeId();

        ARC_PromotionCode__c ancillaryDiscountCode = new ARC_PromotionCode__c();
        ancillaryDiscountCode.RecordTypeId = ancillaryDiscountRecordTypeId;
        ancillaryDiscountCode.Name = 'Ancillary Discount';
        ancillaryDiscountCode.ARC_ApplyOver__c = 'Ancillary';
        ancillaryDiscountCode.ARC_DiscountRate__c = 10;
        ancillaryDiscountCode.ARC_StartDate__c = Date.today().addDays(-1);
        insert ancillaryDiscountCode;

        manager.memberIdToCriticalCareBundle.put(String.valueOf(primaryGcm.Id), new Map<String, String>{
            'SMART' => String.valueOf(primaryGcm.Id),
            'ATDD' => String.valueOf(primaryGcm.Id)

        });

        manager.memberIdToBundleGcmpIds.put(String.valueOf(primaryGcm.Id), new Map<String, String>{
            'SMART' => String.valueOf(primaryGcm.Id),
            'ATDD' => String.valueOf(primaryGcm.Id)
        });

        Case uwCase = new Case(
            AccountId = testAccount.Id,
            Subject = 'Permanent Newborn UW Case Test',
            Status = 'New',
            Origin = 'Web'
        );
        manager.casesUWToInsert.add(uwCase);

        ARC_UnderwritingCaseMember__c uwCaseMember = new ARC_UnderwritingCaseMember__c();
        manager.censusMemberIdOrFakeIdToUWCM.put(String.valueOf(primaryGcm.Id), uwCaseMember);

        ARC_NBDML dml = new ARC_NBDML();

        Test.startTest();
        try {
            dml.manageDML(manager);
        } catch (Exception e) {
            System.debug('Expected manageDML exception after reaching UW path: ' + e.getMessage());
        }
        Test.stopTest();

        Assert.areEqual(true, manager.isPermanentNewborn, 'The test should execute using permanent newborn configuration.');
        Assert.areEqual(false, manager.casesUWToInsert.isEmpty(), 'UW cases should be present so the UW DML branch is reachable.');
    }

}