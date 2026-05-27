import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import HTML_Templates from './Templates/index'
import PICKLIST_OPTIONS from './PICKLIST_OPTIONS'
import EmailAddressOptions from './EmailAddressOptions'


let parameters = {
	"Primary Name": null,
	"First Name": null,
	"Last Name": null,
	"Full Name": null,
	"Next Birth Date": null,
	"Member ID": null,
	"Member e123_Id": null,
	"ContractStatus": null,
	"Medical Plan": null,
	"SMART Plan": null,
	"AIDD Plan": null,
	"Medical Plan Price": null,
	"SMART Plan Price": null,
	"AIDD Plan Price": null,
	"Medical Benefit Level": null,
	"SMART Benefit Level": null,
	"AIDD Benefit Level": null,
	"Plan List": null,
	"Initial Contribution": null,
	"Monthly Contribution": null,
	"Old Monthly Contribution": null,
	"Payment Expiration Month": null,
	"Payment Expiration Year": null,
	"Next Transaction Date": null,
	"Contract Effective Date": null,
	"Contract Inactive Date": null,
	"Payment Method": null,
	"Last 4 Digits": null,
	"Payment Method Name": null,
	"Charge Date": null,
	"orgURL": null,
	"Oldest Member Name": null,
	"Oldest Member Birthdate": null,
	"Next Contribution In Sixty Days": null,
	"Ages Up Draft Date": null,
	"HD Expiration Date": null,
	"AgeUp Name": null,
};

let draftDay = null;
let ageup = [];
let healthydiscount = [];
let promotiondiscount = [];
let AgeUpMemberName;
let AgeUpBirthdate;

export default class ARC_EmailTemplatesOnDemand extends OmniscriptBaseMixin(LightningElement) {
	@api recordId;
	personAccountId;
	initialized = false;
	isModalOpen = false;
	@api templateSelected;
	@api members = [];
	@api membersSelected = [];
	@api hipaaList = [];
	@api subject = '';
	useOrgEmail = true;
	currentUserName = null;
	selectedOption;
	isSendingEmail = false;

	@api get disableSend() {
		return this.membersSelected.length == 0 || !this.templateSelected || this.isSendingEmail
	}

	get showEmailDropdown() {
		return (this.currentUserName == 'Jesse de Nova' || this.currentUserName == 'Rachel Perez') && (this.templateSelected == '37' || this.templateSelected == '38')
	}

	get disableTemplatePicklist() {
		return !this.membersSelected.length
	}

	get displayModalContent() {
		return this.members.length > 0 ? true : false
	}

	get lastSelectionedMember() {
		return this.membersSelected.at(-1);
	}

	get showSubject() {
		if (this.templateSelected) {
			return true
		} else {
			return false;
		}
	}

	get showEFTForm() {
		return ['6', '21', '25', '30', '31'].includes(this.templateSelected);
	}

	get showLabOrderForm() {
		return ['55', '56'].includes(this.templateSelected);
	}

	get showNonLocatesLabOrderForm() {
		return ['57'].includes(this.templateSelected);
	}

	get showhdlrc() {
		return ['51'].includes(this.templateSelected);
	}

	get TemplateOptions() {
		return PICKLIST_OPTIONS.sort((a, b) => a.label.localeCompare(b.label));
	}
	get OrgEmailOptions() {
		return EmailAddressOptions
	}


	//Handle function to open model when button is pressed
	handleManageModal(evt) {
		evt.currentTarget.dataset.manage == 'open' ? this.isModalOpen = true : this.isModalOpen = false;
		this.templateSelected = null;
	}

