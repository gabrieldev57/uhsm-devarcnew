@isTest
public without sharing class ARC_CreateIFPAccountAndCensusV2Test {
    
    @TestSetup
    static void mockData(){
        User brokerUser = ARC_TestUtility.createTestUsers(1, 'System Administrator')[0];
        brokerUser.FirstName = 'Broker';
        brokerUser.LastName = 'Account';
        insert brokerUser;
    }
    
    @isTest
    static void testOneWithGuardianName() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        String inputList = '[{"GuardianLastName": "Tester","GuardianFirstName": "elGuardian","GuardianGender": "Male","GuardianStreet": "2341 U.S. 166","GuardianApt": "","GuardianCity": "Caney","GuardianState": "KS","GuardianZipCode": "67333","GuardianEmail": "fgfdgdf@dfsdf.com","GuardianPhone": "3453453453","GuardianBirthdate": "1996-09-13"}]';
        List<Object> inputData = (List<Object>)JSON.deserializeUntyped(inputList); 
        inputMap=(Map<String,Object>)inputData[0];

        Id userId = [SELECT Id FROM User WHERE Name = 'Broker Account' LIMIT 1].Id;
        
        String optionList = '[{"contractTerm": 12,"ContractReason": "New Application","userProfile":"System Administrator","Phone": "5435345345", "AptUnit": "","MiddleName": "","accountName": "","UserId": "'+ String.valueOf(userId) +'","TimeStamp": "2022-09-19T15:06:09.508Z","OpportunityId": "","NOpportunityId": "","NOContractId": "","NOCensusMemberId": "","NOCensusId": "","NOAccountId": "","LastName": "Chris","Gender": "Male","FirstName": "Test","Email": "sdffsdsfd@dsfsdf.com","DateOfBirth": "2015-09-11","ContractId": "","CensusMemberId": "","CensusId": "","BillingZipCode": "67337","BillingStreet": "123 Meadow Lane","BillingState": "KS","BillingCity": "Coffeyville","AccountId": "","postTransformBundle": "","preTransformBundle": "","useQueueableApexRemoting": false,"ignoreCache": false,"vlcClass": "ARC_CreateIFPAccountAndCensusV2","useContinuation": false}]';
        List<Object> optionData = (List<Object>)JSON.deserializeUntyped(optionList); 
        options=(Map<String,Object>)optionData[0];
        
        String methodName = 'createRecords';
        ARC_CreateIFPAccountAndCensusV2 className = new ARC_CreateIFPAccountAndCensusV2();
        
        Test.startTest();
        	Boolean result = className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        Assert.areEqual(true, result);
    }
    
    @isTest
    static void testTwoWithoutGuardianName() {
        Map<String, Object> inputMap = new Map <String,Object> ();
        Map<String, Object> outputMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();
        
        String inputList = '[{"GuardianLastName": "","GuardianFirstName": "","GuardianGender": "Male","GuardianStreet": "2341 U.S. 166","GuardianApt": "","GuardianCity": "Caney","GuardianState": "KS","GuardianZipCode": "67333","GuardianEmail": "fgfdgdf@dfsdf.com","GuardianPhone": "3453453453","GuardianBirthdate": "1996-09-13"}]';
        List<Object> inputData = (List<Object>)JSON.deserializeUntyped(inputList); 
        inputMap=(Map<String,Object>)inputData[0];

        Id userId = [SELECT Id FROM User WHERE Name = 'Broker Account' LIMIT 1].Id;
        
        String optionList = '[{"contractTerm": 12,"ContractReason": "New Application","userProfile":"System Administrator","Phone": "5435345345", "AptUnit": "","MiddleName": "","accountName": "","UserId": "'+ String.valueOf(userId) +'","TimeStamp": "2022-09-19T15:06:09.508Z","OpportunityId": "","NOpportunityId": "","NOContractId": "","NOCensusMemberId": "","NOCensusId": "","NOAccountId": "","LastName": "Chris","Gender": "Male","FirstName": "Test","Email": "sdffsdsfd@dsfsdf.com","DateOfBirth": "2015-09-11","ContractId": "","CensusMemberId": "","CensusId": "","BillingZipCode": "67337","BillingStreet": "123 Meadow Lane","BillingState": "KS","BillingCity": "Coffeyville","AccountId": "","postTransformBundle": "","preTransformBundle": "","useQueueableApexRemoting": false,"ignoreCache": false,"vlcClass": "ARC_CreateIFPAccountAndCensusV2","useContinuation": false}]';
        List<Object> optionData = (List<Object>)JSON.deserializeUntyped(optionList); 
        options=(Map<String,Object>)optionData[0];
        
        String methodName = 'createRecords';
        ARC_CreateIFPAccountAndCensusV2 className = new ARC_CreateIFPAccountAndCensusV2();
        
        Test.startTest();
        	Boolean result = className.invokeMethod(methodName, inputMap, outputMap, options);
        Test.stopTest();
        Assert.areEqual(true, result);
    }
    
        @isTest
    	static void insertOpportunityTest() {
        	List<Account> accList = ARC_TestUtility.createTestAccount(1,'StandardAccount');
        
            Test.startTest();
                 Opportunity opp = ARC_CreateIFPAccountAndCensusV2.insertOpportunity(accList[0].Id);
            Test.stopTest();
			Opportunity [] relatedOpp = [SELECT Id FROM Opportunity WHERE AccountId =: accList[0].Id];
            System.assertEquals(1, relatedOpp.size());
    	}
    
}