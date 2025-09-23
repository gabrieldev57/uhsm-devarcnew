@isTest
public with sharing class ARC_GetUnderwritingCaseMemberTest {

    @isTest
    public static void getUnderwritingCase() {
        List<Case> casesList = ARC_TestUtility.createTestCase(1, 'Admission');
        List<vlocity_ins__GroupCensusMember__c> censusMemberList = ARC_TestUtility.createTestCensusMember(1);
        List<User> uList = ARC_TestUtility.createTestUsers(1, 'System Administrator');
        // List<ARC_UnderwritingCaseMember__c> uwcMemberList = ARC_TestUtility.create
        List<Contract> contractList = ARC_TestUtility.createContracts(1);
        Contract con = contractList[0];
        insert con;
        Case c = casesList[0];
        vlocity_ins__GroupCensusMember__c member = censusMemberList[0];
        User u = uList[0];
        insert u;
        con.ARC_Case__c = c.Id;
        update con;
        c.ARC_Contract__c = con.Id;
        update c;
        
        //Create group
        List <Group> groupList = new List<Group>();
        //Group queueGroup = new Group(Name ='Clinical Review Completed', Type = 'Queue');
        Group queueGroupTwo = new Group(Name ='Clinical Review', Type = 'Queue');
        //groupList.add(queueGroup);
        groupList.add(queueGroupTwo);
        insert groupList;
        
		String moveTo = 'Clinical Review Completed';
        String status = 'Closed Rejected';
        Test.startTest();
        //Retrieve undCases
		ARC_UnderwritingCaseMember__c undCase = new ARC_UnderwritingCaseMember__c(Name = 'Test', ARC_Member__c = member.Id, ARC_UnderwritingCase__c = c.Id, ARC_Contract__c = con.Id);
        insert undCase;
        ARC_GetUnderwritingCaseMember.getUnderwritingCaseMembers(c.Id);
		
        //Update undCases
        List<Map<String, Object>> casesIds = new List<Map<String, Object>>();
        Map<String, Object> caseId = new Map<String, Object>();
        caseId.put('Id', undCase.Id);
        caseId.put('ARC_Score__c', 100);
        caseId.put('ARC_Description__c', 'description Test');
        casesIds.add(caseId);
        ARC_GetUnderwritingCaseMember.saveUCMembers(casesIds, u.Id, casesList[0].Id );
        ARC_GetUnderwritingCaseMember.closeCase(status, c.Id, 'Other');
        Test.stopTest();
    }

}