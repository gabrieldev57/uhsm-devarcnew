import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import TYPE_OF_BUSINESS_FIELD from '@salesforce/schema/Account.ARC_TypeOfBusiness__c';
import ENTITY_TYPE_FIELD from '@salesforce/schema/Account.ARC_Entity_Type__c';
import PAY_PERIOD_FIELD from '@salesforce/schema/Account.ARC_PayPeriod__c';
import MEDICAL_LEAVE_FIELD from '@salesforce/schema/Account.ARC_MedicalLeaveAllowedMonths__c';
import WAITING_PERIOD_FIELD from '@salesforce/schema/Account.ARC_NewEmployeeWaitingPeriod__c';
import RENEWAL_MONTH_FIELD from '@salesforce/schema/Account.ARC_OtherCoverageRenewalMonth__c';
import getBusinessDetails from '@salesforce/apex/ARC_BusinessDetailsController.getBusinessDetails';
import saveBusinessDetails from '@salesforce/apex/ARC_BusinessFormController.saveBusinessDetails';
import SGFormIcons from '@salesforce/resourceUrl/SGFormIcons';

/**
 * ARC_BusinessDetailsSection - Self-contained Business Details section
 * 
 * @description Handles business details collection with its own validation and save.
 *              Can be reused independently in different contexts or controlled by parent.
 * 
 * Events:
 *   - change: Fired when any field changes { detail: { section, data } }
 *   - save: Fired after save attempt { detail: { section, data, isValid, errors } }
 */
export default class ARC_BusinessDetailsSection extends LightningElement {
    /** @api Record Id (Opportunity Id) from parent */
    @api recordId;

    @track isSaving = false;
    @track sectionStatus = 'not-started';
    @track meetsSmallEmployerError = false;
    @track typeOfBusinessOptions = [{ label: '--None--', value: '' }];
    @track organizationTypeOptions = [{ label: '--None--', value: '' }];
    @track payPeriodOptions = [{ label: '--None--', value: '' }];
    @track medicalLeaveOptions = [{ label: '--None--', value: '' }];
    @track waitingPeriodOptions = [{ label: '--None--', value: '' }];
    @track renewalMonthOptions = [{ label: '--None--', value: '' }];
    
    // Record Type Id for ARC_SmallGroup
    smallGroupRecordTypeId;
    
    // State options for company address
    stateOptions = [
        { label: '--None--', value: '' },
        { label: 'Alabama', value: 'AL' },
        { label: 'Alaska', value: 'AK' },
        { label: 'Arizona', value: 'AZ' },
        { label: 'Arkansas', value: 'AR' },
        { label: 'California', value: 'CA' },
        { label: 'Colorado', value: 'CO' },
        { label: 'Connecticut', value: 'CT' },
        { label: 'Delaware', value: 'DE' },
        { label: 'Florida', value: 'FL' },
        { label: 'Georgia', value: 'GA' },
        { label: 'Hawaii', value: 'HI' },
        { label: 'Idaho', value: 'ID' },
        { label: 'Illinois', value: 'IL' },
        { label: 'Indiana', value: 'IN' },
        { label: 'Iowa', value: 'IA' },
        { label: 'Kansas', value: 'KS' },
        { label: 'Kentucky', value: 'KY' },
        { label: 'Louisiana', value: 'LA' },
        { label: 'Maine', value: 'ME' },
        { label: 'Maryland', value: 'MD' },
        { label: 'Massachusetts', value: 'MA' },
        { label: 'Michigan', value: 'MI' },
        { label: 'Minnesota', value: 'MN' },
        { label: 'Mississippi', value: 'MS' },
        { label: 'Missouri', value: 'MO' },
        { label: 'Montana', value: 'MT' },
        { label: 'Nebraska', value: 'NE' },
        { label: 'Nevada', value: 'NV' },
        { label: 'New Hampshire', value: 'NH' },
        { label: 'New Jersey', value: 'NJ' },
        { label: 'New Mexico', value: 'NM' },
        { label: 'New York', value: 'NY' },
        { label: 'North Carolina', value: 'NC' },
        { label: 'North Dakota', value: 'ND' },
        { label: 'Ohio', value: 'OH' },
        { label: 'Oklahoma', value: 'OK' },
        { label: 'Oregon', value: 'OR' },
        { label: 'Pennsylvania', value: 'PA' },
        { label: 'Rhode Island', value: 'RI' },
        { label: 'South Carolina', value: 'SC' },
        { label: 'South Dakota', value: 'SD' },
        { label: 'Tennessee', value: 'TN' },
        { label: 'Texas', value: 'TX' },
        { label: 'Utah', value: 'UT' },
        { label: 'Vermont', value: 'VT' },
        { label: 'Virginia', value: 'VA' },
        { label: 'Washington', value: 'WA' },
        { label: 'West Virginia', value: 'WV' },
        { label: 'Wisconsin', value: 'WI' },
        { label: 'Wyoming', value: 'WY' }
    ];
    
