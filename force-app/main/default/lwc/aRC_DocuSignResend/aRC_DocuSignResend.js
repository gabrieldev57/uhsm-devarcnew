import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

// import sendCompositeEnvelope from '@salesforce/apex/ARC_DocuSignApi.sendCompositeEnvelope';


export default class aRC_DocuSignResend extends OmniscriptBaseMixin(LightningElement) {

    @api recordId;
    @api enableComponent = false;
    @api showSelect = false;
    @api disableButton = false;
    @api disableSelectRecipient = false;
    @api message;
    @api recipients = [];
    @api allRecipients = [];
    @api selectedRecipient;
    @api selectedRecipientId;
    @api dependentCount;
    @api signerList = [];
    @api templateIds = [];
    @api envelopeSubject;
    @api docuSignTabs;
    @api oldEnvelopeId;
    @api validData = false;

    async connectedCallback() {

        console.log("contractId in ConnectedCallBack: " + this.recordId);

        this.enableComponent = true;
        this.disableButton = true;
        this.message = 'Loading recipients...';

        await this.getHipaaRecipientList();
        await this.getAllRecipientList();

        this.selectedRecipient =
            this.recipients?.find(r => r.recipientRole === "Primary") != null 
            ? this.recipients?.find(r => r.recipientRole === "Primary") 
            : this.recipients?.find(r => (r.recipientRole === "Legal Guardian" || r.recipientRole === "Parent")) != null
            ? this.recipients?.find(r => (r.recipientRole === "Legal Guardian" || r.recipientRole === "Parent"))
            : this.recipients?.find(r => (r.recipientRole === "Other"));
        if (this.selectedRecipient) {
            this.selectedRecipientId = this.selectedRecipient.recipientId;
            await this.getDocuSignData();
        }

        console.log('this.disableSelectRecipient', this.disableSelectRecipient);
        
        console.log('Recipient Email: ' + this.selectedRecipient?.recipientEmail);


        
        if (!this.disableButton && this.selectedRecipientId) {
            this.message = 'Email will be sent to: ' + this.selectedRecipient?.recipientEmail;
        }
    }

    async getAllRecipientList() {
        try {
            this.disableButton = true;
            this.message = 'Getting recipient list...'; 

            let response = await this.omniRemoteCall({
                input: {
                    "contractId": this.recordId
                },
                sClassName: 'ARC_DocuSignResendController',
                sMethodName: 'getAllRecipientList',
                options: '{}'
            }, true)

            console.log('getRecipientList Response:', response);
            this.allRecipients = response.result.allRecipients.map(recipient => {
                return {
                    label: recipient.recipientName + ' - ' + recipient.recipientEmail,
                    value: recipient.recipientId,
                    recipientId: recipient.recipientId,
                    recipientRole: recipient.recipientRole,
                    recipientName: recipient.recipientName,
                    recipientEmail: recipient.recipientEmail,
                    recipientPhone: recipient.recipientPhone,
                    recipientAge: recipient.recipientAge
                };
            });
            this.dependentCount = response.result.allRecipients.filter(recipient => recipient.recipientRole === 'Child').length;
            console.log('dependent count in getAllRecipientList:', this.dependentCount);

            if (this.allRecipients.length > 0) {
                this.disableButton = false;
                this.showSelect = true;
            } else {
                this.disableButton = true;
                this.showSelect = false;
                this.message = 'No recipients were found to resend the envelope.';
            }
            
        } catch (error) {
            console.error('Error:', error);
            this.message = 'Unexpected error occurred';
        }
    }

    async getHipaaRecipientList() {
        try {
            this.disableButton = true;
            this.message = 'Getting recipient list...'; 
            console.log('getHipaaRecipientList Initial');
            let response = await this.omniRemoteCall({
                input: {
                    "contractId": this.recordId
                },
                sClassName: 'ARC_DocuSignResendController',
                sMethodName: 'getHipaaRecipientList',
                options: '{}'
            }, true)

            console.log('getHipaaRecipientList Response:', response);
            this.recipients = response.result.recipients.map(recipient => {
                return {
                    label: recipient.recipientName + ' - ' + recipient.recipientEmail,
                    value: recipient.recipientId,
                    recipientId: recipient.recipientId,
                    recipientRole: recipient.recipientRole,
                    recipientName: recipient.recipientName,
                    recipientEmail: recipient.recipientEmail,
                    recipientPhone: recipient.recipientPhone,
                    recipientAge: recipient.recipientAge
                };
            });

            if (this.recipients.length > 0) {
                this.disableButton = false;
                this.showSelect = true;
            } else {
                this.disableButton = true;
                this.showSelect = false;
                this.message = 'No recipients were found to resend the envelope.';
            }
            
        } catch (error) {
            console.error('Error:', error);
            this.message = 'Unexpected error occurred';
        }
    }

