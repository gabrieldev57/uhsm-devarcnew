import insOsGridProductSelectionSugg from 'vlocity_ins/insOsGridProductSelection';
import { track, api, wire } from 'lwc';
import { commonUtils, dataFormatter, omniscriptUtils } from 'vlocity_ins/insUtility';
import pubsub from 'vlocity_ins/pubsub';
import template from './arc_InsOsGridProductSelectionSugg.html';
const MAX_CONCURRENT_SERVICE_REQUEST = 5;


export default class arc_InsOsGridProductSelectionSugg extends insOsGridProductSelectionSugg {

    // productsByGroup = [
    //     {
    //         groupName: 'Medal',
    //         uniqueAttributes: [
    //             "AMCS Individual/Family",
    //         ],
    //         products: [
    //             "PROG_UHSMBronze",
    //             "PROG_UHSMBronzeEssential",
    //             "PROG_UHSMFundamental",
    //             "PROG_UHSMGold",
    //             "PROG_UHSMGoldEssential",
    //             "PROG_UHSMPlatinum",
    //             "PROG_UHSMPlatinumEssential",
    //             "PROG_UHSMSilver",
    //             "PROG_UHSMSilverEssential",
    //             "PROG_UHSMVital"
    //         ],
    //     },
    //     {
    //         groupName: 'WeShare',
    //         uniqueAttributes: [
    //             "AMCS Individual/Family"
    //         ],
    //         products: [
    //             "PROG_UHSM_WeShare1k,",
    //             "PROG_UHSM_WeShare3k,",
    //             "PROG_UHSM_WeShare6k,",
    //             "PROG_UHSM_WeShare9k,",
    //             "PROG_UHSM_WeShare12k,"
    //         ],
    //         description: "<p>WeShare, our most comprehensive sharing program, provides you with the flexibility to choose a doctor that’s best for you. Whether you prefer the convenience of virtual care or have an in-person need, you’ll easily find care within the network when needed and to help you proactively manage your health. Eligible sharing services include Telehealth, Physician and Therapy services, Labs, Radiology, Urgent Care, Emergency, Hospitalization, Maternity and more.</p><br><p>The program details provided here are a summary of commonly used services. For a more comprehensive view, Member and Program Guides are available.</p>"
    //     },
    //     {
    //         groupName: 'Access',
    //         uniqueAttributes: [
    //             "AMCS Individual/Family"
    //         ],
    //         products: [
    //             "PROG_UHSM_Access5k",
    //             "PROG_UHSM_Access10k"
    //         ],
    //         description: "<p>WeShare Access provides limited sharing benefits to maintain a healthy lifestyle. It focuses on well and sick visits through CVS MinuteClinic and their telehealth services, as well as urgent care and hospitalizations. It should not be considered a comprehensive health care program and does not include sharing for physician, office-based services.</p><br><p>The program details provided here are a summary of commonly used services. For a more comprehensive view, Member and Program Guides are available.</p>"
    //     },
    //     {
    //         groupName: 'SMART',
    //         uniqueAttributes: [
    //             "Max. Share Limit"
    //         ],
    //         products: [
    //             "PROG_SMART_10000",
    //             "PROG_SMART_15000",
    //             "PROG_SMART_20000",
    //             "PROG_SMART_25000",
    //             "PROG_SMART_30000",
    //             "PROG_SMART_35000",
    //             "PROG_SMART_40000",
    //             "PROG_SMART_45000",
    //             "PROG_SMART_5000",
    //             "PROG_SMART_50000"

    //         ]
    //     },
    //     {
    //         groupName: 'AIDD',
    //         uniqueAttributes: [
    //             "Max. Share Limit"
    //         ],
    //         products: [
    //             "PROG_AIDD_10000",
    //             "PROG_AIDD_2500",
    //             "PROG_AIDD_5000",
    //             "PROG_AIDD_7500"

    //         ]
    //     }
    // ];

    productsByGroup;





