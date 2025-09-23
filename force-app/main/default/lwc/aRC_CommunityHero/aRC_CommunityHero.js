import { LightningElement, api, wire, track} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadScript } from 'lightning/platformResourceLoader';
import CommunityHero from '@salesforce/resourceUrl/ARC_CommunityHeroResources';
import scripts from '@salesforce/resourceUrl/ARC_CommunityScripts';

export default class ARC_HeroSlider extends NavigationMixin(LightningElement) {
    @api caption;
    @api captionColor;
    @api title;
    @api titleColor;
    @api subtitle;
    @api subtitleColor;
    @api alignment;
    @api background;
    @api backgroundSize;
    @api backgroundColor;
    @api buttonLabel;
    @api buttonURL;
    @api buttonVariant;
    @api buttonLabel2;
    @api buttonURL2;
    @api buttonVariant2;
    @api buttonLabel3;
    @api buttonURL3;
    @api buttonVariant3;
    @api height;
    @api contentWidth;
    @api contentContentsWidth;
    @api contentContentsPosition;
    @api contentVertical;
    @api contentTextAlignment;
    @api contentHorizontal;
    @api contentBackgroundColor;
    @api contentAnimation;
    @api contentAnimationDelay;
    @api heroAnimation;
    @api heroAnimationDelay;
    @api backgroundVignette;
    @api removeMargin;
    @api heroStyle;
    @api parallax;
    @api contentBoxWidth;
    @api contentBoxHeight;
    @api filter;
    @api scrollButton;

    @track width;
    @track left;
    @track backgroundMedia;
    @track isVideo;
    @track videoType;
    @track styleNormal;
    @track styleHeader;
    @track scrollPrimary;
    @track scrollSecondary;
    @track displayButtons = true;
    
    connectedCallback(){
        if(this.background){
            if(this.background.includes("/")){
                this.isVideo = true;
                this.videoType = "video/mp4";
                this.backgroundMedia = this.background;
            }else{
                let filename = this.background.split('.');
                let ext = filename[filename.length - 1];
                switch (ext.toLowerCase()) {
                    case 'm4v':
                    case 'avi':
                    case 'mpg':
                    case 'mp4':
                        this.isVideo = true;
                        this.videoType = "video/"+ext.toLowerCase();
                        break;
                }
                this.backgroundMedia = CommunityHero + "/ARC_CommunityHeroResources/" + this.background;
            }
        }
        if(!this.height) this.height = "400px";
    }

    handleScrollButton() {
        const event = new CustomEvent('scrollTo', { detail: {endOfElement: this.template.querySelector('.community-hero')} });
        window.dispatchEvent(event);
    }

