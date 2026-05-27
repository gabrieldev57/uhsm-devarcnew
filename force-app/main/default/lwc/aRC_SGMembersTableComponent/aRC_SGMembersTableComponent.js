import { LightningElement, api, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import calculateDatesPerMemberAndProgram from '@salesforce/apex/ARC_CalculateMemberTableStartEndDates.calculateDatesPerMemberAndProgram';
import { NavigationMixin } from 'lightning/navigation';
import resizableColumns from '@salesforce/resourceUrl/resizableColumns';

export default class ARC_SGMembersTableComponent extends NavigationMixin(LightningElement) {

    @api recordId;
    @track activeMemberList = [];
    @track inactiveMemberList = [];
    //@track displayInactiveSection = false;
    isLoading = true;

    navigateToRecordPage(event) {
        event.preventDefault();
        const recordId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        });
    }

    async connectedCallback() {
        await this.updateActiveInactiveDates();
    }

    async updateActiveInactiveDates() {
        this.isLoading = true;
        
        this.activeMemberList = [];
        this.inactiveMemberList = [];

        try {
            const data = await calculateDatesPerMemberAndProgram({ idFromMember: this.recordId });
            
            let today = new Date();
            let yyyy = today.getFullYear();
            let mm = String(today.getMonth() + 1).padStart(2, '0');
            let dd = String(today.getDate()).padStart(2, '0');
            let todayStr = `${yyyy}-${mm}-${dd}`; 

            for (let property in data[0]) {
                let memberInfo = new Object();
                let coverageList = data[0][property];

                if (!coverageList || coverageList.length === 0) continue;

                let accountNode = coverageList[0]?.ARC_PolicyParticipant__r?.PrimaryParticipantContact?.Account;
                if (!accountNode) {
                    continue; 
                }
                
                memberInfo.memberId = accountNode.Id; 
                memberInfo.Id = accountNode.Id;
                memberInfo.FullName = accountNode.Name;
                memberInfo.Email = accountNode.PersonEmail;
               
                let rawSSN = accountNode.vlocity_ins__SocialSecurityNumber__pc;
                memberInfo.SSN = rawSSN ? '···· ' + rawSSN.slice(-4) : '—';
                
                memberInfo.DOB = accountNode.PersonBirthdate || '—';
                memberInfo.Age = accountNode.vlocity_ins__Age__pc || '—';
                memberInfo.Relationship = accountNode.ARC_DependentRelationship__c;
                
                memberInfo.isActive = false; 

                /* PLANS */
                let plans = [];
                
                coverageList.forEach(plan => {
                    let planInfo = new Object();
                    planInfo.planId = plan.Id; 
                    planInfo.PlanName = plan.ARC_CoverageName__c;        
                    planInfo.CoveragePrimaryMember = plan.ARC_PolicyCoverage__r?.ARC_CoveragePrimaryMember__r?.Name || '—';                

                    let ActiveDate = data[1][plan.Id];
                    let InActiveDate = data[2][plan.Id];
                  
                    const options = { year: 'numeric', month: '2-digit', day: '2-digit', timeZone: 'UTC' };
                    var formatter = new Intl.DateTimeFormat('en-US', options);
                
                    let formattedActiveDate = '—';
                    let hasValidStart = /^\d{4}-\d{2}-\d{2}$/.test(ActiveDate);
                    if (hasValidStart) {
                        var originalActiveDate = new Date(ActiveDate);
                        var formattedDateA = formatter.format(originalActiveDate);
                        var ActivedateParts = formattedDateA.split(',')[0].split('/');
                        formattedActiveDate = ActivedateParts[0] + '-' + ActivedateParts[1] + '-' + ActivedateParts[2];
                    }
                    
                    let formattedInactiveDate = '—';
                    let hasValidEnd = /^\d{4}-\d{2}-\d{2}$/.test(InActiveDate);
                    if (hasValidEnd) {
                        var originalInactiveDate = new Date(InActiveDate);
                        var formattedDateI = formatter.format(originalInactiveDate);
                        var InActivedateParts = formattedDateI.split(',')[0].split('/');
                        formattedInactiveDate = InActivedateParts[0] + '-' + InActivedateParts[1] + '-' + InActivedateParts[2];   
                    }

                    planInfo.MemberStartDate = formattedActiveDate;  
                    planInfo.MemberEndDate = formattedInactiveDate;
                   
                    let isActiveBasedOnDates = false;

                    if (hasValidStart && todayStr >= ActiveDate) {
                        if (hasValidEnd) {
                            if (todayStr <= InActiveDate) {
                                isActiveBasedOnDates = true;
                            }
                        } else {
                            isActiveBasedOnDates = true;
                        }
                    }

                    planInfo.isActivePlan = isActiveBasedOnDates;
                    
                    planInfo.status = planInfo.isActivePlan ? 'Active' : 'Inactive';
                    planInfo.statusClass = planInfo.isActivePlan ? 'active-dot' : 'inactive-dot';
                    
                    if (planInfo.isActivePlan === true) {
                        memberInfo.isActive = true;
                    }

                    plans.push(planInfo);
                });

                plans.sort((a, b) => {
                    return (a.isActivePlan === b.isActivePlan) ? 0 : a.isActivePlan ? -1 : 1;
                });

                memberInfo.plans = plans;

                if (memberInfo.isActive === true) {
                    this.activeMemberList.push(memberInfo);
                } else {
                    this.inactiveMemberList.push(memberInfo);
                }
            }

            const roleWeights = {
                'Primary': 1,
                'Spouse': 2,
                'Child': 3
            };

            const sortMembersByRole = (a, b) => {
                const weightA = roleWeights[a.Relationship] || 99;
                const weightB = roleWeights[b.Relationship] || 99;
                return weightA - weightB;
            };

            this.activeMemberList.sort(sortMembersByRole);
            this.inactiveMemberList.sort(sortMembersByRole);
            
            /*if (this.inactiveMemberList.length > 0) {
                this.displayInactiveSection = true;
            }*/
        } catch (error) {
            console.error('Error fetching data: ', error);
        } finally {
            this.isLoading = false;
        }
    }

    async renderedCallback(){
        try {
            await loadScript(this, resizableColumns + '/jquery.min.js');
            await loadScript(this, resizableColumns + '/jquery.resizableColumns.js');
            await loadStyle(this, resizableColumns + '/resizableColumns.css');
           
            if(this.template.querySelector('.resizable-active-table')) {
                $(this.template.querySelector('.resizable-active-table')).resizableColumns();
            }
        } catch(e) {
            console.error('Error loading scripts', e);
        }
    }

    get hasMembers() {
        return this.activeMemberList.length > 0 || this.inactiveMemberList.length > 0;
    }
    get hasActiveMembers() {
        return this.activeMemberList.length > 0;
    }
    get hasInactiveMembers() {
        return this.inactiveMemberList.length > 0;
    }
}