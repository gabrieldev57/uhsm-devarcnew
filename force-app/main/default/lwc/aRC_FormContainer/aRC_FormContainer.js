import { LightningElement, api, track } from 'lwc';
import updateFormCompletion from '@salesforce/apex/ARC_BusinessFormController.updateFormCompletion';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

/**
 * ARC_FormContainer - Main container for the Business Application Form
 * 
 * @description Container component that holds all form sections.
 *              Each section manages its own save functionality.
 *              Receives recordId from Opportunity record page and passes to children.
 *              Automatically opens the next section when current section is saved.
 *              Tracks form completion and updates Opportunity.ARC_SalesFormCompleted__c
 */
export default class ArcFormContainer extends LightningElement {
    /** @api Record Id (Opportunity Id) from the record page */
    @api recordId;

    @track isLoading = false;

    // Header icon
    headerIconUrl = `${SGFormIcons}/cloud.svg`;

    // Define the order of sections (data-section attribute values)
    sectionOrder = ['businessDetails', 'paymentInfo' , 'primaryContact', 'ownership', 'affiliatedEntities'];

    /**
     * Handle contact update events from any section
     * Broadcasts the update to all sections so they can sync their data
     */
    handleContactUpdate(event) {
        event.stopPropagation();
        const { contactId, contactData } = event.detail;
        
        if (!contactId || !contactData) return;
        
        // Broadcast to all sections
        const allSections = this.template.querySelectorAll('[data-section]');
        allSections.forEach(section => {
            if (section.syncContactData && typeof section.syncContactData === 'function') {
                section.syncContactData(contactId, contactData);
            }
        });
    }

    /**
     * Handle company address change events from Business Details section
     * Forwards the update to Payment section
     */
    handleCompanyAddressChange(event) {
        event.stopPropagation();
        const { address } = event.detail;
        
        if (!address) return;
        
        // Forward to payment section
        const paymentSection = this.template.querySelector('[data-section="paymentInfo"]');
        if (paymentSection && typeof paymentSection.updateGroupAccountAddress === 'function') {
            paymentSection.updateGroupAccountAddress(address);
        }
    }

    /**
     * Handle save events from individual sections
     * Each section saves its own data independently
     * When a section saves successfully, open the next section and check form completion
     */
    async handleSectionSave(event) {
        const { section, isValid } = event.detail;
        
        if (isValid) {
            // If Contact Section saved successfully, refresh Payment Section contacts
            if (section === 'contacts') {
                const paymentSection = this.template.querySelector('c-a-r-c_-payment-info-section');
                if (paymentSection && paymentSection.refreshContacts) {
                    await paymentSection.refreshContacts();
                }
            }
            
            // Refresh Other Contacts list after any section save (in case roles changed)
            this.refreshOtherContacts();
            
            // Open next section
            this.openNextSection(section);
            
            // Check and update form completion status
            // Use microtask to ensure section status property is updated
            await Promise.resolve();
            this.checkFormCompletion();
        }
    }

    /**
     * Open the next section in the form flow
     * @param {String} currentSection - The data-section attribute of the current section
     */
    openNextSection(currentSection) {
        const currentIndex = this.sectionOrder.indexOf(currentSection);
        
        if (currentIndex !== -1 && currentIndex < this.sectionOrder.length - 1) {
            const nextSectionName = this.sectionOrder[currentIndex + 1];
            const nextSection = this.template.querySelector(`[data-section="${nextSectionName}"]`);
            
            if (nextSection && typeof nextSection.expand === 'function') {
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => {
                    nextSection.expand();
                }, 300);
            }
        }
    }

    /**
     * Check if all sections are complete and update Opportunity field
     */
    async checkFormCompletion() {
        if (!this.recordId) return;

        // Query all sections and check their status
        const allSections = this.template.querySelectorAll('[data-section]');
        
        
        
        const allComplete = Array.from(allSections).every(section => {
            const sectionName = section.getAttribute('data-section');
            if(sectionName != 'affiliatedEntities' && sectionName != 'ownership' ){
                return section.status === 'complete';
            }else{
                return true
            }
        });
        
        console.log('=== FORM COMPLETION STATUS ===', allComplete);

        // Update Opportunity field
        try {
            await updateFormCompletion({
                opportunityId: this.recordId,
                isComplete: allComplete
            });
            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        } catch (error) {
            console.error('Error updating form completion:', error);
        }
    }

    /**
     * Refresh Other Contacts list in Company Contact Section
     * Called after any section save to reflect role changes
     */
    refreshOtherContacts() {
        const contactSection = this.template.querySelector('[data-section="primaryContact"]');
        if (contactSection && typeof contactSection.refreshOtherContacts === 'function') {
            contactSection.refreshOtherContacts();
        }
    }
}