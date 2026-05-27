import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ARC_CoveragePaymentsTable extends OmniscriptBaseMixin(LightningElement) {
    @api recordId;
    @api refreshComponent() {
        this.getApexData();
    }
    @api refreshRows() {
        this.idsSelected = [];
        this.itemsToChange = [];
        this.template.querySelectorAll('input[type="checkbox"]').forEach(element => element.checked = false);
    }
    @api sendPaymentToValue(value) {
        this.valuePaymentTo = value;
    }
    @api getItems(items) {
        let itemIds = items.map(element => element.item);
        let itemsToParent = this.dataPayment.filter(element => itemIds.includes(element.Id));
        const eventToParent = new CustomEvent("paymentitems", { detail: itemsToParent });
        this.dispatchEvent(eventToParent);
    }
    @track dataPayment;
    itemsToParent = [];
    isLoading = false;
    idsSelected = [];
    isData = false;
    valuePaymentTo = 'provider';
    isMemberPayment = false;
    profClaim = false;
    instClaim = false;
    isEditingItem = false;
    hasRefund = false;
    isAdjust = false;
    wasAdjusted = false;
    adjustPreExistingCond = 0.00;
    adjustPreExistingCondSize = 0;
    adjustBilled = 0.00;
    adjustBilledSize = 0;
    adjustAllowed = 0.00;
    adjustAllowedSize = 0;
    adjustAdjusted = 0.00;
    adjustAdjustedSize = 0;
    adjustTobacco = 0.00;
    adjustTobaccoSize = 0;
    adjustCopay = 0.00;
    adjustCopaySize = 0;
    adjustCoinsurance = 0.00;
    adjustCoinsuranceSize = 0;
    adjustDeductible = 0.00;
    adjustDeductibleSize = 0;
    adjustMbrLiability = 0.00;
    adjustMbrLiabilitySize = 0;
    adjustNetPaid = 0.00;
    adjustNetPaidSize = 0;
    selectedItemId;
    billedTotal = 0.00;
    billedTotalSize = 0;
    allowedTotal = 0.00;
    allowedTotalSize = 0;
    adjustedTotal = 0.00;
    adjustedTotalSize = 0;
    tobaccoTotal = 0.00;
    tobaccoTotalSize = 0;
    copayTotal = 0.00;
    copayTotalSize = 0;
    coinsuranceTotal = 0.00;
    coinsuranceTotalSize = 0;
    deductibleTotal = 0.00;
    deductibleTotalSize = 0;
    mbrLiabilityTotal = 0.00;
    mbrLiabilityTotalSize = 0;
    totalPreExistingCond = 0.00;
    totalPreExistingCondSize = 0;
    wHoldTotal = 0.00;
    interestTotal = 0.00;
    penaltyTotal = 0.00;
    netPaidTotal = 0.00;
    netPaidTotalSize = 0;
    refundTotal = 0.00;
    refundTotalSize = 0;
    originalSmbNetPaid = 0.00;
    originalSmbNetPaidSize = 0;
   
    // LEGACY ONLY TOTALS
    mcrBilledTotal = 0.00;
    mcrBilledTotalSize = 0;
    mcrAllowedTotal = 0.00;
    mcrAllowedTotalSize = 0;
    mcrPaidTotal = 0.00;
    mcrPaidTotalSize = 0;
    mcrAdjustedTotal = 0.00;
    mcrAdjustedTotalSize = 0;
    mcrMbrLiabilityTotal = 0.00;
    mcrMbrLiabilityTotalSize = 0;
    isLegacy = false;

    itemsToChange = [];
    tableStyleProfesional = 'grid-template-columns: repeat(25, 1fr);';
    tableStyleInstitutional = 'grid-template-columns: repeat(24, 1fr);';
    // Add this getter instead:
    get tableStyleLegacy() {
        if (this.profClaim) {
            return 'grid-template-columns: repeat(27, minmax(0, 1fr));'; // Professional has 2 extra columns (Place of Service & ICD DX) + MCR fields
        } else if (this.instClaim) {
            return 'grid-template-columns: repeat(26, minmax(0, 1fr));'; // Institutional has 1 extra column (Revenue Code) + MCR fields
        }
        // Default fallback
        return 'grid-template-columns: repeat(27, minmax(0, 1fr));';
    }

    get optMedicalVisit() {
        return [
            { label: "Accupuncture", value: "Accupuncture" },
            { label: "Behavioral", value: "Behavioral" },
            { label: "Chiropractic", value: "Chiropractic" },
            { label: "P. Therapy", value: "P. Therapy" },
            { label: "Urgent Care", value: "Urgent Care" },
            { label: "Office Visit/Copay", value: "Office Visit/Copay" },
            { label: "Cervical Cancer Screenings", value: "Cervical Cancer Screenings" },
            { label: "Mammograms", value: "Mammograms" },
            { label: "Prostate Screenings", value: "Prostate Screenings" },
            { label: "Psychiatric Care", value: "Psychiatric Care" },
            { label: "CC - Cologuard / Self Screen", value: "CC - Cologuard / Self Screen" },
            { label: "CC - Flexible Sigmoidoscopy", value: "CC - Flexible Sigmoidoscopy" },
            { label: "CC - Colonoscopy", value: "CC - Colonoscopy" },
            //{ label: "Generic Formulary Injectable Pen", value: "Generic Formulary Injectable Pen" },
            //{ label: "Standard Brand Formulary Injectable Pen", value: "Standard Brand Formulary Injectable Pen" },
            //{ label: "Non-Formulary Brand Injectable Pen", value: "Non-Formulary Brand Injectable Pen" },
            //{ label: "Specialty Brand Injectable Pen", value: "Specialty Brand Injectable Pen" },
            { label: "Bone Density Screening", value: "Bone Density Screening" },
            { label: "Well Woman Visit", value: "Well Woman Visit" },
            { label: "Shingles Vaccine - Zostavax 90736", value: "Shingles Vaccine - Zostavax 90736" },
            { label: "Shingles Vaccine - Shingrix 90750", value: "Shingles Vaccine - Shingrix 90750" },
            { label: "Sleep/Insomnia Counseling", value: "Sleep/Insomnia Counseling" }
        ]
    }

    displayMessage(title, variant) {
        const evt = new ShowToastEvent({
            title: title,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    getApexData() {
        this.isLoading = true;
        const paramsGetCoveragePayments = {
            input: JSON.stringify({ 'claimId': this.recordId }),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'getAllCoveragePayments',
            options: '{}',
        };
        this.omniRemoteCall(paramsGetCoveragePayments, true)
            .then(response => {

                // RECEIVES LEGACY VARIABLE FROM ARC_CoveragePaymentsTableController getAllCoveragePayments
                this.isLegacy = Boolean(response.result.isLegacy);

                if (response.result.items.length > 0) {
                    let data = [];
                    this.billedTotal = 0.00;
                    this.allowedTotal = 0.00;
                    this.adjustedTotal = 0.00;
                    this.tobaccoTotal = 0.00;
                    this.copayTotal = 0.00;
                    this.coinsuranceTotal = 0.00;
                    this.deductibleTotal = 0.00;
                    this.mbrLiabilityTotal = 0.00;
                    this.wHoldTotal = 0.00;
                    this.interestTotal = 0.00;
                    this.penaltyTotal = 0.00;
                    this.netPaidTotal = 0.00;
                    this.totalPreExistingCond = 0.00;
                    this.adjustPreExistingCond = 0.00;
                    this.adjustBilled = 0.00;
                    this.adjustAllowed = 0.00;
                    this.adjustAdjusted = 0.00;
                    this.adjustTobacco = 0.00;
                    this.adjustCopay = 0.00;
                    this.adjustCoinsurance = 0.00;
                    this.adjustDeductible = 0.00;
                    this.adjustMbrLiability = 0.00;
                    this.adjustNetPaid = 0.00;
                    
                    // LEGACY ONLY TOTALS
                    this.mcrBilledTotal = 0.00;
                    this.mcrAllowedTotal = 0.00;
                    this.mcrPaidTotal = 0.00;
                    this.mcrAdjustedTotal = 0.00;
                    this.mcrMbrLiabilityTotal = 0.00;

                    response.result.items.forEach(item => {
                        let obj = {};
                        obj['Id'] = item.Id;
                        obj['name'] = item.Name;
                        obj['status'] = item.Status;
                        obj['styleTest'] = (item.Status == 'Paid' ? 'item-container styleRowGreen' : (item.Status == 'Denied' ? 'item-container styleRowRed' : 'item-container styleRowNone'));
                        obj['mod1'] = item.ARC_Mod1__c;
                        obj['mod2'] = item.ARC_Mod2__c;
                        obj['mod3'] = item.ARC_Mod3__c;
                        obj['mod4'] = item.ARC_Mod4__c;
                        obj['qty'] = item.ARC_Quantity__c;
                        obj['freqType'] = item.ARC_FreqType__c;
                        obj['cptCode'] = item.ARC_ProcedureCodeName__c;
                        obj['cptId'] = item.ARC_ProcedureCode__c;

                        // MEDICAL VISIT REASON
                        obj['meicalVisitReason'] = item.ARC_Medical_Visit_Reason__c != null ? item.ARC_Medical_Visit_Reason__c : 'Select';

                        // MAXIMUM TYPE
                        if (item.ARC_MaximumType__c != null && item.ARC_MaximumTypeAmount__c != null) {
                            obj['maxType'] = item.ARC_MaximumType__c + ' - ' + '$ ' + parseFloat(item.ARC_MaximumTypeAmount__c).toFixed(2);
                        }

                        obj['preExistingCond'] = parseFloat(item.ARC_Pre_Existing_Condition__c ? item.ARC_Pre_Existing_Condition__c : '0.00');
                        obj['preExistingCondSize'] = this.decimalPlaces(obj['preExistingCond'].toString());
                        let editValues = {
                            visitReason: false,
                            billed: false,
                            allowed: false,
                            preExistingCond: false,
                            adjusted: false,
                            tobacco: false,
                            copay: false,
                            coinsurance: false,
                            deductible: false,
                            mbrLiability: false,
                            wHold: false,
                            interest: false,
                            penalty: false,
                            // Add these Medicare fields
                            mcrBilled: false,
                            mcrAllowed: false,
                            mcrPaid: false,
                            mcrAdjusted: false,
                            mcrMbrLiability: false
                        }

                        obj['editValues'] = editValues;
                        obj['billed'] = parseFloat(item.ClaimedAmount ? item.ClaimedAmount : '0.00');
                        obj['billedSize'] = this.decimalPlaces(obj['billed'].toString());
                        obj['allowed'] = parseFloat(item.ARC_Allowed__c ? item.ARC_Allowed__c : '0.00');
                        obj['allowedSize'] = this.decimalPlaces(obj['allowed'].toString());
                        obj['adjusted'] = parseFloat(item.AdjustedAmount ? item.AdjustedAmount : '0.00');
                        obj['adjustedSize'] = this.decimalPlaces(obj['adjusted'].toString());
                        
                        // LEGACY ONLY FIELDS
                        obj['mcrBilled'] = parseFloat(item.Medicare_Billed__c ?? '0.00');
                        obj['mcrBilledSize'] = this.decimalPlaces(obj['mcrBilled'].toString());
                        obj['mcrAllowed'] = parseFloat(item.Medicare_Allowed__c ?? '0.00');
                        obj['mcrAllowedSize'] = this.decimalPlaces(obj['mcrAllowed'].toString());
                        obj['mcrPaid'] = parseFloat(item.Medicare_Paid__c ?? '0.00');
                        obj['mcrPaidSize'] = this.decimalPlaces(obj['mcrPaid'].toString());
                        obj['mcrAdjusted'] = parseFloat(item.Medicare_Adjusted__c ?? '0.00');
                        obj['mcrAdjustedSize'] = this.decimalPlaces(obj['mcrAdjusted'].toString());
                        obj['mcrMbrLiability'] = parseFloat(item.Medicare_Member_Liability__c ?? '0.00');
                        obj['mcrMbrLiabilitySize'] = this.decimalPlaces(obj['mcrMbrLiability'].toString());

                        // Add to totals
                        this.mcrBilledTotal += obj['mcrBilled'];
                        this.mcrAllowedTotal += obj['mcrAllowed'];
                        this.mcrPaidTotal += obj['mcrPaid'];
                        this.mcrAdjustedTotal += obj['mcrAdjusted'];
                        this.mcrMbrLiabilityTotal += obj['mcrMbrLiability'];


                        obj['tobacco'] = parseFloat(item.ARC_Tobacco__c ? item.ARC_Tobacco__c : '0.00');
                        obj['tobaccoSize'] = this.decimalPlaces(obj['tobacco'].toString());

                        obj['copay'] = parseFloat(item.ARC_Copay__c ? item.ARC_Copay__c : '0.00');
                        obj['copaySize'] = this.decimalPlaces(obj['copay'].toString());

                        obj['coinsurance'] = parseFloat(item.ARC_Coinsurance__c ? item.ARC_Coinsurance__c : '0.00');
                        obj['coinsuranceSize'] = this.decimalPlaces(obj['coinsurance'].toString());

                        obj['deductible'] = parseFloat(item.ARC_Deductible__c ? item.ARC_Deductible__c : '0.00');
                        obj['deductibleSize'] = this.decimalPlaces(obj['deductible'].toString());;

                        obj['mbrLiability'] = parseFloat(item.ARC_MBRLiability__c ? item.ARC_MBRLiability__c : '0.00');
                        obj['mbrLiabilitySize'] = this.decimalPlaces(obj['mbrLiability'].toString());

                        obj['wHold'] = item.ARC_WHold__c ? item.ARC_WHold__c.toFixed(2) : '0.00';
                        if (item.ARC_WHold__c != null) this.wHoldTotal = (parseFloat(this.wHoldTotal) + parseFloat(item.ARC_WHold__c)).toFixed(2);
                        obj['interest'] = item.ARC_Interest__c ? item.ARC_Interest__c.toFixed(2) : '0.00';
                        if (item.ARC_Interest__c != null) this.interestTotal = (parseFloat(this.interestTotal) + parseFloat(item.ARC_Interest__c)).toFixed(2);
                        obj['penalty'] = item.ARC_Penalty__c ? item.ARC_Penalty__c.toFixed(2) : '0.00';
                        if (item.ARC_Penalty__c != null) this.penaltyTotal = (parseFloat(this.penaltyTotal) + parseFloat(item.ARC_Penalty__c)).toFixed(2);

                        obj['netPaid'] = parseFloat(item.ARC_NetPaid__c ? item.ARC_NetPaid__c.toFixed(2) : '0.00');
                        obj['netPaidSize'] = this.decimalPlaces(obj['netPaid'].toString());

                        if (response.result.claimData.Status == 'Adjusted') {
                            if (item.ARC_Pre_Existing_Condition__c != null) {
                                this.adjustPreExistingCond = (parseFloat(this.adjustPreExistingCond) + parseFloat(item.ARC_Pre_Existing_Condition__c));
                                this.adjustPreExistingCondSize = this.decimalPlaces(this.adjustPreExistingCond.toString());
                            }
                            /*
    
                            if(item.ClaimedAmount != null ){
                                this.adjustBilled = (parseFloat(this.adjustBilled) + parseFloat(item.ClaimedAmount));
                                this.adjustBilledSize = this.decimalPlaces(this.adjustBilled.toString());   
                            }
                            if(item.ARC_Allowed__c != null ){
                                this.adjustAllowed = (parseFloat(this.adjustAllowed) + parseFloat(item.ARC_Allowed__c));
                                this.adjustAllowedSize = this.decimalPlaces(this.adjustAllowed.toString());   
                            }
                            if(item.AdjustedAmount != null ){
                                this.adjustAdjusted = (parseFloat(this.adjustAdjusted) + parseFloat(item.AdjustedAmount));
                                this.adjustAdjustedSize = this.decimalPlaces(this.adjustAdjusted.toString());   
                            }
                            if(item.ARC_PrimaryPaid__c != null ){
                                this.adjustPrimaryPaid = (parseFloat(this.adjustPrimaryPaid) + parseFloat(item.ARC_PrimaryPaid__c));
                                this.adjustPrimaryPaidSize = this.decimalPlaces(this.adjustPrimaryPaid.toString());   
                            }
                            */
                            if (item.ARC_Copay__c != null) {
                                this.adjustCopay = (parseFloat(this.adjustCopay) + parseFloat(item.ARC_Copay__c));
                                this.adjustCopaySize = this.decimalPlaces(this.adjustCopay.toString());
                            }
                            if (item.ARC_Coinsurance__c != null) {
                                this.adjustCoinsurance = (parseFloat(this.adjustCoinsurance) + parseFloat(item.ARC_Coinsurance__c));
                                this.adjustCoinsuranceSize = this.decimalPlaces(this.adjustCoinsurance.toString());
                            }
                            if (item.ARC_Deductible__c != null) {
                                this.adjustDeductible = (parseFloat(this.adjustDeductible) + parseFloat(item.ARC_Deductible__c));
                                this.adjustDeductibleSize = this.decimalPlaces(this.adjustDeductible.toString());
                            }/*
                        if(item.ARC_MBRLiability__c != null ){
                            this.adjustMbrLiability = (parseFloat(this.adjustMbrLiability) + parseFloat(item.ARC_MBRLiability__c));
                            this.adjustMbrLiabilitySize = this.decimalPlaces(this.adjustMbrLiability.toString());   
                        }

                        if(item.ARC_NetPaid__c != null ){
                            this.adjustNetPaid = (parseFloat(this.adjustNetPaid) + parseFloat(item.ARC_NetPaid__c));
                            this.adjustNetPaidSize = this.decimalPlaces(this.adjustNetPaid.toString());   
                        }*/
                        }

                        switch (response.result.claimData.RecordType.DeveloperName) {
                            case 'ARC_Institutional':
                                this.instClaim = true;
                                this.profClaim = false;
                                obj['revenueCode'] = item.ARC_RevenueCode__c;
                                obj['rateCode'] = item.ARC_RateCode__c;
                                obj['dosFrom'] = this.formatDate(item?.ARC_DOSFrom__c?.split('-'));
                                obj['dosTo'] = this.formatDate(item?.ARC_DOSTo__c?.split('-'));
                                break;

                            case 'ARC_Professional':
                                this.profClaim = true;
                                this.instClaim = false;
                                obj['dateOfService'] = this.formatDate(item?.ARC_DateOfService__c?.split('-'));
                                obj['placeOfService'] = item.ARC_PlaceofService__c;
                                obj['ARC_ICD_DX__c'] = item.ARC_ICD_DX__c;
                                obj['nonCovCharges'] = item.ARC_NonCoveragesCharges__c;
                                obj['icdx'] = item.ICD_Codes__c;
                                break;
                        }

                        if (item.Claim_Reason_Codes__r) {
                            let codes = [];
                            item.Claim_Reason_Codes__r.records.forEach(item => {
                                if (item.ARC_CodeDescription__c == null) codes.push(item.ARC_CodeNameText__c);
                                else codes.push(item.ARC_CodeNameText__c + ' - ' + item.ARC_CodeDescription__c);
                            })
                            obj['hasCode'] = true;
                            obj['reasonCodes'] = codes.join(', ');
                        } else {
                            obj['hasCode'] = false;
                        }
                        data.push(obj);
                    });

                    this.totalPreExistingCond = response.result.claimData.ARC_Total_PreExistingConditions__c;
                    this.totalPreExistingCondSize = this.decimalPlaces(this.totalPreExistingCond.toString());
                    this.billedTotal = response.result.claimData.ARC_ClaimTotalAmount__c;
                    this.billedTotalSize = this.decimalPlaces(this.billedTotal.toString());
                    this.allowedTotal = response.result.claimData.ARC_TotalAllowedAmount__c;
                    this.allowedTotalSize = this.decimalPlaces(this.allowedTotal.toString());
                    this.adjustedTotal = response.result.claimData.ARC_TotalAdjustedAmount__c;
                    this.adjustedTotalSize = this.decimalPlaces(this.adjustedTotal.toString());
                    this.tobaccoTotal = response.result.claimData?.ARC_TotalTobacco__c ? response.result.claimData.ARC_TotalTobacco__c.toFixed(2) : '0.00';
                    this.tobaccoTotalSize = this.decimalPlaces(this.tobaccoTotal.toString());
                    this.copayTotal = response.result.claimData.ARC_TotalCopayAmount__c;
                    this.copayTotalSize = this.decimalPlaces(this.copayTotal.toString());
                    this.coinsuranceTotal = response.result.claimData.ARC_TotalCoinsuranceAmount__c;
                    this.coinsuranceTotalSize = this.decimalPlaces(this.coinsuranceTotal.toString());
                    this.deductibleTotal = response.result.claimData.ARC_TotalDeductibleAmount__c;
                    this.deductibleTotalSize = this.decimalPlaces(this.deductibleTotal.toString());
                    this.mbrLiabilityTotal = response.result.claimData.ARC_TotalMBRLiabilityAmount__c;
                    this.mbrLiabilityTotalSize = this.decimalPlaces(this.mbrLiabilityTotal.toString());
                    this.netPaidTotal = response.result.claimData.ARC_TotalNetPaidAmount__c;
                    this.netPaidTotalSize = this.decimalPlaces(this.netPaidTotal.toString());
                    this.refundTotal = response.result.claimData.ARC_RefundAmount__c ? response.result.claimData.ARC_RefundAmount__c.toFixed(2) : '0.00';
                    this.refundTotalSize = this.decimalPlaces(this.refundTotal.toString());
                    this.hasRefund = (response.result.claimData.ARC_Refund__c && this.refundTotal > 0);
                    this.isAdjust = response.result.claimData.ARC_Adjust__c;
                    this.originalSmbNetPaid = response.result.claimData.ARC_OriginalSMB__r?.ARC_TotalNetPaidAmount__c ? response.result.claimData.ARC_OriginalSMB__r.ARC_TotalNetPaidAmount__c.toFixed(2) : '0.00';
                    this.originalSmbNetPaidSize = this.decimalPlaces(this.originalSmbNetPaid.toString());
                    this.wasAdjusted = (response.result.claimData.Status == 'Adjusted') && (this.adjustCopay > 0 || this.adjustCoinsurance > 0 || this.adjustDeductible > 0);

                    // MCR Calculation Values
                    this.mcrBilledTotalSize = this.mcrBilledTotal ? this.decimalPlaces(this.mcrBilledTotal.toString()) : 2;
                    this.mcrAllowedTotalSize = this.mcrAllowedTotal ? this.decimalPlaces(this.mcrAllowedTotal.toString()) : 2;
                    this.mcrPaidTotalSize = this.mcrPaidTotal ? this.decimalPlaces(this.mcrPaidTotal.toString()) : 2;
                    this.mcrAdjustedTotalSize = this.mcrAdjustedTotal ? this.decimalPlaces(this.mcrAdjustedTotal.toString()) : 2;
                    this.mcrMbrLiabilityTotalSize = this.mcrMbrLiabilityTotal ? this.decimalPlaces(this.mcrMbrLiabilityTotal.toString()) : 2;

                    this.dataPayment = data;
                    this.itemsToChange = [];
                    this.isData = true;
                } else {
                    this.isData = false;
                }
            })
            .catch(error => {
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
            })
    }

    renderedCallback() {
        if (this.dataPayment) {
            this.dataPayment.forEach(element => {
                if ((element.status == 'Paid' || element.hasCode == false) && this.template.querySelector('[data-btnid="' + element.Id + '"]')) this.template.querySelector('[data-btnid="' + element.Id + '"]').disabled = true;
            });
        }
    }

    connectedCallback() {
        this.getApexData();
    }

    handleChangeCheckbox(e) {
        const evtTarget = e.currentTarget.dataset.id;
        const isChecked = e.currentTarget.checked;

        if (evtTarget == 'all') {
            if (isChecked) {
                this.template.querySelectorAll('input[type="checkbox"]').forEach(element => element.checked = true);
                this.idsSelected = this.dataPayment.map(item => item.Id);
            } else {
                this.template.querySelectorAll('input[type="checkbox"]').forEach(element => element.checked = false);
                this.idsSelected = [];
            }
        } else {
            if (isChecked) {
                this.idsSelected.push(evtTarget);
            } else {
                this.idsSelected = this.idsSelected.filter(item => item != evtTarget);
                this.template.querySelector('input[data-id="all"]').checked = false;
            }
        }

        let detail = this.idsSelected.map(item => {
            let status = this.dataPayment.filter(element => element.Id == item)[0].status;
            return { item, status }
        })
        const eventToParent = new CustomEvent("checkboxchange", { detail: detail });
        this.dispatchEvent(eventToParent);
    }

    handleNavigate(e) {
        window.location.href = '/' + e.currentTarget.dataset.id;
    }

    handlePayItem(e) {
        this.lastPaymentId = e.currentTarget.dataset.btnid;
        if (this.valuePaymentTo == 'member') {
            this.isMemberPayment = true;
        } else {
            this.payItem(e.currentTarget.dataset.btnid);
        }
    }

    payItem(btnid) {
        this.isLoading = true;
        const input = { itemIds: [btnid], paymentTo: this.valuePaymentTo, claimId: this.recordId };
        const params = {
            input: JSON.stringify(input),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'createItemPayments',
            options: '{}',
        };
        this.omniRemoteCall(params, true)
            .then(response => {
                const res = response.result;

                if (res.error == 'OK') {
                    if (res.itemPayed) this.displayMessage("The item '" + res.itemPayed[0] + "' has been paid successfully!", "success")
                    else if (res.itemsAlreadyPaied) this.displayMessage("The item '" + res.itemsAlreadyPaied[0] + "' already has been paid before", "warning");
                } else {
                    this.displayMessage('Error, try again later...', 'error');
                }
            })
            .catch(error => {
                this.displayMessage('Error, try again later...', 'error');
                console.error(error);
            })
            .finally(() => {
                this.getApexData();
                this.isMemberPayment = false;
                eval("$A.get('e.force:refreshView').fire();");
            })
    }

    handleManageModal() {
        this.isMemberPayment = false;
    }

    handlePaymentMember() {
        this.payItem(this.lastPaymentId);
    }

    handleEditItem(e) {
        if (e.currentTarget.dataset.manage == 'open') {
            this.isEditingItem = true;
            this.selectedItemId = e.currentTarget.dataset.id;            
        } else {
            this.isEditingItem = false;
            this.selectedItemId = null;
        }
    }

    handleChangeValue(e) {
        const item = e.currentTarget.dataset.item;
        const value = e.currentTarget.dataset.value;

        let obj = { item: item, values: { [value]: e.target.value } };
        this.itemsToChange.length == 0 && this.itemsToChange.push(obj);
        let itemToUpdate = this.itemsToChange.filter(element => element.item == item);
        if (itemToUpdate.length == 1) {
            this.itemsToChange.filter(element => element.item == item)[0].values[value] = e.target.value;
        } else {
            this.itemsToChange.push(obj);
        }

        const eventToParent = new CustomEvent("edititem", { detail: this.itemsToChange });
        this.dispatchEvent(eventToParent);
    }

    handleEditValue(e) {
        const item = e.currentTarget.dataset.item;
        const value = e.currentTarget.dataset.value;

        this.dataPayment.forEach(element => {
            if (element.Id == item) {
                element.editValues[value] = true;
            }
        })
    }

    handleSaveValues(e) {
        if (e.keyCode === 13) {
            this.isLoading = true;

            const input = { input: this.itemsToChange }
            const params = {
                input: JSON.stringify(input),
                sClassName: 'ARC_CoveragePaymentsTableController',
                sMethodName: 'saveLineItems',
                options: '{}',
            };
            this.omniRemoteCall(params, true)
                .then(response => {
                    response.result.updated ? this.displayMessage('Items updated successfully!', 'success') : this.displayMessage(response.result.updateError, 'error');
                })
                .catch(error => {
                    console.error(error);
                })
                .finally(() => {
                    this.getApexData();

                    const eventToParent = new CustomEvent("refreshitems");
                    this.dispatchEvent(eventToParent);
                })
        }
    }

    successCreateCovPayment() {
        this.displayMessage('Item saved successfully!', 'success');
        this.getApexData();
        this.isEditingItem = false;
        this.selectedItemId = null;
    }

    errorCreateCovPayment(e) {
        this.displayMessage('Error on the item modification', 'error');
    }

    formatDate(dateArray) {
        if (dateArray != null) return dateArray[1] + '-' + dateArray[2] + '-' + dateArray[0].slice(-2);
        else return null;
    }

    decimalPlaces(num) {
        let res = 0;
        if (num.includes('.')) {
            let arrayNum = num.split('.');
            if (arrayNum[1]?.toString().length < 2) res = num.length;
            else res = num.length - 1;
        }
        else res = num.length + 2;
        return res;
    }

    handleMouseover(evt) {
        const toolTipDiv = this.template.querySelector('[data-display="' + evt.currentTarget.dataset.item + '"]');

        toolTipDiv.style.opacity = 1;
        toolTipDiv.style.display = "block";
        toolTipDiv.style.marginTop = '2%';
        toolTipDiv.style.marginRight = '3%';
    }

    handleMouseout(evt) {
        const toolTipDiv = this.template.querySelector('[data-display="' + evt.currentTarget.dataset.item + '"]');
        toolTipDiv.style.opacity = 0;
        toolTipDiv.style.display = "none";
    }
}