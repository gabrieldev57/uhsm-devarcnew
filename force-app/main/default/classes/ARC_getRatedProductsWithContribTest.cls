@IsTest
public class ARC_getRatedProductsWithContribTest {
    
    @TestSetup
    static void setupData() {
        Account groupAccount = new Account(
            Name = 'Test Group Account'
        );
        insert groupAccount;

        Account memberAccount = new Account(
            LastName = 'Smith',
            ARC_GroupAccount__c = groupAccount.Id
        );
        insert memberAccount;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(
            Name = 'Test Census',
            vlocity_ins__GroupId__c = groupAccount.Id
        );
        insert census;

        vlocity_ins__GroupCensusMember__c primaryMember = new vlocity_ins__GroupCensusMember__c(
            Name = 'John Smith',
            vlocity_ins__CensusId__c = census.Id,
            vlocity_ins__AccountId__c = memberAccount.Id,
            vlocity_ins__IsPrimaryMember__c = true,
            ARC_EmployeeType__c = 'Full Time'
            //ARC_EmployeeTier__c = 'Employee Only'
        );
        insert primaryMember;

        Contract contractRecord = new Contract(
            AccountId = groupAccount.Id,
            Status = 'Enrollment In Progress',
            StartDate = Date.today()
        );
        insert contractRecord;

        vlocity_ins__GroupClass__c groupClass = new vlocity_ins__GroupClass__c(
            Name = 'Test Group Class',
            vlocity_ins__GroupId__c = groupAccount.Id,
            ARC_Contract__c = contractRecord.Id,
            ARC_ContributionMethod__c = 'Flat_Amount',
            ARC_EmployeeTypeModel__c = 'None',
            ARC_ApplyProgramBased__c = false,
            ARC_ApplyEmployeeTier__c = false
        );
        insert groupClass;

        ARC_CensusMemberGroupClass__c memberGroupClass = new ARC_CensusMemberGroupClass__c(
            ARC_CensusMember__c = primaryMember.Id,
            ARC_GroupClass__c = groupClass.Id
        );
        insert memberGroupClass;

        vlocity_ins__GroupClassContribution__c contribution = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = groupClass.Id,
            vlocity_ins__ContributionAmount__c = 50,
            vlocity_ins__ContributionType__c = 'Amount',
            vlocity_ins__ProductCategory__c = 'Medical'
        );
        insert contribution;
    }

    @IsTest
    static void calculateMemberContribution_flatAmount_appliesAmount() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 150
        };

        Test.startTest();
        Map<String, Decimal> result =
            ARC_getRatedProductsWithContributions.calculateMemberContribution(
                primaryMember.Id,
                pricedProducts
            );
        Test.stopTest();

        System.assertEquals(
            150,
            result.get('WeShare Group Enhanced'),
            'Flat Amount contribution should subtract 50 from Enhanced product'
        );

        System.assertEquals(
            100,
            result.get('WeShare Group Essential'),
            'Flat Amount contribution should subtract 50 from Essential product'
        );
    }

    @IsTest
    static void calculateMemberContribution_flatPercentage_appliesPercentage() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Flat_Percentage';
        update groupClass;

        vlocity_ins__GroupClassContribution__c contribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];

        contribution.vlocity_ins__ContributionAmount__c = null;
        contribution.vlocity_ins__ContributionPercent__c = 25;
        contribution.vlocity_ins__ContributionType__c = 'Percent';
        update contribution;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 160
        };

        Test.startTest();
        Map<String, Decimal> result =
            ARC_getRatedProductsWithContributions.calculateMemberContribution(
                primaryMember.Id,
                pricedProducts
            );
        Test.stopTest();

        System.assertEquals(
            150,
            result.get('WeShare Group Enhanced'),
            'Flat Percentage contribution should subtract 25% from Enhanced product'
        );

        System.assertEquals(
            120,
            result.get('WeShare Group Essential'),
            'Flat Percentage contribution should subtract 25% from Essential product'
        );
    }

    @IsTest
    static void calculateMemberContribution_legacyProduct_keepsOriginalPrice() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Legacy' => 300
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            primaryMember.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            150,
            result.get('WeShare Group Enhanced'),
            'Non-Legacy product should still receive the flat amount contribution'
        );

        System.assertEquals(
            300,
            result.get('WeShare Group Legacy'),
            'Legacy product should keep its original price and should not receive contribution'
        );
    }

    @IsTest
    static void calculateMemberContribution_nullPrice_keepsNull() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => null
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            primaryMember.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            150,
            result.get('WeShare Group Enhanced'),
            'Product with a valid price should still receive the flat amount contribution'
        );

        System.assertEquals(
            null,
            result.get('WeShare Group Essential'),
            'Product with null price should remain null and should not cause contribution calculation errors'
        );
    }

    @IsTest
    static void calculateMemberContribution_percentLowestCost_appliesPercentageFromLowestProduct() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Percent_Of_Lowest_Cost';
        update groupClass;

        vlocity_ins__GroupClassContribution__c contribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];

        contribution.vlocity_ins__ContributionAmount__c = null;
        contribution.vlocity_ins__ContributionPercent__c = 50;
        contribution.vlocity_ins__ContributionType__c = 'Percent';
        update contribution;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 100
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            primaryMember.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            150,
            result.get('WeShare Group Enhanced'),
            'Percent Of Lowest Cost should subtract 50% of the lowest product price from Enhanced product'
        );

        System.assertEquals(
            50,
            result.get('WeShare Group Essential'),
            'Percent Of Lowest Cost should subtract 50% of the lowest product price from Essential product'
        );
    }

    @IsTest
    static void calculateMemberContribution_percentLowestByCategory_appliesCategoryLowestPercentage() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Percent_Of_Lowest_By_Category';
        update groupClass;

        vlocity_ins__GroupClassContribution__c contribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c,
                vlocity_ins__ProductCategory__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];

        contribution.vlocity_ins__ContributionAmount__c = null;
        contribution.vlocity_ins__ContributionPercent__c = 50;
        contribution.vlocity_ins__ContributionType__c = 'Percent';
        contribution.vlocity_ins__ProductCategory__c = 'Medical';
        update contribution;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 100
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            primaryMember.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            100,
            result.get('WeShare Group Enhanced'),
            'Percent Of Lowest By Category currently subtracts 50% from the Enhanced product base price when the product matches the Medical category'
        );

        System.assertEquals(
            50,
            result.get('WeShare Group Essential'),
            'Percent Of Lowest By Category should subtract 50% of the lowest Medical product price from Essential product'
        );
    }

    @IsTest
    static void calculateMemberContribution_missingMemberGroupClass_returnsOriginalPrices() {
        vlocity_ins__GroupCensus__c census = [
            SELECT Id, vlocity_ins__GroupId__c
            FROM vlocity_ins__GroupCensus__c
            LIMIT 1
        ];

        Account memberAccountWithoutGroupClass = new Account(
            LastName = 'No Group Class',
            ARC_GroupAccount__c = census.vlocity_ins__GroupId__c
        );
        insert memberAccountWithoutGroupClass;

        vlocity_ins__GroupCensusMember__c memberWithoutGroupClass = new vlocity_ins__GroupCensusMember__c(
            Name = 'Member Without Group Class',
            vlocity_ins__CensusId__c = census.Id,
            vlocity_ins__AccountId__c = memberAccountWithoutGroupClass.Id,
            vlocity_ins__IsPrimaryMember__c = true,
            ARC_EmployeeType__c = 'Full Time'
        );
        insert memberWithoutGroupClass;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 150
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            memberWithoutGroupClass.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            200,
            result.get('WeShare Group Enhanced'),
            'When the member has no ARC_CensusMemberGroupClass__c, Enhanced should keep the original price'
        );

        System.assertEquals(
            150,
            result.get('WeShare Group Essential'),
            'When the member has no ARC_CensusMemberGroupClass__c, Essential should keep the original price'
        );
    }

    @IsTest
    static void calculateMemberContribution_missingContract_returnsOriginalPrices() {
        Account groupAccountWithoutContract = new Account(
            Name = 'Group Account Without Contract'
        );
        insert groupAccountWithoutContract;

        Account memberAccountWithoutContract = new Account(
            LastName = 'No Contract',
            ARC_GroupAccount__c = groupAccountWithoutContract.Id
        );
        insert memberAccountWithoutContract;

        vlocity_ins__GroupCensus__c censusWithoutContract = new vlocity_ins__GroupCensus__c(
            Name = 'Census Without Contract',
            vlocity_ins__GroupId__c = groupAccountWithoutContract.Id
        );
        insert censusWithoutContract;

        vlocity_ins__GroupCensusMember__c memberWithoutContract = new vlocity_ins__GroupCensusMember__c(
            Name = 'Member Without Contract',
            vlocity_ins__CensusId__c = censusWithoutContract.Id,
            vlocity_ins__AccountId__c = memberAccountWithoutContract.Id,
            vlocity_ins__IsPrimaryMember__c = true,
            ARC_EmployeeType__c = 'Full Time'
        );
        insert memberWithoutContract;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 150
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            memberWithoutContract.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            200,
            result.get('WeShare Group Enhanced'),
            'When the member group account has no valid Contract, Enhanced should keep the original price'
        );

        System.assertEquals(
            150,
            result.get('WeShare Group Essential'),
            'When the member group account has no valid Contract, Essential should keep the original price'
        );
    }

    @IsTest
    static void calculateMemberContribution_flatAmount_employeeType_appliesMatchingContribution() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id, ARC_EmployeeType__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_EmployeeTypeModel__c, ARC_ContributionMethod__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_EmployeeTypeModel__c = 'FullTime_PartTime';
        groupClass.ARC_ContributionMethod__c = 'Flat_Amount';
        update groupClass;

        vlocity_ins__GroupClassContribution__c contribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionType__c,
                ARC_EmployeeType__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];
        contribution.vlocity_ins__ContributionAmount__c = 50;
        contribution.vlocity_ins__ContributionType__c = 'Amount';
        contribution.ARC_EmployeeType__c = primaryMember.ARC_EmployeeType__c;
        update contribution;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 150
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            primaryMember.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            150,
            result.get('WeShare Group Enhanced'),
            'When employee type matching is enabled and the contribution matches Full Time, Enhanced should receive the flat amount contribution'
        );

        System.assertEquals(
            100,
            result.get('WeShare Group Essential'),
            'When employee type matching is enabled and the contribution matches Full Time, Essential should receive the flat amount contribution'
        );
    }

    @IsTest
    static void calculateMemberContribution_programBasedFlatAmount_appliesPerProductContribution() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id, ARC_EmployeeType__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Contract contractRecord = [
            SELECT Id
            FROM Contract
            WHERE Status = 'Enrollment In Progress'
            LIMIT 1
        ];


        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c, ARC_ApplyProgramBased__c, ARC_EmployeeTypeModel__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Flat_Amount';
        groupClass.ARC_ApplyProgramBased__c = true;
        groupClass.ARC_EmployeeTypeModel__c = 'FullTime_PartTime';
        update groupClass;

        Product2 enhancedProduct = new Product2(
            Name = 'WeShare Group Enhanced',
            IsActive = true
        );
        Product2 essentialProduct = new Product2(
            Name = 'WeShare Group Essential',
            IsActive = true
        );
        insert new List<Product2>{ enhancedProduct, essentialProduct };

        vlocity_ins__ContractLineItem__c enhancedPlan = new vlocity_ins__ContractLineItem__c(
            Name = 'Enhanced Plan',
            vlocity_ins__ContractId__c = contractRecord.Id,
            vlocity_ins__Product2Id__c = enhancedProduct.Id
        );
        vlocity_ins__ContractLineItem__c essentialPlan = new vlocity_ins__ContractLineItem__c(
            Name = 'Essential Plan',
            vlocity_ins__ContractId__c = contractRecord.Id,
            vlocity_ins__Product2Id__c = essentialProduct.Id
        );
        insert new List<vlocity_ins__ContractLineItem__c>{ enhancedPlan, essentialPlan };

        vlocity_ins__GroupClassContribution__c existingContribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionType__c,
                vlocity_ins__ProductCategory__c,
                ARC_EmployeeType__c,
                ARC_ContractLineItem__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];
        existingContribution.vlocity_ins__ContributionAmount__c = 40;
        existingContribution.vlocity_ins__ContributionType__c = 'Amount';
        existingContribution.vlocity_ins__ProductCategory__c = 'Medical';
        existingContribution.ARC_EmployeeType__c = primaryMember.ARC_EmployeeType__c;
        existingContribution.ARC_ContractLineItem__c = enhancedPlan.Id;
        update existingContribution;

        vlocity_ins__GroupClassContribution__c essentialContribution = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = groupClass.Id,
            vlocity_ins__ContributionAmount__c = 20,
            vlocity_ins__ContributionType__c = 'Amount',
            vlocity_ins__ProductCategory__c = 'Medical',
            ARC_EmployeeType__c = primaryMember.ARC_EmployeeType__c,
            ARC_ContractLineItem__c = essentialPlan.Id
        );
        insert essentialContribution;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 150
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            primaryMember.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            160,
            result.get('WeShare Group Enhanced'),
            'Program-based Flat Amount should apply the Enhanced-specific contribution of 40'
        );

        System.assertEquals(
            130,
            result.get('WeShare Group Essential'),
            'Program-based Flat Amount should apply the Essential-specific contribution of 20'
        );
    }

    @IsTest
    static void calculateMemberContribution_programBasedFlatPercentage_appliesPerProductPercentage() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id, ARC_EmployeeType__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Contract contractRecord = [
            SELECT Id
            FROM Contract
            WHERE Status = 'Enrollment In Progress'
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c, ARC_ApplyProgramBased__c, ARC_EmployeeTypeModel__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Flat_Percentage';
        groupClass.ARC_ApplyProgramBased__c = true;
        groupClass.ARC_EmployeeTypeModel__c = 'FullTime_PartTime';
        update groupClass;

        Product2 enhancedProduct = new Product2(
            Name = 'WeShare Group Enhanced',
            IsActive = true
        );
        Product2 essentialProduct = new Product2(
            Name = 'WeShare Group Essential',
            IsActive = true
        );
        insert new List<Product2>{ enhancedProduct, essentialProduct };

        vlocity_ins__ContractLineItem__c enhancedPlan = new vlocity_ins__ContractLineItem__c(
            Name = 'Enhanced Percentage Plan',
            vlocity_ins__ContractId__c = contractRecord.Id,
            vlocity_ins__Product2Id__c = enhancedProduct.Id
        );
        vlocity_ins__ContractLineItem__c essentialPlan = new vlocity_ins__ContractLineItem__c(
            Name = 'Essential Percentage Plan',
            vlocity_ins__ContractId__c = contractRecord.Id,
            vlocity_ins__Product2Id__c = essentialProduct.Id
        );
        insert new List<vlocity_ins__ContractLineItem__c>{ enhancedPlan, essentialPlan };

        vlocity_ins__GroupClassContribution__c existingContribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c,
                vlocity_ins__ProductCategory__c,
                ARC_EmployeeType__c,
                ARC_ContractLineItem__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];
        existingContribution.vlocity_ins__ContributionAmount__c = null;
        existingContribution.vlocity_ins__ContributionPercent__c = 25;
        existingContribution.vlocity_ins__ContributionType__c = 'Percent';
        existingContribution.vlocity_ins__ProductCategory__c = 'Medical';
        existingContribution.ARC_EmployeeType__c = primaryMember.ARC_EmployeeType__c;
        existingContribution.ARC_ContractLineItem__c = enhancedPlan.Id;
        update existingContribution;

        vlocity_ins__GroupClassContribution__c essentialContribution = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = groupClass.Id,
            vlocity_ins__ContributionPercent__c = 10,
            vlocity_ins__ContributionType__c = 'Percent',
            vlocity_ins__ProductCategory__c = 'Medical',
            ARC_EmployeeType__c = primaryMember.ARC_EmployeeType__c,
            ARC_ContractLineItem__c = essentialPlan.Id
        );
        insert essentialContribution;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 150
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            primaryMember.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            150,
            result.get('WeShare Group Enhanced'),
            'Program-based Flat Percentage should apply the Enhanced-specific contribution of 25%'
        );

        System.assertEquals(
            135,
            result.get('WeShare Group Essential'),
            'Program-based Flat Percentage should apply the Essential-specific contribution of 10%'
        );
    }


    @IsTest
    static void calculateMemberContribution_programBasedPercentLowestCost_appliesPerProductLowestCost() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id, ARC_EmployeeType__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Contract contractRecord = [
            SELECT Id
            FROM Contract
            WHERE Status = 'Enrollment In Progress'
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c, ARC_ApplyProgramBased__c, ARC_EmployeeTypeModel__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Percent_Of_Lowest_Cost';
        groupClass.ARC_ApplyProgramBased__c = true;
        groupClass.ARC_EmployeeTypeModel__c = 'FullTime_PartTime';
        update groupClass;

        Product2 enhancedProduct = new Product2(
            Name = 'WeShare Group Enhanced',
            IsActive = true
        );
        Product2 essentialProduct = new Product2(
            Name = 'WeShare Group Essential',
            IsActive = true
        );
        insert new List<Product2>{ enhancedProduct, essentialProduct };

        vlocity_ins__ContractLineItem__c enhancedPlan = new vlocity_ins__ContractLineItem__c(
            Name = 'Enhanced Lowest Cost Plan',
            vlocity_ins__ContractId__c = contractRecord.Id,
            vlocity_ins__Product2Id__c = enhancedProduct.Id
        );
        vlocity_ins__ContractLineItem__c essentialPlan = new vlocity_ins__ContractLineItem__c(
            Name = 'Essential Lowest Cost Plan',
            vlocity_ins__ContractId__c = contractRecord.Id,
            vlocity_ins__Product2Id__c = essentialProduct.Id
        );
        insert new List<vlocity_ins__ContractLineItem__c>{ enhancedPlan, essentialPlan };

        vlocity_ins__GroupClassContribution__c existingContribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c,
                vlocity_ins__ProductCategory__c,
                ARC_EmployeeType__c,
                ARC_ContractLineItem__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];
        existingContribution.vlocity_ins__ContributionAmount__c = null;
        existingContribution.vlocity_ins__ContributionPercent__c = 50;
        existingContribution.vlocity_ins__ContributionType__c = 'Percent';
        existingContribution.vlocity_ins__ProductCategory__c = 'Medical';
        existingContribution.ARC_EmployeeType__c = primaryMember.ARC_EmployeeType__c;
        existingContribution.ARC_ContractLineItem__c = enhancedPlan.Id;
        update existingContribution;

        vlocity_ins__GroupClassContribution__c essentialContribution = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = groupClass.Id,
            vlocity_ins__ContributionPercent__c = 50,
            vlocity_ins__ContributionType__c = 'Percent',
            vlocity_ins__ProductCategory__c = 'Medical',
            ARC_EmployeeType__c = primaryMember.ARC_EmployeeType__c,
            ARC_ContractLineItem__c = essentialPlan.Id
        );
        insert essentialContribution;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 150
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            primaryMember.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            125,
            result.get('WeShare Group Enhanced'),
            'Program-based Percent Of Lowest Cost should subtract 50% of the lowest product price from Enhanced'
        );

        System.assertEquals(
            75,
            result.get('WeShare Group Essential'),
            'Program-based Percent Of Lowest Cost should subtract 50% of the lowest product price from Essential'
        );
    }

    @IsTest
    static void calculateMemberContribution_programBasedPercentLowestByCategory_appliesCategoryPercentage() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id, ARC_EmployeeType__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Contract contractRecord = [
            SELECT Id
            FROM Contract
            WHERE Status = 'Enrollment In Progress'
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c, ARC_ApplyProgramBased__c, ARC_EmployeeTypeModel__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Percent_Of_Lowest_By_Category';
        groupClass.ARC_ApplyProgramBased__c = true;
        groupClass.ARC_EmployeeTypeModel__c = 'FullTime_PartTime';
        update groupClass;

        Product2 enhancedProduct = new Product2(
            Name = 'WeShare Group Enhanced',
            IsActive = true
        );
        Product2 essentialProduct = new Product2(
            Name = 'WeShare Group Essential',
            IsActive = true
        );
        insert new List<Product2>{ enhancedProduct, essentialProduct };

        vlocity_ins__ContractLineItem__c enhancedPlan = new vlocity_ins__ContractLineItem__c(
            Name = 'Enhanced Lowest Category Plan',
            vlocity_ins__ContractId__c = contractRecord.Id,
            vlocity_ins__Product2Id__c = enhancedProduct.Id
        );
        vlocity_ins__ContractLineItem__c essentialPlan = new vlocity_ins__ContractLineItem__c(
            Name = 'Essential Lowest Category Plan',
            vlocity_ins__ContractId__c = contractRecord.Id,
            vlocity_ins__Product2Id__c = essentialProduct.Id
        );
        insert new List<vlocity_ins__ContractLineItem__c>{ enhancedPlan, essentialPlan };

        vlocity_ins__GroupClassContribution__c existingContribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c,
                vlocity_ins__ProductCategory__c,
                ARC_EmployeeType__c,
                ARC_ContractLineItem__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];
        existingContribution.vlocity_ins__ContributionAmount__c = null;
        existingContribution.vlocity_ins__ContributionPercent__c = 50;
        existingContribution.vlocity_ins__ContributionType__c = 'Percent';
        existingContribution.vlocity_ins__ProductCategory__c = 'Medical';
        existingContribution.ARC_EmployeeType__c = primaryMember.ARC_EmployeeType__c;
        existingContribution.ARC_ContractLineItem__c = enhancedPlan.Id;
        update existingContribution;

        vlocity_ins__GroupClassContribution__c essentialContribution = new vlocity_ins__GroupClassContribution__c(
            vlocity_ins__GroupClassId__c = groupClass.Id,
            vlocity_ins__ContributionPercent__c = 50,
            vlocity_ins__ContributionType__c = 'Percent',
            vlocity_ins__ProductCategory__c = 'Medical',
            ARC_EmployeeType__c = primaryMember.ARC_EmployeeType__c,
            ARC_ContractLineItem__c = essentialPlan.Id
        );
        insert essentialContribution;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => 150
        };

        Test.startTest();
        Map<String, Decimal> result = ARC_getRatedProductsWithContributions.calculateMemberContribution(
            primaryMember.Id,
            pricedProducts
        );
        Test.stopTest();

        System.assertEquals(
            100,
            result.get('WeShare Group Enhanced'),
            'Program-based Percent Of Lowest By Category currently subtracts 50% from the Enhanced base price when the product matches Medical'
        );

        System.assertEquals(
            75,
            result.get('WeShare Group Essential'),
            'Program-based Percent Of Lowest By Category currently subtracts 50% from the Essential base price when the product matches Medical'
        );
    }

    @IsTest
    static void getProductsWithContributionsJsonFromString_validInput_returnsProductPricing() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Product2 enhancedProduct = new Product2(
            Name = 'WeShare Group Enhanced 6k',
            ProductCode = 'PROG_UHSM_WeShareGroupEnhanced6k	',
            IsActive = true
        );
        Product2 essentialProduct = new Product2(
            Name = 'WeShare Group Essential 5k',
            ProductCode = 'PROG_UHSM_WeShareGroupEssential5k',
            IsActive = true
        );
        insert new List<Product2>{ enhancedProduct, essentialProduct };

        ARC_getRatedProductsWithContributions.testPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>{
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Enhanced 6k',
                            'Price' => 200
                        },
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Essential 5k',
                            'Price' => 150
                        }
                    }
                }
            }
        };

        String memberDataJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'Name' => 'John Smith',
                'Age' => 31,
                'PrimaryAge' => 31,
                'IsPrimary' => true,
                'PrimaryId' => primaryMember.Id,
                'IsLegacy' => false
            }
        });

        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Expected final result to be a JSON object keyed by product name, but got: ' + resultJson
        );

        Map<String, Object> resultByName = (Map<String, Object>) deserializedResult;
        System.assertEquals(2, resultByName.size(), 'The valid JSON input should return two priced products');

        Map<String, Object> enhancedResult = (Map<String, Object>) resultByName.get('WeShare Group Enhanced 6k');
        Map<String, Object> essentialResult = (Map<String, Object>) resultByName.get('WeShare Group Essential 5k');

        System.assertNotEquals(null, enhancedResult, 'Enhanced product should be present in the final JSON output');
        System.assertNotEquals(null, essentialResult, 'Essential product should be present in the final JSON output');

        System.assertEquals(200, Decimal.valueOf(String.valueOf(enhancedResult.get('basePrice'))), 'Enhanced base price should come from the mocked IP response');
        System.assertEquals(150, Decimal.valueOf(String.valueOf(enhancedResult.get('priceWithContributions'))), 'Enhanced price should apply the flat amount contribution');

        System.assertEquals(150, Decimal.valueOf(String.valueOf(essentialResult.get('basePrice'))), 'Essential base price should come from the mocked IP response');
        System.assertEquals(100, Decimal.valueOf(String.valueOf(essentialResult.get('priceWithContributions'))), 'Essential price should apply the flat amount contribution');
    }
    
    @IsTest
    static void getProductsWithContributionsJsonFromString_percentLowestByCategory_returnsCategoryPricing() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Percent_Of_Lowest_By_Category';
        update groupClass;

        vlocity_ins__GroupClassContribution__c contribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c,
                vlocity_ins__ProductCategory__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];
        contribution.vlocity_ins__ContributionAmount__c = null;
        contribution.vlocity_ins__ContributionPercent__c = 50;
        contribution.vlocity_ins__ContributionType__c = 'Percent';
        contribution.vlocity_ins__ProductCategory__c = 'Medical';
        update contribution;

        Product2 enhanced6k = new Product2(
            Name = 'WeShare Group Enhanced 6k',
            ProductCode = 'PROG_UHSM_WeShareGroupEnhanced6k',
            IsActive = true
        );
        Product2 enhanced12k = new Product2(
            Name = 'WeShare Group Enhanced 12k',
            ProductCode = 'PROG_UHSM_WeShareGroupEnhanced12k',
            IsActive = true
        );
        Product2 essential5k = new Product2(
            Name = 'WeShare Group Essential 5k',
            ProductCode = 'PROG_UHSM_WeShareGroupEssential5k',
            IsActive = true
        );
        insert new List<Product2>{ enhanced6k, enhanced12k, essential5k };

        ARC_getRatedProductsWithContributions.testPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>{
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Enhanced 6k',
                            'Price' => 200
                        },
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Enhanced 12k',
                            'Price' => 300
                        },
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Essential 5k',
                            'Price' => 150
                        }
                    }
                }
            }
        };

        String memberDataJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'Name' => 'John Smith',
                'Age' => 31,
                'PrimaryAge' => 31,
                'IsPrimary' => true,
                'PrimaryId' => primaryMember.Id,
                'IsLegacy' => false
            }
        });

        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Expected final result to be a JSON object keyed by product name, but got: ' + resultJson
        );

        Map<String, Object> resultByName = (Map<String, Object>) deserializedResult;
        System.assertEquals(3, resultByName.size(), 'The valid JSON input should return three priced products');

        Map<String, Object> enhanced6kResult = (Map<String, Object>) resultByName.get('WeShare Group Enhanced 6k');
        Map<String, Object> enhanced12kResult = (Map<String, Object>) resultByName.get('WeShare Group Enhanced 12k');
        Map<String, Object> essential5kResult = (Map<String, Object>) resultByName.get('WeShare Group Essential 5k');

        System.assertNotEquals(null, enhanced6kResult, 'Enhanced 6k should be present in the final JSON output');
        System.assertNotEquals(null, enhanced12kResult, 'Enhanced 12k should be present in the final JSON output');
        System.assertNotEquals(null, essential5kResult, 'Essential 5k should be present in the final JSON output');

        System.assertEquals(200, Decimal.valueOf(String.valueOf(enhanced6kResult.get('basePrice'))), 'Enhanced 6k base price should come from the mocked IP response');
        System.assertEquals(100, Decimal.valueOf(String.valueOf(enhanced6kResult.get('priceWithContributions'))), 'Enhanced 6k should subtract 50% of the lowest Enhanced category price');

        System.assertEquals(300, Decimal.valueOf(String.valueOf(enhanced12kResult.get('basePrice'))), 'Enhanced 12k base price should come from the mocked IP response');
        System.assertEquals(200, Decimal.valueOf(String.valueOf(enhanced12kResult.get('priceWithContributions'))), 'Enhanced 12k should subtract 50% of the lowest Enhanced category price');

        System.assertEquals(150, Decimal.valueOf(String.valueOf(essential5kResult.get('basePrice'))), 'Essential 5k base price should come from the mocked IP response');
        System.assertEquals(75, Decimal.valueOf(String.valueOf(essential5kResult.get('priceWithContributions'))), 'Essential 5k should subtract 50% of the lowest Essential category price');
    }
    
    
    @IsTest
    static void getProductsWithContributionsJsonFromString_flatPercentage_returnsPercentagePricing() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Flat_Percentage';
        update groupClass;

        vlocity_ins__GroupClassContribution__c contribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c,
                vlocity_ins__ProductCategory__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];
        contribution.vlocity_ins__ContributionAmount__c = null;
        contribution.vlocity_ins__ContributionPercent__c = 25;
        contribution.vlocity_ins__ContributionType__c = 'Percent';
        contribution.vlocity_ins__ProductCategory__c = 'Medical';
        update contribution;

        Product2 enhancedProduct = new Product2(
            Name = 'WeShare Group Enhanced 6k',
            ProductCode = 'PROG_UHSM_WeShareGroupEnhanced6k',
            IsActive = true
        );
        Product2 essentialProduct = new Product2(
            Name = 'WeShare Group Essential 5k',
            ProductCode = 'PROG_UHSM_WeShareGroupEssential5k',
            IsActive = true
        );
        insert new List<Product2>{ enhancedProduct, essentialProduct };

        ARC_getRatedProductsWithContributions.testPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>{
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Enhanced 6k',
                            'Price' => 200
                        },
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Essential 5k',
                            'Price' => 150
                        }
                    }
                }
            }
        };

        String memberDataJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'Name' => 'John Smith',
                'Age' => 31,
                'PrimaryAge' => 31,
                'IsPrimary' => true,
                'PrimaryId' => primaryMember.Id,
                'IsLegacy' => false
            }
        });

        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Expected final result to be a JSON object keyed by product name, but got: ' + resultJson
        );

        Map<String, Object> resultByName = (Map<String, Object>) deserializedResult;
        System.assertEquals(2, resultByName.size(), 'Flat Percentage should return two priced products');

        Map<String, Object> enhancedResult = (Map<String, Object>) resultByName.get('WeShare Group Enhanced 6k');
        Map<String, Object> essentialResult = (Map<String, Object>) resultByName.get('WeShare Group Essential 5k');

        System.assertNotEquals(null, enhancedResult, 'Enhanced product should be present in the final JSON output');
        System.assertNotEquals(null, essentialResult, 'Essential product should be present in the final JSON output');

        System.assertEquals(200, Decimal.valueOf(String.valueOf(enhancedResult.get('basePrice'))), 'Enhanced base price should come from the mocked IP response');
        System.assertEquals(150, Decimal.valueOf(String.valueOf(enhancedResult.get('priceWithContributions'))), 'Enhanced price should subtract 25%');

        System.assertEquals(150, Decimal.valueOf(String.valueOf(essentialResult.get('basePrice'))), 'Essential base price should come from the mocked IP response');
        System.assertEquals(112.50, Decimal.valueOf(String.valueOf(essentialResult.get('priceWithContributions'))), 'Essential price should subtract 25%');
    }

    @IsTest
    static void getProductsWithContributionsJsonFromString_percentLowestCost_returnsLowestCostPricing() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Percent_Of_Lowest_Cost';
        update groupClass;

        vlocity_ins__GroupClassContribution__c contribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c,
                vlocity_ins__ProductCategory__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];
        contribution.vlocity_ins__ContributionAmount__c = null;
        contribution.vlocity_ins__ContributionPercent__c = 50;
        contribution.vlocity_ins__ContributionType__c = 'Percent';
        contribution.vlocity_ins__ProductCategory__c = 'Medical';
        update contribution;

        Product2 enhancedProduct = new Product2(
            Name = 'WeShare Group Enhanced 6k',
            ProductCode = 'PROG_UHSM_WeShareGroupEnhanced6k',
            IsActive = true
        );
        Product2 essentialProduct = new Product2(
            Name = 'WeShare Group Essential 5k',
            ProductCode = 'PROG_UHSM_WeShareGroupEssential5k',
            IsActive = true
        );
        insert new List<Product2>{ enhancedProduct, essentialProduct };

        ARC_getRatedProductsWithContributions.testPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>{
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Enhanced 6k',
                            'Price' => 200
                        },
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Essential 5k',
                            'Price' => 150
                        }
                    }
                }
            }
        };

        String memberDataJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'Name' => 'John Smith',
                'Age' => 31,
                'PrimaryAge' => 31,
                'IsPrimary' => true,
                'PrimaryId' => primaryMember.Id,
                'IsLegacy' => false
            }
        });

        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Expected final result to be a JSON object keyed by product name, but got: ' + resultJson
        );

        Map<String, Object> resultByName = (Map<String, Object>) deserializedResult;
        System.assertEquals(2, resultByName.size(), 'Percent Of Lowest Cost should return two priced products');

        Map<String, Object> enhancedResult = (Map<String, Object>) resultByName.get('WeShare Group Enhanced 6k');
        Map<String, Object> essentialResult = (Map<String, Object>) resultByName.get('WeShare Group Essential 5k');

        System.assertNotEquals(null, enhancedResult, 'Enhanced product should be present in the final JSON output');
        System.assertNotEquals(null, essentialResult, 'Essential product should be present in the final JSON output');

        System.assertEquals(200, Decimal.valueOf(String.valueOf(enhancedResult.get('basePrice'))), 'Enhanced base price should come from the mocked IP response');
        System.assertEquals(125, Decimal.valueOf(String.valueOf(enhancedResult.get('priceWithContributions'))), 'Enhanced price should subtract 50% of the lowest product price');

        System.assertEquals(150, Decimal.valueOf(String.valueOf(essentialResult.get('basePrice'))), 'Essential base price should come from the mocked IP response');
        System.assertEquals(75, Decimal.valueOf(String.valueOf(essentialResult.get('priceWithContributions'))), 'Essential price should subtract 50% of the lowest product price');
    }

    
    @IsTest
    static void getProductsWithContributionsJsonFromString_legacyInput_usesLegacyPricingResponse() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Product2 seniorProduct = new Product2(
            Name = 'WeShare Group Senior',
            ProductCode = 'PROG_UHSM_WeShareGroupSenior',
            IsActive = true
        );
        insert seniorProduct;

        ARC_getRatedProductsWithContributions.testPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>()
                }
            }
        };

        ARC_getRatedProductsWithContributions.testLegacyPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>{
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Senior',
                            'Price' => 300
                        }
                    }
                }
            }
        };

        String memberDataJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'Name' => 'John Smith',
                'Age' => 67,
                'PrimaryAge' => 67,
                'IsPrimary' => true,
                'PrimaryId' => primaryMember.Id,
                'IsLegacy' => true
            }
        });

        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Expected legacy result to be a JSON object keyed by product name, but got: ' + resultJson
        );

        Map<String, Object> resultByName = (Map<String, Object>) deserializedResult;
        System.assertEquals(1, resultByName.size(), 'Legacy input should return one Senior product from the legacy pricing response');

        Map<String, Object> seniorResult = (Map<String, Object>) resultByName.get('WeShare Group Senior');
        System.assertNotEquals(null, seniorResult, 'Senior product should be present in the final legacy JSON output');

        System.assertEquals(
            300,
            Decimal.valueOf(String.valueOf(seniorResult.get('basePrice'))),
            'Senior base price should come from the mocked legacy IP response'
        );

        System.assertEquals(
            250,
            Decimal.valueOf(String.valueOf(seniorResult.get('priceWithContributions'))),
            'Senior product from the legacy pricing response should apply the current flat amount contribution logic'
        );
    }
    
    @IsTest
    static void getProductsWithContributionsJsonFromString_nullPriceProduct_returnsNoPriceNode() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Product2 enhancedProduct = new Product2(
            Name = 'WeShare Group Enhanced 6k',
            ProductCode = 'PROG_UHSM_WeShareGroupEnhanced6k',
            IsActive = true
        );
        insert enhancedProduct;

        ARC_getRatedProductsWithContributions.testPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>{
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Enhanced 6k',
                            'Price' => null
                        }
                    }
                }
            }
        };

        String memberDataJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'Name' => 'John Smith',
                'Age' => 31,
                'PrimaryAge' => 31,
                'IsPrimary' => true,
                'PrimaryId' => primaryMember.Id,
                'IsLegacy' => false
            }
        });

        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Expected final result to be a JSON object keyed by product name, but got: ' + resultJson
        );

        Map<String, Object> resultByName = (Map<String, Object>) deserializedResult;
        System.assertEquals(1, resultByName.size(), 'Null price scenario should return one product node');

        Map<String, Object> enhancedResult = (Map<String, Object>) resultByName.get('WeShare Group Enhanced 6k');
        System.assertNotEquals(null, enhancedResult, 'Enhanced product should be present in the final JSON output');

        System.assertEquals(
            true,
            enhancedResult.get('noPrice'),
            'Product with null base price should be marked as noPrice'
        );

        System.assertEquals(
            'No price available',
            enhancedResult.get('message'),
            'Product with null base price should return the no price message'
        );

        System.assertEquals(
            null,
            enhancedResult.get('employeeSplitPeriod'),
            'Product with null base price should not have employeeSplitPeriod'
        );

        System.assertEquals(
            enhancedProduct.Id,
            enhancedResult.get('productId'),
            'No price node should still include the Product2 Id'
        );
    }
    
    @IsTest
    static void getProductsWithContributionsJsonFromString_emptyInput_returnsError() {
        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString('');
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Empty input should return a JSON error object, but got: ' + resultJson
        );

        Map<String, Object> resultMap = (Map<String, Object>) deserializedResult;
        System.assertEquals(
            0,
            resultMap.size(),
            'Empty input should return an empty JSON object according to the current implementation'
        );
    }

    
    @IsTest
    static void getProductsWithContributionsJson_noPrimaryFlag_usesFirstAvailablePrimaryId() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Product2 enhancedProduct = new Product2(
            Name = 'WeShare Group Enhanced 6k',
            ProductCode = 'PROG_UHSM_WeShareGroupEnhanced6k',
            IsActive = true
        );
        insert enhancedProduct;

        ARC_getRatedProductsWithContributions.testPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>{
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Enhanced 6k',
                            'Price' => 200
                        }
                    }
                }
            }
        };

        ARC_getRatedProductsWithContributions.MemberInput memberInput = new ARC_getRatedProductsWithContributions.MemberInput();
        memberInput.Name = 'Jane Smith';
        memberInput.Age = 31;
        memberInput.PrimaryAge = 31;
        memberInput.IsPrimary = false;
        memberInput.PrimaryId = primaryMember.Id;
        memberInput.IsLegacy = false;

        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJson(
            new List<ARC_getRatedProductsWithContributions.MemberInput>{ memberInput }
        );
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Expected fallback PrimaryId result to be a JSON object keyed by product name, but got: ' + resultJson
        );

        Map<String, Object> resultByName = (Map<String, Object>) deserializedResult;
        System.assertEquals(1, resultByName.size(), 'Fallback PrimaryId path should return one priced product');

        Map<String, Object> enhancedResult = (Map<String, Object>) resultByName.get('WeShare Group Enhanced 6k');
        System.assertNotEquals(null, enhancedResult, 'Enhanced product should be present when fallback PrimaryId is used');

        System.assertEquals(
            200,
            Decimal.valueOf(String.valueOf(enhancedResult.get('basePrice'))),
            'Enhanced base price should come from the mocked IP response when fallback PrimaryId is used'
        );

        System.assertEquals(
            150,
            Decimal.valueOf(String.valueOf(enhancedResult.get('priceWithContributions'))),
            'Enhanced price should still apply the flat amount contribution when fallback PrimaryId is used'
        );
    }
    
    @IsTest
    static void getProductsWithContributionsJsonFromString_invalidJson_returnsErrorObject() {
        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString('not valid json');
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Invalid JSON input should return a JSON object, but got: ' + resultJson
        );

        Map<String, Object> resultMap = (Map<String, Object>) deserializedResult;
        System.assert(
            resultMap.size() > 0,
            'Invalid JSON input should return a non-empty error object, but got: ' + resultJson
        );
    }
    
    @IsTest
    static void getProductsWithContributionsJsonFromString_multipleLegacyMembers_duplicatesSeniorProduct() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        Product2 seniorProduct = new Product2(
            Name = 'WeShare Group Senior',
            ProductCode = 'PROG_UHSM_WeShareGroupSenior',
            IsActive = true
        );
        insert seniorProduct;

        ARC_getRatedProductsWithContributions.testPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>()
                }
            }
        };

        ARC_getRatedProductsWithContributions.testLegacyPricingIpResponse = new Map<String, Object>{
            'tierFactorValue' => 1,
            'products' => new List<Object>{
                new Map<String, Object>{
                    'groupName' => 'Medical',
                    'products' => new List<Object>{
                        new Map<String, Object>{
                            'Name' => 'WeShare Group Senior',
                            'Price' => 300
                        }
                    }
                }
            }
        };

        String memberDataJson = JSON.serialize(new List<Object>{
            new Map<String, Object>{
                'Name' => 'Legacy Primary',
                'Age' => 67,
                'PrimaryAge' => 67,
                'IsPrimary' => true,
                'PrimaryId' => primaryMember.Id,
                'IsLegacy' => true
            },
            new Map<String, Object>{
                'Name' => 'Legacy Spouse',
                'Age' => 66,
                'PrimaryAge' => 67,
                'IsPrimary' => false,
                'PrimaryId' => primaryMember.Id,
                'IsLegacy' => true
            },
            new Map<String, Object>{
                'Name' => 'Legacy Dependent',
                'Age' => 65,
                'PrimaryAge' => 67,
                'IsPrimary' => false,
                'PrimaryId' => primaryMember.Id,
                'IsLegacy' => true
            }
        });

        Test.startTest();
        String resultJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJsonFromString(memberDataJson);
        Test.stopTest();

        Object deserializedResult = JSON.deserializeUntyped(resultJson);
        System.assert(
            deserializedResult instanceof Map<String, Object>,
            'Expected multiple legacy result to be a JSON object keyed by product name, but got: ' + resultJson
        );

        Map<String, Object> resultByName = (Map<String, Object>) deserializedResult;

        System.assert(
            resultByName.containsKey('WeShare Group Senior'),
            'Base Senior product should be present for the first legacy member'
        );
        System.assert(
            resultByName.containsKey('WeShare Group Senior (2)'),
            'Second Senior product duplicate should be present for the second legacy member'
        );
        System.assert(
            resultByName.containsKey('WeShare Group Senior (3)'),
            'Third Senior product duplicate should be present for the third legacy member'
        );

        Map<String, Object> seniorResult = (Map<String, Object>) resultByName.get('WeShare Group Senior');
        Map<String, Object> seniorDuplicateTwo = (Map<String, Object>) resultByName.get('WeShare Group Senior (2)');
        Map<String, Object> seniorDuplicateThree = (Map<String, Object>) resultByName.get('WeShare Group Senior (3)');

        System.assertEquals(
            Decimal.valueOf(String.valueOf(seniorResult.get('priceWithContributions'))),
            Decimal.valueOf(String.valueOf(seniorDuplicateTwo.get('priceWithContributions'))),
            'Senior duplicate two should copy the original Senior product node pricing'
        );

        System.assertEquals(
            Decimal.valueOf(String.valueOf(seniorResult.get('priceWithContributions'))),
            Decimal.valueOf(String.valueOf(seniorDuplicateThree.get('priceWithContributions'))),
            'Senior duplicate three should copy the original Senior product node pricing'
        );
    }

    @IsTest
    static void calculateMemberContribution_percentLowestByCategory_handlesNullLegacySeniorAndUnknownProducts() {
        vlocity_ins__GroupCensusMember__c primaryMember = [
            SELECT Id
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];

        vlocity_ins__GroupClass__c groupClass = [
            SELECT Id, ARC_ContributionMethod__c
            FROM vlocity_ins__GroupClass__c
            LIMIT 1
        ];
        groupClass.ARC_ContributionMethod__c = 'Percent_Of_Lowest_By_Category';
        update groupClass;

        vlocity_ins__GroupClassContribution__c contribution = [
            SELECT Id,
                vlocity_ins__ContributionAmount__c,
                vlocity_ins__ContributionPercent__c,
                vlocity_ins__ContributionType__c,
                vlocity_ins__ProductCategory__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__c = :groupClass.Id
            LIMIT 1
        ];
        contribution.vlocity_ins__ContributionAmount__c = null;
        contribution.vlocity_ins__ContributionPercent__c = 50;
        contribution.vlocity_ins__ContributionType__c = 'Percent';
        contribution.vlocity_ins__ProductCategory__c = 'Medical';
        update contribution;

        Map<String, Decimal> pricedProducts = new Map<String, Decimal>{
            'WeShare Group Enhanced' => 200,
            'WeShare Group Essential' => null,
            'WeShare Group Legacy' => 300,
            'WeShare Group Senior' => 250,
            'Random Product' => 180
        };

        Test.startTest();
        Map<String, Decimal> result =
            ARC_getRatedProductsWithContributions.calculateMemberContribution(
                primaryMember.Id,
                pricedProducts
            );
        Test.stopTest();

        System.assertEquals(
            null,
            result.get('WeShare Group Essential'),
            'Null price should remain null'
        );

        System.assertEquals(
            300,
            result.get('WeShare Group Legacy'),
            'Legacy product should keep original price'
        );

        System.assertEquals(
            125,
            result.get('WeShare Group Senior'),
            'Senior should be categorized and receive category-based contribution'
        );

        System.assertEquals(
            180,
            result.get('Random Product'),
            'Unknown product category should keep original price'
        );
    }
}