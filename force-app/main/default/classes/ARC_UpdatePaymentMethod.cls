/**
 * @description This class, ARC_UpdatePaymentMethod, implements the VlocityOpenInterface and provides methods for updating payment methods.
 * @implements vlocity_ins.VlocityOpenInterface
 * @global
 * @with sharing
 */
global with sharing class ARC_UpdatePaymentMethod implements vlocity_ins.VlocityOpenInterface{
    public Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        switch on methodName {
            when 'getPayorForSelect' {
                getPayorForSelect(input, outMap, options);
            }
            when 'upsertCase' {
                upsertCase(input, outMap, options);
            }
            when 'getExecutionOrigin' {
                getExecutionOrigin(input, outMap, options);
            }
            when 'updateAddresses' {
                updateAddresses(input, outMap, options);
            }
            when 'updateAccountData' {
                updateAccountData(input, outMap, options);
            }
            when 'updatePaymentMethod' {
                updatePaymentMethod(input, outMap, options);
            }
            when 'getCardType' {
                getCardType(input, outMap, options);
            }
            when 'voidCases' {
                voidCases(input);
            }

            
        }
        return true;
    }

    /**
     * @description Retrieves the payor options for the specified member.
     * @param input The input parameters for the method.
     * @param outMap The output map to store the payor options.
     * @param options Additional options for the method.
     */
    public static void getPayorForSelect(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        String accountId = (String) input.get('PersonAccountId');
        Contract contract = getCurrentContract(accountId);
        ChargentOrders__ChargentOrder__c order = contract.ARC_RecurringMonthlyOrder__r != null ? contract.ARC_RecurringMonthlyOrder__r : contract.ARC_AppFeeOrder__r;
        List<Map<String, String>> memberOptions = getMemberOptionsForSelect(contract.Id);
        memberOptions.add(new Map<String, String>{'label' => 'Third Party Payor', 'value' => 'Third Party Payor'});
        outMap.put('payorOptions', memberOptions);
        outMap.put('contractId', contract.Id);
        outMap.put('firstName', contract.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.FirstName);
        outMap.put('PaymentAmount', contract.ARC_TotalPrice__c);
        outMap.put('PrimaryMemberName', contract.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Name);
        outMap.put('PrimaryMemberId', contract.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.ARC_E123MemberIdFromPolicy__c != null ? contract.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.ARC_E123MemberIdFromPolicy__c : contract.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Current_Member_Id__c);
        outMap.put('DOB', contract.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonBirthdate?.format());
        outMap.put('censusId', contract.vlocity_ins__EnrollmentCensusId__c);
        outMap.put('ContractStatus', contract.Status);
        outMap.put('OrderStatus', order.ChargentOrders__Payment_Status__c);
        outMap.put('OrderDescription', order.ChargentOrders__Description__c);
    }

    /**
     * @description Retrieves the current contract for the specified member.
     * @param memberId The ID of the member.
     * @return Contract Returns the current contract for the member.
     */
    public static Contract getCurrentContract(String accountId){
        //Contract Information
        Id censusId = [SELECT ARC_Census__c FROM Account WHERE Id =: accountId].ARC_Census__c;
        List<Contract> contracts = [
            SELECT Id, 
                Status,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Description__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Status__c,
                ARC_AppFeeOrder__r.ChargentOrders__Payment_Status__c,
                ARC_AppFeeOrder__r.ChargentOrders__Description__c,
                ARC_AppFeeOrder__r.ChargentOrders__Total__c,
                vlocity_ins__EnrollmentCensusId__c ,
                ARC_TotalPrice__c,
                vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Name,
                vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.FirstName,
                vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonBirthdate,
                vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.ARC_E123MemberIdFromPolicy__c,
                vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Current_Member_Id__c
            FROM Contract
            WHERE vlocity_ins__EnrollmentCensusId__c =: censusId 
            AND (ARC_RecurringMonthlyOrder__c != null OR ARC_AppFeeOrder__c != null)
            ORDER BY ARC_EffectiveDate__c DESC
        ];
        Contract contractToUse, activeContract, approvedContract, awaitingActivationContract, awaitingFirstPaymentContract, awaitingSignatureContract, awaitingApprovalContract, lastTerminatedContract;
        for(Contract contract: contracts){
            if(contract.Status == 'Activated'){
                activeContract = contract;
            }else if(activeContract == null){
                if(contract.Status == 'Awaiting Activation'){
                    awaitingActivationContract = contract;
                }else if(contract.Status == 'Awaiting First Payment'){
                    awaitingFirstPaymentContract = contract;
                }else if(contract.Status == 'Awaiting Approval'){
                    awaitingApprovalContract = contract;
                }else if(contract.Status == 'Awaiting Signature'){
                    awaitingSignatureContract = contract;
                }else if(contract.Status == 'Terminated' || contract.Status == 'Voided'){
                    lastTerminatedContract = contract;
                }
            }
        }
        //Order of priority: 
        //If no Active Contract; use Awaiting Activation, Awaiting First Payment, Awaiting Approval, Awaiting Signature, Last Terminated, 
        //If Active Contract;  Awaiting Activation, Activated
        if(activeContract == null){
            if(awaitingActivationContract != null){
                contractToUse = awaitingActivationContract;
            }else if(awaitingFirstPaymentContract != null){
                contractToUse = awaitingFirstPaymentContract;
            }else if(awaitingApprovalContract != null){
                contractToUse = awaitingApprovalContract;
            }else if(awaitingSignatureContract != null){
                contractToUse = awaitingSignatureContract;
            }else if(lastTerminatedContract != null){
                contractToUse = lastTerminatedContract;
            }
        }else{
            if (awaitingActivationContract != null) {
                contractToUse = awaitingActivationContract;
            } else if (activeContract != null) {
                contractToUse = activeContract;
            }
        }
        return contractToUse;
    }

    /**
     * @description Retrieves the member options for the specified contract.
     * @param contractId The ID of the contract.
     * @return List<Map<String,String>> Returns a list of member options.
     */
    private static List<Map<String,String>> getMemberOptionsForSelect(String contractId){
        List<Map<String,String>> memberOptions = new List<Map<String,String>>();
        List<vlocity_ins__GroupCensusMemberPlan__c> memberPlans = getMemberPlans(contractId);
        for(vlocity_ins__GroupCensusMemberPlan__c memberPlan: memberPlans){
            Map<String,String> memberMap = new Map<String,String>();
            memberMap.put('name', memberPlan.vlocity_ins__GroupCensusMemberId__r.Name);
            memberMap.put('id', memberPlan.vlocity_ins__GroupCensusMemberId__c);
            memberMap.put('value', memberPlan.vlocity_ins__GroupCensusMemberId__c);
            memberMap.put('label', memberPlan.vlocity_ins__GroupCensusMemberId__r.Name);
            memberMap.put('firstName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c);
            memberMap.put('lastName', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c);
            memberMap.put('phone', memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_Phone__c?.replace('+1', ''));
            memberMap.put('email', memberPlan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c);
            memberMap.put('city', memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressCity__c);
            memberMap.put('state', memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c);
            memberMap.put('zip', memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressZipCode__c);
            memberMap.put('street', memberPlan.vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressStreet__c);

            memberOptions.add(memberMap);
        }
        return memberOptions;
    }

    /**
     * @description Retrieves the member plans for the specified contract.
     * @param contractId The ID of the contract.
     * @return List<vlocity_ins__GroupCensusMemberPlan__c> Returns a list of member plans.
     */
    private static List<vlocity_ins__GroupCensusMemberPlan__c> getMemberPlans(String contractId){
        List<vlocity_ins__GroupCensusMemberPlan__c> memberPlans = [
            SELECT Id,
                vlocity_ins__GroupCensusMemberId__c, 
                vlocity_ins__GroupCensusMemberId__r.Name, 
                vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c,
                vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c,
                vlocity_ins__GroupCensusMemberId__r.ARC_Phone__c,
                vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c,
                vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressCity__c,
                vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c,
                vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressZipCode__c,
                vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressStreet__c
            FROM vlocity_ins__GroupCensusMemberPlan__c 
            WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c =: contractId AND
            vlocity_ins__ContractLineId__r.vlocity_ins__RecordTypeName__c = 'Product' AND
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'  AND
            vlocity_ins__GroupCensusMemberId__r.ARC_Age__c >= 18  
        ];
        return memberPlans;
    }

    public static void upsertCase(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) { 
        Id contextId = (Id) input.get('ContextId');
        Boolean etfRequired = ((String)input.get('RAD_ETFRequired')) == 'Yes'? true : false;
        String RAD_AddressInformationFor = (String) input.get('RAD_AddressInformationFor');
        List<String> voidEnvelopeIds = new List<String>();
        Map<String, String> caseData = new Map<String, String>();
        RecordType caseRecordType;
        
        if (input.get('STEP_CaseRecord') != '') {
            caseData = formatCaseStepData((Map<String, Object>) input.get('STEP_CaseRecord'));
            caseRecordType = [SELECT Id FROM RecordType WHERE DeveloperName =: caseData.get('RecordType')];
        }
        
        Case c = new Case(
            ARC_UpdateThisAddressOnSign__c = RAD_AddressInformationFor,
            ARC_SetRecurringOnSign__c = (String) input.get('setRecurring') == 'Yes'? true : false,
            ARC_PersonAccount__c = (String) input.get('PersonAccountId'),
            ARC_UPMSelectedPayor__c = (String) input.get('ARC_UPMSelectedPayor__c')
        );

        if (etfRequired) {
            c.Status = 'Awaiting Response';
            c.OwnerId = [SELECT Id FROM Group WHERE DeveloperName = 'ProcessingQueue'].Id;
            c.ARC_LastDocuSignEnvelopeId__c = (String)input.get('envelopeId');
            c.ARC_LastDocuSignEnvelopeStatus__c = (String)input.get('envelopeStatus');
        }

        switch on contextId.getSobjectType().getDescribe().getName() {
            
            when 'Case' {
                c.Id = contextId;
            }
            when 'Account'{
                c.RecordTypeId = caseRecordType.Id;
                c.Case_Type__c = caseData.get('Case_Type__c');
                c.ARC_Reason__c = caseData.get('Reason');
                c.Origin = caseData.get('Origin');
                c.ARC_Type__c = caseData.get('ARC_Type__c');
                c.Subject = caseData.get('Subject');
                c.Description = caseData.get('Description');
                c.Status = caseData.get('Status');
                // Void all Contribution cases related to that account
                List<Case> casesToVoid = [SELECT Id, ARC_LastDocuSignEnvelopeId__c, (SELECT Id, Status FROM Tasks WHERE isClosed = false) FROM Case WHERE ARC_PersonAccount__c =: contextId AND Case_Type__c = 'Contribution' AND IsClosed = false AND ARC_Reason__c IN ('Method Change', 'App/Change Fee Decline','One Time Fee Decline','Recurring Decline','First Month Decline')];   
                List<Task> openTasks = new List<Task>();
                for(Case caseToVoid: casesToVoid){
                    for(Task t : caseToVoid.Tasks){
                        t.Status = 'Completed';
                        openTasks.add(t);
                    }
                    caseToVoid.ARC_LastDocuSignEnvelopeStatus__c = 'Voided';
                    caseToVoid.Status = 'Closed';
                }
                update openTasks;
                update casesToVoid;
            }
        }
        upsert c;
        outMap.put('caseId', c.Id);
    }


    public static void voidCases(Map<String, Object> input){
        Id contextId = (Id) input.get('ContextId');
        switch on contextId.getSobjectType().getDescribe().getName() {
            when 'Case' {
                Case c = [SELECT ARC_LastDocuSignEnvelopeId__c FROM Case WHERE Id =: contextId];
                ARC_DocuSignApi.voidEnvelope(c.ARC_LastDocuSignEnvelopeId__c);
            }
            when 'Account' {
                List<Case> cases = [SELECT ARC_LastDocuSignEnvelopeId__c FROM Case WHERE ARC_PersonAccount__c =: contextId];
                for (Case c : cases) {
                    ARC_DocuSignApi.voidEnvelope(c.ARC_LastDocuSignEnvelopeId__c);
                }
            }
        }
    }

    private static Map<String, String> formatCaseStepData(Map<String, Object> input) {
        Map<String, String> caseData = new Map<String, String>();
        caseData.put('RecordType', (String) input.get('TXT_RecordType'));
        caseData.put('Case_Type__c', (String) input.get('TXT_CaseType'));
        caseData.put('Reason', (String) input.get('TXT_Reason'));
        caseData.put('Origin', (String) input.get('SEL_CaseOrigin'));
        caseData.put('ARC_Type__c', (String) input.get('SEL_Caller'));
        caseData.put('Subject', (String) input.get('TXT_Subject'));
        caseData.put('Description', (String) input.get('TXT_Description'));
        caseData.put('Status', (String)input.get('SEL_Status') != null ? (String)input.get('SEL_Status') : (String)input.get('SEL_StatusClosed'));
        caseData.put('OwnerId', (String) input.get('SEL_Owner'));
        caseData.put('ARC_LastDocuSignEnvelopeId__c', (String) input.get('envelopeId'));
        caseData.put('ARC_LastDocuSignEnvelopeStatus__c', (String) input.get('envelopeStatus'));
        return caseData;
    }

    public static void getExecutionOrigin(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        Id contextId = (Id) input.get('ContextId');
        String executionOrigin = contextId.getSobjectType().getDescribe().getName();
        outMap.put('executionOrigin', executionOrigin);
        outMap.put('censusMemberId', executionOrigin == 'Case' ? [SELECT ARC_PersonAccount__r.Census_Member__c FROM Case WHERE Id =: contextId].ARC_PersonAccount__r.Census_Member__c : [SELECT Census_Member__c FROM Account WHERE Id =: contextId].Census_Member__c);
        outMap.put('PersonAccountId', executionOrigin == 'Case' ? [SELECT ARC_PersonAccount__c FROM Case WHERE Id =: contextId].ARC_PersonAccount__c : contextId);
    }

    public static void updateAddresses(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {

        //The billing address in the order is being updated in the updatePaymentMethod method.

        Id personAccountId = (Id)input.get('PersonAccountId');
        if(personAccountId.getSobjectType().getDescribe().getName() == 'vlocity_ins__GroupCensusMember__c'){
            personAccountId = [SELECT vlocity_ins__ContactId__r.AccountId FROM vlocity_ins__GroupCensusMember__c WHERE Id =: personAccountId].vlocity_ins__ContactId__r.AccountId;
        }
        
        String addressInformationFor = (String) input.get('addressInformationFor');
        String state = (String) input.get('state');
        String city = (String) input.get('city');
        String street = (String) input.get('street');
        String zip = (String) input.get('zip');
        String censusId = (String) input.get('censusId');

        List<Account> accounts = new List<Account>();

        switch on addressInformationFor {
            when 'Only for selected payor' {
                accounts = [SELECT Id, Census_Member__c FROM Account WHERE Id =: personAccountId];
                vlocity_ins__GroupCensusMember__c member = new vlocity_ins__GroupCensusMember__c(
                    Id = accounts[0].Census_Member__c,
                    ARC_UpdateAllAddress__c = false
                );
                update member;
            }
            when 'All family members' {
                accounts = [SELECT Id, Census_Member__c FROM Account WHERE ARC_Census__c =: censusId];
            }
        }


        for(Account account: accounts){
            account.BillingState = state;
            account.BillingCity = city;
            account.BillingStreet = street;
            account.BillingPostalCode = zip;
        }

        update accounts;
    }

    /***********************************************************************************
    * @MethodName         :   updatePaymentMethod
    * @Description        :   Receive Data from an IP and do the logic to Update the Encrypted Fields of the Chargent Orders
    **************************************************************************************/
    public static void updatePaymentMethod(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
            
            String creditCardGateway = (String)inputMap.get('creditCardGateway');
            String bankGateway = (String)inputMap.get('bankGateway'); 
            String setRecurring = (String)inputMap.get('setRecurring');
    
            
            Set<Id> orderIds = new Set<Id>();
            Set<Id> futureOrderIds = new Set<Id>();
            Set<Id> uniqueOrderIds = new Set<Id>();
    
            List<ChargentOrders__ChargentOrder__c> chargentFirstUpdate = new List<ChargentOrders__ChargentOrder__c>();
            List<ChargentOrders__ChargentOrder__c> chargentOrders = new List<ChargentOrders__ChargentOrder__c>();
            List<ChargentOrders__ChargentOrder__c> futureChargents = new List<ChargentOrders__ChargentOrder__c>();
            List<ChargentOrders__Chargent_Automated_Collections__c > chargentCollections = new List<ChargentOrders__Chargent_Automated_Collections__c>();
            List<Map<String,Object>> orders = (List<Map<String,Object>>)inputMap.get('orders');
    
            Map<String,Object> paymentInformation = (Map<String,Object>)inputMap.get('paymentInformation');
            Map<String,Object> cardInformationMap =  (Map<String,Object>)paymentInformation.get('BLK_UpdateCreditCard');
            Map<String,Object> bankInformationMap =  (Map<String,Object>)paymentInformation.get('BLK_BankAccount');
    
            Boolean isCreditCard = cardInformationMap != null;
            Boolean isBankAccount = bankInformationMap != null;
    
            for(Map<String,Object> order : orders){
                orderIds.add((Id)order.get('Id'));
            }
            System.debug(orderIds);
            
            chargentOrders = [
                SELECT 
                    Id, 
                    ARC_Contract__c,ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c,
                    ChargentOrders__Account__c,ChargentOrders__Bank_Account_Last_4__c,ChargentOrders__Bank_Account_Name__c,
                    ChargentOrders__Bank_Account_Type__c,ChargentOrders__Bank_Name__c,ChargentOrders__Billing_Address__c,
                    ChargentOrders__Billing_City__c,ChargentOrders__Billing_Email__c,ChargentOrders__Billing_First_Name__c,
                    ChargentOrders__Billing_Last_Name__c,ChargentOrders__Billing_State__c,ChargentOrders__Billing_Zip_Postal__c,
                    ChargentOrders__Card_Last_4__c,ChargentOrders__Card_Month_Indicator__c,ChargentOrders__Card_Type__c,
                    ChargentOrders__Card_Year_Indicator__c,ChargentOrders__Charge_Amount__c,ChargentOrders__Description__c,
                    ChargentOrders__Gateway__c,ChargentOrders__Payment_Frequency__c,ChargentOrders__Payment_Method__c,
                    ChargentOrders__Payment_Status__c,ChargentOrders__Payment_Stop__c,ChargentOrders__Subtotal__c,
                    ChargentOrders__Tokenization__c, ARC_Contract__r.ARC_TotalPrice__c, ChargentOrders__Card_Number__c,
                    ChargentOrders__Bank_Account_Number__c,ChargentOrders__Bank_Routing_Number__c,ARC_UpdatePaymentMethod__c,
                    (
                        SELECT Id, ChargentOrders__Response_Status__c 
                        FROM ChargentOrders__Transactions__r 
                        ORDER BY CreatedDate DESC LIMIT 1
                    ) 
                FROM ChargentOrders__ChargentOrder__c
                WHERE Id IN :orderIds
            ];
            System.debug(chargentOrders);
    
            
            for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrders) {
                uniqueOrderIds.add(chargentOrder.Id);
                if(chargentOrder.ChargentOrders__Description__c == 'Recurring Monthly Order' && setRecurring != null && setRecurring == 'Yes'){
                    chargentOrder.ChargentOrders__Payment_Status__c = 'Recurring';
                    chargentFirstUpdate.add(chargentOrder);
                }
            }
    
            if(chargentFirstUpdate.size() != 0){
                update chargentOrders;
            }
    
            Contract contract = [
                SELECT 
                    Id,
                    vlocity_ins__EnrollmentCensusId__c,
                    CreatedDate,
                    ARC_OneTimeFeeOrder__c,
                    ARC_RecurringMonthlyOrder__c,
                    ARC_AppFeeOrder__c 
                FROM Contract 
                WHERE Id = :chargentOrders[0].ARC_Contract__c LIMIT 1
            ];
            System.debug(contract);
    
    
            List<Contract> futureContracts = new List<Contract>([
                SELECT ARC_RecurringMonthlyOrder__c,ARC_OneTimeFeeOrder__c,ARC_AppFeeOrder__c
                FROM Contract
                WHERE vlocity_ins__EnrollmentCensusId__c = :contract.vlocity_ins__EnrollmentCensusId__c
                AND CreatedDate > :contract.CreatedDate
            ]);
            System.debug(futureContracts);
    
            for (Contract c : futureContracts) {
                if(c.ARC_RecurringMonthlyOrder__c != null){
                    futureOrderIds.add(c.ARC_RecurringMonthlyOrder__c);
                }
                if(c.ARC_OneTimeFeeOrder__c != null){
                    futureOrderIds.add(c.ARC_OneTimeFeeOrder__c);
                }
                if(c.ARC_AppFeeOrder__c != null){
                    futureOrderIds.add(c.ARC_AppFeeOrder__c);
                }
            }
    
            futureChargents = [
                SELECT Id,ChargentOrders__Card_Number__c,ARC_Contract__c,ChargentOrders__Account__c,ChargentOrders__Bank_Account_Last_4__c,ChargentOrders__Bank_Account_Name__c,
                ChargentOrders__Bank_Account_Type__c,ChargentOrders__Bank_Name__c,ChargentOrders__Billing_Address__c,ChargentOrders__Billing_City__c,
                ChargentOrders__Billing_Email__c,ChargentOrders__Billing_First_Name__c,ChargentOrders__Billing_Last_Name__c,ChargentOrders__Billing_State__c,
                ChargentOrders__Billing_Zip_Postal__c,ChargentOrders__Card_Last_4__c,ChargentOrders__Card_Month_Indicator__c,ChargentOrders__Card_Type__c,
                ChargentOrders__Card_Year_Indicator__c,ChargentOrders__Charge_Amount__c,ChargentOrders__Description__c,ChargentOrders__Gateway__c,
                ChargentOrders__Payment_Frequency__c,ChargentOrders__Payment_Method__c,ChargentOrders__Payment_Status__c,ChargentOrders__Payment_Stop__c,
                ChargentOrders__Subtotal__c,ChargentOrders__Tokenization__c,ARC_Contract__r.ARC_TotalPrice__c,
                ChargentOrders__Bank_Account_Number__c,ChargentOrders__Bank_Routing_Number__c, ARC_UpdatePaymentMethod__c
                FROM ChargentOrders__ChargentOrder__c
                WHERE Id IN :futureOrderIds AND Id NOT IN :uniqueOrderIds
            ];
            
            chargentOrders.addAll(futureChargents);
        
    
    
            for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrders) {
                //Addres Information
                chargentOrder.ChargentOrders__Billing_First_Name__c = (String)paymentInformation.get('TXT_FirstName');
                chargentOrder.ChargentOrders__Billing_Last_Name__c = (String)paymentInformation.get('TXT_LastName');
                chargentOrder.ChargentOrders__Billing_City__c = (String)paymentInformation.get('TXT_UpdateBillingAddress_City');
                chargentOrder.ChargentOrders__Billing_Zip_Postal__c= (String)paymentInformation.get('TXT_UpdateBillingAddress_ZipCode');
                chargentOrder.ChargentOrders__Billing_State__c = (String)paymentInformation.get('TXT_UpdateBillingAddress_State');
                chargentOrder.ChargentOrders__Billing_Address__c = (String)paymentInformation.get('TXT_UpdateBillingAddress_Street');
    
                if (isCreditCard) {
                    chargentOrder.ChargentOrders__Card_Expiration_Month__c = String.valueOf(cardInformationMap.get('SLC_ExpirationMonth'));
                    chargentOrder.ChargentOrders__Card_Expiration_Year__c = String.valueOf(cardInformationMap.get('SLC_UpdateExpirationYear'));
                    chargentOrder.ChargentOrders__Card_Number__c = (String)cardInformationMap.get('TXT_CardNumber');
                    chargentOrder.ChargentOrders__Gateway__c = creditCardGateway;
                    chargentOrder.ChargentOrders__Payment_Method__c = 'Credit Card';
                    chargentOrder.ChargentOrders__Tokenization__c = '';
                    chargentOrder.ChargentOrders__Card_Type__c = (String)cardInformationMap.get('SLC_CardType');
                    system.debug('CardType/ChargentOrders__Card_Type__c: ' + chargentOrder.ChargentOrders__Card_Type__c);
                    //Clear Bank Information
                    chargentOrder.ChargentOrders__Bank_Account_Name__c = null;
                    chargentOrder.ChargentOrders__Bank_Account_Number__c = null;
                    chargentOrder.ChargentOrders__Bank_Account_Type__c = null;
                    chargentOrder.ChargentOrders__Bank_Name__c = null;
                    chargentOrder.ChargentOrders__Bank_Account_Last_4__c = null;
                    chargentOrder.ChargentOrders__Bank_Routing_Number__c = null;
                    chargentOrder.ARC_LastPaymentMethodUpdate__c = datetime.now();
                    
                } else if (isBankAccount){
                    chargentOrder.ChargentOrders__Bank_Account_Name__c = (String)paymentInformation.get('TXT_FirstName') + ' ' + (String)paymentInformation.get('TXT_LastName');
                    chargentOrder.ChargentOrders__Bank_Account_Number__c = (String)bankInformationMap.get('TXT_UpdateAccNumber');
                    chargentOrder.ChargentOrders__Bank_Account_Type__c = (String)bankInformationMap.get('SLC_UpdateAccType');
                    chargentOrder.ChargentOrders__Bank_Routing_Number__c = (String)bankInformationMap.get('TXT_UpdateRoutingNumber');
                    chargentOrder.ChargentOrders__Bank_Name__c = (String)bankInformationMap.get('TXT_UpdateBankName');
                    chargentOrder.ChargentOrders__Gateway__c = bankGateway;
                    chargentOrder.ChargentOrders__Payment_Method__c = 'Bank Account';
                    chargentOrder.ChargentOrders__Tokenization__c = '';
                    //Clear Credit Card Information
                    chargentOrder.ChargentOrders__Card_Expiration_Month__c = null;
                    chargentOrder.ChargentOrders__Card_Expiration_Year__c = null;
                    chargentOrder.ChargentOrders__Card_Number__c = null;
                    chargentOrder.ChargentOrders__Card_Last_4__c = null;
                    chargentOrder.ChargentOrders__Card_Type__c = null;
                    chargentOrder.ARC_LastPaymentMethodUpdate__c = datetime.now();
                }
            }
            upsert chargentOrders;
            
            chargentCollections = [
                SELECT 
                Id,
                ChargentOrders__Chargent_Order__c,
                ChargentOrders__Status__c 
                FROM ChargentOrders__Chargent_Automated_Collections__c  
                WHERE ChargentOrders__Chargent_Order__c IN: chargentOrders
            ];
                
            for(ChargentOrders__Chargent_Automated_Collections__c collection : chargentCollections){
                collection.ChargentOrders__Status__c = 'Completed (Stopped)';
            }
    
            update chargentCollections;                                                     

    }

    public static void updateAccountData(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        Id personAccountId = (Id)inputMap.get('PersonAccountId');
        if(personAccountId.getSobjectType().getDescribe().getName() == 'vlocity_ins__GroupCensusMember__c'){
            personAccountId = [SELECT vlocity_ins__ContactId__r.AccountId FROM vlocity_ins__GroupCensusMember__c WHERE Id =: personAccountId].vlocity_ins__ContactId__r.AccountId;
        }
        String firstName = (String)inputMap.get('firstName');
        String lastName = (String)inputMap.get('lastName');
        String phone = (String)inputMap.get('phone');
        String email = (String)inputMap.get('email');

        Account account = new Account(
            Id = personAccountId,
            FirstName = firstName,
            LastName = lastName,
            Phone = phone,
            PersonEmail = email,
            vlocity_ins__Email__c = email
        );
        update account;
    }

    @future (callout=true)
    public static void updatePaymentMethodDocusign(String caseId){
        Case caseRecord = [SELECT Status, ARC_CensusMember__c, ARC_Reason__c, ARC_PersonAccount__c, ARC_PersonAccount__r.ARC_Census__c, ARC_UPMSelectedPayor__c, ARC_UpdateThisAddressOnSign__c, ARC_LastDocuSignEnvelopeId__c,ARC_LastDocuSignEnvelopeStatus__c FROM Case WHERE Id =: caseId];
        System.debug('Trigger is activated, previous formatDocusignResponse');
        Map<String, Object> DocuSignValuesMap = ARC_DocusignApi.formatDocusignResponse(ARC_DocusignApi.httpGetDocumentsTabs(caseRecord.ARC_LastDocuSignEnvelopeId__c));
        System.debug('Trigger is activated, after formatDocusignResponse');

        //Update Case
        if(caseRecord.ARC_Reason__c == 'Method Change'){
            caseRecord.Status = 'Closed';
        }else if (caseRecord.ARC_Reason__c == 'Method Change' || caseRecord.ARC_Reason__c == 'App/Change Fee Decline' || caseRecord.ARC_Reason__c == 'One Time Fee Decline' ||caseRecord.ARC_Reason__c == 'Recurring Decline' ||caseRecord.ARC_Reason__c == 'First Month Decline'){
            caseRecord.Status = 'In Progress';
            caseRecord.OwnerId = [SELECT Id FROM Group WHERE DeveloperName = 'ProcessingQueue'].Id;
        }
        System.debug('CASE RECORD UPDATED: '+caseRecord);
        update caseRecord;

        //Get Orders Information
        Map<String, Object> Payment_CreateOrderToChangePaymentMethod = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex('Payment_CreateOrderToChangePaymentMethod', new Map<String, Object>{'CensusMemberId' => caseRecord.ARC_CensusMember__c}, new Map<String, Object>());
        
        Map<String, Object> BLK_PaymentInfo = new Map<String, Object>();
        BLK_PaymentInfo.put('TXT_FirstName', ((String)DocuSignValuesMap.get('FirstName')));
        BLK_PaymentInfo.put('TXT_LastName', ((String)DocuSignValuesMap.get('LastName')));
        //address
        BLK_PaymentInfo.put('TXT_UpdateBillingAddress_Street', ((String)DocuSignValuesMap.get('Street')));
        BLK_PaymentInfo.put('TXT_UpdateBillingAddress_City', ((String)DocuSignValuesMap.get('City')));
        BLK_PaymentInfo.put('TXT_UpdateBillingAddress_State', ((String)DocuSignValuesMap.get('State')));
        BLK_PaymentInfo.put('TXT_UpdateBillingAddress_ZipCode', ((String)DocuSignValuesMap.get('ZipCode')));
        
        String RAD_MethodOfPayment;
        if (Boolean.valueOf(DocuSignValuesMap.get('CreditCard')) == true) {
            Map<String, Object> BLK_UpdateCreditCard = new Map<String, Object>();
            RAD_MethodOfPayment = 'Credit Card';
		
            BLK_UpdateCreditCard.put('TXT_CardNumber', (String)DocuSignValuesMap.get('CardNumber'));
            BLK_UpdateCreditCard.put('SLC_ExpirationMonth', ((String)DocuSignValuesMap.get('CardExpiration')).substringBefore('/'));
            BLK_UpdateCreditCard.put('SLC_UpdateExpirationYear', String.valueOf(Date.today().year()).left(2) + ((String)DocuSignValuesMap.get('CardExpiration')).substringAfter('/'));
			
            BLK_UpdateCreditCard.put('SLC_CardType', identifyCardType((String)DocuSignValuesMap.get('CardNumber')));
            System.debug('SLC_CardType: '+BLK_UpdateCreditCard.get('SLC_CardType'));
            BLK_PaymentInfo.put('BLK_UpdateCreditCard', BLK_UpdateCreditCard);
            
        }else if (Boolean.valueOf(DocuSignValuesMap.get('ACH')) == true) {
            Map<String, Object> BLK_BankAccount = new Map<String, Object>();
            RAD_MethodOfPayment = 'Bank Account';

            BLK_BankAccount.put('TXT_UpdateBankName', (String)DocuSignValuesMap.get('BankName'));
            BLK_BankAccount.put('TXT_UpdateAccNumber', (String)DocuSignValuesMap.get('AccountNumber'));
            BLK_BankAccount.put('TXT_UpdateBankName', (String)DocuSignValuesMap.get('BankName'));
            BLK_BankAccount.put('TXT_UpdateRoutingNumber', (String)DocuSignValuesMap.get('RoutingNumber'));
            BLK_BankAccount.put('SLC_UpdateAccType', Boolean.valueOf(DocuSignValuesMap.get('Checking')) == true ? 'Checking': Boolean.valueOf(DocuSignValuesMap.get('Savings')) == true? 'Savings' : null);

            BLK_PaymentInfo.put('BLK_BankAccount', BLK_BankAccount);
        }

        //Updates Orders Information
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> output = new Map<String, Object>();
        
        input.put('BankAccountGateway', Payment_CreateOrderToChangePaymentMethod.get('BankAccountGateway'));
        input.put('CreditCardGateway', Payment_CreateOrderToChangePaymentMethod.get('CreditCardGateway'));
        input.put('OneTimeFeeOrder', Payment_CreateOrderToChangePaymentMethod.get('OneTimeFeeOrder'));
        input.put('AppFeeOrder', Payment_CreateOrderToChangePaymentMethod.get('AppFeeOrder'));
        input.put('RecurringOrder', Payment_CreateOrderToChangePaymentMethod.get('RecurringOrder'));
        input.put('Step_SetRecurring', new Map<String,Object>{'RAD_ConfirmSetRecurring'=> null});
        input.put('Step_Instructions', new Map<String,Object>{'BLK_PaymentInfo' => BLK_PaymentInfo});


        Map<String, Object> Payment_UpdatePaymentMethod = (Map<String, Object>) vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex('UpdatePaymentMethod_UpdateChargentOrder', input, output);
        if(caseRecord.ARC_UPMSelectedPayor__c != null && caseRecord.ARC_UPMSelectedPayor__c != 'Third Party Payor' && caseRecord.ARC_UpdateThisAddressOnSign__c != 'None'){
            input.clear();
            input.put('PersonAccountId', caseRecord.ARC_UPMSelectedPayor__c);
            input.put('addressInformationFor', caseRecord.ARC_UpdateThisAddressOnSign__c);
            input.put('state', (String)DocuSignValuesMap.get('State'));
            input.put('city', (String)DocuSignValuesMap.get('City'));
            input.put('street', (String)DocuSignValuesMap.get('Street'));
            input.put('zip', (String)DocuSignValuesMap.get('ZipCode'));
            input.put('censusId',caseRecord.ARC_PersonAccount__r.ARC_Census__c);
            ARC_UpdatePaymentMethod.updateAddresses(input, new Map<String,Object>(), new Map<String,Object>());
            
            input.clear();
        
            input.put('PersonAccountId', caseRecord.ARC_UPMSelectedPayor__c);
            input.put('firstName', (String)DocuSignValuesMap.get('FirstName'));
            input.put('lastName', (String)DocuSignValuesMap.get('LastName'));
            input.put('phone', (String)DocuSignValuesMap.get('Phone'));
            input.put('email', (String)DocuSignValuesMap.get('EmailAddress'));
            
            ARC_UpdatePaymentMethod.updateAccountData(input, new Map<String,Object>(), new Map<String,Object>());
        }

        //Email
        Map<String,Object> inputMapMail = new Map<String,Object>();
        inputMapMail.put('MemberId', Payment_CreateOrderToChangePaymentMethod.get('MemberId'));
        inputMapMail.put('MemberEmail', (String)DocuSignValuesMap.get('EmailAddress'));
        inputMapMail.put('firstName', (String)DocuSignValuesMap.get('FirstName'));
        inputMapMail.put('caseId', caseId);
        inputMapMail.put('Step_Instructions', new Map<String,Object>{'BLK_PaymentInfo' => BLK_PaymentInfo});
        inputMapMail.put('STEP_ChooseMethod', new Map<String,Object>{'RAD_MethodOfPayment' => RAD_MethodOfPayment});
        inputMapMail.put('OldChargeDate', Payment_CreateOrderToChangePaymentMethod.get('OldChargeDate'));
        inputMapMail.put('OldPaymentNextTransactionDate', Payment_CreateOrderToChangePaymentMethod.get('OldPaymentNextTransactionDate'));
        inputMapMail.put('OldPaymentStartDate', Payment_CreateOrderToChangePaymentMethod.get('OldPaymentStartDate'));
        System.debug(inputMapMail);
        ARC_Emails.sendChangePaymentMethodConfirmation(inputMapMail, new Map<String,Object>(), new Map<String,Object>());
    }


    public static void getCardType(Map<String, Object> input, Map<String, Object> outMap, Map<String, Object> options) {
        String cardNumber = (String) input.get('cardNumber');
        String cardType = identifyCardType(cardNumber);
        outMap.put('isVisa', cardType == 'Visa');
        outMap.put('isMasterCard', cardType == 'MasterCard');
        outMap.put('isAmericanExpress', cardType == 'American Express');
        outMap.put('isDiscover', cardType == 'Discover');
    }

    public static String identifyCardType(String cardNumber){
        if(cardNumber == null || cardNumber.length() < 7){
            system.debug('Unknown card type');
            return 'Unknown card type';
        }
        // Check for Visa
        else if (cardNumber.startsWith('4')) {
            system.debug('Visa');
            return 'Visa';
        }
        // Check for MasterCard
        else if (cardNumber.startsWith('51') || cardNumber.startsWith('52') || 
                cardNumber.startsWith('53') || cardNumber.startsWith('54') || 
                cardNumber.startsWith('55') || 
                (Integer.valueOf(cardNumber.substring(0, 2)) >= 22 && 
                Integer.valueOf(cardNumber.substring(0, 2)) <= 27)) {
            system.debug('MasterCard');
            return 'MasterCard';
        }

        // Check for Discover
        else if (cardNumber.startsWith('6011') || 
                (Integer.valueOf(cardNumber.substring(0, 6)) >= 622126 && 
                Integer.valueOf(cardNumber.substring(0, 6)) <= 622925) || 
                (Integer.valueOf(cardNumber.substring(0, 3)) >= 644 && 
                Integer.valueOf(cardNumber.substring(0, 3)) <= 649) || 
                cardNumber.startsWith('65')) {
            system.debug('Discover');
            return 'Discover';
        }
        // Check for American Express
        else if (cardNumber.startsWith('3') && cardNumber.length() == 15){
            system.debug('American Express');
            return 'American Express';
        }
        // If none of the above, return unknown
        else {
            return 'Unknown card type';
        }
    }

}