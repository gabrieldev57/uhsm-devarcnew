import { LightningElement, api, track } from 'lwc';
import { allCustomLabels } from 'vlocity_ins/omniscriptCustomLabels';
import { NavigationMixin } from 'lightning/navigation';

export default class ARC_CustomSaveForLater extends NavigationMixin(LightningElement) {
    _result = null;
    @api set result(value) {
        this._result = value;
        this.handleResultChange(value);
    }
    get result() {
        return this._result;
    }
    @api layout;
    @api auto = false;
    @track resumeLink;
    @track emailLink;
    @track hasResult = false;
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
    handleResultChange(val) {
        if (val) {
            const link = val.value.saveUrl + '&c__instanceId=' + val.value.instanceId;
            const body = `${this._bSflLabels.OmniResumeLink}\n${link}\n${this._bSflLabels.OmniSaveEmailBody}`;
            this.resumeLink = link;
            this.emailLink = `mailto:?subject=&body=${encodeURIComponent(body)}`;
            this.hasResult = true;
        }

  
        location.replace('/s/');
        
   
    }
}