    _sicCodeSet = false; // Track if SIC Code has been pre-selected
    _accountManagerSet = false; // Track if Account Manager has been pre-selected

    // Custom icon URL for section header
    sectionIconUrl = `${SGFormIcons}/business.svg`;
    
    // Options for Yes/No radio groups (used by aRC_RadioGroup)
    yesNoOptions = [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
    ];
    
    @track businessDetails = {
        requestedEffectiveDate: null,
        companyName: '',
        legalCompanyName: '',
        accountManagerId: null,
        accountManagerName: '',
        companyStreet: '',
        companyCity: '',
        companyState: '',
        companyZip: '',
        openEnrollmentStartDate: null,
        openEnrollmentEndDate: null,
        employeesInOtherStates: false,
        otherStates: '',
        employeesInOtherStatesCount: null,
        offerBenefitsDuringWaitingPeriod: false,
        subjectToCalCOBRA: false,
        calCOBRAEnrolleesCount: null,
        subjectToCOBRA: false,
        cobraEnrolleesCount: null,
        federalTaxId: '',
        doingBusinessAs: '',
        sicCode: '',
        sicCodeDescription: '',
        naicsCode: '',
        typeOfBusiness: '',
        otherTypeOfBusiness: '',
        dateEstablished: null,
        organizationType: '',
        otherOrganizationType: '',
        payPeriod: '',
        medicalLeaveMonths: '',
        totalEmployees: null,
        ineligibleEmployees: null,
        newEmployeeWaitingPeriod: '',
        meetsSmallEmployerDefinition: false,
        allowDependentsToEnroll: false,
        isNonProfit: 'No',
        isAssociationMember: false,
        associationName: '',
        hasOtherCoverage: false,
        carrierName: '',
        renewalMonth: '',
        employeesCovered: null
    };

    // ═══════════════════════════════════════════════════════════════════════
    // WIRE ADAPTERS
    // ═══════════════════════════════════════════════════════════════════════

    // Get Account object info to retrieve ARC_SmallGroup record type ID
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
    accountObjectInfo({ data, error }) {
        if (data) {
            const rtInfos = data.recordTypeInfos;
            this.smallGroupRecordTypeId = Object.keys(rtInfos).find(
                rtId => rtInfos[rtId].name === 'Small Group'
            );
        } else if (error) {
            console.error('Error loading Account object info:', error);
        }
    }

    @wire(getPicklistValues, { 
        recordTypeId: '$smallGroupRecordTypeId', 
        fieldApiName: TYPE_OF_BUSINESS_FIELD 
    })
    wiredTypeOfBusiness({ error, data }) {
        if (data) {
            this.typeOfBusinessOptions = [
                { label: '--None--', value: '' },
                ...data.values.map(option => ({ label: option.label, value: option.value }))
            ];
        } else if (error) {
            console.error('Error loading Type of Business picklist values:', error);
        }
    }

    @wire(getPicklistValues, { 
        recordTypeId: '$smallGroupRecordTypeId', 
        fieldApiName: ENTITY_TYPE_FIELD 
    })
    wiredEntityTypes({ error, data }) {
        if (data) {
            this.organizationTypeOptions = [
                { label: '--None--', value: '' },
                ...data.values.map(option => ({ label: option.label, value: option.value }))
            ];
        } else if (error) {
            console.error('Error loading Organization Type picklist values:', error);
        }
    }

    @wire(getPicklistValues, { 
        recordTypeId: '$smallGroupRecordTypeId', 
        fieldApiName: PAY_PERIOD_FIELD 
    })
    wiredPayPeriods({ error, data }) {
        if (data) {
            this.payPeriodOptions = [
                { label: '--None--', value: '' },
                ...data.values.map(option => ({ label: option.label, value: option.value }))
            ];
        } else if (error) {
            console.error('Error loading Pay Period picklist values:', error);
        }
    }

