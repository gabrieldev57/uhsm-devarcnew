@isTest
public class ARC_MultiSelectFlowValuesTestClass{
    
    @isTest
    static void MultiSelectFlowValuesTest(){
    
        List<string> tempLst = new list<string>();
        tempLst.add('AccidentalCoder');
        tempLst.add('Salesforce');
        ARC_MultiselectFlowvalues.CheckValues(tempLst);

    }
}