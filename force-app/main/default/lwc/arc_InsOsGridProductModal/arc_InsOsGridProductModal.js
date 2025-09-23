import InsOsGridProductModal from 'vlocity_ins/insOsGridProductModal';
import template from './arc_InsOsGridProductModal.html';
import { LightningElement, api } from 'lwc';
import pubsub from 'vlocity_ins/pubsub';

import { dataFormatter } from 'vlocity_ins/insUtility';

export default class arc_InsOsGridProductModal extends InsOsGridProductModal {

    @api lastMedicalSelectionId;
    @api medicalWarning;
    @api smartWarning;
    @api aiddWarning;
    @api rootChannel;
    @api theme = 'slds';
    products = [];
    hideHeader = false;
    hideFooter = false;
    currency = dataFormatter.currency;
    labels = {
        InsMonthAbrv: 'mo',
        InsComparePlans: 'Compare Programs',
        BrochuresLabel: 'Brochure',
        Edit: 'Edit',
        View: 'View'
    }
    @api modalTitle;

    hiddenRecordTypes = { 'RatingFactSpec': true, 'InsuredPartySpec': true };

    pubsubPayload = {
        openProductModal: this.openProductModal.bind(this)
    };

    render() {
        return template;
    }


    connectedCallback() {
        pubsub.register(this.rootChannel, this.pubsubPayload);
    }

    disconnectedCallback() {
        pubsub.unregister(this.rootChannel, this.pubsubPayload);
    }

    openProductModal(payload) {
        const isCart = (payload.isCart === 'true' || payload.isCart === true);
        this.isEditable = payload.isEditable;
        this.modalTitle = this.labels.InsComparePlans;
        this.hideHeader = payload.products.length === 1;
        this.hideFooter = !isCart;
        this.compareLimit = payload.compareLimit;
        this.selectBtnFn = payload.selectBtnFn;
        this.products = this.formatData([...payload.products]);


        if (this.hideHeader) {
            this.product = this.products[0];
            if (payload.modalTitle) {
                delete this.products[0].Price;
                // this.products[0].attributeCategories.records[1].productAttributes.records.forEach((attr, index) => {
                //     
                //     if (attr.code === 'familyAMCS') {
                //         delete this.products[0].attributeCategories.records[1].productAttributes.records[index];
                //     }
                //     if (attr.code === 'individualAMCS') {
                //         delete this.products[0].attributeCategories.records[1].productAttributes.records[index];
                //     }

                // });
                // delete this.products[0].attributeCategories.records[1].productAttributes.records[0];
                // delete this.products[0].attributeCategories.records[1].productAttributes.records[1];

            }
            let label = this.isEditable ? this.labels.Edit : this.labels.View;
            this.modalTitle = payload.modalTitle ? payload.modalTitle : label + ' ' + this.product.Name;
            this.price = this.product.Price || 0;
        }

        this.template.querySelector('vlocity_ins-modal').openModal();
    }

    backToCart() {
        this.template.querySelector('vlocity_ins-modal').closeModal();
        pubsub.fire(this.rootChannel, 'backToCart');
    }

    //Hide recordtypes & Names
    formatData(products) {
        return products.map(product => {
            const tempProduct = dataFormatter.deserializeHelper({ ...product }, 'childProducts');
            tempProduct.priceNote = '/' + this.labels.InsMonthAbrv;
            if (tempProduct.childProducts && tempProduct.childProducts.records) {
                tempProduct.childProducts.records = tempProduct.childProducts.records.reduce((acc, childProd) => {
                    const type = dataFormatter.getNamespacedProperty(childProd, 'RecordTypeName__c');
                    const name = dataFormatter.getNamespacedProperty(childProd, 'Name');

                    if (!this.hiddenRecordTypes[type] && !name.includes('DocDay Telehealth')) {
                        childProd.hidePrice = true;
                        acc.push(childProd);
                    }
                    return acc;
                }, []);
            }
            return tempProduct;
        });
    }
}