    @api warningForMedicalWrongSelection = false;
    @api lastMedicalSelectionId;
    @api maxMedicalSelection = 1;
    @api maxSMARTSelection = 2;
    @api maxAIDDSelection = 2;
    @track sortValue = 'High';
    @track repriceActionFn;
    @track reloadProducts = true;
    @api selectedMedical;
    @api selectedSmart;
    @api selectedAidd;
    @api oldproducts;
    @api changeplan;
    @api availablePrograms;
    @api nowOnSet = false;
    @api hasBrochures;
    @api brochures;
    @api brochureType;
    @api availableUpgrade;
    @api availableDowngrade;
    @track allProducts = [];
    @track checkVal;
    @track disabledButton;
    @track className = 'alert danger-alert none';
    @track sugPlan = false;
    @track productSuggested;
    @track emptyPlans = false;
    repriceActionFn = this.rePriceProduct.bind(this);
    @track products
    @track effDate1;
    @track effDate3;

    @api limitDate = new Date('01/01/2023');
    @api programUpgrade;
    @api programDowngrade;
    @api fundamentalsunset;

    @api currentSelectionStep;
    oldProductIds;
    @track showActivateOld = false;
    @track showDeactivateOld = false;

    isRefreshPrices = false;

    @api stepName = '';
    @api lwcName = '';
    oldActivePlanId = '';
    filteredAttributes;
    uniqueAttributesFilter;

    pubsubPayload = {
        addCartProdEvent: this.handleAddCartProd.bind(this),
        updatePriceEvent: this.handleUpdatePrice.bind(this),
        expandProduct: this.handleExpandProduct.bind(this),
        updateCart: this.handleUpdateCart.bind(this),
        toggleCompare: this.toggleCompare.bind(this),
        selectProduct: this.selectProduct.bind(this),
        backToCart: this.openCartModal.bind(this),
        openCompareModal: this.openCompareModal.bind(this),
        printThisProducts: this.printThisProducts.bind(this),
        //getLastMedicalId: this.getLastMedicalId.bind(this)
    };

    openCompareModal() {
        pubsub.fire(this.rootChannel, 'openProductModal', {
            products: this.selectedCompareProducts,
            compareLimit: this.maxCompareProducts,
            selectBtnFn: this.selectProduct.bind(this)
        });
    }

    selectProduct(e) {

        if (e.from === 'renderedCallback') {
            // If pubsub comes from renderedCallback and product is already in cart then ignore
            if (omniscriptUtils.getCartProducts(this)?.map(cartProd => { return cartProd.Id }).includes(e.detail)) {
                return
            }
        }
        this.showActivateOld = false;
        this.showDeactivateOld = false;

        omniscriptUtils.clearStateOnChange(this);
        const clickedProductId = e.detail;
        const selectedProduct = this.products.find(p => p.Id === clickedProductId);
        if (selectedProduct) {
            selectedProduct.isSelected = !selectedProduct.isSelected;
            pubsub.fire(this.rootChannel, 'updateProduct', { product: selectedProduct });
        }
        const cartProducts = omniscriptUtils.getCartProducts(this);


        const productIndex = cartProducts.findIndex(p => p.Id === clickedProductId);
        if (productIndex === -1) {
            cartProducts.push(selectedProduct);
        } else {
            cartProducts.splice(productIndex, 1);
        }

        let medicalProductsCount = cartProducts.filter(p => p.Type__c == "Medical").length;

        let SMARTProductsCount = cartProducts.filter(p => p.SubType__c == "SMART").length;

        let AIDDProductsCount = cartProducts.filter(p => p.SubType__c == "AIDD").length;

        let lastMedicalSelected = (element) => element.Type__c == "Medical";
        let lastMedicalProduct;

        if (medicalProductsCount > this.maxMedicalSelection) {
            lastMedicalProduct = cartProducts.find(lastMedicalSelected);
            let lastProductId = lastMedicalProduct.productId;

            let medicalIndex = cartProducts.findIndex(lastMedicalSelected);

            if (medicalIndex != -1) {
                cartProducts.splice(medicalIndex, 1);
                this.deSelectProduct(lastProductId);
            }

            medicalProductsCount = cartProducts.filter(p => p.Type__c == "Medical").length;
        }

        medicalProductsCount > this.maxMedicalSelection ? this.warningForMedicalWrongSelection = true : this.warningForMedicalWrongSelection = false;
        SMARTProductsCount > this.maxSMARTSelection ? this.warningForSMARTWrongSelection = true : this.warningForSMARTWrongSelection = false;
        AIDDProductsCount > this.maxAIDDSelection ? this.warningForAIDDWrongSelection = true : this.warningForAIDDWrongSelection = false;
        omniscriptUtils.updateCartProducts(this, cartProducts, this.rootChannel);
        this.lastMedicalSelectionIndex = cartProducts.findIndex(lastMedicalSelected);
        this.productCount = cartProducts.length;
        lastMedicalProduct = cartProducts.find(lastMedicalSelected);
        if (lastMedicalProduct) {
            this.lastMedicalSelectionId = lastMedicalProduct.productId;
        }




        this.omniUpdateDataJson({ "cartProductIds": cartProducts?.filter(cartProd => this.products.map(prod => { return prod.Id }).includes(cartProd.Id))?.map(p => { return p.Id }) });



        if (Array.isArray(this.oldProductIds)) {

            if (!cartProducts.filter(prod => (prod.SubType__c == this.currentSelectionStep || prod.Type__c == this.currentSelectionStep)).length) {
                this.showActivateOld = true;
            }

            function eqSet(xs, ys) {
                try {
                    return xs.size === ys.size && [...xs].every((x) => ys.has(x));
                }
                catch (e) { console.log(e); }
            }



            if ((e.from === 'useOldProducts') || eqSet(new Set(cartProducts.filter(prod => prod.SubType__c == this.currentSelectionStep || prod.Type__c == this.currentSelectionStep).map(prod => prod.Id)), new Set(this.oldProductIds))) {
                this.showDeactivateOld = true;
            }
            console.log('this.showDeactivateOld: ' + this.showDeactivateOld);
            if (this.oldProductIds.length === 1 && e.from === 'useOldProducts' && this.oldActivePlanId != null) {
                this.oldActivePlanId = e.detail;
            }
            if (this.currentSelectionStep === 'SMART') {
                this.omniUpdateDataJson({ "keepSMART": this.showDeactivateOld });
            }
            if (this.currentSelectionStep === 'AIDD') {
                this.omniUpdateDataJson({ "keepAIDD": this.showDeactivateOld });
            }
        }


    }


