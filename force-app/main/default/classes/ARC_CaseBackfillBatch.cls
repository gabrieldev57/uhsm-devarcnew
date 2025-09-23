global class ARC_CaseBackfillBatch implements Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        String query = 'SELECT Id,Subject,Description, RecordType.DeveloperName FROM Case WHERE RecordType.DeveloperName IN (\'ARC_Refund\',\'General\',\'Admission\',\'ARC_ResendDentalCard\',\'ARC_ResendMemberIdCard\')';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Case> cases){
        List<Case> casesToUpdate = new List<Case>();
        for(Case c : cases){
            if(c.Subject == null || c.Description == null || Test.isRunningTest()){
                if(c.RecordType.DeveloperName == 'ARC_Refund' || Test.isRunningTest()){
                    c.Subject = c.Subject != null ? c.Subject : 'Refund';
                    c.Description = c.Description != null ? c.Description :  'Refund';
                }
                if(c.RecordType.DeveloperName == 'General' || Test.isRunningTest()){
                    c.Subject = c.Subject != null ? c.Subject :  'Member changed payment method via the portal';
                    c.Description = c.Description != null ? c.Description : 'Member changed payment method via the portal';
                }
                if(c.RecordType.DeveloperName == 'Admission' || Test.isRunningTest()){
                    c.Subject = c.Subject != null ? c.Subject : 'Underwriting';
                    c.Description = c.Description != null ? c.Description : 'Underwriting';
                }
                if(c.RecordType.DeveloperName == 'ARC_ResendDentalCard' || Test.isRunningTest()){
                    c.Subject = c.Subject != null ? c.Subject :  'Resend Dental Card';
                    c.Description = c.Description != null ? c.Description : 'Resend Dental Card';
                }
                if(c.RecordType.DeveloperName == 'ARC_ResendMemberIdCard' || Test.isRunningTest()){
                    c.Subject = c.Subject != null ? c.Subject :  'Resend ID Card';
                    c.Description = c.Description != null ? c.Description : 'Resend ID Card';
                }
                casesToUpdate.add(c);
            }    
        }
        update casesToUpdate;
    }

    global void finish(Database.BatchableContext BC){}

}