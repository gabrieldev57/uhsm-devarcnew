@isTest
private class ARC_ContractParticipantFieldsBatchTest {

    @isTest static void testBatchUpdate() {
        // Obtener RecordTypeId para Person Account
        Id personAccountRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;

        System.debug(personAccountRecordTypeId);

        Account personAcc = new Account(
            RecordTypeId = personAccountRecordTypeId,
            FirstName = 'Juan',
            LastName = 'Perez',
            PersonBirthdate = Date.newInstance(1985, 5, 20),
            PersonEmail = 'juan.perez@arcwona.com',
            ARC_Height__c = '180',
            ARC_Weight__c = '75',
            BillingStreet = 'Calle Falsa 123',
            BillingCity = 'Montevideo',
            BillingState = 'NY',
            BillingPostalCode = '12345',
            et4ae5__Mobile_Country_Code__pc = 'US',
            Phone = '099123456',
            vlocity_ins__SocialSecurityNumber__pc = '12345678',
            PersonGender = 'Male',
            ARC_Smoker__c = false,
            ARC_IsPrimaryMember__c = true
        );

        insert personAcc;

        Contract contract = new Contract(Name = 'Test', AccountId= personAcc.Id);
        insert contract;
    
        ARC_ContractParticipant__c contractParticipant = new ARC_ContractParticipant__c(
            ARC_PersonAccount__c = personAcc.Id,
            ARC_Relationship__c = null,
            ARC_FirstName__c = 'Juan',
            ARC_LastName__c = 'Perez',
            ARC_BirthDate__c = Date.newInstance(1985, 5, 20),
            ARC_Email__c = 'juan.perez@arcwona.com',
            ARC_Height__c = '180',
            ARC_Weight__c = '75',
            ARC_Address__Street__s = 'Calle Falsa 123',
            ARC_Address__City__s = 'Montevideo',
            ARC_Address__StateCode__s = 'NY',
            ARC_Address__PostalCode__s = '12345',
            ARC_Address__CountryCode__s = 'US',
            ARC_Phone__c = '099123456',
            ARC_Gender__c = 'Male',
            ARC_Smoker__c = false,
            ARC_Contract__c = contract.Id
        );

        insert contractParticipant;

        Test.startTest();
        ARC_ContractParticipantFieldsBatch batch = new ARC_ContractParticipantFieldsBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        ARC_ContractParticipant__c updatedParticipant = [
            SELECT ARC_FirstName__c, ARC_LastName__c, ARC_BirthDate__c, ARC_Email__c,
                   ARC_Height__c, ARC_Weight__c,
                   ARC_Address__Street__s, ARC_Address__City__s, ARC_Address__StateCode__s, ARC_Address__PostalCode__s, ARC_Address__CountryCode__s,
                   ARC_Phone__c, ARC_SocialSecurityNumber__c, ARC_Gender__c, ARC_Smoker__c, ARC_Relationship__c
            FROM ARC_ContractParticipant__c
            WHERE Id = :contractParticipant.Id
        ];

        System.assertEquals('Juan', updatedParticipant.ARC_FirstName__c);
        System.assertEquals('Perez', updatedParticipant.ARC_LastName__c);
        System.assertEquals(Date.newInstance(1985, 5, 20), updatedParticipant.ARC_BirthDate__c);
        System.assertEquals('juan.perez@arcwona.com', updatedParticipant.ARC_Email__c);
        System.assertEquals('180', updatedParticipant.ARC_Height__c);
        System.assertEquals('75', updatedParticipant.ARC_Weight__c);
        System.assertEquals('Calle Falsa 123', updatedParticipant.ARC_Address__Street__s);
        System.assertEquals('Montevideo', updatedParticipant.ARC_Address__City__s);
        System.assertEquals('NY', updatedParticipant.ARC_Address__StateCode__s);
        System.assertEquals('12345', updatedParticipant.ARC_Address__PostalCode__s);
        System.assertEquals('US', updatedParticipant.ARC_Address__CountryCode__s);
        System.assertEquals('099123456', updatedParticipant.ARC_Phone__c);
        System.assertEquals('Male', updatedParticipant.ARC_Gender__c);
        System.assertEquals(false, updatedParticipant.ARC_Smoker__c);
        System.assertEquals('Primary', updatedParticipant.ARC_Relationship__c);
    }
}