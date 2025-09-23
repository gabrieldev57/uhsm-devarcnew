import { LightningElement, api, track } from 'lwc';
import loginToPortal from '@salesforce/apex/ARC_CommunityController.loginWithPortalUsername';
import sendReactivationURL from '@salesforce/apex/ARC_CommunityController.sendReactivationURL';
import { NavigationMixin } from 'lightning/navigation';

export default class ARC_CommunityCustomLogin extends NavigationMixin(LightningElement) {
    @track portalUsername = '';
    @track password = '';
    errorMessage = '';
    loading = false;
    error = false;
    inactiveUser = false;
    inactiveUserEmailSent = false;

    //Get the input username
    handleUsernameChange(event) {
        this.portalUsername = event.target.value;
    }

    //Get the input password
    handlePasswordChange(event) {
        this.password = event.target.value;
    }

    //Process the logic when the user clicks the login button
    handleLogin() {
        this.error = false;
        this.inactiveUser = false;
        this.loading = true;
        if (this.portalUsername != '' && this.password != '') {
            loginToPortal({ portalUserName: this.portalUsername, password: this.password })
                .then((result) => {
                    console.log('result', result);
                    if (result.success) {
                        this.navigateToWebPage(result.loginURL);
                    } else {
                        if (result.inactiveUser) {
                            this.inactiveUser = true;
                        } else {
                            this.errorMessage = 'Your login attempt has failed. Make sure the username and password are correct.';
                            this.error = true;
                            console.log('Error loggin attempt: ' + result.message);
                        }
                    }
                })
                .finally(() => {
                    this.loading = false;
                })
        }
        else if (this.portalUsername == '') {
            this.errorMessage = 'Enter a value in the User Name field.';
            this.error = true;
            this.loading = false;
        }
        else if (this.password == '') {
            this.errorMessage = 'Enter a value in the Password field.';
            this.error = true;
            this.loading = false;
        }

    }

    // Submit using Enter
    enterSubmit(evt) {
        if (evt.keyCode == '13') this.handleLogin();
    }

    //Logic executed when the user clicks on the Forgot Username button.
    handleForgotUsername() {
        this.navigateToCommunityPage('ForgotUsername__c');
    }

    handleForgotPassword() {
        this.navigateToCommunityPage('Forgot_Password');
    }

    //Redirect the user to the provided page.
    navigateToWebPage(page) {
        window.location.href = page;
    }

    //Redirect the user to a community page. 
    navigateToCommunityPage(api_page) {
        this[NavigationMixin.Navigate]({
            type: "comm__namedPage",
            attributes: {
                name: api_page
            }
        });
    }

    handleActivateUser() {
        sendReactivationURL({ portalUsername: this.portalUsername });
        this.inactiveUserEmailSent = true;
        this.inactiveUser = false;
    }

}