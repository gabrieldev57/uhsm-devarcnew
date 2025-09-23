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
        return true;
    }

    /*******************************************************************
    * @MethodName         :   insertExternalInsurance
    * @Description        :   Creates the External Insurance Policy and External Insurance Policy Members with the inputs from Step Current Coverage in Enroll
    ********************************************************************/
    public void insertExternalInsurance(Map<String,Object> input, Map < String, Object > outMap, Map < String, Object > options) {
        if(input.get('externalInsurance') != null && input.get('externalInsurance') != '') {
            Map<String,Id> externalInsuranceIdMap = new Map<String,Id>();
            // Map<String,Object>  membersInputMap = (Map<String,Object>)input.get('externalInsurance');
            List<Object> insurerInformationList = (List<Object>) input.get('externalInsurance');
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
                                    extInsPolMembersToCreate.add(exInMember);
                                }
                            }
                            if(extInsPolMembersToCreate.size()>0) insert extInsPolMembersToCreate;
                        }
                    }
                    catch(Exception e){
                        System.debug('Exception in ARC_ExternalInsurerStep.insertExternalInsurance: '+e.getMessage());
                    }
                }
            }
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