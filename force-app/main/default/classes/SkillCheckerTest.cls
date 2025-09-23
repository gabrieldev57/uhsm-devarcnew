@isTest
public class SkillCheckerTest {
    @isTest static void testHasRequiredSkills() {
        // Create Test Data
        Skill__c skill1 = new Skill__c(Name = 'Skill1');
        insert skill1;

        Skill__c skill2 = new Skill__c(Name = 'Skill2');
        insert skill2;

        Claim claim1 = new Claim(Name = 'Test Claim 1', Status = 'Initial', ARC_OriginalReceivedDate__c = Date.today().addDays(-2));
        
        insert new List<Claim>{claim1};
        
        SMB_Skill__c smbSkill1 = new SMB_Skill__c(Skill__c = skill1.Id, Shareable_Medical_Bill__c=claim1.Id);
        SMB_Skill__c smbSkill2 = new SMB_Skill__c(Skill__c = skill2.Id, Shareable_Medical_Bill__c=claim1.Id);
        insert new List<SMB_Skill__c> { smbSkill1, smbSkill2 };

        User_Skill__c userSkill1 = new User_Skill__c(Skill__c = skill1.Id);
        insert userSkill1;

        // Test: User missing one skill
        SkillChecker.SkillCheckRequest request1 = new SkillChecker.SkillCheckRequest();
        request1.smbSkills = new List<SMB_Skill__c> { smbSkill1, smbSkill2 };
        request1.userSkills = new List<User_Skill__c> { userSkill1 };

        List<SkillChecker.CheckResult> results = SkillChecker.hasRequiredSkills(new List<SkillChecker.SkillCheckRequest> { request1 });

        System.assertEquals(1, results.size(), 'Expected one result');
        System.assertEquals(false, results[0].hasSkills, 'User should not have all required skills');

        // Test: User has all skills
        User_Skill__c userSkill2 = new User_Skill__c(Skill__c = skill2.Id);
        insert userSkill2;

        SkillChecker.SkillCheckRequest request2 = new SkillChecker.SkillCheckRequest();
        request2.smbSkills = new List<SMB_Skill__c> { smbSkill1, smbSkill2 };
        request2.userSkills = new List<User_Skill__c> { userSkill1, userSkill2 };

        results = SkillChecker.hasRequiredSkills(new List<SkillChecker.SkillCheckRequest> { request2 });

        System.assertEquals(1, results.size(), 'Expected one result');
        System.assertEquals(true, results[0].hasSkills, 'User should have all required skills');

    }
}