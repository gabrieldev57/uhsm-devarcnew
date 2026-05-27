import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import STATUS_FIELD from '@salesforce/schema/Quote.Status';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'; 
import getQuoteContext from '@salesforce/apex/ARC_QuoteAcceptedProductsController.getQuoteContext';
import getQuoteLineItems from '@salesforce/apex/ARC_QuoteAcceptedProductsController.getQuoteLineItems';
import canEditQLIOnAcceptedQuote from '@salesforce/apex/ARC_QuoteAcceptedProductsController.canEditQLIOnAcceptedQuote';
import handleSave  from '@salesforce/apex/ARC_QuoteAcceptedProductsController.handleSave';
import getActiveContractProductIds from '@salesforce/apex/ARC_QuoteAcceptedProductsController.getActiveContractProductIds';


export default class aRC_AcceptedQLI extends LightningElement {
    @api recordId;

    isModalOpen = false;
    isLoading = false;

    quoteLineItems = [];
    eligibleOptions = [
        { label: 'Selected', value: 'Selected' },
        { label: 'Declined', value: 'Declined' },
        { label: 'Pending', value: 'Pending' }
    ];

    contractProductsLoaded = false;
    activeContractProductIds = new Set();
    isSmallGroupOrRenewal = false;
    quoteStatus;
    canEdit = false;
    cannotEditQLI = false;
    permissionLoaded = false;
    quoteLoaded = false;
    isRenewal = false;

    isEditing = false;
    hasChanges = false;

    connectedCallback() {
        this.checkPermission();
    }

