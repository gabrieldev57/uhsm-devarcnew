@isTest
public class ARC_PlanGroupMetadataTest {
    @isTest
    static void testGetGroups() {

        // Call the method being tested
        Map<String, Object> outMap = new Map<String, Object>();
        Test.startTest();
        ARC_PlanGroupMetadata pgm = new ARC_PlanGroupMetadata();
        pgm.invokeMethod('getGroups',new Map<String, Object>(),outMap,new Map<String, Object>());

        // Verify the results
        List<Object> groupMaps = (List<Object>)outMap.get('groupMaps');
        System.assertEquals(2, groupMaps.size());

        Map<String, Object> group1Map = (Map<String, Object>)groupMaps[0];
        System.assertEquals('Group 1', group1Map.get('groupName'));
        System.assertEquals('Description 1', group1Map.get('description'));
        System.assertEquals(new List<String>{'Product 1', 'Product 2'}, group1Map.get('products'));
        System.assertEquals(new List<String>{'Attribute 1', 'Attribute 2'}, group1Map.get('uniqueAttributes'));

        Map<String, Object> group2Map = (Map<String, Object>)groupMaps[1];
        System.assertEquals('Group 2', group2Map.get('groupName'));
        System.assertEquals('Description 2', group2Map.get('description'));
        System.assertEquals(new List<String>{'Product 3', 'Product 4'}, group2Map.get('products'));
        System.assertEquals(new List<String>{'Attribute 3', 'Attribute 4'}, group2Map.get('uniqueAttributes'));
        Test.stopTest();
    }
}