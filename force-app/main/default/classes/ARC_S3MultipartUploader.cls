/**
 * @description Helper class for AWS S3 Multipart Upload operations
 * Replaces FTP2SF managed package for large file uploads
 * Uses External Credentials for secure AWS authentication
 * 
 * Usage Example:
 *   ARC_S3MultipartUploader uploader = new ARC_S3MultipartUploader('myfile.txt');
 *   uploader.initializeUpload();
 *   uploader.uploadPart(1, 'content chunk 1');
 *   uploader.uploadPart(2, 'content chunk 2');
 *   uploader.completeUpload();
 */
public class ARC_S3MultipartUploader {
    
    // Configuration - These should match your Named Credential setup
    private static final String NAMED_CREDENTIAL = 'UHSM_Eligibility_Files';
    private static final String S3_NAMESPACE = 'http://s3.amazonaws.com/doc/2006-03-01/';
    
    // Instance variables
    private String fileName;
    private String filePath;
    private String uploadId;
    private Map<Integer, String> parts;
    private Integer nextPartNumber;
    
    /**
     * @description Constructor
     * @param filePath Path to file in S3 (can include folders like 'cvs/filename.txt')
     */
    public ARC_S3MultipartUploader(String filePath) {
        this(filePath, null, 1);
    }
    
    /**
     * @description Constructor with uploadId (for continuing existing uploads)
     * @param filePath Path to file in S3 (can include folders like 'cvs/filename.txt')
     * @param uploadId Existing upload ID (pass between queueable executions)
     */
    public ARC_S3MultipartUploader(String filePath, String uploadId) {
        this(filePath, uploadId, 1);
    }
    
    /**
     * @description Constructor with uploadId and nextPartNumber
     * @param filePath Path to file in S3 (can include folders like 'cvs/filename.txt')
     * @param uploadId Existing upload ID
     * @param nextPartNumber The next part number to upload
     */
    public ARC_S3MultipartUploader(String filePath, String uploadId, Integer nextPartNumber) {
        if (String.isBlank(filePath)) {
            throw new IllegalArgumentException('filePath cannot be null or empty');
        }
        this.filePath = filePath;
        this.uploadId = uploadId;
        // Extract filename
        this.fileName = filePath.contains('/') ? filePath.substringAfterLast('/') : filePath;
        this.parts = new Map<Integer, String>();
        this.nextPartNumber = nextPartNumber != null ? nextPartNumber : 1;
    }
    
    /**
     * @description Encode S3 path for URL - encodes each segment separately to preserve slashes
     * AWS signature calculation requires path segments to be encoded but slashes to remain as /
     * @param path S3 path (e.g., 'folder/file.txt')
     * @return URL-encoded path with slashes preserved
     */
    private String encodeS3Path(String path) {
        if (String.isBlank(path)) {
            return '';
        }
        List<String> segments = path.split('/');
        List<String> encodedSegments = new List<String>();
        for (String segment : segments) {
            encodedSegments.add(EncodingUtil.urlEncode(segment, 'UTF-8'));
        }
        return String.join(encodedSegments, '/');
    }
    
