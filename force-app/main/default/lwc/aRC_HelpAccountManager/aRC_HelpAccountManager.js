import { LightningElement, track, wire } from 'lwc';
import getManagerInfo from '@salesforce/apex/ARC_HelpPageController.getManagerInfo';

export default class ARC_HelpAccountManager extends LightningElement {
    @track manager = null;
    hasError = false;

    @wire(getManagerInfo)
    wiredManager({ error, data }) {
        if (data) {
            const availability =
                data.StartDay && data.EndDay
                    ? `${data.StartDay} - ${data.EndDay}`
                    : '';
            this.manager = {
                Name:         data.Name        || '',
                FirstName:    data.FirstName   || '',
                Role:         data.Title       || '',
                Photo:        data.FullPhotoUrl || null,
                Email:        data.Email        || '',
                Phone:        data.Phone        || '',
                mailto:       data.Email ? 'mailto:' + data.Email : '#',
                tel:          data.Phone ? 'tel:' + data.Phone : '#',
                Availability: availability
            };
        } else if (error) {
            console.error('Error retrieving account manager:', error);
            this.hasError = true;
        }
    }

    get hasManager() {
        return !!this.manager;
    }

    handlePhotoError() {
        // If the photo URL is broken, clear it so the fallback icon renders instead
        this.manager = { ...this.manager, Photo: null };
    }
}