public class ARC_TestUtility {
    //Method to generate a fake ID
    static Integer s_num = 1;
    public static String getFakeId(Schema.SObjectType sot){
        String result = String.valueOf(s_num++);
        return sot.getDescribe().getKeyPrefix() + 
            '0'.repeat(12-result.length()) + result;
    }
    //method to create censusmember
    public static List<vlocity_ins__GroupCensusMember__c> createTestCensusMember(Integer numCensusMember) {

        List<vlocity_ins__GroupCensusMember__c> censusMember = new List<vlocity_ins__GroupCensusMember__c>();
        Account acc = new Account(Name = 'Test');
        insert acc;
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        insert census;

        for (Integer i=0;i<numCensusMember;i++) {
            vlocity_ins__GroupCensusMember__c c = new vlocity_ins__GroupCensusMember__c();
            c.Name = 'Test Census Member ' + i;
            c.vlocity_ins__FirstName__c = 'Test';
            c.vlocity_ins__LastName__c = 'Census Member ' + i;
            c.vlocity_ins__CensusId__c = census.Id;
            censusMember.add(c);
        }

        try {
            insert censusMember;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestCensusMember() ' + e.getMessage());
        }

        return censusMember;
    }
// Method to create Test Accounts
    public static List<Account> createTestAccount(Integer numAccts, String recordTypeDevName) {

        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
        List<Account> accts = new List<Account>();

        for (Integer i=0;i<numAccts;i++) {
            Account a = new Account();
            if(recordTypeDevName == 'ARC_IFPPersonAccount') {
                a.Firstname = 'TestFirstName';
                a.Lastname = 'TestLastName ' + i;
            }else a.Name = 'Test Account ' + i;
            a.RecordTypeId = recordTypeId;
            accts.add(a);
        }

        try {
            insert accts;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestAccount() ' + e.getMessage());
        }

        return accts;
    }
    
