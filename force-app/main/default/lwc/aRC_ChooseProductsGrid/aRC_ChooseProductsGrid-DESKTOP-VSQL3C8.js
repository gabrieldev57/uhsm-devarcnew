import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_ChooseProductsGrid extends OmniscriptBaseMixin(LightningElement) {
	@api inputmember;
	@api inputcore;
	@api inputsmart;
	@api inputaidd;
	@api lockedproduct;
	@api programchange;
	@track onlyProduct;
	outputJSON;
	idsCreated = [];
	smartValue;
	aiddValue;
	smartValueSpouse;
	aiddValueSpouse;
	primaryAiddDisabled = true;
	spouseAiddDisabled = true;
	parentSelected = [];
	depDisabled = true;
	valueDependents;
	disPrimarySmart = false;
	disPrimaryAidd = false;
	disSpouseSmart = false;

	get optionsCoreProduct() {
		let options = [];

		this.inputcore.forEach(element => {
			options.push({ "label": element.Name, "value": element.Id });
		});
		
		return options;
	}

	get optionsSmartProduct() {

		return this.optionProducts('Primary', this.inputsmart);
	}

	get optionsAiddProduct() {
		return this.optionProducts('Primary', this.inputaidd);
	}

	get optionsSmartProductSpouse(){
		return this.optionProducts('Spouse', this.inputsmart);
	}

	get optionsAiddProductSpouse(){
		return this.optionProducts('Spouse', this.inputaidd);
	}


	get optionDependents() {
		let options = [{ 'label': 'Primary Program', 'value': 'Primary' }]
		const check = element => element.CensusMemberRelationship == 'Spouse';
		if (this.inputmember.some(check)) {
			options.push({ 'label': 'Spouse Program', 'value': 'Spouse' })
		}
		options.push({ 'label': 'None', 'value': 'None' })
		return options;
	}

	optionProducts(relationship, productType){
		let options = [];
		
		if (this.programchange) {
			let member = this.inputmember.filter(item => item.CensusMemberRelationship == relationship)[0];

			if (productType && member.productIds.length) {
				productType.forEach(element => {
					member.productIds.forEach(prod => {
						if (prod == element.Id){
							options.push({ "label": element.Name, "value": element.Id });
							if (relationship == 'Primary' && productType == this.inputsmart) {
								this.smartValue = element.Id;
								this.disPrimarySmart = true;
							}else if(relationship == 'Primary' && productType == this.inputaidd){
								this.aiddValue = element.Id;
								this.primaryAiddDisabled = true;
							}else if(relationship == 'Spouse' && productType == this.inputsmart){
								this.smartValueSpouse = element.Id;
								this.disSpouseSmart = true;
							}else if(relationship == 'Spouse' && productType == this.inputaidd){
								this.aiddValueSpouse = element.Id;
								this.spouseAiddDisabled = true;
							}
						};
					})
				});
			}else if (!member.productIds.length) {
				productType.forEach(item => options.push({label: item.Name, value: item.Id}))
			}
		}else{
			options.push({ "label": "None", "value": "none" });

			if (productType) {
				productType.forEach(element => {
					options.push({ "label": element.Name, "value": element.Id });
				});
			}
		}
		return options;
	}

	connectedCallback() {
		this.lockedproduct == 'true' ? this.onlyProduct = this.inputcore[0].Id : null;
		if (!this.programchange) {
			if(this.inputsmart.length == 1){
				this.smartValue = this.inputsmart[0].Id;
				this.smartValueSpouse = this.inputsmart[0].Id;
				if (this.inputaidd) {
					this.primaryAiddDisabled = false;
					this.spouseAiddDisabled = false;
				}
			}
			if (this.inputaidd) {
				if (this.inputaidd.length == 1) {
					this.aiddValue = this.inputaidd[0].Id;
					this.aiddValueSpouse = this.inputaidd[0].Id;
				}
			}
			this.outputJSON = [];
		}else{
			this.depDisabled = false;
			this.outputJSON = {};
		}
	}

	renderedCallback(){
		if (this.programchange) {
			this.inputmember.forEach(item => {
				if (item.CensusMemberRelationship == 'Child' && item.productIds.length) {
					let smart = this.inputsmart.filter(prod => item.productIds.includes(prod.Id))[0];
					let aidd = this.inputaidd.filter(prod => item.productIds.includes(prod.Id))[0];
		
					this.template.querySelector("[data-idprod='" + item.CensusMemberId + "SMART']").innerHTML = smart.Name + ",&nbsp;";
					this.template.querySelector("[data-idprod='" + item.CensusMemberId + "AIDD']").innerHTML = aidd.Name;
					this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = true;
					this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").value = this.inputmember.filter(memb => memb.productIds.includes(smart.Id) && memb.productIds.includes(aidd.Id))[0].CensusMemberRelationship;
				}else if(item.CensusMemberRelationship == 'Child' && !item.productIds.length){
					let spouse = this.inputmember.find(item => item.CensusMemberRelationship == 'Spouse');

					if (spouse) {
						if (this.smartValueSpouse && this.aiddValueSpouse) {
							this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = false;
						}else{
							this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = true;
						}
					}else if(this.smartValue && this.aiddValue){
						this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = false;
					}else{
						this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = true;
					}
				}
			})
		}
	}

	handleChangeCoverage(event) {
		if (event.currentTarget.dataset.protype == 'SMART' && event.currentTarget.dataset.relationship == 'Primary') this.smartValue = event.detail.value;
		if (event.currentTarget.dataset.protype == 'AIDD' && event.currentTarget.dataset.relationship == 'Primary') this.aiddValue = event.detail.value;
		if (event.currentTarget.dataset.protype == 'SMART' && event.currentTarget.dataset.relationship == 'Spouse') this.smartValueSpouse = event.detail.value;
		if (event.currentTarget.dataset.protype == 'AIDD' && event.currentTarget.dataset.relationship == 'Spouse') this.aiddValueSpouse = event.detail.value;

		if (!this.programchange) {
			let dataToFunction = {};
			const check = element => element.CensusMemberRelationship == 'Spouse';
	
			if (this.smartValue && this.smartValue !== 'none') this.primaryAiddDisabled = false;
			if (this.smartValueSpouse && this.smartValueSpouse !== 'none') this.spouseAiddDisabled = false;
	
			if (
				(this.smartValue == 'none' && this.smartValueSpouse == 'none') ||
				(this.smartValue && this.smartValueSpouse && this.aiddValue && this.aiddValueSpouse) ||
				(this.smartValue == 'none' && this.aiddValue == undefined && this.smartValueSpouse !== 'none' && this.smartValueSpouse !== undefined && this.aiddValueSpouse !== undefined) ||
				(this.smartValueSpouse == 'none' && this.aiddValueSpouse == undefined && this.smartValue !== 'none' && this.smartValue !== undefined && this.aiddValue !== undefined) ||
				(!this.inputmember.some(check) && this.smartValue !== undefined && this.aiddValue !== undefined)
			) {
				this.depDisabled = false;
			} else {
				this.depDisabled = true;
			}
	
			if (this.smartValue == 'none') {
				this.aiddValue == 'none';
				this.template.querySelector('[data-aidd="primary"]').value = 'none';
				this.primaryAiddDisabled = true;
			}
			if (this.smartValueSpouse == 'none') {
				this.aiddValueSpouse == 'none';
				this.template.querySelector('[data-aidd="spouse"]').value = 'none';
				this.spouseAiddDisabled = true;
			}
	
			const even = (element) => element.CensusMemberRelationship == 'Child';
			if (this.inputmember.some(even)) {
				//Clear dependent select
				this.inputmember.forEach(element => {
					if (element.CensusMemberRelationship == 'Child') {
						this.template.querySelector("[data-idprod='" + element.CensusMemberId + "SMART']").innerHTML = '';
						this.template.querySelector("[data-idprod='" + element.CensusMemberId + "AIDD']").innerHTML = '';
					}
				});
				this.valueDependents = null;
				this.template.querySelector('[data-parent="parent"]').value = null;
			}
	
			dataToFunction['productSelected'] = event.detail.value;
			dataToFunction['productType'] = event.currentTarget.dataset.protype;
			dataToFunction['memberId'] = event.currentTarget.dataset.id;
			dataToFunction['memberRelationship'] = event.currentTarget.dataset.relationship;
			dataToFunction['memberName'] = event.currentTarget.dataset.name;
			this.createOutput(dataToFunction);
		}else{
			this.smartValueSpouse && (this.spouseAiddDisabled = false);		
			this.smartValue && (this.primaryAiddDisabled = false);
			this.inputmember.filter(item => item.CensusMemberRelationship == 'Child' && !item.productIds.length).forEach(memb => {
				this.template.querySelector("[data-idprod='" + memb.CensusMemberId + "SMART']").innerHTML = '';
				this.template.querySelector("[data-idprod='" + memb.CensusMemberId + "AIDD']").innerHTML = '';
				this.template.querySelector("[data-iddep='" + memb.CensusMemberId + "']").value = null
			})

			this.outputJSON = { 
				memberId: event.currentTarget.dataset.id, 
				smartId: event.currentTarget.dataset.protype == 'SMART' ? event.detail.value : null, 
				aiddId: event.currentTarget.dataset.protype == 'AIDD' ? event.detail.value : null
			}			

			const eventToParent = new CustomEvent("outputjson", { detail: this.outputJSON })
			this.dispatchEvent(eventToParent);
		}
	}

	createOutput(inputParameter) {
		let smart = null;
		let smartName = null;
		let aidd = null;
		let aiddName = null;
		let core = null;
		const findProduct = (element) => {
			if (element.Id === inputParameter.productSelected) return element;
		}

		if (inputParameter.productType == 'SMART') {
			smart = inputParameter.productSelected;
			inputParameter.productSelected !== 'none' ? smartName = this.inputsmart.find(findProduct).Name : smartName = 'None';
		}else if(this.smartValue){
			smart = this.smartValue;
			smartName = this.inputsmart[0].Name;
		}

		if (inputParameter.productType == 'AIDD' && smart !== 'none') {
			aidd = inputParameter.productSelected;
			inputParameter.productSelected !== 'none' ? aiddName = this.inputaidd.find(findProduct).Name : aiddName = 'None';
		} else if (smart == 'none') {
			aidd = 'none';
			aiddName = 'None';
		}else if(this.aiddValue && smart !== 'none'){
			aidd = this.aiddValue;
			aiddName = this.inputaidd[0].Name;
		}
		this.lockedproduct ? core = this.inputcore[0].Id : product = inputParameter.productSelected;
		if (this.outputJSON.length == 0 || !this.idsCreated.includes(inputParameter.memberId)) {
			this.outputJSON.push({
				"memberName": inputParameter.memberName,
				"memberId": inputParameter.memberId,
				"memberRelationship": inputParameter.memberRelationship,
				"SMART": smart,
				"SMARTName": smartName,
				"AIDD": aidd,
				"AIDDName": aiddName,
				"Product": core
			});
			this.idsCreated.push(inputParameter.memberId);
		} else {
			this.outputJSON.forEach(element => {
				if (element.memberId == inputParameter.memberId) {
					if (inputParameter.productType == 'SMART') {
						element.SMART = inputParameter.productSelected;
						element.SMARTName = smartName;
					}
					if (inputParameter.productType == 'AIDD') {
						element.AIDD = inputParameter.productSelected;
						element.AIDDName = aiddName;
					} else if (element.SMART == 'none') {
						element.AIDD = 'none'
						element.AIDDName = 'None';
					}
				}
			});
		}

		if (!this.programchange) {
			const changeEvent = new CustomEvent('handlechangevalues');
			this.dispatchEvent(changeEvent);
			const eventToParent = new CustomEvent("outputjson", { detail: this.outputJSON })
			this.dispatchEvent(eventToParent);
		}
	}

	handleSelectDepProgram(evt) {
		let memberId = evt.currentTarget.dataset.id;
		let smart = null;
		let aidd = null;
		
		if (!this.programchange) {
			const check = element => element.memberId === memberId;
			const changeEvent = new CustomEvent('handlechangevalues');
			this.dispatchEvent(changeEvent);

			if (!this.parentSelected.some(check)) {
				this.parentSelected.push({ 'memberId': memberId, 'value': evt.detail.value });
			} else {
				this.parentSelected.forEach(element => {
					if (element.memberId == memberId) element.value = evt.detail.value;
				});
			}
			this.outputJSON.forEach(item => {
				if (evt.detail.value == 'Primary' && item.memberRelationship == 'Primary') {
					smart = item.SMARTName;
					item.AIDDName !== null ? aidd = item.AIDDName : aidd = 'None';
				} else if (evt.detail.value == 'Spouse' && item.memberRelationship == 'Spouse') {
					smart = item.SMARTName;
					item.AIDDName !== null ? aidd = item.AIDDName : aidd = 'None';

				}
				else if (evt.detail.value == 'None') {
					smart = 'None';
					aidd = 'None';
				}

				const eventToParent = new CustomEvent("outputdep", { detail: this.parentSelected })
				this.dispatchEvent(eventToParent);
			});
		}else{
			if (evt.detail.value == 'Primary') {
				smart = this.optionsSmartProduct.filter(item => item.value == this.smartValue)[0].label;
				aidd = this.optionsAiddProduct.filter(item => item.value == this.aiddValue)[0].label;
			}
			else if(evt.detail.value == 'Spouse'){
				smart = this.optionsSmartProductSpouse.filter(item => item.value == this.smartValueSpouse)[0].label;
				aidd = this.optionsAiddProductSpouse.filter(item => item.value == this.aiddValueSpouse)[0].label;
			
			}
			else if(evt.detail.value == 'None'){
				smart = 'None'
				aidd = 'None'
			}

			this.outputJSON = { memberId: memberId, productsFrom: evt.detail.value }
			const eventToParent = new CustomEvent("outputdep", { detail: this.outputJSON })
			this.dispatchEvent(eventToParent);
		}

		this.template.querySelector("[data-idprod='" + memberId + "SMART']").innerHTML = smart + ",&nbsp;";
		this.template.querySelector("[data-idprod='" + memberId + "AIDD']").innerHTML = aidd;
	}

}