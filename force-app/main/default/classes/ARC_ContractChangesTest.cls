@isTest
public class ARC_ContractChangesTest {
   
    @isTest 
    static void processChanges(){
        
        Map<String,Object> m = new Map<String, Object>();
        // Fields for Remove Member
        m.put('CHK_Delete', true);
        m.put('TXT_FirstNameEB', 'Test');
        m.put('TXT_LastNameEB', 'Test');
        // Fields for Add Member
        m.put('isNew', true);
        m.put('vlocity_ins__FirstName__c', 'Test');
        m.put('vlocity_ins__LastName__c', 'Test');
        List<Object> members = new List<Object>();
        members.add(m);
        
        Map<String,Object> s = new Map<String, Object>();
        s.put('Type__c', 'Ancillary');
        s.put('Name', 'Test');
        Map<String,Object> p = new Map<String, Object>();
        p.put('selectedProduct', s);
        List<Object> productLists = new List<Object>();
        productLists.add(p);

        Map<String, Object> c = new Map<String, Object>();
        c.put('SingleReason', 'Remove Member;Add Member;Program Upgrade;Add Ancillary Product;Remove Ancillary');
        c.put('effectiveDate', '2023-01-01');
        c.put('MedicalName', 'Medical');
        c.put('RemovedMembers', members);
        c.put('auxSavedMembers', members);
        c.put('productList', productLists);
        List<Object> changesForContracts = new List<Object>();
        changesForContracts.add(c);

        Map<String,Object> inputMap = new Map<String, Object>();
        Map<String,Object> options = new Map<String, Object>(); 
        Map<String,Object> outputMap = new Map<String, Object>();

        inputMap.put('changesForContracts', changesForContracts);
        
        new ARC_ContractChanges().invokeMethod('processChanges', inputMap, outputMap, options);
    }


    @isTest
    private static void processChangesResendContractTest(){
        Map<String,Object> inputMap = new Map<String, Object>();
        Map<String,Object> options = new Map<String, Object>(); 
        Map<String,Object> outputMap = new Map<String, Object>();
        
        List<Map<String,Object>> memberNewListMap = new  List<Map<String,Object>>();
        List<Map<String,Object>> memberOldListMap = new  List<Map<String,Object>>();

        String contractReason = 'Program Upgrade;Add Member;Remove Member;Add Newborn';
        String effectiveDate = '12/04/2023';
        String newCoreProgram = 'New Program Name';
        List<vlocity_ins__GroupCensusMember__c> censusmemberListOld = ARC_TestUtility.createTestCensusMember(3);  
        for(Integer i = 0 ; i<censusmemberListOld.size(); i++){
            censusmemberListOld[i].vlocity_ins__FirstName__c = 'Test Census Member ';
            censusmemberListOld[i].vlocity_ins__LastName__c = String.valueOf(i);
            censusmemberListOld[i].vlocity_ins__Birthdate__c = System.today().addYears(-20);
        }       
        update censusmemberListOld;
        censusmemberListOld = [SELECT id, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, Name, vlocity_ins__CensusId__c, vlocity_ins__Birthdate__c FROM vlocity_ins__GroupCensusMember__c];

        // clone old list
        List<vlocity_ins__GroupCensusMember__c> censusmemberListNew = censusmemberListOld.clone();

        // remove first element ('Test Census Member 0')
        censusmemberListNew.remove(0);
        // adds members, (one newborn)
        Id censusId = censusmemberListOld[0].vlocity_ins__CensusId__c;
        for(Integer i = 0; i<2 ; i++){
            vlocity_ins__GroupCensusMember__c c = new vlocity_ins__GroupCensusMember__c();
            c.Name = 'New Census Member ' + i;
            c.vlocity_ins__FirstName__c = 'New';
            c.vlocity_ins__LastName__c = 'Census Member ' + i;
            c.vlocity_ins__CensusId__c = censusId;
            c.vlocity_ins__Birthdate__c = System.today().addYears(-20);
            if(i == 0){
                //sets the newborn age
                c.vlocity_ins__Birthdate__c = System.today();
            }
            censusmemberListNew.add(c);
        }
        upsert censusmemberListNew;

        List<Map<String,Object>> censusmemberListNewMap = new List<Map<String,Object>>();
        for (vlocity_ins__GroupCensusMember__c cm : censusmemberListNew) {
            Map<String,Object> cmMap = new Map<String,Object>{
                'Id' => cm.Id,
                'Name' => cm.Name,
                'vlocity_ins__FirstName__c' => cm.vlocity_ins__FirstName__c,
                'vlocity_ins__LastName__c' => cm.vlocity_ins__LastName__c,
                'vlocity_ins__CensusId__c' => cm.vlocity_ins__CensusId__c,
                'vlocity_ins__Birthdate__c' => cm.vlocity_ins__Birthdate__c.format()
            };
            censusmemberListNewMap.add(cmMap);
        }
        Set<Id> ids = (new Map<Id, vlocity_ins__GroupCensusMember__c>(censusmemberListNew)).keySet();
        censusmemberListNew = [SELECT id,vlocity_ins__Birthdate__c, ARC_Age__c, vlocity_ins__FirstName__c, vlocity_ins__LastName__c, Name, vlocity_ins__CensusId__c FROM vlocity_ins__GroupCensusMember__c WHERE Id IN :ids];

        inputMap.put('contractReason', contractReason);
        inputMap.put('effectiveDate', effectiveDate);
        inputMap.put('newCoreProgram', newCoreProgram);
        inputMap.put('censusmemberListOld', JSON.deserializeUntyped(JSON.serialize(censusmemberListOld)));
        inputMap.put('censusmemberListNew', censusmemberListNewMap);

        ARC_ContractChanges contractChanges = new ARC_ContractChanges();
        contractChanges.invokeMethod('processChangesResendContract', inputMap, outputMap, options);
        System.assertEquals('Program Upgrade, Add Member, Remove Member, Add New Born', outputMap.get('actualChanges'));

        System.assertEquals('12/04/2023 Program Upgrade to New Program Name, \n12/04/2023 Add Member New Census Member 1, \n12/04/2023 Remove Member Test Census Member 0, \n12/04/2023 Add Member New Census Member 0', outputMap.get('changesList'));


    }






}