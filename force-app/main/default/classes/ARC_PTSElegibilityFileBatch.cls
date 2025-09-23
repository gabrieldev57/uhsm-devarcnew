global  with sharing class ARC_PTSElegibilityFileBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    private String UHSM_fulfillmentStringTXT;
    private String UHSM_reFulfillmentStringTXT;
    private String WeShare_reFulfillmentStringTXT;
    private String WeShare_fulfillmentStringTXT;
    private String Access_reFulfillmentStringTXT;
    private String Access_fulfillmentStringTXT;
    private String WeShare_reFullfillment_IDcardStringTXT;
    private String Access_reFullfillment_IDcardStringTXT;
    private String UHSM_reFullfillment_IDcardStringTXT;
    private String WeShare_DentalStringTXT;
    private String Legacy_fulfillmentStringTXT;
    private String Legacy_reFulfillmentStringTXT;
    private String Legacy_reFulfillment_IDcardStringTXT;

    private Id productRecordType;
    private Id coverageRecordType;

    public Set<Id> reFulfillmentCensusIds = new Set<Id>();
    public Set<Id> dentalCensusIds = new Set<Id>();

    public Set<Id> useThisCensuses = new Set<Id>();
    private Set<Id> finallyUsedRefulfillmentCensusIds = new Set<Id>();
    private Set<Id> finallyUsedDentalCensusIds = new Set<Id>();
    
    Datetime oggi = Datetime.now();
    private Datetime lastDate;

    public boolean testMode = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    public String sendToEmail = '';

    RecordType refullfilmentRecordType = [ SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_ResendMemberIdCard' AND SobjectType = 'Case' LIMIT 1 ] ;
    RecordType dentalRecordType = [ SELECT Id FROM RecordType WHERE DeveloperName = 'ARC_ResendDentalCard' AND SobjectType = 'Case' LIMIT 1 ] ;
    
    List<ARC_Eligible_Files__c> elegibleFiles =  [ SELECT Name, ARC_LastSent_Datetime__c FROM ARC_Eligible_Files__c WHERE Name = 'ReFulfillment' OR Name = 'Fulfillment'] ;
    
    List<Case> refulfillmentCases = [ 
        SELECT Id, ARC_CensusMember__r.vlocity_ins__CensusId__c, ARC_WelcomeKit__c
        FROM Case 
        WHERE Status = 'New' AND 
        RecordTypeId = :refullfilmentRecordType.Id
    ];

    List<Case> dentalCases = [ 
        SELECT Id, ARC_CensusMember__r.vlocity_ins__CensusId__c, ARC_WelcomeKit__c
        FROM Case 
        WHERE Status = 'New' AND 
        RecordTypeId = :dentalRecordType.Id
    ];

    global ARC_PTSElegibilityFileBatch(){

        getRecordTypes();
        generateHeaders();
        
        
        for (ARC_Eligible_Files__c file : this.elegibleFiles) {
            if (file.Name == 'Fulfillment') {
                this.lastDate = file.ARC_LastSent_Datetime__c;
            }
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        string s = '';
        for (Case r : refulfillmentCases) s += '\n' + r;
        system.debug(s);
        
        for ( Case c : this.refulfillmentCases ) {  
            this.reFulfillmentCensusIds.add(c.ARC_CensusMember__r.vlocity_ins__CensusId__c);
            system.debug('Case Id:' + c.Id);
        }
        for ( Case c : this.dentalCases ) {  
            this.dentalCensusIds.add(c.ARC_CensusMember__r.vlocity_ins__CensusId__c);
        }
        
        // Create a list of contracts, which have a recurring monthly order that has an approved charge (ie non-refund) transaction
        List<Contract> contracts = [ 
            SELECT vlocity_ins__EnrollmentCensusId__c, ARC_AwaitingActivationDate__c, ARC_RecurringMonthlyOrder__c, vlocity_ins__LastDocuSignEnvelopeId__c
            FROM Contract
            WHERE (Status = 'Activated' OR Status = 'Awaiting Activation') 
                AND ARC_RecurringMonthlyOrder__r.ARC_FirstMonthPayed__c = true
        ];
        
        //Create a list of census ids extracted from the list of contracts
        Set<Id> censusIds = new Set<Id>();
        for ( Contract contract : contracts ) {
            censusIds.add(contract.vlocity_ins__EnrollmentCensusId__c);
        } 
        
        if (this.useThisCensuses.size() > 0) {
            return Database.getQueryLocator('SELECT Id FROM vlocity_ins__GroupCensus__c WHERE Id IN :useThisCensuses');
        }else {
            return Database.getQueryLocator('SELECT Id FROM vlocity_ins__GroupCensus__c WHERE Id IN :censusIds OR Id IN :reFulfillmentCensusIds OR Id IN :dentalCensusIds');
        }
    }
    
    global void execute(Database.BatchableContext BC, List<vlocity_ins__GroupCensus__c> censuses) {
        //Get all the "Awaiting Activation" and "Activated" Contracts related to the `vlocity_ins__GroupCensus__c`.
        System.debug('Execute');
        List<Contract> contracts_nonFiltered = [ 
            SELECT Id,vlocity_ins__EnrollmentCensusId__c,ARC_EffectiveDate__c,Status, vlocity_ins__LastDocuSignEnvelopeId__c,
                ARC_ContractReason__c,ARC_SingleReasonForPC__c,ARC_Case__c,ARC_AwaitingActivationDate__c,
                ARC_RecurringMonthlyOrder__c 
            FROM Contract 
            WHERE (Status = 'Activated' OR (Status = 'Awaiting Activation' AND ARC_RecurringMonthlyOrder__r.ARC_FirstMonthPayed__c = true)) 
            AND vlocity_ins__EnrollmentCensusId__c IN :censuses ORDER BY ARC_EffectiveDate__c DESC];
        List<Contract> fulfillmentContracts = new List<Contract>();  
        List<Contract> reFulfillmentContracts = new List<Contract>();  
        List<Contract> dentalContracts = new List<Contract>();
        List<RecordType> recordTypes = [ SELECT Id,DeveloperName FROM RecordType WHERE DeveloperName = 'CoverageSpec' OR DeveloperName = 'Product' ] ;
        List<vlocity_ins__ContractLineItem__c> allProducts = new List<vlocity_ins__ContractLineItem__c>();
        List<vlocity_ins__ContractLineItem__c> medicalProducts = new List<vlocity_ins__ContractLineItem__c>();
        List<vlocity_ins__ContractLineItem__c> smartProducts = new List<vlocity_ins__ContractLineItem__c>();
        List<vlocity_ins__ContractLineItem__c> aiddProducts = new List<vlocity_ins__ContractLineItem__c>();
        
        List<vlocity_ins__GroupCensusMember__c> fulfillmentMembers = new List<vlocity_ins__GroupCensusMember__c>();
        List<vlocity_ins__GroupCensusMember__c> reFulfillmentMembers = new List<vlocity_ins__GroupCensusMember__c>();
        List<ARC_UnderwritingCaseMember__c> underwritingCaseMembers = new List<ARC_UnderwritingCaseMember__c>();
        List<vlocity_ins__GroupCensusMember__c> allMembers = new List<vlocity_ins__GroupCensusMember__c>();

        Set<Id> fulfillmentContractsIds = new Set<Id>();
        Set<Id> repeatedCensusIds = new Set<Id>();
        Set<Id> nonRepeatedCensusIds = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        Set<Id> fulfillmentMemberIds = new Set<Id>();
        Set<Id> medicalProductsIds = new Set<Id>();

        Map<Id,Boolean> contract_sendWelcomeKit = new Map<Id,Boolean>();
        Map<Id, String> contract_AMCS = new Map<Id, String>();
        Map<Id, vlocity_ins__ContractLineItem__c> contract_medicalProduct = new Map<Id,vlocity_ins__ContractLineItem__c>();
        Map<Id, Datetime> contract_firstPayment = new Map<Id, Datetime>();
        Map<Id, List<vlocity_ins__GroupCensusMember__c>> contractMembers = new Map<Id, List<vlocity_ins__GroupCensusMember__c>>();
        Map<Id, String> smartProductMap = new Map<Id, String>();
        Map<Id, String> aiddProductMap = new Map<Id, String>();

        for ( vlocity_ins__GroupCensus__c census : censuses ) {
            Integer countRelated = 0;
            for ( Contract contract : contracts_nonFiltered ) {
                if ( contract.vlocity_ins__EnrollmentCensusId__c == census.Id ) {
                    countRelated++;
                }
            }
            if ( countRelated>1 ) {
                repeatedCensusIds.add(census.Id);
            }else{
                nonRepeatedCensusIds.add(census.Id);
            }
        }

        // Separate contracts_nonFiltered into fulfillmentContracts, reFulfillmentContracts and dentalContracts.
        for ( vlocity_ins__GroupCensus__c census : censuses ) {
            List<Contract> posibleFulfillmentContracts = new List<Contract>();
            for ( Contract contract : contracts_nonFiltered ) {
                if ( contract.vlocity_ins__EnrollmentCensusId__c == census.Id ) {
                    if ( this.reFulfillmentCensusIds.contains(contract.vlocity_ins__EnrollmentCensusId__c) ) {
                        reFulfillmentContracts.add(contract);
                    }
                    if ( this.dentalCensusIds.contains(contract.vlocity_ins__EnrollmentCensusId__c) ) {
                        dentalContracts.add(contract);
                    }
                    if ( nonRepeatedCensusIds.contains(census.Id) && contract.ARC_ContractReason__c != null) {
                        if ( contract.ARC_ContractReason__c.contains('New Application')) {
                            fulfillmentContracts.add(contract);
                            fulfillmentContractsIds.add(contract.Id);
                        }
                    }
                    if ( contract.ARC_ContractReason__c != null && (repeatedCensusIds.contains(census.Id) || Test.isRunningTest())) {
                        if ( contract.ARC_ContractReason__c.contains('New Application')){
                            posibleFulfillmentContracts.add(contract);
                        }
                    }
                }
                if ( posibleFulfillmentContracts.size() > 0 ) {
                    if (!fulfillmentContracts.contains(posibleFulfillmentContracts [ 0 ])) {
                        fulfillmentContracts.add(posibleFulfillmentContracts [ 0 ] );
                        fulfillmentContractsIds.add(posibleFulfillmentContracts [ 0 ] .Id);
                    }
                }
            }
        }

        for ( Contract contract : contracts_nonFiltered ) {
            orderIds.add(contract.ARC_RecurringMonthlyOrder__c);
        }

        allProducts = [ 
            SELECT vlocity_ins__Product2Id__c,
                vlocity_ins__ProductType__c, 
                vlocity_ins__ProductCode__c, 
                vlocity_ins__ContractId__c,
                vlocity_ins__Product2Id__r.vlocity_ins__AttributeDefaultValues__c,
            	vlocity_ins__Product2Id__r.ProductCode 
            FROM vlocity_ins__ContractLineItem__c 
            WHERE vlocity_ins__Product2Id__r.RecordTypeId = :this.productRecordType 
            AND vlocity_ins__ProductType__c IN ('Medical','Ancillary')
            AND vlocity_ins__ContractId__r.vlocity_ins__EnrollmentCensusId__c IN :censuses
        ];

        // Split the allProducts list into Medical,Smart,and AIDD lists   
        for (vlocity_ins__ContractLineItem__c prod : allProducts) {
            switch on prod.vlocity_ins__ProductType__c{
                when 'Medical'{ medicalProducts.add(prod);}
                when 'Ancillary'{
                    if (prod.vlocity_ins__ProductCode__c.contains('SMART')){
                    	smartProducts.add(prod);
                    } else {
                        aiddProducts.add(prod);
                    }
                }
            }
        }
        
		Set<Id> smartContractLineItemIds = new Set<Id>();
        for(vlocity_ins__ContractLineItem__c medicalProduct : medicalProducts){
            medicalProductsIds.add(medicalProduct.vlocity_ins__Product2Id__c);
        }

        //Link contracts with their related Medical product and AMCS coverage
        contract_medicalProduct = getContractMedicalProduct(medicalProducts, contracts_nonFiltered);
        contract_AMCS = getContractAMCS(medicalProducts, contracts_nonFiltered, medicalProductsIds);
        //Create a map with the contracts Id as keys and approved Date as value
        contract_firstPayment = getContractFirstPayment(orderIds);
        //Create a map with the contracts Id as keys and a Boolean that indicates if it's needed to send the welcome kit as value.
        contract_sendWelcomeKit = getContractSendWelcomeKit(reFulfillmentContracts, this.refulfillmentCases);
        //Create a map with the contract Id as key and a set of the members Ids as value
        contractMembers = getContractMembers(new Set<Id>(contract_medicalProduct.keySet()));
        //Create a map with the contract Id as key and the Ancillary Program Name as value
        smartProductMap = getContractAncillaryProduct(smartProducts, contracts_nonFiltered);
        aiddProductMap = getContractAncillaryProduct(aiddProducts, contracts_nonFiltered);


        /*---------------------------------------------------------------------------*/
        /*--------------------------------GENERATE FILES-----------------------------*/
        /*---------------------------------------------------------------------------*/

        //GENERATE FULFILLMENT FILES
        for ( Contract contract : fulfillmentContracts ) {
            if ( (contract_firstPayment.get(contract.Id) > this.lastDate || contract.ARC_AwaitingActivationDate__c > this.lastDate) 
                    && !Test.isRunningTest() ) {
            	if (contract_medicalProduct.get(contract.Id).vlocity_ins__ProductCode__c.contains('Legacy')) {
                    //LEGACY
                    this.Legacy_fulfillmentStringTXT = ARC_UHSMFulfillment.generate(this.Legacy_fulfillmentStringTXT, contract, 
                        contract_medicalProduct.get(contract.Id), contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id));   
                }else if (contract_medicalProduct.get(contract.Id).vlocity_ins__ProductCode__c.contains('WeShare')) {
                    //WESHARE
                    this.WeShare_fulfillmentStringTXT = ARC_UHSMFulfillment.generate(this.WeShare_fulfillmentStringTXT, contract, 
                        contract_medicalProduct.get(contract.Id), contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id));   
                }else if (contract_medicalProduct.get(contract.Id).vlocity_ins__ProductCode__c.contains('Access')){
                    //ACCESS
                    this.Access_fulfillmentStringTXT = ARC_UHSMFulfillment.generate(this.Access_fulfillmentStringTXT, contract, 
                        contract_medicalProduct.get(contract.Id), contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id));  
                }else {
                    //UHSM
                    this.UHSM_fulfillmentStringTXT = ARC_UHSMFulfillment.generate(this.UHSM_fulfillmentStringTXT, contract, 
                        contract_medicalProduct.get(contract.Id), contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id));   
                }
            }
        }

        //GENERATE RE-FULFILLMENT FILES
        System.debug('refulfillmentContracts:' + refulfillmentContracts.size());
        //System.debug('vlocity_ins__LastDocuSignEnvelopeId__c:' + refulfillmentContracts[0].vlocity_ins__LastDocuSignEnvelopeId__c);
        for ( Contract contract : reFulfillmentContracts ) {
            System.debug('refulfillment contract vlocity_ins__LastDocuSignEnvelopeId__c:' + contract.vlocity_ins__LastDocuSignEnvelopeId__c);
            System.debug('vlocity_ins__ProductCode__c: ' + contract_medicalProduct.get(contract.Id).vlocity_ins__ProductCode__c);
             if (contract_medicalProduct.get(contract.Id).vlocity_ins__ProductCode__c.contains('Legacy')) {
                //LEGACY            	
                if (contract_sendWelcomeKit.get(contract.Id)) {
                    System.debug('ARCSONA DEBUG: LEGACY CONTRACT_SENDWELCOMEKIT ');
                    //WELCOME KIT
                    this.Legacy_reFulfillmentStringTXT = ARC_UHSMFulfillment.generate(this.Legacy_reFulfillmentStringTXT, contract,
                        contract_medicalProduct.get(contract.Id),contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id)); 
                }else{
                    System.debug('ARCSONA DEBUG: LEGACY NO WELCOMEKIT- ID CARD ');
                    System.debug('ARCSONA DEBUG: this.Legacy_reFulfillment_IDcardStringTXT: '+this.Legacy_reFulfillment_IDcardStringTXT);
                    System.debug('ARCSONA DEBUG: contract: '+contract);
                    System.debug('ARCSONA DEBUG: contract: '+contract);
                    System.debug('ARCSONA DEBUG: contract_medicalProduct: '+contract_medicalProduct);
                    System.debug('ARCSONA DEBUG: contract_medicalProductgetContractId: '+contract_medicalProduct.get(contract.Id));
                    System.debug('ARCSONA DEBUG: contractMembers: '+contractMembers);
                    System.debug('ARCSONA DEBUG: contractMembersgetContractId: '+contractMembers.get(contract.Id));
                    System.debug('ARCSONA DEBUG: smartProductMap: '+smartProductMap);
                    System.debug('ARCSONA DEBUG: aiddProductMap: '+aiddProductMap);
                    System.debug('ARCSONA DEBUG: contract_AMCS: '+contract_AMCS);
                    System.debug('ARCSONA DEBUG: smartProductMapgetId: '+smartProductMap.get(contract.Id));
                    System.debug('ARCSONA DEBUG: aiddProductMapgetContractId: '+aiddProductMap.get(contract.Id));
                    System.debug('ARCSONA DEBUG: contract_AMCSGetContractID: '+contract_AMCS.get(contract.Id));

                    //NO WELCOME KIT
                    this.Legacy_reFulfillment_IDcardStringTXT = ARC_UHSMFulfillment.generate(this.Legacy_reFulfillment_IDcardStringTXT, contract, 
                        contract_medicalProduct.get(contract.Id), contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id));
                }
                this.finallyUsedRefulfillmentCensusIds.add(contract.vlocity_ins__EnrollmentCensusId__c);
            }else if (contract_medicalProduct.get(contract.Id).vlocity_ins__ProductCode__c.contains('WeShare')) {
                //WESHARE            	
                if (contract_sendWelcomeKit.get(contract.Id)) {
                    //WELCOME KIT
                    this.WeShare_reFulfillmentStringTXT = ARC_UHSMFulfillment.generate(this.WeShare_reFulfillmentStringTXT, contract,
                        contract_medicalProduct.get(contract.Id),contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id)); 
                }else{
                    //NO WELCOME KIT
                    System.debug('contract_medicalProduct size: '+contract_medicalProduct.size());
                    System.debug('contractMembers size: '+contractMembers.size());
                    System.debug('smartProductMap size: '+smartProductMap.size());
                    System.debug('aiddProductMap size: '+aiddProductMap.size());
                    System.debug('contract_AMCS size: '+contract_AMCS.size());
                    this.WeShare_reFullfillment_IDcardStringTXT = ARC_UHSMFulfillment.generate(this.WeShare_reFullfillment_IDcardStringTXT, contract, 
                        contract_medicalProduct.get(contract.Id), contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id));
                }
                this.finallyUsedRefulfillmentCensusIds.add(contract.vlocity_ins__EnrollmentCensusId__c);
            }else if (contract_medicalProduct.get(contract.Id).vlocity_ins__ProductCode__c.contains('Access')) {
                //ACCESS
                if (contract_sendWelcomeKit.get(contract.Id)) {
                    //WELCOME KIT
                    this.Access_reFulfillmentStringTXT = ARC_UHSMFulfillment.generate(this.Access_reFulfillmentStringTXT, contract, 
                        contract_medicalProduct.get(contract.Id),contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id)); 
                }else{
                    //NO WELCOME KIT
                    this.Access_reFullfillment_IDcardStringTXT = ARC_UHSMFulfillment.generate(this.Access_reFullfillment_IDcardStringTXT, contract, 
                        contract_medicalProduct.get(contract.Id),contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id));
                }
                this.finallyUsedRefulfillmentCensusIds.add(contract.vlocity_ins__EnrollmentCensusId__c);
            }else{
                //UHSM
                if (contract_sendWelcomeKit.get(contract.Id)) {
                    //WELCOME KIT
                    this.UHSM_reFulfillmentStringTXT = ARC_UHSMFulfillment.generate(this.UHSM_reFulfillmentStringTXT,contract,
                        contract_medicalProduct.get(contract.Id),contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id)); 
                }else{
                    //NO WELCOME KIT
                    this.UHSM_reFullfillment_IDcardStringTXT = ARC_UHSMFulfillment.generate(this.UHSM_reFullfillment_IDcardStringTXT, contract, 
                        contract_medicalProduct.get(contract.Id),contractMembers.get(contract.Id), smartProductMap.get(contract.Id),
                        aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id));
                }
                this.finallyUsedRefulfillmentCensusIds.add(contract.vlocity_ins__EnrollmentCensusId__c);
            }
        }

        // GENERATE DENTAL FILES
        for (Contract contract : dentalContracts){
            this.WeShare_DentalStringTXT = ARC_UHSMFulfillment.generate(this.WeShare_DentalStringTXT,contract,contract_medicalProduct.get(contract.Id),
                contractMembers.get(contract.Id), smartProductMap.get(contract.Id), aiddProductMap.get(contract.Id), contract_AMCS.get(contract.Id));
            this.finallyUsedDentalCensusIds.add(contract.vlocity_ins__EnrollmentCensusId__c);
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Create filename strings
        String[] prefixes = new String[]{'UHSM_Fulfillment_', 'UHSM_ReFulfillment_', 'UHSM_ReFulfillment_IDcard_', 
                                        'WeShare_Fulfillment_', 'WeShare_ReFulfillment_', 'WeShare_ReFulfillment_IDcard_', 
                                        'Access_Fulfillment_', 'Access_ReFulfillment_', 'Access_ReFulfillment_IDcard_',
                                        'WeShare_Dental_', 'Legacy_Fulfillment_', 'Legacy_ReFulfillment_', 'Legacy_Refulfillment_IDcard_'};
        
        String[] fileNames = new String[prefixes.size()];
        String formattedNow = System.now().format('YYYYMMdd', 'America/Los_Angeles');
        for (Integer i = 0; i < prefixes.size(); i++) {
            fileNames[i] = prefixes[i] + formattedNow + '.txt';
        }

        List<String> bodies = new List<String>{
            this.UHSM_fulfillmentStringTXT, this.UHSM_refulfillmentStringTXT, this.UHSM_reFullfillment_IDcardStringTXT,
            this.WeShare_fulfillmentStringTXT, this.WeShare_refulfillmentStringTXT, this.WeShare_reFullfillment_IDcardStringTXT,
            this.Access_fulfillmentStringTXT, this.Access_refulfillmentStringTXT, this.Access_reFullfillment_IDcardStringTXT,
            this.WeShare_DentalStringTXT, this.Legacy_fulfillmentStringTXT, this.Legacy_reFulfillmentStringTXT, this.Legacy_reFulfillment_IDcardStringTXT
        };
                
        if (this.sendToEmail != '' || Test.isRunningTest()) {
            if(Test.isRunningTest()) this.sendToEmail = 'integrations@uhsm.org';
            sendToEmail(bodies);
        }else{
            if (this.testMode) {
                try {
                        sendFiles(fileNames, 'ptsTEST/', bodies);
                    } catch (Exception e) {
                        System.debug('Error sending files: ' + e.getMessage());
                    }
            } else {   
                sendFiles(fileNames, 'PTS2025/', bodies);     
            }
        	
            //After sending the files, update the cases and the elegible files
            for ( Case cs : this.refulfillmentCases ) {
                if (this.finallyUsedRefulfillmentCensusIds.contains(cs.ARC_CensusMember__r.vlocity_ins__CensusId__c) ) {
                    cs.Status = 'Closed';
                }
            }
            for ( Case cs : this.dentalCases ) {
                if (this.finallyUsedDentalCensusIds.contains(cs.ARC_CensusMember__r.vlocity_ins__CensusId__c) ) {
                    cs.Status = 'Closed';
                }
            }
            for (ARC_Eligible_Files__c file : this.elegibleFiles) {
                if (file.Name == 'Fulfillment') {
                    file.ARC_LastSent_Datetime__c = this.oggi;
                }
            }                
        }
        //close all related tasks
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :this.dentalCases OR WhatId IN :this.refulfillmentCases];
        for (Task t : tasks) {
            t.Status = 'Completed';
        }
        update tasks;
        try {
            update this.dentalCases;
        } catch (Exception e) {
            System.debug('Error updating dental cases: ' + e.getMessage());
        }
        try {
            update this.refulfillmentCases;
        } catch (Exception e) {
            System.debug('Error updating refulfillment cases: ' + e.getMessage());
        }
        try {
            update this.elegibleFiles;
        } catch (Exception e) {
            System.debug('Error updating elegible files: ' + e.getMessage());
        }
    }
    
    private void getRecordTypes(){
        List<RecordType> recordTypes = [ SELECT Id,DeveloperName FROM RecordType WHERE DeveloperName = 'CoverageSpec' OR DeveloperName = 'Product' ] ;
        for ( RecordType rt : recordTypes ) {
            if ( rt.DeveloperName == 'CoverageSpec' ) {
                this.coverageRecordType = rt.Id;
            }else{
                this.productRecordType = rt.Id;
            }
        }
    }
        
    private void generateHeaders(){
        this.UHSM_fulfillmentStringTXT = 'IND|FAM|EMPLOYEE NAME|ID|Primary|Clinic|P1|PLANID|GROUPCODE|Smart|Aidd|E Date|ADDR1|ADDR2|CITY|STATE|ZIP|DEP NAME1|DEP NAME2|DEP NAME3|DEP NAME4|DEP NAME5|DEP NAME6|DEP NAME7|DEP NAME8';
        this.UHSM_reFulfillmentStringTXT = this.UHSM_fulfillmentStringTXT;
        this.UHSM_reFullfillment_IDcardStringTXT = this.UHSM_fulfillmentStringTXT;
        this.Access_fulfillmentStringTXT = this.UHSM_fulfillmentStringTXT;
        this.Access_reFulfillmentStringTXT = this.UHSM_fulfillmentStringTXT;
        this.Access_reFullfillment_IDcardStringTXT = this.UHSM_fulfillmentStringTXT;
        this.WeShare_reFulfillmentStringTXT = this.UHSM_fulfillmentStringTXT;
        this.WeShare_fulfillmentStringTXT = this.UHSM_fulfillmentStringTXT;
        this.WeShare_reFullfillment_IDcardStringTXT = this.UHSM_fulfillmentStringTXT;
        this.WeShare_DentalStringTXT = this.UHSM_fulfillmentStringTXT;
        this.Legacy_fulfillmentStringTXT = this.UHSM_fulfillmentStringTXT;
        this.Legacy_reFulfillmentStringTXT = this.UHSM_fulfillmentStringTXT;
        this.Legacy_reFulfillment_IDcardStringTXT = this.UHSM_fulfillmentStringTXT;
        
    }

    private Map<Id, vlocity_ins__ContractLineItem__c> getContractMedicalProduct( 
        List<vlocity_ins__ContractLineItem__c> medicalProducts, 
        List<Contract> contracts_nonFiltered){
        Set<Id> medicalProductsIds = new Set<Id>();
        Map<Id, vlocity_ins__ContractLineItem__c> contract_medicalProduct = new Map<Id, vlocity_ins__ContractLineItem__c>();
        for ( vlocity_ins__ContractLineItem__c medicalProduct : medicalProducts ) {
            medicalProductsIds.add(medicalProduct.vlocity_ins__Product2Id__c);
            for ( Contract contract : contracts_nonFiltered ) {
                if ( medicalProduct.vlocity_ins__ContractId__c == contract.Id ) {
                    contract_medicalProduct.put(contract.Id,medicalProduct);
                }
            }
        }
        return contract_medicalProduct;
    }
   
    private Map<Id, String> getContractAncillaryProduct(
        List<vlocity_ins__ContractLineItem__c> ancillaryProducts, 
        List<Contract> contracts_nonFiltered) {
        // Create a map of Contracts by Id for quick lookup
        Map<Id, Contract> contractMap = new Map<Id, Contract>(contracts_nonFiltered);
        Map<Id, String> contract_AncillaryProduct = new Map<Id, String>();
    
        for (vlocity_ins__ContractLineItem__c ancillaryProduct : ancillaryProducts) {
            // Check if the Contract Id exists in the map
            if (contractMap.containsKey(ancillaryProduct.vlocity_ins__ContractId__c)) {
                contract_AncillaryProduct.put(
                    ancillaryProduct.vlocity_ins__ContractId__c, 
                    ancillaryProduct.vlocity_ins__ProductCode__c
                );
            }
    }
    return contract_AncillaryProduct;
}

    //get contract amcs
    private Map<Id,String> getContractAMCS(List<vlocity_ins__ContractLineItem__c> medicalProducts, 
                                           List<Contract> contracts_nonFiltered, Set<Id> medicalProductsIds){
        
        Map<Id,String> contract_AMCS = new Map<Id,String>();
        List<vlocity_ins__ProductChildItem__c> coveragesPlans = [ 
            SELECT vlocity_ins__ParentProductId__c, 
            vlocity_ins__ChildProductName__c, 
            vlocity_ins__ChildProductId__r.vlocity_ins__AttributeDefaultValues__c 
            FROM vlocity_ins__ProductChildItem__c 
            WHERE vlocity_ins__ParentProductId__c IN :medicalProductsIds 
            AND vlocity_ins__ChildProductId__r.ProductCode = 'CS_General' 
        ];

        List<vlocity_ins__OverrideDefinition__c> overrideDefinitions = [
            SELECT 
            vlocity_ins__OverriddenProductChildItemId__r.vlocity_ins__ParentProductId__c, 
            vlocity_ins__OverriddenProductChildItemId__r.vlocity_ins__ChildProductName__c, 
            vlocity_ins__OverridingAttributeAssignmentId__r.vlocity_ins__AttributeDisplayName__c, 
            vlocity_ins__OverridingAttributeAssignmentId__r.vlocity_ins__Value__c 
            FROM vlocity_ins__OverrideDefinition__c 
            WHERE vlocity_ins__OverridingAttributeAssignmentId__r.vlocity_ins__AttributeDisplayName__c = 'AMCS' 
            AND vlocity_ins__OverriddenProductChildItemId__r.vlocity_ins__ChildProductId__r.ProductCode = 'CS_General' 
            AND vlocity_ins__OverriddenProductChildItemId__r.vlocity_ins__ParentProductId__c IN :medicalProductsIds 
        ] ;
        
        for ( vlocity_ins__OverrideDefinition__c overrideDefinition : overrideDefinitions ) {
            for ( vlocity_ins__ContractLineItem__c medicalProduct : medicalProducts ) {
                if ( overrideDefinition.vlocity_ins__OverriddenProductChildItemId__r.vlocity_ins__ParentProductId__c == medicalProduct.vlocity_ins__Product2Id__c ) {
                    for ( Contract contract : contracts_nonFiltered ) {
                        if ( medicalProduct.vlocity_ins__ContractId__c == contract.Id ) {
                            contract_AMCS.put(contract.Id, overrideDefinition.vlocity_ins__OverridingAttributeAssignmentId__r.vlocity_ins__Value__c);
                        }
                    }
                }
            }
        }
        
        for ( vlocity_ins__ProductChildItem__c coveragesPlan : coveragesPlans ) {
            for ( vlocity_ins__ContractLineItem__c medicalProduct : medicalProducts ) {
                if ( coveragesPlan.vlocity_ins__ParentProductId__c == medicalProduct.vlocity_ins__Product2Id__c ) {
                    for ( Contract contract : contracts_nonFiltered ) {
                        if ( medicalProduct.vlocity_ins__ContractId__c == contract.Id && contract_AMCS.get(contract.Id)==null) {
                            contract_AMCS.put(contract.Id, String.valueOf(((Map<String, Object>)JSON.deserializeUntyped(coveragesPlan.vlocity_ins__ChildProductId__r.vlocity_ins__AttributeDefaultValues__c)).get('AMCS')));
                        }
                    }
                }
            }
        }
        return contract_AMCS;
    }


    public Map<Id,Datetime> getContractFirstPayment(Set<Id> orderIds){
        //Get Chargent Orders with related transactions (Important: ordered by gateway date ASC)
        List<ChargentOrders__ChargentOrder__c> orders = [SELECT Id,ARC_Contract__c, ARC_Contract__r.ARC_EffectiveDate__c, 
                                                        ChargentOrders__Charge_Amount__c,ARC_Contract__r.ARC_TotalPrice__c, First_Approved_Transaction_Date__c
                                                        FROM ChargentOrders__ChargentOrder__c WHERE Id IN :orderIds];
        Map<Id,Datetime> contractTransaction = new Map<Id,Datetime>();
        //loop for each order
        for (ChargentOrders__ChargentOrder__c order : orders) {
            //loop for each related transaction
            for (ChargentOrders__Transaction__c transa : order.ChargentOrders__Transactions__r) {
                //if it's the recurring monthly payment
                if (contractTransaction.get(order.ARC_Contract__c)==null) {
                    contractTransaction.put(order.ARC_Contract__c, order.First_Approved_Transaction_Date__c);
                }
            }
        }

        return contractTransaction;
    }

    private static Map<Id,Boolean> getContractSendWelcomeKit(List<Contract> contracts, List<Case> refulfillmentCases){
        Map<Id,Boolean> contract_sendWelcomeKit = new Map<Id,Boolean>();
        for (Case cs : refulfillmentCases) {
            for (Contract contract : contracts) {
                if (cs.ARC_CensusMember__r.vlocity_ins__CensusId__c == contract.vlocity_ins__EnrollmentCensusId__c) {
                    contract_sendWelcomeKit.put(contract.Id, cs.ARC_WelcomeKit__c);
                }
            }
        }
        return contract_sendWelcomeKit;
    }

    private static Map<Id, List<vlocity_ins__GroupCensusMember__c>> getContractMembers(Set<Id> contractIds){
        System.debug('getContractMembers.contractIds size: '+ contractIds.size());
        Map<Id, List<vlocity_ins__GroupCensusMember__c>> contractMembers = new Map<Id, List<vlocity_ins__GroupCensusMember__c>>();
        List<vlocity_ins__GroupCensusMemberPlan__c> memberPlans = [ 
            SELECT Id,
            vlocity_ins__GroupCensusMemberId__r.Id,
            vlocity_ins__GroupCensusMemberId__r.Name,
            vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressState__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__FirstName__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__LastName__c,
            vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressCity__c,
            vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressStreet__c,
            vlocity_ins__GroupCensusMemberId__r.ARC_PhysicalAddressZipCode__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__CensusId__c,
            vlocity_ins__GroupCensusMemberId__r.ARC_Phone__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Email__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Birthdate__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__Gender__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__SocialSecurityNumber__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__IsPrimaryMember__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__IsSpouse__c,
            vlocity_ins__GroupCensusMemberId__r.Member_ID__c,
            vlocity_ins__GroupCensusMemberId__r.e123_member_id__c,
            vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c,
            vlocity_ins__GroupCensusMemberId__r.e123_member_id_from_policy__c, 
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c
            FROM vlocity_ins__GroupCensusMemberPlan__c 
            WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c IN :contractIds 
            	AND (vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Medical'
                     OR
                     vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = 'Ancillary')
        ];
        
        System.debug('getContractMembers.memberPlans size: '+ memberPlans.size());
        for (vlocity_ins__GroupCensusMemberPlan__c memberPlan : memberPlans) {            
            if (contractMembers.get(memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c) == null) {
                contractMembers.put(memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c, new List<vlocity_ins__GroupCensusMember__c>());
            }
            
          	if ( memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c == 'Medical' ){
            	contractMembers.get(memberPlan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c).add(memberPlan.vlocity_ins__GroupCensusMemberId__r);
            }
        }
        return contractMembers;
    }

    private void sendFiles(List<String> fileNames, String path, List<String> bodies){
        for (Integer i = 0; i < fileNames.size(); i++) {
            system.debug('filename:' + fileNames[i]);
            FTP2SF.FTP.put('UHSM',path+fileNames[i], Blob.valueOf(bodies[i]));
        }
    }

    private void sendToEmail( List<String> bodies ){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
        List<String> test_fileNames = new List<String>{
            'UHSM_Fulfillment_TEST.txt', 'UHSM_ReFulfillment_TEST.txt', 'UHSM_ReFulfillment_IDcard_TEST.txt',
            'WeShare_Fulfillment_TEST.txt', 'WeShare_ReFulfillment_TEST.txt', 'WeShare_ReFulfillment_IDcard_TEST.txt',
            'Access_Fulfillment_TEST.txt', 'Access_ReFulfillment_TEST.txt', 'Access_ReFulfillment_IDcard_TEST.txt', 
            'WeShare_Dental_TEST.txt','Legacy_Fulfillment_Test.txt','Legacy_ReFulfillment_Test.txt','Legacy_reFulfillment_IDcard_Test.txt'};
                    
        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        
        for (Integer i = 0; i < test_fileNames.size(); i++) {
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(test_fileNames[i]);
            attachment.setBody(Blob.valueOf(bodies[i]));
            attachments.add(attachment);
        }

        List<String> toAddresses = new List<String>();
        toAddresses.add(this.sendToEmail);
        email.setToAddresses( toAddresses );
        email.setPlainTextBody('Testing PTS Files');
        email.setFileAttachments(attachments);
        Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
    }

    @InvocableMethod(label = 'Run PTS File Batch' description = 'Runs the PTS File Batch' category = 'Elegibility Files')
    global static void runPTSBatch() {
        ARC_PTSElegibilityFileBatch a = new ARC_PTSElegibilityFileBatch();
        Database.executeBatch(a,10);
    }
}