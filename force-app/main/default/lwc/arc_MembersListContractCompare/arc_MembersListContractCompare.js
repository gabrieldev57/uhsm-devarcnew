import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const columns = [
    { label: 'Name', fieldName: 'Id' , type: 'url' , typeAttributes: {label: {fieldName: 'Name'}, target:'_blank'}}
    ];
    

export default class Arc_MembersListContractCompare extends NavigationMixin(LightningElement) {


    
    @api record;
    columns = columns;
            
    @api
    get recordsList(){
        const record = JSON.stringify(this.record.Members); 
        //console.log("RECORD: " + record);       
        const members = JSON.parse(record);
        let arrayMembers = [];
        console.log("MEMBERS: " + JSON.stringify(members));
        if(Array.isArray(members)){
            for(let i=0; i<members.length; i++){
                members[i].Id = "/" + members[i].Id;
            }
            return members;   
        } else {
            arrayMembers.push(members);
            return arrayMembers;
        }
        
           
    }
}