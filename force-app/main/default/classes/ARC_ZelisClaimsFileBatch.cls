global with sharing class ARC_ZelisClaimsFileBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public Boolean isTest = false;
    private Integer totalFiles;
    private Id checkrunId;
    private Set<Id> claimIds;
    private Boolean checkrunClosure;
    private Boolean sendToZelis;
    private List<Blob> zipFilesList = new List<Blob>();
    private List<String> fileNameList = new List<String>();
    private Boolean first = true;
    //Initiate XML
    private String XML_Claim = '<file>\n' +'<formatId>001</formatId>\n';
    private String fileName = generateFileName();
    private String folderName = '';

    

    // Create the inboundDocumentIdentifier for document tag
    Integer inboundDocumentIdentifier = 1;

    global ARC_ZelisClaimsFileBatch(Set<Id> clmsIds, Boolean chkClose, Id chkrunId) {
        this.claimIds = clmsIds;
        this.checkrunClosure = chkClose;
        this.checkrunId = chkrunId;
        this.sendToZelis = true;
    }

    global ARC_ZelisClaimsFileBatch(Set<Id> clmsIds, Boolean chkClose, Id chkrunId, Boolean sndToZelis) {
        this.claimIds = clmsIds;
        this.checkrunClosure = chkClose;
        this.checkrunId = chkrunId;
        this.sendToZelis = sndToZelis;
    }

    global Database.QueryLocator start(Database.BatchableContext BC ) {

        return Database.getQueryLocator('SELECT Id, ARC_Attending_Provider__r.Name, ARC_Attending_Provider__r.ARC_NationalProviderIdentifier__pc, ARC_DOSFrom__c,ARC_DOSTo__c,ARC_Payment_To__c,ARC_CheckNumber__c, ARC_PayToStreet__c,ARC_PayToCity__c,ARC_PayTo_State__c,ARC_PayTo_ZipCode__c,ARC_Vendor__r.Name,ARC_Vendor__r.vlocity_ins__TaxID__c,ARC_Vendor__r.BillingStreet,RecordType.Name,ARC_Vendor__r.BillingCity,ARC_Vendor__r.BillingState,ARC_Vendor__r.BillingPostalCode,  ARC_TotalIneligibleAmount__c,ARC_TotalNetPaidAmount__c,ARC_TotalPreviouslyPaidAmount__c,ARC_TotalPatientResponsibilityAmount__c,ARC_TotalDiscountAmount__c,ARC_Vendor__r.ARC_Provider_Tax_Id__c , ARC_Vendor__r.ARC_Provider_Name__c, ARC_MemberContact__c, ARC_ClaimNotes__c, ARC_MemberBenefitPlan__c, ARC_ClaimTotalAmount__c, ARC_TotalAdjustedAmount__c ,ARC_TotalDeductibleAmount__c, ARC_TotalTobacco__c, ARC_Total_PreExistingConditions__c, ARC_TotalCoinsuranceAmount__c, ARC_TotalCopayAmount__c, ARC_TotalAllowedAmount__c,ARC_Vendor__r.ARC_NationalProviderId__c, ARC_TransactionSetControlNumber__c, LossDate, ARC_OriginalReceivedDate__c, Name, PolicyNumber.Name, ARC_PrimaryMemberCM__r.Name,  ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingStreet, ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingCity, ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingState, ARC_PrimaryMemberCM__r.vlocity_ins__ContactId__r.Account.BillingPostalCode, ARC_QwikPay__c, ARC_FlaggedAs__c, ARC_ClaimStatusCode__c, ARC_FilingIndicatorCode__c, ARC_Adjust__c, ARC_OriginalSMB__c, ARC_TotalMBRLiabilityAmount__c, ARC_MemberID__c FROM Claim WHERE Id IN :claimIds');
    }
    
    global void execute(Database.BatchableContext BC, List<Claim> claims ) {  
        Map <String, Object> xmlData = new Map <String, Object>();
        Map <Id,Id> clmToAdjustedClaim = new Map <Id,Id>();
        Set<Id> contactIds = new Set<Id>();
        if([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
            folderName = 'checkrunsTest'; 
        }else {
            folderName = 'checkruns' + Datetime.now().format('YYYY', 'America/Los_Angeles'); 
        }

        for ( Claim c : claims ) {
            contactIds.add(c.ARC_MemberContact__c);
            if(c.ARC_Adjust__c) clmToAdjustedClaim.put(c.ARC_OriginalSMB__c, c.Id);
        }

        
        // Get all Contacts data related to Claim
        Map<Id, Contact> mapClaimContact = new Map<Id, Contact>();
        for ( Contact c : [
            SELECT Id, Name, FirstName, LastName,vlocity_ins__MiddleName__c, Birthdate,ARC_CensusMember__r.ARC_PhysicalAddressStreet__c,  ARC_CensusMember__r.ARC_PhysicalAddressCity__c, ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.Name,
            ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__ContactId__r.vlocity_ins__MiddleName__c,ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__LastName__c, ARC_CensusMember__r.ARC_PhysicalAddressState__c, ARC_CensusMember__r.ARC_PhysicalAddressZipCode__c, ARC_CensusMember__r.ARC_Relationship__c,
            ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.ARC_PhysicalAddressStreet__c,ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.ARC_PhysicalAddressCity__c, ARC_CensusMember__r.vlocity_ins__IsPrimaryMember__c, 
            ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.ARC_PhysicalAddressState__c, ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.ARC_PhysicalAddressZipCode__c, Account.BillingStreet, Account.BillingCity, Account.BillingState, 
            Account.BillingPostalCode, ARC_CensusMember__r.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__FirstName__c
            FROM Contact 
            WHERE Id IN :contactIds]
        ) {
            mapClaimContact.put(c.Id, c);
        }

        //Get all Claim Coverage Payment Detail related to Claim
        Map<Id,List<ClaimCoveragePaymentDetail>> mapClaimCovPayDet = new Map<Id,List<ClaimCoveragePaymentDetail>>();

        Map<Id, ClaimCoveragePaymentDetail> mapCCPD = new Map<Id, ClaimCoveragePaymentDetail>([
            SELECT Id, Status, ARC_Claim__c, Name, ARC_DateOfService__c, ARC_ProcedureCodeName__c,ARC_ProcedureCode__r.vlocity_ins__ShortDescription__c, ARC_Allowed__c, AdjustedAmount, ARC_Copay__c, ARC_Deductible__c, ARC_Coinsurance__c, 
            ARC_Discount__c,ARC_Ineligible__c,ARC_NetPaid__c,ARC_PatientResp__c,ARC_Tobacco__c,ARC_Pre_Existing_Condition__c,ARC_DOSFrom__c, ARC_DOSTo__c,ClaimedAmount,ARC_RevenueCode__c, ARC_MBRLiability__c,
                (SELECT Id, ARC_CodeNameText__c, ARC_CodeDescription__c, ARC_ReasonCode__r.ARC_WPCRemarkCode__c, ARC_ReasonCode__r.ARC_WPCClaimEditCode__c, ARC_ReasonCode__r.ARC_WPCInfoCode__c,ARC_ReasonCode__r.ARC_Status__c
                FROM Claim_Reason_Codes__r 
                ORDER BY CreatedDate ASC LIMIT 4) 
            FROM ClaimCoveragePaymentDetail
            WHERE ARC_Claim__c IN :claims ORDER BY ARC_ItemNumber__c NULLS LAST
        ]);

        for(Id key: mapCCPD.keySet()){
            ClaimCoveragePaymentDetail ccpd = (ClaimCoveragePaymentDetail) mapCCPD.get(key);
            // Round currency fields to 2 decimal places
            if (ccpd.ARC_Allowed__c != null) ccpd.ARC_Allowed__c = ccpd.ARC_Allowed__c.setScale(2);
            if (ccpd.ARC_Copay__c != null) ccpd.ARC_Copay__c = ccpd.ARC_Copay__c.setScale(2);
            if (ccpd.ARC_Deductible__c != null) ccpd.ARC_Deductible__c = ccpd.ARC_Deductible__c.setScale(2);
            if (ccpd.ARC_Coinsurance__c != null) ccpd.ARC_Coinsurance__c = ccpd.ARC_Coinsurance__c.setScale(2);
            if (ccpd.ARC_Discount__c != null) ccpd.ARC_Discount__c = ccpd.ARC_Discount__c.setScale(2);
            if (ccpd.ARC_Ineligible__c != null) ccpd.ARC_Ineligible__c = ccpd.ARC_Ineligible__c.setScale(2);
            if (ccpd.ARC_Tobacco__c != null) ccpd.ARC_Tobacco__c = ccpd.ARC_Tobacco__c.setScale(2);
            if (ccpd.ARC_Pre_Existing_Condition__c != null) ccpd.ARC_Pre_Existing_Condition__c = ccpd.ARC_Pre_Existing_Condition__c.setScale(2);
            if (ccpd.ClaimedAmount != null) ccpd.ClaimedAmount = ccpd.ClaimedAmount.setScale(2);
            if (ccpd.ARC_MBRLiability__c != null) ccpd.ARC_MBRLiability__c = ccpd.ARC_MBRLiability__c.setScale(2);
            if (ccpd.AdjustedAmount != null) ccpd.AdjustedAmount = ccpd.AdjustedAmount.setScale(2);
            
            List<ClaimCoveragePaymentDetail> ccpdList = (List<ClaimCoveragePaymentDetail>) mapClaimCovPayDet.get(ccpd.ARC_Claim__c);
            if (ccpdList == null) mapClaimCovPayDet.put(ccpd.ARC_Claim__c, new List<ClaimCoveragePaymentDetail>{ccpd});
            else{
                ccpdList.add(ccpd);
                mapClaimCovPayDet.put(ccpd.ARC_Claim__c, ccpdList);
            }
        }

        //Get Net Paid of SMB Items on adjusted claims
        Map<Id,List<ClaimCoveragePaymentDetail>> mapClmIdAdjCCPD = new Map<Id,List<ClaimCoveragePaymentDetail>>();
        if(!clmToAdjustedClaim.isEmpty()){
            Map<Id, ClaimCoveragePaymentDetail> mapIdAdjCCPD = new Map<Id, ClaimCoveragePaymentDetail>([SELECT Id, Name, ARC_Claim__c, ARC_NetPaid__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c IN :clmToAdjustedClaim.keySet() ORDER BY ARC_ItemNumber__c NULLS LAST]);
            for(Id key: mapIdAdjCCPD.keySet()){
                ClaimCoveragePaymentDetail ccpd = (ClaimCoveragePaymentDetail) mapIdAdjCCPD.get(key);
                List<ClaimCoveragePaymentDetail> adjCcpdList = (List<ClaimCoveragePaymentDetail>) mapClmIdAdjCCPD.get(clmToAdjustedClaim.get(ccpd.ARC_Claim__c));
                if (adjCcpdList == null) mapClmIdAdjCCPD.put(clmToAdjustedClaim.get(ccpd.ARC_Claim__c), new List<ClaimCoveragePaymentDetail>{ccpd});
                else{
                    adjCcpdList.add(ccpd);
                    mapClmIdAdjCCPD.put(clmToAdjustedClaim.get(ccpd.ARC_Claim__c), adjCcpdList);
                }
            }
        }

        // Iterate through all the claims and generate the documents
        xmlData.put('checkClosing', checkrunClosure);
        for ( Claim c : claims ) {
            xmlData.put('claim', c);
            xmlData.put('contact', mapClaimContact.get(c.ARC_MemberContact__c));
            xmlData.put('listCCPD', mapClaimCovPayDet.get(c.Id));
            xmlData.put('listAdjCCPD', mapClmIdAdjCCPD.get(c.Id));
            if(c.ARC_Payment_To__c == 'Provider' && c.ARC_QwikPay__c == false){
                xmlData.put('isProvider', false);
                xmlData.put('inboundDocumentIdentifier', inboundDocumentIdentifier);
                this.XML_Claim+=(ARC_ClaimsXML.generate(xmlData));
                //Increment the inboun document indentifier counter per document node
                xmlData.put('isProvider', true);
                xmlData.put('inboundDocumentIdentifier', ++inboundDocumentIdentifier);
                this.XML_Claim+=(ARC_ClaimsXML.generate(xmlData));
            } else {
                xmlData.put('isProvider', false);
                xmlData.put('inboundDocumentIdentifier', inboundDocumentIdentifier);
                this.XML_Claim+=(ARC_ClaimsXML.generate(xmlData));
            }
            //Increment the inboun document indentifier counter per document node
            inboundDocumentIdentifier++;
        }
 
        if(Limits.getHeapSize() > Limits.getLimitHeapSize() * 0.2){
            // Close the XML file
            if(this.XML_Claim != '') {
                sendFile();
            }
        } 
                
    }
    
    global void finish(Database.BatchableContext BC ) {
        this.XML_Claim += '</file>';
        sendFile();
        
        ARC_ZelisPostToApi job = new ARC_ZelisPostToApi(fileName, checkRunId, folderName, checkrunClosure, claimIds, sendToZelis);
        System.enqueueJob(job);

    }

    private String generateFileName(){
        // Set the file name
        String fileName = '';
        // ZELIS STL Client Number
        fileName += System.Label.ARC_ZelisClientNumber;
        // Origin ID
        fileName += System.Label.ARC_ZelisOriginID;
        // Date
        fileName += Datetime.now().format('YYYYMMdd', 'America/Los_Angeles');
        // R
        fileName += 'R';
        // Counter
        fileName +=  ARC_CounterXMLFile.generateCounter();
        // E
        fileName += 'E';
        // Translation ID
        fileName += System.Label.ARC_ZelisTranslationID;
        // D
        fileName += 'D';
        // File Count of Set
        fileName += '1';
        // Total File Count of Set
        fileName += '1';

        return fileName;
    }

    private void sendFile(){

        sendFileToServer('UHSM');
        //Send and email with the file if needed, otherwise keep commented
        if(System.Label.ARC_ZelisTestingEmail.contains('@')){
            System.debug('Testing Email');                   
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setContentType('application/xml');
            attach.setFileName(fileName+'.xml');
            attach.setInline(false);
            attach.Body = Blob.valueOf(this.XML_Claim);
            
            List<String> toAddresses = new List<String>();
            toAddresses.add(System.Label.ARC_ZelisTestingEmail);
            email.setToAddresses( toAddresses );
            email.setPlainTextBody('Zelis Claims Files');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});
            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});  
        }
        this.XML_Claim='';
    }

    private void sendFileToServer(String finalPath) {
        try {
            if(!Test.isRunningTest()) {
                if (this.first) {
                    FTP2SF.FTP.Response result = FTP2SF.FTP.put(finalPath, folderName +'/' + fileName+'.xml', Blob.valueOf(this.XML_Claim));
                    System.debug(result);
                    this.first = false;
                } else{
                    FTP2SF.FTP.Response result = FTP2SF.FTP.append(finalPath, folderName +'/' + fileName+'.xml', Blob.valueOf(this.XML_Claim));
                    System.debug(result);

                }
            }
        } catch (Exception e) {
            system.debug(e.getMessage());
        }   
    }

    @InvocableMethod(label = 'Run Zelis Claims File Batch' description = 'Runs the Zelis Claims File Batch' category = 'Elegibility Files')
        global static void runZelisBatch(List<Id> checkRunId) {
            Set<Id> clmIds = new Set<Id>();
            List<Claim> claims = [SELECT Id FROM Claim WHERE ARC_CheckRun__c =: checkRunId[0] ];
            for(Claim clm : claims) clmIds.add(clm.Id);
            Database.executeBatch(new ARC_ZelisClaimsFileBatch(clmIds, true, checkRunId[0]), 50);
        }

}