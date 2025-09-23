import insOsEnrolleeBenefitsSummary from 'vlocity_ins/insOsEnrolleeBenefitsSummary';
// import { api, track } from 'lwc';
// import { dataFormatter, omniscriptUtils } from 'vlocity_ins/insUtility';

export default class aRC_360PlanDetails extends insOsEnrolleeBenefitsSummary {


    // @api initJson;
    // @api dependents;

    // @track isLoaded;

    // connectedCallback() {
    //     this.rootChannel = `ProductSelectionChannel-${dataFormatter.uniqueKey()}`;
    //     const dataOmniLayout = this.getAttribute('data-omni-layout');
    //     this.theme = dataOmniLayout === 'newport' ? 'nds' : 'slds';
    //     this.initData();
        
    //     console.log("----------------- CONSOLE LOG 360 PLAN DETAILS -----------------")
    //     console.log(JSON.stringify(this.initJson))
    // }


    // initData() {
    //     if (this.initJson) {
    //         this.setPlans(this.initJson);
    //         this.isLoaded = true;
    //     } else {
    //         this.getPlans();
    //     }
    // }

    // /**
    //  * Sets plans
    //  * @param {Array} records 
    //  */
    // setPlans(records) {
    //     this.plans = records.map(p => {
    //         let plan = dataFormatter.formatProduct(JSON.parse(JSON.stringify(p)), { isProductSelection: true });
    //         plan.uniqueKey = dataFormatter.uniqueKey();
    //         return plan;
    //     });
    // }

    // /**
    // * Retrieves product data if it wasn't already provided
    // */
    // getPlans() {
    //     // Optionally defined in OS step's json
    //     const initAction = this.omniJsonDef.propSetMap.initAction;
    //     const initActionCall = omniscriptUtils.formatQuery(
    //         this.omniGetMergeField.bind(this),
    //         initAction,
    //         'InsProductService',
    //         'getRatedProducts'
    //     );
    //     // Optionally defined in `CUSTOM LIGHTNING WEB COMPONENT PROPERTIES`
    //     omniscriptUtils.omniGenericInvoke(this, initActionCall)
    //         .then(response => {
    //             response = JSON.parse(response);
    //             if (response.records) {
    //                 this.setPlans(response.records);
    //             }
    //         }, error => {
    //             console.error(error);
    //         })
    //         .finally(() => {
    //             this.isLoaded = true;
    //         });
    // }

}