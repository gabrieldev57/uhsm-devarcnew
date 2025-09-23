public with sharing class ARC_OmniScriptManager {

/* ----------------------------------------------------------- */
/* ---------- GET ALL THE CONFIGURABLE OMNISCRIPTS ----------- */
/* ----------------------------------------------------------- */
    @AuraEnabled(cacheable=false)
    public static List<vlocity_ins__OmniScript__c> getfilteredOSList() { 
        List<vlocity_ins__OmniScript__c> filteredOSList = new List<vlocity_ins__OmniScript__c>();
        for (vlocity_ins__OmniScript__c os : [SELECT Id, Name, vlocity_ins__PropertySet__c
                                FROM vlocity_ins__OmniScript__c WHERE vlocity_ins__IsActive__c = true]) {
            if (os.vlocity_ins__PropertySet__c.substringBetween('"LOB":"','"')!=null) {
                System.debug(os.vlocity_ins__PropertySet__c.substringBetween('"LOB":"','"'));
                filteredOSList.add(os); 
            }
        }
        return filteredOSList;
    }
/* ------------------------------------------------------------ */
/* ------------ GET THE DEFINITION OF AN OMNISCRIPT ----------- */
/* ------------------------------------------------------------ */
    @AuraEnabled(cacheable=false)
    public static List<vlocity_ins__OmniScriptDefinition__c> getOSDefinition(String Name) { 
        List<vlocity_ins__OmniScriptDefinition__c> settings = new List<vlocity_ins__OmniScriptDefinition__c>([SELECT vlocity_ins__Sequence__c, Id, Name, vlocity_ins__Content__c
                                FROM vlocity_ins__OmniScriptDefinition__c WHERE Name = :Name]);
        return settings;
    }
/* ----------------------------------------------------------- */
/* ---------------- GET ALL METADATA SETTINGS ---------------- */
/* ----------------------------------------------------------- */
    @AuraEnabled(cacheable=false)
    public static List<ARC_Settings__mdt> getAllMetadataSettings() { 
        List<ARC_Settings__mdt> settings = new List<ARC_Settings__mdt>([SELECT QualifiedApiName, MasterLabel, ARC_LongText__c, ARC_Visible__C, ARC_Value__c
                                FROM ARC_Settings__mdt]);
        return settings;
    }
/* ----------------------------------------------------------- */
/* ------------ GET AN SPECIFIC METADATA SETTING ------------- */
/* ----------------------------------------------------------- */
    @AuraEnabled(cacheable=false)
    public static ARC_Settings__mdt getMetadataSettingByApiName(String settingApiName){
        ARC_Settings__mdt selectedSetting;
        for(ARC_Settings__mdt x: getAllMetadataSettings()){
            if(x.QualifiedApiName == settingApiName){
                selectedSetting = x;
            }
        }
        return selectedSetting;
    } 
/* ----------------------------------------------------------- */
/* -------------- UPDATE THE METADATA SETTINGS --------------- */
/* ----------------------------------------------------------- */
    @AuraEnabled(cacheable=false)
    public static void saveSettings(String settingApiName, String longText, Boolean showElement, String value) {
        Metadata.DeployContainer container = new Metadata.DeployContainer();
        List<String> settingsFullNames = new List<String>();
        Map<String, ARC_Settings__mdt> settingsByApiName = new Map<String, ARC_Settings__mdt>();
        ARC_Settings__mdt m = getMetadataSettingByApiName(settingApiName);
        m.ARC_LongText__c = longText;
        m.ARC_Visible__c = showElement;
        m.ARC_Value__c = value;
        settingsByApiName.put(m.QualifiedApiName, m);                    
        for (String recordName : settingsByApiName.keySet()) {
            settingsFullNames.add('ARC_Settings__mdt.' + recordName);
        }
        List<Metadata.Metadata> records = 
        Metadata.Operations.retrieve(Metadata.MetadataType.CustomMetadata, 
                                        settingsFullNames);
        for (Metadata.Metadata record : records) {
            Metadata.CustomMetadata settingsRecord = (Metadata.CustomMetadata) record;
            String settingsRecordName = settingsRecord.fullName.substringAfter('.');
            ARC_Settings__mdt settingsToCopy = settingsByApiName.get(settingsRecordName);
            for (Metadata.CustomMetadataValue settingsRecValue : settingsRecord.values) {
                settingsRecValue.value = settingsToCopy.get(settingsRecValue.field);
            }
            container.addMetadata(settingsRecord);
        }   

        if (!Test.isRunningTest()) {
            Id asyncResultId = metadata.Operations.enqueueDeployment(container, null);
        }
    }
}