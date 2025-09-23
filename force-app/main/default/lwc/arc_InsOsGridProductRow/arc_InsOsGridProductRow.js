import insOsGridProductRow from 'vlocity_ins/insOsGridProductRow';
import { track, api } from 'lwc';
import tileTemplate from './arc_InsOsGridProductRow.html';
import pubsub from 'vlocity_ins/pubsub';
import { dataFormatter } from 'vlocity_ins/insUtility';

export default class arc_InsOsGridProductRow extends insOsGridProductRow {

    @api repriceAction;
    @track isCartFull;
    @api groupName;
    inCartProgram;
    inCartProgramId;

    isDisabled = true;
    // parsedAttrkibutes;

    pubsubPayload = {
        addCartProdEvent: this.setConfigProduct.bind(this),
    };

    @api
    get product() {
        return this._product;
    }

    set product(data) {

        this._product = data;
        this.price = data.Price || 0;
        if (data.originalPlan && data.originalPlan.records && data.originalPlan.records.length) {
            this.renewalOldProduct = data.originalPlan.records[0];
        }
    }

    get showEditAction() {
        let product = JSON.parse(JSON.stringify(this.product));
        return product.IsConfigurable__c == true && this.showConfigInline !== 'true';
    }

    clickModalCustomConfigPlan() {
        pubsub.fire(this.rootChannel, 'openProductConfigModal', { product: this.product });
    }

    openDetailsProduct() {
        if (this.isCart) {
            pubsub.fire(this.rootChannel, 'closeCartModal');
        }
        const products = [this.product];
        pubsub.fire(this.rootChannel, 'openProductModal', { products, isCart: this.isCart });
    }

    setCartProgram(objPayload) {
        if (objPayload.type) {
            if (objPayload.type === 'Medical') {
                if (this.inCartProgramId === undefined) {
                    this.inCartProgram = objPayload.program;
                    this.inCartProgramId = objPayload.detail;
                } else if (this.inCartProgramId === objPayload.detail) {
                    this.inCartProgram = undefined;
                    this.inCartProgramId = undefined;
                }
            }
        } else if (this.inCartProgramId === objPayload.detail) {
            this.inCartProgram = undefined;
            this.inCartProgramId = undefined;
        }
        // works until product is updated
    }

    setConfigProduct(objPayload) {
        this.setCartProgram({ detail: objPayload.detail.Id, program: objPayload.detail.Name, type: objPayload.detail.Type__c });
    }

    selectProduct() {
        if (this._product.Type__c === 'Medical') {
            if (this.inCartProgram === undefined || this.inCartProgram === this._product.Name) {
                pubsub.fire(this.rootChannel, 'selectProduct', { detail: this._product.Id, program: this._product.Name, type: this._product.Type__c });
            } else {
                this.showCartPopup();
            }
        } else {
            pubsub.fire(this.rootChannel, 'selectProduct', { detail: this._product.Id });
        }
    }

    showCartPopup() {
        if (!this.isCartFull) {
            this.isCartFull = true;
            window.setTimeout(() => { this.isCartFull = false }, 3000);
        }
    }

    render() {
        return tileTemplate;
    }

    filteredAttributes;



    sendGeneralAttributesToParent(groupName, attributes) {
        const customEvent = new CustomEvent('senddata', {
            detail: {
                attributes: attributes,
                groupName: groupName
            }
        });
        this.dispatchEvent(customEvent);
    }


    set parsedAttributes(data) {


        this.filteredAttributes = this.getUniqueAttributes(data);
        this.sendGeneralAttributesToParent(this.groupName, this.getGeneralAttributes(data))

    }

    @api uniqueAttributes;
    getUniqueAttributes(attributes) {
        return attributes.filter(attr => this.uniqueAttributes.includes(attr.label));
    }

    getGeneralAttributes(attributes) {
        return attributes.filter(attr => !this.uniqueAttributes.includes(attr.label));
    }




}