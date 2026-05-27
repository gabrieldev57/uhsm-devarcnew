import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";

export default class aRC_AssignAncillaryToMemberPremier extends OmniscriptBaseMixin(LightningElement) {
    @api shareSmart = {};
    @api shareAidd = {};
    
    @track allSelected = false;
    @track _members = [];
    @track selectedProducts = [];

    @api
    get members() {
        return this._members;
    }

    set members(value) {
        this._members = value;
        this.processSelectedProducts();
    }

    processSelectedProducts() {
        console.log('processSelectedProducts FINAL IN');

        if (!this._members?.length) return;

        let result = [];

        // ========================
        // MEDICAL (shared)
        // ========================
        const medicalProduct = this._members[0]?.medicalProduct;

        if (medicalProduct?.value) {
            const medicalUserInputs = this._members.map(member => {
                return {
                    ...member.user_input
                };
            });

            result.push({
                selectedProduct: {
                    Id: medicalProduct.value,
                    Name: medicalProduct.name
                },
                userInputs: medicalUserInputs
            });
        }

        // ========================
        // SMART & AIDD (independent)
        // ========================
        this._members.forEach(member => {
            const userInput = member.user_input;

            // SMART
            if (member.smartProduct?.value && member.smartProduct.value !== 'None') {
                result.push({
                    selectedProduct: {
                        Id: member.smartProduct.value,
                        Name: member.smartProduct.name
                    },
                    userInputs: [
                        {
                            ...userInput,
                            'RF_Census.CRF_PrimaryMemberAge': userInput['RF_Census.CM_Age'],
                            'RF_Census.CM_IsPrimary': true
                        }
                    ]
                });
            }

            // AIDD
            if (member.aiddProduct?.value && member.aiddProduct.value !== 'None') {
                result.push({
                    selectedProduct: {
                        Id: member.aiddProduct.value,
                        Name: member.aiddProduct.name
                    },
                    userInputs: [
                        {
                            ...userInput,
                            'RF_Census.CRF_PrimaryMemberAge': userInput['RF_Census.CM_Age'],
                            'RF_Census.CM_IsPrimary': true
                        }
                    ]
                });
            }
        });

        console.log('FINAL RESULT', JSON.stringify(result, null, 2));

        this.omniApplyCallResp({
            'LWC_ChooseProductSelectionOutput': result
        });
    }