    refreshProds() {
        this.isProductsLoading = true;
        this.isRefreshPrices = true;
        this.formatRemoteActions();
        // this.recalculateEffDate(this.omniJsonData);
        this.ratingUserInputs = this.formatRatingUserInputs();
        this.getProducts();
        this.products.forEach(prod => {
            this.printThisProducts(prod);
        });
    }

    printThisProducts(data) {
        let currentProducts = JSON.parse(JSON.stringify(this.products))
        this.products = currentProducts.map(product => {
            if (product.Id == data.Id) {
                product = data;
            }
            return product;
        });
        pubsub.fire(this.rootChannel, 'updateProductRow', { ...data })
    }

    render() {
        this.stateData = null;
        return template;
    }


    recalculateEffDate(omniJsonData) {
        try {
            const effectiveDate = omniJsonData.DATE_ProgramChangeEffectiveDate;
            let effDateRaw = new Date(effectiveDate);
            let effDateFormatted = effDateRaw.setDate(effDateRaw.getDate());

            let userInputs2 = JSON.parse(JSON.stringify(omniJsonData.userInputs2));
            let minBirthdate;
            userInputs2.forEach(userInput => {
                let bd = userInput.Birthdate;
                if (minBirthdate == null) {
                    minBirthdate = bd;
                } else if (bd < minBirthdate) {
                    minBirthdate = bd;
                }
            });
            let userInputs = JSON.parse(JSON.stringify(userInputs2));
            userInputs.forEach(userInput => {
                let PrimaryAge = this.calculateAge(minBirthdate, effDateFormatted, 0);
                // console.log('PrimaryAge0: ' + this.calculateAge(minBirthdate, effDateFormatted, 0));
                // console.log('PrimaryAge 60: ' + this.calculateAge(minBirthdate, effDateFormatted, 60));
                let age = this.calculateAge(userInput.Birthdate, effDateFormatted);
                userInput['RF_Census.CRF_PrimaryMemberAge'] = PrimaryAge;
                userInput['RF_Census.CM_Age'] = age;
            });
            this.censusJson = userInputs;
        } catch (e) {


        }
    }

