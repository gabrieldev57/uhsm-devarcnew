import { LightningElement, api } from 'lwc';
import template from './arc_insProductMatrixRow.html';
import InsProductMatrixRow from 'vlocity_ins/insProductMatrixRow';
import pubsub from 'vlocity_ins/pubsub';


export default class arc_insProductMatrixRow extends InsProductMatrixRow {

    @api rootChannel;
    @api lastMedicalSelectionId;

    pubsubPayload = {

    };

    connectedCallback() {
        pubsub.register(this.rootChannel, this.pubsubPayload);
        this.isOverviewRow = this.rowStyle === 'overviewrow';
        this.isProductRow = this.rowStyle === 'productrow';
        this.isAttributeRow = this.rowStyle === 'attributerow';
        this.isHeaderRow = this.row.isHeader;
    }
    
    render(){
        return template;
    }

    deselectPrevious() {
        // const recordId = event.currentTarget.dataset.recordId;
        // this.selectBtnFn({ detail: recordId});
        let recordId = pubsub.fire(this.rootChannel, 'getLastMedicalId')
    }
    //Invoke custom select btn fn and switch ui for selected/not selected;
    toggleSelect(event) {
        // console.log("---------------------")
        // console.log("----toggle Select----")
        // console.log("---------------------")
        // console.log("----Last medical selected----")
        // console.log(this.lastMedicalSelectionId)
        const recordId = event.currentTarget.dataset.recordId;
        this.selectBtnFn({ detail: recordId});
        const index = event.currentTarget.dataset.recordIndex;
        this.contents[index].isSelected = !this.contents[index].isSelected;
        if(this.lastMedicalSelectionId){
           // console.log("----there is a last medical selected----")
            this.contents.forEach(prod => prod.productId == this.lastMedicalSelectionId ? prod.isSelected = !prod.isSelected : prod.isSelected)
        }
        //console.log('end of toggleSelect')

    }


}