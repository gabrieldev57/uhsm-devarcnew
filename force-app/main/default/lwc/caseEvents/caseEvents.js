import { LightningElement, track, wire, api } from 'lwc';
import getQLE from '@salesforce/apex/ARC_EmployeesTableController.getQLE';
import getUserAccountId from '@salesforce/apex/ARC_EmployeesTableController.getUserAccountId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import updateCases from '@salesforce/apex/ARC_EmployeesTableController.updateCases';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import aRC_ConfirmModalVoid from 'c/aRC_ConfirmModalVoid';
//import LightningConfirm from 'lightning/confirm';

export default class CaseEvents extends NavigationMixin(LightningElement) {

    data = [];
    filteredData = [];
    @track draftValues = [];
    @track selectedStatuses = ['New','Awaiting Signature', 'Pending Enrollment','In Review'];
    @track isLoading = false;
    @track accountId;
    @track currentPage = 1;
    @track pageSize = 10;
    @track searchKey = '';
    userProfile;
    // showConfirm = false;
    // caseToVoid;
    // pendingRow;

    wiredResult;

    statusOptions = [
        { label: 'New', value: 'New' },
        { label: 'Pending Enrollment', value: 'Pending Enrollment' },
        { label: 'Awaiting Signature', value: 'Awaiting Signature' },
        { label: 'In Review', value: 'In Review' },
        { label: 'Closed Rejected', value: 'Closed Rejected' }  
    ];

    editOptions = [
        { label: 'Voided', value: 'Closed Voided' }
    ];

    openStatuses = [
        'New',
        'Awaiting Signature',
        'Pending Enrollment',
        'In Review'
    ];

    columns = [
        { label: 'Case Number', fieldName: 'CaseNumber' },
        {
            label: 'Employee',
            type: 'button',
            fieldName: 'EmployeeName',
            typeAttributes: {
                label: { fieldName: 'EmployeeName' },
                name: 'navigate',
                variant: 'base'
            }
        },
        { label: 'Status', fieldName: 'Status' },
        { label: 'Event Type', fieldName: 'Type' },
        {
            label: 'Actions',
            type: 'button',
            typeAttributes: {
                label: 'Void',
                name: 'void',
                variant: 'base',
                disabled: { fieldName: 'isVoidedOrNotAdmin' },
                class: 'void-btn'
            }
        }
    ];

    @api
    refresh() {
        if (this.wiredResult) {
            return refreshApex(this.wiredResult);
        }
    }
    

    @wire(getRecord, { recordId: USER_ID, fields: ['User.Profile.Name'] })
    wiredUser({ data, error }) {
        if (data) {
            this.userProfile = data.fields.Profile.value?.fields.Name.value;
        } else if (error) {
            console.error('Error loading user profile:', error);
        }
    }

    get canVoid() {
        return this.userProfile === 'Employer Admin';
    }

    connectedCallback() {
        if (this.wiredResult) {
            refreshApex(this.wiredResult);
        }
    }

    @wire(getUserAccountId)
    wiredAccount({ data }) {
        if (data) {
            this.accountId = data;
        }
    }

    @wire(getQLE, { accountId: '$accountId' })
    wiredCases(result) {
        this.wiredResult = result;

        if (result.data) {
            this.data = result.data.map(row => {
                const isOpen = this.openStatuses.includes(row.Status);
                return {
                    ...row,
                    EmployeeName: row.ARC_PersonAccount__r?.Name ?? '',
                    Status: row.Status,
                    CaseNumber: row.CaseNumber,
                    Type: row.ARC_QLEType__c,
                    personAccountId: row.ARC_PersonAccount__c,
                    isEditable: isOpen,
                    isOpen: isOpen 
                };
            });
            this._updateFilteredData();
        } else if (result.error) {
            this.error = result.error;
            console.error('QLE error', result.error);
        }
    }

    get processedData() {
        return this.filteredData.map(row => ({
            ...row,
            isVoidedOrNotAdmin: !row.isOpen || !this.canVoid
        }));
    }