    calculateAge(DOB, dateTo, days = 0) {
        let memberBDToDate = new Date(DOB);
        let effDateRaw = new Date(dateTo);
        let effDateSec = effDateRaw.setDate(effDateRaw.getDate() + days);
        let effDate = new Date(effDateSec)
        let DOBYear = memberBDToDate.getFullYear();
        let effYear = effDate.getFullYear();

        let DOBMonth = memberBDToDate.getMonth();
        let effMonth = effDate.getMonth();

        let DOBDay = memberBDToDate.getDay();
        let effDay = effDate.getDay();

        let turnsInEffYear = effYear - DOBYear;

        let pastBD = false;

        let currentYear = new Date().getFullYear();

        if (currentYear == effYear) {

            if (DOBMonth < effMonth) {
                pastBD = true;
            } else if (DOBMonth == effMonth) {
                if (DOBDay <= effDay) {
                    pastBD = true;
                }
            }
        } else {
            const months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

            if (months.indexOf(DOBMonth) < months.indexOf(effMonth)) {
                pastBD = true;
            } else if (months.indexOf(DOBMonth) == months.indexOf(effMonth)) {
                if (DOBDay <= effDay) {
                    pastBD = true;
                }
            }
        }


        let age = -1;

        if (pastBD == true) {
            age = turnsInEffYear;
        } else {
            age = turnsInEffYear - 1;
        }
        return age;
    }

    mergeLists(list1, list2) {
        // Split the strings into arrays
        let array1 = list1.split(',');
        let array2 = list2.split(',');

        // Merge the arrays into a new one
        let mergedArray = array1.concat(array2);

        // Return the merged array as a string joined by commas
        return mergedArray.join(',');
    }

    async getProducts() {
        this.products = [];
        this.disableSortSelect = true;
        this.reFormulateFilterString();
        this.initAction.optionsMap.filters = this.serviceFilterString;

        if (this.changeplan) {
            let input = {
                changePlan: this.changeplan,
                effectiveDate: this.omniJsonData.DATE_ProgramChangeEffectiveDate,
                program: this.omniJsonData.oldProducts.find(item => item.Type__c == 'Medical').Name,
                fundamentalsunset: this.fundamentalsunset
            }


            const params = {
                input: JSON.stringify(input),
                sClassName: 'vlocity_ins.IntegrationProcedureService',
                sMethodName: 'IFPProgramChange_GetAvailablePrograms',
                options: '{}',
            };
            await this.omniRemoteCall(params, true)

                .then(response => {

                    if (response) {
                        if (this.programUpgrade) {
                            this.availablePrograms = response.result.IPResult.availableUpgrade;
                        }
                        if (this.programDowngrade) {
                            this.availablePrograms = response.result.IPResult.availableDowngrade;
                        }
                        if (this.changeplan == 'spinOff') {
                            this.availablePrograms = response.result.IPResult.availablePlans;
                        }
                    }
                })
                .catch(error => { });

        }



        omniscriptUtils.omniGenericInvoke(this, this.initAction)
            .then(response => {
                const eligibleProductsResponse = JSON.parse(response);
                this.totalNumProducts = eligibleProductsResponse.totalNumProducts;
                if (this.totalNumProducts > 0) {
                    const productIdBatches = this.groupProductIds(eligibleProductsResponse.products);
                    const batchOperations = productIdBatches.map(productIds => {
                        const batchDataMap = this.getRatedProductsDataMap(productIds);
                        return () => {
                            return omniscriptUtils.omniGenericInvoke(this, batchDataMap).then(res => {
                                const response = JSON.parse(res);
                                let records;
                                if (!this.isCancelProductFetch) {
                                    if (response.records) {
                                        records = response.records;
                                    } else if (response.result && response.result.listProducts) {
                                        records = response.result.listProducts.records;
                                    }
                                }

                                // Check if the user want to upgrade or downgrade their plan (OS: ARC_IndividualAndFamilyProgramChangeAncillary)
                                if (this.changeplan != undefined || this.changeplan != null) {


                                    let records = [];
                                    let changePlanRes;
                                    let AllProducts = JSON.parse(res).records;

                                    AllProducts.forEach(product => {
                                        if (this.checkAvailableProducts(product.Name)) {
                                            records.push(product);
                                        }
                                    });
                                    changePlanRes = { totalSize: records.length, records }
                                    this.formatProducts(records);
                                    this.updateProductsInCart();
                                    return (JSON.stringify(changePlanRes)); this.filteredProducts
                                } else {
                                    this.formatProducts(records);
                                    return res;
                                }
                            });
                        };

                    });
                    this.isProductsLoading = true;
                    this.concurrentPromiseWithLimit(this.concurrentBatchRequest, batchOperations)
                        .then(() => {
                            this.isProductsLoading = false;
                            this.disableSortSelect = false;
                            if (this.isCancelProductFetch) {
                                this.isCancelProductFetch = false;
                                this.applyServiceFilters();
                            }
                        })
                        .catch(error => commonUtils.showErrorToast.call(this, error))
                        .finally(() => {
                            this.filteredProducts = this.filteredProducts.sort(this.dynamicSort('Price', this.sortValue));
                            // if (this.changeplan == "spinOff" && this.omniJsonData.oldProducts.find(item => item.Type__c == 'Medical').Name.includes("UHSM")) {

                            //     let filteredWeShare = this.filteredProducts.filter((element) => element.Name.includes("WeShare"));
                            //     filteredWeShare = filteredWeShare.sort(this.dynamicSort('Price', 'High'));

                            //     // let filteredAccess = this.filteredProducts.filter( (element) => element.Name.includes("Access"));
                            //     // filteredAccess = filteredAccess.sort(this.dynamicSort('Price', 'High'));


                            //     let filteredMetal = this.filteredProducts.filter((element) => element.Name.includes("UHSM"));
                            //     filteredMetal = filteredMetal.sort(this.dynamicSort('Price', 'High'));

                            //     this.filteredProducts = filteredMetal.concat(filteredWeShare);
                            //     this.totalNumProducts = this.filteredProducts.length;


                            // }

                            this.filteredProducts = this.splitProductsInGroups(this.filteredProducts);


                            this.updateProductsInCart();
                            this.updateProducts();
                            this.initAction.optionsMap.filters = this.getFilter();
                            this.isLoaded = true;
                        });
                } else {
                    this.products = [];
                    this.filteredProducts = [];
                    this.prepareSortCombo();
                    this.populateInlineFilters(true);
                }
            })

            .catch(error => {
                commonUtils.showErrorToast.call(this, error);
                this.totalNumProducts = 0;
            })


    }



