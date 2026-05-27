trigger ARC_CreateUserSmallGroupTrigger on Create_User_Small_Group__e (after insert) {
    List<ARC_CreateUserSmallGroup.Input> inputs = new List<ARC_CreateUserSmallGroup.Input>();
    for (Create_User_Small_Group__e event : Trigger.New) {
        ARC_CreateUserSmallGroup.Input input = new ARC_CreateUserSmallGroup.Input();
        input.alias = event.Alias__c;
        input.contactId = event.ContactId__c;
        input.email = event.Email__c;
        input.firstName = event.FirstName__c;
        input.lastName = event.LastName__c;
        input.phone = event.Phone__c;
        input.profileId = event.ProfileId__c;
        input.username = event.Username__c;
        inputs.add(input);
    }
    if (!inputs.isEmpty()) {
        ARC_CreateUserSmallGroup.createUser(inputs[0]);
    }
}