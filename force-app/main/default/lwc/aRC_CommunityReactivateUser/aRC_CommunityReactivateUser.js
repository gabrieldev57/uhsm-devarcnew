import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import reactivateEncryptedUser from "@salesforce/apex/ARC_CommunityController.reactivateEncryptedUser";
import { NavigationMixin } from 'lightning/navigation';



export default class ARC_CommunityReactivateUser extends NavigationMixin(LightningElement) {

    error = false;
    errorMessage = '';
    success = false;
    loading = true;

    @wire(CurrentPageReference)
    getURLParameters(currentPageReference) {
        if (currentPageReference) {
            const encryptedUserId = decodeURIComponent(currentPageReference.state?.id).replaceAll(' ', '+');
            this.reactivateUser(encryptedUserId);
        }
    }

    async reactivateUser(encryptedUserId) {
        try {
            const response = await reactivateEncryptedUser({ 'encryptedUserId': encryptedUserId });
            console.log('Response: ', response);
            //listen to the event
            // this.handleSubscribe();

            if (response?.success == true) {
                this.success = true;
                this.successMessage = 'User reactivated successfully. You can now login to the community.';
            } else {
                console.error('Error reactivating user', e);
                this.navigateToCommunityPage('LinkExpiredOrUnavailable__c');
            }
        } catch (e) {
            console.error('Error reactivating user', e);
            this.navigateToCommunityPage('LinkExpiredOrUnavailable__c');
            // this.error = true;
            // this.errorMessage = e.body.message;
        }
        this.loading = false
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

    handleNavigateToLogin() {
        this.navigateToCommunityPage('Login__c');
    }

}