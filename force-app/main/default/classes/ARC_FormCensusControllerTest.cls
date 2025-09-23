@isTest
private class ARC_FormCensusControllerTest {

    @TestSetup
    static void makeData() {
        List<Contract> contract = ARC_TestUtility.createContractsAA(2);
        insert contract;

        contract[0].Status = contract[1].Status =  'Awaiting Activation';
        update contract;
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            Account acc = new Account();
            acc.FirstName = 'TestFirstName ' + i;
            acc.LastName = 'TestLastName ' + i;
            acc.RecordTypeId = recordTypeId;
            accts.add(acc);
        }
        accts[0].IsActive = true;
        accts[1].IsActive = false;
        insert accts;
        
        List<Account> accountListContactIds = [SELECT Id, PersonContactId FROM Account WHERE FirstName Like 'TestFirstName%' ORDER BY FirstName];

        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = contract[0].AccountId;
        insert census;

        List<vlocity_ins__GroupCensusMember__c> cenMems = new List<vlocity_ins__GroupCensusMember__c>();
        for (Integer i = 0; i < 2; i++)  {
            vlocity_ins__GroupCensusMember__c cenMem = new vlocity_ins__GroupCensusMember__c();
            cenMem.Name = 'Test Census Member ' + i;
            cenMem.vlocity_ins__ContactId__c = accountListContactIds[i].PersonContactId;
            cenMem.vlocity_ins__AccountId__c = accountListContactIds[i].Id;
            cenMem.vlocity_ins__CensusId__c = census.Id;
            cenMem.ARC_Phone__c = '11111111111';
            cenMems.add(cenMem);
        }        
        insert cenMems;

        Product2 product = new Product2(Name = 'WeShare', vlocity_ins__Type__c = 'Medical', vlocity_ins__SubType__c = 'PPO');
        insert product;

        List<vlocity_ins__ContractLineItem__c> cliList = new List<vlocity_ins__ContractLineItem__c>();
        for (Integer i = 0; i < 2; i++) {
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
            cli.vlocity_ins__ContractId__c = contract[0].Id;
            cli.vlocity_ins__Product2Id__c = product.Id;
            cliList.add(cli);
        }
        insert cliList;

        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for (Integer i = 0; i < 3; i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmp = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmp.Name = 'Test Plan ' + i;
            gcmpList.add(gcmp);
        }
        gcmpList[0].vlocity_ins__GroupCensusMemberId__c = gcmpList[1].vlocity_ins__GroupCensusMemberId__c = cenMems[0].Id;
        gcmpList[2].vlocity_ins__GroupCensusMemberId__c = cenMems[1].Id;
        gcmpList[0].vlocity_ins__ContractLineId__c = cliList[0].Id;
        gcmpList[1].vlocity_ins__ContractLineId__c = gcmpList[2].vlocity_ins__ContractLineId__c = cliList[1].Id;
        insert gcmpList;
        
        for (Integer i = 0; i < 2; i++) {
            accts[i].Census_Member__c = cenMems[i].Id;
            accts[i].ARC_CensusMember__pc = cenMems[i].Id;
            accts[i].ARC_Census__c = cenMems[i].vlocity_ins__CensusId__c;
        }
        update accts;

