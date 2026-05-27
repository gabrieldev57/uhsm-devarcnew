/*******************************************************************
* @ClassName          :   ARC_ExternalInsurerStep
* @Description        :   Logic that supports the Enroll process for the Current Coverage Step. 
* @MethodName         :   insertExternalInsurance, formatDate
********************************************************************/

global without sharing class ARC_ExternalInsurerStep implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map < String, Object > input, Map < String, Object > outMap, Map < String, Object > options) {
        if (methodName.equals('insertExternalInsurance')) {
            insertExternalInsurance(input, outMap, options);
        } 
        else if (methodName.equals('flagOpenSMBsForExtInsurance')) {
            flagOpenSMBsForExtInsurance(input, outMap, options);
        } 
        return true;
    }

    /*******************************************************************
    * @MethodName         :   insertExternalInsurance
    * @Description        :   Creates the External Insurance Policy and External Insurance Policy Members with the inputs from Step Current Coverage in Enroll
                                Update 29-10-25 : Now also links the External Insurance Policy Members to the Person Account if Person Account Id is provided in input map (for Account360 view scenarios)
                                Update 10-03-26 : returns P.Insurance-Members and P.Insurances (for Account360 view scenarios)
    ********************************************************************/
    public void insertExternalInsurance(Map<String,Object> input, Map < String, Object > outMap, Map < String, Object > options) {
        if(input.get('externalInsurance') != null && input.get('externalInsurance') != '') {
            Map<String,Id> externalInsuranceIdMap = new Map<String,Id>();
            // Map<String,Object>  membersInputMap = (Map<String,Object>)input.get('externalInsurance');
            List<Object> insurerInformationList = (List<Object>) input.get('externalInsurance');
            
            Map<String, String> censusMemberAccountMap = new Map<String, String>();
            if(input.containsKey('familyMembersList')){
                System.debug('FAMILY MEMBERS FOUND: ' + (List<Object>) input.get('familyMembersList'));
                List<Object> familyMembersList  = (List<Object>)input.get('familyMembersList');
                for(Object member : familyMembersList){
                    Map<String, Object> memberInfoMap = (Map<String, Object>) member;
                    censusMemberAccountMap.put(String.valueOf(memberInfoMap.get('Census_Member__c')), String.valueOf(memberInfoMap.get('PersonAccountId')));
                }
            }else{
                System.debug('does not contain person account ID');
            }
            
            System.debug('insurerInformationList: '+insurerInformationList);
            if(insurerInformationList.size()>0){
                List<ARC_ExternalInsurancePolicy__c> externalInsurancePolicies = new List<ARC_ExternalInsurancePolicy__c>();
                Map<String,String> policyNumberExInsPolIdMap = new  Map<String,String>();
                Map<String,List<String>> policyNumberExInsMemberIdMap = new Map<String,List<String>>();
                
                for(Object insurerInfo : insurerInformationList){
                    Map<String, Object> insurerInfoMap = (Map<String, Object>) insurerInfo;
                    ARC_ExternalInsurancePolicy__c externalInsurancePolicy = new ARC_ExternalInsurancePolicy__c();    
                    // Populate fields based on the map data
                    externalInsurancePolicy.ARC_EffectiveDate__c = formatDate((String)insurerInfoMap.get('effectiveDate'));
                    externalInsurancePolicy.ARC_ExpirationDate__c = formatDate((String)insurerInfoMap.get('expirationDate'));
                    externalInsurancePolicy.ARC_SourceOfCoverage__c = (String) insurerInfoMap.get('sourceOfCoverage');
                    externalInsurancePolicy.ARC_InsurerPhone__c = (String) insurerInfoMap.get('insurerPhone');
                    externalInsurancePolicy.ARC_InsurerName__c = (String) insurerInfoMap.get('insurer');
                    externalInsurancePolicy.ARC_PolicyNumber__c = (String) insurerInfoMap.get('policyNumber');
                    policyNumberExInsPolIdMap.put(externalInsurancePolicy.ARC_PolicyNumber__c, String.valueOf(insurerInfoMap.get('id')));
                    List<Object> exInsuranceMembers = (List<Object>) insurerInfoMap.get('policyMembers');
                    for(Object member:exInsuranceMembers){
                        Map<String, Object> memberInfoMap = (Map<String, Object>) member;
                        if(policyNumberExInsMemberIdMap.get(externalInsurancePolicy.ARC_PolicyNumber__c) == null) policyNumberExInsMemberIdMap.put(externalInsurancePolicy.ARC_PolicyNumber__c, new List<String>{(String)memberInfoMap.get('id')});
                        else {
                            List<String> membersList =(List<String>)policyNumberExInsMemberIdMap.get(externalInsurancePolicy.ARC_PolicyNumber__c);
                            membersList.add((String)memberInfoMap.get('id'));
                            policyNumberExInsMemberIdMap.put(externalInsurancePolicy.ARC_PolicyNumber__c, membersList);
                        }
                    }
                    externalInsurancePolicies.add(externalInsurancePolicy);
                }
                
                if(externalInsurancePolicies?.size() > 0) {
                    try{
                        insert externalInsurancePolicies;
                        for(ARC_ExternalInsurancePolicy__c eip: externalInsurancePolicies){
                            if(policyNumberExInsPolIdMap.get(eip.ARC_PolicyNumber__c)!= null){
                                policyNumberExInsPolIdMap.put(eip.ARC_PolicyNumber__c,eip.Id);
                            }
                        }
                        if(externalInsurancePolicies.size()>0){
                            List<ARC_ExternalInsurancePolicyMember__c> extInsPolMembersToCreate = new List<ARC_ExternalInsurancePolicyMember__c>();
                            for (String policyNumber : policyNumberExInsMemberIdMap.keySet()) {
                                List<String> memberIds = policyNumberExInsMemberIdMap.get(policyNumber);
                                for (String memberId : memberIds) {
                                    ARC_ExternalInsurancePolicyMember__c exInMember = new ARC_ExternalInsurancePolicyMember__c();
                                    exInMember.ARC_CensusMember__c=(Id)memberId;
                                    exInMember.ARC_ExternalInsurancePolicy__c=(Id)policyNumberExInsPolIdMap.get(policyNumber);
                                    
                                    
                                    if (censusMemberAccountMap.containsKey(String.valueOf(memberId))){
                                        Id personAccountId = censusMemberAccountMap.get(String.valueOf(memberId));
                                        system.debug('Setting person account ID on external insurance member: ' + personAccountId);
                                        exInMember.ARC_PersonAccount__c = personAccountId;
                                    }else {
                                        System.debug('Person account ID is null, not setting on external insurance member.');
                                    }
                                    
                                    extInsPolMembersToCreate.add(exInMember);
                                }
                            }
                            if(extInsPolMembersToCreate.size()>0) insert extInsPolMembersToCreate;
                            System.debug('Inserted External Insurance Policy Members successfully> ');
                            System.debug(extInsPolMembersToCreate);
                            outMap.put('externalInsurance', externalInsurancePolicies);
                            outMap.put('externalInsuranceMembers', extInsPolMembersToCreate);
                        }
                    }
                    catch(Exception e){
                        System.debug('Exception in ARC_ExternalInsurerStep.insertExternalInsurance: '+e.getMessage());
                    }
                }
            }
        }else{
            System.debug('No external insurance data found in input map.');
        }
    }

    /*******************************************************************
    * @MethodName         :   flagOpenSMBsForExtInsurance
    * @Description        :   Flags SMBs for which External Insurance is active at DOS
    * @Input        :   List<Object> externalInsuranceMembers, List<Object> externalInsurance
    * @Update        :   23/03/2026 - Flag goes for Closed SMBs as well.
    ********************************************************************/
    public void flagOpenSMBsForExtInsurance(Map<String,Object> input, Map<String,Object> outMap, Map<String,Object> options){

        List<Object> externalInsuranceMembers = (List<Object>) input.get('externalInsuranceMembers');
        List<Object> externalInsurance = (List<Object>) input.get('externalInsurance');

        // 1. Index externalInsurance by Id
        Map<String, Map<String,Object>> extPoliciesById = new Map<String, Map<String,Object>>();
        for(Object pol : externalInsurance){
            Map<String,Object> policyMap = (Map<String,Object>) pol;
            extPoliciesById.put((String)policyMap.get('Id'), policyMap);
        }

        // 2. Build memberCoverageRanges
        Map<String, List<Date[]>> memberCoverageRanges = new Map<String, List<Date[]>>();

        for(Object memb : externalInsuranceMembers){
            Map<String,Object> memberInfoMap = (Map<String,Object>) memb;

            String personAccountId = (String) memberInfoMap.get('ARC_PersonAccount__c');
            String extPolicyId = (String) memberInfoMap.get('ARC_ExternalInsurancePolicy__c');

            if(extPoliciesById.containsKey(extPolicyId)){
                Map<String,Object> policy = extPoliciesById.get(extPolicyId);

                Date startDate = Date.valueOf((String)policy.get('ARC_EffectiveDate__c'));
                Date endDate   = policy.get('ARC_ExpirationDate__c') != null ? Date.valueOf((String)policy.get('ARC_ExpirationDate__c')) : null;

                if(!memberCoverageRanges.containsKey(personAccountId)){
                    memberCoverageRanges.put(personAccountId, new List<Date[]>());
                }

                memberCoverageRanges.get(personAccountId).add(new Date[]{startDate, endDate});
            }
        }

        System.debug('memberCoverageRanges: ' + memberCoverageRanges);

        // 3. Query Claims
        List<Claim> claimsToUpdate = new List<Claim>();

        List<Claim> claims = [
            SELECT Id, ARC_DOSFrom__c, ARC_MemberContact__r.AccountId, ARC_PrimaryInsurance__c
            FROM Claim
            WHERE ARC_MemberContact__r.AccountId IN :memberCoverageRanges.keySet()
            AND Status NOT IN ('Voided') 
        ];

        System.debug('claims: ' + claims);
        for(Claim cl : claims){
            String memberAccountId = cl.ARC_MemberContact__r.AccountId;

            if(memberCoverageRanges.containsKey(memberAccountId)){
                for(Date[] range : memberCoverageRanges.get(memberAccountId)){

                    Date startDate = range[0];
                    Date endDate = range[1];

                    if(cl.ARC_DOSFrom__c != null &&
                    cl.ARC_DOSFrom__c >= startDate &&
                    (endDate == null || cl.ARC_DOSFrom__c <= endDate)){

                        cl.ARC_PrimaryInsurance__c = 'With Primary Insurance';
                        claimsToUpdate.add(cl);
                        break;
                    }
                }
            }
        }

        if(!claimsToUpdate.isEmpty()){
            update claimsToUpdate;
        }
    }



    /*******************************************************************
    * @MethodName         :   formatDate
    * @Description        :   Return a date instance from a string with this format MM/DD/YYYY
    ********************************************************************/
    public static Date formatDate(String dateInput){
        if (dateInput == null || dateInput == '') return null; // Handle null or empty input gracefully
        // Split the input date string into day, month, and year parts
        List<String> dateParts = dateInput.split('/');
        if (dateParts.size() != 3) return null; // Invalid input format
        Integer year = Integer.valueOf(dateParts[2]);
        Integer month = Integer.valueOf(dateParts[0]);
        Integer day = Integer.valueOf(dateParts[1]);
        // Format the date in the desired format
        Date formattedDate = date.newInstance(year, month, day);
        return formattedDate;
    }


}