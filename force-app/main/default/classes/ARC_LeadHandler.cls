/*******************************************************************
* @ClassName          :   ARC_LeadHandler
* @Description        :   Handles the Leads changes in the self-enrollment flow. 
* @MethodName         :   qualifyLead, getCreateLeadAndLeadSource, populateAccoutnOnLead, updateLeadStatusUC 
********************************************************************/

global without sharing class ARC_LeadHandler implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'qualifyLead') {
            qualifyLead(inputMap, outputMap, options);
        }
        if (methodName == 'getCreateLeadAndLeadSource') {
            getCreateLeadAndLeadSource(inputMap, outputMap, options);
        }
        if (methodName == 'populateAccoutnOnLead') {
            populateAccoutnOnLead(inputMap, outputMap, options);
        }
        if (methodName == 'getCreateLeadSourceReferral'){
            getCreateLeadSourceReferral(inputMap, outputMap, options); 
        }
        return true;
    }

    /*******************************************************************
    * @MethodName         :   qualifyLead
    * @Description        :   Moves the status of the Lead Source related Lead to Qualified. 
    ********************************************************************/
    public static void qualifyLead(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        String userEmail = String.valueOf(inputMap.get('userEmail')).replaceAll('[()]', '');
        String userPhone = String.valueOf(inputMap.get('userPhone'));
        if(userEmail != null && userPhone != null){
            List<Lead_Source__c> leadSource = [SELECT Id, Lead__c FROM Lead_Source__c WHERE Source_Name__c = 'Self Enroll' AND Lead_Email__c =: userEmail AND Lead_Phone__c = :userPhone ORDER BY CreatedDate DESC LIMIT 1];
            if(leadSource.size()>0){
                Lead leadRecord = new Lead(Id = leadSource[0].Lead__c, Status = 'Qualified');
                try{
                    update leadRecord;
                    outputMap.put('success',true);
                    System.debug('Lead Updated');

                }
                catch(Exception e){
                    outputMap.put('success',false);
                    System.debug('Exception in ARC_LeadHandler.qualifyLead: '+e.getMessage());
                }
            }
        }
    }


    /*******************************************************************
    * @MethodName         :   getCreateLeadAndLeadSource
    * @Description        :   Creates/Updates the Lead and LeadSoruce for Self Enrollment and returns the LeadId and LeadSourceId to the OS JSON.
    ********************************************************************/
    public static void getCreateLeadAndLeadSource(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Id inputLeadId;
        if(String.isNotBlank(String.valueOf(inputMap.get('leadId')))) inputLeadId = (Id)inputMap.get('leadId');
        String inputEmail = (String)inputMap.get('email');
        String inputPhone = (String)inputMap.get('phone');
        Id leadRecordId; 
        List<Lead> leadRecords = new List<Lead>();
        try{
            if(inputLeadId != null) leadRecords = [SELECT Id, FirstName, LastName, Phone, Email  FROM Lead WHERE Id =: inputLeadId];
            else if(String.isNotBlank(inputEmail) && String.isNotBlank(inputPhone)){
                leadRecords = [SELECT Id, FirstName, LastName, Phone, Email  FROM Lead WHERE Phone_Digits__c =: inputPhone AND Email =: inputEmail LIMIT 1];
                if(leadRecords.size()==0) leadRecords = [SELECT Id, FirstName, LastName, Phone, Email FROM Lead WHERE Phone_Digits__c =: inputPhone OR Phone =: inputPhone OR Email =: inputEmail LIMIT 1];
            }
            if(leadRecords.size()==0){
                Lead newLead = new Lead();
                newLead.HealthCloudGA__BirthDate__c = Date.valueOf(String.valueOf(inputMap.get('birthdate')));
                newLead.City = (String)inputMap.get('city');
                newLead.Email = (String)inputMap.get('email');
                newLead.FirstName = (String)inputMap.get('firstName');
                newLead.HealthCloudGA__Gender__c = (String)inputMap.get('gender');
                newLead.LastName = (String)inputMap.get('lastName');
                newLead.Phone = (String)inputMap.get('phone');
                newLead.State = (String) inputMap.get('state');
                newLead.Street = (String) inputMap.get('street');
                newLead.PostalCode = (String) inputMap.get('zipCode');
                newLead.Status = 'Self Enrolling';
                newLead.LeadSource = 'Self Enroll';
                insert newLead;
                leadRecordId= newLead.Id;
            }
            else leadRecordId = leadRecords[0].Id;
            Lead_Source__c leadSource = new Lead_Source__c();
            leadSource.Lead_Address_City__c = (String)inputMap.get('city');
            leadSource.Lead_Email__c = (String)inputMap.get('email');
            leadSource.Lead_First_Name__c = (String)inputMap.get('firstName');
            leadSource.Lead_Last_Name__c = (String)inputMap.get('lastName');
            leadSource.Lead__c = leadRecordId;
            if(String.isNotBlank(String.valueOf(inputMap.get('leadSourceId')))) leadSource.Id = (Id)inputMap.get('leadSourceId');
            leadSource.Lead_Phone__c = (String)inputMap.get('phone');
            leadSource.Source_Name__c = 'Self Enroll';
            leadSource.Lead_Address_Zip__c = (String)inputMap.get('zipCode');
            leadSource.Lead_Address_Street__c = (String)inputMap.get('street');
            leadSource.Lead_Address_State__c = (String)inputMap.get('state');
            leadSource.LeadsRX_Id__c = (String)inputMap.get('cookieId');
            upsert leadSource;
            outputMap.put('LeadId',leadRecordId);
            outputMap.put('LeadSourceId',leadSource.Id);
            outputMap.put('success',true);

        }catch(Exception e){
             outputMap.put('success',false);
        }
    }
    
    /*******************************************************************
    * @MethodName         :   getCreateLeadSourceReferral
    * @Description        :   Creates an additional LeadSource for Self Enrollment (referrals) and returns ReferralLeadSourceId to the OS JSON.
    ********************************************************************/
    public static void getCreateLeadSourceReferral(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Id inputLeadId;
        if(String.isNotBlank(String.valueOf(inputMap.get('leadId')))) inputLeadId = (Id)inputMap.get('leadId');
        String inputEmail = (String)inputMap.get('email');
        String inputPhone = (String)inputMap.get('phone');
        Id leadRecordId; 
        List<Lead> leadRecords = new List<Lead>();
        try{
            if(inputLeadId != null) leadRecords = [SELECT Id, FirstName, LastName, Phone, Email  FROM Lead WHERE Id =: inputLeadId];
            else if(String.isNotBlank(inputEmail) && String.isNotBlank(inputPhone)){
                leadRecords = [SELECT Id, FirstName, LastName, Phone, Email  FROM Lead WHERE Phone_Digits__c =: inputPhone AND Email =: inputEmail LIMIT 1];
                if(leadRecords.size()==0) leadRecords = [SELECT Id, FirstName, LastName, Phone, Email FROM Lead WHERE Phone_Digits__c =: inputPhone OR Phone =: inputPhone OR Email =: inputEmail LIMIT 1];
            }
            if (leadRecords.size()!=0){
                leadRecordId = leadRecords[0].Id;
            }
            Lead_Source__c leadSource = new Lead_Source__c();
            leadSource.Lead_Address_City__c = (String)inputMap.get('city');
            leadSource.Lead_Email__c = (String)inputMap.get('email');
            leadSource.Lead_First_Name__c = (String)inputMap.get('firstName');
            leadSource.Lead_Last_Name__c = (String)inputMap.get('lastName');
            leadSource.Lead__c = leadRecordId;
            leadSource.Lead_Phone__c = (String)inputMap.get('phone');
            leadSource.Source_Name__c = 'Referral';
            leadSource.Lead_Address_Zip__c = (String)inputMap.get('zipCode');
            leadSource.Lead_Address_Street__c = (String)inputMap.get('street');
            leadSource.Lead_Address_State__c = (String)inputMap.get('state');
            leadSource.LeadsRX_Id__c = (String)inputMap.get('cookieId');
            leadSource.Referrer_Account__c = (String)inputMap.get('referral');
            insert leadSource;
            outputMap.put('ReferralLeadSourceId',leadSource.Id);
            outputMap.put('success',true);

        }catch(Exception e){
            System.debug('Exception in getCreateLeadSourceReferral: ' + e.getMessage()); 
             outputMap.put('success',false);
        }
    }


    /*******************************************************************
    * @MethodName         :   populateAccoutnOnLead
    * @Description        :   Populates the Account__c field in the Lead 
    ********************************************************************/
    public static void populateAccoutnOnLead(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        String primaryAccountId = String.valueOf(inputMap.get('primaryAccountId'));
        String leadId = String.valueOf(inputMap.get('leadId'));
        if(primaryAccountId != null){
            Lead leadToUpdate = null;
            if(!String.isBlank(leadId)){
                leadToUpdate = [SELECT Id, Account__c FROM Lead WHERE Id=: leadId];
            }else{
                Account primAccount = [SELECT Id, Name, Phone,PersonEmail, vlocity_ins__Email__c FROM Account WHERE Id=:primaryAccountId LIMIT 1];
                List<Lead> leads = [SELECT Id, Phone, Email, Account__c FROM Lead WHERE (Phone = :primAccount.Phone OR Email = :primAccount.PersonEmail OR Email = :primAccount.vlocity_ins__Email__c) ORDER BY CreatedDate DESC LIMIT 100];
                if (!leads.isEmpty()) {
                    if(leads.size()==1){
                        leadToUpdate=leads[0];
                    } else {
                        Integer maxCoincidences = 0;
                        for (Lead lead : leads) {
                            Integer coincidences = 0;
                            if (primAccount.Phone != null && primAccount.Phone.equals(lead.Phone)) {
                                coincidences++;
                            }
            
                            if (primAccount.PersonEmail != null && primAccount.PersonEmail.equals(lead.Email)) {
                                coincidences++;
                            }
            
                            if (primAccount.vlocity_ins__Email__c != null && primAccount.vlocity_ins__Email__c.equals(lead.Email)) {
                                coincidences++;
                            }
            
                            // Update leadToUpdate if it has more coincidences
                            if (coincidences > maxCoincidences) {
                                maxCoincidences = coincidences;
                                leadToUpdate = lead;
                            }
                        }
                    }
                }
            }
            if(leadToUpdate!=null){
                leadToUpdate.Account__c = primaryAccountId;
                try{
                    update leadToUpdate;
                    outputMap.put('success',true);
                    System.debug('Lead Updated');
    
                }
                catch(Exception e){
                    outputMap.put('success',false);
                    System.debug('Exception in ARC_LeadHandler.qualifyLead: '+e.getMessage());
                }
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   updateLeadStatusUC
    * @Description        :   Converts the lead into a Person Account, so set the lead Status to Converted and populates some Lead fields. It is called from "Update Last Status Update Of UW Case" Flow.
    ********************************************************************/
    @InvocableMethod
    public static void updateLeadStatusUC(List<Id> leadIds) {
        List<Lead> leads = [SELECT Id, IsConverted, OwnerId, Owner.IsActive, ConvertedAccountId,ConvertedContactId, ConvertedDate,Account__c, Status, Account__r.OwnerId, Owner.Type FROM Lead WHERE Id IN : leadIds AND IsConverted = FALSE];

        if(leads.size()>0){
            List<User> integrationUser = [SELECT Id FROM User WHERE Name = 'Integration User' LIMIT 1];
            if(integrationUser.size() > 0){
                Boolean unableOwner = false;
                for(Lead myLead: leads){
                    if(myLead.Owner.Type != 'User' || (myLead.Owner.Type == 'User' && myLead.Owner.IsActive == false)){
                        myLead.OwnerId = integrationUser[0].Id;
                        unableOwner = true;
                    }
                }
                if(unableOwner) update leads;
            }      
            Database.LeadConvert[] leadConverts = new List<Database.LeadConvert>();
            for(Lead myLead: leads){
                Database.LeadConvert lc = new database.LeadConvert();
                lc.setLeadId(myLead.id);
                lc.setConvertedStatus('Converted');
                lc.setAccountId(myLead.Account__c);
                lc.setDoNotCreateOpportunity(true);
                leadConverts.add(lc);
            }
            Database.LeadConvertResult[] lcrs = Database.convertLead(leadConverts);
        }
    }

}