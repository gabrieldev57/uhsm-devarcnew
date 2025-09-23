import { LightningElement, wire, track, api } from 'lwc';
import getClaims from '@salesforce/apex/ARC_PolicyActivityController.getClaims';
import sheetjs from '@salesforce/resourceUrl/sheetjs';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ARC_SMBPolicyActivity extends LightningElement {

    closeReport(){
        const eventToParent = new CustomEvent("closereport")
        this.dispatchEvent(eventToParent);
    }
    workbook; 
    @api policyName;
    @track finalRecords;
    policyHasClaims = false;
    policySearched = false;
    claimsList;
    excelData;
    @track error;
    sortByColumn = '';
    sortDirection = 1;
    columns = [
        { label: '', fieldName: 'expander' },
        { label: 'SMB Number', fieldName: 'Name', sorted: false},
        { label: 'Patient', fieldName: 'Patient', sorted: false},
        { label: 'Status', fieldName: 'Status', sorted: false },
        { label: 'Record Type', fieldName: 'RecordType', sorted: false },
        { label: 'Place of Service', fieldName: 'PlaceOfService', sorted: false },
        { label: 'Zelis Received Date', fieldName: 'ZelisReceivedDate', sorted: false },
        { label: 'Created Date', fieldName: 'CreatedDate', sorted: false },
        { label: 'DOS From', fieldName: 'DOSFrom', sorted: false },
        { label: 'Lag Days', fieldName: 'LagDays', sorted: false },
        { label: 'Billed', fieldName: 'TotalBilledAmount', sorted: false },
        { label: 'Allowed', fieldName: 'Allowed', sorted: false },
        { label: 'Consult Fee', fieldName: 'ConsultFee', sorted: false },
        { label: 'Share for AMCS', fieldName: 'SFAMCS', sorted: false },
        { label: 'AMCS', fieldName: 'AMCS', sorted: false },
        { label: 'MBR Liability', fieldName: 'MBRLiability', sorted: false },
        { label: 'Net Paid', fieldName: 'TotalNetPaidAmount', sorted: false },
        { label: 'Sharing Program', fieldName: 'SharingProgram', sorted: false },
        { label: 'Vendor', fieldName: 'Vendor', sorted: false },
        { label: 'Auditor Validation', fieldName: 'AuditorValidation', sorted: false },
        { label: 'Auditor Approved By', fieldName: 'AuditorApprovedBy', sorted: false },
        { label: 'Last Modified By', fieldName: 'LastModifiedBy', sorted: false },
        { label: 'Last Modified Date', fieldName: 'LastModifiedDate', sorted: false },
        { label: 'Finalized Date', fieldName: 'FinalizedDate', sorted: false },
    ];
       

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.searchPolicy()
        }
    }

    expandChildren(event) {
        const claimId = event.currentTarget.dataset.claimid;
        const recordsCopy = [...this.finalRecords]; // Create a copy of finalRecords to avoid direct modification
        
        // Find the claim with the matching claimId
        const claimToExpand = recordsCopy.find(claim => claim.Id === claimId);
        
        if (claimToExpand) {
            claimToExpand.showChildren = !claimToExpand.showChildren; // Toggle the showChildren property
            this.finalRecords = recordsCopy; // Update finalRecords to trigger rerender
        }
    }
    
    get childRowKey() {
        return `${claim.Id}-child`;
    }
    
    formatDateTime(dateTimeString) {
        const dateTime = new Date(dateTimeString);
        const month = String(dateTime.getMonth() + 1).padStart(2, '0');
        const day = String(dateTime.getDate()).padStart(2, '0');
        const year = dateTime.getFullYear();
    
        let hours = dateTime.getHours();
        const ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12 || 12; // Convert to 12-hour format
        const minutes = String(dateTime.getMinutes()).padStart(2, '0');
    
        return `${month}/${day}/${year}, ${hours}:${minutes} ${ampm}`;
    }
    


    searchPolicy() {
        // Call getClaims with the updated policyName value
        const policyInput = this.template.querySelector('[data-id="policyInput"]');
        this.policyName = policyInput.value;
        this.getClaimsData(this.policyName);
    }
    refreshData() {
        if(this.policyName.length>0) {
            this.getClaimsData(this.policyName);
        }
    }

    getClaimsData(policyName) {
        getClaims({ policyName: policyName })
            .then((data) => {
                if (data) {
                    this.claimsList = data; 
                    let records = [];
                    data.forEach((claim) => { 
                        let childData = [];
                
                        if (claim.RecordType.Name === 'Professional') {
                            //childData = claim.Claim_Coverage_Payment_Details__r.map(childDetail => {
                            claim.Claim_Coverage_Payment_Details__r?.sort((a, b) => {
                                return parseInt(a.Name) - parseInt(b.Name);
                            }).forEach((childDetail) => { 
                                const icdParts = [];
    
                                if (childDetail.ICD_Codes__c?.includes('A')) {
                                    icdParts.push((claim.DX_A__r?.Name ? claim.DX_A__r.Name : '') + (claim.DX_A__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_A__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('B')) {
                                    icdParts.push((claim.DX_B__r?.Name ? claim.DX_B__r.Name : '') + (claim.DX_B__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_B__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('C')) {
                                    icdParts.push((claim.DX_C__r?.Name ? claim.DX_C__r.Name : '') + (claim.DX_C__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_C__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('D')) {
                                    icdParts.push((claim.DX_D__r?.Name ? claim.DX_D__r.Name : '') + (claim.DX_D__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_D__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('E')) {
                                    icdParts.push((claim.DX_E__r?.Name ? claim.DX_E__r.Name : '') + (claim.DX_E__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_E__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('F')) {
                                    icdParts.push((claim.DX_F__r?.Name ? claim.DX_F__r.Name : '') + (claim.DX_F__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_F__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('G')) {
                                    icdParts.push((claim.DX_G__r?.Name ? claim.DX_G__r.Name : '') + (claim.DX_G__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_G__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('H')) {
                                    icdParts.push((claim.DX_H__r?.Name ? claim.DX_H__r.Name : '') + (claim.DX_H__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_H__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('I')) {
                                    icdParts.push((claim.DX_I__r?.Name ? claim.DX_I__r.Name : '') + (claim.DX_I__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_I__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('J')) {
                                    icdParts.push((claim.DX_J__r?.Name ? claim.DX_J__r.Name : '') + (claim.DX_J__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_J__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('K')) {
                                    icdParts.push((claim.DX_K__r?.Name ? claim.DX_K__r.Name : '') + (claim.DX_K__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_K__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                if (childDetail.ICD_Codes__c?.includes('L')) {
                                    icdParts.push((claim.DX_L__r?.Name ? claim.DX_L__r.Name : '') + (claim.DX_L__r?.vlocity_ins__ShortDescription__c ? ' - ' + claim.DX_L__r.vlocity_ins__ShortDescription__c : ''));
                                }
                                childData.push({
                                    'Id': childDetail.Id,
                                    'urlId': '/'+childDetail.Id,
                                    'Name': childDetail.Name,
                                    'CPT': (childDetail.ARC_ProcedureCodeName__c ? childDetail.ARC_ProcedureCodeName__c : '' ) + (childDetail.ARC_ProcedureCode__r?.vlocity_ins__ShortDescription__c ? ' - ' + childDetail.ARC_ProcedureCode__r.vlocity_ins__ShortDescription__c : ''),
                                    'ICD': icdParts.join('; '),
                                });
                            });
                        } else if (claim.RecordType.Name === 'Institutional') {
                            claim.Claim_Coverage_Payment_Details__r?.sort((a, b) => {
                                return parseInt(a.Name) - parseInt(b.Name);
                            }).forEach((childDetail) => { 
                                childData.push({
                                        'Id': childDetail.Id,
                                        'urlId': '/'+childDetail.Id,
                                        'Name': childDetail.Name,
                                        'CPT': (childDetail.ARC_ProcedureCodeName__c ? childDetail.ARC_ProcedureCodeName__c : '' ) + (childDetail.ARC_ProcedureCode__r?.vlocity_ins__ShortDescription__c ? ' - ' + childDetail.ARC_ProcedureCode__r.vlocity_ins__ShortDescription__c : ''),
                                    });
                            });
                            claim.Institutional_Claim_Codes__r?.forEach((institutionalChild) => {
                                    childData.push({
                                        'Id': institutionalChild.Id,
                                        'urlId': '/'+institutionalChild.Id,
                                        'Name': 'Institutional Code',
                                        'ICD': (institutionalChild.ARC_ICD_DX__r?.Name ? institutionalChild.ARC_ICD_DX__r.Name : '' ) + (institutionalChild.ARC_ICD_DX__r?.vlocity_ins__ShortDescription__c ? ' - ' + institutionalChild.ARC_ICD_DX__r.vlocity_ins__ShortDescription__c : ''),
                                    });
                                });
                        }
                        records.push({
                            'Id': claim.Id,
                            'urlId': '/'+claim.Id,
                            'Name': claim.Name,
                            'Patient': claim.ARC_PatientCensusMember__r.Name,
                            'urlPatient': '/'+claim.ARC_PatientCensusMember__c, 
                            'Status': claim.Status,
                            'RecordType': claim.RecordType.Name,
                            'PlaceOfService': claim.ARC_PlaceOfService__c,
                            'ZelisReceivedDate': claim.ARC_OriginalReceivedDate__c,
                            'CreatedDate': this.formatDateTime(claim.CreatedDate),
                            'DOSFrom': claim.ARC_DOSFrom__c,
                            'LagDays': claim.ARC_LagDays__c,
                            'TotalBilledAmount': claim.ARC_ClaimTotalAmount__c.toLocaleString('en-US', { style: 'currency', currency: 'USD' }),
                            'Allowed': claim.ARC_TotalAllowedAmount__c.toLocaleString('en-US', { style: 'currency', currency: 'USD' }),
                            'ConsultFee': claim.ARC_TotalCopayAmount__c.toLocaleString('en-US', { style: 'currency', currency: 'USD' }),
                            'SFAMCS': claim.ARC_TotalCoinsuranceAmount__c.toLocaleString('en-US', { style: 'currency', currency: 'USD' }),
                            'AMCS': claim.ARC_TotalDeductibleAmount__c.toLocaleString('en-US', { style: 'currency', currency: 'USD' }),
                            'MBRLiability': claim.ARC_TotalMBRLiabilityAmount__c.toLocaleString('en-US', { style: 'currency', currency: 'USD' }),
                            'TotalNetPaidAmount': claim.ARC_TotalNetPaidAmount__c.toLocaleString('en-US', { style: 'currency', currency: 'USD' }),
                            'SharingProgram': claim.ARC_MemberBenefitPlan__c,
                            'Vendor': claim.ARC_Vendor__r?.Name,
                            'urlVendor': claim.ARC_Vendor__c,
                            'AuditorValidation': claim.ARC_AuditorValidation__c,
                            'AuditorApprovedBy': claim.ARC_Auditor_Approved_By__c,
                            'LastModifiedBy': claim.LastModifiedBy.Name,
                            'urlLastModifiedBy': claim.LastModifiedById,
                            'LastModifiedDate': this.formatDateTime(claim.LastModifiedDate),
                            'FinalizedDate': claim.FinalizedDate ? this.formatDateTime(claim.FinalizedDate) : '',
                            'showChildren': false,
                            'childData': childData,
                            'hasChildData': childData.length>0
                        });
                    })
                    if(records.length >= 1 ){
                        this.finalRecords = records;
                        this.policyHasClaims = true;
                    }  
                    else {
                        this.finalRecords =[];
                        this.policyHasClaims = false;
                    }
                    console.log('Records:', this.finalRecords);
                    this.policySearched = true;
                }
            })
            .catch((error) => {
                this.error = error;
                console.log('Error: ', error);
            });
    }



    @api async downloadData() {
        await loadScript(this, sheetjs); // load the library
        try {var headersExcel = this.columns.filter(item => item.label != '').map(item =>item.label);
        var excelData = [headersExcel].concat(this.finalRecords.map(record => [
            record.Name,
            record.Patient,
            record.Status,
            record.RecordType,
            record.PlaceOfService,
            record.ZelisReceivedDate,
            record.CreatedDate,
            record.DOSFrom,
            record.LagDays,
            record.TotalBilledAmount,
            record.Allowed,
            record.ConsultFee,
            record.SFAMCS,
            record.AMCS,
            record.MBRLiability,
            record.TotalNetPaidAmount,
            record.SharingProgram,
            record.Vendor,
            record.AuditorValidation,
            record.AuditorApprovedBy,
            record.LastModifiedBy,
            record.LastModifiedDate,
            record.FinalizedDate,
          ]));;
    
        var wb = XLSX.utils.book_new();
        var ws = XLSX.utils.aoa_to_sheet(excelData);
        XLSX.utils.book_append_sheet(wb, ws, "Data");

        var childHeadersExcel = ['SMB','Record Type', 'Name', 'CPT', 'ICD'];
        var childExcelData = [childHeadersExcel];
        for (const claim of this.finalRecords) {
            if (claim.childData && claim.childData.length > 0) {
                for (const child of claim.childData) {
                    childExcelData.push([
                        claim.Name,
                        claim.RecordType,
                        child.Name, 
                        child.CPT, 
                        child.ICD, 
                    ]);
                }
            }
        }
        var wschild = XLSX.utils.aoa_to_sheet(childExcelData);
        XLSX.utils.book_append_sheet(wb, wschild, "ChildData");

        XLSX.writeFile(wb, "SMBs" + this.policyName +".xlsx");

        const evt = new ShowToastEvent({
            title: 'File downloaded succesfully',
            message: 'File: '+ 'SMBs' + this.policyName +'.xlsx',
            variant: "success",
          });
          this.dispatchEvent(evt);
      }catch (error) {
        const errorEvt = new ShowToastEvent({
            title: 'Error downloading file',
            message: 'An error occurred while downloading the file: ' + error.message,
            variant: 'error',
        });
        this.dispatchEvent(errorEvt);
      };
    }

    orderByColumn(event){
        const clickedColumn = event.currentTarget.dataset.column;
        console.log(clickedColumn);
        this.sortBy(clickedColumn);
    }

    sortBy(columnName) {
        const clickedColumn = this.columns.find(column => column.fieldName === columnName);
        if(this.sortByColumn.length>0){
            const oldOrderedColumn = this.columns.find(column => column.fieldName === this.sortByColumn);
            oldOrderedColumn.sorted = false;
        } 
        if(this.sortByColumn === columnName){
            this.sortDirection = -this.sortDirection;
        }
        clickedColumn.sorted = true;
        this.sortByColumn = clickedColumn.fieldName;            
        this.finalRecords.sort((a, b) => {
            if (a[columnName] > b[columnName]) {
                return this.sortDirection;
            } else if (a[columnName] < b[columnName]) {
                return -this.sortDirection;
            }
            return 0;
        });
        
    }

    get showUpArrow() {
        return this.sortDirection === 1;
    }
    
    get showDownArrow() {
        return this.sortDirection === -1;
    }

}