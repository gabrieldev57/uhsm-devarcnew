import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';


export default class ARC_showErrorInMedicationStep extends OmniscriptBaseMixin(LightningElement) {
    @api medicationBlock;
    hasErrorUnexpected = false;
    hasErrorInternations = false;
    hasErrorAddictions = false;
    hasErrorPCP = false;
    hasErrorHospital = false;
    hasErrorCancer = false;
    hasErrorMedication = false;
    lstInputJsonMedication = [];
    lstInputJsonUnexpected = [];
    lstInputJsonInternations = [];
    lstInputJsonAddictions = [];
    lstInputJsonPCP = [];
    lstInputJsonCancer = [];
    lstInputJsonHospital = [];
    
      

    async connectedCallback() {

        this.check = setInterval(() => {
           if (this.omniJsonData.STEP_MedicalQuestions.ED_MemberPrescription) {
                if (JSON.stringify(this.lstInputJsonMedication) != JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.ED_MemberPrescription) ) {
                    if (Array.isArray(this.omniJsonData.STEP_MedicalQuestions.ED_MemberPrescription)) {
                        this.lstInputJsonMedication = JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.ED_MemberPrescription));
                    }else{
                        this.lstInputJsonMedication = [];
                        this.lstInputJsonMedication.push(JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.ED_MemberPrescription)));
                        this.lstInputJsonMedication.flat(Infinity);
                    }
                    this.lstInputJsonMedication.forEach(Nodes => {   
                        if(Nodes.TXT_DatePrescribed != null){
                            if(Nodes.FRML_MemberBirthdate > Nodes.TXT_DatePrescribed){
                                Nodes.TXT_hasErrorMedication = "true";


                        }else{
                            Nodes.TXT_hasErrorMedication = "false";
                        }}
                    });
                    if (this.lstInputJsonMedication.filter(element => element.TXT_hasErrorMedication == "true").length != 0) {
                        this.hasErrorMedication = true;
                        this.omniUpdateDataJson({ "hasErrorMedication": this.hasErrorMedication });
                    }else{
                        this.hasErrorMedication = false; 
                        this.omniUpdateDataJson({ "hasErrorMedication": this.hasErrorMedication });
                    }
                 }
            }
            if (this.omniJsonData.STEP_MedicalQuestions.BLK_UnexpectedSymptoms) {
                if (JSON.stringify(this.lstInputJsonUnexpected) != JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_UnexpectedSymptoms) ) {
                    if (Array.isArray(this.omniJsonData.STEP_MedicalQuestions.BLK_UnexpectedSymptoms)) {
                        this.lstInputJsonUnexpected = JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_UnexpectedSymptoms));
                    }else{
                        this.lstInputJsonUnexpected = [];
                        this.lstInputJsonUnexpected.push(JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_UnexpectedSymptoms)));
                        this.lstInputJsonUnexpected.flat(Infinity);
                    }

                    //New Logic for avoiding null values              
                    this.lstInputJsonUnexpected.forEach(Nodes => {
                        if(Nodes && typeof Nodes === 'object' && Nodes.DATE_MemberUnexpectedSymptoms != null && Nodes.TXT_MemberUnexpectedBirthdate != null){
                            Nodes.TXT_hasError = (Nodes.TXT_MemberUnexpectedBirthdate > Nodes.DATE_MemberUnexpectedSymptoms).toString();
                            }
                        });
                                    
                    const hasErrors = this.lstInputJsonUnexpected.filter(
                        element => element && element.TXT_hasError === "true"
                    );
                    
                    this.hasErrorUnexpected = hasErrors.length > 0;
                    this.omniUpdateDataJson({ "hasErrorUnexpected": this.hasErrorUnexpected });
                    
                 }
            }
            if (this.omniJsonData.STEP_MedicalQuestions.BLK_Internations) {
                if (JSON.stringify(this.lstInputJsonInternations) != JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_Internations) ) {
                    if (Array.isArray(this.omniJsonData.STEP_MedicalQuestions.BLK_Internations)) {
                        this.lstInputJsonInternations = JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_Internations));
                    }else{
                        this.lstInputJsonInternations = [];
                        this.lstInputJsonInternations.push(JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_Internations)));
                        this.lstInputJsonInternations.flat(Infinity);
                    }
                    this.lstInputJsonInternations.forEach(Nodes => {
                        if(Nodes.DATE_MemberInternations != null){
                            if(Nodes.TXT_MemberIdInternationsBirthdate > Nodes.DATE_MemberInternations){
                                Nodes.TXT_hasErrorBedridden = "true";
                        }else{
                            Nodes.TXT_hasErrorBedridden = "false";
                        }}                        
                    });
                    
                   if (this.lstInputJsonInternations.filter(element => element.TXT_hasErrorBedridden == "true").length != 0) {
                       this.hasErrorInternations = true;
                        this.omniUpdateDataJson({ "hasErrorInternations": this.hasErrorInternations });
                    }else{
                        this.hasErrorInternations = false;
                       this.omniUpdateDataJson({ "hasErrorInternations": this.hasErrorInternations }); 
                    }
                 }
            }
            if (this.omniJsonData.STEP_MedicalQuestions.BLK_Addictions) {
                if (JSON.stringify(this.lstInputJsonAddictions) != JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_Addictions) ) {
                    if (Array.isArray(this.omniJsonData.STEP_MedicalQuestions.BLK_Addictions)) {
                        this.lstInputJsonAddictions = JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_Addictions));
                    }else{
                        this.lstInputJsonAddictions = [];
                        this.lstInputJsonAddictions.push(JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_Addictions)));
                        this.lstInputJsonAddictions.flat(Infinity);
                    }

                    //New Logic for avoiding null values    
                    this.lstInputJsonAddictions.forEach(Nodes => {
                        if(Nodes && typeof Nodes == 'object' && Nodes.DATE_MemberAddictions != null && Nodes.TXT_MemberIdAddictionsBirthdate != null){
                            Nodes.TXT_hasErrorAdiction = (Nodes.TXT_MemberIdAddictionsBirthdate > Nodes.DATE_MemberAddictions).toString();
                        }                        
                    });
                    
                  const hasErrors = this.lstInputJsonAddictions.filter(
                    element => element && element.TXT_hasErrorAdiction == "true"
                  );

                  this.hasErrorAddictions = hasErrors.length > 0;
                  this.omniUpdateDataJson({ "hasErrorAddictions": this.hasErrorAddictions });

                 }
            }
            
            if (this.omniJsonData.STEP_MedicalQuestions.EB_Physicians) {
                if (JSON.stringify(this.lstInputJsonPCP) != JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.EB_Physicians) ) {
                    if (Array.isArray(this.omniJsonData.STEP_MedicalQuestions.EB_Physicians)) {
                        this.lstInputJsonPCP = JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.EB_Physicians));
                    }else{
                        this.lstInputJsonPCP = [];
                        this.lstInputJsonPCP.push(JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.EB_Physicians)));
                        this.lstInputJsonPCP.flat(Infinity);
                    }
                    this.lstInputJsonPCP.forEach(Nodes => {
                        if(Nodes.TXT_YearDiagnosed != null){
                            if(Nodes.TXT_MemberPCPBirthdate > Nodes.TXT_YearDiagnosed){
                                Nodes.TXT_hasErrorPCP = "true";
                        }else{
                            Nodes.TXT_hasErrorPCP = "false";
                        }}                        
                    });
                    
                    if (this.lstInputJsonPCP.filter(element => element.TXT_hasErrorPCP == "true").length != 0) {
                      this.hasErrorPCP = true;
                       this.omniUpdateDataJson({ "hasErrorPCP": this.hasErrorPCP });
                   }else{
                       this.hasErrorPCP = false;
                        this.omniUpdateDataJson({ "hasErrorPCP": this.hasErrorPCP }); 
                    }
                 }
            }
            if (this.omniJsonData.STEP_MedicalQuestions.BLK_Consults) {
                if (JSON.stringify(this.lstInputJsonHospital) != JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_Consults) ) {
                    if (Array.isArray(this.omniJsonData.STEP_MedicalQuestions.BLK_Consults)) {
                        this.lstInputJsonHospital = JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_Consults));
                    }else{
                        this.lstInputJsonHospital = [];
                        this.lstInputJsonHospital.push(JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.BLK_Consults)));
                        this.lstInputJsonHospital.flat(Infinity);
                    }
                    this.lstInputJsonHospital.forEach(Nodes => {
                        if(Nodes.DATE_MemberConsults != null){
                            if(Nodes.TXT_MemberIdConsultsBirthdate > Nodes.DATE_MemberConsults){
                                Nodes.TXT_hasErrorHospitalized = "true";
                        }else{
                            Nodes.TXT_hasErrorHospitalized = "false";
                        }}                        
                    });
                    
                    if (this.lstInputJsonHospital.filter(element => element.TXT_hasErrorHospitalized == "true").length != 0) {
                        this.hasErrorHospital = true;
                        this.omniUpdateDataJson({ "hasErrorHospital": this.hasErrorHospital });
                    }else{
                        this.hasErrorHospital = false;
                        this.omniUpdateDataJson({ "hasErrorHospital": this.hasErrorHospital }); 
                  }
                 }
            }
            if (this.omniJsonData.STEP_MedicalQuestions.EB_Cancer) {
                if (JSON.stringify(this.lstInputJsonCancer) != JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.EB_Cancer) ) {
                    if (Array.isArray(this.omniJsonData.STEP_MedicalQuestions.EB_Cancer)) {
                        this.lstInputJsonCancer = JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.EB_Cancer));
                    }else{
                        this.lstInputJsonCancer = [];
                        this.lstInputJsonCancer.push(JSON.parse(JSON.stringify(this.omniJsonData.STEP_MedicalQuestions.EB_Cancer)));
                        this.lstInputJsonCancer.flat(Infinity);
                    }
                    this.lstInputJsonCancer.forEach(Nodes => {
                        if(Nodes.DATE_Cancer != null){
                            if(Nodes.FRML_MemberIdCancerBirthdate > Nodes.DATE_Cancer){
                                Nodes.TXT_hasErrorCancer = "true";
                        }else{
                            Nodes.TXT_hasErrorCancer = "false"; 
                        }}                        
                    });
                    
                    if (this.lstInputJsonCancer.filter(element => element.TXT_hasErrorCancer == "true").length != 0) {
                        this.hasErrorCancer = true;
                        this.omniUpdateDataJson({ "hasErrorCancer": this.hasErrorCancer });
                    }else{
                        this.hasErrorCancer = false;
                        this.omniUpdateDataJson({ "hasErrorCancer": this.hasErrorCancer }); 
                    }
                 }
            }
            if(this.omniJsonData.STEP_MedicalQuestions.RAD_UnexplainedSymptoms == "No"){
                 this.hasErrorUnexpected = false;
                  this.omniUpdateDataJson({ "hasErrorUnexpected": this.hasErrorUnexpected }); 
              }
            if(this.omniJsonData.STEP_MedicalQuestions.RAD_Internations == "No"){
                this.hasErrorInternations = false;
                 this.omniUpdateDataJson({ "hasErrorInternations": this.hasErrorInternations }); 
             }
            if(this.omniJsonData.STEP_MedicalQuestions.RAD_Addictions == "No"){
                this.hasErrorAddictions = false;
                 this.omniUpdateDataJson({ "hasErrorAddictions": this.hasErrorAddictions }); 
             }
             if(this.omniJsonData.STEP_MedicalQuestions.RAD_Consults == "No"){
                this.hasErrorHospital = false;
                 this.omniUpdateDataJson({ "hasErrorHospital": this.hasErrorHospital }); 
             }
             if(this.omniJsonData.STEP_MedicalQuestions.RAD_Cancer == "No"){
                this.hasErrorCancer = false;
                 this.omniUpdateDataJson({ "hasErrorCancer": this.hasErrorCancer }); 
             }
             if(this.omniJsonData.STEP_MedicalQuestions.RAD_PrescriptionMedications == "No"){
                this.hasErrorMedication = false;
                 this.omniUpdateDataJson({ "hasErrorMedication": this.hasErrorMedication }); 
             }
 
        }, 600);
       }

       disconnectedCallback(){
            clearInterval(this.check);
       }
  

}