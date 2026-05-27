import { LightningElement, wire, api } from 'lwc';
import canEdit from '@salesforce/apex/ARC_CompanyDetailsController.canEdit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveCompanyAndPBC from '@salesforce/apex/ARC_CompanyDetailsController.saveCompanyAndPBC';
import { refreshApex } from '@salesforce/apex'; // Import refreshApex
//import loadCompanyContacts from '@salesforce/apex/ARC_CompanyDetailsController.loadCompanyContacts';
//import deactivateUsers from '@salesforce/apex/ARC_ContactWithUserController.deactivateUsers';
import loadCompanyContactsWithUsers from '@salesforce/apex/ARC_CompanyDetailsController.loadCompanyContactsWithUsers';
//import updateContactsWithUser from '@salesforce/apex/ARC_CompanyDetailsController.updateContactsWithUser';
import requestContactDeletion from '@salesforce/apex/ARC_CompanyDetailsController.requestContactDeletion';

export default class ARC_CompanyDetails extends LightningElement {
    @api recordId;
    @api isReadOnly;
    isEdit = false;
    showView = true;
    isSaving = false;
    canEdit = false;

    fullContactList;

    // Primary Business Contact variables
    wiredContactResult;
    acrs = []; //acrs stands for Account Contact Relations
    primaryBusinessContact;
    //

    //Company Officer Contact variables
    companyOfficerContacts = [];
    //

    //Third Party Admin variables
    thirdPartyAdministrators = [];
    //

    //Other Contact variables
    otherContacts = [];
    //

    connectedCallback (){
        this.loadPermissions();
    }

    @api
    getDraftForSave() {
        return {
            newTPAContacts: this.newTPADrafts,
            newOtherContacts: this.newOtherContactDrafts
        };
    }

    @wire(loadCompanyContactsWithUsers)
    wiredContact(result) {
        this.wiredContactResult = result;
        const {data, error} = result;
        if (data && data.acrs) {
            this.acrs = data.acrs; 
            this.splitContactsByRole();
        } else if (error) {
            console.error('Error loading contact data', error);
        }
    }

    // @wire(loadCompanyContacts)
    // wiredContact(result) {
    //     this.wiredContactResult = result;
    //     const {data, error} = result;
    //     if (data) {
    //         this.acrs = data.acrs;
    //         this.splitContactsByRole();
    //     } else if (error) {
    //         console.error('Error loading contact data', error);
    //     }
    // }

    normalizeRoles(roles){
        if (!roles) return [];
        if (Array.isArray(roles)) return roles;
        return roles.split(';').map(r => r.trim()).filter(Boolean);
    }

    //Split contacts
    splitContactsByRole(){
        this.fullContactList = this.acrs;
        this.primaryBusinessContact = null;
        this.companyOfficerContacts = [];
        this.thirdPartyAdministrators = [];
        this.otherContacts = [];

        this.acrs.forEach(acr => {
            
            // const acrCopy = { ...acr };
            // acrCopy.hasUser = acr.HasUser__c || false;
            console.log('Contact:', acr.Contact?.FirstName, acr.Contact?.LastName, 'hasUser:', acr.hasUser, 'Roles:', acr.Roles);

            const roles = this.normalizeRoles(acr.Roles);
            const isPBC = roles.includes('Primary Business Contact');
            const isCO  = roles.includes('Company Officer Contact');
            const isTPA = roles.includes('Third Party Administrator');


            if (isPBC) {
                this.primaryBusinessContact = acr;
            }
    
            if (isCO) {
                this.companyOfficerContacts.push(acr);
            }
    
            if (isTPA) {
                this.thirdPartyAdministrators.push(acr);
            }
    
            if (!isPBC && !isCO && !isTPA) {
                this.otherContacts.push(acr);
            }
        });
    }

    editButtonHandle() {
        this.isEdit = !this.isEdit;
    }

    cancelButtonHandle() {
        // Exit edit mode → children will rollback via isEdit setter
        this.showView = true;
        this.isEdit = false; //As this is the main LWC, this component should control the state of isEdit and muy updated explicity.

        this.template.querySelectorAll('[data-contact-section="true"]').forEach(cmp => {
            if (cmp.resetToOriginal) cmp.resetToOriginal();
        });

        console.log("in cancelButton - showView: ", this.showView);
        console.log("in cancelButton - isEdit: ", this.isEdit);
    }

    @api
    validateRoles() {
        return this.hasPrimaryRoleSelected;
    }

