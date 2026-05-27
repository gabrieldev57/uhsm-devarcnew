/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ARC_SpinOff_BaseServiceTest {

    private static void insertTestData(){
        List<vlocity_ins__GroupCensusMember__c> listGCM = ARC_TestUtility.createTestCensusMember(3);
        List<vlocity_ins__GroupCensusMemberPlan__c> listGCMP = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        List<vlocity_ins__ContractLineItem__c> listCLI = ARC_TestUtility.createTestContractLineItem(6);
        List<Product2> listProducts = ARC_TestUtility.createTestProducts(9);
        List<Contact> listContacts = ARC_TestUtility.createTestContact(4, 'Contact');
        List<Account> listAccounts = ARC_TestUtility.createTestAccount(3, 'ARC_IFPPersonAccount');
        List<Account> listGA = ARC_TestUtility.createTestAccount(1, 'Group');

        Id idRTP = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Id idRTCS = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Coverage Spec').getRecordTypeId();

        listContacts[0].Birthdate = Date.valueOf('2000-06-18');
        listContacts[1].Birthdate = Date.valueOf('2000-06-18');
        listContacts[2].Birthdate = Date.valueOf('2000-06-18');
        listContacts[3].Birthdate = Date.valueOf('2000-06-18');
        update listContacts;
        

        // Group Census Member (0: Primary | 1: Spouse | 2: Child)
        listGCM[0].vlocity_ins__IsPrimaryMember__c = true;
        listGCM[0].ARC_DependentRelationship__c = null;
        listGCM[0].vlocity_ins__ContactId__c = listContacts[0].Id;

        listGCM[1].vlocity_ins__IsPrimaryMember__c = false;
        listGCM[1].ARC_DependentRelationship__c = 'Spouse';
        listGCM[1].vlocity_ins__ContactId__c = listContacts[1].Id;

        listGCM[2].vlocity_ins__IsPrimaryMember__c = false;
        listGCM[2].ARC_DependentRelationship__c = 'Child';
        listGCM[2].vlocity_ins__ContactId__c = listContacts[2].Id;
        upsert listGCM;

        // Group Census Member Plan (three per member | 0,1,2: WeShare 6k | 3,4,5: AIDD 5000 | 6,7,8: SMART Share 20000)
        listGCMP.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='WeShare 6k', vlocity_ins__ContractLineId__c=listCLI[0].Id, vlocity_ins__GroupCensusMemberId__c=listGCM[0].Id));
        listGCMP.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='WeShare 6k', vlocity_ins__ContractLineId__c=listCLI[0].Id, vlocity_ins__GroupCensusMemberId__c=listGCM[1].Id));
        listGCMP.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='WeShare 6k', vlocity_ins__ContractLineId__c=listCLI[0].Id, vlocity_ins__GroupCensusMemberId__c=listGCM[2].Id));

        listGCMP.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='AIDD 5000', vlocity_ins__ContractLineId__c=listCLI[1].Id, vlocity_ins__GroupCensusMemberId__c=listGCM[0].Id));
        listGCMP.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='AIDD 5000', vlocity_ins__ContractLineId__c=listCLI[1].Id, vlocity_ins__GroupCensusMemberId__c=listGCM[1].Id));
        listGCMP.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='AIDD 5000', vlocity_ins__ContractLineId__c=listCLI[1].Id, vlocity_ins__GroupCensusMemberId__c=listGCM[2].Id));

        listGCMP.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='SMART Share 20000', vlocity_ins__ContractLineId__c=listCLI[2].Id, vlocity_ins__GroupCensusMemberId__c=listGCM[0].Id));
        listGCMP.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='SMART Share 20000', vlocity_ins__ContractLineId__c=listCLI[2].Id, vlocity_ins__GroupCensusMemberId__c=listGCM[1].Id));
        listGCMP.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='SMART Share 20000', vlocity_ins__ContractLineId__c=listCLI[2].Id, vlocity_ins__GroupCensusMemberId__c=listGCM[2].Id));
        insert listGCMP;

        // Products (0: Medical | 1: AIDD | 2: SMART)
        listProducts[0].RecordTypeId = idRTP;
        listProducts[0].vlocity_ins__Type__c = 'Medical';
        listProducts[0].Name = 'WeShare 6k';

        listProducts[1].RecordTypeId = idRTP;
        listProducts[1].vlocity_ins__Type__c = 'Ancillary';
        listProducts[1].Name = 'AIDD 5000';

        listProducts[2].RecordTypeId = idRTP;
        listProducts[2].vlocity_ins__Type__c = 'Ancillary';
        listProducts[2].Name = 'SMART Share 20000';

        // Child Products (3: ChildProduct Medical | 4: ChildProduct AIDD | 5: ChildProduct SMART)
        listProducts[3].RecordTypeId = idRTCS;
        listProducts[3].Name = 'Preventative Care';

        listProducts[4].RecordTypeId = idRTCS;
        listProducts[4].Name = 'Program Benefits AIDD';

        listProducts[5].RecordTypeId = idRTCS;
        listProducts[5].Name = 'Program Benefits SMART';

        // PRODUCTS TO NEW CONTRACT
        listProducts[6].RecordTypeId = idRTP;
        listProducts[6].vlocity_ins__Type__c = 'Medical';
        listProducts[6].Name = 'WeShare 3k';

        listProducts[7].RecordTypeId = idRTP;
        listProducts[7].vlocity_ins__Type__c = 'Ancillary';
        listProducts[7].Name = 'AIDD 10000';

        listProducts[8].RecordTypeId = idRTP;
        listProducts[8].vlocity_ins__Type__c = 'Ancillary';
        listProducts[8].Name = 'SMART Share 40000';

        update listProducts;

        // Child Products Items (need it for Child Products)
        List<vlocity_ins__ProductChildItem__c> listPCI= new List<vlocity_ins__ProductChildItem__c>();
        listPCI.add(new vlocity_ins__ProductChildItem__c(vlocity_ins__ChildProductId__c = listProducts[3].Id, vlocity_ins__ChildLineNumber__c = '1')); // Child Item of Preventative Care
        listPCI.add(new vlocity_ins__ProductChildItem__c(vlocity_ins__ChildProductId__c = listProducts[4].Id, vlocity_ins__ChildLineNumber__c = '1')); // Child Item of Program Benefits AIDD
        listPCI.add(new vlocity_ins__ProductChildItem__c(vlocity_ins__ChildProductId__c = listProducts[5].Id, vlocity_ins__ChildLineNumber__c = '1')); // Child Item of Program Benefits SMART
        insert listPCI;

        // Retrieve the Contract of the CLIs
        Contract cnt = [SELECT Id, ARC_AppFeeOrder__c, AccountId FROM Contract LIMIT 1];
        vlocity_ins__GroupCensusMember__c gcm = [SELECT vlocity_ins__CensusId__r.vlocity_ins__GroupId__c FROM vlocity_ins__GroupCensusMember__c LIMIT 1];
        cnt.AccountId = gcm.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c; // Same Group Account Id in GCM and Contract
        cnt.ARC_EffectiveDate__c = Date.newInstance(2025, 8, 15);
        cnt.StartDate = Date.newInstance(2025, 8, 15);
        update cnt; 

        // Guardian Account
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_Guardian').getRecordTypeId();
        Account guardianAccount = new Account();
        guardianAccount.Firstname = 'Guardian';
        guardianAccount.Lastname = 'Member';
        guardianAccount.RecordTypeId = recordTypeId;
        guardianAccount.ARC_GroupAccount__c = gcm.vlocity_ins__CensusId__r.vlocity_ins__GroupId__c;
        guardianAccount.ARC_GuardianRelationshipToChild__c = 'Legal Guardian';
        guardianAccount.ARC_SocialSecurityNumber__c = '222222222';
        guardianAccount.ARC_UpdateAllAddress__c = true;
        guardianAccount.BillingCity = 'San Diego';
        guardianAccount.BillingCountry = 'United States';
        guardianAccount.BillingPostalCode = '92154';
        guardianAccount.BillingState = 'CA';
        guardianAccount.BillingStreet = 'Siempre Viva Court';
        guardianAccount.PersonBirthdate = Date.valueOf('2000-07-29');
        guardianAccount.PersonEmail = 'guardianmember@yopmail.com';
        guardianAccount.PersonGender = 'Male';
        insert guardianAccount;

        for (vlocity_ins__ContractLineItem__c cli : listCLI) {
            cli.vlocity_ins__ContractId__c = cnt.Id;
            cli.ARC_OriginalPrice__c = 100.00;
        }

        // CLI of MEDICAL | SMART | AIDD
        listCLI[0].vlocity_ins__Product2Id__c = listProducts[0].Id;
        listCLI[1].vlocity_ins__Product2Id__c = listProducts[1].Id;
        listCLI[2].vlocity_ins__Product2Id__c = listProducts[2].Id;

        // CLI of Child Products
        listCLI[3].vlocity_ins__Product2Id__c = listProducts[3].Id;
        listCLI[4].vlocity_ins__Product2Id__c = listProducts[4].Id;
        listCLI[5].vlocity_ins__Product2Id__c = listProducts[5].Id;
        update listCLI;
        //
        
    }

    private static Map<String, Object> createInputMapForSpinOff(){
        // Insert the necessary data:
        insertTestData();
        //[TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, ProfileId, LanguageLocaleKey] required fields
        // User usr = new User(FirstName='Test',LastName='User',ARC_EmailNotificationSettings__c = null, Alias='tuser', Email='testuser@example.com', Username='testuser123123@example.com', TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', ProfileId= [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id, LanguageLocaleKey='en_US');
        User usr = new User(FirstName='TestClass',LastName='User123456789',ARC_EmailNotificationSettings__c = null, Alias='tstclss', Email='testclassuser@example.com', Username='testclassuser@example.com', TimeZoneSidKey='America/Los_Angeles', LocaleSidKey='en_US', EmailEncodingKey='UTF-8', ProfileId= [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1].Id, LanguageLocaleKey='en_US');
        insert usr;

        // Fetch the necessary data to fill the map
        Contract contract = [SELECT Id, AccountId FROM Contract ORDER BY CreatedDate LIMIT 1];
        List<Product2> listProducts = [SELECT Id FROM Product2 ORDER BY CreatedDate LIMIT 9];
        List<vlocity_ins__ProductChildItem__c> listPCI = [SELECT Id FROM vlocity_ins__ProductChildItem__c ORDER BY CreatedDate LIMIT 3];
        List<vlocity_ins__GroupCensusMember__c> listGCM = [SELECT Id, vlocity_ins__CensusId__c, vlocity_ins__ContactId__c, Member_ID__c FROM vlocity_ins__GroupCensusMember__c ORDER BY CreatedDate LIMIT 3];
        List<Account> listAccounts = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'ARC_IFPPersonAccount' ORDER BY CreatedDate LIMIT 4];

        List<Case> listCase = ARC_TestUtility.createTestCase(1, 'Admission');
        listCase[0].ARC_Contract__c = contract.Id;
        listCase[0].OwnerId = usr.Id;
        upsert listCase;

        ARC_UnderwritingCaseMember__c UWCaseMembers = new ARC_UnderwritingCaseMember__c (
            ARC_ApprovalResolution__c = 'Pending',
            ARC_Member__c = listGCM[1].Id,
            ARC_PersonAccount__c = listAccounts[0].Id,
            ARC_Reason__c = 'Add Member',
            ARC_Score__c = 1,
            Name = 'TestUWCaseMember',
            ARC_Description__c = 'testing uw case member',
            ARC_UnderwritingCase__c = listCase[0].Id,
            ARC_Contract__c = contract.Id,
            ARC_LastStatusUpdate__c = Date.Today()
        );
        insert UWCaseMembers;
        
        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Old Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Credit Card',
            ChargentBase__Active__c = true
        );
        insert gateway;

        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = contract.Id,
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

        contract.ARC_AppFeeOrder__c = existingOrder.Id;
        update contract; 

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
            ARC_Contract__c = contract.Id,
            ARC_NumberOfTimesCanBeUsed__c = 1,
            ARC_TimesUsed__c = 0,
            ARC_AmountToDiscountPerTransaction__c = 30.39,
            ARC_CorePriceWithoutDiscount__c = 202.6,
            ARC_EndDate__c = null
        );
        insert promotionDiscount;
        ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];

        return new Map<String, Object> {
            'soChanges' => new Map<String, Object> {
                'soReasonsString' => 'Spin Off; Program Upgrade; Ancillary Change; Remove Member; Add Member',
                'feeApplicable' => true,
                'soReasons' => new Map<String, Object> {
                    'ancillaryChange' => true, 
                    'removeMember' => true, 
                    'addMember' => true, 
                    'agingOut' => false, 
                    'programDowngrade' => false, 
                    'programUpgrade' => true, 
                    'spinOff' => true
                },
                'programSummaryFeeText' => 'One Time Change Fee (Add Member, Program Upgrade): 99.000',
                'feeAmount' => 99
            }, 
            'census_component' => new Map<String, Object> {
                'census_members' => new List<Object> {
                    new List<Object> {
                        new Map<String, Object> {
                            'vlocity_ins__Gender__c' => 'Male',
                            'ARC_Relationship__c' => 'Primary',
                            'ARC_isPregnant__c' => '',
                            'vlocity_ins__Email__c' => 'member1@yopmail.com',
                            'ARC_Phone__c' => '1111111111',
                            'ShowAddressForDependent' => false,
                            'CopyAddressFromPrimary' => true,
                            'DISABLE_INPUT_FIELDS' => false,
                            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                            'ShowMember' => true,
                            'IsRemoveMember' => false,
                            'IsNewMember' => false,
                            'IsDependent' => false,
                            'ARC_Address__c' => 'San Diego, CA, Siempre Viva Court, 92154',
                            'ARC_PhysicalAddressZipCode__c' => '92154',
                            'ARC_PhysicalAddressStreet__c' => 'Siempre Viva Court',
                            'ARC_PhysicalAddressState__c' => 'CA',
                            'ARC_PhysicalAddressCity__c' => 'San Diego',
                            'ARC_Smoker__c' => false,
                            'ARC_Weight__c' => '1',
                            'ARC_HeightInches__c' => '1',
                            'ARC_HeightFeet__c' => '1',
                            'showSSN' => 'password',
                            'vlocity_ins__SocialSecurityNumber__c' => '111111111',
                            'ARC_Age__c' => 24,
                            'vlocity_ins__IsPrimaryMember__c' => true,
                            'vlocity_ins__Birthdate__c' => '2000-08-04',
                            'ARC_MiddleInitial__c' => 'M',
                            'vlocity_ins__MemberIdentifier__c' => '2025-08-01T15:28:58.791Z',
                            'PersonContactId' => listGCM[0].vlocity_ins__ContactId__c,
                            'PersonAccountId' => listAccounts[0].Id,
                            'vlocity_ins__LastName__c' => 'Member',
                            'vlocity_ins__FirstName__c' => 'OneMember',
                            'Id' => listGCM[0].Id
                        }
                    },
                    new List<Object> {
                        new Map<String, Object> {
                            'vlocity_ins__Gender__c' => 'Female',
                            'ARC_Relationship__c' => 'Primary',
                            'ARC_isPregnant__c' => false,
                            'vlocity_ins__Email__c' => 'member2@yopmail.com',
                            'ARC_Phone__c' => '2222222222',
                            'ShowAddressForDependent' => false,
                            'CopyAddressFromPrimary' => true,
                            'DISABLE_INPUT_FIELDS' => false,
                            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                            'ShowMember' => true,
                            'IsRemoveMember' => false,
                            'IsNewMember' => false,
                            'IsDependent' => false,
                            'ARC_Address__c' => 'road',
                            'ARC_PhysicalAddressZipCode__c' => '81210',
                            'ARC_PhysicalAddressStreet__c' => 'County Road 267D',
                            'ARC_PhysicalAddressState__c' => 'CO',
                            'ARC_PhysicalAddressCity__c' => 'Tincup',
                            'ARC_Smoker__c' => false,
                            'ARC_Weight__c' => '2',
                            'ARC_HeightInches__c' => '2',
                            'ARC_HeightFeet__c' => '2',
                            'showSSN' => 'password',
                            'vlocity_ins__SocialSecurityNumber__c' => '222222222',
                            'ARC_Age__c' => 24,
                            'vlocity_ins__IsPrimaryMember__c' => true,
                            'vlocity_ins__Birthdate__c' => '2000-08-06',
                            'ARC_MiddleInitial__c' => 'M',
                            'vlocity_ins__MemberIdentifier__c' => '1754062260068-0.33083903547555193',
                            'PersonContactId' => listGCM[1].vlocity_ins__ContactId__c,
                            'PersonAccountId' => listAccounts[1].Id,
                            'vlocity_ins__LastName__c' => 'Member',
                            'vlocity_ins__FirstName__c' => 'TwoMember',
                            'Id' => listGCM[1].Id,
                            'fullName' => 'TwoMember M Member',
                            'accordionStyle' => '--slds-c-accordion-heading-text-color: black;',
                            'DISPLAY_BUTTON_REMOVE_MEMBER' => true
                        },
                        new Map<String, Object> {
                            'vlocity_ins__Gender__c' => 'Male',
                            'ARC_Relationship__c' => 'Child',
                            'ARC_isPregnant__c' => '',
                            'vlocity_ins__Email__c' => 'member3@yopmail.com',
                            'ARC_Phone__c' => '3333333333',
                            'ShowAddressForDependent' => false,
                            'CopyAddressFromPrimary' => true,
                            'DISABLE_INPUT_FIELDS' => false,
                            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                            'ShowMember' => false,
                            'IsRemoveMember' => true,
                            'IsNewMember' => false,
                            'IsDependent' => true,
                            'ARC_Address__c' => 'San Diego, CA, Siempre Viva Court, 92154',
                            'ARC_PhysicalAddressZipCode__c' => '81210',
                            'ARC_PhysicalAddressStreet__c' => 'County Road 267D',
                            'ARC_PhysicalAddressState__c' => 'CO',
                            'ARC_PhysicalAddressCity__c' => 'Tincup',
                            'ARC_Smoker__c' => false,
                            'ARC_Weight__c' => '3',
                            'ARC_HeightInches__c' => '3',
                            'ARC_HeightFeet__c' => '3',
                            'showSSN' => 'password',
                            'vlocity_ins__SocialSecurityNumber__c' => '333333333',
                            'ARC_Age__c' => 23,
                            'vlocity_ins__IsPrimaryMember__c' => false,
                            'vlocity_ins__Birthdate__c' => '2001-08-26',
                            'ARC_MiddleInitial__c' => 'M',
                            'vlocity_ins__MemberIdentifier__c' => '1754062280776-0.5008445784265545',
                            'PersonContactId' => listGCM[2].vlocity_ins__ContactId__c,
                            'PersonAccountId' => listAccounts[2].Id,
                            'vlocity_ins__LastName__c' => 'Member',
                            'vlocity_ins__FirstName__c' => 'ThreeMember',
                            'Id' => listGCM[2].Id,
                            'fullName' => 'ThreeMember M Member',
                            'accordionStyle' => '--slds-c-accordion-heading-text-color: black;',
                            'DISPLAY_BUTTON_REMOVE_MEMBER' => true,
                            'DISPLAY_MODAL_REMOVE_MEMBER' => true
                        },
                        new Map<String, Object> {
                            'vlocity_ins__Gender__c' => 'Male',
                            'ARC_Relationship__c' => 'Spouse',
                            'ARC_isPregnant__c' => '',
                            'vlocity_ins__Email__c' => 'member4@yopmail.com',
                            'ARC_Phone__c' => '4444444444',
                            'ShowAddressForDependent' => false,
                            'CopyAddressFromPrimary' => true,
                            'DISABLE_INPUT_FIELDS' => false,
                            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                            'ShowMember' => true,
                            'IsRemoveMember' => false,
                            'IsNewMember' => true,
                            'IsDependent' => true,
                            'ARC_Address__c' => 'road',
                            'ARC_PhysicalAddressZipCode__c' => '81210',
                            'ARC_PhysicalAddressStreet__c' => 'County Road 267D',
                            'ARC_PhysicalAddressState__c' => 'CO',
                            'ARC_PhysicalAddressCity__c' => 'Tincup',
                            'ARC_Smoker__c' => false,
                            'ARC_Weight__c' => '4',
                            'ARC_HeightInches__c' => '4',
                            'ARC_HeightFeet__c' => '4',
                            'showSSN' => 'password',
                            'vlocity_ins__SocialSecurityNumber__c' => '444444444',
                            'ARC_Age__c' => 25,
                            'vlocity_ins__IsPrimaryMember__c' => false,
                            'vlocity_ins__Birthdate__c' => '2000-07-27',
                            'ARC_MiddleInitial__c' => 'M',
                            'vlocity_ins__MemberIdentifier__c' => '1754062280776-0.5008445784265545',
                            'PersonContactId' => 'MEM-1754063239909826',
                            'PersonAccountId' => 'MEM-1754063239909826',
                            'vlocity_ins__LastName__c' => 'Member',
                            'vlocity_ins__FirstName__c' => 'FourMember',
                            'Id' => 'MEM-1754063239909826',
                            'fullName' => 'FourMember M Member',
                            'accordionStyle' => '--slds-c-accordion-heading-text-color: black;',
                            'DISPLAY_BUTTON_REMOVE_MEMBER' => true,
                            'DISPLAY_MODAL_REMOVE_MEMBER' => false 
                        }
                    }
                },
                'is_form_valid' => true,
                'initial_values' => new List<Object> {
                    new List<Object> {
                        new Map<String, Object> {
                            'vlocity_ins__Gender__c' => 'Male',
                            'ARC_Relationship__c' => 'Primary',
                            'ARC_isPregnant__c' => '',
                            'vlocity_ins__Email__c' => 'member1@yopmail.com',
                            'ARC_Phone__c' => '1111111111',
                            'ShowAddressForDependent' => false,
                            'CopyAddressFromPrimary' => true,
                            'DISABLE_INPUT_FIELDS' => false,
                            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                            'ShowMember' => true,
                            'IsRemoveMember' => false,
                            'IsNewMember' => false,
                            'IsDependent' => false,
                            'ARC_Address__c' => 'San Diego, CA, Siempre Viva Court, 92154',
                            'ARC_PhysicalAddressZipCode__c' => '92154',
                            'ARC_PhysicalAddressStreet__c' => 'Siempre Viva Court',
                            'ARC_PhysicalAddressState__c' => 'CA',
                            'ARC_PhysicalAddressCity__c' => 'San Diego',
                            'ARC_Smoker__c' => false,
                            'ARC_Weight__c' => '1',
                            'ARC_HeightInches__c' => '1',
                            'ARC_HeightFeet__c' => '1',
                            'showSSN' => 'password',
                            'vlocity_ins__SocialSecurityNumber__c' => '111111111',
                            'ARC_Age__c' => 24,
                            'vlocity_ins__IsPrimaryMember__c' => true,
                            'vlocity_ins__Birthdate__c' => '2000-08-04',
                            'ARC_MiddleInitial__c' => 'M',
                            'vlocity_ins__MemberIdentifier__c' => '2025-08-01T15:28:58.791Z',
                            'PersonContactId' => listGCM[0].vlocity_ins__ContactId__c,
                            'PersonAccountId' => listAccounts[0].Id,
                            'vlocity_ins__LastName__c' => 'Member',
                            'vlocity_ins__FirstName__c' => 'OneMember',
                            'Id' => listGCM[0].Id
                        }
                    },
                    new List<Object> {
                        new Map<String, Object> {
                            'vlocity_ins__Gender__c' => 'Female',
                            'ARC_Relationship__c' => 'Primary',
                            'ARC_isPregnant__c' => false,
                            'vlocity_ins__Email__c' => 'member2@yopmail.com',
                            'ARC_Phone__c' => '2222222222',
                            'ShowAddressForDependent' => false,
                            'CopyAddressFromPrimary' => true,
                            'DISABLE_INPUT_FIELDS' => false,
                            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                            'ShowMember' => true,
                            'IsRemoveMember' => false,
                            'IsNewMember' => false,
                            'IsDependent' => false,
                            'ARC_Address__c' => 'San Diego, CA, Siempre Viva Court, 92154',
                            'ARC_PhysicalAddressZipCode__c' => '92154',
                            'ARC_PhysicalAddressStreet__c' => 'Siempre Viva Court',
                            'ARC_PhysicalAddressState__c' => 'CA',
                            'ARC_PhysicalAddressCity__c' => 'San Diego',
                            'ARC_Smoker__c' => false,
                            'ARC_Weight__c' => '2',
                            'ARC_HeightInches__c' => '2',
                            'ARC_HeightFeet__c' => '2',
                            'showSSN' => 'password',
                            'vlocity_ins__SocialSecurityNumber__c' => '222222222',
                            'ARC_Age__c' => 24,
                            'vlocity_ins__IsPrimaryMember__c' => true,
                            'vlocity_ins__Birthdate__c' => '2000-08-06',
                            'ARC_MiddleInitial__c' => 'M',
                            'vlocity_ins__MemberIdentifier__c' => '1754062260068-0.33083903547555193',
                            'PersonContactId' => listGCM[1].vlocity_ins__ContactId__c,
                            'PersonAccountId' => listAccounts[1].Id,
                            'vlocity_ins__LastName__c' => 'Member',
                            'vlocity_ins__FirstName__c' => 'TwoMember',
                            'Id' => listGCM[1].Id,
                            'fullName' => 'TwoMember M Member',
                            'accordionStyle' => '--slds-c-accordion-heading-text-color: black;'
                        },
                        new Map<String, Object> {
                            'vlocity_ins__Gender__c' => 'Male',
                            'ARC_Relationship__c' => 'Child',
                            'ARC_isPregnant__c' => '',
                            'vlocity_ins__Email__c' => 'member3@yopmail.com',
                            'ARC_Phone__c' => '3333333333',
                            'ShowAddressForDependent' => false,
                            'CopyAddressFromPrimary' => true,
                            'DISABLE_INPUT_FIELDS' => false,
                            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                            'ShowMember' => true,
                            'IsRemoveMember' => false,
                            'IsNewMember' => false,
                            'IsDependent' => true,
                            'ARC_Address__c' => 'San Diego, CA, Siempre Viva Court, 92154',
                            'ARC_PhysicalAddressZipCode__c' => '92154',
                            'ARC_PhysicalAddressStreet__c' => 'Siempre Viva Court',
                            'ARC_PhysicalAddressState__c' => 'CA',
                            'ARC_PhysicalAddressCity__c' => 'San Diego',
                            'ARC_Smoker__c' => false,
                            'ARC_Weight__c' => '3',
                            'ARC_HeightInches__c' => '3',
                            'ARC_HeightFeet__c' => '3',
                            'showSSN' => 'password',
                            'vlocity_ins__SocialSecurityNumber__c' => '333333333',
                            'ARC_Age__c' => 23,
                            'vlocity_ins__IsPrimaryMember__c' => false,
                            'vlocity_ins__Birthdate__c' => '2001-08-26',
                            'ARC_MiddleInitial__c' => 'M',
                            'vlocity_ins__MemberIdentifier__c' => '1754062280776-0.5008445784265545',
                            'PersonContactId' => listGCM[2].vlocity_ins__ContactId__c,
                            'PersonAccountId' => listAccounts[2].Id,
                            'vlocity_ins__LastName__c' => 'Member',
                            'vlocity_ins__FirstName__c' => 'ThreeMember',
                            'Id' => listGCM[2].Id,
                            'fullName' => 'ThreeMember M Member',
                            'accordionStyle' => '--slds-c-accordion-heading-text-color: black;'
                        }
                    }
                }
            },
            'STEP_ChargentPayment' => new Map<String, Object> {
                'RAD_ChargeAppFeeDefTrue' => 'No',
                'BLK_ChargeFee' => new Map<String, Object> {
                    'BLK_PaymentInfo' => new Map<String, Object> {
                        'BLK_CreditCard' => new Map<String, Object> {
                            'TXT_FirstNameOnCard' => 'TwoMember',
                            'TXT_LastNameOnCard' => 'Member',
                            'TXT_BillingAddress_Street' => 'County Road 267D',
                            'TXT_BillingAddress_City' => 'Tincup',
                            'TXT_BillingAddress_State' => 'CO',
                            'TXT_BillingAddress_ZipCode' => '81210',
                            'TXT_CardNumber' => '3333333333333333',
                            'SLC_ExpirationMonth' => '3',
                            'SLC_Year' => '2028'
                        },
                        'BLK_BankAccount' => null
                    },
                    'LWC_PromoDiscountCodeRefactor' => new Map<String, Object> {
                        'Id' => null,
                        'PromotionCodeId' => promo.Id,
                        'PromotionCodeName' => 'LUC20',
                        'ApplyOver' => 'Medical',
                        'DiscountAmount' => '59.80',
                        'MedicalPrice' => 398.64,
                        'DiscountPrice' => '338.84',
                        'AgentId' => UserInfo.getUserId()
                    },
                    'BLK_CaseCreationDetails' => new Map<String, Object> {
                        'TXT_NoChargeChangeFeeReason' => 'case fee so'
                    },
                    'RAD_MethodOfPayment' => 'Credit Card'
                }
            },
            'MembersToSpinOff' => new List<Object> {
                new Map<String, Object> {
                    'MemberRank' => '2',
                    'ContractId' => contract.Id,
                    'FRML_isPrimary' => false,
                    'CHK_spinOffSelection' => null,
                    'NUM_Age' => 24,
                    'TXT_Birthdate' => '2000-08-04',
                    'TXT_GroupCensusMemberId' => listGCM[0].Id,
                    'TXT_LastName' => 'Member',
                    'TXT_ContractParticipantId' => '',
                    'TXT_ContractParticipantRelationship' => 'Primary',
                    'TXT_FirstName' => 'OneMember'
                },
                new Map<String, Object> {
                    'MemberRank' => '1',
                    'ContractId' => contract.Id,
                    'FRML_isPrimary' => false,
                    'CHK_spinOffSelection' => true,
                    'NUM_Age' => 24,
                    'TXT_Birthdate' => '2000-08-06',
                    'TXT_GroupCensusMemberId' => listGCM[1].Id,
                    'TXT_LastName' => 'Member',
                    'TXT_ContractParticipantId' => '',
                    'TXT_ContractParticipantRelationship' => 'Spouse',
                    'TXT_FirstName' => 'TwoMember'
                },
                new Map<String, Object> {
                    'MemberRank' => '0',
                    'ContractId' => contract.Id,
                    'FRML_isPrimary' => false,
                    'CHK_spinOffSelection' => false,
                    'NUM_Age' => 23,
                    'TXT_Birthdate' => '2001-08-26',
                    'TXT_GroupCensusMemberId' => listGCM[2].Id,
                    'TXT_LastName' => 'Member',
                    'TXT_ContractParticipantId' => '',
                    'TXT_ContractParticipantRelationship' => 'Child',
                    'TXT_FirstName' => 'ThreeMember'
                }
            },
            'ContractList' => new List<Object> {
                new Map<String, Object> {
                    'ContractID' => contract.Id,
                    'DATE_CreatedDate' => '2025-08-01T15:30:46.000Z',
                    'EffectiveDate' => '07/15/2025',
                    'GroupAccountId' => contract.AccountId,
                    'GroupAccountName' => 'One Member Family',
                    'SelectedContract' => true,
                    'TXT_ContractNumber' => '00103789',
                    'TXT_ContractReason' => 'New Application',
                    'TXT_ContractStatus' => 'Activated',
                    'TXT_MedicalPlan' => 'WeShare 6k',
                    'GuardianId' => null,
                    'TXT_Members' => 'OneMember Member, TwoMember Member, ThreeMember Member',
                    'SV_NameListStatus' => true,
                    'SV_MemberListStatus' => true,
                    'LoopBlockIterationStatus' => true,
                    'LoopBlockIterationIndex' => 1
                } 
            },
            'STEP_AccountSelection'  => new Map<String, Object> {
                'LWC_SpinOffCensusMembersTable' => new List<Object> {
                    new Map<String, Object> {
                        'CHK_spinOffSelection' => null,
                        'TXT_ContractParticipantRelationship' => 'Primary',
                        'TXT_LastName' => 'Member',
                        'TXT_FirstName' => 'OneMember',
                        'TXT_ContractParticipantId' => 'aDdcb0000000qufCAA',
                        'TXT_GroupCensusMemberId' => listGCM[0].Id,
                        'NUM_Age' => 24,
                        'TXT_reason' => 'Remove Member',
                        'NUM_assignToFamily' => 1
                    } ,
                    new Map<String, Object> {
                        'CHK_spinOffSelection' => true,
                        'TXT_ContractParticipantRelationship' => 'Spouse',
                        'TXT_LastName' => 'Member',
                        'TXT_FirstName' => 'TwoMember',
                        'TXT_ContractParticipantId' => 'aDdcb0000000qugCAA',
                        'TXT_GroupCensusMemberId' => listGCM[1].Id,
                        'NUM_Age' => 24,
                        'TXT_reason' => 'TwoMember Member Spin-Off',
                        'NUM_assignToFamily' => 2
                    },
                    new Map<String, Object> {
                        'CHK_spinOffSelection' => false,
                        'TXT_ContractParticipantRelationship' => 'Child',
                        'TXT_LastName' => 'Member',
                        'TXT_FirstName' => 'ThreeMember',
                        'TXT_ContractParticipantId' => 'aDdcb0000000quhCAA',
                        'TXT_GroupCensusMemberId' => listGCM[2].Id,
                        'NUM_Age' => 23,
                        'TXT_reason' => 'TwoMember Member',
                        'NUM_assignToFamily' => 2
                    }    
                },
                'MSG_EffectiveDateMissing' => null,
                'FRML_EffectiveDateSelected' => true,
                'aRC_DatePicker' => new Map<String, Object> {
                    'DATE_SubscriberEffectiveDate' => '2025-08-15'
                }
            },
            'ContractIdSelected' => contract.Id,
            'price_calculation' => new Map<String, Object> {
                'plans' => new List<Object> {
                    new Map<String, Object> {
                        'selectedProduct'  => new Map<String, Object> {
                            'displaySequence' => -1,
                            'RawPriceData' => new List<Object> {
                                new Map<String, Object> {
                                    'aggregationResults'  => new Map<String, Object> {
                                        'Price' => 398.64
                                    },
                                    'calculationResults' => new List<Object> {
                                        new Map<String, Object> {
                                            'Price'  => 398.64,
                                            'Smoker'  => false,
                                            'ProductCodeOut'  => 'PROG_UHSM_WeShare3k',
                                            'IsPrimary'  => true,
                                            'StateOut'  => 'CO',
                                            'AgeOut'  => 25,
                                            'MemberRate'  => 398.64,
                                            'ARC_UHSM_StateRateFactors__StateFactor'  => 0.96,
                                            'ARC_UHSM_Individual__Price'  => 415.25,
                                            'ID'  => '0'
                                        },
                                        new Map<String, Object> {
                                            'Smoker'  => false,
                                            'ProductCodeOut'  => 'PROG_UHSM_WeShare3k',
                                            'IsPrimary'  => false,
                                            'StateOut'  => 'CO',
                                            'AgeOut'  => 25,
                                            'MemberRate'  => 0,
                                            'ID'  => '1'
                                        }
                                    }
                                }
                            },
                            'Id'  => listProducts[6].Id,
                            'Name'  => 'WeShare 3k',
                            'ProductCode'  => 'PROG_UHSM_WeShare3k',
                            'MarketSegment__c'  => 'Individual',
                            'Type__c'  => 'Medical',
                            'SubType__c'  => 'PPO',
                            'IsRecommended__c'  => false,
                            'PricingSource__c'  => 'Configurable',
                            'RecordTypeName__c'  => 'Product',
                            'IsConfigurable__c'  => true,
                            'PricingFormula__c'  => 'Price',
                            'productId'  => listProducts[6].Id,
                            'currencyCode'  => 'USD',
                            'currencySymbol'  => '$',
                            'Price'  => 398.64,
                            'childProducts' => new Map<String, Object> {
                                'totalSize'  => 1,
                                'records' => new List<Object> {
                                    new Map<String, Object> {
                                        'displaySequence'  => 7,
                                        'Id'  => listProducts[3].Id,
                                        'Name'  => 'Preventative Care',
                                        'ProductCode'  => 'ARC_UHSMPreventativeCare',
                                        'Type__c' => 'Medical',
                                        'IsRecommended__c'  => false,
                                        'RecordTypeName__c'  => 'CoverageSpec',
                                        'IsConfigurable__c'  => true,
                                        'Term__c'  => 'Annual',
                                        'isOptional'  => false,
                                        'isSelected'  => true,
                                        'productId'  => listProducts[3].Id,
                                        'pciId'  => listPCI[0].Id
                                    }
                                }
                            }
                        },
                        'userInputs' => new List<Object> {
                            new Map<String, Object> {
                                'RF_Census.CM_Age'  => 24,
                                'RF_Census.CM_State'  => 'CO',
                                'RF_Census.CM_IsPrimary'  => true,
                                'RF_Census.CM_Relationship'  => 'Primary',
                                'RF_Census.CM_Smoker'  => false,
                                'RF_Census.CM_Pregnant'  => false,
                                'RF_Census.CM_FirstName'  => 'TwoMember',
                                'RF_Census.CM_LastName'  => 'Member',
                                'IsRemoveMember'  => false,
                                'IsNewMember'  => false,
                                'IsAddExistingMember'  => false,
                                'Id'  => listGCM[1].Id,
                                'RF_Census.CRF_Coverage'  => '',
                                'RF_Census.CRF_CoverageAIDD'  => '',
                                'RF_Census.CRF_ExtraDependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberAge'  => 25,
                                'RF_Census.CRF_Dependants'  => 1,
                                'RF_Census.CRF_PrimaryMemberDOB'  => '2000-08-06'
                            },
                            new Map<String, Object> {
                                'RF_Census.CM_Age'  => 25,
                                'RF_Census.CM_State'  => 'CO',
                                'RF_Census.CM_IsPrimary'  => false,
                                'RF_Census.CM_Relationship'  => 'Spouse',
                                'RF_Census.CM_Smoker'  => false,
                                'RF_Census.CM_Pregnant'  => false,
                                'RF_Census.CM_FirstName'  => 'FourMember',
                                'RF_Census.CM_LastName'  => 'Member',
                                'IsRemoveMember'  => false,
                                'IsNewMember'  => true,
                                'IsAddExistingMember'  => false,
                                'Id'  => 'MEM-1754063239909826',
                                'RF_Census.CRF_Coverage'  => '',
                                'RF_Census.CRF_CoverageAIDD'  => '',
                                'RF_Census.CRF_ExtraDependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberAge'  => 25,
                                'RF_Census.CRF_Dependants'  => 1,
                                'RF_Census.CRF_PrimaryMemberDOB'  => '2000-08-06'
                            }
                        }
                    },
                    new Map<String, Object> {
                        'selectedProduct'  => new Map<String, Object> {
                            'displaySequence' => -1,
                            'RawPriceData' => new List<Object> {
                                new Map<String, Object> {
                                    'aggregationResults'  => new Map<String, Object> {
                                        'Price' => 39.53
                                    },
                                    'calculationResults' => new List<Object> {
                                        new Map<String, Object> {
                                            'Price'  => 39.53,
                                            'UHSM_SMART__Premium'  => 39.53,
                                            'ID'  => 0
                                        }
                                    }
                                }
                            },
                            'Id'  => listProducts[7].Id,
                            'Name'  => 'AIDD 10000',
                            'ProductCode'  => 'PROG_AIDD_10000',
                            'MarketSegment__c'  => 'Individual',
                            'Type__c'  => 'Ancillary',
                            'SubType__c'  => 'AIDD',
                            'IsRecommended__c'  => false,
                            'RecordTypeName__c'  => 'Product',
                            'IsConfigurable__c'  => false,
                            'PricingFormula__c'  => 'Price',
                            'productId'  => listProducts[7].Id,
                            'currencyCode'  => 'USD',
                            'currencySymbol'  => '$',
                            'Price'  => 39.53,
                            'childProducts' => new Map<String, Object> {
                                'totalSize'  => 1,
                                'records' => new List<Object> {
                                    new Map<String, Object> {
                                        'displaySequence'  => 1,
                                        'Id'  => listProducts[4].Id,
                                        'Name'  => 'Program Benefits AIDD',
                                        'ProductCode'  => 'CS_General_AIDD',
                                        'IsRecommended__c'  => false,
                                        'RecordTypeName__c'  => 'CoverageSpec',
                                        'IsConfigurable__c'  => true,
                                        'Term__c'  => 'Annual',
                                        'isOptional'  => false,
                                        'isSelected'  => true,
                                        'productId'  => listProducts[4].Id, // Id
                                        'pciId'  => listPCI[1].Id
                                    }
                                }
                            }
                        },
                        'userInputs' => new List<Object> {
                            new Map<String, Object> {
                                'RF_Census.CM_Age'  => 24,
                                'RF_Census.CM_State'  => 'CO',
                                'RF_Census.CM_IsPrimary'  => true,
                                'RF_Census.CM_Relationship'  => 'Primary',
                                'RF_Census.CM_Smoker'  => false,
                                'RF_Census.CM_Pregnant'  => false,
                                'RF_Census.CM_FirstName'  => 'TwoMember',
                                'RF_Census.CM_LastName'  => 'Member',
                                'IsRemoveMember'  => false,
                                'IsNewMember'  => false,
                                'IsAddExistingMember'  => false,
                                'Id'  => listGCM[1].Id,
                                'RF_Census.CRF_Coverage'  => 'Primary',
                                'RF_Census.CRF_CoverageAIDD'  => 'Primary',
                                'RF_Census.CRF_ExtraDependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberAge'  => 24,
                                'RF_Census.CRF_Dependants'  => 1,
                                'RF_Census.CRF_PrimaryMemberDOB'  => '2000-08-06'
                            }
                        }
                    },
                    new Map<String, Object> {
                        'selectedProduct'  => new Map<String, Object> {
                            'displaySequence' => -1,
                            'RawPriceData' => new List<Object> {
                                new Map<String, Object> {
                                    'aggregationResults'  => new Map<String, Object> {
                                        'Price' => 39.53
                                    },
                                    'calculationResults' => new List<Object> {
                                        new Map<String, Object> {
                                            'Price'  => 39.53,
                                            'UHSM_SMART__Premium'  => 39.53,
                                            'ID'  => 0
                                        }
                                    }
                                }
                            },
                            'Id'  => listProducts[7].Id,
                            'Name'  => 'AIDD 10000',
                            'ProductCode'  => 'PROG_AIDD_10000',
                            'MarketSegment__c'  => 'Individual',
                            'Type__c'  => 'Ancillary',
                            'SubType__c'  => 'AIDD',
                            'IsRecommended__c'  => false,
                            'RecordTypeName__c'  => 'Product',
                            'IsConfigurable__c'  => false,
                            'PricingFormula__c'  => 'Price',
                            'productId'  => listProducts[7].Id,
                            'currencyCode'  => 'USD',
                            'currencySymbol'  => '$',
                            'Price'  => 39.53,
                            'childProducts' => new Map<String, Object> {
                                'totalSize'  => 1,
                                'records' => new List<Object> {
                                    new Map<String, Object> {
                                        'displaySequence'  => 1,
                                        'Id'  => listProducts[4].Id,
                                        'Name'  => 'Program Benefits AIDD',
                                        'ProductCode'  => 'CS_General_AIDD',
                                        'IsRecommended__c'  => false,
                                        'RecordTypeName__c'  => 'CoverageSpec',
                                        'IsConfigurable__c'  => true,
                                        'Term__c'  => 'Annual',
                                        'isOptional'  => false,
                                        'isSelected'  => true,
                                        'productId'  => listProducts[4].Id, // Id
                                        'pciId'  => listPCI[1].Id
                                    }
                                }
                            }
                        },
                        'userInputs' => new List<Object> {
                            new Map<String, Object> {
                                'RF_Census.CM_Age'  => 25,
                                'RF_Census.CM_State'  => 'CO',
                                'RF_Census.CM_IsPrimary'  => true,
                                'RF_Census.CM_Relationship'  => 'Spouse',
                                'RF_Census.CM_Smoker'  => false,
                                'RF_Census.CM_Pregnant'  => false,
                                'RF_Census.CM_FirstName'  => 'FourMember',
                                'RF_Census.CM_LastName'  => 'Member',
                                'IsRemoveMember'  => false,
                                'IsNewMember'  => true,
                                'IsAddExistingMember'  => false,
                                'Id'  => 'MEM-1754063239909826',
                                'RF_Census.CRF_Coverage'  => 'Primary',
                                'RF_Census.CRF_CoverageAIDD'  => 'Primary',
                                'RF_Census.CRF_ExtraDependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberAge'  => 25,
                                'RF_Census.CRF_Dependants'  => 1,
                                'RF_Census.CRF_PrimaryMemberDOB'  => '2000-08-06'
                            }
                        }
                    },
                    new Map<String, Object> {
                        'selectedProduct'  => new Map<String, Object> {
                            'displaySequence' => -1,
                            'RawPriceData' => new List<Object> {
                                new Map<String, Object> {
                                    'aggregationResults'  => new Map<String, Object> {
                                        'Price' => 29.36
                                    },
                                    'calculationResults' => new List<Object> {
                                        new Map<String, Object> {
                                            'Price'  => 29.36,
                                            'UHSM_SMART__Premium'  => 29.36,
                                            'ID'  => 0
                                        }
                                    }
                                }
                            },
                            'Id'  => listProducts[8].Id,
                            'Name'  => 'SMART Share 40000',
                            'ProductCode'  => 'PROG_SMART_40000',
                            'MarketSegment__c'  => 'Individual',
                            'Type__c'  => 'Ancillary',
                            'SubType__c'  => 'SMART',
                            'IsRecommended__c'  => false,
                            'PricingSource__c'  => 'Price',
                            'RecordTypeName__c'  => 'Product',
                            'IsConfigurable__c'  => false,
                            'productId'  => listProducts[8].Id,
                            'currencyCode'  => 'USD',
                            'currencySymbol'  => '$',
                            'Price'  => 29.36,
                            'childProducts' => new Map<String, Object> {
                                'totalSize'  => 1,
                                'records' => new List<Object> {
                                    new Map<String, Object> {
                                        'displaySequence'  => 1,
                                        'Id'  => listProducts[5].Id,
                                        'Name'  => 'Program Benefits SMART',
                                        'ProductCode'  => 'CS_General_SMART',
                                        'IsRecommended__c'  => false,
                                        'RecordTypeName__c'  => 'CoverageSpec',
                                        'IsConfigurable__c'  => true,
                                        'Term__c'  => 'Annual',
                                        'isOptional'  => false,
                                        'isSelected'  => true,
                                        'productId'  => listProducts[5].Id,
                                        'pciId'  => listPCI[2].Id
                                    }
                                }
                            }
                        },
                        'userInputs' => new List<Object> {
                            new Map<String, Object> {
                                'RF_Census.CM_Age'  => 25,
                                'RF_Census.CM_State'  => 'CO',
                                'RF_Census.CM_IsPrimary'  => true,
                                'RF_Census.CM_Relationship'  => 'Spouse',
                                'RF_Census.CM_Smoker'  => false,
                                'RF_Census.CM_Pregnant'  => false,
                                'RF_Census.CM_FirstName'  => 'FourMember',
                                'RF_Census.CM_LastName'  => 'Member',
                                'IsRemoveMember'  => false,
                                'IsNewMember'  => true,
                                'IsAddExistingMember'  => false,
                                'Id'  => 'MEM-1754063239909826',
                                'RF_Census.CRF_Coverage'  => 'Primary',
                                'RF_Census.CRF_CoverageAIDD'  => 'Primary',
                                'RF_Census.CRF_ExtraDependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberAge'  => 25,
                                'RF_Census.CRF_Dependants'  => 1,
                                'RF_Census.CRF_PrimaryMemberDOB'  => '2000-08-06'
                            }
                        }
                    },
                    new Map<String, Object> {
                        'selectedProduct'  => new Map<String, Object> {
                            'displaySequence' => -1,
                            'RawPriceData' => new List<Object> {
                                new Map<String, Object> {
                                    'aggregationResults'  => new Map<String, Object> {
                                        'Price' => 29.36
                                    },
                                    'calculationResults' => new List<Object> {
                                        new Map<String, Object> {
                                            'Price'  => 29.36,
                                            'UHSM_SMART__Premium'  => 29.36,
                                            'ID'  => 0
                                        }
                                    }
                                }
                            },
                            'Id'  => listProducts[8].Id,
                            'Name'  => 'SMART Share 40000',
                            'ProductCode'  => 'PROG_SMART_40000',
                            'MarketSegment__c'  => 'Individual',
                            'Type__c'  => 'Ancillary',
                            'SubType__c'  => 'SMART',
                            'IsRecommended__c'  => false,
                            'PricingSource__c'  => 'Price',
                            'RecordTypeName__c'  => 'Product',
                            'IsConfigurable__c'  => false,
                            'productId'  => listProducts[8].Id,
                            'currencyCode'  => 'USD',
                            'currencySymbol'  => '$',
                            'Price'  => 29.36,
                            'childProducts' => new Map<String, Object> {
                                'totalSize'  => 1,
                                'records' => new List<Object> {
                                    new Map<String, Object> {
                                        'displaySequence'  => 1,
                                        'Id'  => listProducts[5].Id,
                                        'Name'  => 'Program Benefits SMART',
                                        'ProductCode'  => 'CS_General_SMART',
                                        'IsRecommended__c'  => false,
                                        'RecordTypeName__c'  => 'CoverageSpec',
                                        'IsConfigurable__c'  => true,
                                        'Term__c'  => 'Annual',
                                        'isOptional'  => false,
                                        'isSelected'  => true,
                                        'productId'  => listProducts[5].Id,
                                        'pciId'  => listPCI[2].Id
                                    }
                                }
                            }
                        },
                        'userInputs' => new List<Object> {
                            new Map<String, Object> {
                                'RF_Census.CM_Age'  => 24,
                                'RF_Census.CM_State'  => 'CO',
                                'RF_Census.CM_IsPrimary'  => true,
                                'RF_Census.CM_Relationship'  => 'Primary',
                                'RF_Census.CM_Smoker'  => false,
                                'RF_Census.CM_Pregnant'  => false,
                                'RF_Census.CM_FirstName'  => 'TwoMember',
                                'RF_Census.CM_LastName'  => 'Member',
                                'IsRemoveMember'  => false,
                                'IsNewMember'  => false,
                                'IsAddExistingMember'  => false,
                                'Id' => listGCM[1].Id,
                                'RF_Census.CRF_Coverage'  => 'Primary',
                                'RF_Census.CRF_CoverageAIDD'  => 'Primary',
                                'RF_Census.CRF_ExtraDependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberAge'  => 24,
                                'RF_Census.CRF_Dependants'  => 1,
                                'RF_Census.CRF_PrimaryMemberDOB'  => '2000-08-06'
                            }
                        }
                    }
                }
            },
            'STEP_MembersToSpinOff' => new Map<String, Object> {
                'FRML_membersToSpinOffCount' => 1,
                'FRML_multipleSpinOff' => false,
                'EDITBLK_membersToSpinOff' => new List<Object> {
                    new Map<String, Object> {
                        'MemberRank' => '2',
                        'ContractId' => contract.Id,
                        'FRML_isPrimary' => false,
                        'CHK_spinOffSelection' => null,
                        'NUM_Age' => 24,
                        'TXT_Birthdate' => '2000-08-04',
                        'TXT_GroupCensusMemberId' => listGCM[0].Id,
                        'TXT_LastName' => 'Member',
                        'TXT_ContractParticipantId' => 'aDdcb0000000qufCAA',
                        'TXT_ContractParticipantRelationship' => 'Primary',
                        'TXT_FirstName' => 'OneMember'
                    },
                    new Map<String, Object> {
                        'FRML_isPrimary' => false,
                        'CHK_spinOffSelection' => true,
                        'MemberRank' => '1',
                        'ContractId' => contract.Id,
                        'NUM_Age' => 24,
                        'TXT_Birthdate' => '2000-08-06',
                        'TXT_GroupCensusMemberId' => listGCM[1].Id,
                        'TXT_LastName' => 'Member',
                        'TXT_ContractParticipantId' => 'aDdcb0000000qugCAA',
                        'TXT_ContractParticipantRelationship' => 'Spouse',
                        'TXT_FirstName' => 'TwoMember'
                    },
                    new Map<String, Object> {
                        'FRML_isPrimary' => false,
                        'CHK_spinOffSelection' => false,
                        'MemberRank' => '0',
                        'ContractId' => contract.Id,
                        'NUM_Age' => 23,
                        'TXT_Birthdate' => '2001-08-26',
                        'TXT_GroupCensusMemberId' => listGCM[2].Id,
                        'TXT_LastName' => 'Member',
                        'TXT_ContractParticipantId' => 'aDdcb0000000quhCAA',
                        'TXT_ContractParticipantRelationship' => 'Child',
                        'TXT_FirstName' => 'ThreeMember'
                    }
                },
                'TXTBLK_ContractSelected' => new List<Object> {
                    new Map<String, Object> {
                        'ContractID' => contract.Id,
                        'DATE_CreatedDate' => '2025-08-01T15:30:46.000Z',
                        'EffectiveDate' => '07/15/2025',
                        'GroupAccountId' => contract.AccountId,
                        'GroupAccountName' => 'One Member Family',
                        'SelectedContract' => true,
                        'TXT_ContractNumber' => '00103789',
                        'TXT_ContractReason' => 'New Application',
                        'TXT_ContractStatus' => 'Activated',
                        'TXT_MedicalPlan' => 'WeShare 6k',
                        'GuardianId' => null,
                        'TXT_Members' => 'OneMember Member, TwoMember Member, ThreeMember Member',
                        'SV_NameListStatus' => true,
                        'SV_MemberListStatus' => true,
                        'LoopBlockIterationStatus' => true,
                        'LoopBlockIterationIndex' => 1
                    }
                }
            },
            'price_calculation_removemember_spinoff' => new Map<String, Object> {
                'plans' => new List<Object> {
                    new Map<String, Object> {
                        'selectedProduct'  => new Map<String, Object> {
                            'displaySequence' => -1,
                            'RawPriceData' => new List<Object> {
                                new Map<String, Object> {
                                    'aggregationResults'  => new Map<String, Object> {
                                        'Price' => 225.21
                                    },
                                    'calculationResults' => new List<Object> {
                                        new Map<String, Object> {
                                            'Price'  => 225.21,
                                            'Smoker'  => false,
                                            'ProductCodeOut'  => 'PROG_UHSM_WeShare6k',
                                            'IsPrimary'  => true,
                                            'StateOut'  => 'CA',
                                            'AgeOut'  => 24,
                                            'MemberRate'  => 225.21,
                                            'ARC_UHSM_StateRateFactors__StateFactor'  => 1.03,
                                            'ARC_UHSM_Individual__Price'  => 218.65,
                                            'ID'  => '0'
                                        }
                                    }
                                }
                            },
                            'Id'  => listProducts[0].Id,
                            'Name'  => 'WeShare 6k',
                            'ProductCode'  => 'PROG_UHSM_WeShare6k',
                            'MarketSegment__c'  => 'Individual',
                            'Type__c'  => 'Medical',
                            'SubType__c'  => 'PPO',
                            'IsRecommended__c'  => false,
                            'PricingSource__c'  => 'Configurable',
                            'RecordTypeName__c'  => 'Product',
                            'IsConfigurable__c'  => true,
                            'PricingFormula__c'  => 'Price',
                            'productId'  => listProducts[0].Id,
                            'currencyCode'  => 'USD',
                            'currencySymbol'  => '$',
                            'Price'  => 225.21,
                            'childProducts' => new Map<String, Object> {
                                'totalSize'  => 1,
                                'records' => new List<Object> {
                                   new Map<String, Object> {
                                        'displaySequence'  => 1,
                                        'Id'  => listProducts[3].Id,
                                        'Name'  => 'Preventative Care',
                                        'ProductCode'  => 'ARC_UHSMPreventativeCare',
                                        'Type__c'  => 'Medical',
                                        'IsRecommended__c'  => false,
                                        'RecordTypeName__c'  => 'CoverageSpec',
                                        'IsConfigurable__c'  => true,
                                        'Term__c'  => 'Annual',
                                        'isOptional'  => false,
                                        'isSelected'  => true,
                                        'productId'  => listProducts[3].Id,
                                        'pciId'  => listPCI[0].Id
                                    }
                                }
                            }
                        },
                        'userInputs' => new List<Object> {
                            new Map<String, Object> {
                                'RF_Census.CM_Age'  => 24,
                                'RF_Census.CM_State'  => 'CA',
                                'RF_Census.CM_IsPrimary'  => true,
                                'RF_Census.CM_Relationship'  => 'Primary',
                                'RF_Census.CM_Smoker'  => false,
                                'RF_Census.CM_Pregnant'  => false,
                                'RF_Census.CM_FirstName'  => 'OneMember',
                                'RF_Census.CM_LastName'  => 'Member',
                                'IsRemoveMember'  => false,
                                'IsNewMember'  => false,
                                'IsAddExistingMember'  => false,
                                'Id'  => listGCM[0].Id,
                                'RF_Census.CRF_Coverage'  => 'Primary',
                                'RF_Census.CRF_CoverageAIDD'  => 'Primary',
                                'RF_Census.CRF_ExtraDependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberAge'  => 24,
                                'RF_Census.CRF_Dependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberDOB'  => '2000-08-04'
                            }
                        }
                    },
                    new Map<String, Object> {
                        'selectedProduct'  => new Map<String, Object> {
                            'displaySequence' => -1,
                            'RawPriceData' => new List<Object> {
                                new Map<String, Object> {
                                    'aggregationResults'  => new Map<String, Object> {
                                        'Price' => 29.06
                                    },
                                    'calculationResults' => new List<Object> {
                                        new Map<String, Object> {
                                            'Price'  => 29.06,
                                            'UHSM_SMART__Premium'  => 29.06,
                                            'ID'  => 0
                                        }
                                    }
                                }
                            },
                            'Id'  => listProducts[1].Id,
                            'Name'  => 'AIDD 5000',
                            'ProductCode'  => 'PROG_AIDD_5000',
                            'MarketSegment__c'  => 'Individual',
                            'Type__c'  => 'Ancillary',
                            'SubType__c'  => 'AIDD',
                            'IsRecommended__c'  => false,
                            'RecordTypeName__c'  => 'Product',
                            'IsConfigurable__c'  => false,
                            'PricingFormula__c'  => 'Price',
                            'productId'  => listProducts[1].Id,
                            'currencyCode'  => 'USD',
                            'currencySymbol'  => '$',
                            'Price'  => 29.06,
                            'childProducts' => new Map<String, Object> {
                                'totalSize'  => 1,
                                'records' => new List<Object> {
                                    new Map<String, Object> {
                                        'displaySequence'  => 1,
                                        'Id'  => listProducts[4].Id,
                                        'Name'  => 'Program Benefits AIDD',
                                        'ProductCode'  => 'CS_General_AIDD',
                                        'IsRecommended__c'  => false,
                                        'RecordTypeName__c'  => 'CoverageSpec',
                                        'IsConfigurable__c'  => true,
                                        'Term__c'  => 'Annual',
                                        'isOptional'  => false,
                                        'isSelected'  => true,
                                        'productId'  => listProducts[4].Id,
                                        'pciId'  => listPCI[1].Id
                                    }
                                }
                            }
                        },
                        'userInputs' => new List<Object> {
                            new Map<String, Object> {
                                'RF_Census.CM_Age'  => 24,
                                'RF_Census.CM_State'  => 'CA',
                                'RF_Census.CM_IsPrimary'  => true,
                                'RF_Census.CM_Relationship'  => 'Primary',
                                'RF_Census.CM_Smoker'  => false,
                                'RF_Census.CM_Pregnant'  => false,
                                'RF_Census.CM_FirstName'  => 'OneMember',
                                'RF_Census.CM_LastName'  => 'Member',
                                'IsRemoveMember'  => false,
                                'IsNewMember'  => false,
                                'IsAddExistingMember'  => false,
                                'Id'  => listGCM[0].Id,
                                'RF_Census.CRF_Coverage'  => 'Primary',
                                'RF_Census.CRF_CoverageAIDD'  => 'Primary',
                                'RF_Census.CRF_ExtraDependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberAge'  => 24,
                                'RF_Census.CRF_Dependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberDOB'  => '2000-08-04'
                            }
                        }
                    },
                    new Map<String, Object> {
                        'selectedProduct'  => new Map<String, Object> {
                            'displaySequence' => -1,
                            'RawPriceData' => new List<Object> {
                                new Map<String, Object> {
                                    'aggregationResults'  => new Map<String, Object> {
                                        'Price' => 20
                                    },
                                    'calculationResults' => new List<Object> {
                                        new Map<String, Object> {
                                            'Price'  => 20,
                                            'UHSM_SMART__Premium'  => 20,
                                            'ID'  => 0
                                        }
                                    }
                                }
                            },
                            'Id'  => listProducts[2].Id,
                            'Name'  => 'SMART Share 20000',
                            'ProductCode'  => 'PROG_SMART_20000',
                            'MarketSegment__c'  => 'Individual',
                            'Type__c'  => 'Ancillary',
                            'SubType__c'  => 'SMART',
                            'IsRecommended__c'  => false,
                            'PricingSource__c'  => 'Price',
                            'RecordTypeName__c'  => 'Product',
                            'IsConfigurable__c'  => false,
                            'productId'  => listProducts[2].Id,
                            'currencyCode'  => 'USD',
                            'currencySymbol'  => '$',
                            'Price'  => 20,
                            'childProducts' => new Map<String, Object> {
                                'totalSize'  => 1,
                                'records' => new List<Object> {
                                    new Map<String, Object> {
                                        'displaySequence'  => 1,
                                        'Id'  => listProducts[5].Id,
                                        'Name'  => 'Program Benefits SMART',
                                        'ProductCode'  => 'CS_General_SMART',
                                        'IsRecommended__c'  => false,
                                        'RecordTypeName__c'  => 'CoverageSpec',
                                        'IsConfigurable__c'  => true,
                                        'Term__c'  => 'Annual',
                                        'isOptional'  => false,
                                        'isSelected'  => true,
                                        'productId'  => listProducts[5].Id, // Id
                                        'pciId'  => listPCI[2].Id
                                    }
                                }
                            }
                        },
                        'userInputs' => new List<Object> {
                            new Map<String, Object> {
                                'RF_Census.CM_Age'  => 24,
                                'RF_Census.CM_State'  => 'CA',
                                'RF_Census.CM_IsPrimary'  => true,
                                'RF_Census.CM_Relationship'  => 'Primary',
                                'RF_Census.CM_Smoker'  => false,
                                'RF_Census.CM_Pregnant'  => false,
                                'RF_Census.CM_FirstName'  => 'OneMember',
                                'RF_Census.CM_LastName'  => 'Member',
                                'IsRemoveMember'  => false,
                                'IsNewMember'  => false,
                                'IsAddExistingMember'  => false,
                                'Id'  => listGCM[0].Id,
                                'RF_Census.CRF_Coverage'  => 'Primary',
                                'RF_Census.CRF_CoverageAIDD'  => 'Primary',
                                'RF_Census.CRF_ExtraDependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberAge'  => 24,
                                'RF_Census.CRF_Dependants'  => 0,
                                'RF_Census.CRF_PrimaryMemberDOB'  => '2000-08-04'
                            }
                        }
                    }
                }
            },
            'PlansSummary' => new Map<String, Object> {
                'BLK_ProductSummary' => new Map<String, Object> {
                    'TXT_ProgramSummaryFeeText' => 'One Time Change Fee (Add Member, Program Upgrade):',
                    'TXT_FeeAmount' => '$99.00',
                    'BLK_ProductsPrices' => new Map<String, Object> {
                        'TXT_EffDate' => '2025-08-15',
                        'BLK_IndividualProducts' => new List<Object> {
                            new Map<String, Object> {
                                'TXT_PlanSelected' => 'WeShare 3k',
                                'TXT_PlanSelectedPrice' => '$398.64',
                                'Type' => 'Medical'
                            },
                            new Map<String, Object> {
                                'TXT_PlanSelected' => 'SMART Share 40000',
                                'TXT_PlanSelectedPrice' => '$29.36',
                                'Type' => 'Ancillary'
                            },
                            new Map<String, Object> {
                                'TXT_PlanSelected' => 'SMART Share 40000',
                                'TXT_PlanSelectedPrice' => '$29.36',
                                'Type' => 'Ancillary'
                            },
                            new Map<String, Object> {
                                'TXT_PlanSelected' => 'AIDD 10000',
                                'TXT_PlanSelectedPrice' => '$39.53',
                                'Type' => 'Ancillary'
                            },
                            new Map<String, Object> {
                                'TXT_PlanSelected' => 'AIDD 10000',
                                'TXT_PlanSelectedPrice' => '$39.53',
                                'Type' => 'Ancillary'
                            }
                        }
                    },
                    'TXT_MonthlyPrice' => '$536.42'
                }
            },
            'STEP_MedicalQuestions' => new Map<String, Object> {
                'BLK_ParentSiblingDiagnosed' => new List<Object> {
                    new Map<String, Object> {
                        'CHKBOX_MemberParentDiagnosed' => true,
                        'DATE_MemberParentDiagnosed' => '2025-07-29',
                        'TXTAREA_MemberParentDiagnosed' => 'mq 1 TwoMember, edited',
                        'memberId' => listGCM[1].Id,
                        'TXT_hasErrorParentDiagnosed' => 'false',
                        'TXT_MemberIdParentDiagnosed' => listGCM[1].Id,
                        'TXT_MemberParentDiagnosed' => 'TwoMember Member'
                    },
                    new Map<String, Object> {
                        'CHKBOX_MemberParentDiagnosed' => true,
                        'DATE_MemberParentDiagnosed' => '2025-05-05',
                        'TXTAREA_MemberParentDiagnosed' => 'MQ1 FourMember',
                        'memberId' => 'MEM-1754063239909826',
                        'TXT_hasErrorParentDiagnosed' => 'false',
                        'TXT_MemberIdParentDiagnosed' => 'MEM-1754063239909826',
                        'TXT_MemberParentDiagnosed' => 'FourMember Member'
                    }
                },
                'FRML_ParentSiblingDiagnosedNull' => false,
                'MSG_WrongUnexpectedDate' => null,
                'BLK_UnexpectedSymptoms' => new List<Object> {
                    new Map<String, Object> {
                        'CHKBOX_UnexpectedSymptoms' => true,
                        'DATE_MemberUnexpectedSymptoms' => '2025-08-01',
                        'TXTAREA_MemberUnexpectedSymptoms' => 'test',
                        'memberId' => 'MEM-1754063239909826',
                        'TXT_hasError' => 'false',
                        'TXT_MemberIdUnexpectedSymptoms' => 'MEM-1754063239909826',
                        'TXT_MemberUnexpectedSymptoms' => 'FourMember Member'
                    }
                },
                'FRML_CheckSymptoms' => false,
                'FRML_DateUnexpectedWrong' => false,
                'BLK_PendingTests' => new List<Object> {
                    new Map<String, Object> {
                        'CHKBOX_PendingTests' => true,
                        'DATE_MemberPendingTests' => null,
                        'TXTAREA_MemberPendingTests' => null,
                        'memberId' => 'MEM-1754063239909826',
                        'TXT_MemberIdPendingTests' => 'MEM-1754063239909826',
                        'TXT_MemberPendingTests' => 'test'
                    }
                },
                'FRML_CheckPendingTests' => false,
                'LWC_SelectCensusMemberCancer' => new Map<String, Object> {
                    'SelectedCensusMemberName' => 'FourMember Member',
                    'SelectedCensusMemberId' => 'MEM-1754063239909826',
                    'SelectedCensusMemberBirthdate' => '2000-07-27'
                },
                'EB_Cancer' => new List<Object> {
                    new Map<String, Object> {
                        'index' => 0,
                        'memberId' => listGCM[1].Id,
                        'FRML_MemberIdCancerBirthdate' => '2000-07-27T00:00:00.000Z',
                        'CHK_CheckCancer' => false,
                        'CHK_MemberBeenDiagnosedWithCancer' => true,
                        'DATE_Cancer' => '2025-06-02',
                        'TXT_MemberNameCancer' => 'TwoMember Member',
                        'TXT_MemberIdCancer' => listGCM[1].Id,
                        'TXT_hasErrorCancer' => 'false',
                        'TXT_TypeOfCancer' => 'cancer TwoMember edited'
                    },
                    new Map<String, Object> {
                        'index' => null,
                        'memberId' => null,
                        'FRML_MemberIdCancerBirthdate' => '2000-07-27T00:00:00.000Z',
                        'CHK_CheckCancer' => false,
                        'CHK_MemberBeenDiagnosedWithCancer' => true,
                        'DATE_Cancer' => '2025-06-30',
                        'TXT_MemberNameCancer' => 'FourMember Member',
                        'TXT_MemberIdCancer' => 'MEM-1754063239909826',
                        'TXT_hasErrorCancer' => 'false',
                        'TXT_TypeOfCancer' => 'Cancer FourMember'
                    }
                },
                'FRML_CheckCancer' => false,
                'MSG_DateWrongCancer' => null,
                'FRML_DateWrongCancer' => false,
                'MSG_WrongDateAddiction' => null,
                'BLK_Addictions' => new List<Object> {
                    new Map<String, Object> {
                        'CHKBOX_Addictions' => true,
                        'DATE_MemberAddictions' => null,
                        'TXTAREA_MemberAddictions' => null,
                        'memberId' => 'MEM-1754063239909826',
                        'TXT_hasErrorAdiction' => 'false',
                        'TXT_MemberIdAddictions' => 'MEM-1754063239909826',
                        'TXT_MemberAddictions' => 'test'
                    }
                },
                'FRML_CheckAddictions' => false,
                'FMRL_WrongDateAddictions' => false,
                'BLK_LicenceSuspended' => new List<Object> {
                    new Map<String, Object> {
                        'CHKBOX_LicenceSuspended' => true,
                        'DATE_MemberLicenceSuspended' => null,
                        'TXTAREA_MemberLicenceSuspended' => null,
                        'memberId' => 'MEM-1754063239909826',
                        'TXT_hasErrorLicenceSuspended' => 'false',
                        'TXT_MemberIdLicenceSuspended' => 'MEM-1754063239909826',
                        'TXT_MemberLicenceSuspended' => 'test'
                    }
                },
                'FRML_LicenceSuspended' => false,
                'EB_PastConditions' => new List<Object> {
                    new Map<String, Object> {
                        'memberId' => 'MEM-1754063239909826',
                        'TXT_MemberIdPastConditions' => 'MEM-1754063239909826',
                        'TXT_MemberPastConditions' => 'test',
                        'MULSEL_Conditions' => 'Autism Spectrum Disorders'
                    }
                },
                'FRML_CheckPastConditionsNull' => false,
                'MSG_DateWrongPrescription' => null,
                'LWC_SelectCensusMember' => new Map<String, Object> {
                    'SelectedCensusMemberName' => 'FourMember Member',
                    'SelectedCensusMemberId' => 'MEM-1754063239909826'
                },
                'ED_MemberPrescription' => new List<Object> {
                    new Map<String, Object> {
                        'index' => 0,
                        'memberId' => listGCM[1].Id,
                        'FRML_MemberBirthdate' => null,
                        'TXT_DateDiscontinued' => '2025-07-28',
                        'TXT_DatePrescribed' => '2025-03-04',
                        'TXT_MemberName' => 'TwoMember Member',
                        'TXT_MemberIdPrescription' => listGCM[1].Id,
                        'TXT_hasErrorMedication' => 'false',
                        'TXT_ReasonForMedication' => 'medication edited',
                        'TXT_PrescribingPhysician' => 'Physician  medication edited',
                        'TXT_NameOfMedication' => 'Medication edited'
                    },
                    new Map<String, Object> {
                        'index' => null,
                        'memberId' => null,
                        'FRML_MemberBirthdate' => null,
                        'TXT_DateDiscontinued' => '2025-07-28',
                        'TXT_DatePrescribed' => '2025-07-30',
                        'TXT_MemberName' => 'FourMember Member',
                        'TXT_MemberIdPrescription' => 'MEM-1754063239909826',
                        'TXT_hasErrorMedication' => 'false',
                        'TXT_ReasonForMedication' => 'medication',
                        'TXT_PrescribingPhysician' => 'Physician medication',
                        'TXT_NameOfMedication' => 'Medication'
                    }
                },
                'FRML_CheckPrescriptionsIsNull' => false,
                'FRML_DateWrongPrescription' => false,
                'MSG_WrongDatePCP' => null,
                'FRML_WrongDatePCP' => false,
                'EB_Physicians' => new List<Object> {
                    new Map<String, Object> {
                        'memberId' => listGCM[1].Id,
                        'TXT_hasErrorPCP' => 'false',
                        'TXT_PhysicianPhone' => '2222222333',
                        'TXT_PhysicianCity' => 'San Dieguito',
                        'TXT_PhysicianName' => 'Physician TwoMember edited',
                        'TXT_CensusMemberName' => 'TwoMember Member'
                    },
                    new Map<String, Object> {
                        'memberId' => 'MEM-1754063239909826',
                        'TXT_hasErrorPCP' => 'false',
                        'TXT_PhysicianPhone' => 'FourMember Member',
                        'TXT_PhysicianCity' => 'Physician four member',
                        'TXT_PhysicianName' => 'san diego',
                        'TXT_CensusMemberName' => '3333333333'
                    }
                },
                'RAD_PastConditions' => 'Yes',
                'RAD_LicenceSuspended' => 'Yes',
                'RAD_Addictions' => 'Yes',
                'RAD_PendingTests' => 'Yes',
                'RAD_UnexplainedSymptoms' => 'Yes',
                'RAD_PrescriptionMedications' => 'Yes',
                'RAD_ParentSiblingDiagnosed' => 'Yes',
                'RAD_Cancer' => 'Yes',
                'aRC_showErrorInMedicationStep' => new Map<String, Object> {
                    'hasErrorMedication' => false,
                    'hasErrorUnexpected' => false,
                    'hasErrorAddictions' => false,
                    'hasErrorPCP' => false,
                    'hasErrorCancer' => false
                }
            },
            'STEP_HIPAAAuthorizationForm' => new Map<String, Object> {
                'FRML_HipaaAuthCount' => 2,
                'NewHipaa' => new Map<String, Object> {
                    'TXT_NewFirstName' => 'externalhipaa',
                    'TXT_NewLastName' => 'hipaa',
                    'TXT_NewAdress-Block' => new Map<String, Object> {
                        'TXT_NewAdress' => 'Siempre Viva Ct, San Diego, CA 92154, USA',
                        'TXT_AddCountry' => 'United States',
                        'TXT_AddAddress' => 'Siempre Viva Court',
                        'TXT_AddZipCode' => '92154',
                        'TXT_AddCity' => 'San Diego'
                    },
                    'TXT_NewBirthdate' => '2000-07-30',
                    'TXT_NewTelephone' => '5555555555',
                    'TXT_NewEmailAdress' => 'member8@yopmail.com'
                },
                'Formula1' => false,
                'EDITBLK_HIPAAAuthorizedParties' => new List<Object> {
                    new Map<String, Object> {
                        'Id' => listGCM[1].Id,
                        'CHK_Authorized' => true,
                        'DAT_DOB' => '2000-08-06',
                        'TXT_Telephone' => '2222222222',
                        'TXT_EmailAddress' => 'member2@yopmail.com',
                        'TXT_ZipCode' => '81210',
                        'TXT_State' => 'CO',
                        'TXT_City' => 'Tincup',
                        'TXT_Address' => 'County Road 267D',
                        'TXT_lastName' => 'Member',
                        'TXT_firstName' => 'TwoMember',
                        'TXT_Relationship' => 'Primary',
                        'TXT_FullName' => 'TwoMember Member'
                    },
                    new Map<String, Object> {
                        'Id' => 'MEM-1754063239909826',
                        'CHK_Authorized' => true,
                        'DAT_DOB' => '2000-07-27',
                        'TXT_Telephone' => '4444444444',
                        'TXT_EmailAddress' => 'member4@yopmail.com',
                        'TXT_ZipCode' => '81210',
                        'TXT_State' => 'CO',
                        'TXT_City' => 'Tincup',
                        'TXT_Address' => 'County Road 267D',
                        'TXT_lastName' => 'Member',
                        'TXT_firstName' => 'FourMember',
                        'TXT_Relationship' => 'Spouse',
                        'TXT_FullName' => 'FourMember Member'
                    }
                },
                'RAD_AuthorizeOthers' => 'Yes'
            },
            'PrimaryMember' => new Map<String, Object> {
                'MemberID' => listGCM[0].Member_ID__c,
                'Id' => listGCM[0].Id,
                'Birthdate' => '2000-08-04',
                'BillingStreet' => 'Siempre Viva Court',
                'BillingState' => 'CA',
                'BillingPostalCode' => '92154',
                'BillingCity' => 'San Diego',
                'Email' => 'member1@yopmail.com',
                'Name' => 'OneMember Member'
            },
            'canSpinOff' => true,
            'statusSpinOff' => '',
            'reasonSpinOff' => false,
            'hasOneMember' => false,
            'SpinOffSelectionRefactor' => true,
            'FullPermissionEffectiveDate' => 'Full_Permission_Effective_Date',
            'BackdateEffectiveDate' => 'Backdate_Effective_Date',
            'childLoseAncillary' => false,
            'retained_count' => 1,
            'spinned_off_count' => 3,
            'CensusId' => listGCM[0].vlocity_ins__CensusId__c,
            'userId' => UserInfo.getUserId(),
            'STEP_MedicareCoverage' => null,
            'STEP_GuardiansInformation' => null,
            'STEP_CompleteSpinOff' => null,
            'SellingAgentId' => usr.Id
        };
    }

    @isTest //Spin Off; Program Upgrade; Ancillary Change; Remove Member; Add Member | Case Fee | Credit Card | feeApplicable == true
    static void soTest1() {
        // Create and fill the inputMap
        Map<String, Object> inputMap = createInputMapForSpinOff();
        inputMap.put('inputData', JSON.serialize(inputMap));
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_SpinOff_BaseService baseService = new ARC_SpinOff_BaseService();

        // Run the test
        Test.startTest();
        baseService.invokeMethod('RA_SingleSpinOffDML', inputMap, outputMap, options);
        Test.stopTest();
    }

    @isTest //Spin Off; Guardian | Bank Account | Charge Fee | feeApplicable == true
    static void soTest2() {
        // Create the inputMap with its data
        Map<String, Object> inputMap = createInputMapForSpinOff();
        inputMap.put('inputData', JSON.serialize(inputMap));

        Contract contract = [SELECT Id, AccountId FROM Contract ORDER BY CreatedDate LIMIT 1];

        Account guardian = [SELECT Id, PersonContactId FROM Account WHERE RecordType.DeveloperName = 'ARC_Guardian' ORDER BY CreatedDate LIMIT 1];
        
        ChargentBase__Gateway__c gateway = new ChargentBase__Gateway__c(
            Name = 'Bank Gateway',
            ChargentBase__Available_Payment_Methods__c = 'Bank Account',
            ChargentBase__Active__c = true
        );
        insert gateway;

        ChargentOrders__ChargentOrder__c existingOrder = new ChargentOrders__ChargentOrder__c(
            ARC_Contract__c = contract.Id,
            ChargentOrders__Billing_First_Name__c = 'Norman',
            ChargentOrders__Billing_Last_Name__c = 'Beer',
            ChargentOrders__Bank_Routing_Number__c = '333333333',
            ChargentOrders__Bank_Account_Number__c = '22222222222222222',
            ChargentOrders__Bank_Name__c = 'Santander',
            ChargentOrders__Bank_Account_Type__c = 'Checking',
            ChargentOrders__Payment_Method__c = 'Bank Account',
            ChargentOrders__Gateway__c = gateway.Id,
            ChargentOrders__Charge_Amount__c = 99,
           // ChargentOrders__Charge_Date__c = '04-01-2025',
            ChargentOrders__Charge_Date__c = null,
            ARC_FirstMonthPayed__c = true,
            ChargentOrders__Manual_Charge__c = true,
            ChargentOrders__Description__c = 'Recurring'
        );
        insert existingOrder;

        contract.ARC_AppFeeOrder__c = existingOrder.Id;
        update contract;

        // Modify the inputMap in order to set the extra data
        inputMap.put('soChanges', new Map<String, Object> {
                'soReasonsString' => 'Spin Off; Program Upgrade; Ancillary Change',
                'feeApplicable' => true,
                'soReasons' => new Map<String, Object> {
                    'ancillaryChange' => true, 
                    'removeMember' => false, 
                    'addMember' => false, 
                    'agingOut' => false, 
                    'programDowngrade' => false, 
                    'programUpgrade' => true, 
                    'spinOff' => true
                },
                'programSummaryFeeText' => 'One Time Change Fee (Program Upgrade): 99.000',
                'feeAmount' => 99
        });

        ARC_PromotionCode__c promo = [SELECT Id FROM ARC_PromotionCode__c LIMIT 1];

        inputMap.put('STEP_ChargentPayment', new Map<String, Object> {
                'RAD_ChargeAppFeeDefTrue' => 'Yes',
                'BLK_ChargeFee' => new Map<String, Object> {
                    'BLK_PaymentInfo' => new Map<String, Object> {
                        'BLK_CreditCard' => null,
                        'BLK_BankAccount' => new Map<String, Object> {
                            'TXT_RoutingNumber' => '497411985',
                            'TXT_LastNameOnAccount' => 'Member',
                            'TXT_AccNumber' => '74612900',
                            'TXT_FirstNameOnAccount' => 'Childtwo',
                            'TXT_BankName' => 'BankTest',
                            'SLC_AccType' => 'Checking'
                        }
                    },
                    'LWC_PromoDiscountCodeRefactor' => new Map<String, Object> {
                        'Id' => null,
                        'PromotionCodeId' => promo.Id,
                        'PromotionCodeName' => 'LUC20',
                        'ApplyOver' => 'Medical',
                        'DiscountAmount' => '28.37',
                        'MedicalPrice' => 189.13,
                        'DiscountPrice' => '160.76',
                        'AgentId' => UserInfo.getUserId()
                    },
                    'BLK_CaseCreationDetails' => null,
                    'RAD_MethodOfPayment' => 'Bank Account'
                }
        });
        
        inputMap.put('STEP_HIPAAAuthorizationForm', new Map<String, Object> {
                'Formula2' => true,
                'Formula4' => true,
                'MSG_Authorized' => true,
                'FRML_HipaaAuthCount' => 1,
                'NewHipaa' => null,
                'Formula1' => false,
                'EDITBLK_HIPAAAuthorizedParties' => new Map<String, Object> {
                    'CHK_Authorized' => true,
                    'DAT_DOB' => '2000-07-27',
                    'TXT_ZipCode' => '92154',
                    'TXT_City' => 'Diego',
                    'TXT_Address' => 'Siempre Viva Court',
                    'TXT_State' => 'CA',
                    'TXT_EmailAddress' => 'guardianmember@yopmail.com',
                    'TXT_Telephone' => '2222222222',
                    'TXT_Relationship' => 'Legal Guardian',
                    'TXT_lastName' => 'Member',
                    'TXT_firstName' => 'Guardian',
                    'TXT_FullName' => 'Guardian Member'
                },
                'RAD_AuthorizeOthers' => 'No'
        });
        
        inputMap.put('STEP_GuardiansInformation', new Map<String, Object> {
                'TXT_GuardianSSN' => new Map<String, Object> {
                    'validation' => true,
                    'response' => '222222222'
                },
                'FRML_GuardianNameForDocusign' => 'Guardian Member',
                'FRML_GuardianDOB' => 25,
                'DATE_GuardianBirthdate' => '2000-07-29',
                'PersonContactId' => guardian.PersonContactId,
                'Id' => guardian.Id,
                'THEADBLK_GuardianAddress-Block'  => new Map<String, Object> {
                    'TXT_GuardianStreet' => 'Siempre Viva Court',
                    'THEADBLK_GuardianAddress' => 'Siempre Viva Court, San Diego, CA 92154, United States',
                    'TXT_GuardianZipCode' => '92154',
                    'TXT_GuardianState' => 'CA',
                    'TXT_GuardianCity' => 'San Diego'
                },
                'TXT_GuardianPhone' => '2222222222',
                'TXT_GuardianLastName' => 'Member',
                'TXT_GuardianFirstName' => 'Guardian',
                'SEL_GuardianRelationship' => 'Legal Guardian',
                'SEL_GuardianGender' => 'Male',
                'EMAIL_GuardianEmail' => 'guardianmember@yopmail.com'
        });

        inputMap.put('SelectedContractInfo', new Map<String, Object> {
                'GuardianId' => guardian.Id
        });

        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        // Call the method
        ARC_SpinOff_BaseService baseService = new ARC_SpinOff_BaseService();
        Test.startTest();
        baseService.invokeMethod('RA_SingleSpinOffDML', inputMap, outputMap, options);
        Test.stopTest();
    }
    
    @isTest
    static void soTest3_error_expected() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'soChanges' => new Map<String, Object>{ 'soReasons' => null }
        };
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options   = new Map<String, Object>();

        ARC_SpinOff_BaseService baseService = new ARC_SpinOff_BaseService();

        Boolean threw = false;
        String  msg   = null;
        String  type  = null;

        Test.startTest();
        try {
            baseService.invokeMethod('RA_SingleSpinOffDML', inputMap, outputMap, options);
        } catch (Exception e) {
            threw = true;
            msg   = e.getMessage();       
            type  = e.getTypeName();    
        }
        Test.stopTest();

        System.assert(threw, 'Expected an exception when soReasons = null.');
    }

    @isTest
    static void soTest4() {
        List<String> methods = new List<String>{
            'TRANSFORM_CensusMemberToUserInputs',
            'GET_CensusMembers',
            'censusPlanSelectionChanges',
            'TRANSFORM_RemoveMemberContractCalculatePrice',
            'TRANSFORM_ChooseProductSelectionData',
            'readMedicalQuestions',
            'childLoseAncillary',
            'includeGuardianAsHipaa',
            'getHipaaRecipients',
            'getDocuSignData',
            'updateEnvelopeContractData'
        };
        List<String> errors = new List<String>();

        Test.startTest();
        for (String m : methods) {
            ARC_SpinOff_BaseService svc = new ARC_SpinOff_BaseService();
            Map<String,Object> inMap = new Map<String,Object>();
            Map<String,Object> outMap = new Map<String,Object>();
            Map<String,Object> opts  = new Map<String,Object>();

            if (m == 'updateEnvelopeContractData') {
                inMap.put('EnvelopeContractData', 
                new Map<String,Object> {
                    'contractId' => '800cb00000AAAaTEST',
                    'signerEmail' => 'testTester@yopmail.com',
                    'signerName' => 'Test Tester',
                    'envelopeId' => '11aa1111-a1a1-1a11-1111-111aa11aa111'
                });
            }

            try {
                svc.invokeMethod(m, inMap, outMap, opts);
            } catch (Exception e) {
                errors.add(m + ': ' + e.getMessage());
            }
        }
        Test.stopTest();
    }

    @isTest
    static void soTest5_error_DML2() {
        Account acc = new Account(Name='Ctx Short'); insert acc;

        String jsonUWCase          = 'null';
        String jsonChargentMap     = '{}';
        String jsonUWCaseMembers   = '{}';
        String jsonPromotionDisc   = null;
        String fullJson            = '{"foo":"bar"}';

        Boolean rethrew = false;

        Test.startTest();
        try {
        ARC_SODML.handleUWCaseAndMembersFuture(
            jsonUWCase, null, null, jsonChargentMap, jsonUWCaseMembers, fullJson, acc.Id, jsonPromotionDisc
        );
        
            Test.stopTest();
        } catch (Exception e) {
            rethrew = true;
        }
        //System.assert(rethrew, 'The @future must be re-launch the exception.');
    }

    @isTest
    static void soTest5_error_DML3() {
       // Map<String,Object> soReasons = new Map<String,Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        Map<String, Object> inputMap = createInputMapForSpinOff();
        inputMap.put('soChanges', new Map<String, Object> {
            'soReasonsString' => null,
            'feeApplicable' => true,
            'soReasons' => null,
            'programSummaryFeeText' => 'One Time Change Fee ():',
            'feeAmount' => 0
            }
        );
        inputMap.put('inputData', JSON.serialize(inputMap));

        //ARC_SOManager manager = new ARC_SOManager(soReasons, inputMap);
        ARC_SpinOff_BaseService baseService = new ARC_SpinOff_BaseService();
       // manager.actionsToPerform = new Set<String>{'multiSpinOff'};

        Boolean rethrew = false;

        Test.startTest();
        //new ARC_SODML().manageDML(manager);
        try {
            baseService.invokeMethod('RA_SingleSpinOffDML', inputMap, outputMap, options);
            Test.stopTest();
        } catch (Exception e) {
            rethrew = true;
        }
        System.assert(rethrew, 'test.');
    } 

    @isTest
    static void test_removeSelectedAncillaries() {
        ARC_SpinOff_BaseService service = new ARC_SpinOff_BaseService();
        Map<String, Object> input = new Map<String, Object>{
            'selectedProducts' => new List<Object>{
                new Map<String, Object>{'Type__c' => 'Medical', 'ProductCode' => 'Medical-Premier'},
                new Map<String, Object>{'Type__c' => 'Ancillary', 'ProductCode' => 'Dental'}
            }
        };
        Map<String, Object> output = new Map<String, Object>();
        
        Test.startTest();
        service.invokeMethod('removeSelectedAncillaries', input, output, new Map<String, Object>());
        Test.stopTest();

        System.assert(output.containsKey('selectedProducts'), 'Filtered products list should be present in output.');
    }

    @isTest
    static void test_DirectMethodCalls() {
        Account groupAcc = new Account(Name = 'Group Account');
        insert groupAcc;
        Contract c = new Contract(AccountId = groupAcc.Id, StartDate = Date.today());
        insert c;

        ARC_SpinOff_BaseService service = new ARC_SpinOff_BaseService();
        ARC_SpinOff_Utilities util = new ARC_SpinOff_Utilities();

        Map<String, Object> envInput = new Map<String, Object>{
            'EnvelopeContractData' => new Map<String, Object>{
                'contractId' => c.Id, 'signerEmail' => 'test@test.com', 'signerName' => 'Signer', 'envelopeId' => '12345'
            }
        };
        service.invokeMethod('updateEnvelopeContractData', envInput, new Map<String, Object>(), new Map<String, Object>());

        Map<String, Object> sendInput = new Map<String, Object>{
            'EnvelopeInformation' => new Map<String, Object>{
                'signerList' => new List<Object>(), 'templateIdList' => new List<Object>(), 'tabs' => new Map<String, Object>()
            },
            'contractId' => c.Id
        };
        service.invokeMethod('sendEnvelope', sendInput, new Map<String, Object>(), new Map<String, Object>());

        Map<String, Object> prodInput = new Map<String, Object>{
            'planSelected' => true,
            'selectedProducts' => new List<Object>{
                new Map<String, Object>{'Type__c' => 'Medical', 'ProductCode' => 'PROG_Premier', 'Id' => '01t000000000000'},
                new Map<String, Object>{'Type__c' => 'Ancillary', 'ProductCode' => 'PROG_CriticalCare'}
            },
            'oldProducts' => new List<Object>{
                new Map<String, Object>{'Type__c' => 'Medical', 'ProductCode' => 'PROG_Old'}
            },
            'userInputs' => new List<Object>{
                new Map<String, Object>{'Id' => 'MEM-1', 'RF_Census.CM_Age' => 25, 'IsNewMember' => true}
            }
        };
        Map<String, Object> prodOutput = new Map<String, Object>();
        service.invokeMethod('includeProductCodeToUserInputs', prodInput, prodOutput, new Map<String, Object>());
        service.invokeMethod('includePremierSelected', prodInput, prodOutput, new Map<String, Object>());
        service.invokeMethod('removeSelectedAncillaries', prodInput, prodOutput, new Map<String, Object>());

        Boolean threwException = false;
        try {
            util.invokeMethod('METODO_INVENTADO_PARA_FALLAR', new Map<String, Object>(), new Map<String, Object>(), new Map<String, Object>());
        } catch(AuraHandledException e) {
            threwException = true;
        }
        System.assert(threwException, 'Should throw exception for unknown method');

        util.invokeMethod('includeGuardianAsHipaa', new Map<String, Object>(), new Map<String, Object>(), new Map<String, Object>());
    }
}