    /**
     * @description Initialize multipart upload and get uploadId
     * Call this before uploading any parts
     * @return Upload ID from S3
     */
    public String initializeUpload() {
        try {
            String endpoint = 'callout:' + NAMED_CREDENTIAL + '/' + encodeS3Path(filePath) + '?uploads';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setTimeout(120000);
            
            System.debug('=== INITIALIZING S3 MULTIPART UPLOAD ===');
            System.debug('File Path: ' + filePath);
            System.debug('Endpoint: ' + endpoint);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                this.uploadId = parseUploadIdFromXml(res.getBody());
                
                System.debug('Upload initialized successfully');
                System.debug('Upload ID: ' + uploadId);
                
                return uploadId;
            } else {
                throw new S3Exception('Failed to initialize multipart upload. Status: ' + 
                    res.getStatusCode() + ', Body: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('ERROR initializing upload: ' + e.getMessage());
            throw new S3Exception('Error initializing S3 upload: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Upload the next part automatically (increments part number)
     * Use this when you don't need to track part numbers yourself
     * @param content Content for this part
     * @return ETag for the uploaded part
     */
    public String uploadNextPart(String content) {
        String etag = uploadPart(this.nextPartNumber, content);
        this.nextPartNumber++;
        return etag;
    }
    
    /**
     * @description Upload a single part of the file
     * Parts can be uploaded in any order and in parallel
     * @param partNumber Part number (starting from 1)
     * @param content Content for this part
     * @return ETag for the uploaded part
     */
    public String uploadPart(Integer partNumber, String content) {
        if (partNumber < 1) {
            throw new IllegalArgumentException('partNumber must be >= 1');
        }
        if (String.isBlank(content)) {
            throw new IllegalArgumentException('content cannot be empty');
        }
        
        try {
            // Get uploadId from instance or cache
            String currentUploadId = getUploadId();
            
            String endpoint = 'callout:' + NAMED_CREDENTIAL + '/' + encodeS3Path(filePath) +
                            '?partNumber=' + partNumber + 
                            '&uploadId=' + EncodingUtil.urlEncode(currentUploadId, 'UTF-8');
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('PUT');
            req.setBody(content);
            req.setTimeout(120000);
            
            System.debug('=== UPLOADING PART ' + partNumber + ' ===');
            System.debug('Content size: ' + content.length() + ' characters');
            System.debug('Upload ID: ' + currentUploadId);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                String etag = res.getHeader('ETag');
                if (etag != null) {
                    etag = etag.replace('"', ''); // Remove quotes from ETag
                }
                
                // Store part info in memory only (not in cache)
                // S3 tracks all parts, we'll retrieve them via ListParts API when needed
                parts.put(partNumber, etag);
                
                System.debug('✅ Part ' + partNumber + ' uploaded successfully');
                System.debug('ETag: ' + etag);
                
                return etag;
            } else {
                throw new S3Exception('Failed to upload part ' + partNumber + '. Status: ' + 
                    res.getStatusCode() + ', Body: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('ERROR uploading part ' + partNumber + ': ' + e.getMessage());
            throw new S3Exception('Error uploading part ' + partNumber + ': ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Complete the multipart upload
     * S3 will assemble all parts into final file
     * Call this after all parts have been uploaded
     * @param allParts Map of all part numbers to ETags (pass from caller to avoid DB query)
     */
    public void completeUpload(Map<Integer, String> allParts) {
        try {
            String currentUploadId = getUploadId();
            
            // Use provided parts map
            if (allParts != null && !allParts.isEmpty()) {
                this.parts = allParts;
            }
            
            if (this.parts.isEmpty()) {
                throw new S3Exception('No parts to complete. Upload at least one part before completing.');
            }
            
            String endpoint = 'callout:' + NAMED_CREDENTIAL + '/' + encodeS3Path(filePath) +
                            '?uploadId=' + EncodingUtil.urlEncode(currentUploadId, 'UTF-8');
            
            // Build XML body with all parts
            String xmlBody = buildCompleteMultipartXml();
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setBody(xmlBody);
            req.setHeader('Content-Type', 'application/xml');
            req.setTimeout(120000);
            
            System.debug('=== COMPLETING MULTIPART UPLOAD ===');
            System.debug('Total parts: ' + this.parts.size());
            System.debug('Upload ID: ' + currentUploadId);
            System.debug('XML Body: ' + xmlBody);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                System.debug('Upload completed successfully');
                System.debug('File Path: ' + filePath);
                System.debug('Location: ' + parseLocationFromXml(res.getBody()));
            } else {
                throw new S3Exception('Failed to complete upload. Status: ' + 
                    res.getStatusCode() + ', Body: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('ERROR completing upload: ' + e.getMessage());
            throw new S3Exception('Error completing S3 upload: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Abort a multipart upload and clean up parts
     * Use this to cancel an in-progress upload
     */
    public void abortUpload() {
        try {
            String currentUploadId = getUploadId();
            
            String endpoint = 'callout:' + NAMED_CREDENTIAL + '/' + encodeS3Path(filePath) +
                            '?uploadId=' + EncodingUtil.urlEncode(currentUploadId, 'UTF-8');
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('DELETE');
            req.setTimeout(120000);
            
            System.debug('=== ABORTING MULTIPART UPLOAD ===');
            System.debug('Upload ID: ' + currentUploadId);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 204) {
                System.debug(' Upload aborted successfully');
            } else {
                System.debug('Abort returned status: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Error aborting upload: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get the upload ID from instance variable
     * @return Upload ID
     */
    private String getUploadId() {
        if (String.isBlank(this.uploadId)) {
            throw new S3Exception('Upload not initialized. Call initializeUpload() first or pass uploadId to constructor.');
        }
        return this.uploadId;
    }
    
    
    /**
     * @description Build XML for CompleteMultipartUpload request
     * @return XML string
     */
    private String buildCompleteMultipartXml() {
        // Sort part numbers to ensure correct order
        List<Integer> partNumbers = new List<Integer>(parts.keySet());
        partNumbers.sort();
        
        String xml = '<CompleteMultipartUpload>';
        for (Integer partNum : partNumbers) {
            xml += '<Part>';
            xml += '<PartNumber>' + partNum + '</PartNumber>';
            xml += '<ETag>"' + parts.get(partNum) + '"</ETag>';
            xml += '</Part>';
        }
        xml += '</CompleteMultipartUpload>';
        
        return xml;
    }
    
    /**
     * @description Parse Upload ID from InitiateMultipartUpload XML response
     * @param xmlResponse XML response body
     * @return Upload ID
     */
    private String parseUploadIdFromXml(String xmlResponse) {
        try {
            Dom.Document doc = new Dom.Document();
            doc.load(xmlResponse);
            Dom.XmlNode root = doc.getRootElement();
            Dom.XmlNode uploadIdNode = root.getChildElement('UploadId', S3_NAMESPACE);
            
            if (uploadIdNode == null) {
                throw new S3Exception('UploadId not found in XML response');
            }
            
            return uploadIdNode.getText();
        } catch (Exception e) {
            throw new S3Exception('Error parsing UploadId from XML: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Parse Location from CompleteMultipartUpload XML response
     * @param xmlResponse XML response body
     * @return S3 file location URL
     */
    private String parseLocationFromXml(String xmlResponse) {
        try {
            Dom.Document doc = new Dom.Document();
            doc.load(xmlResponse);
            Dom.XmlNode root = doc.getRootElement();
            Dom.XmlNode locationNode = root.getChildElement('Location', S3_NAMESPACE);
            
            if (locationNode != null) {
                return locationNode.getText();
            }
            return 'Location not available';
        } catch (Exception e) {
            return 'Error parsing location: ' + e.getMessage();
        }
    }

    
    
    /**
     * @description Custom exception for S3 operations
     */
    public class S3Exception extends Exception {}
}