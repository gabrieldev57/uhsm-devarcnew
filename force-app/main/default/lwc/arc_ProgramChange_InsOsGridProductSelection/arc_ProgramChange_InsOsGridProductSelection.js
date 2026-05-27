import insOsGridProductSelection from 'vlocity_ins/insOsGridProductSelection';
import { track, api, wire } from 'lwc';
import { commonUtils, dataFormatter, omniscriptUtils } from 'vlocity_ins/insUtility';
import pubsub from 'vlocity_ins/pubsub';
import template from './arc_ProgramChange_InsOsGridProductSelection.html';
const MAX_CONCURRENT_SERVICE_REQUEST = 5;

export default class arc_ProgramChange_InsOsGridProductSelection extends insOsGridProductSelection {
    productsByGroup;
    showWarning;
    wantsAncillary;
    @api hasHealthyDiscountApplied
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
    @api changeplan;
    @api availablePrograms;
    @api nowOnSet = false;
    @api hasBrochures;
    @api brochures;
    @api brochureType;
    @api availableUpgrade;
    @api availableDowngrade;
    @api hadAncillaries;
    @api userInputs
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

    @api programType;
    @api oldProductIds;
    @api oldProducts;

    isRefreshPrices = false;

    @api stepName = '';
    @api lwcName = '';
    filteredAttributes;
    uniqueAttributesFilter;

