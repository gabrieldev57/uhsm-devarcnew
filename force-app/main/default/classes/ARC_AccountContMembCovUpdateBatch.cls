public class ARC_AccountContMembCovUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {

    private String condition;
    private Boolean runUpdate;
    List<String> reportLines = new List<String>();
    List<String> errorLines = new List<String>();     
    Id currentId;

    public ARC_AccountContMembCovUpdateBatch(String condition, Boolean runUpdate) {
        this.condition = condition;
        this.runUpdate = runUpdate;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

            String query = 'SELECT Id, ARC_ContinuousCoverageStartDate__c, ARC_Last_Aggregator_Reset_Date__c'
            + ' FROM Account';

        if (!String.isBlank(condition)) {
            query += ' WHERE ' + condition;
        }
        
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {

        String errorMsg = '';

        Set<Id> batchAccounts = new Set<Id>();
        for(Account acc : scope){
            batchAccounts.add(acc.Id);
        }

        try {
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToEach = [
            SELECT vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Name,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.PersonBirthdate,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_ContractReason__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.CreatedDate,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_AwaitingActivationDate__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.vlocity_ins__ExpiredContractId__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.vlocity_ins__ExpiredContractId__r.ARC_MedicalPlan__r.Name,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_MedicalPlan__r.Name,
            vlocity_ins__ContractLineId__r.Name
            FROM vlocity_ins__GroupCensusMemberPlan__c
            WHERE vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId IN :batchAccounts
            AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
            AND (
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated' 
                OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Terminated'                    
                OR( vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c <= TODAY
                    AND vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Awaiting Activation'))
            ORDER BY vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c ASC, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.CreatedDate ASC];

        
        Map<Id,Map<String,Date>> memberSinceDateMap = new Map<Id,Map<String,Date>>();
            for(vlocity_ins__GroupCensusMemberPlan__c plan: gcmpRelatedToEach) {
                Map<String,Date> datesMap = memberSinceDateMap.containsKey(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId)? memberSinceDateMap.get(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId): new Map<String,Date>();
                Boolean isFirstContract = !memberSinceDateMap.containsKey(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId);
                Boolean isAddNewBorn = plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_ContractReason__c.contains('Add Newborn');
                Date memberBirthdate = plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.PersonBirthdate;
                Date contractEffectiveDate = plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c;
                
                // Format the Awaiting Activation Date
                Datetime awaitingActivationDateTime = plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_AwaitingActivationDate__c;
                Date awaitingActivationDate = null;
                if (awaitingActivationDateTime != null) {
                    String DateTimeString = awaitingActivationDateTime.format('yyyy-MM-dd', 'GMT');
                    awaitingActivationDate = Date.valueOf(DateTimeString);
                }

                // saves last upgrade date for lastAggReset date
                Boolean isUpgrade = plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_ContractReason__c.contains('Program Upgrade') 
                || plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_ContractReason__c.contains('New Application')
                || plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_ContractReason__c.contains('Upgraded Spin Off')
                || (plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.vlocity_ins__ExpiredContractId__r?.ARC_MedicalPlan__r?.Name.contains('UHSM') 
                    && plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_MedicalPlan__r?.Name.contains('WeShare') );
                if(isUpgrade){    
                    // LARD :  Last Aggregators Reset Date //
                    if(!datesMap.containsKey('LARD')){
                        datesMap.put('LARD',contractEffectiveDate);
                    }else if(datesMap.get('LARD') < contractEffectiveDate){
                        datesMap.put('LARD',contractEffectiveDate);
                    }
                }

                // program is UHSM or WeShare, counts for Continuous Coverage Start Date & Last Aggregators Reset Date
                if(!datesMap.containsKey('inactiveDateForCMD')){ // => first contract for the account
                    //Set Since Date
                    if(!isAddNewBorn){ 
                        datesMap.put('sinceDateForCCD',contractEffectiveDate);
                        datesMap.put('LARD',contractEffectiveDate);
                    }
                    // else isAddNewBorn 
                    // first contract for newborn member
                    else {
                        // first member's contract is Add Newborn => member is newborn
                        // ** if member's birthdate is after contract's effective date, then LARD is member's birthdate
                        // ** else LARD is contract's effective date (Member is not a newborn) 
                        // ** NOTE: In case of voided previous contract => 
                        // ** for members added in voided contract, first contract would be the 'add newborn') 
                        datesMap.put('sinceDateForCCD', memberBirthdate > contractEffectiveDate ? memberBirthdate : contractEffectiveDate);
                        datesMap.put('LARD', memberBirthdate > contractEffectiveDate ? memberBirthdate : contractEffectiveDate);
                    }
                }
                else{
                    if(datesMap.get('inactiveDateForCMD').addDays(1) <contractEffectiveDate){
                        //Reset Continuous Membership Date & Last Aggregator Reset Date 
                        // if a second Add Newborn contract is found for the member at this point, it will not be the member's first contract, 
                        // * inactive date is saved (if exists) on the first contract listed for a member from the query.
                        // => corresponds awaitingActivationDate, when that contract is actually activated (for being Add Newborn).
                        if(!isAddNewBorn)datesMap.put('sinceDateForCCD',contractEffectiveDate);
                        else datesMap.put('sinceDateForCCD', awaitingActivationDate);
                        
                        //Interruption in converage also resets LARD
                        if(!isAddNewBorn)datesMap.put('LARD',contractEffectiveDate);
                        else datesMap.put('LARD', awaitingActivationDate);
                    }
                }

                if(plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status == 'Terminated'
                && plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c != null){ 
                    datesMap.put('inactiveDateForCMD', plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_Inactive_Date__c);
                }
                memberSinceDateMap.put(plan.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId,datesMap);
            }


            List<Account> resultList = new List<Account>();
            for(Account retAccount : scope){
                Id recordId = retAccount.Id;                
                
                Account acc = new Account(Id=recordId);
                Map<String,Date> datesMap = memberSinceDateMap.containsKey(acc.Id)? memberSinceDateMap.get(acc.Id): new Map<String,Date>();
                acc.ARC_ContinuousCoverageStartDate__c = datesMap.containsKey('sinceDateForCCD') ? datesMap.get('sinceDateForCCD') : null;
                acc.ARC_Last_Aggregator_Reset_Date__c = datesMap.containsKey('LARD') ? datesMap.get('LARD') : null;
                Boolean updateCC = retAccount.ARC_ContinuousCoverageStartDate__c != acc.ARC_ContinuousCoverageStartDate__c;
                Boolean updateLAR = retAccount.ARC_Last_Aggregator_Reset_Date__c != acc.ARC_Last_Aggregator_Reset_Date__c;
                if(updateCC || updateLAR){
                    resultList.add(acc);
                    reportLines.add(acc.Id + ' - CC: ' + acc.ARC_ContinuousCoverageStartDate__c + ' - LAR: ' + acc.ARC_Last_Aggregator_Reset_Date__c );
                }
            }         

            if(runUpdate){
                update resultList;
            }

        } catch (Exception e) {
            errorMsg = e.getMessage();
            System.debug('Batch Failed');
            if(!String.isBlank(errorMsg)){
                errorLines.add(errorMsg);
            }           
        }
    }

    public void finish(Database.BatchableContext bc) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { 'ignacio.ferreiro@arcsona.com' });
        mail.setSubject('REPORT - Continuous Coverage & Last Aggregator Reset Date Fields');

        List<String> csvLines = new List<String>();
        csvLines.add('AccountId\tContinuousCoverageStartDate\tLastAggregatorResetDate'); // encabezados

        for (String line : reportLines) {
            List<String> parts = line.split(' - ');
            String accId = parts.size() > 0 ? parts[0] : '';
            String cc = parts.size() > 1 ? parts[1].replace('CC: ', '') : '';
            String lar = parts.size() > 2 ? parts[2].replace('LAR: ', '') : '';

            csvLines.add(accId + '\t' + cc + '\t' + lar);
        }

        String csvContent = String.join(csvLines, '\n');
        Blob csvBlob = Blob.valueOf(csvContent);

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('ContinuousMembershipReport.xls');
        attachment.setBody(csvBlob);
        attachment.setContentType('application/vnd.ms-excel');

        mail.setPlainTextBody(
            'Report (run update: ' + runUpdate + ')\n' +
            'The following Errors have been reported:\n' +
            String.join(errorLines, '\n') + '\n\n' +
            'Attached you will find the processed Accounts report (' + reportLines.size() + ').'
        );

        mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
}

}