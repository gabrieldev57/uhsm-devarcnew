@isTest
public class ARC_DeleteCensusMembersGuestUserTest {
    @isTest public static void testInvokeMethod(){        
        try{
            ARC_DeleteCensusMembersGuestUser a = new ARC_DeleteCensusMembersGuestUser();
        	boolean result = a.invokeMethod('deleteCensusMembers',null,null,null);
        }catch(Exception e){
             System.assertEquals(e.getMessage(),'Attempt to de-reference a null object');
        }
    }
    
    @isTest public static void deleteCensusMembersTest(){
        Account acc = new Account(Name='AccountTest1');
        insert acc;
        acc = [SELECT Id FROM Account WHERE Name = 'AccountTest1'];
        
        vlocity_ins__GroupCensus__c cen = new vlocity_ins__GroupCensus__c(Name = 'CensusTest1',vlocity_ins__GroupId__c = acc.Id);
        insert cen;
        cen = [SELECT Id FROM vlocity_ins__GroupCensus__c WHERE Name = 'CensusTest1'];
        
		vlocity_ins__GroupCensusMember__c censusMember = new vlocity_ins__GroupCensusMember__c(Name = 'a3q3C000000fvCLQAY', vlocity_ins__CensusId__c = cen.Id);
        insert censusMember;
        censusMember = [SELECT Id, Name FROM vlocity_ins__GroupCensusMember__c];
        
        Map<String, Object> inputMap1 = new Map<String, Object>();
    	List<Map<String,Object>> listMaps = new List<Map<String,Object>>();
		Map<String,String> tempMap = new Map<String,String>();
        String enc = vlocity_ins.UserSecurity.encrypt(String.valueOf(censusMember.Id));
        tempMap.put('Id', enc);
        listMaps.add(tempMap);
        inputMap1.put('Members', listMaps);
        ARC_DeleteCensusMembersGuestUser dcmgu = New ARC_DeleteCensusMembersGuestUser();
        dcmgu.invokeMethod('deleteCensusMembers', inputMap1, new Map<String,Object>(), new Map<String,Object>());
        List<vlocity_ins__GroupCensusMember__c> membersList = [SELECT Id FROM vlocity_ins__GroupCensusMember__c];
        System.assertEquals(membersList.size(), 0);
        
        //System.assertEquals(censusMember.Name, 'ElGaboTester2');
        //System.assertEquals(censusMember.Id, 'a3q3C000000fvCL');
        //String a = vlocity_ins.UserSecurity.encrypt(censusMember.Name);
        //String b = vlocity_ins.UserSecurity.decrypt(a);        
        //System.assertEquals(b, censusMember.Name);
    }
    
  
}