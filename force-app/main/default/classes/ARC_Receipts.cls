/*******************************************************************
* @ClassName          :   ARC_Receipts
* @Description        :   Builds the map with receipts information for each transaction to display in the ARC_docGenerationReceipts Omniscript.
* @MethodName         :   getDocumentInformation, formatDate
********************************************************************/


global with sharing class ARC_Receipts implements vlocity_ins.VlocityOpenInterface
{
    global Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        if (methodName == 'getDocumentInformation'){
            getDocumentInformation(inputMap, outputMap, options);
        }
        return true;
    }

    /*******************************************************************
    * @MethodName         :   getDocumentInformation
    * @Description        :   Retrieves the information needed to generate the PDF document, queries either All or just Monthly transactions which belong to any of the contracts selected
    * and are between the FROM and TO date, depending on the input entered by the user in the omniscript ARC_docGenerationReceipts.
    ********************************************************************/
    public void getDocumentInformation(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options){
        List<Map<String, Object>> transactionsList = new List<Map<String, Object>>();
        List<Map<String, Object>> programList = new List<Map<String, Object>>();

        /* INPUTS */
        Id contextId = (Id)inputMap.get('contextId');
        Date fromDate = String.isNotEmpty((String)inputMap.get('FromDate'))? Date.valueOf((String)inputMap.get('FromDate')) : null;
        Date toDate = String.isNotEmpty((String)inputMap.get('ToDate'))? Date.valueOf((String)inputMap.get('ToDate')) : null;
        List<Object> contracts = (List<Object>)inputMap.get('Contracts');
        String inputTransactionType = String.valueOf(inputMap.get('transactionType'));
        String inputChargeType = String.valueOf(inputMap.get('chargeType'));
        String responseStatus='';
        if(inputChargeType.contains('Charge')||inputChargeType.contains('Refund'))responseStatus ='Approved';
        if(inputChargeType.contains('Decline')) responseStatus +='Declined;Rejected';
        
        if (contextId.getSobjectType().getDescribe().getName() == 'Account') {
            Account acc = [SELECT Id,Name,Phone,PersonEmail,ARC_Member_Id__c,ARC_IsPrimaryMember__c,ARC_E123MemberIdFromPolicy__c,ARC_PrimaryMemberAccount__r.ARC_Member_Id__c,ARC_PrimaryMemberAccount__r.ARC_E123MemberIdFromPolicy__c FROM Account WHERE Id = :contextId LIMIT 1];
            outputMap.put('MemberName', acc.Name);
            outputMap.put('Phone', acc.Phone);
            outputMap.put('Email', acc.PersonEmail);
            outputMap.put('Transactions', transactionsList);
            outputMap.put('Programs', programList);

            if(fromDate != null && toDate != null) outputMap.put('DateRange',formatDate(fromDate)+ '_To_'+formatDate(toDate.addDays(-1)));
            String memberId;
            if (acc.ARC_IsPrimaryMember__c != null && acc.ARC_IsPrimaryMember__c) {
                memberId = acc.ARC_E123MemberIdFromPolicy__c != null? acc.ARC_E123MemberIdFromPolicy__c : acc.ARC_Member_Id__c;
            } else {
                memberId = acc.ARC_PrimaryMemberAccount__r?.ARC_E123MemberIdFromPolicy__c != null ? acc.ARC_PrimaryMemberAccount__r?.ARC_E123MemberIdFromPolicy__c : acc.ARC_PrimaryMemberAccount__r?.ARC_Member_Id__c;
            }
            outputMap.put('AccountId', memberId);

        }else if (contextId.getSobjectType().getDescribe().getName() == 'vlocity_ins__GroupCensusMember__c'){
            vlocity_ins__GroupCensusMember__c cm = [SELECT vlocity_ins__IsPrimaryMember__c,vlocity_ins__ContactId__r.Account.Id, vlocity_ins__ContactId__r.Account.Name, vlocity_ins__ContactId__r.Account.Phone,vlocity_ins__ContactId__r.Account.PersonEmail,vlocity_ins__RelatedCensusMemberId__r.Member_ID__c,vlocity_ins__RelatedCensusMemberId__r.e123_member_id_from_policy__c,e123_member_id_from_policy__c,Member_ID__c FROM vlocity_ins__GroupCensusMember__c WHERE Id = :contextId LIMIT 1];
            outputMap.put('MemberName', cm.vlocity_ins__ContactId__r.Account.Name);
            outputMap.put('Phone', cm.vlocity_ins__ContactId__r.Account.Phone);
            outputMap.put('Email', cm.vlocity_ins__ContactId__r.Account.PersonEmail);
            outputMap.put('Transactions', transactionsList);
            outputMap.put('Programs', programList);

            String memberId;
            if (cm.vlocity_ins__IsPrimaryMember__c != null && cm.vlocity_ins__IsPrimaryMember__c) {
                memberId = cm.e123_member_id_from_policy__c != null? cm.e123_member_id_from_policy__c : cm.Member_ID__c;
            } else {
                memberId = cm.vlocity_ins__RelatedCensusMemberId__r?.e123_member_id_from_policy__c != null ? cm.vlocity_ins__RelatedCensusMemberId__r?.e123_member_id_from_policy__c : cm.vlocity_ins__RelatedCensusMemberId__r?.Member_ID__c;
            }
            outputMap.put('AccountId', memberId);
        }

        if(contracts.size() == 1){
            Map<String,Object> contract = (Map<String,Object>)contracts[0];
            contract.put('CHECK_ContractSelected',true);
        }

        List<String> contractsSelected = new List<String>();
        for (Object contract : contracts) {
            Map<String,Object> c = (Map<String,Object>)contract;
            if (c.get('CHECK_ContractSelected') == true) {
                contractsSelected.add((String)c.get('Number'));
            }
        }
 
        // String queryString = 'SELECT Id, Name, ChargentOrders__Order__c,ChargentOrders__Gateway_Date__c,ChargentOrders__Type__c, ChargentOrders__Amount__c, ChargentOrders__Payment_Method__c, ChargentOrders__Response_Status__c, ChargentOrders__Bank_Account_Last_4__c, ChargentOrders__Card_Last_4__c, CreatedDate,ChargentOrders__Order__r.ChargentOrders__Description__c,ARC_Reason__c,ChargentOrders__Order__r.ChargentOrders__Billing_First_Name__c,ChargentOrders__Order__r.ChargentOrders__Billing_Last_Name__c,ARC_Cover_From__c,ARC_Cover_To__c,(SELECT Id,Name,ARC_Product__r.Name,ARC_Amount__c,ARC_Transaction__c,ARC_Type__c FROM Transaction_Line_Items__r ORDER BY ARC_Type__c DESC) FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Order__r.ARC_Contract__r.ContractNumber IN :contractsSelected';

        String queryString = 'SELECT Id, Name, ChargentOrders__Order__c,ChargentOrders__Gateway_Date__c,ChargentOrders__Type__c, ChargentOrders__Amount__c, ChargentOrders__Payment_Method__c, ChargentOrders__Response_Status__c, ChargentOrders__Bank_Account_Last_4__c, ChargentOrders__Card_Last_4__c, CreatedDate,ChargentOrders__Order__r.ChargentOrders__Description__c,ARC_Reason__c,ChargentOrders__Order__r.ChargentOrders__Billing_First_Name__c,ChargentOrders__Order__r.ChargentOrders__Billing_Last_Name__c,ARC_Cover_From__c,ARC_Cover_To__c, ChargentOrders__Order__r.ARC_Contract__r.ARC_EffectiveDate__c, ChargentOrders__Order__r.ARC_Contract__r.ARC_Inactive_Date__c,ChargentOrders__Order__r.ARC_Contract__r.ContractNumber,(SELECT Id,Name,ARC_Product__r.Name,ARC_Amount__c,ARC_Transaction__c,ARC_Type__c,ARC_Product__c, ARC_PromotionDiscount__c FROM Transaction_Line_Items__r ORDER BY ARC_Type__c DESC) FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Order__r.ARC_Contract__r.ContractNumber IN :contractsSelected';

        if (fromDate != null) {
            queryString += ' AND ChargentOrders__Gateway_Date__c >= :fromDate';
        }
        if (toDate != null) {
            queryString += ' AND ChargentOrders__Gateway_Date__c <= :toDate';
        }
        //Check transaction type filter input
        if(inputTransactionType.contains('Recurring') && !inputTransactionType.contains('Fees')){
            queryString += ' AND ChargentOrders__Order__r.ChargentOrders__Description__c = \'Recurring Monthly Order\' AND (ARC_Reason__c = \'Recurring Monthly Order\' OR ARC_Reason__c = \'Recurring Monthly Order Refund\')';
        }
        else if(!inputTransactionType.contains('Recurring') && inputTransactionType.contains('Fees')){
            queryString += ' AND (ChargentOrders__Order__r.ChargentOrders__Description__c != \'Recurring Monthly Order\' OR (ChargentOrders__Order__r.ChargentOrders__Description__c = \'Recurring Monthly Order\' AND (ARC_Reason__c != \'Recurring Monthly Order\' AND ARC_Reason__c != \'Recurring Monthly Order Refund\')))';
        }
        queryString += ' ORDER BY ChargentOrders__Gateway_Date__c ASC';


        List<vlocity_ins__ContractLineItem__c> contractLineItems = [SELECT Id, Name, vlocity_ins__ProductType__c,vlocity_ins__ContractId__r.ContractNumber, (SELECT Id, vlocity_ins__GroupCensusMemberId__r.Name FROM vlocity_ins__Group_Census_Member_Plan__r) FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__r.ContractNumber IN :contractsSelected AND vlocity_ins__ProductType__c = 'Medical' AND vlocity_ins__ParentItemId__c = null];

        List<String> cliMemberList = new List<String>();
        Map<String, List<String>> contractMembersMap = new Map<String, List<String>>();//

        for(vlocity_ins__ContractLineItem__c cli: contractLineItems){
            List<String> members = contractMembersMap.containsKey(cli.vlocity_ins__ContractId__r.ContractNumber)?contractMembersMap.get(cli.vlocity_ins__ContractId__r.ContractNumber):new List<String>();

            for(vlocity_ins__GroupCensusMemberPlan__c gcmp: cli.vlocity_ins__Group_Census_Member_Plan__r){    
                members.add(gcmp.vlocity_ins__GroupCensusMemberId__r.Name);
                // members.add(String.join(gcmp.vlocity_ins__GroupCensusMemberId__r.Name), ', ');
                // String.join(cliMemberList, ', ')
            }
            contractMembersMap.put(cli.vlocity_ins__ContractId__r.ContractNumber,members);
        }
        

        List<ChargentOrders__Transaction__c> transactions = Database.query(queryString);
        if (transactions.size() > 0) {
            for(ChargentOrders__Transaction__c t : transactions){
                //Filter based on charge type
                if(inputChargeType.contains(t.ChargentOrders__Type__c) || (inputChargeType?.contains('Refund') && t.ChargentOrders__Type__c.contains('Chargeback')) || (inputChargeType?.contains('Decline') && (t.ChargentOrders__Response_Status__c == 'Declined' || t.ChargentOrders__Response_Status__c == 'Rejected'))){
                    //Filter based on response status
                    if(responseStatus.contains(t.ChargentOrders__Response_Status__c) && t.ChargentOrders__Order__c != null){
                        Decimal totalAmount = 0;
                        Map<String,Object> corePlan = null;
                        Map<String,Object> healthyDiscount = null;
                        String transactionReason = t.ARC_Reason__c;
                        String transactionType = t.ChargentOrders__Type__c;
                        String orderDescription = t.ChargentOrders__Order__r?.ChargentOrders__Description__c;
                        Boolean recurringOrder = orderDescription?.equals('Recurring Monthly Order') && (transactionReason?.equals('Recurring Monthly Order') || transactionReason?.equals('Recurring Monthly Order Refund'));
                        Boolean e123Order = orderDescription?.equals('Chargent Order to Hold E123 Transactions Only') && (transactionType.equals('Charge') || transactionType.equals('Chargeback') || transactionType.equals('Refund'));
                        Boolean appFee = orderDescription?.equals('App Fee');
                        Boolean changeFee = transactionReason?.equals('Change Fee') || transactionReason?.equals('Change Fee Refund');
                        Boolean oneTimeFee = orderDescription?.contains('One-Time Fee');
    
                        List<Map<String,Object>> TLIList = new List<Map<String,Object>>();
                        List<String> TLIitems = new List<String>();


                        //Recurring or E123 with transaction line items
                        if (recurringOrder || e123Order ) {
                            if(t.Transaction_Line_Items__r?.size() > 0){
                                List<ARC_TransactionLineItem__c> sortedTLI = sortTLI(t.Transaction_Line_Items__r);
                                for(ARC_TransactionLineItem__c tli : sortedTLI){
                                    Map<String,Object> TLIinfo = new Map<String,Object>{
                                        'ProductName'=>tli.Name,
                                        'ProductAmount'=>String.valueOf(tli.ARC_Amount__c?.setScale(2)),
                                        'Programs'=>tli.Name + ', '
                                    };
                                    TLIList.add(TLIinfo);
                                    totalAmount += tli.ARC_Amount__c;
                                    TLIitems.add(tli.Name);
                                }
                            // Recurring or E123 without transaction line items
                            } else {
                                String name = transactionType.equals('Refund')? 'Refund' : transactionType.equals('Chargeback')?'Chargeback':'Charge';
                                Decimal productAmount = t.ChargentOrders__Amount__c != null ? t.ChargentOrders__Amount__c?.setScale(2) : 0;
                                String productAmountString = String.valueOf(productAmount.abs());
                                String productAmountFormatCurrency = productAmount < 0 ? '-$' + productAmountString : '$' + productAmountString;


                                Map<String, Object> TLIinfo = new Map<String, Object>{
                                    'ProductName' => name,
                                    'ProductAmount' => productAmountFormatCurrency
                                };
                                TLIList.add(TLIinfo);
                                totalAmount = t.ChargentOrders__Amount__c;
                            }
                        //Everything else
                        } else if ( appFee || changeFee || oneTimeFee ){
                            if(t.Transaction_Line_Items__r?.size() > 0){
                                List<ARC_TransactionLineItem__c> orderedList =sortTLI(t.Transaction_Line_Items__r);
                                if (t.Transaction_Line_Items__r.size() == 2) {
                                    if (t.Transaction_Line_Items__r[0].ARC_Amount__c.abs() < t.Transaction_Line_Items__r[1].ARC_Amount__c.abs()) {
                                        ARC_TransactionLineItem__c temp = t.Transaction_Line_Items__r[0];
                                        orderedList[0] = t.Transaction_Line_Items__r[1];
                                        orderedList[1] = temp;
                                    }
                                }
                                for(ARC_TransactionLineItem__c tli : orderedList){
                                    Map<String,Object> TLIinfo = new Map<String,Object>{
                                        'ProductName'=>tli.Name,
                                        'ProductAmount'=>String.valueOf(tli.ARC_Amount__c?.setScale(2))
                                    };
                                    TLIList.add(TLIinfo);
                                    totalAmount += tli.ARC_Amount__c;
                                }                           
                            }
                        }

                        if (recurringOrder || e123Order || appFee || changeFee || oneTimeFee) {
                            Decimal transactionAmount = t.ChargentOrders__Amount__c != null ? t.ChargentOrders__Amount__c?.setScale(2) : 0;
                            Decimal totalDecimalAmount = totalAmount != null ? totalAmount?.setScale(2) : 0;

                            String transactionAmountString = String.valueOf(transactionAmount.abs());
                            String totalAmountString = String.valueOf(totalDecimalAmount.abs());

                            String transactionAmountFormatCurrency = transactionAmount < 0 ? '-$' + transactionAmountString : '$' + transactionAmountString;
                            String totalAmountFormatCurrency = totalDecimalAmount < 0 ? '-$' + totalAmountString : '$' + totalAmountString;


                            //TRANSACTION INFORMATION
                            Map<String, Object> transactionInfo = new Map<String, Object>();
                            transactionInfo.put('TransactionDate', formatDate(t.ChargentOrders__Gateway_Date__c?.date()));
                            transactionInfo.put('TransactionOrder', t.ChargentOrders__Order__c);
                            transactionInfo.put('TransactionAmount', transactionAmountFormatCurrency);
                            transactionInfo.put('TransactionType', t.ChargentOrders__Type__c);
                            transactionInfo.put('TotalAmount', totalAmountFormatCurrency);
                            if (t.ARC_Cover_From__c != null && t.ARC_Cover_To__c != null) {
                                transactionInfo.put('CoveragePeriod',formatDate(t.ARC_Cover_From__c) +' | '+ formatDate(t.ARC_Cover_To__c));
                            }
                            transactionInfo.put('PaymentType', t.ChargentOrders__Payment_Method__c);
                            transactionInfo.put('PaymentMethod', t.ChargentOrders__Bank_Account_Last_4__c != null ? t.ChargentOrders__Bank_Account_Last_4__c : t.ChargentOrders__Card_Last_4__c);
                            transactionInfo.put('PaymentTransactionDate', t.ChargentOrders__Gateway_Date__c?.format('MM-dd-yyyy hh:mm a'));
                            transactionInfo.put('PaymentTransactionId', t.Id);
                            transactionInfo.put('PaymentTransactionStatus', t.ChargentOrders__Response_Status__c);
                            transactionInfo.put('TransactionLineItems', TLIList);
                            transactionInfo.put('BillingName', String.valueOf(t.ChargentOrders__Order__r?.ChargentOrders__Billing_First_Name__c) +' '+ String.valueOf(t.ChargentOrders__Order__r?.ChargentOrders__Billing_Last_Name__c));

                            transactionInfo.put('ContractEffectiveDate', formatDate(t.ChargentOrders__Order__r.ARC_Contract__r.ARC_EffectiveDate__c));
                            if (t.ChargentOrders__Order__r.ARC_Contract__r.ARC_Inactive_Date__c == null) {
                                transactionInfo.put('ContractaInactiveDate', 'N/A');
                            }else{
                                transactionInfo.put('ContractaInactiveDate', formatDate(t.ChargentOrders__Order__r.ARC_Contract__r.ARC_Inactive_Date__c));
                            }                          
                            transactionInfo.put('ProgramLineItems', String.join(TLIitems, ', '));
                            transactionInfo.put('ContractMembers', contractMembersMap.get(t.ChargentOrders__Order__r?.ARC_Contract__r?.ContractNumber));


                            transactionsList.add(transactionInfo);

                        }
                    }
                }
            }
        }

    }
    
    /*******************************************************************
    * @MethodName         :   formatDate
    * @Description        :   format the date into MM-DD-YYYY format
    ********************************************************************/
    public static String formatDate(Date d){
        if(d != null){
            DateTime dt = DateTime.newInstance(d, Time.newInstance(0, 0, 0, 0));
            return dt.format('MM-dd-yyyy');
        }
        else return null;
    }

    /*******************************************************************
    * @MethodName         :   sortTLI
    * @Description        :   Return a list of TLI based on this priority:
                              1 Medical Product
                              2 Ancillary Products
                              3 Fees
                              4 The rest of TLI not Discounts
                              5 Medical Discounts
                              6 The rest of TLI Discounts
    ********************************************************************/
    public static List<ARC_TransactionLineItem__c> sortTLI(List<ARC_TransactionLineItem__c> tliList){
        List<ARC_TransactionLineItem__c> resultList = new List<ARC_TransactionLineItem__c>();
        Map<Integer,List<ARC_TransactionLineItem__c>> priorityTLIMap = new Map<Integer,List<ARC_TransactionLineItem__c>>();
        for(ARC_TransactionLineItem__c tli :tliList){
            switch on tli.ARC_Type__c {
                when 'Medical' {
                    if(tli.ARC_Product__c <> null)priorityTLIMap.put(1,new List<ARC_TransactionLineItem__c>{tli});
                    else if(tli.ARC_PromotionDiscount__c<>null) {
                        if(priorityTLIMap.containsKey(5))  priorityTLIMap.get(5).add(tli);
                        else priorityTLIMap.put(5,new List<ARC_TransactionLineItem__c>{tli});
                    }
                }
                when 'Ancillary'{
                    if(priorityTLIMap.containsKey(2)) priorityTLIMap.get(2).add(tli);
                    else priorityTLIMap.put(2,new List<ARC_TransactionLineItem__c>{tli});
                }
                when 'Fee'{
                    if(priorityTLIMap.containsKey(3)) priorityTLIMap.get(3).add(tli);
                    else priorityTLIMap.put(3,new List<ARC_TransactionLineItem__c>{tli});
                }
                when else {
                    if(tli.ARC_PromotionDiscount__c == null){
                        if(priorityTLIMap.containsKey(4)) priorityTLIMap.get(4).add(tli);
                        else priorityTLIMap.put(4,new List<ARC_TransactionLineItem__c>{tli});
                    }
                    else {
                        if(priorityTLIMap.containsKey(6)) priorityTLIMap.get(6).add(tli);
                        else priorityTLIMap.put(6,new List<ARC_TransactionLineItem__c>{tli});
                    }
                }
            }
        }
        for(Integer i = 1; i<7;i++){
            if(priorityTLIMap.containsKey(i)){
                for(ARC_TransactionLineItem__c tli: priorityTLIMap.get(i)){
                    resultList.add(tli);
                }
            }
        }
        return resultList;

        

    }
}