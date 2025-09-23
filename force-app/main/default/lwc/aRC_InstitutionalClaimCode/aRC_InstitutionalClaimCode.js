import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getClaimCodes from '@salesforce/apex/ARC_InstitutionalClaimCodesController.getInstitutionalCodes';
import getRecordType from '@salesforce/apex/ARC_InstitutionalClaimCodesController.getRecordTypeInstClaimCodes'; 
import deleteClaimCode from '@salesforce/apex/ARC_InstitutionalClaimCodesController.deleteClaimCode';

import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import ADMIT_CODE from '@salesforce/schema/Claim.ARC_AdmitDX_Code__c';
import DRG_CODE from '@salesforce/schema/Claim.ARC_Submitted_DRG_Code__c';
import PRINCIPAL_CODE from '@salesforce/schema/Claim.ARC_Principal_Procedure__c';

const actions = [
    { label: 'Delete', name: 'delete' },
];


export default class ARC_InstitutionalClaimCode extends NavigationMixin(LightningElement) {

    @api recordId;
    data=[];
    isLoading = false;
    value;
    //Variables to Get Profile Name
    prfName;
    userId = strUserId;
    isClaimUser = true;
    //Claim Code RecordTypes
    recordTypeList = [];
    selectedRecordType;
    //Intialize Data
    allData;
    //Condition Code
    isConditionCode=false;
    conditionCodeData=[];
    //Occurrence Code
    isOccurrenceCode = false;
    occCodeData=[];
    //Occurrence Span code
    isOccSpanCode=false;
    occSpanCodeData=[];
    //E-Codes
    isECode=false;
    eCodeData=[];
    //ICD 10 DX and POA
    isICDCode=false;
    icdCodeData=[];
    //Other Procedure Codes
    isOtherCode=false;
    otherCodeData=[];
    //Patient DX
    isPatienDx=false;
    patientDxCodeData=[];
    //Value Codes and Amount
    isValueCode=false;
    valeCodeData=[];
    //Modals
    isShowModal=false;
    isShowForm=false;

    admitCode;
    drgCode;
    principalCode;
    actions = [];

    @wire(getRecord, { recordId: '$recordId', fields: [ADMIT_CODE, DRG_CODE, PRINCIPAL_CODE] })
    fetchLaborCategory({ data, error }) {
        if (data) {
            this.admitCode = getFieldValue(data, ADMIT_CODE);
            this.drgCode = getFieldValue(data, DRG_CODE);
            this.principalCode = getFieldValue(data, PRINCIPAL_CODE);
        }else{
            console.error(error);
        }
    }

    //Columns as a User != Claim User
    conditionCodeColumn =[
        { label: 'CONDITION CODE', fieldName:'ARC_ConditionCode__c', editable: false},
        {
            type: 'action',
            typeAttributes: { rowActions: actions },
        }
    ];

    occCodeColumn =[
        { label: 'OCCURRENCE CODE', fieldName:'ARC_Occurrence_Code__c', editable: true},
        { label: 'DATE', fieldName:'ARC_Date__c', type:'date-local', editable: true},
        {
            type: 'action',
            typeAttributes: { rowActions:  actions },
        }
    ];

    occSpanCodeColumn =[
        { label: 'OCCURRENCE SPAN CODE', fieldName:'ARC_Occurrence_Span_Code__c', editable: true},
        { label: 'FROM', fieldName:'ARC_Date_From__c', type:'date-local', editable: true},
        { label: 'THROUGH', fieldName:'ARC_Date_Through__c', type:'date-local', editable: true},
        {
            type: 'action',
            typeAttributes: { rowActions:  actions },
        }
    ];

    eCodeColumn =[
        { label: 'E-CODE', fieldName:'ARC_ECode__c', editable: true},
        {
            type: 'action',
            typeAttributes: { rowActions:  actions },
        }
    ];

    // icdDxCodeColumn =[
    //     { label: 'ICD DX', fieldName:'ARC_ICD_DX__c', editable: false},
    //     { label: 'POA', fieldName:'ARC_POA__c', editable: true},
    //     {
    //         type: 'action',
    //         typeAttributes: { rowActions:  actions },
    //     }
    // ];