    // Method to create Contract Line Items
     public static List<vlocity_ins__ContractLineItem__c> createTestContractLineItem(Integer numCLI) {

        //Id recordTypeId = Schema.SObjectType.vlocity_ins__ContractLineItem__c.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
        List<vlocity_ins__ContractLineItem__c> conlineitems = new List<vlocity_ins__ContractLineItem__c>();
		Account acc= new Account(Name='Test Account');
        insert acc;
        Contract contract = new Contract(Name = 'Test', AccountId= acc.Id);
        insert contract;
        for (Integer i=0;i<numCLI;i++) {
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
            cli.Name = 'Test Plan ' + i;
			cli.vlocity_ins__ContractId__c = contract.Id;


            conlineitems.add(cli);
        }

        try {
            insert conlineitems;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestContractLineItem() ' + e.getMessage());
        }

        return conlineitems;
    }

// Method to create Test Cases
    public static List<Case> createTestCase(Integer numCases, String recordTypeDevName) {

        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
        List<Case> cases = new List<Case>();

        for (Integer i=0;i<numCases;i++) {
            Case c = new Case();
            c.Status = 'New';
            c.Origin = 'Internal Enrollment';
            c.RecordTypeId = recordTypeId;
            c.Subject = 'Test';
            c.Description = 'Test Description';
            cases.add(c);
        }

        insert cases;


        return cases;
    }


// Method to create Test Contacts
    public static List<Contact> createTestContact(Integer numContacts, String recordTypeDevName) {

        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
        List<Contact> contacts = new List<Contact>();

        for (Integer i=0;i<numContacts;i++) {
            Contact c = new Contact();
            c.FirstName = 'Test FirstN ' + i;
            c.LastName = 'Test LastN ' + i;
            c.RecordTypeId = recordTypeId;
            contacts.add(c);
        }

        try {
            insert contacts;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestContact() ' + e.getMessage());
        }

        return contacts;
    }


// Metohd to create Test Emails
public static List<ARC_Email__c> createTestEmail(Integer amountEmails, ARC_EmailCampaign__c campaign){
    List<ARC_Email__c> emails = new List<ARC_Email__c>();
    
    for (Integer i=0;i<amountEmails;i++) {
        ARC_Email__c e = new ARC_Email__c(ARC_To__c = 'To@mail.com', ARC_From__c = 'From@mail.com', 
        ARC_Status__c = 'Pending', ARC_IsAutoSend__c = false, ARC_Subject__c = 'Subject', 
        ARC_Email_Campaign__c = campaign.Id);
        emails.add(e);
    }
    return emails;
}

//Method to create email Campaigns
public static List<ARC_EmailCampaign__c> createTestEmailCampaign(Integer amountCampaigns){
    List<ARC_EmailCampaign__c> campaigns = new List<ARC_EmailCampaign__c>();
  

    for (Integer i=0;i<amountCampaigns;i++) {
        ARC_EmailCampaign__c eCamp = new ARC_EmailCampaign__c(Name = 'Test' + i, ARC_Template__c = 'Template' + i,
        ARC_AutoEmail__c = false, ARC_EmailsSent__c = i );
    campaigns.add(eCamp);
    }
    return campaigns;
}

//Method to create Omniscripts
public static List<vlocity_ins__OmniScript__c> createTestOmniscript(Integer amountOS){
    List<vlocity_ins__OmniScript__c> omniscripts = new List<vlocity_ins__OmniScript__c>();
    String PropertySet = '"LOB":"Test"';
    for (Integer i=0;i<amountOS;i++) {
        vlocity_ins__OmniScript__c os = new vlocity_ins__OmniScript__c(Name = 'TestOS' + i, 
        vlocity_ins__IsActive__c = true, vlocity_ins__PropertySet__c = PropertySet);
        omniscripts.add(os);
    }
    return omniscripts;
}

//Method to create OS Definition
public static List<vlocity_ins__OmniScriptDefinition__c> createTestOmniscriptDefinition(Integer amountOSDef, vlocity_ins__OmniScript__c os){
    List<vlocity_ins__OmniScriptDefinition__c> omniscriptsDef = new List<vlocity_ins__OmniScriptDefinition__c>();

    for (Integer i=0;i<amountOSDef;i++) {
        vlocity_ins__OmniScriptDefinition__c osDef = new vlocity_ins__OmniScriptDefinition__c(Name = 'TestOSDef', 
        vlocity_ins__OmniScriptId__c = os.Id);
        omniscriptsDef.add(osDef);
    }
    return omniscriptsDef;
}

//Method to create StaticResources with name arc_logos and with a zipped file as a body.
public static List<StaticResource> createTestStaticResource(Integer amountSR){
    List<StaticResource> listSR = new List<StaticResource>();
    StaticResource staticRes = [SELECT Body FROM StaticResource WHERE Name = 'arc_logos'];
    
    for (Integer i=0;i<amountSR;i++) {
        StaticResource SR = new StaticResource(Name = 'arc_logos',
        Body = staticRes.Body
        );
        listSR.add(SR);
    }
    return listSR;
}


//Method to create retrieve the metadata
public static List<ARC_Settings__mdt> getAllMetadataSettingsFromOrg() { 
    List<ARC_Settings__mdt> settings = new List<ARC_Settings__mdt>([SELECT QualifiedApiName, MasterLabel, ARC_LongText__c, ARC_Visible__C, ARC_Value__c
                            FROM ARC_Settings__mdt]);
    return settings; 
}

//create test users
    public static List<User> createTestUsers(Integer amountUsers, String profileName){
        Profile p = [SELECT Id FROM Profile WHERE Name=:profileName LIMIT 1]; 
        List<User> testUsers = new List<User>();
        for(Integer i = 0; i < amountUsers; i++ ){
            User u = new User(Alias = 'Alias_' + i , Email= 'user.' + i + '@mail.com', 
            EmailEncodingKey='UTF-8', FirstName='TestUsr', LastName = ''+i, LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/New_York', UserName= 'TestUser-' + i + '@myorg.com', ARC_PortalUsername__c = 'TestUser' + i + '@myorg.com');      
            testUsers.add(u);    
        }
        return testUsers;
    }

    //create test Leads
    public static List<Lead> createTestLeads(Integer amountLeads){
        List<Lead> testLeads = new List<Lead>();
        for(Integer i = 0; i < amountLeads; i++ ){
            Lead lead = new Lead(LastName='Doe', FirstName='TestLead-' + i ,Company='Test');
            testLeads.add(lead);
        }
		return testLeads;   
    }
 // Method to create Benefit cards & ContentVersion
 public static Map<BenefitCard__c, ContentVersion> createTestBenefitCards(Integer recordAmount){
    Map<BenefitCard__c, ContentVersion> benefitCardsAndContentVersion = new Map<BenefitCard__c, ContentVersion>();
    for(Integer i = 0; i < recordAmount; i++ ){
        BenefitCard__c benefitRecord = new BenefitCard__c(ARC_Title__c = 'Benefit Title' + i);
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body to be insert in test class for testing the'+i);
        List<ContentVersion> cvl = createTestContentVersion(1, bodyBlob, 'SampleTitle','H', 'SampleTitle.jpg');
        ContentVersion contentVersion = cvl[0];
        benefitCardsAndcontentVersion.put(benefitRecord, contentVersion);
    }
    return benefitCardsAndcontentVersion;
}

// create test ContentVersion
// public static List<ContentDocument> createTestContentDocument(Integer recordAmount, Blob bodyBlob, String title, String origin, String pathOnClient){
//     List<ContentDocument> ContentDocumentList = new List<ContentDocument>();
//     for(Integer i = 0; i < recordAmount; i++ ){
//         ContentDocument doc = new ContentDocument(
//             ArchivedById= title, 
//             PathOnClient = pathOnClient,
//             VersionData = bodyBlob//, 
//             //Origin = origin
//         );
//         ContentDocumentList.add(doc);
//     }
//     return ContentDocumentList;
// }

// create test ContentVersion
public static List<ContentVersion> createTestContentVersion(Integer recordAmount, Blob bodyBlob, String title, String origin, String pathOnClient){
    List<ContentVersion> ContentVersionList = new List<ContentVersion>();
    for(Integer i = 0; i < recordAmount; i++ ){
        ContentVersion contentVersion = new ContentVersion(
            Title= title, 
            PathOnClient = pathOnClient,
            VersionData = bodyBlob//, 
            //Origin = origin
        );
        ContentVersionList.add(contentVersion);
    }
    return ContentVersionList;
}


// create test contentDocumentLinking linking to existing record & ContentVersion
public static List<ContentDocumentLink> createTestContentDocumentLink(Map<SObject, String> mappedRecordWithContentVersionId, String shareType, String visibility ){
    List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
    System.debug('createTestContentDocumentLink');
    System.debug(mappedRecordWithContentVersionId);
    for(SObject record : mappedRecordWithContentVersionId.keySet() ){
        System.debug(record);
        System.debug(mappedRecordWithContentVersionId.get(record));
        ContentDocumentLink cdl = new ContentDocumentLink( 
            ContentDocumentId = mappedRecordWithContentVersionId.get(record), 
            LinkedEntityId =  record.Id,
            ShareType = shareType,
            Visibility = visibility
        );
        contentDocumentLinks.add(cdl);    
    }
    System.debug(contentDocumentLinks);
    return contentDocumentLinks;
}

// crate test HealthPrograms
    public static List<ARC_HealthProgram__c> createTestHealthProgram(Integer recordAmount, String Name, Boolean isActive,String programList){
        List<ARC_HealthProgram__c> healthProgramsList = new List<ARC_HealthProgram__c>();
        for(Integer i = 0; i < recordAmount; i++ ){
            ARC_HealthProgram__c healthProgram = new ARC_HealthProgram__c();
            healthProgram.Name = Name;
            healthProgram.ARC_Active__c = isActive;
            healthProgram.ARC_ProgramsList__c = programList;
            healthProgramsList.add(healthProgram);
        }
        System.debug('createTestHealthProgram');
        System.debug(healthProgramsList);
        return healthProgramsList;
    }

    // create test HealthSpecs
    public static List<ARC_HealthProgramSpec__c> createTestHealthProgramSpecs(List<ARC_HealthProgram__c> healthPrograms){
        List<ARC_HealthProgramSpec__c> healthProgramsSpecs = new List<ARC_HealthProgramSpec__c>();
        for(ARC_HealthProgram__c hp: healthPrograms){
            ARC_HealthProgramSpec__c hps = new ARC_HealthProgramSpec__c();
            hps.ARC_Description__c = 'HealthProgramSpec Description';
            hps.ARC_HealthProgram__c = hp.Id;
            healthProgramsSpecs.add(hps);
        }
        return healthProgramsSpecs;
    }

    // Create Campaigns

    public static ARC_EmailCampaign__c createTestCampaigns(String template, String obj, String toField, String ccFIeld, String ruleCamp, String operation) {

            ARC_EmailCampaign__c newCamp = new ARC_EmailCampaign__c();
            newCamp.Name = 'Test';
            newCamp.ARC_Template__c = template;
            newCamp.ARC_Object__c = obj;
            newCamp.ARC_To__c = toField;
        	newCamp.ARC_CC__c = ccFIeld;
            newCamp.ARC_Active__c = true;
            // newCamp.ARC_AutoEmail__c = true;
            newCamp.ARC_Rules__c = ruleCamp;
            newCamp.ARC_OperationsMulti__c = operation;
           
        return newCamp;
    }
    
    //Create test Accounts for campaigns

    public static List<Account> createTestAccountForCampaigns(String accName, String email) {

        List<Account> accList = new List<Account>();
        Account acc1 = new Account(Name = accName, vlocity_ins__Email__c = email);
        Account acc2 = new Account(Name = accName);
        accList.add(acc1);
        accList.add(acc2);
        return accList;
    }

    // Create test Quote for campaigns

    public static Quote createTestQuoteForCampaigns(String quoName) {
    
        Account acc = new Account(Name = 'test', vlocity_ins__Email__c = 'acctest@gmail.com');
        insert acc;
        Opportunity opp = new Opportunity(AccountId = acc.Id, Name = acc.Name, closedate = system.today(),stagename='Prospecting');
        insert opp;
        // List<Quote> quoteList = new List<Quote>();
        // for (Integer i = 0; i < amountQuotes; i++) {
            Quote newQuote = new Quote();
            newQuote.Name = quoName;
            newQuote.Email = 'test@gmail.com';
            newQuote.OpportunityId = opp.Id;
            // quoteList.add(newQuote);
        // }
        return newQuote;
    }

   // Create Email templates

    public static EmailTemplate createEmailTemplate(List<Account> accounts) {
        Account account = accounts[0];
        EmailTemplate emailTemp = new EmailTemplate();
        emailTemp.Name = 'Test template';
        emailTemp.Subject = 'Test subject';
        emailTemp.HtmlValue = 'Hello {!account.Name}, ';
        emailTemp.DeveloperName = 'Test_template';
        emailTemp.TemplateType = 'custom';
        return emailTemp;
    }

    //Create Contracts

    public static List<Contract> createContracts(Integer amount) {
        Account acc = new Account(Name = 'testAccount');
        insert acc;
        List<Contract> listContract = new List<Contract>();
        for (Integer i=0;i<amount;i++) {
            Contract con = new Contract();
            con.AccountId = acc.Id;
            con.ContractTerm = 12;
            con.ARC_Selling_Agent__c = UserInfo.getUserId();
            con.StartDate = Date.valueOf('2021-11-12');
            listContract.add(con);
        }
        return listContract;
    }
    
    public static List<Contract> createContractsUniqueAccounts(Integer amount) {
        List<Account> accounts = new List<Account>();
        for (Integer i=0;i<amount;i++) {
            Account acc = new Account(Name = 'testAccount'+string.valueOf(i));
            accounts.add(acc);
        }
        insert accounts;
        
        List<Contract> listContract = new List<Contract>();
        for (Integer i=0;i<amount;i++) {
            Contract con = new Contract();
            con.AccountId = accounts[i].Id;
            con.ContractTerm = 12;
            con.ARC_Selling_Agent__c = UserInfo.getUserId();
            con.StartDate = Date.valueOf('2021-11-12');
            listContract.add(con);
        }
        return listContract;
    }

    //Create Contract in Awaiting Activarion
    
    public static List<Contract> createContractsAA(Integer amount) {

        Account acc = new Account(Name = 'testAccount');
        insert acc;
        List<Contract> listContract = new List<Contract>();
        List<ChargentOrders__ChargentOrder__c> recurringOrders =  createChargentOrders(amount);
        insert recurringOrders;
        for (Integer i=0;i<amount;i++) {
            Contract con = new Contract();
            con.ContractTerm = 12;
            con.ARC_Selling_Agent__c = UserInfo.getUserId();
            con.AccountId = acc.Id;
            con.StartDate = Date.valueOf('2021-11-12');
            con.ARC_RecurringMonthlyOrder__c = recurringOrders.get(i).Id;
            listContract.add(con);
        }
        return listContract;
    }

    //Create Emails

    public static List<ARC_Email__c> createEmails(ARC_EmailCampaign__c campaign, String objectId) {
        List<ARC_Email__c> emailsList = new List<ARC_Email__c>();
        ARC_Email__c emailRecord = new ARC_Email__c();
        // emailRecord.ARC_IsAutoSend__c = true;
        emailRecord.ARC_EmailReciever__c = 'test@gmail.com;acctest@gmail.com';
        emailRecord.ARC_EmailCC__c = 'testCC@gmail.com';
        emailRecord.ARC_Subject__c = 'test subject';
        emailRecord.ARC_Status__c = 'Pending';
        emailRecord.ARC_Email_Campaign__c = campaign.Id;
        emailRecord.ARC_ObjectId__c = objectId;
        emailsList.add(emailRecord);
        return emailsList;
    }

       
    
        //CreateSavedOsFromObject
        public static List<vlocity_ins__OmniScriptInstance__c> createSavedOsFromObject(sObject[] objects,Integer numSavedOs) {
            List<vlocity_ins__OmniScriptInstance__c> savedOs = new List<vlocity_ins__OmniScriptInstance__c>();
            
            vlocity_ins__OmniScript__c omni = new vlocity_ins__OmniScript__c(vlocity_ins__Type__c = 'SGQuote',vlocity_ins__SubType__c = 'Quoting',vlocity_ins__Language__c = 'English');
            insert omni;
            for (sObject obj :objects) {
                // For each sObject, add savedOmniscript
                for (Integer k=0;k<numSavedOs;k++) {
                    savedOs.add(new vlocity_ins__OmniScriptInstance__c(vlocity_ins__ObjectId__c = obj.Id, vlocity_ins__OmniScriptId__c  = omni.Id, vlocity_ins__ObjectLabel__c = 'Contract'));
                
                }
            }
            insert savedOs;
            
            return savedOs;
        }

        //Create Account with Opportunities
    public static List<Account> createAccountsWithOpps(Integer numAccts, Integer numOppsPerAcct) {
        List<Account> accts = new List<Account>();
        for(Integer i=0;i<numAccts;i++) {
            Account a = new Account(Name='TestAccount' + i);
            accts.add(a);
        }

        insert accts;
        
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer j=0;j<numAccts;j++) {
            Account acct = accts[j];
            // For each account just inserted, add opportunities
            for (Integer k=0;k<numOppsPerAcct;k++) {
                opps.add(new Opportunity(Name=acct.Name + ' Opportunity ' + k,
                                       StageName='Prospecting',
                                       CloseDate=System.today().addMonths(1),
                                       AccountId=acct.Id));
            }
        }
        // Insert all opportunities for all accounts.
        insert opps;
        
        return accts;
    }
    
