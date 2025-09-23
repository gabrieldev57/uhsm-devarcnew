global without sharing class ARC_ReadSettingsMetadata implements vlocity_ins.VlocityOpenInterface {
    
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        
        if (methodName.equalsIgnoreCase('ARC_ReadSettingsMetadata')){
            ARC_ReadSettingsMetadata(outMap, inputMap);
        }
        return true;
    }

    public static void ARC_ReadSettingsMetadata(Map<String,Object> outMap, Map<String,Object> inputMap) {

        List<ARC_Settings__mdt> Settings = [SELECT Id, ARC_LongText__c, ARC_Value__c, ARC_Visible__c, MasterLabel, QualifiedApiName FROM ARC_Settings__mdt WHERE Id != ''];
        List<Map<String, Object>> listOfMaps = new List<Map<String, Object>>();
        Map<String, Map<String, Object>> MapOfMaps = new Map<String, Map<String, Object>>();
        Map<String, Object> tempMap = new Map<String, Object>();

        for (ARC_Settings__mdt currentSetting : Settings) {
            tempMap.put('longText', currentSetting.ARC_LongText__c);
            tempMap.put('value', currentSetting.ARC_Value__c);
            tempMap.put('visible', currentSetting.ARC_Visible__c);
            tempMap.put('label', currentSetting.MasterLabel);
            tempMap.put('apiName', currentSetting.QualifiedApiName);
            MapOfMaps.put(currentSetting.QualifiedApiName, tempMap);
        }
        listOfMaps.add(MapOfMaps);
        outMap.put('MetadataTypes', listOfMaps);
    }
}