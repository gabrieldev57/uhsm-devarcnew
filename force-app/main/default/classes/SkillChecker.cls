public class SkillChecker {
    @InvocableMethod(label='Check User Has Required Skills' description='Checks if a user has all the skills needed to analyze and audit an SMB.')
    public static List<CheckResult> hasRequiredSkills(List<SkillCheckRequest> requests) {
        List<CheckResult> results = new List<CheckResult>();

        for (SkillCheckRequest req : requests) {
            CheckResult result = new CheckResult();
            
            List<Id> requiredSkillIds = new List<Id>();
            for (SMB_Skill__c smbSkill : req.smbSkills) {
                requiredSkillIds.add(smbSkill.Skill__c);
            }

            List<Id> userSkillIds = new List<Id>();
            for (User_Skill__c userSkill : req.userSkills) {
                userSkillIds.add(userSkill.Skill__c);
            }

			Set<Id> requiredSkillSet = new Set<Id>(requiredSkillIds);
			Set<Id> userSkillSet = new Set<Id>(userSkillIds);
			requiredSkillSet.removeAll(userSkillSet);
			result.hasSkills = requiredSkillSet.isEmpty(); 

            results.add(result);
        }

        return results;
    }

    public class SkillCheckRequest {
        @InvocableVariable(label='SMB Skills' required=true)
        public List<SMB_Skill__c> smbSkills;

        @InvocableVariable(label='User Skills' required=true)
        public List<User_Skill__c> userSkills;
    }

    public class CheckResult {
        @InvocableVariable
        public Boolean hasSkills;
    }
}