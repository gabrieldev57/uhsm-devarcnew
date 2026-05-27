import { LightningElement, api } from 'lwc';
import saveCensusMemberForCurrentUser from '@salesforce/apex/ARC_CensusMemberPortalController.saveCensusMemberForCurrentUser';
import getPicklistOptions from '@salesforce/apex/ARC_CensusMemberPortalController.getPicklistOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ARC_AddPrimaryCensusMemberPortal extends LightningElement {
    @api title = 'Add Primary Census Member';

    form = {
        firstName: '',
        lastName: '',
        dob: '',
        employmentType: '',
        division: '',
        jobClass: '',
        ssn: '',
        email: '',
        phone: '',
        gender: '',
        street: '',
        city: '',
        state: '',
        zipCode: '',
        effectiveDate: ''
    };

    effectiveDate;
    effectiveDateMin;
    effectiveDateMax;

    genderOptions = [
        { label: 'Male', value: 'Male' },
        { label: 'Female', value: 'Female' }
    ];

    validStates = ['AL', 'AK', 'AZ', 'AR', 'AS', 'CA', 'CO', 'CT', 'DE', 'DC',
                    'FL', 'GA', 'GU', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY',
                    'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE',
                    'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'MP', 'OH', 'OK',
                    'OR', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN', 'TX', 'TT', 'UT',
                    'VT', 'VA', 'VI', 'WA', 'WV', 'WI', 'WY'];

    employmentTypeOptions = [];
    divisionOptions = [];
    jobClassOptions = [];

    isSaving = false;

    getTodayISO() {
        const d = new Date();
        const mm = String(d.getMonth() + 1).padStart(2, '0');
        const dd = String(d.getDate()).padStart(2, '0');
        return `${d.getFullYear()}-${mm}-${dd}`;
    }

    addYearsISO(yearsToAdd) {
        const d = new Date();
        d.setFullYear(d.getFullYear() + yearsToAdd);
        const mm = String(d.getMonth() + 1).padStart(2, '0');
        const dd = String(d.getDate()).padStart(2, '0');
        return `${d.getFullYear()}-${mm}-${dd}`;
    }

    async connectedCallback() {
        const defaultIso = this.getNextFirstOfMonthISO();
        this.effectiveDate = defaultIso;
        this.form.effectiveDate = defaultIso;

        this.effectiveDateMin = this.getTodayISO();

        this.effectiveDateMax = this.addYearsISO(2);

        try {
            const dto = await getPicklistOptions();
            this.employmentTypeOptions = (dto?.employmentTypes || []).map(v => ({ label: v, value: v }));
            this.divisionOptions = (dto?.divisions || []).map(v => ({ label: v, value: v }));
            this.jobClassOptions = (dto?.jobClasses || []).map(v => ({ label: v, value: v }));
        } catch (e) {
            this.toast('Error', this.reduceError(e) || 'Unable to load picklist values.', 'error');
        }
    }

    getNextFirstOfMonthISO() {
        const now = new Date();
        const y = now.getFullYear();
        const m = now.getMonth();
        const nextFirst = new Date(y, m + 1, 1);
        const mm = String(nextFirst.getMonth() + 1).padStart(2, '0');
        const dd = String(nextFirst.getDate()).padStart(2, '0');
        return `${nextFirst.getFullYear()}-${mm}-${dd}`;
    }

    handleChange(event) {
        const input = event.target;
        const name = input.name;
        let value = input.value || '';

        // Transformaciones por campo
        switch (name) {
            case 'ssn':
                value = value.replace(/\D/g, '').slice(0, 9);
                input.value = value;
                break;

            case 'phone':
                value = value.replace(/\D/g, '').slice(0, 10);
                if (value.length > 6) {
                    value = `(${value.slice(0,3)}) ${value.slice(3,6)}-${value.slice(6)}`;
                } 
                else if (value.length > 3) {
                    value = `(${value.slice(0,3)}) ${value.slice(3)}`;
                } 
                else if (value.length > 0) {
                    value = `(${value}`;
                }
                input.value = value;
                break;

            case 'zipCode':
                value = value.replace(/\D/g, '').slice(0, 9);
                input.value = value;
                break;

            case 'state':
                value = value.toUpperCase().slice(0, 2);
                input.value = value;
                break;
        }

        // Guardar en form
        this.form = { ...this.form, [name]: value };

        // Validaciones
        let error = '';

        switch (name) {
            case 'ssn':
                if (value.length !== 9) {
                    error = 'SSN must be exactly 9 digits.';
                }
                break;

            case 'phone':
                value = value.replace(/\D/g, '').slice(0, 10);
                if (value.length !== 10) {
                    error = 'Phone must be exactly 10 digits.';
                }
                break;

            case 'zipCode':
                if (!(value.length === 5 || value.length === 9)) {
                    error = 'ZIP must be 5 digits or 9 digits.';
                }
                break;

            case 'state':
                if (!this.validStates.includes(value)) {
                    error = "Sorry, this is not a valid state";
                }
            break;
        }

        input.setCustomValidity(error);
        input.reportValidity();
    }

    async handleSubmit() {

        const fields = this.template.querySelectorAll(
            'lightning-input, lightning-combobox'
        );

        let isValid = true;

        fields.forEach(field => {
            field.reportValidity(); // muestra errores visuales

            if (!field.checkValidity()) {
                isValid = false;
            }
        });

        if (!isValid) {
            return;
        }

        console.log('form:', this.form);

        this.isSaving = true;

        try {
            const memberJson = JSON.stringify(this.form);
            const res = await saveCensusMemberForCurrentUser({ memberJson });

            if (res?.success) {
                this.toast('Success', res.message || 'Member saved.', 'success');

                this.dispatchEvent(
                    new CustomEvent('saved', {
                        detail: res,
                        bubbles: true,
                        composed: true
                    })
                );

                this.handleClose();

            } else {
                const msg = (res?.errors && res.errors.length)
                    ? res.errors.join('\n')
                    : 'Unable to save member.';

                this.toast('Error', msg, 'error');
            }

        } catch (e) {

            this.toast(
                'Error',
                this.reduceError(e) || 'Unexpected error while saving.',
                'error'
            );

        } finally {
            this.isSaving = false;
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(e) {
        const body = e?.body;
        if (Array.isArray(body)) return body.map(x => x.message).filter(Boolean).join(', ');
        if (typeof body?.message === 'string') return body.message;
        if (typeof e?.message === 'string') return e.message;
        return '';
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleBackdrop() {
        this.handleClose();
    }
}