    getFilter() {
        let filters = this.initAction.optionsMap.filters.split(',');
        let filter;
        filters.forEach(f => {
            if (f.includes('vlocity_ins__MarketSegment__c')) {
                filter = f;
            }
        });
        return filter;
    }

    applyServiceFilters() {
        this.isLoaded = false;
        if (this.isProductsLoading) {
            this.isCancelProductFetch = true;
            return;
        }
        this.products = [];
        this.filteredProducts = [];
        this.selectedCompareProducts = [];
        this.allProducts = [];
        this.getProducts();
    }

    addProductConfig(product) {
        if (this.productConfig) {
            const typeConfig = this.productConfig.config[product.Type__c];
            if (typeConfig.fieldKeyName) {
                const configKey = product[typeConfig.fieldKeyName];
                product.productConfig = typeConfig[configKey];
            } else {
                product.productConfig = typeConfig;
            }
        }
        product.productStep = this.stepName;
        product.placeholders = this.productConfig.placeholders;
        return product;
    }

    formatAllProducts(products) {
        if (products && products.length) {
            this.allProducts = this.allProducts.concat(
                products.map(product => {
                    return dataFormatter.formatProduct(this.addProductConfig(product), {
                        isProductSelection: true
                    });
                })
            );
        }
        this.prepareSortCombo();
        this.populateInlineFilters(true);
    }

    disconnectedCallback() {
        pubsub.unregister(this.rootChannel, this.pubsubPayload);
    }

    updateProductsInCart() {
        const cartProducts = omniscriptUtils.getCartProducts(this);
        if (cartProducts) {
            let cartProductsFiltered;
            cartProductsFiltered = cartProducts.filter(product => product.Type__c === this.selectedMedical || product.SubType__c === this.selectedSmart || product.SubType__c === this.selectedAidd);
            omniscriptUtils.updateCartProducts(this, cartProductsFiltered, this.rootChannel);
            this.productCount = cartProductsFiltered.length;
        }
    }

