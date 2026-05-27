/**
 * Small group pricing: runs the Integration Procedure to get rated products, applies Group Class
 * contribution rules, and returns product pricing with base price, employee/employer splits, and
 * pay period. Supports legacy vs non-legacy member pricing and optional dependents/age overrides.
 * @author Felipe Cladera
 * @date 2025-02-03
 */
 public with sharing class ARC_getRatedProductsWithContributions {
    private static Boolean useAgeAtEnrollmentFromPayload = false;

    @TestVisible
    private static Object testPricingIpResponse;

    @TestVisible
    private static Object testLegacyPricingIpResponse;

	///////////////////////////////
	// --- Public classes ---
	///////////////////////////////

	/** DTO for member context (name, age, primary, legacy). @author Felipe Cladera @date 2025-02-03 */
	public class MemberInput {
		public String Name;
		public Integer Age;
		public Integer PrimaryAge;
		public Boolean IsPrimary;
		public String PrimaryId;
		public Boolean IsLegacy;
	}
 
	///////////////////////////////
	// --- Private classes ---
	///////////////////////////////

	/** Wrapper for IP result: product name to price map and tier factor. @author Felipe Cladera @date 2025-02-03 */
	private class RatedProductsResult {
        public Map<String, Decimal> productPriceMap;
        public Decimal tierFactorValue;
    }

	/** Holds contribution record and method for a member. When program-based, each product has its own contribution (via contributionByProductId). @author Felipe Cladera @date 2025-02-03 */
	private class ContributionInfo {
        vlocity_ins__GroupClassContribution__c contribution;
        /** When ARC_ApplyProgramBased__c is true: Product2 Id -> GroupClassContribution for that product (contribution points to product via ARC_ContractLineItem__r.vlocity_ins__Product2Id__c). */
        Map<Id, vlocity_ins__GroupClassContribution__c> contributionByProductId;
        String contributionMethod;
	}

	/** Application exception for REST/backend; use instead of AuraHandledException when not in Aura/Visualforce. */
	private class RatedProductsException extends Exception {}

	/** Returns JSON object with single key "error" for REST; avoids throwing in non-Aura context. */
	private static String errorJson(String message) {
		if (message == null) message = 'Unknown error';
		String escaped = message.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n').replace('\r', '\\r');
		return '{"error":"' + escaped + '"}';
	}

	/**
	 * Group class is already scoped to a census employee type (e.g. separate Full Time vs Part Time classes).
	 * Picklist may store None as API value "None".
	 */
	@TestVisible
	private static Boolean groupClassDiscriminatesByEmployeeType(vlocity_ins__GroupClass__c gc) {
		if (gc == null) {
			return false;
		}
		String t = gc.ARC_EmployeeType__c;
		return String.isNotBlank(t) && !'none'.equalsIgnoreCase(t.trim());
	}

	/**
	 * When true, contribution SOQL adds AND ARC_EmployeeType__c = census member ARC_EmployeeType__c.
	 * Use when FT/PT is modeled on contribution rows (FullTime_PartTime) and not already on the group class.
	 */
	@TestVisible
	private static Boolean filterGroupClassContributionsByCensusEmployeeType(vlocity_ins__GroupClass__c gc) {
		return gc != null
			&& gc.ARC_EmployeeTypeModel__c == 'FullTime_PartTime'
			&& !groupClassDiscriminatesByEmployeeType(gc);
	}

	/**
	 * Group class already scoped to a single Exempt / Non-Exempt division on ARC_EmployeeDivision__c.
	 */
	@TestVisible
	private static Boolean groupClassDiscriminatesByEmployeeDivision(vlocity_ins__GroupClass__c gc) {
		if (gc == null) {
			return false;
		}
		String division = gc.ARC_EmployeeDivision__c;
		return String.isNotBlank(division) && !'none'.equalsIgnoreCase(division.trim());
	}

	/**
	 * When true, contribution SOQL adds AND ARC_EmployeeDivision__c = census member ARC_EmployeeDivision__c.
	 * Applies when Exempt/Non-Exempt is modeled on contribution rows, unless division is already pinned on the group class.
	 */
	@TestVisible
	private static Boolean filterContributionsByCensusEmployeeDivision(vlocity_ins__GroupClass__c gc) {
		return gc != null
			&& gc.ARC_EmployeeTypeModel__c == 'Exempt_NonExempt'
			&& !groupClassDiscriminatesByEmployeeDivision(gc);
	}

	/** Counts non-null enrollment payload members for tier-based contribution; excludes IsLegacy members. */
	private static Integer countInputMembers(List<MemberInput> memberDataList) {
		if (memberDataList == null) {
			return 0;
		}
		Integer count = 0;
		for (MemberInput mi : memberDataList) {
			if (mi != null && mi.IsLegacy != true) {
				count++;
			}
		}
		return count;
	}

	/**
	 * Maps household size from enrollment input (non-legacy members only) to ARC_EmployeeTier__c on GroupClassContribution.
	 * 1 = Employee Only, 2 = Employee Plus One, 3+ = Family.
	 */
	@TestVisible
	private static String resolveEmployeeTierFromInputMemberCount(Integer memberCount) {
		if (memberCount == null || memberCount <= 0) {
			return null;
		}
		if (memberCount == 1) {
			return 'Employee Only';
		}
		if (memberCount == 2) {
			return 'Employee Plus One';
		}
		return 'Family';
	}

	/** Tier for contribution SOQL: input member count when provided, else census member field. */
	private static String resolveEmployeeTierForContribution(
		Boolean applyEmployeeTier,
		Integer inputMemberCount,
		vlocity_ins__GroupCensusMember__c primaryMember
	) {
		if (applyEmployeeTier != true) {
			return null;
		}
		if (inputMemberCount != null && inputMemberCount > 0) {
			return resolveEmployeeTierFromInputMemberCount(inputMemberCount);
		}
		return primaryMember != null ? primaryMember.ARC_EmployeeTier__c : null;
	}

	private static final String SENIOR_PRODUCT_CODE = 'PROG_UHSM_WeShareGroupSenior';
	private static final String SENIOR_PRODUCT_NAME_PREFIX = 'WeShare Group Senior';
	/** inputMemberCount for Employee Only tier on GroupClassContribution rows. */
	private static final Integer SENIOR_CONTRIBUTION_TIER_MEMBER_COUNT = 1;

	/** Senior / legacy-priced product returned from the separate legacy IP (not "Legacy" in product name). */
	@TestVisible
	private static Boolean isSeniorProduct(String productName, Product2 product) {
		if (product != null && SENIOR_PRODUCT_CODE == product.ProductCode) {
			return true;
		}
		return productName != null && productName.startsWith(SENIOR_PRODUCT_NAME_PREFIX);
	}

	/** Product line bucket for Percent Of Lowest By Category (Enhanced, Essential, Senior, Premier). */
	private static String resolveProductLineCategory(String productName) {
		if (productName == null || productName.containsIgnoreCase('Legacy')) {
			return null;
		}
		if (productName.containsIgnoreCase('Enhanced')) {
			return 'Enhanced';
		}
		if (productName.containsIgnoreCase('Essential')) {
			return 'Essential';
		}
		if (productName.containsIgnoreCase('Premier')) {
			return 'Premier';
		}
		if (isSeniorProduct(productName, null)) {
			return 'Senior';
		}
		return null;
	}

	private static Map<String, Decimal> filterSeniorBasePrices(Map<String, Decimal> pricedProducts) {
		Map<String, Decimal> seniorPrices = new Map<String, Decimal>();
		if (pricedProducts == null) {
			return seniorPrices;
		}
		for (String productName : pricedProducts.keySet()) {
			if (isSeniorProduct(productName, null)) {
				seniorPrices.put(productName, pricedProducts.get(productName));
			}
		}
		return seniorPrices;
	}

	private static Boolean mergedPriceMapHasSeniorProduct(Map<String, Decimal> mergedPriceMap) {
		return mergedPriceMap != null && !filterSeniorBasePrices(mergedPriceMap).isEmpty();
	}

	/** Lowest base among non-Legacy, non-Senior products (pool for Percent Of Lowest Cost). */
	private static Decimal computeLowestBaseExcludingLegacyAndSenior(Map<String, Decimal> priceMap) {
		if (priceMap == null) {
			return null;
		}
		Decimal lowestBasePrice = null;
		for (String pname : priceMap.keySet()) {
			if (pname == null || pname.containsIgnoreCase('Legacy') || isSeniorProduct(pname, null)) {
				continue;
			}
			Decimal bp = priceMap.get(pname);
			if (bp != null && (lowestBasePrice == null || bp < lowestBasePrice)) {
				lowestBasePrice = bp;
			}
		}
		return lowestBasePrice;
	}

	/**
	 * Prefers CMGC row whose related group class ARC_EmployeeType__c matches the census member (separate FT/PT classes).
	 * Falls back to GC with blank/None type (single class for all types), then any row for member+contract.
	 */
	public static Id resolveCmgcGroupClassId(Id memberId, Id contractId) {
		/*String empType = censusMember != null ? censusMember.ARC_EmployeeType__c : null;
		if (String.isNotBlank(empType)) {
			List<ARC_CensusMemberGroupClass__c> exact = [
				SELECT ARC_GroupClass__c
				FROM ARC_CensusMemberGroupClass__c
				WHERE ARC_CensusMember__c = :memberId
				AND ARC_GroupClass__r.ARC_Contract__c = :contractId
				AND ARC_GroupClass__r.ARC_EmployeeType__c = :empType
				LIMIT 1
			];
			if (!exact.isEmpty()) {
				return exact[0].ARC_GroupClass__c;
			}
		}
		List<ARC_CensusMemberGroupClass__c> untypedGc = [
			SELECT ARC_GroupClass__c
			FROM ARC_CensusMemberGroupClass__c
			WHERE ARC_CensusMember__c = :memberId
			AND ARC_GroupClass__r.ARC_Contract__c = :contractId
			AND (ARC_GroupClass__r.ARC_EmployeeType__c = null OR ARC_GroupClass__r.ARC_EmployeeType__c = 'None')
			LIMIT 1
		];
		if (!untypedGc.isEmpty()) {
			return untypedGc[0].ARC_GroupClass__c;
		}*/
		List<ARC_CensusMemberGroupClass__c> anyRow = [
			SELECT ARC_GroupClass__c
			FROM ARC_CensusMemberGroupClass__c
			WHERE ARC_CensusMember__c = :memberId
			AND ARC_GroupClass__r.ARC_Contract__c = :contractId
			LIMIT 1
		];
		return anyRow.isEmpty() ? null : anyRow[0].ARC_GroupClass__c;
	}

	///////////////////////////////
	// --- Public API (entry points) ---
	///////////////////////////////

	/**
	 * Returns JSON of products with contributions for explicit member data; supports legacy vs non-legacy pricing.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	public static String getProductsWithContributionsJson(List<MemberInput> memberDataList) {
		if (memberDataList == null || memberDataList.isEmpty()) {
			return '{}';
		} 
		String primaryIdStr = null;
		Boolean primaryIsLegacy = false;
		for (MemberInput mi : memberDataList) {
			if (mi != null && mi.IsPrimary == true && String.isNotBlank(mi.PrimaryId)) {
				primaryIdStr = mi.PrimaryId;
				primaryIsLegacy = (mi.IsLegacy == true);
				break;
			}
		}
		if (primaryIdStr == null) {
			for (MemberInput mi : memberDataList) {
				if (mi != null && String.isNotBlank(mi.PrimaryId)) {
					primaryIdStr = mi.PrimaryId;
					primaryIsLegacy = (mi.IsLegacy == true);
					break;
				}
			}
		}
		if (String.isBlank(primaryIdStr)) {
			return errorJson('PrimaryId is required in memberDataList');
		}
		try {
        Id primaryCensusMemberId = (Id)primaryIdStr;
        Integer primaryAgeFromInput = null;
        for (MemberInput mi : memberDataList) {
            if (mi != null && mi.IsPrimary == true) {
                if (mi.PrimaryAge != null) {
                    primaryAgeFromInput = mi.PrimaryAge;
                } else if (mi.Age != null) {
                    primaryAgeFromInput = mi.Age;
                }
                break;
            }
        }
        Integer totalMembers = memberDataList.size();
        Integer explicitLegacyCount = 0;
        for (MemberInput mi : memberDataList) {
            if (mi != null && mi.IsLegacy == true) explicitLegacyCount++;
        }
        Integer memberCountLegacy = explicitLegacyCount;
        Integer memberCountNonLegacy = Math.max(0, totalMembers - memberCountLegacy);
        Boolean hasLegacy = memberCountLegacy > 0;
        Integer dependentsNormal = Math.max(0, totalMembers - 1 - memberCountLegacy);
        Integer dependentsLegacy = Math.max(0, memberCountLegacy - 1);

        List<vlocity_ins__GroupCensusMember__c> primaryMembers = [
            SELECT Id,
                   ARC_Age__c,
                   ARC_AgeAtEnrollment__c,
                   vlocity_ins__TotalDependents__c,
                   vlocity_ins__AccountId__r.ARC_GroupAccount__c,
                   vlocity_ins__AccountId__r.ARC_GroupAccount__r.BillingState
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id = :primaryCensusMemberId
            AND vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];
        if (primaryMembers.isEmpty()) {
            System.debug('debugPricing [L109]: ' + ' No records returned for object: vlocity_ins__GroupCensusMember__c (primaryMembers)');
        } else {
            System.debug('debugPricing [L111]: ' + ' vlocity_ins__GroupCensusMember__c (primaryMembers): ' + primaryMembers.size() + ' record(s) - ' + primaryMembers);
        }
        if (primaryMembers.isEmpty()) {
            return errorJson('Primary census member not found');
        }
        vlocity_ins__GroupCensusMember__c primaryMember = primaryMembers[0];

        List<Contract> contractsForPricing = [
            SELECT Id
            FROM Contract
            WHERE AccountId = :primaryMember.vlocity_ins__AccountId__r.ARC_GroupAccount__c
            AND (Status = 'Activated' OR Status = 'Enrollment In Progress')
            LIMIT 1
        ];
        if (contractsForPricing.isEmpty()) {
            System.debug('debugPricing [L118a]: No records returned for object: Contract (contractId resolution)');
            return errorJson('Contract not found');
        }
        System.debug('debugPricing [L118b]: Contract (contractId resolution): ' + contractsForPricing.size() + ' record(s) - ' + contractsForPricing);
        Id contractId = contractsForPricing[0].Id;

        Date effectiveDate = Date.today();
        String monthStr = String.valueOf(effectiveDate.month());
        String dayStr = String.valueOf(effectiveDate.day());
        if (monthStr.length() == 1) monthStr = '0' + monthStr;
        if (dayStr.length() == 1) dayStr = '0' + dayStr;
        String effectiveDateStr = String.valueOf(effectiveDate.year()) + '-' + monthStr + '-' + dayStr;

        Map<String, Object> normalBody = buildPricingIpBody(primaryMember, effectiveDateStr, dependentsNormal, primaryAgeFromInput);
        System.debug('debugPricing [L126]: ' + ' buildPricingIpBody done; normalBody=' + (normalBody != null ? String.valueOf(normalBody) : null));

        Map<String, Object> legacyBody = null;
        if (hasLegacy) {
            Integer legacyAge = primaryAgeFromInput;
            legacyBody = buildPricingIpBody(primaryMember, effectiveDateStr, dependentsLegacy, legacyAge);
        }

        String procedureAPIName = 'smallGroup_GetProducts';
        Object resultObj = (Test.isRunningTest() && testPricingIpResponse != null)
            ? testPricingIpResponse
            : vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, normalBody, null);
        if (resultObj == null) {
            System.debug('debugPricing [L137]: ' + ' IP smallGroup_GetProducts returned null.');
        } else {
            Map<String, Object> ipOut = (Map<String, Object>) resultObj;
            System.debug('debugPricing [L140]: ' + ' IP smallGroup_GetProducts keys=' + (ipOut != null ? String.valueOf(ipOut) : null));
            Object productsObj = ipOut != null ? ipOut.get('products') : null;
            System.debug('debugPricing [L142]: ' + ' IP products present=' + (productsObj != null));
        }
        Object legacyResultObj = null;
        if (hasLegacy) {
            legacyResultObj = (Test.isRunningTest() && testLegacyPricingIpResponse != null)
                ? testLegacyPricingIpResponse
                : vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, legacyBody, null);
        }

        RatedProductsResult normalRes = extractRatedProductsResult((Map<String, Object>) resultObj);
        if (normalRes == null) {
            System.debug('debugPricing [L151]: ' + ' extractRatedProductsResult returned null.');
        } else if (normalRes.productPriceMap == null || normalRes.productPriceMap.isEmpty()) {
            System.debug('debugPricing [L153]: ' + ' extractRatedProductsResult productPriceMap empty or null; tierFactorValue=' + normalRes.tierFactorValue);
        } else {
            System.debug('debugPricing [L155]: ' + ' extractRatedProductsResult productPriceMap size=' + normalRes.productPriceMap.size() + ', keys=' + normalRes.productPriceMap.keySet());
        }
		Map<String, Decimal> mergedPriceMap = new Map<String, Decimal>();
		if (normalRes != null && normalRes.productPriceMap != null) {
			mergedPriceMap.putAll(normalRes.productPriceMap);
		}

		Decimal tierFactorValue = normalRes != null ? normalRes.tierFactorValue : null;

        if (hasLegacy && legacyResultObj != null) {
            RatedProductsResult legacyRes = extractRatedProductsResult((Map<String, Object>) legacyResultObj);
			if (legacyRes != null && legacyRes.productPriceMap != null) {
				for (String productName : legacyRes.productPriceMap.keySet()) {
                    Boolean isLegacyProductName = (productName != null) &&
                        (productName.containsIgnoreCase('Legacy') || productName == 'WeShare Group Senior');
                    if (!isLegacyProductName) continue;
					mergedPriceMap.put(productName, legacyRes.productPriceMap.get(productName));
				}
			}
			if (tierFactorValue == null && legacyRes != null) {
				tierFactorValue = legacyRes.tierFactorValue;
			}
		}

		if (mergedPriceMap.isEmpty()) {
			System.debug('debugPricing [L180]: ' + ' Returning empty JSON: mergedPriceMap is empty (IP returned no products or extraction failed).');
			return '{}';
		}

		Integer inputMemberCount = countInputMembers(memberDataList);
		ContributionInfo contribInfo = getContributionInfo(primaryCensusMemberId, contractId, inputMemberCount);
		Boolean hasSeniorProduct = mergedPriceMapHasSeniorProduct(mergedPriceMap);
		ContributionInfo seniorContribInfo = hasSeniorProduct
			? getContributionInfo(primaryCensusMemberId, contractId, SENIOR_CONTRIBUTION_TIER_MEMBER_COUNT)
			: null;
		System.debug('debugPricing [L185]: getProductsWithContributionsJson inputMemberCount=' + inputMemberCount + ', resolvedTier=' + resolveEmployeeTierFromInputMemberCount(inputMemberCount) + ', seniorTier=' + resolveEmployeeTierFromInputMemberCount(SENIOR_CONTRIBUTION_TIER_MEMBER_COUNT) + ', hasSeniorProduct=' + hasSeniorProduct + ', contribInfo method=' + (contribInfo != null ? contribInfo.contributionMethod : 'null') + (contribInfo != null && contribInfo.contribution != null ? ', Contribution Id=' + contribInfo.contribution.Id + ', vlocity_ins__GroupClassId__c=' + contribInfo.contribution.vlocity_ins__GroupClassId__c + ', ARC_EmployeeType__c=' + contribInfo.contribution.ARC_EmployeeType__c + ', ARC_EmployeeTier__c=' + contribInfo.contribution.ARC_EmployeeTier__c + ', vlocity_ins__ContributionAmount__c=' + contribInfo.contribution.vlocity_ins__ContributionAmount__c + ', vlocity_ins__ContributionPercent__c=' + contribInfo.contribution.vlocity_ins__ContributionPercent__c : ', Contribution=null'));
		Map<String, Decimal> householdTierPrices = new Map<String, Decimal>(mergedPriceMap);
		if (hasSeniorProduct) {
			for (String seniorName : filterSeniorBasePrices(mergedPriceMap).keySet()) {
				householdTierPrices.remove(seniorName);
			}
		}
		Map<String, Decimal> priceWithContributionMap = calculateMemberContribution(primaryCensusMemberId, householdTierPrices, contractId, inputMemberCount);
		if (hasSeniorProduct) {
			Map<String, Decimal> seniorPrices = filterSeniorBasePrices(mergedPriceMap);
			if (!seniorPrices.isEmpty()) {
				priceWithContributionMap.putAll(
					calculateMemberContribution(
						primaryCensusMemberId,
						seniorPrices,
						contractId,
						SENIOR_CONTRIBUTION_TIER_MEMBER_COUNT,
						mergedPriceMap
					)
				);
			}
		}

		Map<String, Product2> productByName = new Map<String, Product2>();
		List<Product2> productList = [SELECT Id, Name, ProductCode FROM Product2 WHERE Name IN :mergedPriceMap.keySet()];
		if (productList.isEmpty()) {
			System.debug('debugPricing [L191]: ' + ' No records returned for object: Product2');
		} else {
			System.debug('debugPricing [L193]: ' + ' Product2: ' + productList.size() + ' record(s) - ' + productList);
		}
		for (Product2 p : productList) {
			productByName.put(p.Name, p);
		}

		Map<String, Object> productsJson = new Map<String, Object>();
        String seniorProductCodeToExcludeWhenNonLegacy = 'PROG_UHSM_WeShareGroupSenior';
		Map<String, Decimal> flatContributionByCategoryForOutput = null;
		Map<String, Decimal> lowestByCategoryForOutput = null;
		Boolean useProgramBasedContrib = (contribInfo != null && contribInfo.contributionByProductId != null && !contribInfo.contributionByProductId.isEmpty());
		if (contribInfo != null && 'Percent_Of_Lowest_By_Category'.equals(contribInfo.contributionMethod) && (contribInfo.contribution != null || useProgramBasedContrib)) {
			lowestByCategoryForOutput = new Map<String, Decimal>();
			for (String pname : mergedPriceMap.keySet()) {
				String cat = resolveProductLineCategory(pname);
				if (cat == null) {
					continue;
				}
				Decimal pr = mergedPriceMap.get(pname);
				if (pr == null) continue;
				if (!lowestByCategoryForOutput.containsKey(cat) || pr < lowestByCategoryForOutput.get(cat)) {
					lowestByCategoryForOutput.put(cat, pr);
				}
			}
			if (contribInfo.contribution != null && contribInfo.contribution.vlocity_ins__ContributionPercent__c != null) {
				flatContributionByCategoryForOutput = new Map<String, Decimal>();
				for (String cat : lowestByCategoryForOutput.keySet()) {
					flatContributionByCategoryForOutput.put(cat, lowestByCategoryForOutput.get(cat) * (contribInfo.contribution.vlocity_ins__ContributionPercent__c / 100));
				}
			}
		}
		for (String productName : mergedPriceMap.keySet()) {
            Product2 p2 = productByName.get(productName);
            if (!hasLegacy && p2 != null && p2.ProductCode == seniorProductCodeToExcludeWhenNonLegacy) {
                continue;
            }
			Decimal basePrice = mergedPriceMap.get(productName);
            if (basePrice == null) {
                String payPeriod = null;
                try {
                    List<vlocity_ins__GroupCensusMember__c> censusMemberList = [
                        SELECT Id,
                               vlocity_ins__CensusId__r.vlocity_ins__GroupId__r.ARC_PayPeriod__c
                        FROM vlocity_ins__GroupCensusMember__c
                        WHERE Id = :primaryCensusMemberId
                        LIMIT 1
                    ];
                    if (censusMemberList.isEmpty()) {
                        System.debug('debugPricing [L240]: ' + ' No records returned for object: vlocity_ins__GroupCensusMember__c (censusMember noPrice)');
                    } else {
                        System.debug('debugPricing [L242]: ' + ' vlocity_ins__GroupCensusMember__c (censusMember noPrice): ' + censusMemberList.size() + ' record(s) - ' + censusMemberList);
                    }
                    vlocity_ins__GroupCensusMember__c censusMember = censusMemberList.isEmpty() ? null : censusMemberList[0];
                    if (censusMember != null &&
                        censusMember.vlocity_ins__CensusId__r != null &&
                        censusMember.vlocity_ins__CensusId__r.vlocity_ins__GroupId__r != null) {
                        payPeriod = censusMember.vlocity_ins__CensusId__r.vlocity_ins__GroupId__r.ARC_PayPeriod__c;
                    }
                } catch (Exception ignore) {}
                Map<String, Object> noPriceNode = new Map<String, Object>();
                noPriceNode.put('noPrice', true);
                noPriceNode.put('message', 'No price available');
                noPriceNode.put('ARC_PayPeriod__c', payPeriod);
                noPriceNode.put('employeeSplitPeriod', null);
                noPriceNode.put('productId', p2 != null ? p2.Id : null);
                noPriceNode.put('productCode', p2 != null ? p2.ProductCode : null);
                productsJson.put(productName, noPriceNode);
                continue;
            }
			Decimal priceWithContribution = priceWithContributionMap.containsKey(productName)
				? priceWithContributionMap.get(productName)
				: basePrice;

			Decimal individualPrice = null;
			if (basePrice != null && tierFactorValue != null && tierFactorValue != 0) {
				individualPrice = basePrice / tierFactorValue;
			}

			String contributionType = null;
			Decimal contributionAmount = null;
			Decimal employerSplit = null;
			ContributionInfo contribForProductResolution = contribInfo;
			if (hasSeniorProduct && isSeniorProduct(productName, p2) && seniorContribInfo != null) {
				contribForProductResolution = seniorContribInfo;
			}
			// Resolve contribution for this product: program-based uses contribution linked to this product (via Contract Line Item -> Product2 Id).
			vlocity_ins__GroupClassContribution__c contributionForProduct = null;
			if (contribForProductResolution != null && contribForProductResolution.contributionMethod != null) {
				if (contribForProductResolution.contributionByProductId != null && !contribForProductResolution.contributionByProductId.isEmpty() && p2 != null) {
					contributionForProduct = contribForProductResolution.contributionByProductId.get(p2.Id);
				} else {
					contributionForProduct = contribForProductResolution.contribution;
				}
			}
			if (contribForProductResolution != null && contributionForProduct != null && contribForProductResolution.contributionMethod != null) {
				String method = contribForProductResolution.contributionMethod;
				if (method == 'Flat_Amount' || method == 'Flat Amount') {
					contributionType = 'Amount';
					contributionAmount = contributionForProduct.vlocity_ins__ContributionAmount__c;
					employerSplit = contributionAmount;
				} else if (method == 'Flat_Percentage' || method == 'Flat Percentage') {
					contributionType = 'Percent';
					contributionAmount = contributionForProduct.vlocity_ins__ContributionPercent__c;
					if (contributionAmount != null && basePrice != null) {
						employerSplit = basePrice * (contributionAmount / 100);
					}
				} else if (method == 'Percent_Of_Lowest_Cost' || method == 'Percent Of Lowest Cost') {
					contributionType = 'Percent';
					contributionAmount = contributionForProduct.vlocity_ins__ContributionPercent__c;
					Decimal lowestBase = null;
					for (String pname : mergedPriceMap.keySet()) {
						if (pname != null && (pname.containsIgnoreCase('Legacy') || isSeniorProduct(pname, null))) {
							continue;
						}
						Decimal bp = mergedPriceMap.get(pname);
						if (bp != null && (lowestBase == null || bp < lowestBase)) {
							lowestBase = bp;
						}
					}
					if (lowestBase != null && contributionForProduct.vlocity_ins__ContributionPercent__c != null) {
						employerSplit = lowestBase * (contributionForProduct.vlocity_ins__ContributionPercent__c / 100);
					}
				} else if (method == 'Percent_Of_Lowest_By_Category') {
					String category = resolveProductLineCategory(productName);
					if (category != null && flatContributionByCategoryForOutput != null && flatContributionByCategoryForOutput.containsKey(category)) {
						employerSplit = flatContributionByCategoryForOutput.get(category);
					} else if (category != null && lowestByCategoryForOutput != null && lowestByCategoryForOutput.containsKey(category) && contributionForProduct.vlocity_ins__ContributionPercent__c != null) {
						employerSplit = lowestByCategoryForOutput.get(category) * (contributionForProduct.vlocity_ins__ContributionPercent__c / 100);
					}
					if (employerSplit != null) {
						contributionType = 'Percent';
						contributionAmount = contributionForProduct.vlocity_ins__ContributionPercent__c;
					}
				}
			}

			// Products with "Legacy" in the name (not WeShare Group Senior) get no employer contribution.
			Boolean isLegacyProduct = (productName != null && productName.containsIgnoreCase('Legacy')
				&& !isSeniorProduct(productName, p2));
			Decimal nodeTierFactorForOutput = tierFactorValue;
			if (isLegacyProduct) {
				priceWithContribution = basePrice;
				employerSplit = 0;
				nodeTierFactorForOutput = tierFactorValue;
			}

			Decimal basePrice2 = basePrice != null ? basePrice.setScale(2, System.RoundingMode.HALF_UP) : null;
			Decimal priceWithContribution2 = priceWithContribution != null ? priceWithContribution.setScale(2, System.RoundingMode.HALF_UP) : null;
			// No output node shall have a negative value; if contribution leads to negative, return zero.
			if (priceWithContribution2 != null && priceWithContribution2 < 0) priceWithContribution2 = 0;
			Decimal individualPrice2 = individualPrice != null ? individualPrice.setScale(2, System.RoundingMode.HALF_UP) : null;
			Decimal employerSplit2 = employerSplit != null ? employerSplit.setScale(2, System.RoundingMode.HALF_UP) : null;
			if (employerSplit2 != null && employerSplit2 < 0) employerSplit2 = 0;
			Decimal contributionAmount2 = contributionAmount != null ? contributionAmount.setScale(2, System.RoundingMode.HALF_UP) : null;
			Decimal tierFactorValue2 = nodeTierFactorForOutput != null ? nodeTierFactorForOutput.setScale(2, System.RoundingMode.HALF_UP) : null;

			String payPeriod = null;
			try {
				List<vlocity_ins__GroupCensusMember__c> censusMemberListPay = [
					SELECT Id,
					       vlocity_ins__CensusId__r.vlocity_ins__GroupId__r.ARC_PayPeriod__c
					FROM vlocity_ins__GroupCensusMember__c
					WHERE Id = :primaryCensusMemberId
					LIMIT 1
				];
				if (censusMemberListPay.isEmpty()) {
					System.debug('debugPricing [L341]: ' + ' No records returned for object: vlocity_ins__GroupCensusMember__c (censusMember payPeriod)');
				} else {
					System.debug('debugPricing [L343]: ' + ' vlocity_ins__GroupCensusMember__c (censusMember payPeriod): ' + censusMemberListPay.size() + ' record(s) - ' + censusMemberListPay);
				}
				vlocity_ins__GroupCensusMember__c censusMember = censusMemberListPay.isEmpty() ? null : censusMemberListPay[0];
				if (censusMember != null &&
					censusMember.vlocity_ins__CensusId__r != null &&
					censusMember.vlocity_ins__CensusId__r.vlocity_ins__GroupId__r != null) {
					payPeriod = censusMember.vlocity_ins__CensusId__r.vlocity_ins__GroupId__r.ARC_PayPeriod__c;
				}
			} catch (Exception ignore) {}

            Decimal employeeSplitPeriod2 = calculateEmployeeSplitPeriod(priceWithContribution2, payPeriod);

			Map<String, Object> productNode = new Map<String, Object>();
			productNode.put('productId', p2 != null ? p2.Id : null);
			productNode.put('productCode', p2 != null ? p2.ProductCode : null);
			productNode.put('basePrice', basePrice2);
			productNode.put('priceWithContributions', priceWithContribution2);
			productNode.put('individualPrice', individualPrice2);
			productNode.put('tierFactorValue', tierFactorValue2);
			productNode.put('contributionType', contributionType);
			productNode.put('contributionAmount', contributionAmount2);
			productNode.put('employeeSplit', priceWithContribution2);
			productNode.put('employeeSplitPeriod', employeeSplitPeriod2);
			productNode.put('employerSplit', employerSplit2);
			productNode.put('ARC_PayPeriod__c', payPeriod);

			productsJson.put(productName, productNode);

            if (hasLegacy && memberCountLegacy > 1 && p2 != null && p2.ProductCode == 'PROG_UHSM_WeShareGroupSenior') {
                Integer duplicatesToAdd = memberCountLegacy - 1;
                for (Integer i = 2; i <= memberCountLegacy; i++) {
                    String dupKey = productName + ' (' + String.valueOf(i) + ')';
                    if (productsJson.containsKey(dupKey)) continue;
                    productsJson.put(dupKey, new Map<String, Object>(productNode));
                }
            }
		}

		String outJson = JSON.serialize(productsJson);
		return outJson;
		} catch (Exception e) {
			return errorJson(e.getMessage());
		}
	}

	public static String getProductsWithContributionsJsonFromString(String memberDataJson) {
		if (String.isBlank(memberDataJson)) {
			return '{}';
		}
		List<MemberInput> members = new List<MemberInput>();
        useAgeAtEnrollmentFromPayload = false;
		try {
			List<Object> raw = (List<Object>)JSON.deserializeUntyped(memberDataJson);
			for (Object o : raw) {
				Map<String, Object> m = (Map<String, Object>)o;
                if (m.containsKey('useAgeAtEnrollment') &&
                    String.valueOf(m.get('useAgeAtEnrollment')).toLowerCase() == 'true') {
                    useAgeAtEnrollmentFromPayload = true;
                }
				MemberInput mi = new MemberInput();
				mi.Name = (String)m.get('Name');
				Object ageObj = m.get('Age');
				mi.Age = ageObj == null ? null : Integer.valueOf(String.valueOf(ageObj));
				Object pAgeObj = m.get('PrimaryAge');
				mi.PrimaryAge = pAgeObj == null ? null : Integer.valueOf(String.valueOf(pAgeObj));
				mi.IsPrimary = m.containsKey('IsPrimary') ? (Boolean)m.get('IsPrimary') : false;
				mi.PrimaryId = (String)m.get('PrimaryId');
				mi.IsLegacy = m.containsKey('IsLegacy') ? (Boolean)m.get('IsLegacy') : false;
				members.add(mi);
			}
		} catch (Exception e) {
			return errorJson('Invalid memberData JSON: ' + e.getMessage());
		}
        try {
		    return getProductsWithContributionsJson(members);
        } finally {
            useAgeAtEnrollmentFromPayload = false;
        }
	}


    ///////////////////////////////
	// --- Auxiliary (helper) methods ---
	///////////////////////////////

	/**
	 * Returns the curv score factor for the primary census member from the group account (used in pricing).
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	private static Decimal getCurvScoreFactorFromMember(Id primaryCensusMemberId) {
        if (primaryCensusMemberId == null) {
            throw new RatedProductsException('Primary census member not found');
        }

        List<vlocity_ins__GroupCensusMember__c> pcm = [
            SELECT Id, vlocity_ins__AccountId__r.ARC_GroupAccount__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id = :primaryCensusMemberId
            LIMIT 1
        ];
        if (pcm.isEmpty()) {
            System.debug('debugPricing [L433]: ' + ' No records returned for object: vlocity_ins__GroupCensusMember__c (pcm curvScore)');
        } else {
            System.debug('debugPricing [L435]: ' + ' vlocity_ins__GroupCensusMember__c (pcm curvScore): ' + pcm.size() + ' record(s) - ' + pcm);
        }
        if (pcm.isEmpty()) {
            throw new RatedProductsException('Primary census member not found');
        }

        //Get curv score from Contract
        List<Contract> contractList = [
            SELECT Id, ARC_CurvScore__c
            FROM Contract
            WHERE AccountId = :pcm[0].vlocity_ins__AccountId__r.ARC_GroupAccount__c
            AND (Status = 'Activated' OR Status = 'Enrollment In Progress')
            LIMIT 1
        ];

        if(contractList.isEmpty()) {
            System.debug('debugPricing [L446]: ' + ' No records returned for object: Contract (curvScore)');
        } else {
            System.debug('debugPricing [L448]: ' + ' Contract (curvScore): ' + contractList.size() + ' record(s) - ' + contractList);
        }
        if(contractList.isEmpty()) {
           throw new RatedProductsException('Contract not found');
        }

        Decimal curvScore = null;
        if (!contractList.isEmpty() && contractList[0].ARC_CurvScore__c != null) {
            curvScore = contractList[0].ARC_CurvScore__c;
        } else {
            if (pcm[0].vlocity_ins__AccountId__r == null) {
                System.debug('debugPricing [L446]: ' + ' GroupCensusMember.AccountId__r is null (Account missing or not loaded) for Id=' + pcm[0].Id);
            } else if (pcm[0].vlocity_ins__AccountId__r.ARC_GroupAccount__c == null) {
                System.debug('debugPricing [L448]: ' + ' Account.ARC_GroupAccount__c is null (Group Account lookup not set) for AccountId=' + pcm[0].vlocity_ins__AccountId__c);
            }
        }
        if (curvScore == null) {
            curvScore = 1;
        }

        Decimal curvFactor;

        if (curvScore >= 0 && curvScore <= 0.59) {
            curvFactor = 0.85;
        } else if (curvScore >= 0.6 && curvScore <= 0.79) {
            curvFactor = 0.9;
        } else if (curvScore >= 0.8 && curvScore <= 0.99) {
            curvFactor = 0.95;
        } else if (curvScore >= 1.0) {
            curvFactor = curvScore;
        } else {
            curvFactor = null;
        }

        return curvFactor;
    }

	/**
	 * Converts monthly employee split to per-period amount based on pay period (weekly, biweekly, monthly, etc.).
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	private static Decimal calculateEmployeeSplitPeriod(Decimal employeeSplit, String payPeriod) {
        if (employeeSplit == null) {
            return null;
        }

        Integer periodsPerYear = 12;

        String pp = payPeriod != null ? payPeriod.trim().toLowerCase() : '';
        if (pp.contains('bi-month') || pp.contains('bimonth') || pp.contains('semi-month') || pp.contains('semimonth')) {
            periodsPerYear = 24;
        } else if (pp.contains('two week') || pp.contains('biweek') || pp.contains('bi-week')) {
            periodsPerYear = 26;
        } else if (pp.contains('week')) {
            periodsPerYear = 52;
        } else if (pp.contains('month')) {
            periodsPerYear = 12;
        }

        if (periodsPerYear == null || periodsPerYear <= 0) {
            return null;
        }

        Decimal periods = Decimal.valueOf(periodsPerYear);
        Decimal perPeriod = (employeeSplit * 12) / periods;
        return perPeriod.setScale(2, System.RoundingMode.HALF_UP);
    }

	/**
	 * Builds the Integration Procedure input body for pricing (userInputs, effectiveDate, memberId).
	 * RF_Census.CM_State is populated from the group Account BillingState (vlocity_ins__AccountId__r.ARC_GroupAccount__r),
	 * not the census member residential state.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	private static Map<String, Object> buildPricingIpBody(vlocity_ins__GroupCensusMember__c member, String effectiveDateStr, Integer dependentsOverride, Integer ageOverride) {
        if (member == null) {
            throw new RatedProductsException('Primary census member not found');
        }

        Integer ageValue = null;
        if (ageOverride != null) {
            ageValue = ageOverride;
        } else if (useAgeAtEnrollmentFromPayload == true && member.ARC_AgeAtEnrollment__c != null) {
            Decimal ageDecimal = member.ARC_AgeAtEnrollment__c;
            ageValue = ageDecimal.intValue();
        } else if (member.ARC_Age__c != null) {
            Decimal ageDecimal = member.ARC_Age__c;
            ageValue = ageDecimal.intValue();
        }

        String stateValue = null;
        if (member.vlocity_ins__AccountId__r != null
            && member.vlocity_ins__AccountId__r.ARC_GroupAccount__r != null
            && String.isNotBlank(member.vlocity_ins__AccountId__r.ARC_GroupAccount__r.BillingState)) {
            stateValue = String.valueOf(member.vlocity_ins__AccountId__r.ARC_GroupAccount__r.BillingState);
        }

        Integer dependentsValue = null;
        if (dependentsOverride != null) {
            dependentsValue = dependentsOverride;
        } else if (member.vlocity_ins__TotalDependents__c != null) {
            Decimal dependentsDecimal = member.vlocity_ins__TotalDependents__c;
            dependentsValue = dependentsDecimal.intValue();
        }

        
        Decimal curvScoreFactor = getCurvScoreFactorFromMember(member.Id);

        String userInputJson = '{';
        if (ageValue != null) {
            userInputJson += '"RF_Census.CRF_PrimaryMemberAge": ' + ageValue;
        }
        if (stateValue != null) {
            if (ageValue != null) userInputJson += ',';
            userInputJson += '"RF_Census.CM_State": "' + stateValue + '"';
        }
        if (dependentsValue != null) {
            if (ageValue != null || stateValue != null) userInputJson += ',';
            userInputJson += '"RF_Census.CRF_Dependants": ' + dependentsValue;
        }
        if (ageValue != null || stateValue != null || dependentsValue != null) userInputJson += ',';
        userInputJson += '"RF_Contract.CRF_CurvScore": ' + curvScoreFactor;
        userInputJson += '}';

        String bodyJsonStr = '{' +
            '"userInputs": [' + userInputJson + '],' +
            '"effectiveDate": "' + effectiveDateStr + '",' +
            '"memberId": "' + String.valueOf(member.Id) + '"' +
        '}';

        return (Map<String, Object>) JSON.deserializeUntyped(bodyJsonStr);
    }

	/**
	 * Extracts product prices and tier factor from the Integration Procedure output.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	private static RatedProductsResult extractRatedProductsResult(Map<String, Object> ipOutput) {
        Map<String, Decimal> productPriceMap = new Map<String, Decimal>();
        Decimal tierFactorValue = null;

        try {
            Object tierFactorObj = ipOutput != null ? ipOutput.get('tierFactorValue') : null;
            if (tierFactorObj != null) {
                try {
                    tierFactorValue = Decimal.valueOf(String.valueOf(tierFactorObj));
                } catch (Exception ignore) {}
            }

            List<Object> productsArray = coerceToList(ipOutput != null ? ipOutput.get('products') : null);

            if (productsArray != null && !productsArray.isEmpty()) {
                for (Object productGroupObj : productsArray) {
                    Map<String, Object> productGroup = (Map<String, Object>) productGroupObj;
                    String currentGroupName = (String)productGroup.get('groupName');
                    List<Object> nestedProducts = coerceToList(productGroup.get('products'));

                    if (nestedProducts != null && !nestedProducts.isEmpty()) {
                        for (Object productObj : nestedProducts) {
                            Map<String, Object> product = (Map<String, Object>) productObj;

                            String productName = (String) product.get('Name');

                            Object priceObj = null;
                            if (product.containsKey('Price')) priceObj = product.get('Price');
                            if (priceObj == null && product.containsKey('price')) priceObj = product.get('price');
                            if (priceObj == null && product.containsKey('RatedPrice')) priceObj = product.get('RatedPrice');
                            if (priceObj == null && product.containsKey('MonthlyPrice')) priceObj = product.get('MonthlyPrice');
                            if (priceObj == null && product.containsKey('ListPrice')) priceObj = product.get('ListPrice');
                            if (priceObj == null && product.containsKey('BasePrice')) priceObj = product.get('BasePrice');
                            Decimal price = parsePriceValue(priceObj);

                            if (productName != null) {
                                productPriceMap.put(productName, price);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {}

        RatedProductsResult res = new RatedProductsResult();
        res.productPriceMap = productPriceMap;
        res.tierFactorValue = tierFactorValue;
        return res;
    }
	/**
	 * Overload: runs IP for primary member with no overrides.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	private static RatedProductsResult getRatedProductsResultForMember(Id primaryCensusMemberId) {
		return getRatedProductsResultForMember(primaryCensusMemberId, null);
	}

	/**
	 * Overload: runs IP with optional dependents override.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	private static RatedProductsResult getRatedProductsResultForMember(Id primaryCensusMemberId, Integer dependentsOverride) {
        return getRatedProductsResultForMember(primaryCensusMemberId, dependentsOverride, null);
    }

	/**
	 * Runs the IP with optional dependents and age overrides; returns product prices and tier factor.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	private static RatedProductsResult getRatedProductsResultForMember(Id primaryCensusMemberId, Integer dependentsOverride, Integer ageOverride) {
        try {
            List<vlocity_ins__GroupCensusMember__c> members = [
                SELECT Id,
                       ARC_Age__c,
                       ARC_AgeAtEnrollment__c,
                       vlocity_ins__TotalDependents__c,
                       vlocity_ins__CensusId__c,
                       vlocity_ins__CensusId__r.vlocity_ins__GroupId__c,
                       vlocity_ins__AccountId__r.ARC_GroupAccount__r.BillingState
                FROM vlocity_ins__GroupCensusMember__c
                WHERE Id = :primaryCensusMemberId
                AND vlocity_ins__IsPrimaryMember__c = true
                LIMIT 1
            ];
            if (members.isEmpty()) {
                System.debug('debugPricing [L658]: ' + ' No records returned for object: vlocity_ins__GroupCensusMember__c (members getRatedProductsResultForMember)');
            } else {
                System.debug('debugPricing [L660]: ' + ' vlocity_ins__GroupCensusMember__c (members getRatedProductsResultForMember): ' + members.size() + ' record(s) - ' + members);
            }
            if (members.isEmpty()) {
                throw new RatedProductsException('Primary census member not found');
            }
           
            vlocity_ins__GroupCensusMember__c member = members[0];
           
            Date effectiveDate = Date.today();
           
            String monthStr = String.valueOf(effectiveDate.month());
            String dayStr = String.valueOf(effectiveDate.day());
            if (monthStr.length() == 1) { 
                monthStr = '0' + monthStr;
            }
            if (dayStr.length() == 1) {
                dayStr = '0' + dayStr;
            }
            String effectiveDateStr = String.valueOf(effectiveDate.year()) + '-' + monthStr + '-' + dayStr;

            Map<String, Object> body = buildPricingIpBody(member, effectiveDateStr, dependentsOverride, ageOverride);

            String procedureAPIName = 'smallGroup_GetProducts';
            Object resultObj = (Test.isRunningTest() && testPricingIpResponse != null)
                ? testPricingIpResponse
                : vlocity_ins.IntegrationProcedureService.runIntegrationProcedureServiceFromApex(procedureAPIName, body, null);
            Map<String, Object> ipOutput = (Map<String, Object>) resultObj;

            Map<String, Decimal> productPriceMap = new Map<String, Decimal>();
            Decimal tierFactorValue = null;
           
            try {
                Object tierFactorObj = ipOutput != null ? ipOutput.get('tierFactorValue') : null;
                if (tierFactorObj != null) {
                    try {
                        tierFactorValue = Decimal.valueOf(String.valueOf(tierFactorObj));
                    } catch (Exception ignore) {}
                }

                List<Object> productsArray = coerceToList(ipOutput != null ? ipOutput.get('products') : null);

                if (productsArray != null && !productsArray.isEmpty()) {
                    for (Object productGroupObj : productsArray) {
                        Map<String, Object> productGroup = (Map<String, Object>) productGroupObj;
                        String currentGroupName = (String)productGroup.get('groupName');
                        List<Object> nestedProducts = coerceToList(productGroup.get('products'));

                        if (nestedProducts != null && !nestedProducts.isEmpty()) {
                            for (Object productObj : nestedProducts) {
                                Map<String, Object> product = (Map<String, Object>) productObj;

                                String productName = (String) product.get('Name');

                                Object priceObj = null;
                                if (product.containsKey('Price')) priceObj = product.get('Price');
                                if (priceObj == null && product.containsKey('price')) priceObj = product.get('price');
                                if (priceObj == null && product.containsKey('RatedPrice')) priceObj = product.get('RatedPrice');
                                if (priceObj == null && product.containsKey('MonthlyPrice')) priceObj = product.get('MonthlyPrice');
                                if (priceObj == null && product.containsKey('ListPrice')) priceObj = product.get('ListPrice');
                                if (priceObj == null && product.containsKey('BasePrice')) priceObj = product.get('BasePrice');
                                Decimal price = parsePriceValue(priceObj);

                                if (productName != null) {
                                    productPriceMap.put(productName, price);
                                }
                            }
                        }
                    }
                }
            } catch (Exception e) {}
           
            RatedProductsResult res = new RatedProductsResult();
            res.productPriceMap = productPriceMap;
            res.tierFactorValue = tierFactorValue;
            return res;
        } catch (Exception e) {
            throw new RatedProductsException('Error getting rated products: ' + e.getMessage());
        }
    }

	/**
	 * Coerces an Object to List<Object>; supports JSON string payloads from the IP.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	private static List<Object> coerceToList(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof List<Object>) {
            return (List<Object>)value;
        }
        if (value instanceof String) {
            try {
                Object parsed = JSON.deserializeUntyped((String)value);
                if (parsed instanceof List<Object>) {
                    return (List<Object>)parsed;
                }
            } catch (Exception ignore) {}
        }
        return null;
    }

    @TestVisible
    private static Decimal parsePriceValue(Object priceObj) {
        if (priceObj == null) {
            return null;
        }
        String priceText = String.valueOf(priceObj);
        if (String.isBlank(priceText)) {
            return null;
        }
        try {
            return Decimal.valueOf(priceText.trim());
        } catch (Exception e) {
            System.debug('debugPricing: Unable to parse product price value "' + priceText + '": ' + e.getMessage());
            return null;
        }
    }

	/**
	 * Backward-compatible overload: resolves ContractId from the member's group account, then delegates to the three-arg overload.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	public static Map<String, Decimal> calculateMemberContribution(Id memberId, Map<String,Decimal> pricedProducts) {
        Id backCompatContractId = null;
        try {
            List<vlocity_ins__GroupCensusMember__c> bcm = [
                SELECT Id, vlocity_ins__AccountId__r.ARC_GroupAccount__c
                FROM vlocity_ins__GroupCensusMember__c
                WHERE Id = :memberId
                LIMIT 1
            ];
            if (!bcm.isEmpty() && bcm[0].vlocity_ins__AccountId__r != null && bcm[0].vlocity_ins__AccountId__r.ARC_GroupAccount__c != null) {
                List<Contract> bcContracts = [
                    SELECT Id FROM Contract
                    WHERE AccountId = :bcm[0].vlocity_ins__AccountId__r.ARC_GroupAccount__c
                    AND (Status = 'Activated' OR Status = 'Enrollment In Progress')
                    LIMIT 1
                ];
                if (!bcContracts.isEmpty()) {
                    backCompatContractId = bcContracts[0].Id;
                }
            }
        } catch (Exception ignore) {}
        return calculateMemberContribution(memberId, pricedProducts, backCompatContractId, null);
    }

	/**
	 * Applies Group Class contribution rules to priced products; returns product name to price-after-contribution.
	 * Resolves the Group Class via ARC_CensusMemberGroupClass__c filtered by contractId.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
	public static Map<String, Decimal> calculateMemberContribution(Id memberId, Map<String,Decimal> pricedProducts, Id contractId) {
        return calculateMemberContribution(memberId, pricedProducts, contractId, null);
    }

	/**
	 * Applies Group Class contribution rules; when inputMemberCount is set and tier-based contributions apply,
	 * matches GroupClassContribution by tier derived from enrollment household size (not census ARC_EmployeeTier__c).
	 */
	public static Map<String, Decimal> calculateMemberContribution(Id memberId, Map<String,Decimal> pricedProducts, Id contractId, Integer inputMemberCount) {
		return calculateMemberContribution(memberId, pricedProducts, contractId, inputMemberCount, null);
	}

	/**
	 * @param lowestCostReferenceMap When set (e.g. full mergedPriceMap for a senior-only pricedProducts pass),
	 *        Percent Of Lowest Cost uses this map to find the lowest base; senior is still excluded from that pool.
	 */
	public static Map<String, Decimal> calculateMemberContribution(
		Id memberId,
		Map<String, Decimal> pricedProducts,
		Id contractId,
		Integer inputMemberCount,
		Map<String, Decimal> lowestCostReferenceMap
	) {
        Map<String, Decimal> productsWithContribution = new Map<String, Decimal>();
		Map<String, Decimal> lowestCostPool = (lowestCostReferenceMap != null) ? lowestCostReferenceMap : pricedProducts;

        Id groupClassId;

        List<vlocity_ins__GroupCensusMember__c> primaryMemberList = [
            SELECT Id, ARC_EmployeeTier__c, ARC_EmployeeType__c, ARC_EmployeeDivision__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id = :memberId
        ];
        if (primaryMemberList.isEmpty()) {
            System.debug('debugPricing [L776]: ' + ' No records returned for object: vlocity_ins__GroupCensusMember__c (primaryMember calculateMemberContribution)');
        } else {
            System.debug('debugPricing [L778]: ' + ' vlocity_ins__GroupCensusMember__c (primaryMember calculateMemberContribution): ' + primaryMemberList.size() + ' record(s) - ' + primaryMemberList);
        }
        vlocity_ins__GroupCensusMember__c primaryMember = primaryMemberList[0];

        if (contractId == null) {
            System.debug('debugPricing [L833a]: contractId is null; no contribution applied for memberId=' + memberId);
            return new Map<String, Decimal>(pricedProducts);
        }
        groupClassId = resolveCmgcGroupClassId(memberId, contractId);
        if (groupClassId == null) {
            System.debug('debugPricing [L833b]: No ARC_CensusMemberGroupClass__c found for memberId=' + memberId + ', contractId=' + contractId);
            return new Map<String, Decimal>(pricedProducts);
        }
        System.debug('debugPricing [L833c]: ARC_CensusMemberGroupClass__c resolved groupClassId=' + groupClassId);
        List<vlocity_ins__GroupClass__c> groupClassList = [
            SELECT Id, ARC_EmployeeTypeModel__c, ARC_ApplyProgramBased__c, ARC_ApplyEmployeeTier__c,
                   ARC_ContributionMethod__c, ARC_EmployeeType__c, ARC_EmployeeDivision__c
            FROM vlocity_ins__GroupClass__c
            WHERE Id = :groupClassId
            LIMIT 1
        ];
        if (groupClassList.isEmpty()) {
            System.debug('debugPricing [L785]: ' + ' No records returned for object: vlocity_ins__GroupClass__c');
        } else {
            System.debug('debugPricing [L787]: ' + ' vlocity_ins__GroupClass__c: ' + groupClassList.size() + ' record(s) - ' + groupClassList);
        }
        vlocity_ins__GroupClass__c groupClass = groupClassList[0];
        System.debug('debugPricing [L790]: ' + ' [GroupClass calculateMemberContribution] Id=' + groupClass.Id + ', ARC_EmployeeTypeModel__c=' + groupClass.ARC_EmployeeTypeModel__c + ', ARC_ApplyProgramBased__c=' + groupClass.ARC_ApplyProgramBased__c + ', ARC_ApplyEmployeeTier__c=' + groupClass.ARC_ApplyEmployeeTier__c + ', ARC_ContributionMethod__c=' + groupClass.ARC_ContributionMethod__c + ', ARC_EmployeeType__c=' + groupClass.ARC_EmployeeType__c + ', ARC_EmployeeDivision__c=' + groupClass.ARC_EmployeeDivision__c);

        String contributionMethod = groupClass.ARC_ContributionMethod__c;
        Boolean employeeType = false;
        Boolean employeeTier = false;
        Boolean filterByEmployeeDivision = filterContributionsByCensusEmployeeDivision(groupClass)
            && String.isNotBlank(primaryMember.ARC_EmployeeDivision__c);

        switch on contributionMethod{
            when 'Flat Amount', 'Flat_Amount'{
                if (filterGroupClassContributionsByCensusEmployeeType(groupClass)) {
                    employeeType = true;
                }
                if(groupClass.ARC_ApplyEmployeeTier__c == true){
                    employeeTier = true;
                }
            }
            when 'Flat Percentage', 'Flat_Percentage'{
                if (filterGroupClassContributionsByCensusEmployeeType(groupClass)) {
                    employeeType = true;
                }
                if(groupClass.ARC_ApplyEmployeeTier__c == true){
                    employeeTier = true;
                }
            }
            when 'Percent Of Lowest Cost', 'Percent_Of_Lowest_Cost'{
                if (filterGroupClassContributionsByCensusEmployeeType(groupClass)) {
                    employeeType = true;
                }
                if(groupClass.ARC_ApplyEmployeeTier__c == true){
                    employeeTier = true;
                }
            }
            when 'Percent Of Lowest By Category', 'Percent_Of_Lowest_By_Category'{
                if (filterGroupClassContributionsByCensusEmployeeType(groupClass)) {
                    employeeType = true;
                }
                if(groupClass.ARC_ApplyEmployeeTier__c == true){
                    employeeTier = true;
                }
            }
        }

        Boolean bothFlagsTrue = (groupClass.ARC_ApplyProgramBased__c == true && groupClass.ARC_ApplyEmployeeTier__c == true);
        if (bothFlagsTrue) {
            employeeTier = true;
            if (!groupClassDiscriminatesByEmployeeType(groupClass)) {
                employeeType = true;
            }
            System.debug('debugPricing [L841]: ' + ' [calculateMemberContribution] Both ARC_ApplyProgramBased__c and ARC_ApplyEmployeeTier__c are true; matching contribution by EmployeeTier' + (employeeType ? ' + EmployeeType' : '') + '.');
        }

        String employmentType = primaryMember.ARC_EmployeeType__c;
        String employeeTierValue = resolveEmployeeTierForContribution(employeeTier, inputMemberCount, primaryMember);
        String employmentDivision = filterByEmployeeDivision ? primaryMember.ARC_EmployeeDivision__c : null;
        if (employeeTier == true || bothFlagsTrue) {
            System.debug('debugPricing [L847]: ' + ' [calculateMemberContribution] Query params: employeeType=' + employeeType + ', employeeTier=' + employeeTier + ', inputMemberCount=' + inputMemberCount + ', resolvedEmployeeTier=' + employeeTierValue + ', filterByEmployeeDivision=' + filterByEmployeeDivision + ', member ARC_EmployeeType__c=' + employmentType + ', member ARC_EmployeeDivision__c=' + primaryMember.ARC_EmployeeDivision__c + ', groupClassId=' + groupClassId);
        }

        Boolean programBased = (groupClass.ARC_ApplyProgramBased__c == true);
        Map<Id, vlocity_ins__GroupClassContribution__c> contributionByProductId = null;
        vlocity_ins__GroupClassContribution__c contribution = null;

        if (programBased) {
            // Program-based: each contribution points to a product via ARC_ContractLineItem__r.vlocity_ins__Product2Id__c. Load all and map by product Id.
            String soqlAll = 'SELECT Id, vlocity_ins__GroupClassId__c, ARC_EmployeeType__c, ARC_EmployeeTier__c, ARC_EmployeeDivision__c, vlocity_ins__ContributionAmount__c, vlocity_ins__ContributionPercent__c, ARC_ContractLineItem__c, ARC_ContractLineItem__r.vlocity_ins__Product2Id__c ' +
                            'FROM vlocity_ins__GroupClassContribution__c ' +
                            'WHERE vlocity_ins__GroupClassId__c = :groupClassId AND ARC_ContractLineItem__c != null';
            if (employeeType == true) {
                soqlAll += ' AND ARC_EmployeeType__c = :employmentType';
            }
            if (employeeTier == true) {
                soqlAll += ' AND ARC_EmployeeTier__c = :employeeTierValue';
            }
            if (filterByEmployeeDivision == true) {
                soqlAll += ' AND ARC_EmployeeDivision__c = :employmentDivision';
            }
            List<vlocity_ins__GroupClassContribution__c> contributionListAll = Database.query(soqlAll);
            if (contributionListAll.isEmpty()) {
                System.debug('debugPricing [L863]: ' + ' No records returned for object: vlocity_ins__GroupClassContribution__c (calculateMemberContribution program-based)');
            } else {
                System.debug('debugPricing [L865]: ' + ' vlocity_ins__GroupClassContribution__c (calculateMemberContribution program-based): ' + contributionListAll.size() + ' record(s) - ' + contributionListAll);
            }
            contributionByProductId = new Map<Id, vlocity_ins__GroupClassContribution__c>();
            for (vlocity_ins__GroupClassContribution__c c : contributionListAll) {
                if (c.ARC_ContractLineItem__r != null && c.ARC_ContractLineItem__r.vlocity_ins__Product2Id__c != null) {
                    contributionByProductId.put(c.ARC_ContractLineItem__r.vlocity_ins__Product2Id__c, c);
                }
            }
        } else {
            String soql = 'SELECT Id, vlocity_ins__GroupClassId__c, ARC_EmployeeType__c, ARC_EmployeeTier__c, ARC_EmployeeDivision__c, vlocity_ins__ContributionAmount__c, vlocity_ins__ContributionPercent__c ' +
                          'FROM vlocity_ins__GroupClassContribution__c ' +
                          'WHERE vlocity_ins__GroupClassId__c = :groupClassId';
            if (employeeType == true) {
                soql += ' AND ARC_EmployeeType__c = :employmentType';
            }
            if (employeeTier == true) {
                soql += ' AND ARC_EmployeeTier__c = :employeeTierValue';
            }
            if (filterByEmployeeDivision == true) {
                soql += ' AND ARC_EmployeeDivision__c = :employmentDivision';
            }
            soql += ' LIMIT 1';

            List<vlocity_ins__GroupClassContribution__c> contributionList = Database.query(soql);
            if (contributionList.isEmpty()) {
                System.debug('debugPricing [L863]: ' + ' No records returned for object: vlocity_ins__GroupClassContribution__c (calculateMemberContribution)');
            } else {
                System.debug('debugPricing [L865]: ' + ' vlocity_ins__GroupClassContribution__c (calculateMemberContribution): ' + contributionList.size() + ' record(s) - ' + contributionList);
            }
            contribution = contributionList.isEmpty() ? null : contributionList[0];
        }

        if (bothFlagsTrue) {
            System.debug('debugPricing [L869]: ' + ' [calculateMemberContribution] ' + (programBased ? 'Program-based: contributionByProductId size=' + (contributionByProductId != null ? contributionByProductId.size() : 0) : 'Contribution ' + (contribution != null ? 'Id=' + contribution.Id : 'null')));
        }
        if (contribution != null) {
            System.debug('debugPricing [L872]: calculateMemberContribution GroupClass Id=' + groupClass.Id + ' (single contribution) | Contribution Id=' + contribution.Id + ', vlocity_ins__ContributionAmount__c=' + contribution.vlocity_ins__ContributionAmount__c + ', vlocity_ins__ContributionPercent__c=' + contribution.vlocity_ins__ContributionPercent__c);
        } else if (!programBased) {
            System.debug('debugPricing [L874]: calculateMemberContribution GroupClass Id=' + groupClass.Id + ' | Contribution=null');
        }

        if (programBased && contributionByProductId != null && !contributionByProductId.isEmpty()) {
            // Apply each product's own contribution (contribution record linked to that product via Contract Line Item).
            Map<String, Id> productNameToId = new Map<String, Id>();
            for (Product2 p : [SELECT Id, Name FROM Product2 WHERE Name IN :pricedProducts.keySet()]) {
                productNameToId.put(p.Name, p.Id);
            }
            if (groupClass.ARC_ContributionMethod__c == 'Flat_Amount' || groupClass.ARC_ContributionMethod__c == 'Flat Amount') {
                for (String productName : pricedProducts.keySet()) {
                    Decimal price = pricedProducts.get(productName);
                    if (price == null) { productsWithContribution.put(productName, null); continue; }
                    if (productName != null && productName.containsIgnoreCase('Legacy')) { productsWithContribution.put(productName, price); continue; }
                    Id productId = productNameToId.get(productName);
                    vlocity_ins__GroupClassContribution__c c = productId != null ? contributionByProductId.get(productId) : null;
                    if (c != null && c.vlocity_ins__ContributionAmount__c != null) {
                        price = price - c.vlocity_ins__ContributionAmount__c;
                    }
                    productsWithContribution.put(productName, price != null ? Math.max(0, price) : null);
                }
            } else if (groupClass.ARC_ContributionMethod__c == 'Flat_Percentage' || groupClass.ARC_ContributionMethod__c == 'Flat Percentage') {
                for (String productName : pricedProducts.keySet()) {
                    Decimal price = pricedProducts.get(productName);
                    if (price == null) { productsWithContribution.put(productName, null); continue; }
                    if (productName != null && productName.containsIgnoreCase('Legacy')) { productsWithContribution.put(productName, price); continue; }
                    Id productId = productNameToId.get(productName);
                    vlocity_ins__GroupClassContribution__c c = productId != null ? contributionByProductId.get(productId) : null;
                    if (c != null && c.vlocity_ins__ContributionPercent__c != null) {
                        price = price - (price * c.vlocity_ins__ContributionPercent__c / 100);
                    }
                    productsWithContribution.put(productName, price != null ? Math.max(0, price) : null);
                }
            } else if (groupClass.ARC_ContributionMethod__c == 'Percent_Of_Lowest_Cost' || groupClass.ARC_ContributionMethod__c == 'Percent Of Lowest Cost') {
                for (String productName : pricedProducts.keySet()) {
                    Decimal price = pricedProducts.get(productName);
                    if (price == null) { productsWithContribution.put(productName, null); continue; }
                    if (productName != null && productName.containsIgnoreCase('Legacy')) { productsWithContribution.put(productName, price); continue; }
                    Id productId = productNameToId.get(productName);
                    vlocity_ins__GroupClassContribution__c c = productId != null ? contributionByProductId.get(productId) : null;
                    Decimal flatAmount = null;
                    if (c != null && c.vlocity_ins__ContributionPercent__c != null) {
                        Decimal lowestBasePrice = computeLowestBaseExcludingLegacyAndSenior(lowestCostPool);
                        if (lowestBasePrice != null) {
							flatAmount = lowestBasePrice * (c.vlocity_ins__ContributionPercent__c / 100);
						}
                    }
                    Decimal afterContrib = (flatAmount != null) ? price - flatAmount : price;
                    productsWithContribution.put(productName, afterContrib != null ? Math.max(0, afterContrib) : null);
                }
            } else if (groupClass.ARC_ContributionMethod__c == 'Percent_Of_Lowest_By_Category' || groupClass.ARC_ContributionMethod__c == 'Percent Of Lowest By Category') {
                Map<String, Decimal> lowestByCategory = new Map<String, Decimal>();
                for (String pname : pricedProducts.keySet()) {
                    String cat = resolveProductLineCategory(pname);
                    if (cat == null) {
                        continue;
                    }
                    Decimal pr = pricedProducts.get(pname);
                    if (pr == null) {
                        continue;
                    }
                    if (!lowestByCategory.containsKey(cat) || pr < lowestByCategory.get(cat)) {
                        lowestByCategory.put(cat, pr);
                    }
                }
                for (String productName : pricedProducts.keySet()) {
                    Decimal price = pricedProducts.get(productName);
                    if (price == null) { productsWithContribution.put(productName, null); continue; }
                    if (productName != null && productName.containsIgnoreCase('Legacy')) { productsWithContribution.put(productName, price); continue; }
                    String category = resolveProductLineCategory(productName);
                    if (category == null || !lowestByCategory.containsKey(category)) { productsWithContribution.put(productName, price); continue; }
                    Id productId = productNameToId.get(productName);
                    vlocity_ins__GroupClassContribution__c c = productId != null ? contributionByProductId.get(productId) : null;
                    Decimal flatAmount = null;
                    if (c != null && c.vlocity_ins__ContributionPercent__c != null) {
                        flatAmount = lowestByCategory.get(category) * (c.vlocity_ins__ContributionPercent__c / 100);
                    }
                    Decimal afterContrib = (flatAmount != null) ? price - flatAmount : price;
                    productsWithContribution.put(productName, afterContrib != null ? Math.max(0, afterContrib) : null);
                }
            } else {
                productsWithContribution.putAll(pricedProducts);
            }
        } else if (contribution != null) {
                if(groupClass.ARC_ContributionMethod__c == 'Flat_Amount' || groupClass.ARC_ContributionMethod__c == 'Flat Amount'){
                    for(String productName : pricedProducts.keySet()){
                        Decimal price = pricedProducts.get(productName);
                        if (price == null) {
                            productsWithContribution.put(productName, null);
                            continue;
                        }
                        if (productName != null && productName.containsIgnoreCase('Legacy')) {
                            productsWithContribution.put(productName, price);
                            continue;
                        }
                        price = price - contribution.vlocity_ins__ContributionAmount__c;
                        productsWithContribution.put(productName, price != null ? Math.max(0, price) : null);
                    }
                }
                else if(groupClass.ARC_ContributionMethod__c == 'Flat_Percentage' || groupClass.ARC_ContributionMethod__c == 'Flat Percentage'){
                    for(String productName : pricedProducts.keySet()){
                        Decimal price = pricedProducts.get(productName);
                        if (price == null) {
                            productsWithContribution.put(productName, null);
                            continue;
                        }
                        if (productName != null && productName.containsIgnoreCase('Legacy')) {
                            productsWithContribution.put(productName, price);
                            continue;
                        }
                        price = price - (price * contribution.vlocity_ins__ContributionPercent__c / 100);
                        productsWithContribution.put(productName, price != null ? Math.max(0, price) : null);
                    }
                }
                else if(groupClass.ARC_ContributionMethod__c == 'Percent_Of_Lowest_Cost' || groupClass.ARC_ContributionMethod__c == 'Percent Of Lowest Cost'){
                    Decimal lowestBasePrice = computeLowestBaseExcludingLegacyAndSenior(lowestCostPool);
                    Decimal flatContributionAmount = null;
                    if (lowestBasePrice != null && contribution.vlocity_ins__ContributionPercent__c != null) {
                        flatContributionAmount = lowestBasePrice * (contribution.vlocity_ins__ContributionPercent__c / 100);
                    }
                    for(String productName : pricedProducts.keySet()){
                        Decimal price = pricedProducts.get(productName);
                        if (price == null) {
                            productsWithContribution.put(productName, null);
                            continue;
                        }
                        if (productName != null && productName.containsIgnoreCase('Legacy')) {
                            productsWithContribution.put(productName, price);
                            continue;
                        }
                        price = (flatContributionAmount != null) ? price - flatContributionAmount : price;
                        productsWithContribution.put(productName, price != null ? Math.max(0, price) : null);
                    }
                }
                else if(groupClass.ARC_ContributionMethod__c == 'Percent_Of_Lowest_By_Category' || groupClass.ARC_ContributionMethod__c == 'Percent Of Lowest By Category'){
                    Map<String, Decimal> lowestByCategory = new Map<String, Decimal>();
                    for (String productName : pricedProducts.keySet()) {
                        String category = resolveProductLineCategory(productName);
                        if (category == null) {
                            continue;
                        }
                        Decimal price = pricedProducts.get(productName);
                        if (price == null) {
                            continue;
                        }
                        if (!lowestByCategory.containsKey(category) || price < lowestByCategory.get(category)) {
                            lowestByCategory.put(category, price);
                        }
                    }
                    Map<String, Decimal> flatContributionByCategory = new Map<String, Decimal>();
                    if (contribution.vlocity_ins__ContributionPercent__c != null) {
                        for (String cat : lowestByCategory.keySet()) {
                            Decimal lowestInCat = lowestByCategory.get(cat);
                            flatContributionByCategory.put(cat, lowestInCat * (contribution.vlocity_ins__ContributionPercent__c / 100));
                        }
                    }
                    for (String productName : pricedProducts.keySet()) {
                        Decimal price = pricedProducts.get(productName);
                        if (price == null) {
                            productsWithContribution.put(productName, null);
                            continue;
                        }
                        if (productName != null && productName.containsIgnoreCase('Legacy')) {
                            productsWithContribution.put(productName, price);
                            continue;
                        }
                        String category = resolveProductLineCategory(productName);
                        if (category == null || !flatContributionByCategory.containsKey(category)) {
                            productsWithContribution.put(productName, price);
                            continue;
                        }
                        Decimal flatAmount = flatContributionByCategory.get(category);
                        Decimal afterContrib = price - flatAmount;
                        productsWithContribution.put(productName, afterContrib != null ? Math.max(0, afterContrib) : null);
                    }
                }
        } else {
            productsWithContribution.putAll(pricedProducts);
        }
        return productsWithContribution;
    }

	/**
	 * Resolves contribution record and method for the member from Group Class.
	 * @author Felipe Cladera
	 * @date 2025-02-03
	 */
    private static ContributionInfo getContributionInfo(Id memberId, Id contractId) {
        return getContributionInfo(memberId, contractId, null);
    }

    private static ContributionInfo getContributionInfo(Id memberId, Id contractId, Integer inputMemberCount) {
        ContributionInfo info = new ContributionInfo();
        try {
            List<vlocity_ins__GroupCensusMember__c> primaryMemberListGci = [
                SELECT Id, ARC_EmployeeTier__c, ARC_EmployeeType__c, ARC_EmployeeDivision__c
                FROM vlocity_ins__GroupCensusMember__c
                WHERE Id = :memberId
                LIMIT 1
            ];
            if (primaryMemberListGci.isEmpty()) {
                System.debug('debugPricing [L1015]: ' + ' No records returned for object: vlocity_ins__GroupCensusMember__c (getContributionInfo primaryMember)');
            } else {
                System.debug('debugPricing [L1017]: ' + ' vlocity_ins__GroupCensusMember__c (getContributionInfo primaryMember): ' + primaryMemberListGci.size() + ' record(s) - ' + primaryMemberListGci);
            }
            vlocity_ins__GroupCensusMember__c primaryMember = primaryMemberListGci.isEmpty() ? null : primaryMemberListGci[0];
            if (primaryMember == null) {
                return null;
            }

            if (contractId == null) {
                System.debug('debugPricing [L1191a]: contractId is null; no contribution info for memberId=' + memberId);
                return null;
            }
            Id groupClassId = resolveCmgcGroupClassId(memberId, contractId);
            if (groupClassId == null) {
                System.debug('debugPricing [L1191b]: No ARC_CensusMemberGroupClass__c found for memberId=' + memberId + ', contractId=' + contractId);
                return null;
            }
            System.debug('debugPricing [L1191c]: ARC_CensusMemberGroupClass__c resolved groupClassId=' + groupClassId);

            List<vlocity_ins__GroupClass__c> groupClassListGci = [
                SELECT Id, ARC_EmployeeTypeModel__c, ARC_ApplyProgramBased__c,
                       ARC_ApplyEmployeeTier__c, ARC_ContributionMethod__c, ARC_EmployeeType__c, ARC_EmployeeDivision__c
                FROM vlocity_ins__GroupClass__c
                WHERE Id = :groupClassId
                LIMIT 1
            ];
            if (groupClassListGci.isEmpty()) {
                System.debug('debugPricing [L1034]: ' + ' No records returned for object: vlocity_ins__GroupClass__c (getContributionInfo)');
            } else {
                System.debug('debugPricing [L1036]: ' + ' vlocity_ins__GroupClass__c (getContributionInfo): ' + groupClassListGci.size() + ' record(s) - ' + groupClassListGci);
            }
            vlocity_ins__GroupClass__c groupClass = groupClassListGci.isEmpty() ? null : groupClassListGci[0];
            if (groupClass == null) {
                return null;
            }
            System.debug('debugPricing [L1042]: ' + ' [GroupClass getContributionInfo] Id=' + groupClass.Id + ', ARC_EmployeeTypeModel__c=' + groupClass.ARC_EmployeeTypeModel__c + ', ARC_ApplyProgramBased__c=' + groupClass.ARC_ApplyProgramBased__c + ', ARC_ApplyEmployeeTier__c=' + groupClass.ARC_ApplyEmployeeTier__c + ', ARC_ContributionMethod__c=' + groupClass.ARC_ContributionMethod__c + ', ARC_EmployeeType__c=' + groupClass.ARC_EmployeeType__c + ', ARC_EmployeeDivision__c=' + groupClass.ARC_EmployeeDivision__c);

            info.contributionMethod = groupClass.ARC_ContributionMethod__c;
            String contributionMethod = groupClass.ARC_ContributionMethod__c;
            Boolean employeeType = false;
            Boolean employeeTier = false;
            Boolean filterByEmployeeDivision = filterContributionsByCensusEmployeeDivision(groupClass)
                && String.isNotBlank(primaryMember.ARC_EmployeeDivision__c);

            switch on contributionMethod {
                when 'Flat Amount',  'Flat_Amount' {
                    if (filterGroupClassContributionsByCensusEmployeeType(groupClass)) {
                        employeeType = true;
                    }
                    if(groupClass.ARC_ApplyEmployeeTier__c == true){
                        employeeTier = true;
                    }
                }
                when 'Flat Percentage', 'Flat_Percentage' {
                    if (filterGroupClassContributionsByCensusEmployeeType(groupClass)) {
                        employeeType = true;
                    }
                    if(groupClass.ARC_ApplyEmployeeTier__c == true){
                        employeeTier = true;
                    }
                }
                when 'Percent Of Lowest Cost', 'Percent_Of_Lowest_Cost' {
                    if (filterGroupClassContributionsByCensusEmployeeType(groupClass)) {
                        employeeType = true;
                    }
                    if(groupClass.ARC_ApplyEmployeeTier__c == true){
                        employeeTier = true;
                    }
                }
                when 'Percent Of Lowest By Category', 'Percent_Of_Lowest_By_Category' {
                    if (filterGroupClassContributionsByCensusEmployeeType(groupClass)) {
                        employeeType = true;
                    }
                    if(groupClass.ARC_ApplyEmployeeTier__c == true){
                        employeeTier = true;
                    }
                }
            }

            Boolean bothFlagsTrue = (groupClass.ARC_ApplyProgramBased__c == true && groupClass.ARC_ApplyEmployeeTier__c == true);
            if (bothFlagsTrue) {
                employeeTier = true;
                if (!groupClassDiscriminatesByEmployeeType(groupClass)) {
                    employeeType = true;
                }
                System.debug('debugPricing [L1094]: ' + ' [getContributionInfo] Both ARC_ApplyProgramBased__c and ARC_ApplyEmployeeTier__c are true; matching contribution by EmployeeTier' + (employeeType ? ' + EmployeeType' : '') + '.');
            }

            String employmentType = primaryMember.ARC_EmployeeType__c;
            String employeeTierValue = resolveEmployeeTierForContribution(employeeTier, inputMemberCount, primaryMember);
            String employmentDivision = filterByEmployeeDivision ? primaryMember.ARC_EmployeeDivision__c : null;
            if (employeeTier == true || bothFlagsTrue) {
                System.debug('debugPricing [L1100]: ' + ' [getContributionInfo] Query params: employeeType=' + employeeType + ', employeeTier=' + employeeTier + ', inputMemberCount=' + inputMemberCount + ', resolvedEmployeeTier=' + employeeTierValue + ', filterByEmployeeDivision=' + filterByEmployeeDivision + ', member ARC_EmployeeType__c=' + employmentType + ', member ARC_EmployeeDivision__c=' + primaryMember.ARC_EmployeeDivision__c + ', groupClassId=' + groupClassId);
            }

            Boolean programBased = (groupClass.ARC_ApplyProgramBased__c == true);
            if (programBased) {
                // Program-based: each contribution record points to a product via ARC_ContractLineItem__r.vlocity_ins__Product2Id__c; load all and map by product Id.
                String soqlAll = 'SELECT Id, vlocity_ins__GroupClassId__c, ARC_EmployeeType__c, ARC_EmployeeTier__c, ARC_EmployeeDivision__c, vlocity_ins__ContributionAmount__c, vlocity_ins__ContributionPercent__c, ARC_ContractLineItem__c, ARC_ContractLineItem__r.vlocity_ins__Product2Id__c ' +
                                'FROM vlocity_ins__GroupClassContribution__c ' +
                                'WHERE vlocity_ins__GroupClassId__c = :groupClassId AND ARC_ContractLineItem__c != null';
                if (employeeType == true) {
                    soqlAll += ' AND ARC_EmployeeType__c = :employmentType';
                }
                if (employeeTier == true) {
                    soqlAll += ' AND ARC_EmployeeTier__c = :employeeTierValue';
                }
                if (filterByEmployeeDivision == true) {
                    soqlAll += ' AND ARC_EmployeeDivision__c = :employmentDivision';
                }
                List<vlocity_ins__GroupClassContribution__c> contributionsAll = Database.query(soqlAll);
                if (contributionsAll.isEmpty()) {
                    System.debug('debugPricing [L1116]: ' + ' No records returned for object: vlocity_ins__GroupClassContribution__c (getContributionInfo program-based)');
                } else {
                    System.debug('debugPricing [L1118]: ' + ' vlocity_ins__GroupClassContribution__c (getContributionInfo program-based): ' + contributionsAll.size() + ' record(s) - ' + contributionsAll);
                }
                info.contributionByProductId = new Map<Id, vlocity_ins__GroupClassContribution__c>();
                for (vlocity_ins__GroupClassContribution__c c : contributionsAll) {
                    if (c.ARC_ContractLineItem__r != null && c.ARC_ContractLineItem__r.vlocity_ins__Product2Id__c != null) {
                        info.contributionByProductId.put(c.ARC_ContractLineItem__r.vlocity_ins__Product2Id__c, c);
                    }
                }
                info.contribution = null;
            } else {
                String soql = 'SELECT Id, vlocity_ins__GroupClassId__c, ARC_EmployeeType__c, ARC_EmployeeTier__c, ARC_EmployeeDivision__c, vlocity_ins__ContributionAmount__c, vlocity_ins__ContributionPercent__c ' +
                              'FROM vlocity_ins__GroupClassContribution__c ' +
                              'WHERE vlocity_ins__GroupClassId__c = :groupClassId';
                if (employeeType == true) {
                    soql += ' AND ARC_EmployeeType__c = :employmentType';
                }
                if (employeeTier == true) {
                    soql += ' AND ARC_EmployeeTier__c = :employeeTierValue';
                }
                if (filterByEmployeeDivision == true) {
                    soql += ' AND ARC_EmployeeDivision__c = :employmentDivision';
                }
                soql += ' LIMIT 1';

                List<vlocity_ins__GroupClassContribution__c> contributions = Database.query(soql);
                if (contributions.isEmpty()) {
                    System.debug('debugPricing [L1116]: ' + ' No records returned for object: vlocity_ins__GroupClassContribution__c (getContributionInfo)');
                } else {
                    System.debug('debugPricing [L1118]: ' + ' vlocity_ins__GroupClassContribution__c (getContributionInfo): ' + contributions.size() + ' record(s) - ' + contributions);
                    vlocity_ins__GroupClassContribution__c c0 = contributions[0];
                    System.debug('debugPricing [L1120]: ' + ' [GroupClassContribution getContributionInfo] Id=' + c0.Id + ', vlocity_ins__GroupClassId__c=' + c0.vlocity_ins__GroupClassId__c + ', ARC_EmployeeType__c=' + c0.ARC_EmployeeType__c + ', ARC_EmployeeTier__c=' + c0.ARC_EmployeeTier__c + ', vlocity_ins__ContributionAmount__c=' + c0.vlocity_ins__ContributionAmount__c + ', vlocity_ins__ContributionPercent__c=' + c0.vlocity_ins__ContributionPercent__c);
                }
                if (bothFlagsTrue) {
                    System.debug('debugPricing [L1123]: ' + ' [getContributionInfo] Contribution query returned ' + contributions.size() + ' record(s). ' + (contributions.isEmpty() ? 'No match; info.contribution will be null.' : 'Using contribution Id=' + contributions[0].Id));
                }
                if (contributions != null && !contributions.isEmpty()) {
                    info.contribution = contributions[0];
                }
            }
            System.debug('debugPricing [L1128]: getContributionInfo GroupClass Id=' + groupClass.Id + ', ARC_EmployeeTypeModel__c=' + groupClass.ARC_EmployeeTypeModel__c + ', ARC_ApplyProgramBased__c=' + groupClass.ARC_ApplyProgramBased__c + ', ARC_ApplyEmployeeTier__c=' + groupClass.ARC_ApplyEmployeeTier__c + ', ARC_ContributionMethod__c=' + groupClass.ARC_ContributionMethod__c + ', ARC_EmployeeType__c=' + groupClass.ARC_EmployeeType__c + (info.contribution != null ? ' | Contribution Id=' + info.contribution.Id + ', vlocity_ins__GroupClassId__c=' + info.contribution.vlocity_ins__GroupClassId__c + ', ARC_EmployeeType__c=' + info.contribution.ARC_EmployeeType__c + ', ARC_EmployeeTier__c=' + info.contribution.ARC_EmployeeTier__c + ', vlocity_ins__ContributionAmount__c=' + info.contribution.vlocity_ins__ContributionAmount__c + ', vlocity_ins__ContributionPercent__c=' + info.contribution.vlocity_ins__ContributionPercent__c : ' | Contribution=null'));
        } catch (Exception e) {
            return null;
        }
        
        return info;
    }
}