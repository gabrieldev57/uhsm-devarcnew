import { api, track } from 'lwc';
import insOsEnrolleeBenefitsSummary from 'vlocity_ins/insOsEnrolleeBenefitsSummary';


export default class arc_insOsEnrolleeBenefitsSummary extends insOsEnrolleeBenefitsSummary {
    @api initJson;
    @api dependents;
    @api productlist;

    @track isLoaded;

    connectedCallback() {
        console.log(this.initJson);
        console.log(this.dependents);
        console.log(this.productlist);
        if ( this.productlist ) {
            this.setNewdependents();
        }
        super.connectedCallback();
    }
    
    setNewdependents() {
        console.log('In setNewdependents');
        const members = [];
        const createdMemberIds = [];
        for ( let product of this.productlist ) {
            for ( let member of product.userInputs ) {
                // Creates the member if not present
                if ( !createdMemberIds.includes(member.CensusMemberId) ) {
                    const newMember = {};
                    newMember.Id = member.CensusMemberId;
                    newMember.Age = member['RF_Census.CM_Age'];
                    newMember.FirstName = member.CensusMemberFirstName;
                    newMember.LastName = member.CensusMemberLastName;
                    newMember.productsIds = [];
                    members.push(newMember);
                    createdMemberIds.push(member.CensusMemberId);
                }
                // Iterates through all the members added in the list and adds the program
                for ( let m of members ) {
                    if ( member.CensusMemberId === m.Id ) {
                        m.productsIds.push(product.selectedProduct.Id);
                    }
                } 
            }
        }
        this.dependents = members;
        console.log(this.dependents);
    }
}