    updateCartValues() {
        const cartProducts = omniscriptUtils.getCartProducts(this);
        if (cartProducts) {
            cartProducts.forEach(product => {
                const prod = this.allProducts.find(p => p.Id === product.Id);
                if (prod.Price !== product.Price && prod.Price !== 0) {
                    const index = cartProducts.findIndex(p => p.Id === product.Id);
                    cartProducts.splice(index, 1, prod);
                }
            });
            omniscriptUtils.updateCartProducts(this, cartProducts, this.rootChannel);
        }
    }

    updateProducts() {

        const cartProducts = omniscriptUtils.getCartProducts(this);
        if (cartProducts) {
            this.filteredProducts.forEach(group => {
                group.products.forEach(product => {

                    const selectedProduct = cartProducts.find(cartProduct => cartProduct.Id === product.Id);

                    selectedProduct ? product.isSelected = true : product.isSelected = false;
                    // if(this.changeplan == "spinOff" && this.omniJsonData.oldProducts.find(item => item.Type__c == 'Medical').Name.includes("UHSM")){
                    //     
                    //     let filteredWeShare = this.filteredProducts.filter( (element) => element.Name.includes("WeShare"));
                    //     filteredWeShare = filteredWeShare.sort(this.dynamicSort('Price', 'High'));

                    //     let filteredMetal = this.filteredProducts.filter( (element) => element.Name.includes("UHSM"));
                    //     filteredMetal = filteredMetal.sort(this.dynamicSort('Price', 'High'));

                    //     this.filteredProducts = filteredWeShare.concat(filteredMetal);
                    //     
                    //     this.totalNumProducts = this.filteredProducts.length;


                    // } 
                    pubsub.fire(this.rootChannel, 'updateProduct', { product: product });
                });
            });
        }
    }

    filterProducts() {

        let filteredProducts = this.products.filter(product => {
            let flag = true;
            this.inlineFilters.forEach(filter => {
                const hasFilterSelection = filter.filterSelection && filter.filterSelection !== '';
                if (hasFilterSelection) {
                    if (filter.isFieldFilter && product[filter.filterKey] !== filter.filterSelection) {
                        flag = false;
                    } else {
                        let attrUserValues = omniscriptUtils.getAttributeObject(product, filter.filterKey).userValues;
                        if (attrUserValues) {
                            if (typeof attrUserValues !== 'string') {
                                attrUserValues = attrUserValues.toString();
                            }
                            if (hasFilterSelection && attrUserValues !== filter.filterSelection) {
                                flag = false;
                            }
                        }
                    }
                }
            });
            return flag;
        });
        filteredProducts = filteredProducts.sort(this.dynamicSort('Price', this.sortValue));
        this.totalNumProducts = filteredProducts.length;

        this.filteredProducts = this.splitProductsInGroups(filteredProducts);
        this.populateInlineFilters();

    }




    dynamicSort(property, sortType) {
        var sortOrder = 1;

        if (property[0] === "-") {
            sortOrder = -1;
            property = property.substr(1);
        }

        return function (a, b) {
            var result;

            if (property === 'Price') {
                if (sortType === 'High') {
                    result = (b[property] < a[property]) ? -1 : (b[property] > a[property]) ? 0 : 1;
                } else if (sortType === 'Low') {
                    result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 0 : 1;
                }
            } else if (property === 'Name') {
                if (sortType === 'WeShare') {
                    result = (b[property] < a[property]) ? -1 : (b[property] > a[property]) ? 0 : 1;
                } else if (sortType === 'Metal') {
                    result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 0 : 1;
                }
            }

            return result * sortOrder;
        }
    }

    sortComboChange(e) {
        this.filterProducts();
        let filteredProducts = this.filteredProducts.map(group => { return group.products }).flat();

        if (e.target.value === 'Low' || e.target.value === 'High') {

            filteredProducts = filteredProducts.sort(this.dynamicSort('Price', e.target.value));
            this.sortValue = e.target.value;
        } else if (e.target.value === 'WeShare' || e.target.value === 'Metal') {
            filteredProducts = filteredProducts.sort(this.dynamicSort('Name', e.target.value));
            if (e.target.value === 'WeShare') {
                filteredProducts = filteredProducts.filter((element) => element.Name.includes("WeShare"));
                filteredProducts = filteredProducts.sort(this.dynamicSort('Price', 'High'));
                this.sortValue = e.target.value;
            } else if (e.target.value === 'Metal') {
                filteredProducts = filteredProducts.filter((element) => element.Name.includes("UHSM"));
                filteredProducts = filteredProducts.sort(this.dynamicSort('Price', 'High'));
                this.sortValue = e.target.value;
            }
        }
        this.filteredProducts = this.splitProductsInGroups(filteredProducts);
    }

