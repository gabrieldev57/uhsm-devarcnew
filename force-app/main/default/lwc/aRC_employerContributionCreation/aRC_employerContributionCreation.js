import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getGroupClassPreview from '@salesforce/apex/aRC_employerContributionController.getGroupClassPreview';
import createGroupClassesAndAssignMembers from '@salesforce/apex/aRC_employerContributionController.createGroupClassesAndAssignMembers';

export default class ARC_employerContributionCreation extends LightningElement {
  @api recordId;

  step = 1;
  loading = false;

  segmentationMode = 'NONE';
  includeEmptyChoice = 'EXCLUDE_EMPTY';

  expectedRows = [];
  emptyLabels = [];
  unknownCount = 0;

  showInvalidEmployeesMessage = false;
  noCensus = false;

  get isStep1() { return this.step === 1; }
  get isStep2() { return this.step === 2; }
  get isStep3() { return this.step === 3; }

  get showContinueTop() { return this.isStep1; }

  get isFTPT() { return this.segmentationMode === 'FT_PT'; }
  get isExempt() { return this.segmentationMode === 'EXEMPT'; }
  get isCombined() { return this.segmentationMode === 'COMBINED'; }
  get isNone() { return this.segmentationMode === 'NONE'; }

  get hasInvalidEmployees() {
    return this.showInvalidEmployeesMessage && (this.unknownCount || 0) > 0;
  }

  get hasNoCensus() {
    return this.noCensus === true;
  }

  get disableContinue() {
    return this.loading || this.hasNoCensus;
  }

  get disableConfirmAndCreate() {
    return this.loading || this.hasInvalidEmployees || this.hasNoCensus;
  }

  cardClass(val) {
    const base = 'optionCard';
    return this.segmentationMode === val ? `${base} selected` : base;
  }
  get cardClassFTPT() { return this.cardClass('FT_PT'); }
  get cardClassExempt() { return this.cardClass('EXEMPT'); }
  get cardClassCombined() { return this.cardClass('COMBINED'); }
  get cardClassNone() { return this.cardClass('NONE'); }

  handleCardClick = (e) => {
    const val = e.currentTarget?.dataset?.value;
    if (val) this.segmentationMode = val;
  };

  handleRadioChange = (e) => {
    const val = e.target?.dataset?.value;
    if (val) this.segmentationMode = val;
  };

  handleCancel = () => {
    this.resetWizard();
  };

  goStep1 = () => {
    this.showInvalidEmployeesMessage = false;
    this.unknownCount = 0;
    this.step = 1;
  };

  goStep2 = () => {
    this.step = 2;
  };

  resetWizard() {
    this.step = 1;
    this.loading = false;

    this.segmentationMode = 'COMBINED';
    this.includeEmptyChoice = 'EXCLUDE_EMPTY';

    this.expectedRows = [];
    this.emptyLabels = [];
    this.unknownCount = 0;

    this.showInvalidEmployeesMessage = false;
    this.noCensus = false;
  }

  handleContinue = async () => {
    if (!this.recordId) {
      this.toastError('Missing opportunity recordId.');
      return;
    }

    this.loading = true;
    try {
      const result = await getGroupClassPreview({
        opportunityId: this.recordId,
        segmentationMode: this.segmentationMode
      });

      this.noCensus = result?.hasCensus === false;

      if (this.noCensus) {
        this.expectedRows = [];
        this.emptyLabels = [];
        this.unknownCount = 0;
        this.showInvalidEmployeesMessage = false;
        this.step = 1;
        return;
      }

      this.expectedRows = result?.rows || [];
      this.emptyLabels = result?.emptyClassLabels || [];
      this.unknownCount = result?.unknownCount || 0;

      this.showInvalidEmployeesMessage = false;
      this.step = 2;
    } catch (e) {
      this.toastError(this.normalizeError(e));
    } finally {
      this.loading = false;
    }
  };

  handleConfirmAndValidate = async () => {
    if (!this.recordId) {
      this.toastError('Missing opportunity recordId.');
      return;
    }

    this.loading = true;
    try {
      const result = await getGroupClassPreview({
        opportunityId: this.recordId,
        segmentationMode: this.segmentationMode
      });

      if (!result) {
        this.toastError('No data returned.');
        return;
      }

      this.noCensus = result?.hasCensus === false;
      if (this.noCensus) {
        this.step = 1;
        return;
      }

      this.expectedRows = result.rows || [];
      this.emptyLabels = result.emptyClassLabels || [];
      this.unknownCount = result.unknownCount || 0;

      if ((this.unknownCount || 0) > 0 && this.segmentationMode !== 'NONE') {
        this.showInvalidEmployeesMessage = true;
        this.step = 2;
        return;
      }

      this.showInvalidEmployeesMessage = false;

      if ((this.emptyLabels || []).length > 0 && this.segmentationMode !== 'NONE') {
        this.includeEmptyChoice = 'EXCLUDE_EMPTY';
        this.step = 3;
        return;
      }

      await this.handleCreate();
    } catch (e) {
      this.toastError(this.normalizeError(e));
    } finally {
      this.loading = false;
    }
  };

  get hasEmptyClasses() {
    return (this.emptyLabels || []).length > 0;
  }

  get emptyLabelsText() {
    return (this.emptyLabels || []).join(', ');
  }

  get includeAll() { return this.includeEmptyChoice === 'INCLUDE_EMPTY'; }
  get excludeEmpty() { return this.includeEmptyChoice === 'EXCLUDE_EMPTY'; }

  get includeAllClass() { return this.includeAll ? 'optionCard selected' : 'optionCard'; }
  get excludeEmptyClass() { return this.excludeEmpty ? 'optionCard selected' : 'optionCard'; }

  handleIncludeEmptyClick = (e) => {
    const val = e.currentTarget?.dataset?.value;
    if (val) this.includeEmptyChoice = val;
  };

  handleIncludeEmptyChange = (e) => {
    const val = e.target?.dataset?.value;
    if (val) this.includeEmptyChoice = val;
  };

  get rowsToCreateInWarning() {
    const rows = this.expectedRows || [];
    if (this.includeEmptyChoice === 'INCLUDE_EMPTY') return rows;
    return rows.filter(r => (r.memberCount || 0) > 0);
  }

  handleCreate = async () => {
    if (!this.recordId) {
      this.toastError('Missing opportunity recordId.');
      return;
    }

    this.loading = true;
    try {
      const res = await createGroupClassesAndAssignMembers({
        req: {
          opportunityId: this.recordId,
          segmentationMode: this.segmentationMode,
          includeEmptyChoice: this.includeEmptyChoice
        }
      });

      this.dispatchEvent(new ShowToastEvent({
        title: 'Success',
        message: res?.message || 'Group Classes created and Census Members assigned.',
        variant: 'success'
      }));

      this.dispatchEvent(new CustomEvent('created', { bubbles: true, composed: true }));

      this.resetWizard();
    } catch (e) {
      this.toastError(this.normalizeError(e));
    } finally {
      this.loading = false;
    }
  };

  toastError(message) {
    this.dispatchEvent(new ShowToastEvent({
      title: 'Error',
      message,
      variant: 'error'
    }));
  }

  normalizeError(e) {
    return e?.body?.message || e?.message || 'Unknown error';
  }
}