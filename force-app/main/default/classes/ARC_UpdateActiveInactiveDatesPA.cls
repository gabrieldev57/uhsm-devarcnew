/*******************************************************************
* @ClassName          :   ARC_UpdateActiveInactiveDatesPA
* @Description        :   Prepares the members data that will be sent to aRC_MembersWithPlansTablePA 
* @MethodName         :   calculateDatesPerMemberAndProgram, existGap
********************************************************************/

public without sharing class ARC_UpdateActiveInactiveDatesPA {
    
    @AuraEnabled(cacheable=true)
    public static List<Map<Id, Object>> calculateDatesPerMemberAndProgram( Id idFromMember) {
        Set<Id> contractsInvolved = new Set<Id>();

        String personFilter;
        if(idFromMember.getSobjectType().getDescribe().getName() == 'vlocity_ins__GroupCensusMember__c'){	
            personFilter = 'vlocity_ins__GroupCensusMemberId__c =\''+idFromMember+'\'';
        }else 
        if(idFromMember.getSobjectType().getDescribe().getName() == 'Account'){	
            personFilter = 'vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId = \''+idFromMember+'\'';
        }
       
//vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Temperory_Newborn__c
        //Get All the Medical GCMP of current member 
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToCm = Database.query(
            'SELECT Id,'+
            'vlocity_ins__ContractLineId__c, '+
            'vlocity_ins__GroupCensusMemberId__c,' +
            'vlocity_ins__GroupCensusMemberId__r.ARC_OldCensusMember__c,' +
            'vlocity_ins__GroupCensusMemberId__r.ARC_NewCensusMember__c,'+
            'vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c, '+
            'vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status,' +
            'vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,'+
            'vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId,'+
            'vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Temperory_Newborn__c '+
            'FROM vlocity_ins__GroupCensusMemberPlan__c ' +
            'WHERE '+personFilter+' '+
            'AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = \'Medical\' '+
            'AND ('+
                'vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Activated\' '+
                'OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Terminated\' '+
                'OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Awaiting Activation\' '+
                ')'
        );

        //Get Contracts Ids WHERE current member is involved
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : gcmpRelatedToCm) {
            contractsInvolved.add(gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c);
        }

        //Get all GCMP 
        List<vlocity_ins__GroupCensusMemberPlan__c> censusMembesrGroups = [
            SELECT Id,
			ARC_Active__c,
            vlocity_ins__ContractLineId__c, 
            vlocity_ins__GroupCensusMemberId__c, 
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Temperory_Newborn__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c, 
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c, 
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status, 
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Name,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.ARC_IsPrimaryMember__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.PersonEmail,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.PersonBirthdate,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.vlocity_ins__SocialSecurityNumber__pc,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.vlocity_ins__Age__pc,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.IsActive,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.ARC_DependentRelationship__c,       
            vlocity_ins__GroupCensusMemberId__r.ARC_NewCensusMember__c, 
            vlocity_ins__GroupCensusMemberId__r.ARC_OldCensusMember__c, 
            vlocity_ins__ContractLineId__r.Name 
            FROM vlocity_ins__GroupCensusMemberPlan__c 
            WHERE (
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c IN :contractsInvolved 
                AND (
                    vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated' 
                    OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Terminated'
                    OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Awaiting Activation')
                )
            ORDER BY vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c ASC, CreatedDate ASC];

        
        Map<Id, Object> accountsAndPlans = new  Map<Id, Object>();
        Set<Id> activeAccounts = new Set<Id>();
        Map<Id, Object> finalMemberAndPlans = new  Map<Id, Object>();
        Map<Id, Object> finalAccountsAndPlans = new  Map<Id, Object>();


        for (vlocity_ins__GroupCensusMemberPlan__c plan : censusMembesrGroups) {
            Id accountId = plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId;

            if (accountsAndPlans.containsKey(accountId)) {
                List<vlocity_ins__GroupCensusMemberPlan__c> plans = (List<vlocity_ins__GroupCensusMemberPlan__c>) accountsAndPlans.get(accountId);
                plans.add(plan);
                accountsAndPlans.put(accountId, plans);
            }
            else{
                List<vlocity_ins__GroupCensusMemberPlan__c> plans = new  List<vlocity_ins__GroupCensusMemberPlan__c>();
                plans.add(plan);
                accountsAndPlans.put(accountId, plans);
            }
            if (plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Activated' ){
                activeAccounts.add(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId);
            }
        }

        //Map of GCMP Initial Dates
        Map<Id, Object> groupMemberPlanInitialDate = new Map<Id, Object>();
        //Map of GCMP End Date
        Map<Id, Object> groupMemberPlanEndDate = new Map<Id, Object>();
        //Never Active Set 
        Set<Id> neverActiveMembers = new Set<Id>();

        //Iterate Map of Member -> Group Census Member Plan to separte by plan type and calculate Initial and End Dates 
        for (Id key : accountsAndPlans.keySet()) {
            List<vlocity_ins__GroupCensusMemberPlan__c> medicals = new List<vlocity_ins__GroupCensusMemberPlan__c>();
            List<vlocity_ins__GroupCensusMemberPlan__c> medicalReversed = new List<vlocity_ins__GroupCensusMemberPlan__c>();
            List<vlocity_ins__GroupCensusMemberPlan__c> smarts = new List<vlocity_ins__GroupCensusMemberPlan__c>();
            List<vlocity_ins__GroupCensusMemberPlan__c> smartsReversed = new List<vlocity_ins__GroupCensusMemberPlan__c>();
            List<vlocity_ins__GroupCensusMemberPlan__c> aidds = new List<vlocity_ins__GroupCensusMemberPlan__c>();
            List<vlocity_ins__GroupCensusMemberPlan__c> aiddsReversed = new List<vlocity_ins__GroupCensusMemberPlan__c>();

            List<vlocity_ins__GroupCensusMemberPlan__c> plans = (List<vlocity_ins__GroupCensusMemberPlan__c>)accountsAndPlans.get(key);
            
            //Separte by plan type of a member
            for (vlocity_ins__GroupCensusMemberPlan__c plan : plans) {
             
                if (plan.vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c == 'Medical'){
                    medicals.add(plan);
                }
                if (plan.vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c == 'SMART' ){
                    smarts.add(plan);
                }
                if (plan.vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c == 'AIDD' ){
                    aidds.add(plan);
                }
            }

            //Create reversed lists
            for(Integer i = medicals.size() - 1; i >= 0; i--){
                medicalReversed.add(medicals[i]);
            }
            for(Integer i = smarts.size() - 1; i >= 0; i--){
                smartsReversed.add(smarts[i]);
            }
            for(Integer i = aidds.size() - 1; i >= 0; i--){
                aiddsReversed.add(aidds[i]);
            }
           
            //Iterate over Medicals and calculate Initial Dates
            Id prevMedicalProduct = null;
            Id prevMedicalPlan = null;
            Date prevInactiveDate = null;
            Date prevEffectiveDate = null;
            Boolean neverActive = true;


         
            for (vlocity_ins__GroupCensusMemberPlan__c medPlan : medicals){ 

                if (prevMedicalProduct == null){
                    prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                    prevMedicalPlan = medPlan.Id;
                    prevInactiveDate= medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;
                    
                    Date effDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                    groupMemberPlanInitialDate.put(medPlan.Id, effDate);
                }

                else if (prevMedicalProduct != null && prevMedicalProduct ==  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c){
                    Date effDateCurrent = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                    
                    if (prevInactiveDate!= null && effDateCurrent != null && existGap(prevInactiveDate, effDateCurrent)) {
                        groupMemberPlanInitialDate.put(medPlan.Id, effDateCurrent);  
                    }
                    else{
                        Date initialDate = (Date)groupMemberPlanInitialDate.get(prevMedicalPlan);
                        groupMemberPlanInitialDate.put(medPlan.Id, initialDate);
                    }
                    prevMedicalPlan = medPlan.Id;
                    prevInactiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;   
                   
                }

                else if (prevMedicalProduct != null && prevMedicalProduct !=  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c) {
                    Date initialDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                    groupMemberPlanInitialDate.put(medPlan.Id, initialDate);
                    prevMedicalPlan = medPlan.Id;
                    prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                    prevInactiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;  
                }
            }

            //Calculate End Dates 
            prevMedicalProduct = null;
            prevMedicalPlan = null;
            prevInactiveDate = null;
            //Iterate over Medicals reversed to calculate End Dates

            for (vlocity_ins__GroupCensusMemberPlan__c medPlan : medicalReversed) {
         

                if (prevMedicalPlan == null){
                    Date endDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c; 
                    groupMemberPlanEndDate.put(medPlan.Id, endDate);
                    prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                    prevMedicalPlan = medPlan.Id;
                    prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                }
               
                else if (prevMedicalPlan != null && prevMedicalProduct ==  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c){
           
                    
                    Date inactiveDateCurrent= medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;

                    if(prevEffectiveDate != null && inactiveDateCurrent !=null && existGap(inactiveDateCurrent, prevEffectiveDate)){
                        groupMemberPlanEndDate.put(medPlan.Id, inactiveDateCurrent);
                        prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                        prevMedicalPlan = medPlan.Id;
                        prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                    }
                    else{
                        Date endDatePrevious= (Date)groupMemberPlanEndDate.get(prevMedicalPlan);
                        groupMemberPlanEndDate.put(medPlan.Id, endDatePrevious);
                        prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                        prevMedicalPlan = medPlan.Id;
                        prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                    }
                }
                else if (prevMedicalPlan != null && prevMedicalProduct !=  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c) {

                    groupMemberPlanEndDate.put(medPlan.Id, medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c);
                    prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                    prevMedicalPlan = medPlan.Id;
                    prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                }

            }

            //Iterate on SMARTS 

            //Iterate over Medicals and calculate Initial Dates
            prevMedicalProduct = null;
            prevMedicalPlan = null;
            prevInactiveDate = null;
            prevEffectiveDate = null;
  
              for (vlocity_ins__GroupCensusMemberPlan__c medPlan : smarts){ 
                  
                  if (prevMedicalProduct == null){
                      prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                      prevMedicalPlan = medPlan.Id;
                      prevInactiveDate= medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;
                      
                      Date effDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      groupMemberPlanInitialDate.put(medPlan.Id, effDate);
                  }
  
                  else if (prevMedicalProduct != null && prevMedicalProduct ==  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c){
  
                      Date effDateCurrent = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      
                      if (prevInactiveDate!= null && effDateCurrent != null && existGap(prevInactiveDate, effDateCurrent)) {
                          groupMemberPlanInitialDate.put(medPlan.Id, effDateCurrent);  
                      }
                      else{
                          Date initialDate = (Date)groupMemberPlanInitialDate.get(prevMedicalPlan);
                          groupMemberPlanInitialDate.put(medPlan.Id, initialDate);
                      }
                      prevMedicalPlan = medPlan.Id;
                      prevInactiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;   
                     
                  }
  
                  else if (prevMedicalProduct != null && prevMedicalProduct !=  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c) {
                      Date initialDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      groupMemberPlanInitialDate.put(medPlan.Id, initialDate);
                      prevMedicalPlan = medPlan.Id;
                      prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                      prevInactiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;  
                  }
              }
  
              //Calculate End Dates 
              prevMedicalProduct = null;
              prevMedicalPlan = null;
              prevInactiveDate = null;
              //Iterate over Medicals reversed to calculate End Dates
  
              for (vlocity_ins__GroupCensusMemberPlan__c medPlan : smartsReversed) {
           
  
                  if (prevMedicalPlan == null){
                      Date endDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c; 
                      groupMemberPlanEndDate.put(medPlan.Id, endDate);
                      prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                      prevMedicalPlan = medPlan.Id;
                      prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                  }
                  
                 
                  else if (prevMedicalPlan != null && prevMedicalProduct ==  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c){
             
                      
                      Date inactiveDateCurrent= medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;
  
                      if(prevEffectiveDate != null && inactiveDateCurrent !=null && existGap(inactiveDateCurrent, prevEffectiveDate)){
                          groupMemberPlanEndDate.put(medPlan.Id, inactiveDateCurrent);
                          prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                          prevMedicalPlan = medPlan.Id;
                          prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      }
                      else{
                          Date endDatePrevious= (Date)groupMemberPlanEndDate.get(prevMedicalPlan);
                          groupMemberPlanEndDate.put(medPlan.Id, endDatePrevious);
                          prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                          prevMedicalPlan = medPlan.Id;
                          prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      }
                  }
                  else if (prevMedicalPlan != null && prevMedicalProduct !=  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c) {
  
                      groupMemberPlanEndDate.put(medPlan.Id, medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c);
                      prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                      prevMedicalPlan = medPlan.Id;
                      prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                  }
                  
              }

              //Iterate on AIDDS

            //Iterate over Medicals and calculate Initial Dates
            prevMedicalProduct = null;
            prevMedicalPlan = null;
            prevInactiveDate = null;
            prevEffectiveDate = null;
  
              for (vlocity_ins__GroupCensusMemberPlan__c medPlan : aidds){ 
                  
                  if (prevMedicalProduct == null){
                      prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                      prevMedicalPlan = medPlan.Id;
                      prevInactiveDate= medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;
                      
                      Date effDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      groupMemberPlanInitialDate.put(medPlan.Id, effDate);
                  }
  
                  else if (prevMedicalProduct != null && prevMedicalProduct ==  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c){
  
                      Date effDateCurrent = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      
                      if (prevInactiveDate!= null && effDateCurrent != null && existGap(prevInactiveDate, effDateCurrent)) {
                          groupMemberPlanInitialDate.put(medPlan.Id, effDateCurrent);  
                      }
                      else{
                          Date initialDate = (Date)groupMemberPlanInitialDate.get(prevMedicalPlan);
                          groupMemberPlanInitialDate.put(medPlan.Id, initialDate);
                      }
                      prevMedicalPlan = medPlan.Id;
                      prevInactiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;   
                     
                  }
  
                  else if (prevMedicalProduct != null && prevMedicalProduct !=  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c) {
                      Date initialDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      groupMemberPlanInitialDate.put(medPlan.Id, initialDate);
                      prevMedicalPlan = medPlan.Id;
                      prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                      prevInactiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;  
                  }
              }
  
              //Calculate End Dates 
              prevMedicalProduct = null;
              prevMedicalPlan = null;
              prevInactiveDate = null;
              //Iterate over Medicals reversed to calculate End Dates
  
              for (vlocity_ins__GroupCensusMemberPlan__c medPlan : aiddsReversed) {
           
  
                  if (prevMedicalPlan == null){
                      Date endDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c; 
                      groupMemberPlanEndDate.put(medPlan.Id, endDate);
                      prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                      prevMedicalPlan = medPlan.Id;
                      prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                  }
                 
                  else if (prevMedicalPlan != null && prevMedicalProduct ==  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c){
             
                      
                      Date inactiveDateCurrent= medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c;
  
                      if(prevEffectiveDate != null && inactiveDateCurrent !=null && existGap(inactiveDateCurrent, prevEffectiveDate)){
                          groupMemberPlanEndDate.put(medPlan.Id, inactiveDateCurrent);
                          prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                          prevMedicalPlan = medPlan.Id;
                          prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      }
                      else{
                          Date endDatePrevious= (Date)groupMemberPlanEndDate.get(prevMedicalPlan);
                          groupMemberPlanEndDate.put(medPlan.Id, endDatePrevious);
                          prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                          prevMedicalPlan = medPlan.Id;
                          prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                      }
                  }
                  else if (prevMedicalPlan != null && prevMedicalProduct !=  medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c) {
  
                      groupMemberPlanEndDate.put(medPlan.Id, medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c);
                      prevMedicalProduct = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                      prevMedicalPlan = medPlan.Id;
                      prevEffectiveDate = medPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                  }
  
              }

                //Order list of member plans by program type
                if (medicals!=null && !medicals.isEmpty()){
                    medicals.addAll(smarts);
                    medicals.addAll(aidds);
                    finalMemberAndPlans.put(key, medicals);
                }
        }
        
        
        //Removing dups
        for (Id key : finalMemberAndPlans.keySet()) {
            List<vlocity_ins__GroupCensusMemberPlan__c> plans = (List<vlocity_ins__GroupCensusMemberPlan__c>)finalMemberAndPlans.get(key);
            Id prevProduct= null;
            Date prevactiveDate= null;
            for(Integer i = (plans.size()-1) ; i>= 0 ; i--) {
                vlocity_ins__GroupCensusMemberPlan__c plan = plans[i];
                if (!activeAccounts.contains(key)) {
                    plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.IsActive = false;
                    plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.ARC_DependentRelationship__c = '';
                }
                if (activeAccounts.contains(key) && plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.ARC_IsPrimaryMember__c) {
                    plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.ARC_DependentRelationship__c = 'Primary';
                }
                if (prevProduct != null) {
                    Date currentActiveDate= (Date)groupMemberPlanInitialDate.get(plan.Id);
                    if ( plan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c == prevProduct && currentActiveDate == prevactiveDate){
                        plans.remove(i);
                    }
                    prevProduct= plan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                    prevactiveDate = currentActiveDate;
                }
                else{
                    prevProduct = plan.vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c;
                    Date planActiveDate = (Date)groupMemberPlanInitialDate.get(plan.Id);
                    prevactiveDate = planActiveDate;
                 }
        
            }

           
         
            finalMemberAndPlans.put(key, plans);
        }


        //Fixing maps in case of null dates 
        for (Id key : groupMemberPlanEndDate.keySet()) {    
            Object endDatePlan = groupMemberPlanEndDate.get(key);
            if (endDatePlan == null) {
                groupMemberPlanEndDate.put(key, '');
            }
        }
        for (Id key : groupMemberPlanInitialDate.keySet()) {    
            Object initialDatePlan = groupMemberPlanInitialDate.get(key);
            if (initialDatePlan == null) {
                groupMemberPlanInitialDate.put(key, '');
            }
        }

        //Prepating return of method 
        List <Map<Id, Object>> finalListOfMaps = new List <Map<Id, Object>>();
        finalListOfMaps.add(finalMemberAndPlans);
        finalListOfMaps.add(groupMemberPlanInitialDate);
        finalListOfMaps.add(groupMemberPlanEndDate);

        return finalListOfMaps;
    }

    public static Boolean existGap(Date inactiveDate, Date effectiveDate) {
        Integer numberDaysDue = inactiveDate.daysBetween(effectiveDate);
        return numberDaysDue > 3;
    }   


}