/**
 * FlowRecordSplitUpdater
 * 
 * PURPOSE:
 * Invocable Apex class that updates a collection of records while ensuring that records 
 * with matching values in a specified field are updated in separate DML transactions.
 * This prevents rollup calculations or other triggered processes from being overwhelmed 
 * when multiple records relate to the same parent record (e.g., multiple Claims updating 
 * the same Account).
 * 
 * USE CASE:
 * When a scheduled Flow needs to update many records that may share common lookup values
 * (like Account__c), and those updates trigger rollup summaries or Apex that should be in
 * separate transactions.
 * 
 * HOW IT WORKS:
 * 1. Groups all input records by the specified field value (converted to String for comparison)
 * 2. Distributes records into batches where no batch contains records with duplicate field values
 * 3. Executes a separate DML update for each batch, ensuring each unique field value 
 *    is only processed once per transaction
 * 4. Returns the total count of successfully updated records and number of batches created
 * 
 * ALGORITHM EXAMPLE:
 * Input: 5 records with field values [A, A, B, A, C]
 * Result: 3 batches
 *   - Batch 1: Record1(A), Record3(B), Record5(C)
 *   - Batch 2: Record2(A)
 *   - Batch 3: Record4(A)
 * Each batch is updated separately, so Account A's rollups are triggered 3 times across 
 * 3 separate transactions instead of once with all 3 records.
 * 
 * FLOW USAGE:
 * 1. Get Records → {!RecordsToUpdate}
 * 2. Loop/Assignment to set field values on records
 * 3. Action: "Update Records Split by Field"
 *    - Records: {!RecordsToUpdate}
 *    - Field API Name: "Account__c" (or any field to split by)
 * 4. Use outputs: successCount and batchCount for confirmation/logging
 * 
 * IMPORTANT NOTES:
 * - Records must have all field updates applied BEFORE calling this action
 * - This class only handles the splitting and DML; it does not modify field values
 * - Works with any field type (Lookup, Text, Number, Date, Picklist, etc.)
 * - Each batch requires a separate DML statement, counting against governor limits
 * - Null field values are excluded from processing
 * 
 * @author Kyle Klopp
 * @date 12/10/2025
 */
public class FlowRecordSplitUpdater {
    @InvocableMethod(label='Update Records Split by Field')
    public static List<Response> updateRecordsSplit(List<Request> requests) {
        Request req = requests[0];
        Response result = new Response();
        result.successCount = 0;
        result.batchCount = 0;
        
        try {
            Map<String, List<SObject>> recordsByFieldValue = new Map<String, List<SObject>>();
            
            // Group records by field value
            for(SObject record : req.records) {
                Object fieldValue = record.get(req.fieldName);
                
                if(fieldValue != null) {
                    // Convert to String for map key
                    String fieldKey = String.valueOf(fieldValue);
                    
                    if(!recordsByFieldValue.containsKey(fieldKey)) {
                        recordsByFieldValue.put(fieldKey, new List<SObject>());
                    }
                    recordsByFieldValue.get(fieldKey).add(record);
                }
            }
            
            // Now split so no batch has duplicate field values
            List<List<SObject>> batches = new List<List<SObject>>();
            List<Set<String>> batchFieldValues = new List<Set<String>>();
            
            for(String fieldKey : recordsByFieldValue.keySet()) {
                for(SObject record : recordsByFieldValue.get(fieldKey)) {
                    Boolean placed = false;
                    
                    // Try to find a batch without this field value
                    for(Integer i = 0; i < batches.size(); i++) {
                        if(!batchFieldValues[i].contains(fieldKey)) {
                            batches[i].add(record);
                            batchFieldValues[i].add(fieldKey);
                            placed = true;
                            break;
                        }
                    }
                    
                    // Create new batch if needed
                    if(!placed) {
                        batches.add(new List<SObject>{ record });
                        batchFieldValues.add(new Set<String>{ fieldKey });
                    }
                }
            }
            
            // Update each batch separately (separate DML = separate rollup transactions)
            for(List<SObject> currentBatch : batches) {
                update currentBatch;
                result.successCount += currentBatch.size();
            }
            
            result.batchCount = batches.size();
            
        } catch(Exception e) {
            throw new InvocableException('Error updating records: ' + e.getMessage());
        }
        
        return new List<Response>{ result };
    }
    
    public class Request {
        @InvocableVariable(required=true label='Records' description='Collection of records to update (must already have field values set)')
        public List<SObject> records;
        
        @InvocableVariable(required=true label='Field API Name' description='API name of the field to split by (can be any field type)')
        public String fieldName;
    }
    
    public class Response {
        @InvocableVariable(label='Success Count' description='Total number of records successfully updated')
        public Integer successCount;
        
        @InvocableVariable(label='Batch Count' description='Number of batches created')
        public Integer batchCount;
    }
    
    public class InvocableException extends Exception {}
}