    //processSelectedProducts() {
    //    console.log('processSelectedProducts IN');
    //    if (!this._members?.length) return;
    //
    //    let grouped = {};
    //
    //    const addToGroup = (key, productId, productName, member) => {
    //        if (!productId || productId === 'None') return;
    //
    //        if (!grouped[key]) {
    //            grouped[key] = {
    //                id: productId,
    //                name: productName,
    //                userInputs: []
    //            };
    //        }
    //
    //        grouped[key].userInputs.push(member.user_input);
    //    };
    //
    //    // const isSharedSmart = this.shareSmart?.value === true;
    //    // const isSharedAidd = this.shareAidd?.value === true;
    //
    //    // const primary = this._members.find(m => m.relationship === 'Primary');
    //    // const spouse = this._members.find(m => m.relationship === 'Spouse');
    //    // const childs = this._members.filter(m => m.relationship === 'Child');
    //
    //    // MEDICAL – All together
    //    this._members.forEach(member => {
    //        const key = `medical-${member.medicalProduct?.value}`;
    //        addToGroup(key, member.medicalProduct?.value, member.medicalProduct?.name, member);
    //    });
    //
    //    // SMART
    //    if (isSharedSmart && primary && spouse) {
    //        // All together
    //        this._members.forEach(member => {
    //            console.log('All Together SMART ' + member.name +' ' +member.smartProduct?.value +' ' +member.smartProduct?.name)
    //            const key = `smart-${member.smartProduct?.value}`;
    //            addToGroup(key, member.smartProduct?.value, member.smartProduct?.name, member);
    //        });
    //    } else {
    //        // Split Primary and Spouse
    //        if (primary) {
    //            const key = `smartPrimary-${primary.smartProduct?.value}`;
    //            addToGroup(key, primary.smartProduct?.value, primary.smartProduct?.name, primary);
    //        }
    //        if (spouse) {
    //            const key = `smartSpouse-${spouse.smartProduct?.value}`;
//
    //            let spouseSmartCopy = JSON.parse(JSON.stringify(spouse));
    //         
    //            spouseSmartCopy.user_input['RF_Census.CM_IsPrimary'] = true;
    //           
    //            addToGroup(key, spouseSmartCopy.smartProduct?.value, spouseSmartCopy.smartProduct?.name, spouseSmartCopy)
    //        }
    //
    //        // Childs are added to the parent's product based on selectedParent
    //        childs.forEach(child => {
    //            const parentId = child.selectedParent?.value;
    //            if (!parentId || parentId === 'None') return;
    //
    //            const parent = this._members.find(m => m.id === parentId);
    //            if (!parent) return;
    //
    //            const smartKey = parent.relationship === 'Primary'
    //                ? `smartPrimary-${parent.smartProduct?.value}`
    //                : `smartSpouse-${parent.smartProduct?.value}`;
    //
    //            if (grouped[smartKey]) {
    //                grouped[smartKey].userInputs.push(child.user_input);
    //            }
    //        });
    //    }
    //
    //    // AIDD
    //    if (isSharedAidd && primary && spouse) {
    //        // All together
    //        this._members.forEach(member => {
    //            console.log('All Together AIDD ' + member.name + ' ' + member.aiddProduct?.value + ' ' +member.aiddProduct?.name )
    //            const key = `aidd-${member.aiddProduct?.value}`;
    //            addToGroup(key, member.aiddProduct?.value, member.aiddProduct?.name, member);
    //        });
    //    } else {
    //        // Split Primary and Spouse
    //        if (primary) {
    //            const key = `aiddPrimary-${primary.aiddProduct?.value}`;
    //            addToGroup(key, primary.aiddProduct?.value, primary.aiddProduct?.name, primary);
    //        }
    //        if (spouse) {
    //            const key = `aiddSpouse-${spouse.aiddProduct?.value}`;
//
    //            let spouseAiddCopy = JSON.parse(JSON.stringify(spouse));
    //         
    //            spouseAiddCopy.user_input['RF_Census.CM_IsPrimary'] = true;
//
    //            addToGroup(key, spouseAiddCopy.aiddProduct?.value, spouseAiddCopy.aiddProduct?.name, spouseAiddCopy);
    //        }
    //
    //         // Childs are added to the parent's product based on selectedParent
    //        childs.forEach(child => {
    //            const parentId = child.selectedParent?.value;
    //            if (!parentId || parentId === 'None') return;
    //
    //            const parent = this._members.find(m => m.id === parentId);
    //            if (!parent) return;
    //
    //            const aiddKey = parent.relationship === 'Primary'
    //                ? `aiddPrimary-${parent.aiddProduct?.value}`
    //                : `aiddSpouse-${parent.aiddProduct?.value}`;
    //
    //            if (grouped[aiddKey]) {
    //                grouped[aiddKey].userInputs.push(child.user_input);
    //            }
    //        });
    //    }
    //
    //    this.selectedProducts = Object.values(grouped).filter(
    //        prod => prod.id && prod.id !== 'None'
    //    );
//
//
    //    let transformed = this.selectedProducts.map(prod => {
    //        // Find max age on userInputs
    //        const maxAge = prod.userInputs.reduce((max, input) => {
    //            const age = parseInt(input['RF_Census.CM_Age'], 10);
    //            return (age > max) ? age : max;
    //        }, 0);
//
    //        const countPrimary = prod.userInputs.filter(ui => ui['RF_Census.CM_Relationship'] === 'Primary').length;
    //        const countSpouse = prod.userInputs.filter(ui => ui['RF_Census.CM_Relationship'] === 'Spouse').length;
    //        const countChilds = prod.userInputs.filter(ui => ui['RF_Census.CM_Relationship'] === 'Child').length;
//
    //        console.log('Prod Name countPrimary ' + prod.name + ' ' + countPrimary)
    //        console.log('Prod Name countSpouse ' + prod.name + ' ' + countSpouse)
    //        console.log('Prod Name countChilds ' + prod.name + ' ' + countChilds)
    //
    //        // Set RF_Census.CRF_PrimaryMemberAge max age for userInputs per product
    //        const updatedUserInputs = prod.userInputs.map(input => {
    //            let smartCoverage = '';
    //            let aiddCoverage = '';
//
    //            if (prod.name?.includes('SMART') || prod.name?.includes('AIDD')) {
    //                if ((countPrimary == 1 && countSpouse == 0 && countChilds == 0) || (countPrimary == 0 && countSpouse == 1 && countChilds == 0)) {
    //                    smartCoverage = 'Primary';
    //                    aiddCoverage = 'Primary';
    //                } else if (countPrimary == 1 && countSpouse == 1 && countChilds == 0) {
    //                    smartCoverage = 'Primary + Spouse';
    //                    aiddCoverage = 'Primary + Spouse';
    //                } else if ((countPrimary == 1 && countSpouse == 0 && countChilds > 0) || (countPrimary == 0 && countSpouse == 1 && countChilds > 0)) {
    //                    smartCoverage = 'Primary + Child';
    //                    aiddCoverage = 'Primary + Children';
    //                } else {
    //                    smartCoverage = 'Family';
    //                    aiddCoverage = 'Family'; 
    //                }
    //            }
//
    //            return {
    //                ...input,
    //                'RF_Census.CRF_PrimaryMemberAge': maxAge,
    //                'RF_Census.CRF_Coverage': smartCoverage,
    //                'RF_Census.CRF_CoverageAIDD': aiddCoverage
    //            }
    //        });
    //
    //        return {
    //            selectedProduct: {
    //                Id: prod.id,
    //                Name: prod.name
    //            },
    //            userInputs: updatedUserInputs
    //        };
    //    });
    //
    //    // console.log('selectedProducts', JSON.stringify(transformed, null, 2));
    //    // console.table('selectedProducts table ',transformed)
//
    //    /* TO CHECK*/
//
    //    //this.omniUpdateDataJson(transformed);
//
    //    this.omniApplyCallResp({
    //        'LWC_ChooseProductSelectionOutput': transformed
    //    });
//
    //  
    //    // let previous_state = this.omniGetSaveState('selectedProducts') || {}; 
    //    // console.log('previous_state =>', previous_state);
    //    // this.omniSaveState({ ...transformed }, 'selectedProducts', true);
//
    //    /* TO CHECK*/
    //} 

