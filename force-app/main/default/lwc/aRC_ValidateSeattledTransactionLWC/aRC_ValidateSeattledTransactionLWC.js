import { LightningElement, api, wire } from 'lwc';
import  getRecord  from '@salesforce/apex/ARC_ValidateSeattledTransaction.validateTransactionSettledDate';

export default class ARC_ValidateSeattledTransactionLWC extends LightningElement {

    lwcLoading = false;
    @api height
    settledDate
    errorMessage = 'No settle date found'
    @api recordId
    queryMade = false


    // @wire(getRecord, { recordId: "$recordId" })
    // handleRecord({ error, data }) {
    //     console.log(2)
    //     this.lwcLoading = true
    //     if (data) {
    //         this.settledDate = data
    //     } else if (!data || error) {
    //         this.settledDate = null
    //     }
    //     this.lwcLoading = false
    // }
    connectedCallback(){
        console.log(this.recordId)
        
            let list = [this.recordId];
            getRecord({ transaction_id: list }).then((data) => {
                if(data && data[0]){
                    this.settledDate = data[0]
                    console.log('Data ====== >', data)
                }else{
                    this.settledDate = null
                    console.log('Data2 ====== >', data)
                }
                            
                })
        
    }


    renderedCallback() {


        let card = this.template.querySelector('.card-outside')

        if (this.height) {
            card.style.height = this.height
        } else {
            card.style.height = "200px"
        }

    }
}