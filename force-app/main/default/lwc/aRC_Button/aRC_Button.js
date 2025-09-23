/*
// @author            : franco.boragno@arcsona.com
// @description       : Universal button that holds all functionality to navigate using the SL NavigationMixin

// @group             : Spark
// @last modified on  : 09-07-2024
// @last modified by  : franco.boragno@arcsona.com
// @modification      : Adjusted so Navigating to CommunityPage works without opening new tabs
                        + How custom buttons are shown
                        + Added noStyle variation which acts as a logic-only container for in-lwc styled elements
*/
import { api, track, LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


export default class SimpleButton extends NavigationMixin(LightningElement) {
    @api href;
    @api target;
    @api title;

    @api buttonData; // Data for the button

    @api variation; // Visual Variation
    @api disableClick; // Disables action for this button
    @api fullWidth; // Will use 100% of available width if true (Used for drawer navigation or dropdowns)
    
    // Variables to define the type of button since different button types might need different HTML on the template of the component
    @track defaultButton = true;
    @track noStyle;
    get bIsNoStyle(){
        return this.buttonData?.variation == "noStyle" || this.buttonData?.variation == "none"
    }
    get bIsDefault(){
        return !this.bIsNoStyle
    }

    // If the button is disabled
    @track disabled = false;
    @track loading = false;
    get bDisabled(){
        return this.disabled || this.loading
    }


    connectedCallback(){
        // Process the button variation
        this.processVariation();

        // Process button data
        this.processButton()
    }

    // renderedCallback(){
    //     // Process the button type to get it ready for user clicking
    //     this.processType();
    // }

    processVariation(){
        switch (this.variation || "brand") {
            case "none":
                this.noStyle = true;
                this.defaultButton = false;
                break;
            default:
                // brand, neutral, outline, clear | none (def: brand)
                this.defaultButton = true;
                break;
        }
    }

    processButton(){
        if(this.buttonData){
            if(this.target = undefined && this.buttonData.windowName === 'NewWindow') this.target = '_blank';
            if(this.title = undefined && this.buttonData.label) this.title = this.buttonData.label;

            // get the correct PageReference object for the menu item type
            if (this.buttonData.type === 'InternalLink' || this.buttonData.type === 'ExternalLink') {
                // WARNING: Normally you shouldn't use 'standard__webPage' for internal relative targets, but
                // we don't have a way of identifying the PageReference type of an InternalLink URL
                this.pageReference = {
                    type: 'standard__webPage',
                    attributes: {
                        url: this.buttonData.target
                    }
                };

                this.onClickAction = this.actionNavigateToPage
            }

            // use the NavigationMixin from lightning/navigation to generate the URL for navigation if there isn't one set already. 
            if (!this.href && this.pageReference) {
                this[NavigationMixin.GenerateUrl](this.pageReference)
                    .then(url => {
                        this.href = url;
                    });
            }
        }
    }

    // Call the method saved for this button type
    handleClick(e){
        if(this.bDisabled) return;
        if(this.disableClick) return this.dispatchEvent(new CustomEvent('handleclick'))
        this.onClickAction(e);
        this.dispatchEvent(new CustomEvent('handleclick'));
    }

    actionNavigateToPage(e){
        // If windowname is external, e.preventDefault wont run and the link will open in a new window
        if(this.buttonData.windowName === "CurrentWindow"){
            e.preventDefault()
            // Navigate using the processed pageReference of this link
            this[NavigationMixin.Navigate](this.pageReference);
        }
    }

    // processType(){
    //     // Get the link type
    //     if(this.refs.button.getAttribute('download')) this.refs.button.removeAttribute('download');
    //     switch (this.buttonData?.type) {
    //         case "External URL":
    //             // Add https:// if missing
    //             if(this.refs.button.getAttribute('href') && !this.refs.button.getAttribute('href').startsWith("http")) this.refs.button.setAttribute('href', "https://"+this.refs.button.getAttribute('href'))
    //             // Set target to blank if unset
    //             if(!this.buttonData?.target) this.refs.button.setAttribute('target', '_blank');
    //             // Save the method to call on click
    //             this.onClickAction = this.goToExternalURL
    //             break;
    //         case "Callable Apex":
    //             // Save the method to call on click
    //             this.onClickAction = this.goToCallableApex
    //             break;
    //         case "Download":
    //             // Save the method to call on click
    //             this.refs.button.setAttribute('href',this.buttonData?.url);
    //             this.refs.button.setAttribute('target','_self');
    //             this.refs.button.setAttribute('download','');
    //             this.onClickAction = this.goToExternalURL
    //             break;
    //         case "Logout":
    //         case "Login":
    //         case "Function":
    //             switch (this.buttonData?.url) {
    //                 case "logout":
    //                     this.pageReference = {
    //                         type: "comm__loginPage",
    //                         attributes: {
    //                             actionName: "logout"
    //                         }
    //                     }
    //                     break;
    //                 case "login":
    //                     this.pageReference = {
    //                         type: 'comm__loginPage',
    //                         attributes: {
    //                             actionName: 'login'
    //                         }
    //                     }
    //                     break
    //                 default:
    //                     this.pageReference = {
    //                         type: 'comm__namedPage',
    //                         attributes: {
    //                             name: this.buttonData?.url
    //                         },
    //                     }
    //             }
    //             this[NavigationMixin.GenerateUrl](this.pageReference).then(generatedUrl => {
    //                 if(!generatedUrl) generatedUrl = "javascript:void(0);"
    //                 this.refs.button.setAttribute('href', generatedUrl);
    //             });
    //             // Save the method to call on click
    //             if(this.buttonData?.target == "_blank"){
    //                 this.onClickAction = this.goToCommunityPageNewTab
    //             }else{
    //                 this.onClickAction = this.goToCommunityPage
    //             }
    //             break;
    //         case "Community Page":
    //         default:
    //             // Default type is Community Page
    //             this.pageReference = {
    //                 type: 'comm__namedPage',
    //                 attributes: {
    //                     name: this.buttonData?.url
    //                 },
    //             }
    //             // For community page, we generate an url to set to the link, so even if the user
    //             // would right click and open on new tab, the link will work. For normal clicking,
    //             // the salesforce routing will work without reloading the page
    //             this[NavigationMixin.GenerateUrl](this.pageReference).then(generatedUrl => {
    //                 this.refs.button.setAttribute('href', generatedUrl);
    //             });
    //             // Save the method to call on click
    //             if(this.buttonData?.target == "_blank"){
    //                 this.onClickAction = this.goToCommunityPageNewTab
    //             }else{
    //                 this.onClickAction = this.goToCommunityPage
    //             }
    //             break;
    //     }
    // }

    // // Method to navigate to Community Page
    // goToCommunityPage(e){
    //     e.preventDefault()
    //     // Navigate using the processed pageReference of this link
    //     this[NavigationMixin.Navigate](this.pageReference);
    // }
    // goToCommunityPageNewTab(e){
    //     // Since this is empty, the 'e' event will just continue execution and open the link
    // }
    
    // // Method to navigate to external URL
    // goToExternalURL(e){
    //     // Since this is empty, the 'e' event will just continue execution and open the link
    // }

    // // Method to call an apex class
    // goToCallableApex(e){
    //     e.preventDefault()
    //     if(this.bDisabled) return;
    //     // Disable button while running apex
    //     this.disabled = true;
    //     this.loading = true;
    //     let call = this.parseCallableApexString(this.buttonData?.url);
    //     // // Call apex code
    //     // callDynamicApex({className: call.className, methodName: call.methodName, param: call.param}).then((i)=>{
    //     //     console.log(i)
    //     //     // Reenable button after apex action finishes
    //     //     this.disabled = false;
    //     //     this.loading = false;
    //     // }).catch(e => {
    //     //     console.error(e)
    //     //     this.disabled = false;
    //     //     this.loading = false;
    //     // })
    // }
    // parseCallableApexString(input){
    //     let className = '';
    //     let methodName = '';
    //     let param = '';
    
    //     const dotIndex = input.indexOf('.');
    //     const parenStartIndex = input.indexOf('(');
    //     const parenEndIndex = input.indexOf(')');
    
    //     // Get the part before the dot
    //     if (dotIndex !== -1) {
    //         className = input.substring(0, dotIndex);
    //     }
    
    //     // Get the part between the dot and the parenthesis
    //     if (dotIndex !== -1 && parenStartIndex !== -1) {
    //         methodName = input.substring(dotIndex + 1, parenStartIndex);
    //     } else if (dotIndex !== -1) {
    //         methodName = input.substring(dotIndex + 1);
    //     }
    
    //     // Get the part inside the parenthesis
    //     if (parenStartIndex !== -1 && parenEndIndex !== -1) {
    //         param = input.substring(parenStartIndex + 1, parenEndIndex);
    //     }
    
    //     return { className, methodName, param };
    // }


    // Parent interaction methods
    @api
    setProperty(property, value){
        this.refs.button.style.setProperty(property, value);
    }
    @api
    removeProperty(property){
        this.refs.button.style.removeProperty(property);
    }
}