/*
// @author            : franco.boragno@arcsona.com
// @description       : Topbar Cmp

// @group             : Spark
// @last modified on  : 06-08-2024
// @last modified by  : franco.boragno@arcsona.com
*/
import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';

import isGuest from "@salesforce/user/isGuest";
import UserId from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';

import TopbarResources from '@salesforce/resourceUrl/ARC_TopbarResources';


export default class aRC_TopbarWeShare extends NavigationMixin(LightningElement) {
    @api height;
    @api responsiveHeight;
    @api background = "";
    @api userOnTopbar = false;
    @api showDrawerDesktop;
    @api color;
    @api colorHover;
    @api transparentAtTop;
    @api colorWhenTransparent;
    @api logoOverride = "";
    @api logoWidth;
    @api logoHeight = "";
    @api logoColor;
    @api fixed;
    @api hideOnScroll;
    @api linkAlignment;
    @api linkHoverStyle;
    @api dropLinkHoverStyle;

    // Guest detection
    get bIsGuest() {
        return isGuest;
    }
    get bIsUser() {
        return !isGuest;
    }

    logoUrl = TopbarResources + "/logo-weshare.svg#svg"
    
    // Get current user's name for displaying when logged in
    @wire(getRecord, { recordId: UserId, fields: [USER_NAME_FIELD]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
        }
    }

    connectedCallback(){
        this.height = "104px";
        this.responsiveHeight = "58px";
        this.background = "";
        this.userOnTopbar = false;
        this.showDrawerDesktop = false
        this.color = "#000"
        this.colorHover = "#000"
        this.transparentAtTop = false
        this.logoWidth = "164px"
        // this.logoHeight = ""
        // this.logoColor =
        this.fixed = true
        this.hideOnScroll = true
        

        loadStyle(this, TopbarResources + '/topbar.css')
    }

    renderedCallback(){        
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
		// if(this.logoOverride != "") this.refs.topbar.style.setProperty('--topbar-logo', `url(${this.logoOverride})`)
		this.refs.topbar.style.setProperty('--topbar-logo-width', this.logoWidth)
		if(this.logoHeight != "") this.refs.topbar.style.setProperty('--topbar-logo-height', this.logoHeight)
        // Logo Color
        this.applyLogoColor()
		
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
    offsetTopOfPage = 250; // How much scroll down is necessary (px) at the start of the page for feature to start working
    
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

    iconPhone = TopbarResources + "/icon-phone.svg#svg"
    iconProfile = TopbarResources + "/icon-profile.svg#svg"

    // Opens the Drawer navigation
    toggleDrawer(){
        this.refs.topbar.classList.toggle("drawer-open")
        this.refs.drawer.toggle({});
    }

    phoneNumber = '+1-555-123-4567';
    @track homeUrl = ""

    // Navigate to Community Home Page
    navigateToHome() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }
    // Navigate to Register page
    navigateToRegister() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Register'
            }
        });
    }

    // Navigate to Login page
    navigateToLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Login'
            }
        });
    }
    // Handle phone button click
    handlePhoneClick() {
        // Option 1: Open phone dialer (mobile devices)
        window.open(`tel:${this.phoneNumber}`);
        
        // Option 2: If you want to navigate to a contact page instead, use:
        // this[NavigationMixin.Navigate]({
        //     type: 'comm__namedPage',
        //     attributes: {
        //         name: 'Contact'
        //     }
        // });
    }

}