    renderedCallback(){
        let div = this.template.querySelector('.community-hero');
        let background = this.template.querySelector('.community-hero-background-container');
        let container = this.template.querySelector('.community-hero-container');
        let contentAbs = this.template.querySelector('.community-hero-content-absolute');
        let contentAlig = this.template.querySelector('.community-hero-content-alignment');
        let content = this.template.querySelector('.community-hero-content');
        let contentContents = this.template.querySelector('.community-hero-content-container');
        let buttonContainer = this.template.querySelector('.hero-button-container');
        let media = this.template.querySelector('.community-hero-media');
        let video = this.template.querySelector('video');
        let caption = this.template.querySelector('h5');
        let title = this.template.querySelector('h2');
        let subtitle = this.template.querySelector('p');
        let parallax = this.template.querySelector('.community-hero-background-parallax');
        let filterElem = this.template.querySelector('.community-hero-background-filter');
        let scrollButton = this.template.querySelector('.hero-scroll-button');
        div.style.height = this.height;
        if(this.removeMargin) div.classList.add("remove-component-vertical-margin");

        if(media && !this.isVideo) media.style.background = `url(${this.backgroundMedia}) no-repeat center center / cover`;
        else if(this.isVideo) {
            video.muted = true;
            video.play();
        } 
        if(!this.buttonLabel && !this.buttonLabel2 && !this.buttonLabel3 && !this.scrollButton) this.displayButtons = false;
        if(title) title.style.color = this.titleColor;
        if(subtitle) subtitle.style.color = this.subtitleColor;
        if(caption) caption.style.color = this.captionColor;
        background.style.backgroundColor = this.backgroundColor;

        contentContents.style.maxWidth = this.contentContentsWidth;
        container.style.height = this.height;
        contentAbs.style.top = this.contentVertical;
        content.style.textAlign = this.contentTextAlignment;
        content.style.maxWidth = this.contentWidth;
        contentAlig.style.maxWidth = this.contentBoxWidth;
        contentAlig.style.minHeight = this.contentBoxHeight;
        filterElem.style.backdropFilter = this.filter;
        switch (this.heroStyle) {
            case "Header":
                this.styleHeader = true;
                break;
            default:
                this.styleNormal = true;
                break;
        }
        switch (this.contentHorizontal) {
            case "center":
                content.style.alignItems = "center";
                break;
            case "right":
                content.style.alignItems = "flex-end";
                break;
            default:
                break;
        }
        switch (this.contentContentsPosition) {
            case "center":
                contentContents.style.margin = "auto";
                break;
            case "right":
                contentContents.style.marginLeft = "auto";
                break;
            default:
                break;
        }
        if(this.displayButtons){
            buttonContainer.style.color = this.subtitleColor;
            buttonContainer.style.borderColor = this.subtitleColor;
            switch (this.contentTextAlignment) {
                case "center":
                    buttonContainer.style.justifyContent = "center";
                    break;
                case "right":
                    buttonContainer.style.justifyContent = "flex-end";
                    break;
                default:
                    break;
            }
            if(this.scrollButton) scrollButton.style.width = scrollButton.offsetHeight + "px";
        }
        contentAlig.style.backgroundColor = this.contentBackgroundColor;
        if(this.contentAnimation && this.contentAnimation !== "None") {
            contentAlig.classList.add("arc-scrollanim");
            this.animationSet(contentAlig, this.contentAnimation);
            this.animationSetDelay(contentAlig, this.contentAnimationDelay);
        }
        if(this.heroAnimation && this.heroAnimation !== "None") {
            div.classList.add("arc-scrollanim");
            this.animationSet(div, this.heroAnimation);
            this.animationSetDelay(div, this.heroAnimationDelay);
        }
        if(this.parallax) {
            // parallax.classList.add("parallax");
            loadScript(this, scripts + '/vendors/rellax.min.js').then(() => {
                
                let rellax = Rellax(parallax, {
                    speed: -10,
                    center: true
                });
                setTimeout(() => {
                    
                    rellax.refresh();
                }, 3000);
            });
        }
    }

    animationSet(el, anim){
        switch (anim) {
            case "Fade":
                el.classList.add("arc-scrollanim-fade");
                break;
            case "Fade from Top":
                el.classList.add("arc-scrollanim-fadefromtop");
                break;
            case "Fade from Bottom":
                el.classList.add("arc-scrollanim-fadefrombottom");
                break;
            case "Fade from Left":
                el.classList.add("arc-scrollanim-fadefromleft");
                break;
            case "Fade from Right":
                el.classList.add("arc-scrollanim-fadefromright");
                break;
            case "Fade/Scale":
                el.classList.add("arc-scrollanim-fadescale");
                break;
            case "Fade/Scale from Top":
                el.classList.add("arc-scrollanim-fadescalefromtop");
                break;
            case "Fade/Scale from Bottom":
                el.classList.add("arc-scrollanim-fadescalefrombottom");
                break;
            case "Fade/Scale from Left":
                el.classList.add("arc-scrollanim-fadescalefromleft");
                break;
            case "Fade/Scale from Right":
                el.classList.add("arc-scrollanim-fadescalefromright");
                break;
            case "Slide from Left":
                el.classList.add("arc-scrollanim-slidefromleft");
                break;
            case "Slide from Right":
                el.classList.add("arc-scrollanim-slidefromright");
                break;
            default:
                break;
        }
    }

    animationSetDelay(el, delay){
        switch (delay) {
            case "0.5s":
                el.classList.add("arc-scrollanim-delay-p5");
                break;
            case "1s":
                el.classList.add("arc-scrollanim-delay-1");
                break;
            case "1.5s":
                el.classList.add("arc-scrollanim-delay-1p5");
                break;
            case "2s":
                el.classList.add("arc-scrollanim-delay-2");
                break;
            case "2.5s":
                el.classList.add("arc-scrollanim-delay-2p5");
                break;
            case "3s":
                el.classList.add("arc-scrollanim-delay-3");
                break;
            case "3.5s":
                el.classList.add("arc-scrollanim-delay-3p5");
                break;
            case "4s":
                el.classList.add("arc-scrollanim-delay-4");
                break;
            default:
                break;
        }
    }
    
    navigatePage() {
        //this.isOpenDashboard = true;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: this.buttonURL
            },
        });
    }
}