@isTest
public without sharing class ARC_EncryptionHelperTest {

    @isTest
    public static void encryptDecryptTestOne() {
        String test1='testOne';
        Test.startTest();
            String encryptTestOne = ARC_EncryptionHelper.encryptText(test1);
            String decryptTestOne = ARC_EncryptionHelper.decryptText(encryptTestOne);
        Test.stopTest();
        Assert.areEqual(test1,decryptTestOne);
        Assert.areNotEqual(test1,encryptTestOne);
    }

    @isTest
    public static void encryptDecryptTestTwo() {
        String test2='testTwo';
        Test.startTest();
            String encryptTestTwo = ARC_EncryptionHelper.encryptText(test2);
            String decryptTestTwo = ARC_EncryptionHelper.decryptText(encryptTestTwo);
        Test.stopTest();
        Assert.areEqual(test2,decryptTestTwo);
        Assert.areNotEqual(test2,encryptTestTwo);
    }
}