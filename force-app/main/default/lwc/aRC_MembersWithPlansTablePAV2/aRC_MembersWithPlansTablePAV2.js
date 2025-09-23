import { LightningElement, api, track } from 'lwc';
import calculateDatesPerMemberAndProgram from '@salesforce/apex/ARC_UpdateActiveInactiveDatesPA.calculateDatesPerMemberAndProgram';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import resizableColumns from '@salesforce/resourceUrl/resizableColumns';
import { NavigationMixin } from 'lightning/navigation';

export default class ARC_MembersWithPlansTablePAV2 extends NavigationMixin(LightningElement) {
    @api recordId;
	@track activeMemberList = [];
    @track inactiveMemberList = [];
	@track displayInactiveSection = false;


    headers = [
		{ label: 'Name', fieldName: 'Id', type: 'url', typeAttributes: { label: { fieldName: 'FullName' } } },
		{ label: 'Plan Name', fieldName: 'PlanName', type: 'text' },
		{ label: 'Active Date', fieldName: 'MemberStartDate', type: 'text', hideDefaultActions: true },
		{ label: 'Inactive Date', fieldName: 'MemberEndDate', type: 'text', hideDefaultActions: true },
	   
		{ label: 'Relationship', fieldName: 'Relationship', type: 'text' },
		{ label: 'Email', fieldName: 'Email', type: 'Email' },
		{ label: 'SSN', fieldName: 'SSN', type: 'text' },
		{ label: 'DOB', fieldName: 'DOB', type: 'text' },
		{ label: 'Age', fieldName: 'Age', type: 'text' },
		{ label: 'Active', fieldName: 'isActive', type: 'boolean' },
        { label: 'Temporary NewBorn', fieldName: 'TemporaryNewBorn', type: 'boolean' }
	];


    navigateToRecordPage(event) {
        const recordId = event.target.dataset.id;
        console.log('recordId',recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        });
    }

    async connectedCallback() {
        await this.updateActiveInactiveDates()
    }

    async updateActiveInactiveDates() {
		/* QUERY INFO */
        const data = await calculateDatesPerMemberAndProgram({ idFromMember: this.recordId })
        console.log('data'+JSON.stringify(data));
		/* PROCESS INFO */
      
		/* MEMBERS */
        for (let property in data[0]) {
            
            let memberInfo = new Object();
            memberInfo.Id = (data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Id;
            memberInfo.FullName = (data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Name;
            if((data[0][property])[0].vlocity_ins__GroupCensusMemberId__r?.ARC_NewCensusMember__c != undefined){
            memberInfo.SpinOffId = "/"+(data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.ARC_NewCensusMember__c;
            memberInfo.SpinOffName = 'Link';
            }
            memberInfo.Email = (data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.PersonEmail;
            memberInfo.SSN = (data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.vlocity_ins__SocialSecurityNumber__pc?.slice(-4);
            memberInfo.DOB =  (data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.PersonBirthdate;
            memberInfo.Age = (data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.vlocity_ins__Age__pc;
            memberInfo.isActive = (data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.IsActive;
            memberInfo.Relationship = (data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.ARC_DependentRelationship__c;
            memberInfo.isMember = true;
            memberInfo.display = true;
            memberInfo.TemporaryNewBorn = (data[0][property])[0].vlocity_ins__GroupCensusMemberId__r.vlocity_ins__ContactId__r.Account.Temperory_Newborn__c;
			/* PLANS */
			let plans = []
            let ActiveDate=[]
            let InActiveDate=[]
            data[0][property].forEach(plan => {
                let planInfo = new Object();
                // planInfo.FullName = plan.ARC_Active__c? 'Active': null;
                planInfo.parentRowId = memberInfo.Id;
                planInfo.display = true;
                planInfo.PlanName = plan.vlocity_ins__ContractLineId__r.Name;                
                ActiveDate=data[1][plan.Id];
                InActiveDate=data[2][plan.Id];
                console.log('ActiveDate' + ActiveDate);  
                console.log('InActiveDate' + InActiveDate); 
              
                const  options = {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    timeZone: 'UTC'
                };
                 var formatter=new Intl.DateTimeFormat('en-US',options);
            
                if (/^\d{4}-\d{2}-\d{2}$/.test(ActiveDate)) {
                    // Original date in another format, e.g., YYYY-MM-DD
                    var originalActiveDate = new Date(ActiveDate);
                    var formattedDate = formatter.format(originalActiveDate);
                    console.log('formattedActiveDate :' + formattedDate); 
                    var ActivedateParts = formattedDate.split(',')[0].split('/');
                    var month = ActivedateParts[0];
                    var day = ActivedateParts[1];
                    var year = ActivedateParts[2];
                    var formattedActiveDate = month + '-' + day + '-' + year;
                    console.log('formattedActiveDate' + formattedActiveDate);
                  
                
                }else{
                    formattedActiveDate=' ';
                }
                if (/^\d{4}-\d{2}-\d{2}$/.test(InActiveDate)) {
                   
                    // Original date in another format, e.g., YYYY-MM-DD
                    var originalInactiveDate = new Date(InActiveDate);
                    var formattedDate = formatter.format(originalInactiveDate);
                    console.log('formattedInActiveDate :' + formattedDate); 
                    var InActivedateParts = formattedDate.split(',')[0].split('/');
                    var month = InActivedateParts[0];
                    var day = InActivedateParts[1];
                    var year = InActivedateParts[2];
                    var formattedInactiveDate = month + '-' + day + '-' + year;
                    console.log('formattedInActiveDate' + formattedInactiveDate);   
                }
                else{
                    formattedInactiveDate=' ';
                }
                planInfo.MemberStartDate = formattedActiveDate;  
                planInfo.MemberEndDate = formattedInactiveDate;
               
                planInfo.isActivePlan = plan.ARC_Active__c;
                planInfo.activeClass = planInfo.isActivePlan ? 'activePlan' : '';
                plans.push(planInfo);
            });

			if(memberInfo.isActive == true){
				this.activeMemberList.push(memberInfo, ...plans)
			} else if(memberInfo.isActive == false){
				this.inactiveMemberList.push(memberInfo, ...plans)
			}

            
			if (this.inactiveMemberList.length > 0) {
				this.displayInactiveSection = true
			}

        }
    }

	handleDropdown(event){
		/* HIDE ROWS LOGIC */
        const rowId = event.target.dataset.id;
		this[event.target.dataset.label].forEach(row => {
			if (rowId == row.parentRowId) {
				row.display = !row.display
			}
		})

		/* ARROW ROTATE ANIMATION */
		if (event.target.classList.contains('open')) {
			event.target.className = 'arrow-down'
		} else {
			event.target.className = 'arrow-down open'
		}
		
	}

    async renderedCallback(){
		/* ADDS RESIZABLE FUNCTIONALITY TO THE TABLE */
            await loadScript(this, resizableColumns + '/jquery.min.js'),
			await loadScript(this, resizableColumns + '/jquery.resizableColumns.js'),
			await loadStyle(this, resizableColumns + '/resizableColumns.css')

			$(this.template.querySelector('.resizable-active-table')).resizableColumns();
			$(this.template.querySelector('.resizable-inactive-table')).resizableColumns();
    }
}