import { LightningElement, track, api, wire  } from 'lwc';
import getContracts from '@salesforce/apex/ARC_ProgramChangeReportController.getContracts';

export default class ARC_ProgramChangeReport extends LightningElement {

    //Table Columns
    contractColumns = [
        { label: 'Contract Number', fieldName:'LinkContractNumber', sortable:true, type:"url", typeAttributes: {label: { fieldName: 'ContractNumber'}, target:"_blank"}},
        { label: 'Contract Reason', fieldName:'ARC_ContractReason__c', sortable:true},
        { label: 'Effective Date', fieldName:'ARC_EffectiveDate__c', sortable:true },
        { label: 'Primary Member', fieldName:'PrimarymemberLink', type:"url", typeAttributes: {label: { fieldName: 'PrimaryMember'}, target:"_blank"}},
        { label: 'New Medical Plan', fieldName:'MedicalPlanName'},
        { label: 'New Smart Plan', fieldName:'SmartPlanName'},
        { label: 'New AIDD Plan', fieldName:'AIDDPlanName'},
        { label: 'Expired Contract', fieldName:'LinkExpiredContractNumber', type:"url", typeAttributes: {label: { fieldName: 'ExpiredContractNumber'}, target:"_blank"}},
        { label: 'Old Medical Plan', fieldName:'OldMedicalPlanName'},
        { label: 'Old Smart Plan', fieldName:'OldSmartPlanName'},
        { label: 'Old AIDD Plan', fieldName:'OldAIDDPlanName'},

    ];
    
    @track columns= this.contractColumns;
    @track outputData;
    @track initialRecords;
    isLoaded = false;
    inputList = []; 
    dataList = [];
    dataListIndex = [];  
    programChangetContList = []; 
    //Sort
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy; 
    error;

    connectedCallback(){
        this.getProgramChangeContacts();
    }

    getProgramChangeContacts(){
       getContracts()
        .then(data => {
            console.log("data" +  JSON.stringify(data)); 
            data.forEach(conRec => {
                //console.log("ConRec" +  JSON.stringify(conRec)); 
                //console.log("ConRecProgramChange " +  JSON.stringify(conRec.ProgramChange[0])); 
                let customC = new Object();
                    customC.ARC_ContractReason__c = conRec.ProgramChange[0]?.ARC_ContractReason__c;
                    customC.ARC_EffectiveDate__c = conRec.ProgramChange[0]?.ARC_EffectiveDate__c;
                    customC.LinkContractNumber = "/" + conRec.ProgramChange[0]?.Id;
                    customC.ContractNumber = conRec.ProgramChange[0]?.ContractNumber;
                    customC.ExpiredContractNumber = conRec.ProgramChange[0]?.vlocity_ins__ExpiredContractId__r?.ContractNumber;
                    customC.LinkExpiredContractNumber = "/" + conRec.ProgramChange[0]?.vlocity_ins__ExpiredContractId__r?.Id;
                    let medicalplan= "";
                    let smartplans= "";
                    let aiddplans= "";
                    if(conRec.ProgramChange[0]?.vlocity_ins__ContractLineItems__r != null){
                        conRec.ProgramChange[0]?.vlocity_ins__ContractLineItems__r.forEach(plan =>{
                            if(plan.Name.startsWith("WeShare") || plan.Name.startsWith("UHSM") ) medicalplan = plan.Name + ';' + ' ';
                            else if(plan.Name.startsWith("SMART")) smartplans += plan.Name + ';'+ ' ';
                            else if(plan.Name.startsWith("AIDD")) aiddplans += plan.Name + ';'+ ' ';
                        })
                    }
                    if(conRec.PrimaryMember != null){
                        customC.PrimarymemberLink = "/" + conRec.PrimaryMember[0]?.Id;
                        customC.PrimaryMember = conRec.PrimaryMember[0]?.Name;
                    }
                    customC.MedicalPlanName = medicalplan;
                    customC.SmartPlanName = smartplans;
                    customC.AIDDPlanName = aiddplans;
                    //Clean variables
                    medicalplan = smartplans = aiddplans = "";
                    //Iterate over Contracts to fetch the old one
                    //if(conRec.ExpiredPrograms.length >0){
                        conRec.ExpiredPrograms.forEach(expProgram =>{
                            if(expProgram.vlocity_ins__ProductName__c.startsWith("WeShare") || expProgram.vlocity_ins__ProductName__c.startsWith("UHSM") ) medicalplan = expProgram.vlocity_ins__ProductName__c + ';'+ ' ';
                            else if(expProgram.vlocity_ins__ProductName__c.startsWith("SMART")) smartplans += expProgram.vlocity_ins__ProductName__c + ';'+ ' ';
                            else if(expProgram.vlocity_ins__ProductName__c.startsWith("AIDD")) aiddplans += expProgram.vlocity_ins__ProductName__c + ';'+ ' ';
                            customC.OldMedicalPlanName = medicalplan;
                            customC.OldSmartPlanName = smartplans;
                            customC.OldAIDDPlanName = aiddplans;
                        });
                    //}
                    this.inputList.push(customC);
                    //console.log('CustomC: '+ JSON.stringify(customC));   
            });

            this.outputData = this.inputList;
            this.initialRecords = this.outputData;
            this.isLoaded=true;
        })
        .catch(error => {
            this.error = error;
            window.console.log('conError', error);
            this.outputData = undefined
        })
    }

    //Sort 
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };
        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.outputData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.outputData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    //Search
    handleSearch(event) {
        const searchKey = event.target.value.toLowerCase();
 
        if (searchKey) {
            this.outputData = this.initialRecords;
 
            if (this.outputData) {
                let searchRecords = [];
 
                for (let record of this.outputData) {
                    let valuesArray = Object.values(record);
 
                    for (let val of valuesArray) {
                        //console.log('val is ' + val);
                        let strVal = String(val);
 
                        if (strVal) {
 
                            if (strVal.toLowerCase().includes(searchKey)) {
                                searchRecords.push(record);
                                break;
                            }
                        }
                    }
                }
 
               // console.log('Matched Contracts are ' + JSON.stringify(searchRecords));
               // console.log('outputData ' + JSON.stringify(this.outputData));
                this.outputData = searchRecords;
            }
        } else {
            this.outputData = this.initialRecords;
        }
    }

}