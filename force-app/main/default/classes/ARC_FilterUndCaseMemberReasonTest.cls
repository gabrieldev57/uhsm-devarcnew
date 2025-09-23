@isTest
public with sharing class ARC_FilterUndCaseMemberReasonTest{
   

    
    @isTest
    public static void ARC_FilterUndCaseMemberReasonTest(){
        //#region inputMapString
        String inputMapString = '{"newMembers":[{"SocialSecurity":"654654654","Weight":234,"MI":"A","LastName":"Deus","Id":"a3q3C000000fwssQAA","isSmoker":false,"Height":"2' + '23","Gender":"Male","FirstName":"Pedro","Age":26,"DOB":"1996-03-14","Name":"PedroDeus"}],"oldMembers":[{"SocialSecurity":"321313213","Weight":234,"MI":"S","LastName":"Deus","Id":"a3q3C000000fwstQAA","isSmoker":false,"Height":"2' + '23","Gender":"Male","FirstName":"Lucas","Age":27,"DOB":"1995-03-15","Name":"LucasDeus"}],"allMembers":[{"SocialSecurity":"654654654","Weight":234,"MI":"A","LastName":"Deus","Id":"a3q3C000000fwssQAA","isSmoker":false,"Height":"2' + '23","Gender":"Male","FirstName":"Pedro","Age":26,"DOB":"1996-03-14","Name":"PedroDeus"},{"SocialSecurity":"321313213","Weight":234,"MI":"S","LastName":"Deus","Id":"a3q3C000000fwstQAA","isSmoker":false,"Height":"2' + '23","Gender":"Male","FirstName":"Lucas","Age":27,"DOB":"1995-03-15","Name":"LucasDeus"},{"SocialSecurity":"313213213","Weight":234,"MI":"A","LastName":"Deus","Id":"a3q3C000000fwsuQAA","isSmoker":false,"Height":"2' + '23","Gender":"Female","FirstName":"Pequeña","Age":2,"DOB":"2020-03-12","Name":"PequeñaDeus"},{"SocialSecurity":"231321321","Weight":234,"LastName":"Deus","Id":"a3q3C000000fwsvQAA","isSmoker":false,"Height":"2' + '65","Gender":"Female","FirstName":"OtraPequeña","Age":0,"DOB":"2022-03-08","Name":"OtraPequeñaDeus"}]}';
        //#endregion

        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_FilterUndCaseMemberReason testClass = new ARC_FilterUndCaseMemberReason();
        Boolean ret = testClass.invokeMethod('filterUCM', inputMap, outMap, options);

        System.assertEquals(true, ret);
    }
}