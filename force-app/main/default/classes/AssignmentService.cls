public class AssignmentService {

    public class FlowInput {
        @InvocableVariable(label='User Id' required=true)
        public String userId;

        @InvocableVariable(label='Scenario' required=true)
        public String scenario;
    }

    public class FlowOutput {
        @InvocableVariable
        public Id claimId;
    }

    @InvocableMethod(label='Find Next Claim For User' description='Finds the next Claim for a user based on the scenario')
    public static List<FlowOutput> findNextClaimForUser(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();

        for(FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();
            Claim claim = getNextClaim(input.userId, input.scenario);
            if(claim != null) {
                output.claimId = claim.Id;
            }
            outputs.add(output);
        }

        return outputs;
    }

    public static Claim getNextClaim(String userId, String scenario) {
        // Validate inputs
        if (String.isEmpty(userId) || String.isEmpty(scenario) || 
            !('Analysis'.equalsIgnoreCase(scenario) || 'Audit'.equalsIgnoreCase(scenario))) {
            throw new IllegalArgumentException('Invalid inputs');
        }
    
        // Step 1: Fetch All Skills the User Has
        Set<Id> userSkillIds = new Set<Id>();
        for (User_Skill__c us : [
            SELECT Skill__c FROM User_Skill__c WHERE User__c = :userId AND Type__c = :scenario
        ]) {
            userSkillIds.add(us.Skill__c);
        }
    
        if (userSkillIds.isEmpty()) {
            System.debug('User has no skills, skipping claim assignment.');
            return null;
        }
    
        // Step 2: Find All Possible Skills in the System
        Set<Id> allSkillIds = new Set<Id>();
        for (Skill__c skill : [
            SELECT Id FROM Skill__c
        ]) {
            allSkillIds.add(skill.Id);
        }
    
        // Step 3: Determine Missing Skills (Skills That Exist but the User Doesn't Have)
        Set<Id> missingSkillIds = new Set<Id>(allSkillIds);
        missingSkillIds.removeAll(userSkillIds); // Remove the ones the user does have
    
        // Step 4: Fetch SMBs Where User Has All Required Skills
        String scenarioCondition = '';
    
        if ('Analysis'.equalsIgnoreCase(scenario)) {
            scenarioCondition = 'Ready_for_Analysis__c = TRUE';
        } else if ('Audit'.equalsIgnoreCase(scenario)) {
            scenarioCondition = 'Ready_for_Audit__c = TRUE AND Analyzed_By__c != :userId';
        }
    
        List<Claim> eligibleClaims = Database.query(
            'SELECT Id, Name, ARC_OriginalReceivedDate__c, Related_Skills_Count__c ' +
            'FROM Claim ' +
            'WHERE ' + scenarioCondition + ' ' +
            'AND Id NOT IN (SELECT Shareable_Medical_Bill__c FROM SMB_Skill__c WHERE Skill__c IN :missingSkillIds) ' +
            'ORDER BY ARC_OriginalReceivedDate__c ASC ' +
            'LIMIT 1'
        );
    
        return eligibleClaims.isEmpty() ? null : eligibleClaims[0];

    }
}