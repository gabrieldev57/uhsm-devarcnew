import {
    api, LightningElement
} from 'lwc';
// import { LightningElement } from "lwc";

// import BaseComponent from 'c/aRC_MC_BaseComponent';
import staticImages from '@salesforce/resourceUrl/membercommunity'

export default class aRC_MC_PriceInfo extends LightningElement {
    image = staticImages + '/membercommunity/06-footer-logo.png'

    iconFacebook = `${staticImages + '/membercommunity/facebook.svg'}#facebook-icon`
    iconTwitter = `${staticImages + '/membercommunity/twitter.svg'}#twitter-icon`
    iconInstagram = `${staticImages + '/membercommunity/instagram.svg'}#instagram-icon`
    iconLinkedin = `${staticImages + '/membercommunity/linkedin.svg'}#linkedin-icon`
    iconTikTok = `${staticImages + '/membercommunity/tiktok.svg'}#tiktok-icon`

    @api section = "home";
 a
    home = {
        "styles": "{\"textHoverColor\":\"#FFFFFF\",\"backgroundColor\":\"#FFFFFF\",\"buttonColor\":\"#5B45E0\",\"linkColorHover\":\"#5B45E0\",\"backgroundHoverColor\":\"#5B45E0\",\"titleHoverColor\":\"#FFFFFF\"}",
        "description": "<p><b> © 2025 Unite Health Share Ministries™ and WeShare® </b></p> <p> <b>WeShare® is not a reimbursement program.</b> WeShare® is not an insurance company nor is the membership offered through an insurance company. WeShare® membership is offered and administered by Unite Health Share Ministries™ (UHSM), a nonprofit, religious healthcare sharing ministry that facilitates member-to-member sharing of medical expenses. WeShare® is connected through partnerships to provide resources, community, and healthcare for all WeShare® members. Members should never have to pay cash up-front for services in-network, with the only payment incurred at the time of service being the per member, per visit, consultation fee, as outlined in the Membership Guidelines. All Sharing Members are responsible for their own medical expenses, less amounts paid from shared dollars. </p>",
        "links": [
            {
                "label": "Contact Us",
                "url": "https://www.weshare.org/contact-weshare/"
            },
            {
                "label": "Find a Provider",
                "url": "https://www.weshare.org/find-a-provider/"
            },
            {
                "label": "Privacy Policy",
                "url": "https://www.weshare.org/privacy-policy/"
            },
            {
                "label": "Terms and Conditions",
                "url": "https://www.weshare.org/terms-and-conditions/"
            },
            {
                "label": "Cookie Policy",
                "url": "https://www.weshare.org/cookies/"
            },
            //{
            //    "label": "Regulatory Information",
            //    "url": "https://www.weshare.org/regulatory-information/"
            //},
        ]
    };


    // renderedCallback() {
    //     super.renderedCallback();

    //     if (this.items && this.items.length > 0) {

    //         const templateM = this.template.querySelector('div')
    //         const cards = this.template.querySelectorAll('.info-card')
    //         const tagline = this.template.querySelectorAll('.spk-tagline')
    //         const title = this.template.querySelectorAll('.spk-title')
    //         const subtitle = this.template.querySelectorAll('.spk-subtitle')
    //         const icons = this.template.querySelectorAll('.icon-s')
    //         const list = this.template.querySelectorAll('.list')
    //         const li = this.template.querySelectorAll('.spk-child-description')
    //         const butt = this.template.querySelectorAll('.bottom-container :nth-child(1) a')
    //         const link = this.template.querySelectorAll('.bottom-container :nth-child(2) a')

    //         const features = this.template.querySelectorAll('.arc-text')

    //         features.forEach(feature => {

    //             const styles = JSON.parse(this.items[feature.dataset.index].styles)

    //             let featureStyles = "";

