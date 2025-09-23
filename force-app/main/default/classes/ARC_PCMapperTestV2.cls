@isTest
public class ARC_PCMapperTestV2 {
    
    @TestSetup
    static void makeData(){
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        List<Contact> contacts = ARC_TestUtility.createTestContact(2, 'Contact');
        List<Account> accounts = ARC_TestUtility.createTestAccount(2, 'ARC_IFPPersonAccount');
        List<Account> groupAccount = ARC_TestUtility.createTestAccount(1, 'Group');
        List<vlocity_ins__ContractLineItem__c> cLineItems = ARC_TestUtility.createTestContractLineItem(4);
        List<vlocity_ins__GroupCensusMemberPlan__c> gcMemberPlans = ARC_TestUtility.createTestCensusMemPlan(4);
        List<Product2> prods = ARC_TestUtility.createTestProducts(4);
        Id rtProduct = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();


        Integer i = 0;

        Contract cnt = [SELECT Id FROM Contract LIMIT 1];

        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test1', vlocity_ins__ContractLineId__c=cLineItems[0].Id, vlocity_ins__GroupCensusMemberId__c=members[0].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test2', vlocity_ins__ContractLineId__c=cLineItems[1].Id, vlocity_ins__GroupCensusMemberId__c=members[1].Id));
        upsert gcMemberPlans;

        for (vlocity_ins__GroupCensusMember__c cm : members) {
            if(i == 0) cm.vlocity_ins__IsPrimaryMember__c = true;
            if(i == 1) cm.ARC_DependentRelationship__c = 'Spouse';

            if(i == 0) cm.vlocity_ins__ContactId__c = contacts[0].Id;
            if(i == 1) cm.vlocity_ins__ContactId__c = contacts[1].Id;
            i++;
        }
        i = 0;
        update members;

        prods[0].RecordTypeId = rtProduct;
        prods[0].vlocity_ins__Type__c = 'Medical';
        update prods;

        prods[1].RecordTypeId = rtProduct;
        prods[1].vlocity_ins__Type__c = 'Ancillary';
        update prods;

        prods[2].RecordTypeId = rtProduct;
        prods[2].vlocity_ins__Type__c = 'Medical';
        update prods;

        prods[3].RecordTypeId = rtProduct;
        prods[2].vlocity_ins__Type__c = 'Medical';
        update prods;

        cLineItems[0].vlocity_ins__Product2Id__c = prods[0].Id;
        update cLineItems;

        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Test Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Credit Card',
            ChargentBase__Active__c = true
        );
        insert gateway;
        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = cnt.Id,
            ChargentOrders__Billing_First_Name__c = 'Norman',
            ChargentOrders__Billing_Last_Name__c = 'Beer',
            ChargentOrders__Card_Number__c = '5162095513838477',
            ChargentOrders__Card_Expiration_Month__c = '7',
            ChargentOrders__Card_Expiration_Year__c = '2025',
            ChargentOrders__Card_Last_4__c = '8477',
            ChargentOrders__Charge_Amount__c = 99,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Gateway__c = gateway.Id,
            ChargentOrders__Charge_Date__c = '04-01-2025',
            ARC_FirstMonthPayed__c = false,
            ChargentOrders__Manual_Charge__c = true
        );
        insert existingOrder;
    }

    @isTest
    static void primaryChange() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];

        // Guardian Info
        Map<String, Object> guardianInfo = new Map<String, Object>{
            'TXT_GuardianFirstName' => 'Cloud',
            'TXT_GuardianLastName' => 'Nube',
            'TXT_GuardianPhone' => '3333333333',
            'EMAIL_GuardianEmail' => 'arcsonatest@yopmail.com',
            'SEL_GuardianGender' => 'Female',
            'DATE_GuardianBirthdate' => '2000-04-29',
            'TXT_GuardianSSN' => new Map<String, Object>{ 'response' => '333333333' },
            'THEADBLK_GuardianAddress-Block' => new Map<String, Object>{
                'TXT_GuardianCity' => 'San Diego',
                'TXT_GuardianZipCode' => '92154',
                'TXT_GuardianState' => 'CA'
            },
            'SEL_GuardianRelationship' => 'Parent'
        };

        // Case Fee info
        Map<String, Object> caseDetails = new Map<String, Object>{
            'TXT_NoChargeChangeFeeReason' => 'I dont want to charge the fee now'
        };

        // Promo Discount info
        Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'RECURRING DISCOUNT',
            'PromotionCodeId' => 'aDFVA0000001HV34AM',
            'ApplyOver' => 'Medical',
            'DiscountAmount' => '88.18',
            'MedicalPrice' => 440.89,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '352.71',
            'AgentId' => '005VA00000CvQrhYAF'
        };
    
        Map<String, Object> blkChargeFee = new Map<String, Object>{
            'LWC_PromoDiscountCodeRefactor' => promoDiscount
        };

        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'No',
            'BLK_CaseCreationDetails' => caseDetails,
            'BLK_ChargeFee' => blkChargeFee
        };

        // Census Member
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => members[0].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' => contacts[0].Id,
                'PersonAccountId' => accounts[0].Id,
                'vlocity_ins__FirstName__c' => 'TestPrimary',
                'vlocity_ins__LastName__c' => 'MemberTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2015-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        // userInputs
        List<Object> userInputs = new List<Object>{
            new Map<String, Object>{
                'Id' => 'a3qVA00000HW88jYAD',
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => false
            }
        };

        // Create Chargent Order Record
        /*   Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contract con = new Contract(AccountId = acc.Id, StartDate = Date.today(), Status = 'Draft');
        insert con;
        
        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Test Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Credit Card',
            ChargentBase__Active__c = true
        );
        insert gateway;
        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = con.Id,
            ChargentOrders__Billing_First_Name__c = 'Norman',
            ChargentOrders__Billing_Last_Name__c = 'Beer',
            ChargentOrders__Card_Number__c = '5162095513838477',
            ChargentOrders__Card_Expiration_Month__c = '7',
            ChargentOrders__Card_Expiration_Year__c = '2025',
            ChargentOrders__Card_Last_4__c = '8477',
            ChargentOrders__Charge_Amount__c = 99,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Gateway__c = gateway.Id,
            ChargentOrders__Charge_Date__c = '04-01-2025',
            ARC_FirstMonthPayed__c = false,
            ChargentOrders__Manual_Charge__c = true
        );
        insert existingOrder;
        */
        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => accounts[0].Id,
            'TXT_ContractStatus' => 'Approved',
            'GroupAccountName' => 'Test Group',
            'ContractID' => cnt.Id
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhmSAAQ',
                    'Name' => 'WeShare 1k',
                    'Type__c' => 'Medical',
                    'Price' => 100.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{ 
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAB',
                                'Name' => 'Preventative Care',
                                'RecordTypeName__c' => 'CoverageSpec',
                                'Type__c' => 'Medical'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            },
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'Price' => 50.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAA',
                                'Name' => 'Dental CoverageSpec',
                                'RecordTypeName__c' => 'CoverageSpec'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 'primaryChange' => true };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'pcReasonsString' => 'Primary change',
            'feeApplicable' => false,
            'feeAmount' => 0,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_GuardiansInfo' => guardianInfo,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => stepPaymentFee,
            'SelectedContractInfo' => selectedContractInfo,
            'userId' => UserInfo.getUserId(),
            'CensusId' => '701000000000000AAA',
            'EffectiveDate' => '2025-05-15',
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            }
        };

        // manager and mapper
        ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
        ARC_PCMapper mapper = new ARC_PCMapper();
        ARC_PCDML DML = new ARC_PCDML();

        // Call the method
        Test.startTest();
        mapper.executeChanges(manager);
       // DML.manageDML(manager);
        Test.stopTest();

        // Assert for guardian
        System.assertEquals(1, manager.guardiansToInsert.size(), 'one guardian inserted');
        // Assert for case fee skipped
        System.assertEquals(1, manager.casesPCToInsert.size(), 'must inserted one case');
        // Assert for UW Case
        System.assertEquals(1, manager.casesUWToInsert.size(), 'must be created a one uw case');
        // Assert fro UW Case Members
        System.assertEquals(0, manager.censusMemberIdOrFakeIdToUWCM.size(), 'Must be created zero UW case member');
        // Assert for Contract
        System.assertEquals(1, manager.contractsToInsert.size(), 'Must be one contract inserted');
        // Assert for Contract Participant
        System.assertEquals(1, manager.personAccIdOrFakeIdToContractPart.size(), 'Must exist one contract participant');
        // Assert for Chargent Order
        System.assertEquals(1, manager.chargentOrdersRecurringOrder.size(), 'must be created a charge order');
    }

    // Same test to relationshipToPrimaryChange | dateOfBirthChange | programDowngrade | programUpgrade (with upsertMedicalQuesitons) | ancillaryChange | removeAllAncillary
    @isTest
    static void programUpgrade() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        System.debug(accounts);
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
        // Guardian Info
        Map<String, Object> guardianInfo = new Map<String, Object>{
            'TXT_GuardianFirstName' => 'Cloud',
            'TXT_GuardianLastName' => 'Nube',
            'TXT_GuardianPhone' => '3333333333',
            'EMAIL_GuardianEmail' => 'arcsonatest@yopmail.com',
            'SEL_GuardianGender' => 'Female',
            'DATE_GuardianBirthdate' => '2000-04-29',
            'TXT_GuardianSSN' => new Map<String, Object>{ 'response' => '333333333' },
            'THEADBLK_GuardianAddress-Block' => new Map<String, Object>{
                'TXT_GuardianCity' => 'San Diego',
                'TXT_GuardianZipCode' => '92154',
                'TXT_GuardianState' => 'CA'
            },
            'SEL_GuardianRelationship' => 'Parent'
        };

        // Promo Discount info
        Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'Change Fee',
            'PromotionCodeId' => 'aDFVA0000001NIj4AM',
            'ApplyOver' => 'Change Fee',
            'DiscountAmount' => '99.00',
            'MedicalPrice' => null,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '0.00',
            'AgentId' => '005VA00000CvQrhYAF'
        };
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_CaseCreationDetails' => null,
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_MethodOfPayment' => 'Credit Card',
                'RAD_KeepRecurringMethodOfPayment' => 'No',
                'LWC_PromoDiscountCodeRefactor' => promoDiscount,
                'BLK_PaymentInfo' => new Map<String, Object>{
                    'BLK_CreditCard' => new Map<String, Object>{
                        'TXT_FirstNameOnCard' => 'Norman',
                        'TXT_LastNameOnCard' => 'Beer',
                        'TXT_CardNumber' => '5162095513838477',
                        'SLC_ExpirationMonth' => '7',
                        'SLC_Year' => '2025',
                        'TXT_BillingAddress_Street' => 'Av siempre viva',
                        'TXT_BillingAddress_City' => 'San Diego',
                        'TXT_BillingAddress_State' => 'CA',
                        'TXT_BillingAddress_ZipCode' => '80215'
                    }
                }
            }
        };

        // Census Member
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => members[0].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'IsInactiveMember' => false,
                'PersonContactId' => contacts[0].Id,
                'PersonAccountId' => accounts[0].Id,
                'vlocity_ins__FirstName__c' => 'TestPrimary',
                'vlocity_ins__LastName__c' => 'MemberTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2015-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        // userInputs
        List<Object> userInputs = new List<Object>{
            new Map<String, Object>{
                'Id' => members[0].Id,
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => false
            }
        };

        // Create Chargent Order Record
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    
        Contract con = new Contract(AccountId = acc.Id, StartDate = Date.today(), Status = 'Draft');
        insert con;
    
        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Bank Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Bank Account',
            ChargentBase__Active__c = true
        );
        insert gateway;
    
        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = con.Id,
            ChargentOrders__Billing_First_Name__c = 'Norman',
            ChargentOrders__Billing_Last_Name__c = 'Beer',
            ChargentOrders__Bank_Routing_Number__c = '333333333',
            ChargentOrders__Bank_Account_Number__c = '22222222222222222',
            ChargentOrders__Bank_Name__c = 'Santander',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Gateway__c = gateway.Id,
            ChargentOrders__Charge_Amount__c = 99,
            ChargentOrders__Charge_Date__c = '04-01-2025',
            ARC_FirstMonthPayed__c = true,
            ChargentOrders__Manual_Charge__c = true
        );
        insert existingOrder;

        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => groupAccount[0].Id,
            'TXT_ContractStatus' => 'Approved',
            'GroupAccountName' => 'Test Group',
            'ContractID' => cnt.Id
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => prods[0].Id,
                    'Name' => 'WeShare 1k',
                    'Type__c' => 'Medical',
                    'Price' => 100.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{ 
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' =>  prods[2].Id,
                                'Name' => 'Preventative Care',
                                'RecordTypeName__c' => 'CoverageSpec',
                                'Type__c' => 'Medical'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[0].Id, 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            },
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' =>  prods[1].Id,
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'Price' => 50.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' =>  prods[3].Id,
                                'Name' => 'Dental CoverageSpec',
                                'RecordTypeName__c' => 'CoverageSpec'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'programUpgrade' => true,
            'dateOfBirthChange' => true,
            'relationshipToPrimaryChange' => true,
            'ancillaryChange' => true,
            'removeAllAncillary' => true,
            'programDowngrade' => true,
            'addMember' => false,
            'addExistingMember' => false
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'pcReasonsString' => 'Program Upgrade',
            'feeApplicable' => true,
            'feeAmount' => 99,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true,
            'programSummaryFeeText' => 'One Time Change Fee (Program Upgrade): 99.000'
        };

        Map<String, Object> aRC_DatePicker = new Map<String, object> {
            'DATE_SubscriberEffectiveDate' => '2025-06-15'
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_GuardiansInfo' => guardianInfo,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => stepPaymentFee,
            'SelectedContractInfo' => selectedContractInfo,
            'userId' => UserInfo.getUserId(),
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => new Map<String, Object> {
                'aRC_DatePicker' => aRC_DatePicker
            },
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            }
        };

        // manager and mapper
        ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
        ARC_PCMapper mapper = new ARC_PCMapper();
        ARC_PCDML DML = new ARC_PCDML();


        // Call the method
        Test.startTest();
        mapper.executeChanges(manager);
        DML.manageDML(manager);
        Test.stopTest();

        // Assert for guardian
        System.assertEquals(1, manager.guardiansToInsert.size(), 'one guardian inserted');
        // Assert for UW Case
        System.assertEquals(1, manager.casesUWToInsert.size(), 'must be created a one uw case');
        // Assert fro UW Case Members
        System.assertEquals(1, manager.censusMemberIdOrFakeIdToUWCM.size(), 'Must be created one UW case member');
        // Assert for Contract
        System.assertEquals(1, manager.contractsToInsert.size(), 'Must be one contract inserted');
        // Assert for Contract Participant
        System.assertEquals(1, manager.personAccIdOrFakeIdToContractPart.size(), 'Must exist one contract participant');
        // Assert for Chargent Order
        System.assertEquals(1, manager.chargentOrdersRecurringOrder.size(), 'must be created a charge order');
    }

    // Same test to effectiveDateChange | removeMember (with createChargentOrders)
    @isTest
    static void effectiveDateChange() {
        // Promo Discount info
        Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'RECURRING DISCOUNT',
            'PromotionCodeId' => 'aDFVA0000001HV34AM',
            'ApplyOver' => 'Medical',
            'DiscountAmount' => '88.18',
            'MedicalPrice' => 440.89,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '352.71',
            'AgentId' => '005VA00000CvQrhYAF'
        };
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_MethodOfPayment' => 'Bank Account',
                'RAD_KeepRecurringMethodOfPayment' => 'No',
                'LWC_PromoDiscountCodeRefactor' => promoDiscount,
                'BLK_PaymentInfo' => new Map<String, Object>{
                    'BLK_BankAccount' => new Map<String, Object>{
                        'TXT_RoutingNumber' => '333333333',
                        'TXT_AccNumber' => '22222222222222222',
                        'TXT_FirstNameOnAccount' => 'Norman',
                        'TXT_LastNameOnAccount' => 'Beer',
                        'TXT_BankName' => 'Santander',
                        'SLC_AccType' => 'Checking'
                    }
                }
            }
        };

        // Census Member
        Id fakeContactId = Id.valueOf('003000000000000AAA');
        Id fakeAccountId = Id.valueOf('001000000000000AAA');
        Id fakeContactId1 = Id.valueOf('003000000000001AAA');
        Id fakeAccountId1 = Id.valueOf('001000000000001AAA');
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => 'a3q000000000000AAA',
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' => fakeContactId,
                'PersonAccountId' => fakeAccountId,
                'vlocity_ins__FirstName__c' => 'TestPrimary',
                'vlocity_ins__LastName__c' => 'MemberTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2015-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => 'a3q000000000001AAA',
                'IsNewMember' => false,
                'IsRemoveMember' => true,
                'PersonContactId' => fakeContactId1,
                'PersonAccountId' => fakeAccountId1,
                'vlocity_ins__FirstName__c' => 'TestRemoved',
                'vlocity_ins__LastName__c' => 'RemovedTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2000-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        // userInputs
        List<Object> userInputs = new List<Object>{
            new Map<String, Object>{
                'Id' => 'a3q000000000000AAA',
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => false
            },
            new Map<String, Object>{
                'Id' => 'a3q000000000001AAA',
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => true
            }
        };

        // Create Chargent Order Record
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contract con = new Contract(AccountId = acc.Id, StartDate = Date.today(), Status = 'Draft');
        insert con;
        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Bank Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Bank Account',
            ChargentBase__Active__c = true
        );
        insert gateway;
        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = con.Id,
            ChargentOrders__Billing_First_Name__c = 'Norman',
            ChargentOrders__Billing_Last_Name__c = 'Beer',
            ChargentOrders__Bank_Routing_Number__c = '333333333',
            ChargentOrders__Bank_Account_Number__c = '22222222222222222',
            ChargentOrders__Bank_Name__c = 'Santander',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Gateway__c = gateway.Id,
            ChargentOrders__Charge_Amount__c = 99,
            ChargentOrders__Charge_Date__c = '04-01-2025',
            ARC_FirstMonthPayed__c = true,
            ChargentOrders__Manual_Charge__c = true
        );
        insert existingOrder;

        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => acc.Id,
            'TXT_ContractStatus' => 'Approved',
            'GroupAccountName' => 'Test Group',
            'ContractID' => con.Id
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhmSAAQ',
                    'Name' => 'WeShare 1k',
                    'Type__c' => 'Medical',
                    'Price' => 100.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{ 
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAB',
                                'Name' => 'Preventative Care',
                                'RecordTypeName__c' => 'CoverageSpec',
                                'Type__c' => 'Medical'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            },
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'Price' => 50.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAA',
                                'Name' => 'Dental CoverageSpec',
                                'RecordTypeName__c' => 'CoverageSpec'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'removeMember' => true ,
            'effectiveDateChange' => true 
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'pcReasonsString' => 'Remove Member',
            'feeApplicable' => true,
            'feeAmount' => 99,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_GuardiansInfo' => null,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => stepPaymentFee,
            'SelectedContractInfo' => selectedContractInfo,
            'userId' => UserInfo.getUserId(),
            'CensusId' => '701000000000000AAA',
            'EffectiveDate' => '2025-05-15',
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            }
        };

        // manager and mapper
        ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
        ARC_PCMapper mapper = new ARC_PCMapper();
        ARC_PCDML DML = new ARC_PCDML();


        // Call the method
        Test.startTest();
        mapper.executeChanges(manager);
        Test.stopTest();

        // Assert for guardian
        System.assertEquals(0, manager.guardiansToInsert.size(), 'No guardian inserted');
        // Assert for UW Case
        System.assertEquals(1, manager.casesUWToInsert.size(), 'must be created a one uw case');
        // Assert fro UW Case Members
        System.assertEquals(1, manager.censusMemberIdOrFakeIdToUWCM.size(), 'Must be created one UW case member');
        // Assert for Contract
        System.assertEquals(1, manager.contractsToInsert.size(), 'Must be one contract inserted');
        // Assert for Contract Participant
        System.assertEquals(1, manager.personAccIdOrFakeIdToContractPart.size(), 'Must exist one contract participant');
        // Assert for Chargent Order
        System.assertEquals(1, manager.chargentOrdersRecurringOrder.size(), 'must be created a charge order');
    }

    @isTest
    static void createChargentOrdersOldBank() {
        // Promo Discount info
        Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'RECURRING DISCOUNT',
            'PromotionCodeId' => 'aDFVA0000001HV34AM',
            'ApplyOver' => 'Medical',
            'DiscountAmount' => '88.18',
            'MedicalPrice' => 440.89,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '352.71',
            'AgentId' => '005VA00000CvQrhYAF'
        };
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_MethodOfPayment' => 'Bank Account',
                'RAD_KeepRecurringMethodOfPayment' => 'Yes',
                'LWC_PromoDiscountCodeRefactor' => promoDiscount
            }
        };

        // Census Member
        Id fakeContactId = Id.valueOf('003000000000000AAA');
        Id fakeAccountId = Id.valueOf('001000000000000AAA');
        Id fakeContactId1 = Id.valueOf('003000000000001AAA');
        Id fakeAccountId1 = Id.valueOf('001000000000001AAA');
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => 'a3q000000000000AAA',
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' => fakeContactId,
                'PersonAccountId' => fakeAccountId,
                'vlocity_ins__FirstName__c' => 'TestPrimary',
                'vlocity_ins__LastName__c' => 'MemberTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2015-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => 'a3q000000000001AAA',
                'IsNewMember' => false,
                'IsRemoveMember' => true,
                'PersonContactId' => fakeContactId1,
                'PersonAccountId' => fakeAccountId1,
                'vlocity_ins__FirstName__c' => 'TestRemoved',
                'vlocity_ins__LastName__c' => 'RemovedTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2000-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        // userInputs
        List<Object> userInputs = new List<Object>{
            new Map<String, Object>{
                'Id' => 'a3q000000000000AAA',
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => false
            },
            new Map<String, Object>{
                'Id' => 'a3q000000000001AAA',
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => true
            }
        };

        // Create Chargent Order Record
        Account acc = new Account(Name = 'Old Bank Acc');
        insert acc;

        Contract con = new Contract(AccountId = acc.Id, StartDate = Date.today(), Status = 'Draft');
        insert con;

        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Bank Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Bank Account',
            ChargentBase__Active__c = true
        );
        insert gateway;

        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = con.Id,
            ChargentOrders__Billing_First_Name__c = 'Norman',
            ChargentOrders__Billing_Last_Name__c = 'Beer',
            ChargentOrders__Bank_Routing_Number__c = '123456789',
            ChargentOrders__Bank_Account_Number__c = '999999999999',
            ChargentOrders__Bank_Name__c = 'Santander',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Gateway__c = gateway.Id,
            ChargentOrders__Charge_Amount__c = 88.50,
            ChargentOrders__Charge_Date__c = '10-11-2024',
            ARC_FirstMonthPayed__c = true,
            ChargentOrders__Manual_Charge__c = true
        );
        insert existingOrder;

        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => acc.Id,
            'TXT_ContractStatus' => 'Approved',
            'GroupAccountName' => 'Test Group',
            'ContractID' => con.Id
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhmSAAQ',
                    'Name' => 'WeShare 1k',
                    'Type__c' => 'Medical',
                    'Price' => 100.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{ 
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAB',
                                'Name' => 'Preventative Care',
                                'RecordTypeName__c' => 'CoverageSpec',
                                'Type__c' => 'Medical'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            },
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'Price' => 50.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAA',
                                'Name' => 'Dental CoverageSpec',
                                'RecordTypeName__c' => 'CoverageSpec'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'removeMember' => true ,
            'effectiveDateChange' => true 
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'pcReasonsString' => 'Remove Member',
            'feeApplicable' => true,
            'feeAmount' => 99,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_GuardiansInfo' => null,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => stepPaymentFee,
            'SelectedContractInfo' => selectedContractInfo,
            'userId' => UserInfo.getUserId(),
            'CensusId' => '701000000000000AAA',
            'EffectiveDate' => '2025-05-15',
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            }
        };

        // manager and mapper
        ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
        ARC_PCMapper mapper = new ARC_PCMapper();
        ARC_PCDML DML = new ARC_PCDML();


        // Call the method
        Test.startTest();
        mapper.executeChanges(manager);
        Test.stopTest();

        // Assert for guardian
        System.assertEquals(0, manager.guardiansToInsert.size(), 'No guardian inserted');
        // Assert for UW Case
        System.assertEquals(1, manager.casesUWToInsert.size(), 'must be created a one uw case');
        // Assert fro UW Case Members
        System.assertEquals(1, manager.censusMemberIdOrFakeIdToUWCM.size(), 'Must be created one UW case member');
        // Assert for Contract
        System.assertEquals(1, manager.contractsToInsert.size(), 'Must be one contract inserted');
        // Assert for Contract Participant
        System.assertEquals(1, manager.personAccIdOrFakeIdToContractPart.size(), 'Must exist one contract participant');
        // Assert for Chargent Order
        System.assertEquals(1, manager.chargentOrdersRecurringOrder.size(), 'must be created a charge order');
    }

    @isTest
    static void createChargentOrdersOldCreditCard() {
        // Promo Discount info
        Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'RECURRING DISCOUNT',
            'PromotionCodeId' => 'aDFVA0000001HV34AM',
            'ApplyOver' => 'Medical',
            'DiscountAmount' => '88.18',
            'MedicalPrice' => 440.89,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '352.71',
            'AgentId' => '005VA00000CvQrhYAF'
        };
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_KeepRecurringMethodOfPayment' => 'Yes',
                'LWC_PromoDiscountCodeRefactor' => promoDiscount
            }
        };

        // Census Member
        Id fakeContactId = Id.valueOf('003000000000000AAA');
        Id fakeAccountId = Id.valueOf('001000000000000AAA');
        Id fakeContactId1 = Id.valueOf('003000000000001AAA');
        Id fakeAccountId1 = Id.valueOf('001000000000001AAA');
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => 'a3q000000000000AAA',
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' => fakeContactId,
                'PersonAccountId' => fakeAccountId,
                'vlocity_ins__FirstName__c' => 'TestPrimary',
                'vlocity_ins__LastName__c' => 'MemberTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2015-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => 'a3q000000000001AAA',
                'IsNewMember' => false,
                'IsRemoveMember' => true,
                'PersonContactId' => fakeContactId1,
                'PersonAccountId' => fakeAccountId1,
                'vlocity_ins__FirstName__c' => 'TestRemoved',
                'vlocity_ins__LastName__c' => 'RemovedTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2000-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        // userInputs
        List<Object> userInputs = new List<Object>{
            new Map<String, Object>{
                'Id' => 'a3q000000000000AAA',
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => false
            },
            new Map<String, Object>{
                'Id' => 'a3q000000000001AAA',
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => true
            }
        };

        // Create Chargent Order Record
        Account acc = new Account(Name = 'Old Payment Test');
        insert acc;

        Contract con = new Contract(AccountId = acc.Id, StartDate = Date.today(), Status = 'Draft');
        insert con;

        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Old Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Credit Card',
            ChargentBase__Active__c = true
        );
        insert gateway;

        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = con.Id,
            ChargentOrders__Billing_First_Name__c = 'Old',
            ChargentOrders__Billing_Last_Name__c = 'User',
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
            ChargentOrders__Charge_Date__c = '10-11-2024',
            ARC_FirstMonthPayed__c = true,
            ChargentOrders__Manual_Charge__c = true
        );
        insert existingOrder;

        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => acc.Id,
            'TXT_ContractStatus' => 'Approved',
            'GroupAccountName' => 'Test Group',
            'ContractID' => con.Id
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhmSAAQ',
                    'Name' => 'WeShare 1k',
                    'Type__c' => 'Medical',
                    'Price' => 100.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{ 
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAB',
                                'Name' => 'Preventative Care',
                                'RecordTypeName__c' => 'CoverageSpec',
                                'Type__c' => 'Medical'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            },
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'Price' => 50.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAA',
                                'Name' => 'Dental CoverageSpec',
                                'RecordTypeName__c' => 'CoverageSpec'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'removeMember' => true ,
            'effectiveDateChange' => true 
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'pcReasonsString' => 'Remove Member',
            'feeApplicable' => true,
            'feeAmount' => 99,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_GuardiansInfo' => null,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => stepPaymentFee,
            'SelectedContractInfo' => selectedContractInfo,
            'userId' => UserInfo.getUserId(),
            'CensusId' => '701000000000000AAA',
            'EffectiveDate' => '2025-05-15',
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            }
        };

        // manager and mapper
        ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
        ARC_PCMapper mapper = new ARC_PCMapper();
        ARC_PCDML DML = new ARC_PCDML();


        // Call the method
        Test.startTest();
        mapper.executeChanges(manager);
        Test.stopTest();

        // Assert for guardian
        System.assertEquals(0, manager.guardiansToInsert.size(), 'No guardian inserted');
        // Assert for UW Case
        System.assertEquals(1, manager.casesUWToInsert.size(), 'must be created a one uw case');
        // Assert fro UW Case Members
        System.assertEquals(1, manager.censusMemberIdOrFakeIdToUWCM.size(), 'Must be created one UW case member');
        // Assert for Contract
        System.assertEquals(1, manager.contractsToInsert.size(), 'Must be one contract inserted');
        // Assert for Contract Participant
        System.assertEquals(1, manager.personAccIdOrFakeIdToContractPart.size(), 'Must exist one contract participant');
        // Assert for Chargent Order
        System.assertEquals(1, manager.chargentOrdersRecurringOrder.size(), 'must be created a charge order');
    }

    // Same test to addMember (updateGCMaddMember) | addExistingMember (updateGCMaddExistingMember)
    @isTest
    static void addMember() {
        // medical questions...
        Map<String, Object> medicalQuestions = new Map<String, Object>{
            'BLK_ParentSiblingDiagnosed' => new Map<String, Object>{
                'CHKBOX_MemberParentDiagnosed' => true,
                'DATE_MemberParentDiagnosed' => '2025-05-01',
                'TXTAREA_MemberParentDiagnosed' => 'q1',
                'memberId' => 'MEM-1747050829654895',
                'TXT_MemberParentDiagnosed' => 'Vicky Vector',
                'TXT_MemberIdParentDiagnosed' => 'MEM-1747050829654895'
            },
            'EB_Cancer' => new Map<String, Object>{
                'CHK_CheckCancer' => true,
                'TXT_MemberNameCancer' => 'Vicky Vector',
                'TXT_MemberIdCancer' => 'MEM-1747050829654895',
                'TXT_TypeOfCancer' => 'skin cancer',
                'DATE_Cancer' => '2025-05-01'
            },
            'ED_MemberPrescription' => new Map<String, Object>{
                'TXT_MemberName' => 'Vicky Vector',
                'TXT_MemberIdPrescription' => 'MEM-1747050829654895',
                'TXT_NameOfMedication' => 'paracetamol',
                'TXT_DatePrescribed' => '2025-01-27',
                'TXT_DateDiscontinued' => '2025-04-28',
                'TXT_ReasonForMedication' => 'no reason',
                'TXT_PrescribingPhysician' => 'Dr. Q'
            },
            'EB_Physicians' => new Map<String, Object>{
                'memberId' => 'MEM-1747050829654895',
                'TXT_PhysicianName' => 'Dr. Carl',
                'TXT_PhysicianCity' => 'San Diego',
                'TXT_PhysicianPhone' => '6666666666'
            }
        };
        // end medical

        Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'RECURRING DISCOUNT',
            'PromotionCodeId' => 'aDFVA0000001HV34AM',
            'ApplyOver' => 'Medical',
            'DiscountAmount' => '88.18',
            'MedicalPrice' => 440.89,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '352.71',
            'AgentId' => '005VA00000CvQrhYAF'
        };
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_MethodOfPayment' => 'Bank Account',
                'RAD_KeepRecurringMethodOfPayment' => 'No',
                'LWC_PromoDiscountCodeRefactor' => promoDiscount,
                'BLK_PaymentInfo' => new Map<String, Object>{
                    'BLK_BankAccount' => new Map<String, Object>{
                        'TXT_RoutingNumber' => '333333333',
                        'TXT_AccNumber' => '22222222222222222',
                        'TXT_FirstNameOnAccount' => 'Norman',
                        'TXT_LastNameOnAccount' => 'Beer',
                        'TXT_BankName' => 'Santander',
                        'SLC_AccType' => 'Checking'
                    }
                }
            }
        };

        // Hipaa info
        Map<String, Object> typeAheadBlock = new Map<String, Object>{
            'TypeAhead1' => 'Siempre Viva Ct, San Diego, CA 92154, USA',
            'TXT_AddAddress' => 'Siempre Viva Court',
            'TXT_AddZipCode' => '92154',
            'TXT_AddCity' => 'San Diego',
            'TXT_AddCountry' => 'United States',
            'SEL_AddState' => 'CA'
        };

        Map<String, Object> block1 = new Map<String, Object>{
            'TXT_NewFirstName' => 'Venus',
            'TXT_NewLastName' => 'Velocity',
            'TXT_NewBirthdate' => '1999-05-04',
            'TXT_NewTelephone' => '2222222222',
            'TXT_NewEmailAdress' => 'latalih346@benznoi.com',
            'TypeAhead1-Block' => typeAheadBlock
        };

        Map<String, Object> internalParty = new Map<String, Object>{
            'Id' => 'MEM-1746446302955487',
            'CHK_Authorized' => true,
            'DAT_DOB' => '2000-05-10',
            'TXT_EmailAddress' => 'arcsonatest@yopmail.com',
            'TXT_Telephone' => '2222222222',
            'TXT_ZipCode' => '80215',
            'TXT_City' => 'Lakewood',
            'TXT_Address' => 'Lakewood, CO, 12345 West Colfax Avenue, 80215',
            'TXT_LastName' => 'Retrogrado',
            'TXT_FirstName' => 'Mercurio',
            'TXT_Relationship' => 'Child',
            'TXT_FullName' => 'Mercurio Retrogrado'
        };

        List<Object> authorizedParties = new List<Object>{ internalParty };

        Map<String, Object> stepHipaa = new Map<String, Object>{
            'Formula1' => 1,
            'Block1' => block1,
            'Formula2' => false,
            'EDITBLK_HIPAAAuthorizedParties' => authorizedParties,
            'RAD_AuthorizeOthers' => 'Yes'
        };

        // Census Member
        Id fakeContactId = Id.valueOf('003000000000000AAA');
        Id fakeAccountId = Id.valueOf('001000000000000AAA');
        Id fakeContactId1 = Id.valueOf('003000000000001AAA');
        Id fakeAccountId1 = Id.valueOf('001000000000001AAA');
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => 'MEM-1746542563528270',
                'IsNewMember' => true,
                'IsRemoveMember' => false,
                'PersonContactId' => fakeContactId,
                'PersonAccountId' => fakeAccountId,
                'vlocity_ins__FirstName__c' => 'TestPrimary',
                'vlocity_ins__LastName__c' => 'MemberTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => 'I1744918617983-0.8047660324798835',
                'vlocity_ins__Birthdate__c' => '2015-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Relationship__c' => 'Spouse',
                'Id' => 'a3q000000000001AAA',
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'IsInactiveMember' => true,
                'PersonContactId' => fakeContactId1,
                'PersonAccountId' => fakeAccountId1,
                'vlocity_ins__FirstName__c' => 'TestRemoved',
                'vlocity_ins__LastName__c' => 'RemovedTest',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__Birthdate__c' => '2000-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => true
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        Map<String, Object> primaryMember = new Map<String, Object>{
            'vlocity_ins__IsPrimaryMember__c' => true,
            'Id' => 'a3q000000000001AAA',
            'vlocity_ins__MemberIdentifier__c' => '2025-03-24T19:17:44.157Z'
        };
        Map<String, Object> oldProduct = new Map<String, Object>{
            'Type__c' => 'Medical',
            'census_members' => new List<Object>{ primaryMember }
        };

        List<Object> oldProductsList = new List<Object>{ oldProduct };

        // userInputs
        List<Object> userInputs = new List<Object>{
            new Map<String, Object>{
                'Id' => 'MEM-1746542563528270',
                'IsAddExistingMember' => false,
                'IsNewMember' => true,
                'IsRemoveMember' => false
            },
            new Map<String, Object>{
                'Id' => 'a3q000000000001AAA',
                'IsAddExistingMember' => true,
                'IsNewMember' => false,
                'IsRemoveMember' => false
            }
        };

        // Create Chargent Order Record
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contract con = new Contract(AccountId = acc.Id, StartDate = Date.today(), Status = 'Draft');
        insert con;
        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Bank Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Bank Account',
            ChargentBase__Active__c = true
        );
        insert gateway;
        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = con.Id,
            ChargentOrders__Billing_First_Name__c = 'Norman',
            ChargentOrders__Billing_Last_Name__c = 'Beer',
            ChargentOrders__Bank_Routing_Number__c = '333333333',
            ChargentOrders__Bank_Account_Number__c = '22222222222222222',
            ChargentOrders__Bank_Name__c = 'Santander',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Gateway__c = gateway.Id,
            ChargentOrders__Charge_Amount__c = 99,
            ChargentOrders__Charge_Date__c = '04-01-2025',
            ARC_FirstMonthPayed__c = true,
            ChargentOrders__Manual_Charge__c = true
        );
        insert existingOrder;

        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => acc.Id,
            'TXT_ContractStatus' => 'Approved',
            'GroupAccountName' => 'Test Group',
            'ContractID' => con.Id
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhmSAAQ',
                    'Name' => 'WeShare 1k',
                    'Type__c' => 'Medical',
                    'Price' => 100.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{ 
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAB',
                                'Name' => 'Preventative Care',
                                'RecordTypeName__c' => 'CoverageSpec',
                                'Type__c' => 'Medical'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            },
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => '01t5f000003xhfHAAQ',
                    'Name' => 'AIDD 7500',
                    'Type__c' => 'Ancillary',
                    'Price' => 50.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => '01t000000000005AAA',
                                'Name' => 'Dental CoverageSpec',
                                'RecordTypeName__c' => 'CoverageSpec'
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => 'a3qVA00000HW88jYAD', 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'First', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false }
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{
            'addMember' => true,
            'addExistingMember' => true,
            'programUpgrade' => false 
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'pcReasonsString' => 'Remove Member',
            'feeApplicable' => true,
            'feeAmount' => 99,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_GuardiansInfo' => null,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => stepPaymentFee,
            'SelectedContractInfo' => selectedContractInfo,
            'userId' => UserInfo.getUserId(),
            'CensusId' => '701000000000000AAA',
            'EffectiveDate' => '2025-05-15',
            'price_calculation' => priceCalc,
            'oldProducts' => oldProductsList,
            'STEP_HIPAAAuthorizationForm' => stepHipaa,
            'STEP_MedicalQuestions' => medicalQuestions,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            }
        };

        // manager and mapper
        ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
        ARC_PCMapper mapper = new ARC_PCMapper();
        ARC_PCDML DML = new ARC_PCDML();


        // Call the method
        Test.startTest();
        mapper.executeChanges(manager);
        Test.stopTest();

        //Assert for Medical Question
        System.assertEquals(1, manager.newMembersMapMedicalConditionsToInsert.size(), 'Must be medical questions');
        // Assert for guardian
        System.assertEquals(0, manager.guardiansToInsert.size(), 'No guardian inserted');
        // Assert Census Member
        System.assertEquals(1, manager.censusMembersToInsert.size(), 'Must be inserted one GroupCensusMember');
        // Assert Hipaa info
        System.assertEquals(1, manager.fakeIdToHipaaAuth.size(), 'Must be created an internal Hipaa');
        // Assert for UW Case
        System.assertEquals(1, manager.casesUWToInsert.size(), 'must be created a one uw case');
        // Assert fro UW Case Members
        System.assertEquals(2, manager.censusMemberIdOrFakeIdToUWCM.size(), 'Must be created two UW case member');
        // Assert for Contract
        System.assertEquals(1, manager.contractsToInsert.size(), 'Must be one contract inserted');
        // Assert for Contract Participant
        System.assertEquals(2, manager.personAccIdOrFakeIdToContractPart.size(), 'Must exist two contract participant');
        // Assert for Chargent Order
        System.assertEquals(1, manager.chargentOrdersRecurringOrder.size(), 'must be created a charge order');
    }

    @isTest
    static void demographicUpdates() {
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => '001000000000000AAA',
            'GroupAccountName' => 'Test Group',
            'ContractID' => '800000000000001AAA'
        };
        Map<String, Object> primaryMember = new Map<String, Object>{
            'Id' => 'a3q000000000001AAA',
            'vlocity_ins__MemberIdentifier__c' => '2025-03-24T19:17:44.157Z',
            'vlocity_ins__IsPrimaryMember__c' => true
        };
    
        Map<String, Object> oldProduct = new Map<String, Object>{
            'Type__c' => 'Medical',
            'census_members' => new List<Object>{ primaryMember }
        };

        // Census Member
        Id fakeContactId = Id.valueOf('003000000000000AAA');
        Id fakeAccountId = Id.valueOf('001000000000000AAA');

        Map<String, Object> updatedMember1 = new Map<String, Object>{
            'vlocity_ins__IsPrimaryMember__c' => true,
            'ARC_Relationship__c' => 'Primary',
            'Id' => 'a3q000000000000AAA',
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'IsInactiveMember' => false,
            'PersonContactId' => fakeContactId,
            'PersonAccountId' => fakeAccountId,
            'vlocity_ins__FirstName__c' => 'TestPrimary',
            'vlocity_ins__LastName__c' => 'MemberTest',
            'ARC_PhysicalAddressStreet__c' => '123 Main St',
            'ARC_PhysicalAddressCity__c' => 'Denver',
            'ARC_PhysicalAddressState__c' => 'CO',
            'ARC_PhysicalAddressZipCode__c' => '80202',
            'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
            'vlocity_ins__Birthdate__c' => '2015-03-12',
            'vlocity_ins__Gender__c' => 'Male',
            'vlocity_ins__Email__c' => 'john.doe@example.com',
            'ARC_Phone__c' => '5551234567',
            'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
            'ARC_HeightFeet__c' => '5',
            'ARC_HeightInches__c' => '10',
            'ARC_Weight__c' => '180',
            'ARC_Smoker__c' => true
        };
        Map<String, Object> updatedMember2 = new Map<String, Object>{
            'vlocity_ins__IsPrimaryMember__c' => true,
            'ARC_Relationship__c' => 'Spouse',
            'Id' => 'a3q000000000003AAA',
            'IsInactiveMember' => false,
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'PersonContactId' => fakeContactId,
            'PersonAccountId' => fakeAccountId,
            'vlocity_ins__FirstName__c' => 'TestSpouse',
            'vlocity_ins__LastName__c' => 'SpouseTest',
            'ARC_PhysicalAddressStreet__c' => '123 Main St',
            'ARC_PhysicalAddressCity__c' => 'Denver',
            'ARC_PhysicalAddressState__c' => 'CA',
            'ARC_PhysicalAddressZipCode__c' => '80202',
            'vlocity_ins__MemberIdentifier__c' => 'I1744918617983-0.8047660324798835',
            'vlocity_ins__Birthdate__c' => '2015-03-12',
            'vlocity_ins__Gender__c' => 'Male',
            'vlocity_ins__Email__c' => 'john.doe@example.com',
            'ARC_Phone__c' => '5551234567',
            'vlocity_ins__SocialSecurityNumber__c' => '123-45-6789',
            'ARC_HeightFeet__c' => '5',
            'ARC_HeightInches__c' => '10',
            'ARC_Weight__c' => '180',
            'ARC_Smoker__c' => true
        };
    
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => new List<Object>{ updatedMember1, updatedMember2 }
        };
    
        Map<String, Object> inputMap = new Map<String, Object>{
            'census_component' => censusComponent,
            'SelectedContractInfo' => selectedContractInfo,
            'EffectiveDate' => '2025-05-15',
            'oldProducts' => new List<Object>{ oldProduct }
        };
    
        inputMap.put('demographicUpdates', true);
    
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'demographicChange' => true,
            'addressStateChange' => true
        };
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons
        };
        inputMap.put('pcChanges', pcChanges);
    
        ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
        ARC_PCMapper mapper = new ARC_PCMapper();
        ARC_PCDML DML = new ARC_PCDML();

    
        Test.startTest();
        mapper.executeChanges(manager);
        Test.stopTest();
    
        System.assertEquals(2, manager.censusMembersDemographicChange.size(), 'Must be one member with demographic updates');
    }

}