    prepareSortCombo() {
        var labelPrice = 'By Price';
        var sortKey = 'Price';
        let optsMap;
        if (this.omniJsonData?.oldProducts?.find(item => item.Type__c == 'Medical').Name.includes("UHSM")) {
            optsMap = [
                {
                    label: 'Price High to Low',
                    value: 'High'
                },
                {
                    label: 'Price Low to High',
                    value: 'Low'
                },
                {
                    label: 'WeShare Plans',
                    value: 'WeShare'
                },
                {
                    label: 'Metal Plans',
                    value: 'Metal'
                }
            ];
        } else {
            optsMap = [
                {
                    label: 'Price High to Low',
                    value: 'High'
                },
                {
                    label: 'Price Low to High',
                    value: 'Low'
                }
            ];
        }


        this.sortCombo = { labelPrice, optsMap, sortKey };
    }

    checkAvailableProducts(productName) {
        let availableProgramsArray = this.availablePrograms.split(", ");
        return availableProgramsArray.includes(productName);
    }

    connectedCallback() {




        if (this.omniJsonData.ProgramUpgrade || this.omniJsonData.ProgramDowngrade) {
            this.formatRemoteActions();
            this.recalculateEffDate(this.omniJsonData);
            this.ratingUserInputs = this.formatRatingUserInputs();
            this.nowOnSet = false;
        }
        this.hasBrochures = this.hasBrochures === 'true'
        if (typeof this.loadBatchSize === 'string') {
            this.loadBatchSize = parseInt(this.loadBatchSize, 10);
        }
        if (typeof this.concurrentBatchRequest === 'string') {
            this.concurrentBatchRequest = Math.min(
                parseInt(this.concurrentBatchRequest, 10),
                MAX_CONCURRENT_SERVICE_REQUEST
            );
        }
        if (typeof this.compareBar === 'string') {
            this.compareBar = this.compareBar === 'true';
        }
        if (this.omniJsonDef.propSetMap.filtersConfig) {
            this.populateServiceFilters();
        }

        this.stepName = this.omniScriptHeaderDef.asName;
        this.rootChannel = `ProductSelectionChannel-${dataFormatter.uniqueKey()}`;
        pubsub.register(this.rootChannel, this.pubsubPayload);
        const dataOmniLayout = this.getAttribute('data-omni-layout');
        this.theme = dataOmniLayout === 'newport' ? 'nds' : 'slds';
        this.productConfig = this.omniJsonDef.propSetMap.productConfig || {};
        if (typeof this.maxCompareProducts === 'string') {
            this.maxCompareProducts = Math.min(parseInt(this.maxCompareProducts, 10), 4);
        }
        this.stateData = omniscriptUtils.getSaveState(this);
        this.formatRemoteActions();
        if (this.stateData) {
            this.parseSavedState(this.stateData);

        } else {
            this.getProducts();
        }
        const cartProducts = omniscriptUtils.getCartProducts(this);
        if (cartProducts.length === 0) {
            // Update the OS json to an empty array
            omniscriptUtils.updateCartProducts(this, [], this.rootChannel);
        }
        this.cartProductCount();
        // this.refreshProds();

        // Add Old Active Programs button functionality
        if (this.omniJsonData.oldProducts && this.omniJsonData.oldProducts.length && this.currentSelectionStep) {
            this.oldProductIds = this.omniJsonData.oldProducts.filter(prod => prod.SubType__c == this.currentSelectionStep || prod.Type__c == this.currentSelectionStep).map(p => { return p.Id });
            if (this.currentSelectionStep && this.oldProductIds.length) {
                this.showActivateOld = true;
            }
        }

        this.getPlanGroups();
    }

    openBrochure() {
        let brochures = JSON.parse(JSON.stringify(this.brochures));
        brochures = brochures.filter((element) => element.ProgramType == this.brochureType);
        let url = brochures[0]['URL'];
        window.open(url, "_blank");

    }


