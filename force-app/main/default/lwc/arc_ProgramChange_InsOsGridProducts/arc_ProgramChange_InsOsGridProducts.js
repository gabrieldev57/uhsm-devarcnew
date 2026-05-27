import insOsGridProducts from 'vlocity_ins/insOsGridProducts';
import { track, api } from 'lwc';
import pubsub from 'vlocity_ins/pubsub';

export default class arc_ProgramChange_InsOsGridProducts extends insOsGridProducts {
    @api hasHealthyDiscountApplied
    @api programType
    _products;
    filteredAttributes;
    isGeneralAttribute = true;

    get products() {
        return this._products;
    }

    set products(value) {
        if (value) {
        this._products = value.map(group => {
                return {
                    ...group,
                    showHealthyDiscountColumn:
                        this.programType === 'Medical' &&
                        group.groupName !== 'Access' && 
                        group.groupName !== 'Legacy'
                };
            });
        }
    }


    pubsubPayload = {
        updateProductList: this.updateProductList.bind(this)
    };

    get showHealthyDiscountColumn(){
        return this.programType == 'Medical';
    }

    
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
            const containers = this.template.querySelectorAll('div[class]');
            const container = Array.from(containers).find(elem => 
                elem.getAttribute('class') === group.groupName
            );
            if (container && group.description) {
                container.innerHTML = group.description;
            }

            // const className = '.' + group.groupName;
            // if (this.template.querySelector(className)) {
            //     this.template.querySelector(className).innerHTML = group.description;
            // }
        });
    }

    removeHiddenAttributes(products, hiddenAttributes) {
        if (!hiddenAttributes?.length) {
            return products;
        }
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
        return products;
    }
}