    async getDocuSignData() {
        try {
            this.disableButton = true;
            this.message = 'Getting required information...'; 

            console.log('Selected Recipient in getDocuSignData: ' + this.selectedRecipient);

            console.log('contractId', this.recordId);
            console.log('selectedRecipient', this.selectedRecipient);
            console.log('allRecipients', this.allRecipients);
            console.log('dependentCount', this.dependentCount);
            let response = await this.omniRemoteCall({
                input: {
                    "contractId": this.recordId,
                    "selectedRecipient": this.selectedRecipient,
                    "allRecipients": this.allRecipients,
                    "dependentCount": this.dependentCount
                },
                sClassName: 'ARC_DocuSignResendController',
                sMethodName: 'getDocuSignData',
                options: '{}'
            }, true);

            console.log('getDocuSignData Response:', response?.result);

            this.validData = response?.result?.error == 'OK' ? true : false;
            
            this.signerList = response.result.signerList;
            this.templateIds = response.result.templateIdList;
            this.envelopeSubject = response.result.subject != null ? response.result.subject : 'Testing Resend';
            this.docuSignTabs = response.result.docuSignTabs?.tabs != null ? response.result.docuSignTabs.tabs : null;
            console.log ('DocuSign Tabs in getDocuSignData: ' + this.docuSignTabs);
            this.oldEnvelopeId = response.result.envelopeId ? response.result.envelopeId : null;

            console.log('this.disableSelectRecipient async', response.result.isPrimaryChange);
            this.disableSelectRecipient = response.result.isPrimaryChange === true ? true : false;
            this.disableButton = false;

        } catch (error) {
            console.error('Error:', error);
            this.message = 'Unexpected error occurred';
        }
    }


    handleChange(event) {
        const selectedValue = event.detail.value;

        // Find full object from your mapped recipients list
        this.selectedRecipient = this.recipients.find(recipient => recipient.value === selectedValue);
        this.selectedRecipientId = this.selectedRecipient.recipientId;

        console.log('Selected recipient:', this.selectedRecipient?.recipientName);

        this.message = 'Email will be sent to: ' + this.selectedRecipient?.recipientEmail;
    }

    async resendEnvelopeHandler() {
        await this.getDocuSignData();

        if (this.validData) {
            await this.voidOldEnvelope();
            await this.resendEnvelope();
        } else {
            this.message = 'Error while trying to fetch the required data.';
        }
        
    }

    async resendEnvelope() {
        this.disableButton = true;
        this.sendingEnvelope = true;
        this.message = 'Sending Envelope...';

        try {
            let response = await this.omniRemoteCall({
                input: {
                    subject: this.envelopeSubject,
                    signerList: JSON.stringify(this.signerList),
                    templateIdList: JSON.stringify(this.templateIds),
                    tabs: JSON.stringify(this.docuSignTabs),
                    contractId: this.recordId
                },
                sClassName: 'ARC_DocuSignApi',
                sMethodName: 'sendCompositeEnvelopeInvocable',
                options: '{}'
            }, true);

            console.log('resendEnvelope Response:', response);

            this.getUpdatedEnvelopeId();

        } catch (error) {
            console.error('Error:', error);
            this.message = 'Error sending envelope';
        }
    }

    async getUpdatedEnvelopeId() {
        const PULL_INTERVAL = 10000; // 10 seconds
        const MAX_DURATION = 60000; // 60 seconds timeout

        let elapsed = 0;

        this.message = 'Waiting for DocuSign response...';

        const intervalId = setInterval(async () => {
            elapsed += PULL_INTERVAL;

            try {
                let response = await this.omniRemoteCall({
                    input: {
                        contractId: this.recordId
                    },
                    sClassName: 'ARC_DocuSignResendController',
                    sMethodName: 'getNewEnvelopeId',
                    options: '{}'
                }, true);

                console.log('Getting envelope Id response:', response);

                let envelopeId = response?.result?.envelopeId;

                if (envelopeId != this.oldEnvelopeId) {
                    this.message = 'Envelope sent and contract updated successfully';

                    clearInterval(intervalId);
                    this.disableButton = false;
                    this.sendingEnvelope = false;
                    return;
                }

                if (elapsed >= MAX_DURATION) {
                    this.message = 'Envelope cannot be sent. Please try again later.';
                    clearInterval(intervalId);
                    this.disableButton = false;
                    this.sendingEnvelope = false;
                }

            } catch (error) {
                console.error('Polling error:', error);
                this.message = 'Error checking envelope status';

                clearInterval(intervalId);
                this.disableButton = false;
                this.sendingEnvelope = false;
            }

        }, PULL_INTERVAL);
    }

    async voidOldEnvelope() {
        if (this.oldEnvelopeId != null) {
            try {
                let response = await this.omniRemoteCall({
                    input: {
                        oldEnvelopeId: this.oldEnvelopeId
                    },
                    sClassName: 'ARC_DocuSignResendController',
                    sMethodName: 'voidOldEnvelope',
                    options: '{}'
                }, true);

            } catch (error) {
                console.error('Error:', error);
                this.message = 'Error voiding old envelope';
            }
        }
    }

}