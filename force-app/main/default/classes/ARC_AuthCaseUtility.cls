/************************************************************************************************************* * 
 * @name            ARC_AuthCaseUtility * 
 * @created         12 / 04 / 2026 * 
 * @description     Manage Auth Case workflows *  
 * ***************************************************************************************************************/

global without sharing class ARC_AuthCaseUtility {

    /*********************************************************************************************************     * 
     * @name            checkForPhysicalTherapy     * 
     * @created         12 / 04 / 2026     * 
     * @description     Runs validations for PT claim line items. 
     *                      if good, returns newCliToDateMap : (cli to DOS) this map is later used to apply consumptions
     *                      If any item is invalid, returns error key. * 
     * @param           Map<String, Object> inputMap * 
     * @return          Map<String, Object>   *
     * *********************************************************************************************************/
    public static Map<String, Object> checkForPhysicalTherapy(Map<String, Object> inputMap){
        Map<String, Object> outMap = new Map<String, Object>();
        Map<Id, Date> newCliToDateMap = new Map<Id, Date>(); // save DOSs for output (to compare existing and count for consumption)
        System.debug('------------checkForPhysicalTherapy------------');
        
        List<ClaimCoveragePaymentDetail> claimItems = (List<ClaimCoveragePaymentDetail>) inputMap.get('claimItems');
        System.debug('claimItems: ' + claimItems);
        Boolean voidedAuth = (Boolean)inputMap.get('voidedAuth');
        System.debug('voidedAuth: ' + voidedAuth);
        Id caseId = (Id)inputMap.get('caseId');
        System.debug('caseId: ' + caseId);
        Date authFrom = (Date)inputMap.get('authFrom');
        Date authTo = (Date)inputMap.get('authTo');
        System.debug('From: ' + authFrom);
        System.debug('To: ' + authTo);

        
        List<ClaimCoveragePaymentDetail> PTItems = new List<ClaimCoveragePaymentDetail>();
        // VERIFY FOR PT ITEMS TO PROCESS AS PAID
        Boolean hasPTItems = false; 
        for (ClaimCoveragePaymentDetail cli : claimItems){
            System.debug('--Loop CLI: ' + cli.ARC_Medical_Visit_Reason__c);
            if(cli.ARC_Medical_Visit_Reason__c == 'PhysicalTherapy' && cli.Status != 'Paid'){
                PTItems.add(cli);
                hasPTItems = true;    
            }
        }  

        // IF PT Items are found, execute validations
        System.debug('hasPTItems?: ' + hasPTItems);
        if (hasPTItems) {
            // 1- verify AuthCase exists and not voided
            System.debug('voidedAuth?: ' + voidedAuth);
            System.debug('crash here??: ');
            if (voidedAuth == true) {
                System.debug('crash there??: ');
                outMap.put('error', 'Authorization is Voided');
                return outMap;
            } else if(caseId == null) {
                System.debug('control');
                outMap.put('error', 'Need Authorization Case to process Physical Therapy treatments.');
                return outMap;
            }

            Case authCase;
            Set<String> authCPTCodes = new Set<String>();
            try {
                for (arcsona__PriorAuthRequestItem__c pari : [
                    SELECT arcsona__CPTCode__r.Name
                    FROM arcsona__PriorAuthRequestItem__c
                    WHERE arcsona__Status__c = 'Approved'
                    AND arcsona__PriorAuthorization__r.arcsona__Case__c = :caseId
                ]) {
                    if (pari.arcsona__CPTCode__r != null && pari.arcsona__CPTCode__r.Name != null) {
                        authCPTCodes.add(pari.arcsona__CPTCode__r.Name);
                    }
                }
            } catch (Exception e) {
                outMap.put('error', 'Could not retrieve CPT codes from Auth Case.');
                return outMap;
            }
            System.debug('authCPTCodes: ' + authCPTCodes);


            
            for(ClaimCoveragePaymentDetail cli : PTItems){
                // 2- verify DOS within AuthCase dates
                Date cliDOS = cli.ARC_DateOfService__c != null ? cli.ARC_DateOfService__c : cli.ARC_DOSTo__c;
                System.debug('-- cli Id - DOS: ' + cli.Id + ' - ' +  cliDOS);
                newCliToDateMap.put(cli.Id, cliDOS);
                Boolean validDates = cliDOS >= authFrom && cliDOS <= authTo;
                System.debug('-- validDates: ' + validDates);
                if(!validDates){
                    outMap.put('error', 'Some Phisical Therapy items are not within the authorized dates.');
                    return outMap;
                }
                // 3- verify CPT codes are in AuthCase
                System.debug('-- CLI CPT code: '+ cli.ARC_ProcedureCodeName__c);
                Boolean CPTCodeInAuth = authCPTCodes.contains(cli.ARC_ProcedureCodeName__c);
                System.debug('-- CLI CPTCodeInAuth: '+ CPTCodeInAuth);
                if(!CPTCodeInAuth){
                    outMap.put('error', 'Some Phisical Therapy procedure codes are not included in the Authorization.');
                    return outMap;
                } 
            }
        }        
        System.debug('newCliToDateMap' + newCliToDateMap);
        outMap.put('newCliToDateMap', newCliToDateMap);
        System.debug('END - checkForPhysicalTherapy');
        return outMap;
    }

    /*********************************************************************************************************     * 
     * @name            countPTConsumptionsForAuthCase     * 
     * @created         12 / 04 / 2026     * 
     * @description     Recieves output from checkForPhysicalTherapy (cli to date map) and auth number (base source system id) 
     *                      resolves how many PT visits to account for and returns a map with newPivotCliIds (clis to update as pivot) and newDatesCount ( amount to add on the auth's used visits )* 
     * @param           Map<String, Object> inputMap * 
     * @return          Map<String, Object>   *
     * *********************************************************************************************************/
    public static Map<String, Object> countPTConsumptionsForAuthCase(Map<String, Object> inputMap){
        Map<String, Object> outMap = new Map<String, Object>();
        System.debug('------------apply consumptions for PT on AuthCase------------');
        Map<Id, Date> newCliToDateMap = (Map<Id, Date>)inputMap.get('newCliToDateMap');
        System.debug('newCliToDateMap: ' + newCliToDateMap);
        String authNumber = (String)inputMap.get('authNumber');
        System.debug('authNumber: ' + authNumber);
        // retrieve all distinct DOSs from the related Claim's CLIs
        // related auth <- claim <- *CLI* 
        Set<Date> existingDates = new Set<Date>();
        try {
            // SELECT DOS FROM CLI WHERE ISPIVOT
            // IF THIS CLI's DOS HAS PIVOT ->> DONT COUNT; DONT MARK AS PIVOT
            // ELSE -> COUNT IN CASE; MARK AS PIVOT
            for (AggregateResult ar : [
                SELECT ARC_DateOfService__c, ARC_DOSTo__c
                FROM ClaimCoveragePaymentDetail
                WHERE ARC_Medical_Visit_Reason__c = 'PhysicalTherapy' 
                AND ARC_Is_PT_Pivot__c = true
                AND Status = 'Paid'
                AND ARC_Claim__r.ARC_PriorAuthorizationCase__r.HealthCloudGA__SourceSystemID__c LIKE :(authNumber + '%')
                GROUP BY ARC_DateOfService__c, ARC_DOSTo__c
            ]) {
                System.debug('aggregateResult' + ar);
                Date d1 = (Date) ar.get('ARC_DateOfService__c');
                Date d2 = (Date) ar.get('ARC_DOSTo__c');
                Date d = d1 != null ? d1 : d2;
                
                if (d != null) existingDates.add(d);
            }
        } catch (Exception e) {
            outMap.put('error', 'Error: Could not verify for existing Physical Therapy treatments.');
            return outMap;
        }
        System.debug('existingDates: ' + existingDates);
        

        Map<Date, Id> newDateToPivotCliMap = new Map<Date, Id>();
        for (Id cliId: newCliToDateMap.keySet()) {
            Date d = newCliToDateMap.get(cliId);
            if (!existingDates.contains(d)) {
                newDateToPivotCliMap.put(d, cliId);
            }
        }

        List<Id> newPivotCliIds = newDateToPivotCliMap.values();
        System.debug('newPivotCliIds: ' + newPivotCliIds);
        outMap.put('newPivotCliIds', newPivotCliIds);
        System.debug('newDatesCount: ' + newPivotCliIds.size());
        outMap.put('newDatesCount', newPivotCliIds.size());
        System.debug('END - countPTConsumptionsForAuthCase');
        return outMap;
    }

    /*********************************************************************************************************     * 
     * @name            uncommitPTVisitsFromAuth     * 
     * @created         12 / 04 / 2026     * 
     * @description     recieves a list of smb_items to uncommit and their smb's authCaseId , processes visits according to pivot clis, reassigns pivots if necessary 
     *                      returns a list of the auths to update their used visits and the clis to update (uncommit and update as pivot, if any)* 
     * @param           Map<String, Object> inputMap * 
     * @return          Map<String, Object>   *
     * *********************************************************************************************************/
    public static Map<String, Object> uncommitPTVisitsFromAuth(Map<String, Object> inputMap){
        Map<String, Object> outMap = new Map<String, Object>();
        System.debug('------------UNCOMMIT  for PT on AuthCase------------');
        List<ClaimCoveragePaymentDetail> smb_items = (List<ClaimCoveragePaymentDetail>)inputMap.get('smb_items');
        List<ClaimCoveragePaymentDetail> pivotItems = new List<ClaimCoveragePaymentDetail>();
        String baseAuthNumber = smb_items[0].ARC_Claim__r.ARC_PriorAuthorizationCase__r?.Base_Source_System_Id__c;
        Id authCaseId = (String)inputMap.get('authCaseId');
        Decimal usedValue = (Decimal)inputMap.get('usedValue'); /// ???
        Set<Id> itemIds = new Set<Id>();
        Set<Date> datesToReset = new Set<Date>();
        // Integer substractFromAuth = 0;
        Map<Id,Integer> authsToUpdate = new Map<Id,Integer>();
        authsToUpdate.put(authCaseId, 0);

        for( ClaimCoveragePaymentDetail item : smb_items){
            if(item.ARC_Is_PT_Pivot__c){
                Date d = item.ARC_DateOfService__c != null ?  item.ARC_DateOfService__c : item.ARC_DOSTo__c;
                datesToReset.add(d);
                item.ARC_Is_PT_Pivot__c = false;
                pivotItems.add(item);
            }
            itemIds.add(item.Id);
        }

        if(!datesToReset.isEmpty()){
            try {
                // find other DOSs on related AuthCases to ensure if resetted dates still account or not on any auth Case
                Map<Date, Map<Id,List<ClaimCoveragePaymentDetail>>> dateToAuthToOpenCLIList = new Map<Date, Map<Id,List<ClaimCoveragePaymentDetail>>>();  
                for (ClaimCoveragePaymentDetail cli : [
                    SELECT ARC_DateOfService__c, ARC_DOSTo__c, ARC_Is_PT_Pivot__c, ARC_Claim__r.ARC_PriorAuthorizationCase__c, ARC_Claim__r.ARC_PriorAuthorizationCase__r.ARC_PT_Visits_Used__c,
                    ARC_Claim__r.ARC_PriorAuthorizationCase__r.HealthCloudGA__SourceSystemID__c 
                    FROM ClaimCoveragePaymentDetail
                    WHERE ARC_Medical_Visit_Reason__c = 'PhysicalTherapy'
                    AND Status = 'Paid'
                    AND ARC_Claim__r.ARC_PriorAuthorizationCase__r.HealthCloudGA__SourceSystemID__c LIKE :(baseAuthNumber + '%')
                    AND (ARC_DateOfService__c IN :datesToReset OR ARC_DOSTo__c IN :datesToReset)
                    AND Id NOT IN :itemIds
                    ORDER BY ARC_Claim__r.ARC_PriorAuthorizationCase__r.createdDate ASC
                ]) {
                    // map by  Date -> AUTHCASE ID -> candidate cli list
                    Date d = cli.get('ARC_DateOfService__c') != null ? (Date) cli.get('ARC_DateOfService__c') : (Date) cli.get('ARC_DOSTo__c');
                    Id auth = cli.ARC_Claim__r.ARC_PriorAuthorizationCase__c;
                    if(dateToAuthToOpenCLIList.containsKey(d)){
                        if(dateToAuthToOpenCLIList.get(d).containsKey(auth)){
                            dateToAuthToOpenCLIList.get(d).get(auth).add(cli);
                        }else{
                            dateToAuthToOpenCLIList.get(d).put(auth, new List<ClaimCoveragePaymentDetail>{cli});
                        }
                    }else{
                        dateToAuthToOpenCLIList.put(d, new Map<Id,List<ClaimCoveragePaymentDetail>>());
                        dateToAuthToOpenCLIList.get(d).put(auth, new List<ClaimCoveragePaymentDetail>{cli});
                    }
                }
                System.debug('dateToAuthToOpenCLIList: ' + dateToAuthToOpenCLIList);

                for(ClaimCoveragePaymentDetail item : pivotItems){
                    Date d = item.get('ARC_DateOfService__c') != null ? (Date) item.get('ARC_DateOfService__c') : (Date) item.get('ARC_DOSTo__c');
                    System.debug('- PivotDate: ' + d);
                    if (dateToAuthToOpenCLIList.containsKey(d)){
                       Map<Id,List<ClaimCoveragePaymentDetail>> candAuths = dateToAuthToOpenCLIList.get(d);
                       
                       /////// ANOTHER CLI LEFT ON SAME AUTH
                       if(candAuths.containsKey(authCaseId)){ 
                            // do not substract, get first cli and set it as new pivot
                            System.debug('do not substract, get first cli and set it as new pivot');
                            candAuths.get(authCaseId)[0].ARC_Is_PT_Pivot__c = true;
                            smb_items.add(candAuths.get(authCaseId)[0]);
                        
                        //////// ANOTHER CLI LEFT ON A DIFFERENT AUTH
                        } else { 
                            // substract from this auth, 
                            System.debug('substract from this auth');
                            authsToUpdate.put(authCaseId, authsToUpdate.get(authCaseId) - 1 );   
                             
                            // if query ordered by HealthCloudGA__SourceSystemID__c ASC::
                            // get first auth on the map, add to its used value, 
                            // should be either open or if not, most earlier due thanks to query order and sourceId format. 
                            // if order query by createdDate ASC:: <----
                            // the fist selected is going to be de earliest
                            System.debug('get first auth on the map, add to its used value'); 
                            Id newAuthId = candAuths.keySet().iterator().next();
                            if (authsToUpdate.containsKey(newAuthId)) {
                                authsToUpdate.put(newAuthId, authsToUpdate.get(newAuthId) + 1);
                            }else{
                                authsToUpdate.put(newAuthId, 1);
                            }
                            // use the first cli on its list to mark as new pivot
                            System.debug('use the first cli on its list to mark as new pivot');     
                            List<ClaimCoveragePaymentDetail> candidatates = candAuths.get(newAuthId);
                            ClaimCoveragePaymentDetail newPivot = candidatates[0];
                            newPivot.ARC_Is_PT_Pivot__c = true;
                            smb_items.add(newPivot);
                        }
                    ////// NO OTHER CLI LEFT
                    } else {
                        // substract from this auth
                        System.debug('substract from this auth');
                        authsToUpdate.put(authCaseId, authsToUpdate.get(authCaseId) - 1 );
                    }
                }
                outMap.put('authsToUpdate', authsToUpdate);
                outMap.put('smb_items', smb_items);
            } catch (Exception e) {
                outMap.put('error', 'Error: Could not retrieve remaining Physical Therapy treatments.');
                return outMap;
            }

        }

        return outMap;
    }

    /*********************************************************************************************************     * 
     * @name            propagateDelta     * 
     * @created         12 / 04 / 2026     * 
     * @description     recursive method used on queueable to propagate 'ARC_PT_Visits_FromParent__c' field on child auths* 
     * @param           Id parentId (record initially updated), Decimal delta (amount to change on child record)* 
     * @return          void   *
     * *********************************************************************************************************/
    private static void propagateDelta(Id parentId, Decimal delta) {
        // Get child (only one)
        List<Case> children = [
            SELECT Id, ParentId, ARC_PT_Visits_FromParent__c, HealthCloudGA__SourceSystemID__c
            FROM Case
            WHERE ParentId = :parentId
            LIMIT 1
        ];
        System.debug('propagate- children? : ' + !children.isEmpty());
        
        if (children.isEmpty()) return;
        
        Case child = children[0];
        System.debug('propagate- CHILD ----');
        System.debug('propagate- sourceId: ' + child.HealthCloudGA__SourceSystemID__c);
        System.debug('propagate- visits initial: ' + child.ARC_PT_Visits_FromParent__c);
        
        // Apply delta
        child.ARC_PT_Visits_FromParent__c =
        (child.ARC_PT_Visits_FromParent__c == null ? 0 : child.ARC_PT_Visits_FromParent__c) 
        + delta;
        

        System.debug('propagate- child visits updated: ' + child.ARC_PT_Visits_FromParent__c);
        System.debug('propagate- child END ----: ' + child);
        update child;

        // Recurse forward
        propagateDelta(child.Id, delta);
    }

    /*********************************************************************************************************     * 
     * @name            PTDeltaPropagationJob     * 
     * @created         12 / 04 / 2026     * 
     * @description     cueueable method to propagate ARC_PT_Visits_FromParent__c* 
     * @param           Map<Id, Decimal> authDeltas : (parent auth Id that has been updated , to amount that was added/subtracted* 
     * @return          void   *
     * *********************************************************************************************************/
    public class PTDeltaPropagationJob implements Queueable {

        Map<Id, Decimal> authDeltas;
        public PTDeltaPropagationJob(Map<Id, Decimal> authDeltas) {
            System.debug('PTDeltaPropagationJob - authDeltas: ' + authDeltas);
            this.authDeltas = authDeltas;
        }

        public void execute(QueueableContext context) {
            for (Id authId : authDeltas.keySet()) {
                Decimal delta = authDeltas.get(authId);
                if (delta != 0) {
                    propagateDelta(authId, delta);
                }
            }
        }
    }

    /*********************************************************************************************************     * 
     * @name            Input     * 
     * @created         12 / 04 / 2026     * 
     * @description     input class for getAuthCaseCandidates(List<Input> inputs)* 
     * @param           Id claimId : target claim* 
     * @param           String sourceId : Authorization # (deprecated)* 
     * @param           String accountId : patient's acc Id* 
     * @param           Date dateFrom :  Claim DOS from* 
     * @param           Date dateTo : Claim DOS to* 
     * *********************************************************************************************************/
    public class Input {
        @InvocableVariable(required=true)
        public Id claimId;

        @InvocableVariable(required=false)
        public String sourceId;

        @InvocableVariable(required=true)
        public String accountId;

        @InvocableVariable(required=true)
        public Date dateFrom;

        @InvocableVariable(required=true)
        public Date dateTo;
    }

    /*********************************************************************************************************     * 
     * @name            Output     * 
     * @created         12 / 04 / 2026     * 
     * @description     input class for getAuthCaseCandidates(List<Input> inputs)* 
     * @param           List<Case> cases : candidate auths* 
     * @param           Boolean hasPhysicalTherapyPaid : flags if the target claim has PT items on 'Paid'
     * *********************************************************************************************************/
    public class Output {
        @InvocableVariable
        public List<Case> cases;

        @InvocableVariable
        public Boolean hasPhysicalTherapyPaid; 
    }

    /*********************************************************************************************************     * 
     * @name            getAuthCaseCandidates     * 
     * @created         12 / 04 / 2026     * 
     * @description     Method used on Claim Quick Action to retrieve auth case candidates for a certain claim * 
     * @param           Input inputs : (view inner class)* 
     * @return          List<Output> : (view inner class)   *
     * *********************************************************************************************************/
    @InvocableMethod(label='Get Authorization Case Candidates')
    public static List<Output> getAuthCaseCandidates(List<Input> inputs) {  

        List<Output> output = new List<Output>();

        if (inputs == null || inputs.isEmpty()) {
            return output;
        }

        Input input = inputs[0];

        // STEP 1: Get CPT codes from Claim
        List<ClaimCoveragePaymentDetail> clis = [
            SELECT ARC_ProcedureCodeName__c
            FROM ClaimCoveragePaymentDetail 
            WHERE ARC_Claim__c = :input.claimId 
            AND ARC_Medical_Visit_Reason__c = 'PhysicalTherapy'
        ];
        
        Set<String> codes = new Set<String>();
        for (ClaimCoveragePaymentDetail c : clis) {
            if (c.ARC_ProcedureCodeName__c != null) {
                codes.add(c.ARC_ProcedureCodeName__c);
            }
        }

        if (codes.isEmpty()) {
            return output;
        }

        // String sourceLike = '%' + input.sourceId + '%';

        // STEP 2: Query
        List<arcsona__PriorAuthRequestItem__c> paris = [
            SELECT 
                arcsona__PriorAuthorization__r.arcsona__Case__r.Id,
                arcsona__PriorAuthorization__r.arcsona__Case__r.CaseNumber,
                arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_Case_URL__c,
                arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_PT_Auth_From_Date__c,
                arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_PT_Auth_To_Date__c,
                arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_PT_Visits_Used__c,
                arcsona__PriorAuthorization__r.arcsona__Case__r.Base_Source_System_Id__c,
                arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_PT_Visits_Authorized__c,
                arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_PT_Visits_Used_Total__c,
                arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_PT_Calculated_Visits_Limit__c
            FROM arcsona__PriorAuthRequestItem__c
            WHERE arcsona__CPTCode__r.Name IN :codes
            AND  arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_PersonAccount__c = :input.accountId
            // AND arcsona__PriorAuthorization__r.arcsona__Case__r.Base_Source_System_Id__c LIKE :sourceLike
            AND arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_PT_Auth_From_Date__c <= :input.dateFrom 
            AND arcsona__PriorAuthorization__r.arcsona__Case__r.ARC_PT_Auth_To_Date__c >= :input.dateTo 
            AND (NOT arcsona__PriorAuthorization__r.arcsona__Case__r.HealthCloudGA__SourceSystemID__c LIKE '%_void%')
        ];

        Boolean hasPaidPT = [
            SELECT COUNT()
            FROM ClaimCoveragePaymentDetail 
            WHERE ARC_Claim__c = :input.claimId 
            AND ARC_Medical_Visit_Reason__c = 'PhysicalTherapy'
            AND Status = 'Paid' AND ARC_Claim__r.Status != 'Adjusted'  
        ] > 0;

        // STEP 3: Build Cases List (for Flow)
        Map<Id, Case> caseMap = new Map<Id, Case>();
        for (arcsona__PriorAuthRequestItem__c pari : paris) {
            Case c = pari.arcsona__PriorAuthorization__r.arcsona__Case__r;
            if (c != null && !caseMap.containsKey(c.Id)) {
                caseMap.put(c.Id, c);
            }
        }

        System.debug('FLOW RESULTS -----> ' + caseMap);
                List<Case> prioritized = new List<Case>();
        List<Case> others = new List<Case>();

        for (Case c : caseMap.values()) {
            if (c.Base_Source_System_Id__c != null && input.sourceId != null && c.Base_Source_System_Id__c.contains(input.sourceId)) {
                prioritized.add(c);
            } else {
                others.add(c);
            }
        }

        Output o = new Output();
        o.cases = new List<Case>();
        o.cases.addAll(prioritized);
        o.cases.addAll(others);
        o.hasPhysicalTherapyPaid = hasPaidPT;
        
        output.add(o);

        return output;
    }

    /*********************************************************************************************************     * 
     * @name            getSMBs     * 
     * @created         12 / 04 / 2026     * 
     * @description     Method used on Arc_PreAuthSMBList to obtain the list of related claims * 
     * @param           Id caseId : target auth case* 
     * @return          List<Claim> : claims related to the auth   *
     * *********************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Claim> getSMBs(Id caseId) {
        return [
            SELECT Id, Name, CreatedDate
            FROM Claim
            WHERE ARC_PriorAuthorizationCase__c = :caseId
            ORDER BY CreatedDate DESC
        ];
    }
}