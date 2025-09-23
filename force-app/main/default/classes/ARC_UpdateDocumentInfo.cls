global with sharing class ARC_UpdateDocumentInfo implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'updateDocInfo') {
            updateDocInfo(inputMap, outputMap, options);
        }
     
        return true;
    }


    public static Boolean updateDocInfo(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){
        List<Object> ProductsList = (List<Object>)inputMap.get('DocumentInfo');
        List<Map<String,Object>> outList= new  List<Map<String,Object>>();
        Integer i = 0;
        Decimal totalSumPrices = 0;
        for(Object key: ProductsList){
            Map<String,Object> outMap= new Map<String,Object>();
            Map<String,Object> Aux = (Map<String,Object>)key;
            outMap.put('TotalPrice', Aux.get('TotalPrice'));
            outMap.put('Name', Aux.get('Name'));
            Object Members = Aux.get('PrimaryMembersList');
            List<Object> MembersList = (List<Object>)Members;
            List<Map<String,Object>> primaryMemberList = new  List<Map<String,Object>>();
            
            for(Object key2: MembersList){
                 Map<String,Object> Member = (Map<String,Object>)key2;
                 if(Member.get('IsPrimary') == true && Member.containsKey('Price')){
                    Decimal familiyTotal = 0;
                    String primaryId = (String)Member.get('Id');
                    List<Map<String,Object>> DepMemberList = new  List<Map<String,Object>>();

                    for(Object key3: MembersList){
                        Map<String,Object> Dependant = (Map<String,Object>)key3;
                        if(Dependant.get('RelatedId') == primaryId){
                            DepMemberList.add(Dependant);
                            familiyTotal += (Decimal)Dependant.get('Price');
                        }
                    }

                    if(DepMemberList.isEmpty() || DepMemberList == null) {
                        Member.put('IF_HasDependants', false);
                    } else {
                        Member.put('IF_HasDependants', true);
                    }
                    Member.put('familyTotal', familiyTotal+(Decimal)Member.get('Price'));
                    Member.put('Dependants', DepMemberList);
                    primaryMemberList.add(Member);
                    }      
            }
        
            Decimal auxDecimal = (Decimal)Aux.get('TotalPrice');
            totalSumPrices = totalSumPrices+auxDecimal;


         
            outMap.put('PrimaryMembers',primaryMemberList);
            outList.add(outMap);  
            i++;   
        }
        outputMap.put('output', outList);
        outputMap.put('total', totalSumPrices);


    return true;
    }

}