public with sharing class aRC_primaryBusinessContactController {

    public class PrimaryBusinessContactDTO {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String name;
        @AuraEnabled public String title;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
        @AuraEnabled public String address;
    }

    @AuraEnabled(cacheable=true)
    public static PrimaryBusinessContactDTO getPrimaryBusinessContact(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        Opportunity opp = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        if (opp.AccountId == null) {
            return null;
        }

        List<AccountContactRelation> relationships = [
            SELECT Id,
                   AccountId,
                   ContactId,
                   Roles,
                   IsActive,
                   CreatedDate,
                   Contact.Id,
                   Contact.Name,
                   Contact.Title,
                   Contact.Phone,
                   Contact.Email,
                   Contact.MailingStreet,
                   Contact.MailingCity,
                   Contact.MailingState,
                   Contact.MailingPostalCode,
                   Contact.MailingCountry
            FROM AccountContactRelation
            WHERE AccountId = :opp.AccountId
              AND ContactId != null
              AND IsActive = true
              AND Roles INCLUDES ('Primary Business Contact')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (relationships.isEmpty()) {
            return null;
        }

        Contact c = relationships[0].Contact;

        PrimaryBusinessContactDTO dto = new PrimaryBusinessContactDTO();
        dto.contactId = c.Id;
        dto.name = c.Name;
        dto.title = c.Title;
        dto.phone = c.Phone;
        dto.email = c.Email;
        dto.address = buildAddress(
            c.MailingStreet,
            c.MailingCity,
            c.MailingState,
            c.MailingPostalCode,
            c.MailingCountry
        );

        return dto;
    }

    private static String buildAddress(
        String street,
        String city,
        String state,
        String postalCode,
        String country
    ) {
        List<String> lines = new List<String>();

        if (String.isNotBlank(street)) {
            lines.add(street);
        }

        List<String> cityStatePostal = new List<String>();

        if (String.isNotBlank(city)) {
            cityStatePostal.add(city);
        }
        if (String.isNotBlank(state)) {
            cityStatePostal.add(state);
        }
        if (String.isNotBlank(postalCode)) {
            cityStatePostal.add(postalCode);
        }

        if (!cityStatePostal.isEmpty()) {
            lines.add(String.join(cityStatePostal, ', '));
        }

        if (String.isNotBlank(country)) {
            lines.add(country);
        }

        return String.join(lines, '\n');
    }
}