    otherCodeColumn =[
        { label: 'OTHER PROCEDURE CODE', fieldName:'ARC_Other_Procedure_Code__c', editable: false},
        { label: 'DATE', fieldName:'ARC_Date__c', type:'date-local', editable: true},
        {
            type: 'action',
            typeAttributes: { rowActions:  actions },
        }
    ];

    patientDxCodeColumn =[
        { label: 'PATIENT DX', fieldName:'ARC_Patient_DX__c', editable: true},
        {
            type: 'action',
            typeAttributes: { rowActions:  actions },
        }
    ];

    valueCodeColumn =[
        { label: 'VALUE CODE', fieldName:'ARC_Vale_Codes__c', editable: true},
        { label: 'AMOUNT', fieldName:'ARC_Amount__c', type:'currency', editable: true},
        {
            type: 'action',
            typeAttributes: { rowActions:  actions },
        }
    ];

     //Columns as a Claim User****************
     conditionCodeColumnCU =[
        { label: 'CONDITION CODE', fieldName:'ARC_ConditionCode__c', editable: false}
    ];

    occCodeColumnCU =[
        { label: 'OCCURRENCE CODE', fieldName:'ARC_Occurrence_Code__c', editable: false},
        { label: 'DATE', fieldName:'ARC_Date__c', type:'date-local', editable: false},
    ];

    occSpanCodeColumnCU =[
        { label: 'OCCURRENCE SPAN CODE', fieldName:'ARC_Occurrence_Span_Code__c', editable: false},
        { label: 'FROM', fieldName:'ARC_Date_From__c', type:'date-local', editable: false},
        { label: 'THROUGH', fieldName:'ARC_Date_Through__c', type:'date-local', editable: false},
    ];

    eCodeColumnCU =[
        { label: 'E-CODE', fieldName:'ARC_ECode__c', editable: false},
    ];

    // icdDxCodeColumnCU =[
    //     { label: 'ICD DX', fieldName:'ARC_ICD_DX__c', editable: false},
    //     { label: 'POA', fieldName:'ARC_POA__c', editable: false},
    // ];

    otherCodeColumnCU =[
        { label: 'OTHER PROCEDURE CODE', fieldName:'ARC_Other_Procedure_Code__c', editable: false},
        { label: 'DATE', fieldName:'ARC_Date__c', type:'date-local', editable: false},
    ];

    patientDxCodeColumnCU =[
        { label: 'PATIENT DX', fieldName:'ARC_Patient_DX__c', editable: false},
    ];

    valueCodeColumnCU =[
        { label: 'VALUE CODE', fieldName:'ARC_Vale_Codes__c', editable: false},
        { label: 'AMOUNT', fieldName:'ARC_Amount__c', type:'currency', editable: false},
    ];


