@IsTest
public class AssignmentServiceTest {

    // Test invalid inputs
    @IsTest
    static void testInvalidInputs() {
        try {
            AssignmentService.getNextClaim(null, 'Analysis');
            System.assert(false, 'Expected an exception for null userId.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Invalid inputs', e.getMessage(), 'Exception message should match.');
        }

        try {
            AssignmentService.getNextClaim(UserInfo.getUserId(), null);
            System.assert(false, 'Expected an exception for null scenario.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Invalid inputs', e.getMessage(), 'Exception message should match.');
        }

        try {
            AssignmentService.getNextClaim(UserInfo.getUserId(), 'InvalidScenario');
            System.assert(false, 'Expected an exception for invalid scenario.');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Invalid inputs', e.getMessage(), 'Exception message should match.');
        }
    }

    // Test no claims available
    @IsTest
    static void testNoClaimsAvailable() {
        // Create a user skill
        Skill__c skill1 = new Skill__c(Name = 'Metal');
        insert skill1;

        User_Skill__c userSkill = new User_Skill__c(User__c = UserInfo.getUserId(), Skill__c = skill1.Id, Type__c = 'Analysis');
        insert userSkill;

        // Execute
        Claim result = AssignmentService.getNextClaim(UserInfo.getUserId(), 'Analysis');

        // Assert
        System.assertEquals(null, result, 'No claim should be assigned if no claims are available.');
    }

    // Test claims without skills
    @IsTest
    static void testClaimWithoutSkills() {
        // Setup: Create a Claim
        Claim claim = new Claim(
            Name = 'Test Claim',
            ARC_OriginalReceivedDate__c = Date.newInstance(2024, 1, 1)
        );
        insert claim;

        // Create a user skill
        Skill__c skill1 = new Skill__c(Name = 'Metal');
        insert skill1;

        User_Skill__c userSkill = new User_Skill__c(User__c = UserInfo.getUserId(), Skill__c = skill1.Id, Type__c = 'Analysis');
        insert userSkill;

        // Execute
        Claim result = AssignmentService.getNextClaim(UserInfo.getUserId(), 'Analysis');

        // Assert
        System.assertEquals(null, result, 'No claim should be assigned if the claim has no skills.');
    }

    // Test multiple claims with different dates
    @IsTest
    static void testMultipleClaims() {
        // Setup: Create Claims
        Claim claim1 = new Claim(
            Name = 'Claim 1',
            ARC_OriginalReceivedDate__c = Date.newInstance(2024, 1, 1)
        );
        Claim claim2 = new Claim(
            Name = 'Claim 2',
            ARC_OriginalReceivedDate__c = Date.newInstance(2023, 12, 31)
        );
        insert new List<Claim>{claim1, claim2};

        // Set up skills
        Skill__c skill1 = new Skill__c(Name = 'Metal');
        insert skill1;

        // Link skills to claims
        insert new SMB_Skill__c(Shareable_Medical_Bill__c = claim1.Id, Skill__c = skill1.Id);
        insert new SMB_Skill__c(Shareable_Medical_Bill__c = claim2.Id, Skill__c = skill1.Id);

        // Create a user with the required skill
        User_Skill__c userSkill = new User_Skill__c(User__c = UserInfo.getUserId(), Skill__c = skill1.Id, Type__c = 'Analysis');
        insert userSkill;

        // Execute
        Claim result = AssignmentService.getNextClaim(UserInfo.getUserId(), 'Analysis');

        // Assert
        System.assertNotEquals(null, result, 'The user should be assigned a claim because they meet the required skills.');
        System.assertEquals(claim2.Id, result.Id, 'The claim with the earliest date should be assigned.');
    }
    
    // Test findNextClaimForUser
    @IsTest
    static void testFindNextClaimForUser() {
        // Setup: Create a Claim
        Claim claim = new Claim(
            Name = 'Test Claim',
            ARC_OriginalReceivedDate__c = Date.newInstance(2024, 1, 1)
        );
        insert claim;

        // Set up a skill and link it to the claim
        Skill__c skill = new Skill__c(Name = 'Metal');
        insert skill;
        insert new SMB_Skill__c(Shareable_Medical_Bill__c = claim.Id, Skill__c = skill.Id);

        // Create a user with the required skill
        User_Skill__c userSkill = new User_Skill__c(User__c = UserInfo.getUserId(), Skill__c = skill.Id, Type__c = 'Analysis');
        insert userSkill;

        // Prepare input for the findNextClaimForUser method
        AssignmentService.FlowInput input = new AssignmentService.FlowInput();
        input.userId = UserInfo.getUserId();
        input.scenario = 'Analysis';

        List<AssignmentService.FlowInput> inputs = new List<AssignmentService.FlowInput>{input};

        // Execute the method
        List<AssignmentService.FlowOutput> outputs = AssignmentService.findNextClaimForUser(inputs);

        // Assert that the claim is assigned correctly
        System.assertNotEquals(null, outputs, 'Outputs should not be null.');
        System.assertEquals(1, outputs.size(), 'There should be exactly one output.');
        System.assertNotEquals(null, outputs[0].claimId, 'The claimId should not be null.');
        System.assertEquals(claim.Id, outputs[0].claimId, 'The assigned claimId should match the expected claim.');
    }
    
}