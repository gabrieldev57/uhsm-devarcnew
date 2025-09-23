@isTest
public with sharing class ARC_PolicyCreationTest {
    public static final ARC_PolicyCreation classTest = new ARC_PolicyCreation();

    @testSetup
    public static void createData() {
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(2);
        List<Contact> contacts = ARC_TestUtility.createTestContact(2, 'Contact');
        List<vlocity_ins__ContractLineItem__c> cLineItems = ARC_TestUtility.createTestContractLineItem(4);
        List<vlocity_ins__GroupCensusMemberPlan__c> gcMemberPlans = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        List<Product2> prods = ARC_TestUtility.createTestProducts(2);
        Id rtProduct = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Integer i = 0;

        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test1', vlocity_ins__ContractLineId__c=cLineItems[0].Id, vlocity_ins__GroupCensusMemberId__c=members[0].Id));
        gcMemberPlans.add(new vlocity_ins__GroupCensusMemberPlan__c(Name='Test2', vlocity_ins__ContractLineId__c=cLineItems[1].Id, vlocity_ins__GroupCensusMemberId__c=members[1].Id));
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
        update prods;

        cLineItems[0].vlocity_ins__Product2Id__c = prods[0].Id;
        update cLineItems;
    }

    @IsTest
    static void testPolicyCreation() {
        Contract cnt = [SELECT Id FROM Contract LIMIT 1];

        Test.startTest();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        input.put('contractId', cnt.Id);

        classTest.invokeMethod('createAllPolicyRecords', input, output, options);
        Test.stopTest();

        Assert.areEqual(1, [SELECT COUNT() FROM InsurancePolicy]);
    }
}