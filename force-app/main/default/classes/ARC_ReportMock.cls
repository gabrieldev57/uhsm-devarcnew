public class ARC_ReportMock implements System.StubProvider {
    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, 
            Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames, 
            List<Object> listOfArgs) {
        
        // Return mock values based on the method being called
        if (stubbedMethodName == 'getId') {
            return '001000000000001AAA';
        }
        if (stubbedMethodName == 'getDeveloperName') {
            return 'SMB_Paid_DoNotTouch';
        }
        if (stubbedMethodName == 'getName') {
            return 'SMB Paid Report';
        }
        
        return null;
    }
}