@isTest
public class ARC_ExternalInsurerStepTest {

    @isTest 
    static void insertExternalInsuranceTest(){
        
        Map<String,Object> m = new Map<String, Object>();
        // Fields for Remove Member
        m.put('effectiveDate', '09/21/2023');
        m.put('expirationDate', '09/21/2024');
        m.put('sourceOfCoverage', 'Employer');
        m.put('insurerPhone', '123456789');
        m.put('insurer', 'SomeName');
        m.put('policyNumber', '123123123');
        m.put('id', '1');


        List<Object> polMembers = new List<Object>();
        Map<String, Object> oneMember = new Map<String, Object>();
        oneMember.put('id', 'memberId123');
        polMembers.add(oneMember);
        Map<String, Object> twoMember = new Map<String, Object>();
        twoMember.put('id', 'memberId456');
        polMembers.add(twoMember);
        m.put('policyMembers',polMembers );
        List<Object> externalInsurances = new List<Object>();
        externalInsurances.add(m);
        

        Map<String,Object> inputMap = new Map<String, Object>();
        Map<String,Object> options = new Map<String, Object>(); 
        Map<String,Object> outputMap = new Map<String, Object>();

        inputMap.put('externalInsurance', externalInsurances);
        Test.startTest();
        new ARC_ExternalInsurerStep().invokeMethod('insertExternalInsurance', inputMap, outputMap, options);
        Test.stopTest();

        List<ARC_ExternalInsurancePolicy__c> insertedPolicies = [SELECT Id FROM ARC_ExternalInsurancePolicy__c];
        Assert.areEqual(1, insertedPolicies.size(), 'Number of policies inserted does not match expectations');
    }

    @isTest 
    static void flagOpenSMBsForExtInsurance(){
        
        List<Account> acc = ARC_TestUtility.createTestAccount(1, 'ARC_IFPPersonAccount');
        List<Contact> c = [SELECT Id FROM Contact WHERE Id IN (SELECT PersonContactId FROM Account WHERE Id IN :acc)];

        List<Claim> claim = ARC_TestUtility.createTestClaims(1);
        claim[0].ARC_MemberContact__c = c[0].Id;
        claim[0].ARC_DOSFrom__c = Date.valueof('2024-06-01');
        update claim;



        ARC_ExternalInsurancePolicy__c externalInsurancePolicy = new ARC_ExternalInsurancePolicy__c();
        externalInsurancePolicy.ARC_EffectiveDate__c = Date.valueof('2023-11-01');
        externalInsurancePolicy.ARC_ExpirationDate__c = Date.valueof('2024-12-31');
        externalInsurancePolicy.ARC_InsurerName__c = 'ExtIns';
        insert externalInsurancePolicy;

        ARC_ExternalInsurancePolicyMember__c exInMember = new ARC_ExternalInsurancePolicyMember__c();
        exInMember.ARC_ExternalInsurancePolicy__c=externalInsurancePolicy.Id;
        exInMember.ARC_PersonAccount__c = acc[0].Id;
        insert exInMember;
        

        Map<String,Object> inputMap = new Map<String, Object>();
        Map<String,Object> options = new Map<String, Object>(); 
        Map<String,Object> outputMap = new Map<String, Object>();

        List<Object> exIn =new List<Object>(); 
        Map<String,Object> polMap = new Map<String,Object>{
            'ARC_EffectiveDate__c' => '2023-11-01',
            'ARC_ExpirationDate__c' => '2024-12-31',
            'Id' => externalInsurancePolicy.Id
        };
        exIn.add(polMap);
        List<Object> exInM =new List<Object>(); 
        Map<String,Object> membMap = new Map<String,Object>{
            'ARC_ExternalInsurancePolicy__c' => exInMember.ARC_ExternalInsurancePolicy__c,
            'ARC_PersonAccount__c' => exInMember.ARC_PersonAccount__c
        };
        exInM.add(membMap);

        inputMap.put('externalInsuranceMembers', exInM);
        inputMap.put('externalInsurance', exIn);

        Test.startTest();
            new ARC_ExternalInsurerStep().invokeMethod('flagOpenSMBsForExtInsurance', inputMap, outputMap, options);
        Test.stopTest();

        List<Claim> claims = [SELECT Id FROM Claim WHERE ARC_PrimaryInsurance__c = 'With Primary Insurance'];
        Assert.areEqual(1, claims.size(), 'Number of claims with primary insurance does not match expectations');
    }
}