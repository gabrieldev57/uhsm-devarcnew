@isTest
global with sharing class ARC_SortMembersForReEnrollmentTest {
	  @isTest
    static void sortMembers() {
    	List<vlocity_ins__GroupCensusMember__c> newMembers = ARC_TestUtility.createTestCensusMember(2);
        List<vlocity_ins__GroupCensusMember__c> allMembers = ARC_TestUtility.createTestCensusMember(3);
        
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
        String mapInfo = '{"newMembers":["'+newMembers[0].Id+'","'+newMembers[1].Id+'"],"allMembers":[{"RF_Census.CRF_Dependants":-1,"RF_Census.CRF_ExtraDependants":0,"CensusMemberId":"'+allMembers[0].Id+'","RF_Census.CM_Age":37,"RF_Census.CM_IsPrimary":true,"RF_Census.CM_State":"KS","CensusMemberName":"Simon Bolivar","RF_Census.CM_Smoker":false,"RF_Census.CRF_State":"KS","SocialSecurity":"123123123","IsSpouse":false,"Email":"gakapeh666@lidely.com","Relationship":"Primary","AgeInSixMonths":38,"CensusMemberFirstName":"Simon","CensusMemberLastName":"Bolivar"},{"RF_Census.CRF_Dependants":-1,"RF_Census.CRF_ExtraDependants":0,"CensusMemberId":"'+allMembers[1].Id+'","RF_Census.CM_Age":24,"RF_Census.CM_IsPrimary":false,"RF_Census.CM_State":"KS","CensusMemberName":"spo sdfsd","RF_Census.CM_Smoker":false,"RF_Census.CRF_State":"KS","SocialSecurity":"123212312","IsSpouse":true,"Email":"sfdfsd@sdfds.com","Relationship":"Spouse","AgeInSixMonths":25,"CensusMemberFirstName":"spo","CensusMemberLastName":"sdfsd"},{"RF_Census.CRF_Dependants":-1,"RF_Census.CRF_ExtraDependants":0,"CensusMemberId":"'+allMembers[2].Id+'","RF_Census.CM_Age":4,"RF_Census.CM_IsPrimary":false,"RF_Census.CM_State":"KS","CensusMemberName":"sdafsdfsa asdfasdf","RF_Census.CM_Smoker":false,"RF_Census.CRF_State":"KS","SocialSecurity":"111111111","IsSpouse":false,"Relationship":"Child","AgeInSixMonths":5,"CensusMemberFirstName":"sdafsdfsa","CensusMemberLastName":"asdfasdf"}]}';
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(mapInfo);

        
        Test.startTest();
        ARC_SortMembersForReEnrollment.SortMembers(inputMap,outputMap,options);
        Test.stopTest();
        
    
    }
}