public without sharing class ARC_CheckRunTriggerHandler {
	// public variable to track/confirm Optum processor setting is not triggering Zelis automation in testing
    public static Boolean zelisLogicExecuted = false;
    
    public static List <Id> checkRunValidation(Map<Id, ARC_CheckRun__c> oldCheckrunMap, Map<Id, ARC_CheckRun__c> newCheckrunMap){
        
        List<Id> checkRunIds = new List<Id>();
    
            for (Id newCheckRunId : newCheckrunMap.keySet()) {
                ARC_CheckRun__c checkRunNew = newCheckrunMap.get(newCheckRunId);
                ARC_CheckRun__c checkRunOld = oldCheckrunMap.get(newCheckRunId);
                
                if(checkRunNew.Id == checkRunOld.Id && checkRunNew.ARC_Status__c == 'Closed' && checkRunOld.ARC_Status__c != 'Closed' && checkRunNew.ARC_SkipAutomation__c == false) {
                    checkRunIds.add(checkRunNew.Id);
                }
            }

        if(checkRunIds.isEmpty() == false){
            return checkRunIds;
        }
        else {
            return new List<Id>();
        }
    }

    public static void sendClaimsToZelis(Map<Id, ARC_CheckRun__c> oldCheckrunMap, Map<Id, ARC_CheckRun__c> newCheckrunMap){
        zelisLogicExecuted = true;
        
        List<Id> checkRunToProcess = checkRunValidation(oldCheckrunMap, newCheckrunMap);
        if(checkRunToProcess.isEmpty() == false) {
            ARC_ZelisClaimsFileBatch.runZelisBatch(checkRunToProcess);
        }
    }

    public static void recalculateTotal(Map<Id, ARC_CheckRun__c> oldCheckrunMap, Map<Id, ARC_CheckRun__c> newCheckrunMap){
        List<Id> checkRunToProcess = checkRunValidation(oldCheckrunMap, newCheckrunMap);
        if(checkRunToProcess.isEmpty()) return;

        List<Claim> claims = [SELECT Id, ARC_TotalNetPaidAmount__c, ARC_CheckRun__c FROM Claim WHERE ARC_CheckRun__c IN :checkRunToProcess];

        Map<Id, Decimal> checkrunId_checkrunTotal_map = new Map<Id, Decimal>();
        for(Claim clm : claims){

            if(checkrunId_checkrunTotal_map.containsKey(clm.ARC_CheckRun__c)) {
                checkrunId_checkrunTotal_map.put(clm.ARC_CheckRun__c, checkrunId_checkrunTotal_map.get(clm.ARC_CheckRun__c) + clm.ARC_TotalNetPaidAmount__c);
            }
            else {
                checkrunId_checkrunTotal_map.put(clm.ARC_CheckRun__c, clm.ARC_TotalNetPaidAmount__c);
            }
        }

        for (Id checkrunId : checkrunId_checkrunTotal_map.keySet()) {
            newCheckrunMap.get(checkrunId).ARC_TotalPaid__c = checkrunId_checkrunTotal_map.get(checkrunId);
        }
    }

    public static void sendSMBPaidReportEmail(Map<Id, ARC_CheckRun__c> oldCheckrunMap, Map<Id, ARC_CheckRun__c> newCheckrunMap){
		zelisLogicExecuted = true;
        
        System.debug('sendSMBPaidReportEmail called');
        List<Id> checkRunIds = new List<Id>();
    
        for (Id newCheckRunId : newCheckrunMap.keySet()) {
            ARC_CheckRun__c checkRunNew = newCheckrunMap.get(newCheckRunId);
            ARC_CheckRun__c checkRunOld = oldCheckrunMap.get(newCheckRunId);
            if(checkRunNew.Id == checkRunOld.Id && checkRunNew.ARC_DocumentSent__c==true && checkRunOld.ARC_DocumentSent__c==false && checkRunNew.ARC_DocumentSentDate__c != null && checkRunNew.ARC_Document_Name__c!=null) checkRunIds.add(checkRunNew.Id);
        }
        if(checkRunIds.size()>0){
            System.debug('call to send the email');
            sendEmail();
        }
        
    }

    public static void populateScheduleClosingDate(List<ARC_CheckRun__c> newCheckruns){
        
        for (ARC_CheckRun__c newCheck : newCheckruns) {
            newCheck.ARC_ScheduledClosingDate__c = calculateNextWednesday(System.now());
        }
        
    }

    @future(callout=true)
    public static void sendEmail(){
        try {
            List<Report> reportList = [SELECT Id, DeveloperName, Name FROM Report WHERE DeveloperName = 'SMB_Paid_DoNotTouch'];
            
            if (reportList.size() > 0) {
                String reportId = reportList[0].Id;
                Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportId);
                Reports.ReportMetadata reportMd = describe.getReportMetadata();

                String reportName = reportList[0].Name;
                String instanceName = URL.getSalesforceBaseUrl().toExternalForm();
                String url = instanceName + '/servlet/PrintableViewDownloadServlet?isdtp=p1&reportId=' + reportId;
                Date todayDate = Date.today();
                String formattedDate = todayDate.month() + '/' + todayDate.day() + '/' + todayDate.year();
                String subject = 'WeShare/UHSM Check Run - ' + formattedDate;
    
                ApexPages.PageReference objPage = new ApexPages.PageReference(url) ;
                //if(!Test.isRunningTest()) Blob content=objPage.getContent();  //Get report content
    

                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                email.setSubject(subject);
                email.setHtmlBody('Hello team, <br/><br/> The check run was completed in Salesforce. Please see the report attached. <br/><br/>Best, <br/>SMB Team');
    
                Messaging.EmailFileAttachment objMsgEmailAttach = new Messaging.EmailFileAttachment();
                objMsgEmailAttach.setFileName(reportName + '.csv');
                
                if(!Test.isRunningTest())objMsgEmailAttach.setBody(objPage.getContent());
                else objMsgEmailAttach.setBody((Blob.valueOf('IsTest')));
                objMsgEmailAttach.setContentType('text/csv');
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{objMsgEmailAttach});
    
                String emailAddresses = System.Label.ARC_EmailsPaidSmbReport;
    
                if (emailAddresses != null && emailAddresses != '') {
                    List<String> toAddresses = emailAddresses.split(',');
                    email.setToAddresses(toAddresses);
                } else {
                    System.debug('Email addresses not found in Custom Label.');
                }
                email.setSenderDisplayName('Salesforce Codex');
    
                if(!Test.isRunningTest()){
                    Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                    System.debug(sendResults[0]);
                    if (sendResults[0].isSuccess()) {
                        System.debug('Email sent successfully');
                    } else {
                        System.debug('Email failed to send. Error: ' + sendResults[0].getErrors()[0].getMessage());
                    }
                }
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
        }
    }

    public static Datetime calculateNextWednesday(Datetime inputDate) {
        String dayOfWeek = inputDate.format('E');
        Datetime addedDate = inputDate;
        Integer daysUntilWednesday = 0;
    
        while(dayOfWeek != 'Wed') {
            daysUntilWednesday++;
            addedDate = inputDate.addDays(daysUntilWednesday);
            dayOfWeek = addedDate.format('E');
        }
    
        Datetime nextWednesday = addedDate;
        nextWednesday = DateTime.newInstanceGmt(
            nextWednesday.dateGmt(),
            Time.newInstance(11, 0, 0, 0)
        );
    
        return nextWednesday;
    }
}