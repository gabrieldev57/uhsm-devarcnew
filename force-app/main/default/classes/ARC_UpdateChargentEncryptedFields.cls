/*******************************************************************
* @ClassName          :   ARC_UpdateChargentEncryptedFields
* @Description        :   Update the actual and future Chargent Orders after a Update Payment Method run
* @MethodName         :   updateChargentEncryptedFields
********************************************************************/
global without sharing class  ARC_UpdateChargentEncryptedFields implements vlocity_ins.VlocityOpenInterface {
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'updateChargentEncryptedFields') {
            updateChargentEncryptedFields(inputMap, outputMap, options);
        }        
        return true;
    }
     /***********************************************************************************
    * @MethodName         :   updateChargentEncryptedFields
    * @Description        :   Receive Data from an IP and do the logic to Update the Encrypted Fields of the Chargent Orders
    **************************************************************************************/
    public static void updateChargentEncryptedFields(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        List<Map<String,Object>> orders = (List<Map<String,Object>>)inputMap.get('orders');
        Map<String,Object> paymentInformation = (Map<String,Object>)inputMap.get('paymentInformation');
        String creditCardGateway = (String)inputMap.get('creditCardGateway');
        String bankGateway = (String)inputMap.get('bankGateway');
        String setRecurring = (String)inputMap.get('setRecurring');
        Set<Id> ordersId = new Set<Id>();
        for(Map<String,Object> order : orders){
            ordersId.add((Id)order.get('Id'));
        }
        
        List<ChargentOrders__ChargentOrder__c> chargent = [
            SELECT Id, 
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
            (SELECT Id, ChargentOrders__Response_Status__c 
            FROM ChargentOrders__Transactions__r 
            ORDER BY CreatedDate DESC LIMIT 1) 
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN :ordersId];

        List<ChargentOrders__ChargentOrder__c> chargentFirstUpdate = new List<ChargentOrders__ChargentOrder__c>();
        for (ChargentOrders__ChargentOrder__c chargentOrder : chargent) {
            if(chargentOrder.ChargentOrders__Description__c == 'Recurring Monthly Order' && setRecurring != null && setRecurring == 'Yes'){
                chargentOrder.ChargentOrders__Payment_Status__c = 'Recurring';
                chargentFirstUpdate.add(chargentOrder);
            }
        }
        if(chargentFirstUpdate.size() != 0){
            update chargent;
        }

        List<Contract> contract = [SELECT Id,vlocity_ins__EnrollmentCensusId__c,CreatedDate,ARC_OneTimeFeeOrder__c,ARC_RecurringMonthlyOrder__c,ARC_AppFeeOrder__c 
                                  FROM Contract 
                                  WHERE Id = :chargent[0].ARC_Contract__c];

        Id censusId = contract[0].vlocity_ins__EnrollmentCensusId__c;
        Datetime contractCreatedDate = contract[0].CreatedDate;

        List<Contract> futureContracts = new List<Contract>([
            SELECT ARC_RecurringMonthlyOrder__c,ARC_OneTimeFeeOrder__c,ARC_AppFeeOrder__c
            FROM Contract
            WHERE vlocity_ins__EnrollmentCensusId__c = :censusId
            AND CreatedDate > :contractCreatedDate
        ]);

        Set<Id> futureOrdersIds = new Set<Id>();
        for (Contract c : futureContracts) {
            if(c.ARC_RecurringMonthlyOrder__c != null){
                futureOrdersIds.add(c.ARC_RecurringMonthlyOrder__c);
            }
            if(c.ARC_OneTimeFeeOrder__c != null){
                futureOrdersIds.add(c.ARC_OneTimeFeeOrder__c);
            }
            if(c.ARC_AppFeeOrder__c != null){
                futureOrdersIds.add(c.ARC_AppFeeOrder__c);
            }
        }

        List<ChargentOrders__ChargentOrder__c> futureChargents = [
            SELECT Id,ChargentOrders__Card_Number__c,ARC_Contract__c,ChargentOrders__Account__c,ChargentOrders__Bank_Account_Last_4__c,ChargentOrders__Bank_Account_Name__c,
            ChargentOrders__Bank_Account_Type__c,ChargentOrders__Bank_Name__c,ChargentOrders__Billing_Address__c,ChargentOrders__Billing_City__c,
            ChargentOrders__Billing_Email__c,ChargentOrders__Billing_First_Name__c,ChargentOrders__Billing_Last_Name__c,ChargentOrders__Billing_State__c,
            ChargentOrders__Billing_Zip_Postal__c,ChargentOrders__Card_Last_4__c,ChargentOrders__Card_Month_Indicator__c,ChargentOrders__Card_Type__c,
            ChargentOrders__Card_Year_Indicator__c,ChargentOrders__Charge_Amount__c,ChargentOrders__Description__c,ChargentOrders__Gateway__c,
            ChargentOrders__Payment_Frequency__c,ChargentOrders__Payment_Method__c,ChargentOrders__Payment_Status__c,ChargentOrders__Payment_Stop__c,
            ChargentOrders__Subtotal__c,ChargentOrders__Tokenization__c,ARC_Contract__r.ARC_TotalPrice__c,
            ChargentOrders__Bank_Account_Number__c,ChargentOrders__Bank_Routing_Number__c, ARC_UpdatePaymentMethod__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE Id IN :futureOrdersIds
        ];
        
        chargent.addAll(futureChargents);
	
        Map<String,Object> cardInformationMap =  (Map<String,Object>)paymentInformation.get('BLK_UpdateCreditCard');
        Map<String,Object> bankInformationMap =  (Map<String,Object>)paymentInformation.get('BLK_BankAccount');

        Boolean creditCard = cardInformationMap != null;
        Boolean bankAccount = bankInformationMap != null;

        for (ChargentOrders__ChargentOrder__c ro : chargent) {
            if (creditCard) {
                ro.ChargentOrders__Card_Expiration_Month__c = (String)cardInformationMap.get('SLC_ExpirationMonth');
                ro.ChargentOrders__Card_Expiration_Year__c = (String)cardInformationMap.get('SLC_UpdateExpirationYear');
                ro.ChargentOrders__Card_Number__c = (String)cardInformationMap.get('TXT_CardNumber');
                ro.ChargentOrders__Gateway__c = creditCardGateway;
                ro.ChargentOrders__Payment_Method__c = 'Credit Card';
                ro.ChargentOrders__Tokenization__c = '';
                ro.ChargentOrders__Billing_First_Name__c = (String)cardInformationMap.get('TXT_UpdateFirstNameOnCard');
                ro.ChargentOrders__Billing_Last_Name__c = (String)cardInformationMap.get('TXT_UpdateLastNameOnCard');
                ro.ChargentOrders__Billing_City__c = (String)cardInformationMap.get('TXT_UpdateBillingAddress_City');
                ro.ChargentOrders__Billing_Zip_Postal__c= (String)cardInformationMap.get('TXT_UpdateBillingAddress_ZipCode');
                ro.ChargentOrders__Billing_State__c = (String)cardInformationMap.get('TXT_UpdateBillingAddress_State');
                ro.ChargentOrders__Billing_Address__c = (String)cardInformationMap.get('TXT_UpdateBillingAddress_Street');
               
                ro.ChargentOrders__Bank_Account_Name__c = null;
                ro.ChargentOrders__Bank_Account_Number__c = null;
                ro.ChargentOrders__Bank_Account_Type__c = null;
                ro.ChargentOrders__Bank_Name__c = null;
                ro.ChargentOrders__Bank_Account_Last_4__c = null;
                ro.ChargentOrders__Bank_Routing_Number__c = null;
                ro.ARC_LastPaymentMethodUpdate__c = datetime.now();
                
            } else if (bankAccount){
                ro.ChargentOrders__Bank_Account_Name__c = (String)bankInformationMap.get('TXT_UpdateFirstNameOnAccount') + bankInformationMap.get('TXT_UpdateLastNameOnAccount');
                ro.ChargentOrders__Bank_Account_Number__c = (String)bankInformationMap.get('TXT_UpdateAccNumber');
                ro.ChargentOrders__Bank_Account_Type__c = (String)bankInformationMap.get('SLC_UpdateAccType');
                ro.ChargentOrders__Bank_Routing_Number__c = (String)bankInformationMap.get('TXT_UpdateRoutingNumber');
                ro.ChargentOrders__Bank_Name__c = (String)bankInformationMap.get('TXT_UpdateBankName');
                ro.ChargentOrders__Gateway__c = bankGateway;
                ro.ChargentOrders__Payment_Method__c = 'Bank Account';
                ro.ChargentOrders__Tokenization__c = '';

                ro.ChargentOrders__Card_Expiration_Month__c = null;
                ro.ChargentOrders__Card_Expiration_Year__c = null;
                ro.ChargentOrders__Card_Number__c = null;
                ro.ChargentOrders__Card_Last_4__c = null;
                ro.ChargentOrders__Card_Type__c = null;
                ro.ARC_LastPaymentMethodUpdate__c = datetime.now();

            }
        }
        upsert chargent;

        List<ChargentOrders__Chargent_Automated_Collections__c > chargentCollections = [SELECT Id,ChargentOrders__Chargent_Order__c,ChargentOrders__Status__c 
                                                                                        FROM ChargentOrders__Chargent_Automated_Collections__c  
                                                                                        WHERE ChargentOrders__Chargent_Order__c IN: chargent];
        for(ChargentOrders__Chargent_Automated_Collections__c collection : chargentCollections){
            collection.ChargentOrders__Status__c = 'Completed (Stopped)';
        }
        update chargentCollections;

        User currentUser = [SELECT Id,Profile.Name, ContactId FROM User WHERE Id =: UserInfo.getUserId()];

        if(currentUser.Profile.Name == 'Member Community'){
            Account personAccount = [SELECT Id, PersonContactId, isPersonAccount FROM Account WHERE PersonContactId =: currentUser.ContactId AND isPersonAccount = true];
			
            List<Case> declinedCases = [SELECT Id, OwnerId FROM Case WHERE ARC_PersonAccount__c =:personAccount.Id AND Status != 'Closed'AND Case_Type__c ='Contribution' AND( ARC_Reason__c = 'First Month Decline' OR ARC_Reason__c = 'Recurring Decline' OR ARC_Reason__c = 'One Time Fee Decline' OR ARC_Reason__c ='App/Change Fee Decline')];

            if(declinedCases.size()>0){
                List<Group> processingQueue = [SELECT Id FROM Group WHERE DeveloperName ='ProcessingQueue' LIMIT 1];
                List<User> integrationUser = [SELECT Id,Name FROM  User WHERE Name = 'Integration User'];
                List<Task> tasksToCreate = new List<Task>();
                for(Case declinedCase: declinedCases){
                    Task upmTask = new Task(
                        WhoId = currentUser.ContactId,
                        WhatId = declinedCase.Id,
                        Subject = 'Member updated method via the portal',
                        Description = 'Member updated method via the portal',
                        ActivityDate = Date.today(),
                        Status = 'Not Started',
                        OwnerId = integrationUser[0].Id
                    );
                    tasksToCreate.add(upmTask);
                    declinedCase.OwnerId = processingQueue[0]?.Id;
                    declinedCase.Status = 'In Progress';
                }
                if(!Test.isRunningTest()) insert tasksToCreate;
                update declinedCases;
            }
        }
    }
}