    // method to create a new claim
    public static List<Claim> createTestClaims(Integer numClaim) {
        List<Claim> claims = new List<Claim>();

        for (Integer i=0;i<numClaim;i++) {
            Claim c = new Claim();            
            c.Name = 'Test Claim ' + i;
            claims.add(c);
        }

        try {
            insert claims;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestClaims() ' + e.getMessage());
        }
        return claims;
    }

    public static List<InsurancePolicy> createTestPolicies(Integer numPolicies, String recordTypeDevName) {
        Id recordTypeId = Schema.SObjectType.InsurancePolicy.getRecordTypeInfosByDeveloperName().get(recordTypeDevName).getRecordTypeId();
        List<InsurancePolicy> policies = new List<InsurancePolicy>();
        Account acc = new Account();
        acc.Name = 'Test Claim';
        insert acc;

        for (Integer i=0;i<numPolicies;i++) {
            InsurancePolicy p = new InsurancePolicy();
            p.Name = 'Test Policy ' + i;
            p.NameInsuredId = acc.Id;
            p.RecordTypeId = recordTypeId;
            policies.add(p);
        }

        try {
            insert policies;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestPolicies() ' + e.getMessage());
        }
        return policies;
    }

    public static List<vlocity_ins_fsc__InsurancePolicyTerm__c> createTestPolicyTerm(Integer terms) {
        List<vlocity_ins_fsc__InsurancePolicyTerm__c> polTerms = new List<vlocity_ins_fsc__InsurancePolicyTerm__c>();
        
        for (Integer i=0;i<terms;i++) {
            vlocity_ins_fsc__InsurancePolicyTerm__c p = new vlocity_ins_fsc__InsurancePolicyTerm__c();
            p.Name = 'Test Policy Term' + i;
            polTerms.add(p);
        }

        try {
            insert polTerms;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestPolicyTerm() ' + e.getMessage());
        }
        return polTerms;
    }

