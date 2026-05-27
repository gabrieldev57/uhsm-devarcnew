public class AccountTeamsHandler {
    
    // Static variable to store data between before and after contexts
    private static Map<Id, AccountTeamMember> capturedSellingAgents = new Map<Id, AccountTeamMember>();
    
    // BEFORE UPDATE: Capture existing Selling Agent records
    public static void captureSellingAgentData(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Set<Id> accountsWithOwnerChange = new Set<Id>();

        
        for (Account acc : newAccounts) {
            Account oldAcc = oldMap.get(acc.Id);
            if (acc.OwnerId != oldAcc.OwnerId) {
                accountsWithOwnerChange.add(acc.Id);
            }
        }
        
        if (!accountsWithOwnerChange.isEmpty()) {
            // Query and store the Selling Agent records before Salesforce deletes them
            List<AccountTeamMember> sellingAgents = [
                SELECT Id, AccountId, UserId, TeamMemberRole, 
                       AccountAccessLevel, OpportunityAccessLevel, CaseAccessLevel
                FROM AccountTeamMember 
                WHERE AccountId IN :accountsWithOwnerChange
                AND TeamMemberRole = 'Selling Agent'
            ];
            
            for (AccountTeamMember atm : sellingAgents) {
                // Only store if this team member is the old owner
                capturedSellingAgents.put(atm.AccountId, atm);
            }
        }
    }
    
    // AFTER UPDATE: Recreate the Selling Agent records
    public static void recreateSellingAgents(List<Account> newAccounts, Map<Id, Account> oldMap) {
        List<AccountTeamMember> teamMembersToCreate = new List<AccountTeamMember>();
        
        for (Account acc : newAccounts) {           
            if (capturedSellingAgents.containsKey(acc.Id)) {
                AccountTeamMember original = capturedSellingAgents.get(acc.Id);
                
                AccountTeamMember newMember = new AccountTeamMember(
                    AccountId = original.AccountId,
                    UserId = original.UserId, // Previous Selling Agent
                    TeamMemberRole = 'Selling Agent',
                    AccountAccessLevel = original.AccountAccessLevel,
                    OpportunityAccessLevel = original.OpportunityAccessLevel,
                    CaseAccessLevel = original.CaseAccessLevel
                );
                teamMembersToCreate.add(newMember);
            }
        }
        
        if (!teamMembersToCreate.isEmpty()) {
            Database.insert(teamMembersToCreate, false);
        }
        
        // Clear the static variable for next execution
        capturedSellingAgents.clear();
    }
}