    //Get User Profile Name
    @wire(getRecord, {recordId: strUserId,fields: [PROFILE_NAME_FIELD]}) 
    wireuser({error,data}) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            this.prfName =data.fields.Profile.value.fields.Name.value;  
            if(this.prfName == 'System Administrator' || this.prfName == 'Claim Administrator')this.isClaimUser = false;
            console.log('this.prfName '+this.prfName);
        }
    }

    get options() {
        return [
            { label: 'Condition Code', value: 'ARC_Condition_Codes' },
            { label: 'Occurrence Codes and Dates', value: 'ARC_Occurrence_Codes_and_Dates' },
            { label: 'Occurrence Span Codes and Dates', value: 'ARC_Occurrence_Span_Codes_and_Dates' },
            { label: 'E-Codes', value: 'ARC_E_Codes' },
            { label: 'ICD 10 DX and POA', value: 'ARC_ICD_10_DX_and_POA' },
            { label: 'Other Procedure Codes', value: 'ARC_Other_Procedure_Codes' },
            { label: 'Patient DX', value: 'ARC_Patient_DX' },
            { label: 'Value Codes and Amount', value: 'ARC_Value_Codes_and_Amount' },
            
        ];
    }

    successInstClaimCov(){
        this.getApexData();
        this.displayMessage('Claim Code created successfully!', 'success');
        this.isShowModal=false;
    }

    errorInstClaimCov(e){
        this.displayMessage('Error, try again later', 'error');
        console.log(e);
    }

    displayMessage(title, variant){
        const evt = new ShowToastEvent({
            title: title,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    //Modal Selection of Code to crete.
    handleChange(event) {
        this.clearForms();
        this.value = event.detail.value;
        //console.log('this.value: '+this.value);
        let rt = this.recordTypeList.filter(rt => rt.DeveloperName == this.value);
        this.selectedRecordType= rt[0].Id;
        switch (this.value) {
            case 'ARC_Condition_Codes':
              this.conditionCodeForm=true;
              this.isShowForm =true;
              break;

            case 'ARC_Occurrence_Codes_and_Dates':
                this.occCodeForm=true;
                this.isShowForm =true;
                break;

            case 'ARC_Occurrence_Span_Codes_and_Dates':
                this.occSpanCodeForm=true;
                this.isShowForm =true;
                break;

            case 'ARC_E_Codes':
                this.eCodeForm=true;
                this.isShowForm =true;
                break;

            case 'ARC_ICD_10_DX_and_POA':
                this.icdCodeForm=true;
                this.isShowForm =true;
                break;

            case 'ARC_Other_Procedure_Codes':
                this.otherCodeForm=true;
                this.isShowForm =true;
                break;

            case 'ARC_Patient_DX':
                this.patientCodeForm=true;
                this.isShowForm =true;
                break;  

            case 'ARC_Value_Codes_and_Amount':
                this.valueCodeForm=true;
                this.isShowForm =true;
                break;
        }        
    }   

    //Modal windows controls
    hideForms(){
        this.isShowModal=this.valueCodeForm=this.patientCodeForm=this.otherCodeForm=this.icdCodeForm=this.eCodeForm=this.occSpanCodeForm=this.occCodeForm= this.conditionCodeForm=false;
        this.value=null;
    }
    clearForms(){
        this.valueCodeForm=this.patientCodeForm=this.otherCodeForm=this.icdCodeForm=this.eCodeForm=this.occSpanCodeForm=this.occCodeForm= this.conditionCodeForm=false;
    }
    handleNew(){
        this.isShowModal=true;
    }

    //Logic to delete records.
    handleRowAction(event){
        const row = event.detail.row;
        //console.log('Row: '+row);
        deleteClaimCode({claimCodeId: row.Id})
        .then((result) => {
            if(result){
                this.displayMessage('Claim Code deleted successfully!', 'success');
                this.getApexData();
                this.hideForms();
            }
            else this.displayMessage('Error, try again later: ', 'error');
        });
    }

    //Message that pop up when a record is created. 
    handleSuccess() {
        this.displayMessage('Claim Code Saved successfully!', 'success');
    }

    //Logic to update a record. 
    async saveHandleAction(event) {
        this.isLoading = true;
        // Convert datatable draft values into record objects
        const records = event.detail.draftValues.slice().map((draftValue) => {
            const fields = Object.assign({}, draftValue);
            return { fields };
        });
        try {
            // Update all records in parallel thanks to the UI API
            const recordUpdatePromises = records.map((record) =>
                updateRecord(record)
            );
            await Promise.all(recordUpdatePromises);
            console.log('records updated');
            // Display fresh data in the datatable
            this.getApexData();
        } catch (error) {
            console.log(error);
        }     
    }

    getApexData(){
        this.isLoading = true;
        //console.log('inside Apex');
        //this.isLoading = true;
        getClaimCodes({ claimId:this.recordId})
        .then(response => {
            //console.log('Response:' + JSON.stringify(response));
            let dataToFilter = response.Institutional_Claim_Codes__r;
            console.log(dataToFilter);
            if (response.Institutional_Claim_Codes__r != null) {
                //console.log('inside response.claimData');
                //console.log('input: '+ JSON.stringify(dataToFilter));
                //Assign the values to each Table depending upon field type. 
                this.conditionCodeData= dataToFilter.filter(claimData => claimData.ARC_ConditionCode__c != null);
                this.occCodeData= dataToFilter.filter(claimData => claimData.ARC_Occurrence_Code__c != null)
                this.occSpanCodeData= dataToFilter.filter(claimData => claimData.ARC_Occurrence_Span_Code__c != null);
                this.eCodeData= dataToFilter.filter(claimData => claimData.ARC_ECode__c != null);
                this.icdCodeData= dataToFilter.filter(claimData => claimData.ARC_ICD_DX__c != null);
                this.otherCodeData= dataToFilter.filter(claimData => claimData.ARC_Other_Procedure_Code__c != null);
                this.patientDxCodeData= dataToFilter.filter(claimData => claimData.ARC_Patient_DX__c != null);
                this.valeCodeData= dataToFilter.filter(claimData => claimData.ARC_Vale_Codes__c != null);
                console.log(JSON.stringify(this.eCodeData));

                //Transform nodes ending with __r.(RelatedField) into one level node. 
                this.otherCodeData?.forEach(od=>{od.ARC_Other_Procedure_Code__c = od.ARC_Other_Procedure_Code__r.Name;});
                this.icdCodeData?.forEach((icd, i)=>{icd.ARC_ICD_DX__c = icd.ARC_ICD_DX__r.Name; icd['index'] = i + 1});
                this.conditionCodeData?.forEach(cc=>{cc.ARC_ConditionCode__c= cc.ARC_ConditionCode__r.Name;});
                this.eCodeData?.forEach((ec, i)=>{ec.ARC_ECode__c= ec.ARC_ECode__r.Name; ec['index'] = i + 1});

                //Check if the table has data to show
                this.isConditionCode= this.conditionCodeData.length>0?true:false;
                this.isOccurenceCode = this.occCodeData.length>0?true:false;
                this.isOccSpanCode= this.occSpanCodeData.length>0?true:false;
                this.isECode= this.eCodeData.length>0?true:false;
                this.isICDCode= this.icdCodeData.length>0?true:false;
                this.isOtherCode= this.otherCodeData.length>0?true:false;
                this.isPatienDx= this.patientDxCodeData.length>0?true:false;
                this.isValueCode= this.valeCodeData.length>0?true:false;
                console.log(JSON.parse(JSON.stringify(this.icdCodeData)))
            }else{
                //this.isData = false;
            }
        })
        .catch(error => {
            console.error(error);
        })
        .finally(() => {
            this.isLoading = false;
        })
    }

    getInsClaimCodeRT(){
        getRecordType()
        .then(response => {
            this.recordTypeList=response;
            console.log('Response:' + JSON.stringify(response));
        })
        .catch(error => {
            console.error(error);
        })
    }

    connectedCallback(){
        this.getApexData();
        this.getInsClaimCodeRT();
        this.actions = [];
    }

    handleMouseover(evt) {
        const toolTipDiv = this.template.querySelector('[data-display="' + evt.currentTarget.dataset.code + '"]');
        if (toolTipDiv != null) {
            toolTipDiv.style.opacity = 1;
            toolTipDiv.style.display = "block";
        }
    }

    handleMouseout(evt) {
        const toolTipDiv = this.template.querySelector('[data-display="' + evt.currentTarget.dataset.code + '"]');
        if (toolTipDiv != null) {
            toolTipDiv.style.opacity = 0;
            toolTipDiv.style.display = "none";
        }
    }

    handleChangeCode(evt){
        switch (evt.currentTarget.dataset.code) {
            case 'admit':
                this.admitCode = evt.target.value;
                break;
            case 'drg':
                this.drgCode = evt.target.value;
                break;
            case 'principal':
                this.principalCode = evt.target.value;
                break;
        }
    }

    handleDelete(e){
        const code = e.currentTarget.dataset.id;
        deleteClaimCode({claimCodeId: code})
        .then((result) => {
            if(result){
                this.displayMessage('Claim Code deleted successfully!', 'success');
                this.getApexData();
                this.hideForms();
            }
            else this.displayMessage('Error, try again later: ', 'error');
        })
        .catch(err => {
            console.error(err);
        })
    }

    handleMouseover(evt) {
        const toolTipDiv = this.template.querySelector('[data-display="' + evt.currentTarget.dataset.item + '"]');
        if (toolTipDiv != null) {
            toolTipDiv.style.opacity = 1;
            toolTipDiv.style.display = "block";
            toolTipDiv.style.marginTop = '2%';
            toolTipDiv.style.marginRight = '3%';
        }
    }

    handleMouseout(evt) {
        const toolTipDiv = this.template.querySelector('[data-display="' + evt.currentTarget.dataset.item + '"]');
        if (toolTipDiv != null) {
            toolTipDiv.style.opacity = 0;
            toolTipDiv.style.display = "none";
        }
    }
}