    //             if (styles.featureColor) featureStyles += `color:${styles.featureColor};`;
    //             if (styles.featureBGColor) featureStyles += `background-color:${styles.featureBGColor};`;
    //             if (styles.featureAlignment) featureStyles += `text-align:${styles.featureAlignment};`;
    //             if (styles.featureBold) featureStyles += "font-weight:700;";
    //             if (styles.featureItalic) featureStyles += "font-style:italic;";
    //             if (styles.featureUnderline) featureStyles += "text-decoration:underline;";
    //             if (styles.featureTextSize) featureStyles += `font-size:${styles.featureTextSize} !important;`
    //             if (styles.iconColor) featureStyles += `fill:${styles.iconColor}`;

    //             feature.style = featureStyles

    //             let iconStyles = ''
    //             if (styles.iconColor) iconStyles += `fill:${styles.iconColor}`

    //             const icons = feature.querySelectorAll('.icon-s')
    //             icons.forEach(icon => {

    //                 icon.style = iconStyles

    //             })

    //         })

    //         this.items.forEach((item, index) => {

    //             if (!item.styles) return;
    //             let styles = JSON.parse(item.styles);

    //             var innerDiv = document.createElement('div')
    //             innerDiv.innerHTML = `<style>.info-card[data-hover='${item.id}']:hover{
    //                                     background-color: ${styles.textHoverColor}!important;
    //                                     border-color: ${styles.borderHoverColor}!important;
    //                                     }</style>`

    //             var innerDiv2 = document.createElement('div')
    //             innerDiv2.innerHTML = `<style>.info-card:hover .top-container .list-div .list[data-hover='${item.id}'] .icon-s{
    //                                     fill: ${styles.iconHoverColor}!important;
    //                                     }</style>`

    //             var innerDiv3 = document.createElement('div')
    //             innerDiv3.innerHTML = `<style>.info-card:hover .top-container .price-container .title-pi[data-hover='${item.id}']{
    //                                     color: ${styles.titleHoverColor}!important;
    //                                     }</style>`

    //             var innerDiv4 = document.createElement('div')
    //             innerDiv4.innerHTML = `<style>.info-card:hover .top-container .price-container .subtitle-pi[data-hover='${item.id}']{
    //                                     color: ${styles.subtitleHoverColor}!important;
    //                                     }</style>`

    //             var innerDiv5 = document.createElement('div')
    //             innerDiv5.innerHTML = `<style>.info-card:hover .top-container h2[data-hover='${item.id}']{
    //                                     color: ${styles.taglineHoverColor}!important;
    //                                     }</style>`

    //             var innerDiv7 = document.createElement('div')
    //             innerDiv7.innerHTML = `<style>.info-card:hover .top-container .list-div .list .arc-text[data-hover='${item.id}']{
    //                                     color: ${styles.featureHoverColor}!important;
    //                                     }</style>`

    //             var innerDiv8 = document.createElement('div')
    //             innerDiv8.innerHTML = `<style>.info-card:hover .bottom-container :nth-child(1) a[data-hover='${item.id}']{
    //                                     color: ${styles.linkTextHoverColor}!important;
    //                                     background-color: ${styles.linkBackgroundHoverColor}!important;
    //                                     border-color: ${styles.linkBorderHoverColor}!important;
    //                                     }</style>`


    //             try {
    //                 if (cards && cards.length > 0) {
    //                     cards[index].appendChild(innerDiv);

    //                     let cardStyles = "";

    //                     if (styles.hoverAnimation) cards[index].classList.add("anim");
    //                     if (styles.cardShadow) cardStyles += "box-shadow: 0 1.5em 2.5em -0.5em rgb(0 0 0 / 15%);";
    //                     if (styles.borderRadius) cardStyles += "border-radius: 12px;";
    //                     if (styles.borderColor) cardStyles += `border: ${styles.borderWidth} solid ${styles.borderColor};`;
    //                     if (styles.backgroundColor) cardStyles += `background-color:${styles.backgroundColor};`;
    //                     cards[index].style = cardStyles;
    //                 }
    //             } catch (error) {

