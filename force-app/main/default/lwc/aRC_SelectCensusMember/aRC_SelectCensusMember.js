import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';


export default class aRC_SelectCensusMember extends OmniscriptBaseMixin(LightningElement)  {
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
        this.lstInputJson = JSON.parse(JSON.stringify(this.omniJsonData.CensusMember));
        console.log("this.lstInputJson " + JSON.stringify(this.lstInputJson))
        console.log(Array.isArray(this.lstInputJson))
        if(Array.isArray(this.lstInputJson)){
            this.lstInputJson.forEach(Nodes => {      
                let ob = Object.create(this.customObject);
                ob.label = Nodes.CensusMemberName;
                ob.value = Nodes.CensusMemberName;
                ob.id = Nodes.CensusMemberId;
                this.optionsList.push(ob);
            });
        } else {
            let ob = Object.create(this.customObject);
                ob.label = this.lstInputJson.CensusMemberName;
                ob.value = this.lstInputJson.CensusMemberName;
                ob.id = this.lstInputJson.CensusMemberId;
                this.optionsList.push(ob);
        }
     
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