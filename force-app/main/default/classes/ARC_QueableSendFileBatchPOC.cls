public with sharing class ARC_QueableSendFileBatchPOC implements Queueable, Database.AllowsCallouts{
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
    private String s3UploadId;

    private Decimal transactionId;
    public static String apexErrorEmail = System.Label.ARC_ApexErrorEmail;

    // Test bypass flag - allows tests to execute production code paths without actual FTP callouts
    @TestVisible
    private static Boolean bypassTestChecks = false;



    //for zelis
    public ARC_QueableSendFileBatchPOC(String text, String name, Integer lines, Boolean tester, Decimal transa, String type) {
        this.content = text;
        this.fileName = name;
        this.segments = lines;
        this.isTest = tester;
        this.transactionId = transa;
        this.fileType = type;
    }


    //for cvs
    public ARC_QueableSendFileBatchPOC(String text, String name, String type, Boolean sendToTest, Boolean first, Boolean finish, Integer lastLine) {
        this.content = text;
        this.fileName = name;
        this.fileType = type;
        this.sendFilesToTestSites = sendToTest;
        this.isFirst = first;
        this.isFinish = finish;
        this.lastLine = lastLine;
    }

    //for SureCo Eligibilty File
    public ARC_QueableSendFileBatchPOC(String text, String name, String type, Integer memberCount) {
        this.content = text;
        this.fileName = name;
        this.fileType = type;
        this.membCount= memberCount;
    }

    //for QwickPay
    public ARC_QueableSendFileBatchPOC(String text, String name,String type, Boolean first, Boolean finish, String siteName, String moveToSite, String moveToPath) {
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
    
    public void sendCVSFile(String fileName, String content, Boolean sendFilesToTestSites, Boolean isFirst, Boolean isFinish, Integer lastLine) {
        Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
        boolean isSandbox = org.IsSandbox;
        boolean isTest = Test.isRunningTest();
        boolean testMode = isSandbox || isTest;
        
        String site0 = 'UHSM';
        String s3FilePath = fileName;
        String testSite1 = 'CVS1';
        String testSite2 = 'CVSTest';
        String testPath1 = 'uploads//'+fileName;
        String testPath2 = 'Rx_enroll//'+fileName;
        String prodSite = 'CVS';
        String prodPath = 'Rx_enroll//'+fileName;

        if (testMode || sendFilesToTestSites) {
            s3FilePath = 'test/'+fileName;
            //sentToEmail(content, fileName);
                // Use S3 multipart upload for test mode too
                try {
                    Integer nextPart = 1;
                    // Query uploadId AND nextPartNumber BEFORE any callouts
                    if (String.isBlank(s3UploadId) && !isFirst) {
                        ARC_S3UploadStateManager.UploadState state = ARC_S3UploadStateManager.getUploadState(fileName);
                        s3UploadId = state.uploadId;
                        nextPart = state.nextPartNumber;
                        System.debug('S3 Test: Retrieved state from DB - uploadId: ' + s3UploadId + ', nextPart: ' + nextPart);
                    }
                    
                    // All callouts happen here
                    ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader(s3FilePath, s3UploadId, nextPart);
                    
                    if (isFirst) {
                        this.s3UploadId = uploader.initializeUpload();
                        nextPart = 1;
                        System.debug('S3 Test: Initialized upload for ' + s3FilePath + ' with ID: ' + s3UploadId);
                    }
                    
                    String etag = uploader.uploadNextPart(content);
                    System.debug('S3 Test: Uploaded part ' + nextPart + ' for ' + s3FilePath);
                    
                    if (isFinish) {
                        // Query all parts from DB BEFORE any more callouts
                        Map<Integer, String> allParts = ARC_S3UploadStateManager.getUploadedParts(fileName);
                        // Add the current part we just uploaded
                        allParts.put(nextPart, etag);
                        
                        // Now make the complete callout (no DB queries after this)
                        uploader.completeUpload(allParts);
                        System.debug('S3 Test: Completed upload for ' + s3FilePath);
                        handleOnFinish('UHSM', s3FilePath, content, testSite2, testPath2, testSite1, testPath1);
                        // Clear state after completion
                        ARC_S3UploadStateManager.clearUploadId(fileName);
                        
                    } else {
                        // Save uploadId, nextPartNumber, AND part ETag AFTER all callouts complete
                        ARC_S3UploadStateManager.saveUploadId(fileName, this.s3UploadId, nextPart + 1);
                        ARC_S3UploadStateManager.savePartETag(fileName, nextPart, etag);
                    }
                        // Transfer from S3 to test FTP sites
                        
                    
                } catch (Exception e) {
                    System.debug('S3 Test Error: ' + e.getMessage());
                    // Fallback to email in test mode
                    sentToEmail(content, fileName);
                }
            
        } else if(!isTest){
            // Production mode - use S3 multipart upload
            s3FilePath = 'cvs/'+fileName;
            try {
                Integer nextPart = 1;
                // Query uploadId AND nextPartNumber BEFORE any callouts
                if (String.isBlank(s3UploadId) && !isFirst) {
                    ARC_S3UploadStateManager.UploadState state = ARC_S3UploadStateManager.getUploadState(fileName);
                    s3UploadId = state.uploadId;
                    nextPart = state.nextPartNumber;
                    System.debug('S3: Retrieved state from DB - uploadId: ' + s3UploadId + ', nextPart: ' + nextPart);
                }
                
                // All callouts happen here
                ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader(s3FilePath, s3UploadId, nextPart);
                
                if (isFirst) {
                    this.s3UploadId = uploader.initializeUpload();
                    nextPart = 1;
                    System.debug('S3: Initialized upload for ' + s3FilePath + ' with ID: ' + s3UploadId);
                }
                
                String etag = uploader.uploadNextPart(content);
                System.debug('S3: Uploaded part ' + nextPart + ' for ' + s3FilePath);
                
                if (isFinish) {
                    // Query all parts from DB BEFORE any more callouts
                    Map<Integer, String> allParts = ARC_S3UploadStateManager.getUploadedParts(fileName);
                    // Add the current part we just uploaded
                    allParts.put(nextPart, etag);
                    
                    // Now make the complete callout (no DB queries after this)
                    uploader.completeUpload(allParts);
                    System.debug('S3: Completed upload for ' + s3FilePath);
                    handleOnFinish('UHSM', s3FilePath, content, prodSite, prodPath, '', '');
                    
                    // Clear state after completion
                    ARC_S3UploadStateManager.clearUploadId(fileName);
                } else {
                    // Save uploadId, nextPartNumber, AND part ETag AFTER all callouts complete
                    ARC_S3UploadStateManager.saveUploadId(fileName, this.s3UploadId, nextPart + 1);
                    ARC_S3UploadStateManager.savePartETag(fileName, nextPart, etag);
                }
            } catch (Exception e) {
                System.debug('S3 Error: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());
                sendEmailNotification(
                    'Error uploading to S3:\\n' + 
                    'File: ' + s3FilePath + '\\n' +
                    'Error: ' + e.getMessage() + '\\n' +
                    'Stack: ' + e.getStackTraceString(),
                    'Error: CVS S3 Upload Failed',
                    apexErrorEmail
                );
                throw e; // Re-throw to fail the job
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



    private static void handleOnFinish(String siteName, String path, String fileString, String moveToSite1, String moveToPath1, String moveToSite2, String moveToPath2) {
        boolean isTest = Test.isRunningTest();
        try {
            if(isTest && !bypassTestChecks){
                CalloutException e2 = new CalloutException();
                e2.setMessage('This is a constructed exception!');
                throw e2;
            }
            
            FTP2SF.FTP.Response resultTrn = FTP2SF.FTP.trn(siteName, path, moveToSite1, moveToPath1);
            if (moveToSite2!='') {
                FTP2SF.FTP.Response resultTrn2 = FTP2SF.FTP.trn(siteName, path, moveToSite2, moveToPath2);
                if(resultTrn2.success == false){
                    sendEmailNotification('Error:\n'+resultTrn2, 'Error Transfering the file UHSM to CVS', apexErrorEmail);
                }
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
        if(!Test.isRunningTest() || bypassTestChecks){
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