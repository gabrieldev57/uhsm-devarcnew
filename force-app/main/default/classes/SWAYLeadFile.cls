global class SWAYLeadFile implements Database.Batchable<sObject>,Database.Stateful,Schedulable,Database.AllowsCallouts {

    private String SWAYFileContent;

    private String filename;

    //Class Constructor
    global SWAYLeadFile(){
        SWAYFileContent='Source Name,First Name,Last Name,Phone,Email,Created Date,Lead Status,Disqualified Reason,Disqualified Remarks,Next Steps\n';

        filename=filename;
    }

     //Add Schedulable method
     global void execute(SchedulableContext ctx) {
        SWAYLeadFile leadfile = new SWAYLeadFile();
        Database.executeBatch(leadfile);
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        return Database.getQueryLocator([
            SELECT Id,Lead_Source_Domain__c,FirstName,LastName,Phone,Email,CreatedDate,Status,Disqualified_Reason__c,Disqualified_Remarks__c,next_steps__c 
            FROM Lead 
            WHERE Lead_Source_Domain__c='Sway'AND (NOT FirstName Like '%test%')   
         ]);
    }
    global void execute(Database.BatchableContext bc, List<Lead> leadrecords){
        // process each batch of records
        System.debug('Lead record :'+ leadrecords);

        String FirstName,LastName,Phone,Email,Status,Disqualified_Reason,Disqualified_Remarks_old,Disqualified_Remarks,next_steps;

        Date CreatedDate;
        
        Datetime todayDate = Datetime.now();
       
        String formattedTodayDate = todayDate.formatGMT('MMddyy');
        
        filename='SwayFile'+ formattedTodayDate;

        for (Lead lr : leadrecords) {

            FirstName=lr.FirstName;
            if (FirstName == null) {
                FirstName='';
            }
            FirstName=FirstName.replaceAll('\r\n|\n|\r|,',' ');

            LastName=lr.LastName;
            if (LastName == null) {
                LastName='';
            }
            LastName=LastName.replaceAll('\r\n|\n|\r|,',' ');

            Phone=lr.Phone;
            if (Phone == null) {
                Phone='';
            }
            Phone=Phone.replaceAll('\r\n|\n|\r|,',' ');

            Email=lr.Email;
            if (Email == null) {
                Email='';
            }
            Email=Email.replaceAll('\r\n|\n|\r|,',' ');

            Status=lr.Status;
            if (Status == null) {
                Status='';
            }
            Status=Status.replaceAll('\r\n|\n|\r|,',' ');

            Disqualified_Reason=lr.Disqualified_Reason__c;
            if (Disqualified_Reason == null) {
                Disqualified_Reason='';
            }
            Disqualified_Reason=Disqualified_Reason.replaceAll('\r\n|\n|\r|,',' ');

            Disqualified_Remarks=lr.Disqualified_Remarks__c;
            if (Disqualified_Remarks == null) {
                Disqualified_Remarks='';
            }
            Disqualified_Remarks=Disqualified_Remarks.replaceAll('\r\n|\n|\r|,',' ');

            next_steps=lr.next_steps__c;
            if (next_steps == null) {
                next_steps='';
            }
            next_steps=next_steps.replaceAll('\r\n|\n|\r|,',' ');


            SWAYFileContent +=lr.Lead_Source_Domain__c + ','+ FirstName + ','+ LastName + ','+ Phone + ','+ 
            Email + ','+ lr.CreatedDate + ','+ Status + ','+ Disqualified_Reason + ','+ 
            Disqualified_Remarks + ','+ next_steps + '\n';               
        }        
    }
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations

        try {
            //makeCalloutAsync(filename, eligibilityFileContent);
            FTP2SF.FTP.Response ftp_response = FTP2SF.FTP.put('uhsmsway','SwayFile/' + filename + '.csv',Blob.valueOf(SWAYFileContent));
        
            System.debug(ftp_response);
           
        } catch (Exception e) {
        
            System.debug(e);
            
        }

        System.debug('SWAYFileContent:' + SWAYFileContent);
        
        ContentVersion content = new ContentVersion();
        
        content.Title = filename + '.csv';
        
        content.PathOnClient = 'SwayFile/'+ filename + '.csv' ;
        
        content.VersionData = Blob.valueOf(SWAYFileContent);
        
        content.Origin = 'H';
        
        System.debug('Content:' + content);
        
        insert content;
    }
}