public class StringSplitter {
    @InvocableMethod(label='Split String' description='Splits a string based on the provided delimiter')
    public static List<StringWrapper> splitString(List<StringWrapper> inputStrings) {
        for(StringWrapper wrap : inputStrings) {
            wrap.values = wrap.input.split(wrap.delimiter);
        }
        return inputStrings;
    }
    public class StringWrapper {
        @InvocableVariable
        public String input;

        @InvocableVariable
        public String delimiter;

        @InvocableVariable
        public List<String> values;
    }
}