	// This method gets all the initial information necessary for the component to work
	async getComponentData(cmId, isInitialization) {
		const params = {
			input: JSON.stringify({
				'recordId': cmId,
				'isInitialization': isInitialization
			}),
			sClassName: 'ARC_EmailTemplatesOnDemandController',
			sMethodName: 'getTemplateInformation',
			options: '{}',
		};

		const response = await this.omniRemoteCall(params, true)
		this.memberid = response.result.memberid
		this.memberide123 = response.result.memberide123
		this.plans = response.result.plans
		this.currentUserName = response.result.currentUser

		if (this.initialized == false) {
			this.initialized = true;

			//HD information
			healthydiscount = [];
			healthydiscount = response.result?.HealthyDiscount
			promotiondiscount = response.result?.PromotionDiscount

			if (promotiondiscount?.length > 0) {

				parameters['Old Monthly Contribution'] = promotiondiscount[0].ARC_CorePriceWithoutDiscount__c;
			}
			if (healthydiscount?.length > 0) {
				this.HDExpirationDate = healthydiscount[0].ARC_EndDate__c;
				parameters['HD Expiration Date'] = healthydiscount[0].ARC_EndDate__c;

			}

			//Age Up Information
			ageup = response.result.ageup
			const options = {
				year: 'numeric',
				month: '2-digit',
				day: '2-digit',
				timeZone: 'UTC'
			};
			var formatter = new Intl.DateTimeFormat('en-US', options);
			var formattedAgeUpBirthdate, formattedOrderUpdateDate, RawAgeUpBirthdate;

			if (ageup) {
				ageup.forEach(ageupMember => {

					if (!ageupMember.ARC_Applied__c) {

						let orderUpdateDate = ageupMember.ARC_ManualDelay__c ? ageupMember.ARC_ManualDelay__c : ageupMember.ARC_EffectiveDate__c;
						AgeUpMemberName = ageupMember.ARC_Account__r.FirstName;
						RawAgeUpBirthdate = ageupMember.ARC_Account__r.PersonBirthdate;
						let ageUpEffectiveDate = ageupMember.ARC_EffectiveDate__c;
						formattedAgeUpBirthdate = /^\d{4}-\d{2}-\d{2}$/.test(ageUpEffectiveDate)
						let currentAge = this.calculateAge(new Date(RawAgeUpBirthdate));
						var formatedAgeUpEffectiveDate = formatter.format(new Date(ageUpEffectiveDate));
						let nextAge = currentAge + 1;

						if (/^\d{4}-\d{2}-\d{2}$/.test(orderUpdateDate)) {
							// Original date in another format, e.g., YYYY-MM-DD
							var originalorderUpdateDate = new Date(orderUpdateDate);
							var formattedDate = formatter.format(originalorderUpdateDate);
							var ActivedateParts = formattedDate.split(',')[0].split('/');
							var month = ActivedateParts[0];
							var day = ActivedateParts[1];
							var year = ActivedateParts[2];
							var monthName = this.getMonthName(month);
							formattedOrderUpdateDate = month + '/' + day + '/' + year;

						} else {
							formattedOrderUpdateDate = ' ';
						}
						if (/^\d{4}-\d{2}-\d{2}$/.test(RawAgeUpBirthdate)) {

							// Original date in another format, e.g., YYYY-MM-DD
							var originalAgeUpBirthdate = new Date(RawAgeUpBirthdate);
							var formattedDate = formatter.format(originalAgeUpBirthdate);
							var InActivedateParts = formattedDate.split(',')[0].split('/');
							var month = InActivedateParts[0];
							var day = InActivedateParts[1];
							var year = InActivedateParts[2];
							AgeUpBirthdate = month + '/' + day;
						}
						else {
							AgeUpBirthdate = ' ';
						}



						parameters["Oldest Member Name"] = ageupMember.ARC_Account__r.ARC_IsPrimaryMember__c === true ? 'your' : `${AgeUpMemberName}’s`;
						parameters["Oldest Member Birthdate"] = AgeUpBirthdate;
						parameters["Next Contribution In Sixty Days"] = ageupMember.ARC_PriceAfterAgeUp__c;
						parameters['Ages Up Draft Date'] = monthName;
						parameters['Ages Up Effective Date'] = formatedAgeUpEffectiveDate;
						parameters['Program Name'] = ageupMember.Contract__r.ARC_MedicalPlan__r.Name;
						parameters['AgeUp'] = nextAge + 'th';
					}

				});
			}

			let contracts = response.result.contracts;
			if (contracts) {
				this.contract = contracts.find(c => c.Status == 'Activated') ||
					contracts.find(c => c.Status == 'Awaiting Activation') ||
					contracts.find(c => c.Status == 'Awaiting for First Payment') ||
					contracts.find(c => c.Status == 'Awaiting Approval') ||
					contracts.find(c => c.Status == 'Awaiting Signature') ||
					contracts.find(c => c.Status == 'Terminated') ||
					contracts.find(c => c.Status == 'Voided');

				if (this.contract) {
					parameters["Contract Effective Date"] = this.contract.ARC_EffectiveDate__c;
					parameters["Contract Inactive Date"] = this.contract.ARC_Inactive_Date__c;
					parameters["ContractStatus"] = this.contract.Status;
					// parameters["Next Contribution In Sixty Days"] = this.contract.Next_Contribution_In_sixty_Days__c;

				}
			}

			let chargentList = response.result.chargentOrders;

			let appFee
			let recurring;
			let tokenChargent; //This is the chargent order that contains the payment information from which the token is then generated.

			if (this.contract && chargentList) {
				appFee = chargentList.find(co => co.Id == this.contract.ARC_AppFeeOrder__c && co.ChargentOrders__Description__c == 'App Fee');
				recurring = chargentList.find(co => co.Id == this.contract.ARC_RecurringMonthlyOrder__c && co.ChargentOrders__Description__c == 'Recurring Monthly Order');

				if (recurring) {
					tokenChargent = chargentList.find(co =>
						co.ChargentOrders__Tokenization__c == recurring.ChargentOrders__Tokenization__c &&
						((co.ChargentOrders__Card_Month_Indicator__c && co.ChargentOrders__Card_Year_Indicator__c && co.ChargentOrders__Card_Type__c) || //If Credit Card
							(co.ChargentOrders__Bank_Name__c && co.ChargentOrders__Bank_Account_Last_4__c))) // If Bank Account

					parameters["Payment Method"] = recurring.ChargentOrders__Payment_Method__c;
					parameters["Next Transaction Date"] = recurring.ChargentOrders__Next_Transaction_Date__c;

					let chargeDate = recurring.ChargentOrders__Charge_Date__c;
					draftDay = chargeDate;
					var regExp = /^0[0-9].*$/
					if (regExp.test(chargeDate) == true) {
						chargeDate = parseInt(chargeDate, 10);
					}
					if (chargeDate) {
						parameters["Charge Date"] = this.getDayWithSuffix(parseInt(chargeDate))
					}

				} else if (appFee) {
					tokenChargent = chargentList.find(co =>
						co.ChargentOrders__Tokenization__c == appFee.ChargentOrders__Tokenization__c &&
						((co.ChargentOrders__Card_Month_Indicator__c && co.ChargentOrders__Card_Year_Indicator__c && co.ChargentOrders__Card_Type__c) || //If Credit Card
							(co.ChargentOrders__Bank_Name__c && co.ChargentOrders__Bank_Account_Last_4__c))) // If Bank Account

					parameters["Payment Method"] = appFee.ChargentOrders__Payment_Method__c;
				}


				let totalPrice = recurring ? recurring.ChargentOrders__Total__c : null;
				let feePrice = appFee ? appFee.ChargentOrders__Total__c : null;

				let fee = isNaN(feePrice) ? 0 : feePrice;
				let contribution = isNaN(totalPrice) ? 0 : totalPrice;
				parameters["Initial Contribution"] = (fee + contribution).toFixed(2);
				parameters["Monthly Contribution"] = contribution;
				if (healthydiscount?.length == 0 && promotiondiscount?.length == 0) {
					parameters["Old Monthly Contribution"] = contribution;
				}
			}

			if (tokenChargent) {
				parameters["Payment Expiration Month"] = tokenChargent.ChargentOrders__Card_Month_Indicator__c;
				parameters["Payment Expiration Year"] = tokenChargent.ChargentOrders__Card_Year_Indicator__c;
				if (parameters["Payment Method"] == 'Credit Card') {
					parameters["Last 4 Digits"] = tokenChargent.ChargentOrders__Card_Last_4__c;
					parameters["Payment Method Name"] = tokenChargent.ChargentOrders__Card_Type__c;
				} else if (parameters["Payment Method"] == 'Bank Account') {
					parameters["Last 4 Digits"] = tokenChargent.ChargentOrders__Bank_Account_Last_4__c;
					parameters["Payment Method Name"] = tokenChargent.ChargentOrders__Bank_Name__c;
				}
			}

			if (response.result.members) {
				this.members = response.result.members;
				let defaultMemberSelected = this.members.find(m => m.isSelected == true)
				this.membersSelected.push(defaultMemberSelected)
				let primaryMember = response.result.primaryMember;
				let primaryMemberName = primaryMember?.vlocity_ins__FirstName__c || '';
				parameters["Primary Name"] = `${primaryMember?.vlocity_ins__FirstName__c} ${primaryMember?.vlocity_ins__LastName__c}`
				let primaryMemberBirthdate = primaryMember?.vlocity_ins__Birthdate__c || '';

				let memberAgeUpBirthdate = /^\d{4}-\d{2}-\d{2}$/.test(primaryMemberBirthdate)
					? new Intl.DateTimeFormat('en-US').format(new Date(primaryMemberBirthdate)).split(',')[0].split('/').slice(0, 2).join('/')
					: ' ';

				// parameters["Oldest Member Name"] = AgeUpMemberName === primaryMemberName ? 'your' : `${AgeUpMemberName}’s`;
				// parameters["Oldest Member Birthdate"] = AgeUpMemberName === primaryMemberName ? memberAgeUpBirthdate : AgeUpBirthdate;
			}

			if (response.result.projectedPaidThroughDate != null) {
				var formatter = new Intl.DateTimeFormat('en-US', options);
				var formatedAgeUpEffectiveDate = formatter.format(new Date(response.result.projectedPaidThroughDate));

				parameters["Projected Paid Through Date"] = formatedAgeUpEffectiveDate;
				console.log('projected paid through date: ' + parameters["Projected Paid Through Date"]);
			}

			if (response.result.imageURLs) {
				this.EFTFormURL = response.result.imageURLs.EFTForm;
				this.LabOrderFormURL = response.result.imageURLs.UHSMLabOrder;
				this.hdlrcURL = response.result.imageURLs.HealthyDiscountLabResultsCriteria;
				this.NonLocatesLabOrderFormURL = response.result.imageURLs.NonLocatesLabOrderForm;
				parameters["imageURLs"] = response.result.imageURLs;
			}
		}
	}

