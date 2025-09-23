import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';


export default class ARC_CreateHospitalizations extends OmniscriptBaseMixin(LightningElement)  {
    value = [];
    optionsList = [];
    isRequired=true;
    txt = null;
    lstInputJson = [];
    customObject = {
        label: null,
        value: null,
        id: null
    }


    async connectedCallback() {
        this.lstInputJson = JSON.parse(JSON.stringify(this.omniJsonData.EditBlock));
        this.lstInputJson.forEach(Nodes => {      
            let ob = Object.create(this.customObject);
            ob.label = Nodes.CensusMemberName;
            ob.value = Nodes.CensusMemberName;
            ob.id = Nodes.CensusMemberId;
            this.optionsList.push(ob);
        });
        console.log(this.lstInputJson);
    }

    get options() {
        return this.optionsList;
    }


    handleChange(event) {
        this.omniUpdateDataJson({ "SelectedCensusMemberName": event.detail.value });
        this.lstInputJson.forEach(Nodes => {
            if(Nodes.CensusMemberName === event.detail.value){
            this.omniUpdateDataJson({ "SelectedCensusMemberId": Nodes.CensusMemberId });
            }
        })
    }
}