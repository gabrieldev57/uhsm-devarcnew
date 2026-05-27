/**
 * @description Manages state for S3 multipart uploads across queueable executions
 * Uses custom object (ARC_S3UploadState__c) to persist uploadId
 * DML operations happen AFTER callouts to avoid conflicts
 */
public class ARC_S3UploadStateManager {
    
    /**
     * @description Store uploadId for a file in custom object
     * IMPORTANT: Call this AFTER all callouts are complete
     * @param fileName The name of the file being uploaded
     * @param uploadId The S3 upload ID
     * @param nextPartNumber The next part number to upload (optional)
     */
    public static void saveUploadId(String fileName, String uploadId, Integer nextPartNumber) {
        if (String.isBlank(fileName) || String.isBlank(uploadId)) {
            return;
        }
        
        try {
            // Use upsert with external ID to handle both insert and update
            ARC_S3UploadState__c state = new ARC_S3UploadState__c(
                ARC_FilePath__c = fileName,
                ARC_UploadId__c = uploadId,
                ARC_NextPartNumber__c = nextPartNumber,
                ARC_LastUpdated__c = System.now()
            );
            upsert state ARC_FilePath__c;
            System.debug('Saved uploadId to DB for ' + fileName + ': ' + uploadId + ', next part: ' + nextPartNumber);
        } catch (Exception e) {
            System.debug('Error saving uploadId to DB: ' + e.getMessage());
        }
    }
    
    // Overload for backward compatibility
    public static void saveUploadId(String fileName, String uploadId) {
        saveUploadId(fileName, uploadId, null);
    }
    