	async connectedCallback() {
		if (this.recordId.startsWith('500')) { // Case
			const caseRecord = await this.getCaseRecord(this.recordId);
			this.personAccountId = caseRecord?.ARC_PersonAccount__c;
		} else if (this.recordId.startsWith('001')) { // Person Account
			this.personAccountId = this.recordId;
		}

		if (this.personAccountId) {
			this.getComponentData(this.personAccountId);
		}

	}



	renderedCallback() {
		if (this.isModalOpen == true && !this.templateSelected) {
			this.template.querySelector('.content').classList.add('overflowVisible');
		}

		if (this.isModalOpen == true && this.templateSelected) {
			this.template.querySelector('.content').classList.remove('overflowVisible');
		}
	}

	//Handle when a template is selected in the dropdown menu.
	handleChangeTemplate(evt) {
		this.templateSelected = evt.detail.value;
		this.renderHTML(this.lastSelectionedMember.id, true);
	}
	//Handle when a emailaddress is selected in the dropdown menu.
	handleChangeEmailAddress(evt) {
		this.useOrgEmail = evt.currentTarget.value;
		this.selectedOption = evt.currentTarget.value;
	}
	//Re render HTML of the Email Template Preview
	renderHTML(selectedMemberId, updatePreview) {
		if (this.templateSelected == null) return;
		let selectedMember = this.members.find(m => m.id == selectedMemberId)
		if (!selectedMember) return;
		parameters["First Name"] = selectedMember.firstname;
		parameters["Last Name"] = selectedMember.lastname;
		parameters["Full Name"] = `${selectedMember.firstname} ${selectedMember.lastname}`;
		parameters["Member ID"] = this.memberide123 != null ? this.memberide123 : this.memberid;



		if (selectedMember.birthdate) {
			let birthdate = this.parseDate(selectedMember.birthdate);
			// Next Birth Date Formatted Logic, if birthdate is this year, use this year, else next year
			let [year, month, day] = birthdate.toISOString().substring(0, 10).split("-");
			let today = new Date();
			let currentYear = today.getFullYear();
			let birthdayThisYear = new Date(currentYear, month - 1, day);
			let yearToUse = today >= birthdayThisYear ? currentYear + 1 : currentYear;
			let formattedNextBirthDate = `${yearToUse}-${month}-${day}`;
			parameters["Next Birth Date"] = formattedNextBirthDate;
		}


		if (this.plans) {
			console.log("plans ", this.plans);
			console.log("selectedMemberId ", selectedMemberId);
			console.log("this.plans.find(p => p.vlocity_ins__ContactId__r?.AccountId == selectedMemberId) ", this.plans.find(p => p.vlocity_ins__ContactId__r?.AccountId == selectedMemberId));
			let plans = this.plans.find(p => p.vlocity_ins__ContactId__r?.AccountId == selectedMemberId)?.vlocity_ins__GroupCensusMemberPlan__r.records
			if (plans) {
				console.log("plans ", plans);
				let allPlans = this.plans.flatMap(member => member.vlocity_ins__GroupCensusMemberPlan__r.records)
				console.log("allPlans ", allPlans);
				console.log("contract", this.contract);
				const contractId = this.contract.Id;

				const calculateBenefitLevel = (searchedPlan, allPlans) => {
					let planCount = allPlans.filter(p => p.vlocity_ins__ContractLineId__c == searchedPlan.vlocity_ins__ContractLineId__c).length
					switch (true) { case planCount === 1: return 'SINGLE'; case planCount === 2: return 'Member + One'; case planCount > 2: return 'FAMILY'; default: return ''; }
				}

				const findPlan = (type, subType) => {
					return plans.find(plan =>
						plan.vlocity_ins__ContractLineId__r.vlocity_ins__ProductType__c === type &&
						plan.vlocity_ins__ContractLineId__r.vlocity_ins__ContractId__c === contractId &&
						(!subType || plan.vlocity_ins__ContractLineId__r.vlocity_ins__ProductSubType__c === subType)
					);
				}

				const addPlanDetails = (plan, type) => {
					parameters[`${type} Plan`] = plan.vlocity_ins__ContractLineId__r.Name;
					parameters[`${type} Plan Price`] = plan.vlocity_ins__ContractLineId__r.vlocity_ins__TotalPrice__c.toFixed(2);
					parameters[`${type} Benefit Level`] = calculateBenefitLevel(plan, allPlans);
					planListHtml += `<p>${parameters[`${type} Plan`]}</p>`;
				};

				const medicalPlan = findPlan('Medical', null);
				const smartPlan = findPlan(null, 'SMART');
				const aiddPlan = findPlan(null, 'AIDD');

				let planListHtml = '';
				if (medicalPlan) addPlanDetails(medicalPlan, 'Medical');
				if (smartPlan) addPlanDetails(smartPlan, 'SMART');
				if (aiddPlan) addPlanDetails(aiddPlan, 'AIDD');
				parameters["Plan List"] = planListHtml;

			}
		}

		const selectedTemplate = PICKLIST_OPTIONS.find(option => option.value === this.templateSelected);
		const { params: templateRequiredInfo, subject, label } = selectedTemplate;

		let functionParameters = templateRequiredInfo.map(key =>
			parameters[key] ? parameters[key] : undefined
		);

		let html = HTML_Templates[`Template${this.templateSelected}`](...functionParameters);
		this.subject = subject;
		if (updatePreview) {
			this.template.querySelector('.preview').innerHTML = html;
		}
		return { html, subject: subject, templateSelected: this.templateSelected, label }
	}

