import { LightningElement, api, track } from 'lwc';
import { allCustomLabels } from 'vlocity_ins/omniscriptCustomLabels';
import { OmniscriptActionCommonUtil } from "vlocity_ins/omniscriptActionUtils";
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { getUserProfile } from 'vlocity_ins/utility';
import { NavigationMixin } from 'lightning/navigation';


export default class UHSM_CustomSaveForLaterModal extends OmniscriptBaseMixin(NavigationMixin(LightningElement)) {

    _result = null;

    @api set result(value) {
        this._result = value;
    }

    get result() {
        return this._result;
    }

    @api layout;
    @api auto = false;
    @track resumeLink;
    @track emailLink;
    @track hasResult = false;
    emailAddress;

    _bSflLabels = {
        OmniSaved: allCustomLabels.OmniSaved,
        OmniSavedFailed: allCustomLabels.OmniSavedFailed,
        OmniSavedFailedConcurrent: allCustomLabels.OmniSavedFailedConcurrent,
        OmniResume: allCustomLabels.OmniResume,
        OmniLink: allCustomLabels.OmniLink,
        OmniCopyLink: allCustomLabels.OmniCopyLink,
        OmniEmailMe: allCustomLabels.OmniEmailMe,
        OmniResumeLink: allCustomLabels.OmniResumeLink,
        OmniSaveEmailBody: allCustomLabels.OmniSaveEmailBody,
        OmniScriptResumeLink: allCustomLabels.OmniScriptResumeLink,
    };

    modalType = 'success';
    modalLayout = 'newport';
    modalTriggeredOnStep = 'false';
    modalHideFooter = false;
    modalHideHeader = false;
    guestUserProfile = false;

    disableEmailButton = true;

    set emailAddress(value) {
        this._emailAddress = value;
        this.disableEmailButton = false;
    }

    get emailAddress() {
        return this._emailAddress;
    }


    communityPage = location.href.split('/s/')[1];
    connectedCallback() {
        console.log('this.result');
        console.log(this.result);
        console.log(this.result.value);
        console.log(this.result.value.instanceId);
        console.log('guestUserProfileBefore ' + this.guestUserProfile);
        console.log('location ' + location.href);
        getUserProfile().then((val) => {
            console.log('Current user: ', JSON.stringify(val.profilename));
            if (val.profilename == 'Member Community Profile' || val.profilename == 'Member Community') {
                this.guestUserProfile = true;
                this.customLink = `${location.href.split('/s/')[0]}/s/${this.communityPage.split('?')[0]}?vlocity_ins${this.result.value.saveUrl.split('?')[1].slice(1).split('&').reverse()[0]}&c__instanceId=${this.result.value.instanceId}`;
                console.log('this.result.value.saveUrl');
                console.log(this.result.value.saveUrl);
                console.log('this.communityPage');
                console.log(this.communityPage);
                this.getEmailFromInstance(this.result.value.instanceId);
            } else if (val.profilename == 'Partner Community') {
                location.replace('/s/');
            } else {
                this.navigateToObjectHome();
            }
        });
        console.log('guestUserProfileAfter ' + this.guestUserProfile);
        // this.customLink =`${location.href.split('/s/')[0]}/s/${this.communityPage}?vlocity_ins${this.result.value.saveUrl.split('?')[1].slice(1)}&c__instanceId=${this.result.value.instanceId}`;
    }

    handleBlurEmail(event) {
        console.log('blur email field: ');
        this.emailAddress = event.target.value;
    }

    handleSendEmail() {
        console.log(this.jsonData);

        this._actionUtilClass = new OmniscriptActionCommonUtil();
        this.IPInput = {
            email: this.emailAddress,
            emailLink: this.customLink
        };

        console.log('this.IPInput', this.IPInput);
        const params = {
            input: JSON.stringify(this.IPInput),
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'UHSM_Email',
            options: '{}'
        };
        this._actionUtilClass
            .executeAction(params, null, this, null, null)
            .then((response) => {
                console.log('UHSM_Email - response ', response);
                // location.replace('/s/');
            })
            .catch((error) => {
                console.error(error);
            });
    }

    navigateToObjectHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                // CustomTabs from managed packages are identified by their
                // namespace prefix followed by two underscores followed by the
                // developer name. E.g. 'namespace__TabName'
                apiName: 'Saved_Enrollments'
            }

        },
       /* true*/);
    }

    getEmailFromInstance(instanceId) {
        this._actionUtilClass = new OmniscriptActionCommonUtil();
        this.IPInput = {
            instanceId: instanceId
        };
        const params = {
            input: JSON.stringify(this.IPInput),
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'SaveForLater_Email',
            options: '{}'
        };
        this._actionUtilClass
            .executeAction(params, null, this, null, null)
            .then((response) => {
                this.emailAddress = response.result.IPResult.email;
            })
            .catch((error) => {
                console.error(error);
            });
    }



}