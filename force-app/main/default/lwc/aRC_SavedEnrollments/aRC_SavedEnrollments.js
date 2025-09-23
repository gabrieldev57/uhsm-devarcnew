import { LightningElement, wire, track } from 'lwc';

import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import USERPROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import getSavedEnrollments from '@salesforce/apex/ARC_SavedEnrollmentsController.getSavedEnrollments';

const actions = [
    { label: 'Resume', name: 'resumeOS' },
];
const columns = [
    {
        apiFieldName: "ContractNumber",
        label: "Contract Number",
        type: "url",
        hideDefaultActions: true,
        sortable: true,
        cellAttributes: {
            alignment: "center"
        },
        fieldName: "contractIdurl",
        urlValue: "Id",
        typeAttributes: {
            label: {
                fieldName: "contractNumber"
            },
            target: "_blank",
            menuAlignment: "center"
        }
    },

    // { label: 'Contract Number', fieldName: 'contractNumber' },
    { label: 'Subscriber Name', fieldName: 'accountName', sortable: true, hideDefaultActions: true },
    { label: 'Subscriber Email', fieldName: 'accountEmail', type: 'email', sortable: true, hideDefaultActions: true },
    { label: 'Last Modified Date', fieldName: 'lastModifiedDate', hideDefaultActions: true },
    { label: 'Created Date', fieldName: 'createdDate', hideDefaultActions: true },
    { type: 'action', typeAttributes: { rowActions: actions } }
];

export default class ARC_SavedEnrollments extends NavigationMixin(LightningElement) {

    tableColumns = columns
    userId = USER_ID;
    userProfile;
    recordsPerPage = 5;
    currentPage = 1;
    data = [];
    queryMade = false;
    @track sortBy;
    @track sortDirection;
    @track searchTerm = '';

    getSavedEnrollments() {
        this.data = [];
        this.queryMade = false;
        getSavedEnrollments()
            .then((result) => {
                const dateOptions = {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric'
                };
                this.data = JSON.parse(JSON.stringify(result));
                this.data.forEach(record => {
                    record.lastModifiedDate = (new Date(record.lastModifiedDate)).toLocaleString('en-US', dateOptions);
                    record.createdDate = (new Date(record.createdDate)).toLocaleString('en-US', dateOptions);
                    record.contractIdurl = this.sfPageUrl + '/' + record.contractId;
                });
                this.queryMade = true;
            })
            .catch((error) => {
                console.log('error', error);
            });
    }


    @wire(getRecord, { recordId: USER_ID, fields: [USERPROFILE_NAME_FIELD] })
    userDetails({ error, data }) {
        if (data) {
            this.userProfile = data.fields.Profile.displayValue;
        } else if (error) {
            console.log('error', error);
        }
    }

    connectedCallback() {
        this.getSavedEnrollments();
    }


    // returns the records that will be displayed in the current page, based in the page number and the records per page
    get displayedData() {
        return this.filteredData?.slice(this.startingRecordIndex, this.endingRecordIndex + 1);
    }

    // returns the index of the first record that will be displayed in the current page
    get startingRecordIndex() {
        return (this.currentPage - 1) * this.recordsPerPage;
    }

    // returns the index of the last record that will be displayed in the current page
    get endingRecordIndex() {
        return Math.min(this.currentPage * this.recordsPerPage, this.recordsAmount) - 1;
    }

    get disablePrevious() {
        return this.currentPage <= 1;
    }

    get disableNext() {
        return this.currentPage >= this.numberOfPages;
    }

    // returns the total number of pages
    get numberOfPages() {
        return Math.ceil(this.recordsAmount / this.recordsPerPage);
    }

    get recordsAmount() {
        return this.filteredData?.length;
    }

    get columns() {
        return this.tableColumns;
    }

    get pageUrl() {
        return location.href.split('/s/')[0];
    }

    get sfPageUrl() {
        return location.href.split('/lightning/')[0];
    }

    get filteredData() {
        if (this.searchTerm === '') {
            return this.data;
        }
        return this.data.filter(record => {
            return record.contractNumber?.includes(this.searchTerm) ||
                record.accountName?.includes(this.searchTerm) ||
                record.accountEmail?.includes(this.searchTerm);
        });
    }

    get noRecords() {
        return !(this.data?.length > 0);
    }

    get noRecordsAfterQuery() {
        return this.queryMade && this.noRecords;
    }
















    handleNextPage() {
        if (this.currentPage < this.numberOfPages) {
            this.currentPage++;
        }
    }
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'resumeOS':
                this.resumeOS(row);
                break;
            default:
        }
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
        this.currentPage = 1;
    }

    handleRefresh() {
        this.currentPage = 1;
        this.getSavedEnrollments();
    }

    resumeOS(row) {
        if (this.userProfile.includes('Community')) {
            let communityPage;
            if (row.omniscriptSubType == 'Enroll') {
                communityPage = 'ifp-enrollment'
            }
            if (row.omniscriptSubType == 'Shop') {
                communityPage = 'ifp-shop'
            }

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.pageUrl + `/s/${communityPage}?vlocity_ins__sfl=true&c__layout=newport&c__instanceId=${row.instanceId}`
                }
            });

        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: this.sfPageUrl + `/lightning/cmp/vlocity_ins__vlocityLWCOmniWrapper?c__target=c:${row.omniScriptType}${row.omniScriptSubType}${row.omniScriptLanguage}&c__layout=newport&c__tabIcon=custom:custom18&c__tabLabel=Shop and Enroll&c__instanceId=${row.Id}`
                }
            });
        }
    }

    navigateToRecord(event) {
        const recordId = event.detail.row.contractId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view',
            },
        });
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData = (fieldName, direction) => {
        if (this.data) {
            let parseData = JSON.parse(JSON.stringify(this.data));

            let keyValue = (a) => {
                return a[fieldName];
            };

            let isReverse = direction === 'asc' ? 1 : -1;
            parseData.sort((x, y) => {
                if (keyValue(x) != undefined || keyValue(x) != null) {
                    if (typeof keyValue(x) === 'string') {
                        x = keyValue(x).toLowerCase();
                    } else {
                        x = keyValue(x);
                    }
                } else {
                    x = '';
                }
                if (keyValue(y) != undefined || keyValue(y) != null) {
                    if (typeof keyValue(y) === 'string') {
                        y = keyValue(y).toLowerCase();
                    } else {
                        y = keyValue(y);
                    }
                } else {
                    y = '';
                }
                if (typeof x === 'boolean' && typeof y === 'boolean') {
                    if (isReverse === 1) {
                        return (x === y) ? 0 : x ? -1 : 1;
                    } else if (isReverse === -1) {
                        return (x === y) ? 0 : x ? 1 : -1;
                    }
                } else if (typeof x === 'number') {
                    if (isReverse === 1) {
                        return x - y
                    } else if (isReverse === -1) {
                        return y - x;
                    }
                } else {
                    return isReverse * ((x > y) - (y > x));
                }
            });
            this.data = parseData;
        }
    }




}