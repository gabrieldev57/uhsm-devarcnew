import InsOsGridProductConfigModal from 'vlocity_ins/insOsGridProductConfigModal';
import template from './arc_insOsGridProductConfigModal.html';
import { api, track } from 'lwc';
import pubsub from 'vlocity_ins/pubsub';

export default class arc_insOsGridProductConfigModal extends InsOsGridProductConfigModal {
    inCartProgram;
    inCartProgramId;
    @api rootChannel;
    @api repriceAction; 
    @track isCartFull;

    pubsubPayload = {
        openProductConfigModal: this.openProductConfigModal.bind(this),
        attrChanges: this.attrChangesEvt.bind(this),
        selectProduct: this.setCartProgram.bind(this), 
        addCartProdEvent: this.setConfigProduct.bind(this)
    };
    
    openProductConfigModal(payload) {
        this.product = { ...payload.product };
        this.resetProduct = { ...payload.product };
        this.modalTitle = this.labels.Edit + ' ' + this.product.Name;
        this.attrChanges = false;
        this.template.querySelector('vlocity_ins-modal').openModal();
    }

    /**
    * Reprice
    */
    rePriceProduct() {
        pubsub.fire(this.rootChannel, 'rePriceProduct', true);
    }

    connectedCallback() {
        pubsub.register(this.rootChannel, this.pubsubPayload);
    }

    disconnectedCallback() {
        pubsub.unregister(this.rootChannel, this.pubsubPayload);
    }

    setCartProgram(objPayload){
        if(objPayload.type) {
            if(objPayload.type === 'Medical') {
                if(this.inCartProgramId === undefined) {
                    this.inCartProgram = objPayload.program;
                    this.inCartProgramId = objPayload.detail;
                } else if(this.inCartProgramId === objPayload.detail) {
                    this.inCartProgram = undefined;
                    this.inCartProgramId = undefined;
                }
            }
        } else if(this.inCartProgramId === objPayload.detail) {
            this.inCartProgram = undefined;
            this.inCartProgramId = undefined;
        }
    }

    setConfigProduct(objPayload) {
        this.setCartProgram({ detail: objPayload.detail.Id, program: objPayload.detail.Name, type: objPayload.detail.Type__c });
    }

    addToCartProd() {
        if(this.product.Type__c === 'Medical') {
            if(this.inCartProgram === undefined || this.inCartProgram === this.product.Name) {
                this.product.isSelected = !this.product.isSelected;
                let message = this.labels.InsProductAddedAttrNameMessage.replace('{0}', this.product.Name);  
                pubsub.fire(this.rootChannel, 'addCartProdEvent', { detail: this.product });
                if (this.product.isSelected) {
                    commonUtils.showSuccessToast.call(this, message);
                }
            } else {
                this.showCartPopup();
            }
        } else {
            this.product.isSelected = !this.product.isSelected;
            let message = this.labels.InsProductAddedAttrNameMessage.replace('{0}', this.product.Name);    
            pubsub.fire(this.rootChannel, 'addCartProdEvent', { detail: this.product });
            if (this.product.isSelected) {
                commonUtils.showSuccessToast.call(this, message);
            }
        }
    }

    showCartPopup() {
        if(!this.isCartFull) {
            this.isCartFull = true;
            window.setTimeout(() => { this.isCartFull = false }, 3000);
        }
    }
    
    render() {
        return template;
    }

}