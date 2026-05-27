import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPoliciesWithQLE from '@salesforce/apex/ARC_LOAPolicyController.getPoliciesWithQLE';
import updateLOADates from '@salesforce/apex/ARC_LOAPolicyController.updateLOADates';
import { refreshApex } from '@salesforce/apex';

export default class ARC_PolicyLOA extends LightningElement {

    @api recordId;
    _editMode = false;
    @api canEdit = false;

    set editMode(value) {
        this._editMode = value;
        this.updateDisabledStates();
    }

    get editMode() {
        return this._editMode;
    }

    handleEdit() {
        this.editMode = true;
    }

    get showEditButton() {
        return this.canEdit && !this.editMode && this.hasRecords;
    }

    updateDisabledStates() {
        if (!this.loaRecords || this.loaRecords.length === 0) {
            return;
        }

        this.loaRecords = this.loaRecords.map(r => {
            const isUpcoming = !r.isPast;

            return {
                ...r,
                startDateDisabled: !isUpcoming || !this._editMode,
                endDateDisabled: !isUpcoming || !this._editMode
            };
        });

    }

    loaRecords = [];
    isLoading = true;
    error;
    noData = false;
    wiredResult;
    hasChanges = false;
    

    @wire(getPoliciesWithQLE, { memberAccountId: '$recordId' })
    wiredPolicies(result) {
        if (!result) {
            return;
        }

        this.wiredResult = result;
        const { error, data } = result;

        if (data) {
            const today = new Date();
            today.setHours(0,0,0,0);

            this.loaRecords = data.map(record => {
                console.log('Record from Apex:', record);
                
                const parseLocalDate = (dateStr) => {
                    if (!dateStr) return null;
                    const [year, month, day] = dateStr.split('-').map(Number);
                    return new Date(year, month - 1, day);
                };

                const startDate = parseLocalDate(record.startDate);
                const endDate = record.endDate ? new Date(record.endDate) : null;
                const isUpcoming = startDate && startDate >= today;

                if (!record.policyId) {
                    console.warn('Record sin policyId:', record);
                }

                return {
                    id: record.policyId,
                    policyId: record.policyId,  
                    policyNumber: record.policyNumber,
                    submittedDate: record.submittedDate,
                    startDate: record.startDate,
                    endDate: record.endDate,
                    reason: record.reason,
                    status: isUpcoming ? 'Upcoming' : 'Past',
                    isPast: !isUpcoming,
                    startDateDisabled: !isUpcoming || !this._editMode,
                    endDateDisabled: !isUpcoming || !this._editMode,
                    startDateEditableClass: isUpcoming ? 'editable-field slds-text-color_success' : 'readonly-field',
                    endDateEditableClass: isUpcoming ? 'editable-field slds-text-color_success' : 'readonly-field',
                    statusClass: isUpcoming ? 'slds-text-color_success slds-text-body_small' : 'slds-text-color_weak slds-text-body_small'
                };
            });

            console.log('loaRecords procesados:', this.loaRecords);
            this.noData = this.loaRecords.length === 0;
            this.error = undefined;
        } else if (error) {
            this.error = error?.body?.message || error?.message || 'Unknown error';
            this.noData = true;
        }
        this.isLoading = false;
    }

    handleDateChange(event) {
        const recordId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;

        console.log('Date change:', { recordId, field, value });

        if (!recordId) {
            console.error('recordId es null/undefined en handleDateChange');
            return;
        }

        this.loaRecords = this.loaRecords.map(record => {
            if (record.policyId === recordId) {
                
                
                const updatedRecord = { 
                    ...record,
                    [field]: value 
                };
                
                return updatedRecord;
            }
            return record;
        });

        this.hasChanges = true;
        
    }

   async handleSave() {
        try {
            this.isLoading = true;
            
            const validRecords = this.loaRecords.filter(r => {
                return !r.isPast && r.startDate && r.endDate && r.policyId;
            });
            
            
            if (validRecords.length === 0) {
                this.showToast('No changes', 'There are no valid records to update', 'info');
                return;
            }
            
            const updates = validRecords.map(r => ({
                policyId: String(r.policyId),
                startDate: String(r.startDate),
                endDate: String(r.endDate)
            }));

            const payload = {
                updates: updates,
                memberAccountId: this.recordId
            };


            await updateLOADates({ payload });  

            this.showToast('Success', 'Dates updated successfully', 'success');
            await refreshApex(this.wiredResult);
            this.hasChanges = false;
            this.editMode = false;

        } catch (error) {
            console.error('Update error', error);
            console.error('Error body:', error?.body);
            
            this.showToast(
                'Error updating dates',
                error?.body?.message || error?.message || 'Unknown error',
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    async handleCancel() {
        this.hasChanges = false;
        await refreshApex(this.wiredResult);
        this.editMode = false;
    }

    get hasRecords() {
        return this.loaRecords.length > 0;
    }

    get hasUpcomingRecords() {
        return this.loaRecords.some(r => !r.isPast);
    }

    get errorMessage() {
        return this.error;
    }

}