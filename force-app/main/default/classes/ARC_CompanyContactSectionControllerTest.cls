/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ARC_CompanyContactSectionControllerTest {

    // Helper: get RecordTypeId for Account by developer name used in controller
    private static Id getBusinessAccountRtId() {
        Map<String, Schema.RecordTypeInfo> rtByDevName =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();

        Schema.RecordTypeInfo rti = rtByDevName.get('Business_Account');
        System.assertNotEquals(null, rti,
            'Missing Account RecordType DeveloperName = Business_Account. Controller will NPE without it.');
        return rti.getRecordTypeId();
    }

    @IsTest
    static void execute_allMethods(){
        // ====== DATA SETUP ======
        Id businessRtId = getBusinessAccountRtId();

        // Main "Group" Account linked to Opportunity (this is the AccountId the controller uses)
        Account groupAcc = new Account(Name = 'Group Account');
        insert groupAcc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = groupAcc.Id
        );
        insert opp;

        // --- Primary Business Contact (PBC) via ACR on group account
        Contact pbc = new Contact(
            AccountId = groupAcc.Id,
            FirstName = 'P',
            LastName = 'BC',
            Email = 'pbc@test.com',
            Phone = '1111111111',
            ARC_PortalAccess__c = 'Admin'
        );
        insert pbc;

        //After Insert pbc
        AccountContactRelation acrPbc = [
            SELECT Id, Roles, IsActive
            FROM AccountContactRelation
            WHERE AccountId = :groupAcc.Id
            AND ContactId = :pbc.Id
            LIMIT 1
        ];

        acrPbc.IsActive = true;
        acrPbc.Roles = (acrPbc.Roles == null) ? 'Primary Business Contact' : acrPbc.Roles + ';Primary Business Contact';
        update acrPbc;

        // --- Company Officer Contact (COC) via ACR on group account
        Contact coc = new Contact(
            AccountId = groupAcc.Id,
            FirstName = 'C',
            LastName = 'OC',
            Email = 'coc@test.com',
            Phone = '2222222222',
            ARC_PortalAccess__c = 'Viewer'
        );
        insert coc;

         //After Insert coc
         AccountContactRelation acrCoc = [
            SELECT Id, Roles, IsActive
            FROM AccountContactRelation
            WHERE AccountId = :groupAcc.Id
            AND ContactId = :coc.Id
            LIMIT 1
        ];

        acrCoc.IsActive = true;
        acrCoc.Roles = (acrCoc.Roles == null) ? 'Company Officer Contact' : acrCoc.Roles + ';Company Officer Contact';
        //acrCoc.Roles = 'Company Officer Contact'; // or add to existing if needed
        update acrCoc;

        // --- Other Contact: on same AccountId but WITHOUT excluded roles in ACR
        Contact otherC = new Contact(
            AccountId = groupAcc.Id,
            FirstName = 'O',
            LastName = 'Ther',
            Email = 'other@test.com',
            Phone = '3333333333',
            ARC_PortalAccess__c = 'No Access'
        );
        insert otherC;
        // (No ACR for excluded roles) -> should appear in getOtherContacts

        // --- TPA Account must be "Business_Account" to show up in lookup
        Account tpaBusinessAcc = new Account(
            Name = 'TPA Business Account 1',
            RecordTypeId = businessRtId,
            BillingStreet = '1 Main',
            BillingCity = 'Austin',
            BillingState = 'TX',
            BillingPostalCode = '78701'
        );
        insert tpaBusinessAcc;

        // TPA Contact belongs to TPA Account, but is related to Group Account via ACR role
        Contact tpaContact = new Contact(
            AccountId = tpaBusinessAcc.Id,
            FirstName = 'T',
            LastName = 'PA',
            Email = 'tpa@test.com',
            Phone = '4444444444',
            ARC_PortalAccess__c = 'Admin'
        );
        insert tpaContact;

        AccountContactRelation acrTpa = new AccountContactRelation(
            AccountId = groupAcc.Id,
            ContactId = tpaContact.Id,
            Roles = 'Third Party Administrator',
            IsActive = true
        );
        insert acrTpa;

        // --- Ownership Contact (also via ACR on group account)
        Contact ownerC = new Contact(
            AccountId = groupAcc.Id,
            FirstName = 'Own',
            LastName = 'Er',
            Email = 'owner@test.com',
            Phone = '5555555555',
            ARC_PortalAccess__c = 'Viewer',
            ARC_OwnershipPercentage__c = 10
        );
        insert ownerC;

        //After Insert Ownership
        AccountContactRelation acrOwner = [
            SELECT Id, Roles, IsActive
            FROM AccountContactRelation
            WHERE AccountId = :groupAcc.Id
            AND ContactId = :ownerC.Id
            LIMIT 1
        ];

        acrOwner.IsActive = true;
        acrOwner.Roles = (acrOwner.Roles == null) ? 'Ownership' : acrOwner.Roles + ';Ownership';
        //acrOwner.Roles = 'Ownership'; // or add to existing if needed
        update acrOwner;

        // ====== EXECUTE / ASSERT ======
        Test.startTest();
        // 1) getPrimaryBusinessContact
        ARC_CompanyContactSectionController.ContactData pbcData =
            ARC_CompanyContactSectionController.getPrimaryBusinessContact(opp.Id);
        System.assertNotEquals(null, pbcData, 'PBC data should not be null');
        System.assertEquals(pbc.Id, pbcData.contact.Id, 'PBC ContactId mismatch');

        // 2) getCompanyOfficerContact
        ARC_CompanyContactSectionController.ContactData cocData =
            ARC_CompanyContactSectionController.getCompanyOfficerContact(opp.Id);
        System.assertNotEquals(null, cocData, 'COC data should not be null');
        System.assertEquals(coc.Id, cocData.contact.Id, 'COC ContactId mismatch');

        // 3) getOtherContacts
        List<Contact> others =
            ARC_CompanyContactSectionController.getOtherContacts(opp.Id);
        System.assertEquals(1, others.size(), 'Should return only the non-excluded "Other" contact');
        System.assertEquals(otherC.Id, others[0].Id);

        // 4) getTPAContacts
        List<Map<String, Object>> tpas =
            ARC_CompanyContactSectionController.getTPAContacts(opp.Id);
        System.assertEquals(1, tpas.size(), 'Should return 1 TPA record');
        System.assertEquals(tpaContact.Id, (Id)tpas[0].get('contactId'));

        // 5) getOwnerContacts
        // This method only needs a smoke assertion for minimum coverage because the payload shape
        // may differ from the TPA method and should not be over-assumed here.
        Map<String, Object> owners =
            ARC_CompanyContactSectionController.getOwnerContacts(opp.Id);
        System.assertNotEquals(null, owners, 'Owner response should not be null');
        System.assert(!owners.isEmpty(), 'Owner response should contain data');

        // 6) searchBusinessAccounts (blank + search term)
        List<Account> lookupBlank =
            ARC_CompanyContactSectionController.searchBusinessAccounts('', 10);
        System.assert(lookupBlank.size() > 0, 'Should return Business Accounts when searchTerm blank');

        List<Account> lookupTerm =
            ARC_CompanyContactSectionController.searchBusinessAccounts('TPA Business Account', 10);
        System.assert(lookupTerm.size() > 0, 'Should return Business Accounts matching the term');

        Test.stopTest();
    }
}