import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getPoliciesfromContracts from '@salesforce/apex/ARC_DashboardController.getPoliciesfromContracts';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';

const USER_FIELDS = ['User.Profile.Name'];

export default class ARC_Dashboard extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showAddNewEmployeeModal = false;

    userProfile;
    activePolicies = 0;
    inProgressPolicies = 0;
    awaitingActivationPolicies = 0;
    coverageWaived = 0;
    pendingEnrollment = 0;
    upcomingTerminations = 0;
    upcomingPaymentAmount = 0;
    coveragePaidThrough = null;
    finalOutstandingBalance = 0;

    _wiredPoliciesResult;

    connectedCallback() {
        if (this._wiredPoliciesResult) {
            refreshApex(this._wiredPoliciesResult);
        }
    }

    @wire(getRecord, { recordId: USER_ID, fields: USER_FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            this.userProfile = data.fields.Profile.value.fields.Name.value;
            console.log('User Profile => ', this.userProfile);
        } else if (error) {
            console.error('Error loading user profile:', error);
        }
    }

    get canEdit() {
        return this.userProfile === 'Employer Admin';
    }

    @wire(getPoliciesfromContracts)
    wiredCounts(result) {
        this._wiredPoliciesResult = result;
        const { error, data } = result;
        if (data) {
            this.activePolicies = data.activePoliciesCount;
            this.inProgressPolicies = data.inProgressPoliciesCount;
            this.awaitingActivationPolicies = data.awaitingActivationPoliciesCount;
            this.coverageWaived = data.coverageWaivedAccountsCount;
            this.pendingEnrollment = data.pendingEnrollmentMembersCount;
            this.upcomingTerminations = data.upcomingTerminationPoliciesCount;
            this.upcomingPaymentAmount = data.upcomingPaymentAmount;
            this.coveragePaidThrough = data.coveragePaidThrough;
            this.finalOutstandingBalance = data.finalOutstandingBalance;
            console.log('Dashboard Counts => ', JSON.parse(JSON.stringify(data)));
        } else if (error) {
            console.error(error);
        }
    }

    handleAddEmployeeClick() {
        this.showAddNewEmployeeModal = true;
        console.log('Add New Employee clicked');
    }

    handleReviewPendingClick() {
        console.log('Review Pending clicked');
        sessionStorage.setItem('employeeStatusFilter', 'Pending Enrollment');
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'Employees__c', url: '/employees' },
        });
    }

    handleViewReportsClick() {
        console.log('View Reports clicked');
    }

    handleExistingLwcClose() {
        this.showAddNewEmployeeModal = false;
        refreshApex(this._wiredPoliciesResult);
    }
}