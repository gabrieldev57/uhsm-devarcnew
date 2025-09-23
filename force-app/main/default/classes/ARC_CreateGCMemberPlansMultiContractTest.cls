@isTest
public class ARC_CreateGCMemberPlansMultiContractTest {
    
    
    @isTest
    public static void ARC_CreateGCMemberPlansMultiContractTest(){
        
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();

        Date oggi = Date.today();

        Account acc = new Account(Name = 'Test');
        insert acc;

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        census.ARC_PrimaryAccount__c = acc.Id;
        insert census;
        
        List<vlocity_ins__ContractLineItem__c> cli = ARC_TestUtility.createTestContractLineItem(1);
        
        Product2 prod = new Product2();
        prod.Name = 'UHSM Vital $10K';
        insert prod;

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


        List<Contract> lCon = ARC_TestUtility.createContractsAA(2);
        Contract con = lCon[0];
        con.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con.Status = 'Draft';
        con.AccountId = acc.Id;
        con.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        upsert con;

        Contract con1 = lCon[1];
        con1.vlocity_ins__EnrollmentCensusId__c = census.Id;
        con1.Status = 'Draft';
        con1.AccountId = acc.Id;
        con1.ARC_EffectiveDate__c = Date.newInstance(2022, 08, 15);
        upsert con1;

        con.Status = 'Activated';
        update con;

        con1.Status = 'Activated';
        update con1;
        
        String Ancillary = 'Ancillary';

		String inputMapString = '{"contractLineItems":[{"ContractId":"'+con.Id+'","ProductId":"'+prod.Id+'","Name":"'+prod.Name+'","ContractLineItemId":"'+cli[0].Id+'"}],"changesForContracts":[{"userInputs2":[{"CensusMemberId":"'+censusMem1.Id+'"}],"Id":"'+con.Id+'"}]}';
        Map<String,Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);

        ARC_CreateGCMemberPlansMultiContract testClass = new ARC_CreateGCMemberPlansMultiContract();

        testClass.invokeMethod('generateGroupCensusMemberPlansMultiContracts', inputMap, outputMap, options);

    }

}