    connectedCallback() {
        // let savedState = this.omniGetSaveState('selectedProducts');

        // console.log('savedState =>', savedState);
        // if (savedState) {
        //     console.log('There is a saved state')
        // } else {
        //     console.log('There is no saved state')
            
        // }
        console.log('connectedCallback shareSmart ' + JSON.stringify(this.shareSmart))
        console.log('connectedCallback shareAidd ' + JSON.stringify(this.shareAidd))
        console.log('connectedCallback members ' + JSON.stringify(this.members))

        this.checkAllSelected();

        if (this.allSelected) {
            this.processSelectedProducts();
        }
    }    
    
    handleSelection(e) {
        console.log('handleSelection IN');
        let { name, value, dataset, options, selectedIndex } = e.target;
        let memberId = dataset.memberId;
        let selectValue = value;
        let selectType = name;
        let optionSelectedName = options[selectedIndex]?.getAttribute('option-label') || null;

        let updatedMembers = JSON.parse(JSON.stringify(this.members));
    
        let memberIndex = updatedMembers.findIndex(m => m.id == memberId);
        if (memberIndex === -1) return;
    
        let member = JSON.parse(JSON.stringify(updatedMembers[memberIndex]));

        //console.log('selectValue ' + selectValue)

        // If is a child
        //if (member.isChild && selectType == 'childParentProgram') {
//
        //    if (selectValue === '-' || selectValue == 'None') {
        //        member.aiddProduct.name = selectValue == 'None' ? 'None' : null;
        //        member.aiddProduct.value = selectValue == 'None' ? 'None' : null;
        //        member.smartProduct.name = selectValue == 'None' ? 'None' : null;
        //        member.smartProduct.value = selectValue == 'None' ? 'None' : null;
        //        member.selectedParent.value = selectValue == 'None' ? 'None' : null;
        //        member.ancillaryProductsToString = selectValue == 'None' ? 'None' : null;                
        //    } else {
        //        let selectedAdult = updatedMembers.find(m => m.id == selectValue);
//
        //        if (selectedAdult) {
        //            member.aiddProduct.name = selectedAdult?.aiddProduct?.name || null;
        //            member.aiddProduct.value = selectedAdult?.aiddProduct?.value || null;
        //            member.smartProduct.name = selectedAdult?.smartProduct?.name || null;
        //            member.smartProduct.value = selectedAdult?.smartProduct?.value || null;
        //            member.selectedParent.value = selectedAdult.id;
        //            member.ancillaryProductsToString =
        //                selectedAdult.smartProduct.name && selectedAdult.aiddProduct.name
        //                    ? `${selectedAdult.smartProduct.name}, ${selectedAdult.aiddProduct.name}`
        //                    : `${selectedAdult.smartProduct.name || ''} ${selectedAdult.aiddProduct.name || ''}`;
        //        }
        //    }
        //    
        //} else {
            // If is Primary o Spouse
            if (selectType === 'smart') {
                if (selectValue === '-' || selectValue == 'None') {
                    member.smartProduct.name = selectValue == 'None' ? 'None' : '-';
                    member.smartProduct.value = selectValue == 'None' ? 'None' : null;
                } else {
                    member.smartProduct.value = selectValue;
                    member.smartProduct.name = optionSelectedName;
                }
            } else if (selectType === 'aidd') {
                if (selectValue === '-' || selectValue == 'None') {
                    member.aiddProduct.name = selectValue == 'None' ? 'None' : '-';
                    member.aiddProduct.value = selectValue == 'None' ? 'None' : null;
                } else {
                    member.aiddProduct.value = selectValue;
                    member.aiddProduct.name = optionSelectedName;
                }
            }

            //let findParentChild = updatedMembers.filter(m => m.selectedParent?.value == member.id);

            //if (findParentChild) {
            //    findParentChild.forEach(child => {
            //        // Assign the parent product values to the child if apply
            //        child.aiddProduct.name = member.aiddProduct?.name || null;
            //        child.aiddProduct.value = member.aiddProduct?.value || null;
            //    
            //        child.smartProduct.name = member.smartProduct?.name || null;
            //        child.smartProduct.value = member.smartProduct?.value || null;
            //    
            //        child.ancillaryProductsToString =
            //            member.smartProduct?.name && member.aiddProduct?.name
            //                ? `${member.smartProduct.name}, ${member.aiddProduct.name}`
            //                : `${member.smartProduct?.name || ''} ${member.aiddProduct?.name || ''}`;
            //    });
            //}
        //}
        
        // Update this.members and UI
        updatedMembers[memberIndex] = member;
        this.members = updatedMembers;

        //console.log('handdleselection ' + JSON.stringify(this.members));

        this.checkAllSelected();
        //this.disableAncillaryShareCheckboxes();
    }

