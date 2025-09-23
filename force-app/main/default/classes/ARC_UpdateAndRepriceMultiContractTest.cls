@isTest
public with sharing class ARC_UpdateAndRepriceMultiContractTest{
    @isTest
    public static void ARC_UpdateAndRepriceMultiContractTest(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Date oggi = Date.today();
        Date effDate = Date.newInstance(2022, 08, 15);

        Account acc = new Account(Name = 'Test');
        insert acc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;

        vlocity_ins__GroupCensusMember__c censusMem1 = new vlocity_ins__GroupCensusMember__c();
        censusMem1.Name = 'Test Census Member';
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        censusMem1.vlocity_ins__IsPrimaryMember__c = true;
        censusMem1.vlocity_ins__Email__c = 'soyunMail@cc.com'; 
        censusMem1.vlocity_ins__SocialSecurityNumber__c = '654654654';
        censusMem1.ARC_Weight__c = '120';
        censusMem1.vlocity_ins__FirstName__c = 'Member';
        censusMem1.vlocity_ins__LastName__c = 'Test Census';
        censusMem1.vlocity_ins__Birthdate__c = oggi;
        censusMem1.ARC_ActiveMember__c = true;
        // censusMem1.isNew = true;
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        insert censusMem1;
        censusMem1.vlocity_ins__MemberIdentifier__c = censusMem1.Id;
        update censusMem1;
        
        vlocity_ins__GroupCensusMember__c censusMem2 = new vlocity_ins__GroupCensusMember__c(Name = 'Test2',vlocity_ins__Birthdate__c=oggi, vlocity_ins__CensusId__c=census.Id,vlocity_ins__IsPrimaryMember__c=true);
        insert censusMem2;
        censusMem2.vlocity_ins__MemberIdentifier__c = censusMem2.Id;
        update censusMem2;
        
        
       System.debug('Member Name' + [SELECT Id,Name, ARC_ActiveMember__c,vlocity_ins__MemberIdentifier__c,vlocity_ins__IsPrimaryMember__c,ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c]);



        List<Contract> lCon = ARC_TestUtility.createContractsAA(2);
        Contract con = lCon[0];
        con.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con.Status = 'Draft';
        con.AccountId = acc.Id;
        con.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con;
        con.Status = 'Awaiting Activation';
        update con;

        Contract con1 = lCon[1];
        con1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con1.Status = 'Draft';
        con1.AccountId = acc.Id;
        con1.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con1;
        con1.Status = 'Awaiting Activation';
        update con1;

        con.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con.Status = 'Activated';
        update con;
        
        con1.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con1.Status = 'Activated';
        update con1;
        
        String Ancillary = 'Ancillary';
		
		String inputMapString = '{"EffDate":"11-01-2022","productList":[{"selectedProduct":{"Type__c":"Medical","SubType__c":"HMO","Id":"01t3C000005v69jQAA","productId":"01t3C000005u7aaQAA","Price":505.61,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"UHSM Fundamental $10K","displaySequence":-1,"PricingFormula__c":"Price","MarketSegment__c":"Individual","ProductCode":"PROG_UHSMFundamental","RecordTypeName__c":"Product"}},{"displaySequence":-1,"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97}],"EffDate":"2022-11-01","auxSavedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'", "DOB":"'+censusMem1.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}],"RemovedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'","CHK_Delete":'+true+', "vlocity_ins__MemberIdentifier__c":"'+censusMem1.Id+'"}], "primaryId":"'+censusMem1.Id+'", "primaryEmail":"'+censusMem1.vlocity_ins__Email__c+'", "EffectiveDate":"2022-08-15", "CensusId": "'+census.Id+'","changesForContracts":[{"SingleReason": "Program Downgrade","Reason": "Program Downgrade; Add Ancillary; Add Member","ProductsToUpdate":[{"displaySequence":-1,"Id":"01t3C000005u7aaQAA","Name":"UHSM Vital $10K","ProductCode":"PROG_UHSMVital","MarketSegment__c":"Individual","Type__c":"Medical","SubType__c":"HMO","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"PricingFormula__c":"Price","productId":"01t3C000005u7aaQAA","currencyCode":"USD","currencySymbol":"$","Price":614.61},{"displaySequence":-1,"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97}],"Reason": "Program Downgrade; Add Ancillary; Add Member","EffDate":"2022-11-01","selectedProducts":[{"Type__c":"Medical","SubType__c":"HMO","Id":"01t3C000005u7aQQAQ","productId":"01t3C000005u7aQQAQ","Price":505.61,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"UHSM Fundamental $10K","displaySequence":-1,"PricingFormula__c":"Price","Id":"01t3C000005u7aQQAQ","MarketSegment__c":"Individual","ProductCode":"PROG_UHSMFundamental","RecordTypeName__c":"Product"},{"Type__c":"Ancillary","SubType__c":"SMART","productId":"01t3C000005v69jQAA","Price":111.97,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"SMART Share 35000","displaySequence":-1,"Id":"01t3C000005v69jQAA","MarketSegment__c":"Individual","ProductCode":"PROG_SMART_35000","RecordTypeName__c":"Product"}],"ProductsToUpdate":[{"displaySequence":-1,"Id":"01t3C000005u7aaQAA","Name":"UHSM Vital $10K","ProductCode":"PROG_UHSMVital","MarketSegment__c":"Individual","Type__c":"Medical","SubType__c":"HMO","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"PricingFormula__c":"Price","productId":"01t3C000005u7aaQAA","currencyCode":"USD","currencySymbol":"$","Price":614.61},{"displaySequence":-1,"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97}],"Reason": "Program Downgrade; Add Ancillary; Add Member","EffDate":"2022-11-01","auxSavedMembers":[{"isNew":true,"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem2.Id+'", "DOB":"'+censusMem2.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem2.Id+'"}],"RemovedMembers":[{"CHK_isPrimary":true,"CHK_Delete":'+true+',"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}]}],"chooseProductsAddMemberOutput":[{"selectedProduct":{"displaySequence":-1,"Id":"01t3C000005u7aaQAA","Name":"UHSM Vital $10K","ProductCode":"PROG_UHSMVital","MarketSegment__c":"Individual","Type__c":"Medical","SubType__c":"HMO","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"PricingFormula__c":"Price","productId":"01t3C000005u7aaQAA","currencyCode":"USD","currencySymbol":"$","Price":614.61},"userInputs":[{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","sortNode":1},{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Jill Valentine","CensusMemberRelationship":"Spouse","RF_Census.CM_IsSpouse":true,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FhQAK","isPrimary":false,"isSpouse":true,"isDependent":false,"memberIdSMART":"a3q3C000001I6FhQAKSMART","memberIdAIDD":"a3q3C000001I6FhQAKAIDD","sortNode":2}]},{"selectedProduct":{"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97},"userInputs":[{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","sortNode":1},{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Jill Valentine","CensusMemberRelationship":"Spouse","RF_Census.CM_IsSpouse":true,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FhQAK","isPrimary":false,"isSpouse":true,"isDependent":false,"memberIdSMART":"a3q3C000001I6FhQAKSMART","memberIdAIDD":"a3q3C000001I6FhQAKAIDD","sortNode":2},{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Claire Redfield","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FmQAK","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6FmQAKSMART","memberIdAIDD":"a3q3C000001I6FmQAKAIDD","sortNode":3},{"CensusMemberName":"aaaa aaaa","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6sZQAS","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6sZQASSMART","memberIdAIDD":"a3q3C000001I6sZQASAIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"sortNode":3}]}],"chooseProductsAncillaryOutput":[{"selectedProduct":{"Type__c":"Medical","SubType__c":"HMO","productId":"01t3C000005u7aaQAA","Price":614.61,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"UHSM Vital $10K","displaySequence":-1,"PricingFormula__c":"Price","Id":"01t3C000005u7aaQAA","MarketSegment__c":"Individual","ProductCode":"PROG_UHSMVital","RecordTypeName__c":"Product"},"userInputs":[{"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":1},{"CensusMemberName":"Jill Valentine","CensusMemberRelationship":"Spouse","RF_Census.CM_IsSpouse":true,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FhQAK","isPrimary":false,"isSpouse":true,"isDependent":false,"memberIdSMART":"a3q3C000001I6FhQAKSMART","memberIdAIDD":"a3q3C000001I6FhQAKAIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":2},{"CensusMemberName":"Claire Redfield","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FmQAK","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6FmQAKSMART","memberIdAIDD":"a3q3C000001I6FmQAKAIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":3},{"CensusMemberName":"aaaa aaaa","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6sZQAS","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6sZQASSMART","memberIdAIDD":"a3q3C000001I6sZQASAIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":3}]},{"selectedProduct":{"Type__c":"Ancillary","SubType__c":"SMART","productId":"01t3C000005v69jQAA","Price":111.97,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"SMART Share 35000","displaySequence":-1,"Id":"01t3C000005v69jQAA","MarketSegment__c":"Individual","ProductCode":"PROG_SMART_35000","RecordTypeName__c":"Product"},"userInputs":[{"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":1},{"CensusMemberName":"Jill Valentine","CensusMemberRelationship":"Spouse","RF_Census.CM_IsSpouse":true,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FhQAK","isPrimary":false,"isSpouse":true,"isDependent":false,"memberIdSMART":"a3q3C000001I6FhQAKSMART","memberIdAIDD":"a3q3C000001I6FhQAKAIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":2},{"CensusMemberName":"Claire Redfield","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FmQAK","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6FmQAKSMART","memberIdAIDD":"a3q3C000001I6FmQAKAIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":3},{"CensusMemberName":"aaaa aaaa","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6sZQAS","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6sZQASSMART","memberIdAIDD":"a3q3C000001I6sZQASAIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":3}]}],"dependants":[],"ProductsToUpdate":[],"selectedProducts":[]}';
              
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);

        ARC_UpdateAndRepriceMultiContract testClass = new ARC_UpdateAndRepriceMultiContract();
        testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
        testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);

    }
    
    @isTest
   	 public static void ARC_UpdateAndRepriceMultiContractTestTwo(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Date oggi = Date.today();
        Date effDate = Date.newInstance(2022, 08, 15);

        Account acc = new Account(Name = 'Test');
        insert acc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;

        vlocity_ins__GroupCensusMember__c censusMem1 = new vlocity_ins__GroupCensusMember__c();
        censusMem1.Name = 'Test Census Member';
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        censusMem1.vlocity_ins__IsPrimaryMember__c = true;
        censusMem1.vlocity_ins__Email__c = 'soyunMail@cc.com'; 
        censusMem1.vlocity_ins__SocialSecurityNumber__c = '654654654';
        censusMem1.ARC_Weight__c = '120';
        censusMem1.vlocity_ins__FirstName__c = 'Member';
        censusMem1.vlocity_ins__LastName__c = 'Test Census';
        censusMem1.vlocity_ins__Birthdate__c = oggi;
        censusMem1.ARC_ActiveMember__c = true;
        // censusMem1.isNew = true;
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        insert censusMem1;
        censusMem1.vlocity_ins__MemberIdentifier__c = censusMem1.Id;
        update censusMem1;
        
        
       System.debug('Member Name' + [SELECT Id,Name, ARC_ActiveMember__c,vlocity_ins__MemberIdentifier__c,vlocity_ins__IsPrimaryMember__c,ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c]);



        List<Contract> lCon = ARC_TestUtility.createContractsAA(2);
        Contract con = lCon[0];
        con.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con.Status = 'Draft';
        con.AccountId = acc.Id;
        upsert con;

        Contract con1 = lCon[1];
        con1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con1.Status = 'Draft';
        con1.AccountId = acc.Id;
        upsert con1;

        con1.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con1;
        con1.Status = 'Awaiting Activation';
        update con1;

        con.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con;
        con.Status = 'Awaiting Activation';
        update con;

        con.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con.Status = 'Activated';
        update con;
        
        con1.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con1.Status = 'Activated';
        update con1;
        
        String Ancillary = 'Ancillary';
		
		String inputMapString = '{"EffDate":"11-01-2022","auxSavedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'", "DOB":"'+censusMem1.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}],"RemovedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'","CHK_Delete":'+true+', "vlocity_ins__MemberIdentifier__c":"'+censusMem1.Id+'"}], "primaryId":"'+censusMem1.Id+'", "primaryEmail":"'+censusMem1.vlocity_ins__Email__c+'", "EffectiveDate":"2022-08-15", "CensusId": "'+census.Id+'","changesForContracts":[{"EffDate":"2022-11-01","auxSavedMembers":[{"isNew":true,"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'", "DOB":"'+censusMem1.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}],"RemovedMembers":[{"CHK_isPrimary":true,"CHK_Delete":'+true+',"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}]}]}';
              
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        ARC_UpdateAndRepriceMultiContract testClass = new ARC_UpdateAndRepriceMultiContract();
        testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
        testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);
    }



    @isTest
    public static void ARC_PCAncillaryUserInputsTest(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Date oggi = Date.today();
        Date effDate = Date.newInstance(2022, 08, 15);

        Account acc = new Account(Name = 'Test');
        insert acc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;

        vlocity_ins__GroupCensusMember__c censusMem1 = new vlocity_ins__GroupCensusMember__c();
        censusMem1.Name = 'Test Census Member';
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        censusMem1.vlocity_ins__IsPrimaryMember__c = true;
        censusMem1.vlocity_ins__Email__c = 'soyunMail@cc.com'; 
        censusMem1.vlocity_ins__SocialSecurityNumber__c = '654654654';
        censusMem1.ARC_Weight__c = '120';
        censusMem1.vlocity_ins__FirstName__c = 'Member';
        censusMem1.vlocity_ins__LastName__c = 'Test Census';
        censusMem1.vlocity_ins__Birthdate__c = oggi;
        censusMem1.ARC_ActiveMember__c = true;
        // censusMem1.isNew = true;
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        insert censusMem1;
        censusMem1.vlocity_ins__MemberIdentifier__c = censusMem1.Id;
        update censusMem1;
        
        vlocity_ins__GroupCensusMember__c censusMem2 = new vlocity_ins__GroupCensusMember__c(Name = 'Test2',vlocity_ins__Birthdate__c=oggi, vlocity_ins__CensusId__c=census.Id,vlocity_ins__IsPrimaryMember__c=true);
        insert censusMem2;
        censusMem2.vlocity_ins__MemberIdentifier__c = censusMem2.Id;
        update censusMem2;
        
        
       System.debug('Member Name' + [SELECT Id,Name, ARC_ActiveMember__c,vlocity_ins__MemberIdentifier__c,vlocity_ins__IsPrimaryMember__c,ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c]);



        List<Contract> lCon = ARC_TestUtility.createContractsAA(2);
        Contract con = lCon[0];
        con.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con.Status = 'Draft';
        con.AccountId = acc.Id;
        upsert con;

        Contract con1 = lCon[1];
        con1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con1.Status = 'Draft';
        con1.AccountId = acc.Id;
        upsert con1;

        con1.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con1;
        con1.Status = 'Awaiting Activation';
        update con1;

        con.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con;
        con.Status = 'Awaiting Activation';
        update con;

        con.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con.Status = 'Activated';
        update con;
        
        con1.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con1.Status = 'Activated';
        update con1;
        
        String Ancillary = 'Ancillary';
		
				String inputMapString ='{"memberIds":["'+censusMem1.Id+'"],"EffDate":"11-01-2022","productList":[{"selectedProduct":{"Type__c":"Medical","SubType__c":"HMO","productId":"01t3C000005u7aQQAQ","Price":614.61,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"UHSM Vital $10K","displaySequence":-1,"PricingFormula__c":"Price","Id":"01t3C000005u7aQQAQ","MarketSegment__c":"Individual","ProductCode":"PROG_UHSMVital","RecordTypeName__c":"Product"}},{"userInputs":[{"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","productIds":["01t3C000005u7aQQAQ","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":1}]}],"auxSavedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'", "DOB":"'+censusMem1.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}],"RemovedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'","CHK_Delete":'+true+', "vlocity_ins__MemberIdentifier__c":"'+censusMem1.Id+'"}], "primaryId":"'+censusMem1.Id+'", "primaryEmail":"'+censusMem1.vlocity_ins__Email__c+'", "EffectiveDate":"2022-08-15", "CensusId": "'+census.Id+'","changesForContracts":[{"selectedProducts":[{"Type__c":"Medical","SubType__c":"HMO","productId":"01t3C000005u7aQQAQ","Price":505.61,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"UHSM Fundamental $10K","displaySequence":-1,"PricingFormula__c":"Price","Id":"01t3C000005u7aQQAQ","MarketSegment__c":"Individual","ProductCode":"PROG_UHSMFundamental","RecordTypeName__c":"Product"},{"Type__c":"Ancillary","SubType__c":"SMART","productId":"01t3C000005v69jQAA","Price":111.97,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"SMART Share 35000","displaySequence":-1,"Id":"01t3C000005v69jQAA","MarketSegment__c":"Individual","ProductCode":"PROG_SMART_35000","RecordTypeName__c":"Product"}],"ProductsToUpdate":[{"displaySequence":-1,"Id":"01t3C000005u7aaQAA","Name":"UHSM Vital $10K","ProductCode":"PROG_UHSMVital","MarketSegment__c":"Individual","Type__c":"Medical","SubType__c":"HMO","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"PricingFormula__c":"Price","productId":"01t3C000005u7aaQAA","currencyCode":"USD","currencySymbol":"$","Price":614.61},{"displaySequence":-1,"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97}],"SingleReason": "Program Downgrade; Add Ancillary; Add ","Reason": "Program Downgrade; Add Ancillary; Add Member","EffDate":"2022-11-01","auxSavedMembers":[{"isNew":true,"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem2.Id+'", "DOB":"'+censusMem2.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem2.Id+'"}],"RemovedMembers":[{"CHK_isPrimary":true,"CHK_Delete":'+true+',"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}]}],"chooseProductsAddMemberOutput":[{"selectedProduct":{"displaySequence":-1,"Id":"01t3C000005u7aaQAA","Name":"UHSM Vital $10K","ProductCode":"PROG_UHSMVital","MarketSegment__c":"Individual","Type__c":"Medical","SubType__c":"HMO","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"PricingFormula__c":"Price","productId":"01t3C000005u7aaQAA","currencyCode":"USD","currencySymbol":"$","Price":614.61},"userInputs":[{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","sortNode":1},{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Jill Valentine","CensusMemberRelationship":"Spouse","RF_Census.CM_IsSpouse":true,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FhQAK","isPrimary":false,"isSpouse":true,"isDependent":false,"memberIdSMART":"a3q3C000001I6FhQAKSMART","memberIdAIDD":"a3q3C000001I6FhQAKAIDD","sortNode":2}]},{"selectedProduct":{"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97},"userInputs":[{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","sortNode":1},{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Jill Valentine","CensusMemberRelationship":"Spouse","RF_Census.CM_IsSpouse":true,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FhQAK","isPrimary":false,"isSpouse":true,"isDependent":false,"memberIdSMART":"a3q3C000001I6FhQAKSMART","memberIdAIDD":"a3q3C000001I6FhQAKAIDD","sortNode":2},{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Claire Redfield","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FmQAK","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6FmQAKSMART","memberIdAIDD":"a3q3C000001I6FmQAKAIDD","sortNode":3},{"CensusMemberName":"aaaa aaaa","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6sZQAS","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6sZQASSMART","memberIdAIDD":"a3q3C000001I6sZQASAIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"sortNode":3}]}],"chooseProductsAncillaryOutput": [ { "userInputs": [{"CensusMemberId": "'+censusMem1.Id+'","CensusMemberName": "Test FinalSpouse",          "RF_Census.CRF_PrimaryMemberAge": 0,"RF_Census.CM_IsPrimary": true,          "RF_Census.CRF_Coverage": "Primary","RF_Census.CRF_CoverageAIDD": "Primary" }],  "selectedProduct": {"Type__c": "Ancillary","SubType__c": "SMART","productId": "01t3C000005v6fGQAQ","Price": 71.82,        "IsRecommended__c": false, "IsConfigurable__c": false,"Name": "SMART Share 45000","displaySequence": -1,"Id": "01t3C000005v6fGQAQ","MarketSegment__c": "Individual","ProductCode": "PROG_SMART_45000","RecordTypeName__c": "Product" }} ],"dependants":[]}';

              
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);

        ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
        testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
        testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);
        testClass.invokeMethod('updateAndRepriceMultiContractsCase', inputMap, outputMap, options);


    }
     @isTest
    public static void ARC_PCAncillaryUserInputsTestTres(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Date oggi = Date.today();
        Date effDate = Date.newInstance(2022, 08, 15);

        Account acc = new Account(Name = 'Test');
        insert acc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;

        vlocity_ins__GroupCensusMember__c censusMem1 = new vlocity_ins__GroupCensusMember__c();
        censusMem1.Name = 'Test Census Member';
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        censusMem1.vlocity_ins__IsPrimaryMember__c = true;
        censusMem1.vlocity_ins__Email__c = 'soyunMail@cc.com'; 
        censusMem1.vlocity_ins__SocialSecurityNumber__c = '654654654';
        censusMem1.ARC_Weight__c = '120';
        censusMem1.vlocity_ins__FirstName__c = 'Member';
        censusMem1.vlocity_ins__LastName__c = 'Test Census';
        censusMem1.vlocity_ins__Birthdate__c = oggi;
        censusMem1.ARC_ActiveMember__c = true;
        // censusMem1.isNew = true;
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        insert censusMem1;
        censusMem1.vlocity_ins__MemberIdentifier__c = censusMem1.Id;
        update censusMem1;
        
        vlocity_ins__GroupCensusMember__c censusMem2 = new vlocity_ins__GroupCensusMember__c(Name = 'Test2',vlocity_ins__Birthdate__c=oggi, vlocity_ins__CensusId__c=census.Id,vlocity_ins__IsPrimaryMember__c=true);
        insert censusMem2;
        censusMem2.vlocity_ins__MemberIdentifier__c = censusMem2.Id;
        update censusMem2;
        
        
       System.debug('Member Name' + [SELECT Id,Name, ARC_ActiveMember__c,vlocity_ins__MemberIdentifier__c,vlocity_ins__IsPrimaryMember__c,ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c]);



        List<Contract> lCon = ARC_TestUtility.createContractsAA(2);
        Contract con = lCon[0];
        con.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con.Status = 'Draft';
        con.AccountId = acc.Id;
        upsert con;

        Contract con1 = lCon[1];
        con1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con1.Status = 'Draft';
        con1.AccountId = acc.Id;
        upsert con1;

        con1.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con1;
        con1.Status = 'Awaiting Activation';
        update con1;

        con.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con;
        con.Status = 'Awaiting Activation';
        update con;

        con.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con.Status = 'Activated';
        update con;
        
        con1.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con1.Status = 'Activated';
        update con1;
        
        String Ancillary = 'Ancillary';
		
		String inputMapString ='{"EffDate":"11-01-2022","productList":[{"selectedProduct":{"Type__c":"Medical","SubType__c":"HMO","productId":"01t3C000005u7aQQAQ","Price":614.61,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"UHSM Vital $10K","displaySequence":-1,"PricingFormula__c":"Price","Id":"01t3C000005u7aQQAQ","MarketSegment__c":"Individual","ProductCode":"PROG_UHSMVital","RecordTypeName__c":"Product"}},{"userInputs":[{"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","productIds":["01t3C000005u7aQQAQ","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":1}]}],"auxSavedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'", "DOB":"'+censusMem1.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}],"RemovedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'","CHK_Delete":'+true+', "vlocity_ins__MemberIdentifier__c":"'+censusMem1.Id+'"}], "primaryId":"'+censusMem1.Id+'", "primaryEmail":"'+censusMem1.vlocity_ins__Email__c+'", "EffectiveDate":"2022-08-15", "CensusId": "'+census.Id+'","changesForContracts":[{"selectedProducts":[{"Type__c":"Medical","SubType__c":"HMO","productId":"01t3C000005u7aQQAQ","Price":505.61,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"UHSM Fundamental $10K","displaySequence":-1,"PricingFormula__c":"Price","Id":"01t3C000005u7aQQAQ","MarketSegment__c":"Individual","ProductCode":"PROG_UHSMFundamental","RecordTypeName__c":"Product"},{"Type__c":"Ancillary","SubType__c":"SMART","productId":"01t3C000005v69jQAA","Price":111.97,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"SMART Share 35000","displaySequence":-1,"Id":"01t3C000005v69jQAA","MarketSegment__c":"Individual","ProductCode":"PROG_SMART_35000","RecordTypeName__c":"Product"}],"ProductsToUpdate":[{"displaySequence":-1,"Id":"01t3C000005u7aaQAA","Name":"UHSM Vital $10K","ProductCode":"PROG_UHSMVital","MarketSegment__c":"Individual","Type__c":"Medical","SubType__c":"HMO","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"PricingFormula__c":"Price","productId":"01t3C000005u7aaQAA","currencyCode":"USD","currencySymbol":"$","Price":614.61},{"displaySequence":-1,"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97}],"SingleReason": "Add Member ","Reason": "Add Member","EffDate":"2022-11-01","auxSavedMembers":[{"isNew":true,"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem2.Id+'", "DOB":"'+censusMem2.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem2.Id+'"}],"RemovedMembers":[{"CHK_isPrimary":true,"CHK_Delete":'+true+',"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}]}],"chooseProductsAddMemberOutput": [ { "userInputs": [{"CensusMemberId": "'+censusMem1.Id+'","CensusMemberName": "Test FinalSpouse",          "RF_Census.CRF_PrimaryMemberAge": 0,"RF_Census.CM_IsPrimary": true,          "RF_Census.CRF_Coverage": "Primary","RF_Census.CRF_CoverageAIDD": "Primary" }],  "selectedProduct": {"Type__c": "Ancillary","SubType__c": "SMART","productId": "01t3C000005v6fGQAQ","Price": 71.82,        "IsRecommended__c": false, "IsConfigurable__c": false,"Name": "SMART Share 45000","displaySequence": -1,"Id": "01t3C000005v6fGQAQ","MarketSegment__c": "Individual","ProductCode": "PROG_SMART_45000","RecordTypeName__c": "Product" }} ],"chooseProductsAncillaryOutput": [ { "userInputs": [{"CensusMemberId": "'+censusMem1.Id+'","CensusMemberName": "Test FinalSpouse",          "RF_Census.CRF_PrimaryMemberAge": 0,"RF_Census.CM_IsPrimary": true,          "RF_Census.CRF_Coverage": "Primary","RF_Census.CRF_CoverageAIDD": "Primary" }],  "selectedProduct": {"Type__c": "Ancillary","SubType__c": "SMART","productId": "01t3C000005v6fGQAQ","Price": 71.82,        "IsRecommended__c": false, "IsConfigurable__c": false,"Name": "SMART Share 45000","displaySequence": -1,"Id": "01t3C000005v6fGQAQ","MarketSegment__c": "Individual","ProductCode": "PROG_SMART_45000","RecordTypeName__c": "Product" }} ],"dependants":[]}';

              
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);

        ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
        testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
        testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);

    }
     @isTest
    public static void ARC_PCAncillaryUserInputsTestTwo(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Date oggi = Date.today();
        Date effDate = Date.newInstance(2022, 08, 15);

        Account acc = new Account(Name = 'Test');
        insert acc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;

        vlocity_ins__GroupCensusMember__c censusMem1 = new vlocity_ins__GroupCensusMember__c();
        censusMem1.Name = 'Test Census Member';
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        censusMem1.vlocity_ins__IsPrimaryMember__c = true;
        censusMem1.vlocity_ins__Email__c = 'soyunMail@cc.com'; 
        censusMem1.vlocity_ins__SocialSecurityNumber__c = '654654654';
        censusMem1.ARC_Weight__c = '120';
        censusMem1.vlocity_ins__FirstName__c = 'Member';
        censusMem1.vlocity_ins__LastName__c = 'Test Census';
        censusMem1.vlocity_ins__Birthdate__c = oggi;
        censusMem1.ARC_ActiveMember__c = true;
        // censusMem1.isNew = true;
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        insert censusMem1;
        censusMem1.vlocity_ins__MemberIdentifier__c = censusMem1.Id;
        update censusMem1;
        
        vlocity_ins__GroupCensusMember__c censusMem2 = new vlocity_ins__GroupCensusMember__c(Name = 'Test2',vlocity_ins__Birthdate__c=oggi, vlocity_ins__CensusId__c=census.Id,vlocity_ins__IsPrimaryMember__c=true);
        insert censusMem2;
        censusMem2.vlocity_ins__MemberIdentifier__c = censusMem2.Id;
        update censusMem2;
        
        
       System.debug('Member Name' + [SELECT Id,Name, ARC_ActiveMember__c,vlocity_ins__MemberIdentifier__c,vlocity_ins__IsPrimaryMember__c,ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c]);



        List<Contract> lCon = ARC_TestUtility.createContractsAA(2);
        Contract con = lCon[0];
        con.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con.Status = 'Draft';
        con.AccountId = acc.Id;
        upsert con;

        Contract con1 = lCon[1];
        con1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con1.Status = 'Draft';
        con1.AccountId = acc.Id;
        upsert con1;

        con1.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con1;
        con1.Status = 'Awaiting Activation';
        update con1;

        con.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con;
        con.Status = 'Awaiting Activation';
        update con;

        con.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con.Status = 'Activated';
        update con;
        
        con1.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con1.Status = 'Activated';
        update con1;
        
        String Ancillary = 'Ancillary';
		
		String inputMapString ='{"EffDate":"11-01-2022","productList":[{"selectedProduct":{"Type__c":"Medical","SubType__c":"HMO","productId":"01t3C000005u7aQQAQ","Price":614.61,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"UHSM Vital $10K","displaySequence":-1,"PricingFormula__c":"Price","Id":"01t3C000005u7aQQAQ","MarketSegment__c":"Individual","ProductCode":"PROG_UHSMVital","RecordTypeName__c":"Product"}},{"userInputs":[{"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","productIds":["01t3C000005u7aQQAQ","01t3C000005v69jQAA","01t3C000005vHT3QAM"],"sortNode":1}]}],"auxSavedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'", "DOB":"'+censusMem1.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}],"RemovedMembers":[{"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'","CHK_Delete":'+true+', "vlocity_ins__MemberIdentifier__c":"'+censusMem1.Id+'"}], "primaryId":"'+censusMem1.Id+'", "primaryEmail":"'+censusMem1.vlocity_ins__Email__c+'", "EffectiveDate":"2022-08-15", "CensusId": "'+census.Id+'","changesForContracts":[{"selectedProducts":[{"Type__c":"Medical","SubType__c":"HMO","productId":"01t3C000005u7aQQAQ","Price":505.61,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"UHSM Fundamental $10K","displaySequence":-1,"PricingFormula__c":"Price","Id":"01t3C000005u7aQQAQ","MarketSegment__c":"Individual","ProductCode":"PROG_UHSMFundamental","RecordTypeName__c":"Product"},{"Type__c":"Ancillary","SubType__c":"SMART","productId":"01t3C000005v69jQAA","Price":111.97,"IsRecommended__c":false,"IsConfigurable__c":false,"Name":"SMART Share 35000","displaySequence":-1,"Id":"01t3C000005v69jQAA","MarketSegment__c":"Individual","ProductCode":"PROG_SMART_35000","RecordTypeName__c":"Product"}],"ProductsToUpdate":[{"displaySequence":-1,"Id":"01t3C000005u7aaQAA","Name":"UHSM Vital $10K","ProductCode":"PROG_UHSMVital","MarketSegment__c":"Individual","Type__c":"Medical","SubType__c":"HMO","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"PricingFormula__c":"Price","productId":"01t3C000005u7aaQAA","currencyCode":"USD","currencySymbol":"$","Price":614.61},{"displaySequence":-1,"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97}],"SingleReason": "Program Downgrade; Add Ancillary; Add ","Reason": "Program Downgrade; Add Ancillary; Add Member","EffDate":"2022-11-01","auxSavedMembers":[{"isNew":true,"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem2.Id+'", "DOB":"'+censusMem2.vlocity_ins__Birthdate__c+'", "FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem2.Id+'"}],"RemovedMembers":[{"CHK_isPrimary":true,"CHK_Delete":'+true+',"SocialSecurity":"'+censusMem1.vlocity_ins__SocialSecurityNumber__c+'","EffDate":"11-01-2022","Weight":"'+censusMem1.ARC_Weight__c+'","LastName":"'+censusMem1.vlocity_ins__LastName__c+'","Id":"'+censusMem1.Id+'","FirstName":"'+censusMem1.vlocity_ins__FirstName__c+'","Name":"'+censusMem1.Name+'", "vlocity_ins__MemberIdentifier__c": "'+censusMem1.Id+'"}]}],"chooseProductsAddMemberOutput":[{"selectedProduct":{"displaySequence":-1,"Id":"01t3C000005u7aaQAA","Name":"UHSM Vital $10K","ProductCode":"PROG_UHSMVital","MarketSegment__c":"Individual","Type__c":"Medical","SubType__c":"HMO","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"PricingFormula__c":"Price","productId":"01t3C000005u7aaQAA","currencyCode":"USD","currencySymbol":"$","Price":614.61},"userInputs":[{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","sortNode":1},{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Jill Valentine","CensusMemberRelationship":"Spouse","RF_Census.CM_IsSpouse":true,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FhQAK","isPrimary":false,"isSpouse":true,"isDependent":false,"memberIdSMART":"a3q3C000001I6FhQAKSMART","memberIdAIDD":"a3q3C000001I6FhQAKAIDD","sortNode":2}]},{"selectedProduct":{"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97},"userInputs":[{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Leon Kennedy","CensusMemberRelationship":"Primary","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":true,"CensusMemberId":"a3q3C000001I6FXQA0","isPrimary":true,"isSpouse":false,"isDependent":false,"memberIdSMART":"a3q3C000001I6FXQA0SMART","memberIdAIDD":"a3q3C000001I6FXQA0AIDD","sortNode":1},{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Jill Valentine","CensusMemberRelationship":"Spouse","RF_Census.CM_IsSpouse":true,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FhQAK","isPrimary":false,"isSpouse":true,"isDependent":false,"memberIdSMART":"a3q3C000001I6FhQAKSMART","memberIdAIDD":"a3q3C000001I6FhQAKAIDD","sortNode":2},{"productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"CensusMemberName":"Claire Redfield","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6FmQAK","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6FmQAKSMART","memberIdAIDD":"a3q3C000001I6FmQAKAIDD","sortNode":3},{"CensusMemberName":"aaaa aaaa","CensusMemberRelationship":"Child","RF_Census.CM_IsSpouse":false,"RF_Census.CM_IsPrimary":false,"CensusMemberId":"a3q3C000001I6sZQAS","isPrimary":false,"isSpouse":false,"isDependent":true,"memberIdSMART":"a3q3C000001I6sZQASSMART","memberIdAIDD":"a3q3C000001I6sZQASAIDD","productIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"sortNode":3}]}],"chooseProductsAncillaryOutput": [ { "userInputs": [{"CensusMemberId": "'+censusMem1.Id+'","CensusMemberName": "Test FinalSpouse",          "RF_Census.CRF_PrimaryMemberAge": 0,"RF_Census.CM_IsPrimary": true,          "RF_Census.CRF_Coverage": "Primary","RF_Census.CRF_CoverageAIDD": "Primary" }],  "selectedProduct": {"Type__c": "Ancillary","SubType__c": "SMART","productId": "01t3C000005v6fGQAQ","Price": 71.82,        "IsRecommended__c": false, "IsConfigurable__c": false,"Name": "SMART Share 45000","displaySequence": -1,"Id": "01t3C000005v6fGQAQ","MarketSegment__c": "Individual","ProductCode": "PROG_SMART_45000","RecordTypeName__c": "Product" }} ],"dependants":[]}';

              
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);

        ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
        testClass.invokeMethod('updateAndRepriceContracts', inputMap, outputMap, options);
        testClass.invokeMethod('updateAndRepriceMultiContracts', inputMap, outputMap, options);

    }
    
  

@isTest
    public static void GenerateInputChooseProducts(){
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Date oggi = Date.today();
        Date effDate = Date.newInstance(2022, 08, 15);

        Account acc = new Account(Name = 'Test');
        insert acc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;

        vlocity_ins__GroupCensusMember__c censusMem1 = new vlocity_ins__GroupCensusMember__c();
        censusMem1.Name = 'Test Census Member';
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        censusMem1.vlocity_ins__IsPrimaryMember__c = true;
        censusMem1.vlocity_ins__Email__c = 'soyunMail@cc.com'; 
        censusMem1.vlocity_ins__SocialSecurityNumber__c = '654654654';
        censusMem1.ARC_Weight__c = '120';
        censusMem1.vlocity_ins__FirstName__c = 'Member';
        censusMem1.vlocity_ins__LastName__c = 'Test Census';
        censusMem1.vlocity_ins__Birthdate__c = oggi;
        censusMem1.ARC_ActiveMember__c = true;
        // censusMem1.isNew = true;
        censusMem1.vlocity_ins__CensusId__c = census.Id;
        insert censusMem1;
        censusMem1.vlocity_ins__MemberIdentifier__c = censusMem1.Id;
        update censusMem1;
        
        
       System.debug('Member Name' + [SELECT Id,Name, ARC_ActiveMember__c,vlocity_ins__MemberIdentifier__c,vlocity_ins__IsPrimaryMember__c,ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c]);



        List<Contract> lCon = ARC_TestUtility.createContractsAA(2);
        Contract con = lCon[0];
        con.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con.Status = 'Draft';
        con.AccountId = acc.Id;
        upsert con;

        Contract con1 = lCon[1];
        con1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con1.Status = 'Draft';
        con1.AccountId = acc.Id;
        upsert con1;

        con1.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con1;
        con1.Status = 'Awaiting Activation';
        update con1;

        con.ARC_EffectiveDate__c = Date.today().addDays(2);
        upsert con;
        con.Status = 'Awaiting Activation';
        update con;

        con.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con.Status = 'Activated';
        update con;
        
        con1.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        con1.Status = 'Activated';
        update con1;
        
        String Ancillary = 'Ancillary';
		
		String inputMapString = '{"primaryEmail":"","primaryId":"","CensusId":"'+census.Id+'","dependants":[{"productsIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"Id":"a3q3C000001I6FXQA0","Age":36,"LastName":"Kennedy","FirstName":"Leon"},{"productsIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"Id":"a3q3C000001I6FhQAK","Age":28,"LastName":"Valentine","FirstName":"Jill"},{"productsIds":["01t3C000005u7aaQAA","01t3C000005v69jQAA","01t3C000005vHSyQAM"],"Id":"a3q3C000001I6FmQAK","Age":12,"LastName":"Redfield","FirstName":"Claire"}],"changesForContracts":[{"SingleReasonToDisplay":"Add Member","SingleReason":"Add Member","Reason":"Add Member","caseId":"5003C0000099NjQQAU","censusId":"'+census.Id+'","accountId":"0013C00000mKwDaQAK","ProductsToUpdate":[{"displaySequence":-1,"Id":"01t3C000005u7aaQAA","Name":"UHSM Vital $10K","ProductCode":"PROG_UHSMVital","MarketSegment__c":"Individual","Type__c":"Medical","SubType__c":"HMO","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"PricingFormula__c":"Price","productId":"01t3C000005u7aaQAA","currencyCode":"USD","currencySymbol":"$","Price":614.61},{"displaySequence":-1,"Id":"01t3C000005v69jQAA","Name":"SMART Share 35000","ProductCode":"PROG_SMART_35000","MarketSegment__c":"Individual","Type__c":"Ancillary","SubType__c":"SMART","IsRecommended__c":false,"PricingSource__c":"Price","RecordTypeName__c":"Product","IsConfigurable__c":false,"productId":"01t3C000005v69jQAA","currencyCode":"USD","currencySymbol":"$","Price":111.97}],"RemovedMembers":"","auxSavedMembers":[{"Id":"a3q3C000001I6FXQA0","ARC_isPregnant__c":false,"ARC_ActiveMember__c":true,"ARC_Phone__c":"+11234567890","ARC_HeightInches__c":"11","ARC_HeightFeet__c":"11","ARC_Weight__c":"11","ARC_Smoker__c":false,"ARC_MiddleInitial__c":null,"ARC_UseParentAddress__c":false,"ARC_PhysicalAddressZipCode__c":"12345","ARC_PhysicalAddressStreet__c":"1234 Zombie Road","ARC_PhysicalAddressState__c":"OH","ARC_PhysicalAddressCity__c":"Racoon City","ARC_DependentRelationship__c":null,"vlocity_ins__SocialSecurityNumber__c":"111111111","vlocity_ins__PrimaryMemberIdentifier__c":null,"vlocity_ins__MemberIdentifier__c":"2022-11-04T21:41:44.258Z","vlocity_ins__LastName__c":"Kennedy","vlocity_ins__IsSpouse__c":false,"vlocity_ins__IsPrimaryMember__c":true,"vlocity_ins__HasSpouse__c":true,"vlocity_ins__Gender__c":"Male","vlocity_ins__FirstName__c":"Leon","vlocity_ins__Email__c":"leon@stars.com","vlocity_ins__Birthdate__c":"1986-11-06","memberIndex":0,"index":0,"isSelected":true},{"ARC_ActiveMember__c":"","vlocity_ins__FirstName__c":"aasd","ARC_MiddleInitial__c":"","vlocity_ins__LastName__c":"aasd","vlocity_ins__Birthdate__c":"2018-11-09","vlocity_ins__Gender__c":"Female","ARC_DependentRelationship__c":"Child","vlocity_ins__HasSpouse__c":"","vlocity_ins__Email__c":"","ARC_Phone__c":"","vlocity_ins__SocialSecurityNumber__c":"543543543","ARC_HeightFeet__c":"3","ARC_HeightInches__c":"4","ARC_Weight__c":"5","ARC_isPregnant__c":"","ARC_Smoker__c":false,"ARC_PhysicalAddressCity__c":"Racoon City","ARC_PhysicalAddressState__c":"OH","ARC_PhysicalAddressStreet__c":"1234 Zombie Road","ARC_PhysicalAddressZipCode__c":"12345","ARC_IgnoreMailing__c":"","ARC_UseParentAddress__c":true,"isNew":true,"vlocity_ins__IsPrimaryMember__c":false,"vlocity_ins__PrimaryMemberIdentifier__c":"2022-11-04T21:41:44.258Z","vlocity_ins__MemberIdentifier__c":"1667862980196-0.4135297260914512","programChangeDependent":true,"Relationship":"","memberIndex":1,"edited":true,"addressModified":true,"vlocity_ins__IsSpouse__c":false,"ARC_EnrollmentCensusMember__c":true}],"selectedProducts":"","EffDate":"2022-12-15","Id":"8003C000000iPP6QAM"}]}';
              
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        ARC_PCAncillaryUserInputs testClass = new ARC_PCAncillaryUserInputs();
        testClass.invokeMethod('getInputForChooseProducts', inputMap, outputMap, options);
    }
    

}