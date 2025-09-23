import { api, track } from 'lwc';
import insField from "vlocity_ins/insField"; 
import template from './arc_DemoCensusField.html';
import { OmniscriptActionCommonUtil } from "vlocity_ins/omniscriptActionUtils";
import { omniscriptUtils, commonUtils, dataFormatter } from 'vlocity_ins/insUtility';
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
    text: 'isText'
};

export default class arc_DemoCensusField extends insField {

    // deprecated properties
    @api currencySymbol;
    @api osData;
    @api theme = 'slds';
    @api currency = dataFormatter.currency;
    @api channel;
    @api dateFormat = 'MM-DD-YYYY';
    @api dateOutputFormat = 'YYYY-MM-DD';
    @api inputTypeSSN ="password";
    @track censusFieldOsData;
    @api isSmokerField= false;


    
    connectedCallback(){
        if (this.osData != null){
            this.censusFieldOsData = this.osData;
        }
    }
  

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
        if (this._field.fieldName == 'vlocity_ins__Birthdate__c') this.bthDate = this._field.value;
        if (this._field.fieldName == 'ARC_Smoker__c') this.isSmokerField = true;

        // format the date of birthdate field if it is read only
        if (this._field.fieldName == 'vlocity_ins__Birthdate__c' && this.isReadonly) {
            const date = new Date(this._field.value);

            const monthValue = date.getUTCMonth() + 1; //Month (1-based)
            const dayValue = date.getUTCDate(); // Day of the month (number)
            const yearValue = date.getUTCFullYear(); // Year
            this.value = `${monthValue < 10 ? '0' : ''}${monthValue}-${dayValue < 10 ? '0' : ''}${dayValue}-${yearValue}`;
        }


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
        else if (this._field.fieldName == "ARC_HeightFeet__c") {
            this._field.maxlength = "2";

        }       
        else if (this._field.fieldName == "ARC_HeightInches__c") {
            this._field.maxlength = "2";

        }
        else if (this._field.fieldName == "ARC_Weight__c") {
            this._field.maxlength = "3";
        }
        
        else if (this._field.fieldName == "ARC_ActiveMember__c") {
            // this._field.maxlength = "3";
            // let value = this.isCheckbox ? e.target.checked : e.target.value;
        }
        else if (this._field.fieldName == "ARC_Phone__c") {
            this._field.minlength = "10";
            this._field.maxlength = "10";
            // this._field.title  = "The phone number must have 10 digits."
            let value = this._field.value;

            if(value != "" && value != undefined && value != null){
                value = value.replace(/\D/g,'');
                // if(value.length == 11){
                //     value = value.substring(1);
                // }

                // if(value.length>0) value=value.replace(/.{0}/,'$&(')
                // if(value.length>4) value=value.replace(/.{4}/,'$&)')                                              
                // if(value.length>5) value=value.replace(/.{5}/,'$&-')                       
                // if(value.length>9) value=value.replace(/.{9}/,'$&-')  
    
                this.value = value;
    
            } 
    
        } 

        else if (this._field.fieldName == "ARC_MiddleInitial__c") {
            this._field.maxlength = "1";

        }

        if (this.isReadonly) {
            this.formatDisplayValue();
        }
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

    handleValueClicked(e){
        // const regex = /[a-zA-Z!@#\$%\^\&*\)\(+=._-]/;
        const regex =  /[a-zA-Z!@#\$%\^\&*\)\(\'+=._-]/;
        let value = e.target.value;
        
       
        const firstDigitStr = String(value)[0];
        if(firstDigitStr == 0 || firstDigitStr == "0" || this.value == "" || this.value == null){
           this.value = null;
        }
        if(this.field.fieldName.includes('ARC_Height') && regex.test(this.value)){
          this.value = null;
          this.value = null;
        } 
        if(this.field.fieldName.includes('ARC_Weight') && regex.test(this.value)){
          this.value = null;
          this.value = null;
        } 

        //Defined input name before using it
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

  
maskPhone(e) { 
    let value = e.target.value;  

    let isInvalid;  
    let stringValue = value.toString();
    if (stringValue.length > 10){
        let nuevoValue = stringValue.substring(0,10);
        value = nuevoValue;
    }
    const payload = {
        fieldName: this.field.fieldName,
        value,
        isInvalid
    };
  
   pubsub.fire(this.channel, 'changeFieldValue', payload);                                                  
  }
  

 

    handleValueChange(e) {
    
        // const regex = /[a-zA-Z!@#\$%\^\&*\)\(+=._-]/;
        const regex =  /[a-zA-Z!@#\$%\^\&*\)\(\'+=._-]/;
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
        if(this.isNumber){
          const firstDigitStr = String(value)[0];
          if (firstDigitStr == 0){
          this.value = "";
          }
        }
        
        if(this.field.fieldName.includes('ARC_Height') && regex.test(this.value)){
            this.value = "";
            this.value = "";
          //e.target.value.slice(0,-1)
        } 
        if(this.field.fieldName.includes('ARC_Weight') && regex.test(this.value)){
            this.value = "";
            this.value = "";
        } 
       
        if(this.field.fieldName == 'vlocity_ins__Email__c'){
            this.value = e.target.value;
        }
    
        let isInvalid;
   
        
        const payload = {
          fieldName: this.field.fieldName,
          value: this.value,
          isInvalid
        };
        pubsub.fire(this.channel, 'changeFieldValue', payload);
  
   
    }

    handleDateChange(evt){
        let value = evt.detail;
        this.value = value;
        let inputName = 'vlocity_ins-input';
        if (this.isCurrency) {
            inputName = 'vlocity_ins-masked-input';
        } else if (this.isDropdown) {
            inputName = 'vlocity_ins-combobox';
        } else if(this.isMultiPicklist) {
            value = JSON.parse(JSON.stringify(e.detail.value)).join(';');
        } 
        if(this.isNumber){
            const firstDigitStr = String(value)[0];
            if (firstDigitStr == 0){
            this.value = "";
            }
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
    
    unmaskSSN(){
        switch (this.inputTypeSSN) {
            case 'password':
                this.inputTypeSSN = 'text';
                break;
            case 'text':
                this.inputTypeSSN = 'password';
                break;
        }
    }

      
    render () {
        return template;
    }
}