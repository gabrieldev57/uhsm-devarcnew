@isTest
public class StringSplitterTest {
    
    @isTest static void testSplitString() {
        // Setup data
        StringSplitter.StringWrapper testWrap = new StringSplitter.StringWrapper();
        testWrap.input = 'John,Doe,Jane';
        testWrap.delimiter = ',';
        
        List<StringSplitter.StringWrapper> wraps = new List<StringSplitter.StringWrapper> { testWrap };

        // Execute method
        List<StringSplitter.StringWrapper> result = StringSplitter.splitString(wraps);

        // Assert results
        System.assertEquals(1, result.size(), 'Expected one result record');
        System.assertEquals(3, result[0].values.size(), 'Expected 3 split values');
        System.assertEquals('John', result[0].values[0], 'First value did not match');
        System.assertEquals('Doe', result[0].values[1], 'Second value did not match');
        System.assertEquals('Jane', result[0].values[2], 'Third value did not match');
    }

    @isTest static void testSplitStringWithEmptyDelimiter() {
        // Setup data
        StringSplitter.StringWrapper testWrap = new StringSplitter.StringWrapper();
        testWrap.input = 'John;Doe;Jane';
        testWrap.delimiter = ';';
        
        List<StringSplitter.StringWrapper> wraps = new List<StringSplitter.StringWrapper> { testWrap };

        // Execute method
        List<StringSplitter.StringWrapper> result = StringSplitter.splitString(wraps);

        // Assert results
        System.assertEquals(1, result.size(), 'Expected one result record');
        System.assertEquals(3, result[0].values.size(), 'Expected 3 split values');
        System.assertEquals('John', result[0].values[0], 'First value did not match');
        System.assertEquals('Doe', result[0].values[1], 'Second value did not match');
        System.assertEquals('Jane', result[0].values[2], 'Third value did not match');
    }

}