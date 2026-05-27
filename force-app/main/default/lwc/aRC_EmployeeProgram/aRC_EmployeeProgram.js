import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getProgramsWithMembers from '@salesforce/apex/ARC_EmployeesDetailController.getProgramsWithMembers';

export default class Arc_EmployeesProgram extends NavigationMixin(LightningElement) {
    @api recordId;
    @track programs = [];
    @track isLoading = true;

    @wire(getProgramsWithMembers, { accountId: '$recordId' })
    wiredPrograms({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.programs = data.map(p => ({
                ...p,
                EffectiveDateFormatted: this.formatDate(p.EffectiveDate)
            }));
        } else if (error) {
            console.error('Error fetching programs:', error);
            this.programs = [];
        }
    }

    handleMemberIdCard(event) {
        const coverageToken = event.currentTarget.dataset.coverageToken;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'MemberCardId__c'
            },
            state: {
                c__ContextId: this.recordId,
                c__CoverageToken: coverageToken
            }
        });
    }

    get hasPrograms() {
        return this.programs && this.programs.length > 0;
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const [year, month, day] = String(dateStr).split('-');
        if (!year || !month || !day) return dateStr;
        return `${month}-${day}-${year}`;
    }
}