/*******************************************************************
* @ClassName          :   ARC_EncryptionHelper
* @Description        :   Handles the encryption and decryption of the userid for reset password and set userName and password in the site.
* @MethodName         :   encryptText, decryptText
********************************************************************/

public class ARC_EncryptionHelper {
    //Key and Initial Vector
    private static final Blob key = EncodingUtil.base64Decode('2vQjmAdsk6bcQ0Qy75OXb1F8i2rbj8GQEcDp/ekyIpo=');
    public static final Blob iv = Blob.valueOf('txampnoaofaIV123');

    /*******************************************************************
    * @MethodName         :   encryptText
    * @Description        :   Method to encrypt a String
    ********************************************************************/
    @AuraEnabled(cacheable=false)
    public static String encryptText(String textToEncrypt) {
        Blob data = Blob.valueOf(textToEncrypt);
        Blob encrypted = Crypto.encrypt('AES256', key, iv, data);
        String encryptedString = EncodingUtil.base64Encode(encrypted);
        return encryptedString;
    }
    
    /*******************************************************************
    * @MethodName         :   decryptText
    * @Description        :   Method to decrypt a String
    ********************************************************************/
    @AuraEnabled(cacheable=false)
    public static String decryptText(String encryptedString) {
        Blob encryptedBlob = EncodingUtil.base64Decode(encryptedString);
        Blob decryptedBlob = Crypto.decrypt('AES256', key, iv, encryptedBlob);
        String decryptedString = decryptedBlob.toString();
        return decryptedString;
    }
}