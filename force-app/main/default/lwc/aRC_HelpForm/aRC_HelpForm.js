import { LightningElement, api, track, wire } from 'lwc';
import createCase from '@salesforce/apex/ARC_HelpPageController.createCase';
import USER_ID from '@salesforce/user/Id';
import { getRecord } from 'lightning/uiRecordApi';
import getEmployeeOptionsByContract from '@salesforce/apex/ARC_HelpPageController.getEmployeeOptionsByContract';

const FIELDS = [
    'User.Name',
    'User.Email',
    'User.Account.Name'
];
export default class ARC_HelpForm extends LightningElement {
    
    @track currentObject = {}
    @track user = { Name: "Sarah Johnson", Email: "",Company:""}
    userId = USER_ID;
    @track isLoading
    @track unfinished = true

    //UHSM-2870 ----------------------------
    inputTypeOptions = [
        { label: 'General', value: 'General' },
        { label: 'Employee-Specific', value: 'Employee-Specific' },
    ];
    inputTypeDefaultValue = 'General';

    selectEmployeeOptions = [];
    selectedEmployeeId = '';
    makeSelectEmployeeRequired = false;
    isSelectEmployeeDisabled = false;
    //UHSM-2870 ----------------------------

    @wire(getEmployeeOptionsByContract)
    wiredEmployees({ data, error }) {
        if (data) {
            this.selectEmployeeOptions = data;
        } else if (error) {
            console.error('getEmployeeOptionsByContract error:', JSON.parse(JSON.stringify(error)));
            this.selectEmployeeOptions = [];
        }
    }

    @wire(getRecord, { recordId: '$userId', fields: FIELDS })
    wiredUser({ error, data }) {
        if (data) {
            this.user.Name = data?.fields.Name.value;
            this.user.Email = data?.fields.Email.value
            this.user.Company = data?.fields?.Account?.value?.fields.Name.value
        } else if (error) {
            console.error('Error retrieving user data:', error);
        }
    }

    connectedCallback(){
        //Set currentObject
        this.currentObject = {
            inputType: this.inputTypeDefaultValue || 'General',
            employee: this.selectedEmployeeId || '',
            subject: '',
            description: ''
        }
    }

    handleSubmit(event) {
        event.preventDefault();
        event.stopPropagation();

        let form = this.template.querySelector('form');

        const inputType = this.currentObject.inputType || this.inputTypeDefaultValue || 'General';

        //If InputType isnt Employee-Specific, set employee to empty
        const employeeId = (inputType === 'Employee-Specific') 
            ? (this.selectedEmployeeId || null) 
            : null;

        if (!form){
            console.error('Form not found');
            return;
        }

        if(form.checkValidity()){
            this.isLoading = true;
            createCase({
                subject: this.currentObject.subject, 
                description: this.currentObject.description, 
                employeeId: employeeId,
                inputType: inputType
            })
            .then(() => {
                this.isLoading = false
                this.currentObject = {}
                this.selectedEmployeeId = '';
                form.reset()
                this.unfinished = false
            })
            .catch(err => {
                this.isLoading = false;
                console.error(err);
            })
        } else {
            form.reportValidity?.();
        }
    }

    avoidRefresh(e){
        e.preventDefault()
        return false;
    }

    handleChange(e){
        this.currentObject[e.target.name] = e.target.value
    }

    handleNewRequest(){
        this.unfinished = true
    }

    handleInputTypeChange(event) {
        this.inputTypeDefaultValue = event.detail.value;
        const isEmployeeSpecific = this.inputTypeDefaultValue === 'Employee-Specific';
        this.makeSelectEmployeeRequired = isEmployeeSpecific;
        this.isSelectEmployeeDisabled = isEmployeeSpecific;
    
        if (!isEmployeeSpecific) this.selectedEmployeeId = '';
        this.currentObject[event.target.name] = this.inputTypeDefaultValue;
      }

    handleSelectEmployeeChange(event){
        this.selectedEmployeeId = event.detail.value;
        this.currentObject[event.target.name] = this.selectedEmployeeId;
    }
}