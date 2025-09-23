import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import DXA_FIELD from '@salesforce/schema/Claim.DX_A__c';
import DXB_FIELD from '@salesforce/schema/Claim.DX_B__c';
import DXC_FIELD from '@salesforce/schema/Claim.DX_C__c';
import DXD_FIELD from '@salesforce/schema/Claim.DX_D__c';
import DXE_FIELD from '@salesforce/schema/Claim.DX_E__c';
import DXF_FIELD from '@salesforce/schema/Claim.DX_F__c';
import DXG_FIELD from '@salesforce/schema/Claim.DX_G__c';
import DXH_FIELD from '@salesforce/schema/Claim.DX_H__c';
import DXI_FIELD from '@salesforce/schema/Claim.DX_I__c';
import DXJ_FIELD from '@salesforce/schema/Claim.DX_J__c';
import DXK_FIELD from '@salesforce/schema/Claim.DX_K__c';
import DXL_FIELD from '@salesforce/schema/Claim.DX_L__c';

export default class ARC_ICDCodesForm extends LightningElement {
    @api recordId;
    dxA = null;
    dxB = null;
    dxC = null;
    dxD = null;
    dxE = null;
    dxF = null;
    dxG = null;
    dxH = null;
    dxI = null;
    dxJ = null;
    dxK = null;
    dxL = null;

    @wire(getRecord, { recordId: '$recordId', fields: 
    [
        DXA_FIELD, 
        DXB_FIELD,
        DXC_FIELD,
        DXD_FIELD,
        DXE_FIELD,
        DXF_FIELD,
        DXG_FIELD,
        DXH_FIELD,
        DXI_FIELD,
        DXJ_FIELD,
        DXK_FIELD,
        DXL_FIELD
    ] })
    fetchLaborCategory({ data, error }) {
        if (data) {
            this.dxA = getFieldValue(data, DXA_FIELD);
            this.dxB = getFieldValue(data, DXB_FIELD);
            this.dxC = getFieldValue(data, DXC_FIELD);
            this.dxD = getFieldValue(data, DXD_FIELD);
            this.dxE = getFieldValue(data, DXE_FIELD);
            this.dxF = getFieldValue(data, DXF_FIELD);
            this.dxG = getFieldValue(data, DXG_FIELD);
            this.dxH = getFieldValue(data, DXH_FIELD);
            this.dxI = getFieldValue(data, DXI_FIELD);
            this.dxJ = getFieldValue(data, DXJ_FIELD);
            this.dxK = getFieldValue(data, DXK_FIELD);
            this.dxL = getFieldValue(data, DXL_FIELD);
        }else{
            console.error(error);
        }
    }

    handleSuccess() {
        const even = new ShowToastEvent({
            title: 'Success!',
            message: 'Record Saved  !',
            variant: 'success'
        });
        this.dispatchEvent(even);
    }

    handleMouseover(evt) {
        const display = this.returnLetter(evt.currentTarget.dataset.display);

        const toolTipDiv = this.template.querySelector('[data-display="' + display + '"]');
        toolTipDiv.style.opacity = 1;
        toolTipDiv.style.display = "block";
    }

    handleMouseout(evt) {
        const display = this.returnLetter(evt.currentTarget.dataset.display);

        const toolTipDiv = this.template.querySelector('[data-display="' + display + '"]');
        toolTipDiv.style.opacity = 0;
        toolTipDiv.style.display = "none";
    }

    returnLetter(num){
        switch (num) {
            case '1':
                return 'A';
            case '2':
                return 'B';
            case '3':
                return 'C';
            case '4':
                return 'D';
            case '5':
                return 'E';
            case '6':
                return 'F';
            case '7':
                return 'G';
            case '8':
                return 'H';
            case '9':
                return 'I';
            case '10':
                return 'J';
            case '11':
                return 'K';
            case '12':
                return 'L';
        }
    }

    handleChangeCode(evt){
        const dataCode = evt.currentTarget.dataset.code;

        switch (dataCode) {
            case 'dxA':
                this.dxA = evt.target.value;
            break;
            case 'dxB':
                this.dxB = evt.target.value;
            break;
            case 'dxC':
                this.dxC = evt.target.value;
            break;
            case 'dxD':
                this.dxD = evt.target.value;
            break;
            case 'dxE':
                this.dxE = evt.target.value;
            break;
            case 'dxF':
                this.dxF = evt.target.value;
            break;
            case 'dxG':
                this.dxG = evt.target.value;
            break;
            case 'dxH':
                this.dxH = evt.target.value;
            break;
            case 'dxI':
                this.dxI = evt.target.value;
            break;
            case 'dxJ':
                this.dxJ = evt.target.value;
            break;
            case 'dxK':
                this.dxK = evt.target.value;
            break;
            case 'dxL':
                this.dxL = evt.target.value;
            break;
        }
    }
}