    public static List<vlocity_ins__GroupCensus__c> createTestCensus(Integer numCensus) {

        List<vlocity_ins__GroupCensus__c> census = new List<vlocity_ins__GroupCensus__c>();
        Account acc = new Account(Name = 'Test');
        insert acc;

        for (Integer i=0;i<numCensus;i++) {
            vlocity_ins__GroupCensus__c c = new vlocity_ins__GroupCensus__c();
            c.Name = 'Test Census ' + i;
            c.vlocity_ins__GroupId__c = acc.Id;
            census.add(c);
        }

        try {
            insert census;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestCensus() ' + e.getMessage());
        }

        return census;
    }


    public static List<vlocity_ins__GroupCensusMemberPlan__c> createTestCensusMemPlan(Integer numCensusPlan) {

        List<vlocity_ins__GroupCensusMemberPlan__c> plan = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        Account acc = new Account(Name = 'Test');
        insert acc;
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        insert census;
        vlocity_ins__GroupCensusMember__c cenMem = new vlocity_ins__GroupCensusMember__c();
        cenMem.Name = 'Test Census Member ';
        cenMem.vlocity_ins__CensusId__c = census.Id;
        insert cenMem;

        for (Integer i=0;i<numCensusPlan;i++) {
            vlocity_ins__GroupCensusMemberPlan__c c = new vlocity_ins__GroupCensusMemberPlan__c();
            c.Name = 'Test Plan ' + i;
            c.vlocity_ins__GroupCensusMemberId__c = cenMem.Id;
            plan.add(c);
        }

        try {
            insert plan;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestCensusMemPlan() ' + e.getMessage());
        }

        return plan;
    }