    //handleShareCheckbox(e) {
    //    console.log('handleShareCheckbox IN');
    //    let { name, checked } = e.target;
//
    //    if (name == 'shareSmart') {
    //        let shareSmartValue = checked
    //        this.shareSmart = { ...this.shareSmart, value: shareSmartValue };
    //        console.log(JSON.stringify(this.shareSmart));
    //    }
//
    //    if (name == 'shareAidd') {
    //        let shareAiddValue = checked
    //        this.shareAidd = { ...this.shareAidd, value: shareAiddValue };
    //        console.log(JSON.stringify(this.shareAidd));
    //    }
//
    //    this.members = [...this.members];
    //}

    //disableAncillaryShareCheckboxes() {
//
    //    console.log('disableAncillaryShareCheckboxes IN');
//
    //    let relevantMembers = this.members.filter(m => 
    //        m.relationship === 'Primary' || m.relationship === 'Spouse'
    //    );
    //    
    //    if (relevantMembers.length == 1) return;
    //    
    //    let firstSmartValue = relevantMembers[0].smartProduct?.value;
    //    let firstAiddValue = relevantMembers[0].aiddProduct?.value;
    //    
    //    let allSameSmart = relevantMembers.every(m => m.smartProduct?.value === firstSmartValue);
    //    let allSameAidd = relevantMembers.every(m => m.aiddProduct?.value === firstAiddValue);
//
    //    if (firstSmartValue != null && firstSmartValue != 'None' && allSameSmart) {
    //        this.shareSmart = { ...this.shareSmart, disabled: false };
    //    } else if (!allSameSmart) {
    //        this.shareSmart = { value: false, disabled: true };
    //    }
    //    
    //    if (firstAiddValue != null && firstAiddValue != 'None' && allSameAidd) {
    //        this.shareAidd = { ...this.shareAidd, disabled: false };
    //    } else if (!allSameAidd) {
    //        this.shareAidd = { value: false, disabled: true };
    //    }
    //}

    checkAllSelected() {
        console.log('checkAllSelected IN');
      
        this.allSelected = this.members.every(member => {
            console.log(member.name + ' ' + member.relationship + ' ' + member.selectedParent?.value + ' ' + member.aiddProduct?.value + ' ' + member.smartProduct?.value);
            return member.aiddProduct?.value != null && member.smartProduct?.value != null;
        });
    }

    handleNext() {
        this.omniNextStep();
    }
}