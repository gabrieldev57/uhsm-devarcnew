import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

const unknownAbrev = ['UNKNOWN', 'UNK', 'UNKN', 'UNKNOW', 'UNKNWN', 'UNKNOWM', 'UNKNOWNE', 'UNKNOWEN', 'UNKNOWM', 'UNKNOWMN'];

import getAllClaimCodes from '@salesforce/apex/ARC_ValidateClaimAfterMapping.getAllClaimCodes';
import getOriginalClaim from '@salesforce/apex/ARC_ValidateClaimAfterMapping.getOriginalClaim';
import getClonedClaims from '@salesforce/apex/ARC_ValidateClaimAfterMapping.getClonedClaims';
import getOriginalCopy from '@salesforce/apex/ARC_ValidateClaimAfterMapping.getOriginalCopy';
import getClaimToValidate from '@salesforce/apex/ARC_ValidateClaimAfterMapping.getClaimToValidate';
import ORIGINAL_CLAIM from '@salesforce/schema/Claim.ARC_OriginalSMB__c';
import ISCOPIED_CLAIM from '@salesforce/schema/Claim.ARC_Copied__c';
import ISADJUSTED_CLAIM from '@salesforce/schema/Claim.ARC_Adjust__c';

export default class ARC_DisplayMissingClaimCodes extends NavigationMixin(LightningElement) {
    @api recordId;
    strMissingCodes;
    missingCodes = false;
    clonedClaim = false;
    isOriginalClaim = false;
    isCopyClaim = false;
    unknownProvider = false;
    negativeNetPaid = false;
    orgClaim = {};
    clonedClaims = [];
    copyClaim = {};

    @wire(getRecord, { recordId: '$recordId', fields: [ORIGINAL_CLAIM, ISCOPIED_CLAIM, ISADJUSTED_CLAIM] })
    fetchLaborCategory({ data }) {
        if (getFieldValue(data, ORIGINAL_CLAIM)) {
            if (getFieldValue(data, ISCOPIED_CLAIM)) {
                this.getOriginalCopy(getFieldValue(data, ORIGINAL_CLAIM));
            } else if (getFieldValue(data, ISADJUSTED_CLAIM)) {
                this.getOriginalClaim(getFieldValue(data, ORIGINAL_CLAIM));
            }
        }
    }

    getOriginalClaim(orgClaim) {
        getOriginalClaim({ originalClaim: orgClaim })
            .then(res => {
                this.clonedClaim = true;
                this.orgClaim['orgName'] = res.Name;
                this.orgClaim['orgNetPaid'] = res.ARC_TotalNetPaidAmount__c;
                this.orgClaim['id'] = res.Id;
            })
            .catch(err => {
                console.error(err);
            })
    }

    getOriginalCopy(orgClaim) {
        getOriginalCopy({ originalClaim: orgClaim })
            .then(res => {
                if (res) {
                    this.isCopyClaim = true;
                    this.copyClaim["id"] = res.Id;
                    this.copyClaim["name"] = res.Name;
                } else {
                    this.isCopyClaim = false;
                }
            })
            .catch(err => {
                console.error(err);
            })
    }

    getClaimCodes() {
        getAllClaimCodes({ clmId: this.recordId })
            .then(res => {
                let codesClaimParsed = res.codesClaim.map(item => {
                    if (item.includes('.')) {
                        return item.replace('.', '');
                    } else {
                        return item;
                    }
                })
                let arrMissing = res.codesInput.filter(item => !codesClaimParsed.includes(item));
                if (arrMissing.length > 0) {
                    this.strMissingCodes = arrMissing.join(', ');
                    this.missingCodes = true;
                } else {
                    this.missingCodes = false;
                }
            })
            .catch(err => {
                console.error(err);
                this.missingCodes = false;
            })
    }

    getClonedClaim() {
        getClonedClaims({ clmId: this.recordId })
            .then(res => {
                if (res.length) {
                    res.forEach(claim => {
                        this.clonedClaims.push({ name: claim.Name, id: claim.Id });
                    })
                    this.isOriginalClaim = true;
                } else {
                    this.isOriginalClaim = false;
                }
            })
            .catch(err => {
                console.error(err);
            })
    }

    getClaimsToValidate() {
        console.log('recordId', this.recordId);
        getClaimToValidate({ clmId: this.recordId })
            .then(res => {

                // CHECK UNKNOWN PROVIDER
                const separateWords = res.ARC_Attending_Provider__r.Name.split(' ');
                if (separateWords.some(word => unknownAbrev.includes(word.toUpperCase()))) {
                    this.unknownProvider = true;
                }

                // CHECK NEGATIVE NETPAID
                console.log(res);
                if (res.Claim_Coverage_Payment_Details__r.length > 0) {
                    this.negativeNetPaid = true;
                }
            })
            .catch(err => {
                console.error(err);
            })
    }

    connectedCallback() {
        this.getClaimCodes();
        this.getClonedClaim();
        this.getClaimsToValidate();
    }

    handleNavigate(evt) {
        let clmSelected = evt.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: clmSelected,
                objectApiName: 'Claim',
                actionName: 'view'
            },
        });
    }
}