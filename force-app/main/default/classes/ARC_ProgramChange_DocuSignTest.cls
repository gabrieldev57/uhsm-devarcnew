@isTest
private class ARC_ProgramChange_DocuSignTest {

    @TestSetup
    static void makeData(){
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(3);
        List<Contact> contacts = ARC_TestUtility.createTestContact(3, 'Contact');
        List<Account> accounts = ARC_TestUtility.createTestAccount(3, 'ARC_IFPPersonAccount');
        List<Account> groupAccount = ARC_TestUtility.createTestAccount(1, 'Group');
        List<vlocity_ins__ContractLineItem__c> cLineItems = ARC_TestUtility.createTestContractLineItem(4);
        List<vlocity_ins__GroupCensusMemberPlan__c> gcMemberPlans = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        List<Product2> prods = ARC_TestUtility.createTestProducts(4);
        Id rtProduct = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id rtCoverageSpec = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Coverage Spec').getRecordTypeId();
        

        Integer i = 0;

        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test1', vlocity_ins__ContractLineId__c=cLineItems[0].Id, vlocity_ins__GroupCensusMemberId__c=members[0].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test2', vlocity_ins__ContractLineId__c=cLineItems[1].Id, vlocity_ins__GroupCensusMemberId__c=members[1].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test3', vlocity_ins__ContractLineId__c=cLineItems[0].Id, vlocity_ins__GroupCensusMemberId__c=members[2].Id));


        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test4', vlocity_ins__ContractLineId__c=cLineItems[2].Id, vlocity_ins__GroupCensusMemberId__c=members[0].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test5', vlocity_ins__ContractLineId__c=cLineItems[3].Id, vlocity_ins__GroupCensusMemberId__c=members[1].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test6', vlocity_ins__ContractLineId__c=cLineItems[1].Id, vlocity_ins__GroupCensusMemberId__c=members[2].Id));
        insert gcMemberPlans;

        for (vlocity_ins__GroupCensusMember__c cm : members) {
            if(i == 0) cm.vlocity_ins__IsPrimaryMember__c = true;
            if(i == 1) cm.ARC_DependentRelationship__c = 'Spouse';
            if(i == 1) cm.ARC_DependentRelationship__c = 'Child';

            if(i == 0) cm.vlocity_ins__ContactId__c = contacts[0].Id;
            if(i == 1) cm.vlocity_ins__ContactId__c = contacts[1].Id;
            if(i == 1) cm.vlocity_ins__ContactId__c = contacts[2].Id;
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
            ARC_StartDate__c =  Date.valueOf('2025-01-01'),
            ARC_EndDate__c = null,
            ARC_ApplyFirst__c = false,
            ARC_ApplyOver__c = 'Change Fee',
            RecordTypeId = Schema.SObjectType.ARC_PromotionCode__c.getRecordTypeInfosByDeveloperName().get('Promotion_Discount').getRecordTypeId(),
            Name = 'Change Fee',
            ARC_PromotionCode__c = 'Change Fee',
            ARC_DiscountType__c = 'Change Fee',
            ARC_DiscountRate__c = 100
        );
        insert promotionCode;
        
        ARC_PromotionDiscount__c promotionDiscount = new ARC_PromotionDiscount__c(
            RecordTypeId = Schema.SObjectType.ARC_PromotionDiscount__c.getRecordTypeInfosByDeveloperName().get('Promotion_Discount').getRecordTypeId(),
            ARC_Agent__c = UserInfo.getUserId(),
            ARC_ApplyFirst__c = false,
            ARC_ApplyOver__c = 'Change Fee',
            ARC_PromoCode__c = promotionCode.Id,
            ARC_Status__c = 'Activated',
            ARC_Contract__c = cnt.Id,
            ARC_NumberOfTimesCanBeUsed__c = 6,
            ARC_TimesUsed__c = 0,
            ARC_AmountToDiscountPerTransaction__c = 99,
            ARC_EndDate__c = null
        );
        insert promotionDiscount;
    }

