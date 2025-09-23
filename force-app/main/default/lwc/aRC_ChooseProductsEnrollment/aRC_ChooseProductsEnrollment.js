import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

export default class ARC_ChooseProductsEnrollment extends OmniscriptBaseMixin(LightningElement) {
    @api membersAndPlans;
    @api lockedProduct;
    @api coverageDependents;
    @track shareSmartPrograms = false;
    @track shareAiddPrograms = false;
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
    outputOfRepriceProducts = { 'records': [] };
    isLoading = false;
    areProgramRepriced = false;

    handleShareSmartProgam(event) {
        this.shareSmartPrograms = event.detail;
    }
    handleShareAiddProgam(event) {
        this.shareAiddPrograms = event.detail;
    }

    connectedCallback() {
        // this.aiddProducts = [];
        // this.smartProducts = [];
        // this.coreProducts = [];
        if (this.omniJsonData.chooseProductsSavedState && this.sameInput()) {
            console.log('sameInput', this.sameInput())
            // if (this.omniJsonData.chooseProductsSavedState && !this.inputLWCHasChanged()) {
            this.getChooseProductsSavedState();
        } else {
            console.log(JSON.parse(JSON.stringify(this.membersAndPlans)))

            if (this.membersAndPlans) {
                this.checkDependents = JSON.parse(JSON.stringify(this.membersAndPlans)).member;
                let inputMembers = JSON.parse(JSON.stringify(this.membersAndPlans)).member;
                this.coreProducts = JSON.parse(JSON.stringify(this.membersAndPlans)).coreProducts;
                this.smartProducts = JSON.parse(JSON.stringify(this.membersAndPlans)).smartProducts;
                this.aiddProducts = JSON.parse(JSON.stringify(this.membersAndPlans)).aiddProducts;

                inputMembers.forEach(element => {
                    element['RF_Census.CM_IsPrimary'] ? element['isPrimary'] = true : element['isPrimary'] = false;
                    element['CensusMemberRelationship'] == 'Spouse' ? element['isSpouse'] = true : element['isSpouse'] = false;
                    element['RF_Census.CM_IsPrimary'] == false && element['CensusMemberRelationship'] != 'Spouse' ? element['isDependent'] = true : element['isDependent'] = false;
                    element['memberIdSMART'] = element.CensusMemberId + 'SMART';
                    element['memberIdAIDD'] = element.CensusMemberId + 'AIDD';
                    // element['parentSelected'] = 'None'
                    if (!element.productIds) element['productIds'] = [];
                    if (element.CensusMemberRelationship == null) element.CensusMemberRelationship = 'Primary';
                    if (element.isPrimary) {
                        element['sortNode'] = 1;
                    } else if (element.isSpouse) {
                        element['sortNode'] = 2;
                    } else {
                        element['sortNode'] = 3;
                    }
                });
                this.checkDependents.forEach(element => {
                    element['assigned'] = false;
                });
                inputMembers.sort(function (a, b) {
                    return a.sortNode - b.sortNode;
                });

                this.members = inputMembers;

            }
        }
    }

    handleGetOuputGrid(event) {
        let btnEnabled = true;
        this.outputPrimaries = event.detail;
        if (!Array.isArray(this.outputPrimaries)) {
            this.outputPrimaries = [this.outputPrimaries];
        }
        if (this.outputPrimaries?.find(item => item.smartId != null)) {
            this.smartSaved = true;
        }

        if (this.outputPrimaries?.find(item => item.aiddId != null)) {
            this.aiddSaved = true;
        }

        this.checkDependents?.forEach(element => {
            if (element.CensusMemberId == event.detail.memberId) {
                element.assigned = true;
            }
        });
        this.members.filter(item => !item.productIds.length).forEach(element => {
            const primaryMemb = this.outputPrimaries.find(item => item.memberId == element.CensusMemberId);
            // const depMemb = this.outputDep.find(item => item.memberId == element.CensusMemberId);
            if (!primaryMemb) {
                btnEnabled = false;
            }
        });
        if (!this.smartSaved || !this.aiddSaved) {
            btnEnabled = false;
        } else {
            this.smartSaved = false;
            this.aiddSaved = false;
        }
        this.areProgramRepriced = btnEnabled;
    }

    handleGetDepGrid(event) {
        this.outputDep = event.detail;
        this.members.forEach(element => {
            // if (this.outputDep.find(item => item.memberId == element.CensusMemberId)) {
            element.parentSelected = this.outputDep.find(item => item.memberId == element.CensusMemberId)?.value;
            // }
        });
        this.saveChooseProductsState();
    }

    async handleSendDataToSummary() {
        this.isLoading = true;
        if (await this.mergeDataRecived(this.outputPrimaries, this.outputDep)) {
            console.log('this.membersRecived =>', this.membersRecived);
            console.log('this.smartProducts =>', this.smartProducts);
            console.log('this.aiddProducts =>', this.aiddProducts);
            const response = await this.callRepriceProducts(this.membersRecived, this.smartProducts, this.aiddProducts);
            this.template.querySelector('c-a-r-c_-choose-product-summary').repriceProductOutput(response);
            this.omniUpdateDataJson(response);
        } else {
            this.isLoading = false;
        }
    }

