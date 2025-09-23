import { LightningElement, api } from 'lwc';

export default class ARC_CustomTable extends LightningElement {
    @api tableicon;
    @api tabledata;
    @api tablecolumns;
    @api tablename;
    @api maxRows;
    tablemodal = false;
    modalloading = false;
    @api refreshComponent(){
        this.modalloading = false;
    }
    loading = true;
    maxRows = 10;
    //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded 


    get tableRowAmount() {
        if (this.tabledata.length > this.maxRows) {
            return this.maxRows + '+';
        }
        return this.tabledata.length;
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    openModal() {
        // to open modal set tablemodal tarck value as true
        this.tablemodal = true;
    }
    closeModal() {
        // to close modal set tablemodal tarck value as false
        this.tablemodal = false;
    }

    handleRefresh(){
        if(this.tablemodal) this.modalloading = true;
        this.dispatchEvent(new CustomEvent('refreshdata', {detail: {modal: this.tablemodal}}));
    }

    get dataToDisplay() {

        return this.maxRows ? this.tabledata.slice(0, this.maxRows) : this.tabledata;

    }
    
}