import { api } from 'lwc';
import insField from "vlocity_ins/insField"; 
import template from './arc_CensusField.html'
import { dataFormatter } from 'vlocity_ins/insUtility';
import pubsub from 'vlocity_ins/pubsub';

const dataTypeKeys = {
    string: 'isText',
    textarea: 'isTextarea',
    boolean: 'isCheckbox',
    double: 'isNumber',
    percent: 'isPercent',
    currency: 'isCurrency',
    date: 'isDate',
    datetime: 'isDatetime',
    time: 'isTime',
    email: 'isEmail',
    phone: 'isPhone',
    url: 'isUrl',
    reference: 'isDropdown',
    picklist: 'isDropdown',
    encryptedstring: 'isText',
    multipicklist: 'isMultiPicklist',
    lookup: 'isLookUp',
    password: 'isPassword',
    birthdate: 'isBirthdate'
};

export default class arc_CensusField extends insField {

    // deprecated properties
    @api currencySymbol;
    @api theme = 'slds';
    @api currency = dataFormatter.currency;
    @api channel;
    @api dateFormat = 'MM-DD-YYYY';
    @api dateOutputFormat = 'YYYY-MM-DD';
    @api jsondata;

    @api
    get field() {
        return this._field;
    }

    set field(data) {
        this._field = JSON.parse(JSON.stringify(data));
        this.value = this._field.value;
        const dataType = this._field.dataType.toLowerCase();
        this.isReadonly = !this._field.isUpdateable;
        const dataTypeKey = dataTypeKeys[dataType];
        this[dataTypeKey] = true;
        if (this.isTime && this.value) {
            // Salesforce returns time values as 'HH:mm:ss.SSS ZZ' but timepicker element expects 'HH:mm'
            const date = new Date('1970-01-01T' + this._field.value);
            const hours = date.getUTCHours();
            const minutes = date.getUTCMinutes();
            this.value = `${hours < 10 ? '0' : ''}${hours}:${minutes < 10 ? '0' : ''}${minutes}`;
        } else if (this.isDropdown) {
            const options = this._field.options ? this._field.options : this._field.values;
            this.options = dataFormatter.formatLabelAndValue(options);
            if (this.value == null) {
                this.value = '';
            }
            if (!this._field.isRequired) {
                const emptyOption = {
                    label: `--${this.labels.None}--`,
                    value: ''
                };
                this.options.unshift(emptyOption);
            }
        } else if (this.isMultiPicklist && !this.isReadonly) {
            let options = this._field.options
                ? this._field.options
                : this._field.values;

            this.options = dataFormatter.formatLabelAndValue(options);
            if (this.value == null) {
                this.value = '';
            }
            this.value = this.value.split(';');
        }

        if (this.isReadonly) {
            this.formatDisplayValue();
        }
    }

    dateChanged(evt){
        let value = evt.detail;
        this.value = value;
        let inputName = 'vlocity_ins-input';
        if (this.isCurrency) {
            inputName = 'vlocity_ins-masked-input';
        } else if (this.isDropdown) {
            inputName = 'vlocity_ins-combobox';
        } else if(this.isMultiPicklist) {
            value = evt.detail;
        }
        
        let isInvalid;
        if (!this.isLookUp && !this.isMultiPicklist) {
            isInvalid = !this.template.querySelector(inputName).checkValidity(); // Determines if input value is formatted correctly
        }
        
        const payload = {
            fieldName: this.field.fieldName,
            value,
            isInvalid
        };
        pubsub.fire(this.channel, 'changeFieldValue', payload);
    }

    formatDisplayValue() {
        const field = {
            userValues: this.value,
            dataType: this._field.dataType.toLowerCase()
        };
        if (this.isDropdown) {
            field.inputType = 'dropdown';
            field.values = this.options;
        } else if(this.isMultiPicklist){
            // multipicklist values have "a;b;c" format
            field.userValues = this.value.split(';').join(', ');
        }
        this.value = dataFormatter.formatDisplayValue(field, this.currency);
    }
    handleValueChange2(e) {
        e.preventDefault();
        let input= e.target.value
        let x = input.replace(/\D+/g, '').match(/(\d{0,3})(\d{0,2})(\d{0,4})/);
        let output;
        output = x[1];
        if (x[2]) {
            output = x[1] + '-' + x[2];
        }
        if (x[3]) {
            output = x[1] + '-' + x[2] + '-' + x[3];
        }
        e.target.value = output;
    }
    handleValueChange(e) {
        
        let value = this.isCheckbox ? e.target.checked : e.target.value;
        this.value = value;
        let inputName = 'vlocity_ins-input';
        if (this.isCurrency) {
            inputName = 'vlocity_ins-masked-input';
        } else if (this.isDropdown) {
            inputName = 'vlocity_ins-combobox';
        } else if(this.isMultiPicklist) {
            value = JSON.parse(JSON.stringify(e.detail.value)).join(';');
        }
        
        let isInvalid;
        if (!this.isLookUp && !this.isMultiPicklist) {
            isInvalid = !this.template.querySelector(inputName).checkValidity(); // Determines if input value is formatted correctly
        }
        
        const payload = {
            fieldName: this.field.fieldName,
            value,
            isInvalid
        };
        pubsub.fire(this.channel, 'changeFieldValue', payload);
    }


    render () {
        return template;
    }

}