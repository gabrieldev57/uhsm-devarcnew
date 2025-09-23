import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_ChooseProductsGridEnrollment extends OmniscriptBaseMixin(LightningElement) {
	@api inputmember;
	@api inputcore;
	@api inputsmart;
	@api inputaidd;
	@api lockedproduct;
	@api omniJsonData;

	@track onlyProduct;
	outputJSON;
	idsCreated = [];
	smartValue = "None";
	aiddValue = "None";
	smartValueSpouse = "None";
	aiddValueSpouse = "None";
	primaryAiddDisabled = false;
	spouseAiddDisabled = false;
	parentSelected = [];
	depDisabled = true;
	valueDependents;
	disPrimarySmart = false;
	disPrimaryAidd = false;
	disSpouseSmart = false;
	@track shareAiddPrograms = false;
	@track shareSmartPrograms = false;

	// showSharePrograms = false;




	get showShareSmartPrograms() {
		if (this.smartValueSpouse == this.smartValue && this.smartValueSpouse != null) {
			return true;
		} else {
			this.shareSmartPrograms = false;
			return false;
		}
	}
	get showShareAiddPrograms() {
		if (this.aiddValueSpouse == this.aiddValue && this.aiddValueSpouse != null) {
			return true;
		} else {
			this.shareAiddPrograms = false;
			return false;
		}
	}
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

	get optionsSmartProductSpouse() {
		return this.optionProducts('Spouse', this.inputsmart);
	}

	get optionsAiddProductSpouse() {
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

	optionProducts(relationship, productType) {
		let options = [{ label: "None", value: "None" }];
		let member = this.inputmember.filter(item => item.CensusMemberRelationship == relationship)[0];

		if (productType && member?.productIds?.length) {

			productType.forEach(element => {
				member.productIds.forEach(prod => {

					if (prod == element.Id) {
						options.push({ "label": element.Name, "value": element.Id });
						if (relationship == 'Primary' && productType == this.inputsmart) {
							this.smartValue = element.Id;
							this.disPrimarySmart = true;
						} else if (relationship == 'Primary' && productType == this.inputaidd) {
							this.aiddValue = element.Id;
							this.primaryAiddDisabled = true;
						} else if (relationship == 'Spouse' && productType == this.inputsmart) {
							this.smartValueSpouse = element.Id;
							this.disSpouseSmart = true;
						} else if (relationship == 'Spouse' && productType == this.inputaidd) {
							this.aiddValueSpouse = element.Id;
							this.spouseAiddDisabled = co;
						}
					};
				})
			});
		} else
			if (!member?.productIds?.length && productType) {

				productType.forEach(item => options.push({ label: item.Name, value: item.Id }))





			}
		return options;
	}

	connectedCallback() {

		// this.initiateValues();
		if (this.omniJsonData.chooseProductsGridSavedState && this.sameInput()) {
			this.getChooseProductsSavedState();
		} else {
			this.lockedproduct == 'true' ? this.onlyProduct = this.inputcore[0].Id : null;
			this.outputJSON = [];
		}
	}

	handleChangeCoverage(event) {
		if (event.currentTarget.dataset.protype == 'SMART' && event.currentTarget.dataset.relationship == 'Primary') this.smartValue = event.detail.value;
		if (event.currentTarget.dataset.protype == 'AIDD' && event.currentTarget.dataset.relationship == 'Primary') this.aiddValue = event.detail.value;
		if (event.currentTarget.dataset.protype == 'SMART' && event.currentTarget.dataset.relationship == 'Spouse') this.smartValueSpouse = event.detail.value;
		if (event.currentTarget.dataset.protype == 'AIDD' && event.currentTarget.dataset.relationship == 'Spouse') this.aiddValueSpouse = event.detail.value;
		let dataToFunction = {};

		if (this.smartValue !== "None" || this.smartValueSpouse !== "None" || this.aiddValue !== "None" || this.aiddValueSpouse !== "None"){
			this.depDisabled = false;
		}
		else {
			this.depDisabled = true;
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

	}

	createOutput(inputParameter) {
		console.log('inputParameter', inputParameter);
		let smart = null;
		let smartName = null;
		let aidd = null;
		let aiddName = null;
		let core = null;
		const findProduct = (element) => {
			if (element.Id === inputParameter.productSelected) return element;
		}
		console.log('prueba1');
		
		if (inputParameter.productType == 'SMART') {
			smart = inputParameter.productSelected;
			inputParameter.productSelected !== 'None' ? smartName = this.inputsmart.find(findProduct).Name : smartName = 'None';
		}

		console.log('prueba2');
		if (inputParameter.productType == 'AIDD' && smart !== 'None') {
			aidd = inputParameter.productSelected;
			inputParameter.productSelected !== 'None' ? aiddName = this.inputaidd.find(findProduct).Name : aiddName = 'None';
		} else if (this.aiddValue && smart !== 'None') {
			aidd = this?.aiddValue;
			if (this.inputaidd != undefined && this.inputaidd != null && this.inputaidd != "") {
				aiddName = this?.inputaidd[0].Name;
			} else {
				aiddName = "None"
			}

		}
		console.log('prueba3');
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
					}
				}
			});
		}
		console.log('prueba4');

		const changeEvent = new CustomEvent('handlechangevalues');
		this.dispatchEvent(changeEvent);
		const eventToParent = new CustomEvent("outputjson", { detail: this.outputJSON })
		this.dispatchEvent(eventToParent);
		this.saveChooseProductsState();
		console.log('prueba5');
	}

	handleSelectDepProgram(evt) {
		let memberId = evt.currentTarget.dataset.id;
		let smart = null;
		let aidd = null;

		const check = element => element.memberId === memberId;
		const changeEvent = new CustomEvent('handlechangevalues');
		this.dispatchEvent(changeEvent);

		console.log('this.inputmember handleSelectDepProgram', JSON.stringify(this.inputmember));
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
		this.saveChooseProductsState();


		this.template.querySelector("[data-idprod='" + memberId + "SMART']").innerHTML = smart + ",&nbsp;";
		this.template.querySelector("[data-idprod='" + memberId + "AIDD']").innerHTML = aidd != 'None' ? aidd : '';
	}

	handleShareAiddOnChange(event) {
		this.shareAiddPrograms = event.target.checked;
		const eventToParent = new CustomEvent("shareaiddprograms", { detail: event.target.checked })
		this.dispatchEvent(eventToParent);
		this.saveChooseProductsState();
	}
	handleShareSmartOnChange(event) {
		this.shareSmartPrograms = event.target.checked;
		const eventToParent = new CustomEvent("sharesmartprograms", { detail: event.target.checked })
		this.dispatchEvent(eventToParent);
		this.saveChooseProductsState();
	}

	initiateValues() {
		// if (this.omniJsonData.chooseProductsFirstTime) {

		// 	this.inputmember = []
		// 	const productsList = [...this.inputcore, ...this.inputsmart, ...this.inputaidd]
		// 	this.omniJsonData.chooseProductsJson.member.forEach(m => { // Members

		// 		let emptyObject = {}
		// 		emptyObject.Id = m.Id
		// 		emptyObject.isPrimary = m['RF_Census.CM_IsPrimary']
		// 		emptyObject.isSpouse = m['RF_Census.CM_IsSpouse']
		// 		emptyObject.isDependent = m.CensusMemberRelationship == "Child" ? true : false
		// 		emptyObject.CensusMemberId = m.CensusMemberId
		// 		emptyObject.CensusMemberName = m.CensusMemberName
		// 		emptyObject.CensusMemberRelationship = m.CensusMemberRelationship

		// 		productsList.forEach(p => { // Products
		// 			if (p.Type__c == "Medical") this.onlyProduct = p.Id

		// 			if (p.CalculatedPriceData) {
		// 				for (const key in p.CalculatedPriceData) { // Calculated Price Data
		// 					if (key !== "Price" && key !== "aggByKey" && key !== "detailPrice") {
		// 						const member = p.CalculatedPriceData[key];

		// 						const anyMemberRelationship = this.omniJsonData.chooseProductsJson.member.find(m => m.CensusMemberId == member.CensusMemberId)?.CensusMemberRelationship
		// 						if (m.CensusMemberRelationShip == "Child" && (anyMemberRelationship == "Primary" || anyMemberRelationship == "Spouse") && (p.SubType__c == "SMART" || p.SubType__c == "AIDD")) {
		// 							emptyObject.parentSelected = anyMemberRelationship
		// 						}

		// 						If product has the member in Calculated Price Data
		// 						if (member.CensusMemberId == m.CensusMemberId) {
		// 							if (p.SubType__c == "SMART") {
		// 								emptyObject[`memberId${p.SubType__c}`] = toString(member.CensusMemberId + p.SubType__c)
		// 								if (m.CensusMemberRelationship == "Primary") {

		// 									this.smartValue = p.Id
		// 									console.log('this.smartValue initiateValues', this.smartValue);
		// 								}
		// 								if (m.CensusMemberRelationship == "Spouse") {
		// 									this.smartValueSpouse = p.Id
		// 									console.log('this.smartValueSpouse initiateValues', this.smartValueSpouse);
		// 								}
		// 							}
		// 							if (p.SubType__c == "AIDD") {
		// 								emptyObject[`memberId${p.SubType__c}`] = toString(member.CensusMemberId + p.SubType__c)
		// 								if (m.CensusMemberRelationship == "Primary") {

		// 									this.aiddValue = p.Id
		// 									console.log('this.aiddValue initiateValues', this.aiddValue);
		// 								}
		// 								if (m.CensusMemberRelationship == "Spouse") {
		// 									this.aiddValueSpouse = p.Id
		// 									console.log('this.aiddValueSpouse initiateValues', this.aiddValueSpouse);
		// 								}
		// 							}
		// 						}
		// 					}
		// 				}

		// 			}
		// 		})

		// 		this.inputmember.push(emptyObject)
		// 		console.log('this.inputmember initiateValues', this.inputmember);

		// 	})
		// 	/* HASTA ACA VAN MIS CAMBIOS, PONE LOS TUYOS ABAJO */
		// 	console.log('getParentSelected initiateValues', this.getParentSelected(this.inputmember));
		// 	console.log('getOutputJSON initiateValues', this.getOutputJSON(this.inputmember, productsList));
		// }


	}

	getParentSelected(inputmember) {
		let parentSelected = [];
		inputmember.forEach(member => {
			if (member.CensusMemberRelationship == 'Child') {
				parentSelected.push({ 'memberId': member.CensusMemberId, 'value': member.parentSelected });
			}
		});
		return parentSelected;
	}

	getOutputJSON(inputmember, productsList) {
		// "memberName": inputParameter.memberName,
		// "memberId": inputParameter.memberId,
		// "memberRelationship": inputParameter.memberRelationship,
		// "SMART": smart,
		// "SMARTName": smartName,
		// "AIDD": aidd,
		// "AIDDName": aiddName,
		// "Product": core


		console.log('getOutputJSON inputmember', inputmember);
		console.log('getOutputJSON productsList', productsList);
		let outputJSON = [];
		inputmember.forEach(m => {
			if (m.CensusMemberRelationship != 'Child') {
				let outputJSONItem = {
					"memberName": m.CensusMemberName,
					"memberId": m.CensusMemberId,
					"memberRelationship": m.CensusMemberRelationship
				};
				productsList.forEach(p => {
					if (p.CalculatedPriceData) {
						for (const key in p.CalculatedPriceData) {
							if (key !== "Price" && key !== "aggByKey" && key !== "detailPrice") {
								const member = p.CalculatedPriceData[key];
								// If product has the member in Calculated Price Data
								if (member.CensusMemberId == m.CensusMemberId) {
									if (p.SubType__c == "SMART") {
										outputJSONItem.SMART = p.Id;
										outputJSONItem.SMARTName = p.Name;
									}
									else if (p.SubType__c == "AIDD") {
										outputJSONItem.AIDD = p.Id;
										outputJSONItem.AIDDName = p.Name;
									}
								}
							}
						}
					}
				})

				outputJSON.push(outputJSONItem);
			}
		});
		return outputJSON;
	}

	saveChooseProductsState() {
		this.omniApplyCallResp(
			{
				'chooseProductsGridSavedState': {
					'outputJSON': this.outputJSON,
					'idsCreated': this.idsCreated,
					'smartValue': this.smartValue,
					'aiddValue': this.aiddValue,
					'smartValueSpouse': this.smartValueSpouse,
					'aiddValueSpouse': this.aiddValueSpouse,
					'primaryAiddDisabled': this.primaryAiddDisabled,
					'spouseAiddDisabled': this.spouseAiddDisabled,
					'parentSelected': this.parentSelected,
					'depDisabled': this.depDisabled,
					'valueDependents': this.valueDependents,
					'disPrimarySmart': this.disPrimarySmart,
					'disPrimaryAidd': this.disPrimaryAidd,
					'disSpouseSmart': this.disSpouseSmart,
					'shareAiddPrograms': this.shareAiddPrograms,
					'shareSmartPrograms': this.shareSmartPrograms,
					'inputmember': this.inputmember,
					'inputcore': this.inputcore,
					'inputsmart': this.inputsmart,
					'inputaidd': this.inputaidd,
					'lockedproduct': this.lockedproduct,
					// 'inputmember': this.inputmember,
				}
			}
		);
	}

	getChooseProductsSavedState() {
		// this.inputmember = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.inputmember));
		this.outputJSON = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.outputJSON));
		this.idsCreated = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.idsCreated));
		this.smartValue = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.smartValue));
		this.aiddValue = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.aiddValue));
		this.smartValueSpouse = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.smartValueSpouse));
		this.aiddValueSpouse = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.aiddValueSpouse));
		this.primaryAiddDisabled = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.primaryAiddDisabled));
		this.spouseAiddDisabled = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.spouseAiddDisabled));
		this.parentSelected = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.parentSelected));
		this.depDisabled = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.depDisabled));
		this.valueDependents = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.valueDependents));
		this.disPrimarySmart = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.disPrimarySmart));
		this.disPrimaryAidd = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.disPrimaryAidd));
		this.disSpouseSmart = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.disSpouseSmart));
		this.shareAiddPrograms = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.shareAiddPrograms));
		this.shareSmartPrograms = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.shareSmartPrograms));

	}
	sameInput() {
		let inputmemberCondition = JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.inputmember) == JSON.stringify(this.inputmember)
		let inputcoreCondition = JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.inputcore) == JSON.stringify(this.inputcore)
		let inputsmartCondition = JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.inputsmart) == JSON.stringify(this.inputsmart)
		let inputaiddCondition = JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.inputaidd) == JSON.stringify(this.inputaidd)
		let lockedproductCondition = JSON.stringify(this.omniJsonData.chooseProductsGridSavedState.lockedproduct) == JSON.stringify(this.lockedproduct)
		return inputmemberCondition && inputcoreCondition && inputsmartCondition && inputaiddCondition;
	}

}