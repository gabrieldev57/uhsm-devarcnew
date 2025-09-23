global with sharing class ARC_SortContractsForHeader implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'SortContractsForHeader') {
            SortContractsForHeader(inputMap, outputMap, options);
        }
        return true;
    }

    global static void SortContractsForHeader(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        List<Object> contracts = (List<Object>)inputMap.get('Contracts');
        List<Object> promotions = (List<Object>)inputMap.get('Promotions');

        List<Map<String,Object>> listOfContracts = new List<Map<String,Object>>();
        List<Map<String,Object>> listOfPromotions = new List<Map<String,Object>>();

        List<Map<String, Object>> activeContracts = new List<Map<String, Object>>();
        List<Map<String, Object>> inactiveContracts = new List<Map<String, Object>>();
        List<Map<String, Object>> terminatedContracts = new List<Map<String, Object>>();
        List<Map<String, Object>> voidedContracts = new List<Map<String, Object>>();

        Map<String, Object> finalTerminatedContract = new map<String, Object>();
        Map<String, Object> finalActiveContract = new map<String, Object>();
        Map<String, Object> finalInactveContract = new map<String, Object>();


        for (Object obj : contracts) {
            Map<String,Object> tempMap = (Map<String, Object>)obj;
            listOfContracts.add(tempMap);
        }

        if (promotions != null) {
            for (Object prom : promotions) {
            Map<String,Object> tempMap = (Map<String, Object>)prom;
            listOfPromotions.add(tempMap);
            }
        }

        for (Map<String,Object> currentContract : listOfContracts) {
                //Search if promo Active
                for (Map<String,Object> promoActive : listOfPromotions) {
                   if ( promoActive.get('ContractId') == currentContract.get('contractId') && ! JSON.serialize(currentContract.get('TotalPrice')).contains('Promo') ) {
                    currentContract.put('TotalPrice', (currentContract.get('TotalPrice')) + ' (Promo)');
                   }
                }
                if(Boolean.valueOf(currentContract.get('Status') == 'Activated')){
                    activeContracts.add(currentContract);
                } else if(Boolean.valueOf(currentContract.get('Status') != 'Activated') && Boolean.valueOf(currentContract.get('Status') != 'Draft') && Boolean.valueOf(currentContract.get('Status') != 'Terminated')  && Boolean.valueOf(currentContract.get('Status') != 'Voided') ){
                    inactiveContracts.add(currentContract);
                } else if(Boolean.valueOf(currentContract.get('Status') == 'Terminated')){
                    terminatedContracts.add(currentContract);
                } else if(Boolean.valueOf(currentContract.get('Status') == 'Voided')){
                    voidedContracts.add(currentContract);
            }

        }

        if(activeContracts.size() > 0){
            if(activeContracts.size() > 1){
                Map<String,Object> auxContract = new Map<String,Object>();
                for (Integer i = 0; i < activeContracts.size()-1 ; i++){
                    if(Date.valueOf((String)activeContracts[i].get('EffectiveDate')) < Date.valueOf((String)activeContracts[i+1].get('EffectiveDate'))){
                        auxContract = activeContracts[i];
                    } else if(Date.valueOf((String)activeContracts[i].get('EffectiveDate')) == Date.valueOf((String)activeContracts[i+1].get('EffectiveDate'))){
                        if(Date.valueOf((String)activeContracts[i].get('CreatedDate')) < Date.valueOf((String)activeContracts[i+1].get('CreatedDate'))){
                            auxContract = activeContracts[i];
                        } else {
                            auxContract = activeContracts[i+1];
                        }
                    } else {
                        auxContract = activeContracts[i+1];
                    }
                }
                finalActiveContract = auxContract;
            } else if(activeContracts.size() == 1) {

                finalActiveContract = activeContracts[0];
            }
        }


        if(terminatedContracts.size() > 0){
            if(terminatedContracts.size() > 1){
                Map<String,Object>  auxContract = new Map<String,Object>();
                for (Integer i = 0; i < terminatedContracts.size()-1 ; i++){
                    if ((String)terminatedContracts[i].get('InactiveDate') != null && (String)terminatedContracts[i+1].get('InactiveDate') != null ){
                        if(Date.valueOf((String)terminatedContracts[i].get('InactiveDate')) > Date.valueOf((String)terminatedContracts[i+1].get('InactiveDate'))){
                            auxContract = terminatedContracts[i];
                        } else {
                            auxContract = terminatedContracts[i+1];
                        }
                    } else {
                        if(Date.valueOf((String)terminatedContracts[i].get('CreatedDate')) < Date.valueOf((String)terminatedContracts[i+1].get('CreatedDate'))){
                            auxContract = terminatedContracts[i];
                        } else {
                            auxContract = terminatedContracts[i+1];
                        }
                    }
                }
                finalTerminatedContract = auxContract;
            } else if(terminatedContracts.size() == 1)  {
                finalTerminatedContract = terminatedContracts[0];
            }
        }

        if(inactiveContracts.size() > 0){
                List<Map<String,Object>>  auxAAContract = new List<Map<String,Object>>();
                List<Map<String,Object>>  auxASContract = new List<Map<String,Object>>();
                List<Map<String,Object>>  auxAPContract = new List<Map<String,Object>>();
    
                for (Map<String,Object> currentContract : inactiveContracts) {

                        if(Boolean.valueOf(currentContract.get('Status') == 'Awaiting Activation')){
                            auxAAContract.add(currentContract);
                        } else if(Boolean.valueOf(currentContract.get('Status') == 'Awaiting Approval')){
                            auxAPContract.add(currentContract);
                        } else if(Boolean.valueOf(currentContract.get('Status') == 'Awaiting First Payment')){
                            auxAPContract.add(currentContract);
                        } else if(Boolean.valueOf(currentContract.get('Status') == 'Awaiting Signature')){
                            auxASContract.add(currentContract);
                        }
                }

                if(auxAAContract.size() > 1){
                    Map<String,Object>  auxContract = new Map<String,Object>();
                    for (Integer i = 0; i < auxAAContract.size()-1 ; i++){
                         if(Date.valueOf((String)auxAAContract[i].get('EffectiveDate')) < Date.valueOf((String)auxAAContract[i+1].get('EffectiveDate'))){
                            auxContract = auxAAContract[i];
                        } else if(Date.valueOf((String)auxAAContract[i].get('EffectiveDate')) == Date.valueOf((String)auxAAContract[i+1].get('EffectiveDate'))){
                            if(Date.valueOf((String)auxAAContract[i].get('CreatedDate')) < Date.valueOf((String)auxAAContract[i+1].get('CreatedDate'))){
                                auxContract = auxAAContract[i];
                            } else {
                                auxContract = auxAAContract[i+1];
                            }
                        } else {
                            auxContract = auxAAContract[i+1];
                        }
                    }
                    finalInactveContract = auxContract;
                } else if(auxAAContract.size() == 1){

                    finalInactveContract = auxAAContract[0];
    
                } else if(auxAPContract.size() > 1){
                    Map<String,Object>  auxContract = new Map<String,Object>();
                    for (Integer i = 0; i < auxAPContract.size()-1 ; i++){
                        if(Date.valueOf((String)auxAPContract[i].get('EffectiveDate')) < Date.valueOf((String)auxAPContract[i+1].get('EffectiveDate'))){
              
                            auxContract = auxAPContract[i];
                        } else  if(Date.valueOf((String)auxAPContract[i].get('EffectiveDate')) == Date.valueOf((String)auxAPContract[i+1].get('EffectiveDate'))){
                    
                            if(Date.valueOf((String)auxAPContract[i].get('CreatedDate')) < Date.valueOf((String)auxAPContract[i+1].get('CreatedDate'))){
          
                                auxContract = auxAPContract[i];
                            } else {
  
                                auxContract = auxAPContract[i+1];
                            }
                        } else {
 
                            auxContract = auxAPContract[i+1];
                        }
                    }
                    finalInactveContract = auxContract;
                } else if(auxAPContract.size() == 1){
                    finalInactveContract = auxAPContract[0];

                } else if(auxASContract.size() > 1){
                    Map<String,Object>  auxContract = new Map<String,Object>();
                    for (Integer i = 0; i < auxASContract.size()-1 ; i++){

                        if(Date.valueOf((String)auxASContract[i].get('EffectiveDate')) < Date.valueOf((String)auxASContract[i+1].get('EffectiveDate'))){
 
                            auxContract = auxASContract[i];
                        } else if (Date.valueOf((String)auxASContract[i].get('EffectiveDate')) == Date.valueOf((String)auxASContract[i+1].get('EffectiveDate'))){
  
                            if(Date.valueOf((String)auxASContract[i].get('CreatedDate')) < Date.valueOf((String)auxASContract[i+1].get('CreatedDate'))){
                                auxContract = auxASContract[i];
                            } else {
                                auxContract = auxASContract[i+1];
                            }
                        } else {
                            auxContract = auxASContract[i+1];
                        }
                    }
                    finalInactveContract = auxContract;
                } else if(auxASContract.size() == 1){
                    finalInactveContract = auxASContract[0];
                }
            
        }

        outputMap.put('activeContract', finalActiveContract);
        outputMap.put('terminatedContract', finalTerminatedContract);
        outputMap.put('inactiveContract', finalInactveContract);
        outputMap.put('voidedContracts', voidedContracts);
    }

}