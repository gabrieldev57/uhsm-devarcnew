public with sharing class aRC_employerPortalMatrixController {

    public class MatrixRowDTO {
        @AuraEnabled public String programName;
        @AuraEnabled public String employeeType;
        @AuraEnabled public String employeeDivision;
        @AuraEnabled public String employeeTier;
        @AuraEnabled public String contributionType;
        @AuraEnabled public Decimal percent;
        @AuraEnabled public Decimal amount;
    }

    public class GroupClassDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String employeeType;
        @AuraEnabled public String employeeDivision;
        @AuraEnabled public Boolean hasContributions;
        @AuraEnabled public List<MatrixRowDTO> rows;
    }

    @AuraEnabled(cacheable=true)
    public static List<GroupClassDTO> getPortalMatrixForCurrentUser() {
        User u = [
            SELECT Id, AccountId, Contact.AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];

        Id accountId = u.AccountId;
        if (accountId == null && u.Contact != null) {
            accountId = u.Contact.AccountId;
        }

        if (accountId == null) {
            return new List<GroupClassDTO>();
        }

        List<vlocity_ins__GroupClass__c> gcs = [
            SELECT Id,
                   Name,
                   vlocity_ins__GroupId__c,
                   ARC_EmployeeType__c,
                   ARC_EmployeeDivision__c,
                   vlocity_ins__IsActive__c,
                   (SELECT Id,
                           Name,
                           ARC_ContractLineItem__c,
                           ARC_ContractLineItem__r.Name,
                           ARC_EmployeeType__c,
                           ARC_EmployeeDivision__c,
                           ARC_EmployeeTier__c,
                           vlocity_ins__ContributionType__c,
                           vlocity_ins__ContributionPercent__c,
                           vlocity_ins__ContributionAmount__c,
                           vlocity_ins__ProductCategory__c
                    FROM vlocity_ins__GroupClassContributions__r)
            FROM vlocity_ins__GroupClass__c
            WHERE vlocity_ins__GroupId__c = :accountId
              AND vlocity_ins__IsActive__c = true
            ORDER BY Name
        ];

        List<GroupClassDTO> result = new List<GroupClassDTO>();

        for (vlocity_ins__GroupClass__c gc : gcs) {
            GroupClassDTO dto = new GroupClassDTO();
            dto.id = gc.Id;
            dto.name = gc.Name;
            dto.employeeType = gc.ARC_EmployeeType__c;
            dto.employeeDivision = gc.ARC_EmployeeDivision__c;
            dto.rows = new List<MatrixRowDTO>();

            if (gc.vlocity_ins__GroupClassContributions__r != null) {
                for (vlocity_ins__GroupClassContribution__c c : gc.vlocity_ins__GroupClassContributions__r) {
                    MatrixRowDTO row = new MatrixRowDTO();
                    row.programName = (c.ARC_ContractLineItem__r != null)
                        ? c.ARC_ContractLineItem__r.Name
                        : null;
                    row.employeeType = c.ARC_EmployeeType__c;
                    row.employeeDivision = c.ARC_EmployeeDivision__c;
                    row.employeeTier = c.ARC_EmployeeTier__c;
                    row.contributionType = c.vlocity_ins__ContributionType__c;
                    row.percent = c.vlocity_ins__ContributionPercent__c;
                    row.amount = c.vlocity_ins__ContributionAmount__c;

                    dto.rows.add(row);
                }
            }

            dto.hasContributions = !dto.rows.isEmpty();
            result.add(dto);
        }

        return result;
    }
}