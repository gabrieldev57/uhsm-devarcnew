public with sharing class ARC_OpenEnrollmentAndProgramsController {

    public class OEInfoDTO {
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date endDate;
        @AuraEnabled public String contractStatus;
        @AuraEnabled public Boolean isActive;
    }

    public class ProgramDTO {
        @AuraEnabled public Id productId;
        @AuraEnabled public String name;
        @AuraEnabled public String code;
        @AuraEnabled public Boolean offered;
        @AuraEnabled public String marketSegment;
    }

    public class OverviewDTO {
        @AuraEnabled public OEInfoDTO oe;
        @AuraEnabled public List<ProgramDTO> programs;
    }

    @AuraEnabled(cacheable=true)
    public static OverviewDTO getOverviewForCurrentUser() {
        OverviewDTO out = new OverviewDTO();
        out.oe = new OEInfoDTO();
        out.programs = new List<ProgramDTO>();

        List<Product2> catalog = [
            SELECT Id, Name, ProductCode, vlocity_ins__MarketSegment__c
            FROM Product2
            WHERE IsActive = true
              AND vlocity_ins__MarketSegment__c = 'Small Group'
            ORDER BY Name
        ];

        Id accountId = resolveAccountIdLikeMatrix();
        Contract chosen = (accountId != null) ? pickContractFlexible(accountId) : null;

        Set<String> offeredCodes = new Set<String>();

        if (chosen != null) {
            out.oe.startDate = chosen.ARC_OEStartDate__c;
            out.oe.endDate   = chosen.ARC_OEEndDate__c;
            out.oe.contractStatus = chosen.Status;

            Date today = Date.today();
            out.oe.isActive =
                (out.oe.startDate != null && out.oe.endDate != null && today >= out.oe.startDate && today <= out.oe.endDate);

            for (vlocity_ins__ContractLineItem__c cli : [
                SELECT vlocity_ins__ProductCode__c
                FROM vlocity_ins__ContractLineItem__c
                WHERE vlocity_ins__ContractId__c = :chosen.Id
                  AND vlocity_ins__ProductCode__c != null
            ]) {
                offeredCodes.add(cli.vlocity_ins__ProductCode__c);
            }
        }

        for (Product2 p : catalog) {
            ProgramDTO dto = new ProgramDTO();
            dto.productId = p.Id;
            dto.name = p.Name;
            dto.code = p.ProductCode;
            dto.marketSegment = p.vlocity_ins__MarketSegment__c;
            dto.offered = (p.ProductCode != null) && offeredCodes.contains(p.ProductCode);
            out.programs.add(dto);
        }

        return out;
    }

    private static Id resolveAccountIdLikeMatrix() {
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
        return accountId;
    }

    private static Contract pickContractFlexible(Id accountId) {
        List<Contract> activeList = [
            SELECT Id, Status, ARC_OEStartDate__c, ARC_OEEndDate__c, LastModifiedDate
            FROM Contract
            WHERE AccountId = :accountId
              AND Status = 'Activated'
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        if (!activeList.isEmpty()) return activeList[0];

        List<Contract> fallback = [
            SELECT Id, Status, ARC_OEStartDate__c, ARC_OEEndDate__c, LastModifiedDate
            FROM Contract
            WHERE AccountId = :accountId
              AND Status IN (
                  'Awaiting Activation',
                  'Awaiting Signature',
                  'Awaiting Approval',
                  'Awaiting First Payment',
                  'Pending Enrollment',
                  'Enrollment In Progress',
                  'Draft',
                  'Created',
                  'Signed'
              )
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
        return fallback.isEmpty() ? null : fallback[0];
    }
}