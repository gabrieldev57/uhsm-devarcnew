/*
// @author            : franco.boragno@arcsona.com
// @description       : Displays links for a topbar or a drawer

Used on Spark Cmp of type "topbar".

// @group             : Spark
// @last modified on  : 09-07-2024
// @last modified by  : franco.boragno@arcsona.com
*/
import { LightningElement, api, wire, track } from 'lwc';


import TopbarResources from '@salesforce/resourceUrl/ARC_TopbarResources';


export default class SimpleNavigation extends LightningElement {
    @api alignment = "right"; // Alignment of the links
    @api drawer = false; // Will display a menu vertically with accordions if true
    @api linkLimit = false; // For topbar, limits how many links are visible

    @api menuItems;
    @api currentPageReference;

    // Icon for submenus
	iconChevronDown = TopbarResources + '/chevron-down.svg#svg'

    // If true, will tell buttons to use 100% of the available width (used for drawer navigation)
    @track forceFullWidthButtons = false


    renderedCallback(){
        // Set accordion height using JS for transitions when opening / closing
        setTimeout(() => {
            this.setAccordionHeights()
        }, 1000);
        if(!this.rendered) {
            // Set current active link visibility
            // this.setActiveLink()
            // When resizing the window, refresh the heights set to accordions (needed because they might not be visible on desktop when loading the component)
            if(!this.eventSet) window.addEventListener('resize', ()=> this.onResize());
            this.eventSet = true;
        }
        this.rendered = true
    }

    
    setActiveLink() {
        // Remove current active link element
        if(this.currentActiveElem) this.currentActiveElem.classList.remove("active")
        this.currentActiveElem = null
        let currentActiveData = {index: -1, subIndex: -1}
        let pageApiName = this.currentPageReference.attributes.name
        // Find link with the same url as the current page and store its indexes to activate
        this.menuLinks.forEach((link, index) => {
            if(pageApiName == link.url){
                currentActiveData.index = index
            }
            if(link.childLinks && link.childLinks.length){
                link.childLinks.forEach((childLink, subIndex) => {
                    if(pageApiName == childLink.url){
                        currentActiveData = {
                            index: index,
                            subIndex: subIndex
                        }
                    }
                })
            }
        })
        // Find the element representing the active link in the DOM using the indexes stored
        if(currentActiveData.index != -1){
            this.currentActiveElem = this.template.querySelectorAll(".menu-link")[currentActiveData.index]
            if(currentActiveData.subIndex != -1){
                this.currentActiveElem = this.currentActiveElem.querySelectorAll(".menu-link")[currentActiveData.subIndex]
            }
        }
        // If an element was found, activate it
        if(this.currentActiveElem) this.currentActiveElem.classList.add("active")
    }

    // On window resize, refresh set accordion heights
    onResize(){
        this.setAccordionHeights()
    }
    // Manually sets the height of the accordions for animating opening/closing them
    setAccordionHeights(){
        let accordionContents = this.template.querySelectorAll(".accordion-links");
        accordionContents.forEach(elem => {
            elem.parentNode.style.setProperty("--accordion-height", elem.offsetHeight + "px")
        })
    }

    // Accordion Open / Close
    toggleAccordion(e){
        e.currentTarget.parentNode.classList.toggle("open");
    }

    // Methods to pass styles from Spark from the cmps using this sub component
    @api
    setDropStyle(style){
        if(this.refs.navigation){
            this.refs.navigation.dataset.dropStyle = style
            this.forceFullWidthButtons = style == "Dropdown"
        }
    }
    @api
    setLinkStyles(style, dropStyle){
        if(this.refs.navigation){
            this.refs.navigation.dataset.linkStyle = style
            this.refs.navigation.dataset.dropLinkStyle = dropStyle
        }
    }
}