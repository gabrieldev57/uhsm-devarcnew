import { LightningElement, track } from 'lwc';
import resetPassword from '@salesforce/apex/ARC_CommunityController.forgotPasswordEmail';
import { NavigationMixin } from 'lightning/navigation';


export default class ARC_CommunityForgotPassword extends NavigationMixin(LightningElement) {

    errorMessage = '';
    error = false;
    @track portalUsername = '';
	showSpinner = false;


    handleUsernameChange(event) {
        this.portalUsername = event.target.value;
    }

    async handleReset() {
        this.showSpinner = true;

        if(this.portalUsername == ''){
            this.errorMessage = 'Enter a value in the User Name field.';
            this.error=true;
            this.showSpinner = false;
            return;
        }

        await resetPassword({ portalUsername: this.portalUsername })
        this.navigateToCommunityPage('Check_Email__c')
    }

    //Redirect the user to a community page. 
    navigateToCommunityPage(api_page){
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: {
                name: api_page
            }
        });
    }
}