    @wire(getPicklistValues, { 
        recordTypeId: '$smallGroupRecordTypeId', 
        fieldApiName: MEDICAL_LEAVE_FIELD 
    })
    wiredMedicalLeaveMonths({ error, data }) {
        if (data) {
            this.medicalLeaveOptions = [
                { label: '--None--', value: '' },
                ...data.values.map(option => ({ label: option.label, value: option.value }))
            ];
        } else if (error) {
            console.error('Error loading Medical Leave Months picklist values:', error);
        }
    }

    @wire(getPicklistValues, { 
        recordTypeId: '$smallGroupRecordTypeId', 
        fieldApiName: WAITING_PERIOD_FIELD 
    })
    wiredWaitingPeriods({ error, data }) {
        if (data) {
            this.waitingPeriodOptions = [
                { label: '--None--', value: '' },
                ...data.values.map(option => ({ label: option.label, value: option.value }))
            ];
        } else if (error) {
            console.error('Error loading Waiting Period picklist values:', error);
        }
    }

    @wire(getPicklistValues, { 
        recordTypeId: '$smallGroupRecordTypeId', 
        fieldApiName: RENEWAL_MONTH_FIELD 
    })
    wiredRenewalMonths({ error, data }) {
        if (data) {
            this.renewalMonthOptions = [
                { label: '--None--', value: '' },
                ...data.values.map(option => ({ label: option.label, value: option.value }))
            ];
        } else if (error) {
            console.error('Error loading Renewal Month picklist values:', error);
        }
    }

    @wire(getBusinessDetails, { opportunityId: '$recordId' })
    wiredBusinessDetails({ error, data }) {
        if (data) {
            // Reset selection flags when data loads so fields repopulate on reopen
            this._sicCodeSet = false;
            this._accountManagerSet = false;
            
            // Populate business details from Account
            this.businessDetails = {
                ...this.businessDetails,
                requestedEffectiveDate: data.requestedEffectiveDate || null,
                companyName: data.companyName || '',
                legalCompanyName: data.legalCompanyName || '',
                accountManagerId: data.accountManagerId || null,
                accountManagerName: data.accountManagerName || '',
                companyStreet: data.companyStreet || '',
                companyCity: data.companyCity || '',
                companyState: data.companyState || '',
                companyZip: data.companyZip || '',
                openEnrollmentStartDate: data.openEnrollmentStartDate || null,
                openEnrollmentEndDate: data.openEnrollmentEndDate || null,
                employeesInOtherStates: data.employeesInOtherStates || false,
                otherStates: data.otherStates || '',
                employeesInOtherStatesCount: data.employeesInOtherStatesCount,
                offerBenefitsDuringWaitingPeriod: data.offerBenefitsDuringWaitingPeriod || false,
                subjectToCalCOBRA: data.subjectToCalCOBRA || false,
                calCOBRAEnrolleesCount: data.calCOBRAEnrolleesCount,
                subjectToCOBRA: data.subjectToCOBRA || false,
                cobraEnrolleesCount: data.cobraEnrolleesCount,
                federalTaxId: data.federalTaxId || '',
                doingBusinessAs: data.doingBusinessAs || '',
                sicCode: data.sicCode || '',
                sicCodeDescription: data.sicCodeDescription || '',
                naicsCode: data.naicsCode || '',
                typeOfBusiness: data.typeOfBusiness || '',
                otherTypeOfBusiness: data.otherTypeOfBusiness || '',
                dateEstablished: data.dateEstablished || null,
                organizationType: data.organizationType || '',
                otherOrganizationType: data.otherOrganizationType || '',
                payPeriod: data.payPeriod || '',
                medicalLeaveMonths: data.medicalLeaveMonths || '',
                totalEmployees: data.totalEmployees,
                ineligibleEmployees: data.ineligibleEmployees,
                newEmployeeWaitingPeriod: data.newEmployeeWaitingPeriod || '',
                meetsSmallEmployerDefinition: data.meetsSmallEmployerDefinition || false,
                allowDependentsToEnroll: data.allowDependentsToEnroll || false,
                isNonProfit: data.isNonProfit || 'No',
                isAssociationMember: data.isAssociationMember || false,
                associationName: data.associationName || '',
                hasOtherCoverage: data.hasOtherCoverage || false,
                carrierName: data.carrierName || '',
                renewalMonth: data.renewalMonth || '',
                employeesCovered: data.employeesCovered || null
            };
            
            // Set status based on data completeness
            if (this.isComplete()) {
                this.sectionStatus = 'complete';
            } else if (this.hasAnyData()) {
                this.sectionStatus = 'in-progress';
            } else {
                this.sectionStatus = 'not-started';
            }
        } else if (error) {
            console.error('Error loading business details:', error);
            this.sectionStatus = 'not-started';
        }
    }

