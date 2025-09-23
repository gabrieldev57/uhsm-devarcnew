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
}