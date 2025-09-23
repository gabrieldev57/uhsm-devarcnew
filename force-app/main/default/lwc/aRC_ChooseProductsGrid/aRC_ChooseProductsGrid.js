import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_ChooseProductsGrid extends OmniscriptBaseMixin(LightningElement) {
	@api inputmember;
	@api inputcore;
	@api inputsmart;
	@api inputaidd;
	@api lockedproduct;
	@api reason;
	@track onlyProduct;
	outputJSON;
	idsCreated = [];
	smartValue;
	aiddValue;
	smartValueSpouse;
	aiddValueSpouse;
	primaryAiddDisabled = false;
	spouseAiddDisabled = false;
	parentSelected = [];
	depDisabled = true;
	// depDisabled = false;
	valueDependents;
	disPrimarySmart = false;
	disPrimaryAidd = false;
	disSpouseSmart = false;

	shareAiddPrograms = false;
	shareSmartPrograms = false;
	@track showShareSmartPrograms;
	@track showShareAiddPrograms;

	@api keepSmart;
	@api keepAidd;

	changeRun = false;

	// get showShareSmartPrograms() {
	//     if (this.smartValueSpouse == this.smartValue && this.smartValueSpouse != null) {
	//         return true;
	//     } else {
	//         this.shareSmartPrograms = false;
	//         return false;
	//     }
	// }
	// get showShareAiddPrograms() {
	//     if (this.aiddValueSpouse == this.aiddValue && this.aiddValueSpouse != null) {
	//         return true;
	//     } else {
	//         this.shareAiddPrograms = false;
	//         return false;
	//     }
	// }

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
		console.log('this.omniJsonData', this.omniJsonData);
		let options = [{ label: "None", value: "None" }];
		let member = this.inputmember.filter(item => item.CensusMemberRelationship == relationship)[0];

		const isSmart = this.inputsmart == productType;
		const isAidd = this.inputaidd == productType;

		// if ( this.keepAidd && isSmart ) {
		// 	options = [];
		// }

		if (productType && member.productIds.length) {

			if (isSmart) {
				if (relationship == "Primary" && this.smartValue == null) {
					this.smartValue = "None";
					// this.disPrimarySmart = true;
				}
				if (relationship == "Spouse" && this.smartValueSpouse == null) {
					this.smartValueSpouse = "None";
					// this.disSpouseSmart = true;
				}
				if (this.reason.includes('Add Member') && !this.reason.includes('Add Ancillary Product')) {
					switch (relationship) {
						case 'Primary':
							this.disPrimarySmart = true;
							break;
						case 'Spouse':
							this.disSpouseSmart = true;
							break;
						default:
							break;
					}
				}
			}
			if (isAidd) {
				if (relationship == "Primary" && this.aiddValue == null) {
					this.aiddValue = "None";
					// this.disPrimaryAidd = true;
				}
				if (relationship == "Spouse" && this.aiddValueSpouse == null) {
					this.aiddValueSpouse = "None";
					// this.spouseAiddDisabled = true;
				}
				if (this.reason.includes('Add Member') && !this.reason.includes('Add Ancillary Product')) {
					switch (relationship) {
						case 'Primary':
							this.primaryAiddDisabled = true;
							break;
						case 'Spouse':
							this.spouseAiddDisabled = true;
							break
						default:
							break;
					}
				}
			}

			productType.forEach(element => {

				if ((this.keepSmart && !this.keepAidd && isAidd) || (this.keepAidd && !this.keepSmart && isSmart)) {
					options.push({ "label": element.Name, "value": element.Id });
					this.primaryAiddDisabled = false;
					this.spouseAiddDisabled = false;
				}

				member.productIds.forEach(prod => {
					if (prod == element.Id) {

						options.push({ "label": element.Name, "value": element.Id });

						if (relationship == 'Primary' && isSmart) {
							console.log('Changing this.smartValue before', this.smartValue);
							if (!this.changeRun) {
								this.smartValue = element.Id;
							}
							console.log('Changing this.smartValue aft', this.smartValue);
							if (this.keepSmart) {
								this.primaryAiddDisabled = false;
							} else {
								this.disPrimarySmart = true;
							}
						} else if (relationship == 'Primary' && isAidd) {
							if (!this.changeRun) {
								this.aiddValue = element.Id;
							}
							if (!this.keepAidd || this.smartValue == 'None') {
								// this.primaryAiddDisabled = true;
							}
						} else if (relationship == 'Spouse' && isSmart) {
							if (!this.changeRun) {
								this.smartValueSpouse = element.Id;
							}
							if (this.keepSmart) {
								this.spouseAiddDisabled = false;
							} else {
								this.disSpouseSmart = true;
							}
						} else if (relationship == 'Spouse' && isAidd) {
							if (!this.changeRun) {
								this.aiddValueSpouse = element.Id;
							}
							if (!this.keepAidd || this.smartValueSpouse == 'None') {
								// this.spouseAiddDisabled = true;
							}
						}
					}
				})

				if (!options.find(o => o.value == element.Id)) {
					options.push({ "label": element.Name, "value": element.Id });
				}
			});

		} else if (!member.productIds.length) {
			productType.forEach(item => options.push({ label: item.Name, value: item.Id }))
		}

		return options;
	}

	connectedCallback() {
		console.log('this.reason', this.reason);
		this.lockedproduct == 'true' ? this.onlyProduct = this.inputcore[0].Id : null;
		this.depDisabled = false;
		this.outputJSON = {};
	}

	renderedCallback() {
		console.log('In rederedCallback');
		this.inputmember.forEach(item => {
			if (item.CensusMemberRelationship == 'Child') { /*If is a child*/
				if (item.productIds.length) { /*And already has products*/
					let smart = this.inputsmart.filter(prod => item.productIds.includes(prod.Id))[0];
					let aidd = this.inputaidd.filter(prod => item.productIds.includes(prod.Id))[0];

					if (smart != undefined || aidd != undefined) { /*And has products*/
						if (this.reason.includes('Add Member') && !this.reason.includes('Add Ancillary Product')) {
							this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = true;
						}
						if (!this.keepSmart) { /* NOT Keep SMART */
							// this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = true; /*Disable child combobox*/
						} else { /* KEEP SMART */
							this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = false; /*Enable child combobox*/
						}

						// if ( aidd == undefined ) {
						if (!this.keepAidd || (this.keepAidd && this.keepSmart)) { /* NOT Keep AIDD OR (Keep AIDD and Keep SMART) */
							this.template.querySelector("[data-idprod='" + item.CensusMemberId + "SMART']").innerHTML = (smart != undefined ? smart.Name : 'None') + ",&nbsp;"; /*Set SMART Name (SMART of the selected parent)*/
							if (smart != undefined && aidd == undefined) {
								this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").value = this.inputmember.filter(memb => memb.productIds.includes(smart.Id))[0].CensusMemberRelationship; /*Set combobox value (Primary Or Spouse)*/
							}
						}
						// return
						// }
						// if (smart == undefined) {
						if (!this.keepSmart || (this.keepAidd && this.keepSmart)) {
							this.template.querySelector("[data-idprod='" + item.CensusMemberId + "AIDD']").innerHTML = aidd != undefined ? aidd.Name : 'None'; /*Set AIDD Name (AIDD of the selected parent)*/
							if (aidd != undefined && smart == undefined) {
								this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").value = this.inputmember.filter(memb => memb.productIds.includes(aidd.Id))[0].CensusMemberRelationship; /*Set combobox value (Primary Or Spouse)*/
							}
						}
						// return
						// }
						if (smart != undefined && aidd != undefined) {
							this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").value = this.inputmember.filter(memb => memb.productIds.includes(smart.Id) && memb.productIds.includes(aidd.Id))[0].CensusMemberRelationship;
						}
					}


				}
				if (!item.productIds.length) { /*And doesn't have products*/
					let spouse = this.inputmember.find(item => item.CensusMemberRelationship == 'Spouse');
					if (spouse) { /*if exist spouse in the family*/
						if (this.smartValueSpouse && this.aiddValueSpouse) { /*if spouse has products*/
							this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = false; /*Enable child combobox*/
						} else { /*if spouse doesn't have products*/
							this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = true; /*Disable child combobox*/
						}
					} else if (this.smartValue && this.aiddValue) { /*if spouse doesn't exist and primary has products*/
						this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = false; /*Enable child combobox*/
					} else { /*if spouse doesn't exist and primary doesn't have products*/
						this.template.querySelector("[data-iddep='" + item.CensusMemberId + "']").disabled = true; /*Disable child combobox*/
					}
				}
			}
		})

		if (this.keepSmart) {
			this.depDisabled = false;
			console.log('Skipping selection');
			const eventToParent = new CustomEvent("outputjson", { detail: '' })
			this.dispatchEvent(eventToParent);
		}

		this.checkShareOptions();
	}

	handleChangeCoverage(event) {
		this.changeRun = true;
		console.log('In handleChangeCoverage', event);

		const hasSpouse = this.inputmember.some(item => item['RF_Census.CM_IsSpouse'] == true);

		if (event.currentTarget.dataset.protype == 'SMART' && event.currentTarget.dataset.relationship == 'Primary') {
			this.smartValue = event.detail.value;
		}
		if (event.currentTarget.dataset.protype == 'AIDD' && event.currentTarget.dataset.relationship == 'Primary') {
			this.aiddValue = event.detail.value;
		}
		if (event.currentTarget.dataset.protype == 'SMART' && event.currentTarget.dataset.relationship == 'Spouse') {
			this.smartValueSpouse = event.detail.value;
		}
		if (event.currentTarget.dataset.protype == 'AIDD' && event.currentTarget.dataset.relationship == 'Spouse') {
			this.aiddValueSpouse = event.detail.value;
		}


		if (this.smartValue /*&& this.smartValue !== 'None'*/) {
			this.primaryAiddDisabled = false;
		}
		if (this.smartValueSpouse /*&& this.smartValueSpouse !== 'None'*/) {
			this.spouseAiddDisabled = false;
		}
		if (this.smartValue) {
			if (hasSpouse && this.smartValueSpouse) {
				this.depDisabled = false;
			} else if (hasSpouse && !this.smartValueSpouse) {
				this.depDisabled = true;
			} else if (!hasSpouse) {
				this.depDisabled = false;
			} else {
				this.depDisabled = false;
			}
		}
		if (this.smartValue == 'None' && !this.keepAidd) {
			// this.aiddValue = 'None';
			// this.template.querySelector('[data-aidd="primary"]').value = 'None';
			// this.primaryAiddDisabled = true;
		}
		if (this.smartValueSpouse == 'None' && !this.keepAidd) {
			// this.aiddValueSpouse = 'None';
			// this.template.querySelector('[data-aidd="spouse"]').value = 'None';
			// this.spouseAiddDisabled = true;
		}

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
		// }

		if (this.keepSmart || this.keepAidd) {
			this.inputmember.filter(member => member.CensusMemberRelationship == 'Child' && member.productIds.length).forEach(member => {
				const parentProds = this.inputmember.filter(parent => parent.CensusMemberRelationship != 'Child' && parent.productIds.length && member.productIds.every((val, idx) => val === parent.productIds[idx]))[0];
				if (event.currentTarget.dataset.relationship == 'Primary' && parentProds.CensusMemberRelationship == 'Primary') {
					if (this.keepAidd && !this.keepSmart && event.currentTarget.dataset.protype == 'SMART') {
						this.template.querySelector("[data-idprod='" + member.CensusMemberId + "SMART']").innerHTML = (this.smartValue == 'None' || !this.smartValue) ? 'None' : this.inputsmart.find(prod => prod.Id === this.smartValue).Name + ",&nbsp;";
					}
					if (this.keepSmart && !this.keepAidd && event.currentTarget.dataset.protype == 'AIDD') {
						this.template.querySelector("[data-idprod='" + member.CensusMemberId + "AIDD']").innerHTML = (this.aiddValue == 'None' || !this.aiddValue) ? 'None' : this.inputaidd.find(prod => prod.Id === this.aiddValue).Name;
					}
				}
				if (event.currentTarget.dataset.relationship == 'Spouse' && parentProds.CensusMemberRelationship == 'Spouse') {
					if (this.keepAidd && !this.keepSmart && event.currentTarget.dataset.protype == 'SMART') {
						this.template.querySelector("[data-idprod='" + member.CensusMemberId + "SMART']").innerHTML = (this.smartValueSpouse == 'None' || !this.smartValueSpouse) ? 'None' : this.inputsmart.find(prod => prod.Id === this.smartValueSpouse).Name + ",&nbsp;";
					}
					if (this.keepSmart && !this.keepAidd && event.currentTarget.dataset.protype == 'AIDD') {
						this.template.querySelector("[data-idprod='" + member.CensusMemberId + "AIDD']").innerHTML = (this.aiddValueSpouse == 'None' || !this.aiddValueSpouse) ? 'None' : this.inputaidd.find(prod => prod.Id === this.aiddValueSpouse).Name;
					}
				}
			});
		}

		console.log('this.smartValue', this.smartValue);
		this.checkShareOptions();
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
			inputParameter.productSelected !== 'None' ? smartName = this.inputsmart.find(findProduct).Name : smartName = 'None';
		} else if (this.smartValue) {
			smart = this.smartValue;
			smartName = this.inputsmart[0].Name;
		}

		if (inputParameter.productType == 'AIDD' && smart !== 'None') {
			aidd = inputParameter.productSelected;
			inputParameter.productSelected !== 'None' ? aiddName = this.inputaidd.find(findProduct).Name : aiddName = 'None';
		} else if (smart == 'None') {
			aidd = 'None';
			aiddName = 'None';
		} else if (this.aiddValue && smart !== 'None') {
			aidd = this.aiddValue;
			if (this.inputaidd != undefined && this.inputaidd != null && this.inputaidd != "") {
				aiddName = this?.inputaidd[0].Name;
			} else {
				aiddName = "None"
			}
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
					} else if (element.SMART == 'None') {
						element.AIDD = 'None'
						element.AIDDName = 'None';
					}
				}
			});
		}

	}

	handleSelectDepProgram(evt) {
		let memberId = evt.currentTarget.dataset.id;
		let smart = null;
		let aidd = null;

		// if (!this.programchange) {
		// 	const check = element => element.memberId === memberId;
		// 	const changeEvent = new CustomEvent('handlechangevalues');
		// 	this.dispatchEvent(changeEvent);

		// 	if (!this.parentSelected.some(check)) {
		// 		this.parentSelected.push({ 'memberId': memberId, 'value': evt.detail.value });
		// 	} else {
		// 		this.parentSelected.forEach(element => {
		// 			if (element.memberId == memberId) element.value = evt.detail.value;
		// 		});
		// 	}
		// 	this.outputJSON.forEach(item => {
		// 		if (evt.detail.value == 'Primary' && item.memberRelationship == 'Primary') {
		// 			smart = item.SMARTName;
		// 			item.AIDDName !== null ? aidd = item.AIDDName : aidd = 'None';
		// 		} else if (evt.detail.value == 'Spouse' && item.memberRelationship == 'Spouse') {
		// 			smart = item.SMARTName;
		// 			item.AIDDName !== null ? aidd = item.AIDDName : aidd = 'None';

		// 		}
		// 		else if (evt.detail.value == 'None') {
		// 			smart = 'None';
		// 			aidd = 'None';
		// 		}

		// 		const eventToParent = new CustomEvent("outputdep", { detail: this.parentSelected })
		// 		this.dispatchEvent(eventToParent);
		// 	});
		// }
		// else{
		if (evt.detail.value == 'Primary') {
			smart = this.optionsSmartProduct.filter(item => item.value == this.smartValue)[0].label;
			if (this.aiddValue && this.aiddValue != 'None') {
				aidd = this.optionsAiddProduct.filter(item => item.value == this.aiddValue)[0].label;
			} else {
				aidd = "None";
			}
		}
		else if (evt.detail.value == 'Spouse') {
			smart = this.optionsSmartProductSpouse.filter(item => item.value == this.smartValueSpouse)[0].label;
			if (this.aiddValueSpouse && this.aiddValueSpouse != 'None') {
				aidd = this.optionsAiddProductSpouse.filter(item => item.value == this.aiddValueSpouse)[0].label;
			} else {
				aidd = "None";
			}
		}
		else if (evt.detail.value == 'None') {
			smart = 'None'
			aidd = 'None'
		}

		this.outputJSON = { memberId: memberId, productsFrom: evt.detail.value }
		const eventToParent = new CustomEvent("outputdep", { detail: this.outputJSON })
		this.dispatchEvent(eventToParent);
		// }

		this.template.querySelector("[data-idprod='" + memberId + "SMART']").innerHTML = smart + ",&nbsp;";
		this.template.querySelector("[data-idprod='" + memberId + "AIDD']").innerHTML = aidd;
	}

	handleShareAiddOnChange(event) {
		this.shareAiddPrograms = event.target.checked;
		const eventToParent = new CustomEvent("shareaiddprograms", { detail: event.target.checked })
		this.dispatchEvent(eventToParent);
	}
	handleShareSmartOnChange(event) {
		this.shareSmartPrograms = event.target.checked;
		const eventToParent = new CustomEvent("sharesmartprograms", { detail: event.target.checked })
		this.dispatchEvent(eventToParent);
	}

	checkShareOptions() {
		console.log('In checkShareOptions');
		console.log('this.smartValueSpouse', this.smartValueSpouse);
		console.log('this.smartValue', this.smartValue);

		// Checking SMART Options
		if (this.smartValueSpouse == this.smartValue && this.smartValueSpouse != null && this.smartValueSpouse != 'None') {
			console.log('In smart true');
			this.showShareSmartPrograms = true;
		} else {
			console.log('In smart false');
			this.showShareSmartPrograms = false;
		}
		// Checking AIDD Options
		if (this.aiddValueSpouse == this.aiddValue && this.aiddValueSpouse != null && this.aiddValueSpouse != 'None') {
			console.log('In aidd true');
			this.showShareAiddPrograms = true;
		} else {
			console.log('In aidd false');
			this.showShareAiddPrograms = false;
		}
	}
}