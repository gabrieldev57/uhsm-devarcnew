public class ReturnUncommon {
    
    public class InputWrapper {
        @InvocableVariable(label='List 1' required=true)
        public List<String> list1;

        @InvocableVariable(label='List 2' required=true)
        public List<String> list2;
    }

    @InvocableMethod(label='Get Uncommon Values' description='Returns a list of values that are present in the first list but not in the second.')
    public static List<List<String>> findUncommonValues(List<InputWrapper> inputs) {
        // Prepare a list to hold all the results. 
        // Each item in the list is a list of strings (the uncommon values between two lists)
        List<List<String>> allResults = new List<List<String>>();

        // Process each record individually
        for (InputWrapper input : inputs) {
            Set<String> set1 = new Set<String>(input.list1);
            Set<String> set2 = new Set<String>(input.list2);

            // Remove all elements from set1 that are present in set2, 
            // thus leaving only uncommon values in set1.
            set1.removeAll(set2);

            // Add the result for the current record to the allResults list.
            allResults.add(new List<String>(set1));
        }
        
        // Return the results for all processed records
        return allResults;
    }
}