global class ARC_PolicyTriggerHandlerManualBatch implements Database.Batchable<sObject>, Database.Stateful {
    private static final List<String> UPGRADE_REASONS = new List<String>{'Program Upgrade', 'New Application', 'Upgraded Spin Off'};
    private static final List<String> ONE_TIME = new List<String>{'CCS__c', 'MAMM__c', 'PROSCRE__c', 'FLXSIG__c', 'CLON__c', 'SSOPT__c'};
    private static final List<String> LIFETIME = new List<String>{'ALGTEST__c'};
    private String whereClause;
    
    public ARC_PolicyTriggerHandlerManualBatch(String whereClause) {
        this.whereClause = whereClause;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id FROM InsurancePolicy WHERE ' + whereClause;
        return Database.getQueryLocator(query);
    }

    // GENERATE AGGREGATORS ONLY WHEN POLICY BECOMES ACTIVE
    global void execute(Database.BatchableContext BC, List<InsurancePolicy> input){
            Set<Id> policyIds = new Set<Id>();
            List<InsurancePolicy> polUpgraded = new List<InsurancePolicy>();
            List<InsurancePolicy> polCarryOver = new List<InsurancePolicy>();
            Map<String, ARC_ProductAggregators__mdt> aggsDefinition = new Map<String, ARC_ProductAggregators__mdt>();
            for (InsurancePolicy pol : input) policyIds.add(pol.Id);
            
            // SEPARATE PARTICIPANTS BY UPGRADE REASON
            Map<Id, InsurancePolicy> policies = new Map<Id, InsurancePolicy>([SELECT Id, ARC_PolicyReason__c, Product.ProductCode, ARC_EffectiveDate__c, ARC_FamilyCoreAggregator__c, RenewedFromPolicy.Product.ProductCode, RenewedFromPolicy.ARC_EffectiveDate__c, RenewedFromPolicyId, (SELECT Id, InsurancePolicyId, PrimaryParticipantContact.AccountId, InsurancePolicy.Product.ProductCode, InsurancePolicy.RenewedFromPolicyId FROM InsurancePolicyParticipants), (SELECT Id, Name, RecordTypeId, ARC_Member__c FROM Aggregators__r) FROM InsurancePolicy WHERE Id IN: policyIds LIMIT 1000]);
            for (InsurancePolicy pol : policies.values()) {
                if(pol.ARC_PolicyReason__c == null) continue;

                List<String> polReasons = pol.ARC_PolicyReason__c.split('<br>');
                Boolean isUpgrade = false;
                for(String reason : polReasons){
                    if(UPGRADE_REASONS.contains(reason)) isUpgrade = true;
                    break;
                }
                
                // CHECK FOR NEW YEAR
                if(
                    pol.RenewedFromPolicy.ARC_EffectiveDate__c != null && 
                    pol.RenewedFromPolicy.ARC_EffectiveDate__c.year() != pol.ARC_EffectiveDate__c.year()
                ) isUpgrade = true;

                if(isUpgrade) polUpgraded.add(pol);
                else polCarryOver.add(pol);

                // GET AGGREGATOR VALUES
                if(pol.Product.ProductCode != null) aggsDefinition.put(pol.Product.ProductCode, ARC_ProductAggregators__mdt.getInstance(pol.Product.ProductCode));
            }
            if(aggsDefinition.isEmpty()) return;

        // CREATE AGGREGATORS FOR PARTICIPANTS
        try {
            if (polUpgraded.size() > 0) createAggsUpgraded(polUpgraded, aggsDefinition);
            if (polCarryOver.size() > 0) createAggsCarryOver(polCarryOver, aggsDefinition);
        } catch (Exception e) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{'agustin.garay@arcsona.com'});
            mail.setSubject('Apex Exception Occurred');
            mail.setPlainTextBody('Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }
    }

    // CREATE AGGREGATORS FOR UPGRADED POLICIES
    public static void createAggsUpgraded(List<InsurancePolicy> input, Map<String, ARC_ProductAggregators__mdt> aggsDefinition){
        List<ARC_Aggregator__c> famAggsToInser = new List<ARC_Aggregator__c>();
        List<ARC_ParticipantAggregator__c> aggsPartToInsert = new List<ARC_ParticipantAggregator__c>();
        List<InsurancePolicyParticipant> participants = new List<InsurancePolicyParticipant>();
        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        Map<Id, Map<String, ARC_Aggregator__c>> familyAggsPerPolicy = new Map<Id, Map<String, ARC_Aggregator__c>>();
        Map<ARC_Aggregator__c, ARC_Aggregator__c> indiToFamilyAggs = new Map<ARC_Aggregator__c, ARC_Aggregator__c>();
        List<ARC_Aggregator__c> noFamAggs = new List<ARC_Aggregator__c>();
        Set<Id> policyIds = new Set<Id>();

        for (InsurancePolicy pol : input) { policyIds.add(pol.RenewedFromPolicyId); }
        List<ARC_Aggregator__c> aggsCreated = [SELECT Id, Name, ARC_Year__c, ARC_Code__c, ARC_Member__c, RecordType.Name, ARC_CreatedIn__c FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c IN: policyIds LIMIT 10000];

        // CREATE AGGREGATOR
        for (InsurancePolicy pol : input) {
            ARC_ProductAggregators__mdt aggValues = aggsDefinition.get(pol.Product.ProductCode);

            if(aggValues == null || pol.Aggregators__r.size() > 0) continue;

            // CREATE FAMILY AGGREGATORS
            for (Schema.SObjectField field : aggValues.getSObjectType().getDescribe().fields.getMap().values()) {
                if(!String.valueOf(field).startsWith('FAM_') || aggValues.get(field) == null) continue;

                Map<String, Object> inputAgg = new Map<String, Object>();
                inputAgg.put('name', field.getDescribe().getLabel());
                inputAgg.put('limit', Double.valueOf((Double)aggValues.get(field)));
                inputAgg.put('year', String.valueOf(pol.ARC_EffectiveDate__c.year()));
                inputAgg.put('recordTypeId', familyAggRT);

                // CHECK IF IT'S A NEW YEAR POLICY
                List<String> polReasons = pol.ARC_PolicyReason__c.split('<br>');
                Boolean isUpgrade = false;
                for(String reason : polReasons){
                    if(UPGRADE_REASONS.contains(reason)) isUpgrade = true;
                    break;
                }

                ARC_Aggregator__c existingAggregator = null;
                if(isUpgrade) inputAgg.put('createdIn', pol.Id);
                else{
                    Integer renewedYear = pol.RenewedFromPolicy.ARC_EffectiveDate__c.year();
                    Integer newPolYear = pol.ARC_EffectiveDate__c.year();

                    // CHECK IF ALREADY EXISTS
                    for(ARC_Aggregator__c agg : aggsCreated){
                        if(agg.RecordType.Name == 'Family' && agg.ARC_Year__c == String.valueOf(newPolYear) && agg.ARC_CreatedIn__c == pol.RenewedFromPolicyId){
                            existingAggregator = agg;
                            break;
                        }
                    }

                    if(renewedYear != newPolYear) inputAgg.put('createdIn', pol.RenewedFromPolicyId);
                }
                
                ARC_Aggregator__c famAgg = existingAggregator == null ? createAggregator(inputAgg) : existingAggregator;
                familyAggsPerPolicy.put(pol.Id, new Map<String, ARC_Aggregator__c>{String.valueOf(field).replace('FAM_', '') => famAgg});
                famAggsToInser.add(famAgg);
            }

            // CREATE INDIVIDUAL AGGREGATORS
            for (InsurancePolicyParticipant part : pol.InsurancePolicyParticipants) {
                for (Schema.SObjectField field : aggValues.getSObjectType().getDescribe().fields.getMap().values()) {
                    if(!String.valueOf(field).startsWith('IND_') || aggValues.get(field) == null) continue;
                    String aggCode = String.valueOf(field).replace('IND_', '');
                   
                    Map<String, Object> inputAgg = new Map<String, Object>();
                    inputAgg.put('name', field.getDescribe().getLabel());
                    inputAgg.put('limit', Double.valueOf((Double)aggValues.get(field)));
                    inputAgg.put('recordTypeId', individualAggRT);
                    inputAgg.put('code', aggCode);
                    inputAgg.put('member', part.PrimaryParticipantContact.AccountId);
                    
                    if(!ONE_TIME.contains(aggCode) && !LIFETIME.contains(aggCode)) inputAgg.put('year', String.valueOf(pol.ARC_EffectiveDate__c.year()));
                    else if(ONE_TIME.contains(aggCode)) inputAgg.put('nextUse', pol.ARC_EffectiveDate__c);

                    // CHECK IF IT'S A NEW YEAR POLICY
                    List<String> polReasons = pol.ARC_PolicyReason__c.split('<br>');
                    Boolean isUpgrade = false;
                    for(String reason : polReasons){
                        if(UPGRADE_REASONS.contains(reason)) isUpgrade = true;
                        break;
                    }

                    ARC_Aggregator__c existingAggregator = null;
                    if(isUpgrade) inputAgg.put('createdIn', pol.Id);
                    else{
                        Integer renewedYear = pol.RenewedFromPolicy.ARC_EffectiveDate__c.year();
                        Integer newPolYear = pol.ARC_EffectiveDate__c.year();

                        // CHECK IF EXISTS
                        for(ARC_Aggregator__c agg : aggsCreated){
                            if(
                                agg.ARC_Code__c == aggCode && 
                                agg.ARC_Member__c == part.PrimaryParticipantContact.AccountId && 
                                agg.ARC_Year__c == String.valueOf(newPolYear)
                            ){
                                existingAggregator = agg;
                                break;

                            }else if(
                                (ONE_TIME.contains(agg.ARC_Code__c) || LIFETIME.contains(agg.ARC_Code__c)) &&
                                agg.ARC_Code__c == aggCode &&
                                agg.ARC_Member__c == part.PrimaryParticipantContact.AccountId
                            ){
                                existingAggregator = agg;
                                break;
                            }
                        }

                        if(renewedYear != newPolYear) inputAgg.put('createdIn', pol.RenewedFromPolicyId);
                    }

                    ARC_Aggregator__c indAgg = existingAggregator == null ? createAggregator(inputAgg) : existingAggregator;
                    if(familyAggsPerPolicy.get(pol.Id) != null){
                        inputAgg.put('famAggregator', familyAggsPerPolicy.get(pol.Id).get(String.valueOf(field).replace('IND_', '')) != null ? familyAggsPerPolicy.get(pol.Id).get(String.valueOf(field).replace('IND_', '')).Id : null);

                        indiToFamilyAggs.put(indAgg, familyAggsPerPolicy.get(pol.Id).get(String.valueOf(field).replace('IND_', '')));
                    }else{
                        noFamAggs.add(indAgg);
                    }
                }
            }
        
            participants.addAll(pol.InsurancePolicyParticipants);
        }
        if(famAggsToInser.size() > 0) upsert famAggsToInser;
        if(noFamAggs.size() > 0) upsert noFamAggs;

        // POPULATE FAMILY AGGREGATORS ON THE INDIVIDUAL AGGREGATORS
        for (ARC_Aggregator__c indAgg : indiToFamilyAggs.keySet()) {
                if(indiToFamilyAggs.get(indAgg) == null) continue;
                else indAgg.ARC_FamilyAggregator__c = indiToFamilyAggs.get(indAgg).Id;
            }
        if(indiToFamilyAggs.size() > 0) upsert new List<ARC_Aggregator__c>(indiToFamilyAggs.keySet());

        // POPULATE FAMILY AGGREGATORS ON THE POLICY
        List<InsurancePolicy> polsToUpdate = new List<InsurancePolicy>();
        for (InsurancePolicy pol : input) {
            if(familyAggsPerPolicy.get(pol.Id) == null || pol.ARC_FamilyCoreAggregator__c != null) continue;

            pol.ARC_FamilyCoreAggregator__c = familyAggsPerPolicy.get(pol.Id).get('AMCS__c').Id;
            polsToUpdate.add(pol);
        }
        if(polsToUpdate.size() > 0) update polsToUpdate;

        // CREATE PARTICIPANT AGGREGATORS        
        for (InsurancePolicy pol : input) {
            List<ARC_Aggregator__c> aggsToUse = new List<ARC_Aggregator__c>(indiToFamilyAggs.keySet());
            if(noFamAggs.size() > 0) aggsToUse.addAll(noFamAggs);
            List<InsurancePolicyParticipant> partsToUse = participants;

            // if(pol.Aggregators__r.size() > 0) aggsToUse = pol.Aggregators__r;
            // if(pol.InsurancePolicyParticipants.size() > 0) partsToUse = pol.InsurancePolicyParticipants;

            for (ARC_Aggregator__c agg : aggsToUse) {
                if(agg.RecordTypeId == familyAggRT) continue;
            
                for (InsurancePolicyParticipant part : partsToUse) {
                    if(
                        agg.ARC_Member__c == part.PrimaryParticipantContact.AccountId &&
                        (agg.ARC_CreatedIn__c == pol.Id || agg.ARC_CreatedIn__c == pol.RenewedFromPolicyId)
                    ){
                        aggsPartToInsert.add(createParticipantAggs(pol, agg, part));
                    }
                }
            }
        }

        if(aggsPartToInsert.size() > 0) insert aggsPartToInsert;
    }

    // CREATE AGGREGATORS FOR CARRY OVER POLICIES
    public static void createAggsCarryOver(List<InsurancePolicy> input, Map<String, ARC_ProductAggregators__mdt> aggsDefinition){
        List<ARC_ParticipantAggregator__c> aggsPartToInsert = new List<ARC_ParticipantAggregator__c>();
        List<ARC_Aggregator__c> aggsToInsert = new List<ARC_Aggregator__c>();
        Set<Id> renewedPolicies = new Set<Id>();
        for (InsurancePolicy p : input) {
            renewedPolicies.add(p.RenewedFromPolicyId);
        }
        List<ARC_Aggregator__c> aggregators = [SELECT Id, Name, ARC_CreatedIn__c, RecordType.Name, ARC_Member__c, ARC_Code__c, ARC_LimitValue__c FROM ARC_Aggregator__c WHERE ARC_CreatedIn__c IN: renewedPolicies LIMIT 1000];

        // POPULATE FAMILY AGGREGATORS
        Map<Id, ARC_Aggregator__c> indiPolAgg = new Map<Id, ARC_Aggregator__c>();
        for (InsurancePolicy pol : input) {
            for (ARC_Aggregator__c agg : aggregators) {
                if(pol.ARC_FamilyCoreAggregator__c == null && agg.RecordType.Name == 'Family' && agg.Name == 'Family AMCS' && agg.ARC_CreatedIn__c == pol.RenewedFromPolicyId){
                    pol.ARC_FamilyCoreAggregator__c = agg.Id;
                }
            }

            // CHECK FOR FUNDAMENTAL SUNSET DOWNGRADE
            if(
                pol.ARC_FamilyCoreAggregator__c == null && 
                pol.Product.ProductCode.contains('Access') &&
                (!pol.RenewedFromPolicy.Product.ProductCode.contains('WeShare') || !pol.RenewedFromPolicy.Product.ProductCode.contains('Access'))
            ){
                ARC_ProductAggregators__mdt aggValues = aggsDefinition.get(pol.Product.ProductCode);
                Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
                for (Schema.SObjectField field : aggValues.getSObjectType().getDescribe().fields.getMap().values()) {
                    if(!String.valueOf(field).startsWith('FAM_') || aggValues.get(field) == null) continue;

                    Map<String, Object> inputAgg = new Map<String, Object>();
                    inputAgg.put('name', field.getDescribe().getLabel());
                    inputAgg.put('limit', Double.valueOf((Double)aggValues.get(field)));
                    inputAgg.put('recordTypeId', familyAggRT);
                    inputAgg.put('createdIn', pol.RenewedFromPolicyId);
                    inputAgg.put('year', String.valueOf(pol.ARC_EffectiveDate__c.year()));

                    indiPolAgg.put(pol.RenewedFromPolicyId, createAggregator(inputAgg));
                }
            }
        }

        if(indiPolAgg.values().size() > 0){
            insert indiPolAgg.values();

            // INCLUDE FAMILY ON PROGRAM SUNSET
            for (InsurancePolicy pol : input) {
                if(indiPolAgg.get(pol.RenewedFromPolicyId) != null) pol.ARC_FamilyCoreAggregator__c = indiPolAgg.get(pol.RenewedFromPolicyId).Id;
            }
        }
        update input;

        // CHECK FOR NEW AGGREGATORS (FUNDAMENTAL SUNSET)
        List<InsurancePolicyParticipant> participants = new List<InsurancePolicyParticipant>();
        for (InsurancePolicy pol : input) participants.addAll(pol.InsurancePolicyParticipants);
        
        Map<Id, Map<String, Double>> aggsMissingPerParticipant = new Map<Id, Map<String, Double>>();
        Map<String, Double> aggLimitUpdate = new Map<String, Double>(); 
        for (InsurancePolicyParticipant part : participants) {
            // CHECK PREVIOUS AGGREGATORS
            Map<String, Double> aggExisting = new Map<String, Double>();
            for (ARC_Aggregator__c agg : aggregators) {
                if(agg.ARC_CreatedIn__c == part.InsurancePolicy.RenewedFromPolicyId && part.PrimaryParticipantContact.AccountId == agg.ARC_Member__c) {
                    aggExisting.put(agg.ARC_Code__c, agg.ARC_LimitValue__c);
                }
            }
            
            // COMPARE PREV. AGGS WITH MEMBER'S NEW PROGRAM
            ARC_ProductAggregators__mdt aggValues = aggsDefinition.get(part.InsurancePolicy.Product.ProductCode);
            for (Schema.SObjectField field : aggValues.getSObjectType().getDescribe().fields.getMap().values()) {
                if(aggValues.get(field) == null || (!String.valueOf(field).startsWith('FAM_') && !String.valueOf(field).startsWith('IND_'))) continue;
                Double limitValue = Double.valueOf((Double)aggValues.get(field));

                if(String.valueOf(field).startsWith('FAM_')){
                    aggLimitUpdate.put(part.InsurancePolicy.RenewedFromPolicyId, limitValue);
                    continue;
                }

                String aggCode = String.valueOf(field).replace('IND_', '');
                aggLimitUpdate.put(part.PrimaryParticipantContact.AccountId + ',' + aggCode, limitValue);

                if(aggExisting.get(aggCode) != null) continue;

                Map<String, Double> aggMissing = aggsMissingPerParticipant.get(part.Id) != null ? aggsMissingPerParticipant.get(part.Id) : new Map<String, Double>();
                aggMissing.put(aggCode, limitValue);
                aggsMissingPerParticipant.put(part.Id, aggMissing);
            }
        }

        // CREATE AGGREGATORS FOR NEW MEMBES AND IF IT'S A FUNDAMENTAL SUNSET
        for (InsurancePolicy pol : input) {
            for(InsurancePolicyParticipant part : pol.InsurancePolicyParticipants){
                Map<String, Double> aggToCreate = aggsMissingPerParticipant.get(part.Id);
                if(aggToCreate == null) continue;

                ARC_ProductAggregators__mdt aggValues = aggsDefinition.get(pol.Product.ProductCode);
                Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
                for (Schema.SObjectField field : aggValues.getSObjectType().getDescribe().fields.getMap().values()) {
                    if(!String.valueOf(field).startsWith('IND_') || aggValues.get(field) == null) continue;
                    String aggCode = String.valueOf(field).replace('IND_', '');
                    if(!aggToCreate.containsKey(aggCode)) continue;

                    Map<String, Object> inputAgg = new Map<String, Object>();
                    inputAgg.put('name', field.getDescribe().getLabel());
                    inputAgg.put('limit', Double.valueOf((Double)aggValues.get(field)));
                    inputAgg.put('recordTypeId', individualAggRT);
                    inputAgg.put('createdIn', pol.RenewedFromPolicyId);
                    inputAgg.put('code', aggCode);
                    inputAgg.put('member', part.PrimaryParticipantContact.AccountId);

                    if(!ONE_TIME.contains(aggCode) && !LIFETIME.contains(aggCode)) inputAgg.put('year', String.valueOf(pol.ARC_EffectiveDate__c.year()));
                    else if(ONE_TIME.contains(aggCode)) inputAgg.put('nextUse', pol.ARC_EffectiveDate__c);

                    if(inputAgg.get('code') == 'AMCS__c') inputAgg.put('famAggregator', pol.ARC_FamilyCoreAggregator__c);
                    aggsToInsert.add(createAggregator(inputAgg));
                }
            }
        }
        
        // MODIFY AGGREGATORS VALUES
        List<ARC_Aggregator__c> aggsModified = new List<ARC_Aggregator__c>();
        for (ARC_Aggregator__c agg : aggregators) {
            Double updateValue = null;
            if(agg.RecordType.Name == 'Individual'){
                updateValue = aggLimitUpdate.get(agg.ARC_Member__c + ',' + agg.ARC_Code__c) != null ? aggLimitUpdate.get(agg.ARC_Member__c + ',' + agg.ARC_Code__c) : null;
            }else if(agg.RecordType.Name == 'Family'){
                updateValue = aggLimitUpdate.get(agg.ARC_CreatedIn__c) != null ? aggLimitUpdate.get(agg.ARC_CreatedIn__c) : null;
            }
            if(updateValue == null) continue;

            agg.ARC_LimitValue__c = updateValue;
            if(agg.ARC_Code__c == 'AMCS__c' && indiPolAgg.get(agg.ARC_CreatedIn__c) != null){
                agg.ARC_FamilyAggregator__c = indiPolAgg.get(agg.ARC_CreatedIn__c).Id;
            }

            aggsModified.add(agg);
        }
        
        if(aggsToInsert.size() > 0) insert aggsToInsert;
        if(aggsModified.size() > 0) update aggsModified;
        aggregators.addAll(aggsToInsert);

        // CREATE PARTICIPANTS AGGREAGTORS FOR EACH AGGREGATORS
        for (InsurancePolicy pol : input) {
            for (ARC_Aggregator__c agg : aggregators) {
                if(agg.ARC_CreatedIn__c != pol.RenewedFromPolicyId) continue;
                if(agg.RecordType.Name == 'Family') continue;
                
                // CREATE PARTICIPANT AGGS
                for (InsurancePolicyParticipant part : pol.InsurancePolicyParticipants) {

                    if(
                        part.PrimaryParticipantContact.AccountId == agg.ARC_Member__c &&
                        agg.ARC_CreatedIn__c == pol.RenewedFromPolicyId
                    ) {
                        aggsPartToInsert.add(createParticipantAggs(pol, agg, part));
                    }
                }
            }
        }

        if(aggsPartToInsert.size() > 0) insert aggsPartToInsert;
    }

    // CREATE PARTICIPANT AGGREGATORS
    public static ARC_ParticipantAggregator__c createParticipantAggs(InsurancePolicy pol, ARC_Aggregator__c agg, InsurancePolicyParticipant part){
        ARC_ParticipantAggregator__c result = new ARC_ParticipantAggregator__c();
        result.Name = agg.Name;
        result.ARC_Aggregator__c = agg.Id;
        result.ARC_ConsumedValue__c = 0;
        result.ARC_PolicyParticipant__c = part.Id;
        result.ARC_Policy__c = pol.Id;
        return result;
    }

    // CREATE AGGREGATOR
    public static ARC_Aggregator__c createAggregator(Map<String, Object> aggData){
        String aggCode = (String)aggData.get('code');
        String aggType = '';
        
        // CALCULATE TYPE OF AGGREGATOR
        switch on aggCode {
            when 'ACC__c', 'HTERAPHPY__c', 'CHIRO__c', 'OFUC__c', 'PHYTH__c', 'CCS__c', 'MAMM__c', 'PROSCRE__c', 'FLXSIG__c', 'CLON__c', 'SSOPT__c' {
                aggType = 'Number';
            }
            when 'AMCS__c', 'PREEX__c', 'SHAMCS__c', 'TOB__c', 'ALGTEST__c', 'DME__c', 'MAT__c' {
                aggType = 'Currency';
            }
        }
        
        // CREATE AGGREGATOR
        ARC_Aggregator__c agg = new ARC_Aggregator__c();
        agg.Name = (String)aggData.get('name');
        agg.ARC_LimitValue__c = (Double)aggData.get('limit');
        agg.ARC_Year__c = (String)aggData.get('year');
        agg.RecordTypeId = (Id)aggData.get('recordTypeId');
        agg.ARC_FamilyAggregator__c = (Id)aggData.get('famAggregator');
        agg.ARC_CreatedIn__c = (Id)aggData.get('createdIn');
        agg.ARC_Member__c = (Id)aggData.get('member');
        agg.ARC_NextAvailabilityDate__c = (Date)aggData.get('nextUse');
        agg.ARC_Code__c = aggCode;
        agg.ARC_Type__c = aggType;
        return agg;
    }

    global void finish(Database.BatchableContext BC) {}
}