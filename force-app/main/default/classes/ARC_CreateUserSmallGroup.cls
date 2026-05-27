public without sharing class ARC_CreateUserSmallGroup {
    public class Input {
        @InvocableVariable
        public String alias;
        @InvocableVariable
        public String contactId;
        @InvocableVariable
        public String email;
        @InvocableVariable
        public String firstName;
        @InvocableVariable
        public String lastName;
        @InvocableVariable
        public String phone;
        @InvocableVariable
        public String profileId;
        @InvocableVariable
        public String username;
    }
    @InvocableMethod(label='Create User')
    public static void publishCreateUserEvent(List<Input> inputs) {
        Input input = inputs[0];
        // Publish the event 
        Create_User_Small_Group__e event = new Create_User_Small_Group__e(
            Alias__c = input.alias,
            ContactId__c = input.contactId,
            Email__c = input.email,
            FirstName__c = input.firstName,
            LastName__c = input.lastName,
            Phone__c = input.phone,
            ProfileId__c = input.profileId,
            Username__c = input.username
        );
        EventBus.publish(event);
    }
    public static void createUser(Input input) {
        User user = new User();
        user.Alias = input.alias;
        user.ContactId = input.contactId;
        user.Email = input.email;
        user.FirstName = input.firstName;
        user.LastName = input.lastName;
        user.Phone = input.phone;
        user.ProfileId = input.profileId;
        user.Username = input.username;
        user.TimeZoneSidKey = 'America/Los_Angeles';
        user.LocaleSidKey = 'en_US';
        user.LanguageLocaleKey = 'en_US';
        user.EmailEncodingKey = 'UTF-8';
        insert user;
    }
}