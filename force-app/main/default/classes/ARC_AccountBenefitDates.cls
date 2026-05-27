/*******************************************************************
* @ClassName          :   ARC_AccountBenefitDates
* @Description        :   Manages logic for: 
                            * ARC_PreExistingResetDate__c – Start of last Pre-existing Conditions benefit period.
                            * ARC_MaternityResetDate__c – Start of last Maternity benefit period.
                           
* @MethodName         :   updateContinuousMembershipStartDateBulk
********************************************************************/
public with sharing class ARC_AccountBenefitDates {

    
    private static final String MAT_CODE = 'MAT__c';
    private static final Integer MAT_YEARS = 2;
    private static final String PREE_CODE = 'PREEX__c';
    private static final Integer PREE_YEARS = 3;

    public class RequestsVariables {
        @InvocableVariable(label='List of Record Ids' description='PA record Ids')
        public list<Id> listRecordIds;
    }

    /*******************************************************************
    * @MethodName         :   updateAccountBenefitDates
    * @Description        :   Used in PersonAccount Activation & Update Continuous Membership Start Date flows. 
                              This should execute when a contract activates and when an account becomes activated.
                                Updates Account fields:
                                * ARC_PreExistingResetDate__c. 
                                * ARC_MaternityResetDate__c.  
    ********************************************************************/
    @InvocableMethod(label='Update Benefit Start Dates for Accounts' description='description' category='Person Account')
    public static void updateAccountBenefitDates (List<RequestsVariables> requests) {
        List<Id> recordIds = new List<Id>();
        List<Account> accountsToUpdate = new List<Account>();
        for (RequestsVariables request : requests) {
            if (request.listRecordIds != null && !request.listRecordIds.isEmpty()) {
                recordIds.addAll(request.listRecordIds);
            }
        }

        Map<Id,Date> maternityResetDates = getResetResetDate(recordIds, MAT_CODE, MAT_YEARS);
        Map<Id,Date> preExistingResetDates = getResetResetDate(recordIds, PREE_CODE, PREE_YEARS);
    
        Set<Id> allAccountIds = new Set<Id>();
        allAccountIds.addAll(maternityResetDates.keySet());
        allAccountIds.addAll(preExistingResetDates.keySet());

        for (Id accId : allAccountIds) {
            Account acc = new Account(
                Id = accId,
                ARC_MaternityResetDate__c    = maternityResetDates.get(accId),
                ARC_PreExistingResetDate__c  = preExistingResetDates.get(accId)
            );
            accountsToUpdate.add(acc);
        }
        update accountsToUpdate;
    }


    public static Map<Id,Date> getResetResetDate (List<Id> recordIds, String codeType, Integer benefitYears) {
        Map<Id,Date> accIdToResetDate = new Map<Id,Date>();
        Map<Id, List<Map<String,Object>>> coveragePeriods = ARC_SMBUtility.mapCoveragePeriods(recordIds, codeType);
        for (Id accId : coveragePeriods.keySet()) {
            List<Map<String,Object>> coveragePeriodsForAcc = coveragePeriods.get(accId);
            coveragePeriodsForAcc.sort(new SortByStartDate());
            System.debug('SORTED LIST: ' + coveragePeriodsForAcc);
            
            Date resetDate = null;
            Date prevEnd = null;


            for (Map<String, Object> period : coveragePeriodsForAcc) {
                System.debug('PERIOD iteration:: resetDate_' + resetDate + ' prevEnd_' + prevEnd);
                if (period == null || !period.containsKey('dates')) continue;
                
                List<Date> dates = (List<Date>) period.get('dates');
                if (dates == null || dates.size() < 2) continue;
                

                Boolean isUHSM = (Boolean) period.get('UHSMProgram');
                Date startDate = dates[0];
                Date endDate = dates[1];

                // ---------- 1. If resetDate is not assigned yet ----------
                if (resetDate == null) {
                    if (isUHSM == true) {
                        // First flagged=true period establishes the resetDate
                        resetDate = startDate;
                    }
                    prevEnd = endDate;
                    continue;
                }

                // ---------- 2. Determine if the period is continuous ----------
                Boolean isContinuous = (prevEnd != null && prevEnd.addDays(1) >= startDate);
                System.debug('isContinuous?: ' + isContinuous);
                if (isContinuous) {
                    // Continuous period never updates reset date
                    prevEnd = endDate;
                    continue;
                }

                // ---------- 3. Non-continuous period logic ----------
                System.debug('is within current benefit period?: ' + (resetDate.addYears(benefitYears) > startDate));
                System.debug('resetDate + add years: ' + resetDate.addYears(benefitYears));
                System.debug('current start: ' + startDate);
                if (resetDate.addYears(benefitYears) < startDate) {
                    // Gap big enough → only update if flagged TRUE
                    System.debug('yes im within period');
                    if (isUHSM == true) {
                        System.debug('yes is UHSM');
                        resetDate = startDate;
                    }else{
                        // if period is not flagged, set resetDate to null since coverage period has ended. (next iterations will find the next flagged period)
                        resetDate = null;
                    }
                } 
                // else: yearsDiff < benefitYears → do nothing
                
                System.debug('end period resetDate: ' + resetDate);
                System.debug('------------------------------------');
                
                prevEnd = endDate;
            }
            
            System.debug('final resetDate: ' + resetDate);
            accIdToResetDate.put(accId, resetDate);
        }
        System.debug('accIdToResetDate return_: ' + accIdToResetDate);
        return accIdToResetDate;
    }

    public class SortByStartDate implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> a, Map<String, Object> b) {
            // Obtener las listas de fechas
            List<Datetime> datesA = (List<Datetime>) a.get('dates');
            List<Datetime> datesB = (List<Datetime>) b.get('dates');

            // Tomar el primer elemento (asumiendo que siempre existe)
            Datetime firstA = datesA[0];
            Datetime firstB = datesB[0];

            // Comparación estándar
            if (firstA == firstB) return 0;
            return firstA < firstB ? -1 : 1;
        }
    }

}