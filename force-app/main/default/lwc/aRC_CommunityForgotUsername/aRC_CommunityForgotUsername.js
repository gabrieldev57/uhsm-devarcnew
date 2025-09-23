import { LightningElement, track } from 'lwc';
import getUsernames from '@salesforce/apex/ARC_CommunityController.forgotUserNameEmail';
import { NavigationMixin } from 'lightning/navigation';

export default class ARC_CommunityForgotUsername extends NavigationMixin(LightningElement)  {

    error = false;
    emailSent=false;
    errorMessage = '';
    @track email = '';

   //Get the input email.
    handleEmailChange(event) {
        this.email = event.target.value;
    }

    //Logic executed when the User clicks on Request Username button. 
    handleSend() {
        this.error = false;
        this.emailSent=false;
        if(this.email == ''){
            this.errorMessage = 'Please enter an email';
            this.error = true;
            return;
        }
        if(this.validateEmail(this.email)){
            getUsernames({ inputEmail: this.email })
                .then((result) => {
                    this.navigateToCommunityPage('Check_Email__c');
                })
                .catch(error => {
                    this.errorMessage = error?.body?.message? error?.body?.message : 'Sorry, something went wrong';
                    this.error = true;
                    console.log('errorMessage', error);
                })
        }
        else{
            this.errorMessage = 'Please enter a valid email';
            this.error = true;
        }
    }

    //Validate if the input email is has the email format.
    validateEmail(inputEmail){
        var re = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(String(inputEmail).toLowerCase());
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