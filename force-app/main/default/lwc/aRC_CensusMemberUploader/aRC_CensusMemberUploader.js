import { LightningElement, track, api } from 'lwc';
import processCensusMembersCSV from '@salesforce/apex/ARC_CensusMemberCSVController.processCensusMembersCSV';
import getCensusStats from '@salesforce/apex/ARC_CensusMemberCSVController.getCensusStats';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

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

export default class ARC_CensusMemberUploader extends LightningElement {
    @api recordId;
    @track csvData = [];
    @track showPreview = false;
    @track isLoading = false;
    @track files = [];
    @track censusStats = {};
    @track validationErrors = [];
    columns = COLUMNS;

    connectedCallback() {
        this.loadCensusStats();
    }

    async loadCensusStats() {
        try {
            this.censusStats = await getCensusStats({ oppId: this.recordId });
        } catch (error) {
            console.error('Error loading census stats:', error);
        }
    }

    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        if (!file.name.toLowerCase().endsWith('.csv')) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Invalid File Type',
                message: 'Please upload a CSV file only.',
                variant: 'error'
            }));
            return;
        }
        
        this.isLoading = true;
        this.files = [file];
        this.validationErrors = [];
        const reader = new FileReader();
        reader.onload = () => this.parseCSV(reader.result);
        reader.readAsText(file);
    }

    handleRemove(event) {
        const fileName = event.currentTarget.dataset.name;
        this.files = this.files.filter(file => file.name !== fileName);
        this.showPreview = false;
        this.csvData = [];
    }

    parseCSV(csv) {
        const lines = csv.split('\n').filter(line => line.trim() !== '');
        
        if (lines.length === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'CSV file is empty.',
                variant: 'error'
            }));
            this.isLoading = false;
            return;
        }

        const headers = this.parseCSVLine(lines[0]);
        
        // Validate required headers
        const requiredHeaders = ['First Name', 'Last Name', 'SSN'];
        const missingHeaders = requiredHeaders.filter(h => 
            !headers.some(header => header.toLowerCase() === h.toLowerCase())
        );
        
        if (missingHeaders.length > 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: `Missing required columns: ${missingHeaders.join(', ')}`,
                variant: 'error'
            }));
            this.isLoading = false;
            return;
        }

        this.csvData = lines.slice(1).map(line => {
            const values = this.parseCSVLine(line);
            const obj = {};
            headers.forEach((header, i) => {
                const val = values[i] ? values[i].trim() : '';
                const normalizedKey = this.normalizeHeaderKey(header);
                obj[normalizedKey] = val;
            });
            return obj;
        }).filter(row => row.FirstName || row.LastName || row.SSN);

        this.showPreview = true;
        this.isLoading = false;
    }

    normalizeHeaderKey(header) {
        if (!header || !/\s/.test(header)) return header;
        
        // Convert "First Name" -> "FirstName"
        return header.trim()
            .split(/\s+/)
            .map(part => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
            .join('');
    }

    // Helper to parse a single CSV line with quoted fields
    parseCSVLine(line) {
        const result = [];
        let current = '';
        let inQuotes = false;
        for (let i = 0; i < line.length; i++) {
            const char = line[i];
            if (char === '"' && (i === 0 || line[i - 1] !== '\\')) {
                inQuotes = !inQuotes;
            } else if (char === ',' && !inQuotes) {
                result.push(current.trim().replace(/^"|"$/g, ''));
                current = '';
            } else {
                current += char;
            }
        }
        result.push(current.trim().replace(/^"|"$/g, ''));
        return result;
    }

    async handleCreateRecords() {
        if (!this.csvData || this.csvData.length === 0) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: 'No data to process. Please upload a valid CSV file.',
                variant: 'error'
            }));
            return;
        }

        const membersToSave = this.csvData.map(member => ({
            firstName: member.FirstName,
            lastName: member.LastName,
            gender: member.Gender,
            dob: member.DOB ? this.parseDate(member.DOB) : null,
            hireDate: member.HireDate ? this.parseDate(member.HireDate) : null,
            jobTitle: member.JobTitle,
            employmentType: member.EmploymentType,
            division: member.Division,
            jobClass: member.JobClass,
            ssn: member.SSN,
            email: member.Email,
            phone: member.Phone,
            street: member.Street,
            city: member.City,
            state: member.State,
            zipCode: member.ZipCode
        }));

        this.isLoading = true;
        this.validationErrors = [];

        try {
            const result = await processCensusMembersCSV({ 
                censusMembersJson: JSON.stringify(membersToSave), 
                oppId: this.recordId 
            });

            await notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

            // Check for validation or processing errors
            if (result.errors && result.errors.length > 0) {
                this.validationErrors = result.errors;
                
                // Log technical errors to console for developers
                if (result.technicalErrors && result.technicalErrors.length > 0) {
                    console.error('=== Technical Error Details ===');
                    result.technicalErrors.forEach(err => console.error(err));
                    console.error('==============================');
                }
                
                // If no records were processed, it's a validation error
                if (result.inserted === 0 && result.updated === 0 && result.deleted === 0) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Validation Failed',
                        message: `Found ${result.errors.length} error(s). Please review and fix the issues below.`,
                        variant: 'error'
                    }));
                } else {
                    // Partial success
                    const deletedPart = result.deleted > 0 ? `, Deleted: ${result.deleted}` : '';
                    const message = `Inserted: ${result.inserted}, Updated: ${result.updated}${deletedPart}`;
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Partial Success',
                        message: `${message}. Some errors occurred. Review details below.`,
                        variant: 'warning'
                    }));
                }
                return;
            }

            // Full success
            const deletedPart = result.deleted > 0 ? `, Deleted: ${result.deleted}` : '';
            const message = `Inserted: ${result.inserted}, Updated: ${result.updated}${deletedPart}`;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success'
            }));

            // Clear form and reload stats
            this.showPreview = false;
            this.files = [];
            this.csvData = [];
            this.validationErrors = [];
            await this.loadCensusStats();

        } catch (error) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: `Error processing CSV: ${error.body?.message || error.message}`,
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    parseDate(dateStr) {
        if (!dateStr) return null;

        // Try MM/DD/YYYY
        let match = dateStr.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
        if (match) {
            const month = match[1].padStart(2, '0');
            const day = match[2].padStart(2, '0');
            return `${match[3]}-${month}-${day}`;
        }

        // Try YYYY-MM-DD (already correct format)
        if (/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
            return dateStr;
        }

        // Try MM-DD-YYYY
        match = dateStr.match(/^(\d{2})-(\d{2})-(\d{4})$/);
        if (match) {
            return `${match[3]}-${match[1]}-${match[2]}`;
        }

        // Fallback to native Date parsing
        try {
            const date = new Date(dateStr);
            return !isNaN(date.getTime()) ? date.toISOString().split('T')[0] : null;
        } catch (e) {
            console.error('Error parsing date:', dateStr);
            return null;
        }
    }

    get memberCount() {
        return this.censusStats.memberCount || 0;
    }

    get hasCensus() {
        return !!this.censusStats.censusId;
    }

    get hasErrors() {
        return this.validationErrors.length > 0;
    }
}