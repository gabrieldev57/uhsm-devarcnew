import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getMemberHeader from '@salesforce/apex/ARC_memberHeaderComponentController.getMemberHeader';
import revealSsn from '@salesforce/apex/ARC_memberHeaderComponentController.revealSsn';
import sendEnrollmentLinkEmail from '@salesforce/apex/ARC_SendEnrollmentLink360Controller.sendEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class aRC_memberHeaderComponent extends NavigationMixin(LightningElement) {
    @api recordId;

    @track member;
    @track displayedSsn;
    @track isSsnVisible = false;
    @track isLoading = false;
    @track showEnrollmentConfirmModal = false;
    @track isSendingEnrollmentLink = false;

    @wire(getMemberHeader, { accountId: '$recordId' })
    wiredMember({ data, error }) {
        if (data) {
            this.member = data;
            this.displayedSsn = data.maskedSsn;
            this.isSsnVisible = false;
        } else if (error) {
            this.member = null;
            this.displayedSsn = null;
            this.isSsnVisible = false;
            this.showToast('Error', this.reduceError(error), 'error');
        }
    }

    get hasMember() {
        return !!this.member;
    }

    get relationshipClass() {
        const value = (this.member?.relationship || '').toLowerCase();

        if (value === 'primary' || value === 'employee') {
            return 'pill relationship-pill primary';
        }
        if (value === 'spouse') {
            return 'pill relationship-pill spouse';
        }
        if (value === 'child') {
            return 'pill relationship-pill child';
        }

        return 'pill relationship-pill';
    }

    get statusClass() {
        return this.member?.isActive === true
            ? 'pill status-pill active'
            : 'pill status-pill inactive';
    }

    get safeStatus() {
        return this.member?.isActive === true ? 'Active' : 'Inactive';
    }

    get ssnToggleLabel() {
        return this.isSsnVisible ? 'HIDE' : 'SHOW';
    }

    get safeFullName() {
        return this.member?.fullName || '—';
    }

    get safeRelationship() {
        return this.member?.relationship || 'Primary';
    }

    get safeMemberId() {
        return this.member?.memberId || '—';
    }

    get safePhone() {
        return this.member?.phone || '—';
    }

    get safeEmail() {
        return this.member?.email || '—';
    }

    get safeAddress() {
        return this.member?.address || '—';
    }

    get safeDob() {
        return this.member?.dateOfBirth || '—';
    }

    get safeAge() {
        return this.member?.age !== null && this.member?.age !== undefined
            ? this.member.age
            : '—';
    }

    get safeGender() {
        return this.member?.gender || '—';
    }

    get safeSsn() {
        return this.displayedSsn || '—';
    }

    get enrollmentConfirmationMessage() {
        return `An enrollment link will be sent to ${this.safeFullName} at ${this.safeEmail}. Do you want to proceed?`;
    }

    get isConfirmEnrollmentDisabled() {
        return this.isSendingEnrollmentLink;
    }

    async handleToggleSsn() {
        if (!this.member?.hasSsn) {
            return;
        }

        if (this.isSsnVisible) {
            this.displayedSsn = this.member.maskedSsn;
            this.isSsnVisible = false;
            return;
        }

        try {
            this.isLoading = true;
            const fullSsn = await revealSsn({ accountId: this.recordId });
            this.displayedSsn = fullSsn || this.member.maskedSsn;
            this.isSsnVisible = !!fullSsn;
        } catch (error) {
            this.showToast('Error', this.reduceError(error), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleTemporaryNewborn() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'vlocity_ins__vlocityLWCOmniWrapper' 
            },
            state: {
                'vlocity_ins__target': 'c:smallGroupAddTemporaryNewbornEnglish',
                'c__layout':'newport',
                'c__ContextId': this.recordId,
                'c__tabIcon': "utility:adduser",
                'c__tabLabel': 'Newborns'
            }
        });
    }

    handleMemberIdCard() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'vlocity_ins__vlocityLWCOmniWrapper'
            },
            state: {
                'vlocity_ins__target': 'c:ARC_MemberPortalSmallGroupEnglish',
                'c__layout': 'newport',
                'c__ContextId': this.recordId,
                'c__tabIcon': 'action:change_record_type',
                'c__tabLabel': 'Member Id Card'
            }
        });
    }

    handleHeaderMenuSelect(event) {
        const selectedValue = event.detail.value;

        if (selectedValue === 'sendEnrollmentLink') {
            this.showEnrollmentConfirmModal = true;
        }
    }

    handleCancelEnrollmentLink() {
        if (this.isSendingEnrollmentLink) {
            return;
        }

        this.showEnrollmentConfirmModal = false;
    }

    async handleConfirmEnrollmentLink() {
    try {
        this.isSendingEnrollmentLink = true;

        await sendEnrollmentLinkEmail({
            personAccountIds: [this.recordId]
        });

        this.showEnrollmentConfirmModal = false;

        this.showToast(
            'Success',
            'Email sent successfully',
            'success'
        );
    } catch (error) {
        this.showToast(
            'Error',
            this.reduceError(error) || 'Error sending email',
            'error'
        );
    } finally {
        this.isSendingEnrollmentLink = false;
    }
    }   

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((item) => item.message).join(', ');
        }

        return error?.body?.message || error?.message || 'Unknown error';
    }
}