import { LightningElement, api, wire, track } from 'lwc';
import getUserAccountId from '@salesforce/apex/ARC_EmployeesTableController.getUserAccountId';
import getPoliciesfromContracts from '@salesforce/apex/ARC_EmployeesTableController.getPoliciesfromContracts';
import getCensusDownloadableData from '@salesforce/apex/ARC_EmployeesTableController.getCensusDownloadableData';
import checkEnrollmentPermission from '@salesforce/apex/ARC_EmployeesTableController.checkEnrollmentPermission';
import isOpenEnrollmentActive from '@salesforce/apex/ARC_EmployeesTableController.isOpenEnrollmentActive';

import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';

const USER_FIELDS = ['User.Profile.Name'];

export default class ArcEmployeesTable extends NavigationMixin(LightningElement) {
    @api recordId;
    @track accountId;

    isOEActive = false;

    @track employees = [];
    @track filteredEmployees = [];
    @track paginatedEmployees = [];
    @track noCoverageWaived = [];
    @track statusFilteredEmployees = [];
    @track personAccountIds = [];
    @track employeesDownloadable = [];

    @track totalEmployeesCount = 0;
    @track pageSize = 50;
    @track currentPage = 1;
    @track searchKey = '';
    @track selectedStatusFilter = ['Active','Awaiting Activation','Awaiting Signature','Awaiting Approval', 'Pending Enrollment'];
    @track isActionsOpen = false;
    @track showCSVUploadModal = false;
    @track userProfile;
    @track isLoading = true;
    error;

    _boundOutside;

   connectedCallback() {
        console.log('from employee table:',this.accountId);
        this._boundOutside = this.handleOutsideClick.bind(this);
        document.addEventListener('click', this._boundOutside);

        if (this._wiredEmployeesResult) {
            refreshApex(this._wiredEmployeesResult);
        }

        const filterFromSession = sessionStorage.getItem('employeeStatusFilter');
        if (filterFromSession) {
            this.selectedStatusFilter = filterFromSession;
            sessionStorage.removeItem('employeeStatusFilter');
        }

        this.applyStatusFilter(this.selectedStatusFilter);
    }

    disconnectedCallback() {
        document.removeEventListener('click', this._boundOutside);
    }

