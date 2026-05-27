/**
 * CVSEligibilityFileBatch_v2
 *
 * Migration Date: February 2026
 * Purpose: CVS eligibility file generation using InsurancePolicyParticipant/ARC_CoverageParticipant data model
 *
 * This class replaces the legacy GroupCensusMember-based implementation (ARC_CVSElegibilityFileBatchPOC)
 * with the coverage/policy participant model. Key changes:
 *   - Uses ARC_CoverageParticipant__c as the foundation query object
 *   - Active member determination via 4-condition logic (Contract Status, Start/End dates, Contact IsActive)
 *   - Product filtering via InsurancePolicyCoverage → Product2
 *   - Family grouping by InsurancePolicy instead of GroupCensus
 *   - FamilyID/MemberID use primary member's SSN (legacy compatible)
 *   - Addresses sourced from Account.BillingAddress fields
 *   - Sequence numbers read from Account.ARC_HAXFamilySequenceNumber__c (no DML updates)
 *
 * This class runs in parallel with the original during transition period.
 */
global with sharing class CVSEligibilityFileBatch_v2 implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

    public Integer limitRecords = 1000000000;
    public Integer sendFileEachNMembers = 1000000000;
    public Boolean sendFilesToTestSites = false;
    public Boolean sendToEmail = false;
    public String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
    
    Integer memberCount = 0;
    Integer totalBatches = 0;
    Integer currentBatch = 0;

    String fileName = '';
    String delimiter = '';
    String endRecord = '\n';
    String header;

    List<String> txtLines;
    // DEPRECATED in v2: No longer needed with new data model
    // List<String> groupCensusMemberFields;
    // List<String> contractFields;
    // List<vlocity_ins__GroupCensusMember__c> membersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();

    private Integer getColumnLength(String columnName, Integer recordType){
        Map<String, Integer> columnLength = new Map<String, Integer>();
        if (recordType == 1) {   
            columnLength.put('RecordType', 1);
            columnLength.put('Carrier', 9);
            columnLength.put('CarrierName', 25);
            columnLength.put('Address1', 25);
            columnLength.put('Address2', 15);
            columnLength.put('City', 20);
            columnLength.put('State', 2);
            columnLength.put('Zip', 10);
            columnLength.put('Phone', 10);
            columnLength.put('CreationDate', 7);
            columnLength.put('CreationTime', 6);
            columnLength.put('FileNumber', 8);
            columnLength.put('PLI', 9);
            columnLength.put('Filler1', 1252);
            columnLength.put('EOR', 1);
        }  
        if (recordType == 3) {            
            columnLength.put('RecordType', 1);
            columnLength.put('Carrier', 9);
            columnLength.put('Account', 15);
            columnLength.put('Group', 15);
            columnLength.put('MemberID', 18);
            columnLength.put('PersonCode', 3);
            columnLength.put('Relationship', 1);
            columnLength.put('LastName', 25);
            columnLength.put('FirstName', 15);
            columnLength.put('MiddleInitial', 1);
            columnLength.put('SexCode', 1);
            columnLength.put('DateOfBirth', 8);
            columnLength.put('MultiBirthCode', 1);
            columnLength.put('MemberType', 1);
            columnLength.put('LanguageCode', 1);
            columnLength.put('DURFlag', 1);
            columnLength.put('DURKey', 18);
            columnLength.put('SocialSecurityNumber', 9);
            columnLength.put('Address1', 40);
            columnLength.put('Address2', 40);
            columnLength.put('City', 20);
            columnLength.put('State', 2);
            columnLength.put('Zip1', 5);
            columnLength.put('Zip2', 4);
            columnLength.put('Zip3', 2);
            columnLength.put('Country', 4);
            columnLength.put('PhoneNumber', 10);
            columnLength.put('FamilyFlag', 1);
            columnLength.put('FamilyType', 1);
            columnLength.put('FamilyID', 18);
            columnLength.put('OriginalFromDate', 7);
            columnLength.put('BenefitResetDate', 7);
            columnLength.put('EffectiveDate', 7);
            columnLength.put('TerminationDate', 7);
            columnLength.put('Plan', 10);
            columnLength.put('PlanEffDate', 7);
            columnLength.put('Brand', 5);
            columnLength.put('Generic', 5);
            columnLength.put('Copay3', 5);
            columnLength.put('Copay4', 5);
            columnLength.put('ClientProductCode', 6);
            columnLength.put('ClientRiderCode', 6);
            columnLength.put('CareFromDate', 7);
            columnLength.put('CareThruDate', 7);
            columnLength.put('CareNetwork', 10);
            columnLength.put('CareNetworkPlanOvr', 10);
            columnLength.put('CareNetworkPlanFrm', 7);
            columnLength.put('CareFacilityID', 6);
            columnLength.put('CareQualifier', 10);
            columnLength.put('PhysicianID', 10);
            columnLength.put('AltInsFromDate', 7);
            columnLength.put('AltInsThruDate', 7);
            columnLength.put('AltInsIndicator', 1);
            columnLength.put('AltInsCode', 10);
            columnLength.put('AltInsID', 18);
            columnLength.put('NewCardFlag', 1);
            columnLength.put('FSA Indicator', 1);
            columnLength.put('GracePeriodInd', 1);
            columnLength.put('GracePeriodEffDate', 7);
            columnLength.put('MedCoverageType', 1);
            columnLength.put('MedFromDate', 7);
            columnLength.put('MBI_HICN_NONMEDD', 11);
            columnLength.put('FamilyTypeFromDate', 7);
            columnLength.put('FamilyTypeThruDate', 7);
            columnLength.put('DisenrollmentReasonCode', 1);
            columnLength.put('DateofDeath', 7);
            columnLength.put('Filler1', 73);
            columnLength.put('CDDEffectiveDate', 7);
            columnLength.put('CDDTermDate', 7);
            columnLength.put('CDD', 256);
            columnLength.put('AccumulationFamilyType', 1);
            columnLength.put('OverrrideDeductibleProrate', 1);
            columnLength.put('OverrideHSAProrate', 1);
            columnLength.put('ProrationDate', 7);
            columnLength.put('MoopLimit', 5);
            columnLength.put('MoopEff', 7);
            columnLength.put('Filler2', 85);
            columnLength.put('AdditionalID', 20);
            columnLength.put('AdditionalIDTypeCode', 2);
            columnLength.put('MedParticipationIndicator', 1);
            columnLength.put('Filler3', 1);
            columnLength.put('MedParticipationEffDate', 8);
            columnLength.put('MedParticipationThruDate', 8);
            columnLength.put('Filler4', 1);
            columnLength.put('AlternateID', 18); 
            columnLength.put('Filler5', 2);
            columnLength.put('Filler6', 1);
            columnLength.put('MBI_HICN', 12);
            columnLength.put('LICSPremiumSubsidyLevel', 3);
            columnLength.put('ContractID', 5);
            columnLength.put('PlanID', 3);
            columnLength.put('CareTakerFirstName', 30);
            columnLength.put('CareTakerLastName', 30);
            columnLength.put('CaretakerAddress1', 30);
            columnLength.put('CaretakerAddress2', 30);
            columnLength.put('CaretakerCity', 30);
            columnLength.put('CaretakerState', 2);
            columnLength.put('CaretakerZip', 9);
            columnLength.put('ST-Carrier', 9);
            columnLength.put('ST-Account', 15);
            columnLength.put('ST-Group', 15);
            columnLength.put('ST-MemberID', 18);
            columnLength.put('ST-Status', 1);
            columnLength.put('ST-COBCoverageCode', 1);
            columnLength.put('TransitionPeriodStartDate', 7);
            columnLength.put('TrasitionPeriodInactiveDate', 7);
            columnLength.put('ESRDFromDate', 7);
            columnLength.put('ESRDThruDate', 7);
            columnLength.put('DialysisFromDate', 7);
            columnLength.put('DialysisThruDate', 7);
            columnLength.put('TransplantFromDate', 7);
            columnLength.put('TransplantThruDate', 7);
            columnLength.put('MBRPartBFlagFromDate', 7);
            columnLength.put('MBRPartBFlagThruDate', 7);
            columnLength.put('MemberLanguagePrintCode', 1);
            columnLength.put('MBRHospiceFromDate', 7);
            columnLength.put('MBRHospiceThruDate', 7);
            columnLength.put('Filler7', 11);
            columnLength.put('QLClientSuppliedExternalMBRID', 20);
            columnLength.put('EOR', 1);
        }
        if (recordType == 9) {   
            columnLength.put('RecordType', 1);
            columnLength.put('Carrier', 9);
            columnLength.put('TotalRecords', 9);
            columnLength.put('TotalAdds', 9);
            columnLength.put('TotalChanges', 9);
            columnLength.put('TotalMoveHistory', 9);
            columnLength.put('TotalRollAccums', 9);
            columnLength.put('TotalReplacements', 9);
            columnLength.put('Filler1', 1335);
            columnLength.put('EOR', 1);
        } 
        
        return columnLength.get(columnName);
    }

    public List<String> getHeaderList() {
        List<String> headerList = new List<String>{
            'RecordType',
            'Carrier',
            'Account',
            'Group',
            'MemberID',
            'PersonCode',
            'Relationship',
        	'LastName',
            'FirstName',
            'MiddleInitial',
            'SexCode',
            'DateOfBirth',
            'MultiBirthCode',
            'MemberType',
            'LanguageCode',
            'DURFlag',
            'DURKey',
            'SocialSecurityNumber',
            'Address1',
            'Address2',
            'City',
            'State',
            'Zip1',
            'Zip2',
            'Zip3',
            'Country',
            'PhoneNumber',
            'FamilyFlag',
            'FamilyType',
            'FamilyID',
            'OriginalFromDate',
            'BenefitResetDate',
            'EffectiveDate',
            'TerminationDate',
            'Plan',
            'PlanEffDate',
            'Brand',
            'Generic',
            'Copay3',
            'Copay4',
            'ClientProductCode',
            'ClientRiderCode',
            'CareFromDate',
            'CareThruDate',
            'CareNetwork',
            'CareNetworkPlanOvr',
            'CareNetworkPlanFrm',
            'CareFacilityID',
            'CareQualifier',
            'PhysicianID',
            'AltInsFromDate',
            'AltInsThruDate',
            'AltInsIndicator',
            'AltInsCode',
            'AltInsID',
            'NewCardFlag',
            'FSA',
            'Indicator',
            'GracePeriodInd',
            'GracePeriodEffDate',
            'MedCoverageType',
            'MedFromDate',
            'MBI_HICN_NONMEDD',
            'FamilyTypeFromDate',
            'FamilyTypeThruDate',
            'DisenrollmentReasonCode',
            'DateofDeath',
            'Filler1',
            'CDDEffectiveDate',
            'CDDTermDate',
            'CDD',
            'AccumulationFamilyType',
            'OverrrideDeductibleProrate',
            'OverrideHSAProrate',
            'ProrationDate',
            'MoopLimit',
            'MoopEff',
            'Filler2',
            'AdditionalID',
            'AdditionalIDTypeCode',
            'MedParticipationIndicator',
            'Filler3',
            'MedParticipationEffDate',
            'MedParticipationThruDate',
            'Filler4',
            'AlternateID',
            'Filler5',
            'Filler6',
            'MBI_HICN',
            'LICSPremiumSubsidyLevel',
            'ContractID',
            'PlanID',
            'CareTakerFirstName',
            'CareTakerLastName',
            'CaretakerAddress1',
            'CaretakerAddress2',
            'CaretakerCity',
            'CaretakerState',
            'CaretakerZip',
            'ST-Carrier',
            'ST-Account',
            'ST-Group',
            'ST-MemberID',
            'ST-Status',
            'ST-COBCoverageCode',
            'TransitionPeriodStartDate',
            'TrasitionPeriodInactiveDate',
            'ESRDFromDate',
            'ESRDThruDate',
            'DialysisFromDate',
            'DialysisThruDate',
            'TransplantFromDate',
            'TransplantThruDate',
            'MBRPartBFlagFromDate',
            'MBRPartBFlagThruDate',
            'MemberLanguagePrintCode',
            'MBRHospiceFromDate',
            'MBRHospiceThruDate',
            'Filler7',
            'QLClientSuppliedExternalMBRID',
            'EOR'
        };

        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        Boolean isTest = Test.isRunningTest();
        Boolean testMode = isSandbox || isTest;

        if (testMode) {
            // headerList.add(0, 'ContractSfId');
        }
        return headerList;
    }

    private Map<String, String> initLineMap(Integer recordType) {
        Map<String, String> lineMap = new Map<String, String>();
        
        String carrier = '3267';

        String space = '';
        String cero = '0';

        if (recordType==1) {
            lineMap.put('RecordType', String.valueOf(recordType));
            lineMap.put('Carrier', carrier);
            lineMap.put('CarrierName', 'UHSM');
            lineMap.put('Address1', '');
            lineMap.put('Address2', '');
            lineMap.put('City', '');
            lineMap.put('State', '');
            lineMap.put('Zip', '');
            lineMap.put('Phone', '');
            lineMap.put('CreationDate', getCYYMMDDDate(Date.today()));
            lineMap.put('CreationTime', Datetime.now().format('HHmmss'));
            lineMap.put('FileNumber', cero);
            lineMap.put('PLI', cero);
            lineMap.put('Filler1', '');
            lineMap.put('EOR', '*');
        }

        if (recordType==3) {
            lineMap.put('RecordType', String.valueOf(recordType));
            lineMap.put('Carrier', '3267');
            lineMap.put('Account', '');
            lineMap.put('Group', '');
            lineMap.put('MemberID', '');
            lineMap.put('PersonCode', space);
            lineMap.put('Relationship', '');
            lineMap.put('LastName', '');
            lineMap.put('FirstName', '');
            lineMap.put('MiddleInitial', space);
            lineMap.put('SexCode', 'U');
            lineMap.put('DateOfBirth', '');
            lineMap.put('MultiBirthCode', cero);
            lineMap.put('MemberType', space);
            lineMap.put('LanguageCode', space);
            lineMap.put('DURFlag', space);
            lineMap.put('DURKey', space);
            lineMap.put('SocialSecurityNumber', cero);
            lineMap.put('Address1', space);
            lineMap.put('Address2', space);
            lineMap.put('City', space);
            lineMap.put('State', space);
            lineMap.put('Zip1', space);
            lineMap.put('Zip2', space);
            lineMap.put('Zip3', space);
            lineMap.put('Country', 'USA');
            lineMap.put('PhoneNumber', space);
            lineMap.put('FamilyFlag', space);
            lineMap.put('FamilyType', '');
            lineMap.put('FamilyID', '');
            lineMap.put('OriginalFromDate', cero);
            lineMap.put('BenefitResetDate', cero);
            lineMap.put('EffectiveDate', '');
            lineMap.put('TerminationDate', '1391231');
            lineMap.put('Plan', space);
            lineMap.put('PlanEffDate', cero);
            lineMap.put('Brand', cero);
            lineMap.put('Generic', cero);
            lineMap.put('Copay3', cero);
            lineMap.put('Copay4', cero);
            lineMap.put('ClientProductCode', space);
            lineMap.put('ClientRiderCode', space);
            lineMap.put('CareFromDate', cero);
            lineMap.put('CareThruDate', cero);
            lineMap.put('CareNetwork', space);
            lineMap.put('CareNetworkPlanOvr', space);
            lineMap.put('CareNetworkPlanFrm', cero);
            lineMap.put('CareFacilityID', space);
            lineMap.put('CareQualifier', space);
            lineMap.put('PhysicianID', space);
            lineMap.put('AltInsFromDate', cero);
            lineMap.put('AltInsThruDate', cero);
            lineMap.put('AltInsIndicator', space);
            lineMap.put('AltInsCode', space);
            lineMap.put('AltInsID', space);
            lineMap.put('NewCardFlag', space);
            lineMap.put('FSA Indicator', space);
            lineMap.put('GracePeriodInd', space);
            lineMap.put('GracePeriodEffDate', cero);
            lineMap.put('MedCoverageType', space);
            lineMap.put('MedFromDate', cero);
            lineMap.put('MBI_HICN_NONMEDD', space);
            lineMap.put('FamilyTypeFromDate', cero);
            lineMap.put('FamilyTypeThruDate', cero);
            lineMap.put('DisenrollmentReasonCode', space);
            lineMap.put('DateofDeath', cero);
            lineMap.put('Filler1', space);
            lineMap.put('CDDEffectiveDate', cero);
            lineMap.put('CDDTermDate', cero);
            lineMap.put('CDD', space);
            lineMap.put('AccumulationFamilyType', space);
            lineMap.put('OverrrideDeductibleProrate', space);
            lineMap.put('OverrideHSAProrate', space);
            lineMap.put('ProrationDate', cero);
            lineMap.put('MoopLimit', cero);
            lineMap.put('MoopEff', cero);
            lineMap.put('Filler2', space);
            lineMap.put('AdditionalID', space);
            lineMap.put('AdditionalIDTypeCode', space);
            lineMap.put('MedParticipationIndicator', space);
            lineMap.put('Filler3', space);
            lineMap.put('MedParticipationEffDate', cero);
            lineMap.put('MedParticipationThruDate', cero);
            lineMap.put('Filler4', space);
            lineMap.put('AlternateID', space);
            lineMap.put('Filler5', space);
            lineMap.put('Filler6', space);
            lineMap.put('MBI_HICN', space);
            lineMap.put('LICSPremiumSubsidyLevel', cero);
            lineMap.put('ContractID', space);
            lineMap.put('PlanID', space);
            lineMap.put('CareTakerFirstName', space);
            lineMap.put('CareTakerLastName', space);
            lineMap.put('CaretakerAddress1', space);
            lineMap.put('CaretakerAddress2', space);
            lineMap.put('CaretakerCity', space);
            lineMap.put('CaretakerState', space);
            lineMap.put('CaretakerZip', space);
            lineMap.put('ST-Carrier', space);
            lineMap.put('ST-Account', space);
            lineMap.put('ST-Group', space);
            lineMap.put('ST-MemberID', space);
            lineMap.put('ST-Status', space);
            lineMap.put('ST-COBCoverageCode', space);
            lineMap.put('TransitionPeriodStartDate', space);
            lineMap.put('TrasitionPeriodInactiveDate', space);
            lineMap.put('ESRDFromDate', space);
            lineMap.put('ESRDThruDate', space);
            lineMap.put('DialysisFromDate', space);
            lineMap.put('DialysisThruDate', space);
            lineMap.put('TransplantFromDate', space);
            lineMap.put('TransplantThruDate', space);
            lineMap.put('MBRPartBFlagFromDate', space);
            lineMap.put('MBRPartBFlagThruDate', space);
            lineMap.put('MemberLanguagePrintCode', space);
            lineMap.put('MBRHospiceFromDate', space);
            lineMap.put('MBRHospiceThruDate', space);
            lineMap.put('Filler7', space);
            lineMap.put('QLClientSuppliedExternalMBRID', space);
            lineMap.put('EOR', '*');
        }

        if (recordType == 9) {   
            lineMap.put('RecordType', String.valueOf(recordType));
            lineMap.put('Carrier', carrier);
            lineMap.put('TotalRecords', cero);
            lineMap.put('TotalAdds', cero);
            lineMap.put('TotalChanges', cero);
            lineMap.put('TotalMoveHistory', cero);
            lineMap.put('TotalRollAccums', cero);
            lineMap.put('TotalReplacements', cero);
            lineMap.put('Filler1', '');
            lineMap.put('EOR', '*');
        } 
        

        for (String columnName : lineMap.keySet()) {
            if (lineMap.get(columnName) == cero) {
                lineMap.put(columnName, fillLengthWithZeros(getColumnLength(columnName, recordType)));
            }
            lineMap.put(columnName, fillWithSpaces(lineMap.get(columnName), getColumnLength(columnName, recordType)));
        }

        return lineMap;
    }

    public String fillLengthWithZeros(Integer length){
        String zeros = '';
        for (Integer i = 0; i < length; i++) {
            zeros+='0';
        }
        return zeros;
    }

    private String completeWithZeros(Integer toComplete, Integer length) {
        String toCompleteStr = '' + toComplete;
        while(toCompleteStr.length() < length) {
            toCompleteStr = '0' + toCompleteStr;
        }
        return toCompleteStr;
    }

    private String getYYYYMMDDDate(Date d) {
        String year = completeWithZeros(d.year(), 4);
        String month = completeWithZeros(d.month(), 2);
        String day = completeWithZeros(d.day(), 2);

        return year + month + day;
    }

    private String getCYYMMDDDate(Date d) {
        String month = completeWithZeros(d.month(), 2);
        String day = completeWithZeros(d.day(), 2);

        String completeYear = completeWithZeros(d.year(), 4);

        String century = completeYear.substring(0, 2);
        String centuryOneZero = century == '19'? '0' : '1';
        String year = completeYear.substring(2, 4);

        return centuryOneZero + year + month + day;
    }

    private String getCYYMMDDDate(Datetime d) {
        String month = completeWithZeros(d.month(), 2);
        String day = completeWithZeros(d.day(), 2);

        String completeYear = completeWithZeros(d.year(), 4);

        String century = completeYear.substring(0, 2);
        String centuryOneZero = century == '19'? '0' : '1';
        String year = completeYear.substring(2, 4);

        return centuryOneZero + year + month + day;
    }

    private String deleteSlashes(String toClean) {
        return toClean.replaceAll('/', '');
    }

    private String deleteSpaces(String toClean) {
        if (toClean == null) {
            return '';
        }
        return toClean.replaceAll(' ', '');
    }

    private String deleteOR(String toClean) {
        return toClean.replaceAll('\'OR', '');
    }

    private String cleanNames(String toClean) {
        toClean = deleteSpaces(toClean);
        toClean = deleteSlashes(toClean);
        toClean = deleteOR(toClean);
        return toClean;
    }

    private String fillWithSpaces(String toFill, Integer length) {
        while (toFill.length() < length) {
            toFill+=' ';
        }
        if (toFill.length() > length) {
            toFill = toFill.substring(0, length);
        }

        return toFill;
    }

    private String getColumn(String column) {
        return '"' + column + '"';
    }
    
    private void addColumn(String columnName, String columnValue, Map<String, String> lineMap, Integer recordType) {
        if (columnValue == null) {
            columnValue = '';
        }
        columnValue = columnValue.toUpperCase();
        columnValue = reduceRepetitiveSpaces(columnValue);
        columnValue = removeAccents(columnValue);
        columnValue = removeSpecialChar(columnValue);
        lineMap.put(columnName, fillWithSpaces(columnValue, getColumnLength(columnName ,recordType)));
    }
    private String removeHypens(String str){
        return str.replaceAll('-', '');
    }

    private String getAccount(String productCode) {
        String account = '';
        // Bronze 10000
        if (productCode == 'PROG_UHSMBronze') {
            account = 'BRONZE';
        }
        // Silver 7500
        if (productCode == 'PROG_UHSMSilver') {
            account = 'SILVER';
        }
        // Gold 5000
        if (productCode == 'PROG_UHSMGold') {
            account = 'GOLD';
        }
        // Platinum 2500
        if (productCode == 'PROG_UHSMPlatinum') {
            account = 'PLATINUM';
        }
        // Bronze Essential 15000
        if (productCode == 'PROG_UHSMBronzeEssential') {
            account = 'ESSENTIAL';
        }
        // Silver Essential 10000
        if (productCode == 'PROG_UHSMSilverEssential') {
            account = 'ESSENTIAL';
        }
        // Gold Essential 7500
        if (productCode == 'PROG_UHSMGoldEssential') {
            account = 'ESSENTIAL';
        }
        // Platinum Essential 5000
        if (productCode == 'PROG_UHSMPlatinumEssential') {
            account = 'ESSENTIAL';
        }
        // Vital 10000
        if (productCode == 'PROG_UHSMVital') {
            account = 'ESSENTIAL';
        }
        // Fundamental 10000
        if (productCode == 'PROG_UHSMFundamental') {
            account = 'ESSENTIAL';
        }
        // WeShare (1k, 3k, 6k, 12k)
        if (
            (productCode == 'PROG_UHSM_WeShare1k') ||
            (productCode == 'PROG_UHSM_WeShare3k') ||
            (productCode == 'PROG_UHSM_WeShare6k') ||
            (productCode == 'PROG_UHSM_WeShare9k') ||
            (productCode == 'PROG_UHSM_WeShare12k')
        ) {
            account = 'GOLD';
        }
        if (
            (productCode == 'PROG_UHSM_Access5k') ||
            (productCode == 'PROG_UHSM_Access10k') 
        ) {
            account = 'ESSENTIAL';
        }
        return account;
    }

    /**
     * Determines family type for policies.
     * Uses policy-based grouping instead of census-based.
     *
     * @param coverageParticipants List of coverage participants
     * @return Map of policy IDs to family type ('1' = family/2+ members, '2' = individual/1 member)
     */
    private Map<Id, String> familyType(List<ARC_CoverageParticipant__c> coverageParticipants) {
        Map<Id, String> types = new Map<Id, String>();
        Map<Id, Integer> policyMemberCounts = new Map<Id, Integer>();

        // Count active members per policy
        for (ARC_CoverageParticipant__c cp : coverageParticipants) {
            if (isActiveMember(cp)) {
                Id policyId = cp.ARC_Policy__c;
                Integer count = policyMemberCounts.containsKey(policyId) ? policyMemberCounts.get(policyId) : 0;
                policyMemberCounts.put(policyId, count + 1);
            }
        }

        // Assign family type: 1 = family (2+ members), 2 = individual (1 member)
        for (Id policyId : policyMemberCounts.keySet()) {
            Integer memberCount = policyMemberCounts.get(policyId);
            types.put(policyId, memberCount == 1 ? '2' : '1');
        }

        return types;
    }

    private String getFirstNCharacters(String word, Integer characters){
        if (word.length()>characters) {
            return word.substring(0, 5);
        }else {
            return word;
        }
    }

    private String formatMemberCode(Integer memberCode){
        return String.valueOf(memberCode).length()==1 ? '0'+String.valueOf(memberCode) : String.valueOf(memberCode);
    }

    private String generateStringFromMap(Map<String, String> lineMap) {
        List<String> headerList = getHeaderList();
        List<String> lineList = new List<String>();
        for (String head: headerList) {
            String value = lineMap.get(head);
            lineList.add(value);
        }
        return String.join(lineMap.values(), delimiter);
    }

    public CVSEligibilityFileBatch_v2() {

        if ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox || sendFilesToTestSites) {
            fileName = 'UHSS.TST' + getMMDD();
        }else {
            fileName = 'UHSS.MBR' + getMMDD();
        }

        txtLines = new List<String>();
        isFirst = true;

        // DEPRECATED in v2: Field lists no longer needed with new data model
        // All fields now queried directly in start() method via ARC_CoverageParticipant__c
    }
    


    global Database.QueryLocator start(Database.BatchableContext BC ) {
        // Query InsurancePolicy records to ensure each policy is processed exactly once
        // This prevents duplicate records in output when families span multiple batches
        String query =
            'SELECT Id, Name, ' +
            'ARC_EffectiveDate__c, ARC_ExpirationDate__c, ' +
            'ARC_Contract__c, ' +
            'ARC_Contract__r.Status, ' +
            'ARC_Contract__r.Member_Id__c, ' +
            'ARC_Contract__r.ARC_EffectiveDate__c, ' +
            'ARC_Contract__r.vlocity_ins__EnrollmentEndDate__c ' +
            'FROM InsurancePolicy ' +
            'WHERE ARC_Contract__r.Status = \'Activated\' ' +
            'AND Id IN (' +
                'SELECT ARC_Policy__c ' +
                'FROM ARC_CoverageParticipant__c ' +
                'WHERE ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = \'Medical\' ' +
                'AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode != \'PROG_WeShareLegacy\' ' +
                'AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode IN (' +
                    '\'PROG_UHSMBronze\', \'PROG_UHSMSilver\', \'PROG_UHSMGold\', \'PROG_UHSMPlatinum\', ' +
                    '\'PROG_UHSMBronzeEssential\', \'PROG_UHSMSilverEssential\', \'PROG_UHSMGoldEssential\', \'PROG_UHSMPlatinumEssential\', ' +
                    '\'PROG_UHSMVital\', \'PROG_UHSMFundamental\', ' +
                    '\'PROG_UHSM_WeShare1k\', \'PROG_UHSM_WeShare3k\', \'PROG_UHSM_WeShare6k\', \'PROG_UHSM_WeShare9k\', \'PROG_UHSM_WeShare12k\', ' +
                    '\'PROG_UHSM_Access5k\', \'PROG_UHSM_Access10k\'' +
                ')' +
            ') ' +
            'ORDER BY ARC_Contract__r.CreatedDate DESC ' +
            'LIMIT ' + limitRecords;

        Integer totalRecords = [
            SELECT COUNT()
            FROM InsurancePolicy
            WHERE ARC_Contract__r.Status = 'Activated'
            AND Id IN (
                SELECT ARC_Policy__c
                FROM ARC_CoverageParticipant__c
                WHERE ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
                AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode != 'PROG_WeShareLegacy'
            )
            LIMIT :limitRecords
        ];
        this.totalBatches = Integer.valueOf(Math.ceil(totalRecords / 10));

        return Database.getQueryLocator(query);
    }

    /**
     * Determines if a coverage participant is active based on 4 conditions:
     * 1. Contract Status = 'Activated'
     * 2. Start Date is not in the future
     * 3. End Date is not in the past (or is null)
     * 4. Contact.vlocity_ins__IsActive__c = true
     */
    private Boolean isActiveMember(ARC_CoverageParticipant__c cp) {
        Date today = Date.today();

        // 1. Contract Status (already filtered in query, but double-check)
        if (cp.ARC_Policy__r.ARC_Contract__r.Status != 'Activated') {
            return false;
        }

        // 2. Start Date Check - member hasn't started yet
        if (cp.ARC_PolicyParticipant__r.ARC_StartDate__c != null &&
            cp.ARC_PolicyParticipant__r.ARC_StartDate__c > today) {
            return false;
        }

        // 3. End Date Check - member has already ended
        if (cp.ARC_PolicyParticipant__r.ARC_EndDate__c != null &&
            cp.ARC_PolicyParticipant__r.ARC_EndDate__c < today) {
            return false;
        }

        // 4. Contact Active Status
        if (cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__IsActive__c != true) {
            return false;
        }

        return true;
    }

    /**
     * Builds a map of Contact IDs to their family's primary member's SSN.
     * This is used for populating the FamilyID and MemberID fields (legacy compatible).
     *
     * Process:
     * 1. Find primary contact per policy
     * 2. Query all primary SSNs in one query
     * 3. Map all family members to their primary's SSN
     */
    private Map<Id, String> buildPrimarySSNMap(List<ARC_CoverageParticipant__c> allParticipants) {
        Map<Id, String> contactIdToPrimarySSN = new Map<Id, String>();
        Map<Id, Id> policyToPrimaryContact = new Map<Id, Id>();
        Set<Id> primaryContactIds = new Set<Id>();

        // Pass 1: Find primary contacts per policy
        for (ARC_CoverageParticipant__c cp : allParticipants) {
            if (cp.ARC_CoverageRole__c == 'Primary') {
                policyToPrimaryContact.put(
                    cp.ARC_Policy__c,
                    cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId
                );
                primaryContactIds.add(cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId);
            }
        }

        // Pass 2: Query all primary SSNs in one query
        Map<Id, Contact> primaryContacts = new Map<Id, Contact>([
            SELECT Id, vlocity_ins__SocialSecurityNumber__c
            FROM Contact
            WHERE Id IN :primaryContactIds
        ]);

        // Pass 3: Map all contacts to their family's primary SSN
        for (ARC_CoverageParticipant__c cp : allParticipants) {
            Id policyId = cp.ARC_Policy__c;
            Id primaryContactId = policyToPrimaryContact.get(policyId);

            if (primaryContactId != null && primaryContacts.containsKey(primaryContactId)) {
                contactIdToPrimarySSN.put(
                    cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId,
                    primaryContacts.get(primaryContactId).vlocity_ins__SocialSecurityNumber__c
                );
            }
        }

        return contactIdToPrimarySSN;
    }

    /**
     * Generates CVS file record data from ARC_CoverageParticipant__c.
     * Replaces the legacy generateFromGroupCensusMember() method.
     *
     * @param cp Coverage participant record
     * @param lineMap Map to populate with field values
     * @param primarySSNMap Map of contact IDs to primary member SSNs (for FamilyID/MemberID)
     * @param memberCodes Map of coverage participant IDs to sequence numbers
     */
    private void generateFromCoverageParticipant(
        ARC_CoverageParticipant__c cp,
        Map<String, String> lineMap,
        Map<Id, String> primarySSNMap,
        Map<Id, String> memberCodes
    ) {
        Contact contact = cp.ARC_PolicyParticipant__r.PrimaryParticipantContact;

        // DEBUG: Log SSN values
        System.debug('Contact ID: ' + contact.Id);
        System.debug('Contact SSN from query: ' + contact.vlocity_ins__SocialSecurityNumber__c);
        System.debug('Primary SSN from map: ' + primarySSNMap.get(contact.Id));
        System.debug('Account PersonGender: ' + (contact.Account != null ? contact.Account.PersonGender : 'null'));

        // MemberID & FamilyID = Primary's SSN (legacy compatible)
        String primarySSN = primarySSNMap.get(contact.Id);
        if (primarySSN != null) {
            addColumn('MemberID', deleteSpaces(removeHypens(primarySSN)), lineMap, 3);
            addColumn('FamilyID', deleteSpaces(removeHypens(primarySSN)), lineMap, 3);
        }

        // AlternateID = Contract Member_Id__c + Sequence
        String sequence = memberCodes.get(cp.Id);
        if (sequence != null && cp.ARC_Policy__r.ARC_Contract__r.Member_Id__c != null) {
            addColumn('AlternateID', cp.ARC_Policy__r.ARC_Contract__r.Member_Id__c + sequence, lineMap, 3);
        }

        // Demographics
        addColumn('LastName', cleanNames(contact.LastName), lineMap, 3);
        addColumn('FirstName', cleanNames(contact.FirstName), lineMap, 3);

        // Middle Initial (extract first char from middle name)
        String middleInitial = '';
        if (contact.vlocity_ins__MiddleName__c != null && contact.vlocity_ins__MiddleName__c.length() > 0) {
            middleInitial = contact.vlocity_ins__MiddleName__c.substring(0, 1);
        }
        addColumn('MiddleInitial', middleInitial, lineMap, 3);

        // Gender (from Person Account field)
        if (contact.Account != null) {
            if (contact.Account.PersonGender == 'Male') {
                addColumn('SexCode', 'M', lineMap, 3);
            }
            if (contact.Account.PersonGender == 'Female') {
                addColumn('SexCode', 'F', lineMap, 3);
            }
        }

        // Date of Birth
        if (contact.Birthdate != null) {
            addColumn('DateOfBirth', getYYYYMMDDDate(contact.Birthdate), lineMap, 3);
        }

        // Relationship (map ARC_CoverageRole__c to codes)
        String relationshipCode = '3'; // Default to dependent
        if (cp.ARC_CoverageRole__c == 'Primary') {
            relationshipCode = '1';
        } else if (cp.ARC_CoverageRole__c == 'Spouse') {
            relationshipCode = '2';
        }
        addColumn('Relationship', relationshipCode, lineMap, 3);

        // SSN
        if (contact.vlocity_ins__SocialSecurityNumber__c != null) {
            addColumn('SocialSecurityNumber', removeHypens(contact.vlocity_ins__SocialSecurityNumber__c), lineMap, 3);
        }

        // Address (BillingAddress from Account)
        if (contact.Account != null) {
            addColumn('Address1', contact.Account.BillingStreet, lineMap, 3);
            addColumn('City', contact.Account.BillingCity, lineMap, 3);
            addColumn('State', contact.Account.BillingState, lineMap, 3);
            addColumn('Zip1', contact.Account.BillingPostalCode != null ? getFirstNCharacters(contact.Account.BillingPostalCode, 5) : null, lineMap, 3);
        }

        // Phone (remove hyphens, extract last 10 digits if needed)
        if (contact.Phone != null) {
            String phone = removeHypens(contact.Phone);
            if (phone.length() > 10) {
                phone = phone.substring(phone.length() - 10); // Last 10 digits
            }
            addColumn('PhoneNumber', phone, lineMap, 3);
        }
    }

    /**
     * Determines sequence numbers for coverage participants.
     * Reads ARC_HAXFamilySequenceNumber__c from Account and formats as 01, 02, 03, etc.
     *
     * @param coverageParticipants List of coverage participants
     * @return Map of coverage participant IDs to formatted sequence numbers (01, 02, 03+)
     */
    private Map<Id, String> memberCodesInsurancePolicy(
        List<ARC_CoverageParticipant__c> coverageParticipants
    ) {
        Map<Id, String> cpIdToSequence = new Map<Id, String>();

        for (ARC_CoverageParticipant__c cp : coverageParticipants) {
            String sequence = '00'; // Default if null

            // Read sequence number from Account field
            if (cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account != null &&
                cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_HAXFamilySequenceNumber__c != null) {

                Decimal seqNumber = cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_HAXFamilySequenceNumber__c;
                sequence = formatMemberCode(Integer.valueOf(seqNumber));
            } else {
                System.debug('WARNING: ARC_HAXFamilySequenceNumber__c is null for Contact ' +
                            cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId +
                            ', using default 00');
            }

            cpIdToSequence.put(cp.Id, sequence);
        }

        return cpIdToSequence;
    }

    /**
     * Determines multi-birth count for policies.
     * Uses policy-based grouping instead of census-based.
     *
     * @param coverageParticipants List of coverage participants
     * @return Map of policy IDs to max duplicate birthdate count (for MultiBirthCode field)
     */
    private Map<Id, String> multiBirth(List<ARC_CoverageParticipant__c> coverageParticipants) {
        Map<Id, Map<String, Integer>> policyDateCounts = new Map<Id, Map<String, Integer>>();

        // Count duplicate birthdates per policy
        for (ARC_CoverageParticipant__c cp : coverageParticipants) {
            if (isActiveMember(cp) && cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.Birthdate != null) {
                Id policyId = cp.ARC_Policy__c;
                String birthdate = cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.Birthdate.format();

                if (!policyDateCounts.containsKey(policyId)) {
                    policyDateCounts.put(policyId, new Map<String, Integer>());
                }

                Map<String, Integer> dateCounts = policyDateCounts.get(policyId);
                Integer count = dateCounts.containsKey(birthdate) ? dateCounts.get(birthdate) : 0;
                dateCounts.put(birthdate, count + 1);
            }
        }

        // Find max duplicate count per policy and convert to CVS format
        // CVS expects: 0 = single birth, 2 = twins, 3 = triplets, etc.
        Map<Id, String> result = new Map<Id, String>();
        for (Id policyId : policyDateCounts.keySet()) {
            Integer maxCount = 0;
            for (Integer count : policyDateCounts.get(policyId).values()) {
                if (count > maxCount) {
                    maxCount = count;
                }
            }
            // Convert: if only 1 person has a birthdate, return "0" (not a multiple birth)
            // If 2+ people share a birthdate, return the count
            String multiBirthCode = (maxCount == 1) ? '0' : String.valueOf(maxCount);
            result.put(policyId, multiBirthCode);
        }

        return result;
    }

    Integer activeMembersCount = 0;
    /**
     * Execute method for batch processing.
     * Processes InsurancePolicy records (not coverage participants) to ensure each policy
     * is processed exactly once and all family members are included together.
     *
     * This approach prevents duplicate records and ensures correct sequence numbering,
     * family type detection, and multi-birth calculation.
     */
    global void execute(Database.BatchableContext BC, List<InsurancePolicy> policies) {
        this.currentBatch++;

        try {
            // Extract policy IDs from batch
            Set<Id> policyIds = new Set<Id>();
            for (InsurancePolicy policy : policies) {
                policyIds.add(policy.Id);
            }

            // Query ONLY Medical coverage participants for these policies
            // This prevents duplicates when a person has multiple coverage types (Medical, Dental, etc.)
            List<ARC_CoverageParticipant__c> coverageParticipants = [
                SELECT Id, ARC_CoverageRole__c,
                    ARC_PolicyParticipant__c,
                    ARC_PolicyParticipant__r.ARC_StartDate__c,
                    ARC_PolicyParticipant__r.ARC_EndDate__c,
                    ARC_PolicyParticipant__r.ParticipantCode,
                    ARC_PolicyParticipant__r.PrimaryParticipantContactId,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.FirstName,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.LastName,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__MiddleName__c,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.Birthdate,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__SocialSecurityNumber__c,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.AccountId,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.BillingStreet,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.BillingCity,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.BillingState,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.BillingPostalCode,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.PersonGender,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.Account.ARC_HAXFamilySequenceNumber__c,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.Phone,
                    ARC_PolicyParticipant__r.PrimaryParticipantContact.vlocity_ins__IsActive__c,
                    ARC_Policy__c, ARC_Policy__r.Name,
                    ARC_Policy__r.ARC_EffectiveDate__c, ARC_Policy__r.ARC_ExpirationDate__c,
                    ARC_Policy__r.ARC_Contract__c,
                    ARC_Policy__r.ARC_Contract__r.Status,
                    ARC_Policy__r.ARC_Contract__r.Member_Id__c,
                    ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c,
                    ARC_Policy__r.ARC_Contract__r.vlocity_ins__EnrollmentEndDate__c,
                    ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode
                FROM ARC_CoverageParticipant__c
                WHERE ARC_Policy__c IN :policyIds
                AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
                AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode != 'PROG_WeShareLegacy'
                AND ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode IN (
                    'PROG_UHSMBronze', 'PROG_UHSMSilver', 'PROG_UHSMGold', 'PROG_UHSMPlatinum',
                    'PROG_UHSMBronzeEssential', 'PROG_UHSMSilverEssential', 'PROG_UHSMGoldEssential', 'PROG_UHSMPlatinumEssential',
                    'PROG_UHSMVital', 'PROG_UHSMFundamental',
                    'PROG_UHSM_WeShare1k', 'PROG_UHSM_WeShare3k', 'PROG_UHSM_WeShare6k', 'PROG_UHSM_WeShare9k', 'PROG_UHSM_WeShare12k',
                    'PROG_UHSM_Access5k', 'PROG_UHSM_Access10k'
                )
                ORDER BY ARC_Policy__c, ARC_CoverageRole__c
            ];

            System.debug('Batch processing ' + policies.size() + ' policies with ' + coverageParticipants.size() + ' total coverage participants');

            // Build all necessary maps once per batch
            Map<Id, String> primarySSNMap = buildPrimarySSNMap(coverageParticipants);
            Map<Id, String> memberCodes = memberCodesInsurancePolicy(coverageParticipants);
            Map<Id, String> familyTypes = familyType(coverageParticipants);
            Map<Id, String> multiBirthCounts = multiBirth(coverageParticipants);

            // Track processed participants to prevent duplicates
            Set<String> processedParticipants = new Set<String>();

            // Process each coverage participant
            for (ARC_CoverageParticipant__c cp : coverageParticipants) {
                // Create unique key: Policy ID + Participant Contact ID
                String participantKey = String.valueOf(cp.ARC_Policy__c) + '_' +
                                       String.valueOf(cp.ARC_PolicyParticipant__r.PrimaryParticipantContactId);

                // Skip if already processed (handles duplicate coverage participant records)
                if (processedParticipants.contains(participantKey)) {
                    System.debug('WARNING: Duplicate coverage participant detected for policy ' +
                                cp.ARC_Policy__r.Name + ' and contact ' +
                                cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.FirstName + ' ' +
                                cp.ARC_PolicyParticipant__r.PrimaryParticipantContact.LastName +
                                '. Skipping duplicate.');
                    continue;
                }

                // Filter to active members only
                if (isActiveMember(cp)) {
                    // Mark this participant as processed
                    processedParticipants.add(participantKey);
                    activeMembersCount++;
                    Map<String, String> newLineMap = initLineMap(3);

                    // Generate member demographics and identifiers
                    generateFromCoverageParticipant(cp, newLineMap, primarySSNMap, memberCodes);

                    // Add family type
                    addColumn('FamilyType', familyTypes.get(cp.ARC_Policy__c), newLineMap, 3);

                    // Add multi-birth code
                    String multiBirthCode = multiBirthCounts.get(cp.ARC_Policy__c);
                    if (multiBirthCode != null) {
                        addColumn('MultiBirthCode', multiBirthCode, newLineMap, 3);
                    }

                    // Add product account (BRONZE, SILVER, GOLD, etc.)
                    String productCode = cp.ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode;
                    if (productCode != null) {
                        addColumn('Account', getAccount(productCode), newLineMap, 3);

                        // Special handling for WeShare products
                        if (productCode.startsWith('PROG_UHSM_WeShare')) {
                            addColumn('Group', 'ADV', newLineMap, 3);
                        }
                    }

                    // Add date fields
                    // EffectiveDate uses Contract-level date (same for all family members)
                    if (cp.ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c != null) {
                        addColumn('EffectiveDate', getCYYMMDDDate(cp.ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c), newLineMap, 3);
                    }

                    // TerminationDate uses participant-level date (can vary per person)
                    if (cp.ARC_PolicyParticipant__r.ARC_EndDate__c != null) {
                        addColumn('TerminationDate', getCYYMMDDDate(cp.ARC_PolicyParticipant__r.ARC_EndDate__c), newLineMap, 3);
                    }

                    // Add grace period logic (based on contract effective date)
                    // NOTE: This runs AFTER WeShare check and overwrites Group value (matching old code behavior)
                    if (cp.ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c != null) {
                        Date contractEffectiveDate = cp.ARC_Policy__r.ARC_Contract__r.ARC_EffectiveDate__c;
                        if (contractEffectiveDate.daysBetween(System.today()) <= 60) {
                            addColumn('GracePeriodInd', 'Y', newLineMap, 3);
                            addColumn('Group', 'GEN', newLineMap, 3);
                        } else {
                            addColumn('GracePeriodInd', 'N', newLineMap, 3);
                            addColumn('Group', 'ADV', newLineMap, 3);
                        }
                        addColumn('GracePeriodEffDate', getCYYMMDDDate(contractEffectiveDate.addDays(60)), newLineMap, 3);
                    }

                    // Handle missing Group value
                    if (newLineMap.get('Group') == null) {
                        addColumn('Group', 'GroupNull', newLineMap, 3);
                    } else if (newLineMap.get('Group') == '') {
                        addColumn('Group', 'GroupEmpty', newLineMap, 3);
                    }

                    txtLines.add(generateStringFromMap(newLineMap));
                    memberCount++;
                }
            }

            // Clear large objects to free heap
            coverageParticipants.clear();
            primarySSNMap.clear();
            memberCodes.clear();
            familyTypes.clear();
            multiBirthCounts.clear();
            processedParticipants.clear();

            System.debug('Batch ' + currentBatch + ': Processed ' + activeMembersCount + ' active members, current txtLines size: ' + txtLines.size());

            // Send file if heap usage exceeds 50%
            if (Limits.getHeapSize() > Limits.getLimitHeapSize() * 0.5) {
                System.debug('Heap usage exceeded 50%, sending file. Current memberCount: ' + memberCount);
                sendFile(false);
                memberCount = 0;
            }

        } catch (Exception e) {
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatchPOC.sendEmailNotification(
                ('Error in CVS FILE BATCH v2 Execute: ' + e.getMessage() + '\n' + e.getStackTraceString()),
                'ERROR in CVS ELIGIBILITY FILE BATCH V2 on the ' + Date.today(),
                apexErrorEmail
            );
        }
    }

    private String reduceRepetitiveSpaces(String file) {
        while(file.contains('  ')) {
            file = file.replace('  ', ' ');
        }
        return file;
    }

    private String removeSpecialChar(String toClean) {
        String allowed = ' ';
        String alphanumeric = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        String special = '\'@,-/#."_';

        allowed += alphanumeric;
        allowed += special;

        String cleaned = '';

        for (Integer j=0; j<toClean.length(); j++) {
            if (allowed.contains(toClean.substring(j, j+1))) {
                cleaned += toClean.substring(j, j+1);
            }
        }

        return cleaned;
    }

    private String removeAccents(String toClean) {
        String wAccents = 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġȑȒȓȔȕȗȘș';
        String woAccents = 'AAAAAAACEEEEIIIIDNOOOOOOUUUUYBaaaaaaaceeeeiiiionoooooouuuuybyAaAaAaCcCcCcCcDdDdEeEeEeEeEeGgGgGgrRrUuuSs';

        String returnString = toClean;
        for (Integer i = 0; i < wAccents.length(); i++) {
            returnString = returnString.replaceAll(wAccents.substring(i, i+1), woAccents.substring(i, i+1));
        }
        return returnString;
    }

    private String getMMDD() {
        Datetime d = Datetime.now();
        String month = completeWithZeros(d.month(), 2);
        String day = completeWithZeros(d.day(), 2);
        String mmdd = month + day;
        return mmdd;
    }

    private Map<String, String> generateTrailerRecord(Integer totalRows){
        Map <String, String> newLineMap = initLineMap(9);
        addColumn('TotalRecords', completeWithZeros(totalRows, getColumnLength('TotalRecords', 9)), newLineMap,9);
        return newLineMap;
    }

    /**
     * Finish method for batch processing.
     * Sends final file. No DML updates needed in v2 (sequence numbers read from field, not calculated).
     */
    global void finish(Database.BatchableContext BC) {
        sendFile(true);
    }

    private Integer totalLines = 0;
    private Integer sentCount = 1;
    private Boolean isFirst = true;

    private void sendFile(Boolean finish){
        String fileString = String.join(txtLines, endRecord) + '\n';
        //add recordType1:
        Integer lastLine = totalLines - txtLines.size();
        totalLines += txtLines.size();
        
        if (isFirst) {
            fileString = generateStringFromMap(initLineMap(1))+'\n' + fileString;
        }
        //add recordType9:
        if (finish) {
            fileString += generateStringFromMap(generateTrailerRecord(totalLines));
            //10 seconds delay
            // Long startTime = System.currentTimeMillis();
            // while (System.currentTimeMillis() - startTime < 10000) {
            // }
        }

        if (this.sendToEmail) {
            List<String> addresses = new List<String>();
            addresses.add(apexErrorEmail);

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(addresses);
            email.setPlainTextBody('Test');

            Messaging.EmailFileAttachment file = new Messaging.EmailFileAttachment();
            file.setFileName('activeMembersCount ' + activeMembersCount + ' ' + memberCount);
            file.setBody(Blob.valueOf(fileString));
            
            email.setFileAttachments(new Messaging.EmailFileAttachment[] {file});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }

        if (!this.sendToEmail && (sendFilesToTestSites || !([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox))) {
            String finalFilename = filename+'.txt';
            System.enqueueJob(new ARC_QueableSendFileBatchPOC(
                fileString, 
                finalFilename, 
                'CVS', 
                sendFilesToTestSites, 
                sentCount == 1, 
                finish, 
                lastLine
            ));
   
            isFirst = false;
            sentCount ++;
        }
        txtLines.clear();
    }

    @InvocableMethod(label='Run CVS File Batch v2' description='Runs the CVS File Batch v2 (posts to test folder)' category='Elegibility Files')
    global static void runCVSBatch(){
        CVSEligibilityFileBatch_v2 batch = new CVSEligibilityFileBatch_v2();
        batch.sendFilesToTestSites = true;  // Posts to AWS test/ folder for parallel validation
        batch.sendFileEachNMembers = 500;
        Database.executeBatch(batch, 10);
    }
}