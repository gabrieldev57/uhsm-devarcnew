public with sharing class ARC_UHSMFulfillment {
    public static String generate(String stringTXT, 
                                  Contract contract,
                                  vlocity_ins__ContractLineItem__c medicalProduct, 
                                  List<vlocity_ins__GroupCensusMember__c> members,
                                  String smartCode,
                                  String aiddCode,
                                  String AMCS) {
        ////System.debug('generar');
        List<Map<String,Object>> listToTXT = new List<Map<String,Object>>();
        // Map<String, Object> productAttributes = (Map<String, Object>)JSON.deserializeUntyped(medicalProduct.vlocity_ins__Product2Id__r.vlocity_ins__AttributeDefaultValues__c);
        // System.debug(productAttributes);
        Map<String, Object> productAttributes = new Map<String, Object>();
        String copay_primary_specialist = '';
        String IndividualDollarAmount = '';
        String FamilyDollarAmount = '';

        if (medicalProduct.vlocity_ins__Product2Id__r.vlocity_ins__AttributeDefaultValues__c != null) {
            productAttributes = (Map<String, Object>)JSON.deserializeUntyped(medicalProduct.vlocity_ins__Product2Id__r.vlocity_ins__AttributeDefaultValues__c);
        }
        if (productAttributes.get('individualAMCS')!= null) {
            IndividualDollarAmount = ((Integer)productAttributes.get('individualAMCS')).format();
        }else {
            AMCS = AMCS.replaceAll('[^0-9]', '');
            IndividualDollarAmount = Integer.valueOf(AMCS).format();
        }
        if (productAttributes.get('familyAMCS')!= null) {
            FamilyDollarAmount = ((Integer)productAttributes.get('familyAMCS')).format();
        }else {
            if (medicalProduct.vlocity_ins__Product2Id__r.ProductCode.contains('Legacy')){
                FamilyDollarAmount = '0';
            }else{
                System.debug('DEBUG: AMCS '+AMCS);
                AMCS = AMCS.replaceAll('[^0-9]', '');
                FamilyDollarAmount = Integer.valueOf(AMCS).format();
            }
        }
        
        List<String> depsNames = new List<String>();
        Map<String,Object> txtLine = new Map<String,Object>();
    
        txtLine.put('E DATE',contract.ARC_EffectiveDate__c.format());
        txtLine.put('PLANID',medicalProduct.vlocity_ins__Product2Id__r.ProductCode);
		if (medicalProduct.vlocity_ins__Product2Id__r.ProductCode.contains('Legacy')){
        	txtLine.put('GROUPCODE','UHSMDVL');                          
        } else {
            txtLine.put('GROUPCODE','UHSMDV');   
        }
        txtLine.put('Smart',smartCode);
        txtLine.put('Aidd',aiddCode);
        ////System.debug(members);
        if (members!= null && members.size() > 0){
            for (vlocity_ins__GroupCensusMember__c member : members) {
                ////System.debug(member.Name);
                ////System.debug(member.vlocity_ins__CensusId__c == contract.vlocity_ins__EnrollmentCensusId__c);
                if (member.vlocity_ins__CensusId__c == contract.vlocity_ins__EnrollmentCensusId__c) {
                    if (member.vlocity_ins__IsPrimaryMember__c) {
                        txtLine.put('IND', IndividualDollarAmount);
                        txtLine.put('FAM', FamilyDollarAmount);
                        txtLine.put('MEMBER ID',member.e123_member_id_from_policy__c != null ? member.e123_member_id_from_policy__c : member.Member_ID__c);
                        txtLine.put('EMPLOYEE NAME',member.Name);
                        txtLine.put('ADDR1',member.ARC_PhysicalAddressStreet__c);
                        txtLine.put('CITY',member.ARC_PhysicalAddressCity__c);
                        txtLine.put('STATE',member.ARC_PhysicalAddressState__c);
                        txtLine.put('ZIP',member.ARC_PhysicalAddressZipCode__c);     
                    }else{
                        depsNames.add(member.Name);
                    }                           
                }
            }
        }
        for (Integer i = 0; i < depsNames.size(); i++) {
            txtLine.put('DEP NAME'+(i+1), depsNames[i]);
        }

        try {
            String ind = ''; 
            String fam = ''; 
            String employeeName = ''; 
            String memberId = ''; 
            String planId = '';
            String groupCode = '';
            String smart = '';
            string aidd = '';
            String effDate = ''; 
            String city = ''; 
            String state = ''; 
            String street = ''; 
            String zip = ''; 
            String depName1 = '';  
            String depName2 = ''; 
            String depName3 = ''; 
            String depName4 = ''; 
            String depName5 = ''; 
            String depName6 = ''; 
            String depName7 = ''; 
            String depName8 = ''; 
            String welcomeKit = '';
            if (txtLine.get('IND') != null) {
                ind = ((String)txtLine.get('IND')).toUpperCase();
            }
            if (txtLine.get('FAM') != null) {
                fam = ((String)txtLine.get('FAM')).toUpperCase();
            }
            if (txtLine.get('EMPLOYEE NAME') != null) {
                employeeName = ((String)txtLine.get('EMPLOYEE NAME'));
            }
            if (txtLine.get('MEMBER ID') != null) {
                memberId = ((String)txtLine.get('MEMBER ID')).toUpperCase();
            }
            if (txtLine.get('PLANID') != null) {
                planId = ((String)txtLine.get('PLANID')).toUpperCase();
            }
            if (txtLine.get('GROUPCODE') != null) {
                groupCode = ((String)txtLine.get('GROUPCODE')).toUpperCase();
            }
            if (txtLine.get('Smart') != null) {
                smart = ((String)txtLine.get('Smart')).toUpperCase();
            }
            if (txtLine.get('Aidd') != null) {
                aidd = ((String)txtLine.get('Aidd')).toUpperCase();
            }
            if (txtLine.get('E DATE') != null) {
                effDate = ((String)txtLine.get('E DATE')).toUpperCase();
            }
            if (txtLine.get('CITY') != null) {
                city = ((String)txtLine.get('CITY')).toUpperCase();
            }
            if (txtLine.get('STATE') != null) {
                state = ((String)txtLine.get('STATE')).toUpperCase();
            }
            if (txtLine.get('ADDR1') != null) {
                street = ((String)txtLine.get('ADDR1')).toUpperCase();
            }
            if (txtLine.get('ZIP') != null) {
                zip = ((String)txtLine.get('ZIP')).toUpperCase();
            }
            if (txtLine.get('DEP NAME1') != null) {
                depName1 = ((String)txtLine.get('DEP NAME1'));
            }
            if (txtLine.get('DEP NAME2') != null) {
                depName2 = ((String)txtLine.get('DEP NAME2'));
            }
            if (txtLine.get('DEP NAME3') != null) {
                depName3 = ((String)txtLine.get('DEP NAME3'));
            }
            if (txtLine.get('DEP NAME4') != null) {
                depName4 = ((String)txtLine.get('DEP NAME4'));
            }
            if (txtLine.get('DEP NAME5') != null) {
                depName5 = ((String)txtLine.get('DEP NAME5'));
            }
            if (txtLine.get('DEP NAME6') != null) {
                depName6 = ((String)txtLine.get('DEP NAME6'));
            }
            if (txtLine.get('DEP NAME7') != null) {
                depName7 = ((String)txtLine.get('DEP NAME7'));
            }
            if (txtLine.get('DEP NAME8') != null) {
                depName8 = ((String)txtLine.get('DEP NAME8'));
            }
            // if(sendWelcomeKit){
            //     welcomeKit = 'Y';
            // }else{
            //     welcomeKit = 'N';
            // }
            ////System.debug(employeeName);
            if (employeeName != null && employeeName.length() > 0) {
                String toAppend =  '\n' +ind+'|'+fam+'|'+employeeName+'|'+memberId+'|'+copay_primary_specialist+'|'+copay_primary_specialist+'|'+'|'+planId+'|'+groupCode+'|'+smart+'|'+aidd+'|'+effDate+'|'+street+'| |'+city+'|'+state+'|'+zip+'|'+depName1+'|'+depName2+'|'+depName3+'|'+depName4+'|'+depName5+'|'+depName6+'|'+depName7+'|'+depName8;
                stringTXT = stringTXT + toAppend; 
            }
        } catch (Exception e) {
            ////System.debug('member sin primary: '+((String)txtLine.get('MEMBER ID')));
        }
        
        return stringTXT;
    }
}