global with sharing class ARC_QwikPayEligibilityFile implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    public String testEmail;
    public Boolean isTest = false;

    private String separator = '|';

    private String siteName = 'UHSM';
    private String path;
    private String moveToSite;
    private String moveToPath;

    private String fileBody = '';
    private String fileName = '';

    private Boolean isFirst = true;
    private Boolean isLast = false;
    private Boolean isProd = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox == false;
    
    private Integer memberCount = 0;

    public ARC_QwikPayEligibilityFile() {
        this.fileName = getFileName();
        this.fileBody = generateHeaders(newRow());
        this.path = this.isProd && !this.isTest ? 'QwikPay/' : 'QwikPayTest/';
        this.moveToSite = this.isProd && !this.isTest ? 'QwikPay' : null;
        this.moveToPath = this.isProd && !this.isTest ? 'QwikPay' : null;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT ' + String.join(getContractFields(),',') +'  FROM Contract WHERE Status = \'Activated\' AND ARC_MedicalPlan__r.vlocity_ins__ProductCode__c != \'PROG_WeShareLegacy\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Contract> contracts) {

        Set<Id> memberIds = new Set<Id>();
        Map<Id, Contract> contractMap = new Map<Id, Contract>(contracts);
        Map<Id, vlocity_ins__GroupCensusMember__c> groupCensusMembers = new Map<Id, vlocity_ins__GroupCensusMember__c>();
        List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans = getGroupCensusMemberPlans(contractMap.keySet());
        List<Map<String,String>> fileMap = new List<Map<String,String>>();
        
        for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : groupCensusMemberPlans) {
            memberIds.add(memberPlan.vlocity_ins__GroupCensusMemberId__c);
        }
        
        groupCensusMembers = getGroupCensusMembers(memberIds);

        this.fileBody += generateFileBody(groupCensusMemberPlans, groupCensusMembers, contractMap);


        // if(this.memberCount > 5000){
        if(Limits.getHeapSize() > Limits.getLimitHeapSize() * 0.1){
        // if(true){
            sendFile();
            this.fileBody = '';
            this.isFirst = false;
            this.memberCount = 0;
        }
    }

    public void finish(Database.BatchableContext bc) {
        this.isLast = true;
        sendFile();
    }

    private Map<String,String> newRow() {
        return new Map<String,String>{
            'First Name'=>'',
            'Last Name'=>'',
            'Middle Initial'=>'',
            'Suffix'=>'',
            'Gender'=>'',
            'Birth Date'=>'',
            'Primary Subscriber ID'=>'',
            'Dependent Subscriber ID'=>'',
            'Address 1'=>'',
            'Address 2'=>'',
            'City'=>'',
            'State'=>'',
            'Zip'=>'',
            'Primary Phone Number'=>'',
            'Secondary Phone Number'=>'',
            'Email'=>'',
            'Group Name'=>'',
            'Group ID'=>'',
            'Primary Care Physician NPI'=>'',
            'Primary Language'=>'',
            'Coverage Start'=>'',
            'Coverage End'=>'',
            'Plan Option ID'=>'',
            'Relationship to Primary Subscriber'=>''
        };
    }

    private String generateHeaders(Map<String,String> line){
        String headerLine = '';
        for (String key : line.keySet()) {
            headerLine += key + this.separator;
        }
        return headerLine.removeEnd(this.separator) + '\n';
    }

    private String getFileName() {
        String clientName = 'UHSM';
        String groupName = 'WeShare';
        String dateYYYYMMMDD = Datetime.now().format('YYYYMMdd', 'America/Los_Angeles');
        return 'Elig_'+clientName+'_'+groupName+'_'+dateYYYYMMMDD+'.txt';
    }

    private String getRelationshipCode(String relationship){
        switch on relationship {
            when null {
                return '01';
            }
            when 'Child' {
                return '02';
            }
            when 'Spouse' {
                return '41';
            }
            when else {
                return '65';
            }
        }
    }

    private String getGender(String gender){
        return gender != null ? (gender == 'Male' ? 'M' : 'F') : '';
    }

    private String formatDatetime(Datetime d){
        return d != null ? d.format('YYYY/MM/dd') : '';
    }

    private Map<Id,vlocity_ins__GroupCensusMember__c> getGroupCensusMembers(Set<Id> memberIds){
        Map<Id,vlocity_ins__GroupCensusMember__c> groupCensusMembers = new Map<Id,vlocity_ins__GroupCensusMember__c>((List<vlocity_ins__GroupCensusMember__c>)Database.query(
            'SELECT '+ String.join(getMemberFields(),',') +
            ' FROM vlocity_ins__GroupCensusMember__c '+
            'WHERE Id IN :memberIds AND ARC_ActiveMember__c = true'
        ));
        return groupCensusMembers;
    }


    private List<vlocity_ins__GroupCensusMemberPlan__c> getGroupCensusMemberPlans(Set<Id> contractIds){
        List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans = new List<vlocity_ins__GroupCensusMemberPlan__c>([
            SELECT Id, 
            vlocity_ins__GroupCensusMemberId__c, 
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductCode__c
            FROM vlocity_ins__GroupCensusMemberPlan__c  
            WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c IN :contractIds 
            AND vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
        ]);
        return groupCensusMemberPlans;
    }

    private String generateFileBody(List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans, Map<Id,vlocity_ins__GroupCensusMember__c> groupCensusMembers, Map<Id,Contract> contracts){
        List<Map<String,String>> fileMap = new List<Map<String,String>>();
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : groupCensusMemberPlans) {
            vlocity_ins__GroupCensusMember__c groupCensusMember = groupCensusMembers.get(gcmp.vlocity_ins__GroupCensusMemberId__c);
            if (isValidMember(groupCensusMember)) {
                Contract contract = contracts.get(gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c);
                Map<String,String> fileRow = newRow();
    
                fileRow.put('First Name', groupCensusMember.vlocity_ins__FirstName__c);
                fileRow.put('Last Name', groupCensusMember.vlocity_ins__LastName__c);
                fileRow.put('Gender', getGender(groupCensusMember.vlocity_ins__Gender__c));
                fileRow.put('Birth Date', formatDatetime(groupCensusMember.vlocity_ins__BirthDate__c));
                fileRow.put('Primary Subscriber ID', groupCensusMember.vlocity_ins__IsPrimaryMember__c ? getMemberId(groupCensusMember) : getMemberId(groupCensusMembers.get(groupCensusMember.vlocity_ins__RelatedCensusMemberId__c)));
                fileRow.put('Dependent Subscriber ID', getMemberId(groupCensusMember));
                fileRow.put('Address 1', groupCensusMember.ARC_PhysicalAddressStreet__c);
                fileRow.put('City', groupCensusMember.ARC_PhysicalAddressCity__c);
                fileRow.put('State', groupCensusMember.ARC_PhysicalAddressState__c);
                fileRow.put('Zip', groupCensusMember.ARC_PhysicalAddressZipCode__c);
                fileRow.put('Primary Phone Number', groupCensusMember.ARC_Phone__c);
                fileRow.put('Email', groupCensusMember.vlocity_ins__Email__c);
                fileRow.put('Group Name', 'UNITE HEALTH SHARE MINISTRIES');
                fileRow.put('Group ID', 'UHSMARCPO ARCS');
                fileRow.put('Primary Language', 'E');
                fileRow.put('Coverage Start', formatDatetime(contract.ARC_EffectiveDate__c));
                fileRow.put('Plan Option ID', gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ProductCode__c.toUpperCase());
                fileRow.put('Relationship to Primary Subscriber',  getRelationshipCode(groupCensusMember.ARC_DependentRelationship__c));
    
                fileMap.add(fileRow);
                this.memberCount++;
            }
        }

        String fileBody = '';
        for (Map<String,String> line : removeNullValues(fileMap)) {
            fileBody += generateLine(line);
        }
        return fileBody;
    }

    private String generateLine(Map<String,String> lineMap){
        String line = '';
        for (String key : lineMap.keySet()) {
            line += (lineMap.get(key)).replace(this.separator, '') + this.separator;
        }
        return line.removeEnd(this.separator) + '\n';
    }

    
    private static List<Map<String,String>> removeNullValues(List<Map<String,String>> file){
        for (Map<String,String> fileRow : file) {
            for (String key : fileRow.keySet()) {
                if (fileRow.get(key) == null) {
                    fileRow.put(key, '');
                }
            }
        }
        return file;
    }

    private void sendToEmail(){
        
        List<String> addresses = new List<String>();
        if (this.testEmail != null) {
            addresses.add(this.testEmail);
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(addresses);
        email.setPlainTextBody('Eligibility File Attached');
        email.setSubject('QwickPay Eligibility File' + ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox ? ' - Sandbox' : ' - Production'));

        Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
        fileAttachment.setFileName(this.fileName);
        fileAttachment.setBody(Blob.valueOf(this.fileBody));
        
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {fileAttachment});
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }


    private void sendEmailNotification(String subject, String body, String address){
        List<String> addresses = new List<String>();
        if (address != null) {
            addresses.add(address);
        }

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(addresses);
        email.setPlainTextBody(body);
        email.setSubject(subject);

        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }


    
    



    //Get Data
    private static List<String> getMemberFields(){
        return new List<String>{
            'Id',
            'vlocity_ins__FirstName__c',
            'vlocity_ins__LastName__c',
            'vlocity_ins__Gender__c',
            'vlocity_ins__BirthDate__c',
            'ARC_PhysicalAddressStreet__c',
            'ARC_PhysicalAddressCity__c',
            'ARC_PhysicalAddressState__c',
            'ARC_PhysicalAddressZipCode__c',
            'ARC_Phone__c',
            'vlocity_ins__Email__c',
            'ARC_DependentRelationship__c',
            'e123_member_id__c',
            'Member_ID__c',
            'vlocity_ins__IsPrimaryMember__c',
            'vlocity_ins__RelatedCensusMemberId__c'
        };
    }
    private static List<String> getContractFields(){
        return new List<String>{
            'Id',
            'ARC_EffectiveDate__c'
        };
    }
    
    private String getMemberId(vlocity_ins__GroupCensusMember__c member){
        if (member == null) {
            return '';
        }
        return member.e123_member_id__c != null ? member.e123_member_id__c : member.Member_ID__c;
    }

    private void sendFile(){
        // sendToEmail();
        sendFileToServer();

    }


    private void sendFileToServer(){
        ARC_QueableSendFileBatch sendJob = new ARC_QueableSendFileBatch(
            this.fileBody,
            getPath(),
            'QwikPay',
            this.isFirst,
            this.isLast,
            this.siteName,
            this.moveToSite,
            this.moveToPath
        );
        ID jobID = System.enqueueJob(sendJob);
    }

    private String getPath(){
        return this.path + this.fileName;
    }


    private Boolean isValidMember(vlocity_ins__GroupCensusMember__c groupCensusMember){
        return groupCensusMember != null && ((groupCensusMember.vlocity_ins__IsPrimaryMember__c && groupCensusMember.vlocity_ins__RelatedCensusMemberId__c == null) || (!groupCensusMember.vlocity_ins__IsPrimaryMember__c && groupCensusMember.vlocity_ins__RelatedCensusMemberId__c != null));
    }

    @InvocableMethod(label = 'Run QwikPay File Batch' description = 'Runs the QwikPay File Batch' category = 'Elegibility Files')
    global static void runBatch() {
        ARC_QwikPayEligibilityFile batchClass = new ARC_QwikPayEligibilityFile();
        //batchClass.testEmail = 'manuel.pallares@arcsona.com';
        Database.executeBatch(batchClass,20);
    }
    

}