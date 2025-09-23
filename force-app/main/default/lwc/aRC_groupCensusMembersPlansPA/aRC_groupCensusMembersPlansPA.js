import { LightningElement, wire, api, track } from 'lwc';
import getCensusMembers from '@salesforce/apex/ARC_groupCensusMembersPlansPA.getCensusMemberPlan';

const tableColumns = [
    {
        label: 'Name', fieldName: 'idURL', minColumnWidth: 100, type: 'url',
        typeAttributes: {
            label: {
                fieldName: 'Name'
            }
        },
    },
    { label: 'Active Member', fieldName: 'Active', type: "boolean", minColumnWidth: 100 }

];

export default class ARC_groupCensusMembersPlansPA extends LightningElement {

    @api recordId;
    tableColumns = tableColumns;
    tableData = [];
    tableName = 'Group Census Member Plans';
    tableIcon = 'custom:custom14';
    loading = true;
    tableModal = false;
    modalLoading = false;

    connectedCallback() {
        this.loading = true;
        getCensusMembers({ recordId: this.recordId })
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

        getCensusMembers({ recordId: this.recordId })
            .then((response) => {
                this.tableData = response;
            })
            .catch((err) => {
                console.error(err);
            })
            .finally(() => {
                this.tableModal = e.detail.modal;
                this.loading = false;
                this.template.querySelector('c-a-r-c_-custom-table').refreshComponent();

            })
    }


}