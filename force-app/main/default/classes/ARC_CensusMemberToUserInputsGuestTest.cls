@isTest
public with sharing class ARC_CensusMemberToUserInputsGuestTest {

    private static vlocity_ins__GroupCensus__c census() {
        Account acc = new Account(Name = 'test');
        insert acc;
        Contract contr = new Contract(AccountId=acc.Id);
        insert contr;
        vlocity_ins__GroupCensus__c newCensus = new vlocity_ins__GroupCensus__c();
        newCensus.Name = 'test Census';
        newCensus.vlocity_ins__GroupId__c = acc.Id;
        newCensus.vlocity_ins__EffectiveStartDate__c = Date.today();
        newCensus.vlocity_ins__EffectiveEndDate__c = Date.today().addYears(1);
        newCensus.ARC_PrimaryAccount__c = acc.Id;       
        insert newCensus;
        return newCensus;
    }

    private static vlocity_ins__GroupCensusMember__c censusMembers(Id censusId, Integer numDep) {
        vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c();
        censusMember.Name = 'Robbie Williams';
        censusMember.vlocity_ins__censusid__c = censusId;
        censusMember.vlocity_ins__birthdate__c = Date.valueOf('1998-01-15');
        censusMember.vlocity_ins__IsPrimaryMember__c = true;
        censusMember.vlocity_ins__gender__c = 'Male';
        censusMember.vlocity_ins__isspouse__c = false;
        censusMember.vlocity_ins__lastname__c = 'Williams';
        censusMember.vlocity_ins__HasSpouse__c = false;
        censusMember.vlocity_ins__NumberOfDependents__c = numDep;
        insert censusMember;
        return censusMember;
    }

    private static void toUserInputs(Id censusId){
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('censusId', censusId);
        inputMap.put('effectiveDate', Date.valueOf('2022-01-15'));

        ARC_CensusMemberToUserInputsGuestUsers toUserInputs = new ARC_CensusMemberToUserInputsGuestUsers();
        toUserInputs.invokeMethod('ARC_CensusMemberToUserInputsGuestUsers', inputMap, new Map<String,Object>(), new Map<String,Object>());
    }

    private static void toTestingMethod(Id censusId){
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('censusId', censusId);
        inputMap.put('effectiveDate', Date.valueOf('2022-01-15'));
        ARC_CensusMemberToUserInputsGuestUsers toUserInputs = new ARC_CensusMemberToUserInputsGuestUsers();
        toUserInputs.invokeMethod('testing', inputMap, new Map<String,Object>(), new Map<String,Object>());
    }

    private static void toUserInputsWithCensusMembers(Id censusId, List<Object> listId){
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('censusId', censusId);
        inputMap.put('censusMemberIdForFilter', listId);
        inputMap.put('effectiveDate', Date.valueOf('2022-01-15'));

        ARC_CensusMemberToUserInputsGuestUsers toUserInputs = new ARC_CensusMemberToUserInputsGuestUsers();
        toUserInputs.invokeMethod('ARC_CensusMemberToUserInputsGuestUsers', inputMap, new Map<String,Object>(), new Map<String,Object>());
    }

    private static void fromUserInputsWithCensusMembers(List<Object> listId){
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('censusMemberIds', listId);
        inputMap.put('censusMemberIdForFilter', listId);
        inputMap.put('effectiveDate', Date.valueOf('2022-01-15'));

        ARC_CensusMemberToUserInputsGuestUsers toUserInputs = new ARC_CensusMemberToUserInputsGuestUsers();
        toUserInputs.invokeMethod('ARC_UserInputsFromCensusMembersGuestUsers', inputMap, new Map<String,Object>(), new Map<String,Object>());
    }

    private static void toUserInputsWithForAncillary(List<Object> listId){
        String inputMapString = '{"censusMemberDataList":[{"RF_Census.CRF_Dependants":4,"RF_Census.CRF_PrimaryMemberAge":32,"codeAIDD":"test","RF_Census.CRF_ExtraDependants":0,"RF_Census.CRF_Coverage":"Family","RF_Census.CRF_CoverageAIDD":"Family","CensusMemberId":"a3q3C000000fwsmQAA","RF_Census.CM_Age":32,"RF_Census.CM_IsPrimary":true,"RF_Census.CM_State":"KS","CensusMemberName":"AndresDeus","RF_Census.CM_Smoker":false,"RF_Census.CRF_State":"KS","SocialSecurity":"654646546","IsSpouse":false,"Email":"andres.deus@arcsona.com","Relationship":"Primary","AgeInSixMonths":32,"CensusMemberFirstName":"Andres","CensusMemberLastName":"Deus"},{"RF_Census.CRF_Dependants":4,"RF_Census.CRF_PrimaryMemberAge":32,"RF_Census.CRF_ExtraDependants":0,"RF_Census.CRF_Coverage":"Family","RF_Census.CRF_CoverageAIDD":"Family","CensusMemberId":"a3q3C000000fwsrQAA","RF_Census.CM_Age":29,"RF_Census.CM_IsPrimary":false,"RF_Census.CM_State":"KS","CensusMemberName":"PepitaLombarda","RF_Census.CM_Smoker":true,"RF_Census.CRF_State":"KS","SocialSecurity":"646546546","IsSpouse":false,"Relationship":"Spouse","AgeInSixMonths":29,"CensusMemberFirstName":"Pepita","CensusMemberLastName":"Lombarda"},{"RF_Census.CRF_Dependants":4,"RF_Census.CRF_PrimaryMemberAge":32,"RF_Census.CRF_ExtraDependants":0,"RF_Census.CRF_Coverage":"Family","RF_Census.CRF_CoverageAIDD":"Family","CensusMemberId":"a3q3C000000fwssQAA","RF_Census.CM_Age":26,"RF_Census.CM_IsPrimary":false,"RF_Census.CM_State":"KS","CensusMemberName":"PedroDeus","RF_Census.CM_Smoker":false,"RF_Census.CRF_State":"KS","SocialSecurity":"654654654","IsSpouse":false,"Relationship":"Child","AgeInSixMonths":26,"CensusMemberFirstName":"Pedro","CensusMemberLastName":"Deus"}],"primaryMemberEmail":"andres.deus@arcsona.com","shareAiddPrograms":true,"shareSmartPrograms":true}';
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        inputMap.put('effectiveDate', Date.valueOf('2022-01-15'));

        system.debug('el inputmap!: '+ inputMap);
        ARC_CensusMemberToUserInputsGuestUsers toUserInputs = new ARC_CensusMemberToUserInputsGuestUsers();
        toUserInputs.invokeMethod('ARC_UserInputsForAncillaryPrograms', inputMap, new Map<String,Object>(), new Map<String,Object>());
    }

    @isTest
    public static void CensusMemberToUserInputOneDep() {

        vlocity_ins__GroupCensus__c newCensus = census();
        
        vlocity_ins__GroupCensusMember__c oneDep = censusMembers(newCensus.Id, 1);

        vlocity_ins__GroupCensusMember__c childCensusMember = new vlocity_ins__GroupCensusMember__c();
        childCensusMember.Name = 'Hija Williams';
        childCensusMember.vlocity_ins__censusid__c = newCensus.Id;
        childCensusMember.vlocity_ins__birthdate__c = Date.valueOf('2003-02-15');
        childCensusMember.vlocity_ins__RelatedCensusMemberId__c = oneDep.Id;
        childCensusMember.vlocity_ins__isprimarymember__c = false;
        childCensusMember.vlocity_ins__gender__c = 'Female';
        childCensusMember.vlocity_ins__isspouse__c = false;
        childCensusMember.vlocity_ins__lastname__c = 'Williams';
        childCensusMember.ARC_DependentRelationship__c = 'Child';
        insert childCensusMember;
        toUserInputs(newCensus.Id);
    }

    @isTest
    public static void CensusMemberToUserInputTwoDep() {
        vlocity_ins__GroupCensus__c newCensus = census();
        vlocity_ins__GroupCensusMember__c oneDep = censusMembers(newCensus.Id, 2);
        toUserInputs(newCensus.Id);
    }

    @isTest
    public static void CensusMemberToUserInputNoDep() {
        vlocity_ins__GroupCensus__c newCensus = census();
        vlocity_ins__GroupCensusMember__c oneDep = censusMembers(newCensus.Id, 0);
        toUserInputs(newCensus.Id);
    }

    @isTest
    public static void CensusMemberToUserInputListIds() {
        List<Object> listId = new List<Object>();
        vlocity_ins__GroupCensus__c newCensus = census();
        vlocity_ins__GroupCensusMember__c oneDep = censusMembers(newCensus.Id, 0);
        listId.add(oneDep.Id);
        toUserInputsWithCensusMembers(newCensus.Id, listId);
    }

    @isTest
    public static void CensusMemberToTestingMethod() {
        vlocity_ins__GroupCensus__c newCensus = census();
        vlocity_ins__GroupCensusMember__c oneDep = censusMembers(newCensus.Id, 0);
        toTestingMethod(newCensus.Id);
    }

    @isTest
    public static void CensusMemberFromUserInputListIds() {
        List<Object> listId = new List<Object>();
        vlocity_ins__GroupCensus__c newCensus = census();
        vlocity_ins__GroupCensusMember__c oneDep = censusMembers(newCensus.Id, 0);
        listId.add(oneDep.Id);
        fromUserInputsWithCensusMembers(listId);
    }

    @isTest
    public static void CensusMemberToUserInputAncillary() {
        List<Object> listId = new List<Object>();
        vlocity_ins__GroupCensus__c newCensus = census();
        vlocity_ins__GroupCensusMember__c oneDep = censusMembers(newCensus.Id, 2);
        listId.add(oneDep);
        toUserInputsWithForAncillary(listId);
    }

    @isTest
    public static void getCoveragesTest() {
        String a =ARC_CensusMemberToUserInputsGuestUsers.getCoverageSmart(true, 5, 3);
        String b =ARC_CensusMemberToUserInputsGuestUsers.getCoverageAidd(true, 5, 3);
    }
}