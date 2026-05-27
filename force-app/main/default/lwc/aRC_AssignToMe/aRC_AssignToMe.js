import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import getCaseForUpdate from '@salesforce/apex/ARC_RepriceCase.getCaseForUpdate';




export default class ARC_AssignToMe extends NavigationMixin(LightningElement) {
    @track currentPageReference;
    recordId;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
    }

    async getCaseForUpdate() {

        let response = await getCaseForUpdate({ caseId: this.recordId, currentUserId: USER_ID })

        let focusedTab = await this.invokeWorkspaceAPI('getFocusedTabInfo');

        if (response['isSuccess'] == true) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Record updated successfully', variant: 'success' }));
        } else if (response['isSuccess'] == false) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Record was modified by another user, please reload the page and try again.', variant: 'error' }));
            this.closeTabAndNavigateToCaseListView(focusedTab.tabId);
            return;
        }


        if (response.caseRecord?.Owner.Type === 'User') {
            this.closeTabHandler(focusedTab.tabId)
            this.navigateToCasesListView()
        } else {
            this.closeTabAndNavigateToCaseRecord(focusedTab.tabId);
        }

    }

    connectedCallback() {
        this.recordId = this.currentPageReference.state.c__recordId;
        if (this.recordId != null) {
            this.getCaseForUpdate();
        }
    }

    renderedCallback() {
        setTimeout(() => {
            if (this.template.querySelector('lightning-spinner').click) {
                this.template.querySelector('lightning-spinner').click();
            }
        }, 1000);
    }

    navigateToCasesListView() {
        // Define the navigation parameters
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case', // The API name of the object
                actionName: 'list' // The action to be taken
            }
        });
    }

    async closeTabHandler(tabId) {
        await this.invokeWorkspaceAPI('closeTab', { tabId: tabId })
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'Case',
                actionName: 'view'
            }
        });

    }

    closeTabAndNavigateToCaseRecord(tabId) {
        this.closeTabHandler(tabId);
        this.navigateToRecord(this.recordId);
    }

    closeTabAndNavigateToCaseListView(tabId){
        this.closeTabHandler(tabId);
        this.navigateToCasesListView();
    }

    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
            const apiEvent = new CustomEvent("internalapievent", {
                bubbles: true,
                composed: true,
                cancelable: false,
                detail: {
                    category: "workspaceAPI",
                    methodName: methodName,
                    methodArgs: methodArgs,
                    callback: (err, response) => {
                        if (err) {
                            return reject(err);
                        }
                        return resolve(response);
                    }
                }
            });

            this.dispatchEvent(apiEvent);
        });
    }

}