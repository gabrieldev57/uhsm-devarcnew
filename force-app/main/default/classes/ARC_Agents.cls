global without sharing class ARC_Agents implements vlocity_ins.VlocityOpenInterface{
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'readAgents') {
            readAgents(inputMap, outputMap, options);
        }        
        return true;
    }


    /*******************************************************************
    * @MethodName         :   readAgents
    * @Description        :   Remote Action that is called during enroll to fetch all agents in the typeahead block question:
                              Did you receive assistance from one of our sales agents?
    ********************************************************************/
    global static void readAgents(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        String agentName = (String)inputMap.get('AgentName');
        String soqlQuery = 'SELECT Name FROM User WHERE Name LIKE \'%' + agentName + '%\' AND Profile.Name = \'WS Sales\' AND IsActive = true';
        List<User> agents = Database.query(soqlQuery);
        outMap.put('agents', agents);
    }
}