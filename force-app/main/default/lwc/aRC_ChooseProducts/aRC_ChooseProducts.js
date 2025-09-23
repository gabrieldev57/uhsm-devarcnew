import { LightningElement, api } from "lwc";
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";

export default class ARC_ChooseProducts extends OmniscriptBaseMixin(
	LightningElement
) {
	shareSmartPrograms = false;
	shareAiddPrograms = false;
	@api membersAndPlans;
	@api lockedProduct;
	@api coverageDependents;
	@api chooseProdProgramChange;
	members;
	smartSaved = false;
	aiddSaved = false;
	membersRecived;
	coreProducts;
	smartProducts;
	aiddProducts;
	checkDependents;
	outputPrimaries = [];
	outputDep = [];
	outputOfRepriceProducts = { records: [] };
	isLoading = false;
	areProgramRepriced = false;
	@api productList;
	reason = '';

	keepSmart;
	keepAidd;

	fixedRepriceProductsInput = [];

	handleShareSmartProgam(event) {
		this.shareSmartPrograms = event.detail;
	}
	handleShareAiddProgam(event) {
		this.shareAiddPrograms = event.detail;
	}

	connectedCallback() {
		this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
		//console.log('this.osData', this.osData);
		this.reason = this.osData.Reason;
		this.keepSmart = this.osData.showAddAncillaryChooseProductsKeepSMART;
		this.keepAidd = this.osData.showAddAncillaryChooseProductsKeepAIDD;
		//
		//


		if (this.membersAndPlans) {
			this.checkDependents = JSON.parse(
				JSON.stringify(this.membersAndPlans)
			).member;
			let inputMembers = JSON.parse(
				JSON.stringify(this.membersAndPlans)
			).member;
			this.coreProducts = JSON.parse(
				JSON.stringify(this.membersAndPlans)
			).coreProducts;
			this.smartProducts = JSON.parse(
				JSON.stringify(this.membersAndPlans)
			).smartProducts;
			this.aiddProducts = JSON.parse(
				JSON.stringify(this.membersAndPlans)
			).aiddProducts;

			inputMembers.forEach((element) => {
				element["RF_Census.CM_IsPrimary"]
					? (element["isPrimary"] = true)
					: (element["isPrimary"] = false);
				element["CensusMemberRelationship"] == "Spouse"
					? (element["isSpouse"] = true)
					: (element["isSpouse"] = false);
				element["RF_Census.CM_IsPrimary"] == false &&
					element["CensusMemberRelationship"] != "Spouse"
					? (element["isDependent"] = true)
					: (element["isDependent"] = false);
				element["memberIdSMART"] = element.CensusMemberId + "SMART";
				element["memberIdAIDD"] = element.CensusMemberId + "AIDD";
				if (!element.productIds) element["productIds"] = [];
				if (element.CensusMemberRelationship == null)
					element.CensusMemberRelationship = "Primary";
				if (element.isPrimary) {
					element["sortNode"] = 1;
				} else if (element.isSpouse) {
					element["sortNode"] = 2;
				} else {
					element["sortNode"] = 3;
				}
				if (element.parentSMART) {
					element.SMARTchildOf = element.parentSMART;
				}
				if (element.parentAIDD) {
					element.AIDDchildOf = element.parentAIDD;
				}
			});
			this.checkDependents.forEach((element) => {
				element["assigned"] = false;
			});
			inputMembers.sort(function (a, b) {
				return a.sortNode - b.sortNode;
			});
			this.members = inputMembers;

			this.members
				.filter(
					(member) =>
						member.CensusMemberRelationship == "Primary" ||
						member.CensusMemberRelationship == "Spouse"
				)
				.forEach((member) => {
					let currentMember = {};
					currentMember["memberId"] = member.CensusMemberId;
					// Set SMART Product
					if (Array.isArray(this.smartProducts)) {
						currentMember["smartId"] = this.smartProducts.find((smart) =>
							member.productIds.includes(smart.productId)
						)?.productId;
					} else if (this.smartProducts) {
						const tempSmartProducts = [this.smartProducts];
						currentMember["smartId"] = tempSmartProducts.find((smart) =>
							member.productIds.includes(smart.productId)
						)?.productId;
					}
					// Set AIDD Product
					if (Array.isArray(this.aiddProducts)) {
						currentMember["aiddId"] = this.aiddProducts.find((aidd) =>
							member.productIds.includes(aidd.productId)
						)?.productId;
					} else if (this.aiddProducts) {
						const tempAiddProducts = [this.aiddProducts];
						currentMember["aiddId"] = tempAiddProducts.find((aidd) =>
							member.productIds.includes(aidd.productId)
						)?.productId;
					}
					this.outputPrimaries.push(currentMember);
				});
		}

		if (this.keepSmart || this.keepAidd) {
			this.areProgramRepriced = true;
		}

	}

	handleGetOuputGrid(event) {
		if (
			(this.keepSmart || this.keepAidd) &&
			(!this.outputDep || !this.outputDep.length)
		) {
			this.members
				.filter(
					(member) =>
						member.CensusMemberRelationship == "Child" &&
						member.productIds.length
				)
				.forEach((member) => {
					let currentMember = {};
					currentMember["memberId"] = member.CensusMemberId;
					const parentProds = this.members.filter(
						(parent) =>
							parent.CensusMemberRelationship != "Child" &&
							parent.productIds.length &&
							member.productIds.every(
								(val, idx) => val === parent.productIds[idx]
							)
					)[0];
					currentMember["productsFrom"] = parentProds.CensusMemberRelationship;
					this.outputDep.push(currentMember);
				});
		}

		// Define outputPrimaries if not existing
		if (!this.outputPrimaries || !this.outputPrimaries.length) {
			this.members
				.filter(
					(member) =>
						member.CensusMemberRelationship == "Primary" &&
						member.productIds.length
				)
				.forEach((member) => {
					let currentMember = {};
					currentMember["memberId"] = member.CensusMemberId;
					// Set SMART Product
					if (Array.isArray(this.smartProducts)) {
						currentMember["smartId"] = this.smartProducts.find((smart) =>
							member.productIds.includes(smart?.productId)
						)?.productId;
						currentMember["smartId"] =
							currentMember["smartId"] == undefined
								? "None"
								: currentMember["smartId"];
					} else if (this.smartProducts) {
						const tempSmartProducts = [this.smartProducts];
						currentMember["smartId"] = tempSmartProducts.find((smart) =>
							member.productIds.includes(smart?.productId)
						)?.productId;
						currentMember["smartId"] =
							currentMember["smartId"] == undefined
								? "None"
								: currentMember["smartId"];
					}
					// Set AIDD Product
					if (Array.isArray(this.aiddProducts)) {
						currentMember["aiddId"] = this.aiddProducts.find((aidd) =>
							member.productIds.includes(aidd?.productId)
						)?.productId;
						currentMember["aiddId"] =
							currentMember["aiddId"] == undefined
								? "None"
								: currentMember["aiddId"];
					} else if (this.aiddProducts) {
						const tempAiddProducts = [this.aiddProducts];
						currentMember["aiddId"] = tempAiddProducts.find((aidd) =>
							member.productIds.includes(aidd?.productId)
						)?.productId;
						currentMember["aiddId"] =
							currentMember["aiddId"] == undefined
								? "None"
								: currentMember["aiddId"];
					}
					this.outputPrimaries.push(currentMember);
				});
		}

		let hasAncillary = this.osData.oldProducts?.filter(
			(item) => item.Type__c == "Ancillary"
		);
		let btnEnabled = true;
		if (!this.keepSmart && !this.keepAidd) {
			this.outputDep = [];
		}
		if (!this.outputPrimaries.length) {
			if (event.detail != "") {
				if (event.detail.smartId == "None") {
					this.outputPrimaries.push({
						memberId: event.detail.memberId,
						smartId: "None",
						aiddId: "None",
					});
					this.checkDependents.forEach((element) => {
						if (element.CensusMemberId == event.detail.memberId) {
							element.assigned = true;
						}
					});
				} else {
					this.outputPrimaries.push({
						memberId: event.detail.memberId,
						smartId: event.detail.smartId,
						aiddId: event.detail.aiddId,
					});
					this.checkDependents.forEach((element) => {
						if (element.CensusMemberId == event.detail.memberId) {
							element.assigned = true;
						}
					});
				}
			}
		} else {
			if (event.detail != "") {
				const sameMember = this.outputPrimaries.find(
					(item) => item.memberId == event.detail.memberId
				);

				if (sameMember) {
					if (event.detail.smartId != null && event.detail.smartId != "None") {
						sameMember.smartId = event.detail.smartId;
					} else if (event.detail.smartId == "None") {
						sameMember.smartId = "None";
						sameMember.aiddId = "None";
					} else if (event.detail.aiddId != null) {
						sameMember.aiddId = event.detail.aiddId;
					}

					this.outputPrimaries.forEach((element) => {
						if (sameMember.memberId == element.memberId) {
							element = sameMember;
						}
					});
					this.checkDependents.forEach((element) => {
						if (element.CensusMemberId == sameMember.memberId) {
							element.assigned = true;
						}
					});
				} else {
					if (event.detail.smartId == "None") {
						this.outputPrimaries.push({
							memberId: event.detail.memberId,
							smartId: "None",
							aiddId: "None",
						});
						this.checkDependents.forEach((element) => {
							if (element.CensusMemberId == event.detail.memberId) {
								element.assigned = true;
							}
						});
					} else {
						this.outputPrimaries.push({
							memberId: event.detail.memberId,
							smartId: event.detail.smartId,
							aiddId: event.detail.aiddId,
						});
						this.checkDependents.forEach((element) => {
							if (element.CensusMemberId == event.detail.memberId) {
								element.assigned = true;
							}
						});
					}
				}
			}
		}

		this.members
			.filter((item) => !item.productIds.length)
			.forEach((element) => {
				const primaryMemb = this.outputPrimaries.find(
					(item) => item.memberId == element.CensusMemberId
				);
				const depMemb = this.outputDep.find(
					(item) => item.memberId == element.CensusMemberId
				);

				if (!primaryMemb && !depMemb) {
					btnEnabled = false;
				}
			});

		this.areProgramRepriced = btnEnabled;
	}

	handleGetDepGrid(event) {
		//
		//

		// Define outputPrimaries if not existing
		if (!this.outputPrimaries || !this.outputPrimaries.length) {
			this.members
				.filter(
					(member) =>
						member.CensusMemberRelationship == "Primary" ||
						member.CensusMemberRelationship == "Spouse"
				)
				.forEach((member) => {
					let currentMember = {};
					currentMember["memberId"] = member.CensusMemberId;
					// Set SMART Product
					if (Array.isArray(this.smartProducts)) {
						currentMember["smartId"] = this.smartProducts.find((smart) =>
							member.productIds.includes(smart.productId)
						)?.productId;
					} else if (this.smartProducts) {
						const tempSmartProducts = [this.smartProducts];
						currentMember["smartId"] = tempSmartProducts.find((smart) =>
							member.productIds.includes(smart.productId)
						)?.productId;
					}
					// Set AIDD Product
					if (Array.isArray(this.aiddProducts)) {
						currentMember["aiddId"] = this.aiddProducts.find((aidd) =>
							member.productIds.includes(aidd.productId)
						)?.productId;
					} else if (this.aiddProducts) {
						const tempAiddProducts = [this.aiddProducts];
						currentMember["aiddId"] = tempAiddProducts.find((aidd) =>
							member.productIds.includes(aidd.productId)
						)?.productId;
					}
					this.outputPrimaries.push(currentMember);
				});
		}

		if (!this.outputDep) {
			this.outputDep = [];
			this.outputDep.push(event.detail);
			this.checkDependents.forEach((element) => {
				if (element.CensusMemberId == event.detail.memberId) {
					element.assigned = true;
				}
			});
		} else {
			let sameMember = this.outputDep.filter(
				(item) => item.memberId == event.detail.memberId
			);
			if (sameMember.length) {
				sameMember[0].productsFrom = event.detail.productsFrom;
			} else {
				this.outputDep.push(event.detail);
			}
			this.checkDependents.forEach((element) => {
				if (element.CensusMemberId == event.detail.memberId) {
					element.assigned = true;
				}
			});
		}
		let btnEnabled = false;
		if (
			this.osData?.FieldsetType == "IFPProgramChangeAddMember" ||
			this.osData?.FieldsetType == "IFPProgramChangeMultiple" ||
			this.osData?.AddExistingMember == true
		) {
			btnEnabled = true;
			this.members
				.filter((item) => !item.productIds.length)
				.forEach((element) => {
					const depMemb = this.outputDep.find(
						(item) => item.memberId == element.CensusMemberId
					);
					if (!depMemb) {
						btnEnabled = false;
					} else {
						btnEnabled = true;
					}
				});
		}

		if (!Array.isArray(this.outputPrimaries)) {
			this.outputPrimaries = [this.outputPrimaries];
		}

		//console.log('aaaaaaaaaaaathis.outputPrimaries', this.outputPrimaries);
		//console.log('this.checkDependents', this.checkDependents);
		if (
			this.outputPrimaries.find(
				(item) => /*item.smartId != "None" && */item.smartId != null && item.aiddId != null
			) &&
			!this.checkDependents.find((item) => item.assigned == false)
		) {
			btnEnabled = true;
		}
		this.members
			.filter((item) => !item.productIds.length)
			.forEach((element) => {
				const primaryMemb = this.outputPrimaries.find(
					(item) => item.memberId == element.CensusMemberId
				);
				const depMemb = this.outputDep.find(
					(item) => item.memberId == element.CensusMemberId
				);

				if (!primaryMemb && !depMemb) {
					btnEnabled = false;
				}
				// if(!this.outputPrimaries.find(item => item.smartId != "None")){
				//     btnEnabled = false;
				// }
			});

		this.areProgramRepriced = btnEnabled;
		// this.members.filter(item => !item.productIds.length).length <= this.outputPrimaries.filter(item => item.smartId != null && item.aiddId != null).length + this.outputDep.length ? this.areProgramRepriced = true : this.areProgramRepriced = false;
		// }
	}
	nextButtonVisibility() { }

	async handleSendDataToSummary() {
		this.isLoading = true;
		if (await this.mergeDataRecived(this.outputPrimaries, this.outputDep)) {
			const response = await this.callRepriceProducts(
				this.membersRecived,
				this.smartProducts,
				this.aiddProducts
			);
			this.template
				.querySelector("c-a-r-c_-choose-product-summary")
				.repriceProductOutput(response);
			this.omniUpdateDataJson(response);
		} else {
			this.isLoading = false;
		}
	}

	async mergeDataRecived(primaries, dependents) {
		let fieldsMissing = true;






		if (dependents) {
			dependents.forEach((item) => {
				if (item.value == "Primary") {
					let primary = primaries.find(
						(element) => element.memberRelationship == "Primary"
					);
					primaries.push({
						memberId: item.memberId,
						SMART: primary.SMART,
						AIDD: primary.AIDD,
						Product: primary.Product,
						SMARTchildOf: this.shareSmartPrograms ? "Primary" : item.value,
						AIDDchildOf: this.shareAiddPrograms ? "Primary" : item.value,
					});
				} else if (item.value == "Spouse") {
					let spouse = primaries.find(
						(element) => element.memberRelationship == "Spouse"
					);
					primaries.push({
						memberId: item.memberId,
						SMART: spouse.SMART,
						AIDD: spouse.AIDD,
						Product: spouse.Product,
						SMARTchildOf: this.shareSmartPrograms ? "Primary" : item.value,
						AIDDchildOf: this.shareAiddPrograms ? "Primary" : item.value,
					});
				} else if (item.value == "None") {
					let None = primaries.find(
						(element) => element.memberRelationship == "Primary"
					);
					primaries.push({
						memberId: item.memberId,
						SMART: "None",
						AIDD: "None",
						Product: None.Product,
						SMARTchildOf: this.shareSmartPrograms ? "Primary" : item.value,
						AIDDchildOf: this.shareAiddPrograms ? "Primary" : item.value,
					});
				}
			});
		} else {
			const even = (element) => element.CensusMemberRelationship == "Child";
			if (even == "None") {
				fieldsMissing = false;
			} else {
				this.members.some(even)
					? (fieldsMissing = true)
					: (fieldsMissing = false);
			}
		}
		if (primaries) {
			let membersMatchPrimary = [];
			this.members.forEach((member) => {
				primaries.forEach((primary) => {
					if (member.CensusMemberId === primary.memberId) {
						membersMatchPrimary.push(member);
					}
				});
			});
			membersMatchPrimary.forEach((member) => {
				// if ( !fieldsMissing ) {
				primaries.forEach((item) => {
					if (member.CensusMemberId == item.memberId) {
						member["Product"] = item.Product;
						member["SMART"] = item.SMART;
						member["AIDD"] = item.AIDD;
						member["SMARTchildOf"] = item.SMARTchildOf;
						member["AIDDchildOf"] = item.AIDDchildOf;
					}
				});
				if (
					member.Product !== null &&
					member.Product !== undefined &&
					member.SMART !== null &&
					member.SMART !== undefined &&
					member.AIDD !== null &&
					member.AIDD !== undefined
				) {
					//
					const prod = this.coreProducts.find(
						(item) => item.Id === member.Product
					);
					const smart = this.smartProducts.find(
						(item) => item.Id === member.SMART
					);
					member.Product !== "None"
						? (member["codeProduct"] = prod.ProductCode)
						: (member["codeProduct"] = "None");
					member.SMART !== "None"
						? (member["codeSMART"] = smart.ProductCode)
						: (member["codeSMART"] = "None");

					if (this.aiddProducts) {
						const aidd = this.aiddProducts.find(
							(item) => item.Id === member.AIDD
						);
						member.AIDD !== "None"
							? (member["codeAIDD"] = aidd.ProductCode)
							: (member["codeAIDD"] = "None");
					} else {
						member["codeAIDD"] = "None";
					}
					fieldsMissing = false;
				} else if (
					member.SMART == "None" &&
					member.AIDD == null &&
					member.AIDD == undefined
				) {
					const prod = this.coreProducts.find(
						(item) => item.Id === member.Product
					);
					member.Product !== "None"
						? (member["codeProduct"] = prod.ProductCode)
						: (member["codeProduct"] = "None");
					member["codeSMART"] = "None";
					member["codeAIDD"] = "None";
					fieldsMissing = false;
				} else if (member.SMART == "None" && member.AIDD == "None") {
					const prod = this.coreProducts.find(
						(item) => item.Id === member.Product
					);
					member.Product !== "None"
						? (member["codeProduct"] = prod.ProductCode)
						: (member["codeProduct"] = "None");
					member["codeSMART"] = "None";
					member["codeAIDD"] = "None";
					fieldsMissing = false;
				} else {
					fieldsMissing = true;
				}
				// }
			});
		} else {
			fieldsMissing = true;
		}
		//console.log('this.membersBEFORE', JSON.parse(JSON.stringify(this.members)));
		this.members.forEach((element) => {
			//console.log('elementName', element.CensusMemberName);
			//console.log('element.parentSMART', element.parentSMART);
			if (element.parentSMART) {
				element.codeSMART = this.members.find((item) => item.CensusMemberRelationship == element.SMARTchildOf).codeSMART;
				//console.log('element.codeSMART', element.codeSMART);
			}
			if (element.parentAIDD) {
				element.codeAIDD = this.members.find((item) => item.CensusMemberRelationship == element.AIDDchildOf).codeAIDD;
				//console.log('element.codeAIDD', element.codeAIDD);
			}
		});
		//console.log('this.membersAFTER', JSON.parse(JSON.stringify(this.members)));

		if (fieldsMissing) {
			alert("You are missing some fields");
			return false;
		} else {
			//console.log('this.members', JSON.parse(JSON.stringify(this.members)));
			let input = {
				censusMemberDataList: this.members,
				shareSmartPrograms: this.shareSmartPrograms,
				shareAiddPrograms: this.shareAiddPrograms,
			};

			const params = {
				input: input,
				sClassName: "ARC_CensusMemberToUserInputsGuestUsers",
				sMethodName: "ARC_UserInputsForAncillaryPrograms",
				options: "{}",
			};
			await this.omniRemoteCall(params, true)
				.then((response) => {
					this.membersRecived = response.result.resp;

				})
				.catch((error) => {
					//
				});

			return true;
		}
	}
	async callRepriceProducts(members, smarts, aidds) {
		//console.log('members', JSON.parse(JSON.stringify(members)));
		//console.log('smarts', JSON.parse(JSON.stringify(smarts)));
		//console.log('aidds', JSON.parse(JSON.stringify(aidds)));

		const repriceProductsInput = [];



		this.outputOfRepriceProducts.records = [this.coreProducts[0]];
		let products = Object.keys(members);

		products.forEach((element) => {
			if (element != "None") {
				let smart = smarts.find(
					(item) => item.ProductCode == element.split("|")[0]
				);
				let aidd = null;
				if (aidds) {
					aidd = aidds.find(
						(item) => item.ProductCode == element.split("|")[0]
					);
				}



				if (smart) {
					repriceProductsInput.push({
						element: element,
						selectedProduct: smart,
						userInputs: members[element]
					});
				} else if (aidd) {
					repriceProductsInput.push({
						element: element,
						selectedProduct: aidd,
						userInputs: members[element]
					});
				}
			}
		});
		this.isLoading = false;


		this.fixedRepriceProductsInput = [];
		for (let index = 0; index < repriceProductsInput.length; index++) {
			const element = repriceProductsInput[index];
			const memberIds = members[element.element].map((memb) => { return memb.CensusMemberId });

			const mm = element.userInputs.filter((ui) => memberIds.includes(ui.CensusMemberId));
			this.fixedRepriceProductsInput.push({
				userInputs: mm,
				selectedProduct: element.selectedProduct
			});
		}




		return true;
	}

	handleChangeValue() {
		this.areProgramRepriced = false;
	}

	async handleNext() {
		let primary = [];
		let dependent = this.outputDep;

		this.outputPrimaries.forEach((item) => {
			let obj = {};
			obj["memberName"] = this.members.find(
				(element) => element.CensusMemberId == item.memberId
			).CensusMemberName;
			obj["memberId"] = item.memberId;
			obj["memberRelationship"] = this.members.find(
				(element) => element.CensusMemberId == item.memberId
			).CensusMemberRelationship;
			obj["SMART"] = item.smartId != undefined ? item.smartId : "None";
			if (item.Name != undefined && item.Name != null && item.Name != "") {
				obj["SMARTName"] = this.smartProducts.find(
					(element) => element.Id == item.smartId
				).Name;
			} else {
				obj["SMARTName"] = "None";
			}

			obj["AIDD"] = item.aiddId != undefined ? item.aiddId : "None";
			if (item.Name != undefined && item.Name != null && item.Name != "") {
				obj["AIDDName"] = this.aiddProducts.find(
					(element) => element.Id == item.aiddId
				).Name;
			} else {
				obj["AIDDName"] = "None";
			}
			obj["Product"] = this.coreProducts[0].Id;
			primary.push(obj);
		});
		dependent.forEach((item) => (item["value"] = item.productsFrom));

		if (await this.mergeDataRecived(primary, dependent)) {
			let response = [];
			if (await this.callRepriceProducts(
				this.membersRecived,
				this.smartProducts,
				this.aiddProducts
			)) {
				response = this.fixedRepriceProductsInput;
				//console.log('response fixedRepriceProductsInput', JSON.parse(JSON.stringify(response)));
			}


			response.push({
				selectedProduct: this.coreProducts[0],
				userInputs: this.members,
			});

			let realResponse = [];
			for (let index = 0; index < response.length; index++) {
				const element = response[index];
				if (element.selectedProduct.Price) {
					realResponse.push(element);
				}
			}



			// this.omniUpdateDataJson((realResponse));

			this.omniUpdateDataJson(this.removeDuplicates(realResponse));
			// //
			this.omniNextStep();

		}
	}

	handlePrev() {
		this.omniPrevStep();
	}




	removeDuplicates(list) {
		const uniqueList = [];

		for (const item of list) {
			let isDuplicate = false;

			for (const uniqueItem of uniqueList) {
				if (
					item.selectedProduct.Id === uniqueItem.selectedProduct.Id &&
					this.areUserInputsEqual(item.userInputs, uniqueItem.userInputs)
				) {
					isDuplicate = true;
					break;
				}
			}

			if (!isDuplicate) {
				uniqueList.push(item);
			}
		}

		return uniqueList;
	}

	areUserInputsEqual(inputs1, inputs2) {
		if (inputs1.length !== inputs2.length) {
			return false;
		}

		const copy1 = [...inputs1];
		const copy2 = [...inputs2];

		copy1.sort((a, b) => a.CensusMemberId.localeCompare(b.CensusMemberId));
		copy2.sort((a, b) => a.CensusMemberId.localeCompare(b.CensusMemberId));

		for (let i = 0; i < copy1.length; i++) {
			if (copy1[i].CensusMemberId !== copy2[i].CensusMemberId) {
				return false;
			}
		}

		return true;
	}







	// Assume that list1 and list2 are arrays of JSON objects with id properties
	checkIds(list1, list2) {
		// Create a set of ids from list2

		// Loop through list1 and check if any id is not in the set
		for (let obj of list1) {
			if (!(list2.map(obj2 => obj2.id).has(obj.id))) {
				// Return true if any id (list1) is not in the set (list2 ids)
				return true;
			}
		}
		// Return false if all ids are in the set
		return false;
	}
}