    public static List<ARC_UnderwritingCaseMember__c> createTestUndCaseMember(Integer numUndCase) {

        //Create Member
        List<vlocity_ins__InsuranceClaim__c> claims = new List<vlocity_ins__InsuranceClaim__c>();
        Account acc = new Account(Name = 'Test');
        insert acc;
        vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
        census.Name = 'census test';
        census.vlocity_ins__GroupId__c = acc.Id;
        insert census;
        vlocity_ins__GroupCensusMember__c censusMem = new vlocity_ins__GroupCensusMember__c();
        censusMem.Name = 'Test Census Member';
        censusMem.vlocity_ins__CensusId__c = census.Id;
        insert censusMem;

        //Create Case
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Admission').getRecordTypeId();
        Case newCase = new Case(recordTypeId = recordTypeId, Description = 'Test Case', Subject = 'Test Case');
        insert newCase;

        List<ARC_UnderwritingCaseMember__c> underCases = new List<ARC_UnderwritingCaseMember__c>();
        for (Integer i=0;i<numUndCase;i++) {
            ARC_UnderwritingCaseMember__c c = new ARC_UnderwritingCaseMember__c();
            c.Name = 'Test Underwriting Case Item ' + i;
            c.ARC_Member__c = censusMem.Id;
            c.ARC_UnderwritingCase__c = newCase.Id;
            underCases.add(c);
        }

        try {
            insert underCases;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestUndCaseMember() ' + e.getMessage());
        }

        return underCases;
    }

    public static List<ClaimCoveragePaymentDetail> createTestCoveragePayments(Integer numCovPayments) {

        List<ClaimCoveragePaymentDetail> covPaymentItem = new List<ClaimCoveragePaymentDetail>();
        ClaimCoverage c = ARC_TestUtility.createTestClaimCoverage(1)[0];

        for (Integer i=0;i<numCovPayments;i++) {
            ClaimCoveragePaymentDetail cc = new ClaimCoveragePaymentDetail();
            cc.Name = 'Test Claim Item ' + i;
            cc.ClaimCoverageId = c.Id;
            cc.ARC_Claim__c = c.ClaimId;
            covPaymentItem.add(cc);
        }

        try {
            insert covPaymentItem;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestCoveragePayments() ' + e.getMessage());
        }

        return covPaymentItem;
    }

    public static List<ClaimCoverage> createTestClaimCoverage(Integer numClaimCov) {

        List<ClaimCoverage> claimCoverList = new List<ClaimCoverage>();
        Claim claimParent = ARC_TestUtility.createTestClaims(1)[0];

        for (Integer i=0;i<numClaimCov;i++) {
            ClaimCoverage cc = new ClaimCoverage();
            cc.Name = 'Test Claim Coverage' + i;
            cc.ClaimId = claimParent.Id;
            cc.InternalReserveMode = 'CoverageReserve';
            claimCoverList.add(cc);
        }

        try {
            insert claimCoverList;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestClaimCoverage() ' + e.getMessage());
        }

        return claimCoverList;
    }

    public static List<InsurancePolicyParticipant> createTestPolicyParticipant(Integer numPart) {

        List<InsurancePolicyParticipant> polPartList = new List<InsurancePolicyParticipant>();

        for (Integer i=0;i<numPart;i++) {
            InsurancePolicyParticipant pp = new InsurancePolicyParticipant();
            pp.Role = 'Primary';
            polPartList.add(pp);
        }

        // DO NOT INSERT
        // try {
        //     insert polPartList;
        // } catch (Exception e) {
        //     System.debug('Error in ARC_TestUtility.createTestPolicyParticipant() ' + e.getMessage());
        // }

        return polPartList;
    }

    public static List<Product2> createTestProducts(Integer numProd) {

        List<Product2> prodList = new List<Product2>();

        for (Integer i=0;i<numProd;i++) {
            Product2 p = new Product2();
            p.Name = 'Test Product UHSM' + i;
            prodList.add(p);
        }

        try {
            insert prodList;
        } catch (Exception e) {
            System.debug('Error in ARC_TestUtility.createTestProducts() ' + e.getMessage());
        }

        return prodList;
    }

    public static List<vlocity_ins__Attribute__c> createTestAttributes(Integer numAtt) {
        List<vlocity_ins__Attribute__c> attList = new List<vlocity_ins__Attribute__c>();

        vlocity_ins__AttributeCategory__c attCat = new vlocity_ins__AttributeCategory__c();
        attCat.Name = 'WESHR_POWATT';
        attCat.vlocity_ins__Code__c = 'WESHR_POWATT';
        attCat.vlocity_ins__DisplayFilter__c = false;
        attCat.vlocity_ins__DisplaySequence__c = 1122;
        attCat.vlocity_ins__IsActive__c = true;
        attCat.vlocity_ins__IsPrivate__c = false;
        attCat.vlocity_ins__IsUserAttributesCreatedPrivate__c = false;
        attCat.vlocity_ins__LockedFlg__c = false;
        insert attCat;

        for (Integer i=0;i<numAtt;i++) {
            vlocity_ins__Attribute__c att = new vlocity_ins__Attribute__c();
            att.Name = 'TEST';
            att.vlocity_ins__AttributeCategoryId__c = attCat.Id;
            att.vlocity_ins__DisplaySequence__c = numAtt;
            att.vlocity_ins__ActiveFlg__c = true;
            att.vlocity_ins__Configurable__c = true;
            att.vlocity_ins__ExcludeFromBasketCache__c = false;
            att.vlocity_ins__Filterable__c = true;
            att.vlocity_ins__IsCloneable__c = true;
            att.vlocity_ins__isDefaultHidden__c = false;
            att.vlocity_ins__IsEncrypted__c = false;
            att.vlocity_ins__IsNotAssetizable__c = false;
            att.vlocity_ins__IsPrivate__c = false;
            attList.add(att);
        }

        return attList;
    }

    public static List<ChargentOrders__Transaction__c> createChargentTransactions(Integer quant){
        List<ChargentOrders__Transaction__c> transList = new List<ChargentOrders__Transaction__c>();
        
        ChargentOrders__ChargentOrder__c ord = new ChargentOrders__ChargentOrder__c();
        ord.ARC_FirstMonthPayed__c = true;
        ord.ChargentOrders__Description__c = 'Recurring Monthly Order';
        ord.ChargentOrders__Charge_Amount__c = 10;
        insert ord;

        for (Integer i = 0; i < quant; i++) {
            ChargentOrders__Transaction__c t = new ChargentOrders__Transaction__c();
            t.ChargentOrders__Order__c = ord.Id;
            t.ChargentOrders__Amount__c = 10;
            transList.add(t);
        }

        return transList;
    }