    async saveButtonHandle() {
        this.isSaving = true;
        try {
            //Get all child LWCs that will be editable
            const sections = [
                ...this.template.querySelectorAll('[data-section="editable"]')
            ];

            //Validate inputs
            for(const section of sections){
                if (section.validateInputs && !section.validateInputs()){
                    this.isSaving = false;
                    return;
                }
            }
            /* -------------------------
            RECOLECT CHILD LWC
            -------------------------- */
            const companyDetailsComponent = this.template.querySelector('c-a-r-c_-company-details_-company-details');
            const primaryBusinessContact = this.template.querySelector('c-a-r-c_-company-details_-company-point-of-contact');

            if (!companyDetailsComponent || !primaryBusinessContact) {
                throw new Error('Required child component not found');
            }

            /* -------------------------
            RECOLECT CONTACT DRAFTS
            -------------------------- */
            const contactSections = [
                this.template.querySelector('[data-contact-section="true"]')
            ];

            let contactPayload = {
                creates: [],
                updates: [],
                deletes: []
            };

            const contactsWithUsers = [];

            let hasValidationError = false;

            contactSections.forEach(section => {
                if (section?.getDraftForSave){
                    const draft = section.getDraftForSave();

                    if (!draft || draft.isValid === false){
                        hasValidationError = true;
                        return;
                    }

                    contactPayload.creates.push(...(draft.create || []));
                    contactPayload.updates.push(...(draft.update || []));
                    //contactPayload.deletes.push(...(draft.delete || []));

                    for(const del of (draft.delete || [])){
                        if(del.contactId && del.hasUser){
                            contactsWithUsers.push(del.contactId);
                        }else{
                            contactPayload.deletes.push(del);
                        }
                    }
                   
                }
            });
            //fix to bug-3534
            if (contactsWithUsers.length > 0) {
                // const contactsToFlag = contactsWithUsers.map(contactId => ({
                //     Id: contactId,
                //     ARC_TriggerUserDeactivation__c: true
                // }));

                try {
                    for(const contactId of contactsWithUsers){
                        await requestContactDeletion({ contactId: contactId });
                    }
                    
                    console.log('Deletion requested for:', contactsWithUsers.length, 'contacts');


                    // await updateContactsWithUser({ contacts: contactsToFlag });
                    // console.log('Contacts flagged for deactivation:', contactsToFlag.length);
                    
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Deletion Initiated',
                            message: `${contactsWithUsers.length} contact(s) queued for user deactivation and deletion.`,
                            variant: 'info'
                        })
                    );
                } catch (error) {
                    console.error('Error flagging contacts:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Could not flag contacts for deactivation',
                            variant: 'error'
                        })
                    );
                }
            }
            //end of fix to bug-3534
            
            
            if (hasValidationError) {
                return;
            }
            
            const finalDraft = this.getDraftForSave();
            console.log('FINAL DRAFT SENT', JSON.parse(JSON.stringify(finalDraft)));

            /* -------------------------
            ARMAR PAYLOAD
            -------------------------- */
            const payload = {
                company: companyDetailsComponent.getFieldValues(),
                primaryBusinessContact: primaryBusinessContact.getDraftForSave(),
                contacts: contactPayload
            };
            console.log('SAVE PAYLOAD →', JSON.stringify(payload, null, 2));
            
            /* -------------------------
            SAVE REAL (APEX)
            -------------------------- */
            await saveCompanyAndPBC({ payloadJson: JSON.stringify(payload) });
            
            await refreshApex(this.wiredContactResult);
            this.splitContactsByRole();
            /* -------------------------
            COMMIT ONLY AFTER SUCCESS
            -------------------------- */
            primaryBusinessContact.commitSavedState();//Commit only the LWCs that required a commit
            //companyDetailsComponent.commitSavedState();

            /* -------------------------
            CONFIRM SAVE IN CHILD LWC
            -------------------------- */
            sections.forEach(section => {
                if (typeof section.confirmSave === 'function') {
                    section.confirmSave();
                }
            });
             /* -------------------------
            EXIT FROM EDIT MODE
            -------------------------- */
            this.isEdit = false;
            this.showView = true;
            

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Company Details were successfully saved.',
                    variant: 'success'
                })
            );
            const companyChild = this.template.querySelector(
                '[data-id="editable-company-details"]'
            );
            
            if (companyChild?.refreshData) {
                companyChild.refreshData();
            }
        } catch(error){
            console.error("Error saving: ", error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'An error occurred while saving the information',
                    variant: 'error'
                })
            );
            this.resetToOriginalState(); //Reset all values as they were bofere the issue found.
            refreshApex(this.wiredContactResult);
            this.splitContactsByRole();
        } finally {
            this.isSaving = false;
        }   
    }

    async loadPermissions(){
        try {
            this.canEdit = await canEdit();
        } catch (e) {
            console.error(e);
            this.canEdit = false;
        }
    }

    resetToOriginalState() {
        this.isEdit = false;
    
        // Refresh data from server
        // Execute again both wire alreadt cached.
        return Promise.all([
            refreshApex(this.wiredEmployerResult),
            refreshApex(this.primaryBusinessContactWire)
        ]);
    }

}