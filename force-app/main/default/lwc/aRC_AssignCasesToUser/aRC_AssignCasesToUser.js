import { LightningElement, api } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import { NavigationMixin } from 'lightning/navigation';

// export default class ARC_AssignCasesToUser extends LightningElement {
export default class ARC_AssignCasesToUser extends NavigationMixin(LightningElement) {
    @api listViewIds

    connectedCallback() {
        // for (const id of this.listViewIds) {
        //     window.open(`${window.location.origin}/lightning/r/Case/${id}/view`, "_blank")
        // };

        //Refresh View
        // window.location.reload();
        eval("$A.get('e.force:refreshView').fire();");
    }
}