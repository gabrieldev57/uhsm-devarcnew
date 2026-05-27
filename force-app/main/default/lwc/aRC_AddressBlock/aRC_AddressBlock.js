import { LightningElement, api, track } from 'lwc';

export default class ArcAddressBlock extends LightningElement {
    @api 
    get value() {
        // Always return the current address state, not _value
        return { ...this.address };
    }
    set value(val) {
        // If this update is coming from our own change event, ignore it to prevent cursor jumping
        if (this.isInternalUpdate) {
            this.isInternalUpdate = false;
            return;
        }

        const newVal = val ? { ...val } : this.getEmptyAddress();
        
        // Convert state abbreviation to full name if needed
        if (newVal.state) {
            newVal.state = this.convertStateAbbreviationToFullName(newVal.state);
        }
        
        // Only update internal state if the new value from parent is actually different
        if (JSON.stringify(newVal) !== JSON.stringify(this.address)) {
            this.address = { ...newVal };
        }
    }

    isInternalUpdate = false;

    @api required = false;
    @api readOnly = false;
    @api label = 'Address';
    @api hideLabel = false;

    @track address = {
        street: '',
        city: '',
        state: '',
        zipCode: ''
    };

    
    stateOptions = [
        { label: 'Select State', value: '' },
        { label: 'Alabama', value: 'Alabama' },
        { label: 'Alaska', value: 'Alaska' },
        { label: 'Arizona', value: 'Arizona' },
        { label: 'Arkansas', value: 'Arkansas' },
        { label: 'California', value: 'California' },
        { label: 'Colorado', value: 'Colorado' },
        { label: 'Connecticut', value: 'Connecticut' },
        { label: 'Delaware', value: 'Delaware' },
        { label: 'Florida', value: 'Florida' },
        { label: 'Georgia', value: 'Georgia' },
        { label: 'Hawaii', value: 'Hawaii' },
        { label: 'Idaho', value: 'Idaho' },
        { label: 'Illinois', value: 'Illinois' },
        { label: 'Indiana', value: 'Indiana' },
        { label: 'Iowa', value: 'Iowa' },
        { label: 'Kansas', value: 'Kansas' },
        { label: 'Kentucky', value: 'Kentucky' },
        { label: 'Louisiana', value: 'Louisiana' },
        { label: 'Maine', value: 'Maine' },
        { label: 'Maryland', value: 'Maryland' },
        { label: 'Massachusetts', value: 'Massachusetts' },
        { label: 'Michigan', value: 'Michigan' },
        { label: 'Minnesota', value: 'Minnesota' },
        { label: 'Mississippi', value: 'Mississippi' },
        { label: 'Missouri', value: 'Missouri' },
        { label: 'Montana', value: 'Montana' },
        { label: 'Nebraska', value: 'Nebraska' },
        { label: 'Nevada', value: 'Nevada' },
        { label: 'New Hampshire', value: 'New Hampshire' },
        { label: 'New Jersey', value: 'New Jersey' },
        { label: 'New Mexico', value: 'New Mexico' },
        { label: 'New York', value: 'New York' },
        { label: 'North Carolina', value: 'North Carolina' },
        { label: 'North Dakota', value: 'North Dakota' },
        { label: 'Ohio', value: 'Ohio' },
        { label: 'Oklahoma', value: 'Oklahoma' },
        { label: 'Oregon', value: 'Oregon' },
        { label: 'Pennsylvania', value: 'Pennsylvania' },
        { label: 'Rhode Island', value: 'Rhode Island' },
        { label: 'South Carolina', value: 'South Carolina' },
        { label: 'South Dakota', value: 'South Dakota' },
        { label: 'Tennessee', value: 'Tennessee' },
        { label: 'Texas', value: 'Texas' },
        { label: 'Utah', value: 'Utah' },
        { label: 'Vermont', value: 'Vermont' },
        { label: 'Virginia', value: 'Virginia' },
        { label: 'Washington', value: 'Washington' },
        { label: 'West Virginia', value: 'West Virginia' },
        { label: 'Wisconsin', value: 'Wisconsin' },
        { label: 'Wyoming', value: 'Wyoming' }
    ];

