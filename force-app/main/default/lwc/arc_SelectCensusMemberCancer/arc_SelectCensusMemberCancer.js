import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';


export default class arc_SelectCensusMemberCancer extends OmniscriptBaseMixin(LightningElement)  {
    value = [];
    optionsList = [];
    isRequired=true;
    txt = null;
    lstInputJson = [];
    customObject = {
        label: null,
        value: null,
        id: null,
        Birthdate: null
    }


    async connectedCallback() {
        this.lstInputJson = JSON.parse(JSON.stringify(this.omniJsonData.CensusMember));
        console.log("this.1stinputjson connceted: "+JSON.stringify(this.lstInputJson))
        this.lstInputJson.forEach(Nodes => {      
            let ob = Object.create(this.customObject);
            ob.label = Nodes.CensusMemberName;
            ob.value = Nodes.CensusMemberName;
            ob.id = Nodes.CensusMemberId;
            ob.Birthdate = Nodes.Birthdate
            this.optionsList.push(ob);
        });
    }

    get options() {
        return this.optionsList;
    }


    handleChange(event) {
        console.log("this.1stinputjson HANDLECHANGE: "+JSON.stringify(this.lstInputJson))
        this.omniUpdateDataJson({ "SelectedCensusMemberName": event.detail.value });
        this.lstInputJson.forEach(Nodes => {
            if(Nodes.CensusMemberName === event.detail.value){
            this.omniUpdateDataJson({ "SelectedCensusMemberId": Nodes.CensusMemberId });
            this.omniUpdateDataJson({ "SelectedCensusMemberBirthdate": Nodes.Birthdate });
            }
        })
    }
}