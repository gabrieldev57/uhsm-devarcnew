global without sharing class ARC_FormCensusControllerSpinOff implements vlocity_ins.VlocityOpenInterface {
    
    /**
     * Invokes the specified method based on the method_name parameter.
     * @param {String} method_name - The name of the method to invoke.
     * @param {Map<String,Object>} input_map - The input parameters for the method.
     * @param {Map<String,Object>} output_map - The output parameters for the method.
     * @param {Map<String,Object>} options_map - Additional options for the method.
     * @returns {Boolean} - Always returns true.
     */
    public static Boolean invokeMethod(String method_name, Map<String,Object> input_map, Map<String,Object> output_map, Map<String,Object> options_map) {
        System.debug('se llamo');
        switch on method_name {
            when 'GET_CensusMembersPerCensus' { GET_CensusMembersPerCensus(input_map, output_map, options_map); }
            when 'GET_AddressSuggestionsFromGoogleMapsAPI' { GET_AddressSuggestionsFromGoogleMapsAPI(input_map, output_map, options_map); }
            when 'GET_AddressDetailsFromGoogleMapsAPI' { GET_AddressDetailsFromGoogleMapsAPI(input_map, output_map, options_map); }
        }
        return true;
    }

    /**
     * Fetches active census members for a given census ID.
     * @param {Map<String,Object>} input_map - Contains the census_id.
     * @param {Map<String,Object>} output_map - Stores the fetched census members.
     * @param {Map<String,Object>} options_map - Additional options (unused).
     */
    public static void GET_CensusMembersPerCensus(Map<String, Object> input_map, Map<String, Object> output_map, Map<String, Object> options_map) {
        List<List<Map<String, Object>>> census_members_per_census_list = new List<List<Map<String, Object>>>();
        Boolean clean_output = (Boolean)input_map.get('clean_output');
        System.debug('entro');
        List<Object> memberAssignment_raw = (List<Object>)input_map.get('memberAssignment');
        List<Map<String, Object>> memberAssignment = new List<Map<String, Object>>();
        for (Object memberAssignment_raw_item : memberAssignment_raw) {
            memberAssignment.add((Map<String, Object>)memberAssignment_raw_item);
        }

        System.debug('memberAssignment: ' + memberAssignment);
        Set<Id> censusMemberIds = getCensusMemberIds(memberAssignment);
        System.debug('censusMemberIds: ' + censusMemberIds);


        Map<Id, vlocity_ins__GroupCensusMember__c> censusMembers = new Map<Id, vlocity_ins__GroupCensusMember__c>([
            SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, ARC_MiddleInitial__c, vlocity_ins__Birthdate__c, 
                   vlocity_ins__Gender__c, ARC_Relationship__c, vlocity_ins__Email__c, ARC_Phone__c, vlocity_ins__SocialSecurityNumber__c, 
                   ARC_HeightFeet__c, ARC_HeightInches__c, ARC_Weight__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressState__c, 
                   ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressZipCode__c, ARC_UpdateAllAddress__c, ARC_Age__c, ARC_Smoker__c, 
                   vlocity_ins__IsPrimaryMember__c,ARC_isPregnant__c, vlocity_ins__ContactId__r.AccountId, vlocity_ins__ContactId__c, vlocity_ins__MemberIdentifier__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id IN :censusMemberIds
            ORDER BY vlocity_ins__IsPrimaryMember__c DESC, vlocity_ins__IsSpouse__c DESC, vlocity_ins__Birthdate__c ASC
        ]);

        Map<Integer, List<Map<String, Object>>> families = new Map<Integer, List<Map<String, Object>>>();
        for (Map<String, Object> member : memberAssignment) {
            Integer familyIndex = (Integer)member.get('NUM_assignToFamily');
            if (!families.containsKey(familyIndex)) {
                families.put(familyIndex, new List<Map<String, Object>>());
            }
            families.get(familyIndex).add(member);
        }
        System.debug('families: ' + families);

        List<Integer> sortedKeys = new List<Integer>(families.keySet());
        sortedKeys.sort();
        System.debug('sortedKeys: ' + sortedKeys);

        for (Integer familyId : sortedKeys) {
            List<Map<String, Object>> family = families.get(familyId);
            System.debug('familyId: ' + familyId);

        
            // Find primary
            vlocity_ins__GroupCensusMember__c primaryMember;
            for (Map<String, Object> member : family) {
                if ((Boolean)member.get('CHK_spinOffSelection') == true || (String)member.get('TXT_ContractParticipantRelationship') == 'Primary') {
                    primaryMember = censusMembers.get((Id)member.get('TXT_GroupCensusMemberId'));
                    break;
                }
            }
            System.debug('primaryMember: ' + primaryMember);
        
            // List of census members
            List<Map<String, Object>> census_members_list = new List<Map<String, Object>>();
        
            for (Map<String, Object> member : family) {
                vlocity_ins__GroupCensusMember__c censusMember = censusMembers.get((Id)member.get('TXT_GroupCensusMemberId'));
                String relationship;
                if ((Boolean)member.get('CHK_spinOffSelection') == true) {
                    relationship = 'Primary';
                } else {
                    relationship = (String)member.get('TXT_ContractParticipantRelationship');
                } 
                Map<String, Object> census_member_map = createMemberMap(censusMember, relationship, primaryMember);
                census_members_list.add(census_member_map);
            }
            System.debug('census_members_list: ' + census_members_list);

            // Sort members
            census_members_list.sort(new CensusMemberMapComparator());
            System.debug('census_members_list sorted: ' + census_members_list);


            if (clean_output == true) {
                for (Map<String, Object> census_member_map : census_members_list) {
                    census_member_map = cleanCensusMemberMapFields(census_member_map);
                }
            }
                
        
            census_members_per_census_list.add(census_members_list);
        }

        output_map.put('census_members', census_members_per_census_list);
        System.debug('census_members: ' + census_members_per_census_list);
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
     * Creates a member map with default values and processed fields.
     * @param {vlocity_ins__GroupCensusMember__c} member - The member record.
     * @returns {Map<String,Object>} - A map representing the member.
     */
    private static Map<String, Object> createMemberMap (vlocity_ins__GroupCensusMember__c member, String relationship, vlocity_ins__GroupCensusMember__c primaryMember) {
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
        Map<String, Object> memberMap = new Map<String, Object>{
            'Id' => member.Id,
            'vlocity_ins__FirstName__c' => member.vlocity_ins__FirstName__c,
            'vlocity_ins__LastName__c' => member.vlocity_ins__LastName__c,
            'PersonAccountId' => member.vlocity_ins__ContactId__r.AccountId,
            'PersonContactId' => member.vlocity_ins__ContactId__c,
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
        system.debug('streetNumber: ' + streetNumber + ' streetName: ' + streetName);
        if (streetNumber != '' && streetName != '') {
            output_map.put('ARC_PhysicalAddressStreet__c', streetNumber + ' ' + streetName);
        } else if (streetName != '') {
            output_map.put('ARC_PhysicalAddressStreet__c', streetName);
        }
    }

    private static Set<Id> getCensusMemberIds(List<Map<String, Object>> memberAssignment) {
        Set<Id> censusMemberIds = new Set<Id>();
        for (Map<String, Object> member : memberAssignment) {
            if (member.containsKey('TXT_GroupCensusMemberId')) {
                censusMemberIds.add((Id)member.get('TXT_GroupCensusMemberId'));
            }
        }
        return censusMemberIds;
    }

    private class CensusMemberMapComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            System.debug('valor 1 a: ' + (Map<String, Object>)a.get('ARC_Relationship__c'));
            System.debug('valor 2 a: ' + (String)((Map<String, Object>)a.get('ARC_Relationship__c')).get('value'));
            String relA = (String)((Map<String, Object>)a.get('ARC_Relationship__c')).get('value');
            System.debug('valor 3 b: ' + (Map<String, Object>)b.get('ARC_Relationship__c'));
            System.debug('valor 4 b: ' + (String)((Map<String, Object>)b.get('ARC_Relationship__c')).get('value'));
            String relB = (String)((Map<String, Object>)b.get('ARC_Relationship__c')).get('value');
            Integer prioA = getPriority(relA);
            Integer prioB = getPriority(relB);
            if (prioA != prioB) {
                return prioA - prioB;
            }
            if (relA == 'Child' && relB == 'Child') {
                Date birthA = (Date)a.get('vlocity_ins__Birthdate__c');
                Date birthB = (Date)b.get('vlocity_ins__Birthdate__c');
                return birthB.daysBetween(birthA);
            }
            return 0;
        }
    
        private Integer getPriority(String rel) {
            if (rel == 'Primary') return 0;
            if (rel == 'Spouse') return 1;
            if (rel == 'Child') return 2;
            return 3;
        }
    }
}