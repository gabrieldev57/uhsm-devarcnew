@IsTest 
public class ARC_RetrieveFieldSetsTest {

    @IsTest 
    public static void retrieveFieldSetsTestIFPShop () {
        
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> inputMapSGQuote = new Map<String, Object>();
        Map<String, Object> inputMapSGEnrollment = new Map<String, Object>();
        Map<String, Object> inputMapIMApp = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'retrieveFields';

        inputMapSGQuote.put('QuoteProcess', 'SmallGroupQuote');
        inputMapSGEnrollment.put('QuoteProcess', 'SmallGroupEnrollment');
        inputMapIMApp.put('QuoteProcess', 'IMApplication');

        inputMap.put('QuoteProcess', 'IFP');
        inputMap.put('NoMedicalPlans', true);
        inputMap.put('NoVisionPlans', true);
        inputMap.put('NoDentalPlans', true);
        inputMap.put('FieldsetType', 'IFPShop');

        ARC_RetrieveFieldSets newInst =  new ARC_RetrieveFieldSets();

        Test.startTest();
        newInst.invokeMethod(methodName, inputMap, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGQuote, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGEnrollment, outMap, options);
        newInst.invokeMethod(methodName, inputMapIMApp, outMap, options);
        Test.stopTest();


    }    

    @IsTest 
    public static void retrieveFieldSetsTestIFPEnroll () {
        
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> inputMapSGQuote = new Map<String, Object>();
        Map<String, Object> inputMapSGEnrollment = new Map<String, Object>();
        Map<String, Object> inputMapIMApp = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'retrieveFields';

        inputMapSGQuote.put('QuoteProcess', 'SmallGroupQuote');
        inputMapSGEnrollment.put('QuoteProcess', 'SmallGroupEnrollment');
        inputMapIMApp.put('QuoteProcess', 'IMApplication');

        inputMap.put('QuoteProcess', 'IFP');
        inputMap.put('NoMedicalPlans', true);
        inputMap.put('NoVisionPlans', true);
        inputMap.put('NoDentalPlans', true);
        inputMap.put('FieldsetType', 'IFPEnroll');

        ARC_RetrieveFieldSets newInst =  new ARC_RetrieveFieldSets();

        Test.startTest();
        newInst.invokeMethod(methodName, inputMap, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGQuote, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGEnrollment, outMap, options);
        newInst.invokeMethod(methodName, inputMapIMApp, outMap, options);
        Test.stopTest();


    }    


    @IsTest 
    public static void retrieveFieldSetsTestIFPProgramChangeAddMember () {
        
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> inputMapSGQuote = new Map<String, Object>();
        Map<String, Object> inputMapSGEnrollment = new Map<String, Object>();
        Map<String, Object> inputMapIMApp = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'retrieveFields';

        inputMapSGQuote.put('QuoteProcess', 'SmallGroupQuote');
        inputMapSGEnrollment.put('QuoteProcess', 'SmallGroupEnrollment');
        inputMapIMApp.put('QuoteProcess', 'IMApplication');

        inputMap.put('QuoteProcess', 'IFP');
        inputMap.put('NoMedicalPlans', true);
        inputMap.put('NoVisionPlans', true);
        inputMap.put('NoDentalPlans', true);
        inputMap.put('FieldsetType', 'IFPProgramChangeAddMember');

        ARC_RetrieveFieldSets newInst =  new ARC_RetrieveFieldSets();

        Test.startTest();
        newInst.invokeMethod(methodName, inputMap, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGQuote, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGEnrollment, outMap, options);
        newInst.invokeMethod(methodName, inputMapIMApp, outMap, options);
        Test.stopTest();


    }    

    @IsTest 
    public static void retrieveFieldSetsTestIFPProgramChangePlan () {
        
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> inputMapSGQuote = new Map<String, Object>();
        Map<String, Object> inputMapSGEnrollment = new Map<String, Object>();
        Map<String, Object> inputMapIMApp = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'retrieveFields';

        inputMapSGQuote.put('QuoteProcess', 'SmallGroupQuote');
        inputMapSGEnrollment.put('QuoteProcess', 'SmallGroupEnrollment');
        inputMapIMApp.put('QuoteProcess', 'IMApplication');

        inputMap.put('QuoteProcess', 'IFP');
        inputMap.put('NoMedicalPlans', true);
        inputMap.put('NoVisionPlans', true);
        inputMap.put('NoDentalPlans', true);
        inputMap.put('FieldsetType', 'IFPProgramChangePlan');


        ARC_RetrieveFieldSets newInst =  new ARC_RetrieveFieldSets();

        Test.startTest();
        newInst.invokeMethod(methodName, inputMap, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGQuote, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGEnrollment, outMap, options);
        newInst.invokeMethod(methodName, inputMapIMApp, outMap, options);
        Test.stopTest();


    }    

    @IsTest 
    public static void retrieveFieldSetsTestIFPProgramChangeMultiple () {
        
        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> inputMapSGQuote = new Map<String, Object>();
        Map<String, Object> inputMapSGEnrollment = new Map<String, Object>();
        Map<String, Object> inputMapIMApp = new Map<String, Object>();
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        String methodName = 'retrieveFields';

        inputMapSGQuote.put('QuoteProcess', 'SmallGroupQuote');
        inputMapSGEnrollment.put('QuoteProcess', 'SmallGroupEnrollment');
        inputMapIMApp.put('QuoteProcess', 'IMApplication');

        inputMap.put('QuoteProcess', 'IFP');
        inputMap.put('NoMedicalPlans', true);
        inputMap.put('NoVisionPlans', true);
        inputMap.put('NoDentalPlans', true);
        inputMap.put('FieldsetType', 'IFPProgramChangeMultiple');


        ARC_RetrieveFieldSets newInst =  new ARC_RetrieveFieldSets();

        Test.startTest();
        newInst.invokeMethod(methodName, inputMap, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGQuote, outMap, options);
        newInst.invokeMethod(methodName, inputMapSGEnrollment, outMap, options);
        newInst.invokeMethod(methodName, inputMapIMApp, outMap, options);
        Test.stopTest();


    }    
    
}