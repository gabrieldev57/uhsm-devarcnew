public with sharing class AccountShareHandler {
    public class ShareInput{
        @InvocableVariable(required=true) public Id accountId; 
        @InvocableVariable(required=true) public Id userId;
        @InvocableVariable public String accessLevel; 
    }

    public class ShareResult{
        @InvocableVariable public Id accountId; 
        @InvocableVariable public Id userId; 
        @InvocableVariable public Boolean result; 
        @InvocableVariable public String errorMessage;
    }

    private static ShareResult result(ShareInput input, Boolean res, String errorMessage){
        ShareResult r = new ShareResult();
        r.accountId = (input != null) ? input.accountId : null;
        r.userId = (input != null) ? input.userId : null;
        r.result = res; 
        r.errorMessage = errorMessage; 
        return r;
    }


    @InvocableMethod(label='Share Account' description='Share Account')
    public static List<ShareResult> createShares(List<ShareInput> inputs){
        List<ShareResult> results = new List<ShareResult>();
        if (inputs == null || inputs.isEmpty()){
            return results;
        }

        System.debug('inputs: ' + inputs); 
        Map<String, ShareInput> inputMap = new Map<String, ShareInput>();
        Set<Id> accountIds = new Set<Id>();

        for(ShareInput input : inputs){
            if (input != null && input.accountId != null && input.userId != null){
                inputMap.put(input.accountId + '-' + input.userId, input);
                accountIds.add(input.accountId);
            }
        }
        if (inputMap.isEmpty()){
            return results; 
        }
        Map<String, AccountShare> existingShares = new Map<String, AccountShare>();
        for(AccountShare share : [SELECT Id, AccountId, UserOrGroupId, RowCause FROM AccountShare WHERE AccountId IN : accountIds AND RowCause =: Schema.AccountShare.RowCause.Manual]){
            existingShares.put(share.AccountId + '-' + String.valueOf(share.UserOrGroupId), share);
        }

        // inserts: 

        List<AccountShare> sharesToInsert = new List<AccountShare>();
        for (String mapKey : inputMap.keySet()){
            if (existingShares.containsKey(mapKey)){
                ShareInput originalInput = inputMap.get(mapKey);
                results.add(result(originalInput, false, 'Share already exists')); 
                continue; 
            }
            ShareInput shareIn = inputMap.get(mapKey); 
            AccountShare share = new AccountShare();
            share.AccountId = shareIn.accountId;
            share.UserOrGroupId = shareIn.userId;
            share.AccountAccessLevel = shareIn.accessLevel;
            share.OpportunityAccessLevel = 'Read'; 
            share.CaseAccessLevel = 'Read'; 
            share.RowCause = Schema.AccountShare.RowCause.Manual;
            sharesToInsert.add(share);
        }

        if (!sharesToInsert.isEmpty()){
            Database.SaveResult[] insertResults = Database.insert(sharesToInsert, false);
            System.debug('SaveResult:' + insertResults); 
            for (Integer i=0; i<insertResults.size(); i++){
                AccountShare accShare = sharesToInsert[i];
                ShareInput originalInput = inputMap.get(sharesToInsert[i].AccountId + '-' + String.valueOf(sharesToInsert[i].UserOrGroupId));
                if (insertResults[i].isSuccess()){
                    results.add(result(originalInput, true, null));
                    }
            }
        }
        return results; 
    }
}