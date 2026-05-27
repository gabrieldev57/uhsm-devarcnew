global without sharing class ARC_FormCensusController implements vlocity_ins.VlocityOpenInterface {
    
    /**
     * Invokes the specified method based on the method_name parameter.
     * @param {String} method_name - The name of the method to invoke.
     * @param {Map<String,Object>} input_map - The input parameters for the method.
     * @param {Map<String,Object>} output_map - The output parameters for the method.
     * @param {Map<String,Object>} options_map - Additional options for the method.
     * @returns {Boolean} - Always returns true.
     */
    public static Boolean invokeMethod(String method_name, Map<String,Object> input_map, Map<String,Object> output_map, Map<String,Object> options_map) {
        switch on method_name {
            when 'GET_CensusMembers' { GET_CensusMembers(input_map, output_map, options_map); }
            when 'GET_InactiveCensusMembers' { GET_InactiveCensusMembers(input_map, output_map, options_map); }
            when 'GET_InactiveCensusMemberDetails' { GET_InactiveCensusMemberDetails(input_map, output_map, options_map); }
            when 'GET_AddressSuggestionsFromGoogleMapsAPI' { GET_AddressSuggestionsFromGoogleMapsAPI(input_map, output_map, options_map); }
            when 'GET_AddressDetailsFromGoogleMapsAPI' { GET_AddressDetailsFromGoogleMapsAPI(input_map, output_map, options_map); }
            when 'getAvailableStates' { getAvailableStates(input_map, output_map, options_map); }
        }
        return true;
    }

    /**
     * Fetches active census members for a given census ID.
     * @param {Map<String,Object>} input_map - Contains the census_id.
     * @param {Map<String,Object>} output_map - Stores the fetched census members.
     * @param {Map<String,Object>} options_map - Additional options (unused).
     */
    public static void GET_CensusMembers(Map<String, Object> input_map, Map<String, Object> output_map, Map<String, Object> options_map) {
        List<Map<String, Object>> census_members_list = new List<Map<String, Object>>();
        Id contractId = (Id) input_map.get('contract_id');
        Boolean clean_output = (Boolean)input_map.get('clean_output');
        Id censusId = input_map.containsKey('census_id') ? (Id)input_map.get('census_id') : null;
        Boolean isSpinOff = input_map.containsKey('is_pcspinoff') ? (Boolean)input_map.get('is_pcspinoff') : false;
        Set<Id> censusMemberIds = getContractMemberIds(contractId, censusId, isSpinOff);

        List<ARC_ContractParticipant__c> contractParticipants = [
            SELECT Id, ARC_PersonAccount__r.Census_Member__c, ARC_Relationship__c, ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressCity__c, 
                ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressState__c, ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressStreet__c, ARC_PersonAccount__r.Census_Member__r.ARC_PhysicalAddressZipCode__c
            FROM ARC_ContractParticipant__c
            WHERE ARC_Contract__c = :contractId AND ARC_Relationship__c != null
        ];

        // Map census members with contract participant relationships
        Map<Id, String> censusMemberRelationshipMap = new Map<Id, String>();
        vlocity_ins__GroupCensusMember__c primaryMember;
        for (ARC_ContractParticipant__c contractParticipant : contractParticipants) {
            if (contractParticipant.ARC_Relationship__c == 'Primary') {
                primaryMember = contractParticipant.ARC_PersonAccount__r.Census_Member__r;
            }
            censusMemberRelationshipMap.put(contractParticipant.ARC_PersonAccount__r.Census_Member__c, contractParticipant.ARC_Relationship__c);
        }

        // Query active census members
        for (vlocity_ins__GroupCensusMember__c member : [
            SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, ARC_MiddleInitial__c, vlocity_ins__Birthdate__c, 
                   vlocity_ins__Gender__c, ARC_Relationship__c, vlocity_ins__Email__c, ARC_Phone__c, vlocity_ins__SocialSecurityNumber__c, 
                   ARC_HeightFeet__c, ARC_HeightInches__c, ARC_Weight__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressState__c, 
                   ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressZipCode__c, ARC_UpdateAllAddress__c, ARC_Age__c, ARC_Smoker__c, 
                   vlocity_ins__IsPrimaryMember__c,ARC_isPregnant__c, vlocity_ins__ContactId__r.AccountId, vlocity_ins__ContactId__c,vlocity_ins__ContactId__r.Account.IsActive, vlocity_ins__MemberIdentifier__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id IN :censusMemberIds
            ORDER BY vlocity_ins__IsPrimaryMember__c DESC, vlocity_ins__IsSpouse__c DESC, vlocity_ins__Birthdate__c ASC
        ]) {
            Map<String,Object> member_map = createMemberMap(member, censusMemberRelationshipMap, primaryMember);
            if (clean_output == true) member_map = cleanCensusMemberMapFields(member_map);
            census_members_list.add(member_map);
        }
        output_map.put('census_members', census_members_list);
    }

    private static Map<String,Object> cleanCensusMemberMapFields(Map<String,Object> member) {
        List<String> fieldsToClean = new List<String>{'vlocity_ins__Gender__c', 'ARC_Relationship__c', 'ARC_Smoker__c', 'ARC_Phone__c', 'vlocity_ins__Email__c', 'ARC_isPregnant__c'};
        for (String field_name : fieldsToClean) {
            if (((Boolean)((Map<String,Object>)member.get(field_name)).get('DISPLAY_FIELD')) == false) {
                ((Map<String,Object>)member.get(field_name)).put('value','');
            }
            member.put(field_name, ((Map<String,Object>)member.get(field_name)).get('value'));
        }
        return member;
    }

    /**
     * Fetches inactive census members for a given census ID and search input.
     * @param {Map<String,Object>} input_map - Contains the census_id and search_input.
     * @param {Map<String,Object>} output_map - Stores the fetched inactive members.
     * @param {Map<String,Object>} options_map - Additional options (unused).
     */
    public static void GET_InactiveCensusMembers(Map<String, Object> input_map, Map<String, Object> output_map, Map<String, Object> options_map) {
        List<Map<String, Object>> return_list = new List<Map<String, Object>>();
        Id censusId = (Id) input_map.get('census_id');
        Id contractId = (Id) input_map.get('contract_id');
        List<Object> census_members_list = (List<Object>) input_map.get('census_members');
        Set<Id> censusMemberIds = new Set<Id>();
        for (Object census_member : census_members_list) {
            Map<String, Object> census_member_map = (Map<String, Object>) census_member;
            if (census_member_map.containsKey('Id') && census_member_map.get('Id') != null && census_member_map.get('IsNewMember') != true) {
                censusMemberIds.add((Id) census_member_map.get('Id'));
            }
        }

        //Get All the Medical GCMP of current member 
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToCm = Database.query(
            'SELECT Id, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c ' +
            'FROM vlocity_ins__GroupCensusMemberPlan__c ' +
            'WHERE vlocity_ins__GroupCensusMemberId__c IN :censusMemberIds '+
            'AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = \'Medical\' '+
            'AND ('+
                'vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Activated\' '+
                'OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Terminated\' '+
                'OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Awaiting Activation\' '+
            ')'
        );

        Set<Id> contractsInvolved = new Set<Id>();
        //Get Contracts Ids WHERE current members are involved
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : gcmpRelatedToCm) {
            contractsInvolved.add(gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c);
        }

        //Get All the Medical GCMP of inactive members
        List<vlocity_ins__GroupCensusMemberPlan__c> inactiveGcmpRelatedToCm = Database.query(
            'SELECT Id, vlocity_ins__GroupCensusMemberId__c, vlocity_ins__GroupCensusMemberId__r.Name ' +
            'FROM vlocity_ins__GroupCensusMemberPlan__c ' +
            'WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c IN :contractsInvolved ' +
            'AND vlocity_ins__GroupCensusMemberId__c NOT IN :censusMemberIds ' +
            'AND (vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.IsActive = false ' +
            'OR vlocity_ins__GroupCensusMemberId__r.ARC_Relationship__c = \'Temporary Newborn\') ' +
            'ORDER BY vlocity_ins__GroupCensusMemberId__r.vlocity_ins__IsPrimaryMember__c DESC, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__IsSpouse__c DESC, vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c ASC'
        );

        Set<vlocity_ins__GroupCensusMember__c> inactiveMembers = new Set<vlocity_ins__GroupCensusMember__c>();
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : inactiveGcmpRelatedToCm) {
            vlocity_ins__GroupCensusMember__c inactive_census_member = new vlocity_ins__GroupCensusMember__c();
            inactive_census_member.Id = gcmp.vlocity_ins__GroupCensusMemberId__c;
            inactive_census_member.Name = gcmp.vlocity_ins__GroupCensusMemberId__r.Name;
            inactiveMembers.add(inactive_census_member);
        }
        for (vlocity_ins__GroupCensusMember__c member : inactiveMembers) {
            Map<String, Object> census_member_map = new Map<String, Object>();
            census_member_map.put('label', member.Name);
            census_member_map.put('value', member.Id);
            return_list.add(census_member_map);
        }
        output_map.put('inactive_members', return_list);
    }

    /**
     * Fetches inactive census members for a given census ID and search input.
     * @param {Map<String,Object>} input_map - Contains the census_id and search_input.
     * @param {Map<String,Object>} output_map - Stores the fetched inactive members.
     * @param {Map<String,Object>} options_map - Additional options (unused).
     */
    public static void GET_InactiveCensusMemberDetails(Map<String, Object> input_map, Map<String, Object> output_map, Map<String, Object> options_map) {
        Id censusMemberId = (Id)input_map.get('census_member_id');

        String query = 'SELECT Id, Name, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, ARC_MiddleInitial__c, vlocity_ins__Birthdate__c, ' +
        'vlocity_ins__Gender__c, ARC_Relationship__c, vlocity_ins__Email__c, ARC_Phone__c, vlocity_ins__SocialSecurityNumber__c, ' +
        'ARC_HeightFeet__c, ARC_HeightInches__c, ARC_Weight__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressState__c, ' +
        'ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressZipCode__c, ARC_UpdateAllAddress__c, ARC_Age__c, ARC_Smoker__c, ARC_isPregnant__c,' +
        'vlocity_ins__IsPrimaryMember__c, vlocity_ins__ContactId__r.AccountId,vlocity_ins__ContactId__r.Account.IsActive, vlocity_ins__MemberIdentifier__c, vlocity_ins__ContactId__c ' +
        'FROM vlocity_ins__GroupCensusMember__c WHERE Id = \'' + String.valueOf(censusMemberId) + '\' ';


        vlocity_ins__GroupCensusMember__c inactiveMember = Database.query(query);
        output_map.put('census_member_details', createMemberMap(inactiveMember, null, null));
    }

    /**
     * Creates a member map with default values and processed fields.
     * @param {vlocity_ins__GroupCensusMember__c} member - The member record.
     * @returns {Map<String,Object>} - A map representing the member.
     */
    private static Map<String, Object> createMemberMap (vlocity_ins__GroupCensusMember__c member, Map<Id, String> censusMemberRelationshipMap, vlocity_ins__GroupCensusMember__c primaryMember) {
        String address = String.join(new List<String>{
                member.ARC_PhysicalAddressCity__c, member.ARC_PhysicalAddressState__c, 
                member.ARC_PhysicalAddressStreet__c, member.ARC_PhysicalAddressZipCode__c
            }, ', ');
        String primaryAddress;
        if (primaryMember != null) {
            primaryAddress = String.join(new List<String>{
                    primaryMember.ARC_PhysicalAddressCity__c, primaryMember.ARC_PhysicalAddressState__c, 
                    primaryMember.ARC_PhysicalAddressStreet__c, primaryMember.ARC_PhysicalAddressZipCode__c
                }, ', ');
        }
        String relationship = member.ARC_Relationship__c;
        if (censusMemberRelationshipMap != null && censusMemberRelationshipMap.containsKey(member.Id)) {
            relationship = censusMemberRelationshipMap.get(member.Id);
            if (relationship == 'Future Primary') {
                relationship = 'Primary';
            }
        }
        Map<String, Object> memberMap = new Map<String, Object>{
            'Id' => member.Id,
            'vlocity_ins__FirstName__c' => member.vlocity_ins__FirstName__c,
            'vlocity_ins__LastName__c' => member.vlocity_ins__LastName__c,
            'PersonAccountId' => member.vlocity_ins__ContactId__r.AccountId,
            'PersonContactId' => member.vlocity_ins__ContactId__c,
            'IsActive' => member?.vlocity_ins__ContactId__r?.Account?.IsActive,
            'vlocity_ins__MemberIdentifier__c' => member.vlocity_ins__MemberIdentifier__c,
            'ARC_MiddleInitial__c' => member.ARC_MiddleInitial__c,
            'vlocity_ins__Birthdate__c' => member.vlocity_ins__Birthdate__c,
            'vlocity_ins__IsPrimaryMember__c' => relationship == 'Primary',
            'ARC_Age__c' => member.ARC_Age__c,
            'vlocity_ins__SocialSecurityNumber__c' => member.vlocity_ins__SocialSecurityNumber__c,
            'showSSN' => 'password',
            'ARC_HeightFeet__c' => member.ARC_HeightFeet__c,
            'ARC_HeightInches__c' => member.ARC_HeightInches__c,
            'ARC_Weight__c' => member.ARC_Weight__c,
            'ARC_Smoker__c' => member.ARC_Smoker__c,
            'ARC_PhysicalAddressCity__c' => member.ARC_PhysicalAddressCity__c,
            'ARC_PhysicalAddressState__c' => member.ARC_PhysicalAddressState__c,
            'ARC_PhysicalAddressStreet__c' => member.ARC_PhysicalAddressStreet__c,
            'ARC_PhysicalAddressZipCode__c' => member.ARC_PhysicalAddressZipCode__c,
            'ARC_Address__c' => address,
            'IsDependent' => relationship != 'Primary',
            'individual_errors' => new List<String>(),
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
            'DISABLE_INPUT_FIELDS' => false
        };

        // Show address

        if (address == primaryAddress) {
            memberMap.put('CopyAddressFromPrimary', true);
            memberMap.put('ShowAddressForDependent', false);
        } else {
            memberMap.put('CopyAddressFromPrimary', false);
            memberMap.put('ShowAddressForDependent', true);
        }
            
        // Remove all non-digit characters
        String cleanPhoneNumber = member.ARC_Phone__c;
        if (cleanPhoneNumber != null) {
            cleanPhoneNumber = member.ARC_Phone__c.replaceAll('[^0-9]', '');
            // Remove leading '1' if it's an 11-digit number starting with '1'
            if (cleanPhoneNumber.length() == 11 && cleanPhoneNumber.startsWith('1')) {
                cleanPhoneNumber = cleanPhoneNumber.substring(1);
            }
        }

        memberMap.put('ARC_Phone__c', new Map<String, Object>{
            'value' => cleanPhoneNumber,
            'DISPLAY_FIELD' => member.ARC_Age__c >= 18 
        });

        memberMap.put('vlocity_ins__Email__c', new Map<String, Object>{
            'value' => member.vlocity_ins__Email__c,
            'DISPLAY_FIELD' => member.ARC_Age__c >= 18
        });

        memberMap.put('ARC_Smoker__c', new Map<String, Object>{
            'value' => member.ARC_Smoker__c,
            'DISPLAY_FIELD' => member.ARC_Age__c >= 18 
        });

        memberMap.put('ARC_isPregnant__c', new Map<String, Object>{
            'value' => member.ARC_isPregnant__c,
            'DISPLAY_FIELD' => member.vlocity_ins__Gender__c == 'Female' && member.ARC_Age__c >= 18
        });

        // Add relationship and gender options
        memberMap.put('ARC_Relationship__c', new Map<String, Object>{
            'value' => relationship,
            'options' => new List<Map<String, String>>{
                new Map<String, String>{ 'label' => 'Primary', 'value' => 'Primary' },
                new Map<String, String>{ 'label' => 'Spouse', 'value' => 'Spouse' },
                new Map<String, String>{ 'label' => 'Child', 'value' => 'Child' }
            }
        });

        memberMap.put('vlocity_ins__Gender__c', new Map<String, Object>{
            'value' => member.vlocity_ins__Gender__c,
            'options' => new List<Map<String, String>>{
                new Map<String, String>{ 'label' => 'Male', 'value' => 'Male' },
                new Map<String, String>{ 'label' => 'Female', 'value' => 'Female' }
            }
        });

        return memberMap;
    }

    /**
     * Fetches address suggestions from Google Maps API.
     * @param {Map<String,Object>} input_map - Contains the search input.
     * @param {Map<String,Object>} output_map - Stores the fetched suggestions.
     * @param {Map<String,Object>} options_map - Additional options (unused).
     */
    public static void GET_AddressSuggestionsFromGoogleMapsAPI(Map<String, Object> input_map, Map<String, Object> output_map, Map<String, Object> options_map) {
        String apiKey = 'AIzaSyACXXKxlzJEJa5nutk3m28tr9J3o7-bK3w';
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=' + EncodingUtil.urlEncode((String)input_map.get('input'), 'UTF-8') + '&key=' + apiKey + '&types=address&language=en');
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);

        Map<String, Object> suggestions = new Map<String, Object>();
        for (Object prediction : (List<Object>)((Map<String, Object>)JSON.deserializeUntyped(res.getBody())).get('predictions')) {
            suggestions.put((String)((Map<String, Object>)prediction).get('description'), (String)((Map<String, Object>)prediction).get('place_id'));
        }

        output_map.put('suggestions', suggestions);
    }

    /**
     * Fetches address details from Google Maps API.
     * @param {Map<String,Object>} input_map - Contains the place_id.
     * @param {Map<String,Object>} output_map - Stores the fetched address details.
     * @param {Map<String,Object>} options_map - Additional options (unused).
     */
    public static void GET_AddressDetailsFromGoogleMapsAPI(Map<String, Object> input_map, Map<String, Object> output_map, Map<String, Object> options_map) {
        String apiKey = 'AIzaSyACXXKxlzJEJa5nutk3m28tr9J3o7-bK3w';
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://maps.googleapis.com/maps/api/place/details/json?placeid=' + EncodingUtil.urlEncode((String)input_map.get('place_id'), 'UTF-8') + '&key=' + apiKey);
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        Map<String, Object> resultMap = (Map<String, Object>) responseMap.get('result');
        List<Object> addressComponents = (List<Object>)resultMap.get('address_components');

        String streetNumber = '';
        String streetName = '';

        for (Object ac : addressComponents) {
            Map<String, Object> component = (Map<String, Object>)ac;
            List<Object> types = (List<Object>) component.get('types');
            String shortName = (String) component.get('short_name');
            String longName = (String) component.get('long_name');
            if (types.contains('administrative_area_level_1')) output_map.put('ARC_PhysicalAddressState__c', shortName);
            else if (types.contains('locality')) output_map.put('ARC_PhysicalAddressCity__c', longName);
            else if (types.contains('postal_code')) output_map.put('ARC_PhysicalAddressZipCode__c', longName);
            else if(types.contains('street_number')) streetNumber = longName;
            else if (types.contains('route')) streetName = longName;
        }

        if (streetNumber != '' && streetName != '') {
            output_map.put('ARC_PhysicalAddressStreet__c', streetNumber + ' ' + streetName);
        } else if (streetName != '') {
            output_map.put('ARC_PhysicalAddressStreet__c', streetName);
        }
    }

    private static Set<Id> getContractMemberIds(Id contractId, Id censusId, Boolean isSpinOff) {
        Set<Id> censusMemberIds = new Set<Id>();
        if (isSpinOff == true) {
            for (vlocity_ins__GroupCensusMember__c member : [
                SELECT Id
                FROM vlocity_ins__GroupCensusMember__c
                WHERE vlocity_ins__CensusId__c = :censusId
            ]) {
                censusMemberIds.add(member.Id);
            }
        } else {
            for (ARC_ContractParticipant__c participant : [
                SELECT Id, ARC_PersonAccount__r.Census_Member__c 
                FROM ARC_ContractParticipant__c 
                WHERE ARC_Contract__c = :contractId
            ]) {
                if (participant.ARC_PersonAccount__r != null && participant.ARC_PersonAccount__r.Census_Member__c != null) {
                    censusMemberIds.add(participant.ARC_PersonAccount__r.Census_Member__c);
                }
            }
        }
        return censusMemberIds;
    }

    public static void getAvailableStates(Map<String, Object> input_map, Map<String, Object> output_map, Map<String, Object> options_map) {
        List<String> availableStates = new List<String>();
        for (ARC_Available_States__mdt state : [SELECT Abbreviation__c FROM ARC_Available_States__mdt WHERE Abbreviation__c != NULL]) {
            availableStates.add(state.Abbreviation__c);
        }
        output_map.put('availableStates', availableStates);
    }
    
}