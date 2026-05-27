import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import checkEnrollmentPermission from '@salesforce/apex/ARC_SendEnrollmentLinkPortalController.checkEnrollmentPermission';
import getDownloadableData  from '@salesforce/apex/ARC_EmployeesDetailController.getDownloadableData'
import getActiveQLEs from '@salesforce/apex/ARC_EmployeesDetailController.getActiveQLEs';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
const FIELDS = [
    'Account.Name',
    'Account.PersonTitle',
    'Account.IsActive',
    'Account.PersonContactId',
    'Account.Census_Member__c',
    'Account.ARC_AllowEnrollmentOutsideOE__c'
];

export default class ARC_EmployeesDetailPage extends NavigationMixin(LightningElement) {
    @api recordId;

    accountName;
    accountRole;
    accountIsActive;
    accountContactId;
    accountCensusMember;
    accountAllowEnrollmentOutsideOE;
    error;
    @track activeQLEs = [];
    @track userProfile;
    @track showModalChild = false;
    isDropdownOpen = false;
    @track showQLEModal = false;
    @track showLOAModal = false;
    @track employeesDownloadable;

    isTerminateFlowOpen = false;
    terminateFlowInputs = [];
    @track flowInputs = [];

    @api openModal(inputs) {
        if (this.showModalChild) {
            console.log('Modal already open, skipping...');
            return;
        }
        this.flowInputs = inputs;
        this.showModalChild = true;
    
        const modal = this.template.querySelector('c-a-r-c_-send-enrollment-link-modal');
        if(modal && !modal.isOpen){
            modal.openModal(this.flowInputs);
        }
    }

    @api
    closeModal() {
        this.showModalChild = false;
        this.flowInputs = [];
        this.dispatchEvent(new CustomEvent('close'));
    }

    @wire(CurrentPageReference)
    getPageRef(pageRef) {
        console.log('pageRef state:', JSON.stringify(pageRef?.state));
        if (pageRef && pageRef.attributes?.recordId) {
            const newRecordId = pageRef.attributes.recordId;
            if (this.recordId !== newRecordId) {
                this.recordId = newRecordId;
            }
        }
        if (pageRef?.state?.c__isPendingEnrollment !== undefined) {
            this.isPendingEnrollment = pageRef.state.c__isPendingEnrollment === 'true';
        }
    }

