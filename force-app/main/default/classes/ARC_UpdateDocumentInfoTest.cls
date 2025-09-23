@isTest
public with sharing class ARC_UpdateDocumentInfoTest {
    @isTest
    public static void ARC_UpdateDocumentInfoTest() {
                
        List<Object> DocumentInfo = new List<Object>();
        List<Map<String,Object>> members = new List <Map<String,Object>>();
        Map<String,Object> ProductsList = new Map<String,Object>();
        Map<String,Object> inputMap = new Map<String,Object>();
        Map<String,Object> member1 = new Map<String,Object>();
        Map<String,Object> member2 = new Map<String,Object>();

        ProductsList.put('TotalPrice', 200);
        ProductsList.put('Name', 'Test');

        member1.put('Id', '1');
        member1.put('IsPrimary', true);
        member1.put('Price', 100);
        member1.put('RelatedId', null);
        member2.put('Id', '2');
        member2.put('IsPrimary', false);
        member2.put('Price', 100);
        member2.put('RelatedId', '1');

        members.add(member1);
        members.add(member2);

        ProductsList.put('PrimaryMembersList', members);
        // ProductsList.add(test);  
        DocumentInfo.add(ProductsList);
        inputMap.put('DocumentInfo', DocumentInfo);
        ARC_UpdateDocumentInfo startTesting = new ARC_UpdateDocumentInfo();
        startTesting.invokeMethod('updateDocInfo', inputMap, new Map<String,Object>(), new Map<String,Object>());
    }
}