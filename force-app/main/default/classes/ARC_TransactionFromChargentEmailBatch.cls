global without sharing class ARC_TransactionFromChargentEmailBatch implements Database.Batchable<sObject> {

    public Set<Id> chargentEmailIds = new Set<Id>();

    global ARC_TransactionFromChargentEmailBatch (Set<Id> chargentEmailIds){
        this.chargentEmailIds = chargentEmailIds;
    }

    global ARC_TransactionFromChargentEmailBatch(){}

    global Database.QueryLocator start(Database.BatchableContext bc) {
        if (this.chargentEmailIds.size() > 0) {
            System.debug('Chargent Email Ids Received: '+this.chargentEmailIds.size());
            return  Database.getQueryLocator([SELECT Id, ChargentOrders__Transaction__r.ChargentOrders__Gateway_ID__c, CreatedDate, ChargentOrders__Unresolved_Transaction__c, ChargentOrders__Notification_Message__c, ChargentOrders__ChargentOrder__c, ChargentOrders__ChargentOrder__r.Name, ChargentOrders__Status__c, ChargentOrders__Transaction__c, ChargentOrders__Transaction_JSON__c, ChargentOrders__Related_Transaction__c FROM ChargentOrders__Email_Notification__c WHERE Id IN :this.chargentEmailIds  ORDER BY CreatedDate DESC]);
        } 
        else {
            return Database.getQueryLocator([SELECT Id, ChargentOrders__Transaction__r.ChargentOrders__Gateway_ID__c, CreatedDate, ChargentOrders__Unresolved_Transaction__c, ChargentOrders__Notification_Message__c, ChargentOrders__ChargentOrder__c, ChargentOrders__ChargentOrder__r.Name, ChargentOrders__Status__c, ChargentOrders__Transaction__c, ChargentOrders__Transaction_JSON__c, ChargentOrders__Related_Transaction__c FROM ChargentOrders__Email_Notification__c WHERE ChargentOrders__Unresolved_Transaction__c = true  ORDER BY CreatedDate DESC ]);
        }
    }

    global void execute(Database.BatchableContext bc, List<ChargentOrders__Email_Notification__c> records){
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        List<ChargentOrders__Transaction__c> transactionsToCreate = new List<ChargentOrders__Transaction__c>();
        
        for(ChargentOrders__Email_Notification__c eRecord:records){
            Map<String, Object> transactionJSON = (Map<String, Object>) JSON.deserializeUntyped(eRecord.ChargentOrders__Transaction_JSON__c);
            String resp = (String)transactionJSON.get('ChargentOrders__Response_Status__c');
            if(resp == 'Approved'){
                ChargentOrders__Transaction__c trans = new ChargentOrders__Transaction__c();
                trans.ChargentOrders__Credit_Card_Type__c = transactionJSON.get('ChargentOrders__Credit_Card_Type__c') != null? (String)transactionJSON.get('ChargentOrders__Credit_Card_Type__c'):null;
                trans.ChargentOrders__Response__c = transactionJSON.get('ChargentOrders__Response__c') != null? (String)transactionJSON.get('ChargentOrders__Response__c'):null;
                trans.ChargentOrders__Amount__c = transactionJSON.get('ChargentOrders__Amount__c') != null? (Decimal)transactionJSON.get('ChargentOrders__Amount__c'):null;
                trans.ChargentOrders__Billing_First__c = transactionJSON.get('ChargentOrders__Billing_First__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_First__c'):null;
                trans.ChargentOrders__Response_Message__c = transactionJSON.get('ChargentOrders__Response_Message__c') != null? (String)transactionJSON.get('ChargentOrders__Response_Message__c'):null;
                trans.ChargentOrders__Description__c = transactionJSON.get('ChargentOrders__Description__c') != null? (String)transactionJSON.get('ChargentOrders__Description__c'):null;
                trans.ChargentOrders__Gateway_ID__c = transactionJSON.get('ChargentOrders__Gateway_ID__c') != null? (String)transactionJSON.get('ChargentOrders__Gateway_ID__c'):null;
                trans.ChargentOrders__Authorization__c = transactionJSON.get('ChargentOrders__Authorization__c') != null? (String)transactionJSON.get('ChargentOrders__Authorization__c'):null;
                trans.ChargentOrders__Payment_Method__c = transactionJSON.get('ChargentOrders__Payment_Method__c') != null? (String)transactionJSON.get('ChargentOrders__Payment_Method__c'):null;
                trans.ChargentOrders__Billing_Province__c = transactionJSON.get('ChargentOrders__Billing_Province__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_Province__c'):null;
                trans.ChargentOrders__Billing_City__c = transactionJSON.get('ChargentOrders__Billing_City__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_City__c'):null;
                String original = transactionJSON.get('ChargentOrders__Gateway_Date__c') != null? (String)transactionJSON.get('ChargentOrders__Gateway_Date__c'):null;
                if(original != null){
                    String cleaned = original.replace('T', ' ').substring(0, 19);
                    trans.ChargentOrders__Gateway_Date__c = Datetime.valueOf(cleaned);
                }
                trans.ChargentOrders__AVS_International__c = transactionJSON.get('ChargentOrders__AVS_International__c') != null? (String)transactionJSON.get('ChargentOrders__AVS_International__c'):null;
                trans.ChargentOrders__Billing_Email__c = transactionJSON.get('ChargentOrders__Billing_Email__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_Email__c'):null;
                trans.ChargentOrders__Reason_Code__c = transactionJSON.get('ChargentOrders__Reason_Code__c') != null? (Decimal)transactionJSON.get('ChargentOrders__Reason_Code__c'):null;
                trans.ChargentOrders__AVS_Zip__c = transactionJSON.get('ChargentOrders__AVS_Zip__c') != null? (String)transactionJSON.get('ChargentOrders__AVS_Zip__c'):null;
                trans.ChargentOrders__Billing_Phone__c = transactionJSON.get('ChargentOrders__Billing_Phone__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_Phone__c'):null;
                trans.ChargentOrders__Card_Code_Response__c = transactionJSON.get('ChargentOrders__Card_Code_Response__c') != null? (String)transactionJSON.get('ChargentOrders__Card_Code_Response__c'):null;
                trans.ChargentOrders__Order__c = transactionJSON.get('ChargentOrders__Order__c') != null? (String)transactionJSON.get('ChargentOrders__Order__c'):null;
                trans.ChargentOrders__Billing_Country__c = transactionJSON.get('ChargentOrders__Billing_Country__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_Country__c'):null;
                trans.ChargentOrders__Card_Last_4__c = transactionJSON.get('ChargentOrders__Card_Last_4__c') != null? (String)transactionJSON.get('ChargentOrders__Card_Last_4__c'):null;
                trans.ChargentOrders__Response_Status__c = transactionJSON.get('ChargentOrders__Response_Status__c') != null? (String)transactionJSON.get('ChargentOrders__Response_Status__c'):null;
                trans.ChargentOrders__Billing_Company__c = transactionJSON.get('ChargentOrders__Billing_Company__c') != null? (String)transactionJSON.get('ChargentOrders__AVS_Zip__c'):null;
                trans.ChargentOrders__Gateway_Response__c = transactionJSON.get('ChargentOrders__Gateway_Response__c') != null? (String)transactionJSON.get('ChargentOrders__Gateway_Response__c'):null;
                trans.ChargentOrders__Gateway__c = transactionJSON.get('ChargentOrders__Gateway__c') != null? (String)transactionJSON.get('ChargentOrders__Gateway__c'):null;
                trans.ChargentOrders__Type__c = transactionJSON.get('ChargentOrders__Type__c') != null? (String)transactionJSON.get('ChargentOrders__Type__c'):null;
                trans.ChargentOrders__Billing_Address_Line_2__c = transactionJSON.get('ChargentOrders__Billing_Address_Line_2__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_Address_Line_2__c'):null;
                trans.ChargentOrders__Recurring__c = transactionJSON.get('ChargentOrders__Recurring__c') != null? (Boolean)transactionJSON.get('ChargentOrders__Recurring__c'):null;
                trans.ChargentOrders__Currency__c = transactionJSON.get('ChargentOrders__Currency__c') != null? (String)transactionJSON.get('ChargentOrders__Currency__c'):null;
                trans.ChargentOrders__Billing_Last__c = transactionJSON.get('ChargentOrders__Billing_Last__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_Last__c'):null;
                trans.ChargentOrders__Credit_Card_Name__c = transactionJSON.get('ChargentOrders__Credit_Card_Name__c') != null? (String)transactionJSON.get('ChargentOrders__Credit_Card_Name__c'):null;
                trans.ChargentOrders__Billing_Fax__c = transactionJSON.get('ChargentOrders__Billing_Fax__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_Fax__c'):null;
                trans.ChargentOrders__Billing_Address__c = transactionJSON.get('ChargentOrders__Billing_Address__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_Address__c'):null;
                trans.ChargentOrders__Amount_available_for_Refund__c = transactionJSON.get('ChargentOrders__Amount_available_for_Refund__c') != null? (Decimal)transactionJSON.get('ChargentOrders__Amount_available_for_Refund__c'):null;
                trans.ChargentOrders__Tokenization__c = transactionJSON.get('ChargentOrders__Tokenization__c') != null? (String)transactionJSON.get('ChargentOrders__Tokenization__c'):null;
                trans.ChargentOrders__Reason_Text__c = transactionJSON.get('ChargentOrders__Reason_Text__c') != null? (String)transactionJSON.get('ChargentOrders__Reason_Text__c'):null;
                trans.ChargentOrders__Billing_Postal_Code__c = transactionJSON.get('ChargentOrders__Billing_Postal_Code__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_Postal_Code__c'):null;
                trans.ChargentOrders__Billing_State__c = transactionJSON.get('ChargentOrders__Billing_State__c') != null? (String)transactionJSON.get('ChargentOrders__Billing_State__c'):null;
                trans.ChargentOrders__AVS_Response_Code__c = transactionJSON.get('ChargentOrders__AVS_Response_Code__c') != null? (String)transactionJSON.get('ChargentOrders__AVS_Response_Code__c'):null;

                transactionsToCreate.add(trans);
            }
        }

        saveResults = Database.insert (transactionsToCreate,false);
        List<String> errorsFound = new List<String>();
        for (Database.SaveResult sr : saveResults) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR, 'Error updating case: ' + err.getMessage());
                    errorsFound.add(err.getMessage());
                }
            } 
        }
        if(errorsFound.size()>0){
            //Send an email in case of errors
            ARC_QueableSendFileBatch.sendEmailNotification(('Insert Failed: '+errorsFound), 'ERROR inserting Transactions ', 'christian.fortunato@arcsona.com');
        }
    }

    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}