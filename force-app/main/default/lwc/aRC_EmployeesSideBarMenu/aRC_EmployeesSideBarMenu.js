import { LightningElement, track, wire } from 'lwc';
import WeShareLogo from '@salesforce/resourceUrl/EmployeesResources';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

const FIELDS = [
    'User.Name',
    'User.Title',
    'User.FullPhotoUrl',
    'User.Account.Name',
    'User.Profile.Name'
];

const ACCOUNT_FIELDS = ['Account.RecordType.DeveloperName'];
export default class ARC_EmployeesSideNavigation extends NavigationMixin(LightningElement) {
    @track user = { Name: "John Shwaab", Role: "Data Manager" }
    companyName = "Company Name"
    logoUrl = WeShareLogo + '/weshare_logo_v2.png';
    userId = USER_ID;
    currentActiveElement
    currentPageReference
    rendered = false

    isMenuOpen = false;
    @track pageRecordId;

    toggleMenu() {
        this.isMenuOpen = !this.isMenuOpen;
    }

    get menuClass() {
        //return this.isMenuOpen ? 'menu open' : 'menu';
        return `menu ${this.isMenuOpen ? 'open' : ''}`;
    }

    @track currentPath = window.location.pathname;


    @wire(getRecord, { recordId: '$userId', fields: FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            this.user.Name = data?.fields.Name.value;
            this.user.Role = data?.fields.Title.value;
            this.user.Photo = data?.fields.FullPhotoUrl.value || WeShareLogo + '/profilePhoto.png';
            this.user.Profile = data?.fields?.Profile?.value?.fields?.Name?.value
            this.companyName = data?.fields?.Account?.value?.fields.Name.value
            console.log('usr', JSON.stringify(data, null, 2))
        } else if (error) {
            console.error('Error retrieving user data:', error);
        }
    }

    @wire(getRecord, { recordId: '$pageRecordId', fields: ACCOUNT_FIELDS })
    wiredPageRecord({ error, data }) {
        if (data) {
            const devName = data?.fields?.RecordType?.value?.fields?.DeveloperName?.value;
            if (devName === 'ARC_SGPersonAccount') {
                this._activateItem('Employees__c');
            }
        }
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;

        const recordId = currentPageReference?.attributes?.recordId
                      || currentPageReference?.state?.recordId;

        if (recordId) {
            this.pageRecordId = recordId;
            if (this.currentActiveElement) {
                this.currentActiveElement.classList.remove('active');
                this.currentActiveElement = null;
            }
            console.log('currentPageReference', JSON.stringify(currentPageReference, null, 2));
            return;
        }

        this.pageRecordId = null;
        if (this.currentActiveElement && this.currentActiveElement.dataset.target != this.currentPageReference.attributes.name) {
            this.currentActiveElement.classList.remove('active')
            this.currentActiveElement = null
        }
        if (!this.currentActiveElement && this.rendered) {
            this.currentActiveElement = this.template.querySelector(`.menu li[data-target="${this.currentPageReference.attributes.name}"]`)
            this.currentActiveElement.classList.add('active')
        }

        console.log('currentPageReference', JSON.stringify(currentPageReference, null, 2))
    }

    _activateItem(target) {
        if (this.currentActiveElement) {
            this.currentActiveElement.classList.remove('active');
            this.currentActiveElement = null;
        }
        const el = this.template.querySelector(`.menu li[data-target="${target}"]`);
        if (el) {
            el.classList.add('active');
            this.currentActiveElement = el;
        }
    }

    renderedCallback() {
        if (!this.currentActiveElement) {
            this.currentActiveElement = this.template.querySelector(`.menu li[data-target="${this.currentPageReference.attributes.name}"]`)
            if(this.currentActiveElement)this.currentActiveElement.classList.add('active')
            this.rendered = true
        }
    }



    //Also works with keyboard
    handleKeyDown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            event.currentTarget.click();
        }
    }

    navigateTo(event) {
        const target = event.currentTarget.dataset.target;
        this.isMenuOpen = false; //close themenu
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: target
            }
        });
    }
    navigateToFlow() {
        if (this.user.Profile == 'Employer Admin') {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'Create_User__c'
                }
            });
        }
    }

    // handleUserMenuSelect(event) {
    //     const value = event.currentTarget?.value;;

    //     if (value === 'logout') {
    //         this[NavigationMixin.Navigate]({
    //             type: 'comm__loginPage',
    //             attributes: { actionName: 'logout' }
    //         });
    //         return;
    //     }
    // }

    // get userMenuItems() {
    //     const items = [];
    //     // if (this.user?.Profile === 'Employer Admin') {
    //     //   items.push({ label: 'Create User', value: 'createUser' });
    //     // }
    //     items.push({ label: 'Logout', value: 'logout' });
    //     return items;
    // }

    handleLogout(){
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: { actionName: 'logout' }
        });
    }

    
}