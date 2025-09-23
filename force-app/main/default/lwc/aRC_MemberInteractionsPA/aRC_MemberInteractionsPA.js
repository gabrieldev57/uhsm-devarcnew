import { LightningElement, wire, api, track } from 'lwc';
import getMemberInteractions from '@salesforce/apex/ARC_GetMemberInteractionsPA.getInteractions';

const tableColumns = [
    {
        label: 'Name', fieldName: 'idURL', type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Name'
            }
        },
    },
    { label: 'Date', fieldName: 'Date', type: "date-local" },
    { label: 'Status', fieldName: 'Status' },
    { label: 'Type', fieldName: 'Type' },
    { label: 'E123 User', fieldName: 'E123 User' },
    { label: 'Description', fieldName: 'Description' },
    { label: 'Notes', fieldName: 'Notes' },
    { label: 'Type', fieldName: 'Type' }

];

export default class ARC_MemberInteractionsPA extends LightningElement {
    @api recordId;
    tableColumns = tableColumns;
    tableData = [];
    tableName = 'Member Interaction';
    tableIcon = 'standard:tableau';
    loading = true;
    tableModal = false;
    modalLoading = false;

    connectedCallback() {
        this.loading = true;
        getMemberInteractions({ recordId: this.recordId })
            .then((response) => {
                this.tableData = response;
            })
            .catch((err) => {
                console.error(err);
            })
            .finally(() => {
                this.loading = false;
            });
    }

    handleRefresh(e) {
        if (!e.detail.modal) this.loading = true;

        getMemberInteractions({ recordId: this.recordId })
            .then((response) => {
                this.tableData = response;
            })
            .catch((err) => {
                console.error(err);
            })
            .finally(() => {
                // this.tableModal = e.detail.modal;
                // this.loading = false;
                // this.template.querySelector('c-a-r-c_-custom-table').refreshComponent();
            })
    }
}