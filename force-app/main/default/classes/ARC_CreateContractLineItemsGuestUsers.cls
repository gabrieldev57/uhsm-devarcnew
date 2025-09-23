global without sharing class ARC_CreateContractLineItemsGuestUsers implements vlocity_ins.VlocityOpenInterface {
    
    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'CreateContractLineItems') {
            CreateContractLineItems(inputMap, outputMap, options);
        }
        if (methodName == 'CreateMultiContractLineItems') {
            CreateMultiContractLineItems(inputMap, outputMap, options);
        }
        return true;
    }

    public static void CreateContractLineItems(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {

        Map<String,Object> firstList = (Map<String,Object>)inputMap.get('contractJson');
        String contractId = String.valueOf(inputMap.get('ContractId'));
                
        Contract con = [SELECT Id, StartDate, EndDate, ARC_EffectiveDate__c, ContractTerm, AccountId FROM Contract WHERE Id = :contractId];
        Account acc = [SELECT Id, Name, PersonContactId FROM Account WHERE Id =: con.AccountId ORDER BY CreatedDate DESC LIMIT 1];
                

        //GET OLD CLI AND DELETE THEM IF EXISTS (TO PREVENT DUPLICATES)
        List<vlocity_ins__ContractLineItem__c> oldCLI = [SELECT Id FROM vlocity_ins__ContractLineItem__c WHERE vlocity_ins__ContractId__c = :contractId];
        if (oldCLI.size() > 0) {
            delete oldCLI;
        }


        Map<String,Object> listObj = (Map<String,Object>)firstList.get('productConfigurationDetail');
        List<Object> listRecords = (List<Object>)listObj.get('records');
        Map<String,Set<String>> CLI_members = new Map<String,Set<String>>();
        Map<Integer, List<vlocity_ins__GroupCensusMemberPlan__c>> index_CLI_gcmp = new Map<Integer, List<vlocity_ins__GroupCensusMemberPlan__c>>();

        List<vlocity_ins__ContractLineItem__c> listOfCli = new List<vlocity_ins__ContractLineItem__c>();
        List<vlocity_ins__ContractLineItem__c> listOfChildRecords = new List<vlocity_ins__ContractLineItem__c>();
        Integer indexCLI = 0;
        for (Object m : listRecords) {
            Map<String, Object> tempMap = (Map<String, Object>)m;
            vlocity_ins__ContractLineItem__c parentCLI = new vlocity_ins__ContractLineItem__c();
            List<vlocity_ins__GroupCensusMemberPlan__c> gcmp = new List<vlocity_ins__GroupCensusMemberPlan__c>();
            for (String record : tempMap.keySet()) {
                parentCLI.Name = String.valueOf(tempMap.get('Name'));
                parentCLI.vlocity_ins__Product2Id__c = String.valueOf(tempMap.get('productId'));
                parentCLI.vlocity_ins__UnitPrice__c = Decimal.valueOf(String.valueOf(tempMap.get('Price')));
                parentCLI.vlocity_ins__Quantity__c = 1;
                parentCLI.vlocity_ins__ContractId__c = con.Id;
                parentCLI.vlocity_ins__AccountId__c = acc.Id;
                parentCLI.vlocity_ins__EffectiveEndDate__c = con.EndDate;
            }
            for (Object calcRes : (List<Object>)((Map<String,Object>)((List<Object>)tempMap.get('RawPriceData'))[0]).get('calculationResults')) {
                gcmp.add(new vlocity_ins__GroupCensusMemberPlan__c(
                    Name = parentCLI.Name,
                    vlocity_ins__GroupCensusMemberId__c=(String)((Map<String, Object>)calcRes).get('CensusMemberId')
                ));
            }
            listOfCli.add(parentCLI);

            Map<String,Object> listObjChild = (Map<String,Object>)tempMap.get('childProducts');
            List<Object> listRecordsChild = (List<Object>)listObjChild.get('records');
            for (Object mapa : listRecordsChild) {
                Map<String, Object> tempMapChild = (Map<String, Object>)mapa;
                vlocity_ins__ContractLineItem__c childCLI = new vlocity_ins__ContractLineItem__c();
                for (String record : tempMapChild.keySet()) {
                    if(tempMapChild.containsKey('isSelected')){
                        if (!tempMapChild.containsKey('lastNonOptional') && Boolean.valueOf(tempMapChild.get('isSelected')) == true) {
                            
                            childCLI.Name = String.valueOf(tempMapChild.get('Name'));
                            childCLI.vlocity_ins__Product2Id__c = String.valueOf(tempMapChild.get('productId'));
                            childCLI.vlocity_ins__AccountId__c = acc.Id;
                            //childCLI.vlocity_ins__UnitPrice__c = Decimal.valueOf(String.valueOf(tempMapChild.get('Price')));
                            childCLI.vlocity_ins__ProductChildItemId__c = String.valueOf(tempMapChild.get('pciId'));
                            childCLI.vlocity_ins__ContractId__c = con.Id;
                            childCLI.vlocity_ins__EffectiveEndDate__c = con.EndDate;
                        }
                    }
                }
                // listOfChildRecords.add(childCLI);
            }
            index_CLI_gcmp.put(indexCLI, gcmp);
            indexCLI++;
        }

        insert listOfCli;
        

        List<vlocity_ins__GroupCensusMemberPlan__c> listOfGcmp = new List<vlocity_ins__GroupCensusMemberPlan__c>();

        indexCLI = 0;
        for (vlocity_ins__ContractLineItem__c cli : listOfCli) {
            for (vlocity_ins__GroupCensusMemberPlan__c gcmp : index_CLI_gcmp.get(indexCLI)) {
                gcmp.vlocity_ins__ContractLineId__c = cli.Id;
                listOfGcmp.add(gcmp);
            }
            indexCLI++;            
        }

        insert listOfGcmp;
        
        Map<String, String> parentCliIds = new Map<String, String>();
        for (vlocity_ins__ContractLineItem__c cli : listOfCli) {
            parentCliIds.put(cli.vlocity_ins__Product2Id__c,cli.Id);
        }
        for (Object m : listRecords) {
            Map<String, Object> tempMap = (Map<String, Object>)m;
            String parentId;
            for (String record : tempMap.keySet()) {
                if (parentCliIds.keySet().contains(String.valueOf(tempMap.get('productId')))) {
                    parentId = parentCliIds.get(String.valueOf(tempMap.get('productId')));
                }
            }
            Map<String,Object> listObjChild = (Map<String,Object>)tempMap.get('childProducts');
            List<Object> listRecordsChild = (List<Object>)listObjChild.get('records');
            for (Object mapa : listRecordsChild) {
                Map<String, Object> tempMapChild = (Map<String, Object>)mapa;
                integer i = 0;
                if( tempMapChild.containsKey('isSelected') ){
                    if (!tempMapChild.containsKey('lastNonOptional') && Boolean.valueOf(tempMapChild.get('isSelected')) == true) {
                        vlocity_ins__ContractLineItem__c childCLI = new vlocity_ins__ContractLineItem__c();
                            childCLI.Name = String.valueOf(tempMapChild.get('Name'));
                            childCLI.vlocity_ins__Product2Id__c = String.valueOf(tempMapChild.get('productId'));
                            childCLI.vlocity_ins__ProductId__c = String.valueOf(tempMap.get('productId'));
                            //childCLI.vlocity_ins__UnitPrice__c = Decimal.valueOf(String.valueOf(tempMapChild.get('Price')));
                            childCLI.vlocity_ins__ProductChildItemId__c = String.valueOf(tempMapChild.get('pciId'));
                            childCLI.vlocity_ins__ContractId__c = con.Id;
                            childCLI.vlocity_ins__AccountId__c = acc.Id;
                            childCLI.vlocity_ins__EffectiveEndDate__c = con.EndDate;
                            childCLI.vlocity_ins__ParentItemId__c = parentId;
                        listOfChildRecords.add(childCLI);
                    }
                }
                if (!tempMapChild.containsKey('lastNonOptional')) {
                    System.debug(i);
                }
            }
        }
        insert listOfChildRecords;

        Set<Id> CliIds = new Set<Id>();
        Set<Id> CliIdsChild = new Set<Id>();
        
        for (vlocity_ins__ContractLineItem__c cli : listOfCli) {
            CliIds.add(cli.Id);
        }

        for (vlocity_ins__ContractLineItem__c cli : listOfChildRecords) {
            CliIdsChild.add(cli.Id);
        }

        List<vlocity_ins__ContractLineItem__c> queryListOfCLI = [SELECT Id, vlocity_ins__ProductType__c FROM vlocity_ins__ContractLineItem__c WHERE Id IN :CliIds];
        List<vlocity_ins__ContractLineItem__c> queryListOfChildCLI = [SELECT Id, vlocity_ins__ProductType__c, vlocity_ins__ParentItemId__c FROM vlocity_ins__ContractLineItem__c WHERE Id IN :CliIdsChild];

        Map<String, String> mapParentId = new Map<String, String>();
        for (vlocity_ins__ContractLineItem__c cli : queryListOfCLI) {
            mapParentId.put(String.valueOf(cli.vlocity_ins__ProductType__c), String.valueOf(cli.Id));
        }
        
        for (vlocity_ins__ContractLineItem__c cli : queryListOfChildCLI) {

            if (mapParentId.keySet().contains(cli.vlocity_ins__ProductType__c)) {
                cli.vlocity_ins__ParentItemId__c = mapParentId.get(cli.vlocity_ins__ProductType__c);
            }
        }
        con.CustomerSignedId = acc.PersonContactId;
        
        update con;
        update queryListOfChildCLI;

        //ADDS CHILD PRODUCTS TO CONTRACT


       
        outputMap.put('ContractId', contractId);
    }


    public static void CreateMultiContractLineItems(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        Set<String> setOfContractIds = new Set<String>();
        Set<String> setOfAccountIds = new Set<String>();
        List<Object> obj_listContractJson = new List<Object>();
        List<Map<String,Object>> listContractJson = new List<Map<String,Object>>();

        System.debug('aa');
        if(inputMap.get('listContractJson') != ''){
            obj_listContractJson = (List<Object>)JSON.deserializeUntyped(JSON.serialize(inputMap.get('listContractJson')));
            System.debug('a');
            for (Object itemObj : obj_listContractJson) {
                System.debug(itemObj);
                Map<String, Object> item = (Map<String, Object>) itemObj;
                listContractJson.add(item);
            }
        }
        System.debug(listContractJson);
        for (Map<String,Object> contractJsons : listContractJson) {
            setOfContractIds.add((String)contractJsons.get('ContractId'));
        }

        


        
       
        List<Contract> listCon = [SELECT Id, StartDate, EndDate, ARC_EffectiveDate__c, ContractTerm, AccountId FROM Contract WHERE Id IN :setOfContractIds];
        system.debug('aca va la list');
        system.debug(listCon);

       
        System.debug('listContractJson? ' + listContractJson);
        List<vlocity_ins__ContractLineItem__c> listOfCli = new List<vlocity_ins__ContractLineItem__c>();
        List<vlocity_ins__ContractLineItem__c> listOfChildRecords = new List<vlocity_ins__ContractLineItem__c>();
        List<Map<String,Object>> listOfCLI_output = new List<Map<String,Object>>(); 
        
        for (Map<String,Object> contractJsons : listContractJson) {
            System.debug('dentro del for contractJsons?? ' + contractJsons);
            System.debug('Enseguida desp del for:'+(String)contractJsons.get('ContractId'));
            Map<String,Object> contractJson = (Map<String,Object>)contractJsons.get('contractJson');
            System.debug('Aqui tenemos el CONTRACTJSON!'+contractJson);
            for(Contract c : listCon){
                System.debug('contract' + listCon);
                System.debug(c.Id);
                if(c.Id==(String)contractJsons.get('ContractId')){
                    System.debug((Map<String,Object>)contractJson.get('productConfigurationDetail'));
                    Map<String,Object> listObj = (Map<String,Object>)contractJson.get('productConfigurationDetail');
                    List<Object> recordsList = new List<Object>();
                    try {
                        System.debug((List<Object>)listObj.get('records'));
                        recordsList = (List<Object>)listObj.get('records');
                    } catch (Exception e) {
                        recordsList.add(listObj.get('records'));
                    }
                    List<Object> listRecords = recordsList;
                    for (Object m : listRecords) {
                        Map<String, Object> tempMap = (Map<String, Object>)m;
                        vlocity_ins__ContractLineItem__c parentCLI = new vlocity_ins__ContractLineItem__c();
                        for (String record : tempMap.keySet()) {
                            parentCLI.Name = String.valueOf(tempMap.get('Name'));
                            parentCLI.vlocity_ins__Product2Id__c = String.valueOf(tempMap.get('productId'));
                            parentCLI.vlocity_ins__UnitPrice__c = Decimal.valueOf(String.valueOf(tempMap.get('Price')));
                            parentCLI.vlocity_ins__Quantity__c = 1;
                            parentCLI.vlocity_ins__ContractId__c = c.Id;
                            parentCLI.vlocity_ins__AccountId__c = c.AccountId;
                            parentCLI.vlocity_ins__EffectiveEndDate__c = c.EndDate;
                        }
                        
                        listOfCli.add(parentCLI);
            
                        Map<String,Object> listObjChild = (Map<String,Object>)tempMap.get('childProducts');
                        List<Object> listRecordsChild = (List<Object>)listObjChild.get('records');
                        for (Object mapa : listRecordsChild) {
                            Map<String, Object> tempMapChild = (Map<String, Object>)mapa;
                            vlocity_ins__ContractLineItem__c childCLI = new vlocity_ins__ContractLineItem__c();
                            for (String record : tempMapChild.keySet()) {
                                if(tempMapChild.containsKey('isSelected')){
                                    if (!tempMapChild.containsKey('lastNonOptional') && Boolean.valueOf(tempMapChild.get('isSelected')) == true) {
                
                                        childCLI.Name = String.valueOf(tempMapChild.get('Name'));
                                        childCLI.vlocity_ins__Product2Id__c = String.valueOf(tempMapChild.get('productId'));
                                        childCLI.vlocity_ins__AccountId__c = c.AccountId;
                                        //childCLI.vlocity_ins__UnitPrice__c = Decimal.valueOf(String.valueOf(tempMapChild.get('Price')));
                                        childCLI.vlocity_ins__ProductChildItemId__c = String.valueOf(tempMapChild.get('pciId'));
                                        childCLI.vlocity_ins__ContractId__c = c.Id;
                                        childCLI.vlocity_ins__EffectiveEndDate__c = c.EndDate;
                                    }
                                }
                            }
                            // listOfChildRecords.add(childCLI);
                        }
                    }
                }
            }
        }


        /*for(Contract c : listCon){
            for (Object m : listRecords) {
                Map<String, Object> tempMap = (Map<String, Object>)m;
                vlocity_ins__ContractLineItem__c parentCLI = new vlocity_ins__ContractLineItem__c();
                for (String record : tempMap.keySet()) {
                    parentCLI.Name = String.valueOf(tempMap.get('Name'));
                    parentCLI.vlocity_ins__Product2Id__c = String.valueOf(tempMap.get('productId'));
                    parentCLI.vlocity_ins__UnitPrice__c = Decimal.valueOf(String.valueOf(tempMap.get('Price')));
                    parentCLI.vlocity_ins__ContractId__c = c.Id;
                    parentCLI.vlocity_ins__AccountId__c = c.AccountId;
                    parentCLI.vlocity_ins__EffectiveEndDate__c = c.EndDate;
                }
                listOfCli.add(parentCLI);
    
                Map<String,Object> listObjChild = (Map<String,Object>)tempMap.get('childProducts');
                List<Object> listRecordsChild = (List<Object>)listObjChild.get('records');
                for (Object mapa : listRecordsChild) {
                    Map<String, Object> tempMapChild = (Map<String, Object>)mapa;
                    vlocity_ins__ContractLineItem__c childCLI = new vlocity_ins__ContractLineItem__c();
                    for (String record : tempMapChild.keySet()) {
                        if(tempMapChild.containsKey('isSelected')){
                            if (!tempMapChild.containsKey('lastNonOptional') && Boolean.valueOf(tempMapChild.get('isSelected')) == true) {
        
                                childCLI.Name = String.valueOf(tempMapChild.get('Name'));
                                childCLI.vlocity_ins__Product2Id__c = String.valueOf(tempMapChild.get('productId'));
                                childCLI.vlocity_ins__AccountId__c = c.AccountId;
                                //childCLI.vlocity_ins__UnitPrice__c = Decimal.valueOf(String.valueOf(tempMapChild.get('Price')));
                                childCLI.vlocity_ins__ProductChildItemId__c = String.valueOf(tempMapChild.get('pciId'));
                                childCLI.vlocity_ins__ContractId__c = c.Id;
                                childCLI.vlocity_ins__EffectiveEndDate__c = c.EndDate;
                            }
                        }
                    }
                    // listOfChildRecords.add(childCLI);
                }
            }

        }*/
     
   
        insert listOfCli;   
        
        Map<String, String> parentCliIds = new Map<String, String>();
        for (vlocity_ins__ContractLineItem__c cli : listOfCli) {
            parentCliIds.put(cli.vlocity_ins__Product2Id__c,cli.Id);
            if(cli.vlocity_ins__ParentItemId__c==null || cli.vlocity_ins__ParentItemId__c==''){
                Map<String,Object> CLI_map = new Map<String,Object>();
                CLI_map.put('ContractLineItemId',cli.Id);
                CLI_map.put('Name',cli.Name);
                CLI_map.put('ProductId',cli.vlocity_ins__Product2Id__c);
                CLI_map.put('ContractId',cli.vlocity_ins__ContractId__c);
                listOfCLI_output.add(CLI_map);
            }
        }

        for (Map<String,Object> contractJsons : listContractJson) {
            Map<String,Object> contractJson = (Map<String,Object>)contractJsons.get('contractJson');
            System.debug('Aqui tenemos el CONTRACTJSON!'+contractJson);
            for(Contract c : listCon){
                if(c.Id==(String)contractJsons.get('ContractId')){
                    Map<String,Object> listObj = (Map<String,Object>)contractJson.get('productConfigurationDetail');
                    List<Object> listRecords = new List<Object>();
                    try {
                        listRecords = (List<Object>)listObj.get('records');
                    } catch (Exception e) {
                        listRecords.add(listObj.get('records'));
                    }
                    for (Object m : listRecords) {
                        Map<String, Object> tempMap = (Map<String, Object>)m;
                        String parentId;
                        for (String record : tempMap.keySet()) {
                            if (parentCliIds.keySet().contains(String.valueOf(tempMap.get('productId')))) {
                                parentId = parentCliIds.get(String.valueOf(tempMap.get('productId')));
                            }
                        }
                        Map<String,Object> listObjChild = (Map<String,Object>)tempMap.get('childProducts');
                        List<Object> listRecordsChild = (List<Object>)listObjChild.get('records');
                        for (Object mapa : listRecordsChild) {
                            Map<String, Object> tempMapChild = (Map<String, Object>)mapa;
                            integer i = 0;
                            if( tempMapChild.containsKey('isSelected') ){
                                if (!tempMapChild.containsKey('lastNonOptional') && Boolean.valueOf(tempMapChild.get('isSelected')) == true) {
                                    vlocity_ins__ContractLineItem__c childCLI = new vlocity_ins__ContractLineItem__c();
                                        childCLI.Name = String.valueOf(tempMapChild.get('Name'));
                                        childCLI.vlocity_ins__Product2Id__c = String.valueOf(tempMapChild.get('productId'));
                                        childCLI.vlocity_ins__ProductId__c = String.valueOf(tempMap.get('productId'));
                                        //childCLI.vlocity_ins__UnitPrice__c = Decimal.valueOf(String.valueOf(tempMapChild.get('Price')));
                                        childCLI.vlocity_ins__ProductChildItemId__c = String.valueOf(tempMapChild.get('pciId'));
                                        childCLI.vlocity_ins__ContractId__c = c.Id;
                                        childCLI.vlocity_ins__AccountId__c = c.AccountId;
                                        childCLI.vlocity_ins__EffectiveEndDate__c = c.EndDate;
                                        childCLI.vlocity_ins__ParentItemId__c = parentId;
                                    listOfChildRecords.add(childCLI);
                                }
                            }
                            if (!tempMapChild.containsKey('lastNonOptional')) {
                                System.debug(i);
                            }
                        }
                    }
                }
            }

        }

        insert listOfChildRecords;

        Set<Id> CliIds = new Set<Id>();
        Set<Id> CliIdsChild = new Set<Id>();
        
        for (vlocity_ins__ContractLineItem__c cli : listOfCli) {
            CliIds.add(cli.Id);
        }

        for (vlocity_ins__ContractLineItem__c cli : listOfChildRecords) {
            CliIdsChild.add(cli.Id);
        }

        List<vlocity_ins__ContractLineItem__c> queryListOfCLI = [SELECT Id, vlocity_ins__ProductType__c FROM vlocity_ins__ContractLineItem__c WHERE Id IN :CliIds];
        List<vlocity_ins__ContractLineItem__c> queryListOfChildCLI = [SELECT Id, vlocity_ins__ProductType__c, vlocity_ins__ParentItemId__c FROM vlocity_ins__ContractLineItem__c WHERE Id IN :CliIdsChild];

        Map<String, String> mapParentId = new Map<String, String>();
        for (vlocity_ins__ContractLineItem__c cli : queryListOfCLI) {
            mapParentId.put(String.valueOf(cli.vlocity_ins__ProductType__c), String.valueOf(cli.Id));
        }
        
        for (vlocity_ins__ContractLineItem__c cli : queryListOfChildCLI) {

            if (mapParentId.keySet().contains(cli.vlocity_ins__ProductType__c)) {
                cli.vlocity_ins__ParentItemId__c = mapParentId.get(cli.vlocity_ins__ProductType__c);
            }
        }


        /*--------------arreglar---------------- */
        for(Contract con : listCon){
            setOfAccountIds.add(con.AccountId);
        }
        List<Account> accs = [SELECT Id, Name, PersonContactId FROM Account WHERE Id IN :setOfAccountIds];
        for(Contract con : listCon){
            for(Account acc : accs){
                if(acc.Id ==con.AccountId){
                    con.CustomerSignedId = acc.PersonContactId;
                }
            }
        }
        update listCon;
        update queryListOfChildCLI;
       
        

        outputMap.put('ContractLineItems',listOfCLI_output);
       
    }

}