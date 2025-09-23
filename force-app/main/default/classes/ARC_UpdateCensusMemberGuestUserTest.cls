@isTest
public with sharing class ARC_UpdateCensusMemberGuestUserTest {
/* @isTest
    public static void ARC_UpdateCensusMemberGuestUserTest() {
        String methodName = 'updateCensusMembers';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> members = new List<Object>();
        Map<String, Object> record1 = new Map<String, Object>();
        Map<String, Object> record2 = new Map<String, Object>();
        Map<String, Object> record3 = new Map<String, Object>();
        Account account = new Account(Name='Test');
        insert account;
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='Test - Census',vlocity_ins__GroupId__c=account.id);
        insert census;
        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__CensusId__c=census.Id,
            vlocity_ins__IsPrimaryMember__c =true,
            vlocity_ins__LastName__c= 'test',
            vlocity_ins__Gender__c= 'Male',     
            vlocity_ins__FirstName__c= 'test',
            vlocity_ins__Email__c= 'test@test.com',
            vlocity_ins__Birthdate__c= Date.valueOf('2022-02-09'),
            ARC_Weight__c = 1.0,
            ARC_HeightFeet__c= 1.0,
            ARC_HeightInches__c= 1.0,
            ARC_Smoker__c= false,
            vlocity_ins__SocialSecurityNumber__c='123456789'
        );
        insert censusMember;
        vlocity_ins__GroupCensusMember__c censusMemberChild = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__CensusId__c=census.Id,
            vlocity_ins__LastName__c= 'test',
            vlocity_ins__Gender__c= 'Female',     
            vlocity_ins__FirstName__c= 'test',
            vlocity_ins__Email__c= 'test@test.com',
            vlocity_ins__Birthdate__c= Date.valueOf('2022-02-09'),
            ARC_Weight__c = 1.0,
            ARC_HeightFeet__c= 1.0,
            ARC_HeightInches__c= 1.0,
            ARC_Smoker__c= false,
            vlocity_ins__SocialSecurityNumber__c='123456789'
        );
        insert censusMemberChild;
        record1.put('Id', vlocity_ins.UserSecurity.encryptForUser(censusMember.Id, '0055e000006VXDWAA4'));
        record1.put('ARC_VisionProduct__c', null);
        record1.put('ARC_UseParentAddress__c', false);
        record1.put('ARC_IgnoreMailing__c', false);
        record1.put('ARC_PhysicalAddressZipCode__c', 'test');
        record1.put('ARC_PhysicalAddressState__c', 'test');
        record1.put('ARC_PhysicalAddressStreet__c', 'test');
        record1.put('ARC_PhysicalAddressCity__c', 'test');
        record1.put('ARC_DependentRelationship__c', null);
        record1.put('vlocity_ins__RelatedCensusMemberId__c', null);
        record1.put('vlocity_ins__PrimaryMemberIdentifier__c', null);
        record1.put('vlocity_ins__LastName__c', 'test');
        record1.put('vlocity_ins__IsSpouse__c', false);
        record1.put('vlocity_ins__IsPrimaryMember__c', true);
        record1.put('vlocity_ins__Gender__c', 'Male');
        record1.put('vlocity_ins__FirstName__c', 'test');
        record1.put('vlocity_ins__Email__c', 'test@gmail.com');
        record1.put('vlocity_ins__Birthdate__c', Date.valueOf('2022-02-09'));
        record1.put('vlocity_ins__MemberIdentifier__c', '2022-02-17T15:30:33.573Z');
        record1.put('ARC_HeightInches__c', 1.0);
        record1.put('ARC_HeightFeet__c', 1.0);
        record1.put('ARC_Weight__c', 1.0);
        record1.put('ARC_Smoker__c', false);
        record1.put('vlocity_ins__SocialSecurityNumber__c', '123121234');


        members.add(record1);

        record2.put('ARC_VisionProduct__c', null);
        record2.put('ARC_UseParentAddress__c', false);
        record2.put('ARC_IgnoreMailing__c', false);
        record2.put('ARC_PhysicalAddressZipCode__c', 'test');
        record2.put('ARC_PhysicalAddressState__c', 'test');
        record2.put('ARC_PhysicalAddressStreet__c', 'test');
        record2.put('ARC_PhysicalAddressCity__c', 'test');
        record2.put('ARC_DependentRelationship__c', null);
        record2.put('vlocity_ins__RelatedCensusMemberId__c', null);
        record2.put('vlocity_ins__LastName__c', 'test');
        record2.put('vlocity_ins__IsSpouse__c', false);
        record2.put('vlocity_ins__IsPrimaryMember__c', false);
        record2.put('vlocity_ins__Gender__c', 'Male');
        record2.put('vlocity_ins__FirstName__c', 'test');
        record2.put('vlocity_ins__Email__c', 'test@gmail.com');
        record2.put('vlocity_ins__Birthdate__c', Date.valueOf('2022-02-09'));
        record2.put('vlocity_ins__PrimaryMemberIdentifier__c', '2022-02-17T15:30:33.573Z');
        record2.put('vlocity_ins__MemberIdentifier__c', '1645111875204-0.8487017874936982');
        record2.put('ARC_HeightInches__c', 1.0);
        record2.put('ARC_HeightFeet__c', 1.0);
        record2.put('ARC_Weight__c', 1.0);
        record2.put('ARC_Smoker__c', true);
        record2.put('vlocity_ins__SocialSecurityNumber__c', '123121234');
        
        members.add(record2);

        record3.put('Id', vlocity_ins.UserSecurity.encryptForUser(String.valueOf(censusMemberChild.Id), '0055e000006VXDWAA4'));
        record3.put('ARC_VisionProduct__c', null);
        record3.put('ARC_UseParentAddress__c', true);
        record3.put('ARC_IgnoreMailing__c', false);
        record3.put('ARC_PhysicalAddressZipCode__c', 'test');
        record3.put('ARC_PhysicalAddressState__c', 'test');
        record3.put('ARC_PhysicalAddressStreet__c', 'test');
        record3.put('ARC_PhysicalAddressCity__c', 'test');
        record3.put('ARC_DependentRelationship__c', 'Child');
        record3.put('vlocity_ins__RelatedCensusMemberId__c', censusMember.Id);
        record3.put('vlocity_ins__LastName__c', 'test');
        record3.put('vlocity_ins__IsSpouse__c', false);
        record3.put('vlocity_ins__IsPrimaryMember__c', false);
        record3.put('vlocity_ins__Gender__c', 'Male');
        record3.put('vlocity_ins__FirstName__c', 'test');
        record3.put('vlocity_ins__Email__c', 'test@gmail.com');
        record3.put('vlocity_ins__Birthdate__c', Date.valueOf('2022-02-09'));
        record3.put('vlocity_ins__PrimaryMemberIdentifier__c', '2022-02-17T15:30:33.573Z');
        record3.put('vlocity_ins__MemberIdentifier__c', '1645116400703-0.3397643669835855');
        record3.put('ARC_HeightInches__c', 1.0);
        record3.put('ARC_HeightFeet__c', 1.0);
        record3.put('ARC_Weight__c', 1.0);
        record3.put('ARC_Smoker__c', true);
        record3.put('vlocity_ins__SocialSecurityNumber__c', '123121234');
        
        members.add(record3);
        inputMap.put('censusId', vlocity_ins.UserSecurity.encryptForUser(String.valueOf(census.Id), '0055e000006VXDWAA4'));
        inputMap.put('Members', members);
        ARC_UpdateCensusMembersGuestUser updateCensusMembersGuestUser = new ARC_UpdateCensusMembersGuestUser();
        updateCensusMembersGuestUser.invokeMethod(methodName, inputMap, outputMap, options); 
    }*/
    @isTest
    public static void ARC_UpdateCensusMemberGuestUserTestDmlExeption() {
        
        String methodName = 'updateCensusMembers';
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        List<Object> members = new List<Object>();
        Map<String, Object> record1 = new Map<String, Object>();
        Map<String, Object> record2 = new Map<String, Object>();
        Map<String, Object> record3 = new Map<String, Object>();
        Account account = new Account(Name='Test');
        insert account;
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c(Name='Test - Census',vlocity_ins__GroupId__c=account.id);
        insert census;
        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__CensusId__c=census.Id,
            vlocity_ins__IsPrimaryMember__c =true,
            vlocity_ins__LastName__c= 'test',
            vlocity_ins__Gender__c= 'Male',     
            vlocity_ins__FirstName__c= 'test',
            vlocity_ins__Email__c= 'test@test.com',
            vlocity_ins__Birthdate__c= Date.valueOf('2022-02-09'),
            ARC_Weight__c = '1',
            ARC_HeightFeet__c= '1',
            ARC_HeightInches__c= '1',
            ARC_Smoker__c= false,
            vlocity_ins__SocialSecurityNumber__c='123456789'
        );
        insert censusMember;
        vlocity_ins__GroupCensusMember__c censusMemberChild = new vlocity_ins__GroupCensusMember__c(
            vlocity_ins__CensusId__c=census.Id,
            vlocity_ins__LastName__c= 'test',
            vlocity_ins__Gender__c= 'Female',     
            vlocity_ins__FirstName__c= 'test',
            vlocity_ins__Email__c= 'test@test.com',
            vlocity_ins__Birthdate__c= Date.valueOf('2022-02-09'),
            ARC_Weight__c = '1',
            ARC_HeightFeet__c= '1',
            ARC_HeightInches__c= '1',
            ARC_Smoker__c= false,
            vlocity_ins__SocialSecurityNumber__c='123456789'
        );
        insert censusMemberChild;
        record1.put('Id', vlocity_ins.UserSecurity.encryptForUser(censusMember.Id, '0055e000006VXDWAA4'));
        record1.put('ARC_VisionProduct__c', null);
        record1.put('ARC_UseParentAddress__c', false);
        record1.put('ARC_IgnoreMailing__c', false);
        record1.put('ARC_PhysicalAddressZipCode__c', 'test');
        record1.put('ARC_PhysicalAddressState__c', 'test');
        record1.put('ARC_PhysicalAddressStreet__c', 'test');
        record1.put('ARC_PhysicalAddressCity__c', 'test');
        record1.put('ARC_DependentRelationship__c', null);
        record1.put('vlocity_ins__RelatedCensusMemberId__c', null);
        record1.put('vlocity_ins__PrimaryMemberIdentifier__c', null);
        record1.put('vlocity_ins__LastName__c', 'test');
        record1.put('vlocity_ins__IsSpouse__c', false);
        record1.put('vlocity_ins__IsPrimaryMember__c', true);
        record1.put('vlocity_ins__Gender__c', 'Male');
        record1.put('vlocity_ins__FirstName__c', 'test');
        record1.put('vlocity_ins__Email__c', 'test@gmail.com');
        record1.put('vlocity_ins__Birthdate__c', Date.valueOf('2022-02-09'));
        record1.put('ARC_HeightInches__c', '1');
        record1.put('ARC_HeightFeet__c', '1');
        record1.put('ARC_Weight__c', '1');
        record1.put('ARC_Smoker__c', false);
        record1.put('vlocity_ins__SocialSecurityNumber__c', '123121234');


        members.add(record1);

        record2.put('ARC_VisionProduct__c', null);
        record2.put('ARC_UseParentAddress__c', false);
        record2.put('ARC_IgnoreMailing__c', false);
        record2.put('ARC_PhysicalAddressZipCode__c', '===================================================================================================Some string which is longer than 255 characters==================================================================================================================================================');
        record2.put('ARC_PhysicalAddressState__c', 'test');
        record2.put('ARC_PhysicalAddressStreet__c', 'test');
        record2.put('ARC_PhysicalAddressCity__c', 'test');
        record2.put('ARC_DependentRelationship__c', null);
        record2.put('vlocity_ins__RelatedCensusMemberId__c', null);
        record2.put('vlocity_ins__LastName__c', 'test');
        record2.put('vlocity_ins__IsSpouse__c', false);
        record2.put('vlocity_ins__IsPrimaryMember__c', false);
        record2.put('vlocity_ins__Gender__c', 'Male');
        record2.put('vlocity_ins__FirstName__c', 'test');
        record2.put('vlocity_ins__Email__c', 'test@gmail.com');
        record2.put('vlocity_ins__Birthdate__c', Date.valueOf('2022-02-09'));
        record2.put('vlocity_ins__PrimaryMemberIdentifier__c', censusMember.vlocity_ins__MemberIdentifier__c);
        record2.put('vlocity_ins__MemberIdentifier__c', '1645111875204-0.8487017874936982');
        record2.put('ARC_HeightInches__c', 1.0);
        record2.put('ARC_HeightFeet__c', '1');
        record2.put('ARC_Weight__c', '1');
        record2.put('ARC_Smoker__c', true);
        record2.put('vlocity_ins__SocialSecurityNumber__c', '123121234');
        
        members.add(record2);

        record3.put('Id', vlocity_ins.UserSecurity.encryptForUser(String.valueOf(censusMemberChild.Id), '0055e000006VXDWAA4'));
        record3.put('ARC_VisionProduct__c', null);
        record3.put('ARC_UseParentAddress__c', true);
        record3.put('ARC_IgnoreMailing__c', false);
        record3.put('ARC_PhysicalAddressZipCode__c', 'test');
        record3.put('ARC_PhysicalAddressState__c', 'test');
        record3.put('ARC_PhysicalAddressStreet__c', 'test');
        record3.put('ARC_PhysicalAddressCity__c', 'test');
        record3.put('ARC_DependentRelationship__c', 'Child');
        record3.put('vlocity_ins__RelatedCensusMemberId__c', censusMember.Id);
        record3.put('vlocity_ins__LastName__c', 'test');
        record3.put('vlocity_ins__IsSpouse__c', false);
        record3.put('vlocity_ins__IsPrimaryMember__c', false);
        record3.put('vlocity_ins__Gender__c', 'Male');
        record3.put('vlocity_ins__FirstName__c', 'test');
        record3.put('vlocity_ins__Email__c', 'test@gmail.com');
        record3.put('vlocity_ins__Birthdate__c', Date.valueOf('2022-02-09'));
        record3.put('vlocity_ins__PrimaryMemberIdentifier__c', censusMember.vlocity_ins__MemberIdentifier__c);
        record3.put('vlocity_ins__MemberIdentifier__c', '1645116400703-0.3397643669835855');
        record3.put('ARC_HeightInches__c', 1.0);
        record3.put('ARC_HeightFeet__c', '1');
        record3.put('ARC_Weight__c', '1');
        record3.put('ARC_Smoker__c', true);
        record3.put('vlocity_ins__SocialSecurityNumber__c', '123121234');
        
        members.add(record3);
        inputMap.put('censusId', vlocity_ins.UserSecurity.encryptForUser(String.valueOf(census.Id), '0055e000006VXDWAA4'));
        inputMap.put('Members', members);
        ARC_UpdateCensusMembersGuestUser updateCensusMembersGuestUser = new ARC_UpdateCensusMembersGuestUser();
        updateCensusMembersGuestUser.invokeMethod(methodName, inputMap, outputMap, options); 
    }
}