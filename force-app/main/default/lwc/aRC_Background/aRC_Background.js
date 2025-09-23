import { LightningElement, api, track} from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CommunityResources from '@salesforce/resourceUrl/ARC_CommunityResources';
import scripts from '@salesforce/resourceUrl/ARC_CommunityScripts';

export default class ARC_Background extends LightningElement {
    @api width;
    @api widthm;
    @api widths;
    @api height;
    @api heightOffset;
    @api animation;
    @api animationDelay;
    @api background;
    @api backgroundOpacity;
    @api backgroundColor;
    @api backgroundRepeat;
    @api parallax;
    @api backgroundSVGFillColor;
    @api backgroundSVGStrokeColor;
    @api horizontalPosition;

    @track backgroundSrc;

    resize(el){
        let width = '100vw';
        if(window.innerWidth >= 1024){
            width = this.width || '100vw';
            if(this.horizontalPosition) el.style.transform = `translateX(${this.horizontalPosition - 50}%)`;
        }else if(window.innerWidth >= 768){
            width = this.widthm || this.width || '100vw';
            if(this.horizontalPosition) el.style.transform = `translateX(${this.horizontalPosition - 50}%)`;
        }else{
            width = this.widths || this.widthm || this.width || '100vw';
            el.style.transform = 'translateX(-50%)';
        }
        el.style.width = width;
    }

    renderedCallback(){
        let component = this.template.querySelector('.arc-component-background');
        let background = this.template.querySelector('.arc-component-background-bg');
        let image = this.template.querySelector('.arc-component-background-image');
        if(this.horizontalPosition) background.style.transform = `translateX(${this.horizontalPosition - 50}%)`;
        if(this.backgroundRepeat){
            background.style.height = this.height;
            if(this.background && this.background.includes("/")) background.style.background = `url(${this.background})`;
            else if(this.background) background.style.background = `url(${CommunityResources + "/" + this.background})`;
            background.style.backgroundRepeat = 'repeat-y';
        }else{
            if(this.background && this.background.includes("/")) this.backgroundSrc = this.background;
            else if(this.background) this.backgroundSrc = CommunityResources + "/" + this.background;
        }
        background.style.top = this.heightOffset;
        background.style.backgroundColor = this.backgroundColor;
        if(this.backgroundOpacity) background.style.opacity = this.backgroundOpacity;

        if(this.animation && this.animation !== "None") {
            component.classList.add("arc-scrollanim");
            this.animationSet(component, this.animation);
            this.animationSetDelay(component, this.animationDelay);
        }
        if(this.parallax) {
            component.classList.add("parallax");
            // parallax.classList.add("parallax");
            loadScript(this, scripts + '/vendors/rellax.min.js').then(() => {
                Rellax(component, {
                    speed: -10,
                    center: true
                });
            });
        }
        if(this.background && this.background.endsWith("svg")){
            image.style.fill = this.backgroundSVGFillColor;
            image.style.stroke = this.backgroundSVGStrokeColor;
            
            const event = new CustomEvent('injectSVG', {'detail': image});
            window.dispatchEvent(event);
            // loadScript(this, scripts + '/vendors/svg-inject.min.js').then(() => {
            //     console.log("CALLING INJECTING SVG")
            //     SVGInject(image);
            // });
        }
        
        if(this.widths !== undefined || this.widthm !== undefined) {
            window.addEventListener('resize', ()=> this.resize(background));
        }
        this.resize(background);
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
    
}