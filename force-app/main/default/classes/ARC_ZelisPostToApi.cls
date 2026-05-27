public class ARC_ZelisPostToApi implements Queueable, Database.AllowsCallouts {
    private string fileName;
    private string folderName;
    private Id checkRunId;
    private Boolean updateCheckRun;
    private Set<Id> claimIds;
    private Boolean sendToZelis;


    public ARC_ZelisPostToApi(String fileN, Id checkId, String foldName, Boolean updateChkRun, Set<Id> clmIds, Boolean sndToZelis){
        this.fileName = fileN;
        this.checkRunId = checkId;
        this.folderName = foldName;
        this.updateCheckRun = updateChkRun;
        this.claimIds = clmIds;
        this.sendToZelis = sndToZelis;
    }

    public void execute(QueueableContext context){
        /*
        FTP2SF.FTP.Response res = FTP2SF.FTP.exists('UHSM', folderName +'/' + fileName+'.xml');
        System.debug('Exists file to zip');
        System.debug(res);*/
        ARC_CheckRun__c checkRun;
        if (checkRunId != null) {
            checkRun = [SELECT Id,ARC_SkipAutomation__c, ARC_DocumentSent__c, ARC_DocumentSentDate__c, ARC_Document_Name__c FROM ARC_CheckRun__c WHERE Id =: checkRunId LIMIT 1];
        }
        

        if(checkRun?.ARC_SkipAutomation__c == true){
            updateCheckRun = false;
            sendToZelis = false;
        }

        HttpRequest request = new HttpRequest();    
        request.setEndpoint('https://prmbjx8jal.execute-api.us-west-2.amazonaws.com/api/zipxml');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        String requestBody = '{ "ApiKey": "b615cd29-4ed9-4672-9308-65acd0bd6404", "Bucket": "uhsmeligibilityfiles", "Keys": ["'+ folderName + '/' + fileName + '.xml"]}';
        request.setBody(requestBody);
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        String endPointServer = isSandbox == false ? 'ZelisClaims' : 'ZelisClaimsTest';
        try {
            response = http.send(request);
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
        }
        if (response.getStatusCode() == 200){
            FTP2SF.FTP.Response result ;
            System.debug('endPointServer: '+endPointServer);
            if(!Test.isRunningTest() && sendToZelis) result = FTP2SF.FTP.trn('UHSM', folderName +'/' + fileName + '.zip', endPointServer, '/'+fileName +'.zip');
            System.debug(result);
            if (Test.isRunningTest() || (sendToZelis && updateCheckRun && result?.success==true )) {
                try{
                    checkRun.ARC_DocumentSent__c = true;
                    checkRun.ARC_DocumentSentDate__c = Date.today();
                    checkRun.ARC_Document_Name__c = fileName;
                    update checkRun;
                }catch(Exception e){
                    System.debug('Error sending file to zelis: '+e.getMessage());
                }
            } else if(result?.error!=null) {
                System.debug(result.error);
                checkRun.ARC_Status__c = 'Failed';
            } else if(result?.success==true && !updateCheckRun){
                List<FeedItem> chatterPosts = new List<FeedItem>();
                for(Id clmid: claimIds){
                    FeedItem post = new FeedItem();
                    post.ParentId = clmid;
                    post.Body = 'This claim document was resent to Zelis on ' + Date.today().format() + '. The file name is: ' + fileName;
                    chatterPosts.add(post);
                }
                insert chatterPosts;
            }
        } else if(response.getStatusCode() != 200 && updateCheckRun){
            checkRun.ARC_Status__c = 'Failed';
            update checkRun;
        } else if(response.getStatusCode() != 200 && !updateCheckRun){
            List<FeedItem> chatterPosts = new List<FeedItem>();
            for(Id clmid: claimIds){
                FeedItem post = new FeedItem();
                post.ParentId = clmid;
                post.Body = 'There was an error resending the Claim document to Zelis, please try again or contact your System Administrator.';
                chatterPosts.add(post);
            }
            insert chatterPosts;
        }
    }

}