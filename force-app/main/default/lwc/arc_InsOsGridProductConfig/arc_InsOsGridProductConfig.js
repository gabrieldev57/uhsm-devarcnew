import insOsGridProductConfig from 'vlocity_ins/insOsGridProductConfig';
import template from './arc_InsOsGridProductConfig.html';
import { dataFormatter} from 'vlocity_ins/insUtility';
import pubsub from 'vlocity_ins/pubsub';

export default class arc_InsOsGridProductConfig extends insOsGridProductConfig {

    /**
     *  Reprice
     */
     rePriceProduct() {
        this.isLoaded = false;
        this.repriceAction(this.product).then((response) => {
            if (response) {
                this.product = dataFormatter.parseResponse(response) || this.product;
                this.attrChanges = false;
                const message = {
                    attrChanges :  this.attrChanges, 
                    product : this.product
                }
                pubsub.fire(this.rootChannel, 'attrChanges', message);
                this.isLoaded = true;
            }
        });
    }

}