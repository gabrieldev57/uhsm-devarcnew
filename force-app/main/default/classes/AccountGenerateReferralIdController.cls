public class AccountGenerateReferralIdController {
    @TestVisible
    public static List<String> mockIds = new List<String>();
    @TestVisible
    public static Integer mockIdIndex = 0;
    
    public static void assignReferralIds(List<Account> newAccounts) {
        String charString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        Set<String> allGeneratedIds = new Set<String>();
        
        // Step 1: generate initial IDs
        for (Account acc : newAccounts) {
            if (String.isBlank(acc.Referral_Id__c)) {
                String referralId;
                do {
                    referralId = generateRandomId(charString, 15);
                } while (allGeneratedIds.contains(referralId));
                
                acc.Referral_Id__c = referralId;
                allGeneratedIds.add(referralId);
            }
        }
        
        // Step 2: check existing Accounts for collisions (single query)
        Set<String> existingIds = new Set<String>();
        for (Account existingAcc : [SELECT Referral_Id__c FROM Account WHERE Referral_Id__c IN :allGeneratedIds]) {
            existingIds.add(existingAcc.Referral_Id__c);
        }
        
        // Step 3: regenerate only the colliding ones - collect all new IDs first
        Set<String> regeneratedIds = new Set<String>();
        for (Account acc : newAccounts) {
            while (existingIds.contains(acc.Referral_Id__c)) {
                String newId;
                do {
                    newId = generateRandomId(charString, 15);
                } while (allGeneratedIds.contains(newId) || existingIds.contains(newId));
                
                acc.Referral_Id__c = newId;
                allGeneratedIds.add(newId);
                regeneratedIds.add(newId);
            }
        }
        
        // Step 4: Single query to verify all regenerated IDs (if any)
        if (!regeneratedIds.isEmpty()) {
            Set<String> stillConflicting = new Set<String>();
            for (Account existingAcc : [SELECT Referral_Id__c FROM Account WHERE Referral_Id__c IN :regeneratedIds]) {
                stillConflicting.add(existingAcc.Referral_Id__c);
            }
            
            // Handle any remaining conflicts (extremely rare edge case)
            if (!stillConflicting.isEmpty()) {
                existingIds.addAll(stillConflicting);
                for (Account acc : newAccounts) {
                    if (stillConflicting.contains(acc.Referral_Id__c)) {
                        String finalId;
                        do {
                            finalId = generateRandomId(charString, 15);
                        } while (allGeneratedIds.contains(finalId) || existingIds.contains(finalId));
                        
                        acc.Referral_Id__c = finalId;
                        allGeneratedIds.add(finalId);
                    }
                }
            }
        }
    }
        
    // Keep the original generateRandomId method unchanged to preserve mockIds functionality
    private static String generateRandomId(String chars, Integer length) {
        // Use mock IDs in test context
        if (Test.isRunningTest() && !mockIds.isEmpty() && mockIdIndex < mockIds.size()) {
            return mockIds[mockIdIndex++];
        }
        
        String id = '';
        for (Integer i = 0; i < length; i++) {
            Integer index = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            id += chars.substring(index, index + 1);
        }
        return id;
     }
    }