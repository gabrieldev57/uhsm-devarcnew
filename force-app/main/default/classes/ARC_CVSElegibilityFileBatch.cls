global with sharing class ARC_CVSElegibilityFileBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

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
    List<String> groupCensusMemberFields;
    List<String> contractFields;
    List<vlocity_ins__GroupCensusMember__c> membersToUpdate = new List<vlocity_ins__GroupCensusMember__c>();

    private Integer getColumnLenght(String columnName, Integer recordType){
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
            lineMap.put('PhoneNumber', cero);
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
                lineMap.put(columnName, fillLengthWithZeros(getColumnLenght(columnName, recordType)));
            }
            lineMap.put(columnName, fillWithSpaces(lineMap.get(columnName), getColumnLenght(columnName, recordType)));
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
        lineMap.put(columnName, fillWithSpaces(columnValue, getColumnLenght(columnName ,recordType)));
    }
    private String removeHypens(String str){
        return str.replaceAll('-', '');
    }

    private void generateFromGroupCensusMember(vlocity_ins__GroupCensusMember__c groupCensusMember, Map<String, String> lineMap, Map <Id, String> memberCodeSSN, Map <Id, String> censusFirstPolicyNumber) {
        if ((groupCensusMember.vlocity_ins__IsPrimaryMember__c ? groupCensusMember.vlocity_ins__SocialSecurityNumber__c : groupCensusMember.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__SocialSecurityNumber__c)!=null) {
            addColumn('MemberID', deleteSpaces(removeHypens(groupCensusMember.vlocity_ins__IsPrimaryMember__c ? groupCensusMember.vlocity_ins__SocialSecurityNumber__c : groupCensusMember.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__SocialSecurityNumber__c)) , lineMap,3);
            addColumn('FamilyID', deleteSpaces(removeHypens(groupCensusMember.vlocity_ins__IsPrimaryMember__c ? groupCensusMember.vlocity_ins__SocialSecurityNumber__c : groupCensusMember.vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__SocialSecurityNumber__c)) , lineMap,3);
        }
        addColumn('AlternateID', deleteSpaces(groupCensusMember.vlocity_ins__RelatedCensusMemberId__r.e123_member_id__c != null || groupCensusMember.e123_member_id__c != null ? censusFirstPolicyNumber.get(groupCensusMember.vlocity_ins__CensusId__c) : (groupCensusMember.vlocity_ins__IsPrimaryMember__c  ? groupCensusMember.Member_ID__c : groupCensusMember.vlocity_ins__RelatedCensusMemberId__r.Member_ID__c)) + memberCodeSSN.get(groupCensusMember.Id), lineMap,3);
        // if (groupCensusMember.e123_member_id__c != null) {
            // addColumn('FamilyID', deleteSpaces(censusFirstPolicyNumber.get(groupCensusMember.vlocity_ins__CensusId__c)), lineMap,3);
            // addColumn('FamilyID', deleteSpaces(censusFirstPolicyNumber.get(groupCensusMember.vlocity_ins__CensusId__c)), lineMap,3);
        // }else {
            // addColumn('FamilyID', deleteSpaces(groupCensusMember.vlocity_ins__RelatedCensusMemberId__c != null ? groupCensusMember.vlocity_ins__RelatedCensusMemberId__r.Member_ID__c : groupCensusMember.Member_ID__c), lineMap,3);
        // }

        addColumn('LastName', cleanNames(groupCensusMember.vlocity_ins__LastName__c), lineMap,3);
        addColumn('FirstName', cleanNames(groupCensusMember.vlocity_ins__FirstName__c), lineMap,3);
        addColumn('MiddleInitial', groupCensusMember.ARC_MiddleInitial__c, lineMap,3);
        if (groupCensusMember.vlocity_ins__Gender__c == 'Male') {
            addColumn('SexCode', 'M', lineMap,3);
        }
        if (groupCensusMember.vlocity_ins__Gender__c == 'Female') {
            addColumn('SexCode', 'F', lineMap,3);

        }
        if (groupCensusMember.vlocity_ins__Birthdate__c != null) {
            addColumn('DateOfBirth', getYYYYMMDDDate(groupCensusMember.vlocity_ins__Birthdate__c), lineMap,3);
        }
        if (groupCensusMember.vlocity_ins__IsPrimaryMember__c) {
            addColumn('Relationship', '1', lineMap,3);
        }
        if (groupCensusMember.vlocity_ins__IsSpouse__c) {
            addColumn('Relationship', '2', lineMap,3);
        }
        if (groupCensusMember.ARC_DependentRelationship__c == 'Child' || groupCensusMember.ARC_DependentRelationship__c == 'Temporary Newborn' ) {
            addColumn('Relationship', '3', lineMap,3);
        }
        if (groupCensusMember.vlocity_ins__SocialSecurityNumber__c != null) {
            addColumn('SocialSecurityNumber', removeHypens(groupCensusMember.vlocity_ins__SocialSecurityNumber__c), lineMap,3);
        }
        addColumn('Address1', groupCensusMember.ARC_PhysicalAddressStreet__c, lineMap,3);
        addColumn('City', groupCensusMember.ARC_PhysicalAddressCity__c, lineMap,3);
        addColumn('State', groupCensusMember.ARC_PhysicalAddressState__c, lineMap,3);
        addColumn('Zip1', groupCensusMember.ARC_PhysicalAddressZipCode__c!=null ? getFirstNCharacters(groupCensusMember.ARC_PhysicalAddressZipCode__c, 5) : null, lineMap,3);
        addColumn('PhoneNumber', groupCensusMember.ARC_Phone__c!=null? removeHypens(groupCensusMember.ARC_Phone__c.substring(2, groupCensusMember.ARC_Phone__c.length())) :null, lineMap,3);
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

    private Map<Id, String> familyType(List<Contract> contracts, List<vlocity_ins__GroupCensusMember__c> members) {

        Map<Id, String> types = new Map<Id, String>();

        for (Contract contract: contracts) {

            String familyType = '';
            Integer primary = 0;
            Integer children = 0;
            Integer spouse = 0;

            for (vlocity_ins__GroupCensusMember__c member: members) {
                if (member.ARC_ActiveMember__c) {
                    if (contract.vlocity_ins__EnrollmentCensusId__c == member.vlocity_ins__CensusId__c) {

                        if (member.vlocity_ins__IsPrimaryMember__c) {
                            primary++;
                        }else
                        if (member.vlocity_ins__IsSpouse__c) {
                            spouse++;
                        }else
                        if (member.ARC_DependentRelationship__c == 'Child') {
                            children++;
                        }

                    }
                }

            }
            
            if (primary + spouse + children == 1) {
                familyType = '2';
            } else {
                familyType = '1';
            }
            
            types.put(contract.vlocity_ins__EnrollmentCensusId__c, familyType);
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

    private Map<Id, String> memberCodesSSN(List<Contract> contracts, List<vlocity_ins__GroupCensusMember__c> members) {
        Map<Id, Map<Id, Integer>> contractmemberCodes = getCurrentMemberCodes(contracts,members);
        Map<Id, Integer> contractLastMemberCode = getContractLastMemberCode(contracts,members);
        Map<Id, String> stringMemberCodes = new Map<Id, String>();
        for (Contract contract: contracts) {
            Integer memberCode = contractLastMemberCode.get(contract.Id) + 1;
            for (vlocity_ins__GroupCensusMember__c member: members) {
                if (contract.vlocity_ins__EnrollmentCensusId__c == member.vlocity_ins__CensusId__c) {
                    
                    if (contractmemberCodes.get(contract.Id).get(member.Id) != null) { //if member already has code
                        stringMemberCodes.put(member.Id, formatMemberCode(contractmemberCodes.get(contract.Id).get(member.Id)));
                    }else { //if not
                        if (contractLastMemberCode.get(contract.Id)==0) { //if there aren't members with member code assigned
                            if (member.vlocity_ins__IsPrimaryMember__c) {
                                stringMemberCodes.put(member.Id, '01');
                                member.ARC_HAXFamilySequenceNumber__c = 1;
                            }
                            if (member.vlocity_ins__IsSpouse__c) {
                                stringMemberCodes.put(member.Id, '02');
                                member.ARC_HAXFamilySequenceNumber__c = 2;
                            }
                            if (member.ARC_DependentRelationship__c=='Child') {
                                if (memberCode<3) {
                                    memberCode = 3;
                                }
                                stringMemberCodes.put(member.Id, formatMemberCode(memberCode));
                                memberCode++;
                            }
                        }else { //if there are members with member code assigned
                            if (member.vlocity_ins__IsSpouse__c && !contractmemberCodes.get(contract.Id).values().contains(2)) { //if the number 2 (reserved for the spouse) is already assigned
                                stringMemberCodes.put(member.Id, '02');
                                member.ARC_HAXFamilySequenceNumber__c = 2;
                            }else {
                                if (memberCode<3) {
                                    memberCode = 3;
                                }
                                stringMemberCodes.put(member.Id, formatMemberCode(memberCode));
                                member.ARC_HAXFamilySequenceNumber__c = memberCode;
                                memberCode ++;
                            }
                        }
                        membersToUpdate.add(member);
                    }
                }
            }
        }
        // update membersToUpdate;

        return stringMemberCodes;
    }

    private String formatMemberCode(Integer memberCode){
        return String.valueOf(memberCode).length()==1 ? '0'+String.valueOf(memberCode) : String.valueOf(memberCode);
    }

    private Map<Id, Integer> getContractLastMemberCode(List<Contract> contracts, List<vlocity_ins__GroupCensusMember__c> members){
        Map<Id, Integer> contractLastMemberCode = new Map<Id, Integer>();
        for (Contract contract: contracts) {
            Integer lastMemberCode = 0;
            for (vlocity_ins__GroupCensusMember__c member: members) {
                if (contract.vlocity_ins__EnrollmentCensusId__c == member.vlocity_ins__CensusId__c) {
                    if (member.ARC_HAXFamilySequenceNumber__c != null) {
                        if (member.ARC_HAXFamilySequenceNumber__c > lastMemberCode) {
                            lastMemberCode = Integer.valueOf(member.ARC_HAXFamilySequenceNumber__c);
                        }
                    }
                }
            }
            contractLastMemberCode.put(contract.Id, lastMemberCode);
        }
        return contractLastMemberCode;
    }

    private Map<Id, Map<Id, Integer>> getCurrentMemberCodes(List<Contract> contracts, List<vlocity_ins__GroupCensusMember__c> members){
        Map<Id, Map<Id, Integer>> contractMemberCode = new Map<Id, Map<Id, Integer>>();
        for (Contract contract: contracts) {
            Map<Id, Integer> memberCode = new Map<Id, Integer>();
            for (vlocity_ins__GroupCensusMember__c member: members) {
                if (contract.vlocity_ins__EnrollmentCensusId__c == member.vlocity_ins__CensusId__c) {
                    if (member.ARC_HAXFamilySequenceNumber__c != null) {
                        memberCode.put(member.Id, Integer.valueOf(member.ARC_HAXFamilySequenceNumber__c));
                    }
                }
            }
            contractMemberCode.put(contract.Id, memberCode);
        }
        return contractMemberCode;
    }

    private Map<Id, String> productCodes(
        List<Contract> contracts,
        List<vlocity_ins__ContractLineItem__c> contractLineItems) {
        
        Map<Id, String> productCodes = new Map<Id, String>();
        
        for (Contract contract: contracts) {
            for (vlocity_ins__ContractLineItem__c contractLineItem: contractLineItems) {
                if (contract.Id == 
                    contractLineItem.vlocity_ins__ContractId__c) {

                    productCodes.put(
                        contract.vlocity_ins__EnrollmentCensusId__c, 
                        contractLineItem.vlocity_ins__Product2Id__r.ProductCode
                    );

                    break;
                }
            }
        }
        return productCodes;
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

    private List<Id> getGroupCensusIds(List<vlocity_ins__GroupCensusMember__c> groupCensusMembersList) {
        List<Id> groupCensusMembersIds = new List<Id>();
        for (vlocity_ins__GroupCensusMember__c groupCensusMember: groupCensusMembersList) {
            if (groupCensusMember.ARC_ActiveMember__c) {
                groupCensusMembersIds.add(groupCensusMember.vlocity_ins__CensusId__c);
            }
        }
        return groupCensusMembersIds;
    }

    public ARC_CVSElegibilityFileBatch() {

        if ([SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox || sendFilesToTestSites) {
            fileName = 'UHSS.TST' + getMMDD();
        }else {
            fileName = 'UHSS.MBR' + getMMDD();
        }

        txtLines = new List<String>();
        isFirst = true;

        groupCensusMemberFields = new List<String>{
            'Id',
            'ARC_ActiveMember__c',
            'vlocity_ins__CensusId__c',
            'vlocity_ins__IsPrimaryMember__c',
            'vlocity_ins__IsSpouse__c',
            'ARC_DependentRelationship__c',
            'e123_member_id__c',
            'Member_ID__c',
            'vlocity_ins__LastName__c',
            'vlocity_ins__FirstName__c',
            'ARC_MiddleInitial__c',
            'vlocity_ins__Gender__c',
            'vlocity_ins__Birthdate__c',
            'vlocity_ins__SocialSecurityNumber__c',
            'ARC_PhysicalAddressStreet__c',
            'ARC_PhysicalAddressCity__c',
            'ARC_PhysicalAddressState__c',
            'ARC_PhysicalAddressZipCode__c',
            'ARC_Phone__c',
            'ARC_HAXFamilySequenceNumber__c',
            'vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__SocialSecurityNumber__c',
            'vlocity_ins__RelatedCensusMemberId__r.Member_ID__c',
            'vlocity_ins__RelatedCensusMemberId__r.e123_member_id__c',
            'vlocity_ins__RelatedCensusMemberId__r.vlocity_ins__CensusId__c'
        };

        contractFields = new List<String>{
            'vlocity_ins__EnrollmentCensusId__c',
            'ARC_EffectiveDate__c',
            'vlocity_ins__EnrollmentEndDate__c'
        };
    }
    


    global Database.QueryLocator start(Database.BatchableContext BC ) {
        String query = '' + 
            'SELECT Id, ' + String.join(contractFields, ',') + ' ' +
            'FROM Contract ' +
            'WHERE '+
            'Status = \'Activated\' ' +
            'AND ARC_MedicalPlan__r.vlocity_ins__ProductCode__c != \'PROG_WeShareLegacy\' ' +
            'ORDER BY createdDate DESC '+ 
            'LIMIT '+limitRecords;
        
        Integer totalRecords = [SELECT COUNT() FROM Contract WHERE Status = 'Activated' LIMIT: limitRecords];
        this.totalBatches =Integer.valueOf(Math.ceil(totalRecords /10));

        return Database.getQueryLocator(query);
    }
    
    private List<Id> getContractEnrollmentCensusId(List<Contract> contracts) {
        List<Id> contractEnrollmentCensusId = new List<Id>();
        for (Contract contract: contracts) {
            contractEnrollmentCensusId.add(contract.vlocity_ins__EnrollmentCensusId__c);
        }
        return contractEnrollmentCensusId;
    }

    private Map<Id, String> firstActive(
        List<ContractHistory> contractHistories, 
        List<Contract> allContracts
        ) {
        Map<Id, String> firstActive = new Map<Id, String>();
        for (Contract contract: allContracts) {
            if (contract.Status == 'Activated') {
                for (ContractHistory contractHistory: contractHistories) {
                    Id censusId = contract.vlocity_ins__EnrollmentCensusId__c;
                    if (firstActive.get(censusId) == null) {
                        firstActive.put(censusId, getCYYMMDDDate(contractHistory.CreatedDate));
                    }
                }
            }
        }
        return firstActive;
    }

    private Map<Id, String> nextProgramChange(
        List<Contract> allContracts
        ) {
        Map<Id, String> nextProgramChange = new Map<Id, String>();
        for (Contract contract: allContracts) {
            if (contract.Status == 'Awaiting Activation') {
                Id censusId = contract.vlocity_ins__EnrollmentCensusId__c;
                if (nextProgramChange.get(censusId) == null) {
                    nextProgramChange.put(censusId, getCYYMMDDDate(contract.ARC_EffectiveDate__c));
                }
            }
        }
        return nextProgramChange;
    }

    private void generateFromContract(
        vlocity_ins__GroupCensusMember__c groupCensusMember, 
        List<Contract> contractsList, 
        Map<Id, String> nextProgramChange,
        Map<String, String> lineMap) {
        for (Contract contract: contractsList) {
            if (contract.vlocity_ins__EnrollmentCensusId__c == groupCensusMember.vlocity_ins__CensusId__c) {
                // addColumn('ContractSfId', deleteSpaces(contract.Id), lineMap);
                if (contract.ARC_EffectiveDate__c != null) {
                    addColumn('EffectiveDate', getCYYMMDDDate(contract.ARC_EffectiveDate__c), lineMap, 3);
                }
                if (contract.vlocity_ins__EnrollmentEndDate__c != null) {
                    addColumn('TerminationDate', getCYYMMDDDate(contract.vlocity_ins__EnrollmentEndDate__c), lineMap, 3);
                }else {
                    if (nextProgramChange.get(contract.vlocity_ins__EnrollmentCensusId__c) != null) {
                        addColumn('TerminationDate', nextProgramChange.get(contract.vlocity_ins__EnrollmentCensusId__c), lineMap, 3);
                    }
                }
                if (contract.ARC_EffectiveDate__c != null) {
                    if (contract.ARC_EffectiveDate__c.daysBetween(System.today()) <= 60) {
                        addColumn('GracePeriodInd', 'Y', lineMap, 3);
                        addColumn('Group', 'GEN', lineMap, 3);
                    } else {
                        addColumn('GracePeriodInd', 'N', lineMap, 3);
                        addColumn('Group', 'ADV', lineMap, 3);
                    }
                }
                if (contract.ARC_EffectiveDate__c != null) {
                    addColumn('GracePeriodEffDate', getCYYMMDDDate(contract.ARC_EffectiveDate__c.addDays(60)), lineMap, 3);
                }
                break;
            }
        }
        if (lineMap.get('Group') == null) {
            addColumn('Group', 'GroupNull', lineMap, 3);
        } else {
            if (lineMap.get('Group') == '') {
                addColumn('Group', 'GroupEmpty', lineMap, 3);
            }
        }
    }

    private void generateFromFamilyType(
        vlocity_ins__GroupCensusMember__c groupCensusMember, 
        List<Contract> contractsList, 
        Map<String, String> lineMap, 
        Map<Id, String> familyTypes) {
        for (Contract contract: contractsList) {
            if (contract.vlocity_ins__EnrollmentCensusId__c == groupCensusMember.vlocity_ins__CensusId__c) {
                addColumn('FamilyType', familyTypes.get(contract.vlocity_ins__EnrollmentCensusId__c), lineMap,3);
            }
        }
    }
    
    private void generateFromProductCodes(
        vlocity_ins__GroupCensusMember__c groupCensusMember, 
        List<Contract> contractsList, 
        Map<String, String> lineMap, 
        Map<Id, String> productCodes//,
        ) {
        for (Contract contract: contractsList) {
            if (contract.vlocity_ins__EnrollmentCensusId__c == groupCensusMember.vlocity_ins__CensusId__c) {
                if (productCodes.get(contract.vlocity_ins__EnrollmentCensusId__c) != null) {
                    if (productCodes.get(contract.vlocity_ins__EnrollmentCensusId__c).startsWith('PROG_UHSM_WeShare')) {
                        addColumn('Group', 'ADV', lineMap,3);
                    }
                }
                addColumn('Account', getAccount(productCodes.get(contract.vlocity_ins__EnrollmentCensusId__c)), lineMap,3);
            }
        }
    }

    private Map<Id, String> multiBirth(
        List<Contract> contracts, 
        List<vlocity_ins__GroupCensusMember__c> groupCensusMembersList) {

            Map<Id, Map<String, Integer>> aux = new Map<Id, Map<String, Integer>>();
            for (vlocity_ins__GroupCensusMember__c groupCensusMember: groupCensusMembersList) {
                if (groupCensusMember.ARC_ActiveMember__c) {
                    Map<String, Integer> dateQuantytyMap = aux.get(groupCensusMember.vlocity_ins__CensusId__c);
    
                    if (dateQuantytyMap == null) {
                        Map<String, Integer> mapToAdd = new Map<String, Integer>();
                        aux.put(groupCensusMember.vlocity_ins__CensusId__c, mapToAdd);
                        dateQuantytyMap = mapToAdd;
                    }
                    
                    if(groupCensusMember.vlocity_ins__Birthdate__c == null) {
                        continue;
                    }
                    Integer quantity = dateQuantytyMap.get(groupCensusMember.vlocity_ins__Birthdate__c.format());
    
                    if (quantity == null) {
                        dateQuantytyMap.put(groupCensusMember.vlocity_ins__Birthdate__c.format(), 0);
                        quantity = 0;
                    }
                    
                    dateQuantytyMap.put(groupCensusMember.vlocity_ins__Birthdate__c.format(), quantity + 1);    
                }

            }

            Map<Id, String> result = new Map<Id, String>();
            for (Id id: aux.keySet()) {
                Map<String, Integer> dateQuantity = aux.get(id);

                Integer max = 0;
                for (Integer quantity: dateQuantity.values()) {
                    if (max < quantity) {
                        max = quantity;
                    }
                }

                result.put(id, String.valueOf(max));
            }

            return result;
    }

    private void generateFromMultiBirth(
        vlocity_ins__GroupCensusMember__c groupCensusMember, 
        List<Contract> contractsList, 
        Map<String, String> lineMap, 
        Map<Id, String> multiBirth) {
        lineMap.put('MultiBirthCode', multiBirth.get(groupCensusMember.vlocity_ins__CensusId__c));
    }

    Integer activeMembersCount = 0;
    global void execute(Database.BatchableContext BC, List<Contract> contracts) {

        this.currentBatch ++; 

        try{
            List<Id> contractEnrollmentCensusId = getContractEnrollmentCensusId(contracts);
            List<vlocity_ins__GroupCensusMember__c> groupCensusMembersListNotFiltered = Database.query('' + 
                'SELECT ' + String.join(groupCensusMemberFields,', ') + ' ' +
                'FROM vlocity_ins__GroupCensusMember__c ' +
                'WHERE vlocity_ins__CensusId__c IN :contractEnrollmentCensusId ' +
                'ORDER BY vlocity_ins__Birthdate__c ASC'
            );


            List<vlocity_ins__ContractLineItem__c> contractLineItems = Database.query('' +
                'SELECT vlocity_ins__ContractId__c, vlocity_ins__Product2Id__r.ProductCode, vlocity_ins__Product2Id__r.ARC_CVSAccount__c ' +
                'FROM vlocity_ins__ContractLineItem__c ' + 
                'WHERE vlocity_ins__ProductType__c = \'Medical\' ' +
                'AND vlocity_ins__RecordTypeName__c = \'Product\' ' +
                'AND vlocity_ins__ContractId__c IN :contracts'
            );

            List<Contract> allContracts = Database.query('' +
                'SELECT Id, vlocity_ins__EnrollmentCensusId__c, ARC_EffectiveDate__c, Status ' +
                'FROM Contract ' +
                'WHERE vlocity_ins__EnrollmentCensusId__c IN :contractEnrollmentCensusId ' +
                'ORDER BY CreatedDate ASC'
            );

            List<ContractHistory> contractHistories = Database.query('' +
                'SELECT ContractId, CreatedDate, NewValue ' +
                'FROM ContractHistory ' +
                'WHERE ContractId IN :allContracts ' +
                'ORDER BY CreatedDate ASC'
            );

            List<vlocity_ins__GroupCensus__c> allCensus = Database.query('' +
                'SELECT Id, '+
                '(SELECT Id FROM vlocity_ins__EnrollmentContract__r ORDER BY CreatedDate ASC LIMIT 1) ' +
                'FROM vlocity_ins__GroupCensus__c ' +
                'WHERE Id IN :contractEnrollmentCensusId ' +
                'ORDER BY CreatedDate ASC'
            );

            Map<Id, String> familyTypes = familyType(contracts, groupCensusMembersListNotFiltered);
            Map<Id, String> productCodes = productCodes(contracts, contractLineItems);
            Map<Id, String> nextProgramChange = nextProgramChange(allContracts);
            Map<Id, String> firstActive = firstActive(contractHistories, allContracts);
            Map<Id, String> multiBirth = multiBirth(contracts, groupCensusMembersListNotFiltered);
            Map <Id, String> memberCodeSSN = memberCodesSSN(contracts,groupCensusMembersListNotFiltered);
            Map <Id, String> censusFirstPolicyNumbers = censusFirstPolicyNumber(allCensus);
            
            for (vlocity_ins__GroupCensusMember__c groupCensusMember: groupCensusMembersListNotFiltered) {
                if (groupCensusMember.ARC_ActiveMember__c) {
                    activeMembersCount++;
                    Map <String, String> newLineMap = initLineMap(3);

                    generateFromGroupCensusMember(groupCensusMember, newLineMap, memberCodeSSN,censusFirstPolicyNumbers);
                    generateFromContract(groupCensusMember, contracts, nextProgramChange, newLineMap);
                    
                    generateFromFamilyType(groupCensusMember, contracts, newLineMap, familyTypes);
                    generateFromProductCodes(groupCensusMember, contracts, newLineMap, productCodes); 

                    txtLines.add(generateStringFromMap(newLineMap));
                    memberCount++;
                }
            }
    
            if ( 
                memberCount > sendFileEachNMembers || 
                Limits.getHeapSize() > Limits.getLimitHeapSize() * 0.4 
            ) {            
                    sendFile(false);
                    memberCount = 0;
        }
        }catch(Exception e){
            String apexErrorEmail = System.Label.ARC_ApexErrorEmail;
            ARC_QueableSendFileBatch.sendEmailNotification(('Error in CVS FILE BATCH Execute: '+e.getMessage()), 'ERROR in CVS ELIGIBILITY FILE BATCH on the '+Date.today(), apexErrorEmail);
        }
         

        // if (
        //     currentBatch == totalBatches
        // ) {
        //     sendFile(true);
        // }
    }

    private Map<Id, String> censusFirstPolicyNumber(List<vlocity_ins__GroupCensus__c> censuses){
        Set<String> contractIds = new Set<String>();
        Map<Id, String> censusFirstPolicyNumbers = new Map<Id, String>();

        for(vlocity_ins__GroupCensus__c census : censuses){
            contractIds.add(census.vlocity_ins__EnrollmentContract__r[0].Id);
        }
        List<InsurancePolicy> policies = [SELECT Id, Name, ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c FROM InsurancePolicy WHERE ARC_Contract__c IN :contractIds];
        for(InsurancePolicy policy : policies){    
            censusFirstPolicyNumbers.put(policy.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c, policy.Name);
        }

        return censusFirstPolicyNumbers;
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

    private String cleanLine(String line) {
        String[] columns = line.split(delimiter);
        for (Integer i=0; i<columns.size(); i++) {
            String result = columns[i];
            columns[i] = result;
        }
        return String.join(columns, delimiter);
    }

    private String cleanFile(String file) {
        String[] lines = file.split(endRecord);
        for (Integer i=0; i<lines.size(); i++) {
            lines[i] = cleanLine(lines[i]);
        }
        return String.join(lines, endRecord);
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
        addColumn('TotalRecords', completeWithZeros(totalRows, getColumnLenght('TotalRecords', 9)), newLineMap,9);
        // addColumn('TotalChanges', completeWithZeros(getTotalChanges(fileString), getColumnLenght('TotalChanges', 9)), newLineMap,9);
        return newLineMap;
    }

    private Integer getTotalRecords(String fileString){
        return fileString.split(endRecord).size();
    }
    private Integer getTotalChanges(String fileString){
        return getTotalRecords(fileString)-1;
    }

    global void finish(Database.BatchableContext BC ) {
        sendFile(true);
        update membersToUpdate;
        membersToUpdate.clear();        
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
            System.enqueueJob(new ARC_QueableSendFileBatch(
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

    @InvocableMethod(label='Run CVS File Batch' description='Runs the CVS File Batch' category='Elegibility Files')
    global static void runCVSBatch(){
        ARC_CVSElegibilityFileBatch a = new ARC_CVSElegibilityFileBatch();
        //a.sendFilesToTestSites = true;
        //a.limitRecords = 100;
        a.sendFileEachNMembers = 500;
        Database.executeBatch(a,10);
    }
}