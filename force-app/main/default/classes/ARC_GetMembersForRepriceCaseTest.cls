@isTest
public with sharing class ARC_GetMembersForRepriceCaseTest {

    @isTest
    public static void getApprovedMembersTest() {
        
        List<Object> userInputs = new List<Object>();
        
        List<vlocity_ins__GroupCensusMember__c> members = ARC_TestUtility.createTestCensusMember(4);
        members[0].vlocity_ins__isprimarymember__c = true;

        members[1].vlocity_ins__isspouse__c = true;
        members[1].arc_dependentrelationship__c = 'Spouse';
        members[1].vlocity_ins__RelatedCensusMemberId__c = members[0].Id;

        members[2].arc_dependentrelationship__c = 'Child';
        members[2].vlocity_ins__RelatedCensusMemberId__c = members[0].Id;

        update members;

        List<Object> rejectedMemberIds = new List<Object>();
        rejectedMemberIds.add(members[3].Id);

        for ( vlocity_ins__GroupCensusMember__c member : members ) {
            Map<String,Object> user = new Map<String,Object>();
            user.put('CensusMemberId', member.Id);
            user.put('RF_Census.CM_IsPrimary', member.vlocity_ins__isprimarymember__c);
            user.put('RF_Census.CM_IsSpouse', member.vlocity_ins__isspouse__c);
            userInputs.add(user);
        }
        
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        inputMap.put('RejectedMemberIds', rejectedMemberIds);
        inputMap.put('changeReason', 'Test');
        inputMap.put('DocuSignData', new Map<String, Object>());
        inputMap.put('userInputs', userInputs);

        new ARC_GetMembersForRepriceCase().invokeMethod('getApprovedMembers', inputMap, outputMap, options); 
    }
}