    public static ChargentOrders__Transaction__c createOneTransaction (Double tAmount, String tType, Id chargentId){
        ChargentOrders__Transaction__c t = new ChargentOrders__Transaction__c();
        t.ChargentOrders__Order__c = chargentId;
        t.ChargentOrders__Amount__c = tAmount;
        t.ChargentOrders__Response_Status__c ='Approved';
        t.ChargentOrders__Type__c =tType;
        t.ARC_Reason__c = 'Test';
        return t;
    }

    public static List<ChargentOrders__ChargentOrder__c> createChargentOrders(Integer quant){
        List<ChargentOrders__ChargentOrder__c> ordList = new List<ChargentOrders__ChargentOrder__c>();
        
        for (Integer i = 0; i < quant; i++) {
            ChargentOrders__ChargentOrder__c ord = new ChargentOrders__ChargentOrder__c();
            ord.ARC_FirstMonthPayed__c = true;
            ord.ChargentOrders__Description__c = 'Recurring Monthly Order';
            ord.ChargentOrders__Charge_Amount__c = 10;
            ordList.add(ord);
        }

        return ordList;
    }

    // public static List<ARC_Commission__c> createCommissions(Integer quant){
    //     List<ARC_Commission__c> commList = new List<ARC_Commission__c>();
        
    //     Contract cont = createContracts(1)[0];
    //     vlocity_ins__GroupCensus__c census = createTestCensus(1)[0];
    //     insert cont;

    //     for (Integer i = 0; i < quant; i++) {
    //         ARC_Commission__c c = new ARC_Commission__c();
    //         c.Sale_Commissionable_Total__c = 0;
    //         c.Contract__c = cont.Id;
    //         c.Census__c = census.Id;
    //         c.ARC_Sale_Count__c = 1;
    //         c.ARC_Agent_Role__c = 'Account Executive';
    //         c.ARC_TransactionTotal__c = 10;
    //         c.Calculated_Commission__c = 10;
    //         c.Sales_Floor_Amount__c = 10;
    //         commList.add(c);
    //     }

    //     return commList;
    // }

    // public static List<ARC_Commission_Payment__c> createCommissionPayments(Integer quant){
    //     List<ARC_Commission_Payment__c> commPayList = new List<ARC_Commission_Payment__c>();
        
    //     for (Integer i = 0; i < quant; i++) {
    //         ARC_Commission_Payment__c c = new ARC_Commission_Payment__c();
    //         c.Amount__c = 10;
    //         c.Type__c = 'Monthly Payout';
    //         commPayList.add(c);
    //     }

    //     return commPayList;
    // }