	// Handle when Send Email button is pressed
	async handleSendEmail() {
		// Prevent multiple simultaneous sends
		if (this.isSendingEmail) {
			return;
		}

		this.isSendingEmail = true;

		let emailListToSend = [];
		for (const m of this.membersSelected) {
			console.log("membersSelected ", this.membersSelected);
			if (m.isSelected == true && m.email != null) {
				const { subject, html, templateSelected, label } = await this.renderHTML(m.id, false);
				emailListToSend.push({ recipientId: m.id, emailAddress: m.email, emailSubject: subject, templateHtml: html, templateSelected: templateSelected, templateLabel: label });
			}
		}

		if (emailListToSend.length) {
			console.log("emailListToSend", emailListToSend);
			const payload = {
				recordId: this.recordId,
				emailListToSend,
				useOrgEmail: this.useOrgEmail
			};

			try {
				await this.omniRemoteCall({ input: JSON.stringify(payload), sClassName: 'ARC_Emails', sMethodName: 'handleEmail', options: '{}', }, true)
				this.displaySuccessMessage();
				emailListToSend = [];
			} catch (error) {
				this.displayErrorMessage();
			} finally {
				this.isSendingEmail = false;
				this.isModalOpen = false;
			}
		} else {
			this.isSendingEmail = false;
		}
	}

