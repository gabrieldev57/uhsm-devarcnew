import { LightningElement, api, wire } from 'lwc';
import getSMBs from '@salesforce/apex/ARC_AuthCaseUtility.getSMBs';

export default class Arc_PreAuthSMBList extends LightningElement {
    @api recordId;

    smbs;
    error;

    columns = [
        {
            label: 'Claim Name',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' }
    ];

    @wire(getSMBs, { caseId: '$recordId' })
    wiredSMBs({ error, data }) {
        if (data) {
            this.smbs = data.map(row => ({
                ...row,
                recordUrl: '/' + row.Id
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.smbs = undefined;
        }
    }

}