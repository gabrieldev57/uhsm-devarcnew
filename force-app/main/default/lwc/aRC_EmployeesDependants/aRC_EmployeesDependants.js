import { LightningElement, api, track } from 'lwc';
import GetDependents from '@salesforce/apex/ARC_EmployeesDetailController.getParticipantsFromAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ARC_EmployeesDependants extends LightningElement {
    @api recordId;
    @api canEdit = false;
    @track editMode = false;
    @track activeMemberList = [];
    

    connectedCallback() {
        this.getDependents();
    }

    normalize(val) {
        return val ? val.toString().trim().toLowerCase() : '';
    }

    /* Compare two addresses */
    isSameAddress(addr1, addr2) {
        if (!addr1 || !addr2) {
            return false;
        }

        return (
            this.normalize(addr1.street) === this.normalize(addr2.street) &&
            this.normalize(addr1.city) === this.normalize(addr2.city) &&
            this.normalize(addr1.state) === this.normalize(addr2.state) &&
            this.normalize(addr1.postalCode) === this.normalize(addr2.postalCode) &&
            this.normalize(addr1.country) === this.normalize(addr2.country)
        );
    }

    /* Format address for display*/

    formatAddress(address) {
        if (!address) return '';

        return [
            address.street,
            address.city,
            address.state,
            address.postalCode,
            address.country
        ]
            .filter(v => v)
            .join(', ');
    }

     // Mask SSN to XXX-XX-1234
    maskSSN(ssn) {
        const digits = ssn.replace(/\D/g, ''); 
        if (digits.length !== 9) return ssn; 
        return `XXX-XX-${digits.slice(5)}`;
    }

    get hasNoDependents() {
    return !this.isLoading && (!this.activeMemberList || this.activeMemberList.length === 0);
}

    /* Fetch dependents */
    getDependents() {
        this.isLoading = true;

        GetDependents({ accountId: this.recordId })
            .then(result => {
                console.log('RAW dependents:',JSON.parse(JSON.stringify(result)));

                this.activeMemberList = result
                    .filter(member => member.Role !== 'Primary')
                    .map(member => {
                        // Mask SSN
                        const maskedSSN = member.SSN ? this.maskSSN(member.SSN) : '';
                        const sameAddress = this.isSameAddress(member.Address,member.primaryParticipantAddress);
                       // console.log('Address check:', {dependent: member.Address,primary: member.primaryParticipantAddress,sameAddress});

                        return {
                            ...member,
                            PersonAccountId:member.PersonAccountId,
                            SSN: maskedSSN,
                            showAddress: !sameAddress,
                            displayAddress: !sameAddress
                                ? this.formatAddress(member.Address)
                                : null,
                            isSaving: false,
                            Birthdate: member.Birthdate ? this.formatDate(member.Birthdate) : '',
                        };
                    });

                console.log('Processed dependents:',JSON.parse(JSON.stringify(this.activeMemberList)));

                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching dependents:', error);
                this.isLoading = false;
            });
    }

    handleCancel() {
        this.editMode = false;
    }

    handleEdit() {
        this.editMode = true;
    }

    get showEditButton() {
        return this.canEdit && !this.editMode;
    }

    handleError(event) {
        this.isSaving = false; // hide spinner

        this.activeMemberList = this.activeMemberList.map(member => ({
        ...member,
        isSaving: false
    }));

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error updating record',
                message: event.detail.message,
                variant: 'error'
            })
        );
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const [year, month, day] = dateStr.split('-');
        if (!year || !month || !day) return dateStr;
        return `${month}-${day}-${year}`;
    }

   handleSubmit(event) {
    this.isSaving = true;

    const recordId = event.target.recordId;

    this.activeMemberList = this.activeMemberList.map(member => ({
        ...member,
        isSaving: member.PersonAccountId === recordId
    }));
}


    handleSuccess(event) {

        this.isSaving = false;  // hide spinner

        this.activeMemberList = this.activeMemberList.map(member => ({
        ...member,
        isSaving: false
    }));

        this.editMode = false;

    const updatedRecordId = event.detail.id; // ID of the updated record

    // Show toast message
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Success',
            message: 'Record has been updated successfully',
            variant: 'success'
        })
    );
    //console.log('Record updated: ', updatedRecordId);
    // Optional: refresh data after edit
    this.getDependents();

}

}