@isTest

public class ARC_FamilyMemberPriceBreakupTest {

   @isTest
   public static void FamilyMemberPriceBreakupTest(){
    
    Map<String, Object> inputMap = new Map<String, Object>();
    Map<String, Object> outMap = new Map<String, Object>();
    Map<String, Object> options = new Map<String, Object>();
    String methodName = 'FamilyMemberPriceBreakup';
    List<Object> families = new List<Object>();


    for (Integer i = 0; i < 5; i++) {
         
        Map<String,Object> familyMembers = new Map<String,Object>();

        for (Integer x = 0; x < 5; x++) {
            Map<String,Object> Member = new Map<String,Object>();
            Member.put('Id', '1');
            Member.put('Price', 10);
            Member.put('Relationship', 'Test');
            Member.put('Birthdate', 01/01/2000);
            Member.put('Name', 'Test');
            familyMembers.put('PrimaryMembersList', Member);
        }
       
        families.add(familyMembers);
    }
    inputMap.put('familyMembers', families);
    ARC_FamilyMemberPriceBreakup newInst =  new ARC_FamilyMemberPriceBreakup();

    Test.startTest();
    newInst.invokeMethod(methodName, inputMap, outMap, options);
    Test.stopTest();

    List<Object> familyRecords = (List<Object>)outMap.get('MemberList');
    System.assertEquals(true, familyRecords.size()>0);
    System.debug('outMap: ' + outMap);

   }

}