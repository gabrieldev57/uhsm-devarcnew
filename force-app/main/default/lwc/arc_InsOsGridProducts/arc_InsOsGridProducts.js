import insOsGridProducts from 'vlocity_ins/insOsGridProducts';
import { track, api } from 'lwc';
import pubsub from 'vlocity_ins/pubsub';
//import pubsub from 'vlocity_ins/pubsub';

export default class arc_InsOsGridProducts extends insOsGridProducts {
    products;
    filteredAttributes;
    isGeneralAttribute = true;

    pubsubPayload = {
        updateProductList: this.updateProductList.bind(this)
    };

    connectedCallback() {
        pubsub.register(this.rootChannel, this.pubsubPayload);
    }

    updateProductList(data) {
        let currentProducts = JSON.parse(JSON.stringify(this.products))
        this.products = currentProducts.map(product => {

            if (product.Id == data.Id) {
                product = data;
            }
            return product;
        });
    }



    handleDataFromChild(event) {


        this.products.forEach(group => {

            if (group.groupName == event.detail.groupName) {

                this.sendGeneralAttributesToParent(event.detail.groupName, event.detail.attributes);
            }
        });
        // 
    }

    sendGeneralAttributesToParent(groupName, attributes) {

        const customEvent = new CustomEvent('senddata', {
            detail: {
                attributes: attributes,
                groupName: groupName
            }
        });
        this.dispatchEvent(customEvent);
    }

    openDetailsProduct(event) {
        if (this.isCart) {
            pubsub.fire(this.rootChannel, 'closeCartModal');
        }

        const products = this.removeHiddenAttributes(JSON.parse(JSON.stringify([this.products.find(p => p.groupName == event.currentTarget.dataset.group)?.products[0]])), this.products.find(p => p.groupName == event.currentTarget.dataset.group).hiddenAttributes);

        pubsub.fire(this.rootChannel, 'openProductModal', { products, isCart: false, modalTitle: event.currentTarget.dataset.group });
    }


    renderedCallback() {
        this.products.forEach(group => {
            const className = '.' + group.groupName;
            if (this.template.querySelector(className)) {
                this.template.querySelector(className).innerHTML = group.description;
            }
        });
    }

    removeHiddenAttributes(products, hiddenAttributes) {
        const hiddenAttributesMap = [];
        hiddenAttributes.forEach(attribute => {
            hiddenAttributesMap.push({ section: attribute.split(':')[0], label: attribute.split(':')[1] });
        });
        products[0].attributeCategories.records.forEach(category => {
            category.productAttributes.records = (category.productAttributes.records.filter(attribute => {
                return !hiddenAttributesMap.filter(attribute2 => { return attribute2.section == 'header' }).map(attribute2 => attribute2.label).includes(attribute.label);
            }));
        });
        products[0].childProducts.records.forEach(category => {
            category.attributeCategories.records.forEach(attributeCategorie => {
                attributeCategorie.productAttributes.records = attributeCategorie.productAttributes.records.filter(
                    attribute => {
                        return !hiddenAttributesMap.filter(hiddenAttribute => {
                            return hiddenAttribute.section == category.Name
                        }).map(hiddenAttribute => hiddenAttribute.label).includes(attribute.label);
                    }
                );

            });
        });
        // 
        // products[0].attributeCategories.records = filteredProducts
        return products;
    }
}