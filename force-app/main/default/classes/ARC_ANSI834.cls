public with sharing class ARC_ANSI834 {
    public Integer segments = 0;
    public String generate(Contract contract,vlocity_ins__ContractLineItem__c plan,List<vlocity_ins__GroupCensusMember__c> members,AggregateResult transa, Date approvedDate, String type) {
        List<String> ANSI_membersData = new List<String>();
        List<vlocity_ins__GroupCensusMember__c> membersOldSSN = new List<vlocity_ins__GroupCensusMember__c>();
        Integer primaryCount = 0;
        Integer childCount = 0;
        Integer spouceCount = 0;
        String ansi_lastTransactionDate = '';

        if ( transa != null ) {
            ansi_lastTransactionDate = formatDate(date.newinstance(((Datetime)transa.get('transactionDate')).year(), ((Datetime)transa.get('transactionDate')).month(),((Datetime)transa.get('transactionDate')).day()) );

        }

        String ansi_coverageLevel = 'EMP';
        String ansi_medicalProduct = plan.vlocity_ins__ProductCode__c.toUpperCase();
        String ansi_memberPhone = '*';
        String ansi_memberEmail = '*';

        for (vlocity_ins__GroupCensusMember__c member : members) {
            if (member.vlocity_ins__CensusId__c == contract.vlocity_ins__EnrollmentCensusId__c && isValidMember(member)) {
                if (member.vlocity_ins__IsPrimaryMember__c) {
                    primaryCount++;
                    ansi_memberPhone = 'TE*' + member.ARC_Phone__c;
                    ansi_memberEmail = 'EM*' + member.vlocity_ins__Email__c;
                }else{
                    if (member.vlocity_ins__IsSpouse__c) {
                        spouceCount++;
                    }else{
                        childCount++;
                    }
                }
            }
        }

        if (primaryCount>0 && childCount > 0 && spouceCount > 0) {
            ansi_coverageLevel = 'FAM';
        }else if(primaryCount>0 && childCount > 1){
            ansi_coverageLevel = 'ECH';
        }else if(primaryCount>0 && spouceCount > 0){
            ansi_coverageLevel = 'ESP';
        }else if(primaryCount>0 && childCount ==1){
            ansi_coverageLevel = 'E1D';
        }

        for (vlocity_ins__GroupCensusMember__c member : members) {
            if (member.vlocity_ins__CensusId__c == contract.vlocity_ins__EnrollmentCensusId__c && isValidMember(member)) {
                
                String ansi_memberId = '';
                String ansi_address = '';
                String ansi_city = '';
                String ansi_state = '';
                String ansi_zip = '';
                String ansi_memberBdate = '';
                String ansi_gender = '';
                String ansi_effDate = '';
                String ansi_approvedDate = '';
                String ansi_SSN = ''; 
                String ansi_memberTypeLet = '';
                String ansi_memberTypeNum = '';
                String ansi_memberLName = '';
                String ansi_memberFName = '';

                //Member Id
                    if (member.vlocity_ins__IsPrimaryMember__c) {
                        if ( member.e123_member_id__c != null ) {
                            ansi_memberId = member.e123_member_id__c;
                        }else if ( member.Member_ID__c != null ) {
                            ansi_memberId = member.Member_ID__c;
                        }
                    } else {
                        if ( member.vlocity_ins__RelatedCensusMemberId__r.e123_member_id__c != null ) {
                            ansi_memberId = member.vlocity_ins__RelatedCensusMemberId__r.e123_member_id__c;
                        } else if ( member.vlocity_ins__RelatedCensusMemberId__r.Member_ID__c != null ) {
                            ansi_memberId = member.vlocity_ins__RelatedCensusMemberId__r.Member_ID__c;
                        }
                    }
                
                //Address
                    if ( member.ARC_PhysicalAddressStreet__c != null) {
                        ansi_address = member.ARC_PhysicalAddressStreet__c.toUpperCase();
                    }
                    if (member.ARC_PhysicalAddressCity__c  != null) {
                        ansi_city = member.ARC_PhysicalAddressCity__c.toUpperCase();
                    }
                    if ( member.ARC_PhysicalAddressState__c != null) {
                        ansi_state = member.ARC_PhysicalAddressState__c.toUpperCase();
                    }
                    if (member.ARC_PhysicalAddressZipCode__c  != null) {
                        ansi_zip = member.ARC_PhysicalAddressZipCode__c.toUpperCase();
                    }

                //Birthdate
                    if (member.vlocity_ins__Birthdate__c  != null) {
                        ansi_memberBdate = formatDate(member.vlocity_ins__Birthdate__c);
                    }

                //Gender
                    if (member.vlocity_ins__Gender__c == 'Female') {
                        ansi_gender = 'F';
                    }else if(member.vlocity_ins__Gender__c =='Male'){
                        ansi_gender = 'M';
                    }

                //Effective Date
                    if ( contract.ARC_EffectiveDate__c  != null) {
                        ansi_effDate = formatDate(contract.ARC_EffectiveDate__c);
                    }

                //Approved Date
                    if ( approvedDate != null) {
                        ansi_approvedDate = formatDate(approvedDate);
                    }
                
                //Social Security Number
                    if ( member.vlocity_ins__SocialSecurityNumber__c  != null && ( member.vlocity_ins__SocialSecurityNumber__c != member.ARC_OldSSN__c && member.ARC_OldSSN__c != null ) ) {
                        ansi_SSN = '34*' + member.vlocity_ins__SocialSecurityNumber__c; 
                        membersOldSSN.add(member);
                    }

                //Name
                    if (member.vlocity_ins__LastName__c  != null) {
                        ansi_memberLName = member.vlocity_ins__LastName__c.toUpperCase();
                    }
                    if (  member.vlocity_ins__FirstName__c != null) {
                        ansi_memberFName = member.vlocity_ins__FirstName__c.toUpperCase();
                    }

                //Member Type Identifiers
                    if (member.vlocity_ins__IsPrimaryMember__c) {
                        ansi_memberTypeLet = 'Y';
                        ansi_memberTypeNum = '18';
                    }else{
                        ansi_memberTypeLet = 'N';
                        if (member.vlocity_ins__IsSpouse__c) {
                            ansi_memberTypeNum = '01';
                        }else{
                            ansi_memberTypeNum = '19';
                        }
                    }

                
                String ansi_ins = 'INS*'+ansi_memberTypeLet+'*'+ansi_memberTypeNum+'*030*XN*A***FT~\n';
                String ansi_ref0f = 'REF*0F*'+removeHyphens(ansi_memberId)+'~\n';
                String ansi_ref1l = 'REF*1L*UHSM~\n';
                String ansi_dtp336 = ansi_effDate != '' ? 'DTP*336*D8*'+ansi_effDate+'~\n' : '';
                String ansi_dtp356 = ansi_approvedDate != '' ? 'DTP*356*D8*'+ansi_approvedDate+'~\n' : '';
                String ansi_dtp357 = ansi_lastTransactionDate != '' ? 'DTP*357*D8*'+ansi_lastTransactionDate+'~\n' : '';
                String ansi_nm1 = 'NM1*IL*1*'+removeHyphens(ansi_memberLName)+'*'+removeHyphens(ansi_memberFName)+'****'+ansi_SSN+'~\n';
                String ansi_n3 = 'N3*'+removeHyphens(ansi_address)+'~\n';
                String ansi_n4 = 'N4*'+removeHyphens(ansi_city)+'*'+removeHyphens(ansi_state)+'*'+removeHyphens(ansi_zip)+'~\n';
                String ansi_dmg8 = 'DMG*D8*'+ansi_memberBdate+'*'+ansi_gender+'~\n';
                String ansi_hd = 'HD*030**HLT**'+ansi_coverageLevel+'~\n';
                String ansi_dtp348 = 'DTP*348*D8*'+ansi_effDate+'~\n';
                String ansi_refzz = 'REF*ZZ*'+removeHyphens(ansi_medicalProduct)+'~\n';

                ANSI_membersData.add(
                    ansi_ins + 
                    ansi_ref0f + 
                    ansi_ref1l + 
                    ansi_dtp336 + 
                    ansi_dtp356 + 
                    ansi_dtp357 + 
                    ansi_nm1 + 
                    ansi_n3 + 
                    ansi_n4 + 
                    ansi_dmg8 + 
                    ansi_hd + 
                    ansi_dtp348 + 
                    ansi_refzz
                );
                segments += 10;
                if (ansi_dtp336!='') {
                    segments ++;
                }
                if (ansi_dtp356!='') {
                    segments ++;
                }
                if (ansi_dtp357!='') {
                    segments ++;
                }
            }
        }
        String ANSI_stringTXT = '';
        for (String ANSI_stringPart : ANSI_membersData) {
            ANSI_stringTXT = ANSI_stringTXT + ANSI_stringPart;
        }
        ARC_ANSI834.updateMembersOldSSN(membersOldSSN);
        return removeAccents(ANSI_stringTXT);
    }

    public static String close(String members, Integer segments, Decimal transactionId){

        String isa13 = formatTransactionId(transactionId);
        String gs04 = Datetime.now().format('YYYYMMdd', 'America/Los_Angeles');
        String gs05 = Datetime.now().format('HHmm', 'America/Los_Angeles');
        String gs06 = isa13.substring(isa13.length() - 3);
        //Header
        String ansi834 = 'ISA*00*11111     *00*22222     *ZZ*364948535      *ZZ*311407689      *221227*1050*^*00501*'+isa13+'*0*P*:~\n'+
                        'GS*BE*71-0847266*311407689*'+gs04+'*'+gs05+'*'+gs06+'*X*005010X220A1~\n'+
                        'ST*834*0001*005010X220A1~\n'+
                        'BGN*00*000000001*20221227*1050*UT***4~\n'+
                        'N1*P5*UHSM*FI*71-0847266~\n'+
                        'N1*IN*Unite Health Share Ministries*FI*71-0847266~\n'+
                        'N1*TV*UHSM*FI*71-0847266~\n'; 
        //Content
        ansi834 += members;

        //Footer
        ansi834 +=  'SE*'+segments+'*0001~\n'+
                    'GE*1*'+gs06+'~\n'+
                    'IEA*1*'+isa13+'~\n'; 

        return ansi834;
    }


    public static String formatDate(Date d){
        if (d != null) {
            String day = String.valueOf(d.day());
            if (day.length()==1) {
                day = '0'+day;
            }
            String month = String.valueOf(d.month());
            if (month.length()==1) {
                month = '0'+month;
            }
            return d.year() + month + day;
        }else{
            return '22222222';
        }
    }

    public static void updateMembersOldSSN(List<vlocity_ins__GroupCensusMember__c> membersList) {
        try {
            List<vlocity_ins__GroupCensusMember__c> membersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();
            for ( vlocity_ins__GroupCensusMember__c m : membersList ) {
                vlocity_ins__GroupCensusMember__c updatedMember = new vlocity_ins__GroupCensusMember__c();
                updatedMember.Id = m.Id;
                updatedMember.ARC_OldSSN__c = m.vlocity_ins__SocialSecurityNumber__c;
                membersToUpdate.add(updatedMember);
            }
            Database.update(membersToUpdate, false);
        } catch (Exception e) {}
    }

    private static String removeAccents(String toClean) {
        String wAccent = 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġȑȒȓȔȕȗȘș';
        String woAccent = 'AAAAAAACEEEEIIIIDNOOOOOOUUUUYBaaaaaaaceeeeiiiionoooooouuuuybyAaAaAaCcCcCcCcDdDdEeEeEeEeEeGgGgGgrRrUuuSs';

        Integer letters = wAccent.length();
        String str = toClean;
        for (Integer i = 0; i < letters; i++) {
            str = str.replaceAll(wAccent.substring(i, i+1), woAccent.substring(i, i+1));
        }
        return str;
    }

    private static String removeHyphens(String toClean) {
        String str = toClean.replaceAll('-','');
        return str;
    }


    private static String formatTransactionId(Decimal transactionId){
        return String.valueOf(transactionId).leftPad(9, '0');
    }

    private static Boolean isValidMember(vlocity_ins__GroupCensusMember__c member){
        Boolean isValid = false;
        if(member.vlocity_ins__IsPrimaryMember__c == false && member.vlocity_ins__RelatedCensusMemberId__c != null){
            isValid = true;
        }
        if(member.vlocity_ins__IsPrimaryMember__c == true && member.vlocity_ins__RelatedCensusMemberId__c == null){
            isValid = true;
        }
        return isValid;
    }
}