    async mergeDataRecived(primaries, dependents) {
        let fieldsMissing = true;
        if (dependents) {
            dependents.forEach(item => {


                if (item.value == 'Primary') {
                    let primary = primaries.find(element => element.memberRelationship == 'Primary');
                    primaries.push({ 'memberId': item.memberId, 'SMART': primary.SMART, 'AIDD': primary.AIDD, 'Product': primary.Product, 'SMARTchildOf': this.shareSmartPrograms ? 'Primary' : item.value, 'AIDDchildOf': this.shareAiddPrograms ? 'Primary' : item.value });

                } else if (item.value == 'Spouse') {
                    let spouse = primaries.find(element => element.memberRelationship == 'Spouse');
                    primaries.push({ 'memberId': item.memberId, 'SMART': spouse.SMART, 'AIDD': spouse.AIDD, 'Product': spouse.Product, 'SMARTchildOf': this.shareSmartPrograms ? 'Primary' : item.value, 'AIDDchildOf': this.shareAiddPrograms ? 'Primary' : item.value });


                } else if (item.value == 'None') {
                    let None = primaries.find(element => element.memberRelationship == 'Primary');
                    primaries.push({ 'memberId': item.memberId, 'SMART': 'None', 'AIDD': 'None', 'Product': None.Product, 'SMARTchildOf': this.shareSmartPrograms ? 'Primary' : item.value, 'AIDDchildOf': this.shareAiddPrograms ? 'Primary' : item.value });

                }
            });
        } else {
            const even = (element) => element.CensusMemberRelationship == 'Child';
            if (even == 'None') {
                fieldsMissing = false;
            } else {
                this.members.some(even) ? fieldsMissing = true : fieldsMissing = false;

            }
        }

        if (primaries) {
            console.log('this.members', this.members);
            this.members.forEach(member => {
                //if member is in primaries
                if (primaries.find(item => item.memberId == member.CensusMemberId)) {

                    primaries.forEach(item => {
                        if (member.CensusMemberId == item.memberId) {
                            member['Product'] = item.Product;
                            member['SMART'] = item.SMART;
                            member['AIDD'] = item.AIDD;
                            member['SMARTchildOf'] = item.SMARTchildOf;
                            member['AIDDchildOf'] = item.AIDDchildOf;
                        }
                    })
                    if (member.Product && (member.SMART || member.AIDD)) { // Member has medical + SMART or AIDD selected
                        // console.log('this.smartProducts =>', this.smartProducts);
                        // console.log('this.aiddProducts =>', this.aiddProducts);
                        // console.log('member.SMART =>', member.SMART);
                        // console.log('member.AIDD =>', member.AIDD);

                        const prod = this.coreProducts.find(item => item.Id === member.Product);
                        member.Product !== 'None' ? member['codeProduct'] = prod.ProductCode : member['codeProduct'] = 'None';

                        
                        if (this.smartProducts) {
                            const smart = this.smartProducts.find(item => item.Id === member.SMART);
                            if(smart && member.SMART != 'None' && member.SMART != null){
                                member['codeSMART'] = smart.ProductCode;
                            }else{
                                member['codeSMART'] = 'None';
                            }
                            
                        } else {
                            member['codeSMART'] = 'None';
                        }

                        // console.log('this.aiddProducts =>', this.aiddProducts);
                        if (this.aiddProducts) {
                            const aidd = this.aiddProducts.find(item => item.Id === member.AIDD);
                            console.log('aidd is ', aidd);
                            member.AIDD !== 'None' ? member['codeAIDD'] = aidd.ProductCode : member['codeAIDD'] = 'None';
                        } else {
                            member['codeAIDD'] = 'None';
                        }
                        fieldsMissing = false;

                    } else if (member.SMART == 'None' && member.AIDD == null && member.AIDD == undefined) {
                        console.log("member.SMART == 'None' && member.AIDD == null && member.AIDD == undefined");
                        const prod = this.coreProducts.find(item => item.Id === member.Product);
                        member.Product !== 'None' ? member['codeProduct'] = prod.ProductCode : member['codeProduct'] = 'None';
                        member['codeSMART'] = 'None';
                        member['codeAIDD'] = 'None';
                        fieldsMissing = false;
                    } else if (member.SMART == 'None' && member.AIDD == 'None') {
                        console.log("member.SMART == 'None' && member.AIDD == 'None'");
                        const prod = this.coreProducts.find(item => item.Id === member.Product);
                        member.Product !== 'None' ? member['codeProduct'] = prod.ProductCode : member['codeProduct'] = 'None';
                        member['codeSMART'] = 'None';
                        member['codeAIDD'] = 'None';
                        fieldsMissing = false;
                    } else {
                        fieldsMissing = true;
                    }
                }
            });
        } else {
            fieldsMissing = true;
        }

        if (fieldsMissing) {
            alert("You are missing some fields");
            return false;
        } else {
            let input = { 'censusMemberDataList': this.members, 'shareSmartPrograms': this.shareSmartPrograms, 'shareAiddPrograms': this.shareAiddPrograms };
            console.log('input =>', input);
            const params = {
                input: input,
                sClassName: 'ARC_CensusMemberToUserInputsGuestUsers',
                sMethodName: 'ARC_UserInputsForAncillaryPrograms',
                options: '{}',
            };
            const response = await this.omniRemoteCall(params, true)
            console.log('response =>', response);
            this.membersRecived = response.result.resp;
            return true;
        }
    }