    // State abbreviation to full name mapping
    stateAbbreviationMap = {
        'AL': 'Alabama',
        'AK': 'Alaska',
        'AZ': 'Arizona',
        'AR': 'Arkansas',
        'CA': 'California',
        'CO': 'Colorado',
        'CT': 'Connecticut',
        'DE': 'Delaware',
        'FL': 'Florida',
        'GA': 'Georgia',
        'HI': 'Hawaii',
        'ID': 'Idaho',
        'IL': 'Illinois',
        'IN': 'Indiana',
        'IA': 'Iowa',
        'KS': 'Kansas',
        'KY': 'Kentucky',
        'LA': 'Louisiana',
        'ME': 'Maine',
        'MD': 'Maryland',
        'MA': 'Massachusetts',
        'MI': 'Michigan',
        'MN': 'Minnesota',
        'MS': 'Mississippi',
        'MO': 'Missouri',
        'MT': 'Montana',
        'NE': 'Nebraska',
        'NV': 'Nevada',
        'NH': 'New Hampshire',
        'NJ': 'New Jersey',
        'NM': 'New Mexico',
        'NY': 'New York',
        'NC': 'North Carolina',
        'ND': 'North Dakota',
        'OH': 'Ohio',
        'OK': 'Oklahoma',
        'OR': 'Oregon',
        'PA': 'Pennsylvania',
        'RI': 'Rhode Island',
        'SC': 'South Carolina',
        'SD': 'South Dakota',
        'TN': 'Tennessee',
        'TX': 'Texas',
        'UT': 'Utah',
        'VT': 'Vermont',
        'VA': 'Virginia',
        'WA': 'Washington',
        'WV': 'West Virginia',
        'WI': 'Wisconsin',
        'WY': 'Wyoming'
    };

    // ═══════════════════════════════════════════════════════════════════════
    // LIFECYCLE HOOKS
    // ═══════════════════════════════════════════════════════════════════════
    
    connectedCallback() {
        // Initialize with empty address if needed
        if (!this.address.street && !this.address.city && !this.address.state && !this.address.zipCode) {
            this.address = this.getEmptyAddress();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PUBLIC API METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    /**
     * @api Check validity of all address fields
     * @returns {Boolean} Whether all required fields are valid
     */
    @api
    checkValidity() {
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        let isValid = true;
        
        inputs.forEach(input => {
            if (!input.checkValidity()) {
                isValid = false;
            }
        });
        
        return isValid;
    }

    /**
     * @api Report validity and show error messages
     * @returns {Boolean} Whether all required fields are valid
     */
    @api
    reportValidity() {
        const inputs = this.template.querySelectorAll('lightning-input, lightning-combobox');
        let isValid = true;
        const errors = [];
        
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
                errors.push({
                    field: input.name || input.label,
                    message: input.validationMessage || 'Invalid value'
                });
            }
        });

        this.dispatchEvent(new CustomEvent('validity', {
            detail: { valid: isValid, errors: errors }
        }));
        
        return isValid;
    }

    /**
     * @api Reset the address to empty values
     */
    @api
    reset() {
        this.address = this.getEmptyAddress();
        this.dispatchChangeEvent();
    }

    /**
     * @api Get the current address value
     * @returns {Object} Current address object
     */
    @api
    getAddress() {
        return { ...this.address };
    }

    /**
     * @api Set the address values programmatically
     * @param {Object} addressData - Address object with street, city, state, zipCode
     */
    @api
    setAddress(addressData) {
        if (addressData) {
            this.address = {
                street: addressData.street || '',
                city: addressData.city || '',
                state: addressData.state || '',
                zipCode: addressData.zipCode || ''
            };
        }
    }

    handleStreetChange(event) {
        this.address = {
            ...this.address,
            street: event.target.value
        };
        this.isInternalUpdate = true;
        this.dispatchChangeEvent();
    }

    handleCityChange(event) {
        this.address = {
            ...this.address,
            city: event.target.value
        };
        this.isInternalUpdate = true;
        this.dispatchChangeEvent();
    }

    handleStateChange(event) {
        this.address = {
            ...this.address,
            state: event.detail.value
        };
        this.isInternalUpdate = true;
        this.dispatchChangeEvent();
    }

    handleZipChange(event) {
        this.address = {
            ...this.address,
            zipCode: event.target.value
        };
        this.isInternalUpdate = true;
        this.dispatchChangeEvent();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════════════
    
    getEmptyAddress() {
        return {
            street: '',
            city: '',
            state: '',
            zipCode: ''
        };
    }

    /**
     * Convert state abbreviation to full name
     * @param {String} state - State abbreviation (e.g., 'FL') or full name (e.g., 'Florida')
     * @returns {String} Full state name
     */
    convertStateAbbreviationToFullName(state) {
        if (!state) return '';
        
        // If it's already a full state name, return as is
        if (this.stateAbbreviationMap[state]) {
            return this.stateAbbreviationMap[state];
        }
        
        // Otherwise assume it's already a full name and return it
        return state;
    }

    dispatchChangeEvent() {
        this.dispatchEvent(new CustomEvent('change', {
            detail: { address: { ...this.address } },
            bubbles: false,
            composed: false
        }));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // GETTERS (Computed Properties)
    // ═══════════════════════════════════════════════════════════════════════
    
    get showLabel() {
        return !this.hideLabel;
    }

    get streetValue() {
        return this.address.street || '';
    }

    get cityValue() {
        return this.address.city || '';
    }

    get stateValue() {
        return this.address.state || '';
    }

    get zipValue() {
        return this.address.zipCode || '';
    }

    get zipPattern() {
        // US ZIP code pattern: 12345 or 12345-6789
        return '[0-9]{5}(-[0-9]{4})?';
    }
}