/*******************************************************************
* @ClassName          :   ARC_SMBUtility
* @Description        :   Utility class for managing Non-calendar year aggregators (Maternity and Pre-Existing Conditions)
********************************************************************/
public without sharing class ARC_SMBUtility {
    // this is the year that Maternity stopped to be part of the Access programs
    private static final Integer HINGE_YEAR = 2026; 
    private static final Date TNB_IMPLEMENTATION_DATE = Date.newInstance(2024, 11, 3); // temporary newborn implementation date 
    private static final String REINSTATEMENT_TAG = 'Reinstatement'; // Reinstatement reason 
    private static final List<String> MERGEABLE_QLA_TAGS = new List<String>{'Family and Medical Leave (FMLA)', 'Military Leave', 'Leave of Absence'}; // Mergeable QLE picklist values 
        
/*******************************************************************
    * @MethodName         :   mapCoveragePeriods
    * @Description        :   Given a list of Account Ids, map their coverage periods from their contracts- 
                                queries Policy Participants and consolidates continuous periods that include (or not) the given aggregator
                                returns a map (key acc id) where for each account, value is the list of consolidated periods.
                                this output can be then used by the method calculateAggregators
    * @Update 2026/04/20  :   Update for SG: take contract reason for reinstatemens, upgrades and downgrades
********************************************************************/
    public static Map<Id, List<Map<String,Object>>> mapCoveragePeriods(List<Id> recordIds, String codeType) {
        System.debug('records: ' + recordIds);
        Map<Id, List<Map<String,Object>>> memberCoveragePeriods = new  Map<Id, List<Map<String,Object>>>(); // accId -> List<{USHMProgram: Boolean, dates: List[]Date}>

        if (!recordIds.isEmpty()) {

            List<Account> resultList = new List<Account>();
            List<InsurancePolicyParticipant> ippRelatedToEach;
            List<String> matAndPreex_ProductCodes = new List<String>();
            try {
                matAndPreex_ProductCodes = getMatPeexProductCodes(codeType);
                ippRelatedToEach = [
                    SELECT InsurancePolicy.ARC_Contract__r.ARC_EffectiveDate__c,
                        InsurancePolicy.ARC_Contract__r.ARC_Inactive_Date__c,
                        InsurancePolicy.ARC_EffectiveDate__c,
                        InsurancePolicy.ARC_ExpirationDate__c,
                        InsurancePolicy.RecordType.Name,
                        InsurancePolicy.ARC_Reason__c,
                        InsurancePolicy.ARC_QLEReason__c,
                        PrimaryParticipantContact.AccountId,
                        PrimaryParticipantContact.Name,
                        PrimaryParticipantContact.Account.PersonBirthdate,
                        PrimaryParticipantContact.CreatedDate,
                        (
                            SELECT ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode
                            FROM Coverage_Participants__r
                            WHERE ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.vlocity_ins__Type__c = 'Medical'
                                AND ARC_PolicyCoverage__r.ARC_ParentProduct__c = null
                        )
                    FROM InsurancePolicyParticipant
                    WHERE PrimaryParticipantContact.AccountId IN :recordIds
                        AND (
                            (
                                InsurancePolicy.RecordType.Name = 'Individual And Family'
                                AND (
                                    InsurancePolicy.ARC_Contract__r.Status IN ('Activated', 'Terminated', 'Awaiting Activation')
                                    AND InsurancePolicy.ARC_Contract__r.ARC_EffectiveDate__c <= TODAY
                                )
                            )
                            OR
                            (
                                InsurancePolicy.RecordType.Name = 'Small Group'
                                AND (
                                    InsurancePolicy.Status IN ('Activated', 'Terminated', 'Awaiting Activation')
                                    AND InsurancePolicy.ARC_EffectiveDate__c <= TODAY
                                )
                            )
                        )
                    ORDER BY InsurancePolicy.ARC_Contract__r.ARC_EffectiveDate__c ASC, InsurancePolicy.ARC_Contract__r.CreatedDate ASC, InsurancePolicy.ARC_EffectiveDate__c ASC, InsurancePolicy.CreatedDate ASC];
            } catch (Exception e) {
                throw new FlowException('error querying records: ' + e.getMessage());
            }

            System.debug('----> RETRIEVED IPP : ' + ippRelatedToEach.size());
            
            // Step 1: Group ranges by AccountId
            // AccId -> List< {start: Date, end: Date} >
            Map<Id, List<Map<String, Object>>> rawRanges = new Map<Id, List<Map<String, Object>>>();

            for (InsurancePolicyParticipant ipp : ippRelatedToEach) {
                Id accId = ipp.PrimaryParticipantContact.AccountId;
                String productCode;
                if (!ipp.Coverage_Participants__r.isEmpty()) productCode = ipp.Coverage_Participants__r[0].ARC_PolicyCoverage__r.vlocity_ins_fsc__Product2Id__r.ProductCode;
                Boolean isAccessProgram = productCode == 'PROG_UHSM_Access10k' || productCode == 'PROG_UHSM_Access5k';

                Date startDate;
                Date endDate;
                
                if (ipp.InsurancePolicy.RecordType.Name == 'Small Group') {
                    startDate = ipp.InsurancePolicy.ARC_EffectiveDate__c;
                    endDate = ipp.InsurancePolicy.ARC_ExpirationDate__c != null 
                        ? ipp.InsurancePolicy.ARC_ExpirationDate__c
                        : ipp.InsurancePolicy.ARC_EffectiveDate__c > Date.today() ? ipp.InsurancePolicy.ARC_EffectiveDate__c : Date.today();
                } else if (ipp.InsurancePolicy.RecordType.Name == 'Individual And Family') {
                    startDate = ipp.InsurancePolicy.ARC_Contract__r.ARC_EffectiveDate__c;
                    endDate = ipp.InsurancePolicy.ARC_Contract__r.ARC_Inactive_Date__c != null 
                        ? ipp.InsurancePolicy.ARC_Contract__r.ARC_Inactive_Date__c 
                        : ipp.InsurancePolicy.ARC_EffectiveDate__c > Date.today() ? ipp.InsurancePolicy.ARC_EffectiveDate__c : Date.today();
                }

                if (accId == null || startDate == null) continue;

                System.debug('matAndPreex_ProductCodes => ' + matAndPreex_ProductCodes);
                Boolean UHSMProgram = matAndPreex_ProductCodes.contains(productCode); // Indicates if the plan contains preex and maternity aggregators
                Boolean isReinstatement = ipp.InsurancePolicy.ARC_Reason__c != null && ipp.InsurancePolicy.ARC_Reason__c.contains(REINSTATEMENT_TAG); // Indicates reinstatement for SG
                Boolean mergeableQLE = ipp.InsurancePolicy.ARC_QLEReason__c != null && MERGEABLE_QLA_TAGS.contains(ipp.InsurancePolicy.ARC_QLEReason__c);
                System.debug('UHSMProgram => ' + UHSMProgram);

                if (!rawRanges.containsKey(accId)) {
                    rawRanges.put(accId, new List<Map<String, Object>>());
                    Date memberBirthdate = ipp.PrimaryParticipantContact.Account.PersonBirthdate;
                    // Fix newborn start day at the beggining of its firt plan : if newborn, coverage starts from DOB 
                    // First contract of Newborn is reason Add Newborn (=>) **DEPRECATED CRITERIA** with the introduction of temporary NB   
                    // IPP ordered by effDate => first contract for a member is its initial contract 

                    // Newborns are detected if the effective date is earlier than the member's birthdate
                    Boolean isNewbornContract = startDate <= memberBirthdate;
                    System.debug('isNewbornContract => ' + isNewbornContract);
                    if (isNewbornContract) {
                        // TNB_IMPLEMENTATION_DATE date when add temporary NB was implemented (3 Nov 2025)
                        startDate = memberBirthdate;
                        endDate = ipp.PrimaryParticipantContact.CreatedDate < TNB_IMPLEMENTATION_DATE ? endDate : startDate.addDays(30);

                        if (codeType == 'MAT__c' && isAccessProgram && startDate.year() < HINGE_YEAR) {
                            rawRanges.get(accId).add(new Map<String, Object>{
                                'start' => startDate,
                                'end' => endDate.year() >= HINGE_YEAR ? Date.newInstance(HINGE_YEAR - 1, 12, 31) : endDate,
                                'UHSMProgram' => true
                            });                        
                            if (endDate.year() >= HINGE_YEAR) {
                                rawRanges.get(accId).add(new Map<String, Object>{
                                    'start' => Date.newInstance(HINGE_YEAR, 01, 01),
                                    'end' => endDate,
                                    'UHSMProgram' => false
                                });
                            }
                            continue;
                        }

                        rawRanges.get(accId).add(new Map<String, Object>{
                            'start' => startDate,
                            'end' => endDate,
                            'UHSMProgram' => UHSMProgram
                        });
                        continue;
                    }
                }

                
                // ADJUSTMENT FOR MATERNITY AGGREGATORS PRIOR 2026
                // - WeShare_Access wont include MATERNITY after 2026, but it does include it prior 2026 -
                // - UHSMProgram flag should state 'false' by default since this will run with updated metadata -
                // If period starts before 2026, period should have flag in TRUE for Maternity
                // If period starts before 2026 AND ENDS LATER, will split in two periods: pre and post 2026 with true and false flags respectively.
                // If period starts after 2026, no extra adjustment should be done since metadata is up to date
                if (codeType == 'MAT__c' && isAccessProgram && startDate.year() < HINGE_YEAR) {
                    rawRanges.get(accId).add(new Map<String, Object>{
                        'start' => startDate,
                        'end' => endDate.year() >= HINGE_YEAR ? Date.newInstance(HINGE_YEAR - 1, 12, 31) : endDate,
                        'UHSMProgram' => true
                    });                        
                    if (endDate.year() >= HINGE_YEAR) {
                        rawRanges.get(accId).add(new Map<String, Object>{
                            'start' => Date.newInstance(HINGE_YEAR, 01, 01),
                            'end' => endDate,
                            'UHSMProgram' => false
                        });
                    }
                    continue;
                }
                
                rawRanges.get(accId).add(new Map<String, Object>{
                    'start' => startDate,
                    'end' => endDate,
                    'UHSMProgram' => UHSMProgram
                });
                System.debug('rawRanges => ' + rawRanges);
            }

            // Step 2: Join contiguous ranges by Account
            for (Id accId : rawRanges.keySet()) {
                List<Map<String, Object>> ranges = rawRanges.get(accId);
                ranges.sort(new RangeComparator()); // Order ranges chronologically
                System.debug('----------RANGES----------');
                for (Map<String, Object> entry : ranges) {
                    System.debug('[');
                    System.debug('start: ' + entry.get('start'));
                    System.debug('end: ' + entry.get('end'));
                    System.debug('UHSMProgram: ' + entry.get('UHSMProgram'));
                    System.debug(']');
                }

                List<Map<String,Object>> mergedRanges = new List<Map<String,Object>>();
                Map<String,Object> merged = new Map<String,Object>();
                Date currentStart = null;
                Date currentEnd = null;
                Boolean lastIsUHSMProgram = null;

                for (Map<String, Object> entry : ranges) {
                    System.debug('start => ' + entry.get('start'));
                    System.debug('end => ' + entry.get('end'));
                    System.debug('UHSMProgram => ' + entry.get('UHSMProgram'));
                    
                    Date entryStart = (Date)entry.get('start');
                    Date entryEnd = (Date)entry.get('end');
                    Boolean UHSMProgram = (Boolean)entry.get('UHSMProgram');
                    
                    if (currentStart == null) {
                        currentStart = entryStart;
                        currentEnd = entryEnd;
                        lastIsUHSMProgram = UHSMProgram;
                        continue;
                    }
                    
                    // Consolidate periods if:
                    // They overlap or are consecutive (gap less than 1 day) and have same UHSMProgram flag value,
                    // UPDATE FOR Small Group: Upgrades & Downgrades reset mat & preex, 
                    // UPDATE FOR Small Group: Reinstatements (FMLA, Militay Leave, Leave of Absence) carry over mat & preex => merge
                    if (entryStart > currentEnd.addDays(1) || UHSMProgram != lastIsUHSMProgram) {
                        merged.put( 'dates', new Date[]{currentStart, currentEnd});
                        merged.put( 'UHSMProgram', lastIsUHSMProgram);
                        mergedRanges.add(merged);
                        merged = new Map<String,Object>();
                        System.debug('CONTROL --------------------------- : ' + mergedRanges);
                        currentStart = entryStart;
                        currentEnd = entryEnd;
                        lastIsUHSMProgram = UHSMProgram;
                    } else {
                        currentEnd = entryEnd > currentEnd ? entryEnd : currentEnd;
                    }
                    System.debug('----------end loop params------');
                    System.debug(currentStart);
                    System.debug(currentEnd);
                    System.debug(lastIsUHSMProgram);
                    System.debug(merged);
                    System.debug(mergedRanges);
                    System.debug('----------/end loop params/------');
                }

                if (currentStart != null && currentEnd != null && lastIsUHSMProgram != null) {
                    merged.put( 'dates', new Date[]{currentStart, currentEnd});
                    merged.put( 'UHSMProgram', lastIsUHSMProgram);
                    System.debug('CONTROL 2.1 --------------------------- : ' + merged);
                    mergedRanges.add(merged);
                    System.debug('CONTROL 2.2 --------------------------- : ' + mergedRanges);
                }

                memberCoveragePeriods.put(accId, mergedRanges);
            }

        }
        System.debug('--COVERAGE PERIODS--: ' + memberCoveragePeriods);
        return memberCoveragePeriods;
    }

    /*******************************************************************
    * @MethodName         :   calculateAggregators
    * @Parameters         :   List<Date[]> coveragePeriods, String type
    * @Description        :   Recieves a list of continuous periods end returns a description of the necessary aggregators for the given type
    ********************************************************************/
    public static List<String> calculateAggregators(List<Map<String, Object>> memberCoveragePeriods, String type) {
        //Starting point    
        //System.debug('---MEMBER COVERAGE PERIODS---');
        System.debug('-COVERAGE PERIODS-'+ memberCoveragePeriods);
        
        if(memberCoveragePeriods == null){
            System.debug('Member coverage period is null');
            return new List<String>();
        }
        
        System.debug('---MEMBER COVERAGE PERIODS---');
        for (Map<String, Object> period : memberCoveragePeriods) {
            System.debug(period);
        }

        Date renewalDate;
        Date benefitEndDate;        
        Integer benefitYearCounter;
        Boolean lastIsUHSMProgram;
        Date lastPeriodStartDate;
        Date lastPeriodEndDate;
        Integer renewalYears = (type == 'PREEX__c') ? 3 : 2;

        List<String> aggregatorsList = new List<String>();

        for (Map<String, Object> period : memberCoveragePeriods) { 
            Date[] periodDates = (Date[]) period.get('dates');
            Boolean isUSHMProgram = (Boolean) period.get('UHSMProgram');
            System.debug(period.get('UHSMProgram'));
            Boolean continuousPeriod = (lastPeriodEndDate != null && periodDates[0] <= lastPeriodEndDate.addDays(1)) ? true : false;
            System.debug('-------------------------------');
            System.debug('-------- NEW ITERATION --------');
            System.debug('-------------------------------');
            System.debug('-------- PERIOD DATES --------');
            System.debug('START ' + periodDates[0]);
            System.debug('END ' + periodDates[1]);
            System.debug('renewal date ' + renewalDate);
            System.debug('-------- IS USHM PROGRAM --------' + isUSHMProgram);
            System.debug('-------- CONTINUOUS PERIOD --------' + continuousPeriod);
            List<String> periodAggregators = new List<String>();
            // find first UHSM program
            if (renewalDate == null && benefitEndDate == null && benefitYearCounter == null) {
                if (isUSHMProgram) {
                    System.debug('---FIRST USHM PROGRAM DETECTED---');
                    renewalDate = periodDates[0];        
                    benefitEndDate = periodDates[0].addYears(renewalYears);        
                    benefitYearCounter = 1;
                } else {
                    continue;
                }
            }

            Boolean resetBenefit = benefitEndDate <= periodDates[0] && (!continuousPeriod);
            if (resetBenefit) { 
                System.debug('---RESET BENEFIT DETECTED---');
                renewalDate = isUSHMProgram ? periodDates[0] : null;        
                benefitEndDate = isUSHMProgram ? periodDates[0].addYears(renewalYears) : null;        
                benefitYearCounter = isUSHMProgram ? 1 : null;    
                if (!isUSHMProgram) {
                    continue;
                }
            }

            Integer maxBY = type == 'MAT__c' ? 1 : 3;
            Integer aggregatorDurationYears = type == 'MAT__c' ? 2 : 1;
            while (renewalDate < periodDates[0] && benefitYearCounter <= maxBY) {
                System.debug('---adjusting renewal date---');
                renewalDate = renewalDate.addYears(aggregatorDurationYears);
                benefitYearCounter++;  
                System.debug('--renDate : ' + renewalDate);
                System.debug('--BY : ' + benefitYearCounter);
            }

            System.debug('renewalDate: ' + renewalDate);
            System.debug('benefitEndDate: ' + benefitEndDate);
            System.debug('benefitYearCounter: ' + benefitYearCounter);
            
            if (benefitYearCounter > 1 && renewalDate.addYears(-1*aggregatorDurationYears) < periodDates[0] 
                && isUSHMProgram
            ) {
                System.debug('---last renewal date is before period start---');
                // Verify if we have created the previous aggregator
                // If not, we need to adjust the benefit year counter, so the previous aggregator is created
                String lastCreatedAgg = aggregatorsList.isEmpty() ? null : aggregatorsList[aggregatorsList.size() - 1];
                List<String> lastCreatedAggParts = lastCreatedAgg != null ? lastCreatedAgg.split('\\|\\|') : new List<String>();
                
                Date lastCreatedAggStartDate = lastCreatedAggParts.size() == 4 ? Date.valueOf(lastCreatedAggParts[0]) : null;
                Date lastCreatedAggEndDate = lastCreatedAggParts.size() == 4 ? Date.valueOf(lastCreatedAggParts[1]) : null;
                String lastCreatedAggBY = lastCreatedAggParts.size() == 4 ? lastCreatedAggParts[2] : null;

                
                if (
                    lastCreatedAggBY == 'BY' + (benefitYearCounter - 1)
                    &&
                    (lastCreatedAggBY != null && lastCreatedAggStartDate != null && lastPeriodEndDate != null) 
                    && 
                    // On this case, aggregator has been created on the corresponding period loop   
                    (lastCreatedAggStartDate >= renewalDate.addYears(-1*aggregatorDurationYears) && lastCreatedAggStartDate <= renewalDate) 
                ) {
                    // '---PREVIOUS AGGREGATOR ALREADY CREATED---');
                    System.debug('---previous agg should EXIST---');
                    // NOTE: This step of the process is ment 
                    // to re-set the end date of the previous aggregator
                    // as the end date of the last period
                    // BUT --> mat and preex should keep their end dates as they are
                    // (they are not affected by contract's end date ==> no action needed)

                    // if (benefitEndDate > periodDates[0]) {
                    //     // fix end date for last agg
                    //     lastCreatedAggParts[1] = renewalDate.addDays(-1) < periodDates[1] ? String.valueOf(renewalDate.addDays(-1)) : String.valueOf(periodDates[1]); 
                    //     String updatedAggregator = String.join(lastCreatedAggParts, '||');
                    //     aggregatorsList[aggregatorsList.size()-1] = updatedAggregator;
                    // }
                } else {
                    // ---PREVOUS AGG WAS NOT CREATED---
                    // Should create rev.agg IF the prev.agg endDate (renewal -1day) IS greater than this period start date
                    // and the renewal date is greater than the previous aggregator end date (?)
                    System.debug('---previous agg should NOT exist (YET)---');
                    if (
                        renewalDate.addYears(-1*aggregatorDurationYears) < periodDates[0] // this means that the previous aggregator STARTED not in this period
                        &&
                        benefitEndDate > periodDates[0] // and the benefit end date is beyond this period
                        && 
                        renewalDate.addDays(-1) >= periodDates[0] // prev.agg endDate (renewal -1day) IS greater than this period start date
                    ) {
                        // '---ADJUSTING BENEFIT YEAR COUNTER TO CREATE PREVIOUS AGGREGATOR---');
                        System.debug('---adjust BY counter and renewal date to account for previous agg---');
                        renewalDate = renewalDate.addYears(-1*aggregatorDurationYears);
                        benefitYearCounter--;
                        System.debug('--renDate : ' + renewalDate);
                        System.debug('--BY : ' + benefitYearCounter);
                    }  
                } 
            }
            Boolean createAggregators = isUSHMProgram;
            System.debug(periodDates + ' || ' + renewalDate + ' || ' + benefitYearCounter + ' || ' + benefitEndDate + ' || ' + type + ' || ' + createAggregators);
            Map<String, Object> endPeriodInfo = createAggregatorsForPeriod(periodDates, renewalDate, benefitYearCounter, benefitEndDate, type, createAggregators);
            renewalDate = (Date) endPeriodInfo.get('renewalDate');
            benefitYearCounter = (Integer) endPeriodInfo.get('BYCounter'); 
            periodAggregators = (List<String>) endPeriodInfo.get('createdAggregators'); 
            System.debug(endPeriodInfo);
            aggregatorsList.addAll(periodAggregators);
            System.debug('----AGGSLIST: ' + aggregatorsList);
            lastIsUHSMProgram = isUSHMProgram;
            lastPeriodEndDate = periodDates[1];
            lastPeriodStartDate = periodDates[0];
        }
        System.debug('---FINAL AGGREGATORS---');
        System.debug('---FINAL AGGREGATORS--- : ' + aggregatorsList.size());
        for (String agg : aggregatorsList) {
            System.debug(agg);
        }
        System.debug('---FINAL AGGREGATORS--- : ' + aggregatorsList.size());
        return aggregatorsList;
    }

    
    /*******************************************************************
    * @MethodName         :   createAggregatorsForPeriod
    * @Parameters         :   Date[] period, Date renewalDate, Integer BYCounter, Date benefitEndDate, String Type, Boolean createAggregators
    * @Description        :   Given a period, a satarting renewal date and a BY counter, create the necessary aggregators within that period, without exceeding the benefit end date
    ********************************************************************/
    public static Map<String, Object> createAggregatorsForPeriod(Date[] period, Date renewalDate, Integer BYCounter, Date benefitEndDate, String type, Boolean createAggregators) {
        Map<String, Object> endPeriodInfo = new Map<String, Object>();
        List<String> createdAggregators = new List<String>();
        Date startDate = period[0];
        Date endDate = period[1];
        // MAT has 1 BY lasting 2 years, 
        // PREEX has 3 BY lastong 1 year each
        Integer aggregatorDurationYears = (type == 'MAT__c') ? 2 : 1;
        Integer maxBY = type == 'MAT__c' ? 1 : 3; 

        while (renewalDate <= endDate && renewalDate < benefitEndDate && BYCounter <= maxBY) {
            System.debug('while loop');
            String benefitYear = 'BY' + BYCounter;
            Date aggStart = renewalDate;
            Date aggEnd = renewalDate.addYears(aggregatorDurationYears).addDays(-1);
            if (createAggregators) {
                createdAggregators.add(debugAggregator(aggStart, aggEnd, benefitYear, type));
            }
            renewalDate = renewalDate.addYears(aggregatorDurationYears);  
            BYCounter++;  
        }
        endPeriodInfo.put('renewalDate', renewalDate);
        endPeriodInfo.put('BYCounter', BYCounter);
        endPeriodInfo.put('createdAggregators', createdAggregators);
        return endPeriodInfo;
        
    }

    /*******************************************************************
    * @MethodName         :   getPartAggForAggInPolicies
    * @Parameters         :   String aggDescription, List<InsurancePolicy> memberPolicies, Id accId
    * @Description        :   given an agg description, a list of policies and an account id, return the description for the participant aggregators to create
                                memberPolicies should be the member's account policies that have the aggregator in question  
    ********************************************************************/
    public static List<String> getPartAggForAggInPolicies (String aggDescription, List<InsurancePolicy> memberPolicies, Id accId) {
        List<String> partAggsDesc = new List<String>();
        System.debug('---START getPartAggForAggInPolicies---');
        System.debug('Aggregator Description: ' + aggDescription);
        
        if (memberPolicies == null) return partAggsDesc;

        Date aggStart = Date.valueOf(aggDescription.split('\\|\\|')[0]);
        Date aggEnd = Date.valueOf(aggDescription.split('\\|\\|')[1]);
        
        for (InsurancePolicy pol : memberPolicies) {
            Date polStart = pol.ARC_EffectiveDate__c;
            Date polEnd = pol.ARC_ExpirationDate__c != null ? pol.ARC_ExpirationDate__c : Date.today();

            System.debug('---FOR POLICY: ---');
            System.debug('Start: ' + polStart);
            System.debug('End: ' + polEnd);
            System.debug('-------------------------DEBUG CONDITIONALS:');
            System.debug(aggStart <= polStart);
            System.debug(aggEnd >= polStart);
            System.debug('----------------------');
            System.debug(aggStart <= polEnd);
            System.debug(aggEnd >= polEnd);
            System.debug('----------------------');
            System.debug(aggStart >= polStart);
            System.debug(aggEnd <= polEnd);

            if (aggStart <= polStart && aggEnd >= polStart
                || aggStart <= polEnd && aggEnd >= polEnd 
                || aggStart >= polStart && aggEnd <= polEnd
            ) {
                String ippId;
                System.debug('control: needs a partAgg OK-');
                for (InsurancePolicyParticipant ipp : pol.InsurancePolicyParticipants) {
                    if (ipp.Participant_Account_Id__c == accId) {
                        ippId = ipp.Id;
                        break;
                    }
                }
                System.debug('---PARTICIPANT AGGREGATOR PRE DEBUG ---');
                System.debug('IPP Id found: ' + pol.Id);
                System.debug('Part.Aggregator policy Id: ' + pol.Id);
                String partAggDescription = debugParticipantAggregator(pol.Id, ippId);
                System.debug('--partAggDescription:_' + partAggDescription);
                partAggsDesc.add(partAggDescription);
                System.debug('control added to list---');
            } 
        }
        System.debug('control end of getPartAggForAggInPolicies---');
        return partAggsDesc;
    }

    /*******************************************************************
    * @MethodName         :   debugParticipantAggregator
    * @Parameters         :   Id polId, Id ippId
    * @Description        :   returns a string describing a participant aggregator record : polId and ippId for the participant aggregator
    ********************************************************************/
    public static String debugParticipantAggregator(Id polId, Id ippId) {
        System.debug('---PARTICIPANT AGGREGATOR INFO---');
        System.debug('Part.Aggregator policy Id: ' + polId);
        System.debug('Part.Aggregator IPP Id: ' + ippId);
        return polId + '||' + ippId;
    }

    /*******************************************************************
    * @MethodName         :   debugAggregator
    * @Parameters         :   Date aggStart, Date aggEnd, String benefitYear, String type
    * @Description        :   returns a string describing a  aggregator record : aggStart, aggEnd, benefitYear, type
    ********************************************************************/
    public static String debugAggregator(Date aggStart, Date aggEnd, String benefitYear, String type) {
        System.debug('---AGGREGATOR INFO---');
        System.debug('Aggregator type: ' + type);
        System.debug('Benefit Year: ' + benefitYear);
        System.debug('Aggregator Start Date: ' + aggStart);
        System.debug('Aggregator End Date: ' + aggEnd);
        return String.valueOf(aggStart) + '||' + String.valueOf(aggEnd) + '||' + benefitYear + '||' + type;
    }

    /*******************************************************************
    * @MethodName         :   getMatPeexProductCodes
    * @Parameters         :   String codeType
    * @Description        :   for string 'PREEX__c' or 'MAT__c' returns the list of product codes that have the given codeType
    ********************************************************************/
    public static List<String> getMatPeexProductCodes(String codeType) {
        List<String> matAndPreex_ProductCodes = new List<String>();
        List<ARC_ProductAggregators__mdt> allProductsMtd = [
            SELECT Id, DeveloperName, MasterLabel, IND_PREEX__c, IND_MAT__c
            FROM ARC_ProductAggregators__mdt
        ];
        for (ARC_ProductAggregators__mdt rec : allProductsMtd) {
            if (codeType == 'MAT__c') {
                if (rec.IND_MAT__c != null && rec.IND_MAT__c != 0) {
                    matAndPreex_ProductCodes.add(rec.DeveloperName);
                }
            } else if (codeType == 'PREEX__c') {
                if (rec.IND_PREEX__c != null && rec.IND_PREEX__c != 0) {
                    matAndPreex_ProductCodes.add(rec.DeveloperName);
                }
            } else {
                if ((rec.IND_PREEX__c != null && rec.IND_PREEX__c != 0) || (rec.IND_MAT__c != null && rec.IND_MAT__c != 0)) {
                matAndPreex_ProductCodes.add(rec.DeveloperName);
                }
            }
        }
        return matAndPreex_ProductCodes;
    }

    public class RangeComparator implements Comparator<Map<String,Object>> {
        
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            Date startA = Date.valueOf(a.get('start'));
            Date startB = Date.valueOf(b.get('start'));

            return startB.daysBetween(startA);
        }
    }

}