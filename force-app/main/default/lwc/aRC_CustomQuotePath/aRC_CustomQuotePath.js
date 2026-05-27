import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

import ID_FIELD from '@salesforce/schema/Quote.Id';
import STATUS_FIELD from '@salesforce/schema/Quote.Status';

const FIELDS = [STATUS_FIELD];

const STEP_CONFIG = [
  { label: 'Draft', value: 'Draft' },
  { label: 'Presented', value: 'Presented' },
  { label: 'Accepted', value: 'Accepted' },
  { label: 'Denied', value: 'Denied' }
];

export default class ARC_CustomQuotePath extends LightningElement {
  @api recordId;

  currentStatus;
  selectedStatus;

  pendingValue;
  showConfirmModal = false;

  wiredResult;
  subscription;
  channelName = '/data/QuoteChangeEvent';

  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredQuote(result) {
    this.wiredResult = result;
    const { data, error } = result;
    if (data) {
      this.currentStatus = data.fields.Status.value;
      if (!this.selectedStatus) this.selectedStatus = this.currentStatus;
      if (this.selectedStatus && !STEP_CONFIG.some(s => s.value === this.selectedStatus)) {
        this.selectedStatus = this.currentStatus;
      }
    } else if (error) {
      this.toast('Error', this.reduceError(error), 'error');
    }
  }

  connectedCallback() {
    onError(() => {});
    this.subscribeCdc();
  }

  disconnectedCallback() {
    this.unsubscribeCdc();
  }

  async subscribeCdc() {
    if (this.subscription) return;

    const messageCallback = async (response) => {
      const ids = response?.data?.payload?.ChangeEventHeader?.recordIds || [];
      if (ids.includes(this.recordId)) {
        await refreshApex(this.wiredResult);
        this.selectedStatus = this.currentStatus;
      }
    };

    this.subscription = await subscribe(this.channelName, -1, messageCallback);
  }

  async unsubscribeCdc() {
    if (!this.subscription) return;
    await unsubscribe(this.subscription);
    this.subscription = null;
  }

  get currentIndex() {
    return STEP_CONFIG.findIndex(s => s.value === this.currentStatus);
  }

  get selectedIndex() {
    return STEP_CONFIG.findIndex(s => s.value === this.selectedStatus);
  }

  get nextStatus() {
    const idx = this.currentIndex;
    if (idx < 0) return null;
    return STEP_CONFIG[idx + 1]?.value || null;
  }

  get actionLabel() {
    if (!this.currentStatus || !this.selectedStatus) return 'Mark Status as Complete';
    if (this.selectedStatus === this.currentStatus) return 'Mark Status as Complete';
    return 'Mark as Current Status';
  }

  get isActionDisabled() {
    if (!this.currentStatus || !this.selectedStatus) return true;
    if (this.selectedStatus !== this.currentStatus) return false;
    return !this.nextStatus;
  }

  get steps() {
    const selected = this.selectedStatus || this.currentStatus;

    return STEP_CONFIG.map((s) => {
      const isSelected = s.value === selected;
      const isComplete = this.isBefore(s.value, this.currentStatus);

      let className = 'slds-path__item slds-is-incomplete';
      if (isSelected) className = 'slds-path__item slds-is-current slds-is-active';
      else if (isComplete) className = 'slds-path__item slds-is-complete';

      return { ...s, isSelected, className };
    });
  }

  handleStepClick(event) {
    event.preventDefault();
    const value = event.currentTarget.dataset.value;
    if (!value) return;
    this.selectedStatus = value;
  }

  async handleSave() {
    if (this.isActionDisabled) return;

    if (this.selectedStatus !== this.currentStatus) {
      if (this.selectedStatus === 'Accepted') {
        this.pendingValue = 'Accepted';
        this.showConfirmModal = true;
        return;
      }
      await this.updateStatus(this.selectedStatus);
      return;
    }

    const next = this.nextStatus;
    if (!next) return;

    if (next === 'Accepted') {
      this.pendingValue = 'Accepted';
      this.showConfirmModal = true;
      return;
    }

    await this.updateStatus(next);
  }

  closeModal() {
    this.showConfirmModal = false;
    this.pendingValue = null;
  }

  async confirmAccepted() {
    try {
      await this.updateStatus(this.pendingValue || 'Accepted');
    } catch (e) {
    } finally {
      this.closeModal();
    }
  }

  isBefore(a, b) {
    const idxA = STEP_CONFIG.findIndex(x => x.value === a);
    const idxB = STEP_CONFIG.findIndex(x => x.value === b);
    return idxA > -1 && idxB > -1 && idxA < idxB;
  }

  extractUiApiError(e) {
    const statusCode = e?.status || e?.body?.statusCode;
    const topMessage = e?.body?.message || e?.message;

    const outputErrors = e?.body?.output?.errors;
    if (Array.isArray(outputErrors) && outputErrors.length) {
      const first = outputErrors[0];
      return {
        statusCode,
        errorCode: first?.errorCode,
        message: first?.message || topMessage
      };
    }

    const pageErrors = e?.body?.output?.pageErrors;
    if (Array.isArray(pageErrors) && pageErrors.length) {
      const first = pageErrors[0];
      return {
        statusCode,
        errorCode: first?.errorCode,
        message: first?.message || topMessage
      };
    }

    return {
      statusCode,
      errorCode: null,
      message: topMessage
    };
  }

  async updateStatus(newValue) {
    const fields = {};
    fields[ID_FIELD.fieldApiName] = this.recordId;
    fields[STATUS_FIELD.fieldApiName] = newValue;

    try {
      await updateRecord({ fields });

      this.currentStatus = newValue;
      this.selectedStatus = newValue;

      await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
      await refreshApex(this.wiredResult);

      this.toast('Success', `Status successfully updated to ${newValue}`, 'success');
    } catch (e) {
      const extracted = this.extractUiApiError(e);

      if (extracted?.errorCode === 'FIELD_CUSTOM_VALIDATION_EXCEPTION') {
        const msg = extracted.message?.includes('Eligible For Contract')
          ? 'Cannot set Quote to Accepted while any Quote Line Item is Pending. Please update products first.'
          : extracted.message;

        this.toast('Cannot update status', msg, 'error');
      }
      else {
        this.toast('Error', extracted?.message || this.reduceError(e), 'error');
      }

      await refreshApex(this.wiredResult);
      this.selectedStatus = this.currentStatus;

      throw e;
    }
  }

  toast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  reduceError(e) {
    return (
      e?.body?.message ||
      (Array.isArray(e?.body) ? e.body.map(x => x.message).join(', ') : null) ||
      e?.message ||
      'Unknown error'
    );
  }
}