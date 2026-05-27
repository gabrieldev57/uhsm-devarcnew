global class ARC_ProgramDowngradeBackfill implements Database.Batchable<sObject>, Database.Stateful {
    private String whereClause;

    public ARC_ProgramDowngradeBackfill(String whereClause) {
        this.whereClause = whereClause;
    }

    public ARC_ProgramDowngradeBackfill() {
        this.whereClause = whereClause;
    }

    // EVALUAR SI PARA SPIN OFF APLICA IGUAL
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id';
        if (this.whereClause != null) {
            query += ' WHERE ' + this.whereClause;
        } else {
            query += ' WHERE ARC_Contract__r.ARC_ContractReasons__c INCLUDES (\'Program Downgrade\', \'Aging Out\')';
            query += ' ORDER BY ARC_Contract__r.ActivatedDate ASC';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<InsurancePolicy> input) {
        Set<Id> policysPDIdSet = new Set<Id>();
        Set<Id> renewedPolicySet = new Set<Id>();
        for (InsurancePolicy policy : input) {
            policysPDIdSet.add(policy.Id);
            if (policy.RenewedFromPolicyId != null) {
                renewedPolicySet.add(policy.RenewedFromPolicyId);
            } else {
                renewedPolicySet.add(policy.Id);
            }
        }
        List<InsurancePolicy> policysPD = [
            SELECT Id, PriorPolicyId, RenewedFromPolicyId, ARC_Contract__r.ARC_ContractReason__c, Product.ProductCode,
                (SELECT Id, Name, ARC_Year__c, ARC_Member__c, RecordTypeId
                FROM Aggregators__r),
                (SELECT Id, ARC_Aggregator__r.Name, ARC_Aggregator__r.ARC_Year__c, ARC_Aggregator__r.ARC_Member__c, ARC_Aggregator__r.RecordTypeId, ARC_Aggregator__r.ARC_Code__c, ARC_Aggregator__r.ARC_Type__c, ARC_Aggregator__r.ARC_NextAvailabilityDate__c, ARC_Aggregator__c
                FROM ParticipantAggregators__r)
            FROM InsurancePolicy
            WHERE Id IN :policysPDIdSet
        ];
        List<InsurancePolicy> policysAssociatedToPD = [
            SELECT Id, PriorPolicyId
            FROM InsurancePolicy
            WHERE RenewedFromPolicyId IN :renewedPolicySet
        ];
        Map<Id, List<InsurancePolicy>> priorPolicyToPolicys = new Map<Id, List<InsurancePolicy>>();
        for (InsurancePolicy policy : policysAssociatedToPD) {
            if (!priorPolicyToPolicys.containsKey(policy.PriorPolicyId)) {
                priorPolicyToPolicys.put(policy.PriorPolicyId, new List<InsurancePolicy>());
            }
            priorPolicyToPolicys.get(policy.PriorPolicyId).add(policy);
        }

        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        // Key: PolicyId - Year
        Map<String, ARC_Aggregator__c> familyAggregatorToUpsert = new Map<String, ARC_Aggregator__c>();
        Map<String, List<ARC_Aggregator__c>> indAMCSPerPolicyYearMap = new Map<String, List<ARC_Aggregator__c>>();
        // Key: PolicyId - Name - Year - Member
        Map<String, ARC_Aggregator__c> aggregatorsToUpsertPerPolicyMap = new Map<String, ARC_Aggregator__c>();
        for (InsurancePolicy policyPD : policysPD) {
            for (ARC_Aggregator__c agg : policyPD.Aggregators__r) {
                if (agg.RecordTypeId == familyAggRT) {
                    familyAggregatorToUpsert.put(policyPD.Id + '-' + agg.ARC_Year__c, agg);
                } else if (agg.RecordTypeId == individualAggRT) {
                    String key = getAggregatorsToInsertPerPolicyKey(policyPD.Id, agg);
                    aggregatorsToUpsertPerPolicyMap.put(key, agg);
                    if (agg.Name == 'Individual AMCS') {
                        if (!indAMCSPerPolicyYearMap.containsKey(policyPD.Id + '-' + agg.ARC_Year__c)) {
                            indAMCSPerPolicyYearMap.put(policyPD.Id + '-' + agg.ARC_Year__c, new List<ARC_Aggregator__c>());
                        }
                        indAMCSPerPolicyYearMap.get(policyPD.Id + '-' + agg.ARC_Year__c).add(agg);
                    }
                }
            }
        }

        // Update Policys RenewedFrom with PD
        List<InsurancePolicy> policiesToUpdate = new List<InsurancePolicy>();
        for (InsurancePolicy policyPD : policysPD) {
            List<InsurancePolicy> policysWithPrior = priorPolicyToPolicys.get(policyPD.Id);
            for (InsurancePolicy policy : policysWithPrior) {
                Id renewedPolicyId;
                if (policyPD.Status == 'Voided') {
                    renewedPolicyId = policyPD.RenewedFromPolicyId;
                } else {
                    renewedPolicyId = policyPD.Id;
                }
                reassignPolicyRenewedPolicy(policy, renewedPolicyId, priorPolicyToPolicys, policiesToUpdate);
            }
        }
        update policiesToUpdate;
        // VER CASOS CON PD VOIDEDS

        Map<ARC_ParticipantAggregator__c, ARC_Aggregator__c> partAggToAggregatorMap = new Map<ARC_ParticipantAggregator__c, ARC_Aggregator__c>();        
        for (InsurancePolicy policy : policysPD) {
            Id renewedPolicyId;
            if (policy.Status == 'Voided') {
                renewedPolicyId = policy.RenewedFromPolicyId;
            } else {
                renewedPolicyId = policy.Id;
            }
            reassignParticipantAggregators(policy, renewedPolicyId, policy.Product.ProductCode, priorPolicyToPolicys, aggregatorsToUpsertPerPolicyMap, partAggToAggregatorMap, indAMCSPerPolicyYearMap);
        }
        createFamilyAggregators(policysPD, familyAggregatorToUpsert, aggregatorsToUpsertPerPolicyMap);

        // Insert Family
        try {
            upsert familyAggregatorToUpsert.values();
        } catch (Exception e) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{
                'ignacio.ferreiro@arcsona.com', 
                'agustin.garay@arcsona.com'
            }); 
            mail.setSubject('Apex Exception Occurred');
            mail.setPlainTextBody('Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }

        // Upsert Individual Aggregators
        for (String key : familyAggregatorToUpsert.keySet()) {
            String[] parts = key.split('-');
            String policyId = parts[0];
            String year = parts[1];
            List<ARC_Aggregator__c> indAMCSAggregators = indAMCSPerPolicyYearMap.get(key);
            for (ARC_Aggregator__c indAMCS : indAMCSAggregators) {
                indAMCS.ARC_FamilyAggregator__c = familyAggregatorToUpsert.get(key).Id;
            }
        }
        try {
            upsert aggregatorsToUpsertPerPolicyMap.values();
        } catch (Exception e) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{
                'ignacio.ferreiro@arcsona.com', 
                'agustin.garay@arcsona.com'
            }); 
            mail.setSubject('Apex Exception Occurred');
            mail.setPlainTextBody('Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }

        // Update ParticipantAggregators
        Set<ARC_ParticipantAggregator__c> partAggToUpdate = partAggToAggregatorMap.keySet();
        for (ARC_ParticipantAggregator__c partAgg : partAggToUpdate) {
            ARC_Aggregator__c agg = partAggToAggregatorMap.get(partAgg);
            partAgg.ARC_Aggregator__c = agg.Id;
        }
        try {
            update new List<ARC_ParticipantAggregator__c>(partAggToUpdate);
        } catch (Exception e) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[]{
                'ignacio.ferreiro@arcsona.com', 
                'agustin.garay@arcsona.com'
            }); 
            mail.setSubject('Apex Exception Occurred');
            mail.setPlainTextBody('Exception: ' + e.getMessage() + '\nStack Trace:\n' + e.getStackTraceString());
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        }
    }

    private void reassignPolicyRenewedPolicy(InsurancePolicy policyToUpdate, Id renewedPolicyId, Map<Id, List<InsurancePolicy>> priorPolicyToPolicys, List<InsurancePolicy> policiesToUpdate) {
        policyToUpdate.RenewedFromPolicyId = renewedPolicyId;
        policiesToUpdate.add(policyToUpdate);
        if (!policyToUpdate.ARC_Contract__r.ARC_ContractReason__c.contains('Program Downgrade') && !policyToUpdate.ARC_Contract__r.ARC_ContractReason__c.contains('Aging Out')) {
            List<InsurancePolicy> policysWithPrior = priorPolicyToPolicys.get(policyToUpdate.Id);
            for (InsurancePolicy policy : policysWithPrior) {
                reassignPolicyRenewedPolicy(policy, renewedPolicyId, priorPolicyToPolicys, policiesToUpdate);
            }
        }
    }

    private void reassignParticipantAggregators(InsurancePolicy policy, Id renewedPolicyId, String productCode, Map<Id, List<InsurancePolicy>> priorPolicyToPolicys, Map<String, ARC_Aggregator__c> aggregatorsToUpsertPerPolicyMap, Map<ARC_ParticipantAggregator__c, ARC_Aggregator__c> partAggToAggregatorMap, Map<String, List<ARC_Aggregator__c>> indAMCSPerPolicyYearMap) {
        for (ARC_ParticipantAggregator__c partAgg : policy.ParticipantAggregators__r) {
            String key = getAggregatorsToInsertPerPolicyKey(renewedPolicyId, partAgg.ARC_Aggregator__r);
            ARC_Aggregator__c newAggregator;
            if (!aggregatorsToUpsertPerPolicyMap.containsKey(key)) {
                newAggregator = createAggregator(partAgg, renewedPolicyId, productCode);
                aggregatorsToUpsertPerPolicyMap.put(key, newAggregator);
            } else {
                newAggregator = aggregatorsToUpsertPerPolicyMap.get(key);
            }
            partAggToAggregatorMap.put(partAgg, newAggregator);
            if (newAggregator.Name == 'Individual AMCS') {
                if (!indAMCSPerPolicyYearMap.containsKey(renewedPolicyId + '-' + newAggregator.ARC_Year__c)) {
                    indAMCSPerPolicyYearMap.put(renewedPolicyId + '-' + newAggregator.ARC_Year__c, new List<ARC_Aggregator__c>());
                }
                indAMCSPerPolicyYearMap.get(renewedPolicyId + '-' + newAggregator.ARC_Year__c).add(newAggregator);
            }
            List<InsurancePolicy> policysWithPrior = priorPolicyToPolicys.get(policy.Id);
            for (InsurancePolicy pol : policysWithPrior) {
                if (pol.RenewedFromPolicyId == renewedPolicyId) {
                    reassignParticipantAggregators(pol, renewedPolicyId, productCode, priorPolicyToPolicys, aggregatorsToUpsertPerPolicyMap, partAggToAggregatorMap, indAMCSPerPolicyYearMap);
                }
            }
        }
    }

    // Key: RenewedPolicyId + '-' + Aggregator.Name + '-' + Year + '-' + Member
    private String getAggregatorsToInsertPerPolicyKey(Id renewedPolicyId, ARC_Aggregator__c aggregator) {
        String key = renewedPolicyId + '-' + aggregator.Name;
        if (aggregator.ARC_Year__c != null) {
            key += '-' + aggregator.ARC_Year__c;
        } else {
            key += '-null';
        }
        if (aggregator.ARC_Member__c != null) {
            key += '-' + aggregator.ARC_Member__c;
        } else {
            key += '-null';
        }
        return key;
    }

    private ARC_Aggregator__c createAggregator(ARC_ParticipantAggregator__c partAgg, Id renewedPolicyId, String productCode) {
        Id individualAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Individual').getRecordTypeId();
        ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(productCode);
        ARC_Aggregator__c newAggregator = new ARC_Aggregator__c();
        newAggregator.Name = partAgg.ARC_Aggregator__r.Name;
        newAggregator.ARC_NextAvailabilityDate__c = partAgg.ARC_Aggregator__r.ARC_NextAvailabilityDate__c;
        newAggregator.ARC_Year__c = partAgg.ARC_Aggregator__r.ARC_Year__c;
        newAggregator.ARC_CreatedIn__c = renewedPolicyId;
        newAggregator.ARC_Member__c = partAgg.ARC_Aggregator__r.ARC_Member__c;
        newAggregator.ARC_Type__c = partAgg.ARC_Aggregator__r.ARC_Type__c;
        newAggregator.ARC_Code__c = partAgg.ARC_Aggregator__r.ARC_Code__c;
        newAggregator.RecordTypeId = individualAggRT;
        newAggregator.ARC_LimitValue__c = Double.valueOf((Double)aggValues.get(partAgg.ARC_Aggregator__r.Name));
        //newAggregator.ARC_CarryOverAggregator__c = partAgg.ARC_Aggregator__c;
        return newAggregator;
    }

    private void createFamilyAggregators(List<InsurancePolicy> policysPD, Map<String, ARC_Aggregator__c> familyAggregatorToUpsert, Map<String, ARC_Aggregator__c> aggregatorsToUpsertPerPolicyMap) {
        Id familyAggRT = Schema.SObjectType.ARC_Aggregator__c.getRecordTypeInfosByName().get('Family').getRecordTypeId();
        Map<Id, Set<String>> yearsPerPolicyMap = new Map<Id, Set<String>>();
        for (String key : aggregatorsToUpsertPerPolicyMap.keySet()) {
            String[] parts = key.split('-');
            String policyId = parts[0];
            String year = parts[2];
            if (year != 'null') {
                if (!yearsPerPolicyMap.containsKey(policyId)) {
                    yearsPerPolicyMap.put(policyId, new Set<String>());
                }
                yearsPerPolicyMap.get(policyId).add(year);
            }
        }
        for (InsurancePolicy policy : policysPD) {
            ARC_ProductAggregators__mdt aggValues = ARC_ProductAggregators__mdt.getInstance(policy.Product.ProductCode);
            for (Schema.SObjectField expectedAggregator : getAggregatorsFields(aggValues)) {
                if (!isFamilyAggregator(expectedAggregator) || aggValues.get(expectedAggregator) == null) continue;
                for (String year : yearsPerPolicyMap.get(policy.Id)) {
                    if (familyAggregatorToUpsert.containsKey(policy.Id + '-' + year)) continue;
                    ARC_Aggregator__c newFamilyAggregator = new ARC_Aggregator__c();
                    newFamilyAggregator.Name = 'Family AMCS';
                    newFamilyAggregator.ARC_CreatedIn__c = policy.Id;
                    newFamilyAggregator.ARC_Year__c = year;
                    newFamilyAggregator.RecordTypeId = familyAggRT;
                    newFamilyAggregator.ARC_LimitValue__c = Double.valueOf((Double)aggValues.get(expectedAggregator));
                    familyAggregatorToUpsert.put(policy.Id + '-' + year, newFamilyAggregator);
                }
            }
        }
    }

    public List<Schema.SObjectField> getAggregatorsFields(ARC_ProductAggregators__mdt aggregatorValues) {
        return aggregatorValues.getSObjectType().getDescribe().fields.getMap().values();
    }

    public Boolean isFamilyAggregator(Schema.SObjectField aggregatorField) {
        return String.valueOf(aggregatorField).startsWith('FAM_');
    }

    global void finish(Database.BatchableContext BC) {
        /*
        NOTAS:
        - Aggregators del Upgrade que son del producto PD pero no del Upgrade seguirán creados en el Update, pero sin PartAgg
        - Hasta no crear fields nuevos, actualizar createmissing y flows de calculo no se puede correr
        - CreateMissing necesita logica separada para PD y para Upgrade la última Policy no incluye cambio de producto
        */
    }
}