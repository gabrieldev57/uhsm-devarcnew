public with sharing class aRC_employerContributionController {

    public enum SegMode { NONE, FT_PT, EXEMPT, COMBINED }

    public class GroupClassRow {
        @AuraEnabled public String key { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Integer memberCount { get; set; }
        public GroupClassRow(String k, String l, Integer c) { key = k; label = l; memberCount = c; }
    }

    public class PreviewData {
        @AuraEnabled public Id censusId { get; set; }
        @AuraEnabled public Boolean hasCensus { get; set; }
        @AuraEnabled public Integer totalMembers { get; set; }
        @AuraEnabled public Integer unknownCount { get; set; }
        @AuraEnabled public List<GroupClassRow> rows { get; set; }
        @AuraEnabled public List<String> emptyClassLabels { get; set; }
    }

    public class CreateRequest {
        @AuraEnabled public Id opportunityId { get; set; }
        @AuraEnabled public String segmentationMode { get; set; }
        @AuraEnabled public String includeEmptyChoice { get; set; }
    }

    public class CreateResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Id censusId { get; set; }
        @AuraEnabled public Integer groupClassesCreated { get; set; }
        @AuraEnabled public Integer membersUpdated { get; set; }
    }

    public class ProgramOption {
        @AuraEnabled public Id id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String description { get; set; }

        public ProgramOption(Id id, String name, String description) {
            this.id = id;
            this.name = name;
            this.description = description;
        }
    }

    private static Boolean canManageGroupClasses() {
    return Schema.sObjectType.vlocity_ins__GroupClass__c.isCreateable()
        && Schema.sObjectType.vlocity_ins__GroupClass__c.isUpdateable()
        && Schema.sObjectType.vlocity_ins__GroupClass__c.isDeletable()
        && Schema.sObjectType.vlocity_ins__GroupClassContribution__c.isCreateable()
        && Schema.sObjectType.vlocity_ins__GroupClassContribution__c.isUpdateable()
        && Schema.sObjectType.vlocity_ins__GroupClassContribution__c.isDeletable()
        && Schema.sObjectType.ARC_CensusMemberGroupClass__c.isCreateable()
        && Schema.sObjectType.ARC_CensusMemberGroupClass__c.isDeletable();
    }


    @AuraEnabled(cacheable=true)
    public static PreviewData getGroupClassPreview(Id opportunityId, String segmentationMode) {
        try {
            SegMode mode;
            try { mode = SegMode.valueOf(segmentationMode); }
            catch (Exception e) { throw new AuraHandledException('Invalid segmentationMode: ' + segmentationMode); }

            if (opportunityId == null) {
                PreviewData dto = new PreviewData();
                dto.hasCensus = false;
                dto.rows = buildExpectedRows(mode, new Map<String, Integer>());
                dto.emptyClassLabels = new List<String>();
                dto.totalMembers = 0;
                dto.unknownCount = 0;
                return dto;
            }

            Opportunity opp = [
                SELECT Id, AccountId
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];

            if (opp.AccountId == null) {
                PreviewData dto = new PreviewData();
                dto.hasCensus = false;
                dto.rows = buildExpectedRows(mode, new Map<String, Integer>());
                dto.emptyClassLabels = new List<String>();
                dto.totalMembers = 0;
                dto.unknownCount = 0;
                return dto;
            }

            Id censusId = resolveCensusId(opp.AccountId);

            if (censusId == null) {
                PreviewData dto = new PreviewData();
                dto.hasCensus = false;
                dto.censusId = null;
                dto.rows = buildExpectedRows(mode, new Map<String, Integer>());
                dto.emptyClassLabels = new List<String>();
                dto.totalMembers = 0;
                dto.unknownCount = 0;
                return dto;
            }

            List<AggregateResult> grouped = [
                SELECT ARC_EmployeeType__c empType,
                       ARC_EmployeeDivision__c empDiv,
                       COUNT(Id) cnt
                FROM vlocity_ins__GroupCensusMember__c
                WHERE vlocity_ins__CensusId__c = :censusId
                GROUP BY ARC_EmployeeType__c, ARC_EmployeeDivision__c
            ];

            Map<String, Integer> countsByKey = new Map<String, Integer>();
            Integer total = 0;
            Integer unknown = 0;

            for (AggregateResult ar : grouped) {
                String empType = (String) ar.get('empType');
                String empDiv  = (String) ar.get('empDiv');
                Integer cnt    = (Integer) ar.get('cnt');

                total += cnt;

                String key = classify(mode, empType, empDiv);
                if (key == 'UNKNOWN') {
                    unknown += cnt;
                    continue;
                }
                countsByKey.put(key, (countsByKey.containsKey(key) ? countsByKey.get(key) : 0) + cnt);
            }

            List<GroupClassRow> rows = buildExpectedRows(mode, countsByKey);

            List<String> empties = new List<String>();
            for (GroupClassRow r : rows) if (r.memberCount == 0) empties.add(r.label);

            PreviewData dto = new PreviewData();
            dto.hasCensus = true;
            dto.censusId = censusId;
            dto.totalMembers = total;
            dto.unknownCount = unknown;
            dto.rows = rows;
            dto.emptyClassLabels = empties;
            return dto;

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Error building group class preview: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static CreateResponse createGroupClassesAndAssignMembers(CreateRequest req) {
        if (req == null || req.opportunityId == null) throw new AuraHandledException('Missing opportunityId.');

        if (!canManageGroupClasses()) {
        throw new AuraHandledException('You do not have the required permissions to create Group Classes and Contributions.');
        }

        SegMode mode;
        try { mode = SegMode.valueOf(req.segmentationMode); }
        catch (Exception e) { throw new AuraHandledException('Invalid segmentationMode: ' + req.segmentationMode); }

        Boolean includeEmpty = (req.includeEmptyChoice == 'INCLUDE_EMPTY');

        Opportunity opp = [SELECT Id, AccountId, ContractId FROM Opportunity WHERE Id = :req.opportunityId LIMIT 1];
        if (opp.AccountId == null) throw new AuraHandledException('Opportunity has no AccountId.');

        Id censusId = resolveCensusId(opp.AccountId);
        if (censusId == null) throw new AuraHandledException('No Census was found for this Opportunity/Account.');

        PreviewData preview = getGroupClassPreview(req.opportunityId, req.segmentationMode);
        if (preview == null || preview.hasCensus == false) throw new AuraHandledException('No Census was found for this Opportunity/Account.');

        List<vlocity_ins__GroupClass__c> existingAll = [
            SELECT Id, Name, ARC_EmployeeTypeModel__c, ARC_EmployeeType__c, ARC_EmployeeDivision__c
            FROM vlocity_ins__GroupClass__c
            WHERE vlocity_ins__GroupId__c = :opp.AccountId
              AND ARC_Opportunity__c = :opp.Id
        ];

        if (!existingAll.isEmpty()) {
            if (mode == SegMode.NONE) {
                Id generalId;
                Boolean hasNonGeneral = false;
                for (vlocity_ins__GroupClass__c gc : existingAll) {
                    if (gc.Name == 'General') generalId = gc.Id;
                    else hasNonGeneral = true;
                }
                if (hasNonGeneral) {
                    throw new AuraHandledException('Group Classes already exist for this Opportunity. Use Change Group Classes to reset and recreate.');
                }
                if (generalId != null) {
                    Integer updatedReuse = assignAllMembersToGroupClass(censusId, generalId);
                    CreateResponse respReuse = new CreateResponse();
                    respReuse.success = true;
                    respReuse.censusId = censusId;
                    respReuse.groupClassesCreated = 0;
                    respReuse.membersUpdated = updatedReuse;
                    respReuse.message = 'General Group Class Created';
                    return respReuse;
                }
            } else {
                throw new AuraHandledException('Group Classes already exist for this Opportunity. Use Change Group Classes to reset and recreate.');
            }
        }

        Integer unknown = preview.unknownCount == null ? 0 : preview.unknownCount;
        if (mode != SegMode.NONE && unknown > 0) {
            throw new AuraHandledException(
                'Some employees do not meet the criteria to be assigned to a Group Class. Please review and complete the required employee fields before creating Group Classes'
            );
        }

        List<GroupClassRow> rowsToCreate = new List<GroupClassRow>();
        if (mode == SegMode.NONE) {
            rowsToCreate.add(new GroupClassRow('GENERAL', 'General', 0));
        } else {
            List<GroupClassRow> rows = preview.rows == null ? new List<GroupClassRow>() : preview.rows;
            for (GroupClassRow r : rows) {
                Integer c = r.memberCount == null ? 0 : r.memberCount;
                if (includeEmpty || c > 0) rowsToCreate.add(r);
            }
        }

        if (rowsToCreate.isEmpty()) throw new AuraHandledException('No Group Classes to create.');

        List<vlocity_ins__GroupClass__c> toInsert = new List<vlocity_ins__GroupClass__c>();
        for (GroupClassRow r : rowsToCreate) {
            GroupClassSpec spec = specForRowKey(mode, r.key);
            vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c();
            gc.Name = spec.label;
            gc.vlocity_ins__GroupId__c = opp.AccountId;
            gc.ARC_Opportunity__c = opp.Id;
            gc.ARC_EmployeeTypeModel__c = spec.model;
            gc.ARC_EmployeeType__c = spec.empType;
            gc.ARC_EmployeeDivision__c = spec.empDiv;
            gc.ARC_ApplyEmployeeTier__c = false;
            gc.ARC_ApplyProgramBased__c = false;
            gc.vlocity_ins__IsActive__c = true;
            gc.ARC_Contract__c = opp.ContractId;
            toInsert.add(gc);
        }

        Database.SaveResult[] ins = Database.insert(toInsert, false);
        List<String> errs = new List<String>();
        List<Id> createdIds = new List<Id>();
        for (Database.SaveResult r : ins) {
            if (r.isSuccess()) createdIds.add(r.getId());
            else for (Database.Error de : r.getErrors()) errs.add(de.getMessage());
        }
        if (!errs.isEmpty()) throw new AuraHandledException('Failed to create some Group Classes: ' + String.join(errs, ' | '));

        List<vlocity_ins__GroupClass__c> created = [
            SELECT Id, Name, ARC_EmployeeTypeModel__c, ARC_EmployeeType__c, ARC_EmployeeDivision__c
            FROM vlocity_ins__GroupClass__c
            WHERE Id IN :createdIds
        ];

        Map<String, Id> keyToGcId = new Map<String, Id>();
        Map<Id, String> gcIdToName = new Map<Id, String>();
        for (vlocity_ins__GroupClass__c gc : created) {
            String k = gcKey(gc.ARC_EmployeeTypeModel__c, gc.ARC_EmployeeType__c, gc.ARC_EmployeeDivision__c);
            if (!keyToGcId.containsKey(k)) keyToGcId.put(k, gc.Id);
            gcIdToName.put(gc.Id, gc.Name);
        }

        List<vlocity_ins__GroupCensusMember__c> members = [
            SELECT Id, Name, ARC_EmployeeType__c, ARC_EmployeeDivision__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__CensusId__c = :censusId
        ];

        List<ARC_CensusMemberGroupClass__c> junctionsToInsert = new List<ARC_CensusMemberGroupClass__c>();

        for (vlocity_ins__GroupCensusMember__c m : members) {
            Id targetGcId = resolveTargetGroupClassId(mode, m.ARC_EmployeeType__c, m.ARC_EmployeeDivision__c, keyToGcId);
            if (targetGcId == null) {
                throw new AuraHandledException(
                    'Some employees do not meet the criteria to be assigned to a Group Class. Please review and complete the required employee fields before creating Group Classes'
                );
            }
            String gcName = gcIdToName.get(targetGcId) ?? '';
            junctionsToInsert.add(new ARC_CensusMemberGroupClass__c(
                Name = m.Name + ' - ' + gcName,
                ARC_CensusMember__c = m.Id,
                ARC_GroupClass__c = targetGcId
            ));
        }

        Integer updated = 0;
        if (!junctionsToInsert.isEmpty()) {
            Database.SaveResult[] ins2 = Database.insert(junctionsToInsert, false);
            List<String> uerrs = new List<String>();
            for (Database.SaveResult r : ins2) {
                if (r.isSuccess()) updated++;
                else for (Database.Error de : r.getErrors()) uerrs.add(de.getMessage());
            }
            if (!uerrs.isEmpty()) throw new AuraHandledException('Failed to assign some Census Members: ' + String.join(uerrs, ' | '));
        }

        CreateResponse resp = new CreateResponse();
        resp.success = true;
        resp.censusId = censusId;
        resp.groupClassesCreated = createdIds.size();
        resp.membersUpdated = updated;
        resp.message = 'Group Classes created and Census Members assigned.';
        return resp;
    }

    private static Integer assignAllMembersToGroupClass(Id censusId, Id groupClassId) {
        List<vlocity_ins__GroupCensusMember__c> ms = [
            SELECT Id, Name
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__CensusId__c = :censusId
        ];
        if (ms.isEmpty()) return 0;

        Set<Id> memberIds = new Map<Id, vlocity_ins__GroupCensusMember__c>(ms).keySet();

        List<ARC_CensusMemberGroupClass__c> existing = [
            SELECT Id
            FROM ARC_CensusMemberGroupClass__c
            WHERE ARC_CensusMember__c IN :memberIds
        ];
        if (!existing.isEmpty()) delete existing;

        vlocity_ins__GroupClass__c gcRecord = [SELECT Name FROM vlocity_ins__GroupClass__c WHERE Id = :groupClassId LIMIT 1];
        String gcName = gcRecord.Name ?? '';

        List<ARC_CensusMemberGroupClass__c> junctions = new List<ARC_CensusMemberGroupClass__c>();
        for (vlocity_ins__GroupCensusMember__c m : ms) {
            junctions.add(new ARC_CensusMemberGroupClass__c(
                Name = m.Name + ' - ' + gcName,
                ARC_CensusMember__c = m.Id,
                ARC_GroupClass__c = groupClassId
            ));
        }

        Database.SaveResult[] ins = Database.insert(junctions, false);
        Integer inserted = 0;
        List<String> errs = new List<String>();
        for (Database.SaveResult r : ins) {
            if (r.isSuccess()) inserted++;
            else for (Database.Error de : r.getErrors()) errs.add(de.getMessage());
        }
        if (!errs.isEmpty()) throw new AuraHandledException('Failed to assign Census Members: ' + String.join(errs, ' | '));
        return inserted;
    }

    private class GroupClassSpec {
        String label;
        String model;
        String empType;
        String empDiv;
        GroupClassSpec(String l, String m, String t, String d) { label=l; model=m; empType=t; empDiv=d; }
    }

    // Example: "Non-Exempt" / "Non Exempt" / "non exempt" -> "nonexempt"
    private static String norm(String s) {
        if (String.isBlank(s)) return '';
        return s.trim().toLowerCase().replace('-', '').replace(' ', '');
    }

    private static GroupClassSpec specForRowKey(SegMode mode, String rowKey) {
        if (rowKey == 'GENERAL') {
            return new GroupClassSpec('General', 'None', 'None', 'None');
        }
        if (mode == SegMode.FT_PT) {
            if (rowKey == 'FULL_TIME') return new GroupClassSpec('Full Time', 'FullTime_PartTime', 'Full Time', 'None');
            return new GroupClassSpec('Part Time', 'FullTime_PartTime', 'Part Time', 'None');
        }
        if (mode == SegMode.EXEMPT) {
            if (rowKey == 'EXEMPT') return new GroupClassSpec('Exempt', 'Exempt_NonExempt', 'None', 'Exempt');
            return new GroupClassSpec('Non-Exempt', 'Exempt_NonExempt', 'None', 'Non-Exempt');
        }

        if (rowKey == 'FULL_TIME__EXEMPT') return new GroupClassSpec('Full Time – Exempt', 'FullTime_PartTime', 'Full Time', 'Exempt');
        if (rowKey == 'FULL_TIME__NON_EXEMPT') return new GroupClassSpec('Full Time – Non-Exempt', 'FullTime_PartTime', 'Full Time', 'Non-Exempt');
        if (rowKey == 'PART_TIME__EXEMPT') return new GroupClassSpec('Part Time – Exempt', 'FullTime_PartTime', 'Part Time', 'Exempt');
        return new GroupClassSpec('Part Time – Non-Exempt', 'FullTime_PartTime', 'Part Time', 'Non-Exempt');
    }

    private static String gcKey(String model, String empType, String empDiv) {
        return String.valueOf(model) + '|' + String.valueOf(empType) + '|' + String.valueOf(empDiv);
    }

    private static Id resolveTargetGroupClassId(SegMode mode, String empType, String empDiv, Map<String, Id> keyToGcId) {
        if (mode == SegMode.NONE) {
            return keyToGcId.get(gcKey('None', 'None', 'None'));
        }

        String t = norm(empType);
        String d = norm(empDiv);

        if (mode == SegMode.FT_PT) {
            if (t == 'fulltime') return keyToGcId.get(gcKey('FullTime_PartTime', 'Full Time', 'None'));
            if (t == 'parttime') return keyToGcId.get(gcKey('FullTime_PartTime', 'Part Time', 'None'));
            return null;
        }

        if (mode == SegMode.EXEMPT) {
            if (d == 'exempt') return keyToGcId.get(gcKey('Exempt_NonExempt', 'None', 'Exempt'));
            if (d == 'nonexempt') return keyToGcId.get(gcKey('Exempt_NonExempt', 'None', 'Non-Exempt'));
            return null;
        }

        if (t == 'fulltime' && d == 'exempt') return keyToGcId.get(gcKey('FullTime_PartTime', 'Full Time', 'Exempt'));
        if (t == 'fulltime' && d == 'nonexempt') return keyToGcId.get(gcKey('FullTime_PartTime', 'Full Time', 'Non-Exempt'));
        if (t == 'parttime' && d == 'exempt') return keyToGcId.get(gcKey('FullTime_PartTime', 'Part Time', 'Exempt'));
        if (t == 'parttime' && d == 'nonexempt') return keyToGcId.get(gcKey('FullTime_PartTime', 'Part Time', 'Non-Exempt'));

        return null;
    }

    private static List<GroupClassRow> buildExpectedRows(SegMode mode, Map<String,Integer> counts) {
        List<GroupClassRow> out = new List<GroupClassRow>();
        if (mode == SegMode.NONE) {
            out.add(new GroupClassRow('GENERAL', 'General', n(counts, 'GENERAL')));
            return out;
        }
        if (mode == SegMode.FT_PT) {
            out.add(new GroupClassRow('FULL_TIME', 'Full Time', n(counts, 'FULL_TIME')));
            out.add(new GroupClassRow('PART_TIME', 'Part Time', n(counts, 'PART_TIME')));
            return out;
        }
        if (mode == SegMode.EXEMPT) {
            out.add(new GroupClassRow('EXEMPT', 'Exempt', n(counts, 'EXEMPT')));
            out.add(new GroupClassRow('NON_EXEMPT', 'Non-Exempt', n(counts, 'NON_EXEMPT')));
            return out;
        }
        out.add(new GroupClassRow('FULL_TIME__EXEMPT', 'Full Time – Exempt', n(counts, 'FULL_TIME__EXEMPT')));
        out.add(new GroupClassRow('FULL_TIME__NON_EXEMPT', 'Full Time – Non-Exempt', n(counts, 'FULL_TIME__NON_EXEMPT')));
        out.add(new GroupClassRow('PART_TIME__EXEMPT', 'Part Time – Exempt', n(counts, 'PART_TIME__EXEMPT')));
        out.add(new GroupClassRow('PART_TIME__NON_EXEMPT', 'Part Time – Non-Exempt', n(counts, 'PART_TIME__NON_EXEMPT')));
        return out;
    }

    private static Integer n(Map<String,Integer> counts, String k) {
        return (counts != null && counts.containsKey(k)) ? counts.get(k) : 0;
    }

    private static String classify(SegMode mode, String empType, String empDiv) {
        if (mode == SegMode.NONE) return 'GENERAL';

        String t = norm(empType);
        String d = norm(empDiv);

        String typeKey =
            (t == 'fulltime') ? 'FULL_TIME' :
            (t == 'parttime') ? 'PART_TIME' :
            'UNKNOWN';

        String divKey =
            (d == 'exempt') ? 'EXEMPT' :
            (d == 'nonexempt') ? 'NON_EXEMPT' :
            'UNKNOWN';

        if (mode == SegMode.FT_PT) return typeKey;
        if (mode == SegMode.EXEMPT) return divKey;

        if (typeKey == 'UNKNOWN' || divKey == 'UNKNOWN') return 'UNKNOWN';
        return typeKey + '__' + divKey;
    }

    private static Id resolveCensusId(Id accountId) {
        Account acc = [SELECT Id, ARC_Census__c FROM Account WHERE Id = :accountId LIMIT 1];
        if (acc.ARC_Census__c != null) return acc.ARC_Census__c;

        List<vlocity_ins__GroupCensus__c> censuses = [
            SELECT Id
            FROM vlocity_ins__GroupCensus__c
            WHERE arc_primaryaccount__c = :accountId
               OR arc_guardianaccount__c = :accountId
               OR vlocity_ins__groupid__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return censuses.isEmpty() ? null : censuses[0].Id;
    }

    @AuraEnabled
    public static void resetGroupClasses(Id opportunityId) {
    if (opportunityId == null) {
        throw new AuraHandledException('Missing opportunityId.');
    }

    List<vlocity_ins__GroupClass__c> gcsToDelete = [
        SELECT Id
        FROM vlocity_ins__GroupClass__c
        WHERE ARC_Opportunity__c = :opportunityId
    ];

    if (!gcsToDelete.isEmpty()) {
        Set<Id> gcIds = new Map<Id, vlocity_ins__GroupClass__c>(gcsToDelete).keySet();
        List<ARC_CensusMemberGroupClass__c> junctionsToDelete = [
            SELECT Id
            FROM ARC_CensusMemberGroupClass__c
            WHERE ARC_GroupClass__c IN :gcIds
        ];
        if (!junctionsToDelete.isEmpty()) delete junctionsToDelete;
        delete gcsToDelete;
    }

    update new Opportunity(
        Id = opportunityId,
        ARC_GroupClassesContributionsDefined__c = false
    );
    }


    @AuraEnabled
    public static void initRenewalGroupClasses(Id opportunityId) {
        if (opportunityId == null) return;

        Opportunity opp = [
            SELECT Id, AccountId, ContractId, RecordType.DeveloperName
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        Boolean isRenewal = opp.RecordType != null && opp.RecordType.DeveloperName == 'ARC_Renewal';
        if (!isRenewal || opp.ContractId == null) return;

        // Check if GCs already exist on this opportunity
        Integer existingCount = [
            SELECT COUNT()
            FROM vlocity_ins__GroupClass__c
            WHERE ARC_Opportunity__c = :opportunityId
        ];
        if (existingCount > 0) return;

        // Find prior active contract
        List<Contract> activeContracts = [
            SELECT Id
            FROM Contract
            WHERE AccountId = :opp.AccountId
              AND Status = 'Activated'
              AND Id != :opp.ContractId
            ORDER BY StartDate DESC NULLS LAST
            LIMIT 1
        ];
        if (activeContracts.isEmpty()) return;

        Id activeContractId = activeContracts[0].Id;

        List<vlocity_ins__GroupClass__c> priorGcs = [
            SELECT Name, ARC_EmployeeTypeModel__c, ARC_EmployeeType__c, ARC_EmployeeDivision__c
            FROM vlocity_ins__GroupClass__c
            WHERE ARC_Contract__c = :activeContractId
        ];
        if (priorGcs.isEmpty()) return;

        List<vlocity_ins__GroupClass__c> toInsert = new List<vlocity_ins__GroupClass__c>();
        for (vlocity_ins__GroupClass__c pgc : priorGcs) {
            toInsert.add(new vlocity_ins__GroupClass__c(
                Name = pgc.Name,
                ARC_EmployeeTypeModel__c = pgc.ARC_EmployeeTypeModel__c,
                ARC_EmployeeType__c = pgc.ARC_EmployeeType__c,
                ARC_EmployeeDivision__c = pgc.ARC_EmployeeDivision__c,
                ARC_Opportunity__c = opportunityId,
                ARC_Contract__c = opp.ContractId,
                vlocity_ins__GroupId__c = opp.AccountId,
                vlocity_ins__IsActive__c = true
            ));
        }
        insert toInsert;
    }

   @AuraEnabled(cacheable=true)
    public static Map<String,Object> getGroupClassFromOpportunity(Id opportunityId) {
        Map<String,Object> result = new Map<String,Object>();
        List<Map<String,Object>> groupClassesList = new List<Map<String,Object>>();

        result.put('opportunityId', opportunityId);
        result.put('groupClasses', groupClassesList);

        if (opportunityId == null) return result;

        Opportunity opp = [
            SELECT Id, AccountId, ContractId, RecordType.DeveloperName
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        if (opp.AccountId == null) return result;

        List<Contract> contracts = new List<Contract>();
        if (opp.ContractId != null) {
            contracts = [
                SELECT Id, Status, CreatedDate
                FROM Contract
                WHERE Id = :opp.ContractId
                LIMIT 1
            ];
        }

        if (contracts.isEmpty()) return result;

        Contract currentContract = contracts[0];

        // Determine CLI comparison result for renewal pre-population (only for ARC_Renewal opps)
        String cliComparisonResult = 'FIRST_TIME';
        Boolean isRenewal = opp.RecordType != null && opp.RecordType.DeveloperName == 'ARC_Renewal';

        // Prior GCs from the active contract — used for both structure cloning and MATCH pre-population
        List<vlocity_ins__GroupClass__c> priorGcsForClone = new List<vlocity_ins__GroupClass__c>();
        // Map: gcKey -> prior settings+contributions — only populated for MATCH
        Map<String, Map<String,Object>> priorGcByKey = new Map<String, Map<String,Object>>();

        if (isRenewal) {
            List<Contract> activeContracts = [
                SELECT Id
                FROM Contract
                WHERE AccountId = :opp.AccountId
                  AND Status = 'Activated'
                  AND Id != :currentContract.Id
                ORDER BY StartDate DESC NULLS LAST
                LIMIT 1
            ];
            if (!activeContracts.isEmpty()) {
                Id activeContractId = activeContracts[0].Id;
                Set<Id> activeProductIds = new Set<Id>();
                for (vlocity_ins__ContractLineItem__c c : [
                    SELECT vlocity_ins__Product2Id__c
                    FROM vlocity_ins__ContractLineItem__c
                    WHERE vlocity_ins__ContractId__c = :activeContractId
                      AND vlocity_ins__Product2Id__c != null
                ]) {
                    activeProductIds.add(c.vlocity_ins__Product2Id__c);
                }
                Set<Id> currentProductIds = new Set<Id>();
                for (vlocity_ins__ContractLineItem__c c : [
                    SELECT vlocity_ins__Product2Id__c
                    FROM vlocity_ins__ContractLineItem__c
                    WHERE vlocity_ins__ContractId__c = :currentContract.Id
                      AND vlocity_ins__Product2Id__c != null
                ]) {
                    currentProductIds.add(c.vlocity_ins__Product2Id__c);
                }
                cliComparisonResult = activeProductIds.equals(currentProductIds) ? 'MATCH' : 'MISMATCH';

                // Always query prior GCs: used to clone structure + for MATCH contribution pre-population
                priorGcsForClone = [
                    SELECT Id, Name,
                        ARC_EmployeeTypeModel__c,
                        ARC_EmployeeType__c,
                        ARC_EmployeeDivision__c,
                        ARC_ContributionMethod__c,
                        ARC_ApplyProgramBased__c,
                        ARC_ApplyEmployeeTier__c,
                        (SELECT ARC_EmployeeType__c,
                                ARC_EmployeeDivision__c,
                                ARC_EmployeeTier__c,
                                vlocity_ins__ContributionType__c,
                                vlocity_ins__ContributionPercent__c,
                                vlocity_ins__ContributionAmount__c,
                                vlocity_ins__ProductCategory__c,
                                ARC_ContractLineItem__r.vlocity_ins__Product2Id__c
                         FROM vlocity_ins__GroupClassContributions__r)
                    FROM vlocity_ins__GroupClass__c
                    WHERE ARC_Contract__c = :activeContractId
                ];

                // For MATCH: build priorGcByKey for contribution pre-population
                if (cliComparisonResult == 'MATCH') {
                    for (vlocity_ins__GroupClass__c pgc : priorGcsForClone) {
                        String key = gcKey(pgc.ARC_EmployeeTypeModel__c, pgc.ARC_EmployeeType__c, pgc.ARC_EmployeeDivision__c);
                        Map<String,Object> priorSettings = new Map<String,Object>();
                        priorSettings.put('contributionMethod', pgc.ARC_ContributionMethod__c);
                        priorSettings.put('applyProgramBased', pgc.ARC_ApplyProgramBased__c);
                        priorSettings.put('applyEmployeeTier', pgc.ARC_ApplyEmployeeTier__c);

                        // Build map productId -> list of contribution rows (no Id so save creates new)
                        Map<Id, List<Map<String,Object>>> priorContribsByProductId = new Map<Id, List<Map<String,Object>>>();
                        if (pgc.vlocity_ins__GroupClassContributions__r != null) {
                            for (vlocity_ins__GroupClassContribution__c pc : pgc.vlocity_ins__GroupClassContributions__r) {
                                Id prodId = pc.ARC_ContractLineItem__r != null
                                    ? pc.ARC_ContractLineItem__r.vlocity_ins__Product2Id__c
                                    : null;
                                if (prodId == null) continue;
                                Map<String,Object> cRow = new Map<String,Object>();
                                // Intentionally no 'id' field so save always inserts new records
                                cRow.put('ARC_EmployeeType__c', pc.ARC_EmployeeType__c);
                                cRow.put('ARC_EmployeeDivision__c', pc.ARC_EmployeeDivision__c);
                                cRow.put('ARC_EmployeeTier__c', pc.ARC_EmployeeTier__c);
                                cRow.put('vlocity_ins__ContributionType__c', pc.vlocity_ins__ContributionType__c);
                                cRow.put('vlocity_ins__ContributionPercent__c', pc.vlocity_ins__ContributionPercent__c);
                                cRow.put('vlocity_ins__ContributionAmount__c', pc.vlocity_ins__ContributionAmount__c);
                                cRow.put('vlocity_ins__ProductCategory__c', pc.vlocity_ins__ProductCategory__c);
                                if (!priorContribsByProductId.containsKey(prodId)) {
                                    priorContribsByProductId.put(prodId, new List<Map<String,Object>>());
                                }
                                priorContribsByProductId.get(prodId).add(cRow);
                            }
                        }
                        priorSettings.put('priorContribsByProductId', priorContribsByProductId);
                        priorGcByKey.put(key, priorSettings);
                    }
                }
            }
        }
        result.put('cliComparisonResult', cliComparisonResult);

        List<vlocity_ins__ContractLineItem__c> clis = [
            SELECT Id,
                Name,
                vlocity_ins__Product2Id__c,
                vlocity_ins__Product2Id__r.Description,
                vlocity_ins__ProductType__c
            FROM vlocity_ins__ContractLineItem__c
            WHERE vlocity_ins__ContractId__c = :currentContract.Id
            ORDER BY CreatedDate DESC
        ];

        List<vlocity_ins__GroupClass__c> gcs = [
            SELECT Id, Name,
                ARC_EmployeeTypeModel__c,
                ARC_EmployeeType__c,
                ARC_EmployeeDivision__c,
                ARC_ApplyProgramBased__c,
                ARC_ApplyEmployeeTier__c,
                ARC_ContributionMethod__c,
                    (SELECT Id,
                        Name,
                        ARC_ContractLineItem__c,
                        ARC_ContractLineItem__r.vlocity_ins__ProductType__c,
                        ARC_EmployeeType__c,
                        ARC_EmployeeDivision__c,
                        ARC_EmployeeTier__c,
                        vlocity_ins__ContributionType__c,
                        vlocity_ins__ContributionPercent__c,
                        vlocity_ins__ContributionAmount__c,
                        vlocity_ins__ProductCategory__c
                    FROM vlocity_ins__GroupClassContributions__r)
            FROM vlocity_ins__GroupClass__c
            WHERE ARC_Opportunity__c = :opportunityId
            ORDER BY Name
        ];

        for (vlocity_ins__GroupClass__c gc : gcs) {
            Map<String,Object> gcMap = new Map<String,Object>();
            gcMap.put('Id', gc.Id);
            gcMap.put('Name', gc.Name);

            gcMap.put('ARC_EmployeeTypeModel__c', gc.ARC_EmployeeTypeModel__c);
            gcMap.put('ARC_EmployeeType__c', gc.ARC_EmployeeType__c);
            gcMap.put('ARC_EmployeeDivision__c', gc.ARC_EmployeeDivision__c);
            gcMap.put('ARC_ApplyProgramBased__c', gc.ARC_ApplyProgramBased__c);
            gcMap.put('ARC_ApplyEmployeeTier__c', gc.ARC_ApplyEmployeeTier__c);
            gcMap.put('ARC_ContributionMethod__c', gc.ARC_ContributionMethod__c);

            Map<Id, List<Map<String,Object>>> cliToContribs = new Map<Id, List<Map<String,Object>>>();
            Boolean gcHasContributions = false;

            if (gc.vlocity_ins__GroupClassContributions__r != null && !gc.vlocity_ins__GroupClassContributions__r.isEmpty()) {
                gcHasContributions = true;

                for (vlocity_ins__GroupClassContribution__c c : gc.vlocity_ins__GroupClassContributions__r) {
                    if (c.ARC_ContractLineItem__c == null) continue;

                    Map<String,Object> cMap = new Map<String,Object>();
                    cMap.put('id', c.Id);
                    cMap.put('Name', c.Name);

                    cMap.put('ARC_ContractLineItem__c', c.ARC_ContractLineItem__c);
                    cMap.put('ARC_EmployeeType__c', c.ARC_EmployeeType__c);
                    cMap.put('ARC_EmployeeDivision__c', c.ARC_EmployeeDivision__c);
                    cMap.put('ARC_EmployeeTier__c', c.ARC_EmployeeTier__c);

                    cMap.put('vlocity_ins__ContributionType__c', c.vlocity_ins__ContributionType__c);
                    cMap.put('vlocity_ins__ContributionPercent__c', c.vlocity_ins__ContributionPercent__c);
                    cMap.put('vlocity_ins__ContributionAmount__c', c.vlocity_ins__ContributionAmount__c);

                    String prodCategory = (String) c.vlocity_ins__ProductCategory__c;
                    if (prodCategory == null && c.ARC_ContractLineItem__r != null) {
                        prodCategory = (String) c.ARC_ContractLineItem__r.vlocity_ins__ProductType__c;
                    }
                    cMap.put('vlocity_ins__ProductCategory__c', prodCategory);

                    if (!cliToContribs.containsKey(c.ARC_ContractLineItem__c)) {
                        cliToContribs.put(c.ARC_ContractLineItem__c, new List<Map<String,Object>>());
                    }
                    cliToContribs.get(c.ARC_ContractLineItem__c).add(cMap);
                }
            }

            gcMap.put('hasContributions', gcHasContributions);

            // Inject prior GC settings for MATCH renewal pre-population
            if (cliComparisonResult == 'MATCH' && !gcHasContributions) {
                String currentGcKey = gcKey(gc.ARC_EmployeeTypeModel__c, gc.ARC_EmployeeType__c, gc.ARC_EmployeeDivision__c);
                if (priorGcByKey.containsKey(currentGcKey)) {
                    Map<String,Object> priorSettings = priorGcByKey.get(currentGcKey);
                    gcMap.put('priorSettings', new Map<String,Object>{
                        'contributionMethod' => priorSettings.get('contributionMethod'),
                        'applyProgramBased' => priorSettings.get('applyProgramBased'),
                        'applyEmployeeTier' => priorSettings.get('applyEmployeeTier')
                    });
                    gcMap.put('priorContribsByProductId', priorSettings.get('priorContribsByProductId'));
                }
            }

            List<Map<String,Object>> programs = new List<Map<String,Object>>();

            for (vlocity_ins__ContractLineItem__c cli : clis) {
                String description = '';
                if (cli.vlocity_ins__Product2Id__r != null && cli.vlocity_ins__Product2Id__r.Description != null) {
                    description = cli.vlocity_ins__Product2Id__r.Description;
                }

                List<Map<String,Object>> contribs = cliToContribs.containsKey(cli.Id)
                    ? cliToContribs.get(cli.Id)
                    : new List<Map<String,Object>>();

                Boolean hasCliContribs = !contribs.isEmpty();

                Map<String,Object> pMap = new Map<String,Object>();
                pMap.put('productName', cli.Name);
                pMap.put('contractLineItemId', cli.Id);
                pMap.put('productId', cli.vlocity_ins__Product2Id__c);
                pMap.put('vlocity_ins__ProductType__c', cli.vlocity_ins__ProductType__c);
                pMap.put('description', description);
                pMap.put('hasContributions', hasCliContribs);
                pMap.put('contributions', contribs);

                programs.add(pMap);
            }

            gcMap.put('programs', programs);
            groupClassesList.add(gcMap);
        }

        System.debug('getGroupClassFromOpportunity payload: ' + JSON.serializePretty(result));
        return result;
    }


    @AuraEnabled
    public static Map<String,Object> saveGroupClassConfiguration(String payloadJson) {
        Map<String,Object> payload = (Map<String,Object>) JSON.deserializeUntyped(payloadJson);
        Map<String,Object> response = new Map<String,Object>();

        try {
            Id opportunityId = (Id) payload.get('opportunityId');
            if (opportunityId == null) {
                throw new AuraHandledException('Missing opportunityId in payload.');
            }

            List<Object> groupClassesList = (List<Object>) payload.get('groupClasses');

            if (groupClassesList == null) {
                Map<String,Object> singleGc = new Map<String,Object>();

                if (payload.containsKey('groupClassId')) singleGc.put('Id', payload.get('groupClassId'));
                if (payload.containsKey('groupClassName')) singleGc.put('Name', payload.get('groupClassName'));

                if (payload.containsKey('ARC_EmployeeTypeModel__c')) singleGc.put('ARC_EmployeeTypeModel__c', payload.get('ARC_EmployeeTypeModel__c'));
                if (payload.containsKey('employeeTypeModel')) singleGc.put('ARC_EmployeeTypeModel__c', payload.get('employeeTypeModel'));

                if (payload.containsKey('ARC_EmployeeType__c')) singleGc.put('ARC_EmployeeType__c', payload.get('ARC_EmployeeType__c'));
                if (payload.containsKey('ARC_EmployeeDivision__c')) singleGc.put('ARC_EmployeeDivision__c', payload.get('ARC_EmployeeDivision__c'));

                if (payload.containsKey('ARC_ApplyProgramBased__c')) singleGc.put('ARC_ApplyProgramBased__c', payload.get('ARC_ApplyProgramBased__c'));
                if (payload.containsKey('applyProgramBased')) singleGc.put('ARC_ApplyProgramBased__c', payload.get('applyProgramBased'));

                if (payload.containsKey('ARC_ApplyEmployeeTier__c')) singleGc.put('ARC_ApplyEmployeeTier__c', payload.get('ARC_ApplyEmployeeTier__c'));
                if (payload.containsKey('applyEmployeeTier')) singleGc.put('ARC_ApplyEmployeeTier__c', payload.get('applyEmployeeTier'));

                if (payload.containsKey('ARC_ContributionMethod__c')) singleGc.put('ARC_ContributionMethod__c', payload.get('ARC_ContributionMethod__c'));
                if (payload.containsKey('contributionMethod')) singleGc.put('ARC_ContributionMethod__c', payload.get('contributionMethod'));

                if (payload.containsKey('programs')) {
                    singleGc.put('programs', payload.get('programs'));
                } else if (payload.containsKey('selectedPrograms')) {
                    singleGc.put('programs', payload.get('selectedPrograms'));
                } else {
                    singleGc.put('programs', new List<Object>());
                }

                groupClassesList = new List<Object>{ singleGc };
            }

            if (groupClassesList == null) {
                throw new AuraHandledException('Missing groupClasses in payload.');
            }

            Opportunity opp = [
                SELECT Id, AccountId, ContractId
                FROM Opportunity
                WHERE Id = :opportunityId
                LIMIT 1
            ];
            if (opp.AccountId == null) {
                throw new AuraHandledException('Opportunity has no AccountId.');
            }

            List<Contract> contracts = new List<Contract>();
            if (opp.ContractId != null) {
                contracts = [
                    SELECT Id, Status, CreatedDate
                    FROM Contract
                    WHERE Id = :opp.ContractId
                    LIMIT 1
                ];
            }
            if (contracts.isEmpty()) {
                throw new AuraHandledException('No Draft Contract found for this Opportunity/Account.');
            }
            Contract currentContract = contracts[0];

            
            List<vlocity_ins__ContractLineItem__c> clisToUpsert = new List<vlocity_ins__ContractLineItem__c>();
            Map<String, Id> tempKeyToCliId = new Map<String, Id>();

            for (Object gcObj : groupClassesList) {
                Map<String,Object> gcMap = (Map<String,Object>) gcObj;
                List<Object> programsList = (List<Object>) gcMap.get('programs');
                if (programsList != null) {
                    for (Object progObj : programsList) {
                        Map<String,Object> progMap = (Map<String,Object>) progObj;
                        Id cliId = (Id) progMap.get('contractLineItemId');

                        String productName = (String) progMap.get('productName');
                        if (tempKeyToCliId.containsKey(productName)) continue;

                        vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();

                        if (cliId != null) {
                            cli.Id = cliId;
                        } else {
                            cli.vlocity_ins__ContractId__c = currentContract.Id;
                        }

                        cli.Name = productName;
                        cli.vlocity_ins__Product2Id__c = (Id) progMap.get('productId');

                        clisToUpsert.add(cli);
                        if (cliId != null) {
                            tempKeyToCliId.put(productName, cliId);
                        }
                    }
                }
            }

            // Upsert CLIs
            if (!clisToUpsert.isEmpty()) {
                upsert clisToUpsert;
            }

            // Map product names to CLI IDs (including newly created)
            for (vlocity_ins__ContractLineItem__c cli : clisToUpsert) {
                tempKeyToCliId.put(cli.Name, cli.Id);
            }

            // Collect all CLI Ids from upserted list to determine which to keep
            Set<Id> cliIdsInPayload = new Set<Id>();
            for (vlocity_ins__ContractLineItem__c cli : clisToUpsert) {
                cliIdsInPayload.add(cli.Id);
            }

            // Delete CLIs not in payload (contributions auto-cascade delete)
            List<vlocity_ins__ContractLineItem__c> clisToDelete = [
                SELECT Id
                FROM vlocity_ins__ContractLineItem__c
                WHERE vlocity_ins__ContractId__c = :currentContract.Id
                AND Id NOT IN :cliIdsInPayload
            ];
            if (!clisToDelete.isEmpty()) {
                delete clisToDelete;
            }

            // process each Group Class
            List<vlocity_ins__GroupClass__c> gcsToUpsert = new List<vlocity_ins__GroupClass__c>();
            Map<Id, Map<String,Object>> gcIdToPayloadMap = new Map<Id, Map<String,Object>>();

            for (Object gcObj : groupClassesList) {
                Map<String,Object> gcMap = (Map<String,Object>) gcObj;

                vlocity_ins__GroupClass__c gc = new vlocity_ins__GroupClass__c();

                Id gcId = (Id) gcMap.get('Id');
                if (gcId != null) {
                    gc.Id = gcId;
                }

                gc.Name = (String) gcMap.get('Name');
                gc.ARC_EmployeeTypeModel__c = (String) gcMap.get('ARC_EmployeeTypeModel__c');
                gc.ARC_EmployeeType__c = (String) gcMap.get('ARC_EmployeeType__c');
                gc.ARC_EmployeeDivision__c = (String) gcMap.get('ARC_EmployeeDivision__c');
                gc.ARC_ApplyProgramBased__c = (Boolean) gcMap.get('ARC_ApplyProgramBased__c');
                gc.ARC_ApplyEmployeeTier__c = (Boolean) gcMap.get('ARC_ApplyEmployeeTier__c');
                gc.ARC_ContributionMethod__c = (String) gcMap.get('ARC_ContributionMethod__c');
                gc.ARC_Contract__c = currentContract.Id;


                gcsToUpsert.add(gc);
                if (gcId != null) {
                    gcIdToPayloadMap.put(gcId, gcMap);
                }
            }

            update gcsToUpsert;

            // Rebuild map with new Ids for newly created GCs
            for (Integer i = 0; i < gcsToUpsert.size(); i++) {
                vlocity_ins__GroupClass__c gc = gcsToUpsert[i];
                Map<String,Object> gcMap = (Map<String,Object>) groupClassesList[i];
                gcIdToPayloadMap.put(gc.Id, gcMap);
            }

            // Build contributions from payload
            List<vlocity_ins__GroupClassContribution__c> contribsToUpsert = new List<vlocity_ins__GroupClassContribution__c>();

            for (Id gcId : gcIdToPayloadMap.keySet()) {
                Map<String,Object> gcMap = gcIdToPayloadMap.get(gcId);
                List<Object> programsList = (List<Object>) gcMap.get('programs');
                Boolean applyProgramBased = (Boolean) gcMap.get('ARC_ApplyProgramBased__c');
                if (applyProgramBased == null) applyProgramBased = false;

                if (programsList != null) {
                    for (Object progObj : programsList) {
                        Map<String,Object> progMap = (Map<String,Object>) progObj;
                        List<Object> contribsList = (List<Object>) progMap.get('contributions');
                        String programName = (String) progMap.get('productName');

                        Id cliId = (Id) progMap.get('contractLineItemId');
                        if (cliId == null) {
                            cliId = tempKeyToCliId.get(programName);
                        }

                        if (contribsList != null) {
                            for (Object contribObj : contribsList) {
                                Map<String,Object> contribMap = (Map<String,Object>) contribObj;

                                vlocity_ins__GroupClassContribution__c contrib = new vlocity_ins__GroupClassContribution__c();

                                Id contribId = (Id) contribMap.get('id');
                                if (contribId != null) {
                                    contrib.Id = contribId;
                                }

                                contrib.vlocity_ins__GroupClassId__c = gcId;
                                contrib.ARC_ContractLineItem__c = cliId;

                                String empType = (String) contribMap.get('ARC_EmployeeType__c');
                                String empDiv = (String) contribMap.get('ARC_EmployeeDivision__c');
                                String empTier = (String) contribMap.get('ARC_EmployeeTier__c');

                                contrib.ARC_EmployeeType__c = empType;
                                contrib.ARC_EmployeeDivision__c = empDiv;
                                contrib.ARC_EmployeeTier__c = empTier;
                                contrib.vlocity_ins__ProductCategory__c = (String) contribMap.get('vlocity_ins__ProductCategory__c');

                                if (applyProgramBased && programName != null) {
                                    List<String> nameParts = new List<String>{ programName };
                                    if (String.isNotBlank(empType) && empType != 'None') nameParts.add(empType);
                                    if (String.isNotBlank(empDiv) && empDiv != 'None') nameParts.add(empDiv);
                                    if (String.isNotBlank(empTier) && empTier != 'None') nameParts.add(empTier);
                                    contrib.Name = String.join(nameParts, ' - ');
                                } else {
                                    contrib.Name = (String) contribMap.get('Name');
                                }

                                contrib.vlocity_ins__ContributionType__c = (String) contribMap.get('vlocity_ins__ContributionType__c');

                                Object percentObj = contribMap.get('vlocity_ins__ContributionPercent__c');
                                contrib.vlocity_ins__ContributionPercent__c = (percentObj != null) ? Decimal.valueOf(String.valueOf(percentObj)) : null;

                                Object amountObj = contribMap.get('vlocity_ins__ContributionAmount__c');
                                contrib.vlocity_ins__ContributionAmount__c = (amountObj != null) ? Decimal.valueOf(String.valueOf(amountObj)) : null;

                                contribsToUpsert.add(contrib);
                            }
                        }
                    }
                }
            }

            if (!contribsToUpsert.isEmpty()) {
                upsert contribsToUpsert;
            }

            //delete tier-based contributions if ARC_ApplyEmployeeTier__c is false
            Set<Id> contribIdsToKeep = new Set<Id>();
            for (vlocity_ins__GroupClassContribution__c c : contribsToUpsert) {
                if (c.Id != null) {
                    contribIdsToKeep.add(c.Id);
                }
            }

            Set<Id> allGcIds = gcIdToPayloadMap.keySet();
            List<vlocity_ins__GroupClassContribution__c> contribsToDelete = [
                SELECT Id
                FROM vlocity_ins__GroupClassContribution__c
                WHERE vlocity_ins__GroupClassId__c IN :allGcIds
                AND Id NOT IN :contribIdsToKeep
            ];

            if (!contribsToDelete.isEmpty()) {
                delete contribsToDelete;
            }

            Map<String,Object> savedData = getGroupClassFromOpportunity(opportunityId);

            Boolean isComplete = validateConfigurationComplete(savedData);
            Opportunity oppToUpdate = new Opportunity(
                Id = opportunityId,
                ARC_GroupClassesContributionsDefined__c = isComplete
            );
            update oppToUpdate;

            savedData.put('success', true);
            savedData.put('message', 'Configuration saved successfully.');
            savedData.put('ARC_GroupClassesContributionsDefined__c', isComplete);
            savedData.put('stats', new Map<String,Object>{
                'groupClassesUpdated' => gcsToUpsert.size(),
                'contractLineItemsUpserted' => clisToUpsert.size(),
                'contractLineItemsDeleted' => clisToDelete.size(),
                'contributionsUpserted' => contribsToUpsert.size(),
                'contributionsDeleted' => contribsToDelete.size()
            });

            return savedData;

        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving configuration: ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString());
        }
    }

    private static Boolean validateConfigurationComplete(Map<String,Object> savedData) {
    List<Object> groupClassesList = (List<Object>) savedData.get('groupClasses');
    if (groupClassesList == null || groupClassesList.isEmpty()) {
        return false;
    }

    Boolean hasAtLeastOneProgram = false;

    for (Object gcObj : groupClassesList) {
        Map<String,Object> gcMap = (Map<String,Object>) gcObj;

        if (String.isBlank((String) gcMap.get('ARC_EmployeeTypeModel__c'))) {
            return false;
        }
        if (String.isBlank((String) gcMap.get('ARC_EmployeeType__c'))) {
            return false;
        }
        if (String.isBlank((String) gcMap.get('ARC_EmployeeDivision__c'))) {
            return false;
        }
        if (String.isBlank((String) gcMap.get('ARC_ContributionMethod__c'))) {
            return false;
        }

        List<Object> programsList = (List<Object>) gcMap.get('programs');
        if (programsList == null || programsList.isEmpty()) {
            return false;
        }

        Boolean gcHasValidContrib = false;

        for (Object progObj : programsList) {
            Map<String,Object> progMap = (Map<String,Object>) progObj;
            List<Object> contribsList = (List<Object>) progMap.get('contributions');

            if (contribsList == null || contribsList.isEmpty()) {
                continue;
            }

            hasAtLeastOneProgram = true;

            for (Object contribObj : contribsList) {
                Map<String,Object> contribMap = (Map<String,Object>) contribObj;

                if (String.isBlank((String) contribMap.get('vlocity_ins__ProductCategory__c'))) {
                    return false;
                }

                Object percent = contribMap.get('vlocity_ins__ContributionPercent__c');
                Object amount = contribMap.get('vlocity_ins__ContributionAmount__c');

                if (percent == null && amount == null) {
                    return false;
                }
            }

            gcHasValidContrib = true;
        }

        if (!gcHasValidContrib) {
            return false;
        }
    }

    if (!hasAtLeastOneProgram) {
        return false;
    }

    return true;
}

 
}