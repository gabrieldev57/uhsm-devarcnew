public with sharing class ARC_memberHeaderComponentController {

    private static final String ACCOUNT_PHONE_FIELD = 'Phone';
    private static final String ACCOUNT_EMAIL_FIELD = 'PersonEmail';
    private static final String ACCOUNT_DOB_FIELD = 'PersonBirthdate';
    private static final String ACCOUNT_GENDER_FIELD = 'PersonGender';

    private static final String MEMBER_OBJECT = 'vlocity_ins__GroupCensusMember__c';
    private static final String MEMBER_RELATIONSHIP_FIELD = 'ARC_Relationship__c';
    private static final String ACCOUNT_IS_ACTIVE_FIELD = 'IsActive';
    private static final String MEMBER_SSN_FIELD = 'vlocity_ins__SocialSecurityNumber__c';
    private static final String ACCOUNT_MEMBER_ID_FIELD = 'Current_Member_Id__c';
    private static final String MEMBER_CONTACT_LOOKUP_FIELD = 'vlocity_ins__ContactId__c';

    public class MemberHeaderDTO {
        @AuraEnabled public Id accountId;
        @AuraEnabled public String fullName;
        @AuraEnabled public String initials;
        @AuraEnabled public String relationship;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String accountTypeLabel;
        @AuraEnabled public String memberId;
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
        @AuraEnabled public String address;
        @AuraEnabled public String dateOfBirth;
        @AuraEnabled public Integer age;
        @AuraEnabled public String gender;
        @AuraEnabled public String maskedSsn;
        @AuraEnabled public Boolean hasSsn;
    }

    @AuraEnabled(cacheable=true)
    public static MemberHeaderDTO getMemberHeader(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account Id is required.');
        }

        SObject accountRecord = queryAccount(accountId);
        Id personContactId = (Id) accountRecord.get('PersonContactId');
        SObject censusMember = queryGroupCensusMember(personContactId);

        MemberHeaderDTO dto = new MemberHeaderDTO();
        dto.accountId = (Id) accountRecord.get('Id');
        dto.fullName = (String) accountRecord.get('Name');
        dto.initials = buildInitials(dto.fullName);
        dto.relationship = censusMember != null ? stringValue(censusMember.get(MEMBER_RELATIONSHIP_FIELD)) : null;
        dto.isActive = accountFieldMapBoolean(accountRecord, ACCOUNT_IS_ACTIVE_FIELD);
        dto.status = dto.isActive ? 'Active' : 'Inactive';
        dto.accountTypeLabel = 'Person Account';
        dto.memberId = stringValue(accountRecord.get(ACCOUNT_MEMBER_ID_FIELD));
        dto.phone = stringValue(accountRecord.get(ACCOUNT_PHONE_FIELD));
        dto.email = stringValue(accountRecord.get(ACCOUNT_EMAIL_FIELD));
        dto.address = buildAddress(accountRecord);
        dto.dateOfBirth = formatDate((Date) accountRecord.get(ACCOUNT_DOB_FIELD));
        dto.age = calculateAge((Date) accountRecord.get(ACCOUNT_DOB_FIELD));
        dto.gender = stringValue(accountRecord.get(ACCOUNT_GENDER_FIELD));

        String ssn = censusMember != null ? stringValue(censusMember.get(MEMBER_SSN_FIELD)) : null;
        dto.maskedSsn = maskSsn(ssn);
        dto.hasSsn = !String.isBlank(ssn);

        if (String.isBlank(dto.relationship)) {
            dto.relationship = 'Primary';
        }

        if (String.isBlank(dto.status)) {
            dto.status = 'Inactive';
        }

        return dto;
    }

    private static Boolean accountFieldMapBoolean(SObject record, String fieldApiName) {
    if (record == null || String.isBlank(fieldApiName)) {
        return false;
    }

    Object value = record.get(fieldApiName);
    if (value == null) {
        return false;
    }

    if (value instanceof Boolean) {
        return (Boolean) value;
    }

    return String.valueOf(value).toLowerCase() == 'true';
}

    @AuraEnabled
    public static String revealSsn(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account Id is required.');
        }

        SObject accountRecord = queryAccount(accountId);
        Id personContactId = (Id) accountRecord.get('PersonContactId');
        SObject censusMember = queryGroupCensusMember(personContactId);

        if (censusMember == null) {
            return null;
        }

        return stringValue(censusMember.get(MEMBER_SSN_FIELD));
    }

    private static SObject queryAccount(Id accountId) {
        List<String> fieldsToQuery = new List<String>{
            'Id',
            'Name',
            'PersonContactId',
            'Phone',
            'PersonEmail',
            'PersonBirthdate',
            'PersonMailingStreet',
            'PersonMailingCity',
            'PersonMailingState',
            'PersonMailingPostalCode',
            'PersonMailingCountry'
        };

        Map<String, Schema.SObjectField> accountFieldMap = Account.SObjectType.getDescribe().fields.getMap();
        if (accountFieldMap.containsKey(ACCOUNT_GENDER_FIELD)) {
            fieldsToQuery.add(ACCOUNT_GENDER_FIELD);
        }

        if (accountFieldMap.containsKey(ACCOUNT_IS_ACTIVE_FIELD)) {
            fieldsToQuery.add(ACCOUNT_IS_ACTIVE_FIELD);
        }

        if (accountFieldMap.containsKey(ACCOUNT_MEMBER_ID_FIELD)) {
            fieldsToQuery.add(ACCOUNT_MEMBER_ID_FIELD);
        }   

        String soql =
            'SELECT ' + String.join(fieldsToQuery, ', ') +
            ' FROM Account' +
            ' WHERE Id = :accountId' +
            ' LIMIT 1';

        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) {
            throw new AuraHandledException('Account not found.');
        }

        return rows[0];
    }

    private static SObject queryGroupCensusMember(Id personContactId) {
        if (personContactId == null) {
            return null;
        }

        String soql =
        'SELECT Id, ' +
            MEMBER_RELATIONSHIP_FIELD + ', ' +
            MEMBER_SSN_FIELD +
        ' FROM ' + MEMBER_OBJECT +
        ' WHERE ' + MEMBER_CONTACT_LOOKUP_FIELD + ' = :personContactId' +
        ' ORDER BY CreatedDate DESC' +
        ' LIMIT 1';

        List<SObject> rows = Database.query(soql);
        return rows.isEmpty() ? null : rows[0];
    }

    private static String buildInitials(String fullName) {
        if (String.isBlank(fullName)) {
            return '';
        }

        List<String> parts = fullName.trim().split('\\s+');
        String result = '';

        for (Integer i = 0; i < parts.size() && i < 2; i++) {
            if (!String.isBlank(parts[i])) {
                result += parts[i].substring(0, 1).toUpperCase();
            }
        }

        return result;
    }

    private static String buildAddress(SObject accountRecord) {
        List<String> parts = new List<String>();

        String street = stringValue(accountRecord.get('PersonMailingStreet'));
        String city = stringValue(accountRecord.get('PersonMailingCity'));
        String state = stringValue(accountRecord.get('PersonMailingState'));
        String postalCode = stringValue(accountRecord.get('PersonMailingPostalCode'));
        String country = stringValue(accountRecord.get('PersonMailingCountry'));

        if (!String.isBlank(street)) {
            parts.add(street);
        }

        String cityStatePostal = '';
        if (!String.isBlank(city)) {
            cityStatePostal += city;
        }
        if (!String.isBlank(state)) {
            cityStatePostal += (cityStatePostal == '' ? '' : ', ') + state;
        }
        if (!String.isBlank(postalCode)) {
            cityStatePostal += (cityStatePostal == '' ? '' : ' ') + postalCode;
        }
        if (!String.isBlank(cityStatePostal)) {
            parts.add(cityStatePostal);
        }
        if (!String.isBlank(country)) {
            parts.add(country);
        }

        return parts.isEmpty() ? null : String.join(parts, ', ');
    }

    private static String formatDate(Date value) {
        if (value == null) {
            return null;
        }

        String mm = value.month() < 10 ? '0' + String.valueOf(value.month()) : String.valueOf(value.month());
        String dd = value.day() < 10 ? '0' + String.valueOf(value.day()) : String.valueOf(value.day());
        String yyyy = String.valueOf(value.year());

        return mm + '/' + dd + '/' + yyyy;
    }

    private static Integer calculateAge(Date birthDate) {
        if (birthDate == null) {
            return null;
        }

        Date today = Date.today();
        Integer age = today.year() - birthDate.year();

        if (today.month() < birthDate.month() ||
            (today.month() == birthDate.month() && today.day() < birthDate.day())) {
            age--;
        }

        return age;
    }

    private static String maskSsn(String ssn) {
        if (String.isBlank(ssn)) {
            return null;
        }

        String clean = ssn.replaceAll('[^0-9]', '');
        if (clean.length() >= 4) {
            return '•••-••-' + clean.right(4);
        }

        return '•••-••-' + clean;
    }

    private static String stringValue(Object value) {
        return value == null ? null : String.valueOf(value);
    }
}