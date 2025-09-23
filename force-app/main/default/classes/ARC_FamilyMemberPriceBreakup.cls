global with sharing class ARC_FamilyMemberPriceBreakup implements vlocity_ins.VlocityOpenInterface {

    public Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options) {
        if (methodName == 'FamilyMemberPriceBreakup') {
            FamilyMemberPriceBreakup(inputMap, outputMap, options);
        }
     
        return true;
    }


    public static Boolean FamilyMemberPriceBreakup(Map<String,Object> inputMap, Map<String,Object> outputMap, Map<String,Object> options){

        List<Object> LoopList = (List<Object>)inputMap.get('familyMembers');
        List<Map<String,Object>> outList = new List<Map<String,Object>>();
        List<Map<String,Object>> ListMembers = new List<Map<String,Object>>();
        Map<String,Object> test = new Map<String,Object>();
        test.put('Id', 1);
        ListMembers.add(test);
        Map<String,Object> outMap= new Map<String,Object>();

        for(Object key: LoopList){
             Map<String,Object> Aux = (Map<String,Object>)key;
            Object Members = Aux.get('PrimaryMembersList');
            //Previous code
            //List<Object> MembersList = (List<Object>)Members;
            //
            //New Code
            List<Object> MembersList = new List<Object>();
            MembersList.add(Members);
            
            for(Object key2: MembersList){
                Map<String,Object> MapMember = new Map<String,Object>();
                Map<String,Object> Member = (Map<String,Object>)key2;
                Decimal auxPrice = (Decimal)Member.get('Price');
                for(map<String,Object> auxMap : ListMembers){
                    if(auxMap.get('Id') <> Member.get('Id')){
                        MapMember.put('Id', Member.get('Id'));
                        MapMember.put('Price', (Decimal)Member.get('Price'));
                        MapMember.put('Relationship', Member.get('Relationship'));
                        MapMember.put('Birthdate', Member.get('Birthdate'));
                        MapMember.put('Name', Member.get('FirstName') + ' ' + Member.get('LastName'));
                    }

                    if(auxMap.get('Id') == Member.get('Id')){
                        MapMember.clear();
                        Decimal priceRemoved = (Decimal)auxMap.Remove('Price');
                        auxMap.put('Price', priceRemoved+auxPrice);
                        break;
                    }
                   
                }
                if(!MapMember.isEmpty()){
                    ListMembers.add(MapMember);
                }
                
            }
        }
        ListMembers.remove(0);
        outputMap.put('MemberList', ListMembers);
    return true;
    }
}