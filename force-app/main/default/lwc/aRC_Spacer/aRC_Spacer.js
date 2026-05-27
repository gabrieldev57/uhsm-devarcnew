import { LightningElement, api, track} from 'lwc';

export default class ARC_Spacer extends LightningElement {
    @api size;
    @api sizeM;
    @api sizeS;

    resize(el){
        let space = 0;
        if(el.offsetWidth >= 1024){
            space = this.size || 0;
        }else if(el.offsetWidth >= 768){
            space = this.sizeM || this.size || 0;
        }else{
            space = this.sizeS || this.sizeM || this.size || 0;
        }
        el.style.marginTop = "unset";
        el.style.padding = "unset";
        // if(space.includes("calc")) {
        //     space += ";";
        //     space = space.replace(");", " - var(--component-vertical-spacing))");
        // }
        // else space = `calc(${space} - var(--component-vertical-spacing))`;
        if(space.startsWith("-") || space.includes("*-") || space.includes("* -")) el.style.marginTop = space;
        else el.style.paddingTop = space;
    }

    renderedCallback(){
        let div = this.template.querySelector('.arc-lwc-spacer');
        if(this.sizeM !== undefined || this.sizeS !== undefined) {
            window.addEventListener('resize', ()=> this.resize(div));
        }
        this.resize(div);
    }
}