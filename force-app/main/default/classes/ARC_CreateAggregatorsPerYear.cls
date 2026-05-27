global class ARC_CreateAggregatorsPerYear implements Database.Batchable<sObject> {
	private static final Integer starting_year = 2025; // Set to the year that the aggregators haven't been created yet.
	private static final List<String> UPGRADE_REASONS = new List<String>{ 'Program Upgrade', 'New Application', 'Upgraded Spin Off' };

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(
			[
				SELECT
					Id,
					RenewedFromPolicyId,
					RenewedFromPolicy.ARC_Contract__r.Status,
					RenewedFromPolicy.ARC_Contract__r.ARC_ContractReason__c,
					ARC_Contract__r.Status,
					ARC_Contract__r.ARC_ContractReason__c,
					(
						SELECT
                            Id,
                            Name,
                            ARC_Year__c,
                            ARC_CurrentValue__c,
                            ARC_FamilyCurrentValue__c,
                            ARC_Member__c,
                            ARC_CreatedIn__c,
                            ARC_LimitValue__c,
                            ARC_BY1_Current__c,
                            ARC_BY1_Date__c,
                            ARC_BY1_Limit__c,
                            ARC_BY2_Current__c,
                            ARC_BY2_Date__c,
                            ARC_BY2_Limit__c,
                            ARC_BY3_Current__c,
                            ARC_BY3_Date__c,
                            ARC_BY3_Limit__c,
                            ARC_Type__c
						FROM Aggregators__r
						WHERE ARC_Year__c = :String.valueOf(starting_year - 1)
						ORDER BY Name ASC
					), // El order es importante aqui, para que el aggregator familiar se itere antes que el individual
					(SELECT Id, InsurancePolicyId, PrimaryParticipantContact.AccountId FROM InsurancePolicyParticipants)
				FROM InsurancePolicy
				WHERE ARC_Contract__r.Status = 'Activated'
			]
		);
	}

	global void execute(Database.BatchableContext BC, List<InsurancePolicy> all_activated_policies) {
		//Map to store the new family aggregators, once inserted use the id to populate the lookup field in the policy
		List<String> carry_over_upgrade_ids = new List<String>();

		for (InsurancePolicy p : all_activated_policies) {
			Boolean is_carry_upgrade = p.RenewedFromPolicyId != null && UPGRADE_REASONS.contains(p.RenewedFromPolicy.ARC_Contract__r.ARC_ContractReason__c);
			Boolean is_carry_terminated = p.RenewedFromPolicyId != null && p.RenewedFromPolicy.ARC_Contract__r.Status == 'Terminated';

			if (is_carry_upgrade && is_carry_terminated) {
				carry_over_upgrade_ids.add(p.RenewedFromPolicyId);
			}
		}

		// Traer informacion de los aggregators de los carry over
		Map<Id, InsurancePolicy> carry_over_upgrades_map = new Map<Id, InsurancePolicy>(
			[
				SELECT
					Id,
					ARC_Contract__r.ARC_ContractReason__c,
					ARC_Contract__r.Status,
					(
						SELECT
                            Id,
                            Name,
                            ARC_Year__c,
                            ARC_CurrentValue__c,
                            ARC_FamilyCurrentValue__c,
                            ARC_Member__c,
                            ARC_CreatedIn__c,
                            ARC_LimitValue__c,
                            ARC_BY1_Current__c,
                            ARC_BY1_Date__c,
                            ARC_BY1_Limit__c,
                            ARC_BY2_Current__c,
                            ARC_BY2_Date__c,
                            ARC_BY2_Limit__c,
                            ARC_BY3_Current__c,
                            ARC_BY3_Date__c,
                            ARC_BY3_Limit__c,
                            ARC_Type__c
						FROM Aggregators__r
						WHERE ARC_Year__c = :String.valueOf(starting_year - 1)
						ORDER BY Name ASC
					) // El order es importante aqui, para que el aggregator familiar se itere antes que el individual
				FROM InsurancePolicy
				WHERE Id IN :carry_over_upgrade_ids AND ARC_Contract__r.Status = 'Terminated'
			]
		);

		//Recorrer y categorizar en upgrade o carry over

		Map<String, ARC_Aggregator__c> policyId_to_new_family_aggregator = new Map<String, ARC_Aggregator__c>();
		Map<ARC_Aggregator__c, ARC_Aggregator__c> old_to_new_individual_aggregators_map = new Map<ARC_Aggregator__c, ARC_Aggregator__c>();

		for (InsurancePolicy p : all_activated_policies) {
			Boolean is_upgrade = UPGRADE_REASONS.contains(p.ARC_Contract__r.ARC_ContractReason__c);
			Boolean is_carry = carry_over_upgrades_map.containsKey(p.RenewedFromPolicyId);

			//Si es un upgrade
			if (is_upgrade || is_carry) {
				if (is_carry) {
					p = carry_over_upgrades_map.get(p.RenewedFromPolicyId);
				}

				//Recorrer aggregators 2024 y crear uno nuevo con el año 2025
				for (ARC_Aggregator__c old_aggregator : p.Aggregators__r) {
					//Clone all the values
					ARC_Aggregator__c new_aggregator = old_aggregator.clone(false,false,false,false);
					new_aggregator.Id = null;
					//Increase ARC_Year by 1
					new_aggregator.ARC_Year__c = String.valueOf(Integer.valueOf(old_aggregator.ARC_Year__c) + 1);

					/* Si es family aggregator, ademas resetear el familycurrentvalue y
					 agregarlo a un mapa para vincularlo cuando lo inserte a la policy */
					if (old_aggregator.Name == 'Family AMCS') {
						new_aggregator.ARC_FamilyCurrentValue__c = 0;
						policyId_to_new_family_aggregator.put(p.Id, new_aggregator);
					}
					/* Si es un aggregator individual, resetearle el current value */
					else {
						// new_aggregator.ARC_CurrentValue__c = 0; No se pone en cero por que es un rollup summary de los participant aggregators
						old_to_new_individual_aggregators_map.put(old_aggregator, new_aggregator);
					}
				}
			}
		}

		/* Se inserta primero los deductibles familiares */
		insert policyId_to_new_family_aggregator.values();
		/* Una vez insertados los deductibles familiares, en cada poliza el lookup que apunta al deducible familiar se cambia y se updatean
        ESTO ESTA PENDIENTE DE CHEQUEAR EN QUE POLIZAS SE ACTUALIZA */

		/* Una vez insertados los deductibles familiares, se popula el lookup en el deductible individual y se insertan */
		for (ARC_Aggregator__c individual_aggregator : old_to_new_individual_aggregators_map.values()) {
			if (individual_aggregator.Name == 'Individual AMCS') {
                if(policyId_to_new_family_aggregator.get(individual_aggregator.ARC_CreatedIn__c) != null){
                    individual_aggregator.ARC_FamilyAggregator__c = policyId_to_new_family_aggregator.get(individual_aggregator.ARC_CreatedIn__c).Id;
                }
			}
		}

		insert old_to_new_individual_aggregators_map.values();
		/* Una vez todos los nuevos aggregators son insertados, recorrer las polizas activadas, y crear los participant aggregators */

		List<ARC_ParticipantAggregator__c> participant_aggregators_to_insert = new List<ARC_ParticipantAggregator__c>();

		for (InsurancePolicy p : all_activated_policies) {
			Boolean is_upgrade = UPGRADE_REASONS.contains(p.ARC_Contract__r.ARC_ContractReason__c);
			Boolean is_carry = carry_over_upgrades_map.containsKey(p.RenewedFromPolicyId);

			InsurancePolicy aggregators_policy = p;

			if (is_upgrade || is_carry) {
				if (is_carry) {
					aggregators_policy = carry_over_upgrades_map.get(p.RenewedFromPolicyId);
				}

				for (ARC_Aggregator__c old_aggregator : aggregators_policy.Aggregators__r) {
					for (InsurancePolicyParticipant participant : p.InsurancePolicyParticipants) {
						if (participant.PrimaryParticipantContact.AccountId == old_aggregator.ARC_Member__c) {
			                if (old_aggregator.Name != 'Family AMCS') {
                                ARC_ParticipantAggregator__c new_participant_aggregator = new ARC_ParticipantAggregator__c();
                                new_participant_aggregator.ARC_Policy__c = p.Id;
                                new_participant_aggregator.ARC_ConsumedValue__c = 0;
                                new_participant_aggregator.ARC_PolicyParticipant__c = participant.Id;
                                if(old_to_new_individual_aggregators_map.get(old_aggregator) != null){
                                    new_participant_aggregator.ARC_Aggregator__c = old_to_new_individual_aggregators_map.get(old_aggregator).Id;
                                }
                                new_participant_aggregator.Name = old_aggregator.Name;

                                participant_aggregators_to_insert.add(new_participant_aggregator);
                            }
						}
					}
				}
			}
		}
	}

	global void finish(Database.BatchableContext BC) {
		System.debug('finish');
	}
}