    @isTest
    static void DocuSignDataTransformTest() {
        List<vlocity_ins__GroupCensusMember__c> members = [SELECT Id, vlocity_ins__AccountId__c, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 3];
        List<Account> groupAccount =  [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Group' ORDER BY CreatedDate LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate LIMIT 3];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 3];
        Contract cnt = [SELECT Id, AccountId FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> prods = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 4];
        ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];
        vlocity_ins__ProductChildItem__c childItem = [SELECT Id FROM vlocity_ins__ProductChildItem__c LIMIT 1];

        Map<String, Object> SelectedContractInfo = new Map<String, Object>{
            'ContractID' => cnt.Id,
            'SelectedContract' => true,
            'DATE_CreatedDate' => '2025-05-22',
            'EffectiveDate' => '06/01/2025',
            'GroupAccountId' => groupAccount[0].Id,
            'GroupAccountName' => 'Carl Beer Family',
            'GuardianId' => null,
            'SV_NameListStatus' => true,
            'SV_MemberListStatus' => true,
            'LoopBlockIterationStatus' => true,
            'LoopBlockIterationIndex' => 2,
            'TXT_ContractNumber' => '00091631',
            'TXT_ContractStatus' => 'Awaiting Signature',
            'TXT_ContractReason' => 'Add Member',
            'TXT_MedicalPlan' => 'WeShare 6k',
            'TXT_Members' => 'Carl Beer, Mary Beer, Gaby Beer'
        };

        Map<String, Object> pcChanges = new Map<String, Object> {
            'pcReasonsString' => 'Add Member',
            'feeApplicable' => true,
            'pcReasons' => new Map<String, Object> {
                'effectiveDateChange' => false,
                'ancillaryChange' => false,
                'programDowngrade' => false,
                'programUpgrade' => false,
                'dateOfBirthChange' => false,
                'relationshipToPrimaryChange' => false,
                'addressStateChange' => false,
                'primaryChange' => false,
                'addExistingMember' => false,
                'removeMember' => false,
                'addMember' => true
            },
            'docuSign' => 'PC DocuSign',
            'createNewContract' => true,
            'feeAmount' => 99,
            'carryOverMedicalQuestions' => true
        };

        List<Map<String, Object>> oldUserInputs = new List<Map<String, Object>> {
            new Map<String, Object> {
                'CensusMemberFirstName' => 'Carl',
                'CensusMemberLastName' => 'Beer',
                'LastName' => 'Beer',
                'FirstName' => 'Carl',
                'CensusMemberId' => members[0].Id
            },
            new Map<String, Object> {
                'CensusMemberFirstName' => 'Mary',
                'CensusMemberLastName' => 'Beer',
                'LastName' => 'Beer',
                'FirstName' => 'Mary',
                'CensusMemberId' => members[1].Id
            }
        };

        List<Map<String, Object>> newUserInputs = new List<Map<String, Object>> {
            new Map<String, Object> {
                'CensusMemberFirstName' => 'Gaby',
                'CensusMemberLastName' => 'Beer',
                'LastName' => 'Beer',
                'FirstName' => 'Gaby',
                'CensusMemberId' => 'MEM-1748006579105335'
            }
        };

        List<Map<String, Object>> allUserInputs = new List<Map<String, Object>> {
            new Map<String, Object> {
                'CensusMemberFirstName' => 'Carl',
                'CensusMemberLastName' => 'Beer',
                'LastName' => 'Beer',
                'FirstName' => 'Carl',
                'CensusMemberId' => members[0].Id
            },
            new Map<String, Object> {
                'CensusMemberFirstName' => 'Mary',
                'CensusMemberLastName' => 'Beer',
                'LastName' => 'Beer',
                'FirstName' => 'Mary',
                'CensusMemberId' => members[1].Id
            },
            new Map<String, Object> {
                'CensusMemberFirstName' => 'Gaby',
                'CensusMemberLastName' => 'Beer',
                'LastName' => 'Beer',
                'FirstName' => 'Gaby',
                'CensusMemberId' => 'MEM-1748006579105335'
            }
        };

        Map<String, Object> OldProduct1 = new Map<String, Object> {
            'selectedProduct' => new Map<String, Object> {
                'productId' => prods[0].Id,
                'Type__c' => 'Medical',
                'Id' => prods[0].Id,
                'Price' => 520.23,
                'Name' => 'WeShare 6k'
            },
            'userInputs' => oldUserInputs
        };

        Map<String, Object> OldProduct2 = new Map<String, Object> {
            'selectedProduct' => new Map<String, Object> {
                'productId' => prods[1].Id,
                'Type__c' => 'Ancillary',
                'Id' => prods[1].Id,
                'Price' => 49.55,
                'Name' => 'SMART Share 45000'
            },
            'userInputs' => oldUserInputs
        };

         Map<String, Object> NewProduct1 = new Map<String, Object> {
            'selectedProduct' => new Map<String, Object> {
                'productId' => prods[0].Id,
                'Type__c' => 'Medical',
                'Id' => prods[0].Id,
                'Price' => 520.23,
                'Name' => 'WeShare 6k'
            },
            'userInputs' => newUserInputs
        };

        Map<String, Object> NewProduct2 = new Map<String, Object> {
            'selectedProduct' => new Map<String, Object> {
                'productId' => prods[1].Id,
                'Type__c' => 'Ancillary',
                'Id' => prods[1].Id,
                'Price' => 49.55,
                'Name' => 'SMART Share 45000'
            },
            'userInputs' => newUserInputs
        };

        List<Map<String, Object>> OldProductList = new List<Map<String, Object>> {
            OldProduct1,
            OldProduct2
        };

        List<Map<String, Object>> NewProductList = new List<Map<String, Object>> {
            NewProduct1,
            NewProduct2
        };

        Map<String, Object> SignTheDocument = new Map<String, Object> {
            'CHK_AgreeingSigning' => true,
            'Recipient-Block' => new Map<String, Object> {
                'Recipient' => 'Carl Beer - nosetep608@bamsrad.com',
                'Id' => members[0].Id,
                'FirstName' => 'Carl',
                'Name' => 'Carl Beer',
                'LastName' => 'Beer',
                'label' => 'Carl Beer - nosetep608@bamsrad.com',
                'role' => 'Primary',
                'value' => 'nosetep608@bamsrad.com'
            },
            'RecipientReadOnly-Block' => null,
            'CHKBX_DoNotSendEmail' => null,
            'FRLM_isMemberServicesManagerUser' => false,
            'FRLM_SendEmail' => true
        };

        Map<String, Object> MedicalQuestions = new Map<String, Object> {
            'BLK_ParentSiblingDiagnosed' => new Map<String, Object> {
                'CHKBOX_MemberParentDiagnosed' => true,
                'DATE_MemberParentDiagnosed' => '2023-04-30',
                'memberId' => 'MEM-1748006579105335',
                'TXT_hasErrorParentDiagnosed' => 'false',
                'TXT_MemberIdParentDiagnosed' => 'MEM-1748006579105335',
                'TXT_MemberParentDiagnosed' => 'Gaby Beer'
            },
            'FRML_ParentSiblingDiagnosedNull' => false,
            'MSG_WrongUnexpectedDate' => null,
            'BLK_UnexpectedSymptoms' => new Map<String, Object> {
                'CHKBOX_UnexpectedSymptoms' => true,
                'DATE_MemberUnexpectedSymptoms' => '2024-04-29',
                'TXTAREA_MemberUnexpectedSymptoms' => 'testing mental health symptoms',
                'memberId' => 'MEM-1748006579105335',
                'TXT_hasError' => false,
                'TXT_MemberIdUnexpectedSymptoms' => 'MEM-1748006579105335',
                'TXT_MemberUnexpectedSymptoms' => 'Gaby Beer'
            },
            'FRML_CheckSymptoms' => false,
            'FRML_DateUnexpectedWrong' => false,
            'BLK_PendingTests' => new Map<String, Object> {
                'CHKBOX_PendingTests' => true,
                'DATE_MemberPendingTests' => '2022-05-06',
                'TXTAREA_MemberPendingTests' => 'testing surgeries pending',
                'memberId' => 'MEM-1748006579105335',
                'TXT_MemberIdPendingTests' => 'MEM-1748006579105335',
                'TXT_MemberPendingTests' => 'Gaby Beer'
            },
            'FRML_CheckPendingTests' => false,
            'LWC_SelectCensusMemberCancer' => new Map<String, Object> {
                'SelectedCensusMemberName' => 'Gaby Beer',
                'SelectedCensusMemberId' => 'MEM-1748006579105335',
                'SelectedCensusMemberBirthdate' => '2000-05-11'
            },
            'EB_Cancer' => new Map<String, Object> {
                'FRML_MemberIdCancerBirthdate' => '2000-05-11T00:00:00.000Z',
                'CHK_CheckCancer' => true,
                'CHK_MemberBeenDiagnosedWithCancer' => true,
                'TXT_MemberNameCancer' => 'Gaby Beer',
                'TXT_MemberIdCancer' => 'MEM-1748006579105335',
                'TXT_hasErrorCancer' => 'false',
                'TXT_TypeOfCancer' => 'Skyn Cancer',
                'DATE_Cancer' => '2025-05-06'
            },
            'FRML_CheckCancer' => false,
            'MSG_DateWrongCancer' => null,
            'MSG_WrongDateAddiction' => null,
            'FRML_DateWrongCancer' => false,
            'BLK_Addictions' => new Map<String, Object> {
                'CHKBOX_Addictions' => true,
                'DATE_MemberAddictions' => '2021-04-29',
                'TXTAREA_MemberAddictions' => 'testing alcohol or drug use',
                'memberId' => 'MEM-1748006579105335',
                'TXT_hasErrorAdiction' => 'false',
                'TXT_MemberIdAddictions' => 'MEM-1748006579105335',
                'TXT_MemberAddictions' => 'Gaby Beer'
            },
            'FRML_CheckAddictions' => false,
            'FMRL_WrongDateAddictions' => false,
            'BLK_LicenceSuspended' => new Map<String, Object> {
                'CHKBOX_LicenceSuspended' => true,
                'DATE_MemberLicenceSuspended' => '2024-05-22',
                'TXTAREA_MemberLicenceSuspended' => 'testing DUI for drugs or alcohol',
                'memberId' => 'MEM-1748006579105335',
                'TXT_hasErrorLicenceSuspended' => 'false',
                'TXT_MemberIdLicenceSuspended' => 'MEM-1748006579105335',
                'TXT_MemberLicenceSuspended' => 'Gaby Beer'
            },
            'FRML_LicenceSuspended' => false,
            'EB_PastConditions' => new Map<String, Object> {
                'memberId' => 'MEM-1748006579105335',
                'TXT_MemberIdPastConditions' => 'MEM-1748006579105335',
                'TXT_MemberPastConditions' => 'Gaby Beer',
                'MULSEL_Conditions' => 'Alcohol Abuse;ALS;Cerebral Palsy;Ectasia;Treatment with Naloxone, Suboxone, Methadone or any other medication to treat addiction within the past 5 years',
                'TXT_MemberOtherPastConditions' => 'testing other condition'
            },
            'FRML_CheckPastConditionsNull' => false,
            'MSG_DateWrongPrescription' => null,
            'LWC_SelectCensusMember' => new Map<String, Object> {
                'SelectedCensusMemberName' => 'Gaby Beer',
                'SelectedCensusMemberId' => 'MEM-1748006579105335'
            },
            'ED_MemberPrescription' => new Map<String, Object> {
                'FRML_MemberBirthdate' => null,
                'TXT_MemberName' => 'Gaby Beer',
                'TXT_MemberIdPrescription' => 'MEM-1748006579105335',
                'TXT_hasErrorMedication' => 'false',
                'TXT_NameOfMedication' => 'Paracetamol',
                'TXT_DatePrescribed' => '2024-04-01',
                'TXT_DateDiscontinued' => '2025-04-29',
                'TXT_ReasonForMedication' => 'testing medication',
                'TXT_PrescribingPhysician' => 'testing prescribing physician'
            },
            'FRML_CheckPrescriptionsIsNull' => false,
            'FRML_DateWrongPrescription' => false,
            'MSG_WrongDatePCP' => null,
            'FRML_WrongDatePCP' => false,
            'EB_Physicians' => new List<Map<String, Object>> {
                new Map<String, Object> {
                    'memberId' => members[0].Id,
                    'TXT_hasErrorPCP' => 'false',
                    'TXT_CensusMemberId' => members[0].Id,
                    'TXT_CensusMemberName' => 'Carl Beer'
                },
                new Map<String, Object> {
                    'memberId' => members[1].Id,
                    'TXT_hasErrorPCP' => 'false',
                    'TXT_CensusMemberId' => members[1].Id,
                    'TXT_CensusMemberName' => 'Mary Beer'
                },
                new Map<String, Object> {
                    'memberId' => 'MEM-1748006579105335',
                    'TXT_hasErrorPCP' => 'false',
                    'TXT_CensusMemberId' => 'MEM-1748006579105335',
                    'TXT_CensusMemberName' => 'Gary Beer',
                    'TXT_PhysicianName' => 'Carla',
                    'TXT_PhysicianCity' => 'San Diego',
                    'TXT_PhysicianPhone' => '5555555555'
                }    
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
                'hasErrorUnexpected' => false,
                'hasErrorAddictions' => false,
                'hasErrorPCP' => false,
                'hasErrorCancer' => false,
                'hasErrorMedication' => false
            }  
        };

        Map<String, Object> PaymentChangeFee = new Map<String, Object> {
            'BLK_ChargeFee' => new Map<String, Object> {
                'RAD_MethodOfPayment' => 'Bank Account',
                'BLK_PaymentInfo' => new Map<String, Object> {
                    'BLK_CreditCard' => null,
                    'BLK_BankAccount' => new Map<String, Object> {
                        'TXT_RoutingNumber' => '557788899',
                        'TXT_AccNumber' => '545454545454545',
                        'TXT_LastNameOnAccount' => 'Roulling',
                        'TXT_FirstNameOnAccount' => 'JK',
                        'TXT_BankName' => 'Santander',
                        'SLC_AccType' => 'Checking'
                    }
                },
                'RAD_KeepRecurringMethodOfPayment' => 'No',
                'LWC_PromoDiscountCodeRefactor' => new Map<String, Object> {
                    'Id' => null,
                    'PromotionCodeId' => promo.Id,
                    'PromotionCodeName' => 'RECURRING DISCOUNT',
                    'ApplyOver' => 'Medical',
                    'DiscountAmount' => '104.05',
                    'MedicalPrice' => 520.23,
                    'NumberOfPayments' => 2,
                    'DiscountPrice' => '416.18',
                    'AgentId' => UserInfo.getUserId()
                }
            },
            'BLK_CaseCreationDetails' => null,
            'RAD_ChargeAppFeeDefTrue' => 'Yes'
        };

        Map<String, Object> EffectiveDate = new Map<String, Object> {
            'MSG_EffectiveDateMissing' => null,
            'FRML_EffectiveDateSelected' => true,
            'aRC_DatePicker' => new Map<String, Object> {
                'DATE_SubscriberEffectiveDate' => '2025-06-01'
            }
        };

        Map<String, Object> PlanSummary = new Map<String, Object> {
            'BLK_ProductSummary' => new Map<String, Object> {
                'TXT_ProgramSummaryFeeText' => null,
                'TXT_FeeAmount' => '$99.00',
                'BLK_ProductsPrices' => new Map<String, Object> {
                    'TXT_EffDate' => '2025-06-01',
                    'BLK_IndividualProducts' => new List<Map<String, Object>> {
                        new Map<String, Object> {
                            'TXT_PlanSelectedPrice' => '$33.04',
                            'TXT_PlanSelected' => 'SMART Share 45000',
                            'Type' => 'Ancillary'
                        },
                        new Map<String, Object> {
                            'TXT_PlanSelectedPrice' => '$520.23',
                            'TXT_PlanSelected' => 'WeShare 6k',
                            'Type' => 'Medical'
                        }
                    }
                },
                'TXT_MonthlyPrice' => '553.27'
            }
        };

        List<Map<String, Object>> Hipaa = new List<Map<String, Object>> {
            new Map<String, Object> {
                'value' => 'nosetep608@bamsrad.com',
                'role' => 'Primary',
                'label' => 'Carl Beer - nosetep608@bamsrad.com',
                'LastName' => 'Beer',
                'Name' => 'Carl Beer',
                'FirstName' => 'Carl',
                'Id' => members[0].Id
            },
            new Map<String, Object> {
                'value' => 'uatagustest@yopmail.com',
                'role' => 'Spouse',
                'label' => 'Mary Beer - uatagustest@yopmail.com',
                'LastName' => 'Beer',
                'Name' => 'Mary Beer',
                'FirstName' => 'Mary',
                'Id' => members[1].Id
            }
        };

        List<Map<String, Object>> allMembersInfo = new List<Map<String, Object>> {
            new Map<String, Object> {
                'DISPLAY_BUTTON_REMOVE_MEMBER' => true,
                'isLast' => false,
                'Id' => members[0].Id,
                'vlocity_ins__FirstName__c' => 'Carl',
                'vlocity_ins__LastName__c' => 'Beer',
                'PersonAccountId' => accounts[0].Id,
                'PersonContactId' => members[0].vlocity_ins__ContactId__c,
                'vlocity_ins__MemberIdentifier__c' => '2025-05-15T15:58:13.541Z',
                'ARC_MiddleInitial__c' => 'B',
                'vlocity_ins__Birthdate__c' => '2000-04-27',
                'vlocity_ins__IsPrimaryMember__c' => true,
                'ARC_Age__c' => 25,
                'vlocity_ins__SocialSecurityNumber__c' => '555555555',
                'showSSN' => 'password',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '7',
                'ARC_Weight__c' => '6',
                'ARC_Smoker__c' => false,
                'ARC_PhysicalAddressCity__c' => 'San Diego',
                'ARC_PhysicalAddressState__c' => 'CA',
                'ARC_PhysicalAddressStreet__c' => 'Siempre Viva Court',
                'ARC_PhysicalAddressZipCode__c' => '92154',
                'ARC_Address__c' => 'San Diego, CA, Siempre Viva Court, 92154',
                'IsDependent' => false,
                'CopyAddressFromPrimary' => true,
                'ShowAddressForDependent' => false,
                'individual_errors' => null,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'ShowMember' => true,
                'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => true,
                'DISABLE_INPUT_FIELDS' => true,
                'ARC_Phone__c' => '4444444444',
                'vlocity_ins__Email__c' => 'nosetep608@bamsrad.com',
                'ARC_isPregnant__c' => false,
                'ARC_Relationship__c' => 'Primary',
                'vlocity_ins__Gender__c' => 'Male'
            },
            new Map<String, Object> {
                'DISPLAY_BUTTON_REMOVE_MEMBER' => true,
                'isLast' => false,
                'Id' => members[1].Id,
                'vlocity_ins__FirstName__c' => 'Mary',
                'vlocity_ins__LastName__c' => 'Beer',
                'PersonAccountId' => accounts[1].Id,
                'PersonContactId' => members[1].vlocity_ins__ContactId__c,
                'vlocity_ins__MemberIdentifier__c' => '1747324811791-0.5902897872642449',
                'ARC_MiddleInitial__c' => null,
                'vlocity_ins__Birthdate__c' => '2000-05-04',
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Age__c' => 25,
                'vlocity_ins__SocialSecurityNumber__c' => '444444444',
                'showSSN' => 'password',
                'ARC_HeightFeet__c' => '5',
                'ARC_HeightInches__c' => '7',
                'ARC_Weight__c' => '6',
                'ARC_Smoker__c' => false,
                'ARC_PhysicalAddressCity__c' => 'San Diego',
                'ARC_PhysicalAddressState__c' => 'CA',
                'ARC_PhysicalAddressStreet__c' => 'Siempre Viva Court',
                'ARC_PhysicalAddressZipCode__c' => '92154',
                'ARC_Address__c' => 'San Diego, CA, Siempre Viva Court, 92154',
                'IsDependent' => true,
                'CopyAddressFromPrimary' => true,
                'ShowAddressForDependent' => false,
                'individual_errors' => null,
                'IsNewMember' => false,
                'IsRemoveMember' => false,
                'ShowMember' => true,
                'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => true,
                'DISABLE_INPUT_FIELDS' => true,
                'ARC_Phone__c' => '3333333333',
                'vlocity_ins__Email__c' => 'uatagustest@yopmail.com',
                'ARC_isPregnant__c' => false,
                'ARC_Relationship__c' => 'Spouse',
                'vlocity_ins__Gender__c' => 'Female'
            },
            new Map<String, Object> {
                'DISPLAY_MODAL_REMOVE_MEMBER' => false,
                'DISPLAY_BUTTON_REMOVE_MEMBER' => true,
                'isLast' => true,
                'Id' => members[2].Id,
                'vlocity_ins__FirstName__c' => 'Gaby',
                'vlocity_ins__LastName__c' => 'Beer',
                'PersonAccountId' => accounts[2].Id,
                'PersonContactId' => contacts[2].Id,
                'vlocity_ins__MemberIdentifier__c' => '1747324811791-0.5902897872642449',
                'ARC_MiddleInitial__c' => 'B',
                'vlocity_ins__Birthdate__c' => '2000-04-27',
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Age__c' => 25,
                'vlocity_ins__SocialSecurityNumber__c' => '333333333',
                'showSSN' => 'password',
                'ARC_HeightFeet__c' => 5,
                'ARC_HeightInches__c' => 4,
                'ARC_Weight__c' => 4,
                'ARC_Smoker__c' => false,
                'ARC_PhysicalAddressCity__c' => 'San Diego',
                'ARC_PhysicalAddressState__c' => 'CA',
                'ARC_PhysicalAddressStreet__c' => 'Siempre Viva Court',
                'ARC_PhysicalAddressZipCode__c' => '92154',
                'ARC_Address__c' => 'San Diego, CA, Siempre Viva Court, 92154',
                'IsDependent' => true,
                'CopyAddressFromPrimary' => true,
                'ShowAddressForDependent' => false,
                'individual_errors' => null,
                'IsNewMember' => true,
                'IsRemoveMember' => false,
                'ShowMember' => true,
                'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                'DISABLE_INPUT_FIELDS' => false,
                'ARC_Phone__c' => '3333333333',
                'vlocity_ins__Email__c' => 'uatagustest@yopmail.com',
                'ARC_isPregnant__c' => false,
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__Gender__c' => 'Male'
            }
        };

        Map<String, Object> inputMap = new Map<String, Object> {
            'MembersInfo' => new Map<String, Object> {
                'primaryMember' => new Map<String, Object> {
                    'Pregnant' => false,
                    'State' => 'CA',
                    'Height' => '5\'7\"',
                    'Phone' => '4444444444',
                    'Gender' => 'Male',
                    'City' => 'San Diego',
                    'Email' => 'nosetep608@bamsrad.com',
                    'DOB' => '2000-04-27',
                    'YearOfBirth' => 2000,
                    'SocialSecurity' => '555555555',
                    'MonthOfBirth' => 4,
                    'DayOfBirth' => 27,
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'Id' => members[0].Id,
                    'MI' => 'B',
                    'Smoker' => false,
                    'FirstName' => 'Carl',
                    'Weight' => '6',
                    'ZipCode' => '92154',
                    'Address' => 'Siempre Viva Court',
                    'LastName' => 'Beer'
                },
                'spouseMember' => new Map<String, Object> {
                    'IsNewMember' => false,
                    'IsRemoveMember' => false,
                    'Id' => members[1].Id,
                    'Height' => '5\'4\"',
                    'DOB' => '2000-05-04',
                    'Email' => 'uatagustest@yopmail.com',
                    'Weight' => '3',
                    'Pregnant' => false,
                    'Gender' => 'Female',
                    'LastName' => 'Beer',
                    'SocialSecurity' => '444444444',
                    'FirstName' => 'Mary',
                    'Smoker' => false
                },
                'dependentMembers' => new List<Object> { 
                    new Map<String, Object> {
                        'IsNewMember' => true,
                        'IsRemoveMember' => false,
                        'SocialSecurity' => '333344444',
                        'Id' => 'MEM-1748006579105335',
                        'Smoker' => false,
                        'Height' => '2\'3\"',
                        'LastName' => 'Beer',
                        'MI' => 'B',
                        'Weight' => 3,
                        'FirstName' => 'Gaby',
                        'Gender' => 'Female',
                        'DOB' => '2000-04-27',
                        'Email' => 'uatagustest@yopmail.com'
                    }
                }
            },
            'EffectiveDate' => '2025-06-01',
            'DocuSign' => new Map<String, Object> {
                'userId' =>  UserInfo.getUserId(),
                'SelectedContractInfo' => SelectedContractInfo,
                'pcChanges' => pcChanges,
                'OldProductList' => OldProductList,
                'NewProductList' => NewProductList,
                'STEP_SignTheDocument' => SignTheDocument,
                'STEP_MedicalQuestions' => MedicalQuestions,
                'Step_PaymentChangeFee' => PaymentChangeFee,
                'STEP_EffectiveDate' => EffectiveDate,
                'PlanSummary' => PlanSummary,
                'Hipaa' => Hipaa
            },
            'newMedicalProduct' => new Map<String, Object> {
                'selectedProduct' => new Map<String, Object>{
                    'Price' => '520.23',
                    'Id' => prods[0].Id,
                    'Type__c' => 'Medical',
                    'productId' => prods[0].Id,
                    'Name' => 'WeShare 6k'
                },
                'userInputs' => allUserInputs
            },
            'UpdateType' =>  'Add or Remove a Member',
            'primaryState' => 'CA',
            'allMembersInfo' => allMembersInfo
        };

        ARC_ProgramChange_DocuSign docuSignPC = new ARC_ProgramChange_DocuSign();
        
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        Test.startTest();
        docuSignPC.invokeMethod('DocuSignDataTransform', inputMap, outputMap, options);
        Test.stopTest();
    }
}