    public static List<Contract> createCompleteEnrollments(Integer numEnroll) {
        //FamilyAccount creation
        List<Account> listFamAcc = new List<Account>();
        for (Integer i = 0; i < numEnroll; i++) {
            Account acc = new Account(Name = 'FamilyAccount Test '+i);
            listFamAcc.add(acc);
        }
        insert listFamAcc;

        //PersonAccount creation
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ARC_IFPPersonAccount').getRecordTypeId();
        List<Account> listPerAcc = new List<Account>();
        for (Integer i = 0; i < numEnroll; i++) {
            Account accPrimary = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount Primary '+i, LastName ='Test');
            accPrimary.BillingStreet = '123 Avenue';
            accPrimary.BillingState = 'NY';
            accPrimary.BillingCity = 'New York';
            accPrimary.BillingPostalCode='12345';
            accPrimary.PersonEmail='test@email.com';
            accPrimary.ARC_IsPrimaryMember__c = true;
            accPrimary.ARC_E123MemberIdFromPolicy__c = 'W123456789';
            accPrimary.ARC_ContinuousMembershipStartDate__c = Date.Today().addYears(-1);
            accPrimary.IsActive = true;
            accPrimary.ARC_GroupAccount__c = listFamAcc[i].Id;
            Account accSpouse = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount Spouse '+i, LastName ='Test');
            accSpouse.BillingStreet = '123 Avenue';
            accSpouse.BillingState = 'NY';
            accSpouse.BillingCity = 'New York';
            accSpouse.BillingPostalCode='12345';
            accSpouse.PersonEmail='test@email.com';
            accSpouse.ARC_IsPrimaryMember__c = false;
            accSpouse.ARC_E123MemberIdFromPolicy__c = 'W123456789';
            accSpouse.ARC_ContinuousMembershipStartDate__c = Date.Today().addYears(-1);
            accSpouse.IsActive = true;
            accSpouse.ARC_GroupAccount__c = listFamAcc[i].Id;
            accSpouse.ARC_DependentRelationship__c = 'Spouse';
            Account accChild = new Account(RecordTypeId = accRecordTypeId, FirstName = 'PersonAccount Child '+i, LastName ='Test');
            accChild.BillingStreet = '123 Avenue';
            accChild.BillingState = 'NY';
            accChild.BillingCity = 'New York';
            accChild.BillingPostalCode='12345';
            accChild.PersonEmail='test@email.com';
            accChild.ARC_IsPrimaryMember__c = false;
            accChild.ARC_E123MemberIdFromPolicy__c = 'W123456789';
            accChild.ARC_ContinuousMembershipStartDate__c = Date.Today().addYears(-1);
            accChild.IsActive = true;
            accChild.ARC_GroupAccount__c = listFamAcc[i].Id;
            accChild.ARC_DependentRelationship__c = 'Child';
            listPerAcc.add(accPrimary);
            listPerAcc.add(accSpouse);
            listPerAcc.add(accChild);
        }
        insert listPerAcc;

        //CensusMember creation
        List <vlocity_ins__GroupCensusMember__c> groupCensusMemberList = new List<vlocity_ins__GroupCensusMember__c>();
        List <vlocity_ins__GroupCensus__c> groupCensusList = new List<vlocity_ins__GroupCensus__c>();
        for (Integer i = 0; i < numEnroll; i++) {
            vlocity_ins__GroupCensus__c census = new vlocity_ins__GroupCensus__c();
            census.Name = 'census test '+i;
            census.vlocity_ins__GroupId__c = listFamAcc[i].Id;
            groupCensusList.add(census);
        }
        insert groupCensusList;
        List <Account> accountListContactIdsPrimary = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount Primary%' ORDER BY FirstName];
        List <Account> accountListContactIdsSpouse = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount Spouse%' ORDER BY FirstName];
        List <Account> accountListContactIdsChild = [SELECT PersonContactId FROM Account WHERE FirstName Like 'PersonAccount Child%' ORDER BY FirstName];
        for (Integer i = 0; i < numEnroll; i++) {
            vlocity_ins__GroupCensusMember__c censusMemberPrimary = new vlocity_ins__GroupCensusMember__c();
            censusMemberPrimary.Name = 'Test Census Member Primary ' + i;
            censusMemberPrimary.vlocity_ins__FirstName__c = 'Test';
            censusMemberPrimary.vlocity_ins__LastName__c = 'Census Member Primary ' + i;
            censusMemberPrimary.vlocity_ins__CensusId__c = groupCensusList[i].Id;
            censusMemberPrimary.vlocity_ins__ContactId__c = accountListContactIdsPrimary[i].PersonContactId;
            censusMemberPrimary.vlocity_ins__SocialSecurityNumber__c = '123456789';
            censusMemberPrimary.ARC_PhysicalAddressStreet__c = '123 Avenue';
            censusMemberPrimary.ARC_PhysicalAddressCity__c = 'New York';
            censusMemberPrimary.ARC_PhysicalAddressState__c = 'NY';
            censusMemberPrimary.ARC_PhysicalAddressZipCode__c = '12345';
            vlocity_ins__GroupCensusMember__c censusMemberSpouse = new vlocity_ins__GroupCensusMember__c();
            censusMemberSpouse.Name = 'Test Census Member Spouse ' + i;
            censusMemberSpouse.vlocity_ins__FirstName__c = 'Test';
            censusMemberSpouse.vlocity_ins__LastName__c = 'Census Member Spouse ' + i;
            censusMemberSpouse.vlocity_ins__CensusId__c = groupCensusList[i].Id;
            censusMemberSpouse.vlocity_ins__ContactId__c = accountListContactIdsSpouse[i].PersonContactId;
            censusMemberSpouse.vlocity_ins__SocialSecurityNumber__c = '123456789';
            censusMemberSpouse.ARC_PhysicalAddressStreet__c = '123 Avenue';
            censusMemberSpouse.ARC_PhysicalAddressCity__c = 'New York';
            censusMemberSpouse.ARC_PhysicalAddressState__c = 'NY';
            censusMemberSpouse.ARC_PhysicalAddressZipCode__c = '12345';
            vlocity_ins__GroupCensusMember__c censusMemberChild = new vlocity_ins__GroupCensusMember__c();
            censusMemberChild.Name = 'Test Census Member Child ' + i;
            censusMemberChild.vlocity_ins__FirstName__c = 'Test';
            censusMemberChild.vlocity_ins__LastName__c = 'Census Member Child ' + i;
            censusMemberChild.vlocity_ins__CensusId__c = groupCensusList[i].Id;
            censusMemberChild.vlocity_ins__ContactId__c = accountListContactIdsChild[i].PersonContactId;
            censusMemberChild.vlocity_ins__SocialSecurityNumber__c = '123456789';
            censusMemberChild.ARC_PhysicalAddressStreet__c = '123 Avenue';
            censusMemberChild.ARC_PhysicalAddressCity__c = 'New York';
            censusMemberChild.ARC_PhysicalAddressState__c = 'NY';
            censusMemberChild.ARC_PhysicalAddressZipCode__c = '12345';
            groupCensusMemberList.add(censusMemberPrimary);
            groupCensusMemberList.add(censusMemberSpouse);
            groupCensusMemberList.add(censusMemberChild);
        }
        insert groupCensusMemberList;
        
        //Link PersonAccounts to CensusMember
        for (Integer i = 0; i < numEnroll; i++) {
            //Primary
            listPerAcc[3*i].Census_Member__c = groupCensusMemberList[3*i].Id;
            listPerAcc[3*i].ARC_CensusMember__pc = groupCensusMemberList[3*i].Id;
            listPerAcc[3*i].ARC_Census__c = groupCensusMemberList[3*i].vlocity_ins__CensusId__c;
            //Spouse
            listPerAcc[3*i+1].Census_Member__c = groupCensusMemberList[3*i+1].Id;
            listPerAcc[3*i+1].ARC_CensusMember__pc = groupCensusMemberList[3*i+1].Id;
            listPerAcc[3*i+1].ARC_Census__c = groupCensusMemberList[3*i+1].vlocity_ins__CensusId__c;
            listPerAcc[3*i+1].ARC_PrimaryMemberAccount__c = listPerAcc[3*i].Id;
            //Child
            listPerAcc[3*i+2].Census_Member__c = groupCensusMemberList[3*i+2].Id;
            listPerAcc[3*i+2].ARC_CensusMember__pc = groupCensusMemberList[3*i+2].Id;
            listPerAcc[3*i+2].ARC_Census__c = groupCensusMemberList[3*i+2].vlocity_ins__CensusId__c;
            listPerAcc[3*i+2].ARC_PrimaryMemberAccount__c = listPerAcc[3*i].Id;
        }
        update listPerAcc;

        //ChargentOrder creation
        List<ChargentOrders__ChargentOrder__c> ordList = new List<ChargentOrders__ChargentOrder__c>();
        for (Integer i = 0; i < numEnroll; i++) {
            ChargentOrders__ChargentOrder__c ord = new ChargentOrders__ChargentOrder__c();
            ord.ARC_FirstMonthPayed__c = true;
            ord.ChargentOrders__Description__c = 'Recurring Monthly Order';
            ord.ChargentOrders__Charge_Amount__c = 10;
            ordList.add(ord);
        }
        insert ordList;

        //Contracts creation
        List<Contract> contractList = new List<Contract>();
        for (Integer i = 0; i < numEnroll; i++) {
            Contract con = new Contract();
            con.ContractTerm = 12;
            con.ARC_Selling_Agent__c = UserInfo.getUserId();
            con.AccountId = listFamAcc[i].Id;
            con.StartDate = Date.today();
            con.ARC_RecurringMonthlyOrder__c = ordList[i].Id;
            con.vlocity_ins__EnrollmentCensusId__c = groupCensusList[i].Id;
            contractList.add(con);
        }
        insert contractList;

        //ContractParticipant creation
        List<ARC_ContractParticipant__c> contractParticipantList = new List<ARC_ContractParticipant__c>();
        for (Integer i = 0; i < numEnroll; i++) {
            ARC_ContractParticipant__c contractParticipantPrimary = new ARC_ContractParticipant__c();
            contractParticipantPrimary.ARC_Contract__c = contractList[i].Id;
            contractParticipantPrimary.ARC_Relationship__c = 'Primary';
            contractParticipantPrimary.ARC_PersonAccount__c = listPerAcc[3*i].Id;
            ARC_ContractParticipant__c contractParticipantSpouse = new ARC_ContractParticipant__c();
            contractParticipantSpouse.ARC_Contract__c = contractList[i].Id;
            contractParticipantSpouse.ARC_Relationship__c = 'Spouse';
            contractParticipantSpouse.ARC_PersonAccount__c = listPerAcc[3*i+1].Id;
            ARC_ContractParticipant__c contractParticipantChild = new ARC_ContractParticipant__c();
            contractParticipantChild.ARC_Contract__c = contractList[i].Id;
            contractParticipantChild.ARC_Relationship__c = 'Child';
            contractParticipantChild.ARC_PersonAccount__c = listPerAcc[3*i+2].Id;
            contractParticipantList.add(contractParticipantPrimary);
            contractParticipantList.add(contractParticipantSpouse);
            contractParticipantList.add(contractParticipantChild);
        }
        insert contractParticipantList;

        //Product creation
        List<Product2> prodList = new List<Product2>();
        for (Integer i = 0; i < numEnroll; i++) {
            Product2 prod = new Product2();
            prod.Name = 'Test Product UHSM' + i;
            prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
            prod.vlocity_ins__RatingProcedureType__c = 'Calculation Procedure';
            prod.vlocity_ins__RatingCalcProcedureName__c = 'ARC_UHSMCalculationProcedure_Individual';
            prod.vlocity_ins__PricingFormula__c = 'Price';
            prod.vlocity_ins__Type__c = 'Medical';
            prod.vlocity_ins__AttributeDefaultValues__c = '{"AMCS":"1k/2k","MedicalMaxShareLimits":"No lifetime or annual share maximums, except where explicitly noted","OutOfNetworkServices":"Only in the case of an emergency or when pre-authorized","PharmacyMemberCareShare":250,"PharmacyShareMaximum":3500,"familyAMCS":2000,"individualAMCS":1000}';
            prodList.add(prod);
        }
        insert prodList;

        //ContractLineItems creation
        List<vlocity_ins__ContractLineItem__c> cliList = new List<vlocity_ins__ContractLineItem__c>();
        for (Integer i = 0; i < numEnroll; i++) {
            vlocity_ins__ContractLineItem__c cli = new vlocity_ins__ContractLineItem__c();
            cli.Name = 'WeShare test';
            cli.ARC_SmokerFee__c = 100;
            cli.ARC_ExtraDependentFee__c = 200;
            cli.ARC_OriginalPrice__c = 1000;
            cli.vlocity_ins__UnitPrice__c = 1000;
            cli.vlocity_ins__EffectiveStartDate__c = ((Date)contractList[i].StartDate).addDays(15);
            cli.vlocity_ins__ContractId__c = contractList[i].Id;
            cli.vlocity_ins__Product2Id__c = prodList[i].Id;
            cliList.add(cli);
        }
        insert cliList;
        
        //GroupCensusMemberPlan creation
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList = new List<vlocity_ins__GroupCensusMemberPlan__c>();
        for (Integer i = 0; i < numEnroll; i++) {
            vlocity_ins__GroupCensusMemberPlan__c gcmpPrimary = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmpPrimary.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmpPrimary.vlocity_ins__GroupCensusMemberId__c = groupCensusMemberList[3*i].Id;
            vlocity_ins__GroupCensusMemberPlan__c gcmpSpouse = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmpSpouse.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmpSpouse.vlocity_ins__GroupCensusMemberId__c = groupCensusMemberList[3*i].Id;
            vlocity_ins__GroupCensusMemberPlan__c gcmpChild = new vlocity_ins__GroupCensusMemberPlan__c();
            gcmpChild.vlocity_ins__ContractLineId__c = cliList[i].Id;
            gcmpChild.vlocity_ins__GroupCensusMemberId__c = groupCensusMemberList[3*i].Id;
            gcmpList.add(gcmpPrimary);
            gcmpList.add(gcmpSpouse);
            gcmpList.add(gcmpChild);
        }
        insert gcmpList;

        return contractList;
    }

    public static List<ARC_ClaimInput__c> createClaimInputs(Integer quant){
        List<ARC_ClaimInput__c> cInputList = new List<ARC_ClaimInput__c>();
        
        for (Integer i = 0; i < quant; i++) {
            ARC_ClaimInput__c c = new ARC_ClaimInput__c();
            c.ARC_ExternalId__c = 'TestData' + i;
            c.ARC_Status__c = 'New';
            cInputList.add(c);
        }

        return cInputList;
    }
}