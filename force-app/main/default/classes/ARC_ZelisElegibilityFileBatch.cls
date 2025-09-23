global with sharing class ARC_ZelisElegibilityFileBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    
    ARC_ANSI834 fileGenerator = new ARC_ANSI834();
    global Boolean sendToTest = false;
    global Integer limitOfContracts = 1000000;
    private Integer sentCount = 1;
    Integer memberCount = 0;
    private Boolean useMetadata = false;
    private List<String> list_ANSI_stringTXT;
    String ANSI_stringTXT = '';
    // ARC_Eligible_Files__c ansiElegibleFile = [ SELECT Name, ARC_LastSent__c FROM ARC_Eligible_Files__c WHERE Name = 'ANSI834' LIMIT 1 ] ;
    ARC_Eligible_Files__c ansiElegibleFile = [ SELECT Name, ARC_ZelisTransactionId__c FROM ARC_Eligible_Files__c WHERE Name = 'ANSI834' LIMIT 1 ] ;
    Date oggi = date.today();
    Integer segmentsCount = 6;
    global ARC_ZelisElegibilityFileBatch( ) {
        list_ANSI_stringTXT = new List<String>();
        ANSI_stringTXT = '';
        ansi834Filename = '';
    }
    global Database.QueryLocator start(Database.BatchableContext BC ) {
        // return Database.getQueryLocator('SELECT Id,vlocity_ins__EnrollmentCensusId__c,ARC_EffectiveDate__c,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c,ARC_Case__c, ARC_AwaitingActivationDate__c FROM Contract WHERE Status = \'Activated\' AND Id IN (\'80076000000ASdNAAW\', \'80076000000ASdDAAW\',\'800760000005wQfAAI\', \'800760000005wO7AAI\',\'800760000005vGnAAI\', \'800760000005uOiAAI\')ORDER BY CreatedDate DESC LIMIT :limitOfContracts');
        return Database.getQueryLocator('SELECT Id,vlocity_ins__EnrollmentCensusId__c,ARC_EffectiveDate__c,Status,ARC_ContractReason__c,ARC_SingleReasonForPC__c,ARC_Case__c, ARC_AwaitingActivationDate__c FROM Contract WHERE Status = \'Activated\' ORDER BY CreatedDate DESC LIMIT :limitOfContracts');
    }
    
    global void execute(Database.BatchableContext BC, List<Contract> elegibilityContracts ) {
        boolean reachingLimits = false;
        Set<Id> censusIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        for ( Contract contract : elegibilityContracts ) {
            censusIds.add(contract.vlocity_ins__EnrollmentCensusId__c);
            contractIds.add(contract.Id);
        }
        Set<Id> elegibilityContractsIds = new Set<Id>();
        Set<Id> repeatedCensusIds = new Set<Id>();
        Set<Id> nonRepeatedCensusIds = new Set<Id>();
        List<RecordType> recordTypes = [ SELECT Id,DeveloperName FROM RecordType WHERE DeveloperName = 'CoverageSpec' OR DeveloperName = 'Product' ] ;
        Id productRecordType;
        Id coverageRecordType;
        for ( RecordType rt : recordTypes ) {
            if ( rt.DeveloperName == 'CoverageSpec' ) {
                coverageRecordType = rt.Id;
            }else{
                productRecordType = rt.Id;
            }
        }
        List<vlocity_ins__ContractLineItem__c> medicalProducts = [ SELECT vlocity_ins__Product2Id__c,vlocity_ins__ProductType__c,vlocity_ins__ProductCode__c, vlocity_ins__ContractId__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__Product2Id__r.RecordTypeId = :productRecordType AND vlocity_ins__ProductType__c = 'Medical' AND vlocity_ins__ContractId__c IN :contractIds ] ;
        Set<Id> medicalProductsIds = new Set<Id>();
        Map<Id, Object> contract_financeVisitCoverage = new Map<Id, Object>();
        Map<Id, vlocity_ins__ContractLineItem__c> contract_medicalProduct = new Map<Id,vlocity_ins__ContractLineItem__c>();
        for ( vlocity_ins__ContractLineItem__c medicalProduct : medicalProducts ) {
            medicalProductsIds.add(medicalProduct.vlocity_ins__Product2Id__c);
            for ( Contract contract : elegibilityContracts ) {
                if ( medicalProduct.vlocity_ins__ContractId__c == contract.Id ) {
                    contract_medicalProduct.put(contract.Id,medicalProduct);
                }
            }
        }

        List<Map<String,Object>> listToTXT = new List<Map<String,Object>>();
        // Set<Id> contractIds = new Set<Id>();
        Map<Id, Date> contract_approvedDate = new Map<Id, Date>();
        for ( Contract contract : elegibilityContracts ) { 
            contract_approvedDate.put(contract.Id, Date.valueOf(contract.ARC_AwaitingActivationDate__c));
        }

        

        // GENERATE ELEGIBILITY FILE
        List<vlocity_ins__GroupCensusMember__c> ansiMembers = [ SELECT Id, vlocity_ins__RelatedCensusMemberId__c, vlocity_ins__RelatedCensusMemberId__r.Member_ID__c, vlocity_ins__RelatedCensusMemberId__r.e123_member_id__c, Name,ARC_PhysicalAddressState__c, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, ARC_PhysicalAddressCity__c,ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressZipCode__c, vlocity_ins__CensusId__c,ARC_Phone__c,vlocity_ins__Email__c,vlocity_ins__Birthdate__c,vlocity_ins__Gender__c,vlocity_ins__SocialSecurityNumber__c, ARC_OldSSN__c, vlocity_ins__IsPrimaryMember__c,vlocity_ins__IsSpouse__c, Member_ID__c, e123_member_id__c FROM vlocity_ins__GroupCensusMember__c WHERE ARC_ActiveMember__c = true and vlocity_ins__CensusId__c IN :censusIds ] ;
        // Get only the E123 members
        // List<vlocity_ins__GroupCensusMember__c> ansiMembers = [ SELECT Id, vlocity_ins__RelatedCensusMemberId__r.Member_ID__c, vlocity_ins__RelatedCensusMemberId__r.e123_member_id__c, Name,ARC_PhysicalAddressState__c, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, ARC_PhysicalAddressCity__c,ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressZipCode__c, vlocity_ins__CensusId__c,ARC_Phone__c,vlocity_ins__Email__c,vlocity_ins__Birthdate__c,vlocity_ins__Gender__c,vlocity_ins__SocialSecurityNumber__c, ARC_OldSSN__c, vlocity_ins__IsPrimaryMember__c,vlocity_ins__IsSpouse__c, Member_ID__c, e123_member_id__c FROM vlocity_ins__GroupCensusMember__c WHERE e123_member_id__c != null AND ARC_ActiveMember__c = true and vlocity_ins__CensusId__c IN :censusIds ] ;
        List<AggregateResult> transactions = [ SELECT ChargentOrders__Order__r.ARC_Contract__c, MAX(ChargentOrders__Gateway_Date__c) transactionDate  FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Order__r.ARC_Contract__c IN :contractIds AND ChargentOrders__Response_Status__c = 'Approved' AND ChargentOrders__Type__c = 'Charge' GROUP BY ChargentOrders__Order__r.ARC_Contract__c ] ;
        for ( Contract contract : elegibilityContracts ) {
            
            String ansi_lastTransactionDate = '';
            AggregateResult transa;
            List<vlocity_ins__GroupCensusMember__c> membersPerContract = new List<vlocity_ins__GroupCensusMember__c>();
            for ( AggregateResult t : transactions ) {
                if ( t.get('ARC_Contract__c') == contract.Id ) {
                    transa = t;
                }
            }

            for ( vlocity_ins__GroupCensusMember__c member : ansiMembers ) {
                if ( member.vlocity_ins__CensusId__c == contract.vlocity_ins__EnrollmentCensusId__c ) {
                    membersPerContract.add(member);
                }
            }

            if ( contract_medicalProduct.get(contract.Id) != null ) {
                Date apprvdDate = contract.ARC_EffectiveDate__c;

                if ( contract_approvedDate.get(contract.Id) != null ) {
                    apprvdDate = contract_approvedDate.get(contract.Id);
                }
                
                String newString = fileGenerator.generate(contract,contract_medicalProduct.get(contract.Id),membersPerContract,transa,apprvdDate, 'Zelis');
                ANSI_stringTXT += newString;
                memberCount += membersPerContract.size();
                newString = '';
                

                if ( Limits.getHeapSize() > Limits.getLimitHeapSize() * 0.4 ) {
                    reachingLimits = true;
                }
            }

            if ( memberCount > 10000 ) {
                sendFile();
                memberCount = 0;
            }
        }
    }

    global void finish(Database.BatchableContext BC ) {
            sendFile();
    }



    private String ansi834Filename = ''; 
    private void sendFile(){
        if (ansi834Filename == '') {
            ansi834Filename = Datetime.now().format('YYYYMMdd_HHmmss', 'America/Los_Angeles')+'_UHSM-v';
        }
        String finalFilename = ansi834Filename+sentCount+'.txt';
        ARC_QueableSendFileBatch sendJob = new ARC_QueableSendFileBatch(ANSI_stringTXT, finalFilename, fileGenerator.segments + 6, sendToTest, ansiElegibleFile.ARC_ZelisTransactionId__c, 'Zelis');
        ID jobID = System.enqueueJob(sendJob);
        sentCount ++;
        ANSI_stringTXT = '';
        fileGenerator.segments = 0;

        ansiElegibleFile.ARC_ZelisTransactionId__c ++;
        update ansiElegibleFile;
    }

    // private void saveMetadata(){
    //     List<ARC_ElegibilityFileContent__c> files = new List<ARC_ElegibilityFileContent__c>();
    //     Decimal index = ARC_ElegibilityFilesMetadata.getLastIndex('Zelis');
    //     List<String> segments = splitTextInSegments(ANSI_stringTXT);
    //     for (String content : segments) {
    //         files.add(ARC_ElegibilityFilesMetadata.createFile('Zelis', content, index));
    //         index++;
    //     }
    //     ARC_ElegibilityFilesMetadata.saveFileData(files, 'Zelis');
    // }

    // private List<String> splitTextInSegments(String text){
    //     List<String> segments = new List<String>();
    //     for (Integer i = 0; i < text.length(); i += 131072) {
    //         Integer endIndex = i + 131072;
    //         if (endIndex > text.length()) {
    //             endIndex = text.length();
    //         }
    //         segments.add(text.substring(i, endIndex));
    //     }
    //     return segments;
    // }

    // private String listToString(List<String> listText){
    //     String resultText = '';
    //     for (String text : listText) {
    //         resultText += text;
    //     }
    //     return resultText;
    // }

    



    @InvocableMethod(label = 'Run Zelis File Batch' description = 'Runs the Zelis File Batch' category = 'Elegibility Files')
    global static void runZelisBatch( ) {
        ARC_ZelisElegibilityFileBatch a = new ARC_ZelisElegibilityFileBatch();
        Database.executeBatch(a,10);
    }
}