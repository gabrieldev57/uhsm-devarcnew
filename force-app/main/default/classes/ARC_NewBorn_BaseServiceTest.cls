@isTest
public with sharing class ARC_NewBorn_BaseServiceTest {

    private static Map<String, Object> createInputMap(){
        Map<String, Object> inputMapNewborn = new Map<String, Object>{
                'execute_reprice_flag' => false,
                'EffectiveDate' => '2025-10-01',
                'plans' => new List<Object>{
                    new Map<String, Object>{
                        'userInputs' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => 'a3qcb00000C5tLJAAZ',
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
                                'Id' => 'a3qcb00000C5ihSAAR',
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
                                'Id' => 'a3qcb00000C5ihTAAR',
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
                                'IsNewMember' => true,
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
                                'CensusMemberId' => 'a3qcb00000C5tLJAAZ',
                                'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'LastName' => 'LN Spouse Test by Gabriel #17',
                                'FirstName' => 'FN Spouse Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                'CensusMemberId' => 'a3qcb00000C5ihSAAR',
                                'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'LastName' => 'LN Child Test by Gabriel #17',
                                'FirstName' => 'FN Child Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                'CensusMemberId' => 'a3qcb00000C5ihTAAR',
                                'CensusMemberFirstName' => 'FN Child Test by Gabriel #17'
                            }
                        }
                    }
                },
                'oldProducts' => new List<Object>{
                    new Map<String, Object>{
                        'census_members' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => 'a3qcb00000C5tLJAAZ',
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
                                'Id' => 'a3qcb00000C5ihSAAR',
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
                                'Id' => 'a3qcb00000C5ihTAAR',
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
                                'CensusMemberId' => 'a3qcb00000C5tLJAAZ',
                                'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'LastName' => 'LN Spouse Test by Gabriel #17',
                                'FirstName' => 'FN Spouse Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                'CensusMemberId' => 'a3qcb00000C5ihSAAR',
                                'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                            },
                            new Map<String, Object>{
                                'LastName' => 'LN Child Test by Gabriel #17',
                                'FirstName' => 'FN Child Test by Gabriel #17',
                                'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                'CensusMemberId' => 'a3qcb00000C5ihTAAR',
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
                                            'Id' => '01tRm000000GGDjIAO',
                                            'Name' => 'Preventative Care',
                                            'ProductCode' => 'ARC_UHSMPreventativeCare',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => '01tRm000000GGDjIAO',
                                            'pciId' => 'a5rcb00000019yzAAA'
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
                                            'productId' => '01tRm000000GGDiIAO',
                                            'pciId' => 'a5rcb00000019z0AAA'
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 3,
                                            'Id' => '01tRm000000GGDhIAO',
                                            'Name' => 'Physician Services',
                                            'ProductCode' => 'ARC_UHSMPhysicianServices',
                                            'Type__c' => 'Medical',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'CoverageSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'isSelected' => true,
                                            'productId' => '01tRm000000GGDhIAO',
                                            'pciId' => 'a5rcb00000019yvAAA'
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
                                            'productId' => '01tRm000000GGC5IAO',
                                            'pciId' => 'a5rcb00000019yxAAA'
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
                                            'pciId' => 'a5rcb00000019yyAAA'
                                        },
                                        new Map<String, Object>{
                                            'displaySequence' => 1,
                                            'Id' => '01t5f000003xhf2AAA',
                                            'Name' => 'Census',
                                            'ProductCode' => 'RF_Census',
                                            'IsRecommended__c' => false,
                                            'RecordTypeName__c' => 'RatingFactSpec',
                                            'IsConfigurable__c' => true,
                                            'Term__c' => 'Annual',
                                            'isOptional' => false,
                                            'productId' => '01t5f000003xhf2AAA',
                                            'pciId' => 'a5rcb00000019ywAAA'
                                        }
                                    }
                                }
                            },
                            'userInputs' => new List<Object>{
                                new Map<String, Object>{
                                    'Id' => 'a3qcb00000C5tLJAAZ',
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
                                    'Id' => 'a3qcb00000C5ihSAAR',
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
                                    'Id' => 'a3qcb00000C5ihTAAR',
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
                                    'IsNewMember' => true,
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
                    'feeApplicable' => false,
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
                'ContextId' => '001cb00000BiT1nAAF',
                'userProfile' => 'System Administrator',
                'timeStamp' => '2025-09-12T00:32:32.295Z',
                'userTimeZoneName' => 'America/Los_Angeles',
                'userTimeZone' => '-420',
                'userCurrencyCode' => 'USD',
                'userName' => 'gabriel.martinez@arcsona.comuhsm.dev25',
                'userId' => '005cb000006lvU2AAI',
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
                    'BLK_ParentSiblingDiagnosed' => null,
                    'FRML_ParentSiblingDiagnosedNull' => false,
                    'MSG_WrongUnexpectedDate' => null,
                    'BLK_UnexpectedSymptoms' => null,
                    'FRML_CheckSymptoms' => false,
                    'FRML_DateUnexpectedWrong' => false,
                    'BLK_PendingTests' => null,
                    'FRML_CheckPendingTests' => false,
                    'LWC_SelectCensusMemberCancer' => null,
                    'EB_Cancer' => null,
                    'FRML_CheckCancer' => false,
                    'MSG_DateWrongCancer' => null,
                    'FRML_DateWrongCancer' => false,
                    'MSG_WrongDateAddiction' => null,
                    'BLK_Addictions' => null,
                    'FRML_CheckAddictions' => false,
                    'FMRL_WrongDateAddictions' => false,
                    'BLK_LicenceSuspended' => null,
                    'FRML_LicenceSuspended' => false,
                    'EB_PastConditions' => null,
                    'FRML_CheckPastConditionsNull' => false,
                    'MSG_DateWrongPrescription' => null,
                    'LWC_SelectCensusMember' => null,
                    'ED_MemberPrescription' => null,
                    'FRML_CheckPrescriptionsIsNull' => false,
                    'FRML_DateWrongPrescription' => false,
                    'MSG_WrongDatePCP' => null,
                    'FRML_WrongDatePCP' => false,
                    'EB_Physicians' => new Map<String, Object>{
                        'memberId' => 'MEM-41110220858522095',
                        'TXT_hasErrorPCP' => 'false',
                        'TXT_CensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                    },
                    'RAD_PrescriptionMedications' => 'No',
                    'RAD_PastConditions' => 'No',
                    'RAD_LicenceSuspended' => 'No',
                    'RAD_Addictions' => 'No',
                    'RAD_Cancer' => 'No',
                    'RAD_PendingTests' => 'No',
                    'RAD_UnexplainedSymptoms' => 'No',
                    'RAD_ParentSiblingDiagnosed' => 'No',
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
                            'CensusMemberId' => 'a3qcb00000C5tLJAAZ',
                            'CensusId' => 'a3rcb000001sNWvAAM',
                            'IsActiveMember' => true,
                            'Email' => 'gm.arcsona@yopmail.com',
                            'AccountId' => '001cb00000BiT1nAAF',
                            'ContractId' => '800cb000009zP4RAAU',
                            'CurrentPrimaryId' => '001cb00000BiT1nAAF',
                            'Name' => 'FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17',
                            'Relationship' => 'Primary',
                            'Gender' => 'Male'
                        },
                        new Map<String, Object>{
                            'CensusMemberId' => 'a3qcb00000C5ihSAAR',
                            'CensusId' => 'a3rcb000001sNWvAAM',
                            'IsActiveMember' => true,
                            'Email' => 'gm.arcsona@yopmail.com',
                            'AccountId' => '001cb00000BiT1lAAF',
                            'ContractId' => '800cb000009zP4RAAU',
                            'CurrentPrimaryId' => '001cb00000BiT1nAAF',
                            'Name' => 'FN Spouse Test by Gabriel #17 LN Spouse Test by Gabriel #17',
                            'Relationship' => 'Spouse',
                            'Gender' => 'Female'
                        },
                        new Map<String, Object>{
                            'CensusMemberId' => 'a3qcb00000C5ihTAAR',
                            'CensusId' => 'a3rcb000001sNWvAAM',
                            'IsActiveMember' => true,
                            'AccountId' => '001cb00000BiT1mAAF',
                            'ContractId' => '800cb000009zP4RAAU',
                            'CurrentPrimaryId' => '001cb00000BiT1nAAF',
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
                        'Selling_Agent' => '005cb000006lvU2AAI',
                        'CensusId' => 'a3rcb000001sNWvAAM'
                    },
                    'SV_FilterMembersForEachContractStatus' => true,
                    'LoopBlockIterationStatus' => true,
                    'LoopBlockIterationIndex' => 1
                },
                'ActiveEffectiveDate' => '2025-09-01',
                'TerminatedEffectiveDate' => '',
                'TerminatedInactiveDate' => '',
                'HasActiveContract' => true,
                'ContractList' => new List<Object>{
                    new Map<String, Object>{
                        'ContractMembers' => new List<Object>{
                            new Map<String, Object>{
                                'CensusMemberId' => 'a3qcb00000C5tLJAAZ',
                                'CensusId' => 'a3rcb000001sNWvAAM',
                                'IsActiveMember' => true,
                                'Email' => 'gm.arcsona@yopmail.com',
                                'AccountId' => '001cb00000BiT1nAAF',
                                'ContractId' => '800cb000009zP4RAAU',
                                'CurrentPrimaryId' => '001cb00000BiT1nAAF',
                                'Name' => 'FN Primary Test by Gabriel #17 LN Primary Test by Gabriel #17',
                                'Relationship' => 'Primary',
                                'Gender' => 'Male'
                            },
                            new Map<String, Object>{
                                'CensusMemberId' => 'a3qcb00000C5ihSAAR',
                                'CensusId' => 'a3rcb000001sNWvAAM',
                                'IsActiveMember' => true,
                                'Email' => 'gm.arcsona@yopmail.com',
                                'AccountId' => '001cb00000BiT1lAAF',
                                'ContractId' => '800cb000009zP4RAAU',
                                'CurrentPrimaryId' => '001cb00000BiT1nAAF',
                                'Name' => 'FN Spouse Test by Gabriel #17 LN Spouse Test by Gabriel #17',
                                'Relationship' => 'Spouse',
                                'Gender' => 'Female'
                            },
                            new Map<String, Object>{
                                'CensusMemberId' => 'a3qcb00000C5ihTAAR',
                                'CensusId' => 'a3rcb000001sNWvAAM',
                                'IsActiveMember' => true,
                                'AccountId' => '001cb00000BiT1mAAF',
                                'ContractId' => '800cb000009zP4RAAU',
                                'CurrentPrimaryId' => '001cb00000BiT1nAAF',
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
                            'Selling_Agent' => '005cb000006lvU2AAI',
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
                'ContractsIdforMothers' => '800cb000009zP4RAAU',
                'EligibleCensusId' => 'a3rcb000001sNWvAAM',
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
                        'PersonContactId' => '003cb00000Fjc0bAAB',
                        'PersonAccountId' => '001cb00000BiT1nAAF',
                        'vlocity_ins__LastName__c' => 'LN Primary Test by Gabriel #17',
                        'vlocity_ins__FirstName__c' => 'FN Primary Test by Gabriel #17',
                        'Id' => 'a3qcb00000C5tLJAAZ'
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
                        'PersonContactId' => '003cb00000Fjc0ZAAR',
                        'PersonAccountId' => '001cb00000BiT1lAAF',
                        'vlocity_ins__LastName__c' => 'LN Spouse Test by Gabriel #17',
                        'vlocity_ins__FirstName__c' => 'FN Spouse Test by Gabriel #17',
                        'Id' => 'a3qcb00000C5ihSAAR'
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
                        'PersonContactId' => '003cb00000Fjc0aAAB',
                        'PersonAccountId' => '001cb00000BiT1mAAF',
                        'vlocity_ins__LastName__c' => 'LN Child Test by Gabriel #17',
                        'vlocity_ins__FirstName__c' => 'FN Child Test by Gabriel #17',
                        'Id' => 'a3qcb00000C5ihTAAR'
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
                        'Id' => 'a3qcb00000C5tLJAAZ'
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
                        'Id' => 'a3qcb00000C5ihSAAR'
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
                        'Id' => 'a3qcb00000C5ihTAAR'
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
                                'Id' => 'a3qcb00000C5tLJAAZ',
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
                                'Id' => 'a3qcb00000C5ihSAAR',
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
                                'Id' => 'a3qcb00000C5ihTAAR',
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
                                'IsNewMember' => true,
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
                        'ChargentOrders__Gateway__c' => 'aBUcb0000006X4XGAU',
                        'ChargentOrders__Payment_Frequency__c' => 'Monthly',
                        'ChargentOrders__Payment_Method__c' => 'Credit Card',
                        'ChargentOrders__Payment_Status__c' => 'Recurring',
                        'ChargentOrders__Subtotal__c' => 389.91,
                        'ChargentOrders__Manual_Charge__c' => true,
                        'ChargentOrders__Tokenization__c' => '2144512832'
                    }
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
                    'Step_PaymentChangeFee' => new Map<String, Object>{

                    },
                    'STEP_MedicalQuestions' => new Map<String, Object>{
                        'BLK_ParentSiblingDiagnosed' => null,
                        'FRML_ParentSiblingDiagnosedNull' => false,
                        'MSG_WrongUnexpectedDate' => null,
                        'BLK_UnexpectedSymptoms' => null,
                        'FRML_CheckSymptoms' => false,
                        'FRML_DateUnexpectedWrong' => false,
                        'BLK_PendingTests' => null,
                        'FRML_CheckPendingTests' => false,
                        'LWC_SelectCensusMemberCancer' => null,
                        'EB_Cancer' => null,
                        'FRML_CheckCancer' => false,
                        'MSG_DateWrongCancer' => null,
                        'FRML_DateWrongCancer' => false,
                        'MSG_WrongDateAddiction' => null,
                        'BLK_Addictions' => null,
                        'FRML_CheckAddictions' => false,
                        'FMRL_WrongDateAddictions' => false,
                        'BLK_LicenceSuspended' => null,
                        'FRML_LicenceSuspended' => false,
                        'EB_PastConditions' => null,
                        'FRML_CheckPastConditionsNull' => false,
                        'MSG_DateWrongPrescription' => null,
                        'LWC_SelectCensusMember' => null,
                        'ED_MemberPrescription' => null,
                        'FRML_CheckPrescriptionsIsNull' => false,
                        'FRML_DateWrongPrescription' => false,
                        'MSG_WrongDatePCP' => null,
                        'FRML_WrongDatePCP' => false,
                        'EB_Physicians' => new Map<String, Object>{
                            'memberId' => 'MEM-41110220858522095',
                            'TXT_hasErrorPCP' => 'false',
                            'TXT_CensusMemberName' => 'FN Newborn Test by Gabriel #17 LN Newborn Test by Gabriel #17'
                        },
                        'RAD_PrescriptionMedications' => 'No',
                        'RAD_PastConditions' => 'No',
                        'RAD_LicenceSuspended' => 'No',
                        'RAD_Addictions' => 'No',
                        'RAD_Cancer' => 'No',
                        'RAD_PendingTests' => 'No',
                        'RAD_UnexplainedSymptoms' => 'No',
                        'RAD_ParentSiblingDiagnosed' => 'No',
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
                                    'CensusMemberId' => 'a3qcb00000C5tLJAAZ',
                                    'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Spouse Test by Gabriel #17',
                                    'FirstName' => 'FN Spouse Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                    'CensusMemberId' => 'a3qcb00000C5ihSAAR',
                                    'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Child Test by Gabriel #17',
                                    'FirstName' => 'FN Child Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                    'CensusMemberId' => 'a3qcb00000C5ihTAAR',
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
                                    'CensusMemberId' => 'a3qcb00000C5tLJAAZ',
                                    'CensusMemberFirstName' => 'FN Primary Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Spouse Test by Gabriel #17',
                                    'FirstName' => 'FN Spouse Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Spouse Test by Gabriel #17',
                                    'CensusMemberId' => 'a3qcb00000C5ihSAAR',
                                    'CensusMemberFirstName' => 'FN Spouse Test by Gabriel #17'
                                },
                                new Map<String, Object>{
                                    'LastName' => 'LN Child Test by Gabriel #17',
                                    'FirstName' => 'FN Child Test by Gabriel #17',
                                    'CensusMemberLastName' => 'LN Child Test by Gabriel #17',
                                    'CensusMemberId' => 'a3qcb00000C5ihTAAR',
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
                    'userId' => '005cb000006lvU2AAI'
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
                            'Dependent1.Id' => 'a3qcb00000C5ihTAAR',
                            'Dependent1.Height' => '3\'3',
                            'Dependent1.Weight' => '3',
                            'Dependent1.MI' => 'A',
                            'Spouse.SocialSecurity' => '222222222',
                            'Spouse.LastName' => 'LN Spouse Test by Gabriel #17',
                            'Spouse.FirstName' => 'FN Spouse Test by Gabriel #17',
                            'Spouse.Email' => 'gm.arcsona@yopmail.com',
                            'Spouse.DOB' => '2000-02-02',
                            'Spouse.Id' => 'a3qcb00000C5ihSAAR',
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
                            'Primary.Id' => 'a3qcb00000C5tLJAAZ',
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
    public static void addTemporaryNewbornTest(){
        Map<String, Object> inputMap = createInputMap();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_NewBorn_BaseService baseService = new ARC_NewBorn_BaseService();

        Test.startTest();
        baseService.invokeMethod('NB_NewBornDML', inputMap, outputMap, options);
        Test.stopTest();

        Assert.areEqual(JSON.serialize(outputMap), JSON.serialize(''));
    }

    // Scenario #2 : Add a Permanent Newborn | Actions to perform: mapContract, mapContractLineItem, mapContractParticipants, mapChargentOrders, insertHipaaAuthorization, mapMedicalQuestions, mapCases, mapCaseMember, insertPromotionDiscount, insertCaseForFeeSkipped
    @isTest
    public static void addPermanentNewbornTest(){

    }
}