    loadQLEs() {
        // getActiveQLEs({ accountId: this.recordId })
        //     .then(activeQLEList => { this.activeQLEs = activeQLEList; })
        //     .catch(() => { this.activeQLEs = []; });
        getActiveQLEs({ accountId: this.recordId })
        .then(activeQLEList => {
            console.log('QLEs result ==>', JSON.stringify(activeQLEList));
            this.activeQLEs = [...activeQLEList];
        })
        .catch(err => {
            console.error('QLEs error ==>', err);
            this.activeQLEs = [];
        });
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountName = data.fields.Name.value;
            this.accountRole = data.fields.PersonTitle.value;
            this.accountIsActive = data.fields.IsActive.value;
            this.accountContactId = data.fields.PersonContactId.value;
            this.accountCensusMember = data.fields.Census_Member__c.value;
            this.accountAllowEnrollmentOutsideOE = data.fields.ARC_AllowEnrollmentOutsideOE__c.value;
            this.error = undefined;
            this.loadQLEs();
        } else if (error) {
            this.error = error;
            this.accountName = undefined;
            this.accountRole = undefined;
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



    get canEdit() {
        return this.userProfile === 'Employer Admin';
    }

    get dropdownMenuClass() {
        return `dropdown-menu ${this.isDropdownOpen ? 'show' : ''}`;
    }

    get canSendEnrollmentLink() {
        return this.canEdit && (this.isPendingEnrollment || this.accountAllowEnrollmentOutsideOE);
    }

    toggleDropdown() {
        this.isDropdownOpen = !this.isDropdownOpen;
    }

    handleActionClick(event) {
        const action = event.currentTarget.dataset.action;
        console.log('Action clicked:', action);

        switch(action) {
            case 'qualifying-life':
                this.handleQualifyingLife();
                break;
            // case 'brochure':
            //     this.handleDownloadBrochure();
            //     break;
            // case 'guide':
            //     this.handleDownloadGuide();
            //     break;
            case 'enrollment':
                this.handleEnrollmentDetails();
                break;
            case 'member-id':
                this.handleMemberIdCard();
                break;
            case 'terminate':
                this.handleTerminateBenefits();
                break;
            case 'enrollment-link':
                this.handleSelfEnrollmentLink();
                break;
            case 'leave-absence':
                this.handleLeaveOfAbsence();
                break;
        }
        this.isDropdownOpen = false;
    }

    handleSelfEnrollmentLink() {
        console.log('LWC: Send Enrollment Link clicked for recordId=', this.recordId);

        const personIds  = [this.recordId];

        checkEnrollmentPermission({ personIds : personIds })
            .then(hasAccess => {
                if (!hasAccess) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Access Denied',
                            message: 'You do not have access to run this flow.',
                            variant: 'error'
                        })
                    );
                    return;
                }
                // this.openModal([{ name: 'personIds', type: 'String', value: personIds }]);
                this.openModal([{ name: 'personIds', type: 'String', value: personIds  }]);
                
                
            })
            .catch(error => {
                console.log('LWC: Error from Apex:', error);
                const message = error?.body?.message || 'Unknown error';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Access Denied',
                        message: message,
                        variant: 'error'
                    })
                );
            });
    }

    handleModalClose() {
        console.log('Employee Detail Modal closed');
        this.flowInputs = [];
    }

    handleQualifyingLife() {
        console.log('Opening QLE Flow for recordId:', this.recordId);
        this.showQLEModal = true;
    }

    handleQLEClose() {
        this.showQLEModal = false;
        this.loadQLEs();
    }

    handleLeaveOfAbsence(){
        this.showLOAModal = true;
    }
    
    handleLOAClose() {
        this.showLOAModal = false;
        const policyLOA = this.template.querySelector('c-a-r-c_-policy-l-o-a');
        if (policyLOA) {
            policyLOA.refresh();
        }
    }

    // handleLOAClose(){
    //     this.showLOAModal = false;
    // }

    // handleDownloadBrochure() { }

    // handleDownloadGuide() { }

    formatCsvValue(value, key) {
        if (value === null || value === undefined) {
            return '""';
        }

        let stringValue = String(value);

        if (key === 'Phone') {
            stringValue = '\t' + stringValue;
        }

        stringValue = stringValue.replace(/"/g, '""');

        return `"${stringValue}"`;
    }

    handleEnrollmentDetails() { 
        console.log('This is the Record Id ===> ', this.recordId)

        const columns = [
            { label: 'First Name', key: 'FirstName' },
            { label: 'Middle Name', key: 'MiddleName' },
            { label: 'Last Name', key: 'LastName' },
            { label: 'Division', key: 'Division' },
            { label: 'Social Security Number', key: 'SSN' },
            { label: 'DOB', key: 'DOB' },
            { label: 'Hire Date', key: 'HireDate' },
            { label: 'Termination Date', key: 'TerminationDate' },
            { label: 'Job Title', key: 'JobTitle' },
            { label: 'Address 1', key: 'Street' },
            { label: 'City', key: 'City' },
            { label: 'State', key: 'State' },
            { label: 'ZIP', key: 'ZIP' },
            { label: 'Country', key: 'Country' },
            { label: 'Phone', key: 'Phone' },
            { label: 'Personal Email', key: 'PersonEmail' },
            { label: 'Payment Period', key: 'PayPeriod' },
            { label: 'Program', key: 'Program' },
            { label: 'Enrollment Status', key: 'EnrollmentStatus' },
            { label: 'Relationship', key: 'Relationship' },
            { label: 'EECost', key: 'EECost' },
            { label: 'ERCost', key: 'ERCost' },
            { label: 'Monthly Amount', key: 'MonthlyAmount' },
            { label: 'Member Start Date', key: 'MemberStartDate' },
            { label: 'Member End Date', key: 'MemberEndDate' }
        ];
        
        let csv = columns.map(col => col.label).join(',') + '\n';

        console.log('Before getDownloadableData')

        getDownloadableData({ accountId: this.recordId })
            .then(result => {
                console.log('Downloadable Data:', result);
                this.employeesDownloadable = result;

                this.employeesDownloadable.forEach(row => {
                    const values = columns.map(col => this.formatCsvValue(row[col.key], col.key));
                    csv += values.join(',') + '\n';
                });

                const element = document.createElement('a');
                const BOM = '\uFEFF';
                element.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(BOM + csv);
                element.download = 'Enrollment Information.csv';
                element.click();
            });
        console.log('After getDownloadableData')
    }

    handleMemberIdCard() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { 
                name: 'MemberCardId__c' 
            },
            state: { 
                c__ContextId: this.recordId 
            }
        });
    }

    handleTerminateBenefits() {
        this.terminateFlowInputs = [
            { name: 'recordId', type: 'String', value: this.recordId },
            { name: 'employeeName', type: 'String', value: this.accountName }
        ];
        this.isTerminateFlowOpen = true;
    }

    handleTerminateFlowStatus(event) {
        const status = event.detail.status;
        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            this.handleCloseModal();
            window.location.reload();
        }

        if (status === status === 'CANCELED'){
            this.handleCloseModal();
        }
    }

    handleCloseModal() {
        this.isTerminateFlowOpen = false;
    }

    handleTabChange(event) {
        if (event.detail.value === 'tab2') {
            const policyHistory = this.template.querySelector('c-a-r-c_-policy-history');
            if (policyHistory) {
                policyHistory.refresh();
            }
        }
    }

    navigateToEmployees(event) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Employees__c' }
        });
    }

    get showQLEFlag() {   
        return this.activeQLEs?.length > 0;
    }

    get qleFlowInputVariables() {
        return [
            {
                name: 'recordId', 
                type: 'String',
                value: this.recordId
            }
        ];
    }

    get loaFlowInputVariables() {
        return [
            {
                name: 'recordId', 
                type: 'String',
                value: this.recordId
            }
        ];
    }
}