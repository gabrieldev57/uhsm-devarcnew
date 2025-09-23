import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class ARC_Spam extends NavigationMixin(LightningElement) {


    connectedCallback(){
        // Navigate to the Case object's Recent list view.
        this[NavigationMixin.Navigate]({
            type: "standard__objectPage",
            attributes: {
              objectApiName: "Case",
              actionName: "list",
            },          
          });
    }
    


      
      

}