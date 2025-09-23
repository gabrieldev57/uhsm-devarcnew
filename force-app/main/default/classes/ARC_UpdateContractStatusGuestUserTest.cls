@isTest
public with sharing class ARC_UpdateContractStatusGuestUserTest {
    @isTest
    public static void ARC_UpdateContractStatusGuestUserTest() {
        List<Contract> listContract = ARC_TestUtility.createContracts(1);
        Contract con = listContract[0];
        insert con;
        Map<String, Object> inputMap = new Map<String, Object>();
        String contractId = con.Id;
        inputMap.put('ContractId', contractId);
        ARC_UpdateContractStatusGuestUser updateContract = new ARC_UpdateContractStatusGuestUser();        
        
        Test.startTest();
        	updateContract.invokeMethod('UpdateContractStatus', inputMap, new Map<String,Object>(), new Map<String,Object>());
        Test.stopTest();

        Contract conQuery = [SELECT Id, Status FROM Contract WHERE Id = :contractId];
        System.assertEquals('Awaiting Approval', conQuery.Status);
    }
    
    @isTest
    public static void ARC_UpdateContractStatusGuestUserTestTwo() {
        List<Contract> listContract = ARC_TestUtility.createContracts(1);
        Contract con = listContract[0];
        insert con;
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        String contractId = con.Id;
        inputMap.put('ContractId', '123131235');
        ARC_UpdateContractStatusGuestUser updateContract = new ARC_UpdateContractStatusGuestUser();        
        Test.startTest();
            try{
                updateContract.invokeMethod('UpdateContractStatus', inputMap, outMap, new Map<String,Object>());
            }catch(Exception e){
            }
        Test.stopTest();

        System.assertEquals(false, outMap.get('success'));
    }
}