    get processedPaginatedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = this.currentPage * this.pageSize;
        return this.filteredData.map(row => ({
            ...row,
            isVoidedOrNotAdmin: !row.isOpen || !this.canVoid
        })).slice(start, end);
    }

    get statusOptionsWithChecked() {
        return this.statusOptions.map(s => ({
            ...s,
            checked: this.selectedStatuses.includes(s.value)
        }));
    }

    _updateFilteredData() {
        let filtered = [...this.data];

        if (this.selectedStatuses?.length) {
            filtered = filtered.filter(row =>
                this.selectedStatuses.includes(row.Status)
            );
        }

        if (this.searchKey) {
            filtered = filtered.filter(row =>
                (row.CaseNumber && row.CaseNumber.toLowerCase().includes(this.searchKey)) ||
                (row.EmployeeName && row.EmployeeName.toLowerCase().includes(this.searchKey))
            );
        }

        this.filteredData = filtered;
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.currentPage = 1;
        this._updateFilteredData();
    }

    handleCheckboxChange(event) {
        const value = event.target.value;

        if (event.target.checked) {
            this.selectedStatuses = [...this.selectedStatuses, value];
        } else {
            this.selectedStatuses = this.selectedStatuses.filter(s => s !== value);
        }

        this.currentPage = 1;
        this._updateFilteredData();
    }

    get paginatedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = this.currentPage * this.pageSize;
        return this.filteredData.slice(start, end);
    }

    get totalCount() {
    return this.filteredData.length;
}

    get totalPages() {
        return Math.ceil(this.filteredData.length / this.pageSize) || 1;
    }

    get isPreviousDisabled() {
        return this.currentPage <= 1;
    }

    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }

    get showingFrom() {
        return this.filteredData.length === 0
            ? 0
            : (this.currentPage - 1) * this.pageSize + 1;
    }

    get showingTo() {
        const to = this.currentPage * this.pageSize;
        return to > this.filteredData.length ? this.filteredData.length : to;
    }

    async openConfirmModal(row) {
        const result = await aRC_ConfirmModalVoid.open({
            size: 'small',
            label: 'Confirm Void', 
            description: 'Confirm Void',
            caseNumber: row.CaseNumber
        });

        if (result === 'confirm') {
            await this.voidCase(row);
        }
    }

    async voidCase(row) {
        if (this.isLoading) return;
        this.isLoading = true;

        try {
            await updateCases({ 
                casesToUpdate: [{ Id: row.Id, Status: 'Closed Voided' }] 
            });

            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: `Case ${row.CaseNumber} voided successfully`,
                variant: 'success'
            }));

            if (this.wiredResult) {
                await refreshApex(this.wiredResult);
            }

        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error voiding case',
                message: error?.body?.message ?? error?.message ?? 'Unknown error',
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    // handleCancelVoid() {
    //     this.showConfirm = false;
    //     this.pendingRow = null;
    //     this.caseToVoid = null;
    // }

    // async handleConfirmVoid() {
    //     this.showConfirm = false;
    //     const row = this.pendingRow;
    //     this.pendingRow = null;
    //     this.caseToVoid = null;

    //     if (this.isLoading) return;
    //     this.isLoading = true;
    //     try {
    //         await updateCases({ casesToUpdate: [{ Id: row.Id, Status: 'Closed Voided' }] });
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Success',
    //             message: `Case ${row.CaseNumber} voided successfully`,
    //             variant: 'success'
    //         }));
    //         if (this.wiredResult) await refreshApex(this.wiredResult);
    //     } catch (error) {
    //         this.dispatchEvent(new ShowToastEvent({
    //             title: 'Error voiding case',
    //             message: error?.body?.message ?? error?.message ?? 'Unknown error',
    //             variant: 'error',
    //             mode: 'sticky'
    //         }));
    //     } finally {
    //         this.isLoading = false;
    //     }
    // }

    handlePrevious() {
        if (this.currentPage > 1) this.currentPage--;
    }

    handleNext() {
        if (this.currentPage < this.totalPages) this.currentPage++;
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.target.value, 10);
        this.currentPage = 1;
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'navigate' && row.personAccountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.personAccountId,
                    objectApiName: 'Account',
                    actionName: 'view'
                }
            });
        }

        if (actionName === 'void') {
            // if (this.isLoading) return;
            // this.isLoading = true;
            // try {
            //     await updateCases({ casesToUpdate: [{ Id: row.Id, Status: 'Closed Voided' }] });
            //     this.dispatchEvent(new ShowToastEvent({
            //         title: 'Success',
            //         message: `Case ${row.CaseNumber} voided successfully`,
            //         variant: 'success'
            //     }));
            //     if (this.wiredResult) await refreshApex(this.wiredResult);
            // } catch (error) {
            //     this.dispatchEvent(new ShowToastEvent({
            //         title: 'Error voiding case',
            //         message: error?.body?.message ?? error?.message ?? 'Unknown error',
            //         variant: 'error',
            //         mode: 'sticky'
            //     }));
            // } finally {
            //     this.isLoading = false;
            // }
            await this.openConfirmModal(row);
            return;
        }
    }
}