@isTest
public class ARC_OmniScriptManagerTest {

    @isTest 
    static void testGetFilteredOSList(){
        Integer numberOfOS = 4;
        vlocity_ins__OmniScript__c[] expectedOS = ARC_TestUtility.createTestOmniscript(numberOfOS);
        insert expectedOS;
        List<vlocity_ins__OmniScript__c> actualOS = ARC_OmniScriptManager.getfilteredOSList();
        System.assertEquals(numberOfOS, actualOS.size());
    }

    @isTest
    static void testgetOSDefinition(){
        Integer numberOfOSDef = 4;
        Integer numberOfOS = 4;
        vlocity_ins__OmniScript__c[] expectedOS = ARC_TestUtility.createTestOmniscript(numberOfOS);
        insert expectedOS;
        vlocity_ins__OmniScriptDefinition__c[] expectedOSDef = ARC_TestUtility.createTestOmniscriptDefinition(numberOfOSDef, expectedOS[0]);
        insert expectedOSDef;
        String name = 'TestOSDef';
        List<vlocity_ins__OmniScriptDefinition__c> actualOSDef = ARC_OmniScriptManager.getOSDefinition(name);
        System.assertEquals(numberOfOSDef, actualOSDef.size()); 
    }

    @isTest
    static void testgetAllMetadataSettings(){
        List<ARC_Settings__mdt> expectedMetadata = ARC_TestUtility.getAllMetadataSettingsFromOrg();
        List<ARC_Settings__mdt> actualMetadata = ARC_OmniScriptManager.getAllMetadataSettings();
        System.assertEquals(expectedMetadata.size(), actualMetadata.size()); 
    }

    @isTest
    static void testgetMetadataSettingByApiName(){
        List<ARC_Settings__mdt> allMetadata = ARC_TestUtility.getAllMetadataSettingsFromOrg();
        ARC_Settings__mdt expectedMetadata = allMetaData[0];
        String settingApiName = expectedMetadata.QualifiedApiName;
        ARC_Settings__mdt actualMetadata = ARC_OmniScriptManager.getMetadataSettingByApiName(settingApiName);
        System.debug(expectedMetadata);
        System.debug(settingApiName);
        System.debug(actualMetadata);
        System.assertEquals(expectedMetadata, actualMetadata); 
    }
    
    @isTest
    static void testsaveSettings(){
        List<ARC_Settings__mdt> allMetadata = ARC_TestUtility.getAllMetadataSettingsFromOrg();
        ARC_Settings__mdt testOriginalMetadata = allMetaData[0];
        String settingApiName = testOriginalMetadata.QualifiedApiName;
        String longText = 'Changed long text';
        String value = 'Changed value';
        testOriginalMetadata.ARC_LongText__c = longText;
        testOriginalMetadata.ARC_Visible__c = false;
        testOriginalMetadata.ARC_Value__c = value;
        ARC_OmniScriptManager.saveSettings(settingApiName, longText, false, value);
        ARC_Settings__mdt testUpdatedMetadata = ARC_OmniScriptManager.getMetadataSettingByApiName(settingApiName);
        System.assertNotEquals(testOriginalMetadata, testUpdatedMetadata);
    }
}