import { LightningElement } from 'lwc';
import resources from '@salesforce/resourceUrl/ARC_CommunityResources';

export default class uhsmFooter extends LightningElement {
    iconFacebook = `${resources}/social-facebook.svg#svg`;
    iconTwitter = `${resources}/social-twitter.svg#svg`;
    iconInstagram = `${resources}/social-instagram.svg#svg`;
    iconPinterest = `${resources}/social-pinterest.svg#svg`;
    iconLinkedin = `${resources}/social-linkedin.svg#svg`;
    iconYoutube = `${resources}/social-youtube.svg#svg`;

    handleNavigate(event){
        window.open(event.currentTarget.dataset.externalurl, '_blank');
    }

}