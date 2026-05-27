public without sharing class AccountShareHandler {
    public class InputWrapper{
        @InvocableVariable(required=true) public List<Id> accountIds; 
        @InvocableVariable(required=true) public Id userId;
        @InvocableVariable(required=true) public String accessLevel; 
        @InvocableVariable public String role;    
    }
    
    @InvocableMethod(label='Add Account Team Member to Accounts' description='Add Account Team Member')
    public static void addTeamMembers(List<InputWrapper> requests){
        Set<Id> accountIds = new Set<Id>(); 
        List<AccountTeamMember> toInsert = new List<AccountTeamMember>(); 
        
        for (InputWrapper req : requests){
            if (req == null || req.accountIds == null) continue; 
            
            for (Id acc : req.accountIds){
                if (acc == null) continue; 
                
                Set<String> existingKeys = new Set<String>(); 
                
                // Query with SYSTEM_MODE to bypass all permission checks
                for (AccountTeamMember atm : [
                    SELECT UserId, TeamMemberRole 
                    FROM AccountTeamMember 
                    WHERE AccountId = :acc
                    WITH SYSTEM_MODE
                ]){
                    existingKeys.add(atm.UserId + '-' + atm.TeamMemberRole);
                }        
                
                String newKey = req.userId + '-' + req.role; 
                if (!existingKeys.contains(newKey)){
                    toInsert.add(new AccountTeamMember(
                        AccountId = acc, 
                        UserId = req.userId, 
                        TeamMemberRole = req.role, 
                        AccountAccessLevel = req.accessLevel
                    ));
                }
            }
            System.debug('request: ' + req); 
        }
        
        if (!toInsert.isEmpty()){
            // Insert with SYSTEM_MODE to bypass all permission checks
            insert as system toInsert; 
        }
    }
}