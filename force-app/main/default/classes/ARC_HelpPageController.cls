public without sharing class ARC_HelpPageController {

    public class PicklistOptionDTO {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public PicklistOptionDTO(String l, String v) { label = l; value = v; }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOptionDTO> getEmployeeOptionsByContract(){
        
        User currentUser = [
            SELECT Id, AccountId
            FROM User
            WHERE Id = :UserInfo.getUserId() 
            WITH SECURITY_ENFORCED] ;

        List<Account> employees = [
            SELECT Id, Name
            FROM Account
            WHERE ARC_GroupAccount__c = :currentUser.AccountId
              AND ARC_IsPrimaryMember__c = true
              AND (
                    IsActive = true
                 OR (
                        ARC_CoverageWaived__c = false
                    AND (ARC_TerminationDate__c = null OR ARC_TerminationDate__c >= TODAY)
                 )
              )
            ORDER BY Name ASC
        ];

        List<PicklistOptionDTO> options = new List<PicklistOptionDTO>();
        for (Account employee : employees) {
            options.add(new PicklistOptionDTO(
                employee.Name,
                employee.Id
            ));
        }
        return options;
    }
    
    @AuraEnabled
    public static string createCase(String subject, String description, Id employeeId, String inputType) {
        try {
            User currentUser = [SELECT Id, AccountId,Account.OwnerId,ContactId FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED LIMIT 1];
            RecordType rt = [
                SELECT Id 
                FROM RecordType 
                WHERE SObjectType = 'Case' 
                AND DeveloperName = 'Service' WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if(currentUser.AccountId != null){
                Id caseContactId = (inputType == 'Employee-Specific') ? currentUser.ContactId : null;
                Case newCase = new Case(
                    Subject = subject,
                    Description = description,
                    RecordTypeId = rt.Id,
                    AccountId = currentUser.AccountId,
                    OwnerId = currentUser.Account.OwnerId,
                    ContactId = caseContactId,
                    ARC_PersonAccount__c = employeeId
                );
                System.debug('New Case: ' + newCase);

                // CRUD check
                if (!Schema.sObjectType.Case.isCreateable()) {
                    throw new SecurityException('User does not have permission to create Case');
                }
                
                insert newCase;
                return newCase.Id;
            } else {
                throw new AuraHandledException('Current user is not associated with any Account.');
            }
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String formatHour(String hour24) {
        if (String.isBlank(hour24)) {
            return null;
        }

        Integer hour = Integer.valueOf(hour24);

        Integer hour12 = Math.mod(hour, 12);
        if (hour12 == 0) {
            hour12 = 12;
        }

        String amPm;
        if (hour < 12) {
            amPm = 'AM';
        } else {
            amPm = 'PM';
        }

        return hour12 + ':00 ' + amPm;
    }


    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getManagerInfo() {
        try {
            User currentUser = [
                SELECT AccountId
                FROM User
                WHERE Id = :UserInfo.getUserId()
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (currentUser.AccountId == null) {
                return null;
            }

            // Query Account 
            Account acc = [
                SELECT ARC_AccountManager__c
                FROM Account
                WHERE Id = :currentUser.AccountId
                LIMIT 1
            ];

            if (acc.ARC_AccountManager__c == null) {
                return null;
            }

            // Query the User record directly 
            List<User> managers = [
                SELECT Name, FirstName, Title, Email, Phone, FullPhotoUrl
                FROM User
                WHERE Id = :acc.ARC_AccountManager__c
                LIMIT 1
            ];

            if (managers.isEmpty()) {
                return null;
            }

            User u = managers[0];

            Map<String, Object> result = new Map<String, Object>();
            result.put('Name',         u.Name);
            result.put('FirstName',    u.FirstName);
            result.put('Title',        u.Title);
            result.put('FullPhotoUrl', u.FullPhotoUrl);
            result.put('Email',        u.Email);
            result.put('Phone',        u.Phone);
            result.put('StartDay', '8:00 AM');// Hardcoded for now
            result.put('EndDay',       '5:00 PM');// Hardcoded for now
            return result;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}