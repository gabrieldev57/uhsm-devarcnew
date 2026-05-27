/*******************************************************************
* @ClassName          :   ARC_PersonAccount360view
* @Description        :   Provides the information presented in the component of the 360 view of Person Account. 
* @MethodName         :   getPersonAccountDetails360FlexCard, stampPersonAccountInSpinOffMembers, getSSNDescrypted, lastDateOfMonth
********************************************************************/

global without sharing class ARC_PersonAccount360view implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'getPersonAccountDetails360FlexCard') {
            getPersonAccountDetails360FlexCard(inputMap, outputMap, options);
        }
        else if (methodName == 'stampPersonAccountInSpinOffMembers') {
            stampPersonAccountInSpinOffMembers(inputMap, outputMap, options);
        }
        return true;
    }

    /*******************************************************************
    * @MethodName         :   getPersonAccountDetails360FlexCard
    * @Description        :   Get the census member linked to the Person Account, contracts, underwriting case, hippa and return the information to be displayed in the component. 
    ********************************************************************/
    public static void getPersonAccountDetails360FlexCard(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        String personAccountId =  String.valueOf(inputMap.get('personAccountId'));
        Boolean showButton;
        Boolean showEmails; 
        Boolean showUPM; 
        Boolean isHipaa;
        Boolean showButtonSpinOff;
        Boolean dentalAvailableState;
        Boolean showButtonTemporaryNewborns;
        Contract awaitingActivationContract;
        Contract awaitingFirstPaymentContract;
        Contract activeContract;
        Contract newestPotentialActiveContract;
        Contract spinOffContract;
        Contract oldestPotentialActiveContract;
        Contract oldestTerminatedVoidedContract;
        
        // SpinOff refactor:
        Boolean isSingleMember = true;
        Contract approvalOrSignature;
        Contract activationOrFirstPayment;
        
        if(!String.isBlank(personAccountId)){
            List<User> accountUserList = [SELECT Id,ARC_PortalUsername__c,IsActive FROM User WHERE Contact.AccountId =: personAccountId LIMIT 1];
            User accountUser = accountUserList.size()>0? accountUserList[0]: null;
            
            Account personAcc = [SELECT Id, 
                                        Name,
                                        vlocity_ins__Age__pc,
                                        BillingStreet,
                                        BillingState,
                                        BillingCity,
                                        BillingPostalCode,
                                        PersonBirthdate,
                                        Census_Member__r.vlocity_ins__CensusId__c,
                                        ARC_Census__c,
                                        Phone,
                                        ARC_DependentRelationship__c,
                                        PersonEmail,
                                        FirstName,
                                        LastName,
                                        vlocity_ins__SocialSecurityNumber__pc,
                                        ARC_IsPrimaryMember__c,
                                        ARC_E123MemberIdFromPolicy__c,
                                        ARC_Member_Id__c,
                                        ARC_PrimaryMemberAccount__r.ARC_E123MemberIdFromPolicy__c,
                                        ARC_PrimaryMemberAccount__r.ARC_Member_Id__c,
                                        Census_Member__c,
                                        PersonGender,
                                        HealthCloudGA__SourceSystemId__c FROM Account WHERE Id =: personAccountId LIMIT 1];    
            if(personAcc != null){
                //Sort Contracts ascending to get the newest at the end of the list.
                List<Contract> contracts = [SELECT Id, Status, ARC_Selling_Agent__r.Name, ARC_EffectiveDate__c, ARC_RecurringMonthlyOrder__c, ARC_ContractReason__c, vlocity_ins__EnrollmentCensusId__c FROM Contract WHERE vlocity_ins__EnrollmentCensusId__c =: personAcc.Census_Member__r.vlocity_ins__CensusId__c ORDER BY ARC_EffectiveDate__c ASC,ARC_Inactive_Date__c ASC];
                
                // Get contracts for Temporary Newborn Refactor
                List<ARC_ContractParticipant__c> temporaryNewbornEligibleContracts = [SELECT Id, ARC_PersonAccount__c, ARC_Contract__c, ARC_Contract__r.Status, ARC_Contract__r.ARC_EffectiveDate__c, ARC_Contract__r.ARC_RecurringMonthlyOrder__c FROM ARC_ContractParticipant__c WHERE ARC_PersonAccount__c =: personAcc.Id AND ARC_Contract__r.Status != 'Draft' AND ARC_Contract__r.Status != 'Voided' ORDER BY ARC_Contract__r.ARC_EffectiveDate__c DESC, CreatedDate DESC];
                if (temporaryNewbornEligibleContracts.size() > 0) {
                    String contractStatus = temporaryNewbornEligibleContracts[0].ARC_Contract__r.Status;
                    // showButtonTemporaryNewborns = true;
                    showButtonTemporaryNewborns = temporaryNewbornEligibleContracts.size() == 1 && contractStatus.contains('Awaiting') ? false : true; 
                    outputMap.put('showButtonTemporaryNewborns', showButtonTemporaryNewborns);
                }

                // Contract Participant of the contract Draft-Spin Off (to PCSpinOff)
                List<ARC_ContractParticipant__c> contractParticipant = [SELECT Id, ARC_PersonAccount__c, ARC_Contract__c, ARC_Contract__r.Status, ARC_Contract__r.ARC_RecurringMonthlyOrder__c, ARC_Contract__r.ARC_RecurringMonthlyOrder__r.ChargentOrders__Transaction_Count__c, ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c FROM ARC_ContractParticipant__c WHERE ARC_PersonAccount__c =: personAcc.Id AND (ARC_Contract__r.Status = 'Draft' OR ARC_Contract__r.Status LIKE '%Awaiting%') AND ARC_Contract__r.ARC_ContractReason__c INCLUDES ('Spin Off') LIMIT 1];
                if (contractParticipant.size() > 0) {
                    showButtonSpinOff = false;
                    outputMap.put('pcSpinOff', contractParticipant[0].ARC_Contract__r.Status == 'Draft' ? true : false);
                    // Variables and output for 360 chargent order component
                    String persAccCensusId = personAcc.Census_Member__r.vlocity_ins__CensusId__c;
                    String contractCensusId = contractParticipant[0].ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c;
                    Integer transactionCount = Integer.valueOf(contractParticipant[0].ARC_Contract__r.ARC_RecurringMonthlyOrder__r.ChargentOrders__Transaction_Count__c);
                    outputMap.put('SpinOffOrderId', persAccCensusId != contractCensusId && transactionCount > 0 ? contractParticipant[0].ARC_Contract__r.ARC_RecurringMonthlyOrder__c : null);
                } else {
                    showButtonSpinOff = true;
                    outputMap.put('pcSpinOff', false);
                    outputMap.put('SpinOffOrderId', null);
                }

                List<ARC_HipaaAuthorization__c> hippa = [SELECT Id FROM ARC_HipaaAuthorization__c WHERE ARC_AuthorizedMember__c =: personAcc.Census_Member__c AND ARC_Census__c =:personAcc.Census_Member__r.vlocity_ins__CensusId__c];
                List<ARC_UnderwritingCaseMember__c> underWritingCase = [SELECT Id , ARC_ApprovalResolution__c, ARC_LastStatusUpdate__c FROM ARC_UnderwritingCaseMember__c WHERE ARC_Member__c =: personAcc.Census_Member__c AND ARC_ApprovalResolution__c = 'Rejected' ORDER BY ARC_LastStatusUpdate__c DESC];
                List<ARC_Available_States__mdt> dentalStates = [SELECT Abbreviation__c FROM ARC_Available_States__mdt WHERE dentalAvailableState__c = TRUE];

                //Member Information
                if(personAcc.vlocity_ins__Age__pc != null)outputMap.put('CensusMemberAge', personAcc.vlocity_ins__Age__pc);
                if(personAcc.Phone != null) outputMap.put('Phone',personAcc.Phone);
                if(personAcc.HealthCloudGA__SourceSystemId__c != null) outputMap.put('AppUsername',personAcc.HealthCloudGA__SourceSystemId__c);
                if(personAcc.BillingCity != null) outputMap.put('City',personAcc.BillingCity );
                if(personAcc.BillingState != null) outputMap.put('State',personAcc.BillingState);
                if(personAcc.BillingStreet != null) outputMap.put('Street',personAcc.BillingStreet);
                if(personAcc.BillingPostalCode != null) outputMap.put('PostalCode',personAcc.BillingPostalCode);
                outputMap.put('Relationship',personAcc?.ARC_DependentRelationship__c != null ?personAcc.ARC_DependentRelationship__c:'Primary');
                if(personAcc.Census_Member__c != null) outputMap.put('CensusMemberId',personAcc.Census_Member__c);
                if(personAcc.Name != null) outputMap.put('Name',personAcc.Name);
                if(personAcc.PersonBirthdate != null){
                    DateTime birthdateToDateTime = DateTime.newInstance(personAcc.PersonBirthdate.year(), personAcc.PersonBirthdate.month(), personAcc.PersonBirthdate.day());
                    outputMap.put('Birthdate',birthdateToDateTime.format('MM/dd/yyyy'));
                }
                if(personAcc?.Census_Member__r?.vlocity_ins__CensusId__c != null) outputMap.put('CensusId',personAcc.Census_Member__r.vlocity_ins__CensusId__c);
                if(personAcc.PersonEmail != null) outputMap.put('Email',personAcc.PersonEmail);
                if(personAcc.FirstName!= null) outputMap.put('FirstName',personAcc.FirstName);
                if(personAcc.LastName != null) outputMap.put('LastName',personAcc.LastName);
                if(personAcc.PersonGender != null) outputMap.put('CensusMemberGender',personAcc.PersonGender);
                if(personAcc.vlocity_ins__SocialSecurityNumber__pc!= null) outputMap.put('SSN',personAcc.vlocity_ins__SocialSecurityNumber__pc);
                if(personAcc.vlocity_ins__SocialSecurityNumber__pc != null)outputMap.put('subSSN',String.valueOf(personAcc.vlocity_ins__SocialSecurityNumber__pc).right(4));
                String memberId;
                if(personAcc.ARC_IsPrimaryMember__c != null && personAcc.ARC_IsPrimaryMember__c){
                    if(personAcc.ARC_E123MemberIdFromPolicy__c != null) memberId = personAcc.ARC_E123MemberIdFromPolicy__c;
                    else memberId = personAcc.ARC_Member_Id__c	;
                }
                else{
                    if(personAcc.ARC_PrimaryMemberAccount__r?.ARC_E123MemberIdFromPolicy__c != null) memberId = personAcc.ARC_PrimaryMemberAccount__r?.ARC_E123MemberIdFromPolicy__c;
                    else memberId = personAcc.ARC_PrimaryMemberAccount__r?.ARC_Member_Id__c	;
                }
                outputMap.put('MemberId',memberId);

                if(accountUser!= null && accountUser.ARC_PortalUsername__c != null){
                    outputMap.put('PortalUsername',accountUser.IsActive ? accountUser.ARC_PortalUsername__c : '(Inactive) ' + accountUser.ARC_PortalUsername__c);
                }else{
                    outputMap.put('PortalUsername',null);
                }

                //Create a Set to perform better .contains()
                Set<String> availableBillingStates = new Set<String>();

                for(ARC_Available_States__mdt state : dentalStates){
                   if(state.Abbreviation__c!=null){
                        availableBillingStates.add(state.Abbreviation__c.toUpperCase());
                    }
                }

                if(personAcc.BillingState!=null && availableBillingStates.contains(personAcc.BillingState.toUpperCase())){
                   dentalAvailableState = true;
               } else {
                    dentalAvailableState = false;
                }

                outputMap.put('showDentalAvailableState', dentalAvailableState);
                
                //Contract Information
                if(contracts.size()>0){
                    for(Contract cont: contracts){
                        switch on cont.Status {
                            when 'Activated'{
                                spinOffContract = cont;
                                activeContract = cont;
                            }
                            when 'Awaiting Activation'{
                                spinOffContract = cont;
                                activationOrFirstPayment = cont;
                                awaitingActivationContract = cont;
                                if (oldestPotentialActiveContract == null) oldestPotentialActiveContract = cont;
                            }
                            when 'Awaiting First Payment'{
                                spinOffContract = cont;
                                activationOrFirstPayment = cont;
                                awaitingFirstPaymentContract = cont;
                                if (oldestPotentialActiveContract == null) oldestPotentialActiveContract = cont;
                            }
                            when 'Awaiting Approval'{
                                approvalOrSignature = cont;
                                if (oldestPotentialActiveContract == null) oldestPotentialActiveContract = cont;
                            }
                            when 'Awaiting Signature'{
                                approvalOrSignature = cont;
                                if (oldestPotentialActiveContract == null) oldestPotentialActiveContract = cont;
                            }
                            when 'Voided','Terminated'{
                                if (oldestTerminatedVoidedContract == null) oldestTerminatedVoidedContract = cont;
                            }
                        }
  
                        // Hide Spin Off Icon when New Application Contract is not active
                        if (cont.Status.contains('Awaiting') && String.valueOf(cont.get('ARC_ContractReason__c')).contains('New Application')) {
                            showButtonSpinOff = false;
                        }
                    }
                    outputMap.put('ContractSellingAgent',activeContract?.ARC_Selling_Agent__r?.Name != null ? activeContract?.ARC_Selling_Agent__r?.Name : (oldestPotentialActiveContract?.ARC_Selling_Agent__r?.Name != null ? oldestPotentialActiveContract?.ARC_Selling_Agent__r?.Name: null));
                    outputMap.put('ContractActive',activeContract != null? true: false);
                    outputMap.put('SpinOffContractEffDate', spinOffContract?.ARC_EffectiveDate__c != null ? spinOffContract?.ARC_EffectiveDate__c: null);
                    outputMap.put('SpinOffContractId',spinOffContract?.Id != null ? spinOffContract?.Id: null);

                    if(activeContract != null && activeContract.ARC_RecurringMonthlyOrder__c != null){
                        outputMap.put('OrderId',activeContract.ARC_RecurringMonthlyOrder__c);
                        List<vlocity_ins__ContractLineItem__c> contractLineItems = [
                            SELECT Id FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c = :activeContract.Id
                            AND Name LIKE '%WeShare%'AND vlocity_ins__ParentItemId__c = null AND vlocity_ins__RecordTypeName__c = 'Product' 
                            AND vlocity_ins__ProductType__c = 'Medical'
                        ];
                    
                        if (!contractLineItems.isEmpty()) {
                            outputMap.put('HasWeSharePlan', true);
                        }
                        try {
                            outputMap.put('HasUserCreated',true);
                            outputMap.put('HasChangedUsername', accountUser.ARC_PortalUsername__c.containsIgnoreCase(personAccountId)? false:true);
                        } catch (Exception e) {
                            outputMap.put('HasUserCreated',false);
                            outputMap.put('HasChangedUsername', false);
                        }
                    } 
                    else if(oldestPotentialActiveContract != null && oldestPotentialActiveContract.ARC_RecurringMonthlyOrder__c != null){
                        outputMap.put('OrderId',oldestPotentialActiveContract.ARC_RecurringMonthlyOrder__c);
                    }
                    else if(oldestTerminatedVoidedContract != null && oldestTerminatedVoidedContract.ARC_RecurringMonthlyOrder__c != null){
                        outputMap.put('OrderId',oldestTerminatedVoidedContract.ARC_RecurringMonthlyOrder__c);
                    }
                    outputMap.put ('success', true);
                }
                else{
                    outputMap.put ('success', false);
                    outputMap.put('errorMessage','Error in ARC_PersonAccount360view.getPersonAccountDetails360FlexCard(), No Contract found');
                }


                // Overwrite orderId key value if acc is Temporary Newborn
                if (personAcc.ARC_DependentRelationship__c == 'Temporary Newborn') {
                    List<InsurancePolicyParticipant> newbornPP = [ SELECT Id, InsurancePolicy.ARC_Contract__r.ARC_RecurringMonthlyOrder__c FROM InsurancePolicyParticipant WHERE PrimaryParticipantContact.AccountId = :personAcc.Id ORDER BY ExpirationDate DESC LIMIT 1];
                    System.debug('TN pp: ' + newbornPP);
                    String recurringOrderId = newbornPP[0].InsurancePolicy.ARC_Contract__r.ARC_RecurringMonthlyOrder__c;
                    outputMap.put('OrderId', recurringOrderId != NULL  && recurringOrderId != '' ? recurringOrderId : outputMap.get('OrderId'));
                }


                //Hipaa
                outputMap.put('IsHipaa',hippa.size()> 0 ? true: false);

                //Buttos & Actions
                if(spinOffContract != null || underWritingCase.size() ==  0) outputMap.put('ShowActions', true);
                else outputMap.put('ShowActions', false);

                //SPIN OFF REFACTOR: Show SpinOff Icon if is a single member in the contract
                Integer cantMembers;
                if (activeContract != null && approvalOrSignature != null) { // Case Activated  && (Approval || Signature) contracts
                    cantMembers = [SELECT COUNT() FROM ARC_ContractParticipant__c WHERE ARC_Contract__c =: activeContract?.Id];
                    if (cantMembers != 1) isSingleMember = false;
                }
                else if (activeContract != null && activationOrFirstPayment != null) { // Case Activated && (Activation || First Payment) contracts
                    cantMembers = [SELECT COUNT() FROM ARC_ContractParticipant__c WHERE ARC_Contract__c =: activationOrFirstPayment?.Id];
                    if (cantMembers != 1) isSingleMember = false;
                }
                else if (activeContract != null) { // Case only Activated contract
                    cantMembers = [SELECT COUNT() FROM ARC_ContractParticipant__c WHERE ARC_Contract__c =: activeContract?.Id];
                    if (cantMembers != 1) isSingleMember = false;
                }
                else if(activationOrFirstPayment != null) { // Case only (Activation || First Payment) contract
                    cantMembers = [SELECT COUNT() FROM ARC_ContractParticipant__c WHERE ARC_Contract__c =: activationOrFirstPayment?.Id];
                    if (cantMembers != 1) isSingleMember = false;
                }
                else if(approvalOrSignature != null) { // Case only (Approval || Signature) contract, can't spin off but show step of no spin off
                    cantMembers = [SELECT COUNT() FROM ARC_ContractParticipant__c WHERE ARC_Contract__c =: approvalOrSignature?.Id];
                    if (cantMembers != 1) isSingleMember = false;
                }

                // if(activeContract != null || awaitingActivationContract != null || awaitingFirstPaymentContract != null || oldestPotentialActiveContract) {
                if(oldestPotentialActiveContract != null ||  activeContract != null){
                    outputMap.put('ShowButton',true);
                    outputMap.put('ShowEmails',true); 
                }else{
                    outputMap.put('ShowButton',false);
                    outputMap.put('ShowEmails',false);
                }
                //Show Update Payment Method
                if(activeContract != null || oldestPotentialActiveContract != null) outputMap.put('ShowUPM',true);
                else outputMap.put('ShowUPM',false);
                //Show MemberIdCard
                if(activeContract == null && awaitingActivationContract == null && awaitingFirstPaymentContract != null) outputMap.put('AwaitingFirstPayment',true);
                else outputMap.put('AwaitingFirstPayment',false);

                outputMap.put('showButtonSpinOff', showButtonSpinOff);
            }
            else{
                outputMap.put ('success', false);
                outputMap.put('errorMessage','Error in ARC_PersonAccount360view.getPersonAccountDetails360FlexCard(), No Person Account found');
            }
        }
        else{
            outputMap.put ('success', false);
            outputMap.put('errorMessage','Error in ARC_PersonAccount360view.getPersonAccountDetails360FlexCard(), No Person Account found');
        }
    }

    /*******************************************************************
    * @MethodName         :   stampPersonAccountInSpinOffMembers
    * @Description        :   If there are spin off members it gets their person account and stamps in the new Census Member
    ********************************************************************/
    public static void stampPersonAccountInSpinOffMembers(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> memberInput = (List<Object>)inputMap.get('censusMembers');
        if(memberInput != null){
            Set<Id> memberIds = new Set<Id>(); 
            for(Object member: (List<Object>)memberInput){
                Map<String, Object> censusMember = (Map<String, Object>)member;
                memberIds.add((Id)censusMember.get('Id'));
            } 
            List<vlocity_ins__GroupCensusMember__c> cmList = [SELECT Id,vlocity_ins__ContactId__c,ARC_OldCensusMember__r.vlocity_ins__ContactId__c FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :memberIds AND ARC_OldCensusMember__c != null];
            if(cmList.size()>0){
                for(vlocity_ins__GroupCensusMember__c cm: cmList){
                    if(cm.ARC_OldCensusMember__r?.vlocity_ins__ContactId__c != null) cm.vlocity_ins__ContactId__c = cm.ARC_OldCensusMember__r.vlocity_ins__ContactId__c;
                }
                try{
                    update cmList;
                    outPutMap.put('success', true);
                    outPutMap.put('spinOffUpdated', true);
                }catch(Exception e){
                    outPutMap.put('success', false);
                    outPutMap.put('spinOffUpdated', false);
                    outputMap.put('errorMessage','Error in ARC_GetSpinOffMembers.stampPersonAccountInSpinOffMembers(), Could not update Census Mebers');
                }
            }
            else{
                outPutMap.put('success', true);
                outPutMap.put('spinOffUpdated', false);
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   getSSNDescrypted
    * @Description        :   Used in Syn Census member to Person Account and Sync Person Account to Census Member flows. It gets the SSN decrypted.
    ********************************************************************/
    public static List<Results> getSSNDescrypted (List<Id> recordIds) {
        List<Results> resultList = new List<Results>();
        List<Id> censusMemberIds = new List<Id>();
        List<Id> accountRecordsIds = new List<Id>();
        Map<Id,Results> personResultMap = new Map<Id,Results>();
        for(Id recordId: recordIds) {
            //Id recordId = (Id)objId;
            if(recordId.getSobjectType().getDescribe().getName() == 'vlocity_ins__GroupCensusMember__c') censusMemberIds.add(recordId);
            else if(recordId.getSobjectType().getDescribe().getName() == 'Account') accountRecordsIds.add(recordId);
        }

        if(censusMemberIds.size()>0){
            List<vlocity_ins__GroupCensusMember__c> censusMembers = [SELECT Id, vlocity_ins__SocialSecurityNumber__c FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :censusMemberIds];
            for(vlocity_ins__GroupCensusMember__c cm: censusMembers){
                Results res = new Results();
                res.recordId = cm.Id;
                if(cm?.vlocity_ins__SocialSecurityNumber__c != null) res.ssn = String.valueOf(cm.vlocity_ins__SocialSecurityNumber__c);
                else res.ssn = null;
                personResultMap.put(cm.Id,res);
            }
        }
        if(accountRecordsIds.size()>0){
            List<Account> personAccounts = [SELECT Id, vlocity_ins__SocialSecurityNumber__pc FROM Account WHERE Id IN :accountRecordsIds];
            for(Account pa: personAccounts){
                Results res = new Results();
                res.recordId = pa.Id;
                if(pa.vlocity_ins__SocialSecurityNumber__pc != null) res.ssn = String.valueOf(pa.vlocity_ins__SocialSecurityNumber__pc);
                else res.ssn = null;
                personResultMap.put(pa.Id,res);
            }
        }
        for(Id recordId: recordIds){
            if(personResultMap.containsKey(recordId)) resultList.add(personResultMap.get(recordId));
            else resultList.add(null);
        }
        System.debug(resultList);
        return resultList;
    }

    /*******************************************************************
    * @MethodName         :   lastDateOfMonth
    * @Description        :   Returns the last date of the month based on the input date.
    ********************************************************************/
    public static Date lastDateOfMonth(Date d){
        if(d!= null){
            Integer numberOfDays = Date.daysInMonth(d.year(), d.month());
            return Date.newInstance(d.year(), d.month(), numberOfDays);
        }
        else return null;
    }

    //Helper class that is used inside the Invocable Method to execute different methods depending upon the inputs.
    public class RequestsVariables {
        @InvocableVariable(label='Method' description='method to execute' required=true)
        public String methodName;

        @InvocableVariable(label='Record Id' description='record')
        public Id recordId;
    }

    //Helper class that is used inside the Invocable Method to execute different methods depending upon the inputs.
    public class Results {
        @InvocableVariable(label='SSN' description='Social Security Number')
        public String ssn;

        @InvocableVariable(label='recordId' description='recordId')
        public Id recordId;

        @InvocableVariable(label='Since Date' description='Since Date')
        public Date sinceDate;

        @InvocableVariable(label='Conitnuous Coverage Start Date' description='Conitnuous Coverage Start Date')
        public Date continuousCoverageStartDate;
    }

    /*******************************************************************
    * @MethodName         :   invocablePersonAccount
    * @Description        :   Invocable Method that execute the corresponding Method received by parameter. 
    ********************************************************************/
    @InvocableMethod(label='Person Account Manager' description='description' category='Person Account')
    public static List<Results> invocablePersonAccount(List<RequestsVariables> requests){
        System.debug(requests);
        Map<String, List<Id>> personAccountIdsByMethod = new Map<String, List<Id>>();
        for(RequestsVariables request : requests){
            if(request.recordId != null){
                if(personAccountIdsByMethod.containsKey(request.methodName)){
                    personAccountIdsByMethod.get(request.methodName).add(request.recordId);
                }else{
                    personAccountIdsByMethod.put(request.methodName, new List<Id>{request.recordId});
                }
            }
        }
        System.debug(personAccountIdsByMethod);
        if(personAccountIdsByMethod.containsKey('getSSNDescrypted')){
            return getSSNDescrypted(new List<Id>(personAccountIdsByMethod.get('getSSNDescrypted'))); 
        }
        else return null;
    }


}