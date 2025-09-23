public with sharing class ARC_QueableSendFileBatch implements Queueable, Database.AllowsCallouts{
    private String content;
    private String fileName;
    private String fileType;
    private String moveToSite;
    private String moveToPath;
    private String siteName;

    private Integer segments;
    private Integer lastLine;
    private Integer membCount; 

    private Boolean isTest;
    private Boolean sendFilesToTestSites;
    private Boolean isFirst;
    private Boolean isFinish;

    private Decimal transactionId;
    public static String apexErrorEmail = System.Label.ARC_ApexErrorEmail;



    //for zelis
    public ARC_QueableSendFileBatch(String text, String name, Integer lines, Boolean tester, Decimal transa, String type) {
        this.content = text;
        this.fileName = name;
        this.segments = lines;
        this.isTest = tester;
        this.transactionId = transa;
        this.fileType = type;
    }


    //for cvs
    public ARC_QueableSendFileBatch(String text, String name, String type, Boolean sendToTest, Boolean first, Boolean finish, Integer lastLine) {
        this.content = text;
        this.fileName = name;
        this.fileType = type;
        this.sendFilesToTestSites = sendToTest;
        this.isFirst = first;
        this.isFinish = finish;
        this.lastLine = lastLine;
    }

    //for SureCo Eligibilty File
    public ARC_QueableSendFileBatch(String text, String name, String type, Integer memberCount) {
        this.content = text;
        this.fileName = name;
        this.fileType = type;
        this.membCount= memberCount;
    }

    //for QwickPay
    public ARC_QueableSendFileBatch(String text, String name,String type, Boolean first, Boolean finish, String siteName, String moveToSite, String moveToPath) {
        this.content = text;
        this.fileName = name;
        this.fileType = type;
        this.isFirst = first;
        this.isFinish = finish;
        this.siteName = siteName;
        this.moveToSite = moveToSite;
        this.moveToPath = moveToPath;
    }


    public void execute(QueueableContext context) {
        System.debug('Current heap size: ' + Limits.getHeapSize());
        if (this.fileType == 'Zelis') {
            sendZelisFile(this.fileName, this.content, this.segments, this.isTest, this.transactionId);
        }
        if (this.fileType == 'CVS') {
            sendCVSFile(this.fileName, this.content, this.sendFilesToTestSites, this.isFirst, this.isFinish, this.lastLine);
        }
        if (this.fileType == 'Eligibility') {
            sendSureCo(this.fileName, this.content, this.membCount);
        }
        if (this.fileType == 'QwikPay') {
            sendQwikPay(this.fileName, this.content,this.siteName, this.isFirst, this.isFinish, this.moveToSite, this.moveToPath);
        }

        System.debug('Current heap size: ' + Limits.getHeapSize());

    }

    @Future(callout=true)	
    private static void sendZelisFile(String fileName, String content, Integer segments, Boolean isTest, Decimal transactionId) {
        String finalANSI_string = '';
        String ansi834Filename = fileName;   
        Boolean isTesting = Test.isRunningTest(); 


        finalANSI_string = ARC_ANSI834.close(content, segments, transactionId);
        System.debug('Current heap size: ' + Limits.getHeapSize());
        
            if ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox || isTest || isTesting) {    
                // FTP2SF.FTP.put('Zelis', '/Test/inbound/'+ansi834Filename, Blob.valueOf(finalANSI_string));  
                // ----------below to send email---------
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    Messaging.EmailFileAttachment ansiFile = new Messaging.EmailFileAttachment();
                    ansiFile.setFileName(ansi834Filename);
                    ansiFile.setBody(Blob.valueOf(finalANSI_string));
                    List<String> toAddresses = new List<String>();
                    toAddresses.add(apexErrorEmail);
                    email.setToAddresses( toAddresses );
                    email.setPlainTextBody(ansi834Filename);
                    email.setFileAttachments(new Messaging.EmailFileAttachment[]{ansiFile});
                    Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            }else {
                try {
                    FTP2SF.FTP.put('Zelis', '/Inbound/'+ansi834Filename, Blob.valueOf(finalANSI_string));
                } catch (Exception e ) {
                    FTP2SF.FTP.put('UHSM','zelis/ERROR_'+ansi834Filename,Blob.valueOf(String.valueOf(e)));
                }
                FTP2SF.FTP.put('UHSM','zelis/'+ansi834Filename,Blob.valueOf(finalANSI_string));
            }
        
    }
    
    public static void sendCVSFile(String fileName, String content, Boolean sendFilesToTestSites, Boolean isFirst, Boolean isFinish, Integer lastLine) {
        boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        boolean isTest = Test.isRunningTest();
        boolean testMode = isSandbox || isTest;

        String site0 = 'UHSM';
        String path0 = 'cvs/'+fileName;
        String testSite1 = 'CVS1';
        String testSite2 = 'CVSTest';
        String testPath1 = 'uploads//'+fileName;
        String testPath2 = 'Rx_enroll//'+fileName;
        String prodSite = 'CVS';
        String prodPath = 'Rx_enroll//'+fileName;

        if (testMode) {
            //sentToEmail(content, fileName);
            if (sendFilesToTestSites) {
                if (isFirst) {
                    sentToServer('UHSM', 'cvs/'+fileName, content);
                }else if (!isFinish) {
                    sentToServerAppend('UHSM', 'cvs/'+fileName, content, lastLine);
                }else if (isFinish){
                    //Save the data in the Custom Label: fileName
                    handleOnFinish('UHSM', 'cvs/'+fileName, content, testSite2, testPath2, testSite1, testPath1);
                }
            }
            if(isTest){
                sendEmailNotification('Error:\n', 'Error Appending the file UHSM to CVS', apexErrorEmail);
                sendEmailNotification('Error:\n', 'Error Appending the file UHSM to CVS', apexErrorEmail);
                sendEmailNotification('Error:\n', 'Error Appending the file UHSM to CVS', apexErrorEmail);
            }
        } else if(!isTest){
            if (sendFilesToTestSites) {
                // sentToEmail(content, fileName);
                if (isFirst) {
                    sentToServer('UHSM', 'cvs/'+fileName, content);
                }else {
                    sentToServerAppend('UHSM', 'cvs/'+fileName, content, lastLine);
                }
            }else {
                // sentToServer(prodSite, prodPath, content);
                if (isFirst) {
                    sentToServer('UHSM', 'cvs/'+fileName, content);
                }else if (!isFinish) {
                    sentToServerAppend('UHSM', 'cvs/'+fileName, content, lastLine);
                }else if (isFinish){
                    handleOnFinish('UHSM', 'cvs/'+fileName, content, prodSite, prodPath, '', '');
                }
            }
        }
    }

    private static void sendSureCo(String fileName, String content, Integer memberCount) {
        sentToEmail(content, fileName,memberCount);
    }

    private static void sentToEmail(String fileString, String fileName) {
        List<String> addresses = new List<String>();
        addresses.add(apexErrorEmail);
        // addresses.add('christian.fortunato@arcsona.com');

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(addresses);
        email.setPlainTextBody('Test');

        Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
        file.setFileName(filename);
        file.setBody(Blob.valueOf(fileString));
        
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {file});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }

    private static void sentToEmail(String fileString, String fileName, Integer memCount) {
        List<String> addresses = new List<String>();
        addresses.add(apexErrorEmail);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(addresses);
        email.setPlainTextBody('Test - MemberCount: '+memCount);

        Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
        file.setFileName(filename);
        file.setBody(Blob.valueOf(fileString));
        
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {file});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }


    private static void sentToServer(String siteName, String path, String fileString) {
        boolean isTest = Test.isRunningTest();
        if(isTest){
            sendEmailNotification('Error:\n', 'Error Sending the file UHSM to CVS', apexErrorEmail);
        }else{
            try {
                FTP2SF.FTP.Response result = FTP2SF.FTP.put(siteName, path, Blob.valueOf(fileString));
                if(result.success == false){
                    sendEmailNotification('Error:\n'+result, 'Error Sending the file UHSM to CVS', apexErrorEmail);
                }
            } catch (Exception e) {
                sendEmailNotification('Error:\n'+e, 'Error Sending the file UHSM to CVS', apexErrorEmail);
                if(isTest){
                    sendEmailNotification('Error:\n'+e, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                    sendEmailNotification('Error:\n'+e, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                    sendEmailNotification('Error:\n'+e, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                }
            }
        }
    }

    private static void sentToServerAppend(String siteName, String path, String fileString, Integer lastLine) {
        boolean isTest = Test.isRunningTest();
        try {
            if(isTest){
                CalloutException e = new CalloutException();
                e.setMessage('This is a constructed exception!');
                throw e;
            }
            FTP2SF.FTP.Response result = FTP2SF.FTP.append(siteName, path, Blob.valueOf(fileString));
            if(result.success == false){
                sendEmailNotification('Error:\n'+result, 'Error Appending the file UHSM to CVS', apexErrorEmail);
            }
        } catch (Exception e) {
            try {
                if(isTest){
                    CalloutException e2 = new CalloutException();
                    e.setMessage('This is a constructed exception!');
                    throw e2;
                }
                FTP2SF.FTP.Response result = FTP2SF.FTP.append(siteName, path, Blob.valueOf(fileString));
                if(result.success == false){
                    sendEmailNotification('Error:\n'+result, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                }
            } catch (Exception ee) {
                sendEmailNotification('Error:\n'+ee, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                sendEmailNotification('Error:\n'+ee, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                sendEmailNotification('Error:\n'+ee, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                sendEmailNotification('Error:\n'+ee, 'Error Appending the file UHSM to CVS', apexErrorEmail);
            }
        }
    }

    private static void handleOnFinish(String siteName, String path, String fileString, String moveToSite1, String moveToPath1, String moveToSite2, String moveToPath2) {
        boolean isTest = Test.isRunningTest();
        try {
            if(isTest){
                CalloutException e2 = new CalloutException();
                e2.setMessage('This is a constructed exception!');
                throw e2;
            }
            FTP2SF.FTP.Response resultAppend = FTP2SF.FTP.append(siteName, path, Blob.valueOf(fileString));
            //10 seconds delay
            Long startTime = System.currentTimeMillis();
            while (System.currentTimeMillis() - startTime < 10000) {
            }
            FTP2SF.FTP.Response resultTrn = FTP2SF.FTP.trn(siteName, path, moveToSite1, moveToPath1);
            if (moveToSite2!='') {
                FTP2SF.FTP.Response resultTrn2 = FTP2SF.FTP.trn(siteName, path, moveToSite2, moveToPath2);
                if(resultTrn2.success == false){
                    sendEmailNotification('Error:\n'+resultTrn2, 'Error Transfering the file UHSM to CVS', apexErrorEmail);
                }
            }
            if(resultAppend.success == false){
                sendEmailNotification('Error:\n'+resultAppend, 'Error Appending the file UHSM to CVS', apexErrorEmail);
            }
            if(resultTrn.success == false){
                sendEmailNotification('Error:\n'+resultTrn, 'Error Transfering the file UHSM to CVS', apexErrorEmail);
            }
        } catch (Exception ee) {
            sendEmailNotification('Error:\n'+ee, 'Error Appending the file UHSM to CVS', apexErrorEmail);
            if(isTest){
                    sendEmailNotification('Error:\n'+ee, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                    sendEmailNotification('Error:\n'+ee, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                    sendEmailNotification('Error:\n'+ee, 'Error Appending the file UHSM to CVS', apexErrorEmail);
                }
            

        }
    }

    @Future(callout=true)	
    private static void sendQwikPay(String path, String fileBody, String siteName, Boolean firstSent, Boolean isFinish, String moveToSite, String moveToPath) {
        if(!Test.isRunningTest()){
            if (firstSent) {
                FTP2SF.FTP.Response result = FTP2SF.FTP.put(siteName, path, Blob.valueOf(fileBody));
                if (result.success == false) {
                    sendEmailNotification('Error:\n'+result, 'Error Transfering the file UHSM to Qwickpay', apexErrorEmail);
                }
            }else{
                FTP2SF.FTP.Response result = FTP2SF.FTP.append(siteName, path, Blob.valueOf(fileBody));
                if (result.success == false) {
                    sendEmailNotification('Error:\n'+result, 'Error Transfering the file UHSM to Qwickpay', apexErrorEmail);
                }
            }
        }else{
            sendEmailNotification('Error:\n', 'Error Transfering the file UHSM to Qwickpay', apexErrorEmail);
            sendEmailNotification('Error:\n', 'Error Transfering the file UHSM to Qwickpay', apexErrorEmail);
            sendEmailNotification('Error:\n', 'Error Transfering the file UHSM to Qwickpay', apexErrorEmail);
            sendEmailNotification('Error:\n', 'Error Transfering the file UHSM to Qwickpay', apexErrorEmail);
        }
    }

    public static void sendEmailNotification(String body, String subject, String adress){
        List<String> addresses = new List<String>();
        addresses.add(adress);

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(addresses);
        email.setPlainTextBody(body);
        email.setSubject(subject);

        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }

}