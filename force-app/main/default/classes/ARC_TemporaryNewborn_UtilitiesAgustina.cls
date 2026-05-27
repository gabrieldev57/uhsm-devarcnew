global without sharing class ARC_TemporaryNewborn_UtilitiesAgustina {

    
    ////Main methods/////////////////////
    /////////////////////////////////////////////

    private static integer daysToAdd = 60;


    /*******************************************************************
    * @MethodName         :   readMedicalQuestions
    * @Description        :   Method to retrieve active members medical questions and populate new member fields on medical quesitons omniscript
    ********************************************************************/
    public static void populateMedicalQuestions(Map<String, Object> inputMap, Map<String, Object> outputMap, Map<String, Object> options) {

        // Get the newborn data
        Map<String, Object> censusComponent = (Map<String, Object>) inputMap.get('STEP_AddNewborn');

        List<Object> censusMembers = new List<Object>(); // Initialize as empty
        List<Object> censusDataList = new List<Object>();

        try {
            censusDataList = (List<Object>)censusComponent.get('EB_TemporaryNewborn'); // Store the value in an auxiliary variable
        } catch(Exception e){
            Map<String, Object> censusDataMap = (Map<String, Object>)censusComponent.get('EB_TemporaryNewborn'); // Store the value in an auxiliary variable
            censusDataList.add(censusDataMap);
        }

        // censusMembers = (List<Object>) censusDataList[1];
        censusMembers = censusDataList;

        system.debug('censusMembers 1 '+ censusMembers);

        Map<Id,Id> paToNewCensusId = new Map<Id,Id>();
        
        // Output contractor
        Map<String, Object> stepMedicalQuestions = new Map<String, Object>();

        // Map questions values to blocks
        Map<String, List<Map<String, Object>>> questionsMap = new Map<String, List<Map<String, Object>>>();

        // Use to populate arc_SelectCensusMember and arc_SelectCensusMemberCancer LWC SELECTS on the Omniscript
        List<Object> selectCensusMemberList = new List<Object>();

        // Populate new members medical question field member name
        if (censusMembers.Size() > 0) {
            for (Object member : censusMembers) {
                Map<String, Object> memberMap = (Map<String, Object>) member;
                addMemberNameToMedicalQuestions(memberMap, questionsMap, selectCensusMemberList);
            }
        }
        
        // Populate Step Medical Qustions Blocks
        for (String key : questionsMap.keySet()) {
            stepMedicalQuestions.put(key, questionsMap.get(key));
        }
        
        // If Radio Buttons are null we will set them to 'No'
        if(stepMedicalQuestions.get('RAD_ParentSiblingDiagnosed') == null) stepMedicalQuestions.put('RAD_ParentSiblingDiagnosed', 'No');
        if(stepMedicalQuestions.get('RAD_UnexplainedSymptoms') == null) stepMedicalQuestions.put('RAD_UnexplainedSymptoms', 'No');
        if(stepMedicalQuestions.get('RAD_PendingTests') == null) stepMedicalQuestions.put('RAD_PendingTests', 'No');
        if(stepMedicalQuestions.get('RAD_Cancer') == null) stepMedicalQuestions.put('RAD_Cancer', 'No');
        if(stepMedicalQuestions.get('RAD_Addictions') == null) stepMedicalQuestions.put('RAD_Addictions', 'No');
        if(stepMedicalQuestions.get('RAD_LicenceSuspended') == null) stepMedicalQuestions.put('RAD_LicenceSuspended', 'No');
        if(stepMedicalQuestions.get('RAD_PastConditions') == null) stepMedicalQuestions.put('RAD_PastConditions', 'No');
        if(stepMedicalQuestions.get('RAD_PrescriptionMedications') == null) stepMedicalQuestions.put('RAD_PrescriptionMedications', 'No');

        // Save Output on STEP_MedicalQuestions
        outputMap.put('STEP_MedicalQuestions', stepMedicalQuestions);
        // Save Output for LWC Select arc_SelectCensusMember and arc_SelectCensusMemberCancer
        outputMap.put('CensusMember', selectCensusMemberList);
        system.debug('Final OutputMap: ' + JSON.serializePretty(outputMap));
    }


         /**
     * Transform the census members to user inputs
     * @param {Map<String,Object>} inputMap - The input map.
     * @param {Map<String,Object>} outputMap - The output map.
     * @param {Map<String,Object>} options - The options map.
     * @returns {Map<String,Object>} - The output map.
     */
    public static Map<String,Object> TRANSFORM_CensusMemberToUserInputs(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Map<String,Object> eligibleContractInfo = (Map<String,Object>)inputMap.get('EligibleContractInfo');
        String activeCensusId = (String)inputMap.get('ActiveCensusId');
        String censusId = (String)eligibleContractInfo.get('CensusId');
        String contractId = (String)eligibleContractInfo.get('Id');
        Boolean isSpinOff = ((String)eligibleContractInfo.get('Reasons')).contains('Spin Off') && ((String)eligibleContractInfo.get('Status')).contains('Awaiting') && censusId != activeCensusId ? true : false;
       
        system.debug('inputMap ' + inputMap);
        system.debug('EffectiveDate ' + inputMap.get('EffectiveDate'));
        Date effectiveDate = (String)inputMap.get('EffectiveDate') != null && String.isNotBlank((String)inputMap.get('EffectiveDate')) ? Date.valueOf((String)inputMap.get('EffectiveDate')): null;


        Map<Id, String> censusMemberRelationshipMap = new Map<Id, String>();
        // Iterate over each CP and map their relationships to census member Id
        for (ARC_ContractParticipant__c cp : [
            SELECT Id, ARC_PersonAccount__r.Census_Member__c, ARC_Relationship__c
            FROM ARC_ContractParticipant__c
            WHERE ARC_Contract__c = :contractId AND ARC_Relationship__c != null
        ]) {
            String cpRelationship = cp.ARC_Relationship__c;
            censusMemberRelationshipMap.put(cp.ARC_PersonAccount__r.Census_Member__c, cpRelationship);
        }

        Set<Id> censusMemberIds = getContractMemberIds(contractId, censusId, isSpinOff);
        // Query active census members
        List<Map<String, Object>> census_members_list = new List<Map<String, Object>>();
        // vlocity_ins__GroupCensusMember__c primaryMember;
        for (vlocity_ins__GroupCensusMember__c member : [
            SELECT Id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, ARC_MiddleInitial__c, vlocity_ins__Birthdate__c, 
                   vlocity_ins__Gender__c, ARC_Relationship__c, vlocity_ins__Email__c, ARC_Phone__c, vlocity_ins__SocialSecurityNumber__c, 
                   ARC_HeightFeet__c, ARC_HeightInches__c, ARC_Weight__c, ARC_PhysicalAddressCity__c, ARC_PhysicalAddressState__c, 
                   ARC_PhysicalAddressStreet__c, ARC_PhysicalAddressZipCode__c, ARC_UpdateAllAddress__c, ARC_Age__c, ARC_Smoker__c, 
                   vlocity_ins__IsPrimaryMember__c,ARC_isPregnant__c, vlocity_ins__ContactId__r.AccountId, vlocity_ins__ContactId__c, vlocity_ins__MemberIdentifier__c
            FROM vlocity_ins__GroupCensusMember__c
            WHERE Id IN :censusMemberIds
            ORDER BY vlocity_ins__IsPrimaryMember__c DESC, vlocity_ins__IsSpouse__c DESC, vlocity_ins__Birthdate__c ASC
        ]) {
            Map<String,Object> member_map = createMemberMap (member, censusMemberRelationshipMap, isSpinOff);
            census_members_list.add(member_map);
        }

        // Variables for User Inputs
        List<Map<String, Object>> user_input_list = new List<Map<String, Object>>();
        Boolean hasPrimary = false;
        Boolean hasSpouse = false;
        Integer dependentCount = 0;
        Integer oldestAge = 0;
        String familyAddressState = '';
        String familyAddressCity = '';
        String familyAddressStreet = '';
        String familyAddressZipCode = '';

        for (Map<String,Object> cm : census_members_list) {
            Map<String,Object> censusMemberMap = (Map<String,Object>)cm;
            Map<String, Object> user_input = new Map<String, Object>();
            String cmRelationship = (String)censusMemberMap.get('ARC_Relationship__c');
            Integer age;

            if (effectiveDate != null){
                age = calculateAge((Date)censusMemberMap.get('vlocity_ins__Birthdate__c'), effectiveDate.addDays(daysToAdd));
            } else age = ((Decimal)censusMemberMap.get('ARC_Age__c')).intValue();

            // Track oldest member
            oldestAge = age > oldestAge ? age : oldestAge;

            user_input.put('Id', (String)censusMemberMap.get('Id'));
            user_input.put('RF_Census.CM_Age', age);
            user_input.put('RF_Census.CRF_PrimaryMemberDOB', String.valueOf((Date)censusMemberMap.get('vlocity_ins__Birthdate__c')));
            user_input.put('RF_Census.CM_State', (String)censusMemberMap.get('ARC_PhysicalAddressState__c'));
            user_input.put('RF_Census.CM_IsPrimary', cmRelationship == 'Primary' ? true : false);
            user_input.put('RF_Census.CM_Relationship', cmRelationship);
            user_input.put('RF_Census.CM_Smoker', (Boolean)censusMemberMap.get('ARC_Smoker__c') == true ? true : false);
            user_input.put('RF_Census.CM_Pregnant', (Boolean)censusMemberMap.get('ARC_isPregnant__c') == true ? true : false);
            user_input.put('RF_Census.CM_FirstName', (String)censusMemberMap.get('vlocity_ins__FirstName__c'));
            user_input.put('RF_Census.CM_LastName', (String)censusMemberMap.get('vlocity_ins__LastName__c'));
            user_input.put('IsRemoveMember', false);
            user_input.put('IsNewMember', false);
            user_input.put('IsAddExistingMember', false);

            user_input_list.add(user_input);

            if (cmRelationship == 'Primary') {
                hasPrimary = true;
                familyAddressState = (String)censusMemberMap.get('ARC_PhysicalAddressState__c');
                familyAddressCity = (String)censusMemberMap.get('ARC_PhysicalAddressCity__c');
                familyAddressStreet = (String)censusMemberMap.get('ARC_PhysicalAddressStreet__c');
                familyAddressZipCode = (String)censusMemberMap.get('ARC_PhysicalAddressZipCode__c');
            } else {
                dependentCount++;
                hasSpouse = cmRelationship == 'Spouse' ? true : hasSpouse;
                familyAddressState = familyAddressState == '' ? familyAddressState : (String)censusMemberMap.get('ARC_PhysicalAddressState__c');
                familyAddressCity = familyAddressCity == '' ? familyAddressCity : (String)censusMemberMap.get('ARC_PhysicalAddressCity__c');
                familyAddressStreet = familyAddressStreet == '' ? familyAddressStreet : (String)censusMemberMap.get('ARC_PhysicalAddressStreet__c');
                familyAddressZipCode = familyAddressZipCode == '' ? familyAddressZipCode : (String)censusMemberMap.get('ARC_PhysicalAddressZipCode__c');
            }
        }

        // Get added newborn members
        String familyAddress = String.join(new List<String>{familyAddressStreet, familyAddressCity, familyAddressState, familyAddressZipCode},', ');
        Object addedNewborn = inputMap.get('addedNewborn');
        List<Object> newbornList = new List<Object>();
        if (addedNewborn instanceOf List<Object>) {
            newbornList = (List<Object>)addedNewborn;
        } else {
            newbornList.add((Map<String,Object>)addedNewborn);
        }
        
        for (Object newborn : newbornList) {
            Map<String,Object> newbornMap = (Map<String,Object>)newborn;
            Map<String, Object> user_input = new Map<String, Object>();
            user_input.put('Id', newbornMap.get('Id'));
            user_input.put('RF_Census.CM_Age', 0);
            user_input.put('RF_Census.CRF_PrimaryMemberDOB', newbornMap.get('vlocity_ins__Birthdate__c'));
            user_input.put('RF_Census.CM_State', familyAddressState);
            user_input.put('RF_Census.CM_IsPrimary', false);
            user_input.put('RF_Census.CM_Relationship', 'Child');
            user_input.put('RF_Census.CM_Smoker', false);
            user_input.put('RF_Census.CM_Pregnant', false);
            user_input.put('RF_Census.CM_FirstName', newbornMap.get('vlocity_ins__FirstName__c'));
            user_input.put('RF_Census.CM_LastName', newbornMap.get('vlocity_ins__LastName__c'));
            user_input.put('IsRemoveMember', false);
            user_input.put('IsNewMember', true);
            user_input.put('IsAddExistingMember', false);

            dependentCount++;
            user_input_list.add(user_input);

            // Map newborns to census members node
            Map<String, Object> censusNewbornMap = new Map<String, Object>{
                'Id' => newbornMap.get('Id'),
                'vlocity_ins__FirstName__c' => newbornMap.get('vlocity_ins__FirstName__c'),
                'vlocity_ins__LastName__c' => newbornMap.get('vlocity_ins__LastName__c'),
                'PersonAccountId' => '',
                'PersonContactId' => '',
                'vlocity_ins__MemberIdentifier__c' => '',
                'ARC_MiddleInitial__c' => newbornMap.get('ARC_MiddleInitial__c'),
                'vlocity_ins__Birthdate__c' => newbornMap.get('vlocity_ins__Birthdate__c'),
                'vlocity_ins__IsPrimaryMember__c' => false,
                'ARC_Age__c' => 0,
                'vlocity_ins__SocialSecurityNumber__c' => newbornMap.get('vlocity_ins__SocialSecurityNumber__c'),
                'showSSN' => 'password',
                'ARC_HeightFeet__c' => newbornMap.get('ARC_HeightFeet__c'),
                'ARC_HeightInches__c' => newbornMap.get('ARC_HeightInches__c'),
                'ARC_Weight__c' => newbornMap.get('ARC_Weight__c'),
                'ARC_Smoker__c' => false,
                'ARC_PhysicalAddressCity__c' => familyAddressCity,
                'ARC_PhysicalAddressState__c' => familyAddressState,
                'ARC_PhysicalAddressStreet__c' => familyAddressStreet,
                'ARC_PhysicalAddressZipCode__c' => familyAddressZipCode,
                'ARC_Address__c' => familyAddress,
                'IsDependent' => true,
                'individual_errors' => new List<String>(),
                'IsNewMember' => true,
                'IsRemoveMember' => false,
                'ShowMember' => true,
                'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
                'DISABLE_INPUT_FIELDS' => false,
                'ARC_Phone__c' => '',
                'vlocity_ins__Email__c' => '',
                'ARC_isPregnant__c' => false,
                'ARC_Relationship__c' => 'Child',
                'vlocity_ins__Gender__c' => newbornMap.get('vlocity_ins__Gender__c')
            };
            census_members_list.add(censusNewbornMap);
        }

        // Sort the list: Primary first, Spouse second, Child last
        user_input_list.sort(new RelationshipComparator());

        Integer extraDependents = hasSpouse == true ? Math.max(dependentCount - 4, 0) : Math.max(dependentCount - 3, 0);
        // Integer user_input_list_size = user_input_list.size();

        // String aidd = hasPrimary == true & user_input_list_size == 1 ? 'Primary' : hasPrimary == true & hasSpouse == true & user_input_list_size == 2 ? 'Primary + Spouse' : hasPrimary == true & hasSpouse != true & user_input_list_size > 1 ? 'Primary + Children' : 'Family';
        // String smart = hasPrimary == true & user_input_list_size == 1 ? 'Primary' : hasPrimary == true & hasSpouse == true & user_input_list_size == 2 ? 'Primary + Spouse' : hasPrimary == true & hasSpouse != true & user_input_list_size > 1 ? 'Primary + Child' : 'Family';

        for (Map<String, Object> ui : user_input_list) {
            Map<String,Object> user_input = (Map<String,Object>)ui;
            // user_input.put('RF_Census.CRF_Coverage', smart);
            // user_input.put('RF_Census.CRF_CoverageAIDD', aidd);
            user_input.put('RF_Census.CRF_ExtraDependants', extraDependents);
            user_input.put('RF_Census.CRF_PrimaryMemberAge', oldestAge);
            user_input.put('RF_Census.CRF_Dependants', dependentCount);
        }

        Boolean applyExtraDependentFee = extraDependents > 0 ? true : false;
        outputMap.put('applyExtraDependentFee', applyExtraDependentFee);
        outputMap.put('userInputs', user_input_list);
        outputMap.put('census_members', census_members_list);

        return outputMap;
    }

    /**
     * Get the DocuSign related data 
     * @param {List<Object>} census_members - The census members.
     * @returns {Map<String, Object>} - DocuSign data.
     */
    public static void getDocuSignData(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> census_members = (List<Object>)inputMap.get('census_members');
        Map<String, Object> DocuSignMap = (Map<String, Object>)inputMap.get('DocuSign');

        System.debug('census_members: ' + census_members);
        // Get the primary
        Map<String, Object> primaryData = new Map<String, Object>();
        ARC_ContractParticipant__c contractParticipantData = new ARC_ContractParticipant__c();
        List<Contract> guardianInfo = new List<Contract>();
        
        
        String signerFullName = '';
        Boolean primaryIsOver18;

        // Look for the primary and check if is over 18, otherwise, the guardian is retrieved
        for (Object census_member : census_members) {
            Map<String,Object> cm = (Map<String,Object>)census_member;
            if ((String)cm.get('ARC_Relationship__c') == 'Primary' && (Integer)cm.get('ARC_Age__c') >= 18) {
                inputMap.put('signerEmail', (String)cm.get('vlocity_ins__Email__c'));
                inputMap.put('primaryState', (String)cm.get('ARC_PhysicalAddressState__c'));
                signerFullName = (String) cm.get('vlocity_ins__FirstName__c') + ' ' + (String) cm.get('vlocity_ins__LastName__c');
                primaryIsOver18 = true;
            }
        }
        System.debug('primary is over 18? ' + primaryIsOver18);
        // If primary is minor, query the guardian
        if (primaryIsOver18 != true) {
            String contractId = (String)((Map<String,Object>)DocuSignMap.get('SelectedContractInfo')).get('ContractID');
            System.debug('contract Id:' + contractId);
            guardianInfo = [
                SELECT ARC_Guardian__r.FirstName, ARC_Guardian__r.LastName, ARC_Guardian__r.vlocity_ins__Email__c, ARC_Guardian__r.BillingState
                FROM Contract
                WHERE Id = :contractId 
                LIMIT 1
            ];
            System.debug('Guardian info: ' + guardianInfo);
            inputMap.put('signerEmail', guardianInfo[0].ARC_Guardian__r.vlocity_ins__Email__c);
            inputMap.put('primaryState', guardianInfo[0].ARC_Guardian__r.BillingState);
            signerFullName = guardianInfo[0].ARC_Guardian__r.FirstName + ' ' + guardianInfo[0].ARC_Guardian__r.LastName;
        }
        // // Verify if the first census_member is the primary, otherwise, the guardian is retrieved
        // if ((((Map<String, Object>) census_members[0]).get('ARC_Relationship__c')) == 'Primary' && ((Integer)(((Map<String, Object>) census_members[0]).get('ARC_Age__c'))) >= 18){
        //     primaryData = (Map<String, Object>) census_members[0];
        //     inputMap.put('signerEmail', (String) primaryData.get('vlocity_ins__Email__c'));
        //     inputMap.put('primaryState', (String) primaryData.get('ARC_PhysicalAddressState__c'));
        //     signerFullName = (String) primaryData.get('vlocity_ins__FirstName__c') + ' ' + (String) primaryData.get('vlocity_ins__LastName__c');
        // } 
        // else {
        //     String accountId = (String) inputMap.get('ContextId');
        //     System.debug('Context Id:' + (String)inputMap.get('ContextId'));
        //     contractParticipantData = [SELECT ARC_Contract__r.ARC_Guardian__r.FirstName, ARC_Contract__r.ARC_Guardian__r.LastName, 
        //                                         ARC_Contract__r.ARC_Guardian__r.vlocity_ins__Email__c, ARC_Contract__r.ARC_Guardian__r.BillingState
        //                                FROM ARC_ContractParticipant__c
        //                                WHERE ARC_PersonAccount__c = :accountId 
        //                                AND ARC_Contract__r.Status = 'Activated'
        //                                LIMIT 1];
        //     inputMap.put('signerEmail', contractParticipantData.ARC_Contract__r.ARC_Guardian__r.vlocity_ins__Email__c);
        //     inputMap.put('primaryState', contractParticipantData.ARC_Contract__r.ARC_Guardian__r.BillingState);
        //     signerFullName = contractParticipantData.ARC_Contract__r.ARC_Guardian__r.FirstName + ' ' + contractParticipantData.ARC_Contract__r.ARC_Guardian__r.LastName;
        // }

        // Number of dependents
        Integer numberDependents = 0;
        for (Object census_member : census_members) {
            Map<String, Object> member = (Map<String, Object>)census_member;
            if ((String)member.get('ARC_Relationship__c') == 'Child') {
                numberDependents++;
            }
        }
        System.debug('numberDependents: ' + numberDependents);
        String signerEmail = (String)inputMap.get('signerEmail');
        System.debug('signerEmail: ' + signerEmail);
        String primaryState = (String)inputMap.get('primaryState');
        System.debug('primaryState: ' + primaryState);

        // Get the necessary data for the STEP_SignTheDocument
        outputMap.put('signerEmail', signerEmail);
        outputMap.put('signerFullName', signerFullName);

        // Is Legacy
        Boolean isLegacy = false;
        // Object selectedProducts_obj = inputMap.get('selectedProducts');

        Map<String, Object> PlansSummary = (Map<String, Object>) DocuSignMap.get('PlanSummary');
        Map<String, Object> BLK_ProductSummary = (Map<String, Object>) PlansSummary.get('BLK_ProductSummary');
        Map<String, Object> BLK_ProductsPrices = (Map<String, Object>) BLK_ProductSummary.get('BLK_ProductsPrices');
        Object selectedProducts_obj = BLK_ProductsPrices.get('BLK_IndividualProducts');

        if (selectedProducts_obj != null && selectedProducts_obj != '') {
            List<Object> selectedProducts = (List<Object>)selectedProducts_obj;
            for (Object selectedProduct_obj : selectedProducts) {
                Map<String, Object> selectedProduct = (Map<String, Object>)selectedProduct_obj;
                if ((String)selectedProduct.get('Type') == 'Medical' && (String)selectedProduct.get('TXT_PlanSelected') == 'WeShare Legacy') {
                    isLegacy = true;
                    break;
                }
            }
        }
        // Query template
        String templateNameStr = '';
        if (isLegacy) {
            if (primaryState == 'CA') {
                templateNameStr = 'WeShare Legacy Membership Application CA';
            }
            else {
                templateNameStr = 'WeShare Legacy Membership Application';
            }
        } else {
            String queryStr = 'SELECT ARC_Template_Name__c, ARC_DRTransform__c ';
            queryStr += 'FROM ARC_DocuSignTemplates__c';
            queryStr += ' WHERE ARC_Contract_Reasons__c LIKE \'%Spin Off%\'';
            queryStr += ' AND ARC_Min_Dependents__c <= ' + numberDependents;
            queryStr += ' AND ARC_Max_Dependents__c >= ' + numberDependents;
            if (primaryState == 'CA') {
                queryStr += ' AND ARC_State__c =  \'CA\'';
            }
            queryStr += ' ORDER BY ARC_Template_Name__c ASC LIMIT 1';
            ARC_DocuSignTemplates__c templateSettings = Database.query(queryStr);
            templateNameStr = templateSettings.ARC_Template_Name__c;
        }
        System.debug('templateNameStr: ' + templateNameStr);
        vlocity_ins__VlocityDocuSignTemplate__c template = [
            SELECT Id, Name, vlocity_ins__templateidentifier__c
            FROM vlocity_ins__VlocityDocuSignTemplate__c
            WHERE name = :templateNameStr
            ORDER BY LastModifiedDate DESC LIMIT 1
        ];
        System.debug('template: ' + template);
        Map<String, Object> DocuSignTemplateId = new Map<String, Object>();
        DocuSignTemplateId.put('Id', template.Id);
        DocuSignTemplateId.put('Name', template.Name);
        DocuSignTemplateId.put('TemplateId', template.vlocity_ins__templateidentifier__c);
        outputMap.put('DocuSignTemplateId', DocuSignTemplateId);
        // Signers....
        List<Object> recipients = new List<Object>();
        Integer dependentCount = 1;
        for (Object census_member_obj : census_members) {
            Map<String, Object> census_member = (Map<String, Object>)census_member_obj;
            String name = (String)census_member.get('vlocity_ins__FirstName__c') + ' ' + (String)census_member.get('vlocity_ins__LastName__c');
            String relationship = (String)census_member.get('ARC_Relationship__c');
            if ((Integer)census_member.get('ARC_Age__c') < 18 || (relationship != 'Primary' && !(Boolean)census_member.get('IsNewMember'))) continue;
            String templateRole;
            if (relationship == 'Primary' || relationship == 'Spouse') {
                templateRole = relationship == 'Primary' ? 'Primary' : 'Spouse';
            } else if (relationship == 'Child') {
                templateRole = 'Dependent' + dependentCount;
                dependentCount++;
            }
            Map<String, Object> recipient = new Map<String, Object>();
            recipient.put('templateRole', templateRole);
            recipient.put('signerEmail', signerEmail);
            recipient.put('signerName', name);
            recipients.add(recipient);
        }

        // Get the Guardian if there is no a Primary
        if (recipients.size() == 0) {
            String templateRole = 'Primary';

            // Map<String, Object> guardianStep = (Map<String, Object>)inputMap.get('STEP_GuardiansInformation');
            String guardianFirstName = guardianInfo[0].ARC_Guardian__r.FirstName;
            String guardianLastName = guardianInfo[0].ARC_Guardian__r.LastName;
            String guardianName = guardianFirstName + ' ' + guardianLastName;
            Map<String, Object> recipient = new Map<String, Object>();
            recipient.put('templateRole', templateRole);
            recipient.put('signerEmail', signerEmail);
            recipient.put('signerName', guardianName);
            recipients.add(recipient);
        }
        System.debug('SignerList: ' + recipients);
        outputMap.put('SignerList', recipients);
        // Info....
        // Transform DATA
        // GET Input DATA
        Map<String,Object> inputMapDSTrans = new Map<String,Object>();

        Map<String, Object> MembersInfo = new Map<String, Object>();
        List<Object> dependentMembers = new List<Object>();
        for (Object census_member_obj : census_members) {
            Map<String, Object> census_member = (Map<String, Object>)census_member_obj;
            String relationship = (String)census_member.get('ARC_Relationship__c');
            System.debug('Relationship: ' + relationship);

            if (relationship == 'Primary') {
                Map<String, Object> primaryMember = new Map<String, Object>();
                Object isPregnant_obj = census_member.get('ARC_isPregnant__c');
                primaryMember.put('Pregnant',isPregnant_obj != null && isPregnant_obj != '' ? (Boolean)isPregnant_obj : false);
                Object Smoker_obj = census_member.get('ARC_Smoker__c');
                primaryMember.put('Smoker', Smoker_obj != null && Smoker_obj != '' ? (Boolean)Smoker_obj : false);
                primaryMember.put('MI', (String)census_member.get('ARC_MiddleInitial__c'));
                primaryMember.put('Phone', (String)census_member.get('ARC_Phone__c'));
                primaryMember.put('City', (String)census_member.get('ARC_PhysicalAddressCity__c'));
                primaryMember.put('State', (String)census_member.get('ARC_PhysicalAddressState__c'));
                primaryMember.put('Address', (String)census_member.get('ARC_PhysicalAddressStreet__c'));
                primaryMember.put('ZipCode', (String)census_member.get('ARC_PhysicalAddressZipCode__c'));
                primaryMember.put('Weight', (String)census_member.get('ARC_Weight__c'));
                primaryMember.put('DayOfBirth', (Date.valueOf((String)census_member.get('vlocity_ins__Birthdate__c'))).day());
                primaryMember.put('Height', (String)census_member.get('ARC_HeightFeet__c') + '\'' + (String)census_member.get('ARC_HeightInches__c'));
                primaryMember.put('Id', (String)census_member.get('Id'));
                //primaryMember.put('IsInactiveMember', (Boolean)census_member.get('IsInactiveMember'));
                primaryMember.put('IsNewMember', (Boolean)census_member.get('IsNewMember'));
                primaryMember.put('IsRemoveMember', (Boolean)census_member.get('IsRemoveMember'));
                primaryMember.put('MonthOfBirth', (Date.valueOf((String)census_member.get('vlocity_ins__Birthdate__c'))).month());
                primaryMember.put('YearOfBirth', (Date.valueOf((String)census_member.get('vlocity_ins__Birthdate__c'))).year());
                primaryMember.put('DOB', (String)census_member.get('vlocity_ins__Birthdate__c'));
                primaryMember.put('Email', (String)census_member.get('vlocity_ins__Email__c'));
                primaryMember.put('FirstName', (String)census_member.get('vlocity_ins__FirstName__c'));
                primaryMember.put('LastName', (String)census_member.get('vlocity_ins__LastName__c'));
                primaryMember.put('Gender', (String)census_member.get('vlocity_ins__Gender__c'));
                primaryMember.put('SocialSecurity', (String)census_member.get('vlocity_ins__SocialSecurityNumber__c'));
                MembersInfo.put('primaryMember', primaryMember);
            } else if (relationship == 'Spouse') {
                Map<String, Object> spouseMember = new Map<String, Object>();
                Object isPregnant_obj = census_member.get('ARC_isPregnant__c');
                spouseMember.put('Pregnant', isPregnant_obj != null && isPregnant_obj != '' ? (Boolean)isPregnant_obj : false);
                Object Smoker_obj = census_member.get('ARC_Smoker__c');
                spouseMember.put('Smoker', Smoker_obj != null && Smoker_obj != '' ? (Boolean)Smoker_obj : false);
                spouseMember.put('MI', (String)census_member.get('ARC_MiddleInitial__c'));
                spouseMember.put('Weight', (String)census_member.get('ARC_Weight__c'));
                spouseMember.put('Height', (String)census_member.get('ARC_HeightFeet__c') + '\'' + (String)census_member.get('ARC_HeightInches__c'));
                spouseMember.put('Id', (String)census_member.get('Id'));
                //spouseMember.put('IsInactiveMember', (Boolean)census_member.get('IsInactiveMember'));
                spouseMember.put('IsNewMember', (Boolean)census_member.get('IsNewMember'));
                spouseMember.put('IsRemoveMember', (Boolean)census_member.get('IsRemoveMember'));
                spouseMember.put('DOB', (String)census_member.get('vlocity_ins__Birthdate__c'));
                spouseMember.put('Email', (String)census_member.get('vlocity_ins__Email__c'));
                spouseMember.put('FirstName', (String)census_member.get('vlocity_ins__FirstName__c'));
                spouseMember.put('LastName', (String)census_member.get('vlocity_ins__LastName__c'));
                spouseMember.put('Gender', (String)census_member.get('vlocity_ins__Gender__c'));
                spouseMember.put('SocialSecurity', (String)census_member.get('vlocity_ins__SocialSecurityNumber__c'));
                MembersInfo.put('spouseMember', spouseMember);
            } else if (relationship == 'Child') {
                Map<String, Object> dependentMember = new Map<String, Object>();
                Object isPregnant_obj = census_member.get('ARC_isPregnant__c');
                dependentMember.put('Pregnant', isPregnant_obj != null && isPregnant_obj != '' ? (Boolean)isPregnant_obj : false);
                Object Smoker_obj = census_member.get('ARC_Smoker__c');
                dependentMember.put('Smoker', Smoker_obj != null && Smoker_obj != '' ? (Boolean)Smoker_obj : false);
                dependentMember.put('MI', (String)census_member.get('ARC_MiddleInitial__c'));
                dependentMember.put('Weight', String.valueOf(census_member.get('ARC_Weight__c')));
                dependentMember.put('Height', String.valueOf(census_member.get('ARC_HeightFeet__c')) + '\'' + String.valueOf(census_member.get('ARC_HeightInches__c')));
                dependentMember.put('Id', (String)census_member.get('Id'));
                //dependentMember.put('IsInactiveMember', (Boolean)census_member.get('IsInactiveMember'));
                dependentMember.put('IsNewMember', (Boolean)census_member.get('IsNewMember'));
                dependentMember.put('IsRemoveMember', (Boolean)census_member.get('IsRemoveMember'));
                dependentMember.put('DOB', (String)census_member.get('vlocity_ins__Birthdate__c'));
                dependentMember.put('Email', (String)census_member.get('vlocity_ins__Email__c'));
                dependentMember.put('FirstName', (String)census_member.get('vlocity_ins__FirstName__c'));
                dependentMember.put('LastName', (String)census_member.get('vlocity_ins__LastName__c'));
                dependentMember.put('Gender', (String)census_member.get('vlocity_ins__Gender__c'));
                dependentMember.put('SocialSecurity', (String)census_member.get('vlocity_ins__SocialSecurityNumber__c'));
                dependentMembers.add(dependentMember);
            }

        }
        if (!dependentMembers.isEmpty()) {
            MembersInfo.put('dependentMembers', dependentMembers);
        }
        System.debug('MembersInfo: ' + MembersInfo);

        // Adapt Payment Step in DocuSign Map to PC DocuSign class so information is correctly populated in DS
        Map<String,Object> pcChangesMap = (Map<String, Object>)DocuSignMap.get('pcChanges');
        // Map<String,Object> pcChangesMap = (Map<String, Object>)DocuSignMap.get('nbChanges');

        // ((Map<String, Object>)((Map<String, Object>)DocuSignMap.get('Step_PaymentChangeFee')).get('BLK_ChargeFee')).put('RAD_KeepRecurringMethodOfPayment', 'No');
        // (((Map<String, Object>)DocuSignMap.get('Step_PaymentChangeFee'))).put('RAD_ChargeAppFeeDefTrue', 'Yes');

        //Testing values
        // pcChangesMap.put('feeAmount', 0);
        // System.debug('Updated DocuSign Map: ' + DocuSignMap);
        // System.debug('pc changes map : ' + pcChangesMap);


        inputMapDSTrans.put('MembersInfo', MembersInfo);
        inputMapDSTrans.put('DocuSign', DocuSignMap);
        inputMapDSTrans.put('EffectiveDate', (String)inputMap.get('effectiveDate'));
        inputMapDSTrans.put('pcChanges', pcChangesMap);
        inputMapDSTrans.put('allMembersInfo', census_members);
        inputMapDSTrans.put('primaryState', primaryState);
        
        Map<String, Object> newMedicalProduct = new Map<String, Object>();
        List<Object> productList = (List<Object>)DocuSignMap.get('NewProductList');
        for (Object product_obj : productList) {
            Map<String, Object> product = (Map<String, Object>)product_obj;
            Map<String, Object> selectedProduct = (Map<String, Object>)product.get('selectedProduct');
            if (selectedProduct.get('Type__c') == 'Medical') {
                newMedicalProduct.put('selectedProduct', selectedProduct);
                break;
            }
        }
        if (newMedicalProduct.containsKey('selectedProduct')) {
            inputMapDSTrans.put('newMedicalProduct', newMedicalProduct);
        }
        inputMapDSTrans.put('UpdateType', 'Add Newborn');
        Map<String,Object> outputMapDSTrans = new Map<String,Object>();

        ARC_ProgramChange_DocuSign.DocuSignDataTransform(inputMapDSTrans, outputMapDSTrans, new Map<String,Object>());
        outputMap.put('RAresponse', outputMapDSTrans);
    }



        /**
    * Method to transform data of member family and send it to calculate price lwc
     * @param {Map<String,Object>} inputMap - The input map.
     * @param {Map<String,Object>} outputMap - The output map.
     * @param {Map<String,Object>} options - The options map.
     * @returns {Map<String,Object>} - The output map.
    */
    public static Map<String,Object> TRANSFORM_ChooseProductSelectionData(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        List<Object> oldProducts = (List<Object>)inputMap.get('oldProducts');
        List<Object> userInputs = (List<Object>)inputMap.get('userInputs'); 
        Map<String,Integer> ageMembersMap = getOldestAgeMap(userInputs);
        Integer oldestMemberAge = (Integer)ageMembersMap.get('oldestAge');

        if (oldProducts != null && !oldProducts.isEmpty()) {
            String oldestMemberRelationShip;
            List<Map<String,Object>> products_list = new List<Map<String,Object>>();
            for (Object product_object : oldProducts) {
                Set<String> newMemberIds = new Set<String>();
                Map<String,Object> product = (Map<String,Object>)product_object;
                
                Map<String, Object> product_map = new Map<String, Object>{'selectedProduct' => new Map<String,Object>{'Id' => (String)product.get('productId')}, 'userInputs' => new List<Map<String,Object>>()};

                Boolean hasPrimary = false;
                Boolean hasOldestMember = false;

                // We need to count relationship member per product to set coverage on Ancillaries
                Integer countPrimary = 0;
                Integer countSpouse = 0;
                Integer countChilds = 0;

                for (Object user_input_object : userInputs) {
                    Map<String,Object> user_input = new Map<String,Object>((Map<String,Object>)user_input_object);

                    for (Object census_member_object : (List<Object>)product.get('census_members')) {
                        Map<String,Object> census_member = (Map<String,Object>)census_member_object;
                        //Add the userInput if the member that we are in the loop of UserInput is included and has the product.
                        if ((String)user_input.get('Id') == (String)census_member.get('Id')) {
                            if ((Boolean)user_input.get('RF_Census.CM_IsPrimary') == true) hasPrimary = true;
                            if ((Integer)user_input.get('RF_Census.CM_Age') == oldestMemberAge) {
                                oldestMemberRelationShip= (String)user_input.get('RF_Census.CM_Relationship');
                                hasOldestMember=true;
                            }
                            user_input.put('RF_Census.CRF_PrimaryMemberAge',oldestMemberAge);
                            ((List<Map<String,Object>>)product_map.get('userInputs')).add(user_input);
                        }
                        // Add newborns only to Medical plans 
                        else if ((Boolean)user_input.get('IsNewMember') == true && !newMemberIds.contains((String)user_input.get('Id')) && (String)product.get('Type__c') == 'Medical') {
                            user_input.put('RF_Census.CRF_PrimaryMemberAge',oldestMemberAge);
                            ((List<Map<String,Object>>)product_map.get('userInputs')).add(user_input);
                            newMemberIds.add((String)user_input.get('Id'));
                        }
                    }
                }

                if((String)product.get('Type__c') == 'Ancillary'){
                    for(Object census_Member_object : (List<Map<String,Object>>)product_map.get('userInputs')){
                        Map<String,Object> census_Member = (Map<String,Object>)census_Member_object;
                            
                        if((String)census_Member.get('RF_Census.CM_Relationship') == 'Primary'){
                            countPrimary ++;
                        } else if ((String)census_Member.get('RF_Census.CM_Relationship') == 'Spouse'){
                            countSpouse ++;
                        } else if((String)census_Member.get('RF_Census.CM_Relationship') == 'Child'){
                            countChilds ++;
                        }
                    }
                }

                //Adjust the Oldest Member Age AND Primary Member on the procut if the Primary is not inlcuded or if the oldest member is not included. OR is Ancillary Product
                if((String)product.get('Type__c') == 'Ancillary'){
                    for(Object census_Member_object : (List<Map<String,Object>>)product_map.get('userInputs')){
                        Map<String,Object> census_Member_instance = (Map<String,Object>)census_Member_object;
                        if(!hasPrimary){
                            if((String)census_Member_instance.get('RF_Census.CM_Relationship') == 'Spouse'){
                                census_Member_instance.put('RF_Census.CM_IsPrimary',true);
                            }
                        }
                        if(!hasOldestMember){
                            if(oldestMemberRelationShip == 'Primary'){
                                census_Member_instance.put('RF_Census.CRF_PrimaryMemberAge',(Integer)ageMembersMap.get('Spouse'));
                            }
                            else{
                                census_Member_instance.put('RF_Census.CRF_PrimaryMemberAge',(Integer)ageMembersMap.get('Primary'));
                            }
                        }
                        // Set Coverages for Anillaries
                        // if ((String)product.get('Type__c') == 'Ancillary') {

                        if((countPrimary == 1 && countSpouse == 0 && countChilds == 0) || (countPrimary == 0 && countSpouse == 1 && countChilds == 0)){
                            census_Member_instance.put('RF_Census.CRF_Coverage','Primary');
                            census_Member_instance.put('RF_Census.CRF_CoverageAIDD','Primary');
                        } else if(countPrimary == 1 && countSpouse == 1 && countChilds == 0){ 
                            census_Member_instance.put('RF_Census.CRF_Coverage','Primary + Spouse');
                            census_Member_instance.put('RF_Census.CRF_CoverageAIDD','Primary + Spouse');
                        } else if((countPrimary == 1 && countSpouse == 0 && countChilds > 0) || (countPrimary == 0 && countSpouse == 1 && countChilds > 0)){
                            census_Member_instance.put('RF_Census.CRF_Coverage','Primary + Child');
                            census_Member_instance.put('RF_Census.CRF_CoverageAIDD','Primary + Children');
                        } else {
                            census_Member_instance.put('RF_Census.CRF_Coverage','Family');
                            census_Member_instance.put('RF_Census.CRF_CoverageAIDD','Family');
                        }
                            
                        // }
                    }
                }

                products_list.add(product_map);
            }
            outputMap.put('LWC_ChooseProductSelectionOutput', products_list);
        }
        return outputMap;
    }

    /*******************************************************************
    * @MethodName         :   populateReasons
    * @Description        :   method to populate the reasons of the contract based on the contract status
    ********************************************************************/
    public static Map<String,Object> populateReasons(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        String contractStatus = (String)inputMap.get('ContractStatus');

        Set<Id> setOrderId = new Set<Id>();

        Id recurringMonthlyOrderId = inputMap.containsKey('RecurringMonthlyOrderId') ? (Id)inputMap.get('RecurringMonthlyOrderId') : null;
        if (recurringMonthlyOrderId != null) setOrderId.add(recurringMonthlyOrderId);
    
        Id appFeeOrderId = inputMap.containsKey('AppFeeOrderId') ? (Id)inputMap.get('AppFeeOrderId') : null;
        if (appFeeOrderId != null) setOrderId.add(appFeeOrderId);
        
        Map<Id, ChargentOrders__ChargentOrder__c> mapChargentOrders = new Map<Id, ChargentOrders__ChargentOrder__c>([SELECT Id, ChargentOrders__Charge_Date__c, ChargentOrders__Bank_Routing_Number__c, ChargentOrders__Bank_Account_Number__c, ChargentOrders__Bank_Account_Type__c, ChargentOrders__Bank_Name__c, ChargentOrders__Billing_First_Name__c, ARC_FirstMonthPayed__c, ChargentOrders__Billing_Last_Name__c, ChargentOrders__Billing_Address__c, ChargentOrders__Billing_City__c, ChargentOrders__Billing_State__c, ChargentOrders__Billing_Zip_Postal__c, ChargentOrders__Card_Expiration_Month__c, ChargentOrders__Card_Expiration_Year__c, ChargentOrders__Card_Last_4__c, ChargentOrders__Card_Month_Indicator__c, ChargentOrders__Card_Number__c, ChargentOrders__Card_Type__c, ChargentOrders__Card_Year_Indicator__c, ChargentOrders__Charge_Amount__c, ChargentOrders__Description__c, ChargentOrders__Gateway__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Payment_Method__c, ChargentOrders__Payment_Status__c, ChargentOrders__Subtotal__c, ChargentOrders__Manual_Charge__c, ChargentOrders__Tokenization__c FROM ChargentOrders__ChargentOrder__c WHERE Id IN :setOrderId LIMIT 2]);

        ChargentBase__Chargent_Settings__c feeAmounts = [SELECT Id, Name, ARC_UpgradeChangeFee__c, ARC_AddMemberChangeFee__c,ARC_DowngradeChangeFee__c, ARC_AppFee__c FROM ChargentBase__Chargent_Settings__c LIMIT 1];
        //Decimal addMemberFee = feeAmounts.ARC_AddMemberChangeFee__c;
        //Decimal upgradeFee = feeAmounts.ARC_UpgradeChangeFee__c;
        //Decimal downgradeFee = feeAmounts.ARC_DowngradeChangeFee__c;
        
        Map<String, Object> nbReasons = new Map<String, Object> {
            'Add Newborn' => true
        };

        Boolean feeApplicable = false;
        Decimal feeAmount = 0;

        String nbReasonsString = 'Add Newborn; ';
        String nbFeeReasonsString = 'Add Newborn, ';

        if (inputMap.containsKey('GapInPermNB') && (Boolean)inputMap.get('GapInPermNB') == true) {
            feeApplicable = true;
            feeAmount = feeAmounts.ARC_AddMemberChangeFee__c;
        }

        if(inputMap.containsKey('ContractStatus') && contractStatus.contains('Awaiting')) { 
            String reasonsString = inputMap.containsKey('ContractReasons') ? (String)inputMap.get('ContractReasons') : null;

            if (reasonsString != null && reasonsString.contains('Add Ancillary Product')) {
                reasonsString = reasonsString.replace('Add Ancillary Product', 'Ancillary Change');
            }

            List<String> listReasons = reasonsString.contains(';') ? reasonsString.split(';') : new List<String>{reasonsString};
            for(String reason : listReasons) {
                if (reason != 'Add Newborn') {
                    nbReasons.put(reason, true);
                    nbReasonsString = nbReasonsString += reason + '; ';
                }
                if (reason == 'Add Member') {
                    feeApplicable = true;
                    nbFeeReasonsString += 'Add Member, ';
                    if (feeAmounts.ARC_AddMemberChangeFee__c > feeAmount) feeAmount = feeAmounts.ARC_AddMemberChangeFee__c;
                }
                if (reason == 'Program Upgrade') {
                    feeApplicable = true;
                    nbFeeReasonsString += 'Program Upgrade, ';
                    if (feeAmounts.ARC_UpgradeChangeFee__c > feeAmount) feeAmount = feeAmounts.ARC_UpgradeChangeFee__c;
                }
                if (reason == 'Program Downgrade') {
                    feeApplicable = true;
                    nbFeeReasonsString += 'Program Downgrade, ';
                    if (feeAmounts.ARC_DowngradeChangeFee__c > feeAmount) feeAmount = feeAmounts.ARC_DowngradeChangeFee__c;
                }
                if (reason == 'New Application') {
                    feeApplicable = true;
                    nbFeeReasonsString += 'New Application, ';
                    if (feeAmounts.ARC_AppFee__c > feeAmount) feeAmount = feeAmounts.ARC_AppFee__c;
                }
            }
        }

        Map<String,Object> nbReasonsOutput = new Map<String,Object> {
            'feeApplicable' => feeApplicable,
            'feeAmount' => feeAmount
        };

        if (nbReasonsString.endsWith('; ')) {
            nbReasonsString = nbReasonsString.substring(0, nbReasonsString.length() - 2);
        }

        if (nbFeeReasonsString.endsWith(', ')) {
            nbFeeReasonsString = nbFeeReasonsString.substring(0, nbFeeReasonsString.length() - 2);
        }

        if (nbFeeReasonsString != null) {
            String programSummaryFeeText = 'One Time Change Fee (' + nbFeeReasonsString + '): ' + (Decimal)nbReasonsOutput.get('feeAmount');
            nbReasonsOutput.put('programSummaryFeeText', programSummaryFeeText);
        }        

        nbReasonsOutput.put('nbReasons', nbReasons);
        nbReasonsOutput.put('nbReasonsString', nbReasonsString);
        outputMap.put('nbChanges', nbReasonsOutput);
        outputMap.put('mapChargentOrders', mapChargentOrders);
        return outputMap;
    }


    /////////////////////////////////////////////
    ////////Auxiliary methods/////////////////////
    /////////////////////////////////////////////

    /*******************************************************************
    * @MethodName         :   addQuestionResponse
    * @Description        :   Aux method to populate input fields for the medical questions omniscript if apply
    ********************************************************************/
    private static void addQuestionResponse(Map<String, List<Map<String, Object>>> questionMap, String blockName, String fieldName, Object value, String memberId) {
        if (value == null) {
            return; // Skip null values
        }
    
        // Get the list of responses for the block or create a new one if it does not exist
        if (!questionMap.containsKey(blockName)) {
            questionMap.put(blockName, new List<Map<String, Object>>());
        }
    
        List<Map<String, Object>> responses = questionMap.get(blockName);
    
        // Check if a response already exists for the same member
        Map<String, Object> response = null;
        for (Map<String, Object> existingResponse : responses) {
            if (existingResponse.containsKey('memberId') && existingResponse.get('memberId') == memberId) {
                response = existingResponse;
                break;
            }
        }
    
        // If no response is found for this member, create a new one
        if (response == null) {
            response = new Map<String, Object>();
            response.put('memberId', memberId); // Store the member identifier
            
            responses.add(response);
        }
    
        // Add the new field to the same object in the list
        response.put(fieldName, value);
    }


    /*******************************************************************
    * @MethodName         :   addMemberNameToMedicalQuestions
    * @Description        :   Aux method to populate member name fields on Medical Questions Omniscript
    ********************************************************************/
    private static void addMemberNameToMedicalQuestions(Map<String, Object> memberMap, Map<String, List<Map<String, Object>>> questionsMap, List<Object> selectCensusMemberList ) {
        String fullName = (String) memberMap.get('vlocity_ins__FirstName__c') + ' ' + (String) memberMap.get('vlocity_ins__LastName__c');
        String memberId = (String) memberMap.get('Id');
        String memberBirthDate = (String) memberMap.get('vlocity_ins__Birthdate__c');

        // Generic responses that apply to all members name fields
        addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'TXT_MemberParentDiagnosed', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_ParentSiblingDiagnosed', 'TXT_MemberIdParentDiagnosed', memberId, memberId);
        addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'TXT_MemberUnexpectedSymptoms', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_UnexpectedSymptoms', 'TXT_MemberIdUnexpectedSymptoms', memberId, memberId);
        addQuestionResponse(questionsMap, 'BLK_PendingTests', 'TXT_MemberPendingTests', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_PendingTests', 'TXT_MemberIdPendingTests', memberId, memberId);
        addQuestionResponse(questionsMap, 'BLK_Addictions', 'TXT_MemberAddictions', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_Addictions', 'TXT_MemberIdAddictions', memberId, memberId);
        addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'TXT_MemberLicenceSuspended', fullName, memberId);
        addQuestionResponse(questionsMap, 'BLK_LicenceSuspended', 'TXT_MemberIdLicenceSuspended', memberId, memberId);
        addQuestionResponse(questionsMap, 'EB_PastConditions', 'TXT_MemberPastConditions', fullName, memberId);
        addQuestionResponse(questionsMap, 'EB_PastConditions', 'TXT_MemberIdPastConditions', memberId, memberId);
        addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_CensusMemberName', fullName, memberId);
        //addQuestionResponse(questionsMap, 'EB_Physicians', 'TXT_CensusMemberId', memberId, memberId);

        Map<String, Object> selectMemberDetail = new Map<String, Object>();
        selectMemberDetail.put('CensusMemberName', fullName);
        selectMemberDetail.put('CensusMemberId', memberId);
        selectMemberDetail.put('Birthdate', memberBirthDate);

        selectCensusMemberList.add(selectMemberDetail);
    }

    // Custom comparator class to sort by relationship
    private class RelationshipComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            String relationshipA = (String)a.get('RF_Census.CM_Relationship');
            String relationshipB = (String)b.get('RF_Census.CM_Relationship');
            
            // Primary comes first (value = 1)
            if (relationshipA == 'Primary' && relationshipB != 'Primary') return -1;
            if (relationshipA != 'Primary' && relationshipB == 'Primary') return 1;
            
            // If both are Primary or neither is Primary, Spouse comes before Child (value = 2)
            if (relationshipA == 'Spouse' && relationshipB == 'Child') return -1;
            if (relationshipA == 'Child' && relationshipB == 'Spouse') return 1;
            
            // If same relationship, maintain original order
            return 0;
        }
    }

    private static Map<String,Integer> getOldestAgeMap(List<Object> userInputs){
        Map<String,Integer> ageMap = new Map<String,Integer>();
        Integer oldestAge = 0;
        for (Object user_input_object : userInputs) {
            Map<String,Object> user_input = (Map<String,Object>)user_input_object;
            if (user_input.containsKey('RF_Census.CM_Age') && user_input.get('RF_Census.CM_Age')!= null) {
                if((Integer)user_input.get('RF_Census.CM_Age')>oldestAge){
                    oldestAge = (Integer)user_input.get('RF_Census.CM_Age');
                }
                if(user_input.containsKey('RF_Census.CM_Relationship') && ((String)user_input.get('RF_Census.CM_Relationship') == 'Primary' || (String)user_input.get('RF_Census.CM_Relationship') == 'Spouse')){
                    ageMap.put((String)user_input.get('RF_Census.CM_Relationship'),(Integer)user_input.get('RF_Census.CM_Age'));
                }
            }
        }
        ageMap.put('oldestAge',oldestAge);
        return ageMap;
    }

    private static Set<Id> getContractMemberIds(Id contractId, Id censusId, Boolean isSpinOff) {
        Set<Id> censusMemberIds = new Set<Id>();
        if (isSpinOff == true) {
            for (vlocity_ins__GroupCensusMember__c member : [
                SELECT Id
                FROM vlocity_ins__GroupCensusMember__c
                WHERE vlocity_ins__CensusId__c = :censusId
            ]) {
                censusMemberIds.add(member.Id);
            }
        } else {
            for (ARC_ContractParticipant__c participant : [
                SELECT Id, ARC_PersonAccount__r.Census_Member__c 
                FROM ARC_ContractParticipant__c 
                WHERE ARC_Contract__c = :contractId
            ]) {
                if (participant.ARC_PersonAccount__r != null && participant.ARC_PersonAccount__r.Census_Member__c != null) {
                    censusMemberIds.add(participant.ARC_PersonAccount__r.Census_Member__c);
                }
            }
        }
        return censusMemberIds;
    }

    private static Map<String, Object> createMemberMap (vlocity_ins__GroupCensusMember__c member, Map<Id, String> censusMemberRelationshipMap, Boolean isSpinOff) {
        String address = String.join(new List<String>{member.ARC_PhysicalAddressStreet__c, member.ARC_PhysicalAddressCity__c, member.ARC_PhysicalAddressState__c, member.ARC_PhysicalAddressZipCode__c}, ', ');

        System.debug('Is Spin Off:' + isSpinOff);
        String relationship = isSpinOff == true ? member.ARC_Relationship__c : censusMemberRelationshipMap.get(member.Id);
        System.debug('Member Relationship: ' + relationship);

        Map<String, Object> memberMap = new Map<String, Object>{
            'Id' => member.Id,
            'vlocity_ins__FirstName__c' => member.vlocity_ins__FirstName__c,
            'vlocity_ins__LastName__c' => member.vlocity_ins__LastName__c,
            'PersonAccountId' => member.vlocity_ins__ContactId__r.AccountId,
            'PersonContactId' => member.vlocity_ins__ContactId__c,
            'vlocity_ins__MemberIdentifier__c' => member.vlocity_ins__MemberIdentifier__c,
            'ARC_MiddleInitial__c' => member.ARC_MiddleInitial__c,
            'vlocity_ins__Birthdate__c' => member.vlocity_ins__Birthdate__c,
            'vlocity_ins__IsPrimaryMember__c' => relationship == 'Primary',
            'ARC_Age__c' => member.ARC_Age__c,
            'vlocity_ins__SocialSecurityNumber__c' => member.vlocity_ins__SocialSecurityNumber__c,
            'showSSN' => 'password',
            'ARC_HeightFeet__c' => member.ARC_HeightFeet__c,
            'ARC_HeightInches__c' => member.ARC_HeightInches__c,
            'ARC_Weight__c' => member.ARC_Weight__c,
            'ARC_Smoker__c' => member.ARC_Smoker__c,
            'ARC_PhysicalAddressCity__c' => member.ARC_PhysicalAddressCity__c,
            'ARC_PhysicalAddressState__c' => member.ARC_PhysicalAddressState__c,
            'ARC_PhysicalAddressStreet__c' => member.ARC_PhysicalAddressStreet__c,
            'ARC_PhysicalAddressZipCode__c' => member.ARC_PhysicalAddressZipCode__c,
            'ARC_Address__c' => address,
            'IsDependent' => relationship != 'Primary',
            'individual_errors' => new List<String>(),
            'IsNewMember' => false,
            'IsRemoveMember' => false,
            'ShowMember' => true,
            'DISABLE_PRIMARY_ADDRESS_AND_COPY_ADDRESS' => false,
            'DISABLE_INPUT_FIELDS' => false,
            'ARC_Phone__c' => member.ARC_Phone__c,
            'vlocity_ins__Email__c' =>member.vlocity_ins__Email__c,
            'ARC_isPregnant__c' => member.ARC_isPregnant__c,
            'ARC_Relationship__c' => relationship,
            'vlocity_ins__Gender__c' => member.vlocity_ins__Gender__c
        };

        return memberMap;
    }

    /**
     * Set the member future age from effective date +60 days
     * @param Date Birthdate of Member
     * @param Date New Effective Date + 60 days or a target date
     * @returns Integer
     */
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