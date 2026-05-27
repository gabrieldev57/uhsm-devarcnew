import { LightningElement, track, api } from 'lwc';
import processCensusMembersCSVCommunity from '@salesforce/apex/ARC_CensusMemberCSVController.processCensusMembersCSVCommunity';
import getCensusStatsCommunity from '@salesforce/apex/ARC_CensusMemberCSVController.getCensusStatsCommunity';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    { label: 'First Name', fieldName: 'FirstName' },
    { label: 'Last Name', fieldName: 'LastName' },
    { label: 'Gender', fieldName: 'Gender' },
    { label: 'DOB', fieldName: 'DOB' },
    { label: 'Hire Date', fieldName: 'HireDate' },
    { label: 'Job Title', fieldName: 'JobTitle' },
    { label: 'Employment Type', fieldName: 'EmploymentType' },
    { label: 'Division', fieldName: 'Division' },
    { label: 'Job Class', fieldName: 'JobClass' },
    { label: 'SSN', fieldName: 'SSN' },
    { label: 'Email', fieldName: 'Email' },
    { label: 'Phone', fieldName: 'Phone' },
    { label: 'Street', fieldName: 'Street' },
    { label: 'City', fieldName: 'City' },
    { label: 'State', fieldName: 'State' },
    { label: 'Zip Code', fieldName: 'ZipCode' }
];

export default class ARC_CensusMemberUploaderCommunity extends LightningElement {
    @api recordId; // Account Id from record context
    @track csvData = [];
    @track showPreview = false;
    @track isLoading = false;
    @track files = [];
    @track censusStats = {};
    @track validationErrors = [];
    @track isModalOpen = false;
    columns = COLUMNS;

    connectedCallback() {
        this.isModalOpen = true; // Open modal on component load
        this.loadCensusStats();
    }

    async loadCensusStats() {
        try {
            this.censusStats = await getCensusStatsCommunity();
        } catch (error) {
            console.error('Error loading census stats:', error);
        }
    }

    @api
    openModal() {
        this.isModalOpen = true;
        this.loadCensusStats();
    }

    closeModal() {
        this.isModalOpen = false;
        this.resetComponent();
        // Fire close event for parent component
        this.dispatchEvent(new CustomEvent('close'));
    }

