public without sharing class ARC_SG_Utilities {

    public static Map<String,Object> evaluateChanges (Map<String,Object> payload) {
        try {
            System.debug('Evaluating changes...');
            Map<String,Object> payloadMap = payload;
            // Map to put into payload with changes
            Map<String,Boolean> changesMap = new Map<String,Boolean>{
                'addMember' => false,
                'removeMember' => false,
                'programUpgrade' => false,
                'programDowngrade' => false,
                'agingOut' => false,
                'noChanges' => true
            };
            // Get current information (Policy, Programs, Members) and the new information
            Map<String,Object> currentStateMap = payloadMap.containsKey('currentState') ? (Map<String,Object>)payloadMap.get('currentState') : null;
            Map<String,Object> generalInfoMap = payload.containsKey('generalInformation') ? (Map<String,Object>)payload.get('generalInformation') : null;
             // Get upgrade and downgrade plans matrix values
            Map<String,Map<String,Object>> upgradeDowngradePlansMap = getUpgradeDowngradePlans();

            // Build current program map - product Id to Product Name
            Map<String,Object> currentProductIdToPlanNameMap = new Map<String,Object>();
            Set<String> currentPrograms = currentStateMap.containsKey('currentProducts') ? ((Map<String,Object>)currentStateMap.get('currentProducts')).keySet() : new Set<String>();
            if (currentPrograms != null && !currentPrograms.isEmpty()) {
                for (String planName : currentPrograms) {
                    Map<String,Object> planMap = ((Map<String,Object>)currentStateMap.get('currentProducts')).containsKey(planName) ? (Map<String,Object>)((Map<String,Object>)currentStateMap.get('currentProducts')).get(planName) : new Map<String,Object>();
                    if (!planMap.isEmpty()) currentProductIdToPlanNameMap.put((String)planMap.get('productId'), planName);
                }
            }
            // Build new program map - product Id to Product Name
            Map<String,Object> newProductIdToPlanNameMap = new Map<String,Object>();
            Set<String> newPrograms =  generalInfoMap.containsKey('medicalProgram') ? ((Map<String,Object>)generalInfoMap.get('medicalProgram')).keySet() : new Set<String>();
            if (newPrograms != null && !newPrograms.isEmpty()) {
                for (String planName : newPrograms) {
                    Map<String,Object> planMap = ((Map<String,Object>)generalInfoMap.get('medicalProgram')).containsKey(planName) ? (Map<String,Object>)((Map<String,Object>)generalInfoMap.get('medicalProgram')).get(planName) : new Map<String,Object>();
                    if (!planMap.isEmpty()) newProductIdToPlanNameMap.put((String)planMap.get('productId'), planName);
                }
            }

            // Current and New member lists
            List<Object> currentMemberList = currentStateMap.containsKey('currentMembers') ? (List<Object>)currentStateMap.get('currentMembers') : new List<Object>();
            System.debug('currentMemberList: ' + currentMemberList.size());
            Map<String,String> currentMemberToProductIdMap = new Map<String,String>(); // Map to put member external id to product id
            Map<String,Boolean> currentMemberToRemoveMemberMap = new Map<String,Boolean>(); // Map to put member external id to remove member boolean
            if (currentMemberList != null & !currentMemberList.isEmpty()) {
                for (Object currentMember : currentMemberList) {
                    Map<String,Object> currentMemberMap = (Map<String,Object>)currentMember;
                    String memberExtId = (String)currentMemberMap.get('memberExternalId');
                    String productId = (String)currentMemberMap.get('productId');
                    currentMemberToProductIdMap.put(memberExtId, productId);
                    currentMemberToRemoveMemberMap.put(memberExtId, true);
                }
            }
            List<Object> newMemberList = payload.containsKey('members') ? (List<Object>)payload.get('members') : new List<Object>();
            System.debug('newMemberList: ' + newMemberList.size());
            if (newMemberList != null && !newMemberList.isEmpty()) {
                for (Object member : newMemberList) {
                    Map<String,Object> memberMap = (Map<String,Object>)member;
                    memberMap.put('action', '');
                    String memberExtId = (String)memberMap.get('memberExternalId');
                    // Check if the member of the new list was already in the current member list, if not, is a new member
                    if (!currentMemberToProductIdMap.containsKey(memberExtId)) {
                        memberMap.put('action', 'Add member');
                        changesMap.put('addMember', true);
                        changesMap.put('noChanges', false);
                    } else {
                        currentMemberToRemoveMemberMap.put(memberExtId, false); // Set to false in remove member map
                        // Compare the current and the new member product
                        if (currentMemberToProductIdMap.get(memberExtId) != (String)memberMap.get('productId')) {
                            // Need to have a map with program upgrade or downgrade
                            String currentPlanName = (String)currentProductIdToPlanNameMap.get(currentMemberToProductIdMap.get(memberExtId));
                            String newPlanName = (String)newProductIdToPlanNameMap.get((String)memberMap.get('productId'));
                            if (newPlanName == 'WeShare Group Senior') {
                                memberMap.put('action', 'Aging out');
                                changesMap.put('agingOut', true);
                                changesMap.put('noChanges', false);
                                continue;
                            }
                            Map<String,Object> currentUpgradeDowngradePlans = upgradeDowngradePlansMap.get(currentPlanName); // Get all upgrade & downgrade plans based on the current member product name
                            String upgradeResult = currentUpgradeDowngradePlans == null ? null : (String) currentUpgradeDowngradePlans.get('Upgrade Result');
                            String downgradeResult = currentUpgradeDowngradePlans == null ? null : (String) currentUpgradeDowngradePlans.get('Downgrade Result');
                            Boolean noMatrixResult = String.isBlank(upgradeResult) && String.isBlank(downgradeResult);

                            if (
                                (!String.isBlank(upgradeResult) && !String.isBlank(newPlanName) && upgradeResult.toLowerCase().contains(newPlanName.toLowerCase()))
                                || noMatrixResult
                            ) {
                                changesMap.put('programUpgrade', true);
                                memberMap.put('action', 'Program Upgrade');
                            } else if (!String.isBlank(downgradeResult) && !String.isBlank(newPlanName) && downgradeResult.toLowerCase().contains(newPlanName.toLowerCase())) {
                                changesMap.put('programDowngrade', true);
                                memberMap.put('action', 'Program Downgrade');
                            }
                            changesMap.put('noChanges', false);
                        }
                    }
                }
            }

            // Check if a member was removed, if yes, set removeMember to true
            for (Object currentMember : currentMemberList) {
                Map<String,Object> currentMemberMap = (Map<String,Object>)currentMember;
                currentMemberMap.put('action', '');
                Boolean wasRemoved = currentMemberToRemoveMemberMap.get((String)currentMemberMap.get('memberExternalId'));
                if (wasRemoved == true) {
                    currentMemberMap.put('action', 'Remove Member');
                    changesMap.put('removeMember', true);
                    changesMap.put('noChanges', false);
                }
            }

            currentStateMap.put('currentMembers', currentMemberList);
            generalInfoMap.put('qleChanges', changesMap);
            payloadMap.put('generalInformation', generalInfoMap); // Add changes map to payload to be returned
            payloadMap.put('members', newMemberList); // Update member list with additional information
            payloadMap.put('currentState', currentStateMap); // Add current state node with updates current member list
            System.debug('Final Payload: ' + JSON.serializePretty(payloadMap)); 
            return payloadMap;

        } catch (Exception e) {
            System.debug('Error en evaluateChanges method: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw e;
        }
    }




    // HELPER METHODS
@TestVisible
    private static Map<String,Map<String,Object>> getUpgradeDowngradePlans() {
        Map<String,Map<String,Object>> upgradeDowngradePlans = new Map<String,Map<String,Object>>();

        vlocity_ins__CalculationMatrixVersion__c matrixVersion = [
            SELECT Id, Name,vlocity_ins__CalculationMatrixId__c
            FROM vlocity_ins__CalculationMatrixVersion__c 
            WHERE vlocity_ins__IsEnabled__c = true AND vlocity_ins__CalculationMatrixId__r.Name = 'ARC_UHSM_Programs2023' 
            ORDER BY vlocity_ins__VersionNumber__c DESC 
            LIMIT 1
        ];

        List<vlocity_ins__CalculationMatrixRow__c> rows = [
            SELECT Id,
                vlocity_ins__InputData__c,
                vlocity_ins__OutputData__c
            FROM vlocity_ins__CalculationMatrixRow__c
            WHERE vlocity_ins__CalculationMatrixVersionId__c = :matrixVersion.Id
        ];

        for (vlocity_ins__CalculationMatrixRow__c row : rows) {
            Map<String,Object> inputMap = row.vlocity_ins__InputData__c != null ? (Map<String,Object>)JSON.deserializeUntyped(row.vlocity_ins__InputData__c) : null;
            Map<String,Object> outputMap = row.vlocity_ins__OutputData__c != null ? (Map<String,Object>)JSON.deserializeUntyped(row.vlocity_ins__OutputData__c) : null;
            if (inputMap != null && outputMap != null && inputMap.containsKey('Program')) {
                String inputPlan = (String)inputMap.get('Program');
                upgradeDowngradePlans.put(inputPlan, outputMap);
            }
        }

        System.debug('upgradeDowngradePlans: ' + JSON.serialize(upgradeDowngradePlans));
        System.debug('upgradeDowngradePlans: ' + upgradeDowngradePlans.size()); 
        return upgradeDowngradePlans;
    }

}