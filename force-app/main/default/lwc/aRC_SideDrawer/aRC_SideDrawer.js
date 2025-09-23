import { LightningElement, api, track } from 'lwc';

export default class SimpleDrawer extends LightningElement {
    @track detail; // Detail data to use in drawer if needed
    @api customClass; // Custom class to add to the drawer container for custom css

    @api topOffset;
    @api responsiveTopOffset;

    @track isOpen = false;
    @track drawerClass = "si-drawer"

    connectedCallback(){
        // Add custom class to the drawer's main classList
        if(this.customClass) this.drawerClass = this.drawerClass + " " + this.customClass
    }

    get bIsOpen(){
        return this.isOpen && !this.willClose
    }

    @api
    toggle(args){
        if(!this.bIsOpen) this.open(args)
        else this.close()
    }

    // Method to open the drawer
    // When using await thisDrawer.open(data), data is stored in this.detail
    // the rest of the code on the method that calls that line will executed
    // with the data that returns on the 'close' method
    @api
    open(args) {
        clearTimeout(this.willClose)
        this.willClose = null
        this.detail = args.detail

        this.isOpen = true;
        this.refs.drawer.classList.add("drawer-open")

        return new Promise((resolve, reject) => {
            this.resolve = resolve;
            this.reject = reject;
        });
    }

    // Closes and retuns data from the drawer result
    close(result) {
        this.resolve(result);
        this.refs.drawer.classList.remove("drawer-open")

        // Wait for 0.6 seconds and then remove content
        this.willClose = setTimeout(() => {
            this.isOpen = false;
        }, 600); // 1000ms = 1 second
    }
    handleClose() {
        this.close();
    }

    renderedCallback(){
        this.refs.drawer.style.setProperty("--topbar-offset", this.topOffset)
        this.refs.drawer.style.setProperty("--topbar-offset-responsive", this.responsiveTopOffset)
    }
}