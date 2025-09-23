global without sharing class ARC_UpdateContractStatusGuestUser implements vlocity_ins.VlocityOpenInterface {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'UpdateContractStatus') {
            UpdateContractStatus(inputMap, outputMap, options);
        }
        return true;
    }

    public static void UpdateContractStatus(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {

        String contractId = String.valueOf(inputMap.get('ContractId'));
        
        if(!String.isBlank(contractId)){
            try{
        		Contract con = [SELECT Id, Name, Status FROM Contract WHERE Id = :contractId LIMIT 1];
                con.Status = 'Awaiting Approval';
            	update con;    
            }catch(Exception e){
          		System.debug('Error in ARC_UpdateContractStatusGuestUser.UpdateContractStatus() ' + e.getMessage());
                outputMap.put('success', false);
            }       	                 
        }
    }
}