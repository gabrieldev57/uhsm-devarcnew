global class ARC_PolicyServices implements Database.Batchable<sObject>, Database.Stateful {
    private String whereClause;
    private static final List<String> ONE_TIME = new List<String>{'CCS__c', 'MAMM__c', 'PROSCRE__c', 'FLXSIG__c', 'CLON__c', 'SSOPT__c'};
    private static final List<String> LIFETIME = new List<String>{'ALGTEST__c'};
    private static final List<String> BACKFILLCODES = new List<String>{'CCS__c', 'MAMM__c', 'PROSCRE__c', 'FLXSIG__c', 'CLON__c', 'SSOPT__c', 'ALGTEST__c', 'DME__c','MAT__c'};
    private static final List<String> UPGRADE_REASONS = new List<String>{'Program Upgrade', 'New Application', 'Upgraded Spin Off'};
    private static final Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
    
    public ARC_PolicyServices(String whereClause) {
        this.whereClause = whereClause;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String queryString = 'SELECT Id, Name, ARC_PolicyReason__c, Product.Name, RenewedFromPolicyId, Product.ProductCode,ARC_EffectiveDate__c,' +
                             '(SELECT Id, Name, PrimaryParticipantContact.AccountId FROM InsurancePolicyParticipants), ' +
                             '(SELECT Id, Name FROM ParticipantAggregators__r) ' +
                             'FROM InsurancePolicy ' +
                             'WHERE ' + whereClause;
        return Database.getQueryLocator(queryString);
    }

    global void execute(Database.BatchableContext BC, List<InsurancePolicy> scope) {
        List<String> polReasons = scope[0].ARC_PolicyReason__c.split('<br>');
        Boolean isUpgrade = false;

        for (String reason : polReasons) {
            if (UPGRADE_REASONS.contains(reason)) {
                isUpgrade = true;
                break;
            }
        }
        if (isUpgrade) {
            createNewAggsUpgrade(scope);
        } else {
            createNewAggsCarryOver(scope);
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('finish');
    }

    public static void createNewAggsUpgrade(List<InsurancePolicy> policies){
        List<ARC_Aggregator__c> aggsToInsert = new List<ARC_Aggregator__c>();
        List<ARC_ParticipantAggregator__c> partAggsToInsert = new List<ARC_ParticipantAggregator__c>();
        Map<Id, Id> memberToIPP = new Map<Id, Id>();
        for (InsurancePolicy pol : policies) {
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(pol.Product.ProductCode);
            if(aggValues == null || pol.InsurancePolicyParticipants==null) continue;
            for (InsurancePolicyParticipant part : pol.InsurancePolicyParticipants) {
                for (Schema.SObjectField field : aggValues.getSObjectType().getDescribe().fields.getMap().values()) {
                    if(!String.valueOf(field).startsWith('IND_') || aggValues.get(field) == null) continue;
                    String aggCode = String.valueOf(field).replace('IND_', '');
                    //Only create new Aggs
                    if(!BACKFILLCODES.contains(aggCode)) continue;
                    Map<String, Object> inputAgg = new Map<String, Object>();
                    inputAgg.put('name', field.getDescribe().getLabel());
                    inputAgg.put('limit', Double.valueOf((Double)aggValues.get(field)));
                    inputAgg.put('recordTypeId', individualAggRT);
                    inputAgg.put('code', aggCode);
                    inputAgg.put('member', part.PrimaryParticipantContact.AccountId);
                    inputAgg.put('createdIn', pol.Id); 
    
                    if(!ONE_TIME.contains(aggCode) && !LIFETIME.contains(aggCode)) inputAgg.put('year', '2024');
                    else if(ONE_TIME.contains(aggCode)) inputAgg.put('nextUse', pol.ARC_EffectiveDate__c);
                    aggsToInsert.add(createAggregator(inputAgg));
                    memberToIPP.put(part.PrimaryParticipantContact.AccountId, part.Id);
                }
            }
        }
        if(aggsToInsert.size() > 0) insert aggsToInsert;
    
        for (ARC_Aggregator__c agg : aggsToInsert) {
    
            ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c();
            newPartAgg.Name = agg.Name;
            newPartAgg.ARC_Aggregator__c = agg.Id;
            newPartAgg.ARC_ConsumedValue__c = 0;
            newPartAgg.ARC_PolicyParticipant__c = memberToIPP.get(agg.ARC_Member__c);
            newPartAgg.ARC_Policy__c = agg.ARC_CreatedIn__c;
    
            partAggsToInsert.add(newPartAgg);
        }
        if(partAggsToInsert.size() > 0) insert partAggsToInsert;
    
    }
    
    public static void createNewAggsCarryOver(List<InsurancePolicy> policies){
        List<ARC_Aggregator__c> aggsToInsert = new List<ARC_Aggregator__c>();
        List<ARC_ParticipantAggregator__c> partAggsToInsertFirst = new List<ARC_ParticipantAggregator__c>();
        List<ARC_ParticipantAggregator__c> partAggsToInsertSecond = new List<ARC_ParticipantAggregator__c>();
        Set<Id> participantWithPartAgg = new Set<Id>();
    
        Map<Id, Id> memberToIPP = new Map<Id, Id>();
        Map<Id,Id> oldPolToNewPol = new Map<Id,Id>(); 
        for (InsurancePolicy pol : policies) {
            oldPolToNewPol.put(pol.RenewedFromPolicyId, pol.Id);
            for(InsurancePolicyParticipant part: pol.InsurancePolicyParticipants) {
                memberToIPP.put(part.PrimaryParticipantContact.AccountId, part.Id);
            }
        }
        List<ARC_Aggregator__c> existingAggs = [SELECT Id, Name, ARC_Member__c, ARC_CreatedIn__c, ARC_Code__c FROM ARC_Aggregator__c WHERE ARC_Code__c IN :BACKFILLCODES AND ARC_CreatedIn__c IN:oldPolToNewPol.keyset()];
        for (ARC_Aggregator__c agg: existingAggs) {
            ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c();
            newPartAgg.Name = agg.Name;
            newPartAgg.ARC_Aggregator__c = agg.Id;
            newPartAgg.ARC_ConsumedValue__c = 0;
            newPartAgg.ARC_PolicyParticipant__c = memberToIPP.get(agg.ARC_Member__c);
            newPartAgg.ARC_Policy__c = oldPolToNewPol.get(agg.ARC_CreatedIn__c);
            partAggsToInsertFirst.add(newPartAgg);
            participantWithPartAgg.add(newPartAgg.ARC_PolicyParticipant__c);
        }
        if(partAggsToInsertFirst.size() > 0) insert partAggsToInsertFirst;
        for (InsurancePolicy pol : policies) {
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(pol.Product.ProductCode);
            if(aggValues == null || pol.InsurancePolicyParticipants==null) continue;
            for(InsurancePolicyParticipant part: pol.InsurancePolicyParticipants) {
                if(participantWithPartAgg.contains(part.Id)) continue;
                for (Schema.SObjectField field : aggValues.getSObjectType().getDescribe().fields.getMap().values()) {
                    if(!String.valueOf(field).startsWith('IND_') || aggValues.get(field) == null) continue;
                    String aggCode = String.valueOf(field).replace('IND_', '');
                    //Only create new Aggs
                    if(!BACKFILLCODES.contains(aggCode)) continue;
                    Map<String, Object> inputAgg = new Map<String, Object>();
                    inputAgg.put('name', field.getDescribe().getLabel());
                    inputAgg.put('limit', Double.valueOf((Double)aggValues.get(field)));
                    inputAgg.put('recordTypeId', individualAggRT);
                    inputAgg.put('code', aggCode);
                    inputAgg.put('member', part.PrimaryParticipantContact.AccountId);
                    inputAgg.put('createdIn', pol.RenewedFromPolicyId); 
    
                    if(!ONE_TIME.contains(aggCode) && !LIFETIME.contains(aggCode)) inputAgg.put('year', '2024');
                    else if(ONE_TIME.contains(aggCode)) inputAgg.put('nextUse', pol.ARC_EffectiveDate__c);
                    aggsToInsert.add(createAggregator(inputAgg));
                }
            }
        }
        if(aggsToInsert.size() > 0) insert aggsToInsert;
    
        for (ARC_Aggregator__c agg : aggsToInsert) {
    
            ARC_ParticipantAggregator__c newPartAgg = new ARC_ParticipantAggregator__c();
            newPartAgg.Name = agg.Name;
            newPartAgg.ARC_Aggregator__c = agg.Id;
            newPartAgg.ARC_ConsumedValue__c = 0;
            newPartAgg.ARC_PolicyParticipant__c = memberToIPP.get(agg.ARC_Member__c);
            newPartAgg.ARC_Policy__c = oldPolToNewPol.get(agg.ARC_CreatedIn__c);
    
            partAggsToInsertSecond.add(newPartAgg);
        }
        if(partAggsToInsertSecond.size() > 0) insert partAggsToInsertSecond;
    }
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
        agg.ARC_CreatedIn__c = (Id)aggData.get('createdIn');
        agg.ARC_Member__c = (Id)aggData.get('member');
        agg.ARC_NextAvailabilityDate__c = (Date)aggData.get('nextUse');
        agg.ARC_Code__c = aggCode;
        agg.ARC_Type__c = aggType;
        return agg;
    }
}