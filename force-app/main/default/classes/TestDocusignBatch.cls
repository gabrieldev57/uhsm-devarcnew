public class TestDocusignBatch {
    

    public static void Test(){
       String docuSignTemplateObjectName= 'vlocity_ins__VlocityDocuSignTemplate__c';
       Map<String, String>  docuSignTemplateFieldMap = new Map<String, String> {
            'Name' => 'Name',
            'LastModifiedDate' => 'LastModifiedDate',
            'Description__c' =>  'vlocity_ins__Description__c',
            'DocuSignAccountId__c' =>  'vlocity_ins__DocuSignAccountId__c',
            'RoleTabs__c' =>   'vlocity_ins__RoleTabs__c',
            'RolesData__c' =>   'vlocity_ins__RolesData__c',
            'TabsData__c' => 'vlocity_ins__TabsData__c',
            'TemplateIdentifier__c' =>  'vlocity_ins__TemplateIdentifier__c',
            'Vendor' =>  ''
        };

        if (Test.isRunningTest() == false) {
            Database.executeBatch(new vlocity_ins.DocuSignBatch(null, docuSignTemplateObjectName, docuSignTemplateFieldMap, ARC_DocuSignApi.getDocuSignAccountId()), 5);
        }
    }

}