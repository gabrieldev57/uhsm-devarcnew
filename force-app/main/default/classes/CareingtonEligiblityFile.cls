global class CareingtonEligiblityFile implements Database.Batchable<sObject>,Schedulable,Database.AllowsCallouts,Database.Stateful {
 /*This class generates a csv file of WeShare/Access members
  * it posts the file to our AWS using the SF2FTP app
  * From there Zapier moves the file to the Careington SFTP
  * 
  * 2023.10.20: Cleaned up white space and declarations, added a few comments
  * 			Removed trailing space from EFFECTIVE DATE in header
  */   
    private String eligibilityFileContent;
    private String groupCode;
    private String filename;

    global CareingtonEligiblityFile(){
        eligibilityFileContent = 'TITLE|FIRST NAME|MIDDLE INITIAL|LAST NAME|POST NAME|UNIQUE ID|SEQUENCE NUMBER|MEMBER SSN|ADDRESS LINE 1|ADDRESS LINE 2|CITY|STATE|ZIP|ZIP PLUS 4|HOME PHONE|WORK PHONE|COVERAGE CODE|GROUP CODE|TERMINATION DATE|EFFECTIVE DATE|DATE OF BIRTH|RELATION|STUDENT STATUS|PLAN|GENDER|EMAIL ADDRESS\n';
        groupCode=groupCode; 
        filename=filename;
    }

    public String fillWithSpaces(String toFill, Integer length) {
        if (toFill.length() > length) {
            toFill = toFill.substring(0, length);
        }
        System.debug('ToFill : '+ toFill);
        return toFill;
    }

    //Add Schedulable method
    global void execute(SchedulableContext ctx) {
        CareingtonEligiblityFile Care = new CareingtonEligiblityFile();
        Database.executeBatch(Care);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
            SELECT Id,CoverageName,vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c,InsurancePolicyId 
            FROM InsurancePolicyCoverage 
            WHERE vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c='Medical' 
                AND (vlocity_ins_fsc__Product2Id__r.ProductCode LIKE '%Access%' 
                     OR vlocity_ins_fsc__Product2Id__r.ProductCode LIKE '%WeShare%') 
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<InsurancePolicyCoverage> records){
        // process each batch of records
        groupCode='';

        List<Id> ipcId = new List<Id>();
        List<Id> accountId = new List<Id>();
        List<Id> contractId = new List<Id>();
        List<Id> coverageParticipantId = new List<Id>();
              
        String firstName,
            lastName,
            addLine1,
            city,
            state,
            uniqueId,
            coverage,
            emailAddress,
            sequenceNumber,
            zip,
            DOB,
            effectiveDate,
            Title,
            middleInitial,
            postName,
            MemberSSN,
            addLine12,
            ZIPPlus4,
            homePhone,
            workPhone,
            terminationDate,
            Relation,
            studentStatus,
            plan,
            Gender;
       
        Integer rawSeqNumber;       
        Datetime todayDate = Datetime.now();
        String formattedTodayDate = todayDate.formatGMT('MMddyy');

        filename = 'UHSMGRPS' + formattedTodayDate + '_full';

        System.debug('filename' + filename);
             
        Map<Id, String> accountSequenceNumber = new Map<Id,String>();
        Map<Id, String> accountGroupCode = new Map<Id,String>();
       
        for(InsurancePolicyCoverage IPC:records){
                      ipcId.add(IPC.Id);        
        }
        List<ARC_CoverageParticipant__c> coverageParticipant=[SELECT Id,ARC_PolicyCoverage__c, ARC_Policy__r.ARC_Contract__c,
                                                              ARC_PolicyParticipant__r.PrimaryParticipantContactId,ARC_CoverageRole__c,
                                                              ARC_Policy__r.Name,ARC_PolicyParticipant__c,ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c,
                                                              ARC_Policy__r.ARC_Contract__r.Status, Sequence_Number__c, ARC_Policy__r.Careington_Effective_Date__c,
                                                              ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode
                                                              FROM ARC_CoverageParticipant__c  
                                                              WHERE ARC_PolicyCoverage__c IN : ipcId AND ARC_Policy__r.ARC_Contract__c != Null 
                                                              AND ARC_Policy__r.ARC_Contract__r.Status ='Activated' 
                                                              AND (ARC_PolicyParticipant__r.ARC_EndDate__c = NULL 
                                                                    OR ARC_PolicyParticipant__r.ARC_EndDate__c>=TODAY)];
        
                                                            
        for(ARC_CoverageParticipant__c CP:coverageParticipant){
            System.debug('coverageParticipant'+coverageParticipant + '\n');   
            
            contractId.add(CP.ARC_Policy__r.ARC_Contract__c);
            accountId.add(CP.ARC_PolicyParticipant__r.PrimaryParticipantContactId); 
            coverageParticipantId.add(CP.Id);   
            Datetime raweffectiveDate=CP.ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c;
            
            Datetime careingtonEffectiveDate=CP.ARC_Policy__r.Careington_Effective_Date__c;
            System.debug('careingtonEffectiveDate'+ careingtonEffectiveDate);
            
            effectiveDate=careingtonEffectiveDate?.formatGMT('MMddyyyy');
            System.debug('effectiveDate'+ effectiveDate);
           
            if (effectiveDate != null) {               
                effectiveDate=fillWithSpaces(effectiveDate, 8);           
            }else {               
                effectiveDate= ' ';
            }    
            System.debug('effectiveDate'+ effectiveDate);

            rawSeqNumber=Integer.valueOf(CP.Sequence_Number__c);
            if (CP.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode.contains('Legacy')){
            	groupCode = 'UHSMDVL';
            } else {
            	groupCode = 'UHSMDV';
            }
            
            if(rawSeqNumber != null){
                sequenceNumber = String.valueOf(CP.Sequence_Number__c).leftPad(2, '0');   
                System.debug('sequenceNumber'+sequenceNumber + '\n'); 
                System.debug('policy participant  :'+CP.ARC_PolicyParticipant__r.PrimaryParticipantContactId + '\n'); 
                
                accountSequenceNumber.put(CP.ARC_PolicyParticipant__r.PrimaryParticipantContactId, sequenceNumber);
                accountGroupCode.put(CP.ARC_PolicyParticipant__r.PrimaryParticipantContactId, groupCode);
                }
        }
            System.debug('accountSequenceNumber' + accountSequenceNumber.keySet());
            
            List<Account> account = [SELECT Id,Salutation,PersonContactId,FirstName,LastName, ARC_Member_Id__c,PersonBirthdate,
                                     PersonEmail,BillingCity,BillingPostalCode,BillingState,BillingStreet
                                        FROM Account 
                                        WHERE PersonContactId IN :accountSequenceNumber.keySet()];
            System.debug('accountinfo'+ account + '\n');   

            String sequenceNumberfinal;
            
            for(Account acc:account){
                if ((acc.BillingState != 'WA') && (acc.BillingState != 'VT') && (acc.BillingState != 'UT')) {
                    Datetime PersonBD=acc.PersonBirthdate;
                    Title=acc.Salutation; 
                    if (Title!= null) {               
                        Title=fillWithSpaces(Title, 3);           
                    }else {               
                        Title= '';
                    }    
        
                    sequenceNumberfinal= accountSequenceNumber.get(acc.PersonContactId);
                    if (sequenceNumberfinal != null) {               
                        sequenceNumberfinal=fillWithSpaces(sequenceNumberfinal, 2); 
                    }else {
                        sequenceNumberfinal= '';             
                    } 
        
                    firstName=acc.FirstName;
                    if (firstName!= null) {               
                        firstName=fillWithSpaces(firstName, 15);           
                    }else {               
                        firstName= '';
                    } 
            
                    lastName=acc.LastName;
                    if (lastName!= null) {               
                        lastName=fillWithSpaces(lastName, 20);           
                    }else {               
                        lastName= '';
                    } 
                    
                    uniqueId=acc.ARC_Member_Id__c;
                    if (uniqueId != null) {               
                        uniqueId=fillWithSpaces(uniqueId, 12);           
                    }else {               
                        uniqueId= '';
                    } 
                    
                    addLine1=acc.BillingStreet;
                    if (addLine1 != null) {               
                        addLine1=fillWithSpaces(addLine1, 33);           
                    }else {               
                        addLine1= '';
                    } 
                    
                    city=acc.BillingCity;
                    if (city != null) {               
                        city=fillWithSpaces(city, 21);           
                    }else {               
                        city= '';
                    }
                    
                    state=acc.BillingState;
                    if (state != null) {               
                        state=fillWithSpaces(state, 2);           
                    }else {               
                        state= '';
                    }
                    
                    DOB=PersonBD.formatGMT('MMddyyyy');
                    if (DOB != null) {               
                        DOB=fillWithSpaces(DOB, 8);           
                    }else {               
                        DOB= '';
                    }
                    
                    emailAddress=acc.PersonEmail;
                    if (emailAddress != null) {               
                        emailAddress=fillWithSpaces(emailAddress, 64);           
                    }else {               
                        emailAddress= '';
                    }
                    
                    coverage='MF';
                    if (coverage != null) {               
                        coverage=fillWithSpaces(coverage, 2);           
                    }else {               
                        coverage = '';
                    }
                
                    zip=acc.BillingPostalCode;
                    if (zip != null) {               
                        zip=fillWithSpaces(zip, 5);           
                    }else {               
                        zip= '';
                    }
        
                    middleInitial='';
                    if (middleInitial == '') {               
                        middleInitial=fillWithSpaces(middleInitial, 1);           
                    }
        
                    postName = '';
                    MemberSSN = '';
                    addLine12 = '';
                    ZIPPlus4 = '';
                    homePhone = '';
                    workPhone = '';
                    terminationDate = '';
                    Relation = '';
                    studentStatus = '';
                    plan = '';
                    Gender = '';
                    
					groupCode = accountGroupCode.get(acc.PersonContactId);
                    if (groupCode != null) {               
                        groupCode=fillWithSpaces(groupCode, 12);           
                    }
                    
                    eligibilityFileContent +=Title + '|' + firstName + '|' + middleInitial + '|' + lastName + '|' +
                        postName + '|' + uniqueId + '|' + sequenceNumberfinal + '|'  + MemberSSN + '|'  + addLine1 +
                        '|' + addLine12 + '|' + city + '|' + state + '|'+  zip + '|' + ZIPPlus4 + '|' + homePhone +
                        '|' + workPhone + '|' + coverage + '|' + groupCode + '|' + terminationDate + '|' + effectiveDate +
                        '|' + DOB + '|' + Relation + '|' + studentStatus + '|' + plan + '|' + Gender + '|' + emailAddress + '\n';
                    
                    System.debug('firstName'+firstName + '\n');
                    System.debug('firstNamelength'+firstName.length() + '\n');            
                    
                    System.debug('lastName'+lastName + '\n');
                    System.debug('lastNamelength'+lastName.length() + '\n');
                    
                    System.debug('uniqueId'+uniqueId + '\n'); 
                    System.debug('uniqueIdlength'+uniqueId.length() + '\n'); 
        
                    System.debug('addLine1'+addLine1 + '\n');
                    System.debug('addLine1length'+addLine1.length() + '\n');
        
                    System.debug('state'+state + '\n');
                    System.debug('statelength'+state.length() + '\n');
                    
                    System.debug('DOB'+DOB + '\n');
                    System.debug('DOBlength'+DOB.length() + '\n');
        
                    System.debug('zip'+zip + '\n');
                    System.debug('ziplength'+zip.length() + '\n');
        
                    System.debug('effectiveDate'+effectiveDate + '\n');
                    System.debug('effectiveDatelength'+effectiveDate.length() + '\n');
        
                    System.debug('sequenceNumber'+sequenceNumberfinal + '\n');
                    System.debug('sequenceNumberlength'+sequenceNumberfinal.length() + '\n');
    
                }// end if
        	}// end account loop  
    }// end execute method
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations

        try {
            FTP2SF.FTP.Response ftp_response = FTP2SF.FTP.put('UHSM','CareingtonEligibilityFile/' + 
                                                              filename + '.psv',Blob.valueOf(eligibilityFileContent));
            System.debug(ftp_response);
        } catch (Exception e) {
            System.debug(e);
        }
        
        System.debug('eligibilityFileContent:' + eligibilityFileContent);
        
        ContentVersion content = new ContentVersion();
        
        content.Title = filename + '.psv';
        content.PathOnClient = 'CareingtonEligibilityFile/'+ filename + '.psv' ;
        content.VersionData = Blob.valueOf(eligibilityFileContent);
        content.Origin = 'H';
        
        System.debug('Content:' + content);
        
        insert content;
    }
}