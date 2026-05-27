/**
 * @description Standalone reusable service to compare a member's current active policy price
 *              against what the renewal pricing would be.
 *              Designed to be called independently from ARC_AutoRenewalPolicyBatch or any other context.
 * @author lucas.benero@arcsona.com
 * @date 2026-05-06
 */
public without sharing class ARC_AutoRenewalPricingService {

    /**
     * @description Determines whether the renewal price for a member matches their current active policy
     *              employee contribution (i.e., plan and price have not changed).
     *
     *              Calls the ARC_getRatedProductsWithContributions pricing integration procedure with the
     *              member's current age, then sums priceWithContributions across all returned products and
     *              compares it — rounded to 2 decimal places — to the active policy's EmployeeContribution.
     *
     * @param memberAccountId   The Account ID of the employee (NameInsuredId on the policy)
     * @param activePolicy      The member's currently active InsurancePolicy record (must have EmployeeContribution populated)
     * @param renewalContractId The renewal Contract ID (used for context when the pricing IP resolves the contract)
     * @return Boolean          true if renewal price equals current price, false otherwise or on pricing errors
     */
    public static Boolean pricesMatch(Id memberAccountId, InsurancePolicy activePolicy, Id renewalContractId) {
        if (memberAccountId == null || activePolicy == null) {
            return false;
        }

        // Resolve primary census member for this account (mirrors ARC_SGEnrollmentEndpoint.buildMemberDataFromId)
        List<vlocity_ins__GroupCensusMember__c> censusMembers = [
            SELECT Id, Name, ARC_AgeInSixMonths__c, vlocity_ins__CensusId__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__AccountId__c = :memberAccountId
              AND vlocity_ins__IsPrimaryMember__c = true
            LIMIT 1
        ];
        if (censusMembers.isEmpty()) {
            System.debug('ARC_AutoRenewalPricingService: no primary census member found for Account ' + memberAccountId);
            return false;
        }
        vlocity_ins__GroupCensusMember__c censusMember = censusMembers[0];
        Integer primaryAge = censusMember.ARC_AgeInSixMonths__c != null ? censusMember.ARC_AgeInSixMonths__c.intValue() : 0;

        // Build MemberInput — primary
        ARC_getRatedProductsWithContributions.MemberInput mi = new ARC_getRatedProductsWithContributions.MemberInput();
        mi.Name = censusMember.Name;
        mi.Age = primaryAge;
        mi.PrimaryAge = primaryAge;
        mi.IsPrimary = true;
        mi.PrimaryId = String.valueOf(censusMember.Id);
        mi.IsLegacy = false;

        List<ARC_getRatedProductsWithContributions.MemberInput> memberInputList =
            new List<ARC_getRatedProductsWithContributions.MemberInput>{ mi };

        // Query actual dependent census members by CensusId (same approach as buildMemberDataFromId)
        List<vlocity_ins__GroupCensusMember__c> dependents = [
            SELECT Id, Name, ARC_AgeInSixMonths__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE vlocity_ins__CensusId__c = :censusMember.vlocity_ins__CensusId__c
              AND vlocity_ins__IsPrimaryMember__c = false
        ];
        for (vlocity_ins__GroupCensusMember__c dep : dependents) {
            ARC_getRatedProductsWithContributions.MemberInput depInput = new ARC_getRatedProductsWithContributions.MemberInput();
            depInput.Name = dep.Name;
            depInput.Age = dep.ARC_AgeInSixMonths__c != null ? dep.ARC_AgeInSixMonths__c.intValue() : 0;
            depInput.PrimaryAge = primaryAge;
            depInput.IsPrimary = false;
            depInput.PrimaryId = String.valueOf(censusMember.Id);
            depInput.IsLegacy = false;
            memberInputList.add(depInput);
        }

        // Call pricing
        String pricingJson;
        try {
            pricingJson = ARC_getRatedProductsWithContributions.getProductsWithContributionsJson(memberInputList);
        } catch (Exception e) {
            System.debug('ARC_AutoRenewalPricingService: pricing call failed for Account ' + memberAccountId + ' — ' + e.getMessage());
            return false;
        }

        if (String.isBlank(pricingJson) || pricingJson == '{}') {
            System.debug('ARC_AutoRenewalPricingService: pricing returned empty result for Account ' + memberAccountId);
            return false;
        }

        // Check for error response
        Map<String, Object> parsedResult;
        try {
            parsedResult = (Map<String, Object>) JSON.deserializeUntyped(pricingJson);
            System.debug(JSON.serializePretty(parsedResult));
        } catch (Exception e) {
            System.debug('ARC_AutoRenewalPricingService: failed to parse pricing JSON for Account ' + memberAccountId);
            return false;
        }

        if (parsedResult.containsKey('error')) {
            System.debug('ARC_AutoRenewalPricingService: pricing error for Account ' + memberAccountId + ' — ' + parsedResult.get('error'));
            return false;
        }

        // Collect ProductCodes the member is enrolled in — IDs differ across contract catalog versions
        // so matching by ProductCode is the stable way to correlate active coverage to renewal pricing
        Set<Id> activeCoverageProductIds = new Set<Id>();
        for (InsurancePolicyCoverage cov : activePolicy.InsurancePolicyCoverages) {
            if (cov.ARC_ParentProduct__c == null && cov.vlocity_ins_fsc__Product2Id__c != null) {
                activeCoverageProductIds.add(cov.vlocity_ins_fsc__Product2Id__c);
            }
        }
        Set<String> activeCoverageProductCodes = new Set<String>();
        if (!activeCoverageProductIds.isEmpty()) {
            for (Product2 p : [SELECT ProductCode FROM Product2 WHERE Id IN :activeCoverageProductIds]) {
                if (p.ProductCode != null) activeCoverageProductCodes.add(p.ProductCode);
            }
        }
        System.debug('ARC_AutoRenewalPricingService: Account=' + memberAccountId
            + ' activeCoverageProductCodes=' + activeCoverageProductCodes
            + ' totalCoverages=' + activePolicy.InsurancePolicyCoverages.size());

        // Sum priceWithContributions only for products the member is enrolled in (matched by ProductCode)
        Decimal renewalEmployeePrice = 0;
        for (String productName : parsedResult.keySet()) {
            Map<String, Object> productNode = (Map<String, Object>) parsedResult.get(productName);
            if (productNode == null) continue;
            String productCode = productNode.get('productCode') != null ? String.valueOf(productNode.get('productCode')) : null;
            Boolean matched = productCode != null && activeCoverageProductCodes.contains(productCode);
            System.debug('ARC_AutoRenewalPricingService: product=' + productName + ' productCode=' + productCode + ' matched=' + matched);
            if (!matched) continue;
            Object priceObj = productNode.get('priceWithContributions');
            if (priceObj != null) {
                renewalEmployeePrice += Decimal.valueOf(String.valueOf(priceObj));
            }
        }

        Decimal currentEmployeePrice = activePolicy.ARC_TotalPremiumAmount__c != null ? activePolicy.ARC_TotalPremiumAmount__c : 0;

        Decimal renewalRounded = renewalEmployeePrice.setScale(2, System.RoundingMode.HALF_UP);
        Decimal currentRounded = currentEmployeePrice.setScale(2, System.RoundingMode.HALF_UP);

        System.debug('ARC_AutoRenewalPricingService: Account=' + memberAccountId
            + ' currentPrice=' + currentRounded + ' renewalPrice=' + renewalRounded
            + ' match=' + (renewalRounded == currentRounded));

        return renewalRounded == currentRounded;
    }
}