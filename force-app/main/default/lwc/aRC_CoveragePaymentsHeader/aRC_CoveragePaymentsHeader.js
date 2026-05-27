import { LightningElement, api, track, wire } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ARC_CoveragePaymentsHeader extends OmniscriptBaseMixin(LightningElement) {
    @api recordId;
    @api modalpopup = false;
    @api showDuplicate = false;
    @api showPartialDuplicate = false;
    @track onlyone = false;
    nextItem;
    disCode = true;
    goAhead = false;
    moveBack = false;
    instItem = false;
    profItem = false;
    isLoading = true;
    noChecked = false;
    showCommit = false;
    disDuplicate = false;
    commitStatus = false;
    valueCoverage = null;
    isUncommiting = false;
    isMemberPayment = false;
    valueParticipant = null;
    uncommitAllItems = true;
    isCreateCovPayment = false;
    loadingItemCreation = false;
    optionsCode = [];
    arrToFilter = [];
    rowsSelected = [];
    reasonCodeList = [];
    @track modItems = [];
    icdCodes = []; // ?
    cptCodes = []; // ?
    allCodes = {
        'letter': [],
        'denied': [],
        'pended': [],
        'refund': [],
        'capitated': [],
        'adjustment': [],
        'informational': []
    };
    
    valueStatus = null;
    isAdjReason = false; // ?
    valueCPTCode = null; // ?
    valueCodeType = []; // ?
    
    showDropdown = false;
    @track valueReason = '';
    
    get disApplyBtn() {
        if ((this.rowsSelected.length > 0 && this.valueStatus != null) || this.modItems.length > 0) {
            return false;
        } else {
            return true;
        }
    }

    get disResetBtn() {
        if (this.rowsSelected.length > 0) {
            return false;
        } else {
            return true;
        }
    }

    get disPayBtn() {
        let disable = false;

        if (this.rowsSelected.length > 0) {
            this.rowsSelected.forEach(cli => {
                if (cli.status == 'Denied') {
                    disable = true;
                } else if (this.onlyone == false) {
                    disable = true;
                }
            });
        }
        else disable = true;
        return disable;
    }

    get disPayItemsBtn() {
        return this.rowsSelected.length > 0 ? false : true;
    }

    get disDeleteItems() {
        return this.rowsSelected.length > 0 ? false : true;
    }

    connectedCallback() {
        // this.getApexData(true)
        this.disDuplicate = true;
        this.SMBDuplicateValue(true);
    }

    handleChangeStatus(evt) {
        this.valueStatus = evt.detail.value;
        this.reasonCodeList = [];
        if (this.valueStatus != 'New') {
            this.valueReason = ''
            this.populateCodeOptions(this.valueStatus);
        } else {
            this.disCode = true;
        }        
    }

    handleSelectReasonFocus(e){
        this.showDropdown = true
    }

    handleSelectReasonBlur(e){
        const dropdown = this.template.querySelector('[data-id="optionsDropdown"]');
        const selectReasons = this.template.querySelector('[data-id="selectReasons"]');
        const newFocus = e.relatedTarget;
        if (
            newFocus &&
            (dropdown.contains(newFocus) || selectReasons.contains(newFocus))
        ) {
            return;
        }

       this.showDropdown = false;
    }

    filterItems(e) {
        const label = e.detail.value;
        this.arrToFilter = [...this.optionsCode];
        if (label) {
            this.arrToFilter = this.arrToFilter.filter(item => {
                if(item.label) { 
                    return item.label.toLowerCase().includes(label.toLowerCase())
                }else{
                    console.log('no item.label')
                    return false
                }
            });
        }
    }


    populateCodeOptions(codeType) {
        const type = codeType.toLowerCase();

        let mapCodes = this.reasonCodeList.map(item => item.id);
        let codes = this.allCodes[type].filter(item => !mapCodes.includes(item.id));

        this.optionsCode = JSON.parse(JSON.stringify(codes.map(item => ({ label: item.name + ' - ' + item.reason, value: item.id })))); 


        this.arrToFilter = [...this.optionsCode];

        if (this.optionsCode.length > 0) {
            this.disCode = false;
            return true;
        } else {
            this.disCode = true;
            return false;
        }
    }

    handleSelectCode(e) {
        const codeId = e.currentTarget.dataset.id;
        this.valueReason = ''
        const value = this.valueStatus.toLowerCase();
        let code = this.allCodes[value].find(element => element.id == codeId);
        this.reasonCodeList.push({ code: code.name, id: codeId });

        this.populateCodeOptions(this.valueStatus);
    }

    handleDeleteCode(e) {
        this.reasonCodeList = this.reasonCodeList.filter(item => item.id !== e.currentTarget.dataset.code);
        this.populateCodeOptions(this.valueStatus);
    }

    handleUpdate() {
        if ((this.valueStatus && this.rowsSelected.length) || this.modItems.length > 0) {
            this.isLoading = true;
            const input = {
                status: this.valueStatus,
                reasonCodeList: this.reasonCodeList,
                codes: this.reasonCodeList.map(item => item.id),
                ids: this.rowsSelected.map(element => element.item),
                itemsMod: this.modItems,
            }

            const params = {
                input: JSON.stringify(input),
                sClassName: 'ARC_CoveragePaymentsTableController',
                sMethodName: 'updateCovPaymentStatus',
                options: '{}',
            };
            this.omniRemoteCall(params, true).then(response => {
                if (response.result.result == "updated") {
                    this.displayMessage('Line Items updated successfully!', 'success');
                } else {
                    if (response?.result?.result != null) this.displayMessage(response.result.result, 'error');
                    else this.displayMessage('The Line Items were not updated!', 'error');
                }
            })
                .catch(error => {
                    console.error(error);
                })
                .finally(() => {
                    this.clearAllData();
                    eval("$A.get('e.force:refreshView').fire();");
                    this.isLoading = false;
                })
        } else {
            alert('You are missing some data');
        }
    }

    handleManageModal(e) {
        const action = e.currentTarget.dataset.id;
        action == 'open' ? this.isCreateCovPayment = true : this.isCreateCovPayment = false;
    }

    handleChangeCheckbox(e) {
        this.rowsSelected = e.detail;
    }

    getItemsFromChild() {
        this.template.querySelector('c-a-r-c_-coverage-payments-table').getItems(this.rowsSelected);
    }

    handleManageModalUncommit(e) {
        const action = e.currentTarget.dataset.action;
        action == 'open' ? this.isUncommiting = true : this.isUncommiting = false;
    }

    handleUncommit() {
        const input = { 'itemIds': [], claimId: this.recordId };
        this.rowsSelected.forEach(element => input.itemIds.push(element.item));
        this.isLoading = true;
        this.isUncommiting = false;
        const params1 = {
            input: JSON.stringify(input),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'createIfMissingSMBItemPayments',
            options: '{}',
        };
        console.log('createIfMissingSMBItemPayments params1', params1);
        this.omniRemoteCall(params1, true)
            .then(response => {
                console.log('createIfMissingSMBItemPayments response', response);

                const params = {
                    input: JSON.stringify(input),
                    sClassName: 'ARC_CoveragePaymentsTableController',
                    sMethodName: 'uncommitAllChanges',
                    options: '{}',
                };
                this.omniRemoteCall(params, true)
                    .then(response => {
                        if (response.result.updated) {
                            this.displayMessage('All the line items was restored!', 'success');
                        } else if(response.result.DOSToMissing) {
                            this.displayMessage('The DOS Through field is missing', 'error');
                            console.log(response)
                        } else {
                            this.displayMessage('The SMB is closed or already approved by Auditor', 'error');
                            console.log(response)
                        }
                    })
                    .catch(error => {
                        console.error(error);
                        this.displayMessage('Error', 'error');
                    })
                    .finally(() => {
                        this.clearAllData();
                        this.template.querySelector('c-a-r-c_-coverage-payments-table').refreshRows();
                        // eval("$A.get('e.force:refreshView').fire();");
                    })
                
                })
            .catch(error => {
                console.error(error);
                this.displayMessage('Error', 'error');
            })

        
    }

    validateItemPayment(evt) {
        let reasonCodes = true;
        evt.detail.forEach(item => {
            if (!item?.reasonCodes) reasonCodes = false;
        })

        if (!reasonCodes) {
            this.displayMessage('Error, you need to apply reason codes to pay an Item', 'error');
            return;
        } else {
            const negativeNetpaid = evt.detail.some(item => item.netPaid < 0)
            if (negativeNetpaid) {
                if (confirm("There are items with negative Net Paid, do you want to continue?")) {
                    this.executeItemPayment();
                }
            } else {
                this.executeItemPayment();
            }
        }
    }

    executeItemPayment() {
        const input = { 'itemIds': [], claimId: this.recordId };
        this.isLoading = true;
        this.isMemberPayment = false;
        this.rowsSelected.forEach(element => input.itemIds.push(element.item));

        const params = {
            input: JSON.stringify(input),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'createItemPayments',
            options: '{}',
        };
        this.omniRemoteCall(params, true)
            .then(response => {
                if (response.result.itemsPaid) {
                    this.displayMessage(response.result.itemsPaid, "success")
                } else if (response.result.errorOnUpdate) {
                    this.displayMessage(response.result.errorOnUpdate, "error")
                } else {
                    this.displayMessage("No items has been paid", "warning")
                }
            })
            .catch(error => {
                this.displayMessage('Error, try again later...', 'error');
                console.error(error);
            })
            .finally(() => {
                this.clearAllData();
                this.template.querySelector('c-a-r-c_-coverage-payments-table').refreshRows();
                // eval("$A.get('e.force:refreshView').fire();");
            })
    }

    handleManageModalMemberPaymnt() {
        this.isMemberPayment = false;
    }

    handleGetModItems(e) {
        e.detail.forEach(element => {
            let sameItem = this.modItems.filter(value => value.item == element.item);
            if (element.values.visitReason && sameItem.length == 0) {
                this.modItems.push({ item: element.item, reason: element.values.visitReason });
            }
        })
    }

    successCreateCovPayment() {
        this.clearAllData();
        this.displayMessage('Coverage Payment created successfully!', 'success');
    }

    errorCreateCovPayment(e) {
        this.isCreateCovPayment = false;
        this.isLoading = false;
        this.displayMessage('Error, try again later', 'error');
    }

    handleSaveItem() {
        this.isLoading = true;
        this.isCreateCovPayment = false;
    }

    handleSubmitItem(e) {
        e.preventDefault();
        const fields = e.detail.fields;
        this.loadingItemCreation = true;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleDeleteItems() {
        console.log('this.rowsSelected',JSON.parse(JSON.stringify(this.rowsSelected)))
        if (!confirm('Are you sure you want to delete the selected items?')) return;
        if (!this.rowsSelected.length) return;
        for (const lineItem of this.rowsSelected) {
            if (lineItem['status'] == 'Paid') {
                this.displayMessage('Delete failed: Paid items are locked and cannot be removed.', 'error');
                return;
            }
        }
        this.isLoading = true;
        //Test comment - delete after deploying in copado
        const params = {
            input: JSON.stringify({ recordId: this.recordId, rowsSelected: this.rowsSelected }),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'deleteItems',
            options: '{}',
        };

        this.omniRemoteCall(params, true)
            .then(({ result: response }) => {
                console.log(response);
                if (response.Status == 'Success') {
                    this.displayMessage(response.Message, 'success');
                    this.clearAllData()
                } else if (response.Status == 'Error') {
                    this.displayMessage(response.Message, 'error');
                }
            })
            .catch(error => {
                console.error(error);
                this.displayMessage('There was an error, try again later', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            })

    }

    aheadModel() {
        this.modalpopup = false;
        this.goAhead = true;
        this.SMBDeDuplicateValue(true);
        // eval("$A.get('e.force:refreshView').fire();");
    }

    hideModalBox() {
        this.modalpopup = false;
        this.onlyone = false;
    }

    checkDuplicates(evt) {
        this.disDuplicate = true;
        this.getApexDuplicateData(true);
    }
    
    async getApexDuplicateData(once = false) {
        this.isLoading = true;
        const paramsGetStatuses = {
            input: JSON.stringify({ claimId: this.recordId }),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'CheckForDuplicateClaim2',
            options: '{}',
        };
        this.omniRemoteCall(paramsGetStatuses, true)
            .then(response => {
                this.disDuplicate = false;
                if (response.result.errorMessage) {
                    this.displayMessage(response.result.errorMessage, 'warning');
                } else if (response.result.duplicatesFound == 'duplicate') {
                    this.displayMessage('Duplicate found, claim name updated', 'success');
                    this.modalpopup = true;
                    this.showDuplicate = true;
                } else if (response.result.duplicatesFound == 'partialDuplicate') {
                    this.displayMessage('Partial Duplicate found, claim name updated', 'success');
                    this.modalpopup = true;
                    this.showPartialDuplicate = true;
                } else {
                    this.modalpopup = true;
                }
                this.getApexData(true);
                console.log('showDuplicate getApexDup: ',this.showDuplicate);
                console.log('showPartialDuplicate getApexDup: ',this.showPartialDuplicate);
            })
            .catch(error => {
                console.error(error);
            })
    }
    
    async SMBDuplicateValue(once = false) {
        this.isLoading = true;

        const paramsGetStatusesDup = {
            input: JSON.stringify({ claimId: this.recordId }),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'CheckForDuplicateClaim2',
            options: '{}',
        };
        this.omniRemoteCall(paramsGetStatusesDup, true)
            .then(response => {
                this.disDuplicate = false;
                if (response.result.errorMessage) {
                    this.displayMessage(response.result.errorMessage, 'warning');
                } else if (response.result.duplicatesFound == 'duplicate') {
                    this.displayMessage('Duplicate found, claim name updated', 'success');
                    this.modalpopup = true;
                    this.showDuplicate = true;
                } else if (response.result.duplicatesFound == 'partialDuplicate') {
                    this.displayMessage('Partial Duplicate found, claim name updated', 'success');
                    this.modalpopup = true;
                    this.showPartialDuplicate = true;
                }
                this.getApexData(true);
                console.log('showDuplicate getApexDup: ',this.showDuplicate);
                console.log('showPartialDuplicate getApexDup: ',this.showPartialDuplicate);
            })
            .catch(error => {
                console.error(error);
            })

        const paramsGetStatuses = {
            input: JSON.stringify({ claimId: this.recordId }),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'CheckForDuplicateClaim2InIt',
            options: '{}',
        };
        this.omniRemoteCall(paramsGetStatuses, true)
            .then(response => {
                if (response.result.duplicateStatus == 'duplicatesFound') {
                    //this.displayMessage('Duplicate found, claim name updated', 'success');
                    this.showDuplicate = true;
                } else if (response.result.duplicateStatus == 'partialDupeClaims') {
                    //this.displayMessage('Duplicate found, claim name updated', 'success');
                    this.showPartialDuplicate = true;
                } else if (response.result.duplicateStatus == 'partialMoveAheadDupeClaims') {
                    this.showPartialDuplicate = true;
                    this.onlyone = true;
                    //this.displayMessage('This SMB does not have a duplicate', 'success');
                } else if (response.result.duplicateStatus == 'duplicatesMoveAheadFound') {
                    //this.displayMessage('Duplicate found, claim name updated', 'success');
                    this.showDuplicate = true;
                    this.onlyone = true;
                } else if (response.result.duplicateStatus == 'duplicatesChecked') {
                    this.onlyone = true;
                    //this.displayMessage('This SMB does not have a duplicate', 'success');
                } else {
                    this.onlyone = false;
                    this.commitStatus = true;
                }
                console.log('showDuplicate DUPVAL: ',this.showDuplicate);
                console.log('showPartialDuplicate DUPVAL: ',this.showPartialDuplicate);
            })
            .catch(error => {
                console.error(error);
            })

    }

    async SMBDeDuplicateValue(once = false) {
        this.isLoading = true;
        const paramsGetStatuses = {
            input: JSON.stringify({ claimId: this.recordId }),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'CheckForDuplicateClaim2DeDuplicate',
            options: '{}',
        };
        this.omniRemoteCall(paramsGetStatuses, true)
            .then(response => {
                if (response.result.duplicateStatus == 'duplicatesFound') {
                    this.onlyone = true;
                    this.displayMessage('Duplicate found, claim name updated', 'success');
                    this.showDuplicate = true;
                } else if (response.result.duplicateStatus == 'partialDupeClaims') {
                    this.onlyone = true;
                    this.displayMessage('Duplicate found, claim name updated', 'success');
                    this.showPartialDuplicate = true;
                } else {
                    this.onlyone = true;
                    this.displayMessage('No Duplicate found', 'success');
                }
                this.getApexData(true);
                console.log('showDuplicate SMBDeDup: ',this.showDuplicate);
                console.log('showPartialDuplicate SMBDeDup: ',this.showPartialDuplicate);
            })
            .catch(error => {
                console.error(error);
            })
    }

    async getApexData(once = false) {
        this.isLoading = true;
        const paramsGetStatuses = {
            input: JSON.stringify({ claimId: this.recordId }),
            sClassName: 'ARC_CoveragePaymentsTableController',
            sMethodName: 'getAllOptions',
            options: '{}',
        };
        this.omniRemoteCall(paramsGetStatuses, true)
            .then(response => {
                if (response.result.statuses) {
                    let statusList = [];
                    response.result.statuses.forEach(s => {
                        statusList.push({ label: s, value: s });
                    });
                    this.optionsStatus = statusList;
                }
                if (response.result.coverages) {
                    this.valueCoverage = response.result.coverages[0].Id;
                }
                if (response.result.reasonCodes.length > 0) {
                    const codes = response.result.reasonCodes;

                    codes.forEach(code => {
                        if (code.ARC_Status__c == 'Denied') {
                            this.allCodes.denied.push({ reason: code.vlocity_ins__ShortDescription__c, name: code.Name, id: code.Id });
                        } else if (code.ARC_Status__c == 'Informational') {
                            this.allCodes.informational.push({ reason: code.vlocity_ins__ShortDescription__c, name: code.Name, id: code.Id });
                        } else if (code.ARC_Status__c == 'Pended') {
                            this.allCodes.pended.push({ reason: code.vlocity_ins__ShortDescription__c, name: code.Name, id: code.Id });
                        } else if (code.ARC_Status__c == 'Capitated') {
                            this.allCodes.capitated.push({ reason: code.vlocity_ins__ShortDescription__c, name: code.Name, id: code.Id });
                        } else if (code.ARC_Status__c == 'Adjustment') {
                            this.allCodes.adjustment.push({ reason: code.vlocity_ins__ShortDescription__c, name: code.Name, id: code.Id });
                        } else if (code.ARC_Status__c == 'Refund') {
                            this.allCodes.refund.push({ reason: code.vlocity_ins__ShortDescription__c, name: code.Name, id: code.Id });
                        } else if (code.ARC_Status__c == 'Letter') {
                            this.allCodes.letter.push({ reason: code.vlocity_ins__ShortDescription__c, name: code.Name, id: code.Id });
                        }
                    });

                }
                if (response.result.clmInfo.RecordType?.Name == 'Professional') this.profItem = true;
                if (response.result.clmInfo.RecordType?.Name == 'Institutional') this.instItem = true;
                this.nextItem = response.result.clmInfo.ARC_ItemsCounter__c + 1 + '';
                this.itemTypeId = response.result.claimItemRTypeId;
                this.clmDOSFrom = response.result.clmInfo.ARC_DOSFrom__c;
                this.clmDOSTo = response.result.clmInfo.ARC_DOSTo__c;
            })
            .then(() => {
                if (!once) this.template.querySelector('c-a-r-c_-coverage-payments-table').refreshComponent();
            })
            .catch(error => {
                console.error(error);
            })
            .finally(() => {
                this.isLoading = false;
            })
    }

    clearAllData() {
        this.allCodes = {
            'letter': [],
            'denied': [],
            'pended': [],
            'refund': [],
            'capitated': [],
            'adjustment': [],
            'informational': []
        };
        this.disCode = true;
        this.valueStatus = null;
        this.isAdjReason = false; // ?
        this.valueCPTCode = null; // ?
        this.valueCoverage = null;
        this.isMemberPayment = false;
        this.valueParticipant = null;
        this.isCreateCovPayment = false;
        this.icdCodes = []; // ?
        this.cptCodes = []; // ?
        this.optionsCode = [];
        this.arrToFilter = [];
        this.valueCodeType = []; // ?
        this.reasonCodeList = [];
        this.template.querySelector('c-a-r-c_-coverage-payments-table').refreshRows();
        this.modItems = [];
        this.rowsSelected = [];
        this.loadingItemCreation = false;
        this.getApexData();
    }

    closeModal() {
        this.modalpopup = false;
        this.moveBack = true;
        this.onlyone = false;
        // eval("$A.get('e.force:refreshView').fire();");
    }

    displayMessage(title, variant) {
        const evt = new ShowToastEvent({
            title: title,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}