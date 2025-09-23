public with sharing class ARC_ElegibilityFileSureCo {
    public static String generate(String stringTXT, Contract contract,vlocity_ins__ContractLineItem__c product, List<vlocity_ins__GroupCensusMember__c> members, Boolean futureCancellation, Datetime contractApprovedDate, Datetime lastPayment, ChargentOrders__ChargentOrder__c chargentOrder, Map<Id, Datetime> member_lastChange, InsurancePolicy policy, Map<Id, Set<Id>> contractMemberIds, Map<Id, Map<String, Object>> memberOldValue) {
        System.debug(contract.Id);
        System.debug(contract.ContractNumber);
        System.debug(contractMemberIds.get(contract.Id));
        
        List<Map<String,Object>> listToTXT = new List<Map<String,Object>>();
        String ansi_status = '';
        String ansi_cancelReason = '';
        Datetime cancelledTimestamp; 
        if (contract.ARC_CancellationReason__c != null) {
            ansi_cancelReason = contract.ARC_CancellationReason__c;
            if (contract.ARC_OtherCancellationReason__c != null) {
                ansi_cancelReason = ansi_cancelReason + ', ' + contract.ARC_OtherCancellationReason__c;
            }
        }

        if (contract.Status == 'Activated') {
            if (futureCancellation) {
                ansi_status = 'Future In Active';
            }else{
                ansi_status = 'Active';
            }
        }
        if (contract.Status == 'Terminated' || contract.Status == 'Voided') {
            ansi_status = 'InActive';
        }
        if (contract.Status =='Awaiting Activation') {
            ansi_status = 'Future Active';
        }
        
        if (contract.ARC_Inactive_Date__c != null) {
            cancelledTimestamp = DateTime.newInstance(contract.ARC_Inactive_Date__c.year(), contract.ARC_Inactive_Date__c.month(), contract.ARC_Inactive_Date__c.day());
        }else
        if (contract.vlocity_ins__EnrollmentEndDate__c != null) {
            cancelledTimestamp = DateTime.newInstance(contract.vlocity_ins__EnrollmentEndDate__c.year(), contract.vlocity_ins__EnrollmentEndDate__c.month(), contract.vlocity_ins__EnrollmentEndDate__c.day());
        }
                
        List<String> depsNames = new List<String>();
        Integer sequence =2;
        String strSequence = '';
        Integer primaryCount = 0;
        Integer spouceCount = 0;
        Integer childCount = 0;
        String ansi_coverageLevel = 'Individual';
        // String ansi_coverageLevel = 'Individual';
        String primaryId = '';
        for (vlocity_ins__GroupCensusMember__c member : members) {
            if(contractMemberIds.get(contract.Id) != null) {
                if ((contractMemberIds.get(contract.Id)).contains(member.Id) && isValidMember(member,contract)) {
                    if (member.vlocity_ins__IsPrimaryMember__c) {
                        primaryCount++;
                        primaryId = member.e123_member_id__c != null ? member.e123_member_id__c :member.Member_ID__c;
                    }else{
                        if (member.vlocity_ins__IsSpouse__c) {
                            spouceCount++;
                        }else{
                            childCount++;
                        }
                    }
                }
            }
            
        }
        if (primaryCount>0 && childCount > 0 && spouceCount > 0) {
            ansi_coverageLevel = 'Family';
        }else if(primaryCount>0 && childCount > 1){
            ansi_coverageLevel = 'Individual plus Child(ren)';
        }else if(primaryCount>0 && spouceCount > 0){
            ansi_coverageLevel = 'Individual plus Spouse';
        }else if(primaryCount>0 && childCount ==1){
            ansi_coverageLevel = 'Individual plus 1 Dependent';
        }

	
        for (vlocity_ins__GroupCensusMember__c member : members) {
            if(contractMemberIds.get(contract.Id) != null) {
                if ((contractMemberIds.get(contract.Id)).contains(member.Id) && isValidMember(member,contract)) {
                    Integer timesToLoop = memberOldValue.get(member.Id) != null ? 2 : 1;
                    Boolean useOldValues = false;
                    for (Integer i = 0; i < timesToLoop; i++) {
                        if (timesToLoop == 2 && i == 0 && memberOldAndNewAreTheSame(member, memberOldValue.get(member.Id))) {
                            i++;
                        }
                        if (!useOldValues || (useOldValues && ansi_status != 'InActive')) {
                            Map<String,Object> txtLine = new Map<String,Object>();
                            String memberStatus = 'InActive';
                            if (member.ARC_ActiveMember__c && contract.Status == 'Activated' && !useOldValues) {
                                memberStatus = 'Active';
                            }
                            if (member.vlocity_ins__IsPrimaryMember__c) {
                                txtLine.put('sequence_id', '1');     //sequence
                            }else {
                                if (sequence.format().length() ==1) {
                                    
                                    txtLine.put('sequence_id', String.valueOf(sequence));     //sequence
                                }else{
                                    txtLine.put('sequence_id', String.valueOf(sequence));     //sequence
                                }
                                
                                sequence++;
                            }
                            
                            String gender = '';
                            if (member.vlocity_ins__Gender__c == 'Male') {
                                gender = 'M';
                            }else if (member.vlocity_ins__Gender__c == 'Female') {
                                gender = 'F';
                            }else {
                                gender = 'O';
                            }
                
                            txtLine.put('customer_id',member.vlocity_ins__CensusId__c );
                            txtLine.put('unique_id',member.e123_member_id__c != null ? member.e123_member_id__c :member.Member_ID__c);
                            if (member.vlocity_ins__IsPrimaryMember__c) {
                                txtLine.put('primary_unique_id',member.e123_member_id__c != null ? member.e123_member_id__c :member.Member_ID__c);
                            }else {
                                txtLine.put('primary_unique_id',member.vlocity_ins__RelatedCensusMemberId__r.e123_member_id__c != null ? member.vlocity_ins__RelatedCensusMemberId__r.e123_member_id__c : member.vlocity_ins__RelatedCensusMemberId__r.Member_ID__c);
                            }
                            if(txtLine.get('primary_unique_id')==null){
                                txtLine.put('primary_unique_id', primaryId);
                            }
                            txtLine.put('firstname', getNewOrOldValue(useOldValues, member.Id, member.vlocity_ins__FirstName__c, 'vlocity_ins__FirstName__c',memberOldValue));
                            txtLine.put('middlename',member.ARC_MiddleInitial__c);
                            txtLine.put('lastname', getNewOrOldValue(useOldValues, member.Id, member.vlocity_ins__LastName__c, 'vlocity_ins__LastName__c',memberOldValue));     
                            txtLine.put('member_created_timestamp',member.CreatedDate);     
                            txtLine.put('member_updated_timestamp',member_lastChange.get(member.Id)); 
                            txtLine.put('dob', getNewOrOldValue(useOldValues, member.Id, member.vlocity_ins__Birthdate__c, 'vlocity_ins__Birthdate__c',memberOldValue));       
                            txtLine.put('address',member.ARC_PhysicalAddressStreet__c);     
                            txtLine.put('address2', '');     
                            txtLine.put('city',member.ARC_PhysicalAddressCity__c);     
                            txtLine.put('state',member.ARC_PhysicalAddressState__c);     
                            txtLine.put('zipcode',member.ARC_PhysicalAddressZipCode__c);     
                            txtLine.put('phone',member.ARC_Phone__c);     
                            txtLine.put('phone2','');     
                            txtLine.put('email',member.vlocity_ins__Email__c);     
                            txtLine.put('gender',gender);     
                            txtLine.put('ssn',getNewOrOldValue(useOldValues, member.Id, member.vlocity_ins__SocialSecurityNumber__c, 'vlocity_ins__SocialSecurityNumber__c',memberOldValue));   
                            txtLine.put('height',member.ARC_Height__c);    
                            txtLine.put('weight',member.ARC_Weight__c);    
                            if (member.vlocity_ins__IsPrimaryMember__c) {
                                txtLine.put('member_type','Primary');     
                            } else {
                                txtLine.put('member_type','Dependant');     
                            }
                            txtLine.put('relationship_to_primary',member.ARC_Relationship__c);     
                            txtLine.put('policy_number', policy?.Name); //policy    
                            if (product != null) {
                                if (product.vlocity_ins__ProductCode__c != null) {
                                    txtLine.put('product_label',product.vlocity_ins__ProductCode__c);  
                                }else {
                                    txtLine.put('product_label',null);  
                
                                }
                            }else {
                                txtLine.put('product_label',null);  
                
                            }
                            txtLine.put('product_created_timestamp',contract.CreatedDate);     
                            txtLine.put('product_cancelled_timestamp',cancelledTimestamp);  
                            txtLine.put('product_effective_timestamp',contract.ARC_EffectiveDate__c);   
                            txtLine.put('policy_status',useOldValues ? 'InActive' : ansi_status);   
                            txtLine.put('coverage_type',ansi_coverageLevel);    
                            txtLine.put('product_unique_id',contract.ContractNumber);    
                            txtLine.put('policy_billing_date', lastPayment != null ? lastPayment : null);    //the same as the through date ????? 
                            txtLine.put('policy_paid_through_date',lastPayment != null ? lastPayment.addMonths(1) : null);
                            txtLine.put('policy_cancel_reason',ansi_cancelReason);    
                            txtLine.put('policy_hold_date',null);     //hold 
                            txtLine.put('policy_hold_reason',null);     //hold 
                            txtLine.put('policy_hold_type',null);     //hold 
                            txtLine.put('policy_hold_flag',null);     //hold 
                            txtLine.put('policy_fulfillment_date',contractApprovedDate);    
                            txtLine.put('policy_renewal_date',null);     //RENEWAL 
                            
                            if (chargentOrder != null) {
                                if (chargentOrder.ChargentOrders__Next_Transaction_Date__c != null) {
                                    txtLine.put('policy_recurring_date',chargentOrder.ChargentOrders__Next_Transaction_Date__c);     
                                }else {
                                    txtLine.put('policy_recurring_date',null);     
                                }
                            }else {
                                System.debug('chargentOrder is null');
                                txtLine.put('policy_recurring_date',null);    
                            }
                            txtLine.put('member_status',memberStatus);     
                            
                            listToTXT.add(txtLine);
                            useOldValues = true;
                        }
                    }
                }
            }
        }

        for (Map<String,Object> txtLine : listToTXT) {
            String customer_id = '';
            String unique_id = '';
            String primary_unique_id = '';
            String firstname = '';
            String middlename = '';
            String lastname = '';
            Datetime member_created_timestamp;
            Datetime member_updated_timestamp;
            Date dob;
            String address = '';
            String address2 = '';
            String city = '';
            String state = '';
            String zipcode = '';
            String phone = '';
            String phone2 = '';
            String email = '';
            String gender = '';
            String ssn = '';
            String member_type = '';
            String relationship_to_primary = '';
            String policy_number = '';
            String product_label = '';
            Datetime product_created_timestamp;
            // Datetime product_cancelled_timestamp;
            Object product_cancelled_timestamp = '';
            Datetime product_effective_timestamp;
            String policy_status = '';
            String coverage_type = '';
            String product_unique_id = '';
            String policy_billing_date = '';
            String policy_paid_through_date  = '';
            String policy_cancel_reason = '';
            String policy_hold_date = '';
            String policy_hold_reason = '';
            String policy_hold_type = '';
            String policy_fulfillment_date = '';
            String policy_renewal_date = '';
            String policy_recurring_date  = '';
            String policy_hold_flag = '';
            String sequence_id  = '';
            String member_status = '';
            String height = '';	
            String weight = '';

            if (txtLine.get('customer_id')!=null) {
                customer_id = (String)txtLine.get('customer_id');
            }
            if (txtLine.get('unique_id')!=null) {
                unique_id = (String)txtLine.get('unique_id');
            }
            if (txtLine.get('primary_unique_id')!=null) {
                primary_unique_id = (String)txtLine.get('primary_unique_id');
            }
            if (txtLine.get('firstname')!=null) {
                firstname = (String)txtLine.get('firstname');
            }
            if (txtLine.get('middlename')!=null) {
                middlename = (String)txtLine.get('middlename');
            }
            if (txtLine.get('lastname')!=null) {
                lastname = (String)txtLine.get('lastname');
            }
            if (txtLine.get('member_created_timestamp')!=null) {
                member_created_timestamp = (Datetime)txtLine.get('member_created_timestamp');
            }
            if (txtLine.get('member_updated_timestamp')!=null) {
                member_updated_timestamp = (Datetime)txtLine.get('member_updated_timestamp');
            }
            if (txtLine.get('dob')!=null) {
                dob = (Date)txtLine.get('dob');
            }
            if (txtLine.get('address')!=null) {
                address = (String)txtLine.get('address');
            }
            if (txtLine.get('address2')!=null) {
                address2 = (String)txtLine.get('address2');
            }
            if (txtLine.get('city')!=null) {
                city = (String)txtLine.get('city');
            }
            if (txtLine.get('state')!=null) {
                state = (String)txtLine.get('state');
            }
            if (txtLine.get('zipcode')!=null) {
                zipcode = (String)txtLine.get('zipcode');
            }
            if (txtLine.get('phone')!=null) {
                phone = (String)txtLine.get('phone');
            }
            if (txtLine.get('phone2')!=null) {
                phone2 = (String)txtLine.get('phone2');
            }
            if (txtLine.get('email')!=null) {
                email = (String)txtLine.get('email');
            }
            if (txtLine.get('gender')!=null) {
                gender = (String)txtLine.get('gender');
            }
            if (txtLine.get('ssn')!=null) {
                ssn = (String)txtLine.get('ssn');
            }
            if (txtLine.get('member_type')!=null) {
                member_type = (String)txtLine.get('member_type');
            }
            if (txtLine.get('relationship_to_primary')!=null) {
                relationship_to_primary = (String)txtLine.get('relationship_to_primary');
            }
            if (txtLine.get('policy_number')!=null) {
                policy_number = (String)txtLine.get('policy_number');
            }
            if (txtLine.get('product_label')!=null) {
                product_label = (String)txtLine.get('product_label');
            }
            if (txtLine.get('product_created_timestamp')!=null) {
                product_created_timestamp = (Datetime)txtLine.get('product_created_timestamp');
            }
            if (txtLine.get('product_cancelled_timestamp')!=null) {
                product_cancelled_timestamp = (Datetime)txtLine.get('product_cancelled_timestamp');
            }
            if (txtLine.get('product_effective_timestamp')!=null) {
                product_effective_timestamp = (Datetime)txtLine.get('product_effective_timestamp');
            }
            if (txtLine.get('policy_status')!=null) {
                policy_status = (String)txtLine.get('policy_status');
            }
            if (txtLine.get('coverage_type')!=null) {
                coverage_type = (String)txtLine.get('coverage_type');
            }
            if (txtLine.get('product_unique_id')!=null) {
                product_unique_id = (String)txtLine.get('product_unique_id');
            }
            if (txtLine.get('policy_billing_date')!=null) {
                policy_billing_date = formatDate((Datetime)txtLine.get('policy_billing_date'));
            }
            if (txtLine.get('policy_paid_through_date')!=null) {
                policy_paid_through_date = formatDate((Datetime)txtLine.get('policy_paid_through_date'));
            }
            if (txtLine.get('policy_cancel_reason')!=null) {
                policy_cancel_reason = (String)txtLine.get('policy_cancel_reason');
            }
            if (txtLine.get('policy_hold_date')!=null) {
                policy_hold_date = (String)txtLine.get('policy_hold_date');
            }
            if (txtLine.get('policy_hold_reason')!=null) {
                policy_hold_reason = (String)txtLine.get('policy_hold_reason');
            }
            if (txtLine.get('policy_hold_type')!=null) {
                policy_hold_type = (String)txtLine.get('policy_hold_type');
            }
            if (txtLine.get('policy_fulfillment_date')!=null) {
                policy_fulfillment_date = formatDate((Datetime)txtLine.get('policy_fulfillment_date'));
            }
            if (txtLine.get('policy_renewal_date')!=null) {
                policy_renewal_date = (String)txtLine.get('policy_renewal_date');
            }
            if (txtLine.get('policy_recurring_date')!=null) {
                policy_recurring_date = formatDate((Datetime)txtLine.get('policy_recurring_date'));
            }
            if (txtLine.get('policy_hold_flag')!=null) {
                policy_hold_flag = (String)txtLine.get('policy_hold_flag');
            }
            if (txtLine.get('sequence_id')!=null) {
                sequence_id = (String)txtLine.get('sequence_id');
            }
            if (txtLine.get('member_status')!=null) {
                member_status = (String)txtLine.get('member_status');
            }
            if (txtLine.get('height')!=null) {
                height = (String)txtLine.get('height');
            }
            if (txtLine.get('weight')!=null) {
                weight = (String)txtLine.get('weight');
            }
            

            stringTXT = stringTXT 
                + '\n"' + customer_id + '","' 
                + unique_id + '","' 
                + primary_unique_id + '","' 
                + firstname + '","' 
                + middlename + '","' 
                + lastname + '","' 
                + member_created_timestamp + '","' 
                + member_updated_timestamp + '","' 
                + dob + '","' 
                + address + '","' 
                + address2 + '","' 
                + city + '","' 
                + state + '","' 
                + zipcode + '","' 
                + phone + '","' 
                + phone2 + '","' 
                + email + '","' 
                + gender + '","' 
                + ssn + '","' 
                + member_type + '","' 
                + relationship_to_primary + '","' 
                + policy_number + '","' 
                + product_label + '","' 
                + product_created_timestamp + '","' 
                + product_cancelled_timestamp + '","' 
                + product_effective_timestamp + '","' 
                + policy_status + '","' 
                + coverage_type + '","' 
                + product_unique_id + '","' 
                + policy_billing_date + '","' 
                + policy_paid_through_date + '","' 
                + policy_cancel_reason + '","' 
                + policy_hold_date + '","' 
                + policy_hold_reason + '","' 
                + policy_hold_type + '","' 
                + policy_fulfillment_date + '","' 
                + policy_renewal_date + '","' 
                + policy_recurring_date + '","' 
                + policy_hold_flag + '","' 
                + sequence_id + '","' 
                + member_status+ '","' 
                + height+ '","' 
                + weight+ '"'; 
        }
                        
                    
                    

        
        return stringTXT;
    
    }


    public static String formatDate(Datetime d){
        if (d != null) {
            String day = String.valueOf(d.day());
            if (day.length()==1) {
                day = '0'+day;
            }
            String month = String.valueOf(d.month());
            if (month.length()==1) {
                month = '0'+month;
            }
            return month +'-'+ day+'-'+d.year();
        }else{
            return '';
        }
    }

    private static Object getNewOrOldValue(Boolean useOldValues, Id memberId, Object newValue, String fieldName, Map<Id, Map<String, Object>> memberOldValues){
        return useOldValues ? ((memberOldValues.get(memberId)).get(fieldName) != null ? (memberOldValues.get(memberId)).get(fieldName) : newValue) : newValue;
    }

    private static Boolean memberOldAndNewAreTheSame(vlocity_ins__GroupCensusMember__c member, Map<String, Object> oldValues){
        if(
            (member.vlocity_ins__FirstName__c == oldValues.get('vlocity_ins__FirstName__c') || oldValues.get('vlocity_ins__FirstName__c') == null) &&
            (member.vlocity_ins__LastName__c == oldValues.get('vlocity_ins__LastName__c') || oldValues.get('vlocity_ins__LastName__c') == null) &&
            (member.vlocity_ins__Birthdate__c == oldValues.get('vlocity_ins__Birthdate__c') || oldValues.get('vlocity_ins__Birthdate__c') == null) &&
            (member.vlocity_ins__SocialSecurityNumber__c == oldValues.get('vlocity_ins__SocialSecurityNumber__c') || oldValues.get('vlocity_ins__SocialSecurityNumber__c') == null)
        ){
            return true;
        }else{
            return false;
        }
    }

    private static Boolean isValidMember(vlocity_ins__GroupCensusMember__c member, Contract contract){
        Boolean validMember = true;
        if (!member.ARC_ActiveMember__c && contract.Status=='Activated') {
            validMember = false;
        }
        // if(member.ARC_ActiveMember__c  && contract.Status=='Terminated'){
        //     validMember = false;
        // }
        return validMember;
    }
}