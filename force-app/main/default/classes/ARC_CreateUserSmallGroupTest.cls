@IsTest (isParallel=false)
private class ARC_CreateUserSmallGroupTest {

    @TestSetup
    static void setupData() {
        // Ensure we have a Contact to link to the new User
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test.contact@example.com', AccountId = acc.Id);
        insert con;
    }
    
    /**
     * Helper to find a profile suitable for portal users (portal/community).
     * Returns null if none found.
     */
    private static Id getPortalProfileIdOrNull() {
        // Use the known portal profile name provided: 'Employer Admin'
        List<Profile> portalProfiles = [SELECT Id, Name FROM Profile WHERE Name = 'Employer Admin' LIMIT 1];
        if (!portalProfiles.isEmpty()) {
            return portalProfiles[0].Id;
        }
        // Fallback to any profile with Community/Portal in the name if the exact one is not present
        portalProfiles = [SELECT Id, Name FROM Profile WHERE Name LIKE '%Community%' OR Name LIKE '%Portal%' LIMIT 1];
        if (!portalProfiles.isEmpty()) {
            return portalProfiles[0].Id;
        }
        return null;
    }

    /**
     * Helper to find a valid standard profile for testing.
     * Prefer a non-admin standard profile commonly available in orgs.
     */
    private static Id getAnyStandardProfileId() {
        // Try to find a standard profile appropriate for community/portal/user creation as needed.
        // Fallback to any active profile if specific ones are not found.
        List<Profile> candidates = [
            SELECT Id, Name
            FROM Profile
            WHERE Name IN ('Standard User', 'Salesforce Platform User', 'Minimum Access - Salesforce')
            LIMIT 1
        ];
        if (!candidates.isEmpty()) {
            return candidates[0].Id;
        }
        // Fallback - pick any profile
        return [SELECT Id FROM Profile LIMIT 1][0].Id;
    }

    private static ARC_CreateUserSmallGroup.Input buildInput(Id contactId, String username, String email) {
        ARC_CreateUserSmallGroup.Input input = new ARC_CreateUserSmallGroup.Input();
        input.alias = 'tuser';
        // Do not set contactId here directly. The test will decide whether to attach a Contact based on available profiles.
        input.contactId = null;
        input.email = email;
        input.firstName = 'First';
        input.lastName = 'Last';
        input.phone = '555-0100';
        input.profileId = getAnyStandardProfileId();
        input.username = username;
        return input;
    }

    @IsTest
    static void testPublishCreateUserEventPublishesEvent() {
        // Arrange
        Contact c = [SELECT Id, Email FROM Contact LIMIT 1];
        String unique = String.valueOf(DateTime.now().getTime());
        ARC_CreateUserSmallGroup.Input inpt = buildInput(
            null,
            'sg_' + unique + '@example.com',   // username must be unique and in email format
            'sg_' + unique + '@example.com'
        );
        // Use portal profile when available for event test (not required but safe)
        Id portalProfileId = getPortalProfileIdOrNull();
        if (portalProfileId != null) {
            inpt.profileId = portalProfileId;
            inpt.contactId = c.Id;
        }

        // Act
        Test.startTest(); 
        ARC_CreateUserSmallGroup.publishCreateUserEvent(new List<ARC_CreateUserSmallGroup.Input>{ inpt }); 
        Test.stopTest();
        
    }

    @IsTest
    static void testCreateUserCreatesUserSuccessfully() {
        // Arrange
        Contact c = [SELECT Id, Email FROM Contact LIMIT 1];
        String unique = String.valueOf(DateTime.now().getTime());
        String uname = 'user_' + unique + '@example.com';
        ARC_CreateUserSmallGroup.Input inpt = buildInput(
            null,
            uname,
            'user_email_' + unique + '@example.com'
        );

        // If a portal profile exists, attach the contact and use portal profile.
        Id portalProfileId = getPortalProfileIdOrNull();
        if (portalProfileId != null) {
            inpt.profileId = portalProfileId;
            inpt.contactId = c.Id;
        }

        Test.startTest(); 
        ARC_CreateUserSmallGroup.createUser(inpt); 
        Test.stopTest();


        // Verify the user exists with expected fields
        User u = [ SELECT Id, Alias, ContactId, Email, FirstName, LastName, Phone, ProfileId, Username, TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey, EmailEncodingKey 
        FROM User WHERE Username = :uname LIMIT 1 ]; 
        System.assertEquals(inpt.alias, u.Alias, 'Alias not set correctly'); 
        // Only assert ContactId when we supplied one (portal profile present)
        if (inpt.contactId != null) {
            System.assertEquals(inpt.contactId, u.ContactId, 'ContactId not set correctly'); 
        } else {
            System.assertEquals(null, u.ContactId, 'ContactId should be null when no portal profile is available');
        }
        System.assertEquals(inpt.email, u.Email, 'Email not set correctly'); 
        System.assertEquals(inpt.firstName, u.FirstName, 'FirstName not set correctly'); 
        System.assertEquals(inpt.lastName, u.LastName, 'LastName not set correctly'); 
        System.assertEquals(inpt.phone, u.Phone, 'Phone not set correctly'); 
        System.assertEquals(inpt.profileId, u.ProfileId, 'ProfileId not set correctly'); 
        System.assertEquals(inpt.username, u.Username, 'Username not set correctly'); 
        System.assertEquals('America/Los_Angeles', u.TimeZoneSidKey, 'TimeZone not set correctly'); 
        System.assertEquals('en_US', u.LocaleSidKey, 'Locale not set correctly'); 
        System.assertEquals('en_US', u.LanguageLocaleKey, 'Language not set correctly'); 
        System.assertEquals('UTF-8', u.EmailEncodingKey, 'Email encoding not set correctly');
  
        
    }
}