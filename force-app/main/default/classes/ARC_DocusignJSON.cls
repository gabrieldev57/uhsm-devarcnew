global without sharing class ARC_DocusignJSON implements vlocity_ins.VlocityOpenInterface {
    public Boolean invokeMethod(String methodName, Map <String, Object> inputMap, Map<String, Object> outputMap, Map <String, Object> options) {
        switch on methodName {
            when 'transformInformationForDocusign'{
                transformInformationForDocusign(inputMap, outputMap);
            }
            when 'transformInformationForDocusignCancellation'{
                transformInformationForDocusignCancellation(inputMap, outputMap);
            }
        }
        return true;
    }

    /*******************************************************************
    * @MethodName         :   transformInformationForDocusign
    * @Description        :   Transform DocuSignData from the omniscript IP_DocuSignData into JSON format valid for the docusign templates
    * @Author             :   Francisco Caliaba
    * @LastModified       :   10-13-2023
    ********************************************************************/
    public static void transformInformationForDocusign(Map <String, Object> inputMap, Map<String, Object> outMap) {
        Map<String, Object> tabs = new Map<String, Object>();
        Map<String, Object> textTabs = new Map<String, Object>();
        Map<String, Object> checkboxTabs = new Map<String, Object>();
        
        Map<String, Object> DocuSignData = ((Map<String, Object>)inputMap.get('DocuSignData'));
        Map<String, Object> Primary = ((Map<String, Object>)DocuSignData.get('Primary'));
        Map<String, Object> Spouse = ((Map<String, Object>)DocuSignData.get('Spouse'));


        Object DependentsObject = DocuSignData.get('Dependents');

        List<Object> Dependents = new List<Object>();
        if (DependentsObject != null) {
            if (DependentsObject instanceof Map<String, Object>) {
                Dependents.add(DependentsObject);

            } else if (DependentsObject instanceof List<Object> && !((List<Object>)DocuSignData.get('Dependents')).isEmpty() && !((List<Object>)DocuSignData.get('Dependents')).contains(null)) {
                Dependents = (List<Object>)DocuSignData.get('Dependents');
            }
        }


        Map<String, Object> MedicalQuestions = (Map<String, Object>)DocuSignData.get('MedicalQuestions');
        Map<String, Object> Payment = ((Map<String, Object>)DocuSignData.get('Payment'));
        Map<String, Object> Plan = ((Map<String, Object>)DocuSignData.get('Plan'));
        Map<String, Object> Info = ((Map<String, Object>)DocuSignData.get('Info'));
        List<Object> Hipaas = DocuSignData.get('hipaas') != null ? (List<Object>)DocuSignData.get('hipaas') : new List<Object>();
        Map<String, Object> AuthorizedPrimary = ((Map<String, Object>)DocuSignData.get('authorizedPrimary'));

        //Loop Primary Object keys
        for (String key : Primary.keySet()) {
            Object value = Primary.get(key);
            if (key == 'isSmoker' || key == 'Pregnant') continue;
            if (value == true || value == false) {
                checkboxTabs.put('Primary.' + key, value);
            } else {
                textTabs.put('Primary.' + key, value);
            }
        }

        //Loop Spouse Object keys
        if (Spouse != null) {
            for (String key : Spouse.keySet()) {
                Object value = Spouse.get(key);
                if (key == 'isSmoker' || key == 'Pregnant') continue;
    
                if (value == true || value == false) {
                    checkboxTabs.put('Spouse.' + key, value);
                } else {
                    textTabs.put('Spouse.' + key, value);
                }
            }
        }

        //Loop Dependents Objects and then Loop again for each key
        if (Dependents != null) {
            for (Integer i = 0; i < Dependents.size(); i++) {
                Map<String, Object> Dependent = (Map<String, Object>)Dependents[i];
                Integer n = i + 1;

                for (String key : Dependent.keySet()) {
                    Object value = Dependent.get(key);
                    if (key == 'isSmoker' || key == 'Pregnant') continue;

                    if (value == true || value == false) {
                        checkboxTabs.put('Dependent' + n + '.' + String.valueOf(key),value);
                    } else {
                        textTabs.put('Dependent' + n + '.' + String.valueOf(key),value);
                    }
                }


                checkboxTabs.put('Dependent' + n + '.' + String.valueOf(Dependent.get('Gender')), true);
                textTabs.put('Dependent' + n + '.DOB2', String.valueOf(Dependent.get('DOB')));

                if (Dependent.get('isSmoker') == true) {
                    checkboxTabs.put('Dependent' + n + '.Smoker', true);
                } else {
                    checkboxTabs.put('Dependent' + n + '.NotSmoker', true);
                }

                if (Dependent.get('Pregnant') == true) {
                    checkboxTabs.put('Dependent' + n + '.Pregnant', true);
                } else {
                    checkboxTabs.put('Dependent' + n + '.NotPregnant', true);
                }
            }
        }

        if (MedicalQuestions != null) {
            //Loop Medical Notes
            for (String key : MedicalQuestions.keySet()) {
                Map<String, Object> MedicalQuestion = (Map<String, Object>)MedicalQuestions.get(key);

                for (String question : MedicalQuestion.keySet()) {
                    Object answer = (Object)MedicalQuestion.get(question);

                    if (answer == true || answer == false) {
                        checkboxTabs.put(question, answer);
                    } else {
                        textTabs.put(question, answer);
                    }
                }
            }
        }

        //Loop Payment Info
        if (Payment != null) {
            for (String key : Payment.keySet()) {
                String value = String.valueOf(Payment.get(key));
                if (key == 'CardType' || key == 'FirstName' || key == 'LastName' || key == 'PaymentMethod' || key == 'BankAccountType') continue;
                textTabs.put('Payment.' + key, value);
            }
        }

        if (Plan != null) {
            for (String key : Plan.keySet()) {
                String value = String.valueOf(Plan.get(key));
                textTabs.put('Plan.' + key, value);
            }
        }

        if (Info != null) {
            for (String key : Info.keySet()) {
                String value = String.valueOf(Info.get(key));
                textTabs.put('Info.' + key, value);
            }
        }

        if (AuthorizedPrimary != null) {
            if (((String)AuthorizedPrimary.get('TXT_RelationshipPrimary')) == 'Guardian') {
                textTabs.put('Guardian.FirstName', AuthorizedPrimary.get('TXT_FirstNamePrimary'));
                textTabs.put('Guardian.LastName', AuthorizedPrimary.get('TXT_LastNamePrimary'));
                // textTabs.put('Guardian.MI',);
                textTabs.put('Guardian.Email', AuthorizedPrimary.get('TXT_EmailAddressPrimary'));
                textTabs.put('Guardian.Address', AuthorizedPrimary.get('TXT_AddressPrimary'));
                textTabs.put('Guardian.SSN', AuthorizedPrimary.get('TXT_SSN'));
                checkboxTabs.put('Guardian.'+ AuthorizedPrimary.get('TXT_Gender'), true);
                textTabs.put('Guardian.State', AuthorizedPrimary.get('SEL_StatePrimary'));
                textTabs.put('Guardian.City', AuthorizedPrimary.get('TXT_CityPrimary'));
                textTabs.put('Guardian.Phone', AuthorizedPrimary.get('TXT_TelephonePrimary'));
                textTabs.put('Guardian.ZipCode', AuthorizedPrimary.get('TXT_ZipCodePrimary'));
                textTabs.put('Guardian.DOB', AuthorizedPrimary.get('DAT_DOBPrimary'));  
                textTabs.put('Guardian.DOB2', AuthorizedPrimary.get('DAT_DOBPrimary'));  
                textTabs.put('Guardian.GuardianRelationshipToChild', AuthorizedPrimary.get('TXT_GuardianRelationshipToChild'));  
            }
        }

        if (Hipaas != null && Hipaas.size() > 0) {
            for (Integer i = 0; i < Hipaas.size(); i++) {
                if (Hipaas[i] != '' && Hipaas[i] != null) {
                    Map<String, Object> h = (Map<String, Object>)Hipaas[i];
                    System.debug(h);
                    if (h.containsKey('TXT_FullNamePrimary')) {
                        textTabs.put('Hipaa' + (i + 1), String.valueOf(h.get('TXT_FullNamePrimary')));
                    } else if (h.isEmpty() == false) {
                        textTabs.put('Hipaa' + (i + 1), String.valueOf(h.get('TXT_FullName')));
                    }
                } 
            }
        }

        //Formulas and Other Generic info
        if (Primary != null) {
            checkboxTabs.put('Primary.' + String.valueOf(Primary.get('Gender')), Primary.get('Gender') != null ? true : false);
            checkboxTabs.put('Primary.Smoker', Primary.get('isSmoker') != null && Primary.get('isSmoker') == true ? true : false);
            checkboxTabs.put('Primary.NotSmoker', Primary.get('isSmoker') == null || Primary.get('isSmoker') != true ? true : false);
            checkboxTabs.put('Primary.Pregnant', Primary.get('Pregnant') != null && Primary.get('Pregnant') == true ? true : false);
            checkboxTabs.put('Primary.NotPregnant', Primary.get('Pregnant') == null || Primary.get('Pregnant') != true ? true : false);
            textTabs.put('Primary.DOB2', Primary.get('DOB'));
        }

        //
        if (Spouse != null) {
            checkboxTabs.put('Spouse.' + String.valueOf(Spouse.get('Gender')), Spouse.get('Gender') != null ? true : false);
            checkboxTabs.put('Spouse.Smoker', Spouse.get('isSmoker') != null && Spouse.get('isSmoker') == true ? true : false);
            checkboxTabs.put('Spouse.NotSmoker', Spouse.get('isSmoker') == null || Spouse.get('isSmoker') != true ? true : false);
            checkboxTabs.put('Spouse.Pregnant', Spouse.get('Pregnant') != null && Spouse.get('Pregnant') == true ? true : false);
            checkboxTabs.put('Spouse.NotPregnant', Spouse.get('Pregnant') == null || Spouse.get('Pregnant') != true ? true : false);
            textTabs.put('Spouse.DOB2', Spouse.get('DOB'));
        }

        //Promotion Discount
        if (DocuSignData.get('PromotionDiscount') != null) {
            textTabs.put('PromotionDiscount', '$' + String.valueOf(DocuSignData.get('PromotionDiscount')));
        }
        //Agent Name
        textTabs.put('Agent.Name', (String)(((Map<String,Object>)DocuSignData.get('Agent')).get('Name')));
        //Members Associated to each plan
        textTabs.put('Info.MembersPerProgramNew', (String)(((Map<String,Object>)DocuSignData.get('Info')).get('MembersPerProgram')));
        if (DocuSignData.containsKey('Relationship')) textTabs.put('Relationship',(String)DocuSignData.get('Relationship'));
        //Payment Information
        if ((String)Payment.get('Savings') == 'Savings') checkboxTabs.put('Payment.Savings', true);
        if (Payment.get('CardType') == 'American Express') {
            checkboxTabs.put('Payment.AmericanExpress', true);
        } else if (Payment.get('CardType') == 'Visa' || Payment.get('CardType') == 'MasterCard' || 
                   Payment.get('CardType') == 'Discover'){
            checkboxTabs.put('Payment.' + Payment.get('CardType'), true);
    	}
        if (Payment.get('PaymentMethod') == 'Credit Card') checkboxTabs.put('Payment.CreditCardPayment', true);
        if (Payment.get('PaymentMethod') == 'Bank Account') checkboxTabs.put('Payment.BankAccountPayment', true);
        if (Payment.get('BankAccountType') == 'Checking') checkboxTabs.put('Payment.Checking', true);
        textTabs.put('Payment.NameOnCard', Payment.get('FirstName') + ' ' + Payment.get('LastName'));
        if (Payment.get('CardExpMonth') != null && Payment.get('CardExpYear') != null) checkboxTabs.put('Payment.CardExpDate', String.valueOf(Payment.get('CardExpMonth')) + '/' + String.valueOf(Payment.get('CardExpYear')));

        // MEDICARE OUTPUT
        if (DocuSignData.containsKey('Medicare')) {
            Map<String, Object> medicareMap = (Map<String,Object>)DocuSignData.get('Medicare');
            if (medicareMap.containsKey('isLegacy')) {
                if (medicareMap.get('isLegacy') == true) {
                    for (String medicareKey : medicareMap.keySet()) {
                        if (medicareMap.get(medicareKey) != true && medicareMap.get(medicareKey) != false) {
                            textTabs.put('Medicare.' + medicareKey, medicareMap.get(medicareKey));
                        }
                        if (medicareMap.get(medicareKey) == true && medicareKey != 'isLegacy') {
                            checkboxTabs.put('Medicare.' + medicareKey, true);
                        }
                    }
                }               
            }
        }

        // Amendment resend DocuSign keys
        if (Primary != null) {
            textTabs.put('FullName', Primary.get('Name'));
            textTabs.put('MemberID', Primary.get('internalId'));
            textTabs.put('BillingStreet', Primary.get('Address'));
            textTabs.put('BillingCity', Primary.get('City'));
            textTabs.put('BillingState', Primary.get('State'));
            textTabs.put('BillingPostalCode', Primary.get('ZipCode'));
        }
        if (Info != null) {
            List<String> amendmentInfoList = new List<String>();
            if (Info.containsKey('ContractReason')) {
                String contractReasons = (String)Info.get('ContractReason');
                if (contractReasons.contains('State Change')) amendmentInfoList.add('Primary Address State Changed');
                if (contractReasons.contains('Effective Date Change')) amendmentInfoList.add('Effective Date Change');
                if (contractReasons.contains('Date of Birth Change')) amendmentInfoList.add('DOB update cause a change in age bracket');
                if (contractReasons.contains('Relationship To Primary Change')) amendmentInfoList.add('Relationship to Primary Change');
            }
            if (amendmentInfoList.size() > 0) {
                String amendmentInfoString = String.join(amendmentInfoList, '; ');
                textTabs.put('AmendmentInfo', amendmentInfoString);
            }
            textTabs.put('ContractNumber', (String)Info.get('ContractNumber') != null ? (String)Info.get('ContractNumber') : null);
            Datetime myDate = Date.today();
            String currentMonth = myDate.format('MMMMM');
            String currentYear = myDate.format('yyyy');
            textTabs.put('CurrentMonthYear', currentMonth + ' ' + currentYear);
        }
        


        outMap.put('tabs', new Map<String, Object>{
            'checkboxTabs' => checkboxTabs,
            'textTabs' => textTabs
        });
    }

    public static void transformInformationForDocusignCancellation(Map<String, Object> inputMap, Map<String, Object> outMap) {
        Map<String, Object> tabs = new Map<String, Object>();
        Map<String, Object> textTabs = new Map<String, Object>();
        Map<String, Object> radioGroupTabs = new Map<String, Object>();

        Map<String, Object> DocuSignData = ((Map<String, Object>)inputMap.get('DocuSignData'));
        Map<String, Object> Primary = ((Map<String, Object>)DocuSignData.get('Primary'));
        Map<String, Object> Info = ((Map<String, Object>)DocuSignData.get('Info'));

        //Loop Primary Object keys
        for (String key : Primary.keySet()) {
            Object value = Primary.get(key);
            if (key == 'isSmoker' || key == 'Pregnant' || key == 'Gender') continue;

            if (value == true || value == false) {
                continue;
            } else {
                textTabs.put('Primary.' + key, value);
            }
        }

        if (Info != null) {
            for (String key : Info.keySet()) {
                String value = String.valueOf(Info.get(key));
                textTabs.put('Info.' + key, value);
            }
        }

        radioGroupTabs.put('Primary.Gender', (String)Primary.get('Gender'));
        radioGroupTabs.put('Info.SignedBy', (String)Info.get('SignedBy'));
        textTabs.put('Info.DateToday', Date.today());

        outMap.put('tabs', new Map<String, Object>{
            'radioGroupTabs' => radioGroupTabs,
            'textTabs' => textTabs
        });
    }
}