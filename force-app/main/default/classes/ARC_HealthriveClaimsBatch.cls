global  with sharing class ARC_HealthriveClaimsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    public String fileBody = '';
    public Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox ;
    String dateFormat = Datetime.now().format('YYYYMMdd_HHmmss', 'America/Los_Angeles');
    String fileName = dateFormat+'_UHSM_Claims.csv';
    ARC_SureCoClaim__c sureCoClaim = [SELECT ARC_LastSent__c FROM ARC_SureCoClaim__c WHERE Name = 'SureCoClaim' LIMIT 1];  
    
    
    global ARC_HealthriveClaimsBatch() {
        fileBody = 'ClaimID_PK,Claim Number,Payment Sequence,Claim Original Number,Claim Detail Line Number,Service Category Code,Claim Type,Service From Date,Service To Date,Date of Service,Received Date,Location of Service Code,Medical Diagnosis Code,Medical Diagnosis Code One Description,Procedure Code,Revenue Code,Charge Amount,Allowed Amount,Deductible Amount,Copayment Amount,Coinsurance Amount,Paid Amount,COB Other Allowed Amount,Source Claim Status,Paid Date,Member Number,Member Name,Benefit Plan ID Value,Provider Number,Provider Name,Payee Number,Payee Name,Payee Tax Id Number,Document Control Number,Check Number,Modifier 1 Code,Modifier 2 Code,Modifier 3 Code,Modifier 4 Code,Medical Diagnosis Code Two, Medical Diagnosis Code Two Description,Medical Diagnosis Code Three,Medical Diagnosis Code Three Description,Medical Diagnosis Code Four,Medical Diagnosis Code Four Description,Medical Diagnosis Code Five,Medical Diagnosis Code Five Description,Medical Diagnosis Code Six,Medical Diagnosis Code Six Description,Medical Diagnosis Code Seven,Medical Diagnosis Code Seven Description,Medical Diagnosis Code Eight,Medical Diagnosis Code Eight Description,Medical Diagnosis Code Nine,Medical Diagnosis Code Nine Description,Medical Diagnosis Code Ten,Medical Diagnosis Code Ten Description,Medical Diagnosis Code Eleven,Medical Diagnosis Code Eleven Description,Medical Diagnosis Code Twelve,Medical Diagnosis Code Twelve Description,Secondary Payee Name,Secondary Payee Number,Claim Entered Date,Net Paid Amount,Adjustment Reason Code,Adjustment Reason Description,Load Timestamp,Line Reason Code, Member SSN, Member Gender,Member Date of Birth,Member Street,Member City,Member County,Member State,Member Zip,Member Phone,Member Relationship,Attending provider,Attending provider Street,Attending provider City,Attending provider County,Attending provider State, Attending provider Zip,Place Of Service,Revenue Code,Procedure Code Description,DRG code,DRG Description,Service Quantity,Admit Type,Adjustment Codes';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        fileBody = 'ClaimID_PK,Claim Number,Payment Sequence,Claim Original Number,Claim Detail Line Number,Service Category Code,Claim Type,Service From Date,Service To Date,Date of Service,Received Date,Location of Service Code,Medical Diagnosis Code,Medical Diagnosis Code One Description,Procedure Code,Revenue Code,Charge Amount,Allowed Amount,Deductible Amount,Copayment Amount,Coinsurance Amount,Paid Amount,COB Other Allowed Amount,Source Claim Status,Paid Date,Member Number,Member Name,Benefit Plan ID Value,Provider Number,Provider Name,Payee Number,Payee Name,Payee Tax Id Number,Document Control Number,Check Number,Modifier 1 Code,Modifier 2 Code,Modifier 3 Code,Modifier 4 Code,Medical Diagnosis Code Two, Medical Diagnosis Code Two Description,Medical Diagnosis Code Three,Medical Diagnosis Code Three Description,Medical Diagnosis Code Four,Medical Diagnosis Code Four Description,Medical Diagnosis Code Five,Medical Diagnosis Code Five Description,Medical Diagnosis Code Six,Medical Diagnosis Code Six Description,Medical Diagnosis Code Seven,Medical Diagnosis Code Seven Description,Medical Diagnosis Code Eight,Medical Diagnosis Code Eight Description,Medical Diagnosis Code Nine,Medical Diagnosis Code Nine Description,Medical Diagnosis Code Ten,Medical Diagnosis Code Ten Description,Medical Diagnosis Code Eleven,Medical Diagnosis Code Eleven Description,Medical Diagnosis Code Twelve,Medical Diagnosis Code Twelve Description,Secondary Payee Name,Secondary Payee Number,Claim Entered Date,Net Paid Amount,Adjustment Reason Code,Adjustment Reason Description,Load Timestamp,Line Reason Code, Member SSN, Member Gender,Member Date of Birth,Member Street,Member City,Member County,Member State,Member Zip,Member Phone,Member Relationship,Attending provider,Attending provider Street,Attending provider City,Attending provider County,Attending provider State, Attending provider Zip,Place Of Service,Revenue Code,Procedure Code Description,DRG code,DRG Description,Service Quantity,Admit Type,Adjustment Codes';
        return Database.getQueryLocator([
            SELECT Id, 
            ARC_Claim__c,
            ARC_Claim__r.Name, 
            ARC_Claim__r.RecordType.Name,
            ARC_Claim__r.ARC_MemberId__c, 
            ARC_Claim__r.ARC_MemberContact__r.Name,
            ARC_Claim__r.ARC_Vendor__r.ARC_NationalProviderId__c,
            ARC_Claim__r.ARC_Vendor__r.Name,
            ARC_Claim__r.ARC_CheckRun__r.Name,
            ARC_Claim__r.Status,
            ARC_Claim__r.CreatedDate,
            ARC_Mod1__c,
            ARC_Mod2__c,
            ARC_Mod3__c,
            ARC_Mod4__c,
            Status,
            ARC_Claim__r.DX_A__r.Name,//Code
            ARC_Claim__r.DX_A__r.vlocity_ins__ShortDescription__c,//Code Description
            ARC_Claim__r.DX_B__r.Name,//Code
            ARC_Claim__r.DX_B__r.vlocity_ins__ShortDescription__c,//Code Description
            ARC_Claim__r.DX_C__r.Name,//Code
            ARC_Claim__r.DX_C__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.DX_D__r.Name,//Code
            ARC_Claim__r.DX_D__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.DX_E__r.Name,//Code
            ARC_Claim__r.DX_E__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.DX_F__r.Name,//Code
            ARC_Claim__r.DX_F__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.DX_G__r.Name,//Code
            ARC_Claim__r.DX_G__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.DX_H__r.Name,//Code
            ARC_Claim__r.DX_H__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.DX_I__r.Name,//Code
            ARC_Claim__r.DX_I__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.DX_J__r.Name,//Code
            ARC_Claim__r.DX_J__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.DX_K__r.Name,//Code
            ARC_Claim__r.DX_K__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.DX_L__r.Name,//Code
            ARC_Claim__r.DX_L__r.vlocity_ins__ShortDescription__c,//Code Des
            ARC_Claim__r.ARC_TypeofBill__c,
            LastModifiedDate,
            Name,
            ARC_Copay__c,
            ARC_DateOfService__c,
            ARC_NetPaid__c,
            ARC_PaidDate__c,
            ARC_ProcedureCode__r.Name,
            ARC_RevenueCode__c,
            ClaimedAmount,
            ARC_Allowed__c,
            ARC_Deductible__c,
            ARC_Coinsurance__c,
            CreatedDate,
            ARC_Claim__r.PolicyNumber.Product.Name,
            ARC_Claim__r.SourceSystemIdentifier,//************************Fields after here were added**********************
            ARC_Claim__r.ARC_MemberContact__r.ARC_CensusMember__r.vlocity_ins__SocialSecurityNumber__c,//Member SSN
            ARC_Claim__r.ARC_MemberContact__r.ARC_CensusMember__r.vlocity_ins__Gender__c,//Member Gender
            ARC_Claim__r.ARC_MemberContact__r.ARC_CensusMember__r.vlocity_ins__Birthdate__c,// Member Date of Birth
            ARC_Claim__r.ARC_MemberContact__r.ARC_CensusMember__r.ARC_PhysicalAddressStreet__c,//Member Street
            ARC_Claim__r.ARC_MemberContact__r.ARC_CensusMember__r.ARC_PhysicalAddressCity__c,//Member City
            ARC_Claim__r.ARC_MemberContact__r.ARC_CensusMember__r.ARC_PhysicalAddressState__c,//Member County and State
            ARC_Claim__r.ARC_MemberContact__r.ARC_CensusMember__r.ARC_PhysicalAddressZipCode__c,//Member Zip Code
            ARC_Claim__r.ARC_MemberContact__r.ARC_CensusMember__r.ARC_Phone__c,//Member Phone
            ARC_Claim__r.ARC_MemberContact__r.ARC_CensusMember__r.ARC_Relationship__c,//Member Relationship
            ARC_Claim__r.ARC_Attending_Provider__r.Name,//Attending provider Relationship
            ARC_Claim__r.ARC_Attending_Provider__r.PersonMailingStreet,//Attending provider Street
            ARC_Claim__r.ARC_Attending_Provider__r.PersonMailingCity,//Attending provider City
            ARC_Claim__r.ARC_Attending_Provider__r.PersonMailingState,//Attending provider County and State  
            ARC_Claim__r.ARC_Attending_Provider__r.PersonMailingPostalCode,//Attending provider Zip Code    
            ARC_Claim__r.ARC_PlaceOfService__c,//Place Of Service Code
            ARC_ProcedureCode__r.vlocity_ins__LongDescription__c, // Procedure Code Description
            ARC_Claim__r.ARC_Submitted_DRG_Code__r.Name, // If Institutional DRG code description
            ARC_Claim__r.ARC_Submitted_DRG_Code__r.vlocity_ins__ShortDescription__c, // If Institutional DRG code description
            ARC_Quantity__c,// Service Quantity
            ARC_Claim__r.ARC_AdmitDX_Code__c,//Admit Type
            ARC_Claim__r.ARC_DOSFrom__c,
            ARC_Claim__r.ARC_DOSTo__c,
            (SELECT Id, ARC_CodeNameText__c, ARC_ReasonCode__r.ARC_Status__c FROM Claim_Reason_Codes__r)
            FROM ClaimCoveragePaymentDetail WHERE LastModifiedDate > :sureCoClaim.ARC_LastSent__c AND ARC_Claim__r.HaxSMB__c = FALSE ORDER BY CreatedDate DESC
        ]);
    }
    global void execute(Database.BatchableContext BC, List<ClaimCoveragePaymentDetail> claimCoverages) {

        
        //TO DO: Include the DX codes of Institutional Claims. 
        //Get all the Claims Ids
        Set <Id> institutionalClaimIds = new Set<Id>();
        Set <Id> profClaimIds = new Set<Id>();
        for (ClaimCoveragePaymentDetail cc : claimCoverages) {
            if(cc.ARC_Claim__r?.RecordType?.Name =='Institutional') institutionalClaimIds.add(cc.ARC_Claim__c);
            else profClaimIds.add(cc.ARC_Claim__c);
        }

        //Get all the InstitutionalCodes related to the InstitutionalClaims
        Map <Id, List<ARC_Institutional_Claim_Code__c>> icdCodesMap = new Map <Id, List<ARC_Institutional_Claim_Code__c>>();
        List<ARC_Institutional_Claim_Code__c> icdList = [SELECT Id,ARC_Institutional_Claim__c,ARC_ICD_DX__c,ARC_ICD_DX__r.Name,ARC_ICD_DX__r.vlocity_ins__ShortDescription__c  FROM ARC_Institutional_Claim_Code__c WHERE ARC_Institutional_Claim__c IN :institutionalClaimIds AND ARC_ICD_DX__c != null ORDER BY CreatedDate ASC];
        for(ARC_Institutional_Claim_Code__c icd: icdList){
            List<ARC_Institutional_Claim_Code__c> icdCodeList = icdCodesMap.get(icd.ARC_Institutional_Claim__c);
            if(icdCodeList == null){
                List<ARC_Institutional_Claim_Code__c> newIcdCodeList = new List<ARC_Institutional_Claim_Code__c>{icd};
                icdCodesMap.put(icd.ARC_Institutional_Claim__c, newIcdCodeList);
            } 
            else icdCodeList.add(icd);
            //icdCodesMap.put(icd.ARC_Institutional_Claim__c, icdCodeList);
        }

        for (ClaimCoveragePaymentDetail cc : claimCoverages) {
            Object dateOfService =cc.ARC_DateOfService__c;
            String reasonCodes = '';
            String adjustmentCodes = '';
            List <ARC_Institutional_Claim_Code__c> claimDxCodes = new List<ARC_Institutional_Claim_Code__c>{null, null, null, null, null, null, null, null, null, null, null, null};
            claimDxCodes = icdCodesMap.get(cc.ARC_Claim__c);
            if(claimDxCodes != null) {
                for(Integer i=claimDxCodes.size()-1; i<11;i++){
                    claimDxCodes.add(null);
                }
                System.debug(claimDxCodes.size());
            }
           // if(claimDxCodes != null)System.debug('claimDxCodes.size() '+ claimDxCodes.size() + ' - Claim Id: '+ cc.ARC_Claim__c);
            //if(claimDxCodes != null)System.debug(cc.ARC_Claim__c+' - '+claimDxCodes);    
            List<ARC_ClaimReasonCode__c> rCodes = (List<ARC_ClaimReasonCode__c>)cc.Claim_Reason_Codes__r;
            for (ARC_ClaimReasonCode__c rc : rCodes) {
                if(rc.ARC_CodeNameText__c != null){
                    if(reasonCodes == '') reasonCodes = rc.ARC_CodeNameText__c;
                    else reasonCodes = reasonCodes + ' - ' + rc.ARC_CodeNameText__c;
                }
                if(rc.ARC_ReasonCode__r?.ARC_Status__c != null && rc.ARC_ReasonCode__r.ARC_Status__c == 'Adjustment') {
                    if(adjustmentCodes == '') adjustmentCodes = rc.ARC_CodeNameText__c;
                    else adjustmentCodes = adjustmentCodes + ' - ' + rc.ARC_CodeNameText__c;
                }
            }

            
            fileBody = fileBody+'\n"' 
            + (String.valueOf( cc?.ARC_Claim__c ) != null ? String.valueOf( cc?.ARC_Claim__c ) : '' )+'","' //ClaimID_PK","
            + (String.valueOf( cc?.ARC_Claim__r?.Name ) != null ? String.valueOf( cc?.ARC_Claim__r.Name ) : '' )+'","' //Claim Number","
            + '' +'","' //Payment Sequence","
            + (String.valueOf( cc?.ARC_Claim__r.Name ) != null ? String.valueOf( cc?.ARC_Claim__r.Name ) : '' )+'","' //Claim Original Number","
            + (String.valueOf( cc?.Name ) != null ? String.valueOf( cc.Name ) : '' )+'","' //Claim Detail Line Number","
            + '' +'","' //Service Category Code","
            + (String.valueOf( cc?.ARC_Claim__r?.RecordType.Name ) != null ? String.valueOf( cc?.ARC_Claim__r?.RecordType.Name  ) : '' ) +'","' //Claim Type","
            + ( dateOfService  != null ?  dateOfService  : (cc?.ARC_Claim__r?.ARC_DOSFrom__c != null ? cc?.ARC_Claim__r?.ARC_DOSFrom__c :null) )+'","' //Service From Date","
            + ( dateOfService  != null ?  dateOfService  : (cc?.ARC_Claim__r?.ARC_DOSTo__c != null ? cc?.ARC_Claim__r?.ARC_DOSTo__c :null) )+'","' //Service To Date","
            + ( dateOfService  != null ? dateOfService  : (cc?.ARC_Claim__r?.ARC_DOSFrom__c != null ? cc?.ARC_Claim__r?.ARC_DOSFrom__c :null) )+'","' //Date of Service","
            + cc?.ARC_Claim__r?.CreatedDate +'","' //Received Date","
            + '' +'","' //Location of Service Code","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_A__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_A__r.Name ) : (claimDxCodes!=null && claimDxCodes[0]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[0]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_A__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_A__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[0]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[0]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code One Description","
            + (String.valueOf( cc?.ARC_ProcedureCode__c ) != null ? String.valueOf( cc?.ARC_ProcedureCode__r.Name ) : '' )+'","' //Procedure Code","
            + (String.valueOf( cc?.ARC_RevenueCode__c ) != null ? String.valueOf( cc?.ARC_RevenueCode__c ) : '' )+'","' //Revenue Code","
            + (String.valueOf( cc?.ClaimedAmount ) != null ? String.valueOf( cc?.ClaimedAmount ) : '' )+'","' //Charge Amount","
            + (String.valueOf( cc?.ARC_Allowed__c ) != null ? String.valueOf( cc?.ARC_Allowed__c ) : '' )+'","' //Allowed Amount","
            + (String.valueOf( cc?.ARC_Deductible__c ) != null ? String.valueOf( cc?.ARC_Deductible__c ) : '' )+'","' //Deductible Amount","
            + (String.valueOf( cc?.ARC_Copay__c ) != null ? String.valueOf( cc?.ARC_Copay__c ) : '' )+'","' //Copayment Amount","
            + (String.valueOf( cc?.ARC_Coinsurance__c ) != null ? String.valueOf( cc?.ARC_Coinsurance__c ) : '' )+'","' //Coinsurance Amount","
            + (String.valueOf( cc?.ARC_NetPaid__c ) != null && cc.Status == 'Paid' ? String.valueOf( cc?.ARC_NetPaid__c ) : '' )+'","' //Paid Amount","
            + '' +'","' //COB Other Allowed Amount","
            + (String.valueOf( cc?.ARC_Claim__r.Status ) != null ? String.valueOf( cc?.ARC_Claim__r.Status ) : '' ) +'","' //Source Claim Status","
            + (String.valueOf( cc?.ARC_PaidDate__c ) != null ? String.valueOf( cc?.ARC_PaidDate__c ) : '' )+'","' //Paid Date","
            + (String.valueOf( cc?.ARC_Claim__r.ARC_MemberId__c ) != null ? String.valueOf( cc?.ARC_Claim__r.ARC_MemberId__c ) : '' )+'","' //Member Number","
            + (String.valueOf( cc?.ARC_Claim__r.ARC_MemberContact__r.Name ) != null ? String.valueOf( cc?.ARC_Claim__r.ARC_MemberContact__r.Name ) : '' )+'","' //Member Name","
            + (String.valueOf( cc?.ARC_Claim__r.PolicyNumber.Product.Name ) != null ? String.valueOf( cc?.ARC_Claim__r.PolicyNumber.Product.Name ) : '' ) +'","' //Benefit Plan ID Value","
            + (String.valueOf( cc?.ARC_Claim__r.ARC_Vendor__r.ARC_NationalProviderId__c ) != null ? String.valueOf( cc?.ARC_Claim__r.ARC_Vendor__r.ARC_NationalProviderId__c ) : '' )+'","' //Provider Number","
            + (String.valueOf( cc?.ARC_Claim__r.ARC_Vendor__r.Name ) != null ? String.valueOf( cc?.ARC_Claim__r.ARC_Vendor__r.Name ) : '' )+'","' //Provider Name","
            + '' +'","' //Payee Number","
            + '' +'","' //Payee Name","
            + '' +'","' //Payee Tax Id Number","
            + (String.valueOf( cc?.ARC_Claim__r.SourceSystemIdentifier ) != null ? String.valueOf( cc?.ARC_Claim__r.SourceSystemIdentifier ) : '' ) +'","' //Document Control Number","
            + (String.valueOf( cc?.ARC_Claim__r.ARC_CheckRun__r.Name ) != null ? String.valueOf( cc?.ARC_Claim__r.ARC_CheckRun__r.Name ) : '' )+'","' //Check Number","
            + (String.valueOf( cc?.ARC_Mod1__c ) != null ? String.valueOf( cc?.ARC_Mod1__c ) : '' )+'","' //Modifier 1 Code","
            + (String.valueOf( cc?.ARC_Mod2__c ) != null ? String.valueOf( cc?.ARC_Mod2__c ) : '' )+'","' //Modifier 2 Code","
            + (String.valueOf( cc?.ARC_Mod3__c ) != null ? String.valueOf( cc?.ARC_Mod3__c ) : '' )+'","' //Modifier 3 Code","
            + (String.valueOf( cc?.ARC_Mod4__c ) != null ? String.valueOf( cc?.ARC_Mod4__c ) : '' )+'","' //Modifier 4 Code","
            //DX Codes
            + (String.valueOf( cc?.ARC_Claim__r?.DX_B__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_B__r.Name ) : (claimDxCodes!=null && claimDxCodes[1] != null && claimDxCodes[1]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[1]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Two","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_B__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_B__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[1]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[1]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Two Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_C__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_C__r.Name ) : (claimDxCodes!=null && claimDxCodes[2] != null && claimDxCodes[2]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[2]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Three","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_C__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_C__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[2]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[2]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Three Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_D__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_D__r.Name ) : (claimDxCodes!=null && claimDxCodes[3] != null && claimDxCodes[3]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[3]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Four","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_D__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_D__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[3]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[3]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Four Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_E__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_E__r.Name ) : (claimDxCodes!=null && claimDxCodes[4] != null && claimDxCodes[4]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[4]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Five","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_E__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_E__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[4]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[4]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Five Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_F__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_F__r.Name ) : (claimDxCodes!=null && claimDxCodes[5] != null && claimDxCodes[5]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[5]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Six","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_F__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_F__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[5]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[5]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Six Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_G__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_G__r.Name ) : (claimDxCodes!=null && claimDxCodes[6] != null && claimDxCodes[6]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[6]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Seven","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_G__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_G__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[6]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[6]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Seven Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_H__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_H__r.Name ) : (claimDxCodes!=null && claimDxCodes[7] != null && claimDxCodes[7]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[7]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Eight","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_H__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_H__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[7]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[7]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Eight Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_I__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_I__r.Name ) : (claimDxCodes!=null && claimDxCodes[8] != null && claimDxCodes[8]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[8]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Nine","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_I__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_I__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[8]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[8]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Nine Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_J__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_J__r.Name ) : (claimDxCodes!=null && claimDxCodes[9] != null && claimDxCodes[9]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[9]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Ten","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_J__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_J__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[9]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[9]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Ten Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_K__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_K__r.Name ) : (claimDxCodes!=null && claimDxCodes[10] != null && claimDxCodes[10]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[10]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Eleven","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_K__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_K__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[10]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[10]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Eleven Description","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_L__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_L__r.Name ) : (claimDxCodes!=null && claimDxCodes[11] != null && claimDxCodes[11]?.ARC_ICD_DX__r?.Name != null ? String.valueOf(claimDxCodes[11]?.ARC_ICD_DX__r?.Name): '') )+'","' //Medical Diagnosis Code Twelve","
            + (String.valueOf( cc?.ARC_Claim__r?.DX_L__r?.vlocity_ins__ShortDescription__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.DX_L__r?.vlocity_ins__ShortDescription__c ) : ( claimDxCodes!=null && claimDxCodes[11]?.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c != null ? String.valueOf(claimDxCodes[11]?.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c) :'') )+'","' //Medical Diagnosis Code Twelve Description","
            + '' +'","' //Secondary Payee Name","
            + '' +'","' //Secondary Payee Number","
            + cc?.ARC_Claim__r?.CreatedDate +'","' //Claim Entered Date","
            + (String.valueOf( cc?.ARC_NetPaid__c ) != null ? String.valueOf( cc?.ARC_NetPaid__c ) : '' )+'","' //Net Paid Amount","
            + '' +'","' //Adjustment Reason Code","
            + '' +'","' //Adjustment Reason Description","
            + cc.ARC_Claim__r.CreatedDate +'","' //Load Timestamp","
            + reasonCodes +'","'//Line Reason Code
            //Fields Added
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.vlocity_ins__SocialSecurityNumber__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.vlocity_ins__SocialSecurityNumber__c ) : '' )+'","' //Member SSN","
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.vlocity_ins__Gender__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.vlocity_ins__Gender__c ) : '' )+'","' //Member Gender","
            + cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.vlocity_ins__Birthdate__c +'","' //Member Date of Birth","
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressStreet__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressStreet__c ) : '' )+'","' //Member Street","
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressCity__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressCity__c ) : '' )+'","' //Member City","
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressState__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressState__c ) : '' )+'","' //Member State","
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressState__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressState__c ) : '' )+'","' //Member County","
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressZipCode__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_PhysicalAddressZipCode__c ) : '' )+'","' //Member ZipCode","
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_Phone__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_Phone__c ) : '' )+'","' //Member Phone","
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_Relationship__c ) != null ? String.valueOf( cc?.ARC_Claim__r?.ARC_MemberContact__r?.ARC_CensusMember__r?.ARC_Relationship__c ) : '' )+'","' //Member Relationship","
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.Name ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.Name ) : '' )+'","' //Attending Provider
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingStreet ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingStreet ) : '' )+'","' //Attending Provider Street
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingCity ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingCity ) : '' )+'","' //Attending Provider City
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingState ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingState ) : '' )+'","' //Attending Provider County
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingState ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingState ) : '' )+'","' //Attending Provider State
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingPostalCode ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_Attending_Provider__r?.PersonMailingPostalCode ) : '' )+'","' //Attending Provider ZIP
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_PlaceOfService__c ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_PlaceOfService__c ) : '' )+'","' //Procedure Code
            + (String.valueOf( cc?.ARC_RevenueCode__c) != null ? String.valueOf(cc?.ARC_RevenueCode__c ) : '' )+'","' //Revenue Code
            + (String.valueOf( cc?.ARC_ProcedureCode__r?.vlocity_ins__LongDescription__c ) != null ? String.valueOf(cc?.ARC_ProcedureCode__r?.vlocity_ins__LongDescription__c ) : '' )+'","' //Procedure Code Description
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_Submitted_DRG_Code__r?.Name  ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_Submitted_DRG_Code__r?.Name) : '' )+'","' //DRG code description
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_Submitted_DRG_Code__r?.vlocity_ins__ShortDescription__c  ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_Submitted_DRG_Code__r?.vlocity_ins__ShortDescription__c) : '' )+'","' //DRG code description
            + (String.valueOf( cc?.ARC_Quantity__c  ) != null ? String.valueOf(cc?.ARC_Quantity__c) : '' )+'","' //Service Quantity
            + (String.valueOf( cc?.ARC_Claim__r?.ARC_AdmitDX_Code__c  ) != null ? String.valueOf(cc?.ARC_Claim__r?.ARC_AdmitDX_Code__c) : '' )+'","' //Admit Type
            + adjustmentCodes+ '"'; //Adjustment Reason codes
        }
        sendFile();
    }
    global void finish(Database.BatchableContext BC) {
        System.debug('insideFinish SureCo ');
        if(fileBody.length()>0) sendfile(); 

        if(!Test.isRunningTest()){
            if(!this.isSandbox){
                FTP2SF.FTP.Response result = FTP2SF.FTP.trn('UHSM', 'surecoClaims/' + filename, System.Label.ARC_SureCoClaimServerName,  'claims/inbound/'+filename);
                System.debug(result);
            }else{
                FTP2SF.FTP.Response result = FTP2SF.FTP.trn('UHSM', 'surecoClaimsTest/' + filename, System.Label.ARC_SureCoClaimServerName,  'claims/inbound/'+filename);
                System.debug(result);
            }
        }        
        //Update Last Sent
        sureCoClaim.ARC_LastSent__c = Datetime.now();
        update sureCoClaim;
    }


    private void sendFile(){
        try {
            if(!Test.isRunningTest()){
                if(!this.isSandbox){
                    FTP2SF.FTP.Response result = FTP2SF.FTP.append( 'UHSM', 'surecoClaims/'+filename, Blob.valueOf(fileBody));
                    System.debug(result);
                }else{
                    FTP2SF.FTP.Response result = FTP2SF.FTP.append( 'UHSM', 'surecoClaimsTest/'+filename, Blob.valueOf(fileBody));
                    System.debug(result);
                }
            }
            fileBody = '';

        } catch (Exception e) {
            System.debug('SureCo Claim Batch error: '+String.valueOf(e));
        }
    }

    
    @InvocableMethod(label='Run SureCo Claim File Batch' description='Runs the SureCo Claim File Batch' category='Elegibility Files')
    global static void runSureCoBatch(){
        ARC_HealthriveClaimsBatch a = new ARC_HealthriveClaimsBatch();
        Database.executeBatch(a,200);
    }
}