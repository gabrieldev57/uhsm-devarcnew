import { LightningElement, wire, track} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import FirstName from '@salesforce/schema/User.Contact.FirstName';
import LastName from '@salesforce/schema/User.Contact.LastName';
import UsingPhoto from '@salesforce/schema/User.IsProfilePhotoActive';
import Id from '@salesforce/user/Id';

export default class ARC_UserPicture extends LightningElement {
    // TODO - if client changes topbar max-height, this is hardcoded to 1440 and will be unaligned
    @wire(getRecord, { recordId: Id, fields: [FirstName,LastName,UsingPhoto] })
    user;

    get usingPhoto() {
        return getFieldValue(this.user.data, UsingPhoto);
    }

    get firstNameInitial() {
        let name = getFieldValue(this.user.data, FirstName);
        if(!name) return "";
        else return name.charAt(0);
    }

    get lastNameInitial() {
        let name = getFieldValue(this.user.data, LastName);
        if(!name) return "";
        else return name.charAt(0);
    }
}