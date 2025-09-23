@isTest
public class ARC_AgentsTest {

    @isTest
    static void testReadAgents() {
        Map<String, Object> inputMap = new Map<String, Object>{
            'AgentName' => 'Test Agent'
        };
        Map<String, Object> optionsMap = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();

        // Call the method being tested
        Test.startTest();
        ARC_Agents newInstance = new ARC_Agents();
        newInstance.invokeMethod('readAgents',inputMap,outMap,optionsMap);
        Test.stopTest();
    }
}