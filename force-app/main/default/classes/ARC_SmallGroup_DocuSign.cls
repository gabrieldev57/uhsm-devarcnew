public with sharing class ARC_SmallGroup_DocuSign {
    public class InputData {
        @InvocableVariable(required=true)
        public Id opportunityId;

        @InvocableVariable(required=false)
        public Id contractId;
    }

    public class OutputData {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;

        @InvocableVariable
        public String errorMessage;

        @InvocableVariable
        public String accountHolderEmail;

        @InvocableVariable
        public String companyOfficerEmail;
    }

    @InvocableMethod(callout=true)
    public static List<OutputData> sendEnvelope(List<InputData> input) {

        // Variables
        List<OutputData> results = new List<OutputData>();
        OutputData output = new OutputData();
        List<Map<String, Object>> docuSignData = new List<Map<String, Object>>();
        Map<String, Object> outputMap = new Map<String, Object>();
        List<Contract> contractsToUpdate = new List<Contract>();
        String templateId = '';

        try {
            // 1. Try to get the templateId
            templateId = getDocuSignTemplateId();

            // 2. Try to get all the DocuSign data
            docuSignData = getDocuSignData(input);

            // 3. Try to send the email
            for (Map<String, Object> data : docuSignData) {
                System.debug('Before sending the DocuSign');
                // Void the Previous DocuSign if necessary
                if ((String)data.get('previousDSNextStep') == 'void') 
                {
                    ARC_DocuSignApi.voidEnvelope((String) data.get('envelopeId'));
                } else if ((String)data.get('previousDSNextStep') == 'cantVoid') {
                    output.message = 'Previous DocuSign can\'t be voided.';
                    output.errorMessage = 'Previous DocuSign can\'t be voided.';
                    System.debug('Message: ' + output.message);
                    System.debug('Error Message: ' + output.errorMessage);
                    break;
                }

                // Send the new DocuSign
                outputMap = sendEnvelopeAsync(data, templateId);
                contractsToUpdate.add((Contract) outputMap.get('contractToUpdate'));

                List<Map<String, Object>> signerList = (List<Map<String, Object>>) data.get('signerList');
                for (Map<String, Object> signer : signerList) {
                    if (signer.get('templateRole').equals('Account Holder')) {
                        output.accountHolderEmail = (String)signer.get('signerEmail');
                    } else if (signer.get('templateRole').equals('Company Officer Contact')) {
                        output.companyOfficerEmail = (String)signer.get('signerEmail');
                    }
                }

                output.success = (Boolean) outputMap.get('success');
                output.message = (String) outputMap.get('message');
                output.errorMessage = (String) outputMap.get('error');
                System.debug('Success: ' + output.success);
                System.debug('Message: ' + output.message);
                System.debug('Error Message: ' + output.errorMessage);
                System.debug('envelopeId: ' + (String)((Map<String, Object>) outputMap.get('DS_SendEnvelope')).get('envelopeId'));
            }
            update contractsToUpdate;

        } catch (Exception e) {
            System.debug('Error message: ' + e.getMessage());
            output.success = false;
            output.errorMessage = e.getMessage();
            System.debug('Output message: ' + output.errorMessage);
        }

        results.add(output);
        return results;
    }

    private static List<Map<String, Object>> getDocuSignData(List<InputData> input) {
        // Variables
        Id opportunityId = input[0].opportunityId;
        List<Map<String, Object>> outputDataList = new List<Map<String, Object>>();
        Map<String, Boolean> checkboxTabs = new Map<String, Boolean>();
        Map<String, String> textTabs = new Map<String, String>();
        List<Map<String, Object>> signerList = new List<Map<String, Object>>();

        // ==================== QUERIES ====================

        // 1. Get Opportunity (includes ContractId)
        Opportunity opp = [SELECT Id,
                                  ContractId,
                                  ARC_OEStartDate__c,
                                  ARC_OEEndDate__c,
                                  AccountId,
                                  Account.Name,
                                  Account.BillingStreet,
                                  Account.BillingCity,
                                  Account.BillingState,
                                  Account.BillingPostalCode,
                                  Account.ARC_GroupNumber__c,
                                  Account.vlocity_ins__Email__c,
                                  Account.ARC_LegalCompanyName__c,
                                  Account.ARC_FederalEmployerTaxIDNumber__c,
                                  Account.ARC_Doing_Business_As_Name__c,
                                  Account.ARC_MemberOfAssociation__c,
                                  Account.ARC_AssociationName__c,
                                  Account.ARC_Entity_Type__c,
                                  Account.ARC_OtherEntityType__c,
                                  Account.ARC_NAICSCode__c,
                                  Account.ARC_TypeOfBusiness__c,
                                  Account.vlocity_ins__DateFounded__c,
                                  Account.ARC_MeetsSmallEmployerDefinition__c,
                                  Account.ARC_TotalEmployees__c,
                                  Account.ARC_AllowDependents__c,
                                  Account.ARC_NumberOfIneligibleEmployees__c,
                                  Account.ARC_NewEmployeeWaitingPeriod__c,
                                  Account.ARC_OfferSharingBenefitsDuringWaitingPer__c,
                                  Account.ARC_EmployeesInOtherStates__c,
                                  Account.ARC_OtherStates__c,
                                  Account.ARC_EmployeesInOtherStatesCount__c,
                                  Account.ARC_SubjectToCalCOBRA__c,
                                  Account.ARC_CalCOBRAEnrolleesCount__c,
                                  Account.ARC_SubjectToCOBRA__c,
                                  Account.ARC_COBRAEnrolleesCount__c,
                                  Account.ARC_MedicalLeaveAllowedMonths__c,
                                  Account.ARC_OfferingOtherCoverage__c,
                                  Account.ARC_OtherCoverageCarrierName__c,
                                  Account.ARC_OtherCoverageRenewalMonth__c,
                                  Account.ARC_OtherCoverageEmployeesCovered__c
                           FROM Opportunity
                           WHERE Id = :opportunityId];

        System.debug('Opportunity = ' + opp);

        // 2. Get Contract directly from Opportunity.ContractId
        Contract contract = [SELECT Id,
                                    AccountId,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Payment_Method__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Type__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Name__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Name__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Routing_Number__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Last_4__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Credit_Card_Name__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Month_Indicator__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Year_Indicator__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Last_4__c,
                                    ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Number__c,
                                    ARC_ContractReason__c,
                                    ARC_EffectiveDate__c,
                                    vlocity_ins__LastDocuSignEnvelopeId__c,
                                    vlocity_ins__LastDocuSignEnvelopeStatus__c
                             FROM Contract
                             WHERE Id = :opp.ContractId];

        System.debug('Contract = ' + contract);

        // 3. Get Account Contact Relationships
        List<AccountContactRelation> accountContactRelationshipList = [
            SELECT Id,
                   Roles,
                   AccountId,
                   Account.Name,
                   ContactId,
                   Contact.FirstName,
                   Contact.LastName,
                   Contact.Name,
                   Contact.Title,
                   Contact.MailingStreet,
                   Contact.MailingCity,
                   Contact.MailingState,
                   Contact.MailingPostalCode,
                   Contact.Phone,
                   Contact.Email,
                   Contact.vlocity_ins__MiddleName__c,
                   Contact.ARC_OwnershipPercentage__c,
                   Contact.ARC_Eligible__c,
                   Contact.Account.Name,
                   Contact.Account.BillingStreet,
                   Contact.Account.BillingCity,
                   Contact.Account.BillingState,
                   Contact.Account.BillingPostalCode
            FROM AccountContactRelation
            WHERE AccountId = :opp.AccountId
            AND Roles INCLUDES ('Account Holder', 'Billing Contact', 'Ownership', 'Third Party Administrator', 'Company Officer Contact', 'Primary Business Contact', 'Other')
        ];

        // 4. Get Contract Line Items
        List<vlocity_ins__ContractLineItem__c> cliList = [
            SELECT vlocity_ins__ProductCode__c,
                   vlocity_ins__ContractId__c
            FROM vlocity_ins__ContractLineItem__c
            WHERE vlocity_ins__ContractId__c = :contract.Id
        ];

        // 5. Get Related Accounts (Affiliated Entities)
        List<Account> relatedAccountsList = [
            SELECT Id,
                   Name,
                   ARC_FederalEmployerTaxIDNumber__c,
                   ARC_Number_Of_Employees__c,
                   ParentId
            FROM Account
            WHERE RecordType.DeveloperName = 'Business_Account'
            AND ParentId = :opp.AccountId
        ];

        // 6. Get Group Class Contributions
        List<vlocity_ins__GroupClassContribution__c> gccList = [
            SELECT Id,
                   vlocity_ins__GroupClassId__r.vlocity_ins__GroupId__c,
                   ARC_EmployeeType__c,
                   ARC_EmployeeTier__c,
                   ARC_EmployeeDivision__c,
                   ARC_ContractLineItem__r.Name,
                   vlocity_ins__ContributionType__c,
                   vlocity_ins__ContributionAmount__c,
                   vlocity_ins__ContributionPercent__c
            FROM vlocity_ins__GroupClassContribution__c
            WHERE vlocity_ins__GroupClassId__r.ARC_Opportunity__c = :opportunityId
        ];

        // ==================== CONTACT MAPS ====================

        Contact contactAccountHolder;
        Contact contactBillingContact;
        Contact contactCompanyOfficer;
        Contact contactPrimaryBusiness;
        Contact contactOther;
        Map<String, Object> contactThirdPartyMap = new Map<String, Object>();
        List<Contact> contactOwnershipList = new List<Contact>();

        for (AccountContactRelation acr : accountContactRelationshipList) {
            if (acr.AccountId != null && acr.ContactId != null) {
                Contact tmpContact = new Contact(
                    Id = acr.ContactId,
                    Title = acr.Contact?.Title,
                    AccountId = acr.AccountId,
                    FirstName = acr.Contact?.FirstName,
                    LastName = acr.Contact?.LastName,
                    MailingStreet = acr.Contact?.MailingStreet,
                    MailingCity = acr.Contact?.MailingCity,
                    MailingState = acr.Contact?.MailingState,
                    MailingPostalCode = acr.Contact?.MailingPostalCode,
                    Phone = acr.Contact?.Phone,
                    Email = acr.Contact?.Email,
                    vlocity_ins__MiddleName__c = acr.Contact?.vlocity_ins__MiddleName__c,
                    ARC_OwnershipPercentage__c = acr.Contact?.ARC_OwnershipPercentage__c,
                    ARC_Eligible__c = acr.Contact?.ARC_Eligible__c
                );

                Account tmpAccount = new Account(
                    Id = acr.AccountId,
                    Name = acr.Contact?.Account?.Name,
                    BillingStreet = acr.Contact?.Account?.BillingStreet,
                    BillingCity = acr.Contact?.Account?.BillingCity,
                    BillingState = acr.Contact?.Account?.BillingState,
                    BillingPostalCode = acr.Contact?.Account?.BillingPostalCode
                );

                if (acr.Roles.contains('Account Holder'))           contactAccountHolder   = tmpContact;
                if (acr.Roles.contains('Billing Contact'))          contactBillingContact  = tmpContact;
                if (acr.Roles.contains('Company Officer Contact'))  contactCompanyOfficer  = tmpContact;
                if (acr.Roles.contains('Primary Business Contact')) contactPrimaryBusiness = tmpContact;
                if (acr.Roles.contains('Other'))                    contactOther           = tmpContact;
                if (acr.Roles.contains('Third Party Administrator')) {
                    contactThirdPartyMap.put('contact', tmpContact);
                    contactThirdPartyMap.put('account', tmpAccount);
                }
                if (acr.Roles.contains('Ownership')) {
                    contactOwnershipList.add(tmpContact);
                }
            }
        }

        // ==================== TABS ====================

        Map<String, Object> docuSignDataMap = new Map<String, Object>();

        // 1. Employer Information
        textTabs.put('TXT_EmployerName', opp.Account?.Name != null ? opp.Account.Name : '');
        textTabs.put('TXT_GroupNumber', opp.Account?.ARC_GroupNumber__c != null ? opp.Account.ARC_GroupNumber__c : '');
        textTabs.put('TXT_EmployerEmailAddress', contactPrimaryBusiness?.Email != null ? contactPrimaryBusiness.Email : '');
        System.debug('Employer Information Executed.');

        // 2. Electronic Funds Transfer (EFT) Authorization Form
        if (contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Payment_Method__c == 'Bank Account') {
            checkboxTabs.put('CHKBOX_InitialContributionCheckingAccount', true);
        } else if (contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Payment_Method__c == 'Credit Card') {
            checkboxTabs.put('CHKBOX_InitialContributionCreditCard', true);
        }
        System.debug('Electronic Funds Transfer (EFT) Authorization Form.');

        // 3. Financial Institution Information
        if (contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Payment_Method__c == 'Bank Account') {
            textTabs.put('TXT_FinancialInstitutionName', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Bank_Name__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Name__c : '');
            textTabs.put('TXT_AccountHolderName', (contactAccountHolder?.FirstName != null ? contactAccountHolder.FirstName : '') + ' ' + contactAccountHolder?.LastName);
            textTabs.put('TXT_AccountHolderStreetAddress', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_Address__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c : '');
            textTabs.put('TXT_City', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_City__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c : '');
            textTabs.put('TXT_State', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_State__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c : '');
            textTabs.put('TXT_ZipCode', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_Zip_Postal__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c : '');
            textTabs.put('TXT_BankRoutingNumber', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Bank_Routing_Number__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Routing_Number__c : '');
            textTabs.put('TXT_BankAccountNumber', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Bank_Account_Number__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Bank_Account_Number__c : '');
        } else if (contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Payment_Method__c == 'Credit Card') {
            textTabs.put('TXT_NameOnCard', (contactAccountHolder?.FirstName != null ? contactAccountHolder.FirstName : '') + ' ' + contactAccountHolder?.LastName);
            textTabs.put('TXT_CardNumber', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Card_Last_4__c != null ? 'XXXX XXXX XXXX ' + contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Last_4__c : '');
            if (contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Card_Month_Indicator__c != null && contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Card_Year_Indicator__c != null) {
                textTabs.put('TXT_ExpirationDate', contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Month_Indicator__c + '/' + contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Year_Indicator__c);
            }
            if (contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_Address__c != null && contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_City__c != null && contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_State__c != null && contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_Zip_Postal__c != null) {
                textTabs.put('TXT_CardBillingAddress', contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c + ', ' + contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c + ', ' + contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c + ', ' + contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c);
            }
            if (contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Type__c == 'Visa') {
                checkboxTabs.put('CHKBOX_CardTypeVisa', true);
            } else if (contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Type__c == 'Mastercard') {
                checkboxTabs.put('CHKBOX_CardTypeMasterCard', true);
            } else if (contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Type__c == 'Discover') {
                checkboxTabs.put('CHKBOX_CardTypeDiscover', true);
            } else if (contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Card_Type__c == 'American Express') {
                checkboxTabs.put('CHKBOX_CardTypeAmex', true);
            }
        }
        System.debug('Financial Institution Information Executed.');

        // 4. Medical - Section A
        if (contract.ARC_ContractReason__c == 'New Enrollment') {
            checkboxTabs.put('CHKBOX_SectionANewEnrollment', true);
        }
        if (contract.ARC_EffectiveDate__c != null) {
            Date effectiveDate = Date.valueOf(contract.ARC_EffectiveDate__c);
            textTabs.put('TXT_SectionARequestedEffectiveDateMonth', String.valueOf(effectiveDate.month()));
            textTabs.put('TXT_SectionARequestedEffectiveDateDay', String.valueOf(effectiveDate.day()));
            textTabs.put('TXT_SectionARequestedEffectiveDateYear', String.valueOf(effectiveDate.year()));
        }
        System.debug('Section A Executed.');

        // Section B
        textTabs.put('TXT_SectionBLegalCompanyName', opp.Account?.ARC_LegalCompanyName__c != null ? opp.Account.ARC_LegalCompanyName__c : '');
        textTabs.put('TXT_SectionBFederalEmployerTaxIdNumber', opp.Account?.ARC_FederalEmployerTaxIDNumber__c != null ? opp.Account.ARC_FederalEmployerTaxIDNumber__c : '');
        textTabs.put('TXT_SectionBDoingBusinessAs', opp.Account?.ARC_Doing_Business_As_Name__c != null ? opp.Account.ARC_Doing_Business_As_Name__c : '');
        textTabs.put('TXT_SectionBCompanyStreetAddress', opp.Account?.BillingStreet != null ? opp.Account.BillingStreet : '');
        textTabs.put('TXT_SectionBCity', opp.Account?.BillingCity != null ? opp.Account.BillingCity : '');
        textTabs.put('TXT_SectionBState', opp.Account?.BillingState != null ? opp.Account.BillingState : '');
        textTabs.put('TXT_SectionBZipCode', opp.Account?.BillingPostalCode != null ? opp.Account.BillingPostalCode : '');

        if (contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_Address__c != null && contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_Address__c != opp.Account.BillingStreet) {
            textTabs.put('TXT_SectionBBillingAddress', contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Address__c);
            textTabs.put('TXT_SectionBBillingCity', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_City__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_City__c : '');
            textTabs.put('TXT_SectionBBillingState', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_State__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_State__c : '');
            textTabs.put('TXT_SectionBBillingZipCode', contract.ARC_RecurringMonthlyOrder__r?.ChargentOrders__Billing_Zip_Postal__c != null ? contract.ARC_RecurringMonthlyOrder__r.ChargentOrders__Billing_Zip_Postal__c : '');
        }
        textTabs.put('TXT_SectionBBillingContactName', (contactBillingContact?.FirstName != null ? contactBillingContact.FirstName : '') + ' ' + contactBillingContact?.LastName);
        textTabs.put('TXT_SectionBPhoneNumber', contactBillingContact?.Phone != null ? contactBillingContact.Phone : '');
        textTabs.put('TXT_SectionBEmail', contactBillingContact?.Email != null ? contactBillingContact.Email : '');

        if (opp.Account?.ARC_MemberOfAssociation__c) {
            checkboxTabs.put('CHKBOX_SectionBMemberOfAnAssociationPlanYes', true);
            textTabs.put('TXT_SectionBAssociationPlanName', opp.Account?.ARC_AssociationName__c != null ? opp.Account.ARC_AssociationName__c : '');
        } else {
            checkboxTabs.put('CHKBOX_SectionBMemberOfAnAssociationPlanNo', true);
        }
        checkboxTabs.put('CHKBOX_SectionBCorporation',    opp.Account?.ARC_Entity_Type__c == 'Corporation' ? true : false);
        checkboxTabs.put('CHKBOX_SectionBLLC',            opp.Account?.ARC_Entity_Type__c == 'LLC' ? true : false);
        checkboxTabs.put('CHKBOX_SectionBOther',          opp.Account?.ARC_Entity_Type__c == 'Other' ? true : false);
        checkboxTabs.put('CHKBOX_SectionBPartnership',    opp.Account?.ARC_Entity_Type__c == 'Partnership' ? true : false);
        checkboxTabs.put('CHKBOX_SectionBLP',             opp.Account?.ARC_Entity_Type__c == 'Limited Partnership' ? true : false);
        checkboxTabs.put('CHKBOX_SectionBProprietorship', opp.Account?.ARC_Entity_Type__c == 'Proprietorship' ? true : false);
        checkboxTabs.put('CHKBOX_SectionBLLP',            opp.Account?.ARC_Entity_Type__c == 'Limited Liability Partnership (LLP)' ? true : false);
        textTabs.put('TXT_SectionBOtherText', opp.Account?.ARC_OtherEntityType__c != null ? opp.Account.ARC_OtherEntityType__c : '');
        textTabs.put('TXT_SectionBNAICSCode', opp.Account?.ARC_NAICSCode__c != null ? opp.Account.ARC_NAICSCode__c : '');
        textTabs.put('TXT_SectionBTypeOfBusiness', opp.Account?.ARC_TypeOfBusiness__c != null ? opp.Account.ARC_TypeOfBusiness__c : '');

        if (opp.Account?.vlocity_ins__DateFounded__c != null) {
            textTabs.put('TXT_SectionBDateBusinessEstablishedMonth', String.valueOf(Date.valueOf(opp.Account.vlocity_ins__DateFounded__c).month()));
            textTabs.put('TXT_SectionBDateBusinessEstablishedDay',   String.valueOf(Date.valueOf(opp.Account.vlocity_ins__DateFounded__c).day()));
            textTabs.put('TXT_SectionBDateBusinessEstablishedYear',  String.valueOf(Date.valueOf(opp.Account.vlocity_ins__DateFounded__c).year()));
        }

        if (contactPrimaryBusiness != null) {
            textTabs.put('TXT_SectionBCompanyHRContactName', (contactPrimaryBusiness.FirstName != null ? contactPrimaryBusiness.FirstName : '') + ' ' + contactPrimaryBusiness.LastName);
            textTabs.put('TXT_SectionBHRTitle',        contactPrimaryBusiness.Title != null ? contactPrimaryBusiness.Title : '');
            textTabs.put('TXT_SectionBHRPhoneNumber',  contactPrimaryBusiness.Phone != null ? contactPrimaryBusiness.Phone : '');
            textTabs.put('TXT_SectionBHREmailAddress', contactPrimaryBusiness.Email != null ? contactPrimaryBusiness.Email : '');
        }

        if (contactOther != null) {
            textTabs.put('TXT_SectionBAdditionalContactName', (contactOther.FirstName != null ? contactOther.FirstName : '') + ' ' + contactOther.LastName);
            textTabs.put('TXT_SectionBAdditionalTitle',        contactOther.Title != null ? contactOther.Title : '');
            textTabs.put('TXT_SectionBAdditionalEmailAddress', contactOther.Email != null ? contactOther.Email : '');
        }

        // Affiliated Entities
        if (!relatedAccountsList.isEmpty()) {
            checkboxTabs.put('CHKBOX_SectionBHaveAffiliatedEntities', true);
            for (Account relAcc : relatedAccountsList) {
                Integer idx = relatedAccountsList.indexOf(relAcc) + 1;
                textTabs.put('TXT_SectionBLegalName'          + idx, relAcc.Name != null ? relAcc.Name : '');
                textTabs.put('TXT_SectionBFederalTaxIdNumber' + idx, relAcc.ARC_FederalEmployerTaxIDNumber__c != null ? relAcc.ARC_FederalEmployerTaxIDNumber__c : '');
                textTabs.put('TXT_SectionBNumberOfEmployees'  + idx, relAcc.ARC_Number_Of_Employees__c != null ? String.valueOf(relAcc.ARC_Number_Of_Employees__c) : '');
            }
        } else {
            checkboxTabs.put('CHKBOX_SectionBDontHaveAffiliatedEntities', true);
        }
        System.debug('Section B Executed.');

        // Section C - Ownership
        for (Integer i = 0; i < 5 && i < contactOwnershipList.size(); i++) {
            textTabs.put('TXT_SectionCLastName'  + (i + 1), contactOwnershipList[i].LastName != null ? contactOwnershipList[i].LastName : '');
            textTabs.put('TXT_SectionCFirstName' + (i + 1), contactOwnershipList[i].FirstName != null ? contactOwnershipList[i].FirstName : '');
            textTabs.put('TXT_SectionCMI'        + (i + 1), contactOwnershipList[i].vlocity_ins__MiddleName__c != null ? contactOwnershipList[i].vlocity_ins__MiddleName__c : '');
            if (contactOwnershipList[i].ARC_OwnershipPercentage__c != null) {
                textTabs.put('TXT_SectionCPercentOfOwnership' + (i + 1), String.valueOf(contactOwnershipList[i].ARC_OwnershipPercentage__c));
            }
            checkboxTabs.put('CHKBOX_SectionCEligibleYes' + (i + 1), contactOwnershipList[i].ARC_Eligible__c != null ? contactOwnershipList[i].ARC_Eligible__c : false);
            checkboxTabs.put('CHKBOX_SectionCEligibleNo'  + (i + 1), contactOwnershipList[i].ARC_Eligible__c == true ? false : true);
        }
        System.debug('Section C Executed.');

        // Section D - Third Party Administrator
        Contact contactThirdParty = contactThirdPartyMap.containsKey('contact') ? (Contact) contactThirdPartyMap.get('contact') : null;
        Account accountTPA        = contactThirdPartyMap.containsKey('account') ? (Account) contactThirdPartyMap.get('account') : null;
        if (contactThirdParty != null && accountTPA != null) {
            textTabs.put('TXT_SectionDCompanyName',    accountTPA.Name != null ? accountTPA.Name : '');
            textTabs.put('TXT_SectionDMailingAddress', accountTPA.BillingStreet != null ? accountTPA.BillingStreet : '');
            textTabs.put('TXT_SectionDCity',           accountTPA.BillingCity != null ? accountTPA.BillingCity : '');
            textTabs.put('TXT_SectionDState',          accountTPA.BillingState != null ? accountTPA.BillingState : '');
            textTabs.put('TXT_SectionDZipCode',        accountTPA.BillingPostalCode != null ? accountTPA.BillingPostalCode : '');
            textTabs.put('TXT_SectionDContactName',    (contactThirdParty.FirstName != null ? contactThirdParty.FirstName : '') + ' ' + contactThirdParty.LastName);
            textTabs.put('TXT_SectionDPhoneNumber',    contactThirdParty.Phone != null ? contactThirdParty.Phone : '');
            textTabs.put('TXT_SectionDEmailAddress',   contactThirdParty.Email != null ? contactThirdParty.Email : '');
        }
        System.debug('Section D Executed.');

        // Section E - Eligibility
        checkboxTabs.put(opp.Account?.ARC_MeetsSmallEmployerDefinition__c ? 'CHKBOX_SectionESmallEmployerYes' : 'CHKBOX_SectionESmallEmployerNo', true);
        if (opp.Account?.ARC_TotalEmployees__c != null) textTabs.put('TXT_SectionESmallEmployerTotalEmployees', String.valueOf(opp.Account.ARC_TotalEmployees__c));
        checkboxTabs.put(opp.Account?.ARC_AllowDependents__c ? 'CHKBOX_SectionEAllowDependentsToEnrollYes' : 'CHKBOX_SectionEAllowDependentsToEnrollNo', true);
        if (opp.Account?.ARC_NumberOfIneligibleEmployees__c != null) textTabs.put('TXT_SectionENumberOfIneligibleEmployees', String.valueOf(opp.Account.ARC_NumberOfIneligibleEmployees__c));

        if      (opp.Account?.ARC_NewEmployeeWaitingPeriod__c == 'None – effective date of hire')                          checkboxTabs.put('CHKBOX_SectionEWaitingPeriodA', true);
        else if (opp.Account?.ARC_NewEmployeeWaitingPeriod__c == 'First of the month following hire date')                 checkboxTabs.put('CHKBOX_SectionEWaitingPeriodB', true);
        else if (opp.Account?.ARC_NewEmployeeWaitingPeriod__c == 'First of the month following one month from hire date')  checkboxTabs.put('CHKBOX_SectionEWaitingPeriodC', true);
        else if (opp.Account?.ARC_NewEmployeeWaitingPeriod__c == 'First of the month following two months from hire date') checkboxTabs.put('CHKBOX_SectionEWaitingPeriodD', true);

        checkboxTabs.put(opp.Account?.ARC_OfferSharingBenefitsDuringWaitingPer__c ? 'CHKBOX_SectionEOfferSharingBenefitsYes' : 'CHKBOX_SectionEOfferSharingBenefitsNo', true);

        if (opp.Account?.ARC_EmployeesInOtherStates__c) {
            checkboxTabs.put('CHKBOX_SectionEOtherStateEmployeesYes', true);
            textTabs.put('TXT_SectionEEmployeeState', opp.Account?.ARC_OtherStates__c != null ? opp.Account.ARC_OtherStates__c : '');
            if (opp.Account?.ARC_EmployeesInOtherStatesCount__c != null) textTabs.put('TXT_SectionEOtherStateEmployeesNumber', String.valueOf(opp.Account.ARC_EmployeesInOtherStatesCount__c));
        } else {
            checkboxTabs.put('CHKBOX_SectionEOtherStateEmployeesNo', true);
        }
        System.debug('Section E Executed.');

        // Section F - Program Election
        for (vlocity_ins__ContractLineItem__c cli : cliList) {
            if (cli.vlocity_ins__ProductCode__c != null) {
                if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupPremier')) {
                    checkboxTabs.put('CHKBOX_SectionFWeShareGroupPremier', true);
                    if      (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupPremier1k'))  checkboxTabs.put('CHKBOX_SectionF1k1', true);
                    else if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupPremier3k'))  checkboxTabs.put('CHKBOX_SectionF3k1', true);
                    else if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupPremier6k'))  checkboxTabs.put('CHKBOX_SectionF6k1', true);
                    else if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupPremier9k'))  checkboxTabs.put('CHKBOX_SectionF9k1', true);
                    else if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupPremier12k')) checkboxTabs.put('CHKBOX_SectionF12k1', true);
                }
                if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupEnhanced')) {
                    checkboxTabs.put('CHKBOX_SectionFWeShareGroupEnhanced', true);
                    if      (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupEnhanced1k'))  checkboxTabs.put('CHKBOX_SectionF1k2', true);
                    else if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupEnhanced3k'))  checkboxTabs.put('CHKBOX_SectionF3k2', true);
                    else if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupEnhanced6k'))  checkboxTabs.put('CHKBOX_SectionF6k2', true);
                    else if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupEnhanced9k'))  checkboxTabs.put('CHKBOX_SectionF9k2', true);
                    else if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupEnhanced12k')) checkboxTabs.put('CHKBOX_SectionF12k2', true);
                }
                if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupEssential')) {
                    checkboxTabs.put('CHKBOX_SectionFWeShareGroupEssential', true);
                    if      (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupEssential5k'))  checkboxTabs.put('CHKBOX_SectionF5k1', true);
                    else if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupEssential10k')) checkboxTabs.put('CHKBOX_SectionF10k1', true);
                }
                if (cli.vlocity_ins__ProductCode__c.contains('WeShareGroupSenior')) {
                    checkboxTabs.put('CHKBOX_SectionFWeShareGroupSenior', true);
                    checkboxTabs.put('CHKBOX_SectionF500', true);
                }
            }
        }

        if (opp.ARC_OEStartDate__c != null && opp.ARC_OEEndDate__c != null) {
            String oeStart = Date.valueOf(opp.ARC_OEStartDate__c).month() + '/' + Date.valueOf(opp.ARC_OEStartDate__c).day() + '/' + Date.valueOf(opp.ARC_OEStartDate__c).year();
            String oeEnd   = Date.valueOf(opp.ARC_OEEndDate__c).month()   + '/' + Date.valueOf(opp.ARC_OEEndDate__c).day()   + '/' + Date.valueOf(opp.ARC_OEEndDate__c).year();
            textTabs.put('TXT_SectionFOpenEnrollmentPeriod', oeStart + ' - ' + oeEnd);
        }
        System.debug('Section F Executed.');

        // Section G - Medical Contribution Arrangement
        for (Integer i = 0; i < gccList.size(); i++) {
            vlocity_ins__GroupClassContribution__c gcc = gccList[i];
            String contributionType = gcc.vlocity_ins__ContributionType__c != null ? gcc.vlocity_ins__ContributionType__c : '';
            textTabs.put('TXT_SectionGEmployeeType' + (i + 1), gcc.ARC_EmployeeType__c != null ? gcc.ARC_EmployeeType__c : '');
            textTabs.put('TXT_SectionGDivision'     + (i + 1), gcc.ARC_EmployeeDivision__c != null ? gcc.ARC_EmployeeDivision__c : '');
            textTabs.put('TXT_SectionGProgram'      + (i + 1), gcc.ARC_ContractLineItem__r?.Name != null ? gcc.ARC_ContractLineItem__r.Name : '');
            textTabs.put('TXT_SectionGTier'         + (i + 1), gcc.ARC_EmployeeTier__c != null ? gcc.ARC_EmployeeTier__c : '');
            textTabs.put('TXT_SectionGContribution' + (i + 1), contributionType == 'Percent' ? String.valueOf(gcc.vlocity_ins__ContributionPercent__c) + '%' : '');
            textTabs.put('TXT_SectionGAmount'       + (i + 1), contributionType == 'Amount'  ? '$' + String.valueOf(gcc.vlocity_ins__ContributionAmount__c) : '');
        }
        System.debug('Section G Executed.');

        // Section H - Leave of Absence
        if      (opp.Account?.ARC_MedicalLeaveAllowedMonths__c == '')         checkboxTabs.put('CHKBOX_SectionHNone', true);
        else if (opp.Account?.ARC_MedicalLeaveAllowedMonths__c == '1 Month')  checkboxTabs.put('CHKBOX_SectionH1Month', true);
        else if (opp.Account?.ARC_MedicalLeaveAllowedMonths__c == '2 Months') checkboxTabs.put('CHKBOX_SectionH2Months', true);
        else if (opp.Account?.ARC_MedicalLeaveAllowedMonths__c == '3 Months') checkboxTabs.put('CHKBOX_SectionH3Months', true);
        else if (opp.Account?.ARC_MedicalLeaveAllowedMonths__c == '4 Months') checkboxTabs.put('CHKBOX_SectionH4Months', true);
        else if (opp.Account?.ARC_MedicalLeaveAllowedMonths__c == '5 Months') checkboxTabs.put('CHKBOX_SectionH5Months', true);
        else if (opp.Account?.ARC_MedicalLeaveAllowedMonths__c == '6 Months') checkboxTabs.put('CHKBOX_SectionH6Months', true);
        System.debug('Section H Executed.');

        // Section I - Other Coverage
        if (opp.Account?.ARC_OfferingOtherCoverage__c) {
            checkboxTabs.put('CHKBOX_SectionIOfferAnotherSmallGroupYes', true);
            textTabs.put('TXT_SectionINameOfCarrier', opp.Account?.ARC_OtherCoverageCarrierName__c != null ? opp.Account.ARC_OtherCoverageCarrierName__c : '');
            textTabs.put('TXT_SectionIRenewalMonth',  opp.Account?.ARC_OtherCoverageRenewalMonth__c != null ? opp.Account.ARC_OtherCoverageRenewalMonth__c : '');
            if (opp.Account?.ARC_OtherCoverageEmployeesCovered__c != null) textTabs.put('TXT_SectionINumberOfEmployeesCovered', String.valueOf(opp.Account.ARC_OtherCoverageEmployeesCovered__c));
        } else {
            checkboxTabs.put('CHKBOX_SectionIOfferAnotherSmallGroupNo', true);
        }
        System.debug('Section I Executed.');

        // Section L - Company Officer
        textTabs.put('TXT_SectionLTitle', contactCompanyOfficer?.Title != null ? contactCompanyOfficer.Title : '');

        // Signer List
        if (contactAccountHolder != null) {
            signerList.add(new Map<String, Object>{
                'signerName'   => (contactAccountHolder.FirstName != null ? contactAccountHolder.FirstName + ' ' : '') + contactAccountHolder.LastName,
                'signerEmail'  => contactAccountHolder.Email != null ? contactAccountHolder.Email : '',
                'templateRole' => 'Account Holder'
            });
        }
        if (contactCompanyOfficer != null) {
            signerList.add(new Map<String, Object>{
                'signerName'   => (contactCompanyOfficer.FirstName != null ? contactCompanyOfficer.FirstName + ' ' : '') + contactCompanyOfficer.LastName,
                'signerEmail'  => contactCompanyOfficer.Email != null ? contactCompanyOfficer.Email : '',
                'templateRole' => 'Company Officer Contact'
            });
        }
        System.debug('Signer List = ' + signerList);

        // ==================== BUILD OUTPUT ====================
        docuSignDataMap.put('tabs', new Map<String, Object>{
            'checkboxTabs' => checkboxTabs,
            'textTabs'     => textTabs,
            'prefillTabs'  => new Map<String, Object>{ 'textTabs' => textTabs }
        });
        docuSignDataMap.put('signerList', signerList);
        docuSignDataMap.put('contractId', contract.Id);

        if (
            contract.vlocity_ins__LastDocuSignEnvelopeId__c != null &&
            contract.vlocity_ins__LastDocuSignEnvelopeStatus__c == 'Pending' ||
            contract.vlocity_ins__LastDocuSignEnvelopeStatus__c == 'Failed'
        ) {
            docuSignDataMap.put('envelopeId', contract.vlocity_ins__LastDocuSignEnvelopeId__c);
            docuSignDataMap.put('previousDSNextStep', 'void');
        } else if (
            contract.vlocity_ins__LastDocuSignEnvelopeStatus__c == 'Completed' ||
            contract.vlocity_ins__LastDocuSignEnvelopeStatus__c == 'Voided'
        ) {
            docuSignDataMap.put('previousDSNextStep', 'cantVoid');
        }

        outputDataList.add(docuSignDataMap);
        return outputDataList;
    }

    private static String getDocuSignTemplateId() {
        System.debug('Getting DocuSign template ID...');
        String queryStr = 'SELECT ARC_Template_Name__c ';
        queryStr += 'FROM ARC_DocuSignTemplates__c';
        queryStr += ' WHERE ARC_Contract_Reasons__c LIKE \'%New Application%\'';
        queryStr += ' AND ARC_BusinessSegment__c = \'Small Group\'';
        queryStr += ' ORDER BY ARC_Template_Name__c ASC LIMIT 1';

        ARC_DocuSignTemplates__c templateSettings = Database.query(queryStr);
        String templateNameStr = templateSettings.ARC_Template_Name__c;
        System.debug('templateNameStr: ' + templateNameStr);

        vlocity_ins__VlocityDocuSignTemplate__c template = [
            SELECT Id, Name, vlocity_ins__templateidentifier__c
            FROM vlocity_ins__VlocityDocuSignTemplate__c
            WHERE name = :templateNameStr
            ORDER BY LastModifiedDate DESC LIMIT 1
        ];

        System.debug('template: ' + template);
        return template.vlocity_ins__templateidentifier__c;
    }

    private static Map<String, Object> sendEnvelopeAsync(Map<String, Object> inputMap, String templateId) {
        List<Object> signerList = (List<Object>)inputMap.get('signerList');
        Map<String,Object> outputMap = new Map<String,Object>();
        Map<String,Object> options = new Map<String, Object>{
            'docuSignTemplatesGroup' => new List<Object>{
                new Map<String, Object>{
                    'docuSignTemplate' => templateId,
                    'sendJSONPath'     => null,
                    'sendJSONNode'     => null,
                    'includeToSend'    => true,
                    'signerList'       => signerList,
                    'TFDRresp'         => null
                }
            },
            'elementName' => 'DS_SendEnvelope'
        };

        System.debug('TABS: ' + inputMap.get('tabs'));
        vlocity_ins.DefaultDocuSignOmniScriptIntegration docusignIntegration = new vlocity_ins.DefaultDocuSignOmniScriptIntegration();
        docusignIntegration.invokeMethod('sendEnvelope', inputMap, outputMap, options);
        System.debug('DocuSign sendEnvelope result => ' + outputMap);

        if (outputMap.containsKey('DS_SendEnvelope')) {
            Contract contractToUpdate = new Contract();
            contractToUpdate.Id = (Id) inputMap.get('contractId');
            contractToUpdate.vlocity_ins__LastDocuSignEnvelopeId__c     = (String)((Map<String, Object>) outputMap.get('DS_SendEnvelope')).get('envelopeId');
            contractToUpdate.vlocity_ins__LastDocuSignEnvelopeStatus__c = (String)((Map<String, Object>) outputMap.get('DS_SendEnvelope')).get('status') == 'sent' ? 'Pending' : 'Failed';
            outputMap.put('contractToUpdate', contractToUpdate);
        }

        return outputMap;
    }

    public static void createPortalUsers(Map<Id, Contract> sgContractMap) {
        Map<Id, Id> contractIdAccountIdMap = new Map<Id, Id>();
        Map<Id, List<AccountContactRelation>> contractIdACRelationMap = new Map<Id, List<AccountContactRelation>>();
        Map<Id, Contact> contactsMap = new Map<Id, Contact>();
        List<User> associatedUsersList = new List<User>();
        List<AccountContactRelation> accountContactRelationList = new List<AccountContactRelation>();
        Map<String, Id> profileIdsByNameMap = new Map<String, Id>();
        Map<Id, User> contactUserMap = new Map<Id, User>();
        List<User> usersToCreate;

        for (Profile profileTemp : [SELECT Id, Name
                                    FROM Profile
                                    WHERE Name IN ('Employer Admin', 'Employer Viewer')]) {
            profileIdsByNameMap.put(profileTemp.Name, profileTemp.Id);
        }

        for (Contract contractTemp : sgContractMap.values()) {
            contractIdAccountIdMap.put(contractTemp.Id, contractTemp.AccountId);
        }

        accountContactRelationList = [SELECT Id,
                                             AccountId,
                                             ContactId,
                                             Contact.FirstName,
                                             Contact.LastName,
                                             Contact.Email,
                                             Contact.ARC_PortalAccess__c
                                      FROM AccountContactRelation
                                      WHERE AccountId IN :contractIdAccountIdMap.values()
                                      AND Contact.ARC_PortalAccess__c IN ('Viewer', 'Admin')];

        for (Id contractId : contractIdAccountIdMap.keySet()) {
            List<AccountContactRelation> acRelationList = new List<AccountContactRelation>();
            for (AccountContactRelation acTemp : accountContactRelationList) {
                if (acTemp.AccountId == contractIdAccountIdMap.get(contractId)) {
                    Contact contactTemp = new Contact(
                        Id = acTemp.ContactId,
                        FirstName = acTemp.Contact.FirstName,
                        LastName = acTemp.Contact.LastName,
                        Email = acTemp.Contact.Email,
                        ARC_PortalAccess__c = acTemp.Contact.ARC_PortalAccess__c
                    );
                    contactsMap.put(contactTemp.Id, contactTemp);
                    acRelationList.add(acTemp);
                }
            }
            contractIdACRelationMap.put(contractId, acRelationList);
        }

        associatedUsersList = [SELECT Id, ContactId, Contact.ARC_PortalAccess__c
                               FROM User
                               WHERE ContactId IN :contactsMap.keySet()];

        for (User userTemp : associatedUsersList) {
            contactUserMap.put(userTemp.ContactId, userTemp);
        }

        usersToCreate = new List<User>();
        for (Contact contactTemp : contactsMap.values()) {
            if (!contactUserMap.containsKey(contactTemp.Id)) {
                String alias = contactTemp.FirstName != '' ? contactTemp.FirstName.substring(0, 1) : '';
                alias += contactTemp.LastName.length() >= 7 ? contactTemp.LastName.substring(0, 7) : contactTemp.LastName;

                User newUser = new User();
                newUser.ContactId          = contactTemp.Id;
                newUser.ProfileId          = contactTemp.ARC_PortalAccess__c == 'Admin' ? profileIdsByNameMap.get('Employer Admin') : profileIdsByNameMap.get('Employer Viewer');
                newUser.FirstName          = contactTemp.FirstName;
                newUser.LastName           = contactTemp.LastName;
                newUser.Email              = contactTemp.Email;
                newUser.Username           = contactTemp.Email;
                newUser.Alias              = alias;
                newUser.TimeZoneSidKey     = 'America/Los_Angeles';
                newUser.LocaleSidKey       = 'en_US';
                newUser.EmailEncodingKey   = 'UTF-8';
                newUser.LanguageLocaleKey  = 'en_US';

                usersToCreate.add(newUser);
            }
        }

        try {
            System.debug('Users to Create:');
            for (User userTemp : usersToCreate) System.debug(userTemp);
            List<Database.saveResult> dsr = Database.insert(usersToCreate, false);
            System.debug('Users created: ' + dsr);

            List<Id> listIdsAdminUsers = new List<Id>();
            for (User user : usersToCreate) {
                if (user.Id != null && (user.ProfileId == profileIdsByNameMap.get('Employer Admin') || user.ProfileId == profileIdsByNameMap.get('Employer Viewer'))) {
                    listIdsAdminUsers.add(user.Id);
                }
            }
            if (!listIdsAdminUsers.isEmpty()) addToPublicGroup(listIdsAdminUsers);

        } catch (Exception e) {
            System.debug('Error creating Users: ' + e.getMessage());
        }
    }

    public static void updateSmallGroupSignedContract(Map<Id, Contract> sgContractMap) {
        List<Contract> contractsToUpdate = new List<Contract>();

        for (Contract contractTemp : sgContractMap.values()) {
            if (contractTemp.vlocity_ins__LastDocuSignEnvelopeStatus__c == 'Completed') {
                Contract contractToUpdate = new Contract();
                contractToUpdate.Id     = contractTemp.Id;
                contractToUpdate.Status = 'Pending Enrollment';
                contractsToUpdate.add(contractToUpdate);
            }
        }

        try {
            System.debug('Contracts to Update:');
            for (Contract contractTemp : contractsToUpdate) System.debug(contractTemp);
            List<Database.saveResult> results = Database.update(contractsToUpdate, false);
            System.debug('Contracts updated: ' + results);
        } catch (Exception e) {
            System.debug('Error updating Contracts: ' + e.getMessage());
        }
    }

    @future
    private static void addToPublicGroup(List<Id> usersIdToAdd) {
        Group publicGroup = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = 'Employer_Portal_Users' LIMIT 1];

        List<GroupMember> gmToInsert = new List<GroupMember>();
        for (Id userId : usersIdToAdd) {
            gmToInsert.add(new GroupMember(
                GroupId        = publicGroup.Id,
                UserOrGroupId  = userId
            ));
        }
        if (!gmToInsert.isEmpty()) Database.insert(gmToInsert, false);
    }
}