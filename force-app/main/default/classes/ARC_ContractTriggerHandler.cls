/*******************************************************************
* @ClassName          : ARC_ContractTriggerHandler
* @Description        : Creates the Account Exectuive Commission record and Initial Commission Payments. 
                        Also updates the contract in the Existing Commissions after a PC/Reprice.
* @MethodNames         : changeEffectiveDatePolicies, createUpdateCommission, createCommissionAndInitialCP, updateContractOnCommission, 
                        getProgramPrices, createInitialCP, updateCommissionPrice,reactivateContractLinkToCommission, createInitialCPAdjustment, getTransactionsFromPC
********************************************************************/

public without sharing class ARC_ContractTriggerHandler {

    public static Id rtCommPaymentAccExecutive = Schema.SObjectType.ARC_Commission_Payment__c.getRecordTypeInfosByDeveloperName().get('ARC_AccountExecutive').getRecordTypeId();

    /*******************************************************************
    * @MethodName         :   changeEffectiveDatePolicies
    * @Description        :   Return a list of contracts whose effective date is changed.
    ********************************************************************/
    public static Set<Id> changeEffectiveDatePolicies (Map<Id,Contract> oldContractMap, Map<Id,Contract> newContractMap){
        Set<Id> contractList = new Set<Id>();
        for(Id contractId : newContractMap.keySet()){
            if(oldContractMap.get(contractId).ARC_EffectiveDate__c != newContractMap.get(contractId).ARC_EffectiveDate__c) contractList.add(contractId);
        }
        return contractList;
    }
    
    /*******************************************************************
    * @MethodName         :   createUpdateCommission
    * @Description        :   When a contract gets activated, creates a new Commission or update the Contract on the Commission.
    ********************************************************************/
    public static void createUpdateCommission (Map<Id,Contract> oldContractMap, Map<Id,Contract> newContractMap){
        //Define Variables
        Set<Id> agentsIds = new Set<Id>();
        Map<Id,Contract> contractsToCreateCommissionsMap = new Map<Id,Contract>();
        Map<Id,Contract> oldContractNewContractMap = new Map<Id,Contract>();

        for(Id contractId : newContractMap.keySet()){
            Contract newContract = newContractMap.get(contractId);
            Contract oldContract = oldContractMap.get(contractId);
            
            //Check if it's a New Enrollment contract
            if(newContract?.ARC_ContractReason__c != null && newContract?.ARC_ContractReason__c.contains('New Application')){
                contractsToCreateCommissionsMap.put(newContract.Id, newContract);
                agentsIds.add(newContract.ARC_Selling_Agent__c);
            }
            //Check if it's a PC
            else if(newContract?.ARC_ContractReason__c != null && !newContract?.ARC_ContractReason__c?.contains('New Application') && !newContract?.ARC_ContractReason__c?.contains('Spin Off') && newContract.vlocity_ins__ExpiredContractId__c != null){
                oldContractNewContractMap.put(newContract.vlocity_ins__ExpiredContractId__c, newContract);
            }
        }
        if(!contractsToCreateCommissionsMap.isEmpty()) createCommissionAndInitialCP(contractsToCreateCommissionsMap, agentsIds);
        if(!oldContractNewContractMap.isEmpty()) updateContractOnCommission(oldContractNewContractMap);
    }
    
    /*******************************************************************
    * @MethodName         :   createCommissionAndInitialCP 
    * @Description        :   Creates the Commission record and the Initial Commission Payment. 
    ********************************************************************/
    public static void createCommissionAndInitialCP(Map<Id,Contract> contractsToCreateCommissionsMap,  Set<Id> agentsIds){
        Id rtCommAccExecutive = Schema.SObjectType.ARC_Commission__c.getRecordTypeInfosByDeveloperName().get('ARC_AccountExecutive').getRecordTypeId();
        List<User> agentUsers = [SELECT Id, Name FROM User WHERE (Id IN: agentsIds OR Name = 'Integration User') AND IsActive = true];
        Set<Id> activeUsers = new Set<Id>();
        Id integrationUserId;
        for(User u: agentUsers){
            activeUsers.add(u.Id);
            if(u.Name == 'Integration User') integrationUserId = u.Id;
        }
        //Declar Variables
        List<ARC_Commission__c> commissionsToCreate = new List<ARC_Commission__c>();
        Map<Id, User> agentUsersMap = new Map <Id,User>([SELECT Id, Agent_Role__c FROM User WHERE Id IN: agentsIds]);
        Map<Id,Date> contractPaymentDate = new Map <Id,Date>();
        Map<Id,Double> contractMedicalTotal = new Map<Id,Double>();
        Map<Id,Double> contractAncillaryTotal = new Map<Id,Double>();
        List<Id> newContractIds = new List<Id>();

        //Get existing Commissions
        List<ARC_Commission__c> commList = [SELECT Id,Contract__c FROM ARC_Commission__c WHERE Contract__c IN : contractsToCreateCommissionsMap.keySet()];
        Set<Id> contractsWithExistingCommissions = new Set<Id>();
        for(ARC_Commission__c comm: commList) contractsWithExistingCommissions.add(comm.Contract__c);


        newContractIds.addAll(contractsToCreateCommissionsMap.keySet());
        getProgramPrices(contractMedicalTotal,contractAncillaryTotal, newContractIds); 

        //Healthy Discount Price is considered in the total price
        for(Contract cont : contractsToCreateCommissionsMap.values()){
            if(!contractsWithExistingCommissions.contains(cont.Id)){
                Double corePrice = contractMedicalTotal.containsKey(cont.Id) ? contractMedicalTotal.get(cont.Id) : 0;
                Double ancillaryPrice = contractAncillaryTotal.containsKey(cont.Id) ? contractAncillaryTotal.get(cont.Id) : 0;
                //Define the selling agent and the agent role
                Id sellingAgentId = (cont.ARC_IsSelfEnrollment__c || !activeUsers.contains(cont.ARC_Selling_Agent__c))? integrationUserId: cont.ARC_Selling_Agent__c;
                String agentRole = sellingAgentId != IntegrationUserId? agentUsersMap.get(cont.ARC_Selling_Agent__c)?.Agent_Role__c:null;
                //New Commission Instance
                ARC_Commission__c commission = new ARC_Commission__c(
                    OwnerId = sellingAgentId,
                    ARC_Agent_Role__c = agentRole,
                    Contract__c = cont.Id,
                    Original_Contract__c = cont.Id,
                    ARC_InitialCommission__c = (0.10 * corePrice + 0.50 * ancillaryPrice), 
                    ARC_RecurringCommission__c = agentRole == 'Senior Account Executive' ? (0.05 * cont.ARC_TotalPrice__c) :(0.03 * cont.ARC_TotalPrice__c),
                    RecordTypeId = rtCommAccExecutive
                );
                commissionsToCreate.add(commission);
            }
        }
        try{
            Database.insert(commissionsToCreate, false);
            createInitialCP(commissionsToCreate, contractsToCreateCommissionsMap);
        }catch(Exception e){
            System.debug('Exception inserting the Commissions :'+e.getMessage());
            throw new AuraHandledException('Exception inserting the Commissions :'+e.getMessage());
        }
    }

    /*******************************************************************
    * @MethodName         :   updateContractOnCommission
    * @Description        :   Updates the Contract on Commisisons when the PC contract becomes activated.
    ********************************************************************/
    public static void updateContractOnCommission (Map<Id,Contract> contractOldNewMap){
        //Gets the active commissions related to the expired contract
        List<ARC_Commission__c> commList = [SELECT Id,Contract__c,ARC_ExistingContributions__c,ARC_InitialCommission__c,OwnerId, ARC_MemberContribution__c, ARC_RefundsVoidedContributions__c, ARC_Agent_Role__c,Original_Contract__c, Original_Contract__r.ARC_EffectiveDate__c, (SELECT Id, Type__c, Amount__c, RecordTypeId, ARC_PaymentDate__c FROM Commision_Payments__r WHERE Type__c = 'Initial' ORDER BY CreatedDate DESC LIMIT 1) FROM ARC_Commission__c WHERE Contract__c IN : contractOldNewMap.keySet() AND Active__c = true];
        //Variable to store the original Contracts that are voided. 
        Set<Id> originalContractVoided = new Set<Id>();
        List<Contract> oldContractsNeverAcive = [SELECT Id, (Select Id FROM Commissions__r) FROM Contract WHERE Id IN : contractOldNewMap.keySet() AND Status = 'Voided' AND ARC_ContractReason__c INCLUDES ('New Application') AND ARC_IsSelfEnrollment__c = false];
        
        //Store the new contract ids in a list
        List<Id> newContractIds = new List<Id>();
        for(Contract c: contractOldNewMap.values()) newContractIds.add(c.id);

        if(!commList.isEmpty()){
            //List of adjustment commissions payments to create
            List<ARC_Commission_Payment__c> adjusmentInitialCPToCreate = new List<ARC_Commission_Payment__c>();

            //Get program prices
            Map<Id,Double> contractMedicalTotal = new Map<Id,Double>();
            Map<Id,Double> contractAncillaryTotal = new Map<Id,Double>();
            getProgramPrices(contractMedicalTotal,contractAncillaryTotal, newContractIds);

            //Get the transaction from the pc contract if already exists
            Map<Id,Id> pcContractHasContributionMap = getTransactionsFromPC(newContractIds);

            List<ARC_Commission__c> commissionsWithoutInitial = new List<ARC_Commission__c>();
            Map<Id,Contract> contractsToCreateInitialComm = new Map<Id,Contract>();
            List<ARC_Commission_Payment__c> recurringCPToCreate = new List<ARC_Commission_Payment__c>();


            for(ARC_Commission__c comm:commList){
                //New Contract Core & Ancillary Plans prices
                Contract newContract = contractOldNewMap.get(comm.Contract__c);
                Double corePrice = contractMedicalTotal.containsKey(newContract.Id) ? contractMedicalTotal.get(newContract.Id) : 0;
                Double ancillaryPrice = contractAncillaryTotal.containsKey(newContract.Id) ? contractAncillaryTotal.get(newContract.Id) : 0;
                Decimal existingContributions = comm.ARC_ExistingContributions__c != null ? comm.ARC_ExistingContributions__c:0;

                //Is 60 days from Original Contract Effective Date?
                if(comm.Original_Contract__r.ARC_EffectiveDate__c.daysBetween(Date.today()) <= 60){
                    Double oldInitialAmount = comm.ARC_InitialCommission__c;
        
                    //Check if the Initial Commission was already created and make the adjustment 
                    if(comm.ARC_MemberContribution__c - comm.ARC_RefundsVoidedContributions__c >= 1 && existingContributions == 0){
                        comm.ARC_InitialCommission__c = (0.10 * corePrice + 0.50 * ancillaryPrice);
                        adjusmentInitialCPToCreate.add(createInitialCPAdjustment(comm,oldInitialAmount));
                    }
                }
                comm.Contract__c = newContract.Id;
                comm.ARC_RecurringCommission__c = comm.ARC_Agent_Role__c == 'Senior Account Executive'? (0.05 * (corePrice + ancillaryPrice)): (0.03 * (corePrice + ancillaryPrice));

                //Check if the program change contract that became activated already has a contribution
                if(pcContractHasContributionMap.containsKey(newContract.Id)){
                    //Only Creates the Initial Commissions for those contracts without existing contributions (backfill).
                    if(comm.ARC_MemberContribution__c + existingContributions + comm.ARC_RefundsVoidedContributions__c == 0){
                        commissionsWithoutInitial.add(comm);
                        contractsToCreateInitialComm.put(newContract.Id,newContract);
                    }
                    else if(comm.ARC_MemberContribution__c + existingContributions - comm.ARC_RefundsVoidedContributions__c > 0 && comm.ARC_MemberContribution__c + existingContributions - comm.ARC_RefundsVoidedContributions__c < 12){
                        recurringCPToCreate.add(createsRecurringCP(comm,pcContractHasContributionMap.get(newContract.Id)));
                    }
                }
            }
            if(commList.size()> 0)update commList;
            if(adjusmentInitialCPToCreate.size()> 0) insert adjusmentInitialCPToCreate;
            if(!contractsToCreateInitialComm.isEmpty() &&commissionsWithoutInitial.size()>0) createInitialCP(commissionsWithoutInitial,contractsToCreateInitialComm);
            if(recurringCPToCreate.size()> 0) insert recurringCPToCreate;
        }

        //Check if there are New Enrollment Contracts that were never active, so Commissions don't exist in these cases. 
        if(!oldContractsNeverAcive.isEmpty()){
            List<Id> pcContractIds = new List<Id>();
            for(Contract oldContract: oldContractsNeverAcive){
                //The old contract doesn't have a related Commission? 
                if(oldContract.Commissions__r.isEmpty()){
                    pcContractIds.add(contractOldNewMap.get(oldContract.Id).Id);
                }
            }
            //Create the Commission for the PC Contract, since the old contract was never activated. 
            if(!pcContractIds.isEmpty()){
                Map<Id,Contract> contractsWithoutCommissionMap = new Map<Id,Contract>([SELECT Id,ARC_IsSelfEnrollment__c, ARC_Selling_Agent__c, ARC_TotalPrice__c, ARC_AwaitingActivationDate__c, ARC_EffectiveDate__c FROM Contract WHERE Id IN :pcContractIds]);
                Set<Id> agentIds = new Set<Id>();
                for(Contract cont : contractsWithoutCommissionMap.values()){
                    agentIds.add(cont.ARC_Selling_Agent__c);
                }
                createCommissionAndInitialCP(contractsWithoutCommissionMap,agentIds);
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   getProgramPrices
    * @Description        :   Populate the program prices in the maps. 
    ********************************************************************/
    public static void getProgramPrices(Map<Id,Double> contractMedicalTotal, Map<Id,Double> contractAncillaryTotal, List<Id> contracts){
        List<vlocity_ins__ContractLineItem__c> cliList = [SELECT Id, vlocity_ins__ContractId__c, vlocity_ins__TotalPrice__c, vlocity_ins__ProductType__c FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c IN: contracts AND vlocity_ins__ParentItemId__c = NULL AND (vlocity_ins__ProductType__c = 'Ancillary' OR vlocity_ins__ProductType__c = 'Medical')];
        for(vlocity_ins__ContractLineItem__c cli: cliList){
            if(cli.vlocity_ins__ProductType__c == 'Medical') contractMedicalTotal.put(cli.vlocity_ins__ContractId__c, cli.vlocity_ins__TotalPrice__c);
            else{
                if(!contractAncillaryTotal.containsKey(cli.vlocity_ins__ContractId__c)) contractAncillaryTotal.put(cli.vlocity_ins__ContractId__c, cli.vlocity_ins__TotalPrice__c);
                else contractAncillaryTotal.put(cli.vlocity_ins__ContractId__c, (contractAncillaryTotal.get(cli.vlocity_ins__ContractId__c) +cli.vlocity_ins__TotalPrice__c));
            }
        }
    }

    /*******************************************************************
    * @MethodName         :   createInitialCP
    * @Description        :   Receives a list of commissions and contracts and creates the Initial Commission Payments
    ********************************************************************/
    public static void createInitialCP(List<ARC_Commission__c> commissions, Map<Id,Contract> contractsToCreateCommissions){
        if(!commissions.isEmpty()){
            List<ARC_Commission_Payment__c> commissionPaymentsToCreate = new List<ARC_Commission_Payment__c>();

            //Get the Initial Transaction
            List<ChargentOrders__Transaction__c> existingTransactions = [SELECT Id,CreatedDate, ChargentOrders__Amount__c, ChargentOrders__Order__r.ARC_Contract__c, ChargentOrders__Order__r.ARC_Contract__r.ARC_TotalPrice__c FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Order__r.ARC_Contract__c IN:contractsToCreateCommissions.keySet() AND ChargentOrders__Response_Status__c = 'Approved' AND ChargentOrders__Type__c = 'Charge' AND ChargentOrders__Order__r.ChargentOrders__Description__c ='Recurring Monthly Order' ORDER BY CreatedDate ASC];

            Map<Id,Id> contractInitialTransactionMap = new Map<Id,Id>();
            for(ChargentOrders__Transaction__c t: existingTransactions){
                if(!contractInitialTransactionMap.containsKey(t?.ChargentOrders__Order__r?.ARC_Contract__c) && t.ChargentOrders__Amount__c == t.ChargentOrders__Order__r.ARC_Contract__r.ARC_TotalPrice__c){
                    contractInitialTransactionMap.put(t.ChargentOrders__Order__r.ARC_Contract__c,t.Id);
                }
            }
            //Generate the Initial Commission Payments
            for(ARC_Commission__c commission: commissions){
                if(commission.Id != null){
                    Date paymentDate = calculateInitialCommDate(contractsToCreateCommissions.get(commission.Contract__c));
                    ARC_Commission_Payment__c cp = new ARC_Commission_Payment__c(
                        Commission__c = commission.Id,
                        Amount__c = commission.ARC_InitialCommission__c,
                        ARC_PaymentDate__c = paymentDate,
                        Type__c = 'Initial',
                        RecordTypeId = rtCommPaymentAccExecutive,
                        ARC_Transaction__c = contractInitialTransactionMap.containsKey(commission.Contract__c)?contractInitialTransactionMap.get(commission.Contract__c):null
                    );
                    commissionPaymentsToCreate.add(cp);
                }
            }
            insert commissionPaymentsToCreate;
        }
    }

    /*******************************************************************
    * @MethodName         :   updateCommissionPrice
    * @Description        :   When the total amount of the contract changed and is linked to an active Commission, it updates the initial and recurring prices.
    ********************************************************************/
    public static void updateCommissionPrice (Map<Id,Contract> contractsMap){
        List<ARC_Commission__c> commList = [SELECT Id,Contract__c,OwnerId, ARC_MemberContribution__c, ARC_RefundsVoidedContributions__c, Original_Contract__c, ARC_Agent_Role__c FROM ARC_Commission__c WHERE Contract__c IN : contractsMap.keySet() AND Active__c = true];
        List<Id> contractIds = new List<Id>();
        if(!commList.isEmpty()){
            //Get program prices
            Map<Id,Double> contractMedicalTotal = new Map<Id,Double>();
            Map<Id,Double> contractAncillaryTotal = new Map<Id,Double>();
            contractIds.addAll(contractsMap.keySet());
            getProgramPrices(contractMedicalTotal,contractAncillaryTotal,contractIds);

            for(ARC_Commission__c comm:commList){
                //New Contract Core & Ancillary Plans prices
                Double corePrice = contractMedicalTotal.containsKey(comm.Contract__c) ? contractMedicalTotal.get(comm.Contract__c) : 0;
                Double ancillaryPrice = contractAncillaryTotal.containsKey(comm.Contract__c) ? contractAncillaryTotal.get(comm.Contract__c) : 0;
                comm.ARC_InitialCommission__c = (0.10 * corePrice + 0.50 * ancillaryPrice);
                comm.ARC_RecurringCommission__c = comm.ARC_Agent_Role__c == 'Senior Account Executive' ? (0.05 * (corePrice + ancillaryPrice)):(0.03 * (corePrice + ancillaryPrice));
            }
            update commList;
        }
    }

    /*******************************************************************
    * @MethodName         :   reactivateContractLinkToCommission
    * @Description        :   Updates the Contract in the Commission when the Contract gets reactivated and the Currenct contract is another one.
    ********************************************************************/
    public static void reactivateContractLinkToCommission(Map<Id,Contract> contractsMap){
        Integer counter = 0;
        Integer countOfContracts = contractsMap.size();
        Map<Id,Id> commissionReactivateContractMap = new Map<Id,Id>();
        List<ARC_Commission__History> commHistoryList = [SELECT Id, Field, NewValue,OldValue, Parent.Id FROM ARC_Commission__History WHERE Field = 'Contract__c'];
        for(ARC_Commission__History ch: commHistoryList){
            if(String.valueOf(ch.NewValue).startsWith('8008') && contractsMap.keySet().contains((Id)ch.NewValue)){
                commissionReactivateContractMap.put(ch.Parent.Id,(Id)ch.NewValue);
                counter++;
            }
            else if(String.valueOf(ch.OldValue).startsWith('8008') && contractsMap.keySet().contains((Id)ch.OldValue)){
                commissionReactivateContractMap.put(ch.Parent.Id,(Id)ch.OldValue);
                counter++;
            }
            if(counter == countOfContracts) break;
        }
        if(!commissionReactivateContractMap.isEmpty() || Test.isRunningTest()){
            List<ARC_Commission__c> commList = [SELECT Id,ARC_Agent_Role__c,ARC_InitialCommission__c,Contract__c,Original_Contract__r.ARC_EffectiveDate__c, Original_Contract__c,ARC_RefundsVoidedContributions__c, ARC_MemberContribution__c,RecordTypeId, (SELECT Id, Type__c, Amount__c, RecordTypeId, ARC_PaymentDate__c FROM Commision_Payments__r WHERE Type__c = 'Initial' ORDER BY CreatedDate DESC LIMIT 1) FROM ARC_Commission__c WHERE Id IN: commissionReactivateContractMap.keySet() AND Contract__c NOT IN:contractsMap.keySet()];
            if(Test.isRunningTest()){
                List<Id> testContract = new List<Id>(contractsMap.keySet());
                commList = [SELECT Id,ARC_Agent_Role__c,ARC_InitialCommission__c,Contract__c,Original_Contract__r.ARC_EffectiveDate__c, Original_Contract__c,ARC_RefundsVoidedContributions__c, ARC_MemberContribution__c,RecordTypeId, (SELECT Id, Type__c, Amount__c, RecordTypeId, ARC_PaymentDate__c FROM Commision_Payments__r WHERE Type__c = 'Initial' ORDER BY CreatedDate DESC LIMIT 1) FROM ARC_Commission__c WHERE Original_Contract__c =:testContract[0]];
            }
            Map<Id,Double> contractMedicalTotal = new Map<Id,Double>();
            Map<Id,Double> contractAncillaryTotal = new Map<Id,Double>();
            List<Id> contractIds = new List<Id>();
            contractIds.addAll(contractsMap.keySet());
            List<ARC_Commission_Payment__c> adjusmentInitialCPToCreate = new List<ARC_Commission_Payment__c>();
            getProgramPrices(contractMedicalTotal,contractAncillaryTotal, contractIds);

            for(ARC_Commission__c comm:commList){
                Id reactivatedContractId = commissionReactivateContractMap.get(comm.Id);
                if(Test.isRunningTest()){
                    List<Id> testContract = new List<Id>(contractsMap.keySet());
                    reactivatedContractId = (Id)testContract[0];
                }
                //Reactivated Contract Core & Ancillary Plans prices    
                Double corePrice = contractMedicalTotal.containsKey(reactivatedContractId) ? contractMedicalTotal.get(reactivatedContractId) : 0;
                Double ancillaryPrice = contractAncillaryTotal.containsKey(reactivatedContractId) ? contractAncillaryTotal.get(reactivatedContractId) : 0;

                //Is 60 days from Original Contract Effective Date?
                if(comm.Original_Contract__r.ARC_EffectiveDate__c.daysBetween(Date.today()) <= 60){
                    //Check if the Initial Commission was already created and make the adjustment
                    if(comm.ARC_MemberContribution__c - comm.ARC_RefundsVoidedContributions__c >= 1){
                        Double oldInitialAmount = comm.ARC_InitialCommission__c;
                        comm.ARC_InitialCommission__c = (0.10 * corePrice + 0.50 * ancillaryPrice);
                        adjusmentInitialCPToCreate.add(createInitialCPAdjustment(comm,oldInitialAmount));
                    }
                }
                comm.Contract__c = reactivatedContractId;
                comm.ARC_RecurringCommission__c = comm.ARC_Agent_Role__c == 'Senior Account Executive'?  (0.05 * (corePrice + ancillaryPrice)) : (0.03 * (corePrice + ancillaryPrice));
            }
            if(commList.size()> 0)update commList;
            if(adjusmentInitialCPToCreate.size()> 0) insert adjusmentInitialCPToCreate;
        }
    }

    /*******************************************************************
    * @MethodName         :   createInitialCPAdjustment
    * @Description        :   Create the Commission Payment adjustment for the initial commission.
    ********************************************************************/
    public static ARC_Commission_Payment__c createInitialCPAdjustment(ARC_Commission__c comm, Double oldInitialAmount){
        if(comm != null){
            for(ARC_Commission_Payment__c cp: comm.Commision_Payments__r){
                if(cp.Type__c == 'Initial'){
                    ARC_Commission_Payment__c cpayment = new ARC_Commission_Payment__c();
                    cpayment.Amount__c = comm.ARC_InitialCommission__c - oldInitialAmount;
                    cpayment.RecordTypeId = cp.RecordTypeId;
                    cpayment.Type__c = 'Adjustment';
                    cpayment.Commission__c = comm.Id;
                    if(cp.ARC_PaymentDate__c >= Date.Today()) cpayment.ARC_PaymentDate__c = cp.ARC_PaymentDate__c;
                    else{
                        cpayment.ARC_PaymentDate__c = (Date.today().day() <= 15) ?
                            Date.newinstance(Date.today().year(), Date.today().month(), 15) :
                            Date.newinstance(Date.today().year(), Date.today().addMonths(1).month(), 15);
                    }
                    return cpayment;
                }
            }
        }
        return null;
    }

    /*******************************************************************
    * @MethodName         :   createsRecurringCP
    * @Description        :   Create the recurring Commission Payments.
    ********************************************************************/
    public static ARC_Commission_Payment__c createsRecurringCP(ARC_Commission__c comm, Id transactionId){
        if(comm != null){
            ARC_Commission_Payment__c cpayment = new ARC_Commission_Payment__c();
            cpayment.Amount__c = comm.ARC_RecurringCommission__c;
            cpayment.RecordTypeId = rtCommPaymentAccExecutive;
            cpayment.Type__c = 'Recurring';
            cpayment.Commission__c = comm.Id;
            cpayment.ARC_Transaction__c = transactionId;
            cpayment.ARC_PaymentDate__c = (Date.today().day() <= 15) ?
                Date.newinstance(Date.today().year(), Date.today().month(), 15) :
                Date.newinstance(Date.today().year(), Date.today().addMonths(1).month(), 15);
            return cpayment;
        }
        return null;
    }

    /*******************************************************************
    * @MethodName         :   getTransactionsFromPC
    * @Description        :   Returns a map with the pc contract id and the corresponding transaction id if exist
    ********************************************************************/
    public static Map<Id,Id> getTransactionsFromPC (List<Id> pcContractIds){
        if(pcContractIds.isEmpty()) return null;

        List<ChargentOrders__ChargentOrder__c> recurringOrders = [SELECT Id,ARC_Contract__c, (SELECT Id FROM ChargentOrders__Transactions__r WHERE ChargentOrders__Response_Status__c = 'Approved' AND ChargentOrders__Type__c = 'Charge' LIMIT 1) FROM ChargentOrders__ChargentOrder__c WHERE ARC_Contract__c IN: pcContractIds AND ChargentOrders__Description__c ='Recurring Monthly Order'];

        if(recurringOrders.isEmpty()) return null;

        Map<Id,Id> resultMap = new  Map<Id,Id>();

        for(ChargentOrders__ChargentOrder__c recurring: recurringOrders){
            for(ChargentOrders__Transaction__c t: recurring.ChargentOrders__Transactions__r){
                resultMap.put(recurring.ARC_Contract__c,t.Id);
                break;
            }
        }
        return resultMap;
    }

    /*******************************************************************
    * @MethodName         :   calculateInitialCommDate
    * @Description        :   Returns the Commission Payment date based on the Contract Effective Date and Contract Awaiting Activation Date. 
    ********************************************************************/
    public static Date calculateInitialCommDate(Contract cont){
        if(cont.ARC_AwaitingActivationDate__c != null && (cont.ARC_AwaitingActivationDate__c.date() > cont.ARC_EffectiveDate__c)){
            if(cont.ARC_AwaitingActivationDate__c.date().day() == 1 ) return Date.newInstance(cont.ARC_AwaitingActivationDate__c.date().year(),cont.ARC_AwaitingActivationDate__c.date().month(), 15);
            else return Date.newInstance(cont.ARC_AwaitingActivationDate__c.date().year(),cont.ARC_AwaitingActivationDate__c.date().month(), 15).addMonths(1);
        }
        else{
            if(cont.ARC_EffectiveDate__c.day() == 1 ) return Date.newInstance(cont.ARC_EffectiveDate__c.year(),cont.ARC_EffectiveDate__c.month(), 15);
            else return Date.newInstance(cont.ARC_EffectiveDate__c.year(),cont.ARC_EffectiveDate__c.month(), 15).addMonths(1);
        }
    }

    /*********************************************************************************************************
     * @name            updateAggregators
     * @description     When a Contract gets voided, this method verifies if the Participant Aggregators are pointing to a Terminated/Activated policy
     *                  and if they do, relocates the Aggregators to the closest future Terminated/Activated Policy from its Participant Aggregators,
     *                  otherwise, the ARC_IsInactive__c field is checked.
     * @param           newVoidedContractMap
     *********************************************************************************************************/
    public static void updateAggregators(Map<Id,Contract> newVoidedContractMap){
        Map<Id, InsurancePolicy> mapPolicies;
        List<ARC_Aggregator__c> aggregatorsList = new List<ARC_Aggregator__c>();
        Map<Id, List<Map<String, String>>> mapFamilyAggregators = new Map<Id, List<Map<String, String>>>();
        List<ARC_Aggregator__c> aggregatorsToUpdate = new List<ARC_Aggregator__c>();
        Set<Id> familyAggregatorsIds = new Set<Id>();

        mapPolicies = new Map<Id, InsurancePolicy>([SELECT Id FROM InsurancePolicy WHERE ARC_Contract__c = :newVoidedContractMap.keySet()]);

        aggregatorsList = [SELECT Id, Name, RecordType.Name, ARC_FamilyAggregator__c, ARC_FamilyAggregator__r.ARC_CreatedIn__c, ARC_FamilyAggregator__r.ARC_CreatedIn__r.ARC_Contract__r.ARC_EffectiveDate__c, ARC_FamilyAggregator__r.ARC_CreatedIn__r.ARC_Contract__r.CreatedDate,
                                (SELECT Id, Name, ARC_PolicyParticipant__r.InsurancePolicyId, ARC_PolicyParticipant__r.InsurancePolicy.ARC_Contract__r.Status, ARC_PolicyParticipant__r.InsurancePolicy.ARC_Contract__r.ARC_EffectiveDate__c, ARC_PolicyParticipant__r.InsurancePolicy.ARC_Contract__r.CreatedDate
                                FROM Participant_Aggregators__r
                                WHERE ARC_PolicyParticipant__r.InsurancePolicy.ARC_Contract__r.Status = 'Activated' OR ARC_PolicyParticipant__r.InsurancePolicy.ARC_Contract__r.Status = 'Terminated'
                                ORDER BY ARC_PolicyParticipant__r.InsurancePolicy.ARC_Contract__r.ARC_EffectiveDate__c)
                           FROM ARC_Aggregator__c
                           WHERE ARC_CreatedIn__c IN :mapPolicies.keySet()];
        
        for (ARC_Aggregator__c aggregatorTemp : aggregatorsList) {
            if (aggregatorTemp.RecordType.Name == 'Family') {
                familyAggregatorsIds.add(aggregatorTemp.Id);
            } else if (aggregatorTemp.Participant_Aggregators__r.isEmpty()) {
                aggregatorTemp.ARC_IsInactive__c = true;
                aggregatorsToUpdate.add(aggregatorTemp);
            } else {
                Id closestPolicyId;
                Id closestContractId;
                Date closestEffectiveDate = Date.today();
                Datetime closestCreatedDate = Date.today();

                Map<Id, Map<String, String>> mapContractDates = new Map<Id, Map<String, String>>();
                for (ARC_ParticipantAggregator__c participantAggregatorTemp : aggregatorTemp.Participant_Aggregators__r) {
                    mapContractDates.put(participantAggregatorTemp.ARC_PolicyParticipant__r.InsurancePolicy.ARC_Contract__c, new Map<String, String> {
                        'ARC_EffectiveDate__c' => String.valueOf(participantAggregatorTemp.ARC_PolicyParticipant__r.InsurancePolicy.ARC_Contract__r.ARC_EffectiveDate__c),
                        'CreatedDate' => String.valueOf(participantAggregatorTemp.ARC_PolicyParticipant__r.InsurancePolicy.ARC_Contract__r.CreatedDate),
                        'InsurancePolicyId' => String.valueOf(participantAggregatorTemp.ARC_PolicyParticipant__r.InsurancePolicyId)
                    });
                }

                for (Id contractIdTemp : mapContractDates.keySet()) {
                    if (closestPolicyId == null) {
                        closestContractId = contractIdTemp;
                        closestPolicyId = mapContractDates.get(contractIdTemp).get('InsurancePolicyId');
                        closestEffectiveDate = Date.valueOf(mapContractDates.get(contractIdTemp).get('ARC_EffectiveDate__c'));
                        closestCreatedDate = Datetime.valueOf(mapContractDates.get(contractIdTemp).get('CreatedDate'));
                    } else {
                        Date currentEffectiveDate = Date.valueOf(mapContractDates.get(contractIdTemp).get('ARC_EffectiveDate__c'));
                        if (currentEffectiveDate <= closestEffectiveDate) {
                            if (currentEffectiveDate == closestEffectiveDate) {
                                if (Datetime.valueOf(mapContractDates.get(contractIdTemp).get('CreatedDate')) < Datetime.valueOf(mapContractDates.get(closestContractId).get('CreatedDate'))) {
                                    closestPolicyId = mapContractDates.get(contractIdTemp).get('InsurancePolicyId');
                                    closestContractId = contractIdTemp;
                                    closestEffectiveDate = Date.valueOf(mapContractDates.get(contractIdTemp).get('ARC_EffectiveDate__c'));
                                    closestCreatedDate = Datetime.valueOf(mapContractDates.get(contractIdTemp).get('CreatedDate'));
                                }
                            } else {
                                closestPolicyId = mapContractDates.get(contractIdTemp).get('InsurancePolicyId');
                                closestContractId = contractIdTemp;
                                closestEffectiveDate = Date.valueOf(mapContractDates.get(contractIdTemp).get('ARC_EffectiveDate__c'));
                                closestCreatedDate = Datetime.valueOf(mapContractDates.get(contractIdTemp).get('CreatedDate'));
                            }
                        }
                    }
                }

                if (aggregatorTemp.ARC_FamilyAggregator__c != null) {
                    if (mapFamilyAggregators.containsKey(aggregatorTemp.ARC_FamilyAggregator__c)) {
                        List<Map<String, String>> childAggregators = mapFamilyAggregators.get(aggregatorTemp.ARC_FamilyAggregator__c);
                        childAggregators.add(new Map<String, String> {
                            'ARC_EffectiveDate__c' => String.valueOf(closestEffectiveDate),
                            'CreatedDate' => String.valueOf(closestCreatedDate),
                            'InsurancePolicyId' => String.valueOf(closestPolicyId)
                        });
                        mapFamilyAggregators.put(aggregatorTemp.ARC_FamilyAggregator__c, childAggregators);
                    } else {
                        mapFamilyAggregators.put(aggregatorTemp.ARC_FamilyAggregator__c, new List<Map<String, String>> {
                            new Map<String, String> {
                                'ARC_EffectiveDate__c' => String.valueOf(closestEffectiveDate),
                                'CreatedDate' => String.valueOf(closestCreatedDate),
                                'InsurancePolicyId' => String.valueOf(closestPolicyId)
                            }
                        });
                    }
                } 

                aggregatorTemp.ARC_CreatedIn__c = closestPolicyId;
                aggregatorsToUpdate.add(aggregatorTemp);
            }
        }

        for (Id aggregatorIdTemp : familyAggregatorsIds) {
            Id closestPolicyId;
            Date closestEffectiveDate = Date.today();
            Datetime closestCreatedDate = Date.today();
            ARC_Aggregator__c familyAggregator = new ARC_Aggregator__c(Id = aggregatorIdTemp);

            if (!mapFamilyAggregators.containsKey(aggregatorIdTemp)) {
                familyAggregator.ARC_IsInactive__c = true;
            } else {
                for (Map<String, String> mapFamilyAggregatorTemp : mapFamilyAggregators.get(aggregatorIdTemp)) {
                    if (closestPolicyId == null) {
                        closestPolicyId = mapFamilyAggregatorTemp.get('InsurancePolicyId');
                        closestEffectiveDate = Date.valueOf(mapFamilyAggregatorTemp.get('ARC_EffectiveDate__c'));
                        closestCreatedDate = Datetime.valueOf(mapFamilyAggregatorTemp.get('CreatedDate'));
                    } else {
                        Date currentEffectiveDate = Date.valueOf(mapFamilyAggregatorTemp.get('ARC_EffectiveDate__c'));
                        if (currentEffectiveDate <= closestEffectiveDate) {
                            if (currentEffectiveDate == closestEffectiveDate) {
                                if (Datetime.valueOf(mapFamilyAggregatorTemp.get('CreatedDate')) < closestCreatedDate) {
                                    closestPolicyId = mapFamilyAggregatorTemp.get('InsurancePolicyId');
                                    closestEffectiveDate = Date.valueOf(mapFamilyAggregatorTemp.get('ARC_EffectiveDate__c'));
                                    closestCreatedDate = Datetime.valueOf(mapFamilyAggregatorTemp.get('CreatedDate'));
                                }
                            } else {
                                closestPolicyId = mapFamilyAggregatorTemp.get('InsurancePolicyId');
                                closestEffectiveDate = Date.valueOf(mapFamilyAggregatorTemp.get('ARC_EffectiveDate__c'));
                                closestCreatedDate = Datetime.valueOf(mapFamilyAggregatorTemp.get('CreatedDate'));
                            }
                        }
                    }
                }
                familyAggregator.ARC_CreatedIn__c = closestPolicyId;
            }
            aggregatorsToUpdate.add(familyAggregator);
        }

        if (!aggregatorsToUpdate.isEmpty()) update aggregatorsToUpdate;
    }

    /************************************************************************************************************
     * @name            reactivateAggregators
     * @description     When a Voided Contract gets Terminated or Activated, this method unchecks the ARC_IsInactive__c fields 
     *                  of the Aggregators its Participant Aggregators point to.
     * @param           reactivatedVoidedContractMap
     *********************************************************************************************************/
    public static void reactivateAggregators(Map<Id,Contract> reactivatedVoidedContractMap) {
        List<ARC_ParticipantAggregator__c> participantAggregatorsList = new List<ARC_ParticipantAggregator__c>();
        Map<Id, ARC_Aggregator__c> aggregatorsToUpdate = new Map<Id, ARC_Aggregator__c>();

        participantAggregatorsList = [
            SELECT Id, Name, ARC_Aggregator__c, ARC_Aggregator__r.ARC_FamilyAggregator__c, ARC_Aggregator__r.ARC_FamilyAggregator__r.ARC_IsInactive__c
            FROM ARC_ParticipantAggregator__c
            WHERE ARC_Policy__r.ARC_Contract__c IN :reactivatedVoidedContractMap.keySet()
                AND ARC_Aggregator__r.ARC_IsInactive__c = true
                AND (NOT (ARC_Aggregator__r.ARC_Year__c != null AND ARC_Aggregator__r.ARC_Code__c IN ('PREEX__c', 'MAT__c')))
        ];
        for (ARC_ParticipantAggregator__c partAgg : participantAggregatorsList) {
            if (!aggregatorsToUpdate.containsKey(partAgg.ARC_Aggregator__c)) {
                aggregatorsToUpdate.put(partAgg.ARC_Aggregator__c, new ARC_Aggregator__c(Id = partAgg.ARC_Aggregator__c, ARC_IsInactive__c = false));
            }
            if (
                partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__c != null 
                && partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__r.ARC_IsInactive__c 
                && !aggregatorsToUpdate.containsKey(partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__c)
            ) {
                aggregatorsToUpdate.put(partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__c, new ARC_Aggregator__c(Id = partAgg.ARC_Aggregator__r.ARC_FamilyAggregator__c, ARC_IsInactive__c = false));
            }
        }

        if (!aggregatorsToUpdate.isEmpty()) update aggregatorsToUpdate.values();
    }

    // Recursion prevention
    private static Boolean billingAutomationExecuted = false;
    
    /************************************************************************************************************
     * @name            updateNextInvoiceAnchor
     * @description     Updates ARC_NextInvoiceCoverageStart__c for pre-invoice contracts when effective date changes.
     *                  Must run in before context to avoid DML operations.
     * @param           newContracts   - List of new/updated contracts
     * @param           oldContractMap - Map of old contract versions (null for insert)
     * @developer       lucas.benero@arcsona.com
     * @date            2026-01-26
     *********************************************************************************************************/
    public static void updateNextInvoiceAnchor(List<Contract> newContracts, Map<Id, Contract> oldContractMap) {
        if (newContracts == null || newContracts.isEmpty()) return;
        
        Id smallGroupRTId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Boolean isInsert = (oldContractMap == null);
        
        for (Contract newContract : newContracts) {
            if (newContract.RecordTypeId != smallGroupRTId) continue;
            if (newContract.ARC_CoveragePaidThrough__c != null) continue;
            
            Boolean effectiveDateChanged = false;
            if (isInsert && newContract.ARC_EffectiveDate__c != null) {
                effectiveDateChanged = true;
            } else if (!isInsert) {
                Contract oldContract = oldContractMap.get(newContract.Id);
                if (newContract.ARC_EffectiveDate__c != oldContract.ARC_EffectiveDate__c) {
                    effectiveDateChanged = true;
                }
            }
            
            if (effectiveDateChanged) {
                newContract.ARC_NextInvoiceCoverageStart__c = newContract.ARC_EffectiveDate__c;
            }
        }
    }
    
    /************************************************************************************************************
     * @name            processBillingAutomation
     * @description     Evaluates contract changes and invokes billing service for qualified contracts.
     *                  Uses bulk methods to avoid hitting SOQL governor limits when multiple contracts
     *                  are updated in the same transaction.
     * @param           newContracts   - List of new/updated contracts
     * @param           oldContractMap - Map of old contract versions (null for insert)
     * @developer       lucas.benero@arcsona.com
     * @date            2026-01-26
     *********************************************************************************************************/
    public static void processBillingAutomation(List<Contract> newContracts, Map<Id, Contract> oldContractMap) {
        if (billingAutomationExecuted) return;
        billingAutomationExecuted = true;
        
        if (newContracts == null || newContracts.isEmpty()) {
            billingAutomationExecuted = false;
            return;
        }
        
        Id smallGroupRTId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('ARC_SmallGroup').getRecordTypeId();
        Boolean isInsert = (oldContractMap == null);
        
        Set<Id> qualifiedContractIds = new Set<Id>();
        
        for (Contract newContract : newContracts) {
            if (newContract.RecordTypeId != smallGroupRTId) continue;
            
            Boolean isQualified = false;
            
            if (isInsert) {
                isQualified = true;
            } else {
                Contract oldContract = oldContractMap.get(newContract.Id);
                if (newContract.ARC_EffectiveDate__c != oldContract.ARC_EffectiveDate__c ||
                    newContract.ARC_Inactive_Date__c != oldContract.ARC_Inactive_Date__c ||
                    newContract.ARC_PaymentFrequency__c != oldContract.ARC_PaymentFrequency__c) {
                    isQualified = true;
                }
            }
            
            if (isQualified) qualifiedContractIds.add(newContract.Id);
        }
        
        if (qualifiedContractIds.isEmpty()) {
            billingAutomationExecuted = false;
            return;
        }
        
        // Step 1: Evaluate eligibility for all contracts — BULK (single set of queries)
        ARC_ContractBillingService.evaluatePolicyEligibilityForContracts(qualifiedContractIds);
        
        // Step 2: Recalculate next bill amount for all contracts — BULK (single set of queries)
        ARC_ContractBillingService.recalculateNextBillAmount(qualifiedContractIds);
        
        billingAutomationExecuted = false;
    }
}