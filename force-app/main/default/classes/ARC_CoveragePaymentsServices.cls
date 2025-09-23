public with sharing class ARC_CoveragePaymentsServices {
    
    public static void createAggregators(List <ClaimCoveragePaymentDetail> inputItemList) {
        Set<Id> inputIds = (new Map<Id,SObject>(inputItemList)).keySet();
        Set<String> claimIds = new Set<String>();
        Set<String> claimCoverageIds = new Set<String>();
        Set<String> policyIds = new Set<String>();
        Map<String, Object> familyTermRemainingAmounts = new Map<String, Object>();
        Map<String, Object> individualTermRemainingAmounts = new Map<String, Object>();
        Set<Id> familyTermsDuplicated = new Set<Id>();
        Set<Id> individualTermsDuplicated = new Set<Id>();
        Set<Id> termsEntryDuplicated = new Set<Id>();
        Integer itemListLength = inputItemList.size();
        Integer currentIteration = 0;
        List<vlocity_ins_fsc__InsurancePolicyTermTrackingEntry__c> updateList = new List<vlocity_ins_fsc__InsurancePolicyTermTrackingEntry__c>();

        for (ClaimCoveragePaymentDetail item : inputItemList) {
            if (item.ARC_Claim__c != null) {
                claimIds.add(item.ARC_Claim__c);
            }
            claimCoverageIds.add(item.ClaimCoverageId);
        }

        List<ClaimCoveragePaymentDetail> inputCoveragePayments = [SELECT Name, Id, ARC_Claim__c, ClaimedAmount, ClaimCoverageId, ClaimParticipantRecipient.InsurancePolicyParticipantId, ClaimParticipantRecipient.InsurancePolicyParticipant.PrimaryParticipantContact.Name FROM ClaimCoveragePaymentDetail WHERE Id IN: inputIds LIMIT 2000];
        List<vlocity_ins_fsc__InsurancePolicyTermTrackingEntry__c> termsTracking = [SELECT Id, vlocity_ins_fsc__PostedAmount__c, vlocity_ins_fsc__PostedValue__c, vlocity_ins_fsc__RemainingAmount__c, vlocity_ins_fsc__InsurancePolicyTermId__c, vlocity_ins_fsc__RemainingValue__c  FROM vlocity_ins_fsc__InsurancePolicyTermTrackingEntry__c WHERE vlocity_ins_fsc__ClaimId__c IN: claimIds ORDER BY CreatedDate DESC LIMIT 2000];
        List<Claim> claimList = [SELECT Id, PolicyNumberId FROM Claim WHERE Id IN: claimIds LIMIT 1000];
        for (Claim clm : claimList) {
            policyIds.add(clm.PolicyNumberId);
        }
        List<InsurancePolicy> policyList = [SELECT Id FROM InsurancePolicy WHERE Id IN: policyIds LIMIT 1000];
        List<vlocity_ins_fsc__InsurancePolicyTerm__c> termList = [SELECT Id, Name, vlocity_ins_fsc__AttributeClass__c, vlocity_ins_fsc__DurationType__c, vlocity_ins_fsc__InitialAmount__c, vlocity_ins_fsc__InitialValue__c, vlocity_ins_fsc__InsurancePolicyCoverageId__c, vlocity_ins_fsc__InsurancePolicyId__c, vlocity_ins_fsc__IsActive__c, vlocity_ins_fsc__InsurancePolicyParticipantId__c  FROM vlocity_ins_fsc__InsurancePolicyTerm__c WHERE vlocity_ins_fsc__InsurancePolicyId__c IN: policyIds LIMIT 5000];

        for (ClaimCoveragePaymentDetail lineItem : inputCoveragePayments) {
            currentIteration += 1; 
            if (lineItem.ClaimedAmount != null && (lineItem.Status == 'Capitated' || lineItem.Status == 'Paid')) {
                for (Claim clm : claimList) {
                    if (clm.Id == lineItem.ARC_Claim__c) {
                        for (InsurancePolicy policy : policyList) {
                            if (policy.Id == clm.PolicyNumberId) {
                                for (vlocity_ins_fsc__InsurancePolicyTerm__c term : termList) {
                                    if (term.vlocity_ins_fsc__InsurancePolicyId__c == policy.Id) {
                                        String policyPartId = lineItem.ClaimParticipantRecipient.InsurancePolicyParticipantId;

                                        // --- Check if already exists policy term tracking entry ---
                                        if (termsTracking.size() == 0) {
                                            Map<String, Object> inputTermEntry = new Map<String, Object>();

                                            //  --- Check type of term ---
                                            if (term.vlocity_ins_fsc__AttributeClass__c == 'Deductible') {
                                                String trackingName = lineItem.ClaimParticipantRecipient.InsurancePolicyParticipant.PrimaryParticipantContact.Name + ' AMCS';
                                                
                                                //  --- Check if the term had already been created ---
                                                if (!familyTermsDuplicated.contains(term.Id) || !individualTermsDuplicated.contains(term.Id)) {
                                                    Double remainingValue = term.vlocity_ins_fsc__InitialValue__c - lineItem.ClaimedAmount < 0 ? 0 : term.vlocity_ins_fsc__InitialValue__c - lineItem.ClaimedAmount;
                                                    
                                                    inputTermEntry.put('name', term.Name.contains('Family') ? term.Name : trackingName);
                                                    inputTermEntry.put('claimId', clm.Id);
                                                    inputTermEntry.put('claimCoverageId', lineItem.ClaimCoverageId);
                                                    inputTermEntry.put('lineItemId', lineItem.Id);
                                                    inputTermEntry.put('participantId', term.Name.contains('Family') ? null : policyPartId);
                                                    inputTermEntry.put('termId', term.Id);
                                                    inputTermEntry.put('initialValue', term.vlocity_ins_fsc__InitialValue__c);
                                                    inputTermEntry.put('postedValue', lineItem.ClaimedAmount);
                                                    inputTermEntry.put('remainingValue', remainingValue);
                                                    inputTermEntry.put('calculatedValue', 0);
                                                    
                                                    updateList.add(createTermEntry(inputTermEntry));

                                                    // --- Store amount values depending on type of term ---
                                                    if (term.Name.contains('Family')) {
                                                        familyTermRemainingAmounts.put((String)term.Id, remainingValue);
                                                        familyTermsDuplicated.add(term.Id);
                                                    }else{
                                                        individualTermRemainingAmounts.put(term.Id, remainingValue);
                                                        individualTermsDuplicated.add(term.Id);
                                                    }
                                                    // -- Check if the term for the family
                                                }else if(familyTermsDuplicated.contains(term.Id) && term.Name.contains('Family')){

                                                    // --- Check if the term tracking has remaining amount ---
                                                    if (familyTermRemainingAmounts.get((String)term.Id) != 0) {
                                                        Double remainingValue = (Double)familyTermRemainingAmounts.get((String)term.Id) - lineItem.ClaimedAmount < 0 ? 0 : (Double)familyTermRemainingAmounts.get((String)term.Id) - lineItem.ClaimedAmount;

                                                        inputTermEntry.put('name', term.Name);
                                                        inputTermEntry.put('claimId', clm.Id);
                                                        inputTermEntry.put('claimCoverageId', lineItem.ClaimCoverageId);
                                                        inputTermEntry.put('lineItemId', lineItem.Id);
                                                        inputTermEntry.put('participantId', null);
                                                        inputTermEntry.put('termId', term.Id);
                                                        inputTermEntry.put('initialValue', familyTermRemainingAmounts.get((String)term.Id));
                                                        inputTermEntry.put('postedValue', lineItem.ClaimedAmount);
                                                        inputTermEntry.put('remainingValue', remainingValue);
                                                        inputTermEntry.put('calculatedValue', 0);
                                                        
                                                        updateList.add(createTermEntry(inputTermEntry));
                                                        familyTermRemainingAmounts.put((String)term.Id, remainingValue); 
                                                    }
                                                    // --- Check if already has been created a term for individual member ---
                                                }else if (individualTermsDuplicated.contains(term.Id) && !term.Name.contains('Family')) {
                                                    Double initialValue = (Double)individualTermRemainingAmounts.get(term.Id);
                                                    Double remainingValue = (Double)individualTermRemainingAmounts.get((String)term.Id) - lineItem.ClaimedAmount < 0 ? 0 : (Double)individualTermRemainingAmounts.get((String)term.Id) - lineItem.ClaimedAmount;

                                                    inputTermEntry.put('name', trackingName);
                                                    inputTermEntry.put('claimId', clm.Id);
                                                    inputTermEntry.put('claimCoverageId', lineItem.ClaimCoverageId);
                                                    inputTermEntry.put('lineItemId', lineItem.Id);
                                                    inputTermEntry.put('participantId', policyPartId);
                                                    inputTermEntry.put('termId', term.Id);
                                                    inputTermEntry.put('initialValue', initialValue);
                                                    inputTermEntry.put('postedValue', lineItem.ClaimedAmount);
                                                    inputTermEntry.put('remainingValue', remainingValue);
                                                    inputTermEntry.put('calculatedValue', 0);
                                                }

                                            }
                                        }else{
                                            for (vlocity_ins_fsc__InsurancePolicyTermTrackingEntry__c termTracking : termsTracking) {
                                                if (termTracking.vlocity_ins_fsc__InsurancePolicyTermId__c == term.Id) {
                                                    Map<String, Object> inputTermEntry = new Map<String, Object>();
                                                    //  --- Check if the terms had already been populated ---
                                                    if (term.vlocity_ins_fsc__AttributeClass__c == 'Deductible') {

                                                        //  --- Create the term tracking only if there are remaining value ---
                                                        if (termTracking.vlocity_ins_fsc__RemainingValue__c != 0) {
                                                            String trackingName = lineItem.ClaimParticipantRecipient.InsurancePolicyParticipant.PrimaryParticipantContact.Name + ' AMCS';
                                                            
                                                            //  --- Check if the term had already been populated ---
                                                            if (!termsEntryDuplicated.contains(term.Id)) {
                                                                Double remainingValue = termTracking.vlocity_ins_fsc__RemainingValue__c - lineItem.ClaimedAmount < 0 ? 0 : termTracking.vlocity_ins_fsc__RemainingValue__c - lineItem.ClaimedAmount;
        
                                                                inputTermEntry.put('name', term.Name.contains('Family') ? term.Name : trackingName);
                                                                inputTermEntry.put('claimId', clm.Id);
                                                                inputTermEntry.put('claimCoverageId', lineItem.ClaimCoverageId);
                                                                inputTermEntry.put('lineItemId', lineItem.Id);
                                                                inputTermEntry.put('participantId', term.Name.contains('Family') ? null : policyPartId);
                                                                inputTermEntry.put('termId', term.Id);
                                                                inputTermEntry.put('initialValue', termTracking.vlocity_ins_fsc__RemainingValue__c);
                                                                inputTermEntry.put('postedValue', lineItem.ClaimedAmount);
                                                                inputTermEntry.put('remainingValue', remainingValue);
                                                                inputTermEntry.put('calculatedValue', 0);
                                                                
                                                                updateList.add(createTermEntry(inputTermEntry));
                                                                termsEntryDuplicated.add(term.Id);
                                                                familyTermRemainingAmounts.put((String)term.Id, remainingValue);
                                                            }else{
                                                                // --- Check if the term tracking has remaining amount ---
                                                                if (familyTermRemainingAmounts.get((String)term.Id) != 0) {
                                                                    Double remainingValue = (Double)familyTermRemainingAmounts.get((String)term.Id) - lineItem.ClaimedAmount < 0 ? 0 : (Double)familyTermRemainingAmounts.get((String)term.Id) - lineItem.ClaimedAmount;
    
                                                                    inputTermEntry.put('name', term.Name.contains('Family') ? term.Name : trackingName);
                                                                    inputTermEntry.put('claimId', clm.Id);
                                                                    inputTermEntry.put('claimCoverageId', lineItem.ClaimCoverageId);
                                                                    inputTermEntry.put('lineItemId', lineItem.Id);
                                                                    inputTermEntry.put('participantId', term.Name.contains('Family') ? null : policyPartId);
                                                                    inputTermEntry.put('termId', term.Id);
                                                                    inputTermEntry.put('initialValue', familyTermRemainingAmounts.get((String)term.Id));
                                                                    inputTermEntry.put('postedValue', lineItem.ClaimedAmount);
                                                                    inputTermEntry.put('remainingValue', remainingValue);
                                                                    inputTermEntry.put('calculatedValue', 0);
                                                                    
                                                                    updateList.add(createTermEntry(inputTermEntry));
                                                                    familyTermRemainingAmounts.put((String)term.Id, remainingValue); 
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                upsert updateList;
            }else{
                System.debug('Claim item without ClaimedAmount: ' + lineItem.Id);
            }
        }
    }

    public static vlocity_ins_fsc__InsurancePolicyTermTrackingEntry__c createTermEntry(Map<String, Object> inputMap){
        String name = String.valueOf(inputMap.get('name'));
        String claimId = String.valueOf(inputMap.get('claimId'));
        String claimCoverageId = String.valueOf(inputMap.get('claimCoverageId'));
        String lineItemId = String.valueOf(inputMap.get('lineItemId'));
        String participantId = String.valueOf(inputMap.get('participantId'));
        String termId = String.valueOf(inputMap.get('termId'));
        Double initialValue = Double.valueOf(inputMap.get('initialValue'));
        Double postedValue = Double.valueOf(inputMap.get('postedValue'));
        Double remainingValue = Double.valueOf(inputMap.get('remainingValue'));
        Double calculatedValue = Double.valueOf(inputMap.get('calculatedValue'));

        vlocity_ins_fsc__InsurancePolicyTermTrackingEntry__c newTermTracking = new vlocity_ins_fsc__InsurancePolicyTermTrackingEntry__c();
        newTermTracking.Name = name;
        newTermTracking.vlocity_ins_fsc__ClaimId__c = claimId;
        newTermTracking.vlocity_ins_fsc__ClaimCoverageId__c = claimCoverageId;
        newTermTracking.vlocity_ins_fsc__ClaimCoveragePaymentDetailId__c = lineItemId;
        newTermTracking.vlocity_ins_fsc__InsurancePolicyParticipantId__c = participantId;
        newTermTracking.vlocity_ins_fsc__InsurancePolicyTermId__c = termId;
        newTermTracking.vlocity_ins_fsc__InitialValue__c = initialValue;
        newTermTracking.vlocity_ins_fsc__PostedValue__c = postedValue;
        newTermTracking.vlocity_ins_fsc__RemainingValue__c = remainingValue;
        newTermTracking.vlocity_ins_fsc__CalculatedInitialValue__c = calculatedValue;
        
        return newTermTracking;
    }

}