    async callRepriceProducts(members, smarts, aidds) {



        this.outputOfRepriceProducts.records = [this.coreProducts[0]];
        let repriceProductsInput = [];
        let products = Object.keys(members);
        products.forEach(element => {
            if (element != 'None') {
                let smart = null;
                if (smarts) {
                    smart = smarts.find((item) => item.ProductCode == element.split('|')[0]);
                }

                let aidd = null;
                if (aidds) {
                    aidd = aidds.find((item) => item.ProductCode == element.split('|')[0]);
                }

                let jsonInp = { 'userInputs': [], 'selectedProduct': { 'records': [] } }
                if (smart) {
                    jsonInp.selectedProduct.records.push(smart);
                } else if (aidd) {
                    jsonInp.selectedProduct.records.push(aidd);
                }
                members[element].forEach(item => {
                    let obj = {};
                    obj['CensusMemberId'] = item.CensusMemberId;
                    obj['CensusMemberName'] = item.CensusMemberName;
                    obj['RF_Census.CRF_PrimaryMemberAge'] = item['RF_Census.CRF_PrimaryMemberAge'];
                    obj['RF_Census.CM_IsPrimary'] = item['RF_Census.CM_IsPrimary'];
                    obj['RF_Census.CRF_Coverage'] = item['RF_Census.CRF_Coverage'];
                    obj['RF_Census.CRF_CoverageAIDD'] = item['RF_Census.CRF_CoverageAIDD'];

                    jsonInp.userInputs.push(obj);
                });
                repriceProductsInput.push(jsonInp);
            }
        });

        for (const item of repriceProductsInput) {
            const remoteOptions = {
                includeRawCalculationResult: true
            }
            const params = {
                input: item,
                sClassName: 'InsProductService',
                sMethodName: 'repriceProduct',
                options: JSON.stringify(remoteOptions),
            };
            await this.omniRemoteCall(params, true).then(response => {
                if (response.result.records) {
                    this.outputOfRepriceProducts.records.push(response.result.records[0]);

                }
            }).catch(error => {
                console.error(error);
            });
        }
        this.areProgramRepriced = true;
        this.isLoading = false;
        return this.outputOfRepriceProducts;
    }

    handleChangeValue() {

        this.areProgramRepriced = false;
    }

    handleNext() {
        this.omniNextStep();


    }

    handlePrev() {
        this.saveChooseProductsState();
        this.omniPrevStep();
    }

    saveChooseProductsState() {
        this.omniApplyCallResp(
            {
                'chooseProductsSavedState': {
                    members: this.members,
                    shareSmartPrograms: this.shareSmartPrograms,
                    shareAiddPrograms: this.shareAiddPrograms,
                    outputPrimaries: this.outputPrimaries,
                    outputDep: this.outputDep,
                    outputOfRepriceProducts: this.outputOfRepriceProducts,
                    areProgramRepriced: this.areProgramRepriced,
                    smartSaved: this.smartSaved,
                    aiddSaved: this.aiddSaved,
                    membersRecived: this.membersRecived,
                    coreProducts: this.coreProducts,
                    smartProducts: this.smartProducts,
                    aiddProducts: this.aiddProducts,
                    checkDependents: this.checkDependents,
                    lockedProduct: this.lockedProduct,
                    membersAndPlans: this.membersAndPlans,
                    lockedProduct: this.lockedProduct,
                    coverageDependents: this.coverageDependents

                }
            }
        );
    }

    getChooseProductsSavedState() {
        console.log('getChooseProductsSavedState', this.omniJsonData.chooseProductsSavedState);
        this.members = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.members));
        this.shareSmartPrograms = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.shareSmartPrograms));
        this.shareAiddPrograms = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.shareAiddPrograms));
        this.outputPrimaries = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.outputPrimaries));
        this.outputDep = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.outputDep));
        this.outputOfRepriceProducts = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.outputOfRepriceProducts));
        this.areProgramRepriced = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.areProgramRepriced));
        this.smartSaved = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.smartSaved));
        this.aiddSaved = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.aiddSaved));
        this.membersRecived = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.membersRecived));
        this.coreProducts = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.coreProducts));
        this.smartProducts = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.smartProducts));
        this.aiddProducts = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.aiddProducts));
        this.checkDependents = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.checkDependents));
        // this.lockedProduct = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.lockedProduct));
        // this.coverageDependents = JSON.parse(JSON.stringify(this.omniJsonData.chooseProductsSavedState.coverageDependents));
    }

    sameInput() {
        let membersAndPlansCondition = JSON.stringify(this.omniJsonData.chooseProductsSavedState.membersAndPlans) == JSON.stringify(this.membersAndPlans);
        return membersAndPlansCondition;
    }
}