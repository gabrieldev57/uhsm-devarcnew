@isTest
public class ARC_groupCensusMembersPlansPATest {

    @isTest
    static void ARC_groupCensusMembersPlansPATest() {
        
        
        Account pacc = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount')[0];
        List<ChargentOrders__ChargentOrder__c> cos = ARC_TestUtility.createChargentOrders(1);
        insert cos;
        vlocity_ins__ContractLineItem__c cli = ARC_TestUtility.createTestContractLineItem(1)[0];
        Contract c = [SELECT Id FROM Contract LIMIT 1];
        ChargentOrders__ChargentOrder__c co = [SELECT Id FROM ChargentOrders__ChargentOrder__c LIMIT 1];
        vlocity_ins__GroupCensusMember__c gcm =ARC_TestUtility.createTestCensusMember(1)[0];
        gcm.vlocity_ins__ContactId__c = [SELECT Id, PersonContactId FROM Account WHERE Id = :pacc.Id LIMIT 1 ].PersonContactId;
        update gcm;
        
        c.ARC_RecurringMonthlyOrder__c = co.Id;
        c.Status = 'Activated';
        update c;
        vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
        gcmp.Name = 'Test';
        gcmp.vlocity_ins__ContractLineId__c = cli.Id;
        gcmp.vlocity_ins__GroupCensusMemberId__c = gcm.Id;
        insert gcmp;

        Test.startTest();
        ARC_groupCensusMembersPlansPA.getCensusMemberPlan(pacc.Id);
        Test.stopTest();
    }
}