	// Handle when a member is clicked
	toggleMemberSelection(evt) {
		const selectedId = evt.target.dataset.id;
		let memberSelected = this.members.find(m => m.id === selectedId);
		memberSelected.isSelected = !memberSelected.isSelected

		if (memberSelected.isSelected == true) {
			this.membersSelected = [...this.membersSelected, memberSelected];
			if (this.templateSelected == null) return;
			this.renderHTML(this.lastSelectionedMember.id, true);
		} else if (memberSelected.isSelected == false) {
			this.membersSelected = this.membersSelected.filter(m => m !== memberSelected);
			if (this.templateSelected == null || this.membersSelected.length == 0) return;
			this.renderHTML(this.lastSelectionedMember.id, true);
		}

	}

	// Displays Success Message
	displaySuccessMessage() {
		const evt = new ShowToastEvent({
			"title": "Email Sent successfully.",
			"variant": "success"
		});
		this.dispatchEvent(evt);
		eval("$A.get('e.force:refreshView').fire();");
	}

	// Displays Error Message
	displayErrorMessage() {
		const evt = new ShowToastEvent({
			title: "There was an error when sending the email.",
			variant: 'error',
		});
		this.dispatchEvent(evt);
	}

	// parse a date in yyyy-mm-dd format
	parseDate(input) {
		var parts = input.match(/(\d+)/g);
		return new Date(parts[0], parts[1] - 1, parts[2]);
	}

