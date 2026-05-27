/**
 * @Description: Central manager class responsible for coordinating temporary newborn operations 
 * for Small Group (SG). It acts as the state holder (context) that stores data extracted 
 * from the OmniScript, queried reference data, and the records prepared for DML.
 * This instance is passed between the Mapper and DML utility classes.
 */
public without sharing class ARC_SGNBManager {
    //---------------------------------------------
    // Custom Exceptions for Business Rules Validation
    //---------------------------------------------
    public class NoMotherPolicyException extends Exception {}
    public class InvalidTwinBirthdateException extends Exception {}

    /**
     * @Description: Constructor for ARC_SGNBManager. Initializes the manager with the payload from OmniScript.
     * @param inputMap The raw JSON payload received from the OmniScript context.
     */
    public ARC_SGNBManager(Map<String,Object> inputMap) {
        this.inputMap = inputMap;
    } 

    //---------------------------------------------
    // InputData from Omniscript
    //---------------------------------------------
    public Map<String,Object> inputMap;   

    //---------------------------------------------
    // Source Data & Queried Records
    //---------------------------------------------
    public Map<String, Object> mapPrimaryInfo = new Map<String, Object>();
    public List<Map<String,Object>> listTemporaryNewborns = new List<Map<String,Object>>();
    public List<InsurancePolicy> listPol = new List<InsurancePolicy>();

    //---------------------------------------------
    // Maps of Related Records: Policy Id -> Policy Participants | Policy Id -> Coverage Participants | Person Account Id -> Contact Id | Policy Id -> Coverage Participant Id
    //---------------------------------------------
    public Map<String, Map<String, InsurancePolicyParticipant>> mapPolIdToPolPart = new Map<String, Map<String, InsurancePolicyParticipant>>();
    public Map<String, Map<String, ARC_CoverageParticipant__c>> mapPolIdToCovPart = new Map<String, Map<String, ARC_CoverageParticipant__c>>();
    public Map<String, String> mapAccIdToContactId = new Map<String, String>();
    public Map<String, String> mapPolIdToMotherCovPartId = new Map<String, String>();

    //---------------------------------------------
    // Maps and Lists of Records to Insert
    //---------------------------------------------
    public Map<String, Account> mapAccToInsert = new Map<String, Account>();
    public Map<String, vlocity_ins__GroupCensusMember__c> mapGCMToInsert = new  Map<String, vlocity_ins__GroupCensusMember__c>();
    public List<InsurancePolicyParticipant> listPolPartToInsert = new List<InsurancePolicyParticipant>();
    public List<ARC_CoverageParticipant__c> listCovPartToInsert = new List<ARC_CoverageParticipant__c>();

    //---------------------------------------------
    // Extremes Dates for Newborns
    //---------------------------------------------
    public Date oldestNewbornBirthdate;
    public Date youngestNewbornBirthdate;
    
    /**
     * @Description: Main execution method that orchestrates the newborn process. 
     * It delegates the extraction and mapping logic to ARC_SGNBMapper, and if successful, 
     * passes the current instance to ARC_SGNBDML to commit the records to the database.
     * @throws Exception Propagates both business logic exceptions and system errors to the BaseService.
     */
    public void executeSingleNewBorn() {        
        try{ 
            ARC_SGNBMapper mapper = new ARC_SGNBMapper();
            mapper.manageMapper(this);
        }
        catch(Exception e){
            throw e; 
        }

        try{    
            ARC_SGNBDML dml = new ARC_SGNBDML();
            dml.manageDML(this);            
        }
        catch(Exception e){
            throw e;
        }
    }
}