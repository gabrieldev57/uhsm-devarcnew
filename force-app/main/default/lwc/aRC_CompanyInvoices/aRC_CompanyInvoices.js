import { LightningElement, api, wire } from 'lwc';
import JSZip from '@salesforce/resourceUrl/jszip';
import { loadScript } from 'lightning/platformResourceLoader';
import getInvoicesList from '@salesforce/apex/ARC_CompanyInvoicesController.getInvoicesList';

export default class ARC_CompanyInvoices extends LightningElement {
    @api recordId;
    allRecords = 0;
    pageSize = 5;
    pageNumber = 1;
    startPagination = 0;
    endPagination = 0;
    invoices = [];
    filteredInvoices = [];
    statusValue = '';
    fromDate = '';
    toDate = '';
    isLoading = true;

    zipInitialized = false;

    connectedCallback() {
        this.loadInvoices();
    }

    renderedCallback() {
        if (this.zipInitialized) return;
        this.zipInitialized = true;

        loadScript(this, JSZip);
    }

    // @wire(getInvoicesList)
    // wiredInvoices({ data, error }) {
    //     if (data) {
    //         console.log('Company Invoices => ', JSON.parse(JSON.stringify(data)));
    //         let formattedData = data.map(originalInvoice => {
    //             let invoice = {...originalInvoice}
    //             const months = [
    //                     'Jan','Feb','Mar','Apr','May','Jun',
    //                     'Jul','Aug','Sep','Oct','Nov','Dec'
    //                 ];
    //             if (invoice.Date) {
    //                 const [year, month, day] = invoice.Date.split('-');
    //                 invoice.DateFormatted = `${months[parseInt(month) - 1]} ${parseInt(day)}, ${year}`;
    //             }

    //             if (invoice.DueDate) {
    //                 const [year, month, day] = invoice.DueDate.split('-');
    //                 invoice.DueDateFormatted = `${months[parseInt(month) - 1]} ${parseInt(day)}, ${year}`;
    //             }

    //             return invoice;
    //         })

    //         this.invoices = formattedData;
    //         this.filteredInvoices = formattedData;
    //         this.statusValue = 'all';
    //         this.isLoading = false;
    //     } else if (error) {
    //         console.log('Company Invoices error => ', JSON.parse(JSON.stringify(error)));
    //         this.isLoading = false;
    //     }
    // }

    async loadInvoices() {
        console.log('Loading Invoices')

        try {
            const data = await getInvoicesList();

            if (data) {
                console.log('Company Invoices => ', JSON.parse(JSON.stringify(data)));
                let formattedData = data.map(originalInvoice => {
                    let invoice = {...originalInvoice}
                    const months = [
                            'Jan','Feb','Mar','Apr','May','Jun',
                            'Jul','Aug','Sep','Oct','Nov','Dec'
                        ];
                    if (invoice.Date) {
                        const [year, month, day] = invoice.Date.split('-');
                        invoice.DateFormatted = `${months[parseInt(month) - 1]} ${parseInt(day)}, ${year}`;
                    }

                    if (invoice.DueDate) {
                        const [year, month, day] = invoice.DueDate.split('-');
                        invoice.DueDateFormatted = `${months[parseInt(month) - 1]} ${parseInt(day)}, ${year}`;
                    }

                    return invoice;
                })

                this.invoices = formattedData;
                this.filteredInvoices = formattedData;
                this.statusValue = 'all';
                this.isLoading = false;
            }
            this.isLoading = false;
        } catch(error) {
            console.log('Error while loading invoices: ', error);
            this.isLoading = false;
        }
    }

    handleFilterChange(event){
        const filterName = event.currentTarget.name;
        const filterValue = event.currentTarget.value
        console.log('The filter applied is: ', filterName);
        console.log('Filter Value => ', filterValue);

        switch(filterName){
            case 'status':
                this.statusValue = filterValue;
                break;
            case 'fromDate':
                this.fromDate = filterValue;
                break;
            case 'toDate':
                this.toDate = filterValue;
                break;
        }

        // Apply filters
        this.filteredInvoices = this.getFilteredInvoices();
        
        // Update the Page Number to 1
        this.pageNumber = 1;
    }

    getFilteredInvoices() {
        let filteredInvoices = [...this.invoices];

        // Apply all filters in order
        if (this.statusValue && this.statusValue != 'all') {
            filteredInvoices = filteredInvoices.filter(invoice => invoice.Status.toLowerCase() == this.statusValue);
        }

        if (this.fromDate) {
            filteredInvoices = filteredInvoices.filter(invoice => invoice.Date >= this.fromDate);
        }

        if (this.toDate) {
            filteredInvoices = filteredInvoices.filter(invoice => invoice.Date <= this.toDate);
        }

        return filteredInvoices;
    }

    findInvoice(invoiceId) {
        return this.invoices.find(invoice => invoice.Id === invoiceId);
    }

    // handlePreviewInvoice(event) {
    //     const url = event.currentTarget.dataset.url;
    //     window.open(url, '_blank');
    // }

    handlePreviewInvoice(event) {
        const invoiceId = event.currentTarget.dataset.invoiceId;

        if (!invoiceId) {
            console.log('No invoice Id found for preview');
            return;
        }

        const currentPath = window.location.pathname;
        let communityBasePath = '';

        if (currentPath.includes('/s/')) {
            communityBasePath = currentPath.substring(0, currentPath.indexOf('/s/') + 2);
        }

        const previewUrl = `${window.location.origin}${communityBasePath}/invoice-preview?invoiceId=${encodeURIComponent(invoiceId)}`;

        window.open(previewUrl, '_blank');
    }

    handleDownloadInvoice(event) {
        const invoiceId = event.currentTarget.dataset.invoiceId;
        console.log('Invoice Id Selected => ', invoiceId);

        const invoice = this.findInvoice(invoiceId)
        console.log('Invoice Selected => ', invoice);

        const byteCharacters = atob(invoice.base64Data);
        const byteNumbers = new Array(byteCharacters.length);

        for (let i = 0; i < byteCharacters.length; i++) {
            byteNumbers[i] = byteCharacters.charCodeAt(i);
        }

        const byteArray = new Uint8Array(byteNumbers);
        const blob = new Blob([byteArray], { type: 'application/pdf' });

        const url = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = invoice.fileName;

        link.click();

        URL.revokeObjectURL(url);
    }

    handleExportAllInvoices() {
        console.log('Export all invoices');

        const zip = new window.JSZip();

        this.invoices.forEach(file => {
            zip.file(file.fileName, file.base64Data, { base64: true });
        });

        zip.generateAsync({ type: "blob" })
        .then(content => {

            const link = document.createElement('a');
            link.href = URL.createObjectURL(content);
            link.download = 'UHSM Invoices.zip';
            link.click();
        });
    }

    
    get statusesOptions() {
        return [
            { label: 'All Statuses', value: 'all' },
            { label: 'Paid', value: 'paid' },
            { label: 'Pending', value: 'pending' },
            { label: 'Overdue', value: 'overdue' }
        ];
    }

    get hasInvoices() {
        return this.filteredInvoices.length > 0;
    }

    get totalPages() {
        return Math.ceil(this.filteredInvoices.length / this.pageSize);
    }

    get paginatedData() {
        let start = (this.pageNumber - 1) * this.pageSize;
        this.startPagination = start + 1;
        this.endPagination = Math.min(this.pageNumber * this.pageSize, this.filteredInvoices.length);
        return this.filteredInvoices.slice(start, this.endPagination);
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
        }
    }

    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
        }
    }
}