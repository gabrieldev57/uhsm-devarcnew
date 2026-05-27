/*******************************************************************
* @ClassName          :   ARC_BenefitSummaryHandler
* @Description        :   Provides the information to be used in LWC ARC_BenefitSummaryCommunity and ARC_BenefitsSummary360 displayed in the Person Account 360 view
* @MethodName         :   calculateDatesPerMemberAndProgram, getBenefitsSummary360Data, sortProducts, sortObjectsByProducts, getContractFromPA, formatAccountIdsForQuery
********************************************************************/

public without sharing class ARC_BenefitSummaryHandler {
    /*******************************************************************
    * @MethodName         :   calculateDatesPerMemberAndProgram
    * @Description        :   Return a JSON with the information of programs included in Activeated or Awaiting Activation contracts related to the UserId. 
    ********************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Object> calculateDatesPerMemberAndProgram(Id userId) {
        Set<Id> contractsInvolved = new Set<Id>();
        String personFilter;
        Id personAccountId = [SELECT Contact.AccountId FROM User WHERE Id =: userId AND Contact.AccountId != null LIMIT 1]?.Contact.AccountId;
        personFilter = 'vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId = \''+personAccountId+'\'';
        if (personAccountId == null) return null;

        //Get All the Medical GCMP of current member 
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToCm = Database.query(
            'SELECT vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c '+
            'FROM vlocity_ins__GroupCensusMemberPlan__c ' +
            'WHERE '+personFilter+' '+
            'AND (vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = \'Medical\' '+
                'OR vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c  = \'Ancillary\' '+
                +')'+
            'AND ('+
                'vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Activated\' '+
                'OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Awaiting Activation\' '+
                'OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = \'Terminated\' '+
                ')'
        );
        
        //Get Contracts Ids WHERE current member is involved
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : gcmpRelatedToCm) {
            contractsInvolved.add(gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c);
        }

        //Get all GCMP 
        List<vlocity_ins__GroupCensusMemberPlan__c> censusMembesrGroups = [
            SELECT Id,
            Name,
            vlocity_ins__ContractLineId__c, 
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,
            vlocity_ins__ContractLineId__r.Name,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.ARC_EffectiveDate__c, 
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status, 
            vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__TotalPrice__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Name,
            vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c,
            vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c
            FROM vlocity_ins__GroupCensusMemberPlan__c 
            WHERE (
                vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c IN :contractsInvolved
                AND (
                    vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Activated' 
                    OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Awaiting Activation'
                    OR vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status = 'Terminated')
                )
            ORDER BY CreatedDate ASC];
            //ASC means oldest to newest.
        Map<Id,Object> contractMap = new Map<Id,Object>();
        Map<String,Date> plansDateMap = new Map<String,Date>();

        for (vlocity_ins__GroupCensusMemberPlan__c plan : censusMembesrGroups) {
            String censusMemberRelationship = plan?.vlocity_ins__GroupCensusMemberId__r?.ARC_DependentRelationship__c;
            Boolean isActive = plan?.vlocity_ins__GroupCensusMemberId__r?.ARC_ActiveMember__c;
            if (censusMemberRelationship != 'Temporary Newborn' || (censusMemberRelationship == 'Temporary Newborn' && isActive)) {
                if(!plansDateMap.containsKey(plan.Name)) plansDateMap.put(plan.Name,plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_EffectiveDate__c);
                if(plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.Status == 'Awaiting Activation' || plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.Status =='Activated'){
                    //Check if the contract is already in the map xx
                    if(contractMap.containsKey(plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__c)){
                        Map<String,Object> contractDetailsMap = (Map<String,Object>)contractMap.get(plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c);
                        String [] lineItems = (List<String>) contractDetailsMap.get('lineItems');
                        List<Map<String,String>> allProducts = (List<Map<String,String>>)contractDetailsMap.get('products');
                        //Check if it is the same product
                        if(lineItems.contains(plan.vlocity_ins__ContractLineId__c)){
                            for(Map<String,String> productMap:allProducts){
                                //Check if the same line item and add the Member
                                if(productMap.get('id') == plan?.vlocity_ins__ContractLineId__c){
                                    String membersConcat= productMap.get('members') +', '+plan?.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.Account?.Name;
                                    productMap.put('members',membersConcat);
                                    contractDetailsMap.put('products',sortProducts(allProducts));
                                }
                            }
                        }
                        else{
                            Map<String,String> productsMap = new Map<String,String>();
                            productsMap.put('id',plan?.vlocity_ins__ContractLineId__c);
                            productsMap.put('type',plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductType__c == 'Medical'? 'Medical':plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductSubType__c);
                            productsMap.put('subtype',plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductSubType__c);
                            productsMap.put('effectiveDate',plansDateMap.containsKey(plan.Name)?String.valueOf(plansDateMap.get(plan.Name)):String.ValueOf(plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_EffectiveDate__c));
                            productsMap.put('name',plan?.vlocity_ins__ContractLineId__r?.Name);
                            productsMap.put('price',String.valueOf(plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__TotalPrice__c));
                            productsMap.put('members',plan?.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.Account?.Name);

                            String link;
                            String productSubType = plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductSubType__c;
                            String contractLineName = plan?.vlocity_ins__ContractLineId__r?.Name;
                            String baseUrl = 'https://' + ARC_CommunityController.domainURLCommunity + '/members/resource/1/';
                            
                            if (productSubType == 'PPO') {
                                if (contractLineName != null && contractLineName.containsIgnoreCase('Access')) {
                                    link = baseUrl + 'WeShare_Access_Program_Overview';
                                } else {
                                    if (contractLineName != null && contractLineName.containsIgnoreCase('Legacy')) {
                                    link = baseUrl + 'WeShare_Legacy_Program_Overview';
                                    } else {
                                        link = baseUrl + 'WeShare_Program_Overview';
                                    }
                                }
                            } else if (productSubType == 'SMART') {
                                link = baseUrl + 'WeShare_SMART_Care_Program_Overview';
                            } else if (productSubType == 'AIDD') {
                                link = baseUrl + 'WeShare_AIDD_Care_Program_Overview';
                            } else {
                                link = null;
                            }
                            
                            productsMap.put('link', link);
                            lineItems.add(plan?.vlocity_ins__ContractLineId__c);
                            allProducts.add(productsMap);
                            contractDetailsMap.put('lineItems',lineItems);
                            contractDetailsMap.put('products',sortProducts(allProducts));
                        }
                    }
                    else{
                        Map<String,Object> contractDetailsMap = new Map<String, Object>();
                        contractDetailsMap.put('id',plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__c);
                        contractDetailsMap.put('status',plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.Status);
                        contractDetailsMap.put('lineItems',new List<String>{plan?.vlocity_ins__ContractLineId__c});
                        Map<String,String> productsMap = new Map<String,String>();
                        productsMap.put('id',plan?.vlocity_ins__ContractLineId__c);
                        productsMap.put('type',plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductType__c == 'Medical'? 'Medical':plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductSubType__c);
                        productsMap.put('subtype',plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductSubType__c);
                        productsMap.put('effectiveDate',plansDateMap.containsKey(plan.Name)?String.valueOf(plansDateMap.get(plan.Name)):String.ValueOf(plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__r?.ARC_EffectiveDate__c));
                        productsMap.put('name',plan?.vlocity_ins__ContractLineId__r?.Name);
                        productsMap.put('price',String.valueOf(plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__TotalPrice__c));
                        productsMap.put('members',plan?.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.Account?.Name);
                        String link;
                        String productSubType = plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductSubType__c;
                        String contractLineName = plan?.vlocity_ins__ContractLineId__r?.Name;
                        String baseUrl = 'https://' + ARC_CommunityController.domainURLCommunity + '/members/resource/1/';
                        
                        if (productSubType == 'PPO') {
                            if (contractLineName != null && contractLineName.containsIgnoreCase('Access')) {
                                link = baseUrl + 'WeShare_Access_Program_Overview';
                            } else if (contractLineName.containsIgnoreCase('Legacy')) {
                                link = baseUrl + 'WeShare_Legacy_Program_Overview';
                            } else {
                                link = baseUrl + 'WeShare_Program_Overview';
                            }
                        } else if (productSubType == 'SMART') {
                            link = baseUrl + 'WeShare_SMART_Care_Program_Overview';
                        } else if (productSubType == 'AIDD') {
                            link = baseUrl + 'WeShare_AIDD_Care_Program_Overview';
                        } else {
                            link = null;
                        }
                    
                        productsMap.put('link', link);
                        List<Map<String,String>> allProducts = new List<Map<String,String>>{productsMap};
                        contractDetailsMap.put('products',sortProducts(allProducts));
                        contractMap.put(plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ContractId__c,contractDetailsMap);
                    }
                }
            }
        }
        if(contractMap.isEmpty()) return null;
        else  return contractMap.values();
    }  
    
   /*******************************************************************
    * @MethodName         :   getBenefitsSummary360Data
    * @Description        :   Return a JSON with the information of programs tight to the Activated, last activated or future activated contract. 
    ********************************************************************/    
    @AuraEnabled(cacheable=true)
    public static List<Object> getBenefitsSummary360Data(Id personAccountId) {
        String personFilter = 'vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId = \''+personAccountId+'\'';
        Id contractId;
        String contractStatus;
        Map<String,Object> resultMap= new Map<String,Object>();

        //Get All the Medical GCMP of current member with Status != Draft
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToCm = Database.query(
            'SELECT vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status '+
            'FROM vlocity_ins__GroupCensusMemberPlan__c ' +
            'WHERE '+personFilter+' '+
            'AND (vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = \'Medical\' '+
                'OR vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c  = \'Ancillary\' '+
                +')'+
            'AND ('+
                'vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status != \'Draft\')'+
            'ORDER BY CreatedDate ASC'
        ); //ASC means oldest to newest.

        //Get the Active or Last Active ContractId WHERE current member is involved
        Map<String, Integer> statusPriorities = new Map<String, Integer>{
            'Activated' => 1,
            'Awaiting Activation' => 2,
            'Awaiting Approval' => 3,
            'Awaiting First Payment' => 4,
            'Awaiting Signature' => 5,
            'Terminated' => 6,
            'Voided' => 7
        };
        
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : gcmpRelatedToCm) {
            String loopContractStatus = gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status;
            if (statusPriorities.containsKey(loopContractStatus)) {
                // Process the remaining statuses based on priority
                if (contractStatus == null || statusPriorities.get(loopContractStatus) < statusPriorities.get(contractStatus)) {
                    contractId = gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c;
                    contractStatus = loopContractStatus;
                }
            }
        }

        //Get all GCMP involved in that Contract
        List<vlocity_ins__GroupCensusMemberPlan__c> censusMembesrGroups = [
            SELECT Id,
            Name,
            vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c,
            vlocity_ins__ContractLineId__r.Name,
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__Product2Id__c,
            vlocity_ins__ContractLineId__r.vlocity_ins__TotalPrice__c,
            vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Name,
            vlocity_ins__GroupCensusMemberId__r.ARC_ActiveMember__c,
            vlocity_ins__GroupCensusMemberId__r.ARC_DependentRelationship__c
            FROM vlocity_ins__GroupCensusMemberPlan__c 
            WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c =:contractId
            ORDER BY CreatedDate ASC];
            //ASC means oldest to newest.
        Map<Id,Object> products = new Map<Id,Object>();

        for (vlocity_ins__GroupCensusMemberPlan__c plan : censusMembesrGroups) {
            Boolean isActiveMember = plan?.vlocity_ins__GroupCensusMemberId__r?.ARC_ActiveMember__c;
            String memberRelationship = plan?.vlocity_ins__GroupCensusMemberId__r?.ARC_DependentRelationship__c;

            // Only proceed if the member of the GCMP is active or is inactive and is not a temporary newborn
            if (isActiveMember || (isActiveMember == false && memberRelationship != 'Temporary Newborn')) {
                //Check if the product is alread in the Map
                if(products.containsKey(plan.vlocity_ins__ContractLineId__c)){
                    Map<String,String> productMap = (Map<String,String>) products.get(plan.vlocity_ins__ContractLineId__c);
                    String membersConcat= productMap.get('members') +', '+plan?.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.Account?.Name;
                    productMap.put('members',membersConcat);
                    products.put(plan.vlocity_ins__ContractLineId__c,productMap);

                }
                else {
                    Map<String,String> productsMap = new Map<String,String>();
                    productsMap.put('type',plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductType__c);
                    productsMap.put('subtype',plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductSubType__c);
                    productsMap.put('name',plan?.vlocity_ins__ContractLineId__r?.Name);
                    productsMap.put('price',String.valueOf(plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__TotalPrice__c));
                    productsMap.put('members',plan?.vlocity_ins__GroupCensusMemberId__r?.vlocity_ins__ContactId__r?.Account?.Name);

                    String link;
                    String productSubType = plan?.vlocity_ins__ContractLineId__r?.vlocity_ins__ProductSubType__c;
                    String contractLineName = plan?.vlocity_ins__ContractLineId__r?.Name;
                    String baseUrl = 'https://' + ARC_CommunityController.domainURLCommunity + '/members/resource/';
                    
                    if (productSubType == 'PPO') {
                        if (contractLineName != null && contractLineName.containsIgnoreCase('Access')) {
                            link = baseUrl + 'WeShare_Access_Program_Overview_Internal';
                        } else if (contractLineName != null && contractLineName.containsIgnoreCase('Legacy')) {
                            link = baseUrl + 'WeShare_Legacy_Program_Overview_Internal';
                        } else if (contractLineName != null && contractLineName.containsIgnoreCase('Premier')) {
                            link = baseUrl + 'WeShare_Premier_Program_Overview_Internal';
                        } else {
                            link = baseUrl + 'WeShare_Program_Overview_Internal';
                        }
                    } else if (contractLineName != null && contractLineName.containsIgnoreCase('Critical Care')) {
                        link = baseUrl + 'Brochure_Critical_Care';
                    } else if (contractLineName != null && contractLineName.containsIgnoreCase('Accidental Injury')) {
                        link = baseUrl + 'Brochure_Accidental_Injury';
                    } else if (productSubType == 'SMART') {
                        link = baseUrl + 'WeShare_SMART_Care_Program_Overview';
                    } else if (productSubType == 'AIDD') {
                        link = baseUrl + 'WeShare_AIDD_Care_Program_Overview';
                    } else if (contractLineName != null) {
                        if (contractLineName.contains('Gold Essential')) {
                            link = 'GoldEssential';
                        } else if (contractLineName.contains('Gold')) {
                            link = 'Gold';
                        } else if (contractLineName.contains('Bronze Essential')) {
                            link = 'BronzeEssential';
                        } else if (contractLineName.contains('Bronze')) {
                            link = 'Bronze';
                        } else if (contractLineName.contains('Platinum Essential')) {
                            link = 'PlatinumEssential';
                        } else if (contractLineName.contains('Platinum')) {
                            link = 'Platinum';
                        } else if (contractLineName.contains('Silver Essential')) {
                            link = 'SilverEssential';
                        } else if (contractLineName.contains('Silver')) {
                            link = 'Silver';
                        } else if (contractLineName.contains('Fundamental')) {
                            link = 'Fundamental';
                        } else if (contractLineName.contains('Vital')) {
                            link = 'Vital';
                        } else {
                            link = null;
                        }
                    } else {
                        link = null;
                    }

                    productsMap.put('link', link);
                    products.put(plan.vlocity_ins__ContractLineId__c,productsMap);
                }
            }    
        }
        if(products.isEmpty()) return null;
        else return sortObjectsByProducts(products.values());
    }  

   /*******************************************************************
    * @MethodName         :   sortProducts
    * @Description        :   Receives a List<Map<String,String>> and sort the procucts returning a list with this order Medical > Smart > Aidd. 
    ********************************************************************/
    private static List<Map<String,String>> sortProducts(List<Map<String,String>> products){
        List<Map<String,String>> sortedProducts = new List<Map<String,String>>();
        for(Map<String,String> product:products){
            if(product.get('type') == 'Medical') sortedProducts.add(product);
        }
        for(Map<String,String> product:products){
            if(product.get('subtype') == 'SMART') sortedProducts.add(product);
        }
        for(Map<String,String> product:products){
            if(product.get('subtype') == 'AIDD') sortedProducts.add(product);
        }
        return sortedProducts;
    }
    /*******************************************************************
    * @MethodName         :   sortObjectsByProducts
    * @Description        :   Receives a List<Object> and sort the procucts returning a list with this order Medical > Smart > Aidd. 
    ********************************************************************/
    private static List<Object> sortObjectsByProducts(List<Object> products){
        List<Object>  sortedProducts = new List<Object> ();
        for(Object product:products){
            Map<String, Object> productMap = (Map<String, Object>) product;
            if((String)productMap.get('type') == 'Medical') sortedProducts.add(product);
        }
        for(Object product:products){
            Map<String, Object> productMap = (Map<String, Object>) product;
            if((String) productMap.get('subtype') == 'SMART') sortedProducts.add(product);
        }
        for(Object product:products){
            Map<String, Object> productMap = (Map<String, Object>) product;
            if((String) productMap.get('subtype') == 'AIDD') sortedProducts.add(product);
        }
        return sortedProducts;
    }

    /*******************************************************************
    * @MethodName         :   getContractFromPA
    * @Description        :   Return a JSON with the information of programs tight to the Activated, last activated or future activated contract. 
    ********************************************************************/    
    @InvocableMethod(label='Get Contract From Person Account' description='Get the current contract related to a Person Account' category='Account')
    public static List<Id> getBenefitsSummary360Data(List<Id> personAccountId) {
        if(personAccountId.isEmpty()) return null;
        String personFilter = 'vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId IN '+formatAccountIdsForQuery(personAccountId);
        List<Id> contractIds = new List<Id>();
        Map<Id,Contract> personAccountContractMap = new Map<Id,Contract>();

        //Get All the Medical GCMP related to the input person accounts with Status != Draft
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpRelatedToCm = Database.query(
            'SELECT vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c, vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status, '+
            'vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId '+
            'FROM vlocity_ins__GroupCensusMemberPlan__c ' +
            'WHERE '+personFilter+' '+
            'AND (vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c = \'Medical\' '+')'+
            'AND (vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status != \'Draft\')'+
            'ORDER BY CreatedDate ASC'
        ); //ASC means oldest to newest.

        //Get the Active or Last Active ContractId WHERE current member is involved
        Map<String, Integer> statusPriorities = new Map<String, Integer>{
            'Activated' => 1,
            'Awaiting Activation' => 2,
            'Awaiting Approval' => 3,
            'Awaiting First Payment' => 4,
            'Awaiting Signature' => 5,
            'Terminated' => 6,
            'Voided' => 7
        };
        
        for (vlocity_ins__GroupCensusMemberPlan__c gcmp : gcmpRelatedToCm) {
            Id loopContractId = gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c;
            String loopContractStatus = gcmp.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__r.Status;
            //Check if the contract status is included in the priorities.
            if (statusPriorities.containsKey(loopContractStatus)) {
                Contract mostPriorityContract = personAccountContractMap.containsKey(gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId)?personAccountContractMap.get(gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId):null;
                //Process the remaining statuses based on priority
                if (mostPriorityContract == null || statusPriorities.get(loopContractStatus) < statusPriorities.get(mostPriorityContract.Status)) {
                    mostPriorityContract = new Contract(Id =loopContractId, Status = loopContractStatus);
                    personAccountContractMap.put(gcmp.vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.AccountId,mostPriorityContract);
                }
            }
        }
        //Return the contractIds in the same order that the personAccountIds were received
        for(Id paId: personAccountId){
            if(personAccountContractMap.containsKey(paId)) contractIds.add(personAccountContractMap.get(paId)?.Id);
            else contractIds.add(null);
            
        }
        return contractIds;
    }

    /*******************************************************************
    * @MethodName         :   formatAccountIdsForQuery
    * @Description        :   Format the list of ids from this (22321545390r3,2232154533213213) to this ('22321545390r3','2232154533213213')
    ********************************************************************/    
    public static String formatAccountIdsForQuery(List<Id> personAccountIds){
        if(personAccountIds.isEmpty()) return '';
        Integer counter = personAccountIds.size();
        String result = '(\'';
        for(Id paId: personAccountIds){
            if(counter == 1) result += paId+'\')';
            else result += paId+'\',\'';
            counter--;
        }
        return result;
    }
}