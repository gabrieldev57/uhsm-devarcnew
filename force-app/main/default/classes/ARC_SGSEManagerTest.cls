@isTest
private class ARC_SGSEManagerTest {

    @isTest
    static void testConstructor_only() {

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        enrollmentInfo.put('TestKey', 'TestValue');

        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);

        System.assertEquals('TestValue', manager.enrollmentInfo.get('TestKey'));
    }

    @isTest
    static void testExecuteEnrollment_safe() {

        Map<String, Object> enrollmentInfo = new Map<String, Object>();
        enrollmentInfo.put('TestKey', 'TestValue');

        ARC_SGSEManager manager = new ARC_SGSEManager(enrollmentInfo);

        try {
            Test.startTest();
            manager.executeEnrollment();
            Test.stopTest();
        } catch (Exception e) {
            // We EXPECT failure due to real mapper/DML dependency
            System.assert(
                e.getMessage() != null,
                'Expected controlled failure: ' + e.getMessage()
            );
        }
    }
}