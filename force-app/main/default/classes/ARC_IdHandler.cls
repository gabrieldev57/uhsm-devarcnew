public with sharing class ARC_IdHandler {

    public static void insertPolicyId(List<InsurancePolicy> policies) {
        //Day
        String currentDay = String.valueOf(System.today().day());
        String dayStr = currentDay.length() == 1 ? '0' + currentDay : currentDay;
        //Month
        String currentMonth = String.valueOf(System.today().month());
        String monthStr = currentMonth.length() == 1 ? '0' + currentMonth : currentMonth;
        //Year
        String currentYear = String.valueOf(System.today().year());

        Integer count = 0;

        try {
            InsurancePolicy newestPolicy = [SELECT CreatedDate,Name FROM InsurancePolicy ORDER BY CreatedDate DESC LIMIT 1];
            if (newestPolicy != null) {
                String policyDay = String.valueOf(newestPolicy.CreatedDate.day());
                String policyMonth = String.valueOf(newestPolicy.CreatedDate.month());
                String policyYear = String.valueOf(newestPolicy.CreatedDate.year());

                if (currentDay.equals(policyDay) && currentMonth.equals(policyMonth) && currentYear.equals(policyYear)) {
                    count = Integer.valueOf(newestPolicy.Name.substring(8));
                }
            }
        } catch (Exception error) {
            System.debug('Invalid Previous Policy');
        }

        for (InsurancePolicy policy : policies) {
            if (policy.Name == 'ShopAndEnroll Policy') {
                String stringId = String.valueOf(count+1);
                String ceros = '00000000'.substring(stringId.length());
                policy.Name = currentYear + monthStr + dayStr + ceros + stringId;
                count = count + 1;
            }
        }
    }

    public static void insertClaimCoveragePaymentDetail(List<ClaimCoveragePaymentDetail> ccpd){
        Map<Id, ClaimCoveragePaymentDetail> claimIdList = new Map<Id, ClaimCoveragePaymentDetail>();
        for (ClaimCoveragePaymentDetail item : ccpd) {
            if (item.ARC_Claim__c != null) {
                claimIdList.put(item.ARC_Claim__c, null);
            }
        }
        List<ClaimCoveragePaymentDetail> lastItems = [SELECT Name, Id, ARC_Claim__c FROM ClaimCoveragePaymentDetail WHERE ARC_Claim__c IN: claimIdList.keySet() ORDER BY CreatedDate DESC];
        for (ClaimCoveragePaymentDetail lastItem : lastItems) {
            try {
                if (String.valueOf(lastItem.Name) > String.valueOf(claimIdList.get(lastItem.ARC_Claim__c))) {
                    claimIdList.put(lastItem.ARC_Claim__c, lastItem);
                }
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }
        System.debug(claimIdList);
        for (ClaimCoveragePaymentDetail item : ccpd) {
            if (claimIdList.get(item.ARC_Claim__c) != null) {
                if (claimIdList.get(item.ARC_Claim__c).ARC_Claim__c == item.ARC_Claim__c) {
                    
                    item.Name = String.valueOf(Integer.valueOf(claimIdList.get(item.ARC_Claim__c).Name) + 1);
                }
            }else{
                item.Name = '1';
            }     
        }
    }

    
}