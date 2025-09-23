/*
// @author            : franco.boragno@arcsona.com
// @description       : Topbar Cmp

// @group             : Spark
// @last modified on  : 06-08-2024
// @last modified by  : franco.boragno@arcsona.com
*/
import { api, LightningElement, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';

import getNavigationMenuItems from '@salesforce/apex/TopbarNavigationController.getNavigationMenuItems';
import isGuest from "@salesforce/user/isGuest";
import UserId from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';

import TopbarResources from '@salesforce/resourceUrl/ARC_TopbarResources';


export default class SimpleTopbar extends LightningElement {
    @api navigationName;
    @api height;
    @api responsiveHeight;
    @api maxLinksDesktop;
    @api background;
    @api userOnTopbar;
    @api showDrawerDesktop;
    @api color;
    @api colorHover;
    @api transparentAtTop;
    @api colorWhenTransparent;
    @api logoOverride;
    @api logoWidth;
    @api logoHeight = "";
    @api logoColor;
    @api fixed;
    @api hideOnScroll;
    @api linkAlignment;
    @api linkHoverStyle;
    @api dropLinkHoverStyle;

    // Icon for arrows
	iconChevronDown = TopbarResources + '/chevron-down.svg#svg'

    // Max links to show inside the topbar, configured in setup
    maxLinksDesktop = 4
    @track topbarLinks = []

    // If the user will be shown inside the topbar, configured in setup
    @track userOnTopbar = false

    // Guest detection
    get bIsGuest() {
        return isGuest;
    }
    get bIsUser() {
        return !isGuest;
    }
    // Alignment of links on the topbar, configured in design
    get bLinksLeft() { return this.linkAlignment == "Left"; }
    get bLinksCenter() { return this.linkAlignment == "Center"; }
    get bLinksRight() { return this.linkAlignment == "Right"; }

    // Hardcoded links processed for the Logo link and hamburger button to open the drawer navigation for mobile devices
    homeButtonData = {
        "target": "home",
        "id": 0,
        "label": "Home",
        "type": "InternalLink",
        "subMenu": [],
        "imageUrl": null,
        "windowName": "CurrentWindow"
    }
    burgerButtonData = {
        "title": "Open drawer",
        "variation": "noStyle"
    }
    
    
    // Get current user's name for displaying when logged in
    @wire(getRecord, { recordId: UserId, fields: [USER_NAME_FIELD]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
        }
    }
    
    /**
        * the published state of the site, used to determine from which schema to 
        * fetch the NavigationMenuItems
        */
    publishStatus;
    // Connect to page change events and set new active link when changing pages
    /**
     * Using the CurrentPageReference, check if the app is 'commeditor'.
     * 
     * If the app is 'commeditor', then the page will use 'Draft' NavigationMenuItems. 
     * Otherwise, it will use the 'Live' schema.
    */
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference
        const app = currentPageReference && currentPageReference.state && currentPageReference.state.app;
        if (app === 'commeditor') {
            this.publishStatus = 'Draft';
        } else {
            this.publishStatus = 'Live';
        }
        // if(this.rendered) this.setActiveLink()
    }

    addHomeMenuItem = false;
    includeImageUrls = false;

    @track menuItems = [];

    /**
        * Using a custom Apex controller, query for the NavigationMenuItems using the
        * menu name and published state.
        * 
        * The custom Apex controller is wired to provide reactive results. 
        */
    @wire(getNavigationMenuItems, {
        navigationLinkSetMasterLabel: '$navigationName',
        publishStatus: '$publishStatus',
        addHomeMenuItem: '$addHomeMenuItem',
        includeImageUrl: '$includeImageUrls'
    })
    wiredMenuItems({error, data}) {
        console.log("Navigation Data:", data)
        if (data) {
            this.menuItems = data.map((item, index) => {
                return {
                    target: item.actionValue,
                    id: index,
                    label: item.label,
                    type: item.actionType,
                    subMenu: item.subMenu,
                    imageUrl: item.imageUrl,
                    windowName: item.target
                }
            });
            console.log(this.menuItems)
        } else if (error) {
            this.menuItems = [];
            console.error(`Navigation menu error: ${JSON.stringify(this.error)}`);
        }
    }

    connectedCallback(){
        loadStyle(this, TopbarResources + '/base.css')
            .then(() => {
            })
            .catch(error => {
                console.error('Error loading Component CSS: ', error);
            });
        console.log(this.bLinksRight)
    }

    renderedCallback(){
        console.log(this.bLinksRight)
        // Image for this component is placed on the --dxp-s-site-logo-url variable which is an exp.builder variable that stores the site's logo
        // then placed as a background inside the .logo element
        // this.refs.topbar.style.setProperty('--dxp-s-site-logo-url', `url(${this.items[0].image})`)

        // // Look for {{{user}}} in the title field and replace it with the logged in user name
        // // Title is used for a "Welcome" message for logged in users
        // if(item.title){
        //     if(this.bIsUser){
        //         if(item.title.includes('{{{user}}}') || item.title.includes('{{{User}}}')){
        //             item.title = item.title.replace('{{{user}}}', this.currentUserName)
        //             item.title = item.title.replace('{{{User}}}', this.currentUserName)
        //         }
        //     }else{
        //         item.title = null
        //     }
        // }

        // // process links into variables for later use
        // this.processLinks(item)
        
        // Apply styles
        this.applyStyles()
    }

    ////////////////////////////////////////////
	///////////// STYLES ////////////////////
    ////////////////////////////////////////////
	applyStyles(){

        // Topbar height
        this.refs.topbarContainer.style.setProperty('--topbar-height-responsive', this.responsiveHeight);
        this.refs.topbarContainer.style.setProperty('--topbar-height', this.height);

        // Colors
        this.refs.topbar.style.setProperty('--topbar-background', this.background)
        this.refs.topbar.style.setProperty('--item-color', this.color)
        this.refs.topbar.style.setProperty('--item-color-hover', this.colorHover)
        this.refs.topbar.style.setProperty('--item-color-transparent', this.colorWhenTransparent)

		// Disable hamburger on desktop
		if(this.showDrawerDesktop) this.refs.topbar.classList.remove("hide-drawer-desktop")
        else this.refs.topbar.classList.add("hide-drawer-desktop")

		// Logo
		this.refs.topbar.style.setProperty('--topbar-logo-width', this.logoWidth)
		if(this.logoHeight != "") this.refs.topbar.style.setProperty('--topbar-logo-height', this.logoHeight)
        // Logo Color
        this.applyLogoColor()
        // MARK: Custom Logos
        // Logo overrides set
		// this.refs.topbar.style.setProperty('--logo-weshare', "")
		
		// // Max width for content (not whole topbar, elements inside will be contained to this width and not reach the sides of the screen)
		// if(styles.contentWidth) this.refs.topbar.style.setProperty("--topbar-content-max-width", styles.contentWidth)
		// else this.refs.topbar.style.removeProperty("--topbar-content-max-width")
		
		// // Background color
        // if(styles.dropdownBackgroundColor) this.refs.topbar.style.setProperty("--dropdown-background-color", styles.dropdownBackgroundColor)
        // else this.refs.topbar.style.setProperty("--dropdown-background-color", "var(--def-dropdown-background-color)")

		// FEATURES ////////////
		// Transparency on top of page (Effect)
        // When the user scroll is at the top of the page, the topbar takes a transparent style that blends into other component such as a hero.
        if(this.transparentAtTop) {
            this.refs.topbar.classList.add("si-topbar-transparentontop");
			this.refs.topbar.style.setProperty("--topbar-color-at-top", this.colorWhenTransparent);
			// loadStyle(this, simpleResources + '/styles/simpleTopbarFix.css');
			if(window.pageYOffset < this.offsetTopOfPage) this.refs.topbar.classList.add("on-top");
            // If there is a color set to replace elements when transparent on top, apply it
            if(this.colorWhenTransparent){
                this.refs.topbar.classList.add("replace-top-color");
                this.refs.topbar.style.setProperty("--topbar-transparent-elem-color", this.colorWhenTransparent);
            }
        }else{
            this.refs.topbar.classList.remove("si-topbar-transparentontop");
        }

		// Fixed
        // The topbar will follow the scroll at the top of the page
		if(this.fixed) this.refs.topbar.classList.add("si-topbar-fixed");
		else this.refs.topbar.classList.remove("si-topbar-fixed");
		
		// Hide when scrolling down / Show when scrolling up
        // When scrolling down, the topbar hides to allow more visibility of the content
        // The topbar reveals itself when scrolling up
		if(this.hideOnScroll) {
			this.refs.topbar.classList.add("si-topbar-autohide");
			this.refs.topbar.classList.add("si-topbar-show");
			this.listener = () => this.checkScroll();
			if (window.addEventListener) {
				addEventListener('scroll', this.listener, false);
			} else if (window.attachEvent) {
				attachEvent('onscroll', this.listener);
			}
		}else{
			this.refs.topbar.classList.remove("si-topbar-autohide");
			this.refs.topbar.classList.remove("si-topbar-show");
			if (window.removeEventListener) {
				removeEventListener('scroll', this.listener, false);
			} else if (window.detachEvent) {
				detachEvent('onscroll', this.listener);
			}
		}

        // Link styles, when hovered, defines the effect that is displayed for the hovered navigation item
        this.template.querySelectorAll(".topbar-navigation").forEach(elem => {
            elem.setLinkStyles(this.linkHoverStyle, this.dropLinkHoverStyle)
        })

        // Dropdown style
        let topbarLinks = this.template.querySelector(".topbar-links")
        if(topbarLinks) topbarLinks.setDropStyle("Dropdown")

        // // Color for the hover effect
        // if(styles.linkHighlightColor) this.refs.topbar.style.setProperty("--link-high-color", styles.linkHighlightColor);
        // else this.refs.topbar.style.setProperty("--link-high-color", "var(--def-link-high-color)");
        // if(styles.linkBottomBorderWidth) this.refs.topbar.style.setProperty("--link-high-height", styles.linkBottomBorderWidth + 'px');
        // else this.refs.topbar.style.setProperty("--link-high-height", "var(--def-link-high-height)");
        
        // // Background colors for links, independant of highlight color/effect
        // if(styles.linkBackgroundColor) this.refs.topbar.style.setProperty("--link-bg-color", styles.linkBackgroundColor);
        // else this.refs.topbar.style.setProperty("--link-bg-color", "var(--def-link-bg-color)");
        
        // // Font Colors for links, independant of highlight color/effect
        // if(styles.linkColor) this.refs.topbar.style.setProperty("--link-color", styles.linkColor);
        // else this.refs.topbar.style.setProperty("--link-color", "var(--def-link-color)");
        // if(styles.linkHoverColor) this.refs.topbar.style.setProperty("--link-hover-color", styles.linkHoverColor);
        // else this.refs.topbar.style.setProperty("--link-hover-color", "var(--def-link-hover-color)");

        // if(styles.hoverUnderline) this.refs.topbar.style.setProperty("--link-hover-text-decoration", "underline");
        // else this.refs.topbar.style.setProperty("--link-hover-text-decoration", "none");

        // // Dropdown Styles, same as all the above, but only for navigation items inside dropdowns
        // if(styles.droplinkHighlightColor) this.refs.topbar.style.setProperty("--drop-link-high-color", styles.droplinkHighlightColor);
        // else this.refs.topbar.style.setProperty("--drop-link-high-color", "var(--def-link-high-color)");
        // if(styles.droplinkBottomBorderWidth) this.refs.topbar.style.setProperty("--drop-link-high-height", styles.droplinkBottomBorderWidth + 'px');
        // else this.refs.topbar.style.setProperty("--drop-link-high-height", "var(--def-drop-link-high-height)");
        
        // if(styles.droplinkBackgroundColor) this.refs.topbar.style.setProperty("--drop-link-bg-color", styles.droplinkBackgroundColor);
        // else this.refs.topbar.style.setProperty("--drop-link-bg-color", "var(--def-link-bg-color)");
        
        // if(styles.droplinkColor) this.refs.topbar.style.setProperty("--drop-link-color", styles.droplinkColor);
        // else this.refs.topbar.style.setProperty("--drop-link-color", "var(--def-link-color)");
        // if(styles.droplinkHoverColor) this.refs.topbar.style.setProperty("--drop-link-hover-color", styles.droplinkHoverColor);
        // else this.refs.topbar.style.setProperty("--drop-link-hover-color", "var(--def-link-hover-color)");

        // if(styles.drophoverUnderline) this.refs.topbar.style.setProperty("--drop-link-hover-text-decoration", "underline");
        // else this.refs.topbar.style.setProperty("--drop-link-hover-text-decoration", "none");

	}

    applyLogoColor(){
        if(this.logoColor) {
            this.refs.topbar.classList.add("mask-logo");
            this.refs.topbar.style.setProperty("--logo-fill-color", this.logoColor);
        }else{
            this.refs.topbar.classList.remove("mask-logo");
        }
    }

    ////////////////////////////////////////////
	///////////// JS FEATURES //////////////////
    ////////////////////////////////////////////

    // While the mouse is inside the topbar, prevents it from hiding while scrolling
	handleMouseEnter(e){
		e.currentTarget.classList.add("mouse-hovering")
	}
	handleMouseLeave(e){
		e.currentTarget.classList.remove("mouse-hovering")
	}

    // /////////////// Scroll Show/Hide ///////////////////////////
    // Autohide function for when the feature is activated and the user scrolls on the page
    offsetToShow = 150; // How much scroll down is necessary (px) for topbar to hide
    offsetTopOfPage = 400; // How much scroll down is necessary (px) at the start of the page for feature to start working
    
    lastScrollOffset = 0;
    checkScroll(){
        if (window.pageYOffset < 0) {
            return
        }
        if (Math.abs(window.pageYOffset - this.lastScrollOffset) < this.offsetToShow) {
            return
        }
        if(window.pageYOffset < this.lastScrollOffset || window.pageYOffset < this.offsetTopOfPage){
            this.refs.topbar.classList.add("si-topbar-show");
        }else{
			if(this.refs.topbar.classList.contains("mouse-hovering")) return
            this.refs.topbar.classList.remove("si-topbar-show");
        }
        this.lastScrollOffset = window.pageYOffset
        if(window.pageYOffset < this.offsetTopOfPage){
            this.refs.topbar.classList.add("on-top");
        }else{
            this.refs.topbar.classList.remove("on-top");
        }
    }


    
    ////////////////////////////////////////////
    // /////////////// Navigation ///////////////////////////
    ////////////////////////////////////////////

    // Opens the Drawer navigation
    toggleDrawer(){
        this.refs.topbar.classList.toggle("drawer-open")
        this.refs.drawer.toggle({});
    }

    // Not being used at the moment but might be useful if taking navigation menus from Exp.Builder becomes a necessity
    // /**
    //  * Using the CurrentPageReference, check if the app is 'commeditor'.
    //  * 
    //  * If the app is 'commeditor', then the page will use 'Draft' NavigationMenuItems. 
    //  * Otherwise, it will use the 'Live' schema.
    // */
    // @wire(CurrentPageReference)
    // setCurrentPageReference(currentPageReference) {
    //     const app = currentPageReference && currentPageReference.state && currentPageReference.state.app;
    //     if (app === 'commeditor') {
    //         this.publishStatus = 'Draft';
    //     } else {
    //         this.publishStatus = 'Live';
    //     }
    // }

}