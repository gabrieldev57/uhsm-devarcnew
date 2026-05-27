import { LightningElement,api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';


export default class ARC_ExternalInsurerCard extends OmniscriptBaseMixin(NavigationMixin(LightningElement)) {

    @api recordId; // Person Account Id
    @api insurersList=[]; // List of Insurers( Healthcare Providers )
    @api renderComponent=false;
    
    // new
    @api formButton = false;
    showForm = false;
    get prefill(){
        return {
            ContextId: this.recordId
        };
    }
    
    async connectedCallback(){

        let response = await this.omniRemoteCall({
            input: {'personAccountId': this.recordId},
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'PersonAccount_ReadExternalInsurer',
            options: '{}',
        }, true)

        if (!response.error) {
            this.insurersList = response.result.IPResult.response;
            this.renderComponent=true;
            console.log('ok',JSON.stringify(response.result.IPResult.response));
            console.log('this.renderComponent',JSON.stringify(this.renderComponent));
        }
        else console.log('error',JSON.stringify(response));
    }

    refreshComponent(data) {
        this.connectedCallback();
    }

    navigateToRecordPage(event) {
        const recordId = event.target.dataset.id;
        console.log('recordId',recordId);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        });
    }

    // add primary insurance
    toggleForm(event) {
        this.showForm = !this.showForm ;
        console.log('showForm',this.showForm);
    }
    
}