    @api get showCartButton() {
        return this.programType == 'Medical' && this.productCount > 0;
    }

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
    };

    waitForRender() {
        return new Promise((resolve) => {
            requestAnimationFrame(() => requestAnimationFrame(resolve));
        });
    }
    microTick() {
        return Promise.resolve();
    }

    openCompareModal() {
        pubsub.fire(this.rootChannel, 'openProductModal', {
            products: this.selectedCompareProducts,
            compareLimit: this.maxCompareProducts,
            selectBtnFn: this.selectProduct.bind(this)
        });
    }

    selectProduct(event) {
        const selectedProductId = event.detail;
        const eventSource = event.from;

        // Ignore si ya está en cart y viene del renderedCallback
        if (eventSource === 'renderedCallback' && omniscriptUtils.getCartProducts(this)?.some(cartProd => cartProd.Id === selectedProductId)) {
            return;
        }

        omniscriptUtils.clearStateOnChange(this);

        const selectedProductDetails = this.products.find(product => product.Id === selectedProductId);
        if (!selectedProductDetails) return;
        selectedProductDetails.isSelected = !selectedProductDetails.isSelected;
        pubsub.fire(this.rootChannel, 'updateProduct', { product: selectedProductDetails });
        console.log('PRODUCTS', JSON.parse(JSON.stringify(this.products)))
        const cartProducts = omniscriptUtils.getCartProducts(this);
        console.log('PRODUCTS2', JSON.parse(JSON.stringify(cartProducts)))
        const productIndex = cartProducts.findIndex(product => product.Id === selectedProductId);

         if (productIndex === -1) { // Product is not in Cart already
            cartProducts.push(selectedProductDetails); // Add product to cart
        } else { // Product is in Cart already
            cartProducts.splice(productIndex, 1); // Remove product from cart
        }

        const medicalProductsCount = cartProducts.filter(p => p.Type__c === "Medical").length;
        const SMARTProductsCount = cartProducts.filter(p => p.SubType__c === "SMART").length;
        const AIDDProductsCount = cartProducts.filter(p => p.SubType__c === "AIDD").length;

        // Handle medical product selection limit
        if (medicalProductsCount > this.maxMedicalSelection) {
            const lastMedicalProduct = cartProducts.find(p => p.Type__c === "Medical");
            if (lastMedicalProduct) {
                const lastProductId = lastMedicalProduct.productId;
                const medicalIndex = cartProducts.findIndex(p => p.Type__c === "Medical");
                cartProducts.splice(medicalIndex, 1);
                this.deSelectProduct(lastProductId);
            }
        }

        // Set warnings to true or false based on selection limits
        this.warningForMedicalWrongSelection = medicalProductsCount > this.maxMedicalSelection;
        this.warningForSMARTWrongSelection = SMARTProductsCount > this.maxSMARTSelection;
        this.warningForAIDDWrongSelection = AIDDProductsCount > this.maxAIDDSelection;

        omniscriptUtils.updateCartProducts(this, cartProducts, this.rootChannel);

        const legacyProductsCount = cartProducts.filter(p => p.ProductCode === "PROG_WeShareLegacy").length;

        console.log('this.hadAncillaries ' + this.hadAncillaries);
        console.log('this.userInputs ' + this.userInputs);
        
        if (legacyProductsCount > 0) {
            this.wantsAncillary = 'No';
            this.disableAncillary = true;
        }
        else {
            this.wantsAncillary = this.hadAncillaries;
            this.disableAncillary = false;
        }

        this.omniApplyCallResp({
            STEP_PlanSelection: {
                RAD_WantsAncillary: this.wantsAncillary,
            }
        });

        this.lastMedicalSelectionIndex = cartProducts.findIndex(p => p.Type__c === "Medical");
        this.productCount = cartProducts.length;
        this.lastMedicalSelectionId = cartProducts.find(p => p.Type__c === "Medical")?.productId;

         // Update data JSON with cart product IDs
        const cartProductIds = cartProducts
            .filter(cartProd => this.products.some(prod => prod.Id === cartProd.Id))
            .map(p => p.Id);
        this.omniUpdateDataJson({ cartProductIds });
    }

    async refreshProds() {
        this.isProductsLoading = true;
        this.isRefreshPrices = true;
        this.formatRemoteActions();
        this.ratingUserInputs = this.formatRatingUserInputs();
        await this.getProducts();
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
            let userInputs2 = JSON.parse(JSON.stringify(omniJsonData.userInputs));
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
                let age = this.calculateAge(userInput.Birthdate, effDateFormatted);
                userInput['RF_Census.CRF_PrimaryMemberAge'] = PrimaryAge;
                userInput['RF_Census.CM_Age'] = age;
            });
            this.censusJson = userInputs;
        } catch (error) {
            console.error('error =>', error);
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
        try {
            this.products = [];
            this.disableSortSelect = true;
            this.reFormulateFilterString();
            this.initAction.optionsMap.filters = this.serviceFilterString;

            if (this.programType === 'Medical') {
                const metalProduct = this.oldProducts
                    .filter(prod => prod.Type__c === 'Medical' && prod.Name.startsWith('UHSM'))
                    .map(prod => prod.Name);
                if (metalProduct.length !== 0) {
                    delete this.initAction.optionsMap.filters;
                    this.initAction.optionsMap.whereClause = "(Name = \'" + metalProduct[0] + "\' OR Name LIKE \'WeShare%\')";
                }
            }
            console.log('this.initAction: ', this.initAction);
            
            const response = await omniscriptUtils.omniGenericInvoke(this, this.initAction);
            console.log('this.initAction response: ', response);
            const eligibleProductsResponse = JSON.parse(response);
            this.totalNumProducts = eligibleProductsResponse.totalNumProducts;

            if (this.totalNumProducts > 0) {
                const productIdBatches = this.groupProductIds(eligibleProductsResponse.products);
                console.log('productIdBatches: ', productIdBatches);
                const batchOperations = productIdBatches.map(productIds => {
                    const batchDataMap = this.getRatedProductsDataMap(productIds);
                    console.log('batchDataMap: ', batchDataMap);
                    return async () => {
                        const res = await omniscriptUtils.omniGenericInvoke(this, batchDataMap);
                        const response = JSON.parse(res);
                        console.log('batchDataMap response: ', response);
                        let records;

                        if (!this.isCancelProductFetch) {
                            if (response.records) {
                                records = response.records;
                            } else if (response.result && response.result.listProducts) {
                                records = response.result.listProducts.records;
                            }
                        }

                        // Upgrade/Downgrade
                        if (this.changeplan != undefined || this.changeplan != null) {
                            let records = [];
                            let changePlanRes;
                            let AllProducts = JSON.parse(res).records;

                            AllProducts.forEach(product => {
                                if (this.checkAvailableProducts(product.Name)) {
                                    records.push(product);
                                }
                            });

                            changePlanRes = { totalSize: records.length, records };
                            this.formatProducts(records);
                            this.updateProductsInCart();
                            return JSON.stringify(changePlanRes);
                        } else {
                            this.formatProducts(records);
                            return res;
                        }
                    };
                });

                console.log('batchOperations: ', batchOperations);
                this.isProductsLoading = true;
                await this.concurrentPromiseWithLimit(this.concurrentBatchRequest, batchOperations);

                this.isProductsLoading = false;
                this.disableSortSelect = false;

                if (this.isCancelProductFetch) {
                    this.isCancelProductFetch = false;
                    this.applyServiceFilters();
                }

                this.filteredProducts = this.filteredProducts.sort(this.dynamicSort('Price', this.sortValue));
                console.log('filteredProducts2: ', JSON.parse(JSON.stringify(this.filteredProducts)));
                
                // Populate the product JSON with the price + healthy discount applied
                this.populateHealthyDiscount();

                await this.preSelectOldProducts();

                this.filteredProducts = this.splitProductsInGroups(this.filteredProducts);
                console.log('filteredProducts3: ', JSON.parse(JSON.stringify(this.filteredProducts)));
                await this.updateProducts();

                if (this.initAction.optionsMap.filters) {
                    this.initAction.optionsMap.filters = this.getFilter();
                }

                this.isLoaded = true;
            } else {
                this.products = [];
                this.filteredProducts = [];
                this.prepareSortCombo();
                this.populateInlineFilters(true);
            }
        } catch (error) {
            console.error('error =>', error);
            commonUtils.showErrorToast.call(this, error);
            this.totalNumProducts = 0;
        }
    }

    populateHealthyDiscount() {
        let healthyDiscountRate = this.omniJsonData.HealthyDiscountRate;
        this.filteredProducts.forEach(product => {
            product.healthyDiscount = product.Price * ((100 - healthyDiscountRate) / 100);
        });
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

    async applyServiceFilters() {
        this.isLoaded = false;
        if (this.isProductsLoading) {
            this.isCancelProductFetch = true;
            return;
        }
        this.products = [];
        this.filteredProducts = [];
        this.selectedCompareProducts = [];
        this.allProducts = [];
        await this.getProducts();
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

    async updateProducts() {
        const cartProducts = await omniscriptUtils.getCartProducts(this);
        if (cartProducts) {
            this.filteredProducts.forEach(group => {
                group.products.forEach(product => {
                    const selectedProduct = cartProducts.find(cartProduct => cartProduct.Id === product.Id);
                    selectedProduct ? product.isSelected = true : product.isSelected = false;
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
        console.log('filteredProducts: ', JSON.parse(JSON.stringify(this.filteredProducts)));
        
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
        if (this.omniJsonData?.oldProducts?.find(item => item.Type__c == 'Medical')?.Name.includes("UHSM")) {
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

    async connectedCallback() {

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
        this.getPlanGroups();
        if (this.stateData) {
            this.parseSavedState(this.stateData);

        } else {
            await this.getProducts();
        }
        const cartProducts = omniscriptUtils.getCartProducts(this);
        if (cartProducts.length === 0) {
             // Update the OS json to an empty array
            omniscriptUtils.updateCartProducts(this, [], this.rootChannel);
        }
        this.cartProductCount();

        let wantsAncillaryFromJson = this.omniJsonData?.STEP_PlanSelection?.RAD_WantsAncillary;
        let enforceWantsAncillarySelection = this.omniJsonData?.STEP_PlanSelection?.EnforceWantsAncillarySelection;
        let selectedProducts = this.omniJsonData?.selectedProducts;
        let isLegacyProductSelected = selectedProducts?.some(product => product.Name === 'WeShare Legacy')

        if (isLegacyProductSelected) {
            this.wantsAncillary = 'No'
            this.disableAncillary = true
        } else if (this.hadAncillaries && !this.wantsAncillary && enforceWantsAncillarySelection != true) {
            this.wantsAncillary = this.hadAncillaries;
        } else {
            this.wantsAncillary = wantsAncillaryFromJson;
        }
        
        this.omniApplyCallResp({
            STEP_PlanSelection: {
                RAD_WantsAncillary: this.wantsAncillary
            }
        });
        // if (this.hadAncillaries && !this.wantsAncillary) {

        //     this.wantsAncillary = this.hadAncillaries;
        //     this.omniApplyCallResp({
        //         STEP_PlanSelection: {
        //             RAD_WantsAncillary: this.wantsAncillary
        //         }
        //     });
        // }
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
    }

    async preSelectOldProducts() {
        // Log the current state of relevant properties for debugging purposes.
        // Using JSON.parse(JSON.stringify()) ensures a deep copy of the data,
        // which avoids logging class properties which are reactive or proxied objects that might change over time.
        //console.log('oldProductIds =>', JSON.parse(JSON.stringify(this.oldProductIds)));
        //console.log('programType =>', JSON.parse(JSON.stringify(this.programType)));
        //console.log('filteredProducts =>', JSON.parse(JSON.stringify(this.filteredProducts)));

        // Filter the products to find those that match the current selection step
        // and are included in the list of old product IDs.
        // - The product must match the current step, which can be either its `SubType__c` or `Type__c`.
        // - The product's ID must also exist in the `oldProductIds` list.

        // Iterate over the filtered list of old products and trigger the 'selectProduct' event
        // for each product after a 2-second delay. This delay is necessary because this function
        // is called in the `connectedCallback` lifecycle hook, and the component may not
        // be fully rendered yet. Without the delay, the event will not work as intended.

        // if selected products include an old product, return
        const alreadyHasSelection =
            Array.isArray(this.omniJsonData?.selectedProducts) &&
            this.omniJsonData.selectedProducts.some(product =>
                this.programType === product?.SubType__c ||
                this.programType === product?.Type__c
            );
        if (alreadyHasSelection) {
            return;
        }

        const oldPlans = (this.filteredProducts || []).filter(product =>
            (this.programType === product?.SubType__c ||
             this.programType === product?.Type__c) &&
            (this.oldProductIds || []).includes(product?.Id)
        );

        if (!oldPlans.length) {
            return;
        }

        await this.waitForRender();

        for (const product of oldPlans) {
            pubsub.fire(this.rootChannel, 'selectProduct', { detail: product.Id });
            await this.microTick();
        }
    }

    renderedCallback() {
        const stepCartProductIds = this.omniJsonData[this.stepName]?.[this.lwcName]?.cartProductIds;
        if (stepCartProductIds?.length) {
            requestAnimationFrame(() => {
                stepCartProductIds.forEach(prod => {
                    pubsub.fire(this.rootChannel, 'selectProduct', { detail: prod, from: 'renderedCallback' });
                });
            });
        }
        console.log('filteredproducts rend: ', JSON.parse(JSON.stringify(this.filteredProducts)));
        console.log('filteredAttributes rend: ', this.filteredAttributes);
    }

    splitProductsInGroups(products) {
        console.log('this.productsByGroup: ', this.productsByGroup);
         // Create a lookup map for productsByGroup
        const groupMap = this.productsByGroup.reduce((map, group) => {
            group.products.forEach(productCode => {
                map[productCode] = {
                    groupName: group.groupName,
                    uniqueAttributes: group.uniqueAttributes,
                    description: group.description,
                    hiddenAttributes: group.hiddenAttributes,
                };
            });
            return map;
        }, {});
        console.log('groupMap: ', groupMap);
        
         // Group products by their groupName
        const groupedProducts = products.reduce((acc, product) => {
            const groupInfo = groupMap[product.ProductCode];
            if (groupInfo) {
                const { groupName } = groupInfo;
                if (!acc[groupName]) {
                    acc[groupName] = [];
                }
                acc[groupName].push(product);
            }
            return acc;
        }, {});
        console.log('groupedProducts: ', groupedProducts);

         // Transform the grouped products into the desired output format
        return Object.entries(groupedProducts).map(([groupName, products]) => ({
            groupName,
            products,
            uniqueAttributes: groupMap[products[0].ProductCode]?.uniqueAttributes ?? [],
            description: groupMap[products[0].ProductCode]?.description ?? '',
            hiddenAttributes: groupMap[products[0].ProductCode]?.hiddenAttributes ?? [],
            showHealthyDiscountColumn: this.programType === 'Medical' && groupName !== 'Medal' && groupName !== 'Legacy',
        }));
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

    handle_RAD_WantsAncillary(event) {
        this.wantsAncillary = event.target.value;
        this.showWarning = this.wantsAncillary === 'No' && this.hadAncillaries === 'Yes';
        this.omniApplyCallResp({
            STEP_PlanSelection: {
                RAD_WantsAncillary: this.wantsAncillary,
                EnforceWantsAncillarySelection: true
            }
        });
    }

    get isPlanSelection() {
        return this.programType === 'Medical';
    }

    get wantsAncillaryIsYes() {
        return this.wantsAncillary === 'Yes';
    }
    
    get wantsAncillaryIsNo() {
        return this.wantsAncillary === 'No';
    }

    handler_NextStep() {
        if (this.wantsAncillary === 'No') {
            this.updateProductsInCart();
        }
        this.omniNextStep();
    }

    handler_PreviousStep() {
        this.omniPrevStep();
    }
}