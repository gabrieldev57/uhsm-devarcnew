@isTest
public class ARC_PCMapperTest {
    
    @TestSetup
    static void makeData(){
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        List<Contact> contacts = ARC_TestUtility.createTestContact(2, 'Contact');
        List<Account> accounts = ARC_TestUtility.createTestAccount(2, 'ARC_IFPPersonAccount');
        List<Account> groupAccount = ARC_TestUtility.createTestAccount(1, 'Group');
        List<vlocity_ins__ContractLineItem__c> cLineItems = ARC_TestUtility.createTestContractLineItem(4);
        List<vlocity_ins__GroupCensusMemberPlan__c> gcMemberPlans = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        List<Product2> prods = ARC_TestUtility.createTestProducts(4);
        Id rtProduct = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id rtCoverageSpec = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Coverage Spec').getRecordTypeId();
        

        Integer i = 0;

        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test1', vlocity_ins__ContractLineId__c=cLineItems[0].Id, vlocity_ins__GroupCensusMemberId__c=members[0].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test3', vlocity_ins__ContractLineId__c=cLineItems[2].Id, vlocity_ins__GroupCensusMemberId__c=members[0].Id));

        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test2', vlocity_ins__ContractLineId__c=cLineItems[1].Id, vlocity_ins__GroupCensusMemberId__c=members[1].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test4', vlocity_ins__ContractLineId__c=cLineItems[3].Id, vlocity_ins__GroupCensusMemberId__c=members[1].Id));
        insert gcMemberPlans;

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

        prods[1].RecordTypeId = rtProduct;
        prods[1].vlocity_ins__Type__c = 'Ancillary';

        prods[2].RecordTypeId = rtProduct;
        prods[2].vlocity_ins__Type__c = 'Medical';
        prods[2].RecordTypeId = rtCoverageSpec;

        prods[3].RecordTypeId = rtCoverageSpec;

        update prods;

        vlocity_ins__ProductChildItem__c childItem1 = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ChildProductId__c = prods[2].Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert childItem1;

        vlocity_ins__ProductChildItem__c childItem2 = new vlocity_ins__ProductChildItem__c(
            vlocity_ins__ChildProductId__c = prods[3].Id,
            vlocity_ins__ChildLineNumber__c = '1'
        );
        insert childItem2;

        Contract cnt = [SELECT Id, ARC_AppFeeOrder__c, AccountId FROM Contract LIMIT 1];
        cnt.AccountId = groupAccount[0].Id;

        for (vlocity_ins__ContractLineItem__c cli : cLineItems) {
            cli.vlocity_ins__ContractId__c = cnt.Id;
            cli.ARC_OriginalPrice__c = 100.00;
        }

        cLineItems[0].vlocity_ins__Product2Id__c = prods[0].Id;
        cLineItems[1].vlocity_ins__Product2Id__c = prods[1].Id;
        cLineItems[2].vlocity_ins__Product2Id__c = prods[2].Id;
        cLineItems[3].vlocity_ins__Product2Id__c = prods[3].Id;

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

        cnt.ARC_AppFeeOrder__c = existingOrder.Id;
        update cnt;

        ARC_PromotionCode__c promotionCode = new ARC_PromotionCode__c(
            ARC_StartDate__c =  Date.valueOf('2025-06-18'),
            ARC_EndDate__c = null,
            ARC_ApplyFirst__c = false,
            ARC_ApplyOver__c = 'Medical',
            RecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Promotion_Discount').getRecordTypeId(),
            Name = 'LUC20',
            ARC_PromotionCode__c = 'LUC20',
            ARC_DiscountType__c = 'First Month Payment',
            ARC_DiscountRate__c = 15,
            ARC_DiscountedAmount__c = null
        );
        insert promotionCode;
        
        ARC_PromotionDiscount__c promotionDiscount = new ARC_PromotionDiscount__c(
            RecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Promotion_Discount').getRecordTypeId(),
            ARC_Agent__c = UserInfo.getUserId(),
            ARC_ApplyFirst__c = false,
            ARC_ApplyOver__c = 'Medical',
            ARC_PromoCode__c = promotionCode.Id,
            ARC_Status__c = 'Activated',
            ARC_Contract__c = cnt.Id,
            ARC_NumberOfTimesCanBeUsed__c = 1,
            ARC_TimesUsed__c = 0,
            ARC_AmountToDiscountPerTransaction__c = 30.39,
            ARC_CorePriceWithoutDiscount__c = 202.6,
            ARC_EndDate__c = null
        );
        insert promotionDiscount;
    }

    // Same test to dateOfBirthChange
    @isTest
    static void primaryChange() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
      //  ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
        List<vlocity_ins__ProductChildItem__c> childItems = [SELECT Id FROM vlocity_ins__ProductChildItem__c ORDER BY CreatedDate LIMIT 2];


        // Census Member
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => members[0].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'IsInactiveMember' => false,
                'PersonContactId' => members[0].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'CopyAddressFromPrimary' => true,
                'vlocity_ins__FirstName__c' => 'Carl',
                'vlocity_ins__LastName__c' => 'Test',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2015-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Relationship__c' => 'Spouse',
                'Id' => members[1].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'IsInactiveMember' => false,
                'PersonContactId' => members[1].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[1].Id,
                'CopyAddressFromPrimary' => true,
                'vlocity_ins__FirstName__c' => 'Mary',
                'vlocity_ins__LastName__c' => 'Test',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2000-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
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
                'IsRemoveMember' => false,
                'RF_Census.CM_Relationship' => 'Primary'
            }
        };

        // Create Chargent Order Record
        Account acc = new Account(Name = 'Test Account');
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
        
        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => groupAccount[0].Id,
            'TXT_ContractStatus' => 'Awaiting Activation',
            'GroupAccountName' => 'Test Group',
            'ContractID' => cnt.Id
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => prods[0].Id,
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItems[0].Id
                            }
                        }
                    } 
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' =>  members[0].Id, 'RF_Census.CM_FirstName' => 'Carl', 'RF_Census.CM_LastName' => 'Test', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'Mary', 'RF_Census.CM_LastName' => 'Test', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            },
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => prods[1].Id,
                    'Name' => 'AIDD 7500',
                    'ProductCode' => 'PROG_AIDD_7500',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Ancillary',
                    'SubType__c' => 'AIDD',
                    'IsRecommended__c' => false,
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => false, 
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[1].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 50.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[3].Id,
                                'Name' => 'Program Benefits AIDD',
                                'ProductCode' => 'CS_General_AIDD',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[3].Id,
                                'pciId' => childItems[1].Id
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' =>  members[0].Id, 'RF_Census.CM_FirstName' => 'Carl', 'RF_Census.CM_LastName' => 'Test', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'Mary', 'RF_Census.CM_LastName' => 'Test', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
            

        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'primaryChange' => true,
            'dateOfBirthChange' => true,
            'effectiveDateChange' => false,
            'ancillaryChange' => false,
            'programDowngrade' => false,
            'programUpgrade' => false,
            'relationshipToPrimaryChange' => false,
            'addressStateChange' => false,
            'addExistingMember' => false,
            'effectiveDateChange' => false,
            'removeMember' => false,
            'addMember' => false
        };

        // STEP_ChangeSelect
        Map<String, Object> STEP_ChangeSelect = new Map<String, Object>{
            'SEL_ReasonsForChange' => null,
            'SEL_UpdateTypes' => 'Demographic Updates',
            'FRML_IsReasonSelected' => false,
            'FRML_IsOtherReasonSelected' => false,
            'TXT_OtherReason' => null
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasonsString' => 'Date of Birth Change; Primary change',
            'feeApplicable' => false,
            'pcReasons' => pcReasons,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true,            
            'feeAmount' => 0,
            'carryOverMedicalQuestions' => false
        };

        Map<String, Object> aRC_DatePicker = new Map<String, object> {
            'DATE_SubscriberEffectiveDate' => '2025-06-15'
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_GuardiansInfo' => null,
            'STEP_ChangeSelect' => STEP_ChangeSelect,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => null,
            'SelectedContractInfo' => selectedContractInfo,
            'userId' => UserInfo.getUserId(),
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => new Map<String, Object> {
                'MSG_EffectiveDateMissing' => null,
                'FRML_EffectiveDateSelected' => true,
                'aRC_DatePicker' => aRC_DatePicker
            },
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'ContractCount' => 1,
            'STEP_HIPAAAuthorizationForm' => null,
            'EffectiveDate'=> '2025-06-15'
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // manager and mapper
        ARC_PCBaseService baseService = new ARC_PCBaseService();
       // ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
       // ARC_PCMapper mapper = new ARC_PCMapper();
       // ARC_PCDML DML = new ARC_PCDML();

        // Call the method
        Test.startTest();
        baseService.invokeMethod('processChanges', inputMap, outputMap, options);
      //  mapper.executeChanges(manager);
       // DML.manageDML(manager);
        Test.stopTest();

       /* // Assert for guardian
        System.assertEquals(1, manager.guardiansToInsert.size(), 'one guardian inserted');
        // Assert for UW Case
        System.assertEquals(1, manager.casesUWToInsert.size(), 'must be created a one uw case');
        // Assert for Contract
        System.assertEquals(1, manager.contractsToInsert.size(), 'Must be one contract inserted');
        // Assert for Contract Participant
        System.assertEquals(2, manager.personAccIdOrFakeIdToContractPart.size(), 'Must exist two contract participants');
        // Assert for Chargent Order
        System.assertEquals(1, manager.chargentOrdersRecurringOrder.size(), 'must be created a charge order'); */
    }

    // Same test to relationshipToPrimaryChange | programDowngrade | programUpgrade (with upsertMedicalQuesitons) | ancillaryChange | removeAllAncillary
    // RAD_KeepRecurringMethodOfPayment = NO, Credit Card 
    @isTest
    static void programUpgrade() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1]; 

        // UW Case
        List<Case> listCase = ARC_TestUtility.createTestCase(1, 'Admission');
        ARC_UnderwritingCaseMember__c UWCaseMembers = new ARC_UnderwritingCaseMember__c (
            ARC_ApprovalResolution__c = 'Pending',
            ARC_Member__c = members[0].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            ARC_Reason__c = 'Add Member',
            ARC_Score__c = 1,
            Name = 'TestUWCaseMember',
            ARC_Description__c = 'testing uw case member',
            ARC_UnderwritingCase__c = listCase[0].Id,
            ARC_Contract__c = cnt.Id,
            ARC_LastStatusUpdate__c = Date.Today()
        );
        insert UWCaseMembers;

        listCase[0].Status = 'New';
        listCase[0].ARC_Reason__c = 'Underwriting';
        listCase[0].ARC_Contract__c = cnt.Id;
        upsert listCase;

        // Case fee
        Map<String, Object> BLK_CaseCreationDetails = new Map<String, Object>{
            'TXT_NoChargeChangeFeeReason' => 'I dont want to charge the fee now'
        };
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'No',
            'BLK_CaseCreationDetails' => BLK_CaseCreationDetails,
            'BLK_ChargeFee' => null
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
                'PersonContactId' => members[0].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        // Create Chargent Order Record
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
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItem.Id
                            }
                        }
                    } 
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[0].Id, 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => true, 'RF_Census.CRF_Coverage' => 'Primary', 'RF_Census.CRF_CoverageAIDD' => 'Primary', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'programUpgrade' => true,
            'effectiveDateChange' => false,
            'ancillaryChange' => false,
            'programDowngrade' => false,
            'dateOfBirthChange' => false,
            'relationshipToPrimaryChange' => false,
            'addressStateChange' => false,
            'primaryChange' => false,
            'addExistingMember' => false,
            'removeMember' => false,
            'addMember' => false
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasonsString' => 'Program Upgrade',
            'feeApplicable' => true,
            'pcReasons' => pcReasons,
            'programSummaryFeeText' => 'One Time Change Fee (Program Upgrade): 99.000',
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true,
            'feeAmount' => 99,
            'carryOverMedicalQuestions' => false
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges,
            'EffectiveDate' => '04/01/2025',
            'census_component' => censusComponent,
            'STEP_GuardiansInfo' => null,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => stepPaymentFee,
            'SelectedContractInfo' => selectedContractInfo,
            'userId' => UserInfo.getUserId(),
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => null,
            'price_calculation' => priceCalc,
            'STEP_MedicalQuestions' => null,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'ContractCount' => 1,
            'STEP_HIPAAAuthorizationForm' => null
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_PCBaseService baseService = new ARC_PCBaseService();

        // Call the method
        Test.startTest();
        baseService.invokeMethod('processChanges', inputMap, outputMap, options);
        Test.stopTest();
    }

    // Same test to addMember (updateGCMaddMember) | addExistingMember (updateGCMaddExistingMember)
    // RAD_KeepRecurringMethodOfPayment = NO, Bank Account
    @isTest
    static void addMember() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 1];
        Contract cnt = [SELECT Id, AccountId FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
       // ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1];

        List<Case> listCase = ARC_TestUtility.createTestCase(1, 'Admission');
        listCase[0].ARC_Contract__c = cnt.Id;
        upsert listCase;
        ARC_UnderwritingCaseMember__c UWCaseMembers = new ARC_UnderwritingCaseMember__c (
            ARC_ApprovalResolution__c = 'Pending',
            ARC_Member__c = members[0].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            ARC_Reason__c = 'Add Member',
            ARC_Score__c = 1,
            Name = 'TestUWCaseMember',
            ARC_Description__c = 'testing uw case member',
            ARC_UnderwritingCase__c = listCase[0].Id,
            ARC_Contract__c = cnt.Id,
            ARC_LastStatusUpdate__c = Date.Today()
        );
        insert UWCaseMembers;

        // medical questions...
        Map<String, Object> medicalQuestions = new Map<String, Object>{
            'BLK_ParentSiblingDiagnosed' => new Map<String, Object>{
                'CHKBOX_MemberParentDiagnosed' => true,
                'DATE_MemberParentDiagnosed' => '2025-05-01',
                'TXTAREA_MemberParentDiagnosed' => 'q1',
                'memberId' => 'MEM-1746542563528270',
                'TXT_MemberParentDiagnosed' => 'Vicky Vector',
                'TXT_MemberIdParentDiagnosed' => 'MEM-1747050829654895'
            },
            'EB_Cancer' => new Map<String, Object>{
                'CHK_CheckCancer' => true,
                'TXT_MemberNameCancer' => 'Vicky Vector',
                'TXT_MemberIdCancer' => 'MEM-1746542563528270',
                'TXT_TypeOfCancer' => 'skin cancer',
                'DATE_Cancer' => '2025-05-01'
            },
            'FRML_ParentSiblingDiagnosedNull' => false,
            'MSG_WrongUnexpectedDate' => null,
            'ED_MemberPrescription' => new Map<String, Object>{
                'TXT_MemberName' => 'Vicky Vector',
                'TXT_MemberIdPrescription' => 'MEM-1746542563528270',
                'TXT_NameOfMedication' => 'paracetamol',
                'TXT_DatePrescribed' => '2025-01-27',
                'TXT_DateDiscontinued' => '2025-04-28',
                'TXT_ReasonForMedication' => 'no reason',
                'TXT_PrescribingPhysician' => 'Dr. Q'
            },
            'EB_Physicians' => new List<Object> {
                new Map<String, Object>{
                    'memberId' => 'MEM-1746542563528270',
                    'TXT_PhysicianName' => 'Dr. Carl',
                    'TXT_PhysicianCity' => 'San Diego',
                    'TXT_PhysicianPhone' => '6666666666'
                },
                new Map<String, Object> {
                    'memberId' => members[1].Id,
                    'TXT_hasErrorPCP' => 'false',
                    'TXT_PhysicianPhone' => '2222222333',
                    'TXT_PhysicianCity' => 'San Dieguito',
                    'TXT_PhysicianName' => 'Physician TwoMember edited',
                    'TXT_CensusMemberName' => 'TwoMember Member'
                }
            }
        };


        for (vlocity_ins__GroupCensusMember__c cm : members) {
            cm.Name = 'Member1 Test1';
            cm.ARC_PhysicianCity__c = 'San Diego';
            cm.ARC_PhysicianName__c = 'testPhysician';
            cm.ARC_PhysicianPhone__c = '3333333333';
        }

        upsert members;

        ARC_MedicalConditions__c medicalContition1 = new ARC_MedicalConditions__c (
            Name = 'Member1 Test1-Medical Condition',
            ARC_CensusMember__c = members[1].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            ARC_Active__c = true,
            ARC_ParentsOrSiblingsDiagnosed__c = true,
            ARC_ParentsOrSiblingsDiagnosedNote__c = 'test organ transplant',
            ARC_ParentsOrSiblingsDiagnosedDate__c = date.valueOf('2020-05-01'),
            ARC_UnexplainedConditions__c = true,
            ARC_Unexplained_Conditions_Notes__c = 'test  mental health symptoms',
            ARC_Unexplained_Conditions_Date__c = date.valueOf('2021-05-09'),
            ARC_Tests__c = true,
            ARC_Tests_Notes__c = 'test surgeries pending',
            ARC_Tests_Date__c = date.valueOf('2022-05-16'),
            ARC_IllegalDrugsAlcohol__c = true,
            ARC_Illegal_Drugs_Alcohol_Notes__c = 'test drug use',
            ARC_Illegal_Drugs_Alcohol_Date__c = date.valueOf('2023-05-02'),
            ARC_LicenceSuspended__c = true,
            ARC_LicenceSuspendedNote__c = 'test license suspended',
            ARC_LicenseSuspendedDate__c = date.valueOf('2024-05-11'),
            ARC_Condition__c = 'Down’s Syndrome;Hepatitis (Chronic Viral B & C);Lupus',
            ARC_OtherConditions__c = 'test other conditions',
            ARC_Currently_Under_Treatment__c = false
        );

        ARC_MedicalConditions__c medicalContition2 = new ARC_MedicalConditions__c (
            Name = 'Member1 Test1-Medical Condition',
            ARC_CensusMember__c = members[1].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            ARC_Active__c = true,
            ARC_Type_Of_Cancer__c = 'test cancer',
            ARC_Year_Diagnosed_Cancer__c = date.valueOf('2010-04-26')
        );

        List<ARC_MedicalConditions__c> listMedical = new List<ARC_MedicalConditions__c>{medicalContition1, medicalContition2};

        vlocity_ins__ConsumerDrug__c medicalContition3 = new vlocity_ins__ConsumerDrug__c (
            Name = 'Paracetamol',
            ARC_Active__c = true,
            ARC_CensusMember__c = members[1].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            vlocity_ins__MedicationStartDate__c = date.valueOf('2024-04-01'),
            vlocity_ins__MedicationEndDate__c = date.valueOf('2025-04-01'),
            vlocity_ins__PrescribedBy__c = 'physician test',
            vlocity_ins__IsActive__c = false
        );

        insert listMedical;
        insert medicalContition3;
        
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
     /*   Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'Change Fee',
            'PromotionCodeId' => promo.Id,
            'ApplyOver' => 'Change Fee',
            'DiscountAmount' => '99.00',
            'MedicalPrice' => null,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '0.00',
            'AgentId' => UserInfo.getUserId()
        }; */
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_MethodOfPayment' => 'Bank Account',
                'RAD_KeepRecurringMethodOfPayment' => 'No',
                'LWC_PromoDiscountCodeRefactor' => null,
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
        Map<String, Object> TXTNewAdressBlock = new Map<String, Object>{
            'TXT_NewAdress' => 'Siempre Viva Ct, San Diego, CA 92154, USA',
            'TXT_AddAddress' => 'Siempre Viva Court',
            'TXT_AddZipCode' => '92154',
            'TXT_AddCity' => 'San Diego',
            'TXT_AddCountry' => 'United States',
            'SEL_AddState' => 'CA'
        };

        Map<String, Object> NewHipaa = new Map<String, Object>{
            'TXT_NewFirstName' => 'Venus',
            'TXT_NewLastName' => 'Velocity',
            'TXT_NewBirthdate' => '1999-05-04',
            'TXT_NewTelephone' => '2222222222',
            'TXT_NewEmailAdress' => 'latalih346@benznoi.com',
            'TXT_NewAdress-Block' => TXTNewAdressBlock
        };

        Map<String, Object> internalParty = new Map<String, Object>{
            'Id' => 'MEM-1746542563528270',
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
            'TXT_FullName' => 'Mercurio Retrogrado',
            'TXT_State' => 'CA'
        };

        List<Object> authorizedParties = new List<Object>{ internalParty };

        Map<String, Object> stepHipaa = new Map<String, Object>{
            'Formula1' => 1,
            'NewHipaa' => NewHipaa,
            'Formula2' => false,
            'EDITBLK_HIPAAAuthorizedParties' => authorizedParties,
            'RAD_AuthorizeOthers' => 'Yes'
        };

        // Census Member
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Relationship__c' => 'Spouse',
                'Id' => 'MEM-1746542563528270',
                'IsNewMember' => true,
                'IsRemoveMember' => false,
                'PersonContactId' => null,
                'PersonAccountId' => null,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => members[1].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'IsInactiveMember' => true,
                'CopyAddressFromPrimary' => true,
                'PersonContactId' => members[1].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'vlocity_ins__FirstName__c' => 'Test',
                'vlocity_ins__LastName__c' => 'Tester',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__Birthdate__c' => '2000-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123456799',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        Map<String, Object> primaryMember = new Map<String, Object>{
            'vlocity_ins__IsPrimaryMember__c' => true,
            'Id' => members[0].Id,
            'vlocity_ins__MemberIdentifier__c' => '2025-03-24T19:17:44.157Z'
        };
        Map<String, Object> oldProduct = new Map<String, Object>{
            'Type__c' => 'Medical',
            'census_members' => new List<Object>{ primaryMember }
        };

        List<Object> oldProductsList = new List<Object>{ oldProduct };

        // userInputs
       /* List<Object> userInputs = new List<Object>{
            new Map<String, Object>{
                'Id' => 'MEM-1746542563528270',
                'IsAddExistingMember' => false,
                'IsNewMember' => true,
                'IsRemoveMember' => false,
                'RF_Census.CM_Relationship' => 'Spouse'

            },
            new Map<String, Object>{
                'Id' => members[0].Id,
                'IsAddExistingMember' => true,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'RF_Census.CM_Relationship' => 'Primary'
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
        insert existingOrder; */

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
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItem.Id
                            }
                        }
                    } 
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => true, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => 'MEM-1746542563528270', 'RF_Census.CM_FirstName' => 'TestAdded', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => false, 'IsNewMember' => true,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        Map<String, Object> STEP_ChangeSelect = new Map<String, Object>{
            'SEL_UpdateTypes' => 'Add or Remove a Member',
            'FRML_IsReasonSelected' => false,
            'SEL_ReasonsForChange' => null,
            'FRML_IsOtherReasonSelected' => false,
            'TXT_OtherReason' => null
        };

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
            'oldProducts' => oldProductsList,
            'STEP_HIPAAAuthorizationForm' => stepHipaa,
            'STEP_MedicalQuestions' => medicalQuestions,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'STEP_ChangeSelect' => STEP_ChangeSelect,
            'FRML_DisplayEffDateStep' => true,
            'EffectiveDate'=> '2025-06-15'
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // manager and mapper
        ARC_PCBaseService baseService = new ARC_PCBaseService();
      
        // Call the method
        Test.startTest();
        baseService.invokeMethod('processChanges', inputMap, outputMap, options);
        Test.stopTest();
    }

    // Remove Member
    // RAD_KeepRecurringMethodOfPayment = YES, Bank Account
    @isTest
    static void createChargentOrdersOldBank() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1];


        
        ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_MethodOfPayment' => 'Bank Account',
                'RAD_KeepRecurringMethodOfPayment' => 'Yes',
                'LWC_PromoDiscountCodeRefactor' => new Map<String, Object> {
                    'Id' => 'null',
                    'PromotionCodeId' => promo.Id,
                    'PromotionCodeName' => 'LUC20',
                    'ApplyOver' => 'Medical',
                    'DiscountAmount' => '41.02',
                    'MedicalPrice' => 273.44,
                    'DiscountPrice' => '232.42',
                    'AgentId' => UserInfo.getUserId()
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
                'PersonContactId' => members[0].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Relationship__c' => 'Spouse',
                'Id' => members[1].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => true,
                'PersonContactId' => members[1].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[1].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
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
                'IsRemoveMember' => false,
                'RF_Census.CM_Relationship' => 'Primary'
            },
            new Map<String, Object>{
                'Id' => members[1].Id,
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => true,
                'RF_Census.CM_Relationship' => 'Spouse'
            }
        };

        // Create Chargent Order Record
        Account acc = new Account(Name = 'Old Bank Acc');
        insert acc;

        Contract con = new Contract(AccountId = acc.Id, StartDate = Date.today(), Status = 'Draft');
        insert con;

        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
       //     Id = chgateway.Id,
            Name = 'Bank Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Bank Account',
            ChargentBase__Active__c = true
        );
        insert gateway;

        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
          //  Id = chargentOrder.Id,
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
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItem.Id
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[0].Id, 'RF_Census.CM_FirstName' => 'TestPrimary', 'RF_Census.CM_LastName' => 'MemberTest', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'TestRemoved', 'RF_Census.CM_LastName' => 'RemovedTest', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => true, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
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

        Map<String, Object> aRC_DatePicker = new Map<String, object> {
            'DATE_SubscriberEffectiveDate' => '2025-06-15'
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
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => new Map<String, Object> {
                'aRC_DatePicker' => aRC_DatePicker
            },
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'STEP_HIPAAAuthorizationForm' => null,
            'EffectiveDate'=> '2025-06-15'
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_PCBaseService baseService = new ARC_PCBaseService();
       
        // Call the method
        Test.startTest();
        baseService.invokeMethod('processChanges', inputMap, outputMap, options);
        Test.stopTest();
    }

    // RAD_KeepRecurringMethodOfPayment = YES, Credit Card
    @isTest
    static void createChargentOrdersOldCreditCard() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
       // ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1];
       
        // Promo Discount info
     /*   Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'Change Fee',
            'PromotionCodeId' => promo.Id,
            'ApplyOver' => 'Change Fee',
            'DiscountAmount' => '99.00',
            'MedicalPrice' => null,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '0.00',
            'AgentId' => UserInfo.getUserId()
        }; */
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_MethodOfPayment' => 'Credit Card',
                'RAD_KeepRecurringMethodOfPayment' => 'Yes',
                'LWC_PromoDiscountCodeRefactor' => null
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
                'PersonContactId' => members[0].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Relationship__c' => 'Child',
                'Id' => members[1].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' => members[1].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[1].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
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
                'IsRemoveMember' => false,
                'RF_Census.CM_Relationship' => 'Primary'

            },
            new Map<String, Object>{
                'Id' => members[1].Id,
                'IsAddExistingMember' => false,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'RF_Census.CM_Relationship' => 'Spouse'
            }
        };

        // Create Chargent Order Record
        Account acc = new Account(Name = 'Old Payment Test');
        insert acc;

        Contract con = new Contract(AccountId = acc.Id, StartDate = Date.today(), Status = 'Draft');
        insert con;

        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
          //  Id = chgateway.Id,
            Name = 'Old Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Credit Card',
            ChargentBase__Active__c = true
        );
        insert gateway;

        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
           // Id = chargentOrder.Id,
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
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItem.Id
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[0].Id, 'RF_Census.CM_FirstName' => 'TestPrimary', 'RF_Census.CM_LastName' => 'MemberTest', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'TestRemoved', 'RF_Census.CM_LastName' => 'RemovedTest', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'removeMember' => false,
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

        Map<String, Object> aRC_DatePicker = new Map<String, object> {
            'DATE_SubscriberEffectiveDate' => '04/01/2025'
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
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => new Map<String, Object> {
                'aRC_DatePicker' => aRC_DatePicker
            },
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'STEP_HIPAAAuthorizationForm' => null,
            'EffectiveDate'=> '2025-04-01'
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // manager and mapper
        ARC_PCBaseService baseService = new ARC_PCBaseService();
      //  ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
       // ARC_PCMapper mapper = new ARC_PCMapper();
       // ARC_PCDML DML = new ARC_PCDML();


        // Call the method
        Test.startTest();
        baseService.invokeMethod('processChanges', inputMap, outputMap, options);
      //  mapper.executeChanges(manager);
      //  DML.manageDML(manager);
        Test.stopTest();

        // Assert for guardian
      /*  System.assertEquals(0, manager.guardiansToInsert.size(), 'No guardian inserted');
        // Assert for UW Case
        System.assertEquals(1, manager.casesUWToInsert.size(), 'must be created a one uw case');
        // Assert for Contract
        System.assertEquals(1, manager.contractsToInsert.size(), 'Must be one contract inserted');
        // Assert for Contract Participant
        System.assertEquals(2, manager.personAccIdOrFakeIdToContractPart.size(), 'Must exist 2 contract participant');
        // Assert for Chargent Order
        System.assertEquals(1, manager.chargentOrdersRecurringOrder.size(), 'must be created a charge order');*/
    }

    // effectiveDateChange (Future)
    @isTest
    static void effectiveDateChange() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
      //  ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1];
        
        // Promo Discount info
      /*  Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'Change Fee',
            'PromotionCodeId' => promo.Id,
            'ApplyOver' => 'Change Fee',
            'DiscountAmount' => '99.00',
            'MedicalPrice' => null,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '0.00',
            'AgentId' => UserInfo.getUserId()
        }; */
    
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_MethodOfPayment' => 'Bank Account',
                'RAD_KeepRecurringMethodOfPayment' => 'No',
                'LWC_PromoDiscountCodeRefactor' => null,
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
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => members[0].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' =>members[0].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
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
                'IsRemoveMember' => false,
                'RF_Census.CM_Relationship' => 'Primary'
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
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItem.Id
                            }
                        }
                    } 
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[0].Id, 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'removeMember' => false ,
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

        Map<String, Object> aRC_DatePicker = new Map<String, object> {
            'DATE_SubscriberEffectiveDate' => '2025-06-15'
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
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => new Map<String, Object> {
                'aRC_DatePicker' => aRC_DatePicker
            },
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'STEP_HIPAAAuthorizationForm' => null,
            'EffectiveDate'=> '2025-06-15'
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // manager and mapper
        ARC_PCBaseService baseService = new ARC_PCBaseService();
       // ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
      //  ARC_PCMapper mapper = new ARC_PCMapper();
      //  ARC_PCDML DML = new ARC_PCDML();


        // Call the method
        Test.startTest();
        baseService.invokeMethod('processChanges', inputMap, outputMap, options);
       // mapper.executeChanges(manager);
       // DML.manageDML(manager);
        Test.stopTest();
        /*
        // Assert for guardian
        System.assertEquals(0, manager.guardiansToInsert.size(), 'No guardian inserted');
        // Assert for UW Case
        System.assertEquals(1, manager.casesUWToInsert.size(), 'must be created a one uw case');
        // Assert for Contract
        System.assertEquals(1, manager.contractsToInsert.size(), 'Must be one contract inserted');
        // Assert for Contract Participant
        System.assertEquals(1, manager.personAccIdOrFakeIdToContractPart.size(), 'Must exist one contract participant');
        // Assert for Chargent Order
        System.assertEquals(1, manager.chargentOrdersRecurringOrder.size(), 'must be created a charge order');*/
    }

    // Effective back date change (Past)
    @isTest
    static void effectiveBackDateChange() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
        //ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1];
        
        // Promo Discount info
       /* Map<String, Object> promoDiscount = new Map<String, Object>{
            'PromotionCodeName' => 'Change Fee',
            'PromotionCodeId' => promo.Id,
            'ApplyOver' => 'Change Fee',
            'DiscountAmount' => '99.00',
            'MedicalPrice' => null,
            'NumberOfPayments' => 2,
            'DiscountPrice' => '0.00',
            'AgentId' => UserInfo.getUserId()
        };
        */
    
        Map<String, Object> stepPaymentFee = new Map<String, Object>{
            'RAD_ChargeAppFeeDefTrue' => 'Yes',
            'BLK_ChargeFee' => new Map<String, Object>{
                'RAD_MethodOfPayment' => 'Bank Account',
                'RAD_KeepRecurringMethodOfPayment' => 'No',
                'LWC_PromoDiscountCodeRefactor' => null,
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
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => members[0].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' =>members[0].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
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
                'IsRemoveMember' => false,
                'RF_Census.CM_Relationship' => 'Primary'
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
            'ContractID' => cnt.Id,
            'EffectiveDate' => '07/01/2025',
            'SelectedContract' => true
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => prods[0].Id,
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItem.Id
                            }
                        }
                    } 
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[0].Id, 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'effectiveDateChange' => true,
            'ancillaryChange' => false ,
            'programDowngrade' => false ,
            'programUpgrade' => false ,
            'dateOfBirthChange' => false ,
            'relationshipToPrimaryChange' => false ,
            'addressStateChange' => false ,
            'primaryChange' => false ,
            'addExistingMember' => false ,
            'removeMember' => false ,
            'addMember' => false
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'pcReasonsString' => 'Effective Date Change',
            'feeApplicable' => false,
            'feeAmount' => 0,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => false,
            'effectiveBackDateChange' => true
        };

        Map<String, Object> aRC_DatePicker = new Map<String, object> {
            'DATE_SubscriberEffectiveDate' => '2025-06-01'
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
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => new Map<String, Object> {
                'aRC_DatePicker' => aRC_DatePicker
            },
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'BackdateEffectiveDate' => 'Backdate_Effective_Date',
            'FullPermissionEffectiveDate' => 'Full_Permission_Effective_Date',
            'ContractCount' => 1,
            'STEP_Census' => null,
            'execute_reprice_flag' => false,
            'STEP_HIPAAAuthorizationForm' => null,
            'EffectiveDate'=> '2025-06-01'

        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_PCBaseService baseService = new ARC_PCBaseService();

        // Call the method
        Test.startTest();
        baseService.invokeMethod('processChanges', inputMap, outputMap, options);
        Test.stopTest();
    }

    @isTest
    static void demographicUpdates() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1];
        

        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => groupAccount[0].Id,
            'GroupAccountName' => 'Test Group',
            'ContractID' => cnt.Id
        };
        Map<String, Object> primaryMember = new Map<String, Object>{
            'Id' => members[0].Id,
            'vlocity_ins__MemberIdentifier__c' => '2025-03-24T19:17:44.157Z',
            'vlocity_ins__IsPrimaryMember__c' => true
        };
    
        Map<String, Object> oldProduct = new Map<String, Object>{
            'Type__c' => 'Medical',
            'census_members' => new List<Object>{ primaryMember }
        };

        Map<String, Object> updatedMember1 = new Map<String, Object>{
            'vlocity_ins__IsPrimaryMember__c' => true,
            'ARC_Relationship__c' => 'Primary',
            'ARC_isPregnant__c' => '',
            'Id' => members[0].Id,
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'IsInactiveMember' => false,
            'PersonContactId' => members[0].vlocity_ins__ContactId__c,
            'PersonAccountId' => accounts[0].Id,
            'CopyAddressFromPrimary' => true,
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
            'vlocity_ins__SocialSecurityNumber__c' => '123456789',
            'ARC_HeightFeet__c' => '5',
            'ARC_HeightInches__c' => '10',
            'ARC_Weight__c' => '180',
            'ARC_Smoker__c' => false
        };
        Map<String, Object> updatedMember2 = new Map<String, Object>{
            'vlocity_ins__IsPrimaryMember__c' => false,
            'ARC_Relationship__c' => 'Spouse',
            'Id' => members[1].Id,
            'ARC_isPregnant__c' => '',
            'IsInactiveMember' => false,
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'PersonContactId' =>  members[1].vlocity_ins__ContactId__c,
            'PersonAccountId' => accounts[1].Id,
            'CopyAddressFromPrimary' => true,
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
            'vlocity_ins__SocialSecurityNumber__c' => '123456789',
            'ARC_HeightFeet__c' => '5',
            'ARC_HeightInches__c' => '10',
            'ARC_Weight__c' => '180',
            'ARC_Smoker__c' => false
        };
    
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => new List<Object>{ updatedMember1, updatedMember2 }
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => prods[0].Id,
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItem.Id
                            }
                        }
                    } 
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[0].Id, 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'TestAdded', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        Map<String, Object> inputMap = new Map<String, Object>{
            'census_component' => censusComponent,
            'SelectedContractInfo' => selectedContractInfo,
            'EffectiveDate' => '2025-04-01',
            'STEP_EffectiveDate' => null,
            'userId' => UserInfo.getUserId(),
            'price_calculation' => priceCalc,
            'oldProducts' => new List<Object>{ oldProduct },
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'STEP_HIPAAAuthorizationForm' => null
        };
    
        inputMap.put('demographicUpdates', true);
    
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'demographicChange' => true,
            'addressStateChange' => true
        };
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'createNewContract' => true
        };
        inputMap.put('pcChanges', pcChanges);
    
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // manager and mapper
        ARC_PCBaseService baseService = new ARC_PCBaseService();
       // ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
      //  ARC_PCMapper mapper = new ARC_PCMapper();
       // ARC_PCDML DML = new ARC_PCDML();

    
        Test.startTest();
        baseService.invokeMethod('processChanges', inputMap, outputMap, options);
       // mapper.executeChanges(manager);
        //DML.manageDML(manager);
        Test.stopTest();
    
        //System.assertEquals(2, manager.censusMembersDemographicChange.size(), 'Must be one member with demographic updates');
    }

    @isTest
    static void addressStateChange() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Contract> oldContracts = ARC_TestUtility.createContracts(1);
        insert oldContracts;
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
      //  ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1];


        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => members[0].Id,
                'ARC_isPregnant__c' => '',
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' => members[0].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Relationship__c' => 'Spouse',
                'ARC_isPregnant__c' => '',
                'Id' => members[1].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' => members[1].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[1].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        Map<String, Object> primaryMember = new Map<String, Object>{
            'vlocity_ins__IsPrimaryMember__c' => true,
            'Id' => members[0].Id,
            'vlocity_ins__MemberIdentifier__c' => '2025-03-24T19:17:44.157Z'
        };
        Map<String, Object> oldProduct = new Map<String, Object>{
            'Type__c' => 'Medical',
            'census_members' => new List<Object>{ primaryMember }
        };

        List<Object> oldProductsList = new List<Object>{ oldProduct };

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

        //stepSelecContract
        Map<String, Object> stepSelecContract  = new Map<String, Object>{
            'ContractID' => oldContracts[0].Id,
            'GroupAccountId' => groupAccount[0].Id,
            'TXT_ContractStatus' => 'Awaiting Approval'
        };

        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => groupAccount[0].Id,
            'TXT_ContractStatus' => 'Awaiting Activation',
            'GroupAccountName' => 'Test Group',
            'ContractID' => cnt.Id
        };

        List<Object> ebContractList = new List<Object>{ stepSelecContract, selectedContractInfo };


        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => prods[0].Id,
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItem.Id
                            }
                        }
                    } 
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[0].Id, 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'TestAdded', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{
            'addressStateChange' => true,
            'effectiveDateChange' => false,
            'ancillaryChange' => false,
            'programDowngrade' => false,
            'programUpgrade' => false,
            'dateOfBirthChange' => false,
            'relationshipToPrimaryChange' => false,
            'primaryChange' => false,
            'addExistingMember' => false,
            'removeMember' => false,
            'addMember' => false
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'feeApplicable' => false,
            'pcReasonsString' => 'State Change',
            'pcReasons' => pcReasons,
            'amendmentReasons' => 'Primary Address State Changed',
            'docuSign' => 'Amendment',
            'createNewContract' => true,
            'feeAmount' => 0,
            'carryOverMedicalQuestions' => false
        };
        Map<String, Object> aRC_DatePicker = new Map<String, object> {
            'DATE_SubscriberEffectiveDate' => '2025-06-15'
        };
        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'ContractCount' => 2, 
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_Census' => null,
            'STEP_GuardiansInfo' => null,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => null,
            'SelectedContractInfo' => selectedContractInfo,
            'STEP_SelectContract' => new Map<String, Object>{
                'EB_ContractList' => ebContractList,
                'FRML_CheckIfContractIsSelected' => true 
            },
            'userId' => UserInfo.getUserId(),
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => new Map<String, Object> {
                'aRC_DatePicker' => aRC_DatePicker
            },
            'EffectiveDate' => '2025-06-15',
            'price_calculation' => priceCalc,
            'oldProducts' => oldProductsList,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'STEP_PlanSelection' => null,
            'STEP_ChooseProductSelection' => null,
            'STEP_HIPAAAuthorizationForm' => null,
            'STEP_MedicalQuestions' => null,
            'STEP_PlansSummary' => null,
            'primaryState' => 'CA',
            'demographicUpdates' => true,
            'ED_MemberPrescription' => null
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // manager and mapper
        ARC_PCBaseService baseService = new ARC_PCBaseService();
      //  ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
       // ARC_PCMapper mapper = new ARC_PCMapper();
       // ARC_PCDML DML = new ARC_PCDML();


        // Call the method
        Test.startTest();
        baseService.invokeMethod('processChanges', inputMap, outputMap, options);
       // mapper.executeChanges(manager);
       // DML.manageDML(manager);
        Test.stopTest();

        //System.assertEquals(2, manager.censusMembersToUpdate.size(), 'must be one member with change state');
    }

    @isTest
    static void updateEnvelopeContractDataTest() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
       // ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
        List<vlocity_ins__ProductChildItem__c> childItems = [SELECT Id FROM vlocity_ins__ProductChildItem__c ORDER BY CreatedDate LIMIT 2];


        // Census Member
        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => members[0].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'IsInactiveMember' => false,
                'PersonContactId' => members[0].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'CopyAddressFromPrimary' => true,
                'vlocity_ins__FirstName__c' => 'Carl',
                'vlocity_ins__LastName__c' => 'Test',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2015-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Relationship__c' => 'Spouse',
                'Id' => members[1].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'IsInactiveMember' => false,
                'PersonContactId' => members[1].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[1].Id,
                'CopyAddressFromPrimary' => true,
                'vlocity_ins__FirstName__c' => 'Mary',
                'vlocity_ins__LastName__c' => 'Test',
                'ARC_PhysicalAddressStreet__c' => '123 Main St',
                'ARC_PhysicalAddressCity__c' => 'Denver',
                'ARC_PhysicalAddressState__c' => 'CO',
                'ARC_PhysicalAddressZipCode__c' => '80202',
                'vlocity_ins__MemberIdentifier__c' => '2025-03-21T14:13:04.982Z',
                'vlocity_ins__Birthdate__c' => '2000-03-12',
                'vlocity_ins__Gender__c' => 'Male',
                'vlocity_ins__Email__c' => 'john.doe@example.com',
                'ARC_Phone__c' => '5551234567',
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
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
                'IsRemoveMember' => false,
                'RF_Census.CM_Relationship' => 'Primary'
            }
        };

        // Create Chargent Order Record
        Account acc = new Account(Name = 'Test Account');
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
        
        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => groupAccount[0].Id,
            'TXT_ContractStatus' => 'Awaiting Activation',
            'GroupAccountName' => 'Test Group',
            'ContractID' => cnt.Id
        };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => prods[0].Id,
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItems[0].Id
                            }
                        }
                    } 
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' =>  members[0].Id, 'RF_Census.CM_FirstName' => 'Carl', 'RF_Census.CM_LastName' => 'Test', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'Mary', 'RF_Census.CM_LastName' => 'Test', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            },
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => prods[1].Id,
                    'Name' => 'AIDD 7500',
                    'ProductCode' => 'PROG_AIDD_7500',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Ancillary',
                    'SubType__c' => 'AIDD',
                    'IsRecommended__c' => false,
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => false, 
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[1].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 50.0,
                    'RawPriceData' => new Map<String, Object>(),
                    'childProducts' => new Map<String, Object>{
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[3].Id,
                                'Name' => 'Program Benefits AIDD',
                                'ProductCode' => 'CS_General_AIDD',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[3].Id,
                                'pciId' => childItems[1].Id
                            }
                        }
                    }
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' =>  members[0].Id, 'RF_Census.CM_FirstName' => 'Carl', 'RF_Census.CM_LastName' => 'Test', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'Mary', 'RF_Census.CM_LastName' => 'Test', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
            

        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'primaryChange' => true,
            'dateOfBirthChange' => true,
            'effectiveDateChange' => false,
            'ancillaryChange' => false,
            'programDowngrade' => false,
            'programUpgrade' => false,
            'relationshipToPrimaryChange' => false,
            'addressStateChange' => false,
            'addExistingMember' => false,
            'effectiveDateChange' => false,
            'removeMember' => false,
            'addMember' => false
        };

        // STEP_ChangeSelect
        Map<String, Object> STEP_ChangeSelect = new Map<String, Object>{
            'SEL_ReasonsForChange' => null,
            'SEL_UpdateTypes' => 'Demographic Updates',
            'FRML_IsReasonSelected' => false,
            'FRML_IsOtherReasonSelected' => false,
            'TXT_OtherReason' => null
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasonsString' => 'Date of Birth Change; Primary change',
            'feeApplicable' => false,
            'pcReasons' => pcReasons,
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true,            
            'feeAmount' => 0,
            'carryOverMedicalQuestions' => false
        };

        Map<String, Object> aRC_DatePicker = new Map<String, object> {
            'DATE_SubscriberEffectiveDate' => '2025-06-15'
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_GuardiansInfo' => null,
            'STEP_ChangeSelect' => STEP_ChangeSelect,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => null,
            'SelectedContractInfo' => selectedContractInfo,
            'userId' => UserInfo.getUserId(),
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => new Map<String, Object> {
                'MSG_EffectiveDateMissing' => null,
                'FRML_EffectiveDateSelected' => true,
                'aRC_DatePicker' => aRC_DatePicker
            },
            'price_calculation' => priceCalc,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'ContractCount' => 1,
            'STEP_HIPAAAuthorizationForm' => null,
            'EnvelopeContractData' => new Map<String, Object> {
                'signerEmail' => 'tester@test.com',
                'signerName' => 'Test Tester',
                'envelopeId' => '81f51431-e4de-4fcc-b92d-00a910866ac6',
                'contractId' => cnt.Id
            }
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
   
        ARC_PCBaseService baseService = new ARC_PCBaseService();

        // Call the method
        Test.startTest();
        baseService.invokeMethod('updateEnvelopeContractData', inputMap, outputMap, options);
        Test.stopTest();
    }

    @isTest
    static void updateEnvelopeContractDataTestCatch() {
        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'EnvelopeContractData' => new Map<String, Object> {
                'signerEmail' => 'tester@test.com',
                'signerName' => 'Test Tester',
                'envelopeId' => '81f51431-e4de-4fcc-b92d-00a910866ac6',
                'contractId' => null
            }
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
   
        ARC_PCBaseService baseService = new ARC_PCBaseService();

        Boolean error = false;
        // Call the method
        Test.startTest();
        try {
            baseService.invokeMethod('updateEnvelopeContractData', inputMap, outputMap, options);
        } catch (Exception e) {
            error = true;
            System.assert(e instanceof DmlException, 'Expected DmlException');
        }
        Test.stopTest();
        System.assert(error);
    }

    // This test is to cover the catch in ARC_PCBaseService AND DML
    @isTest
    static void errorTestDML() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 2];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 2];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 2];
        Contract cnt = [SELECT Id FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Contract> oldContracts = ARC_TestUtility.createContracts(1);
        insert oldContracts;
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
        ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1];

        List<Case> listCase = ARC_TestUtility.createTestCase(1, 'Admission');
        listCase[0].ARC_Contract__c = cnt.Id;
        upsert listCase;
        ARC_UnderwritingCaseMember__c UWCaseMembers = new ARC_UnderwritingCaseMember__c (
            ARC_ApprovalResolution__c = 'Pending',
            ARC_Member__c = members[0].Id,
            ARC_PersonAccount__c = accounts[0].Id,
            ARC_Reason__c = 'Add Member',
            ARC_Score__c = 1,
            Name = 'TestUWCaseMember',
            ARC_Description__c = 'testing uw case member',
            ARC_UnderwritingCase__c = listCase[0].Id,
            ARC_Contract__c = cnt.Id,
            ARC_LastStatusUpdate__c = Date.Today()
        );
        insert UWCaseMembers;

        List<Map<String, Object>> censusMembers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Relationship__c' => 'Primary',
                'Id' => members[0].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' => members[0].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[0].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '599',
                'ARC_HeightInches__c' => '10',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            },
            new Map<String, Object>{
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Relationship__c' => 'Spouse',
                'Id' => members[1].Id,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'PersonContactId' => members[1].vlocity_ins__ContactId__c,
                'PersonAccountId' => accounts[1].Id,
                'CopyAddressFromPrimary' => true,
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
                'vlocity_ins__SocialSecurityNumber__c' => '123456789',
                'ARC_HeightFeet__c' => '56',
                'ARC_HeightInches__c' => '160',
                'ARC_Weight__c' => '180',
                'ARC_Smoker__c' => false
            }
        };
        Map<String, Object> censusComponent = new Map<String, Object>{
            'census_members' => censusMembers
        };

        Map<String, Object> primaryMember = new Map<String, Object>{
            'vlocity_ins__IsPrimaryMember__c' => true,
            'Id' => members[0].Id,
            'vlocity_ins__MemberIdentifier__c' => '2025-03-24T19:17:44.157Z'
        };
        Map<String, Object> oldProduct = new Map<String, Object>{
            'Type__c' => 'Medical',
            'census_members' => new List<Object>{ primaryMember }
        };

        List<Object> oldProductsList = new List<Object>{ oldProduct };

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

        //stepSelecContract
        Map<String, Object> stepSelecContract  = new Map<String, Object>{
            'ContractID' => oldContracts[0].Id,
            'GroupAccountId' => groupAccount[0].Id,
            'TXT_ContractStatus' => 'Awaiting Approval'
        };

        // selectedContractInfo
        Map<String, Object> selectedContractInfo = new Map<String, Object>{
            'GroupAccountId' => groupAccount[0].Id,
            'TXT_ContractStatus' => 'Awaiting Activation',
            'GroupAccountName' => 'Test Group',
            'ContractID' => cnt.Id
        };

        List<Object> ebContractList = new List<Object>{ stepSelecContract, selectedContractInfo };

        // Contract Line Items info
        List<Object> plans = new List<Object>{
            new Map<String, Object>{
                'selectedProduct' => new Map<String, Object>{
                    'Id' => prods[0].Id,
                    'Name' => 'WeShare 6k',
                    'ProductCode' => 'PROG_UHSM_WeShare6k',
                    'MarketSegment__c' => 'Individual',
                    'Type__c' => 'Medical',
                    'SubType__c' => 'PPO',
                    'IsRecommended__c' => false,
                    'PricingSource__c' => 'Configurable',
                    'RecordTypeName__c' => 'Product',
                    'IsConfigurable__c' => true,
                    'PricingFormula__c' => 'Price',
                    'productId' => prods[0].Id,
                    'currencyCode' => 'USD',
                    'currencySymbol' => '$',
                    'Price' => 520.23,
                    'RawPriceData' => new Map<String, Object>(), 
                    'childProducts' => new Map<String, Object>{ 
                        'totalSize' => 1,
                        'records' => new List<Object>{
                            new Map<String, Object>{
                                'Id' => prods[2].Id,
                                'Name' => 'Preventative Care',
                                'ProductCode' => 'ARC_UHSMPreventativeCare',
                                'Type__c' => 'Medical',
                                'IsRecommended__c' => false,
                                'RecordTypeName__c' => 'CoverageSpec',
                                'IsConfigurable__c' => true,
                                'Term__c' => 'Annual',
                                'isOptional' => false,
                                'isSelected' => true,
                                'productId' => prods[2].Id,
                                'pciId' => childItem.Id
                            }
                        }
                    } 
                },
                'userInputs' => new List<Object>{
                    new Map<String, Object>{ 'Id' => members[0].Id, 'RF_Census.CM_FirstName' => 'Test', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => true, 'RF_Census.CM_Relationship' => 'Primary', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false, 'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1},
                    new Map<String, Object>{ 'Id' => members[1].Id, 'RF_Census.CM_FirstName' => 'TestAdded', 'RF_Census.CM_LastName' => 'Tester', 'RF_Census.CM_IsPrimary' => false, 'RF_Census.CM_Relationship' => 'Spouse', 'RF_Census.CM_Age' => 25, 'RF_Census.CM_State' => 'CO', 'RF_Census.CM_Smoker' => false, 'RF_Census.CM_Pregnant' => false,
                    'IsRemoveMember' => false, 'IsNewMember' => false,  'IsAddExistingMember' => false, 'RF_Census.CRF_Coverage' => 'Primary + Spouse', 'RF_Census.CRF_CoverageAIDD' => 'Primary + Spouse', 'RF_Census.CRF_ExtraDependants' => 0, 'RF_Census.CRF_PrimaryMemberAge' => 25, 'RF_Census.CRF_Dependants' => 1}
                }
            }
        };
        Map<String, Object> priceCalc = new Map<String, Object>{ 'plans' => plans };

        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{
            'addressStateChange' => true,
            'effectiveDateChange' => true,
            'ancillaryChange' => true,
            'programDowngrade' => true,
            'programUpgrade' => true,
            'dateOfBirthChange' => true,
            'relationshipToPrimaryChange' => true,
            'primaryChange' => true,
            'addExistingMember' => true,
            'removeMember' => true,
            'addMember' => true,
            'removeAllAncillary' => true
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'feeApplicable' => false,
            'pcReasonsString' => 'State Change',
            'pcReasons' => pcReasons,
            'amendmentReasons' => 'Primary Address State Changed',
            'docuSign' => 'Amendment',
            'createNewContract' => true,
            'feeAmount' => 0,
            'carryOverMedicalQuestions' => false
        };
        Map<String, Object> aRC_DatePicker = new Map<String, object> {
            'DATE_SubscriberEffectiveDate' => '2025-06-15'
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'ContractCount' => 2, 
            'pcChanges' => pcChanges,
            'census_component' => censusComponent,
            'STEP_Census' => null,
            'STEP_GuardiansInfo' => null,
            'GuardianPhysicalStreetApt' => 'Siempre Viva Court Apt/Unit 34',
            'Step_PaymentChangeFee' => null,
            'SelectedContractInfo' => selectedContractInfo,
            'STEP_SelectContract' => new Map<String, Object>{
                'EB_ContractList' => ebContractList,
                'FRML_CheckIfContractIsSelected' => true 
            },
            'userId' => UserInfo.getUserId(),
            'CensusId' => members[0].vlocity_ins__CensusId__c,
            'STEP_EffectiveDate' => new Map<String, Object> {
                'aRC_DatePicker' => aRC_DatePicker
            },
            'EffectiveDate' => '2025-06-15',
            'price_calculation' => priceCalc,
            'oldProducts' => oldProductsList,
            'PlansSummary' => new Map<String, Object>{
                'BLK_ProductSummary' => new Map<String, Object>{
                    'TXT_MonthlyPrice' => '$677.21'
                }
            },
            'STEP_PlanSelection' => null,
            'STEP_ChooseProductSelection' => null,
            'STEP_HIPAAAuthorizationForm' => null,
            'STEP_MedicalQuestions' => null,
            'STEP_PlansSummary' => null,
            'primaryState' => 'CA',
            'demographicUpdates' => true,
            'ED_MemberPrescription' => null
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        ARC_PCBaseService baseService = new ARC_PCBaseService();

        Boolean error = false;
        Test.startTest();
        try {
            baseService.invokeMethod('processChanges', inputMap, outputMap, options);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'Script-thrown exception');
            error = true;
        }        
        Test.stopTest();
        System.assert(error);
    }

     // This test is to cover the catch in Manager
    @isTest
    static void errorTestManager() {
        // inputMap
        Map<String, Object> inputMap = null;
        Map<String, Object> pcReasons = null;
        
        ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);

        Boolean error = false;
        Test.startTest();
        try {
            manager.executeAll();
        } catch (Exception e) {
            error = true;
        }        
        Test.stopTest();
        System.assert(error);
    }

    @isTest
    static void test_handleDemographicChangeFuture_ifMaxFieldSize() {
        String tooLongName = '';
        for (Integer i = 0; i < 2000; i++) {
            tooLongName += 'X';
        }
        String jsonCensusMembers =
            '[{"attributes":{"type":"vlocity_ins__GroupCensusMember__c"},"Name":"' +
            tooLongName + '"}]';

        String fullJson = '';
        for (Integer i = 0; i < 140000; i++) {
            fullJson += 'Y';
        }

        Id fakeAccId = '001000000000000AAA';

        Test.startTest();
        ARC_PCDML.handleDemographicChangeFuture(
            new List<Id>(),
            jsonCensusMembers,
            fullJson,
            fakeAccId
        );
        try {
            Test.stopTest(); 
            System.assert(false, 'must launch exception @future.');
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'exception.');
        }
    }

    @isTest
    static void future_rethrows_with_long_fullJson() {
        Account acc = new Account(Name = 'Ctx Long');
        insert acc;

        String jsonUWCase        = 'null'; 
        String jsonUWCaseMembers = '[]';

        Integer TARGET = 140000;
        String fullJson = 'xxxxxxxxxxxxxxxx';
        while (fullJson.length() < TARGET) {
            fullJson += fullJson; 
        }
        fullJson = fullJson.substring(0, TARGET);

        Boolean rethrew = false;

        Test.startTest();
        ARC_PCDML.handleUWCaseAndMembersFuture(
            jsonUWCase,
            /* contractId     */ null,
            /* feeOrderId     */ null,
            /* recurringOrder */ null,
            jsonUWCaseMembers,
            fullJson,
            acc.Id,
            /* jsonPromotionDiscount */ null,
            /* jsonTasksToInsert     */ null,
            /* jsonTasksToUpdate     */ null,
            /* paymentStartDate      */ null
        );
        try {
            Test.stopTest(); 
        } catch (Exception e) {
            rethrew = true;
        }

        System.assert(
            rethrew == false,
            'Exception while processing UW case and members in future context'
        );
    }

    @isTest
    static void testMapperReasons() {
        // pcReasons
        Map<String, Object> pcReasons = new Map<String, Object>{ 
            'agingOut' => true
        };

        // STEP_ChangeSelect
        Map<String, Object> STEP_ChangeSelect = new Map<String, Object>{
            'SEL_ReasonsForChange' => null,
            'SEL_UpdateTypes' => 'Demographic Updates',
            'FRML_IsReasonSelected' => false,
            'FRML_IsOtherReasonSelected' => false,
            'TXT_OtherReason' => null
        };

        // pcChanges
        Map<String, Object> pcChanges = new Map<String, Object>{
            'pcReasons' => pcReasons,
            'createNewContract' => true
        };

        // inputMap
        Map<String, Object> inputMap = new Map<String, Object>{
            'pcChanges' => pcChanges
        };

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // manager and mapper
        //ARC_PCBaseService baseService = new ARC_PCBaseService();
        ARC_PCManager manager = new ARC_PCManager(pcReasons, inputMap);
        ARC_PCMapper mapper = new ARC_PCMapper();
        Boolean error = false;
        Test.startTest();
        try {
            mapper.executeChanges(manager);
        } catch (Exception e) {
            error = true;
        }
        Test.stopTest();

        System.assert(error, 'must launch exception.');
    }
}