/*******************************************************************
 * @ClassName          :   ARC_ScheduleExpiringCreditCards
 * @Description        :   Schedulable and batchable Apex class that manages the automated creation of cases 
 *                        for credit cards expiring within the next 2 months. The class performs two main functions:
 *                        1. Creates cases for expiring credit cards on the 1st of each month
 *                        2. Sends email notifications for cards expiring within the next month every Sunday
 * @Implemented        :   Database.Batchable<sObject> - For processing records in chunks
 *                        Database.Stateful - To maintain state across batch executions
 *                        Database.AllowsCallouts - To enable external system calls
 *                        Schedulable - To enable scheduled execution
 ********************************************************************/
public without sharing class ARC_ScheduleExpiringCreditCards implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts,Schedulable {

    // Class-level constants for configuration and date calculations
    private final List<String> INVALID_CONTRACT_STATUSES = new List<String>{'Draft','Terminated','Voided'};
    private final Date TODAY = Date.today();
    // Determines the current day of week for scheduling purposes
    private final String DAY_OF_WEEK = Datetime.now().format('EEEE');
    // Current day of month for scheduling monthly tasks
    private final Integer DAY_OF_MONTH = TODAY.day();
    // Calculate dates for 2-month and 1-month windows
    private final Date TODAY_PLUS_TWO_MONTHS = Date.today().addMonths(3).toStartofMonth().addDays(-1);
    private final Date TODAY_PLUS_ONE_MONTH = Date.today().addMonths(2).toStartofMonth().addDays(-1);
    // System queue and chargent_order type IDs for case creation
    private final Id PROCESSING_QUEUE_ID = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperNAME = 'ProcessingQueue']?.Id;
    private final Id SERVICE_CASE_RECORDTYPE_ID = [SELECT Id FROM RecordType WHERE DeveloperName = 'Service' AND SObjectType = 'Case' LIMIT 1]?.Id;
    private final Id INTEGRATION_USER = [SELECT Id FROM User WHERE Name = 'Integration User' LIMIT 1]?.Id;

    // Stateful list to maintain cases that need EFT form processing across batch executions
    public List<Id> list_of_cases_to_send_eft_form = new List<Id>();

    /**
     * @description Scheduled execution entry point - triggers the batch process on the first day of month or Sundays
     * @param sc SchedulableContext provided by the Salesforce scheduler
     */
    public void execute(System.SchedulableContext sc){
        if(DAY_OF_MONTH == 1 || DAY_OF_WEEK == 'Sunday' || Test.isRunningTest()){
            Database.executeBatch(new ARC_ScheduleExpiringCreditCards(), 1);
        }
    }

    /**
     * @description Batch start method - queries for credit cards expiring in the next 2 months
     * @param BC BatchableContext provided by the Salesforce batch framework
     * @return Database.QueryLocator containing the records to process
     */
    public Database.QueryLocator start(Database.BatchableContext BC){
        // Query focuses on active recurring credit card orders with expiration dates in the target window
        return Database.getQueryLocator([
            SELECT
                Id,
                Name,
                ChargentOrders__Card_Month_Indicator__c,
                ChargentOrders__Card_Year_Indicator__c,
                Card_Expiration_Date__c,
                ARC_Contract__c,
                ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__c,
                ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c,
                ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.PersonContactId,
                ARC_Contract__r.vlocity_ins__EnrollmentCensusId__r.ARC_PrimaryAccount__r.Census_Member__c,
                ChargentOrders__Card_Last_4__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE
                ChargentOrders__Description__c = 'Recurring Monthly Order'
                AND ChargentOrders__Payment_Status__c = 'Recurring'
                AND ChargentOrders__Payment_Method__c = 'Credit Card'
                AND Card_Expiration_Date__c >=: TODAY AND Card_Expiration_Date__c <=: TODAY_PLUS_TWO_MONTHS
                AND ARC_Contract__r.Status NOT IN :INVALID_CONTRACT_STATUSES
        ]);
    }

    /**
     * @description Batch execute method - processes credit card records in chunks
     * @param BC BatchableContext provided by the Salesforce batch framework
     * @param chargent_order_list List of ChargentOrders__ChargentOrder__c records to process
     */
    public void execute(Database.BatchableContext BC, List<ChargentOrders__ChargentOrder__c> chargent_order_list){
        // Validate required system IDs are available
        if (INTEGRATION_USER == null && PROCESSING_QUEUE_ID == null && SERVICE_CASE_RECORDTYPE_ID == null) return;

        // Collect census IDs for cards expiring within one month
        Set<String> census_ids = new Set<String>();
        Set<Id> contract_ids = new Set<Id>();
        Map<Id,Id> contractid_to_censusid = new Map<Id,Id>();
        Map<Id,ChargentOrders__ChargentOrder__c> contractid_to_chargentorder = new Map<Id,ChargentOrders__ChargentOrder__c>();

        for (ChargentOrders__ChargentOrder__c chargent_order : chargent_order_list) {
            census_ids.add(chargent_order.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c);
            contract_ids.add(chargent_order?.ARC_Contract__r?.Id);
            contractid_to_censusid.put(chargent_order.ARC_Contract__c, chargent_order.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c);
            contractid_to_chargentorder.put(chargent_order.ARC_Contract__c, chargent_order);
        }

        // Query census records with related member and HIPAA authorization information
        Map<Id,vlocity_ins__GroupCensus__c> censusid_to_census_map = new Map<Id,vlocity_ins__GroupCensus__c>([
            SELECT Id,
                (SELECT Id,vlocity_ins__CensusId__c,vlocity_ins__ContactId__r.Email,Member_ID__c,e123_member_id_from_policy__c,vlocity_ins__FirstName__c,ARC_Age__c
                FROM vlocity_ins__Census_Members__r
                WHERE vlocity_ins__IsPrimaryMember__c = true AND ARC_ActiveMember__c = true AND vlocity_ins__ContactId__r.Email != null LIMIT 1),

                (SELECT ARC_ExternalPersonAuthorized__r.Email,ARC_ExternalPersonAuthorized__r.IsPersonAccount
                FROM HipaaAuthorizations__r
                WHERE ARC_ExternalPersonAuthorized__r.Email != null
                ORDER BY ARC_ExternalPersonAuthorized__r.IsPersonAccount DESC LIMIT 1)
            FROM vlocity_ins__GroupCensus__c
            WHERE Id IN: census_ids
        ]);

        // Query existing credit card expiration cases to avoid duplicates
        List<Case> existing_cc_expiration_cases = [
            SELECT Id, ARC_Contract__c, Subject
            FROM Case
            WHERE ARC_Contract__c IN: contract_ids 
            AND Case_Type__c = 'Contribution' 
            AND ARC_Reason__c = 'CC Expiration Date' 
            AND Subject LIKE 'CC expiring%'
            ORDER BY CreatedDate ASC // Most recent cases will be processed last
        ];

        // Create map of contract ID to existing cases for efficient lookup
        Map<Id, Case> contractid_to_case_map = new Map<Id, Case>();
        if (existing_cc_expiration_cases.isEmpty() == false) {
            for (Case c : existing_cc_expiration_cases) {
                contractid_to_case_map.put(c.ARC_Contract__c, c);
            }
        }

        List<Case> cases_for_insert = new List<Case>();
        List<Map<String,Object>> list_of_emails_to_send = new List<Map<String,Object>>();

        // Process case creation on the 1st of each month
        if(DAY_OF_MONTH == 1 || Test.isRunningTest()){

            // Process each credit card order
            for (ChargentOrders__ChargentOrder__c chargent_order : chargent_order_list) {

                // Create new case if no existing case or if expiration date has changed
                if (check_for_existing_case(contractid_to_case_map, chargent_order) == false) {
                    Case caseInfo = new Case();
                    caseInfo.RecordTypeId = SERVICE_CASE_RECORDTYPE_ID;
                    caseInfo.OwnerId = PROCESSING_QUEUE_ID;
                    caseInfo.CreatedById = INTEGRATION_USER;
                    caseInfo.LastModifiedById = INTEGRATION_USER;
                    caseInfo.Status = 'New';
                    caseInfo.Case_Type__c = 'Contribution';
                    caseInfo.ARC_Reason__c = 'CC Expiration Date';
                    caseInfo.Origin = 'System';
                    caseInfo.ARC_Type__c = 'Member';
                    caseInfo.Subject = 'CC expiring ' + chargent_order.ChargentOrders__Card_Month_Indicator__c + '/' + chargent_order.ChargentOrders__Card_Year_Indicator__c;
                    caseInfo.Description = 'CC expiring ' + chargent_order.ChargentOrders__Card_Month_Indicator__c + '/' + chargent_order.ChargentOrders__Card_Year_Indicator__c;
                    caseInfo.ARC_Contract__c = chargent_order.ARC_Contract__r.Id;
                    caseInfo.ARC_PersonAccount__c = chargent_order.ARC_Contract__r?.vlocity_ins__EnrollmentCensusId__r?.ARC_PrimaryAccount__c;
                    caseInfo.ARC_CensusMember__c = chargent_order.ARC_Contract__r?.vlocity_ins__EnrollmentCensusId__r?.ARC_PrimaryAccount__r.Census_Member__c;
                    cases_for_insert.add(caseInfo);
                }
            }

            // Insert new cases and add them to the list for EFT form processing
            if (cases_for_insert.isEmpty() == false) {
                insert cases_for_insert;
                list_of_cases_to_send_eft_form.addAll(new List<Id>(new Map<Id,Case>(cases_for_insert).keySet()));

                for (Case c : cases_for_insert) {
                    vlocity_ins__GroupCensus__c census_data = censusid_to_census_map.get(contractid_to_censusid.get(c.ARC_Contract__c));
                    ChargentOrders__ChargentOrder__c chargent_order = contractid_to_chargentorder.get(c.ARC_Contract__c);
                    Map<String,Object> email = prepare_new_email(census_data, chargent_order, c.Id, true);

                    if(email.get('censusMember')!= null && email.get('chargentOrder')!= null) {
                        list_of_emails_to_send.add(email);
                    }
                }
            }
        }

        // Process email notifications on Sundays
        if(DAY_OF_WEEK == 'Sunday' || Test.isRunningTest()){
            // Prepare email notifications    
            for (ChargentOrders__ChargentOrder__c chargent_order : chargent_order_list) {

                if (chargent_order.Card_Expiration_Date__c >= TODAY && chargent_order.Card_Expiration_Date__c <= TODAY_PLUS_ONE_MONTH) {

                    Id case_id;
                    if (check_for_existing_case(contractid_to_case_map, chargent_order) == true){
                        case_id = contractid_to_case_map.get(chargent_order.ARC_Contract__c).Id;
                    }

                    Map<String,Object> email = prepare_new_email(censusid_to_census_map.get(chargent_order.ARC_Contract__r.vlocity_ins__EnrollmentCensusId__c), chargent_order, case_id, false);

                    if(list_of_emails_to_send.contains(email) == false && email.get('censusMember')!= null && email.get('chargentOrder')!= null) {
                        list_of_emails_to_send.add(email);
                    }

                }
            }
        }

        // Send email notifications
        Map<String, Object> inputMap = new Map<String, Object>{'emails'=> list_of_emails_to_send};

        try {
            ARC_Emails.email_9(inputMap, new Map<String, Object>(), new Map<String, Object>());
        } catch (Exception e) {
            System.debug(e.getMessage());
            ARC_Emails.sendErrorMessage(e.getMessage(), e.getLineNumber(), 'ARC_CardExpirationBatch.email_9',String.valueOf(list_of_emails_to_send));
        }

    }

    /**
     * @description Batch finish method - initiates EFT form processing for new cases
     * @param BC BatchableContext provided by the Salesforce batch framework
     */
    public void finish(Database.BatchableContext BC) {
        // Process EFT forms for newly created cases (limited to 100 callouts per transaction)
        Database.executeBatch(new ARC_DocusignEFTFormCalloutBatch(list_of_cases_to_send_eft_form),50);
    }

    private Map<String,Object> prepare_new_email(vlocity_ins__GroupCensus__c census_data, ChargentOrders__ChargentOrder__c chargent_order, Id case_id, Boolean eft_form_sent){
        // Get primary member and guardian information
        vlocity_ins__GroupCensusMember__c primary_member;
        ARC_HipaaAuthorization__c guardian;

        if (census_data != null) {
            primary_member = census_data.vlocity_ins__Census_Members__r.isEmpty() == false
                ? (vlocity_ins__GroupCensusMember__c) census_data.vlocity_ins__Census_Members__r[0]
                : null;
        
            guardian = census_data.HipaaAuthorizations__r.isEmpty() == false
                ? (ARC_HipaaAuthorization__c) census_data.HipaaAuthorizations__r[0]
                : null;
        }

        // For members under 18, use guardian's email
        if (primary_member != null && primary_member.ARC_Age__c < 18  && guardian != null) {
            primary_member.vlocity_ins__ContactId__r.Email = guardian.ARC_ExternalPersonAuthorized__r.Email;
        }

        // Prepare email data
        Map<String, Object> email = new Map<String,Object>();
        email.put('censusMember', primary_member);
        email.put('chargentOrder', chargent_order);
        email.put('caseId', case_id);
        email.put('eftFormSent', eft_form_sent);
        return email;
    }

    private Boolean check_for_existing_case(Map<Id,Case> contractid_to_case_map, ChargentOrders__ChargentOrder__c chargent_order){
        // Check for existing case and extract expiration date details
        Case existing_case = contractid_to_case_map.containsKey(chargent_order?.ARC_Contract__c) ? contractid_to_case_map.get(chargent_order?.ARC_Contract__c) : null;
        Integer slashIndex = (existing_case != null && existing_case.Subject != null && existing_case.Subject.contains('CC expiring ')) ? existing_case.Subject.substringAfter('CC expiring ').indexOf('/') : -1;

        String case_expiration_month = existing_case <> null ? (existing_case.Subject.substringAfter('CC expiring ')?.substring(0, slashIndex)) : null;
        String case_expiration_year = existing_case <> null ? (existing_case.Subject.substringAfter('CC expiring ')?.substring(slashIndex + 1)) : null;

        return (existing_case != null) && (chargent_order.ChargentOrders__Card_Month_Indicator__c == case_expiration_month && chargent_order.ChargentOrders__Card_Year_Indicator__c == case_expiration_year);
    }
}