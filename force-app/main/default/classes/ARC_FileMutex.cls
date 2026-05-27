public class ARC_FileMutex {
    private final String fileKey;
    private final String token;
    private final Integer leaseSeconds;
 
    public ARC_FileMutex(String fileKey, Integer leaseSeconds) {
        this.fileKey = fileKey;
        this.leaseSeconds = Math.max(5, leaseSeconds);
        this.token = EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA1', Blob.valueOf(UserInfo.getUserId() + ':' + System.now().getTime() + ':' + Crypto.getRandomLong()))
        );
    }
 
    public Boolean tryAcquire(Integer attempts) {
        Integer tries = Math.max(1, attempts);
        while (tries-- > 0) {
            if (acquireOnce()) return true;
        }
        return false;
    }
 
    public void release() {
        ARC_FileLock__c row = lockRowForUpdate();
        if (row != null && row.ARC_HeldBy__c == token) {
            row.ARC_HeldBy__c = null;
            row.ARC_ExpiresOn__c = null;
            update row;
        }
    }
 
    private Boolean acquireOnce() {
        ARC_FileLock__c row = ensureRowForUpdate();
        Boolean expired = row.ARC_ExpiresOn__c != null && row.ARC_ExpiresOn__c < System.now();

        if (String.isBlank(row.ARC_HeldBy__c) || expired || row.ARC_HeldBy__c == token) {
            row.ARC_HeldBy__c = token;
            row.ARC_ExpiresOn__c = System.now().addSeconds(leaseSeconds);
            update row;
            return true;
        }
        return false;
    }
 
    private ARC_FileLock__c ensureRowForUpdate() {
        ARC_FileLock__c row = lockRowForUpdate();
        if (row == null) {
            try { insert new ARC_FileLock__c(Name = fileKey); } catch (DmlException e) {}
            row = lockRowForUpdate();
        }
        return row;
    }
 
    private ARC_FileLock__c lockRowForUpdate() {
        List<ARC_FileLock__c> rows = [
            SELECT Id, Name, ARC_HeldBy__c, ARC_ExpiresOn__c
            FROM ARC_FileLock__c
            WHERE Name = :fileKey
            LIMIT 1
            FOR UPDATE
        ];
        return rows.isEmpty() ? null : rows[0];
    }
}