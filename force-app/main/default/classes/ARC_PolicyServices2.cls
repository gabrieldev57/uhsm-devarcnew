global without sharing class ARC_PolicyServices2 implements vlocity_ins.VlocityOpenInterface {
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        if (methodName.equalsIgnoreCase('getMemberInfo')){
            getMemberInfo(inputMap, outMap);
        }

        if (methodName.equalsIgnoreCase('createPolicies')){
            createPolicies(inputMap, outMap);
        }

        if (methodName.equalsIgnoreCase('createPoliciesProgramChange')){
            createPoliciesProgramChange(inputMap, outMap);
        }

        return true;
    }

    public static void getMemberInfo(Map<String,Object> inputMap, Map<String,Object> outMap) {
		Id ContractId = (Id)inputMap.get('ContractId');
		Id CensusId = (Id)inputMap.get('CensusId');
		List<vlocity_ins__GroupCensusMemberPlan__c> groupCensusMemberPlans = [SELECT id,vlocity_ins__groupcensusmemberid__r.Id,vlocity_ins__groupcensusmemberid__r.vlocity_ins__isprimarymember__c,vlocity_ins__contractlineid__r.vlocity_ins__ProductType__c,vlocity_ins__groupcensusmemberid__r.vlocity_ins__IsSpouse__c,vlocity_ins__contractlineid__r.vlocity_ins__contractid__c,vlocity_ins__contractlineid__r.vlocity_ins__product2id__c,vlocity_ins__contractlineid__r.vlocity_ins__product2id__r.Name,vlocity_ins__groupcensusmemberid__r.vlocity_ins__contactid__c,vlocity_ins__groupcensusmemberid__r.vlocity_ins__gender__c,vlocity_ins__groupcensusmemberid__r.Name,vlocity_ins__groupcensusmemberid__r.vlocity_ins__contactid__r.accountid FROM vlocity_ins__GroupCensusMemberPlan__c WHERE (vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c =:ContractId) LIMIT 50000];

		// Products
		Set<Id> products = new Set<Id>();
		for (vlocity_ins__GroupCensusMemberPlan__c gcmp : groupCensusMemberPlans) {
			products.add(gcmp.vlocity_ins__contractlineid__r.vlocity_ins__product2id__c);
		}
		// UserInputs
		Map<String,Object> censusIdMap = new Map<String,Object>();
		censusIdMap.put('censusId', CensusId);
		List<Map<String,Object>> userInputs = ARC_CensusMemberToUserInputsGuestUsers(censusIdMap);

        Map<String,Object> response = new Map<String,Object>();
        Map<String,Object> options = new Map<String,Object>();
		String productIdsString ='';
		for (Id productId : products) {
			productIdsString = productIdsString+ ',\'' + String.valueOf(productId) + '\'';
		}
		productIdsString='('+productIdsString.removeStart(',')+')';
		String whereClause = 'Id IN '+productIdsString;
        outMap.put('whereClause', whereClause);
        outMap.put('userInputs', userInputs);
        outMap.put('MemberPlans', groupCensusMemberPlans);
    }

    public static void createPolicies(Map<String,Object> inputMap, Map<String,Object> outMap) {
        /* POLICY CREATION STARTS HERE */
        List<Object> RatedProducts = (List<Object>)inputMap.get('RatedProducts');
        List<Object> MemberPlans = (List<Object>)inputMap.get('MemberPlans');
        Id AccountId = (Id)inputMap.get('AccountId');
        Id ContractId = (Id)inputMap.get('ContractId');
		Id CensusId = (Id)inputMap.get('CensusId');

        Set<Id> plansPrimary = new Set<Id>();
        Set<Id> plansSpouse = new Set<Id>();
        Set<Map<String,Object>> censusMemberIds = new Set<Map<String,Object>>();
        
        Contract c = [SELECT ARC_TotalPrice__c,(SELECT vlocity_ins__Product2Id__c FROM vlocity_ins__ContractLineItems__r WHERE vlocity_ins__Product2Id__r.vlocity_ins__Type__c = 'Medical' AND vlocity_ins__RecordTypeName__c = 'Product') FROM Contract WHERE Id =: ContractId];
        Id medicalProductId = c.vlocity_ins__ContractLineItems__r[0].vlocity_ins__Product2Id__c;
        Double price = c.ARC_TotalPrice__c;

        InsurancePolicy InsPolicy = new InsurancePolicy();
        InsPolicy.Name = 'ShopAndEnroll Policy';
        InsPolicy.NameInsuredId = (Id)inputMap.get('AccountId');
        InsPolicy.PolicyName = 'Test Name 2';
        InsPolicy.ProductId = medicalProductId;
        InsPolicy.Status = 'Initial';
        InsPolicy.Substatus = 'Draft';
        InsPolicy.vlocity_ins_fsc__PremiumCalculationMethod__c = 'Daily';
        InsPolicy.vlocity_ins_fsc__PremiumPaymentType__c = 'Advance';
        InsPolicy.StandardPremiumAmount = price;
        InsPolicy.ARC_Contract__c = ContractId;
        insert InsPolicy;
        /* POLICY CREATION ENDS */

        /* PARTICIPANTS CREATION STARTS HERE */
        List<vlocity_ins__GroupCensusMember__c> CensusMembers = [SELECT vlocity_ins__ContactId__c,vlocity_ins__IsPrimaryMember__c,vlocity_ins__IsSpouse__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c =: CensusId];
        List<InsurancePolicyParticipant> ParticipantsToInsert = new List<InsurancePolicyParticipant>();

        for (vlocity_ins__GroupCensusMember__c cm : CensusMembers) {
            InsurancePolicyParticipant PolicyParticipant = new InsurancePolicyParticipant();
            PolicyParticipant.InsurancePolicyId = InsPolicy.Id;
            PolicyParticipant.PrimaryParticipantContactId = cm.vlocity_ins__ContactId__c;
            if (cm.vlocity_ins__IsPrimaryMember__c) {
                PolicyParticipant.Role = 'Primary';
            }
            else if (cm.vlocity_ins__IsSpouse__c) {
                PolicyParticipant.Role = 'Spouse';
            }
            else {
                PolicyParticipant.Role = 'Dependent';
            }
            ParticipantsToInsert.add(PolicyParticipant);
        }
        /* PARTICIPANTS CREATION ENDS */
        insert ParticipantsToInsert;

        /* COVERAGES CREATION STARTS HERE */
        List<vlocity_ins__ContractLineItem__c> clis = [SELECT Id,Name,vlocity_ins__Product2Id__r.vlocity_ins__Type__c,vlocity_ins__ParentItemId__c,vlocity_ins__ParentItemId__r.vlocity_ins__Product2Id__c,vlocity_ins__Product2Id__c,vlocity_ins__Product2Id__r.Name,vlocity_ins__ProductChildItemId__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c =: ContractId AND vlocity_ins__ParentItemId__c != NULL];

        Set<InsurancePolicyCoverage> MedicalCoverages = new Set<InsurancePolicyCoverage>();
        List<InsurancePolicyCoverage> SmartAndAiddCoverages = new List<InsurancePolicyCoverage>();
        List<InsurancePolicyCoverage> CoveragesToInsert = new List<InsurancePolicyCoverage>();

        for (vlocity_ins__ContractLineItem__c cli : clis) {
            String cliProductType = cli.vlocity_ins__Product2Id__r.vlocity_ins__Type__c;

            if (cliProductType == 'Medical') {
                InsurancePolicyCoverage PolicyCoverage = new InsurancePolicyCoverage();
                PolicyCoverage.CoverageName = cli.Name;
                PolicyCoverage.InsurancePolicyId = InsPolicy.Id;
                PolicyCoverage.vlocity_ins_fsc__Product2Id__c = cli.vlocity_ins__Product2Id__c;
                PolicyCoverage.vlocity_ins_fsc__ProductChildItemId__c = cli.vlocity_ins__ProductChildItemId__c;
                PolicyCoverage.ARC_ParentProduct__c = cli.vlocity_ins__ParentItemId__r.vlocity_ins__Product2Id__c;
                MedicalCoverages.add(PolicyCoverage);
            } else {
                for (Object Plan : MemberPlans) {
                    vlocity_ins__GroupCensusMemberPlan__c gcmp = (vlocity_ins__GroupCensusMemberPlan__c)Plan;
                    String gcmpProductType = gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c;

                    if ( gcmpProductType != 'Ancillary') {
                        continue;
                    }

                    for (InsurancePolicyParticipant Participant : ParticipantsToInsert) {
                        if(Participant.PrimaryParticipantContactId == gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__c && gcmp.vlocity_ins__ContractLineId__r.Id == cli.vlocity_ins__ParentItemId__c){
                            InsurancePolicyCoverage PolicyCoverage = new InsurancePolicyCoverage();
                            PolicyCoverage.CoverageName = cli.Name;
                            PolicyCoverage.InsurancePolicyId = InsPolicy.Id;
                            PolicyCoverage.vlocity_ins_fsc__Product2Id__c = cli.vlocity_ins__Product2Id__c;
                            PolicyCoverage.vlocity_ins_fsc__ProductChildItemId__c = cli.vlocity_ins__ProductChildItemId__c;
                            PolicyCoverage.ARC_ParentProduct__c = cli.vlocity_ins__ParentItemId__r.vlocity_ins__Product2Id__c;
                            PolicyCoverage.vlocity_ins_fsc__InsurancePolicyParticipantId__c = Participant.Id;
                            SmartAndAiddCoverages.add(PolicyCoverage);
                        }
                    }
                }
            }
        }

        CoveragesToInsert.addAll(MedicalCoverages);
        CoveragesToInsert.addAll(SmartAndAiddCoverages);
        /* COVERAGES CREATION ENDS */

        /* TERMS CREATION STARTS HERE */
        List<vlocity_ins_fsc__InsurancePolicyTerm__c> InsurancePolicyTerms = new List<vlocity_ins_fsc__InsurancePolicyTerm__c>();
        for (Object rp : RatedProducts) {
            Map<String, Object> product = (Map<String, Object>)rp;
            if (product.get('Type__c') == 'Medical') {
                Map<String,Object> attributeCategories = (Map<String,Object>)product.get('attributeCategories');
                List<Object> categories = (List<Object>)attributeCategories.get('records');

                for (Object cat : categories) {
                    Map<String,Object> category = (Map<String,Object>)cat;
                    if (String.valueOf(category.get('Code__c')) == 'WESHR_POWATT') {
                        Map<String,Object> productAttributes = (Map<String,Object>)category.get('productAttributes');
                        List<Object> policyTerms = (List<Object>)productAttributes.get('records');

                        for (Object pt : policyTerms) {
                            Map<String,Object> policyTerm = (Map<String,Object>)pt;
                            vlocity_ins_fsc__InsurancePolicyTerm__c InsurancePolicyTerm = new vlocity_ins_fsc__InsurancePolicyTerm__c();
                            InsurancePolicyTerm.Name = (String)policyTerm.get('label');
                            InsurancePolicyTerm.vlocity_ins_fsc__AttributeId__c = (Id)policyTerm.get('attributeId');
                            InsurancePolicyTerm.vlocity_ins_fsc__InitialValue__c = (Decimal)policyTerm.get('userValues');
                            InsurancePolicyTerm.vlocity_ins_fsc__InsurancePolicyId__c = (Id)InsPolicy.Id;
                            InsurancePolicyTerm.vlocity_ins_fsc__OriginalInsurancePolicyId__c = (Id)InsPolicy.Id;

                            // if (String.valueOf(policyTerm.get('code')).contains('COIN')) {
                            //     InsurancePolicyTerm.vlocity_ins_fsc__InitialValue__c = (Decimal)policyTerm.get('userValues');
                            // } else {
                            //     InsurancePolicyTerm.vlocity_ins_fsc__InitialAmount__c = (Decimal)policyTerm.get('userValues');
                            // }

                            InsurancePolicyTerms.add(InsurancePolicyTerm);
                        }
                    }
                }
            }
        }
        /* TERMS CREATION ENDS */

        /* INSERT LISTS OF RECORDS IN DATABASE */
        insert CoveragesToInsert;
        insert InsurancePolicyTerms;

    }

	public static void createPoliciesProgramChange(Map<String,Object> inputMap, Map<String,Object> outMap) {
        /* POLICY CREATION STARTS HERE */
        List<Object> changesForContracts = (List<Object>)inputMap.get('changesForContracts');
		List<Object> Ids = (List<Object>)inputMap.get('censusMemberIds');
		List<Object> censusIds = (List<Object>)inputMap.get('censusIds');
        List<String> censusIdsList = new List<String>();
        System.debug(censusIds);
        for (Object cId : censusIds) {
            String censusId = String.valueOf(cId);
            censusIdsList.add(censusId);
        }
		Id OldContractId = (Id)inputMap.get('OldContractId');

		List<vlocity_ins__GroupCensusMember__c> censusMembers = [SELECT Id,vlocity_ins__ContactId__c,vlocity_ins__CensusId__c,vlocity_ins__IsPrimaryMember__c,vlocity_ins__IsSpouse__c,vlocity_ins__MemberIdentifier__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c IN:censusIdsList];
        InsurancePolicy OldPolicy = [SELECT Id FROM InsurancePolicy WHERE ARC_Contract__c =: OldContractId];

        List<InsurancePolicy> PoliciesToInsert = new List<InsurancePolicy>();

        for (Object c : changesForContracts) {
            Map<String, Object> contract = (Map<String, Object>)c;
            String Reason = (String)contract.get('Reason');

            if (Reason.containsIgnoreCase('Program Downgrade') || Reason.containsIgnoreCase('Program Upgrade')) {
                Map<String,Object> RA_GetProductDetails = (Map<String,Object>)contract.get('RA_GetProductDetails');
                List<Object> products = (List<Object>)RA_GetProductDetails.get('records');
    
                Id MedicalProductId;
                Double TotalPrice = 0;
                for (Object p : products) {
                    Map<String,Object> product = (Map<String,Object>)p;
                    if (product.get('Type__c') == 'Medical') {
                        MedicalProductId = (Id)product.get('productId');
                    }
                    TotalPrice = TotalPrice + (Double)product.get('Price');
                }
    
                InsurancePolicy InsPolicy = new InsurancePolicy();
                InsPolicy.Name = 'Test Name';
                InsPolicy.NameInsuredId = (Id)contract.get('accountId');
                InsPolicy.PolicyName = 'Test Name 2';
                InsPolicy.ProductId = MedicalProductId;
                InsPolicy.Status = 'Initial';
                InsPolicy.Substatus = 'Draft';
                InsPolicy.vlocity_ins_fsc__PremiumCalculationMethod__c = 'Daily';
                InsPolicy.vlocity_ins_fsc__PremiumPaymentType__c = 'Advance';
                InsPolicy.StandardPremiumAmount = TotalPrice;
                InsPolicy.ARC_Contract__c = (Id)contract.get('Id');
                PoliciesToInsert.add(InsPolicy);
            }
        }

        if (PoliciesToInsert.isEmpty() == false) {
            insert PoliciesToInsert;
        }
        /* POLICY CREATION ENDS */

        List<InsurancePolicyCoverage> CoveragesToInsert = new List<InsurancePolicyCoverage>();
        List<InsurancePolicyParticipant> ParticipantsToInsert = new List<InsurancePolicyParticipant>();
		List<vlocity_ins_fsc__InsurancePolicyTerm__c> PolicyTermsToInsert = new List<vlocity_ins_fsc__InsurancePolicyTerm__c>();

        for (Object c : changesForContracts) {
            Map<String, Object> contract = (Map<String, Object>)c;
            String Reason = (String)contract.get('Reason');

            if (Reason.containsIgnoreCase('Program Downgrade') || Reason.containsIgnoreCase('Program Upgrade')) {
                Map<String,Object> RA_GetProductDetails = (Map<String,Object>)contract.get('RA_GetProductDetails');
                List<Object> products = (List<Object>)RA_GetProductDetails.get('records');

                for (InsurancePolicy Policy : PoliciesToInsert) {

                    if (Policy.ARC_Contract__c.equals((Id)contract.get('Id'))) {

                        for (Object p : products) {
                            Map<String,Object> product = (Map<String,Object>)p;
                            //Child Products -> Coverages
                            Map<String,Object> childProducts = (Map<String,Object>)product.get('childProducts');
                            List<Object> coverages = (List<Object>)childProducts.get('records');
                            //Attribute Categories
                            Map<String,Object> attributeCategories = (Map<String,Object>)product.get('attributeCategories');
                            List<Object> categories = (List<Object>)attributeCategories.get('records');
        
                            for (Object cov : coverages) {
                                Map<String,Object> coverage = (Map<String,Object>)cov;

                                if (!coverage.get('ProductCode').equals('RF_Census')) {
                                    InsurancePolicyCoverage PolicyCoverage = new InsurancePolicyCoverage();
                                    PolicyCoverage.CoverageName = (String)coverage.get('Name');
                                    PolicyCoverage.InsurancePolicyId = (Id)Policy.Id;
                                    PolicyCoverage.vlocity_ins_fsc__Product2Id__c = (Id)coverage.get('Id');
                                    PolicyCoverage.vlocity_ins_fsc__ProductChildItemId__c = (Id)coverage.get('pciId');
                                    CoveragesToInsert.add(PolicyCoverage);
                                }
                            }

                            for (Object cat : categories) {
                                Map<String,Object> category = (Map<String,Object>)cat;
                                if (String.valueOf(category.get('Code__c')).contains('POW_')) {
                                    Map<String,Object> productAttributes = (Map<String,Object>)category.get('productAttributes');
                                    List<Object> policyTerms = (List<Object>)productAttributes.get('records');
        
                                    for (Object pt : policyTerms) {
                                        Map<String,Object> policyTerm = (Map<String,Object>)pt;
                                        vlocity_ins_fsc__InsurancePolicyTerm__c PTerm = new 	vlocity_ins_fsc__InsurancePolicyTerm__c();
                                        PTerm.Name = (String)policyTerm.get('label');
                                        PTerm.vlocity_ins_fsc__AttributeId__c = (Id)policyTerm.get('attributeId');
                                        PTerm.vlocity_ins_fsc__InitialAmount__c = (Decimal)policyTerm.get('userValues');
                                        PTerm.vlocity_ins_fsc__InsurancePolicyId__c = (Id)Policy.Id;
                                        PTerm.vlocity_ins_fsc__OriginalInsurancePolicyId__c = (Id)Policy.Id;
                                        PolicyTermsToInsert.add(PTerm);
                                    }
                                }
                            }
                        }

                        for (vlocity_ins__GroupCensusMember__c censusMember : censusMembers) {
                            if (censusMember.vlocity_ins__CensusId__c == contract.get('censusId')) {
                                InsurancePolicyParticipant PolicyParticipant = new InsurancePolicyParticipant();
                                PolicyParticipant.InsurancePolicyId = Policy.Id;
                                PolicyParticipant.PrimaryParticipantContactId = censusMember.vlocity_ins__ContactId__c;
                                Date effectiveDate = Date.valueOf((String)contract.get('EffDate'));
                                PolicyParticipant.EffectiveDate = effectiveDate;

                                if (censusMember.vlocity_ins__IsPrimaryMember__c) {
                                    PolicyParticipant.Role = 'Policy Holder';
                                }
                                else if (censusMember.vlocity_ins__IsSpouse__c) {
                                    PolicyParticipant.Role = 'Spouse';
                                }
                                else{
                                    PolicyParticipant.Role = 'Dependent';
                                }
                                ParticipantsToInsert.add(PolicyParticipant);
                            }
                        }
                    }
                }
            }


            if (Reason.equals('Add Member')) { // for each contract
                List<Object> auxSavedMembers = (List<Object>)contract.get('auxSavedMembers');
                for (Object m : auxSavedMembers) {
                    Map<String, Object> member = (Map<String, Object>)m;
                    if ((Boolean)member.get('isNew') == true) { // for each new member
                        for (vlocity_ins__GroupCensusMember__c censusMember : censusMembers) {
                            if (censusMember.vlocity_ins__MemberIdentifier__c == member.get('vlocity_ins__MemberIdentifier__c')) {
                                InsurancePolicyParticipant PolicyParticipant = new InsurancePolicyParticipant();
                                PolicyParticipant.InsurancePolicyId = OldPolicy.Id;
                                PolicyParticipant.PrimaryParticipantContactId = censusMember.vlocity_ins__ContactId__c;
                                Date effectiveDate = Date.valueOf((String)contract.get('EffDate'));
                                PolicyParticipant.EffectiveDate = effectiveDate;

                                if (censusMember.vlocity_ins__IsPrimaryMember__c) {
                                PolicyParticipant.Role = 'Policy Holder';
                                }
                                else if (censusMember.vlocity_ins__IsSpouse__c) {
                                PolicyParticipant.Role = 'Spouse';
                                }
                                else{
                                PolicyParticipant.Role = 'Dependent';
                                }

                                ParticipantsToInsert.add(PolicyParticipant);
                            }
                        }
                    }
                }
            }
        }

        insert CoveragesToInsert;
        insert ParticipantsToInsert;
        insert PolicyTermsToInsert;
    }

	public static List<Map<String,Object>> ARC_CensusMemberToUserInputsGuestUsers(Map<String,Object> inputMap) {
        String censusId =  String.valueOf(inputMap.get('censusId'));
        String onlyActiveMembers = String.valueOf(inputMap.get('onlyActiveMembers'));
        String censusMemberIdForFilter = String.valueOf(inputMap.get('censusMemberIdForFilter'));

        List<vlocity_ins__GroupCensusMember__c> censusMember = new List<vlocity_ins__GroupCensusMember__c>();

        if(onlyActiveMembers == 'true'){
            censusMember = [SELECT Id, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE (vlocity_ins__CensusId__c = :censusId AND ARC_ActiveMember__c = true )];
        }else{
            censusMember = [SELECT Id, Name, vlocity_ins__Email__c, ARC_Smoker__c, ARC_ActiveMember__c, ARC_PhysicalAddressState__c,vlocity_ins__MemberIdentifier__c, arc_medicalproduct__c, arc_dentalproduct__c, arc_visionproduct__c, vlocity_ins__censusid__c,vlocity_ins__birthdate__c, vlocity_ins__isprimarymember__c, vlocity_ins__gender__c, vlocity_ins__isspouse__c, vlocity_ins__lastname__c, vlocity_ins__firstname__c, ARC_AgeInSixMonths__c, ARC_DependentRelationship__c FROM vlocity_ins__GroupCensusMember__c WHERE vlocity_ins__CensusId__c = :censusId];
        }

        Date minBirthdate = null;

        for(vlocity_ins__GroupCensusMember__c member : censusMember){
            Date bd = member.vlocity_ins__birthdate__c;
            if(minBirthdate == null){
                minBirthdate = bd;
            } else if(bd < minBirthdate){
                minBirthdate = bd;
            }
        } 

        vlocity_ins__GroupCensus__c census = [SELECT Id, Name, ARC_MinCensusDOB__c, ARC_CountSuscribers__c, ARC_CountChildren__c, ARC_CountSpouse__c, vlocity_ins__GroupId__c, ARC_PrimaryAccount__c FROM vlocity_ins__GroupCensus__c WHERE Id = :censusId];
        Account censusAccount = [SELECT Id, vlocity_ins__Email__c, Phone, BillingStreet, BillingCity, BillingState, BillingPostalCode, ARC_Effective_Date__c FROM Account WHERE Id =: census.vlocity_ins__GroupId__c LIMIT 1];
        Contract censusContract = [SELECT Id, RecordTypeId, StartDate FROM Contract WHERE AccountId =: censusAccount.Id ORDER BY CreatedDate DESC LIMIT 1];
    
        
        List<Map<String, Object>> userInputList = new List<Map<String, Object>>();

        for (vlocity_ins__GroupCensusMember__c member : censusMember) {
            Map<String, Object> userInputMap = new Map<String, Object>();
            Map<String, Object> userBirthdate = new Map<String, Object>();

            Decimal Dependants = census.ARC_CountSuscribers__c - 1;
            
            Decimal ExtraDependants;
            if (census.ARC_CountSuscribers__c - 5 < 0){
                ExtraDependants = 0;
            } else{
                ExtraDependants = census.ARC_CountSuscribers__c - 5;
            }

            String effectiveDate =  String.valueOf(inputMap.get('effectiveDate'));
            
            Integer PrimaryAge = -1;
            Integer age = -1;
            if(effectiveDate != null ){
                //PrimaryAge = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.valueOf(effectiveDate)))/365.2425);
                PrimaryAge = calculateAge( Date.valueOf(minBirthdate), Date.valueOf(effectiveDate));
                //age = Integer.valueOf((Date.valueOf(member.vlocity_ins__Birthdate__c).daysBetween(Date.valueOf(effectiveDate)))/365.2425);
                age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.valueOf(effectiveDate));
            }else{
                //PrimaryAge = Integer.valueOf((Date.valueOf(minBirthdate).daysBetween(Date.today()))/365.2425);
                PrimaryAge = calculateAge( Date.valueOf(minBirthdate), Date.today());
                //age = Integer.valueOf((Date.valueOf(member.vlocity_ins__Birthdate__c).daysBetween(Date.today()))/365.2425);   
                age = calculateAge( Date.valueOf(member.vlocity_ins__Birthdate__c), Date.today());
            }

            String coverage = '';
            if(census.ARC_CountSpouse__c==1 && census.ARC_CountSuscribers__c == 2){
                coverage = 'Primary + Spouse';
            }else if(census.ARC_CountSpouse__c == 0 && census.ARC_CountChildren__c>0){
                coverage = 'Primary + Child';
            }else if(census.ARC_CountSuscribers__c==1){
                coverage = 'Primary';
            }else{
                coverage = 'Family';
            }

            Boolean isMinor = false;
            if(age < 18){
                isMinor = true;
            }

            String coverageAIDD = '';
            if(census.ARC_CountSpouse__c==1 && census.ARC_CountSuscribers__c == 2){
                coverageAIDD = 'Primary + Spouse';
            }else if(census.ARC_CountSpouse__c == 0 && census.ARC_CountChildren__c>0){
                coverageAIDD = 'Primary + Children';
            }else if(census.ARC_CountSuscribers__c==1){
                coverageAIDD = 'Primary';
            }else{
                coverageAIDD = 'Family';
            }

            userInputMap.put('CensusMemberId', member.Id);
            userInputMap.put('CensusMemberName', member.Name);
            userInputMap.put('isMinor', isMinor);
            userInputMap.put('CensusMemberLastName', member.vlocity_ins__lastname__c);
            userInputMap.put('CensusMemberFirstName', member.vlocity_ins__firstname__c);
            userInputMap.put('CensusMemberRelationship', member.ARC_DependentRelationship__c);
            userInputMap.put('CensusMemberIdentifier', member.vlocity_ins__MemberIdentifier__c);
            userInputMap.put('CensusEmail', censusAccount.vlocity_ins__Email__c);
            userInputMap.put('ContractId', censusContract.Id);
            userInputMap.put('AccountId', censusAccount.Id);
            userInputMap.put('ContractRecType', censusContract.RecordTypeId);
            userInputMap.put('ContractStartDate', censusContract.StartDate);
            userInputMap.put('Email', member.vlocity_ins__Email__c);
            userInputMap.put('Phone', censusAccount.Phone);
            userInputMap.put('Street', censusAccount.BillingStreet);
            userInputMap.put('City', censusAccount.BillingCity);
            userInputMap.put('State', censusAccount.BillingState);
            userInputMap.put('Zipcode', censusAccount.BillingPostalCode);
            userInputMap.put('EffectiveDate', censusAccount.ARC_Effective_Date__c);
            userInputMap.put('Birthdate', member.vlocity_ins__Birthdate__c);
            userInputMap.put('RF_Census.CRF_Dependants', Dependants);
            userInputMap.put('RF_Census.CRF_ExtraDependants', ExtraDependants);
            userInputMap.put('RF_Census.CRF_PrimaryMemberAge', PrimaryAge);
            userInputMap.put('RF_Census.CM_State', member.ARC_PhysicalAddressState__c);
            userInputMap.put('RF_Census.CM_IsPrimary', member.vlocity_ins__IsPrimaryMember__c);
            userInputMap.put('RF_Census.CM_IsSpouse', member.vlocity_ins__isspouse__c);
            userInputMap.put('RF_Census.CM_Smoker', member.ARC_Smoker__c);
            userInputMap.put('RF_Census.CM_Age', age);
            userInputMap.put('RF_Census.CRF_Coverage', coverage);
            userInputMap.put('RF_Census.CRF_CoverageAIDD', coverageAIDD);
    
            userInputList.add(userInputMap);
        }        

        if(String.isNotBlank(censusMemberIdForFilter)){
             String s = censusMemberIdForFilter;
			 s = s.substring(1, s.length() - 1);
             List<String> bulkCensusMemberId = s.split('\\, ');
             Date aux = date.today();
            Map<String, Object>  memberAux = new Map<String, Object>();
            
            for (Map<String, Object> censusMemberAux  : userInputList) {
                Date bd = date.valueOf(censusMemberAux.get('Birthdate'));
                Integer age = Integer.valueOf(censusMemberAux.get('RF_Census.CM_Age'));
                String censusMemberIdFromBulk = String.valueOf(censusMemberAux.get('CensusMemberId'));
                
                for(String censusMemberIdAux : bulkCensusMemberId){

                    if(bd < aux && censusMemberIdFromBulk == censusMemberIdAux) {
                        aux = bd;
                        memberAux = censusMemberAux;
                    }
                }
            }
           
        }
    	return userInputList;
    }

	private static Integer calculateAge(Date DOB, Date dateTo){
        Date memberBDToDate = DOB;
        Date effDate = dateTo;

        Integer DOBYear = memberBDToDate.year();
        Integer effYear = effDate.year();

        Integer DOBMonth = memberBDToDate.month();
        Integer effMonth = effDate.month();

        Integer DOBDay = memberBDToDate.day();
        Integer effDay = effDate.day();

        Integer turnsInEffYear = effYear - Dobyear;

        Boolean pastBD = false;
        if(DOBMonth < effMonth){
            pastBD = true;
        }else if(DOBMonth == effMonth){
            if(DOBDay<=effDay){
                pastBD = true;
            }
        }

        Integer age = -1;
        if(pastBD == true){
            age = turnsInEffYear;
        } else{
            age = turnsInEffYear -1;
        }

        return age;
    } 

    
}