@isTest
public with sharing class ARC_DocuSignHelperTest{
    @testSetup
    static void setup(){
        //TestSetup
    }

    @isTest
    public static void createRecipientsTest(){
        //#region inputMapString
        String inputMapString = '{"userInputs":[{"RF_Census.CRF_Dependants":4,"RF_Census.CRF_PrimaryMemberAge":32,"RF_Census.CRF_ExtraDependants":0,"RF_Census.CRF_Coverage":"Family","RF_Census.CRF_CoverageAIDD":"Family","CensusMemberId":"a3q3C000000fwsmQAA","RF_Census.CM_Age":32,"RF_Census.CM_IsPrimary":true,"RF_Census.CM_State":"KS","CensusMemberName":"AndresDeus","RF_Census.CM_Smoker":false,"RF_Census.CRF_State":"KS","SocialSecurity":"654646546","IsSpouse":false,"Email":"andres.deus@arcsona.com","Relationship":"Primary","AgeInSixMonths":32,"CensusMemberFirstName":"Andres","CensusMemberLastName":"Deus"},{"RF_Census.CRF_Dependants":4,"RF_Census.CRF_PrimaryMemberAge":32,"RF_Census.CRF_ExtraDependants":0,"RF_Census.CRF_Coverage":"Family","RF_Census.CRF_CoverageAIDD":"Family","CensusMemberId":"a3q3C000000fwsrQAA","RF_Census.CM_Age":29,"RF_Census.CM_IsPrimary":false,"RF_Census.CM_State":"KS","CensusMemberName":"PepitaLombarda","RF_Census.CM_Smoker":true,"RF_Census.CRF_State":"KS","SocialSecurity":"646546546","IsSpouse":false,"Relationship":"Spouse","AgeInSixMonths":29,"CensusMemberFirstName":"Pepita","CensusMemberLastName":"Lombarda"},{"RF_Census.CRF_Dependants":4,"RF_Census.CRF_PrimaryMemberAge":32,"RF_Census.CRF_ExtraDependants":0,"RF_Census.CRF_Coverage":"Family","RF_Census.CRF_CoverageAIDD":"Family","CensusMemberId":"a3q3C000000fwssQAA","RF_Census.CM_Age":26,"RF_Census.CM_IsPrimary":false,"RF_Census.CM_State":"KS","CensusMemberName":"PedroDeus","RF_Census.CM_Smoker":false,"RF_Census.CRF_State":"KS","SocialSecurity":"654654654","IsSpouse":false,"Relationship":"Child","AgeInSixMonths":26,"CensusMemberFirstName":"Pedro","CensusMemberLastName":"Deus"}],"primaryMemberEmail":"andres.deus@arcsona.com"}';
        //#endregion
        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        Boolean ret = docuSignHelper.invokeMethod('createRecipients', inputMap, outMap, options);

        System.assertEquals(true, ret);
    }

    @isTest
    public static void createMedicalQuestionsTest(){
        //#region inputMapString
        String inputMapString = '{"DocuSignData":{"Primary":{"ZipCode":"67337","State":"KS","Weight":"111","Name":"Amai Pregent","SocialSecurity":"123123123","LastName":"Pregent","Phone":"+12323423422","isSmoker":false,"Gender":"Female","Id":"a3q3C000001I7dOQAS","Email":"favexit789@kixotic.com","FirstName":"Amai","Height":"11' + '11","DOB":"1990-11-12","City":"Coffeyville","Address":"123 Meadow Lane"},"Spouse":{"Weight":"222","SocialSecurity":"234234234","Name":"Emmai Gregnant","isSmoker":false,"LastName":"Gregnant","Id":"a3q3C000001I7diQAC","Gender":"Female","FirstName":"Emmai","DOB":"1990-11-06","Height":"22'+ '11"},"Dependents":[{"Pregnant":true,"SocialSecurity":"234234234","Weight":"111","LastName":"Pregonate","Id":"a3q3C000001I7djQAC","isSmoker":true,"Height":"11'+ '11","Gender":"Female","FirstName":"Canaibe","Age":21,"DOB":"2000-11-14","Name":"Canaibe Pregonate"},{"Pregnant":true,"SocialSecurity":"111111111","Weight":"111","LastName":"Pranget","Id":"a3q3C000001I7dkQAC","isSmoker":false,"Height":"11'+ '11","Gender":"Female","FirstName":"Isabelity","Age":11,"DOB":"2010-11-18","Name":"Isabelity Pranget"}],"Plan":{"ApplicationFee":"$99.00","Name":"UHSM Vital $10K","EffectiveDate":"2022-11-15","MonthlyContribution":"$560.30"}},"MedicalQuestions":{"Cancers":[{"CHK_CheckCancer":true,"TXT_MemberNameCancer":"Emmai Gregnant","TXT_MemberIdCancer":"a3q3C000001I7diQAC","TXT_TypeOfCancer":"CANCERONE","DATE_Cancer":"2022-11-01"}],"PastConditions":[{"TXT_MemberPastConditions":"Amai Pregent","TXT_MemberIdPastConditions":"a3q3C000001I7dOQAS","MULSEL_Conditions":"Heart Disease;Behavioral/Mental Health;Chron'+ 's Disease"},{"TXT_MemberPastConditions":"Emmai Gregnant","TXT_MemberIdPastConditions":"a3q3C000001I7diQAC"},{"TXT_MemberPastConditions":"Canaibe Pregonate","TXT_MemberIdPastConditions":"a3q3C000001I7djQAC"},{"TXT_MemberPastConditions":"Isabelity Pranget","TXT_MemberIdPastConditions":"a3q3C000001I7dkQAC"}],"Internations":[{"CHKBOX_Internations":false,"DATE_MemberInternations":null,"TXTAREA_MemberInternations":null,"TXT_MemberIdInternations":"a3q3C000001I7dOQAS","TXT_MemberInternations":"Amai Pregent"},{"CHKBOX_Internations":true,"DATE_MemberInternations":"2013-10-30","TXTAREA_MemberInternations":"sdfsdfdv","TXT_MemberIdInternations":"a3q3C000001I7diQAC","TXT_MemberInternations":"Emmai Gregnant"},{"CHKBOX_Internations":false,"DATE_MemberInternations":null,"TXTAREA_MemberInternations":null,"TXT_MemberIdInternations":"a3q3C000001I7djQAC","TXT_MemberInternations":"Canaibe Pregonate"},{"CHKBOX_Internations":false,"DATE_MemberInternations":null,"TXTAREA_MemberInternations":null,"TXT_MemberIdInternations":"a3q3C000001I7dkQAC","TXT_MemberInternations":"Isabelity Pranget"}],"UnexpectedSymptoms":[{"CHKBOX_UnexpectedSymptoms":true,"DATE_MemberUnexpectedSymptoms":"2022-10-31","TXTAREA_MemberUnexpectedSymptoms":"wer","TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7dOQAS","TXT_MemberUnexpectedSymptoms":"Amai Pregent"},{"CHKBOX_UnexpectedSymptoms":false,"DATE_MemberUnexpectedSymptoms":null,"TXTAREA_MemberUnexpectedSymptoms":null,"TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7diQAC","TXT_MemberUnexpectedSymptoms":"Emmai Gregnant"},{"CHKBOX_UnexpectedSymptoms":false,"DATE_MemberUnexpectedSymptoms":null,"TXTAREA_MemberUnexpectedSymptoms":null,"TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7djQAC","TXT_MemberUnexpectedSymptoms":"Canaibe Pregonate"},{"CHKBOX_UnexpectedSymptoms":false,"DATE_MemberUnexpectedSymptoms":null,"TXTAREA_MemberUnexpectedSymptoms":null,"TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7dkQAC","TXT_MemberUnexpectedSymptoms":"Isabelity Pranget"}],"LWC_SelectCensusMember":{"SelectedCensusMemberId":"a3q3C000001I7diQAC"},"Prescriptions":[{"ReasonForMedication":"asdfsdzds","DateDiscontinued":"23/423423","PrescribingPhysician":"zsdvzsdv","NameOfMedication":"sdfasdfasdfsadf","MemberName":"Emmai Gregnant","DatePrescribed":"2342/342","MemberIdPrescription":"a3q3C000001I7diQAC"}],"Physicians":[{"CensusMemberId":"a3q3C000001I7djQAC","PhysicianCity":"v","YearDiagnosed":"3423","Controlled":"Yes","PhysicianPhone":"3423423232","PhysicianName":"sdvv","Diagnosis":"fasdfasdfdcsadczcfsdvz","CensusMemberName":"Canaibe Pregonate"}],"RAD_UnexplainedSymptoms":"Yes","RAD_PastConditions":"Yes","RAD_Internations":"Yes","RAD_Consults":"No","RAD_PendingTests":"No","RAD_PrescriptionMedications":"Yes","RAD_Addictions":"No","Consults":[null,null,null,null],"Addictions":[null,null,null,null],"PendingTests":[null,null,null,null],"RAD_Cancer":"Yes"}}';
        //#endregion

        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        Boolean ret = docuSignHelper.invokeMethod('createMedicalQuestions', inputMap, outMap, options);

        System.assertEquals(true, ret);
    }

    @isTest
    public static void medicalQuestionsConstructorForDocuSignTest(){
        //#region inputMapString
        String inputMapString = '{"DocuSignData":{"Primary":{"ZipCode":"67337","State":"KS","Weight":"111","Name":"Amai Pregent","SocialSecurity":"123123123","LastName":"Pregent","Phone":"+12323423422","isSmoker":false,"Gender":"Female","Id":"a3q3C000001I7dOQAS","Email":"favexit789@kixotic.com","FirstName":"Amai","Height":"11' + '11","DOB":"1990-11-12","City":"Coffeyville","Address":"123 Meadow Lane"},"Spouse":{"Weight":"222","SocialSecurity":"234234234","Name":"Emmai Gregnant","isSmoker":false,"LastName":"Gregnant","Id":"a3q3C000001I7diQAC","Gender":"Female","FirstName":"Emmai","DOB":"1990-11-06","Height":"22'+ '11"},"Dependents":[{"Pregnant":true,"SocialSecurity":"234234234","Weight":"111","LastName":"Pregonate","Id":"a3q3C000001I7djQAC","isSmoker":true,"Height":"11'+ '11","Gender":"Female","FirstName":"Canaibe","Age":21,"DOB":"2000-11-14","Name":"Canaibe Pregonate"},{"Pregnant":true,"SocialSecurity":"111111111","Weight":"111","LastName":"Pranget","Id":"a3q3C000001I7dkQAC","isSmoker":false,"Height":"11'+ '11","Gender":"Female","FirstName":"Isabelity","Age":11,"DOB":"2010-11-18","Name":"Isabelity Pranget"}],"Plan":{"ApplicationFee":"$99.00","Name":"UHSM Vital $10K","EffectiveDate":"2022-11-15","MonthlyContribution":"$560.30"}},"MedicalQuestions":{"Cancers":[{"CHK_CheckCancer":true,"TXT_MemberNameCancer":"Emmai Gregnant","TXT_MemberIdCancer":"a3q3C000001I7diQAC","TXT_TypeOfCancer":"CANCERONE","DATE_Cancer":"2022-11-01"}],"PastConditions":[{"TXT_MemberPastConditions":"Amai Pregent","TXT_MemberIdPastConditions":"a3q3C000001I7dOQAS","MULSEL_Conditions":"Heart Disease;Behavioral/Mental Health;Chron'+ 's Disease"},{"TXT_MemberPastConditions":"Emmai Gregnant","TXT_MemberIdPastConditions":"a3q3C000001I7diQAC"},{"TXT_MemberPastConditions":"Canaibe Pregonate","TXT_MemberIdPastConditions":"a3q3C000001I7djQAC"},{"TXT_MemberPastConditions":"Isabelity Pranget","TXT_MemberIdPastConditions":"a3q3C000001I7dkQAC"}],"Internations":[{"CHKBOX_Internations":false,"DATE_MemberInternations":null,"TXTAREA_MemberInternations":null,"TXT_MemberIdInternations":"a3q3C000001I7dOQAS","TXT_MemberInternations":"Amai Pregent"},{"CHKBOX_Internations":true,"DATE_MemberInternations":"2013-10-30","TXTAREA_MemberInternations":"sdfsdfdv","TXT_MemberIdInternations":"a3q3C000001I7diQAC","TXT_MemberInternations":"Emmai Gregnant"},{"CHKBOX_Internations":false,"DATE_MemberInternations":null,"TXTAREA_MemberInternations":null,"TXT_MemberIdInternations":"a3q3C000001I7djQAC","TXT_MemberInternations":"Canaibe Pregonate"},{"CHKBOX_Internations":false,"DATE_MemberInternations":null,"TXTAREA_MemberInternations":null,"TXT_MemberIdInternations":"a3q3C000001I7dkQAC","TXT_MemberInternations":"Isabelity Pranget"}],"UnexpectedSymptoms":[{"CHKBOX_UnexpectedSymptoms":true,"DATE_MemberUnexpectedSymptoms":"2022-10-31","TXTAREA_MemberUnexpectedSymptoms":"wer","TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7dOQAS","TXT_MemberUnexpectedSymptoms":"Amai Pregent"},{"CHKBOX_UnexpectedSymptoms":false,"DATE_MemberUnexpectedSymptoms":null,"TXTAREA_MemberUnexpectedSymptoms":null,"TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7diQAC","TXT_MemberUnexpectedSymptoms":"Emmai Gregnant"},{"CHKBOX_UnexpectedSymptoms":false,"DATE_MemberUnexpectedSymptoms":null,"TXTAREA_MemberUnexpectedSymptoms":null,"TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7djQAC","TXT_MemberUnexpectedSymptoms":"Canaibe Pregonate"},{"CHKBOX_UnexpectedSymptoms":false,"DATE_MemberUnexpectedSymptoms":null,"TXTAREA_MemberUnexpectedSymptoms":null,"TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7dkQAC","TXT_MemberUnexpectedSymptoms":"Isabelity Pranget"}],"LWC_SelectCensusMember":{"SelectedCensusMemberId":"a3q3C000001I7diQAC"},"Prescriptions":[{"ReasonForMedication":"asdfsdzds","DateDiscontinued":"23/423423","PrescribingPhysician":"zsdvzsdv","NameOfMedication":"sdfasdfasdfsadf","MemberName":"Emmai Gregnant","DatePrescribed":"2342/342","MemberIdPrescription":"a3q3C000001I7diQAC"}],"Physicians":[{"CensusMemberId":"a3q3C000001I7djQAC","PhysicianCity":"v","YearDiagnosed":"3423","Controlled":"Yes","PhysicianPhone":"3423423232","PhysicianName":"sdvv","Diagnosis":"fasdfasdfdcsadczcfsdvz","CensusMemberName":"Canaibe Pregonate"}],"RAD_UnexplainedSymptoms":"Yes","RAD_PastConditions":"Yes","RAD_Internations":"Yes","RAD_Consults":"No","RAD_PendingTests":"No","RAD_PrescriptionMedications":"Yes","RAD_Addictions":"No","Consults":[null,null,null,null],"Addictions":[null,null,null,null],"PendingTests":[null,null,null,null],"RAD_Cancer":"Yes"}}';
        //#endregion

        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        Boolean ret = docuSignHelper.invokeMethod('medicalQuestionsConstructorForDocuSign', inputMap, outMap, options);

        System.assertEquals(true, ret);
    }
    @isTest
    public static void createRecipientForAddMemberTest(){
        //#region inputMapString
        String inputMapString = '{"userInputs":[{"RF_Census.CRF_CoverageAIDD":"Family","RF_Census.CRF_Coverage":"Family","RF_Census.CM_Age":32,"RF_Census.CM_Smoker":false,"RF_Census.CM_IsSpouse":false,"contact":"0033C00000bA89LQAS","RF_Census.CM_IsPrimary":true,"RF_Census.CM_State":"KS","RF_Census.CRF_PrimaryMemberAge":32,"RF_Census.CRF_ExtraDependants":0,"RF_Census.CRF_Dependants":4,"Birthdate":"1990-11-08","EffectiveDate":null,"Zipcode":null,"State":null,"City":null,"Street":null,"Phone":"+11231231321","Email":"wexat49677@probdd.com","ContractStartDate":"2023-01-15","ContractRecType":"0123C000000SHr9QAG","AccountId":"0013C00000mnpfJQAQ","ContractId":"8003C000000iUfDQAU","CensusEmail":"wexat49677@probdd.com","CensusMemberIdentifier":"2022-11-21T18:56:25.218Z","CensusMemberRelationship":null,"CensusMemberFirstName":"Xavier","CensusMemberLastName":"X","isMinor":false,"CensusMemberName":"Xavier X","CensusMemberId":"a3q3C000001I9qOQAS"},{"RF_Census.CRF_CoverageAIDD":"Family","RF_Census.CRF_Coverage":"Family","RF_Census.CM_Age":9,"RF_Census.CM_Smoker":false,"RF_Census.CM_IsSpouse":false,"contact":null,"RF_Census.CM_IsPrimary":false,"RF_Census.CM_State":"KS","RF_Census.CRF_PrimaryMemberAge":32,"RF_Census.CRF_ExtraDependants":0,"RF_Census.CRF_Dependants":4,"Birthdate":"2013-11-06","EffectiveDate":null,"Zipcode":null,"State":null,"City":null,"Street":null,"Phone":"+11231231321","Email":null,"ContractStartDate":"2023-01-15","ContractRecType":"0123C000000SHr9QAG","AccountId":"0013C00000mnpfJQAQ","ContractId":"8003C000000iUfDQAU","CensusEmail":"wexat49677@probdd.com","CensusMemberIdentifier":"1669059646006-0.46730597063913737","CensusMemberRelationship":"Child","CensusMemberFirstName":"Raven","CensusMemberLastName":"X","isMinor":true,"CensusMemberName":"Raven X","CensusMemberId":"a3q3C000001I9rHQAS"}],"signerEmail":"biliv69236@kixotic.com","Guardian":"","memberIds":["2022-11-19T05:46:54.834Z","1669028245869-0.9112627282903651"],"isAddMember":true}';        // #endregion

        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        Boolean ret = docuSignHelper.invokeMethod('createRecipientForAddMember', inputMap, outMap, options);

        System.assertEquals(true, ret);
    }



    @isTest
    public static void createRecipients2Test(){
        //#region inputMapString
        String inputMapString = '{"DocuSignData":{"Primary":{"ZipCode":"67337","State":"KS","Weight":"111","Name":"Amai Pregent","SocialSecurity":"123123123","LastName":"Pregent","Phone":"+12323423422","isSmoker":false,"Gender":"Female","Id":"a3q3C000001I7dOQAS","Email":"favexit789@kixotic.com","FirstName":"Amai","Height":"11'+'11","DOB":"1990-11-12","City":"Coffeyville","Address":"123 Meadow Lane"},"Spouse":{"Weight":"222","SocialSecurity":"234234234","Name":"Emmai Gregnant","isSmoker":false,"LastName":"Gregnant","Id":"a3q3C000001I7diQAC","Gender":"Female","FirstName":"Emmai","DOB":"1990-11-06","Height":"22'+'11"},"Dependents":[{"Pregnant":true,"SocialSecurity":"234234234","Weight":"111","LastName":"Pregonate","Id":"a3q3C000001I7djQAC","isSmoker":true,"Height":"11'+'11","Gender":"Female","FirstName":"Canaibe","Age":21,"DOB":"2000-11-14","Name":"Canaibe Pregonate"},{"Pregnant":true,"SocialSecurity":"111111111","Weight":"111","LastName":"Pranget","Id":"a3q3C000001I7dkQAC","isSmoker":false,"Height":"11'+'11","Gender":"Female","FirstName":"Isabelity","Age":11,"DOB":"2010-11-18","Name":"Isabelity Pranget"}],"Plan":{"ApplicationFee":"$99.00","Name":"UHSM Vital $10K","EffectiveDate":"2022-11-15","MonthlyContribution":"$560.30"}},"MedicalQuestions":{"Cancers":[{"CHK_CheckCancer":true,"TXT_MemberNameCancer":"Emmai Gregnant","TXT_MemberIdCancer":"a3q3C000001I7diQAC","TXT_TypeOfCancer":"CANCERONE","DATE_Cancer":"2022-11-01"}],"PastConditions":[{"TXT_MemberPastConditions":"Amai Pregent","TXT_MemberIdPastConditions":"a3q3C000001I7dOQAS","MULSEL_Conditions":"Heart Disease;Behavioral/Mental Health;Chron  '+' s Disease"},{"TXT_MemberPastConditions":"Emmai Gregnant","TXT_MemberIdPastConditions":"a3q3C000001I7diQAC"},{"TXT_MemberPastConditions":"Canaibe Pregonate","TXT_MemberIdPastConditions":"a3q3C000001I7djQAC"},{"TXT_MemberPastConditions":"Isabelity Pranget","TXT_MemberIdPastConditions":"a3q3C000001I7dkQAC"}],"Internations":[{"CHKBOX_Internations":false,"DATE_MemberInternations":null,"TXTAREA_MemberInternations":null,"TXT_MemberIdInternations":'+
        '"a3q3C000001I7dOQAS","TXT_MemberInternations":"Amai Pregent"},{"CHKBOX_Internations":true,"DATE_MemberInternations":"2013-10-30","TXTAREA_MemberInternations":"sdfsdfsdv","TXT_MemberIdInternations":"a3q3C000001I7diQAC","TXT_MemberInternations":'+
        '"Emmai Gregnant"},{"CHKBOX_Internations":false,"DATE_MemberInternations":null,"TXTAREA_MemberInternations":null,"TXT_MemberIdInternations":"a3q3C000001I7djQAC","TXT_MemberInternations":"Canaibe Pregonate"},{"CHKBOX_Internations":false,"DATE_MemberInternations":null,"TXTAREA_MemberInternations":null,"TXT_MemberIdInternations":"a3q3C000001I7dkQAC","TXT_MemberInternations":"Isabelity Pranget"}],"UnexpectedSymptoms":[{"CHKBOX_UnexpectedSymptoms":true,"DATE_MemberUnexpectedSymptoms":"2022-10-31","TXTAREA_MemberUnexpectedSymptoms":"wer","TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7dOQAS","TXT_MemberUnexpectedSymptoms":"Amai Pregent"},{"CHKBOX_UnexpectedSymptoms":false,"DATE_MemberUnexpectedSymptoms":null,"TXTAREA_MemberUnexpectedSymptoms":null,"TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7diQAC","TXT_MemberUnexpectedSymptoms":"Emmai Gregnant"},{"CHKBOX_UnexpectedSymptoms":false,"DATE_MemberUnexpectedSymptoms":null,"TXTAREA_MemberUnexpectedSymptoms":null,"TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7djQAC","TXT_MemberUnexpectedSymptoms":"Canaibe Pregonate"},{"CHKBOX_UnexpectedSymptoms":false,"DATE_MemberUnexpectedSymptoms":null,"TXTAREA_MemberUnexpectedSymptoms":null,"TXT_MemberIdUnexpectedSymptoms":"a3q3C000001I7dkQAC","TXT_MemberUnexpectedSymptoms":"Isabelity Pranget"}],"LWC_SelectCensusMember":{"SelectedCensusMemberId":"a3q3C000001I7diQAC"},"Prescriptions":[{"ReasonForMedication":"asdfsvzds","DateDiscontinued":"23/423423","PrescribingPhysician":"zsdvzsdv","NameOfMedication":"sdfasdfasdfsadf","MemberName":"Emmai Gregnant","DatePrescribed":"2342/342","MemberIdPrescription":"a3q3C000001I7diQAC"}],"Physicians":[{"CensusMemberId":"a3q3C000001I7djQAC","PhysicianCity":"sdv","YearDiagnosed":"3423","Controlled":"Yes","PhysicianPhone":"3423423232","PhysicianName":"sdvsv","Diagnosis":"fasdfasdfdcsadczcfsdvz","CensusMemberName":"Canaibe Pregonate"}],"RAD_UnexplainedSymptoms":"Yes","RAD_PastConditions":"Yes","RAD_Internations":"Yes","RAD_Consults":"No","RAD_PendingTests":"No","RAD_PrescriptionMedications":"Yes","RAD_Addictions":"No","Consults":[null,null,null,null],"Addictions":[null,null,null,null],"PendingTests":[null,null,null,null],"RAD_Cancer":"Yes"}}';
        //#endregion

        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        Boolean ret = docuSignHelper.invokeMethod('createRecipients2', inputMap, outMap, options);

        System.assertEquals(true, ret);
    }

    
    @isTest
    public static void removeMemberTest(){
        //#region inputMapString
        String inputMapString = '{"DocuSignData":{"Primary":{"ZipCode":"66213","State":"KS","Weight":234,"Name":"AndresDeus","SocialSecurity":"654646546","LastName":"Deus","Phone":"(123)-123-12315","isSmoker":false,"Gender":"Male","Id":"a3q3C000000fwsmQAA","Email":"andres.deus@arcsona.com","FirstName":"Andres","MI":"D","Height":"2' + '22","DOB":"1990-03-08","City":"OverlandPark","Address":"12330MetcalfAvenue"},"Spouse":{"Weight":234,"SocialSecurity":"646546546","Name":"PepitaLombarda","MI":"D","isSmoker":true,"LastName":"Lombarda","Id":"a3q3C000000fwsrQAA","Gender":"Female","FirstName":"Pepita","DOB":"1993-03-11","Height":"2' + '23"},"Dependents":[{"SocialSecurity":"654654654","Weight":234,"MI":"A","LastName":"Deus","Id":"a3q3C000000fwssQAA","isSmoker":false,"Height":"2' + '23","Gender":"Male","FirstName":"Pedro","Age":26,"DOB":"1996-03-14","Name":"PedroDeus"},{"SocialSecurity":"321313213","Weight":234,"MI":"S","LastName":"Deus","Id":"a3q3C000000fwstQAA","isSmoker":false,"Height":"2' + '23","Gender":"Male","FirstName":"Lucas","Age":27,"DOB":"1995-03-15","Name":"LucasDeus"},{"SocialSecurity":"313213213","Weight":234,"MI":"A","LastName":"Deus","Id":"a3q3C000000fwsuQAA","isSmoker":false,"Height":"2' + '23","Gender":"Female","FirstName":"Pequeña","Age":2,"DOB":"2020-03-12","Name":"PequeñaDeus"},{"SocialSecurity":"231321321","Weight":234,"LastName":"Deus","Id":"a3q3C000000fwsvQAA","isSmoker":false,"Height":"2' + '65","Gender":"Female","FirstName":"OtraPequeña","Age":0,"DOB":"2022-03-08","Name":"OtraPequeñaDeus"}]},"RemoveMembers":[{"SocialSecurity":"654654654","Weight":234,"MI":"A","TXT_LastNameEB":"Deus","TXT_CensusMemberId":"a3q3C000000fwssQAA","isSmoker":false,"Height":"2' + '23","Gender":"Male","TXT_FirstNameEB":"Pedro","Age":26,"DOB":"1996-03-14","Name":"PedroDeus"},{"SocialSecurity":"321313213","Weight":234,"MI":"S","TXT_LastNameEB":"Deus","TXT_CensusMemberId":"a3q3C000000fwstQAA","isSmoker":false,"Height":"2' + '23","Gender":"Male","TXT_FirstNameEB":"Lucas","Age":27,"DOB":"1995-03-15","Name":"LucasDeus"},{"SocialSecurity":"313213213","Weight":234,"MI":"A","TXT_LastNameEB":"Deus","TXT_CensusMemberId":"a3q3C000000fwsuQAA","isSmoker":false,"Height":"2' + '23","Gender":"Female","TXT_FirstNameEB":"Pequeña","Age":2,"DOB":"2020-03-12","Name":"PequeñaDeus"},{"SocialSecurity":"231321321","Weight":234,"TXT_LastNameEB":"Deus","TXT_CensusMemberId":"a3q3C000000fwsvQAA","isSmoker":false,"Height":"2' + '65","Gender":"Female","TXT_FirstNameEB":"OtraPequeña","Age":0,"DOB":"2022-03-08","Name":"OtraPequeñaDeus"}]}';
        //#endregion

        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        Boolean ret = docuSignHelper.invokeMethod('removeMembers', inputMap, outMap, options);

        System.assertEquals(true, ret);
    }

    @isTest
    public static void listMembersPerPlanTest(){
        //#region inputMapString
        String inputMapString = '{"ContracLineItemList":[{"GCMP":[{"MemberName":"George Jungle","MemberId":"a3q3C000001IL1NQAW"},{"MemberName":"Jane Jungle","MemberId":"a3q3C000001IL1SQAW"},{"MemberName":"Jimmy Jungle","MemberId":"a3q3C000001IL1TQAW"},{"MemberName":"Lexi Jungle","MemberId":"a3q3C000001IL1XQAW"},{"MemberName":"Billie Jungle","MemberId":"a3q3C000001IL1YQAW"}],"Program":"WeShare 6k","Id":"a2W3C000000d1EoUAI"},{"GCMP":[{"MemberName":"Jane Jungle","MemberId":"a3q3C000001IL1SQAW"},{"MemberName":"Billie Jungle","MemberId":"a3q3C000001IL1YQAW"}],"Program":"AIDD 7500","Id":"a2W3C000000d1EpUAI"},{"GCMP":[{"MemberName":"Jane Jungle","MemberId":"a3q3C000001IL1SQAW"},{"MemberName":"Billie Jungle","MemberId":"a3q3C000001IL1YQAW"}],"Program":"SMART Share 10000","Id":"a2W3C000000d1EqUAI"},{"GCMP":[{"MemberName":"George Jungle","MemberId":"a3q3C000001IL1NQAW"},{"MemberName":"Jimmy Jungle","MemberId":"a3q3C000001IL1TQAW"},{"MemberName":"Lexi Jungle","MemberId":"a3q3C000001IL1XQAW"}],"Program":"AIDD 10000","Id":"a2W3C000000d1ErUAI"},{"GCMP":[{"MemberName":"George Jungle","MemberId":"a3q3C000001IL1NQAW"},{"MemberName":"Jimmy Jungle","MemberId":"a3q3C000001IL1TQAW"},{"MemberName":"Lexi Jungle","MemberId":"a3q3C000001IL1XQAW"}],"Program":"SMART Share 45000","Id":"a2W3C000000d1EsUAI"}]}';
        //#endregion

        Map<String, Object> inputMap = (Map<String, Object>)JSON.deserializeUntyped(inputMapString);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();

        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        Boolean ret = docuSignHelper.invokeMethod('getMembersForPlans', inputMap, outMap, options);

        System.assertEquals(true, ret);
    }

    @isTest
    public static void getDependentsTest(){
        List<vlocity_ins__ContractLineItem__c> cliList = ARC_TestUtility.createTestContractLineItem(1);
        Id contractId =  cliList[0].vlocity_ins__ContractId__c;
        Id censusId = cliList[0].vlocity_ins__ContractId__r.vlocity_ins__EnrollmentCensusId__c;
        List<vlocity_ins__GroupCensusMember__c> censusMembers  = ARC_TestUtility.createTestCensusMember(2);
        censusMembers[0].vlocity_ins__Birthdate__c = System.today().addYears(-16);
        censusMembers[0].vlocity_ins__IsPrimaryMember__c = true;
        censusMembers[0].vlocity_ins__Email__c = 'atestemail@atestemail.com';

        censusMembers[1].vlocity_ins__Birthdate__c = System.today().addYears(-4);
        censusMembers[1].vlocity_ins__IsPrimaryMember__c = false;
        censusMembers[1].ARC_DependentRelationship__c = 'Child';
        censusMembers[1].vlocity_ins__Email__c = 'atestemail@atestemail.com';

        update censusMembers;
        vlocity_ins__GroupCensusMemberPlan__c mplan = new vlocity_ins__GroupCensusMemberPlan__c(
            Name = 'Test',
            vlocity_ins__ContractLineId__c = cliList[0].Id,
            vlocity_ins__GroupCensusMemberId__c = censusMembers[0].Id
        );
        insert mplan;
        System.debug([SELECT vlocity_ins__GroupCensusMemberId__c FROM vlocity_ins__GroupCensusMemberPlan__c WHERE vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c = :contractId]);
        System.debug(contractId);
        System.debug(censusMembers);
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('contractId', contractId);
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options =  new Map<String, Object>();

        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        docuSignHelper.invokeMethod('getDependents', inputMap, outMap, options);
        System.debug(outMap);
        List<vlocity_ins__GroupCensusMember__c> ret = (List<vlocity_ins__GroupCensusMember__c>)outMap.get('Dependents');

        System.assertEquals(1, ret.size());

    }
    
    @isTest
    public static void createRecipientsFromMembersTest(){
        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        List<vlocity_ins__GroupCensusMember__c> censusMembers = ARC_TestUtility.createTestCensusMember(4);
        
        censusMembers[0].vlocity_ins__Birthdate__c = System.today().addYears(-30);
        censusMembers[0].vlocity_ins__IsPrimaryMember__c = true;
        censusMembers[0].vlocity_ins__Email__c = 'atestemail@atestemail.com';
        
        censusMembers[1].vlocity_ins__Birthdate__c = System.today().addYears(-28);
        censusMembers[1].vlocity_ins__IsPrimaryMember__c = false;
        censusMembers[1].ARC_DependentRelationship__c = 'Spouse';
        censusMembers[1].vlocity_ins__Email__c = 'atestemail@atestemail.com';
        
        censusMembers[2].vlocity_ins__Birthdate__c = System.today().addYears(-19);
        censusMembers[2].vlocity_ins__IsPrimaryMember__c = false;
        censusMembers[2].ARC_DependentRelationship__c = 'Child';
        censusMembers[2].vlocity_ins__Email__c = 'atestemail@atestemail.com';
        
        censusMembers[3].vlocity_ins__Birthdate__c = System.today().addYears(-5);
        censusMembers[3].vlocity_ins__IsPrimaryMember__c = false;
        censusMembers[3].ARC_DependentRelationship__c = 'Child';

        update censusMembers;
        censusMembers = [SELECT id, Name, ARC_Age__c, vlocity_ins__Email__c, vlocity_ins__CensusId__c, vlocity_ins__IsPrimaryMember__c, ARC_DependentRelationship__c, ARC_Relationship__c FROM vlocity_ins__GroupCensusMember__c];
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('censusMemberList', censusMembers);
        inputMap.put('ContractReasons', 'Primary Change');
        Map<String, Object> outMap = new Map<String, Object>();
        Map<String, Object> options =  new Map<String, Object>();

        
     
        docuSignHelper.invokeMethod('createRecipientsFromMembers', inputMap, outMap, options);
        List<Map<String, Object>>  ret = (  List<Map<String, Object>> )outMap.get('recipients');

        System.assertEquals(4, ret.size());
    }

    @isTest
    public static void createRecipientsFromMembersTestGuardian(){
        //test for child families (guardian recipients)
        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        List<vlocity_ins__GroupCensusMember__c> censusMembers2 = ARC_TestUtility.createTestCensusMember(2);
        censusMembers2[0].vlocity_ins__Birthdate__c = System.today().addYears(-16);
        censusMembers2[0].vlocity_ins__IsPrimaryMember__c = true;
        censusMembers2[0].vlocity_ins__Email__c = 'atestemail@atestemail.com';

        censusMembers2[1].vlocity_ins__Birthdate__c = System.today().addYears(-4);
        censusMembers2[1].vlocity_ins__IsPrimaryMember__c = false;
        censusMembers2[1].ARC_DependentRelationship__c = 'Child';
        censusMembers2[1].vlocity_ins__Email__c = 'atestemail@atestemail.com';

        update censusMembers2;
        censusMembers2 = [SELECT id, Name, ARC_Age__c, vlocity_ins__Email__c, vlocity_ins__CensusId__c, vlocity_ins__IsPrimaryMember__c, ARC_DependentRelationship__c, ARC_Relationship__c FROM vlocity_ins__GroupCensusMember__c];
        Map<String, Object> inputMap2 = new Map<String, Object>();
        inputMap2.put('censusMemberList', censusMembers2);
        inputMap2.put('ContractReasons', 'Primary Change');
        Map<String, Object> outMap2 = new Map<String, Object>();
        Map<String, Object> options2 =  new Map<String, Object>();

        docuSignHelper.invokeMethod('createRecipientsFromMembers', inputMap2, outMap2, options2);
        List<Map<String, Object>> ret = (  List<Map<String, Object>> )outMap2.get('recipients');

        System.assertEquals(1, ret.size());

    }

    
    @isTest
    public static void getTemplateIdTest(){
        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        List<String> reasonsList = new List<String>();
        reasonsList.add('New Application');
        reasonsList.add('Add Member');
        reasonsList.add('Program Downgrade');
        
        // templates
        List<vlocity_ins__VlocityDocuSignTemplate__c> templateList = new List<vlocity_ins__VlocityDocuSignTemplate__c>(); 
        for(String reason : reasonsList){
            for(Integer i = 1; i<= 3 ; i++){
                vlocity_ins__VlocityDocuSignTemplate__c template = new vlocity_ins__VlocityDocuSignTemplate__c();
                template.name =  'Template ' + reason + i;
                template.vlocity_ins__templateidentifier__c = reason + i; 
                templateList.add(template);
            }
        }
        insert templateList;


        // template settings 
        // template settings' ARC_Template_Name__c will make the tested methos search for a template with the same name
        List<ARC_DocuSignTemplates__c> templateSettingsList = new List<ARC_DocuSignTemplates__c>(); 
        for(String reason : reasonsList){
            Integer minDeps = 1; 
            for(Integer i = 1; i<= 3; i++){
                ARC_DocuSignTemplates__c templateSettings = new ARC_DocuSignTemplates__c();
                templateSettings.Name = 'Template ' + reason + i;
                templateSettings.ARC_Template_Name__c = 'Template ' + reason + i;
                templateSettings.ARC_Contract_Reasons__c = reason;
                templateSettings.ARC_DRTransform__c = 'Transform for ' + reason;
                templateSettings.ARC_Min_Dependents__c = minDeps;
                templateSettings.ARC_Max_Dependents__c = i * 5;
                minDeps = (i * 5) + 1;
                templateSettingsList.add(templateSettings);
            }
        }
        insert templateSettingsList;
        
        // execute method
        List<Integer> dependentsNrs = new List<Integer>();
        //dependents divided by 5 gets 1, 2 and 3 correlating to the template asigned in the template's name for each amount of members
        // example 5 / 5 = 1 expects so for 5 dependents is expected " Template_reason 1 "
        dependentsNrs.add(5);
        dependentsNrs.add(10);
        dependentsNrs.add(15);
        
        for(String reason : reasonsList){
            for(Integer dependents : dependentsNrs){
                Map<String, Object> inputMap = new Map<String, Object>();
                Map<String, Object> outMap = new Map<String, Object>();
                Map<String, Object> options =  new Map<String, Object>();

                inputMap.put('reasons', reason);
                inputMap.put('dependents', dependents);
                
                docuSignHelper.invokeMethod('getTemplateId', inputMap, outMap, options);
                Map<String, Object> ret = (Map<String, Object>)outMap.get('templateData');



                Integer num = dependents/5 ;
                vlocity_ins__VlocityDocuSignTemplate__c returnedTemplate = (vlocity_ins__VlocityDocuSignTemplate__c)ret.get('Template');
    
                System.assertEquals('Template ' + reason + num, (String)returnedTemplate.get('name'));

            }


        }

    }
    
    @isTest
    public static void isPublcGroupMemberTest(){
        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();

        UserRole role = new UserRole(Name = 'RoleName');
        insert role;

        Group publicGroup = new Group();
        publicGroup.Name = 'Public Group Test';
        publicGroup.DeveloperName = 'Public_Group_Test';
        insert publicGroup;

        List<Group> roleGroup = [SELECT Id, Name, DeveloperName FROM Group WHERE Type = 'Role' AND relatedId = :role.Id];

        GroupMember gm = new GroupMember();
        gm.groupId = publicGroup.Id;
        gm.UserOrGroupId = roleGroup[0].Id;
        insert gm;
      
        List<User> users = ARC_TestUtility.createTestUsers(2, 'WS Sales');
        users[0].UserRoleId = role.Id;
        insert users;

        Map<String, Object> inputMap = new Map<String, Object>();
        Map<String, Object> inputMap2 = new Map<String, Object>();
        Map<String, Object> outMap =  new Map<String, Object>();
        Map<String, Object> outMap2 =  new Map<String, Object>();
        inputMap.put('GroupName', publicGroup.DeveloperName);
        inputMap.put('UserRoleId', users[0].UserRoleId);

        Test.startTest();
        docuSignHelper.invokeMethod('isPublicGroupMember', inputMap, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(true, outMap.get('belongsInGroup'));
    }

    @isTest
    public static void filterMembersByIdTest(){
        ARC_DocuSignHelper docuSignHelper = new ARC_DocuSignHelper();
        List<Contract> contracts =  ARC_TestUtility.createContracts(1); 
        List<vlocity_ins__GroupCensusMemberPlan__c> gcmpList =ARC_TestUtility.createTestCensusMemPlan(1);
        vlocity_ins__GroupCensusMemberPlan__c gcmp = gcmpList[0];
        
        Id gcmId = gcmp.vlocity_ins__GroupCensusMemberId__c;
        Map<String, Object> inputMap = new Map<String, Object>(); 
        Map<String, List<Object>> outMap = new Map<String, List<Object>>();
        
        Map<String,String> fmMap = new Map<String,String>();
        fmMap.put('Id', gcmId);
        List<Map<String,String>> filteredMembers = new List<Map<String,String>>();
        filteredMembers.add(fmMap); 
        inputMap.put('OldContractId', contracts[0].Id);
        inputMap.put('FilteredMembers', filteredMembers);

        Test.startTest();
        docuSignHelper.invokeMethod('filterMembersById', inputMap, outMap, new Map<String, Object>());
        Test.stopTest();

        System.assertEquals(0, outMap.get('filteredNewMembers').size());

    }



}