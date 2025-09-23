import { LightningElement, api, track } from 'lwc';
import { allCustomLabels } from 'vlocity_ins/omniscriptCustomLabels';
import { OmniscriptActionCommonUtil } from "vlocity_ins/omniscriptActionUtils";
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { getUserProfile, omniscriptUtils } from 'vlocity_ins/utility';
import { NavigationMixin } from 'lightning/navigation';


export default class UHSM_CustomSaveForLaterModal extends OmniscriptBaseMixin(NavigationMixin(LightningElement)) {

    _result = null;
    @api set result(value) {
        this._result = JSON.parse(JSON.stringify(value));
    }

    get result() {
        return this._result;
    }

    loading = true;
    communityPage = location.href.split('/s/')[1];
    modalType = 'success';
    modalLayout = 'newport';
    customLink;

    userProfile;
    emailSent = false;
    isGuestUserProfile = false;

    isUserLogged;
    loginLink;
    // userID;

    @track emailAddress;
    @api auto = false;
    
    async connectedCallback() {
        await getUserProfile().then((profile) => {
            this.isGuestUserProfile = profile.profilename === 'Member Community Profile' || profile.profilename === 'Member Community';
            this.isUserLogged = profile.profilename === 'Member Community';
        //    this.userID = profile.userid;
        });

        if (!this.auto) {
            if (this.isGuestUserProfile) {
                this.loginLink = `${location.href.split('/s/')[0]}/s/login/`;
                this.customLink = `${location.href.split('/s/')[0]}/s/${this.communityPage.split('?')[0]}?vlocity_ins${this.result.value.saveUrl.split('?')[1].slice(1).split('&').reverse()[0]}&c__instanceId=${this.result.value.instanceId}`;
                this.getEmailFromInstance(this.result.value.instanceId);
            } else {
                this.loading = false;
                this.isInternalUser = true;
                this.navigateToSavedEnrollments();
                this.closeTabHandler();
            }
        }
    }

    handleSendEmail() {
        this.loading = true;
        this._actionUtilClass = new OmniscriptActionCommonUtil();
        this.IPInput = {
            email: this.emailAddress,
            emailLink: this.customLink,
            isUserLogged: this.isUserLogged,
            loginLink: this.loginLink,
        //    userID: this.userID
        };

        const params = {
            input: JSON.stringify(this.IPInput),
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'SaveForLater_Email',
            options: '{}'
        };
        this._actionUtilClass
            .executeAction(params, null, this, null, null)
            .then(() => {
                this.loading = false;
                this.emailSent = true;
            })
            .catch((error) => {
                console.error(error);
            });
    }

    getEmailFromInstance(instanceId) {
        this._actionUtilClass = new OmniscriptActionCommonUtil();
        this.IPInput = {
            instanceId: instanceId
        };
        const params = {
            input: JSON.stringify(this.IPInput),
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'GetSaveForLater_Email',
            options: '{}'
        };
        this._actionUtilClass
            .executeAction(params, null, this, null, null)
            .then((response) => {
                this.emailAddress = response.result.IPResult.emailAddress;
                this.loading = false;
            })
            .catch((error) => {
                console.error('error', error);
            });
    }

    handleCloseButton() {
        window.open('https://www.weshare.org/', '_top');
    }

    navigateToSavedEnrollments() {
        this[NavigationMixin.Navigate]({
            type: "standard__navItemPage",
            attributes: {
                // CustomTabs from managed packages are identified by their
                // namespace prefix followed by two underscores followed by the
                // developer name. E.g. 'namespace__TabName'
                apiName: "Saved_Enrollments",
            },
        });
    }


    //-----------------------

    async closeTabHandler() {
        let foucedTabInfo = await this.invokeWorkspaceAPI('getFocusedTabInfo');
        await this.invokeWorkspaceAPI('closeTab', {
            tabId: foucedTabInfo.tabId,
        })
    }

    async changeTabLabelHandler(event) {
        let foucedTabInfo = await this.invokeWorkspaceAPI('getFocusedTabInfo');
        await this.invokeWorkspaceAPI('setTabLabel', {
            tabId: foucedTabInfo.tabId,
            label: 'LWC Demo Tab'
        })
    }

    async changeTabIconHandler(event) {
        let foucedTabInfo = await this.invokeWorkspaceAPI('getFocusedTabInfo');
        await this.invokeWorkspaceAPI('setTabIcon', {
            tabId: foucedTabInfo.tabId,
            icon: 'standard:contact',
            iconAlt: 'LWC Demo Tab'
        })
    }

    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "workspaceAPI",
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                            return reject(err);
                        } else {
                            return resolve(response);
                        }
                    }
                }
            });

            this.dispatchEvent(apiEvent);
        });
    }

    handleEmailChange(event) {
        this.emailAddress = event.target.value;
    }

}