    renderedCallback() {
        // Set SIC Code selection if we have data but haven't set it yet
        if (this.businessDetails.sicCode && !this._sicCodeSet) {
            const lookups = this.template.querySelectorAll('c-a-r-c_-generic-lookup');
            lookups.forEach(lookup => {
                if (lookup.label === 'SIC Code') {
                    lookup.setSelection({
                        Id: this.businessDetails.sicCode,
                        Name: this.businessDetails.sicCode,
                        Title: this.businessDetails.sicCodeDescription,
                        subtitle: this.businessDetails.sicCodeDescription,
                        record: {
                            code: this.businessDetails.sicCode,
                            description: this.businessDetails.sicCodeDescription
                        }
                    });
                    this._sicCodeSet = true;
                }
            });
        }

        // Set Account Manager selection if we have data but haven't set it yet
        if (this.businessDetails.accountManagerId && !this._accountManagerSet) {
            const lookups = this.template.querySelectorAll('c-a-r-c_-generic-lookup');
            lookups.forEach(lookup => {
                if (lookup.label === 'Account Manager' && typeof lookup.setSelection === 'function') {
                    lookup.setSelection({
                        Id: this.businessDetails.accountManagerId,
                        Name: this.businessDetails.accountManagerName
                    });
                    this._accountManagerSet = true;
                }
            });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // OPTIONS
    // ═══════════════════════════════════════════════════════════════════════

    nonProfitOptions = [
        { label: 'Yes', value: 'yes' },
        { label: 'No', value: 'no' }
    ];

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS
    // ═══════════════════════════════════════════════════════════════════════

    @api
    get status() {
        return this.sectionStatus;
    }

    get showOtherTypeOfBusiness() {
        return this.businessDetails.typeOfBusiness === 'Other';
    }

    get showOtherOrganizationType() {
        return this.businessDetails.organizationType === 'Other';
    }

    get nonProfitValue() {
        // isNonProfit is a picklist field with values like 'Yes' or 'No'
        // Convert to lowercase for consistency with radio group
        return this.businessDetails.isNonProfit ? this.businessDetails.isNonProfit.toLowerCase() : 'no';
    }

    get associationMemberValue() {
        return this.businessDetails.isAssociationMember ? 'yes' : 'no';
    }

    get showAssociationName() {
        return this.businessDetails.isAssociationMember === true;
    }

    get showOtherCoverageFields() {
        return this.businessDetails.hasOtherCoverage === true;
    }

    get showOtherStates() {
        return this.businessDetails.employeesInOtherStates;
    }

    get showCalCOBRACount() {
        return this.businessDetails.subjectToCalCOBRA;
    }

    get showCOBRACount() {
        return this.businessDetails.subjectToCOBRA;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPER METHODS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Check if all required fields are filled
     * @param {Object} data - The business details data from Apex
     * @returns {Boolean} True if all required fields have values
     */
    hasAnyData() {
        const bd = this.businessDetails;
        // Check if any field has been filled
        return bd.companyName || bd.legalCompanyName || bd.federalTaxId || bd.sicCode || 
               bd.naicsCode || bd.typeOfBusiness || bd.dateEstablished || bd.organizationType ||
               bd.payPeriod || bd.totalEmployees || bd.newEmployeeWaitingPeriod;
    }

    /**
     * Set status to in-progress when user starts editing (if not already complete)
     */
    setInProgress() {
        if (this.sectionStatus !== 'complete') {
            this.sectionStatus = 'in-progress';
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API METHODS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * @api Expand this section programmatically
     */
    @api
    expand() {
        const collapsibleSection = this.template.querySelector('c-a-r-c_-collapsible-section');
        if (collapsibleSection && typeof collapsibleSection.expand === 'function') {
            collapsibleSection.expand();
        }
    }

    @api
    getData() {
        return { ...this.businessDetails };
    }

    @api
    setData(data) {
        if (data) {
            this.businessDetails = { ...this.businessDetails, ...data };
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Validate all fields in this section
     * @returns {Object} { isValid: Boolean, errors: Array<String> }
     */
    @api
    validate() {
        // Run native field validation (shows red on fields)
        const isValid = this.reportFieldValidity();

        // Don't update status here - that's handled by isComplete()

        return {
            isValid: isValid,
            errors: []
        };
    }

    /**
     * Check if section is complete (all required fields filled)
     * This determines the section status, not whether save is allowed
     * @returns {Boolean} Whether all required fields have values
     */
    isComplete() {
        const bd = this.businessDetails;
        
        // Check all required fields (matching HTML required attributes)
        const requiredFields = [
            bd.requestedEffectiveDate,
            bd.companyName,
            bd.legalCompanyName,
            bd.companyStreet,
            bd.companyCity,
            bd.companyState,
            bd.companyZip,
            bd.openEnrollmentStartDate,
            bd.openEnrollmentEndDate,
            bd.federalTaxId,
            bd.sicCode,
            bd.naicsCode,
            bd.typeOfBusiness,
            bd.dateEstablished,
            bd.organizationType,
            bd.payPeriod,
            bd.totalEmployees,
            bd.newEmployeeWaitingPeriod,
            bd.isNonProfit
        ];
        
        // Check if all required fields have values
        const allFieldsFilled = requiredFields.every(field => field !== null && field !== undefined && field !== '');
        if (!allFieldsFilled) return false;
        
        // Check conditional required fields
        if (bd.typeOfBusiness === 'Other' && !bd.otherTypeOfBusiness) return false;
        if (bd.organizationType === 'Other' && !bd.otherOrganizationType) return false;
        if (bd.isAssociationMember && !bd.associationName) return false;
        if (bd.employeesInOtherStates && (!bd.otherStates || !bd.employeesInOtherStatesCount)) return false;
        if (bd.subjectToCalCOBRA && !bd.calCOBRAEnrolleesCount) return false;
        if (bd.subjectToCOBRA && !bd.cobraEnrolleesCount) return false;
        if (bd.hasOtherCoverage && (!bd.carrierName || !bd.renewalMonth || !bd.employeesCovered)) return false;
        if (!bd.meetsSmallEmployerDefinition) return false;
        
        return true;
    }

    /**
     * Report validity on all lightning-input and lightning-combobox fields
     * @returns {Boolean} Whether all fields are valid
     */
    @api
    reportFieldValidity() {
        const allComponents = [
            ...this.template.querySelectorAll('lightning-input'),
            ...this.template.querySelectorAll('lightning-combobox')
        ];
        
        let isValid = allComponents.reduce((valid, component) => {
            // Skip validation for Other Coverage fields if hasOtherCoverage is false
            if (!this.businessDetails.hasOtherCoverage) {
                const name = component.name;
                if (name === 'carrierName' || name === 'renewalMonth' || name === 'employeesCovered') {
                    return valid; // Skip validation for these fields
                }
            }
            return component.reportValidity() && valid;
        }, true);
        
        // Custom validation: OE End Date must be at least 14 days before Requested Effective Date
        if (!this.validateOpenEnrollmentDates()) {
            isValid = false;
        }
        
        // Custom validation: Count fields cannot be 0 when their checkboxes are enabled
        if (!this.validateCountFields()) {
            isValid = false;
        }
        
        return isValid;
    }
    
    /**
     * Validate Open Enrollment dates against Requested Effective Date and Contract Effective Date
     * OE Start Date must be before OE End Date
     * OE End Date must be at least 14 days before both dates
     * @returns {Boolean} Whether OE dates are valid
     */
    validateOpenEnrollmentDates() {
        // Get all lightning-input elements
        const allInputs = this.template.querySelectorAll('lightning-input');
        let oeStartDateInput = null;
        let oeEndDateInput = null;
        let requestedEffectiveDateInput = null;
        
        // Find the specific inputs by name
        allInputs.forEach(input => {
            if (input.name === 'openEnrollmentStartDate') {
                oeStartDateInput = input;
            } else if (input.name === 'openEnrollmentEndDate') {
                oeEndDateInput = input;
            } else if (input.name === 'requestedEffectiveDate') {
                requestedEffectiveDateInput = input;
            }
        });
        
        if (!oeEndDateInput || !requestedEffectiveDateInput) {
            console.log('Input fields not found', { oeStartDateInput, oeEndDateInput, requestedEffectiveDateInput });
            return true; // Fields not found, skip validation
        }
        
        const oeStartDate = this.businessDetails.openEnrollmentStartDate;
        const oeEndDate = this.businessDetails.openEnrollmentEndDate;
        const requestedEffectiveDate = this.businessDetails.requestedEffectiveDate;
        
        console.log('Validating OE dates:', { oeStartDate, oeEndDate, requestedEffectiveDate });
        
        let isValid = true;
        
        // Validation 0: OE Start Date must be before OE End Date
        if (oeStartDate && oeEndDate && oeStartDateInput) {
            const oeStart = new Date(oeStartDate + 'T00:00:00');
            const oeEnd = new Date(oeEndDate + 'T00:00:00');
            
            if (oeStart >= oeEnd) {
                const formattedEndDate = this.formatDate(oeEnd);
                oeStartDateInput.setCustomValidity(`Open Enrollment Start Date must be before End Date (${formattedEndDate}).`);
                oeStartDateInput.reportValidity();
                isValid = false;
            } else {
                oeStartDateInput.setCustomValidity('');
                oeStartDateInput.reportValidity();
            }
        } else if (oeStartDateInput) {
            oeStartDateInput.setCustomValidity('');
            oeStartDateInput.reportValidity();
        }
        
        // Skip remaining validation if OE End Date is blank
        if (!oeEndDate) {
            console.log('OE End Date is blank, clearing validation');
            oeEndDateInput.setCustomValidity('');
            return isValid;
        }
        
        // Parse dates using UTC to avoid timezone issues
        const oeEnd = new Date(oeEndDate + 'T00:00:00');
        let errorMessages = [];
        
        // Validation: OE End Date must be at least 14 days before Requested Effective Date
        if (requestedEffectiveDate) {
            const effectiveDate = new Date(requestedEffectiveDate + 'T00:00:00');
            const timeDiff = effectiveDate.getTime() - oeEnd.getTime();
            const daysDiff = Math.floor(timeDiff / (1000 * 60 * 60 * 24));
            
            console.log('Validation - Days diff:', daysDiff);
            
            if (daysDiff < 14) {
                const formattedDate = this.formatDate(effectiveDate);
                errorMessages.push(`Open Enrollment End Date must be at least 14 days before Requested Effective Date (${formattedDate}).`);
            }
        }
        
        console.log('Validation errors:', errorMessages);
        
        if (errorMessages.length > 0) {
            const errorMsg = errorMessages.join(' ');
            console.log('Setting custom validity:', errorMsg);
            oeEndDateInput.setCustomValidity(errorMsg);
            // Force the error to show
            oeEndDateInput.reportValidity();
            console.log('Validity after setting:', oeEndDateInput.validity);
            isValid = false;
        } else {
            // Clear any previous custom validity
            console.log('Clearing custom validity');
            oeEndDateInput.setCustomValidity('');
            oeEndDateInput.reportValidity();
        }
        
        return isValid;
    }
    
    /**
     * Format date to MM/DD/YYYY
     * @param {Date} date - Date object to format
     * @returns {String} Formatted date string
     */
    formatDate(date) {
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        const year = date.getFullYear();
        return `${month}/${day}/${year}`;
    }
    
    /**
     * Validate count fields are not 0 or empty when their checkboxes are enabled
     * @returns {Boolean} Whether count fields are valid
     */
    validateCountFields() {
        const allInputs = this.template.querySelectorAll('lightning-input');
        let isValid = true;
        
        allInputs.forEach(input => {
            const name = input.name;
            
            // Validate employeesInOtherStatesCount
            if (name === 'employeesInOtherStatesCount' && this.businessDetails.employeesInOtherStates) {
                const value = this.businessDetails.employeesInOtherStatesCount;
                if (!value || Number(value) === 0) {
                    input.setCustomValidity('Number of employees in other states must be greater than 0.');
                    input.reportValidity();
                    isValid = false;
                } else {
                    input.setCustomValidity('');
                }
            }
            
            // Validate calCOBRAEnrolleesCount
            if (name === 'calCOBRAEnrolleesCount' && this.businessDetails.subjectToCalCOBRA) {
                const value = this.businessDetails.calCOBRAEnrolleesCount;
                if (!value || Number(value) === 0) {
                    input.setCustomValidity('Number of Cal-COBRA enrollees must be greater than 0.');
                    input.reportValidity();
                    isValid = false;
                } else {
                    input.setCustomValidity('');
                }
            }
            
            // Validate cobraEnrolleesCount
            if (name === 'cobraEnrolleesCount' && this.businessDetails.subjectToCOBRA) {
                const value = this.businessDetails.cobraEnrolleesCount;
                if (!value || Number(value) === 0) {
                    input.setCustomValidity('Number of COBRA enrollees must be greater than 0.');
                    input.reportValidity();
                    isValid = false;
                } else {
                    input.setCustomValidity('');
                }
            }
        });
        
        return isValid;
    }

    /**
     * Check validity without showing errors
     * @returns {Boolean} Whether all fields are valid
     */
    @api
    checkValidity() {
        const allComponents = [
            ...this.template.querySelectorAll('lightning-input'),
            ...this.template.querySelectorAll('lightning-combobox')
        ];
        
        return allComponents.every(component => component.checkValidity());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // EVENT HANDLERS
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Generic handler for lightning-input fields (text, number, date)
     * Uses the 'name' attribute to determine which field to update
     */
    handleInputChange(event) {
        const fieldName = event.target.name;
        const value = event.target.value;
        
        
        if (fieldName && fieldName in this.businessDetails) {
            this.businessDetails[fieldName] = value;
            this.setInProgress();
            this.dispatchChangeEvent();
            
            // Trigger validation when OE dates or Requested Effective Date change
            if (fieldName === 'openEnrollmentEndDate' || fieldName === 'requestedEffectiveDate' || fieldName === 'openEnrollmentStartDate') {
              
                this.validateOpenEnrollmentDates();
            }
            
            // Clear custom validity and trigger validation when count fields change
            if (fieldName === 'employeesInOtherStatesCount' || fieldName === 'calCOBRAEnrolleesCount' || fieldName === 'cobraEnrolleesCount') {
                event.target.setCustomValidity('');
                this.validateCountFields();
            }
        }
    }

    /**
     * Generic handler for lightning-combobox fields
     * Uses the 'name' attribute to determine which field to update
     */
    handleComboboxChange(event) {
        const fieldName = event.target.name;
        const value = event.detail.value;
        
        if (fieldName && fieldName in this.businessDetails) {
            this.businessDetails[fieldName] = value;
            this.setInProgress();
            this.dispatchChangeEvent();
        }
    }

    /**
     * Handle SIC Code selection from lookup
     */
    handleSICCodeSelect(event) {
        const selected = event.detail.record;
        if (selected && selected.record) {
            this.businessDetails.sicCode = selected.record.code || '';
            this.businessDetails.sicCodeDescription = selected.record.description || '';
            this.setInProgress();
            this.dispatchChangeEvent();
        }
    }

    /**
     * Handle SIC Code clear from lookup
     */
    handleSICCodeClear() {
        this.businessDetails.sicCode = '';
        this.businessDetails.sicCodeDescription = '';
        this._sicCodeSet = false;
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    handleAccountManagerSelect(event) {
        const selected = event.detail;
        // Handle both {record: {...}} and direct {...} formats
        const record = selected.record || selected;
        if (record && record.Id) {
            this.businessDetails.accountManagerId = record.Id;
            this.businessDetails.accountManagerName = record.Name;
            this._accountManagerSet = true;
            this.setInProgress();
            this.dispatchChangeEvent();
        }
    }

    handleAccountManagerClear() {
        this.businessDetails.accountManagerId = null;
        this.businessDetails.accountManagerName = '';
        this._accountManagerSet = false;
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    /**
     * Generic handler for checkbox fields
     * Uses the 'name' attribute to determine which field to update
     */
    _setSmallEmployerValidity(isValid) {
        this.meetsSmallEmployerError = !isValid;
    }

    handleCheckboxChange(event) {
        const fieldName = event.target.name;
        const checked = event.target.checked;
        
        if (fieldName && fieldName in this.businessDetails) {
            this.businessDetails[fieldName] = checked;
            if (fieldName === 'meetsSmallEmployerDefinition' && checked) {
                this._setSmallEmployerValidity(true);
            }
            this.dispatchChangeEvent();
            
            // Trigger count field validation when related checkboxes change
            if (fieldName === 'employeesInOtherStates' || fieldName === 'subjectToCalCOBRA' || fieldName === 'subjectToCOBRA') {
                // Clear validation when checkbox is unchecked
                if (!checked) {
                    const allInputs = this.template.querySelectorAll('lightning-input');
                    allInputs.forEach(input => {
                        if ((fieldName === 'employeesInOtherStates' && input.name === 'employeesInOtherStatesCount') ||
                            (fieldName === 'subjectToCalCOBRA' && input.name === 'calCOBRAEnrolleesCount') ||
                            (fieldName === 'subjectToCOBRA' && input.name === 'cobraEnrolleesCount')) {
                            input.setCustomValidity('');
                        }
                    });
                } else {
                    // Trigger validation when checkbox is checked
                    this.validateCountFields();
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SPECIFIC HANDLERS (for fields with custom logic)
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Auto-format Federal Tax ID as user types (XX-XXXXXXX)
     */
    handleFederalTaxIdKeyUp(event) {
        let value = event.target.value.replace(/\D/g, ''); // Remove non-digits
        if (value.length > 9) {
            value = value.substring(0, 9);
        }
        // Add dash after first 2 digits
        if (value.length > 2) {
            value = value.substring(0, 2) + '-' + value.substring(2);
        }
        event.target.value = value;
        this.businessDetails.federalTaxId = value;
    }

    /**
     * Type of Business - clears "other" field when different option selected
     */
    handleTypeOfBusinessChange(event) {
        this.businessDetails.typeOfBusiness = event.detail.value;
        if (event.detail.value !== 'Other (free format)') {
            this.businessDetails.otherTypeOfBusiness = '';
        }
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    /**
     * Organization Type - clears "other" field when different option selected
     */
    handleOrganizationTypeChange(event) {
        this.businessDetails.organizationType = event.detail.value;
        if (event.detail.value !== 'Other') {
            this.businessDetails.otherOrganizationType = '';
        }
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    /**
     * Non-Profit - stores picklist value (Yes/No)
     */
    handleNonProfitChange(event) {
        // Capitalize first letter for picklist value (Yes/No)
        const value = event.detail.value;
        this.businessDetails.isNonProfit = value.charAt(0).toUpperCase() + value.slice(1);
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    /**
     * Association Member - converts yes/no to boolean and clears name if No
     */
    handleAssociationMemberChange(event) {
        this.businessDetails.isAssociationMember = event.detail.value === 'yes';
        if (!this.businessDetails.isAssociationMember) {
            this.businessDetails.associationName = '';
        }
        this.setInProgress();
        this.dispatchChangeEvent();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════════════

    dispatchChangeEvent() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: { section: 'businessDetails', data: this.getData() }
        }));
    }

    /**
     * Dispatch company address change event
     * Called after successful save to sync with payment section
     */
    dispatchCompanyAddressChangeEvent() {
        const addressChangeEvent = new CustomEvent('companyaddresschange', {
            detail: {
                address: {
                    street: this.businessDetails.companyStreet,
                    city: this.businessDetails.companyCity,
                    state: this.businessDetails.companyState,
                    zipCode: this.businessDetails.companyZip
                }
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(addressChangeEvent);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SAVE HANDLER
    // ═══════════════════════════════════════════════════════════════════════

    async handleSave() {
        // Only validate count fields before saving
        if (!this.validateCountFields()) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Validation Error',
                message: 'Please fix the errors before saving.',
                variant: 'error'
            }));
            return;
        }
        
        // Start saving
        this.isSaving = true;

        try {
            // Call Apex to save business details
            const result = await saveBusinessDetails({ 
                opportunityId: this.recordId, 
                businessData: this.getData()
            });

            if (result.isSuccess) {
                // Update status based on completion, not validation
                this.sectionStatus = this.isComplete() ? 'complete' : 'in-progress';
                // Show native error on checkbox if unchecked after save
                const checkboxValid = this.businessDetails.meetsSmallEmployerDefinition;
                this._setSmallEmployerValidity(checkboxValid);

                // Show success toast
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Business details saved successfully.',
                    variant: 'success'
                }));

                // Dispatch company address change event for payment section sync
                this.dispatchCompanyAddressChangeEvent();

                // Notify parent
                this.dispatchEvent(new CustomEvent('save', {
                    detail: { 
                        section: 'businessDetails', 
                        data: this.getData(),
                        isValid: true,
                        errors: []
                    }
                }));

                // Collapse section after successful save (only if checkbox is valid)
                if (checkboxValid) {
                    const section = this.template.querySelector('c-a-r-c_-collapsible-section');
                    if (section) {
                        section.notifySaved();
                    }
                }
            } else {
                // Handle save failure - show error toast
                this.sectionStatus = 'error';
                
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Unable to Save Business Details',
                    message: 'There was a problem saving your business information.',
                    variant: 'error',
                    mode: 'sticky'
                }));
                
                console.error('Save failed:', result.message);
            }

        } catch (error) {
            console.error('Error saving business details:', error);
            this.sectionStatus = 'error';
            
            // Show error toast for unexpected errors
            this.dispatchEvent(new ShowToastEvent({
                title: 'Unable to Save Business Details',
                message: 'An unexpected error occurred. Please try again or contact support if the problem persists.',
                variant: 'error',
                mode: 'sticky'
            }));
        } finally {
            this.isSaving = false;
        }
    }
}