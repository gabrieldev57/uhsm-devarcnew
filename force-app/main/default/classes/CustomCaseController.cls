public with sharing class CustomCaseController {
    public Case relatedTo { get; set; }
    public List<ARC_UnderwritingCaseMember__c> caseMembers { get; set; }

    public CustomCaseController() {
        // Retrieve the Case record with the necessary fields
        List<Case> cases = [SELECT Id, Status, ARC_Appealed__c 
                            FROM Case 
                            WHERE Id = :ApexPages.currentPage().getParameters().get('id')
                            LIMIT 1];
        
        if (!cases.isEmpty()) {
            relatedTo = cases[0];
            
            // Initialize the list to store related records
            caseMembers = new List<ARC_UnderwritingCaseMember__c>();
            
            // For new (unappealed) cases select only Pending members
            if (relatedTo.ARC_Appealed__c == null) {
                caseMembers = [SELECT Id, ARC_ApprovalResolution__c 
                               FROM ARC_UnderwritingCaseMember__c 
                               WHERE ARC_UnderwritingCase__c = :relatedTo.Id AND
                                     ARC_ApprovalResolution__c = 'Pending'];
            // For Appealed cases, select Pending and Denied Members
            } else {
                caseMembers = [SELECT Id, ARC_ApprovalResolution__c 
                               FROM ARC_UnderwritingCaseMember__c
                               WHERE ARC_UnderwritingCase__c = :relatedTo.Id AND
                                     ARC_ApprovalResolution__c != 'Approved' AND 
                              		 ARC_ApprovalResolution__c != 'Non-Locate'];
            }
        } else {
            // Handle the case where no Case is found
            relatedTo = new Case();
            caseMembers = new List<ARC_UnderwritingCaseMember__c>();
        }
        
        system.debug('caseMembers=' + caseMembers.size());
    }
}