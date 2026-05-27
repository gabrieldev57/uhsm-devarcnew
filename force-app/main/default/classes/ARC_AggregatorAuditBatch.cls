global class ARC_AggregatorAuditBatch implements Database.Batchable<sObject>, Database.Stateful {

    private Boolean runUpdate = false;
    private String condition;
    // Holds flagged results between executions
    List<String> reportLines = new List<String>();
    List<Id> aggregatorsExceedingLimits = new List<Id>();

    // // Define years to include
    // Set<String> yearsToCompare = new Set<String>{'2021', '2022', '2023', '2024', '2025'};
    // // Date batchStartDate = Date.newInstance(2024, 11, 4);
    // Date batchStartDate = Date.newInstance(2020, 1, 1);

    private static final Integer LIMIT_TIER_1 = 15000;
    private static final Integer LIMIT_TIER_2 = 25000;
    private static final Integer LIMIT_TIER_3 = 50000;
    private static final Integer LIMIT_MAX = 99999999;
    private static final List<Decimal> LIST_PROGRESSION_LIMITS = new List<Decimal>{LIMIT_TIER_1, LIMIT_TIER_2, LIMIT_TIER_3, LIMIT_MAX};

    public ARC_AggregatorAuditBatch(String condition, Boolean runUpdate) {
        this.runUpdate = runUpdate;
        this.condition = condition;
    }
    
    // Map<Id AccountId, List<DateRange>>
    Map<Id, List<Date[]>> memberCoveragePeriods = new Map<Id, List<Date[]>>();

    global Database.QueryLocator start(Database.BatchableContext context) {
        String query = 'SELECT Id, ARC_Code__c, ARC_Year__c, ARC_LimitValue__c, ARC_Member__c, LastModifiedDate, ARC_Member__r.Name, ARC_CreatedIn__r.ARC_EffectiveDate__c,'
                            + 'ARC_BY1_Date__c,'
                            + 'ARC_BY1_Current__c,'
                            + 'ARC_BY1_Limit__c,'
                            + 'ARC_BY2_Date__c,'
                            + 'ARC_BY2_Current__c,'
                            + 'ARC_BY2_Limit__c,'
                            + 'ARC_BY3_Date__c,'
                            + 'ARC_BY3_Current__c,'
                            + 'ARC_BY3_Limit__c,'
                            + 'ARC_CurrentValue__c'
            +' FROM ARC_Aggregator__c'
            +' WHERE ARC_Code__c IN (\'PREEX__c\', \'MAT__c\') ';
        if(condition != null ){
            query += 'AND ' + condition;
        }
        query += ' ORDER BY ARC_Member__c, ARC_Code__c, ARC_Year__c';

        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext context, List<ARC_Aggregator__c> aggregators) {
        List<ARC_Aggregator__c> aggregatorsToUpdate = new List<ARC_Aggregator__c>();
        
        // // Preload member anniversary map
        preloadCoveragePeriods(aggregators);
        // System.debug('------------ coverage periods --------------');
        // System.debug(memberCoveragePeriods);

        // KEY : Date|Member 
        // Value: aggs list 
        Map<String, List<ARC_Aggregator__c>> preexAggsMap = new Map<String, List<ARC_Aggregator__c>>(); 

        for (ARC_Aggregator__c agg : aggregators) {
            if (String.isBlank(agg.ARC_Year__c) || agg.ARC_Member__c == null) continue;
            // System.debug(' ------ ------ ------ ------ ------ ------ ------ ');
            // System.debug(' ------ ------ ------ ------ ------ ------ ------ ');
            // System.debug('Code: ' + agg.ARC_Code__c);
            // System.debug('Year: ' + agg.ARC_Year__c);
            // System.debug('member Name: ' + agg.ARC_Member__r.Name);

            Integer year;
            try {
                year = Integer.valueOf(agg.ARC_Year__c);
            } catch (Exception e) {
                continue;
            }
            Date aggEffDate = agg.ARC_CreatedIn__r.ARC_EffectiveDate__c;
            Date[] aggRange = coverageRange(agg.ARC_Member__c, year, aggEffDate); 
            // System.debug('Aggregator Range: ' + aggRange);
            if (aggRange == null) continue;

            Date contCoverageDate = aggRange[0]; // ranges are based on the appropriate date for newborn cases
            // generate key Date|Member para preexAggsMap
            String rangeMemberKey = contCoverageDate + '|' + agg.ARC_Member__c;
            // System.debug('rangeMemberKey: ' + rangeMemberKey);
            Integer continuousYears = calculateContinuousYears(agg.ARC_Member__c, year, contCoverageDate, aggRange);
            // System.debug('continuousYears : ' + continuousYears);
            if (agg.ARC_Code__c == 'MAT__c') {
                Decimal expectedLimit;
                expectedLimit = getExpectedMatLimit(continuousYears); // 1 year progression
                // // System.debug('Current Limit : ' + agg.ARC_LimitValue__c);
                // // System.debug('Expected Limit : ' + expectedLimit);
                if (expectedLimit != null && agg.ARC_LimitValue__c != expectedLimit) {
                    reportLines.add(formatLine(agg, continuousYears, expectedLimit));
                    aggregatorsToUpdate.add(fixMaternityAggregator(agg, expectedLimit));
                }
            } else if (agg.ARC_Code__c == 'PREEX__c') {
                // List<ARC_Aggregator__c> preexAggsList = preexAggsMap.containsKey(rangeMemberKey) ? preexAggsMap.get(rangeMemberKey) : null;
                Map<String, Object> expectedValues = getExpectedPreexLimit(continuousYears, contCoverageDate);
                // System.debug('Current Limit : ' + agg);
                // System.debug('Expected Values: ' + expectedValues);
                if (expectedValues.get('aggLimit') != null && agg.ARC_LimitValue__c != (Decimal)expectedValues.get('aggLimit')
                    || agg.ARC_BY1_Limit__c != (Decimal)expectedValues.get('BY1_Limit')
                    || agg.ARC_BY2_Limit__c != (Decimal)expectedValues.get('BY2_Limit')
                    || agg.ARC_BY3_Limit__c != (Decimal)expectedValues.get('BY3_Limit')
                    || agg.ARC_BY1_Date__c != (Date)expectedValues.get('BY1_Date')
                    || agg.ARC_BY2_Date__c != (Date)expectedValues.get('BY2_Date')
                    || agg.ARC_BY3_Date__c != (Date)expectedValues.get('BY3_Date') ){
                    reportLines.add(formatLine(agg, continuousYears, (Decimal)expectedValues.get('aggLimit')));
                    aggregatorsToUpdate.add(fixPreexAggregator(agg, (Decimal)expectedValues.get('aggLimit'), contCoverageDate));
                }
                
                if(!preexAggsMap.containsKey(rangeMemberKey)){
                    preexAggsMap.put(rangeMemberKey, new List<ARC_Aggregator__c>());
                }
                preexAggsMap.get(rangeMemberKey).add(agg);
            }
        }
        // System.debug('---------------------------- RUN UPDATE: ' + runUpdate);
        // System.debug('----------------------------AGGREGATORS TO UPDATE----------------------------');
        List<ARC_Aggregator__c> remainingAggregators = new List<ARC_Aggregator__c>();
        for (ARC_Aggregator__c agg : aggregatorsToUpdate) {
            if (agg.ARC_CurrentValue__c > agg.ARC_LimitValue__c) {
                aggregatorsExceedingLimits.add(agg.Id);
            } else {
                remainingAggregators.add(agg);
                // System.debug(agg);
            }
        }

        if(runUpdate){
            update remainingAggregators;
        }
    }

    global void finish(Database.BatchableContext context) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { 'ignacio.ferreiro@arcsona.com' });

        if (reportLines.isEmpty()) {
            mail.setSubject('Aggregator Audit Completed - No Issues Found');
            mail.setPlainTextBody('The audit completed and found no invalid aggregators.');
        } else {

            List<String> csvLines = new List<String>();
            csvLines.add('AggregatorID\tYear\tCode\tMember\tLimit\tCoverageYears\tExpected');
            for (String line : reportLines) {
            // System.debug(line);
            line = line.remove('\n');
            List<String> parts = line.split(' - ');
            // System.debug(parts);

            String aggId = parts.size() > 0 ? parts[0].replace('Aggregator Id: ', '') : '';
            String year = parts.size() > 1 ? parts[1].replace('Year: ', '') : '';
            String code = parts.size() > 2 ? parts[2].replace('Code: ', '') : '';
            String memb = parts.size() > 3 ? parts[3].replace('Member: ', '') : '';
            String lim = parts.size() > 4 ? parts[4].replace('Limit: ', '') : '';
            String covy = parts.size() > 5 ? parts[5].replace('Coverage Years: ', '') : '';
            String exp = parts.size() > 6 ? parts[6].replace('Expected: ', '') : '';

            csvLines.add(aggId + '\t' + year + '\t' + code + '\t' + memb + '\t' + lim + '\t' + covy + '\t' + exp);
            }

            String csvContent = String.join(csvLines, '\n');
            Blob csvBlob = Blob.valueOf(csvContent);

            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName('Wrong Preex-Mat.xls');
            attachment.setBody(csvBlob);
            attachment.setContentType('application/vnd.ms-excel');

            
            String body = 'The following aggregators were flagged:\n\n';
            body += 'Attached you will find the processed records report (' + reportLines.size() + ').';
            body += String.join(reportLines, '\n');
            body += '\n\nAggregators exceeding Limits:\n';
            body += String.join(aggregatorsExceedingLimits, '\n');

            mail.setSubject('Aggregator Audit Report - Issues Found');
            mail.setPlainTextBody(body);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
        }

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    //////////////////////////////////////////////////////////////////////////
    /////////////////// AUXILIARY METHODS ////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////

    private void preloadCoveragePeriods(List<ARC_Aggregator__c> aggregators) {
        Set<Id> accountIds = new Set<Id>();
        for (ARC_Aggregator__c agg : aggregators) {
            if (agg.ARC_Member__c != null) {
                accountIds.add(agg.ARC_Member__c);
            }
        }

        List<ARC_ContractParticipant__c> plans = [
            SELECT Id, ARC_PersonAccount__c, 
                ARC_Contract__c,
                ARC_Contract__r.ARC_EffectiveDate__c,
                ARC_Contract__r.ARC_Inactive_Date__c,
                ARC_Contract__r.ARC_ContractReason__c,
                ARC_PersonAccount__r.PersonBirthdate,
                ARC_Contract__r.ARC_AwaitingActivationDate__c
            FROM ARC_ContractParticipant__c 
            WHERE ARC_PersonAccount__c IN :accountIds
                AND ARC_Contract__r.Status IN ('Activated', 'Terminated')
                AND ARC_Contract__r.ARC_EffectiveDate__c != NULL
                AND ARC_Contract__r.ARC_MedicalPlan__r.Name LIKE '%WeShare%'
            ORDER BY ARC_PersonAccount__c, ARC_Contract__r.ARC_EffectiveDate__c, ARC_Contract__r.CreatedDate
        ];

        // Paso 1: agrupar todos los rangos por AccountId
        Map<Id, List<Map<String, Object>>> rawRanges = new Map<Id, List<Map<String, Object>>>();

        for (ARC_ContractParticipant__c p : plans) {
            Id accId = p.ARC_PersonAccount__c;

            Date startDate = p.ARC_Contract__r.ARC_EffectiveDate__c;
            Date endDate = p.ARC_Contract__r.ARC_Inactive_Date__c != null 
                ? p.ARC_Contract__r.ARC_Inactive_Date__c 
                : Date.today();
            Boolean isUpgrade = p.ARC_Contract__r.ARC_ContractReason__c.contains('Program Upgrade');
            
            if (accId == null || startDate == null) continue;
            
            if (!rawRanges.containsKey(accId)) {
                Boolean isNewborn = p.ARC_Contract__r.ARC_ContractReason__c.contains('Add Newborn');
                // fix newborn start day at the beggining of its firt plan : if newborn, coverage starts from DOB 
                // GCMP ordered by effDate => first contract for a member is its initial contract
                // => => **first contract is its initial coverage period**
                // => if member is newborn, take its DOB as startDate - if member is newborn its first contract is reason Add Newborn  
                if(isNewborn){
                    // Fix for manual changes where Add Newborn is not the only contract reason.  
                    // if Add Newborn is the first contract for many members, the true newbon's birthdate is always > effDate (inherited from previous contract)
                    startDate = p.ARC_PersonAccount__r.PersonBirthdate > p.ARC_Contract__r.ARC_EffectiveDate__c ? p.ARC_PersonAccount__r.PersonBirthdate : p.ARC_Contract__r.ARC_EffectiveDate__c;
                }
                rawRanges.put(accId, new List<Map<String, Object>>());
            }

             rawRanges.get(accId).add(new Map<String, Object>{
                'start' => startDate,
                'end' => endDate,
                'upgrade' => isUpgrade
            });
        }

        // Paso 2: unir rangos continuos por AccountId
        for (Id accId : rawRanges.keySet()) {
            List<Map<String, Object>> ranges = rawRanges.get(accId);
            ranges.sort(new RangeComparator()); // ordenar por fecha de inicio
            // System.debug('----------RANGES----------');
            for(Map<String, Object> entry : ranges){

                // System.debug('[');
                // System.debug('start: ' + entry.get('start'));
                // System.debug('end: ' + entry.get('end'));
                // System.debug('upgrade: ' + entry.get('upgrade'));
                // System.debug(']');
            }
            List<Date[]> merged = new List<Date[]>();
            Date currentStart = null;
            Date currentEnd = null;

            for (Map<String, Object> entry : ranges) {
                // // System.debug('r[0] => ' + r[0]);
                // // System.debug('r[1] => ' + r[1]);
                Date entryStart = (Date)entry.get('start');
                Date entryEnd = (Date)entry.get('end');
                Boolean isUpgrade = (Boolean)entry.get('upgrade');
                
                if (currentStart == null) {
                    currentStart = entryStart;
                    currentEnd = entryEnd;
                    continue;
                }
                
                // unir si:
                // Se solapan o están consecutivas (sin gap de más de 1 día),
                // el periodo no es el inicio de un program upgrade,
                if (isUpgrade || entryStart > currentEnd.addDays(1)) {
                    merged.add(new Date[]{currentStart, currentEnd});
                    currentStart = entryStart;
                    currentEnd = entryEnd;
                } else {
                    currentEnd = entryEnd > currentEnd ? entryEnd : currentEnd;
                }
            }

            if (currentStart != null && currentEnd != null) {
                merged.add(new Date[]{currentStart, currentEnd});
            }

            memberCoveragePeriods.put(accId, merged);
        }
    }


    private Date[] coverageRange(Id accId, Integer year, Date aggEffDate) {
        // System.debug('----coverageRange Agg Year: ' + year);
        // System.debug('----coverageRange Agg EffDate: ' + aggEffDate);
        if (!memberCoveragePeriods.containsKey(accId)) return null;

        List<Date[]> coverageRanges = memberCoveragePeriods.get(accId);
        Date[] fallbackRange = null;

        for (Date[] range : coverageRanges) {
            Boolean yearMatches = range[0].year() <= year && range[1].year() >= year;
            // System.debug(' - period: ' + range + ' -' + yearMatches);

            if (yearMatches) {
                // Si además la effDate está dentro del rango, usamos ese
                if (aggEffDate >= range[0] && aggEffDate <= range[1]) {
                    // System.debug('((FOUND MATCH)) : ' + range);
                    return range;
                }
                // Guardamos como posible fallback si no hay match por effDate
                if (fallbackRange == null && aggEffDate <= range[0] ) {
                    fallbackRange = range;
                }
            }
        }
        // System.debug('((FALLBACK MATCH)) : ' + fallbackRange);
        
        return fallbackRange;
    }   


    private Integer calculateContinuousYears(Id accId, Integer upToYear, Date lastCoverageStartDate, Date[] aggRange) {
        // System.debug('---CALCULATE CONTINUITY YEARS---');
        if (!memberCoveragePeriods.containsKey(accId)) return 0; // found an agg that does not belong to a coverage period for the member
        
        Date[] range = aggRange;
        // System.debug('range: ' + range);
        Integer startYear = range[0].year();
        Integer endYear = range[1].year();

        // TODO : 
        // period anniversary does not match with range start date when member is newborn/add member => Takes lastCoverageStartDate
        // member is nb or add member? => lastCoverageStartDate
        // else => range
        Date periodAniversary = endYear==Date.today().year() ? Date.newInstance(upToYear, lastCoverageStartDate.month(), lastCoverageStartDate.day()) : Date.newInstance(upToYear, range[0].month(), range[0].day()); 
        
        // System.debug('periodAniversary: ' +periodAniversary);
        // is last aggregator for the period
        if(endYear == upToYear && range[1] < periodAniversary) {
            // System.debug('+++RANGE 1: ' + range[1]);
            // System.debug('+++periodAniversary: ' + periodAniversary);
            return upToYear - startYear - 1 >= 0 ? upToYear - startYear - 1 : 0;        
        }
        return upToYear - startYear;
        
    }
    
    private Decimal getExpectedMatLimit(Integer years) {
        // System.debug('Expected limit for ' + years + ' years: ');
        if (years < 0) return null;
        // For maternity, increase to max amount after 2 years
        // not update for year 0 and year 1
        Integer yearsFromInitialUpdate =  years- 1 >= 0 ? years - 1 : 0;
        // System.debug('Years to update: ' + yearsFromInitialUpdate);
        return yearsFromInitialUpdate <= 0 ? LIMIT_TIER_1 : LIMIT_MAX;
    }
    
    private Map<String, Object> getExpectedPreexLimit(Integer years, Date contCoverageDate) {
        // System.debug('Expected limit for ' + years + ' years: ');
        if (years < 0) return null;
        Map<String, Object> result = new Map<String, Object>();
        Decimal aggLimit = years < LIST_PROGRESSION_LIMITS.size() ? LIST_PROGRESSION_LIMITS[ years ] : LIMIT_MAX;
        Decimal BY1_Limit;
        Decimal BY2_Limit;
        Decimal BY3_Limit;
        Date BY1_Date;
        Date BY2_Date;
        Date BY3_Date;

        if(years >= 1){
            BY1_Limit = LIST_PROGRESSION_LIMITS[0];
            BY1_Date = contCoverageDate.addYears(1);
        }

        if(years >= 2){
            BY2_Limit = LIST_PROGRESSION_LIMITS[1];
            BY2_Date = contCoverageDate.addYears(2);
        }
        
        if(years >= 3){
            BY3_Limit = LIST_PROGRESSION_LIMITS[3];
            BY3_Date = contCoverageDate.addYears(years);
        }

        result.put('aggLimit', aggLimit);
        result.put('BY1_Limit', BY1_Limit); 
        result.put('BY2_Limit', BY2_Limit);
        result.put('BY3_Limit', BY3_Limit);
        result.put('BY1_Date', BY1_Date);
        result.put('BY2_Date', BY2_Date); 
        result.put('BY3_Date', BY3_Date);

        return result;
    }

    private String formatLine(ARC_Aggregator__c agg, Integer years, Decimal expectedLimit) {
        // System.debug('--Needs to update.');
        return 'Aggregator Id: ' + agg.Id +
               ' - Year: ' + agg.ARC_Year__c +
               ' - Code: ' + agg.ARC_Code__c +
               ' - Member: ' + agg.ARC_Member__c +
               ' - Limit: ' + agg.ARC_LimitValue__c +
               ' - Coverage Years: ' + years +
               ' - Expected: ' + expectedLimit +
               '\n';
    }

    private ARC_Aggregator__c fixMaternityAggregator(ARC_Aggregator__c agg, Decimal limitToSet){
        // System.debug('--UPDATE MATERNITY AGGREGATOR');
        agg.ARC_LimitValue__c = limitToSet;
        // aggregatorsToUpdate.add(agg);        
        return agg;        
 
    }
    private ARC_Aggregator__c fixPreexAggregator(ARC_Aggregator__c agg, Decimal limitToSet, Date contCoverageDate){
        // System.debug('--UPDATE PREEX AGGREGATOR');
        updatePreExAggregatorLimit(agg, limitToSet, contCoverageDate);
        // System.debug('UPDATED VALUES: ');
        // System.debug('agg.ARC_LimitValue__c: ' + agg.ARC_LimitValue__c);
        // System.debug('agg.ARC_BY1_Limit__c: ' + agg.ARC_BY1_Limit__c);
        // System.debug('agg.ARC_BY1_Date__c: ' + agg.ARC_BY1_Date__c);
        // System.debug('agg.ARC_BY1_Current__c: ' + agg.ARC_BY1_Current__c);
        // System.debug('agg.ARC_BY2_Limit__c: ' + agg.ARC_BY2_Limit__c);
        // System.debug('agg.ARC_BY2_Date__c: ' + agg.ARC_BY2_Date__c);
        // System.debug('agg.ARC_BY2_Current__c: ' + agg.ARC_BY2_Current__c);
        // System.debug('agg.ARC_BY3_Limit__c: ' + agg.ARC_BY3_Limit__c);
        // System.debug('agg.ARC_BY3_Date__c: ' + agg.ARC_BY3_Date__c);
        // System.debug('agg.ARC_BY3_Current__c: ' + agg.ARC_BY3_Current__c);
        // aggregatorsToUpdate.add(agg);        
        return agg;        
 
    }

        // Update the limit value for pre-existing condition aggregators based on their current tier
    private void updatePreExAggregatorLimit(ARC_Aggregator__c aggregator, Decimal limitToSet, Date contCoverageDate) {
        // System.debug('UPDATE PREEX AGG:');
        // System.debug('----------lastPreexAgg Data:');
        // // System.debug('----------PreexAggsList: ' + preexAggsList);
        // System.debug('----------limitToSet: ' + limitToSet);
        // System.debug('----------contCoverageDate: ' + contCoverageDate);

        if (limitToSet == LIMIT_TIER_1) {
            increaseBenefitTierLimit(LIMIT_TIER_1, aggregator, contCoverageDate);
        } else if (limitToSet == LIMIT_TIER_2 ) {
            increaseBenefitTierLimit(LIMIT_TIER_2, aggregator, contCoverageDate);
        } else if (limitToSet == LIMIT_TIER_3 ) {
            increaseBenefitTierLimit(LIMIT_TIER_3, aggregator, contCoverageDate);
        } else if (limitToSet == LIMIT_MAX ) {
            increaseBenefitTierLimit(LIMIT_MAX, aggregator, contCoverageDate);
        }

    }

    private void increaseBenefitTierLimit(Integer newTier, ARC_Aggregator__c aggregator, Date contCoverageDate) {
       
        if (newTier == LIMIT_TIER_1) {
            aggregator.ARC_BY1_Limit__c = null; 
            aggregator.ARC_BY2_Limit__c = null;  
            aggregator.ARC_BY3_Limit__c = null;

            aggregator.ARC_LimitValue__c = LIMIT_TIER_1;
            
            aggregator.ARC_BY1_Date__c = null;
            aggregator.ARC_BY2_Date__c = null;
            aggregator.ARC_BY3_Date__c = null;

        } else if (newTier == LIMIT_TIER_2) {
            
            aggregator.ARC_BY1_Limit__c = LIMIT_TIER_1; 
            aggregator.ARC_BY2_Limit__c = null;  
            aggregator.ARC_BY3_Limit__c = null;
            
            aggregator.ARC_LimitValue__c = LIMIT_TIER_2;

            aggregator.ARC_BY1_Date__c = contCoverageDate.addYears(1);
            aggregator.ARC_BY2_Date__c = null;
            aggregator.ARC_BY3_Date__c = null;

        } else if (newTier == LIMIT_TIER_3) {
            aggregator.ARC_BY1_Limit__c = LIMIT_TIER_1;
            aggregator.ARC_BY2_Limit__c = LIMIT_TIER_2;
            aggregator.ARC_BY3_Limit__c = null;
            
            aggregator.ARC_LimitValue__c = LIMIT_TIER_3;
            
            aggregator.ARC_BY1_Date__c = contCoverageDate.addYears(1);
            aggregator.ARC_BY2_Date__c = contCoverageDate.addYears(2);
            aggregator.ARC_BY3_Date__c = null;
            
        } else if (newTier == LIMIT_MAX) {
            aggregator.ARC_BY1_Limit__c = LIMIT_TIER_1; 
            aggregator.ARC_BY2_Limit__c = LIMIT_TIER_2;  
            aggregator.ARC_BY3_Limit__c = LIMIT_TIER_3;

            aggregator.ARC_LimitValue__c = LIMIT_MAX;

            aggregator.ARC_BY1_Date__c = contCoverageDate.addYears(1);
            aggregator.ARC_BY2_Date__c = contCoverageDate.addYears(2);
            aggregator.ARC_BY3_Date__c = contCoverageDate.addYears(3);

        }
    }

    public class RangeComparator implements Comparator<Map<String,Object>>{
        
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            Date startA = Date.valueOf(a.get('start'));
            Date startB = Date.valueOf(b.get('start'));
            // System.debug('compare---------------');
            // System.debug('A: ' + startA);
            // System.debug('B: ' + startB);
            // System.debug('----> ' + startB.daysBetween(startA));

            return startB.daysBetween(startA);
        }
    }
}