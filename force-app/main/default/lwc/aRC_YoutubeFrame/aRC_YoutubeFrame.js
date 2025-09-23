import { LightningElement, api, wire } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';
import { CurrentPageReference } from 'lightning/navigation';


export default class ARC_YoutubeFrame extends OmniscriptBaseMixin(LightningElement) {
    @api malevideoids;
    @api femalevideoids;
    @api gender = 'Female';
    @api helpmessage;

    player;
    index = 0;
    showIframe = false;
    closeBubble = false;
    renderedInCommunity = false;

    @wire(CurrentPageReference)
    handlePageReference(pageRef) {
        console.log('pageRef',pageRef);
        if (pageRef?.type == 'comm__namedPage'){
             this.renderedInCommunity = true;
        }
        console.log('this.renderedInCommunity: ',this.renderedInCommunity);
    }

    connectedCallback() {
        console.log('ARC_IFrameHelper connectedCallback');
        console.log('ARC_IFrameHelper gender', this.gender);
        console.log('ARC_IFrameHelper maleURL', this.malevideoids);
        console.log('ARC_IFrameHelper femaleURL', this.femalevideoids);
        console.log('ARC_IFrameHelper user profile', this.omniJsonData?.userProfile);
        console.log('ARC_IFrameHelper isMemberCommunity', this.isMemberCommunity);
        console.log('ARC_IFrameHelper helpmessage', this.helpmessage);
    }

    renderedCallback() {

    }


    get videoIds() {
        console.log('get videoIds');
        switch (this.gender) {
            case 'Male':
                return this.malevideoids?.split(';');
            case 'Female':
                return this.femalevideoids?.split(';');
            default:
                return this.femalevideoids?.split(';');
        }
    }


    get url() {
        console.log('get url');
        return 'https://www.youtube.com/embed/' + this.videoIds[this.index] + '?autoplay=1&rel=0&color=white';
    }

    get maxIndex() {
        return this.videoIds.length - 1;
    }

    get showNext() {
        return this.index < this.maxIndex;
    }

    get showPrevious() {
        return this.index > 0;
    }

    get isMemberCommunity() {
        return true //(this.omniJsonData?.userProfile == 'Member Community' || this.omniJsonData?.userProfile == 'Member Community Profile');
    }

    get showHelpBubble() {
        return (this.helpmessage != null && this.helpmessage != '') && !this.closeBubble && !this.omniJsonData?.bubbleClosed;
    }

    handleCloseBubble() {
        this.closeBubble = true;
        //say to the omniscript that the bubble has been closed
        this.omniApplyCallResp({ 'bubbleClosed': true });
    }

    toggleIFrameVisibility() {
        this.handleCloseBubble();
        this.showIframe = !this.showIframe;
        if(this.showIframe && !this.renderedInCommunity){
            //Add margin top to the component if it is redenred from SF
            setTimeout(()=>{
                console.log('youtubeFrameElement'+this.template.querySelector('[data-id="youtube_modal"]'));
                let youtubeFrameElement = this.template.querySelector('[data-id="youtube_modal"]');
                youtubeFrameElement?.classList?.add("frame-margin-Top");
            },500)

        }
    }

    next() {
        if (this.index < this.maxIndex) {
            this.index++;
        }
    }

    previous() {
        if (this.index > 0) {
            this.index--;
        }
    }


}