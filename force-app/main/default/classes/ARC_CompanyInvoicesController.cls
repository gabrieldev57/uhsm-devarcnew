public with sharing class ARC_CompanyInvoicesController {
    @TestVisible
    private static Id testAccountId;

    private static Id resolveRunningAccountId() {
     
        if (Test.isRunningTest() && testAccountId != null) {
            return testAccountId;
        }

        return [
            SELECT AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ].AccountId;
    }

    @AuraEnabled
    public static List<Map<String, Object>> getInvoicesList() {
        // Variables
        Contract selectedContract;
        Map<Id, ARC_Invoice__c> invoicesMap;
        List<Map<String, Object>> output = new List<Map<String, Object>>();
        Map<String, Object> outputMap = new Map<String, Object>();
        Date today = Date.today();
        // Resolve the Account once so production keeps using the logged-in user context,
        // while tests can inject a stable AccountId without requiring an external user.
        Id runningAccountId = resolveRunningAccountId();
        List<ContentDocumentLink> links;
        Set<Id> documentIds = new Set<Id>();
        Map<Id, Id> documentToInvoice = new Map<Id, Id>();
        Map<Id, ContentVersion> invoiceToContentVersion = new Map<Id, ContentVersion>();
        Map<Id, ContentVersion> versions;
        List<ContentDistribution> existingDistributions;
        List<ContentDistribution> distributionsToInsert = new List<ContentDistribution>();
        Map<Id, ContentDistribution> versionToDistribution = new Map<Id, ContentDistribution>();
        String baseUrl;
        Map<String, Integer> fileNamesCounter = new Map<String, Integer>();

        baseUrl = URL.getOrgDomainUrl().toExternalForm();

        // Get Contract
        // selectedContract = [
        //     SELECT Id,
        //         ARC_CoveragePaidThrough__c,
        //         ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c
        //     FROM Contract
        //     WHERE AccountId IN (
        //         SELECT AccountId
        //         FROM User
        //         WHERE Id = :UserInfo.getUserId()
        //     )
        //     WITH SECURITY_ENFORCED
        //     LIMIT 1
        // ];

        selectedContract = [
            SELECT Id,
                ARC_CoveragePaidThrough__c,
                ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c
            FROM Contract
            WHERE AccountId = :runningAccountId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (selectedContract == null) {
            return output;
        }

        invoicesMap = new Map<Id, ARC_Invoice__c> (
            [
                SELECT Id,
                   Name,
                   ARC_Description__c,
                   ARC_CoverageAmount__c,
                   ARC_CoverageDateFrom__c,
                   ARC_DueDate__c
                FROM ARC_Invoice__c
                WHERE ARC_Contract__c = :selectedContract.Id
            ]
        );

        links = [
            SELECT ContentDocumentId,
                   LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :invoicesMap.keySet()
        ];

        for (ContentDocumentLink link : links) {
            documentToInvoice.put(link.ContentDocumentId, link.LinkedEntityId);
            documentIds.add(link.ContentDocumentId);
        }

        versions = new Map<Id, ContentVersion>(
            [SELECT Id, 
                   Title, 
                   FileExtension, 
                   ContentDocumentId,
                   VersionData
            FROM ContentVersion
            WHERE ContentDocumentId IN :documentIds
            AND FileExtension = 'pdf'
            AND IsLatest = true]
        );

        existingDistributions = [
            SELECT DistributionPublicUrl,
                   ContentVersionId
            FROM ContentDistribution 
            WHERE ContentVersionId IN :versions.keySet()
        ];

        for (ContentDistribution distribution : existingDistributions) {
            versionToDistribution.put(distribution.ContentVersionId, distribution);
        }

        for (ContentVersion cv : versions.values()) {
            if (!versionToDistribution.containsKey(cv.Id)) {
                ContentDistribution cd = new ContentDistribution();
                cd.Name = cv.Title;
                cd.ContentVersionId = cv.Id;
                cd.PreferencesAllowViewInBrowser = true;
                cd.PreferencesLinkLatestVersion = true;
                cd.PreferencesNotifyOnVisit = false;
                cd.PreferencesPasswordRequired = false;
                cd.PreferencesAllowOriginalDownload = true;
                
                distributionsToInsert.add(cd);
            }
        }

        insert distributionsToInsert;
        
        List<ContentDistribution> allDistributions = [
            SELECT Id, 
                   DistributionPublicUrl, 
                   ContentVersionId 
            FROM ContentDistribution 
            WHERE ContentVersionId IN :versions.keySet()
        ];

        for (ContentDistribution distribution : allDistributions) {
            if (!versionToDistribution.containsKey(distribution.ContentVersionId)) {
                versionToDistribution.put(distribution.ContentVersionId, distribution);
            }
        }

        for (ContentVersion cv : versions.values()) {
            Id invoiceId = documentToInvoice.get(cv.ContentDocumentId);
            if (invoiceId != null) {
                invoiceToContentVersion.put(invoiceId, cv);
            }
        }

        // Prepare the output
        for (ARC_Invoice__c invoice : invoicesMap.values()) {
            // Variables
            // ContentDistribution invoiceToDownload;
            Map<String, String> fileData = new Map<String, String>();
            // Map<String, Object> outputMap = new Map<String, Object>();
            Map<String, Object> invoiceData = new Map<String, Object>();
            String status = '';
            String statusStyle = 'slds-text-body_regular status-style ';

            // Get the Status and Status Style
            if (invoice.ARC_CoverageDateFrom__c < selectedContract.ARC_CoveragePaidThrough__c) {
                Integer chargeDate = selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c != null ? Integer.valueOf(selectedContract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Charge_Date__c) : 0;
                if (chargeDate > today.day() 
                    && invoice.ARC_CoverageDateFrom__c.month() == selectedContract.ARC_CoveragePaidThrough__c.month()) 
                {
                    status = 'Pending';
                    statusStyle += 'pending-color';
                } else {
                    status = 'Paid';
                    statusStyle += 'paid-color';
                }
            } else if (invoice.ARC_DueDate__c < Date.today()) {
                status = 'Overdue';
                statusStyle += 'overdue-color';
            } else {
                status = 'Pending';
                statusStyle += 'pending-color';
            }

            // Prepare the output
            invoiceData.put('Id', invoice.Id);
            invoiceData.put('Number', invoice.Name);
            invoiceData.put('Description', invoice.ARC_Description__c);
            invoiceData.put('Amount', invoice.ARC_CoverageAmount__c);
            invoiceData.put('Date', invoice.ARC_CoverageDateFrom__c);
            invoiceData.put('DueDate', invoice.ARC_DueDate__c);
            invoiceData.put('Status', status);
            invoiceData.put('StatusStyle', statusStyle);

            // Get files data
            ContentVersion contentVersionTemp = invoiceToContentVersion.get(invoice.Id);

            if (contentVersionTemp != null) {
                ContentDistribution distributionTemp = versionToDistribution.get(contentVersionTemp.Id);
                String fileNameFormatted = '';
                if (fileNamesCounter.containsKey(contentVersionTemp.Title + '.pdf')) {
                    String title = contentVersionTemp.Title;
                    Integer counter = fileNamesCounter.get(title + '.pdf') + 1;
                    fileNameFormatted = title + '(' + counter + ').pdf';
                    fileNamesCounter.put(title + '.pdf', counter);
                } else {
                    fileNameFormatted = contentVersionTemp.Title + '.pdf';
                    fileNamesCounter.put(fileNameFormatted, 0);
                }
    
                fileData.put('base64Data', EncodingUtil.base64Encode(contentVersionTemp.VersionData));
                fileData.put('fileName', fileNameFormatted);
    
                // invoiceData.put('pdfPreview', baseUrl + '/sfc/servlet.shepherd/version/download/' + contentVersionTemp.Id);
                invoiceData.put('pdfPreview', distributionTemp.DistributionPublicUrl);
                invoiceData.put('base64Data', fileData.get('base64Data'));
                invoiceData.put('fileName', fileData.get('fileName'));
                invoiceData.put('contentVersionId', contentVersionTemp.Id);
            }

            output.add(invoiceData);
        }

        return output;
    }

    //Method for getting the invoice preview data by invoice Id, used in the invoice details page (PDF Preview)
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getInvoicePreviewById(String invoiceId) {
        if (String.isBlank(invoiceId)) {
            return null;
        }

        List<Map<String, Object>> invoices = getInvoicesList();

        for (Map<String, Object> invoice : invoices) {
            if (String.valueOf(invoice.get('Id')) == invoiceId) {
                return invoice;
            }
        }

        return null;
    }
}