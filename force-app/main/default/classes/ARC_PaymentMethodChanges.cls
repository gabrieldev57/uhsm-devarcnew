global with sharing class ARC_PaymentMethodChanges implements vlocity_ins.VlocityOpenInterface{
    global static Boolean invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        if (methodName.equals('getPaymentMethodUpdates')) {
            getPaymentMethodUpdates(inputMap, outMap, options);
        }
        return true;
    }

    private static List<String> trackedFields = new List<String>{'ChargentOrders__Card_Last_4__c','ChargentOrders__Bank_Account_Last_4__c','ChargentOrders__Billing_First_Name__c','ChargentOrders__Billing_Last_Name__c','ChargentOrders__Payment_Method__c'};

    private static void getPaymentMethodUpdates(Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Id personAccountId;

        // change personAccountId to recordId and put caseId on a variable

        if(((String)inputMap.get('recordId')).startsWithIgnoreCase('001')){
            personAccountId = (String)inputMap.get('recordId');
        } else if (((String)inputMap.get('recordId')).startsWithIgnoreCase('500')){
            Id CaseId = (String)inputMap.get('recordId');
            personAccountId = [SELECT ARC_PersonAccount__c FROM Case WHERE Id =: CaseId LIMIT 1].ARC_PersonAccount__c;
        }

        List<vlocity_ins__GroupCensusMemberPlan__c> plans = [
            SELECT Id, vlocity_ins__contractlineid__r.vlocity_ins__producttype__c, vlocity_ins__groupcensusmemberid__r.vlocity_ins__contactid__r.accountid, vlocity_ins__contractlineid__r.vlocity_ins__contractid__c, CreatedBy.Name, CreatedDate, Name 
            FROM vlocity_ins__GroupCensusMemberPlan__c
            WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical' 
            AND vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId =: personAccountId LIMIT 50000
        ];

        Set<Id> contractIds = new Set<Id>();
        for (vlocity_ins__GroupCensusMemberPlan__c p : plans) {
            Id contractId = p.vlocity_ins__contractlineid__r.vlocity_ins__contractid__c;
            contractIds.add(contractId);
        }

        Map<Id,ChargentOrders__ChargentOrder__c> orders = new Map<Id,ChargentOrders__ChargentOrder__c>([
            SELECT Id,Name,
            arc_contract__c,
            ARC_UpdatePaymentMethod__c,
            CreatedBy.Name, CreatedDate,
            ARC_LastPaymentMethodUpdate__c,
            LastModifiedBy.Name,
            ChargentOrders__Card_Last_4__c,
            ChargentOrders__Bank_Account_Last_4__c,
            ChargentOrders__Billing_First_Name__c,
            ChargentOrders__Billing_Last_Name__c,
            ChargentOrders__Payment_Method__c,
                (SELECT Field,OldValue,NewValue,CreatedDate,CreatedBy.Name,
                Parent.Id,
                Parent.Name,
                Parent.ARC_UpdatePaymentMethod__c,
                Parent.CreatedDate,
                Parent.CreatedBy.Name
                FROM Histories 
                ORDER BY Field DESC,CreatedDate ASC LIMIT 50000)
            FROM ChargentOrders__ChargentOrder__c
            WHERE (ARC_Contract__c IN: contractIds) LIMIT 50000
        ]);

        //Old Logic
        List <Map<String,String>> legacyPaymentMethodUpdatesList = getLegacyPaymentMethodUpdates(orders);
        //New Logic
        List <Map<String,String>> newPaymentMethodUpdatesList = getNewPaymentMethodUpdates(orders);

        //Merge both type of payment updates
        legacyPaymentMethodUpdatesList.addAll(newPaymentMethodUpdatesList);
        //Sort from most recent update to oldest update
        legacyPaymentMethodUpdatesList.sort(new ARC_UpdateDateComparator());
        findLastFieldUpdateForNullValues(legacyPaymentMethodUpdatesList);

        outMap.put('values', legacyPaymentMethodUpdatesList);
    }

    private static List<Map<String,String>> getLegacyPaymentMethodUpdates(Map<Id,ChargentOrders__ChargentOrder__c> orders){
        List<Map<String,String>> legacyPaymentMethodUpdatesList = new List<Map<String,String>>();      
        for (ChargentOrders__ChargentOrder__c o : orders.values()) {
            Boolean hasLastPaymentMethodUpdate = false;
            for (ChargentOrders__ChargentOrder__History h : o.Histories) {
                if (h.Field == 'ARC_LastPaymentMethodUpdate__c') hasLastPaymentMethodUpdate = true;
            }
            if(o.ARC_UpdatePaymentMethod__c == true && hasLastPaymentMethodUpdate == false){
                Map<String, String> paymentMethodChange = new Map<String, String>();
                paymentMethodChange.put('OrderName', String.valueOf(o.Name));
                paymentMethodChange.put('OrderId', String.valueOf(o.Id));
                paymentMethodChange.put('UpdateDate', String.valueOf(o.CreatedDate));
                paymentMethodChange.put('OrderDate', String.valueOf(o.CreatedDate.format('MM/dd/yyy')));
                paymentMethodChange.put('UpdatePaymentMethod', String.valueOf(o.ARC_UpdatePaymentMethod__c));
                paymentMethodChange.put('LastModifiedBy', o.CreatedBy.Name);
                paymentMethodChange.put('ChargentOrders__Card_Last_4__c', o.ChargentOrders__Card_Last_4__c);
                paymentMethodChange.put('ChargentOrders__Bank_Account_Last_4__c', o.ChargentOrders__Bank_Account_Last_4__c);
                paymentMethodChange.put('ChargentOrders__Billing_First_Name__c', o.ChargentOrders__Billing_First_Name__c);
                paymentMethodChange.put('ChargentOrders__Billing_Last_Name__c', o.ChargentOrders__Billing_Last_Name__c);
                paymentMethodChange.put('ChargentOrders__Payment_Method__c', o.ChargentOrders__Payment_Method__c);
                legacyPaymentMethodUpdatesList.add(paymentMethodChange);
            }
        }

        return legacyPaymentMethodUpdatesList;
    }

    private static List<Map<String,String>> getNewPaymentMethodUpdates(Map<Id,ChargentOrders__ChargentOrder__c> orders){
        Map<Datetime,Map<String,String>> updatesByTime = new Map<Datetime,Map<String,String>>();
        Map<String,String> mostRecentValueByField = new Map<String,String>();

        for (ChargentOrders__ChargentOrder__c o: orders.values()){
            Integer counter = 1;
            for (ChargentOrders__ChargentOrder__History h : o.Histories) {

                Boolean newMapExistsWithDatetime = updatesByTime.containsKey(h.CreatedDate);
                Boolean oldMapExistsWithDatetime = updatesByTime.containsKey(h.Parent.CreatedDate);

                if (h.Parent.ARC_UpdatePaymentMethod__c == true && h.Field == 'ARC_LastPaymentMethodUpdate__c' && counter == 1) {
                    Map<String, String> oldValues = new Map<String, String>();
                    Map<String, String> newValues = new Map<String, String>();

                    oldValues.put('OrderName', o.Name);
                    oldValues.put('OrderId', o.Id);
                    oldValues.put('UpdateDate', String.valueOf(h.Parent.CreatedDate));
                    oldValues.put('OrderDate', String.valueOf(h.Parent.CreatedDate.format('MM/dd/yyy')));
                    oldValues.put('LastModifiedBy', h.Parent.CreatedBy.Name);
                    oldValues.put('Parent.ChargentOrders__Billing_First_Name__c',o.ChargentOrders__Billing_First_Name__c);
                    oldValues.put('Parent.ChargentOrders__Billing_Last_Name__c',o.ChargentOrders__Billing_Last_Name__c);
                    oldValues.put('Parent.ChargentOrders__Card_Last_4__c',o.ChargentOrders__Card_Last_4__c);
                    oldValues.put('Parent.ChargentOrders__Bank_Account_Last_4__c',o.ChargentOrders__Bank_Account_Last_4__c);
                    oldValues.put('Parent.ChargentOrders__Payment_Method__c',o.ChargentOrders__Payment_Method__c);
                    updatesByTime.put(h.createdDate-1,oldValues);

                    newValues.put('OrderName', o.Name);
                    newValues.put('OrderId', o.Id);
                    newValues.put('UpdateDate', String.valueOf(h.CreatedDate));
                    newValues.put('OrderDate', String.valueOf(h.CreatedDate.format('MM/dd/yyy')));
                    newValues.put('LastModifiedBy', h.CreatedBy.Name);
                    newValues.put('Parent.ChargentOrders__Billing_First_Name__c',o.ChargentOrders__Billing_First_Name__c);
                    newValues.put('Parent.ChargentOrders__Billing_Last_Name__c',o.ChargentOrders__Billing_Last_Name__c);
                    newValues.put('Parent.ChargentOrders__Card_Last_4__c',o.ChargentOrders__Card_Last_4__c);
                    newValues.put('Parent.ChargentOrders__Bank_Account_Last_4__c',o.ChargentOrders__Bank_Account_Last_4__c);
                    newValues.put('Parent.ChargentOrders__Payment_Method__c',o.ChargentOrders__Payment_Method__c);
                    updatesByTime.put(h.CreatedDate,newValues);

                    counter++;

                }
                
                if ((h.Parent.ARC_UpdatePaymentMethod__c == false && h.Field == 'ARC_LastPaymentMethodUpdate__c') ||
                    (h.Parent.ARC_UpdatePaymentMethod__c == true && h.Field == 'ARC_LastPaymentMethodUpdate__c' && counter > 1)
                ){
                    Map<String, String> newValues = new Map<String, String>();
                    newValues.put('OrderName', o.Name);
                    newValues.put('OrderId', o.Id);
                    newValues.put('UpdateDate', String.valueOf(h.CreatedDate));
                    newValues.put('OrderDate', String.valueOf(h.CreatedDate.format('MM/dd/yyyy')));
                    newValues.put('LastModifiedBy', h.CreatedBy.Name);
                    newValues.put('Parent.ChargentOrders__Billing_First_Name__c',o.ChargentOrders__Billing_First_Name__c);
                    newValues.put('Parent.ChargentOrders__Billing_Last_Name__c',o.ChargentOrders__Billing_Last_Name__c);
                    newValues.put('Parent.ChargentOrders__Card_Last_4__c',o.ChargentOrders__Card_Last_4__c);
                    newValues.put('Parent.ChargentOrders__Bank_Account_Last_4__c',o.ChargentOrders__Bank_Account_Last_4__c);
                    newValues.put('Parent.ChargentOrders__Payment_Method__c',o.ChargentOrders__Payment_Method__c);
                    updatesByTime.put(h.CreatedDate,newValues);
                }
                
                if (trackedFields.contains(h.Field)){
                    if(oldMapExistsWithDatetime) ((Map<String,String>)updatesByTime.get(h.Parent.CreatedDate)).put(h.Field,(String)h.OldValue);
                    if(newMapExistsWithDatetime) ((Map<String,String>)updatesByTime.get(h.CreatedDate)).put(h.Field,(String)h.NewValue);
                }
            }
        }

        return updatesByTime.values();
    }

    private static List <Map<String,String>> findLastFieldUpdateForNullValues(List <Map<String,String>> legacyPaymentMethodUpdatesList){
        for (String fieldApiName : trackedFields) { // por cada field
                String oldPaymentMethod = null;
                for (Integer i = 0; i < legacyPaymentMethodUpdatesList.size(); i++) { // history tracking
                    String mostRecentValue = '';
                    //Looks for most recent value
                    for (Integer j = i; j < legacyPaymentMethodUpdatesList.size(); j++) { // history tracking
                        Object currentValue = legacyPaymentMethodUpdatesList[j].get(fieldApiName);
                        if(currentValue != null){
                            mostRecentValue = String.valueOf(currentValue);
                            break;
                        } else {
                            continue;
                        }
                    }
                    //Get the value of the field from the parent chargent order if there is no most recent value in the history tracking.
                    legacyPaymentMethodUpdatesList[i].put(fieldApiName, mostRecentValue.isWhitespace()? (String)legacyPaymentMethodUpdatesList[i].get('Parent.'+ fieldApiName) : mostRecentValue);
                    //With the first value populates the older values
                    if (fieldApiName == 'ChargentOrders__Payment_Method__c') {
                        if ((String)legacyPaymentMethodUpdatesList[i].get(fieldApiName) != null) {
                            oldPaymentMethod = (String)legacyPaymentMethodUpdatesList[i].get(fieldApiName) == 'Credit Card'? 'Bank Account' : 'Credit Card';
                            legacyPaymentMethodUpdatesList[i].put(fieldApiName,(String)legacyPaymentMethodUpdatesList[i].get(fieldApiName));
                        }
                        else if ((String)legacyPaymentMethodUpdatesList[i].get(fieldApiName) == null) {
                            legacyPaymentMethodUpdatesList[i].put(fieldApiName,oldPaymentMethod);
                        }
                    }
                }
        }
        return legacyPaymentMethodUpdatesList;
    }
}