        List<ARC_ContractParticipant__c> contractParticipantList = new List<ARC_ContractParticipant__c>();
        for (Integer i = 0; i < 3; i++) {
            ARC_ContractParticipant__c contractParticipant = new ARC_ContractParticipant__c();
            contractParticipant.Name = 'Test Contract Participant ' + i;
            contractParticipantList.add(contractParticipant);
        }
        contractParticipantList[0].ARC_Contract__c = contract[0].Id;
        contractParticipantList[1].ARC_Contract__c = contractParticipantList[2].ARC_Contract__c = contract[1].Id;
        contractParticipantList[0].ARC_PersonAccount__c = contractParticipantList[1].ARC_PersonAccount__c = accts[0].Id;
        contractParticipantList[2].ARC_PersonAccount__c = accts[1].Id;
        insert contractParticipantList;
    }

    @isTest
    static void GET_CensusMembersTest() {
        Map<String,Object> input_map = new Map<String,Object>();
        Map<String,Object> output_map = new Map<String,Object>();
        Map<String,Object> options_map = new Map<String,Object>();

        Contract contract = [SELECT Id FROM Contract LIMIT 1];

        input_map.put('contract_id', contract.Id);
        input_map.put('clean_output', true);

        Test.startTest();
        Boolean result = ARC_FormCensusController.invokeMethod('GET_CensusMembers', input_map, output_map, options_map);
        Test.stopTest();

        Assert.areEqual(((List<Map<String, Object>>) output_map.get('census_members')).size(), 1, 'Census members are not correctly retrieved');
    }

    @isTest
    static void GET_InactiveCensusMembersTest() {
        Map<String,Object> input_map = new Map<String,Object>();
        Map<String,Object> output_map = new Map<String,Object>();
        Map<String,Object> options_map = new Map<String,Object>();

        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        vlocity_ins__GroupCensus__c census = [SELECT Id, (SELECT Id FROM vlocity_ins__Census_Members__r WHERE vlocity_ins__ContactId__r.Account.IsActive = true) FROM vlocity_ins__GroupCensus__c LIMIT 1];
        List<Map<String, Object>> census_members_list = new List<Map<String, Object>>();
        for (vlocity_ins__GroupCensusMember__c censMem : census.vlocity_ins__Census_Members__r) {
            Map<String, Object> census_member_map = new Map<String, Object>();
            census_member_map.put('Id', censMem.Id);
            census_members_list.add(census_member_map);
        }

        input_map.put('contract_id', contract.Id);
        input_map.put('census_members', census_members_list);
        input_map.put('census_id', census.Id);

        Test.startTest();
        Boolean result = ARC_FormCensusController.invokeMethod('GET_InactiveCensusMembers', input_map, output_map, options_map);
        Test.stopTest();

        Assert.areEqual(((List<Map<String, Object>>) output_map.get('inactive_members')).size(), 1, 'Inactive Census members are not correctly retrieved');
    }

    @isTest
    static void GET_InactiveCensusMemberDetailsTest() {
        Map<String,Object> input_map = new Map<String,Object>();
        Map<String,Object> output_map = new Map<String,Object>();
        Map<String,Object> options_map = new Map<String,Object>();

        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__ContactId__r.Account.IsActive = false LIMIT 1];

        input_map.put('census_member_id', censusMember.Id);

        Test.startTest();
        Boolean result = ARC_FormCensusController.invokeMethod('GET_InactiveCensusMemberDetails', input_map, output_map, options_map);
        Test.stopTest();

        Assert.areNotEqual(((Map<String, Object>) output_map.get('census_member_details')), null, 'Inactive Census member details are not correctly retrieved');
    }

    private class GoogleMapsAutocompleteMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"predictions": [ ' +
                '{"description": "1600 Amphitheatre Parkway, Mountain View, CA", "place_id": "ChIJ2eUgeAK6j4ARbn5u_wAGqWA"},' +
                '{"description": "1 Hacker Way, Menlo Park, CA", "place_id": "ChIJZQvWkWS7j4AR1p1nTSaRtuQ"} ]}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void GET_AddressSuggestionsFromGoogleMapsAPITest() {
        Map<String,Object> input_map = new Map<String,Object>();
        Map<String,Object> output_map = new Map<String,Object>();
        Map<String,Object> options_map = new Map<String,Object>();

        input_map.put('input', '1600');

        Test.setMock(HttpCalloutMock.class, new GoogleMapsAutocompleteMock());

        vlocity_ins__GroupCensusMember__c censusMember = [SELECT Id FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__ContactId__r.Account.IsActive = false LIMIT 1];

        input_map.put('census_member_id', censusMember.Id);

        Test.startTest();
        Boolean result = ARC_FormCensusController.invokeMethod('GET_AddressSuggestionsFromGoogleMapsAPI', input_map, output_map, options_map);
        Test.stopTest();

        Assert.areEqual(output_map.containsKey('suggestions'), true, 'Output map should contain suggestions');
        Map<String, Object> suggestions = (Map<String, Object>) output_map.get('suggestions');
        Assert.areEqual(suggestions.size(), 2, 'There should be 2 address suggestions');
    }

    private class GoogleMapsDetailsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{' +
                '"result": {' +
                    '"address_components": [' +
                        '{"long_name": "1600", "short_name": "1600", "types": ["street_number"]},' +
                        '{"long_name": "Amphitheatre Parkway", "short_name": "Amphitheatre Pkwy", "types": ["route"]},' +
                        '{"long_name": "Mountain View", "short_name": "Mountain View", "types": ["locality"]},' +
                        '{"long_name": "California", "short_name": "CA", "types": ["administrative_area_level_1"]},' +
                        '{"long_name": "94043", "short_name": "94043", "types": ["postal_code"]}' +
                    ']' +
                '}' +
            '}');
            return res;
        }
    }

    @IsTest
    static void GET_AddressDetailsFromGoogleMapsAPITest() {
        Test.setMock(HttpCalloutMock.class, new GoogleMapsDetailsMock());

        Map<String, Object> input_map = new Map<String, Object>{
            'place_id' => 'ChIJ2eUgeAK6j4ARbn5u_wAGqWA'
        };
        Map<String, Object> output_map = new Map<String, Object>();
        Map<String, Object> options_map = new Map<String, Object>();

        Test.startTest();
        Boolean result = ARC_FormCensusController.invokeMethod('GET_AddressDetailsFromGoogleMapsAPI', input_map, output_map, options_map);
        Test.stopTest();

        Assert.areEqual('CA', output_map.get('ARC_PhysicalAddressState__c'));
        Assert.areEqual('Mountain View', output_map.get('ARC_PhysicalAddressCity__c'));
        Assert.areEqual('94043', output_map.get('ARC_PhysicalAddressZipCode__c'));
        Assert.areEqual('1600 Amphitheatre Parkway', output_map.get('ARC_PhysicalAddressStreet__c'));
    }
}