    //             }
    //             try {
    //                 if (tagline && tagline.length > 0) {
    //                     tagline[index].appendChild(innerDiv5);

    //                     let taglineStyles = "";

    //                     if (styles.taglineColor) taglineStyles += `color:${styles.taglineColor};`;
    //                     if (styles.taglineAlignment) taglineStyles += `text-align:${styles.taglineAlignment};`;
    //                     if (styles.taglineBold) taglineStyles += "font-weight:700;";
    //                     if (styles.taglineSize) taglineStyles += `font-size:${styles.taglineSize};`
    //                     if (styles.taglineItalic) taglineStyles += "font-style:italic;";
    //                     if (styles.taglineUnderline) taglineStyles += "text-decoration:underline;";

    //                     tagline[index].style = taglineStyles;
    //                 }
    //             } catch (error) {

    //             }
    //             try {
    //                 if (title && title.length > 0) {
    //                     title[index].appendChild(innerDiv3);

    //                     let titleStyles = "";

    //                     if (styles.titleColor) titleStyles += `color:${styles.titleColor};`;
    //                     if (styles.titleAlignment) titleStyles += `text-align:${styles.titleAlignment} !important;`;
    //                     if (styles.separatorLinesColor) titleStyles += `border-bottom: 2px solid ${styles.separatorLinesColor} !important;`;
    //                     if (styles.titleBold) titleStyles += "font-weight:700 !important;";
    //                     if (styles.titleSize) titleStyles += `font-size:${styles.titleSize}!important;`;
    //                     if (styles.titleItalic) titleStyles += "font-style:italic !important;";
    //                     if (styles.titleUnderline) titleStyles += "text-decoration:underline !important;";

    //                     title[index].style = titleStyles;
    //                 }
    //             } catch (error) {

    //             }
    //             try {
    //                 if (subtitle && subtitle.length > 0) {
    //                     subtitle[index].appendChild(innerDiv4);

    //                     let subtitleStyles = "";

    //                     if (styles.subtitleColor) subtitleStyles += `color:${styles.subtitleColor};`;
    //                     if (styles.subtitleAlignment) subtitleStyles += `text-align:${styles.subtitleAlignment} !important;`;
    //                     if (styles.subtitleSize) subtitleStyles += `font-size:${styles.subtitleSize}!important;`;
    //                     if (styles.subtitleBold) subtitleStyles += "font-weight:700 !important;";
    //                     if (styles.subtitleItalic) subtitleStyles += "font-style:italic !important;";
    //                     if (styles.subtitleUnderline) subtitleStyles += "text-decoration:underline !important;";

    //                     subtitle[index].style = subtitleStyles;
    //                 }
    //             } catch (error) {

    //             }
    //             try {
    //                 if (butt && butt.length > 0) {
    //                     butt[index].appendChild(innerDiv8);

    //                     let linkStyles = "";

    //                     if (styles.linkColor) linkStyles += `color:${styles.linkColor};`;
    //                     if (styles.buttonColor) linkStyles += `background-color:${styles.buttonColor};`;
    //                     if (styles.linkBorderColor) linkStyles += `border-color: ${styles.linkBorderColor};`;
    //                     if (styles.linkSize) linkStyles += `font-size:${styles.linkSize};`;
    //                     if (styles.linkBold) linkStyles += "font-weight:700;";
    //                     if (styles.linkItalic) linkStyles += "font-style:italic;";
    //                     if (styles.linkUnderline) linkStyles += "text-decoration:underline;";

    //                     butt[index].style = linkStyles;
    //                 }
    //             } catch (error) {

    //             }
    //             try {

    //                 if (list) {

    //                     li[index].appendChild(innerDiv7);
    //                     list[index].appendChild(innerDiv2);

    //                 }

    //             } catch (error) {

    //             }
    //         })
    //     }
    // }

    handleNavigate(event) {
        window.open(event.currentTarget.dataset.externalurl, '_blank');
    }

}