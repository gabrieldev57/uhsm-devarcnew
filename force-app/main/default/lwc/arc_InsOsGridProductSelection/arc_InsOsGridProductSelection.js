import insOsGridProductSelection from 'vlocity_ins/insOsGridProductSelection';
import { track, api } from 'lwc';
import { commonUtils, dataFormatter, omniscriptUtils } from 'vlocity_ins/insUtility';
import pubsub from 'vlocity_ins/pubsub';
import template from './arc_InsOsGridProductSelection.html';

export default class Arc_InsOsGridProductSelection extends insOsGridProductSelection {

    @track sortValue = 'Low';
    @track repriceActionFn;
    @track reloadProducts = true;
    @api selectedMedical;
    @api selectedDental;
    @api selectedVision;
    @track allProducts = [];
    labels = {
        InsComparePlans : 'Compare Programs',
        BrochuresLabel : 'Brochure'
    }

    render() {
        this.stateData = null;
        return template;
    }

    getProducts() {
        this.products = [];
        this.disableSortSelect = true;
        this.reFormulateFilterString();
        this.initAction.optionsMap.filters = this.serviceFilterString;
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
                                if (!this.isCancelProductFetch) {
                                    const response = JSON.parse(res);
                                    let records;
                                    if (response.records) {
                                        records = response.records;
                                    } else if (response.result && response.result.listProducts) {
                                        records = response.result.listProducts.records;
                                    }
                                    this.formatProducts(records);
                                }
                                return res;
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
                            this.updateProductsInCart();
                            this.updateProducts();
                            this.initAction.optionsMap.filters = this.getFilter();
                            omniscriptUtils.omniGenericInvoke(this, this.initAction)
                                .then(response => {
                                    const eligibleProductsResponse = JSON.parse(response);
                                    this.totalAllNumProducts = eligibleProductsResponse.totalNumProducts;
                                    if (this.totalAllNumProducts > 0) {
                                        const productIdBatches = this.groupProductIds(eligibleProductsResponse.products);
                                        const batchOperations = productIdBatches.map(productIds => {
                                            const batchDataMap = this.getRatedProductsDataMap(productIds);
                                            return () => {
                                                return omniscriptUtils.omniGenericInvoke(this, batchDataMap).then(res => {
                                                    if (!this.isCancelProductFetch) {
                                                        const response = JSON.parse(res);
                                                        let records;
                                                        if (response.records) {
                                                            records = response.records;
                                                        } else if (response.result && response.result.listProducts) {
                                                            records = response.result.listProducts.records;
                                                        }
                                                        this.formatAllProducts(records);
                                                    }
                                                    return res;
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
                                                this.updateCartValues();
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
                            // this.isLoaded = true;
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
            cartProductsFiltered = cartProducts.filter(product => product.Type__c === this.selectedMedical || product.Type__c === this.selectedDental || product.Type__c === this.selectedVision);
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
            this.filteredProducts.forEach(product => {
                const selectedProduct = cartProducts.find(cartProduct => cartProduct.Id === product.Id);
                selectedProduct ? product.isSelected = true : product.isSelected = false;
                pubsub.fire(this.rootChannel, 'updateProduct', { product: product });
            });
        }
    }

    filterProducts() {
        this.filteredProducts = this.products.filter(product => {
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
        this.filteredProducts = this.filteredProducts.sort(this.dynamicSort('Price', this.sortValue));
        this.totalNumProducts = this.filteredProducts.length;
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
            if (sortType == 'High') {
                result = (b[property] < a[property]) ? -1 : (b[property] > a[property]) ? 0 : 1;
            } else {
                result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 0 : 1;
            }

            return result * sortOrder;
        }
    }

    sortComboChange(e) {
        this.filteredProducts = this.filteredProducts.sort(this.dynamicSort('Price', e.target.value));
        this.sortValue = e.target.value;
    }

    prepareSortCombo() {
        var labelPrice = 'By Price';
        var sortKey = 'Price';
        const optsMap = [
            {
                label: 'Price Low to High',
                value: 'Low'
            },
            {
                label: 'Price High to Low',
                value: 'High'
            }
        ];

        this.sortCombo = { labelPrice, optsMap, sortKey };
    }


    get showInlineConfiguration() {
        return false;
    }

}