    checkPermission() {
        canEditQLIOnAcceptedQuote()
            .then(result => {
                this.canEdit = result;
                this.permissionLoaded = true;
                this.evaluateEditAccess();
            })
            .catch(() => {
                this.canEdit = false;
                this.permissionLoaded = true;
                this.evaluateEditAccess();
            });
    }

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD] })
    wiredQuoteStatus({ data }) {
        if (data) {
 
            const newStatus = data.fields.Status.value;
            if (
                this.previousQuoteStatus &&
                this.previousQuoteStatus !== 'Accepted' &&
                newStatus === 'Accepted'
            ) {
                // this.showToast(
                //     'Warning',
                //     'This action cannot be undone once the Quote is moved to Accepted status.',
                //     'warning'
                // );
            }
 
            this.previousQuoteStatus = newStatus;
            this.quoteStatus = newStatus;
 
            this.quoteLoaded = true;
            this.evaluateEditAccess();
        }
    }

    @wire(getQuoteContext, { quoteId: '$recordId' })
    wiredQuoteContext({ data }) {
        if (data) {
            const devName = data?.Opportunity?.RecordType?.DeveloperName;
            this.isSmallGroupOrRenewal = 
                devName === 'ARC_SmallGroup' || devName === 'ARC_Renewal';
            this.isRenewal = devName === 'ARC_Renewal';

            if (this.isSmallGroupOrRenewal && this.contractProductsLoaded) {
                this.loadQLIs();
            }
        }
    }
    
    @wire(getActiveContractProductIds, { quoteId: '$recordId' })
    wiredContractProducts({ data, error }) {
        if (data) {
            this.activeContractProductIds = new Set(data);
        }
        this.contractProductsLoaded = true;

        if (this.isSmallGroupOrRenewal) {
            this.loadQLIs();
        }
    }

    autoSaveRenewalDefaults() {
        const itemsToSave = this.quoteLineItems.filter(item => 
            !item.eligibleStatus || item.eligibleStatus === 'Pending'
        );
    
        if (itemsToSave.length === 0) return;
        const payload = itemsToSave.map(item => ({
            Id: item.id,
            QuoteId: this.recordId,
            Product2Id: item.product2Id,
            ARC_EligibleForContract__c: item.eligibleStatus === 'Pending' ? 'Selected' : item.eligibleStatus
        }));

        handleSave({ qlis: payload })
            .then(() => {
               
            })
            .catch(() => {
                this.showToast('Warning', 'Could not pre-save product selections. Please click Save Products before accepting the quote.', 'warning');
            });
    }

    evaluateEditAccess() {
        if (!this.permissionLoaded || !this.quoteLoaded) return;
        this.cannotEditQLI = (this.quoteStatus === 'Accepted' && !this.canEdit);
        if (this.cannotEditQLI) {
            this.isEditing = false;
            this.hasChanges = false;
        }
    }

    get isInputsDisabled() {
        return !this.isEditing || this.cannotEditQLI;
    }

    get isSaveDisabled() {
    return this.cannotEditQLI || this.isLoading;
    }
    get isEditDisabled() {
    return this.cannotEditQLI || this.isLoading;
    }
    
    get editLabel() {
    return this.isEditing ? 'Cancel Edit' : 'Edit Products';
    }

    getStatusIcon(status) {
    switch (status) {
        case 'Selected':
            return 'utility:check';
        case 'Declined':
            return 'utility:close';
        default:
            return 'utility:record';
    }
}

    getStatusIconClass(status) {
        switch (status) {
            case 'Selected':
                return 'status-icon status-icon--selected';
            case 'Declined':
                return 'status-icon status-icon--declined';
            default:
                return 'status-icon status-icon--pending';
        }
    }

    getStatusIconVariant(status) {
        switch (status) {
            case 'Selected':
            case 'Declined':
                return 'inverse';
            default:
                return 'base';
        }
    }

    /* ------------------ DATA ------------------ */
    loadQLIs() {
        this.isLoading = true;
        getQuoteLineItems({ quoteId: this.recordId })
            .then(result => {
           
                const getProductOrder = (name) => {
                if (!name) return 999;
 
                const lower = name.toLowerCase();
 
                if (lower.includes('essential')) return 1;
                if (lower.includes('enhanced')) return 2;
                if (lower.includes('premier')) return 3;
                if (lower.includes('senior')) return 4;
 
                return 999;
            };
 
                this.quoteLineItems = result
                    .map(qli => {

                        const hasSavedStatus = qli.ARC_EligibleForContract__c && qli.ARC_EligibleForContract__c !== 'Pending';
                        const isCurrentProduct = this.isRenewal && this.activeContractProductIds.has(qli.Product2Id);
                        let finalStatus;
                        if (this.isEditing && hasSavedStatus) {
                            finalStatus = qli.ARC_EligibleForContract__c;
                        } 
                        else if (!this.isEditing && this.isRenewal) {
                            finalStatus = isCurrentProduct ? 'Selected' : 'Pending';
                        }
                        else {
                            finalStatus = qli.ARC_EligibleForContract__c || 'Pending';
                        }
                        if (this.isRenewal && hasSavedStatus && !this.isEditing) {
                            finalStatus = qli.ARC_EligibleForContract__c;
                        }

                        const showCurrentBadge = this.isRenewal && 
                                             isCurrentProduct  && 
                                             finalStatus === 'Selected';

                        return {
                            id: qli.Id,
                            productName: qli.Product2?.Name || 'Unnamed Product',
                            product2Id: qli.Product2Id,
                            lineItemNumber: qli.LineNumber,
                            eligibleStatus: finalStatus,
                            statusIcon: this.getStatusIcon(finalStatus),
                            statusIconClass: this.getStatusIconClass(finalStatus),
                            statusIconVariant: this.getStatusIconVariant(finalStatus),
                            isCurrentProduct: showCurrentBadge
                        };
                        // const status = qli.ARC_EligibleForContract__c || 'Pending';
                        // return {
                        //     id: qli.Id,
                        //     productName: qli.Product2?.Name || 'Unnamed Product',
                        //     product2Id: qli.Product2Id,
                        //     lineItemNumber: qli.LineNumber,
                        //     eligibleStatus: status,
                        //     statusIcon: this.getStatusIcon(status),
                        //     statusIconClass: this.getStatusIconClass(status),
                        //     statusIconVariant: this.getStatusIconVariant(status)
                            
                        // };
                    })
                    .sort((a, b) => {
 
                const orderA = getProductOrder(a.productName);
                const orderB = getProductOrder(b.productName);
 
                if (orderA === orderB) {
 
                    const getPlanNumber = (name) => {
                        const match = name?.match(/(\d+)k/i);
                        return match ? parseInt(match[1], 10) : 0;
                    };
 
                    const numA = getPlanNumber(a.productName);
                    const numB = getPlanNumber(b.productName);
 
                    return numA - numB;
                }
 
                return orderA - orderB;
            });
            
            
                this.isEditing = false;
                this.hasChanges = false;

                 if (this.isRenewal && !this.hasExistingSelections(result)) {
                    this.autoSaveRenewalDefaults();
                }
            })
            .catch(error => {
                this.showToast('Error', 'Could not load products. Please try again.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    hasExistingSelections(quoteLineItems) {
        return quoteLineItems.some(item => 
            item.ARC_EligibleForContract__c && 
            item.ARC_EligibleForContract__c !== 'Pending'
        );
    }

    handleEdit() {
        if (this.cannotEditQLI) {
            this.showToast(
                'Action denied',
                'You do not have permission to modify products on an Accepted Quote.',
                'error'
            );
            return;
        }
        if (this.isEditing) {
            this.loadQLIs(); 
        } else {
            this.isEditing = true;
            this.hasChanges = false;
        }
    }

    handleStatusChange(event) {
        if (this.isInputsDisabled) return;

        const qliId = event.currentTarget.dataset.id;
        const value = event.detail.value;

        let changed = false;

        this.quoteLineItems = this.quoteLineItems.map(item => {
            if (item.id === qliId) {
                if (item.eligibleStatus !== value) changed = true;

                const isProductInActiveContract = this.activeContractProductIds.has(item.product2Id);
                const showCurrentBadge = this.isRenewal && 
                                        isProductInActiveContract && 
                                        value === 'Selected';

                return {
                    ...item,
                    eligibleStatus: value,
                    statusIcon: this.getStatusIcon(value),
                    statusIconClass: this.getStatusIconClass(value),
                    statusIconVariant: this.getStatusIconVariant(value),
                    isCurrentProduct: showCurrentBadge
                };
            }
            return item;
        });

        if (changed) this.hasChanges = true;
    }

    /* ------------------ TOAST METHODS ------------------ */
    showToast(title, message, variant, duration = 5000) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(toastEvent);
    }

   handleSave() {
    if (this.cannotEditQLI) {
        this.showToast(
            'Action denied',
            'You do not have permission to modify products on an Accepted Quote.',
            'error'
        );
        return;
    }

    this.isLoading = true;

    const payload = this.quoteLineItems.map(item => ({
        Id: item.id,
        QuoteId: this.recordId,
        Product2Id: item.product2Id,
        ARC_EligibleForContract__c: item.eligibleStatus
    }));

    handleSave({ qlis: payload })
        .then(result => {
            if (result?.success) {
                this.showToast('Success', 'Products saved successfully', 'success');

                if (result.hasDeletedContributions) {
                    this.showToast('Information', result.message, 'info', 7000);
                }
            } else {
                this.showToast('Error', result?.message || 'Failed to update contract', 'error');
            }

            this.loadQLIs();
        })
        .catch(error => {
            this.showToast('Error', error?.body?.message || 'Failed to save products', 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
}

}