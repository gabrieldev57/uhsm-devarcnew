public with sharing class ARC_QuoteAcceptedProductsController {

    @AuraEnabled
    public static List<QuoteLineItem> getQuoteLineItems(Id quoteId) {
        return [
            SELECT Id, LineNumber,
                   Product2.Name,
                   ARC_EligibleForContract__c
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
        ];
    }

    @AuraEnabled
    public static Map<String, Object> handleSave(List<QuoteLineItem> qlis) {
        Savepoint sp = Database.setSavepoint();
        try {
            update qlis;
            return updateContractLineItems(qlis);
        } catch (AuraHandledException e) {
            Database.rollback(sp);
            throw e;
        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(
                'You cannot edit Quote Line Items because the Quote is not in the Accepted stage. If the products appear blocked when the stage is Accepted, it means you do not have permission to modify them.'
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static Quote getQuoteContext(Id quoteId) {
        return [
            SELECT Id, Status,
                   Opportunity.RecordType.DeveloperName
            FROM Quote
            WHERE Id = :quoteId
            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Boolean canEditQLIOnAcceptedQuote() {
        return FeatureManagement.checkPermission('ARC_EditQLIOnAcceptedQuote');
    }

    @AuraEnabled
    public static Map<String, Object> updateContractLineItems(List<QuoteLineItem> qlis) {
        Map<String, Object> result = new Map<String, Object>{
            'success' => false,
            'hasDeletedContributions' => false,
            'message' => ''
        };
        
        if (qlis == null || qlis.isEmpty()) {
            result.put('message', 'No Quote Line Items provided');
            return result;
        }
        
        try {
            List<Id> qliIds = new List<Id>();
            for (QuoteLineItem qli : qlis) qliIds.add(qli.Id);
            
            Map<Id, QuoteLineItem> fullQLIMap = new Map<Id, QuoteLineItem>([
                SELECT Id, QuoteId, Product2Id, Product2.Name, ARC_EligibleForContract__c,
                       Quote.OpportunityId, Quote.AccountId, Quote.Status, Quote.ContractId
                FROM QuoteLineItem
                WHERE Id IN :qliIds
            ]);
            
            if (fullQLIMap.isEmpty()) {
                result.put('message', 'No Quote Line Items found');
                return result;
            }
            
            Id firstQuoteId = fullQLIMap.values()[0].QuoteId;
            Id opportunityId = fullQLIMap.values()[0].Quote.OpportunityId;
            Id accountId = fullQLIMap.values()[0].Quote.AccountId;
            Id contractId = fullQLIMap.values()[0].Quote.ContractId;

            Contract existingContract = null;

            if (contractId != null) {
                List<Contract> contracts = [
                    SELECT Id, AccountId,
                           (SELECT Id, vlocity_ins__Product2Id__c, Name 
                            FROM vlocity_ins__ContractLineItems__r)
                    FROM Contract
                    WHERE Id = :contractId
                    LIMIT 1
                ];
                if (!contracts.isEmpty()) {
                    existingContract = contracts[0];
                }
            }

            if (existingContract == null) {
                result.put('message', 'No existing Contract found');
                result.put('success', true);
                return result;
            }

            Boolean canEdit = FeatureManagement.checkPermission('ARC_EditQLIOnAcceptedQuote');

            if (
                existingContract != null &&
                fullQLIMap.values()[0].Quote.Status != 'Accepted' &&
                !canEdit
            ) {
                throw new AuraHandledException(
                    'You cannot edit Quote Line Items because a Contract already exists for this Quote and you do not have permission to modify them.'
                );
            }

            Set<Id> selectedProductIds = new Set<Id>();
            Set<Id> declinedProductIds = new Set<Id>();

            for (QuoteLineItem qli : qlis) {
                QuoteLineItem fullQLI = fullQLIMap.get(qli.Id);
                if (fullQLI == null) continue;

                if (qli.ARC_EligibleForContract__c == 'Selected') {
                    selectedProductIds.add(fullQLI.Product2Id);
                } else if (qli.ARC_EligibleForContract__c == 'Declined') {
                    declinedProductIds.add(fullQLI.Product2Id);
                }
            }

            List<vlocity_ins__GroupClass__c> groupClasses = [
                SELECT Id, Name, ARC_Opportunity__c,
                       (SELECT Id, Name, ARC_ContractLineItem__c 
                        FROM vlocity_ins__GroupClassContributions__r
                        WHERE ARC_ContractLineItem__c != null)
                FROM vlocity_ins__GroupClass__c
                WHERE ARC_Opportunity__c = :opportunityId
            ];
            
            Boolean contributionsDeleted = false;
            List<vlocity_ins__GroupClassContribution__c> allContributionsToDelete = new List<vlocity_ins__GroupClassContribution__c>();
            
            if (!groupClasses.isEmpty() && existingContract != null) {
                Set<Id> cliIdsForDeclinedProducts = new Set<Id>();
                
                for (vlocity_ins__ContractLineItem__c cli : existingContract.vlocity_ins__ContractLineItems__r) {
                    if (declinedProductIds.contains(cli.vlocity_ins__Product2Id__c)) {
                        cliIdsForDeclinedProducts.add(cli.Id);
                    }
                }
                
                if (!cliIdsForDeclinedProducts.isEmpty()) {
                    for (vlocity_ins__GroupClass__c gc : groupClasses) {
                        for (vlocity_ins__GroupClassContribution__c contrib : gc.vlocity_ins__GroupClassContributions__r) {
                            if (cliIdsForDeclinedProducts.contains(contrib.ARC_ContractLineItem__c)) {
                                allContributionsToDelete.add(contrib);
                            }
                        }
                    }
                }

                if (!allContributionsToDelete.isEmpty()) {
                    try {
                        delete allContributionsToDelete;
                        contributionsDeleted = true;
                    } catch (DmlException e) {
                        contributionsDeleted = false;
                        throw new AuraHandledException(
                            'Failed to delete Group Class Contributions. Please contact your administrator.'
                        );
                    }
                }
            }
            
            List<vlocity_ins__ContractLineItem__c> clisToInsert = new List<vlocity_ins__ContractLineItem__c>();
            List<vlocity_ins__ContractLineItem__c> clisToDelete = new List<vlocity_ins__ContractLineItem__c>();
            
            if (existingContract != null) {
                Map<Id, vlocity_ins__ContractLineItem__c> existingCLIsByProduct = new Map<Id, vlocity_ins__ContractLineItem__c>();
                for (vlocity_ins__ContractLineItem__c cli : existingContract.vlocity_ins__ContractLineItems__r) {
                    existingCLIsByProduct.put(cli.vlocity_ins__Product2Id__c, cli);
                }
                
                for (Id productId : selectedProductIds) {
                    if (!existingCLIsByProduct.containsKey(productId)) {
                        vlocity_ins__ContractLineItem__c newCLI = new vlocity_ins__ContractLineItem__c();
                        
                        for (QuoteLineItem qli : fullQLIMap.values()) {
                            if (qli.Product2Id == productId) {
                                newCLI.Name = qli.Product2.Name;
                                break;
                            }
                        }
                        
                        newCLI.vlocity_ins__Product2Id__c = productId;
                        newCLI.vlocity_ins__ContractId__c = existingContract.Id;
                        clisToInsert.add(newCLI);
                    }
                }
                
                for (Id productId : declinedProductIds) {
                    if (existingCLIsByProduct.containsKey(productId)) {
                        clisToDelete.add(existingCLIsByProduct.get(productId));
                    }
                }
            }
            
            try {
                if (!clisToInsert.isEmpty()) {
                    insert clisToInsert;
                }
                
                if (!clisToDelete.isEmpty()) {
                    delete clisToDelete;
                }
                
                result.put('success', true);
                result.put('hasDeletedContributions', contributionsDeleted);
                
                if (contributionsDeleted) {
                    result.put('message', allContributionsToDelete.size() + 
                              ' Group Class Contributions were removed. If you add new products, ' +
                              'you must add their Group Class Contributions manually.');
                } else {
                    result.put('message', 'Contract Line Items updated successfully.');
                }
                
            } catch (Exception e) {
                throw new AuraHandledException('Error updating contract: ' + e.getMessage());
            }
            
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(
                'You cannot edit products because this Quote is not in Accepted stage.'
            );
        }
        
        return result;
    }

    /*new method to get active contract products for
     badge component on renewal opportunities
    */
    @AuraEnabled(cacheable=true)
    public static List<String> getActiveContractProductIds(Id quoteId) {
        try {
            Quote q = [
                SELECT Id, AccountId
                FROM Quote
                WHERE Id = :quoteId
                LIMIT 1
            ];

            if (q.AccountId == null) return new List<String>();

            List<Contract> activeContracts = [
                SELECT Id,
                    (SELECT Id, vlocity_ins__Product2Id__c
                        FROM vlocity_ins__ContractLineItems__r)
                FROM Contract
                WHERE AccountId = :q.AccountId
                AND Status = 'Activated'
                ORDER BY StartDate DESC
                LIMIT 1
            ];

            if (activeContracts.isEmpty()) return new List<String>();

            List<String> productIds = new List<String>();
            for (vlocity_ins__ContractLineItem__c cli : activeContracts[0].vlocity_ins__ContractLineItems__r) {
                if (cli.vlocity_ins__Product2Id__c != null) {
                    productIds.add(cli.vlocity_ins__Product2Id__c);
                }
            }

            return productIds;

        } catch (Exception e) {
            throw new AuraHandledException('Error fetching active contract products: ' + e.getMessage());
        }
    }
}