    /**
     * @description Store a part's ETag after successful upload
     * IMPORTANT: Call this AFTER the upload callout completes
     * @param fileName The name of the file
     * @param partNumber The part number
     * @param etag The ETag returned by S3
     */
    public static void savePartETag(String fileName, Integer partNumber, String etag) {
        if (String.isBlank(fileName) || partNumber == null || String.isBlank(etag)) {
            return;
        }
        
        try {
            ARC_S3UploadState__c partRecord = new ARC_S3UploadState__c(
                ARC_FilePath__c = fileName + '_part_' + partNumber,
                ARC_UploadId__c = etag,  // Store ETag in ARC_UploadId__c field
                ARC_NextPartNumber__c = partNumber,  // Store part number
                ARC_LastUpdated__c = System.now()
            );
            insert partRecord;
            System.debug('Saved part ' + partNumber + ' ETag to DB: ' + etag);
        } catch (Exception e) {
            System.debug('Error saving part ETag to DB: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieve uploadId for a file from custom object
     * IMPORTANT: Call this BEFORE any callouts to avoid DML/callout conflicts
     * @param fileName The name of the file
     * @return The S3 upload ID, or null if not found
     */
    public static String getUploadId(String fileName) {
        if (String.isBlank(fileName)) {
            return null;
        }
        
        try {
            List<ARC_S3UploadState__c> states = [
                SELECT ARC_UploadId__c, ARC_NextPartNumber__c
                FROM ARC_S3UploadState__c 
                WHERE ARC_FilePath__c = :fileName 
                LIMIT 1
            ];
            
            if (!states.isEmpty() && String.isNotBlank(states[0].ARC_UploadId__c)) {
                System.debug('Retrieved uploadId from DB for ' + fileName + ': ' + states[0].ARC_UploadId__c + ', next part: ' + states[0].ARC_NextPartNumber__c);
                return states[0].ARC_UploadId__c;
            }
            
            System.debug('No uploadId found in DB for ' + fileName);
            return null;
        } catch (Exception e) {
            System.debug('Error retrieving uploadId from DB: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Retrieve uploadId AND nextPartNumber from DB
     * IMPORTANT: Call this BEFORE any callouts to avoid DML/callout conflicts
     * @param fileName The name of the file
     * @return UploadState wrapper with uploadId and nextPartNumber
     */
    public static UploadState getUploadState(String fileName) {
        UploadState state = new UploadState();
        state.uploadId = null;
        state.nextPartNumber = 1;
        
        if (String.isBlank(fileName)) {
            return state;
        }
        
        try {
            List<ARC_S3UploadState__c> states = [
                SELECT ARC_UploadId__c, ARC_NextPartNumber__c
                FROM ARC_S3UploadState__c 
                WHERE ARC_FilePath__c = :fileName 
                LIMIT 1
            ];
            
            if (!states.isEmpty() && String.isNotBlank(states[0].ARC_UploadId__c)) {
                state.uploadId = states[0].ARC_UploadId__c;
                state.nextPartNumber = states[0].ARC_NextPartNumber__c != null ? 
                    Integer.valueOf(states[0].ARC_NextPartNumber__c) : 1;
                System.debug('Retrieved state from DB for ' + fileName + ': uploadId=' + state.uploadId + ', nextPart=' + state.nextPartNumber);
            } else {
                System.debug('No state found in DB for ' + fileName);
            }
        } catch (Exception e) {
            System.debug('Error retrieving state from DB: ' + e.getMessage());
        }
        
        return state;
    }
    
    /**
     * Wrapper class for upload state
     */
    public class UploadState {
        public String uploadId;
        public Integer nextPartNumber;
    }
    
    /**
     * @description Retrieve all uploaded parts from custom object
     * @param fileName The name of the file
     * @return Map of part numbers to ETags
     */
    public static Map<Integer, String> getUploadedParts(String fileName) {
        Map<Integer, String> partsMap = new Map<Integer, String>();
        
        if (String.isBlank(fileName)) {
            return partsMap;
        }
        
        try {
            List<ARC_S3UploadState__c> partRecords = [
                SELECT ARC_NextPartNumber__c, ARC_UploadId__c
                FROM ARC_S3UploadState__c
                WHERE ARC_FilePath__c LIKE :fileName + '_part_%'
                ORDER BY ARC_NextPartNumber__c ASC
            ];
            
            for (ARC_S3UploadState__c record : partRecords) {
                if (record.ARC_NextPartNumber__c != null && String.isNotBlank(record.ARC_UploadId__c)) {
                    partsMap.put(Integer.valueOf(record.ARC_NextPartNumber__c), record.ARC_UploadId__c);
                }
            }
            
            System.debug('Retrieved ' + partsMap.size() + ' parts from DB for ' + fileName);
        } catch (Exception e) {
            System.debug('Error retrieving parts from DB: ' + e.getMessage());
        }
        
        return partsMap;
    }
    
    /**
     * @description Remove uploadId record and all part records after upload is complete
     * IMPORTANT: Call this AFTER all callouts are complete
     * @param fileName The name of the file
     */
    public static void clearUploadId(String fileName) {
        if (String.isBlank(fileName)) {
            return;
        }
        
        try {
            // Delete main upload state record
            List<ARC_S3UploadState__c> states = [
                SELECT Id 
                FROM ARC_S3UploadState__c 
                WHERE ARC_FilePath__c = :fileName 
                LIMIT 1
            ];
            
            // Delete all part records
            List<ARC_S3UploadState__c> partRecords = [
                SELECT Id
                FROM ARC_S3UploadState__c
                WHERE ARC_FilePath__c LIKE :fileName + '_part_%'
            ];
            
            List<ARC_S3UploadState__c> toDelete = new List<ARC_S3UploadState__c>();
            toDelete.addAll(states);
            toDelete.addAll(partRecords);
            
            if (!toDelete.isEmpty()) {
                delete toDelete;
                System.debug('Cleared uploadId and ' + partRecords.size() + ' parts from DB for ' + fileName);
            }
        } catch (Exception e) {
            System.debug('Error clearing upload state from DB: ' + e.getMessage());
        }
    }
}