    resetComponent() {
        this.csvData = [];
        this.showPreview = false;
        this.files = [];
        this.validationErrors = [];
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        if (!file.name.endsWith('.csv')) {
            this.showToast('Error', 'Please upload a CSV file', 'error');
            return;
        }

        this.files = [{ name: file.name }];
        this.isLoading = true;
        this.validationErrors = [];

        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const csvContent = e.target.result;
                this.parseCsv(csvContent);
            } catch (error) {
                this.showToast('Error', 'Failed to read CSV file: ' + error.message, 'error');
            } finally {
                this.isLoading = false;
            }
        };
        reader.readAsText(file);
    }

    parseCsv(csvContent) {
        const lines = csvContent.split('\n').filter(line => line.trim());
        if (lines.length < 2) {
            this.showToast('Error', 'CSV file is empty or invalid', 'error');
            return;
        }

        const headers = lines[0].split(',').map(h => h.trim());
        const data = [];

        for (let i = 1; i < lines.length; i++) {
            const values = this.parseCSVLine(lines[i]);
            if (values.length !== headers.length) continue;

            const row = {};
            headers.forEach((header, index) => {
                row[this.mapHeaderToField(header)] = values[index].trim();
            });
            data.push(row);
        }

        this.csvData = data;
        this.showPreview = data.length > 0;

        if (!this.showPreview) {
            this.showToast('Error', 'No valid data found in CSV', 'error');
        }
    }

    parseCSVLine(line) {
        const result = [];
        let current = '';
        let inQuotes = false;

        for (let i = 0; i < line.length; i++) {
            const char = line[i];
            if (char === '"') {
                inQuotes = !inQuotes;
            } else if (char === ',' && !inQuotes) {
                result.push(current);
                current = '';
            } else {
                current += char;
            }
        }
        result.push(current);
        return result;
    }

    mapHeaderToField(header) {
        const mapping = {
            'First Name': 'FirstName',
            'Last Name': 'LastName',
            'Gender': 'Gender',
            'DOB': 'DOB',
            'Hire Date': 'HireDate',
            'Job Title': 'JobTitle',
            'Employment Type': 'EmploymentType',
            'Division': 'Division',
            'Job Class': 'JobClass',
            'SSN': 'SSN',
            'Email': 'Email',
            'Phone': 'Phone',
            'Street': 'Street',
            'City': 'City',
            'State': 'State',
            'Zip Code': 'ZipCode'
        };
        return mapping[header] || header;
    }

    handleRemove() {
        this.files = [];
        this.csvData = [];
        this.showPreview = false;
        this.validationErrors = [];
    }

    handleDownloadTemplate() {
        const headers = 'First Name,Last Name,DOB,Hire Date,Job Title,Employment Type,Division,Job Class,SSN,Email,Street,City,State,Zip Code,Phone,Gender\n';
        const BOM = '\uFEFF';
        const element = document.createElement('a');
        element.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(BOM + headers);
        element.download = 'Template - Add Multiple Employees.csv';
        element.click();
    }

    async handleCreateRecords() {
        if (!this.csvData || this.csvData.length === 0) {
            this.showToast('Error', 'No data to process', 'error');
            return;
        }

        this.isLoading = true;
        this.validationErrors = [];

        try {
            // Transform data to match wrapper structure
            const membersToSave = this.csvData.map(row => ({
                firstName: row.FirstName || '',
                lastName: row.LastName || '',
                gender: row.Gender || '',
                dob: row.DOB || '',
                hireDate: row.HireDate || '',
                jobTitle: row.JobTitle || '',
                employmentType: row.EmploymentType || '',
                division: row.Division || '',
                jobClass: row.JobClass || '',
                ssn: row.SSN || '',
                email: row.Email || '',
                phone: row.Phone || '',
                street: row.Street || '',
                city: row.City || '',
                state: row.State || '',
                zipCode: row.ZipCode || ''
            }));

            const result = await processCensusMembersCSVCommunity({
                censusMembersJson: JSON.stringify(membersToSave)
            });

            if (result.errors && result.errors.length > 0) {
                this.validationErrors = result.errors;
                this.showToast('Validation Errors', 
                    `Found ${result.errors.length} error(s). Please review and correct.`, 
                    'error');
            } else {
                // Build descriptive success message
                const parts = [];
                if (result.inserted > 0) {
                    parts.push(`${result.inserted} new member(s) added`);
                }
                if (result.skipped > 0) {
                    parts.push(`${result.skipped} member(s) already exist and were skipped`);
                }
                const successMsg = parts.length > 0
                    ? parts.join(' · ')
                    : 'No changes made — all members already exist in the census';
                const toastVariant = result.inserted > 0 ? 'success' : 'info';
                
                this.showToast('Upload Complete', successMsg, toastVariant);
                
                // Refresh stats and reset
                await this.loadCensusStats();
                this.closeModal();
                
                // Fire event to refresh parent page
                this.dispatchEvent(new CustomEvent('uploadcomplete', {
                    detail: { inserted: result.inserted, skipped: result.skipped }
                }));
            }
        } catch (error) {
            console.error('Error processing CSV:', error);
            this.showToast('Error', 
                'An error occurred while processing your file: ' + (error.body?.message || error.message), 
                'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }

    get hasCensus() {
        return this.censusStats && this.censusStats.censusId;
    }

    get memberCount() {
        return this.censusStats?.memberCount || 0;
    }

    get hasErrors() {
        return this.validationErrors && this.validationErrors.length > 0;
    }

    get modalHeader() {
        return 'Add Census Members';
    }
}