    columns = [
        {
            label: 'Name',
            type: 'button',
            fieldName: 'employeeName',
            typeAttributes: { label: { fieldName: 'employeeName' }, name: 'navigate', variant: 'base' }
        },
        { label: 'Program', fieldName: 'productName', type:'text', wrapText: true},
        { label: 'Effective Date', fieldName: 'effectiveDate', type: 'text' },
        {
            label: 'Status',
            fieldName: 'status',
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'statusClass' },
                style: { fieldName: 'statusStyle' },
                alignment: 'center'
            }
        }
    ];

    statusOptions = [
        { label: 'Active', value: 'Active' },
        { label: 'Awaiting Approval', value: 'Awaiting Approval' },
        { label: 'Awaiting Activation', value: 'Awaiting Activation' },
        { label: 'Awaiting Signature', value: 'Awaiting Signature' },
        { label: 'Pending Enrollment', value: 'Pending Enrollment' },
        { label: 'Inactive', value: 'Inactive' }
    ];

    @wire(isOpenEnrollmentActive, { accountId: null })
    wiredOE({ data, error }) {
        console.log('isOEActive data:', data, 'error:', error);
        if (data !== undefined) this.isOEActive = data;
    }

    @wire(getRecord, { recordId: USER_ID, fields: USER_FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            this.userProfile = data.fields.Profile.value.fields.Name.value;
        } else if (error) {
            console.error('Error loading user profile:', error);
        }
    }

    @wire(getUserAccountId)
    wiredAccount({ data, error }) {
        if (data) {
            this.accountId = data;
        } else if (error) {
           
        }
    }

    _wiredEmployeesResult;

    @wire(getPoliciesfromContracts, { accountId: '$accountId' })
    wiredEmployees(result) {
        this._wiredEmployeesResult = result;
        const { data, error } = result;
        if (data) {
            this.isLoading = false;
            console.log('RAW Apex Data: ', JSON.parse(JSON.stringify(data)));
            this.employees = data.map(participant => {
                let productDisplay = '';

                if (Array.isArray(participant.ProductName)) {
                    productDisplay = participant.ProductName.join('\n');
                } else if (typeof participant.ProductName === 'string') {
                    productDisplay = participant.ProductName.replace(/,\s*/g, '\n');
                }

                return {
                    rowKey: participant.Id,
                    employeeName: participant.Name,
                    productName: productDisplay,
                    effectiveDate: participant.EffectiveDate ? this.formatDate(participant.EffectiveDate) : '',
                    status: participant.Status,
                    personAccountId: participant.AccountId,
                    coverageWaived: participant.CoverageWaived,
                    censusMemberId: participant.CensusMemberId,
                    statusClass: this.getStatusClass(participant.Status)
                };
            });

            this.personAccountIds = this.employees
                .filter(emp => emp.status === 'Pending Enrollment')
                .map(emp => emp.personAccountId)
                .filter(id => id);

            this.noCoverageWaived = this.employees.filter(emp => emp.coverageWaived === false);
            this.applyStatusFilter(this.selectedStatusFilter);
        } else if (error) {
            this.isLoading = false;
            this.error = error;
            console.error('Employees error', error);
        }
    }

    @wire(getCensusDownloadableData)
    wireCensusDownloadableData({ error, data }) {
        if (data) {
            this.employeesDownloadable = data.map(participant => ({
                FirstName: participant.FirstName,
                LastName: participant.LastName,
                Gender: participant.Gender,
                DOB: participant.DOB,
                Relationship: participant.Relationship,
                EmploymentType: participant.EmploymentType,
                Division: participant.Division,
                JobClass: participant.JobClass,
                EffectiveDate: participant.EffectiveDate,
                ExpirationDate: participant.ExpirationDate,
                Programs: participant.Programs,
                Status: participant.Status,
                PrimaryMember: participant.PrimaryMember
            }));
        } else if (error) {
            console.error('Error fetching downloadable data:', error);
        }
    }

    get isEmployerAdmin() {
        return this.userProfile === 'Employer Admin';
    }

    handleCSVUploadClose() {
        this.showCSVUploadModal = false;
    }

    async handleUploadComplete(event) {
        this.showCSVUploadModal = false;
        this.isLoading = true;
        try {
            await refreshApex(this._wiredEmployeesResult);
        } catch(e) {
            console.error('Error refreshing employees:', e);
        } finally {
            this.isLoading = false;
        }
    }

    getStatusClass(status) {
        return status === 'Active' ? 'status-cell active' : 'status-cell awaiting';
    }

    handleDownloadCensus() {
        const columns = [
            { label: 'First Name', key: 'FirstName' },
            { label: 'Last Name', key: 'LastName' },
            { label: 'Gender', key: 'Gender' },
            { label: 'DOB', key: 'DOB' },
            { label: 'Relationship', key: 'Relationship' },
            { label: 'EmploymentType', key: 'EmploymentType' },
            { label: 'Division', key: 'Division' },
            { label: 'Job Class', key: 'JobClass' },
            { label: 'Effective Date', key: 'EffectiveDate' },
            { label: 'Inactive Date', key: 'ExpirationDate' },
            { label: 'Programs', key: 'Programs' },
            { label: 'Status', key: 'Status' }
        ];

        let csv = columns.map(col => col.label).join(',') + '\n';
        this.employeesDownloadable.forEach(row => {
            const values = columns.map(col => `"${row[col.key] ?? ''}"`);
            csv += values.join(',') + '\n';
        });

        const element = document.createElement('a');
        const BOM = '\uFEFF';
        element.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(BOM + csv);
        element.download = 'Census Information.csv';
        element.click();
    }

    get actionsTriggerClass() {
        return `slds-dropdown-trigger slds-dropdown-trigger_click actions-trigger ${this.isActionsOpen ? 'slds-is-open' : ''}`;
    }

    toggleActions(event) {
        event.stopPropagation();
        this.isActionsOpen = !this.isActionsOpen;
    }

    handleOutsideClick(event) {
        const root = this.template.querySelector('.actions-trigger');
        if (this.isActionsOpen && root && !root.contains(event.target)) {
            this.isActionsOpen = false;
        }
    }

    handleActionClick(event) {
        const action = event.currentTarget.dataset.action;
        this.isActionsOpen = false;

        if (action === 'addEmployee') {
            this.openAddPrimaryCensusModal(event);
        } else if (action === 'addEmployeeCsv') {
            this.showCSVUploadModal = true;
        } else if (action === 'DownloadCensus') {
            this.handleDownloadCensus();
        } else if (action === 'sendEnrollmentToAllEmployees') {
            if (!this.personAccountIds || this.personAccountIds.length === 0) {
                console.warn('No person account IDs available to launch flow.');
                return;
            }
            checkEnrollmentPermission({ personIds: this.personAccountIds })
                .then(hasAccess => {
                    if (hasAccess) {
                        const modal = this.template.querySelector('c-a-r-c_-send-enrollment-link-modal');
                        if (modal && !modal.isOpen) {
                            modal.openModal([
                                { name: 'personIds', type: 'String', value: this.personAccountIds }
                            ]);
                        }
                    } else {
                        this.dispatchEvent(new ShowToastEvent({
                            title: 'Access Denied',
                            message: 'You do not have permission to run this flow.',
                            variant: 'error'
                        }));
                    }
                })
                .catch(error => {
                    const message = error?.body?.message || 'Unknown error occurred';
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Access Denied',
                        message: message,
                        variant: 'error'
                    }));
                });
        }
    }

    menuOpen = false;
    isAddPrimaryCensusOpen = false;

    openAddPrimaryCensusModal = (event) => {
        event?.preventDefault?.();
        this.isAddPrimaryCensusOpen = true;
    };
    
    closeAddPrimaryCensusModal = async () => {
        this.isAddPrimaryCensusOpen = false;
        this.isLoading = true;
        try {
            await refreshApex(this._wiredEmployeesResult);
        } catch(e) {
            console.error('error trying to refresh employees table:', e);
        } finally {
            this.isLoading = false;
        }
    };

    toggleMenu() {
        this.menuOpen = !this.menuOpen;
    }

    get menuClass() {
        return `menu ${this.menuOpen ? 'open' : ''}`;
    }

    get canSendEnrollmentToAll() {
        return this.isEmployerAdmin && this.isOEActive;
    }

    handleTabChange(event) {
        if (event.detail.value === 'tab2') {
            const caseEvents = this.template.querySelector('[data-id="caseEvents"]');
            if (caseEvents) {
                caseEvents.refresh();
            }
        }
    }

    handleCheckboxChange(event) {
        const value = event.target.value;
        const checked = event.target.checked;

        if (checked) {
            this.selectedStatusFilter = [...this.selectedStatusFilter, value];
        } else {
            this.selectedStatusFilter = this.selectedStatusFilter.filter(s => s !== value);
        }

        this.applyStatusFilter();
    }

    get statusOptionsWithChecked() {
        return this.statusOptions.map(status => ({
            ...status,
            checked: this.selectedStatusFilter.includes(status.value)
        }));
    }

    applyStatusFilter(filter) {
        this.currentPage = 1;

        if (!this.selectedStatusFilter || this.selectedStatusFilter.length === 0) {
            this.statusFilteredEmployees = [...this.noCoverageWaived];
        } else {
            this.statusFilteredEmployees = this.noCoverageWaived.filter(emp =>
                this.selectedStatusFilter.includes(emp.status)
            );
        }

        this.filteredEmployees = [...this.statusFilteredEmployees];
        this.updatePaginatedEmployees();
    }

    handleSearch(event) {
        const value = event.detail.value || '';
        this.searchKey = value.toLowerCase();
        this.currentPage = 1;

        if (this.searchKey) {
            this.filteredEmployees = this.statusFilteredEmployees.filter(emp =>
                emp.employeeName &&
                emp.employeeName.toLowerCase().includes(this.searchKey)
            );
        } else {
            this.filteredEmployees = [...this.statusFilteredEmployees];
        }

        this.updatePaginatedEmployees();
    }

    updatePaginatedEmployees() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.paginatedEmployees = this.filteredEmployees.slice(start, end);
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePaginatedEmployees();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePaginatedEmployees();
        }
    }

    get totalPages() {
        return Math.ceil(this.filteredEmployees.length / this.pageSize);
    }

    get isPreviousDisabled() {
        return this.currentPage <= 1;
    }

    get isNextDisabled() {
        return this.currentPage >= this.totalPages;
    }

    get showingFrom() {
        return this.filteredEmployees.length === 0
            ? 0
            : (this.currentPage - 1) * this.pageSize + 1;
    }

    get showingTo() {
        const calc = this.currentPage * this.pageSize;
        return calc > this.filteredEmployees.length ? this.filteredEmployees.length : calc;
    }

    get noRecords() {
        return Array.isArray(this.paginatedEmployees) && this.paginatedEmployees.length === 0 && !this.error;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'navigate' && row.personAccountId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.personAccountId,
                    objectApiName: 'Account',
                    actionName: 'view'
                },
                state: {
                    c__isPendingEnrollment: row.status === 'Pending Enrollment' ? 'true' : 'false'
                }
            });
        }
        console.log('Navigating with isPendingEnrollment:', row.status, row.status === 'Pending Enrollment');
    }

    handleChildModalClose() {
        console.log('Enrollment modal closed');
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const [year, month, day] = dateStr.split('-');
        if (!year || !month || !day) return dateStr;
        return `${month}-${day}-${year}`;
    }
}