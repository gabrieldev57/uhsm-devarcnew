import { LightningElement, api } from 'lwc';
import getGroupClassFromOpportunity from '@salesforce/apex/aRC_employerContributionController.getGroupClassFromOpportunity';
import initRenewalGroupClasses from '@salesforce/apex/aRC_employerContributionController.initRenewalGroupClasses';

export default class ARC_employerContributionWizard extends LightningElement {
  @api recordId;

  currentScreen = 'CREATION';
  refreshKey = `${Date.now()}`;

  isLoading = true;

  async connectedCallback() {
    this.isLoading = true;
    await this.initScreen();
    this.isLoading = false;
  }

  async initScreen() {
    if (!this.recordId) {
      this.currentScreen = 'CREATION';
      return;
    }

    try {
      await initRenewalGroupClasses({ opportunityId: this.recordId });

      const res = await getGroupClassFromOpportunity({
        opportunityId: this.recordId,
        cacheBuster: this.refreshKey
      });

      const list = res?.groupClases || res?.groupClasses || [];
      const exists = (list?.length || 0) > 0;

      this.currentScreen = exists ? 'CONFIG' : 'CREATION';

      if (exists) this.refreshKey = `${Date.now()}`;
    } catch (e) {
      this.currentScreen = 'CREATION';
    }
  }

  get showCreation() {
    return this.currentScreen === 'CREATION';
  }

  get showConfiguration() {
    return this.currentScreen === 'CONFIG';
  }

  handleCreated() {
    this.refreshKey = `${Date.now()}`;
    this.currentScreen = 'CONFIG';
  }

  handleChangeGroupClasses() {
    this.refreshKey = `${Date.now()}`;
    this.currentScreen = 'CREATION';
  }
}