    /**
    * Inherits userInputs and optionsMap from productsAction
    * Used by configuration modal/inline component
    * @param {Object} product
    */
    rePriceProduct(product) {

        return new Promise((resolve, reject) => {
            omniscriptUtils.rePriceProduct(this, product, this.repriceAction, this.ratingUserInputs)
                .then(response => {
                    resolve(response);
                }, error => {
                    reject(error);
                });
        });
    }

    //deselects product based on productId
    deSelectProduct(productId) {
        omniscriptUtils.clearStateOnChange(this);
        const clickedProductId = productId;
        const selectedProduct = this.products.find(p => p.Id === clickedProductId);
        if (selectedProduct) {
            selectedProduct.isSelected = !selectedProduct.isSelected;
            pubsub.fire(this.rootChannel, 'updateProduct', { product: selectedProduct });
        }
        // const cartProducts = omniscriptUtils.getCartProducts(this);
        // const productIndex = cartProducts.findIndex(p => p.Id === clickedProductId);
        // if (productIndex != -1) {
        //     cartProducts.splice(productIndex, 1);
        // }

        // omniscriptUtils.updateCartProducts(this, cartProducts, this.rootChannel);
        // this.productCount = cartProducts.length;
    }

    useOldProducts() {
        let oldActives = this.products.filter(prod => (prod.SubType__c == this.currentSelectionStep || prod.Type__c == this.currentSelectionStep) && this.oldProductIds.includes(prod.Id));
        oldActives.forEach(prod =>
            setTimeout(() => { pubsub.fire(this.rootChannel, 'selectProduct', { detail: prod.Id, from: 'useOldProducts' }) }, 0)
        );
    }

    removeOldProducts() {
        let newActives = this.omniJsonData.selectedProducts.filter(prod => prod.isSelected && (prod.SubType__c == this.currentSelectionStep || prod.Type__c == this.currentSelectionStep) && this.oldProductIds.includes(prod.Id));
        newActives.forEach(prod =>
            setTimeout(() => { pubsub.fire(this.rootChannel, 'selectProduct', { detail: prod.Id }) }, 0)
        );
    }

    renderedCallback() {
        const stepCartProductIds = this.omniJsonData[this.stepName]?.[this.lwcName]?.cartProductIds;
        if (stepCartProductIds?.length) {
            stepCartProductIds.forEach(prod => {
                setTimeout(() => { pubsub.fire(this.rootChannel, 'selectProduct', { detail: prod, from: 'renderedCallback' }); }, 0)
            });
        }
    }



    splitProductsInGroups(products) {
        /*
        products format:
        [
            {
                "Id": "1",
                "ProductCode": "PROG_UHSM_WeShare1k",
                ...
            },
            {
                "Id": "2",
                "ProductCode": "PROG_UHSM_WeShare6k",
                ...
            },
            ...
        */
        let splitedProducts = {};
        for (const product of products) {
            const groupName = this.productsByGroup.find(group => group.products.includes(product.ProductCode))?.groupName;
            if (groupName) {
                if (!splitedProducts[groupName]) {
                    splitedProducts[groupName] = [];
                }
                splitedProducts[groupName].push(product);
            }
        }


        return Object.keys(splitedProducts).map(groupName => {
            return ({
                groupName: groupName,
                products: splitedProducts[groupName],
                uniqueAttributes: this.productsByGroup.find(group => group.groupName == groupName)?.uniqueAttributes,
                description: this.productsByGroup.find(group => group.groupName == groupName)?.description,
                hiddenAttributes: this.productsByGroup.find(group => group.groupName == groupName)?.hiddenAttributes,
            })
        });

    }


    handleDataFromChild(event) {
        this.filteredProducts.forEach(group => {
            if (group.groupName == event.detail.groupName) {
                // const generalAttributesList = [];
                if (!group.generalAttributes) {
                    group.generalAttributes = [];
                    event.detail.attributes.forEach(attribute => {
                        group.generalAttributes.push(JSON.parse(JSON.stringify(attribute)));
                    });
                }

            }
        });
    }
    async getPlanGroups() {

        const params = {
            input: {},
            sClassName: 'ARC_PlanGroupMetadata',
            sMethodName: 'getGroups',
            options: '{}',
        };
        await this.omniRemoteCall(params, true).then(response => {
            this.productsByGroup = response.result.groupMaps;

        }).catch(error => {

        });
    }
}