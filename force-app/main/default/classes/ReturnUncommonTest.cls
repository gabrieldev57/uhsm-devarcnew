@isTest
public class ReturnUncommonTest {
    
    @isTest static void testFindUncommonValues() {
        // Define Test Data
        List<String> list1 = new List<String>{'A', 'B', 'C', 'D'};
        List<String> list2 = new List<String>{'B', 'C', 'E', 'F'};

        ReturnUncommon.InputWrapper input = new ReturnUncommon.InputWrapper();
        input.list1 = list1;
        input.list2 = list2;

        // Test
        List<List<String>> results = ReturnUncommon.findUncommonValues(new List<ReturnUncommon.InputWrapper> { input });

        System.assertEquals(1, results.size(), 'Expected one result list');
        System.assertEquals(2, results[0].size(), 'Expected 2 uncommon values');
        System.assert(results[0].contains('A'), 'Expected A to be an uncommon value');
        System.assert(results[0].contains('D'), 'Expected D to be an uncommon value');
        System.assert(!results[0].contains('B'), 'B should not be in the result');
        System.assert(!results[0].contains('C'), 'C should not be in the result');
        System.assert(!results[0].contains('E'), 'E should not be in the result');
        System.assert(!results[0].contains('F'), 'F should not be in the result');

    }
}