	async getCaseRecord(caseId) {
		try {
			const response = await this.omniRemoteCall({
				input: { caseId },
				sClassName: 'ARC_EmailTemplatesOnDemandController',
				sMethodName: 'getCaseRecord',
				options: '{}',
			}, true);
			return response.result.caseRecord;
		} catch (error) {
			console.error('Error getting case record:', error);
			this.displayErrorMessage();
			return null;  // Return null on error
		}
	}

	getDayWithSuffix(day) {
		const suffix = ['th', 'st', 'nd', 'rd'];
		const v = day % 100;
		return day + (suffix[(v - 20) % 10] || suffix[v] || suffix[0]);
	}

	getMonthName(monthNumber) {
		const monthNames = [
			"January", "February", "March", "April", "May", "June",
			"July", "August", "September", "October", "November", "December"
		];
		if (monthNumber < 1 || monthNumber > 12) {
			return "Invalid month number";
		}
		return monthNames[monthNumber - 1];
	}

	// Calculate age based on birth date
	calculateAge(birthDate) {
		if (!birthDate) return null;
		const today = new Date();
		const birth = new Date(birthDate);
		let age = today.getFullYear() - birth.getFullYear();
		const monthDiff = today.getMonth() - birth.getMonth();
		if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
			age--;
		}
		return age;
	}
}