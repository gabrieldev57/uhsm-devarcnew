import {api,track} from 'lwc';
import insOsCensusInfo from 'vlocity_ins/insOsCensusInfo';
import template from './arc_CensusInfo.html';
import {OmniscriptActionCommonUtil} from 'vlocity_ins/omniscriptActionUtils';
import { commonUtils, dataFormatter } from 'vlocity_ins/insUtility';
import pubsub from 'vlocity_ins/pubsub';

export default class arc_CensusInfo extends insOsCensusInfo {
    @api osData;
    @api requiredFieldsPrimary;
    @api requiredFieldsDependent;
    @api visibleFieldsPrimary;
    @api visibleFieldsDependent;
    @api tabAddressPosition;
    @api jsondata;
    medicalValue;
    visionValue;
    dentalValue;
    hasOneMedical = false;
    hasOneVision = false;
    hasOneDental = false;
    customColumns= [];
    mapAddress = new Map();

    @track showGoogleApiResults = false;
    @track showGoogleApiResultsMailing = false;
    @track listAddress = [];
    @track listAddressMailing = [];
    @track customAddressPhysical = [];
    @track mailingAddressColumns = [];
    @track physicalAddressColumns = [];
    @track showMailingSection = true;
    @track ignoreValue = false;
    @track showInfoAddress = false;
    @track ignoreAddress = false;
    @track isEnrollment = false;
    @track listPrimaryAddress = [];
    
    render () {
        return template;
    }

    connectedCallback(){

        super.connectedCallback();
        this._actionUtilClass = new OmniscriptActionCommonUtil();
        this.mailingAddressColumns = this.mailingAddressColumnsFunc();
        this.physicalAddressColumns = this.physicalAddressColumnsFunc();
        this.dependentUseAddress = true;
        
        if (this.osData != null && this.osData.QuoteProcess == "IFP" || this.osData != null && this.osData.QuoteProcess == "IMApplication"){
            this.listPrimaryAddress = this.osData.Address;
            this.populatePhysicalAddress();
            this.ignoreValue = true;
            this.showMailingSection = false;
            this.person['ARC_MailingAddressCity__c'] = this.person['ARC_PhysicalAddressCity__c'];
            this.person['ARC_MailingAddressState__c'] = this.person['ARC_PhysicalAddressState__c'];
            this.person['ARC_MailingAddressStreet__c'] = this.person['ARC_PhysicalAddressStreet__c'];
            this.person['ARC_MailingAddressStreet2__c'] = this.person['ARC_PhysicalAddressStreet2__c'];
            this.person['ARC_MailingAddressZipCode__c'] = this.person['ARC_PhysicalAddressZipCode__c'];
        }
    }
 

    handleActive(event){
            const tab = event.target;
            this.tabAddressPosition = true;
        
    }
   
 
    populatePhysicalAddress(){
        this.showGoogleApiResults = false; 
        var street = this.listPrimaryAddress.BillingStreet;
        
        var city = this.listPrimaryAddress.BillingCity;
        var state = this.listPrimaryAddress.BillingState;
        var postal = this.listPrimaryAddress.BillingZipCode;
        this.person['ARC_PhysicalAddressStreet__c'] = street;
        this.person['ARC_PhysicalAddressCity__c'] = city;
        this.person['ARC_PhysicalAddressState__c'] = state;
        this.person['ARC_PhysicalAddressZipCode__c'] = postal;
        this.physicalAddressColumns = [];
        var newListAux = [];
        this.headerColumns.forEach(column => {
            if ( (column.fieldName).includes('Physical') ){
                var valueNew = column.value;
                var isRequired = true;
                if ( (column.fieldName) == 'ARC_PhysicalAddressStreet__c') {
                    valueNew = street;
                } else if ( (column.fieldName) == 'ARC_PhysicalAddressCity__c' ) {
                    valueNew = city;
                } else if ( (column.fieldName) == 'ARC_PhysicalAddressState__c' ) {
                    valueNew = state;
                } else if ( (column.fieldName) == 'ARC_PhysicalAddressZipCode__c' ) {
                    valueNew = postal;
                }
                if ((column.fieldName) == 'ARC_PhysicalAddressStreet2__c') {
                    isRequired = false;
                }
                newListAux.push({
                    disableColumn: false,
                    dataType: column.dataType,
                    isUpdateable: column.isUpdateable,
                    options: column.options,
                    label: column.label,
                    isRequired: isRequired,
                    value: valueNew,
                    fieldName: column.fieldName,
                    objectApiName: column.objectApiName                
                });
            }
        });
        this.physicalAddressColumns = newListAux;
        const selectedEvent = new CustomEvent('update', { detail: this.person });
        this.dispatchEvent(selectedEvent);
    }



    physicalAddressColumnsFunc () {
        this.customAddressPhysical = [];
        this.showInfoAddress = true;
                if (this.isDependent == true) {
                    this.ignoreAddress = true;
                    this.person['ARC_UseParentAddress__c'] = true;
                }
                if (this.ignoreAddress == true) {
                    this.showInfoAddress = false;
                    this.person['ARC_UseParentAddress__c'] = true;
                }
        this.headerColumns.forEach(column => {
            var isRequired = true;
            if ( (column.fieldName).includes('Physical') ){
                this.isEnrollment = true;
                if ((column.fieldName) == 'ARC_PhysicalAddressStreet2__c') {
                    isRequired = false;
                }
                if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
                    isRequired = false;
                }
                this.customAddressPhysical.push({
                    disableColumn: false,
                    dataType: column.dataType,
                    isUpdateable: column.isUpdateable,
                    options: column.options,
                    label: column.label,
                    isRequired: isRequired,
                    value: column.value,
                    fieldName: column.fieldName,
                    objectApiName: column.objectApiName                
                });
            } 
        });
        // console.log("he aqui el this.person: "+JSON.stringify(this.person))
        return this.customAddressPhysical;

    }

    mailingAddressColumnsFunc() {
        
        var customAddressMailing = [];
        if (this.isDependent == true) {
            this.ignoreAddress = true;
        }
        if (this.ignoreAddress == true) {
            this.showMailingSection = false;
            this.person['ARC_UseParentAddress__c'] = true;
        }
        this.headerColumns.forEach(column => {
            if (column.fieldName == 'ARC_IgnoreMailing__c' && column.value == true) {
                this.ignoreValue = true;
                this.showMailingSection = false;
            }
        });

        

        this.headerColumns.forEach(column => {
            var isRequired = true;
            if ( !this.hideMailingSection && (column.fieldName).includes('Mailing') && column.fieldName != 'ARC_IgnoreMailing__c' ){
                this.showInfoAddress = true;
                this.isEnrollment = true;
                if ((column.fieldName) == 'ARC_MailingAddressStreet2__c') {
                    isRequired = false;
                }
                if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
                    isRequired = false;
                }
                customAddressMailing.push({
                    disableColumn: false,
                    dataType: column.dataType,
                    isUpdateable: column.isUpdateable,
                    options: column.options,
                    label: column.label,
                    isRequired: isRequired,
                    value: column.value,
                    fieldName: column.fieldName,
                    objectApiName: column.objectApiName                
                });
            } 
        });
        return customAddressMailing;
    }
    
    get customHeaderColumns(){
        // console.log("entro al customheader")
        let medicalPlanList = [];
        let visionPlanList = [];
        let dentalPlanList = [];
        let parsedOsData = {...this.osData};
        if(this.osData && parsedOsData.selectedQuoteMedicalPlans){
            let medicalPlanDetails = parsedOsData.selectedQuoteMedicalPlans;
            medicalPlanList = medicalPlanDetails.map(item =>{
                return{
                    "value": item.productId,
                    "label": item.Name   
                }
            });
            if ( medicalPlanDetails.length == 1 ) {
                this.medicalValue = medicalPlanList[0].value;
                this.hasOneMedical = true;
            }
        }

        if(this.osData && parsedOsData.selectedQuoteVisionPlans){
            let visionPlanDetails = parsedOsData.selectedQuoteVisionPlans;
            visionPlanList = visionPlanDetails.map(item =>{
                return{
                    "value": item.productId,
                    "label": item.Name   
                }
            });
            if ( visionPlanDetails.length == 1 ) {
                this.visionValue = visionPlanList[0].value;
                this.hasOneVision = true;
            }
        }

        if(this.osData && parsedOsData.selectedQuoteDentalPlans){
            let dentalPlanDetails = parsedOsData.selectedQuoteDentalPlans;
            dentalPlanList = dentalPlanDetails.map(item =>{
                return{
                    "value": item.productId,
                    "label": item.Name   
                }
            });
            if ( dentalPlanDetails.length == 1 ) {
                this.dentalValue = dentalPlanList[0].value;
                this.hasOneDental = true;
            }
        }
        
        this.customColumns= [];
        this.headerColumns.forEach(column => {
            if ( !(column.fieldName).includes('Mailing') && !(column.fieldName).includes('Physical') ) {
                var isRequiredVar = false;
                var containsField = false;
                if (this.isDependent) {
                    isRequiredVar = this.requiredFieldsDependent.includes(column.fieldName);
                    containsField = this.visibleFieldsDependent.includes(column.fieldName);
                } else {
                    isRequiredVar = this.requiredFieldsPrimary.includes(column.fieldName);
                    containsField = this.visibleFieldsPrimary.includes(column.fieldName);
                }

                if ( column.fieldName === 'ARC_UseParentAddress__c' ) {
              
                    if ( this.isDependent && column.value == true ) {
                        this.showInfoAddress = false;
                        this.showMailingSection = false;
                        this.ignoreAddress = true;
                    } 
                    return;
                }

                if (column.fieldName === 'ARC_MedicalProduct__c' && this.isDependent == false) {
                    var customValue = column.value;
                    if ( this.hasOneMedical ) {
                        customValue = this.medicalValue;
                    }
                    
                    if(medicalPlanList.length == 0){
                        this.customColumns.push({
                            disableColumn: true,
                            isRequired: false
                        })
                    } else {
                    this.customColumns.push({
                        disableColumn: false,
                        dataType: 'PICKLIST',
                        isUpdateable: column.isUpdateable,
                        options: medicalPlanList,                    
                        label: column.label,
                        isRequired: isRequiredVar,
                        value: customValue,
                        fieldName: column.fieldName,
                        objectApiName: column.objectApiName                
                    });
                    }
                    return;
                }

                if (column.fieldName === 'ARC_VisionProduct__c' && this.isDependent == false) {
                    var customValue = column.value;
                    if ( this.hasOneVision ) {
                        customValue = this.visionValue;
                    }
                    
                    if(visionPlanList.length == 0){
                        this.customColumns.push({
                            disableColumn: true,
                            isRequired: false
                        })
                    } else {
                    this.customColumns.push({
                        disableColumn: false,
                        dataType: 'PICKLIST',
                        isUpdateable: column.isUpdateable,
                        options: visionPlanList,                    
                        label: column.label,
                        isRequired: isRequiredVar,
                        value: customValue,
                        fieldName: column.fieldName,
                        objectApiName: column.objectApiName                
                    });
                    }
                    return;
                }

                if (column.fieldName === 'ARC_DentalProduct__c' && this.isDependent == false) {
                    var customValue = column.value;
                    if ( this.hasOneDental ) {
                        customValue = this.dentalValue;
                    }
                
                    if(dentalPlanList.length == 0){
                        this.customColumns.push({
                            disableColumn: true,
                            isRequired: false
                        })
                    } else {
                    this.customColumns.push({
                        disableColumn: false,
                        dataType: 'PICKLIST',
                        isUpdateable: column.isUpdateable,
                        options: dentalPlanList,                    
                        label: column.label,
                        isRequired: isRequiredVar,
                        value: customValue,
                        fieldName: column.fieldName,
                        objectApiName: column.objectApiName                
                    });
                    }
                    

                    return;

                }       

                if (containsField) {
                    var customType = column.dataType
                    if ( column.fieldName === 'vlocity_ins__SocialSecurityNumber__c' ) {
                        customType = 'password';
                    }else if ( column.fieldName === 'ARC_Smoker__c' ) {
                        customType = 'boolean';
                        column.label="Do you Smoke?"
                        
                        
                    }
                    this.customColumns.push({
                        disableColumn: false,
                        dataType: customType,
                        isUpdateable: column.isUpdateable,
                        options: column.options,
                        label: column.label,
                        isRequired: isRequiredVar,
                        value: column.value,
                        fieldName: column.fieldName,
                        objectApiName: column.objectApiName,
                        
                    });
                    return;
                }
            }});
            
        return this.customColumns
    }    

    async googleAPi(e) {
        var value = e.target.value;
        if ( value && value.length > 1 ) {
            value = value.replace(/\s/g, '');
            this.showGoogleApiResults = true
 
            const options = {
                inputKey: value,
            };
            const params = {
                input: JSON.stringify(options),
                sClassName: 'vlocity_ins.IntegrationProcedureService',
                sMethodName: 'Custom_GoogleTypeAhead',
                options: JSON.stringify(options),
            };
            this.listAddress = await this._actionUtilClass.executeAction(params, null, this, null, null).then(response => {
                let res = response.result.IPResult;
                var auxList = []
                res.response.forEach(function (item, index) {
                    
                    var state = "";
                    var street = "";
                    var city = "";
                    var postalCode ="";
                    var streetNumber = "";
                    item.map.forEach(function (elemItem, index) {
                        if ( elemItem.type[0] == "postal_code") {
                            postalCode = elemItem.value;
                        } else if ( elemItem.type[0] == "street_number") {
                            streetNumber = elemItem.value;
                        } else if ( elemItem.type[0] == "route") {
                            street = elemItem.value;
                        } else if ( elemItem.type[0] == "locality") {
                            city = elemItem.value;
                        } else if ( elemItem.type[0] == "administrative_area_level_1") {
                            state = elemItem.value;
                        } 
                    });
                    var finalStreet = streetNumber + " " + street ;
                    var addressObject = { 'address': item.address,'index':index, 'state':state, 'street':finalStreet, 'city':city, 'postalCode':postalCode };
                    auxList.push(addressObject);   
                });
                return auxList;
            });
        } else {
            this.listAddress = [];
            this.showGoogleApiResults = false;
        }
    }

    async googleAPiMailing(e) {
        var value = e.target.value;
        if ( value && value.length > 1 ) {
            value = value.replace(/\s/g, '');
            this.showGoogleApiResultsMailing = true
            const options = {
                inputKey: value,
            };
            const params = {
                input: JSON.stringify(options),
                sClassName: 'vlocity_ins.IntegrationProcedureService',
                sMethodName: 'Custom_GoogleTypeAhead',
                options: JSON.stringify(options),
            };
            this.listAddressMailing = await this._actionUtilClass.executeAction(params, null, this, null, null).then(response => {
                let res = response.result.IPResult;
                var auxList = []
                res.response.forEach(function (item, index) {
                    
                    var state = "";
                    var street = "";
                    var city = "";
                    var postalCode ="";
                    var streetNumber = "";
                    item.map.forEach(function (elemItem, index) {
                        if ( elemItem.type[0] == "postal_code") {
                            postalCode = elemItem.value;
                        } else if ( elemItem.type[0] == "street_number") {
                            streetNumber = elemItem.value;
                        } else if ( elemItem.type[0] == "route") {
                            street = elemItem.value;
                        } else if ( elemItem.type[0] == "locality") {
                            city = elemItem.value;
                        } else if ( elemItem.type[0] == "administrative_area_level_1") {
                            state = elemItem.value;
                        } 
                    });
                    var finalStreet = streetNumber + " " + street ;
                    var addressObject = { 'address': item.address,'index':index, 'state':state, 'street':finalStreet, 'city':city, 'postalCode':postalCode };
                    auxList.push(addressObject);   
                });
                return auxList;
            });
        } else {
            this.listAddressMailing = [];
            this.showGoogleApiResultsMailing = false;
        }
    }

    pushMailingAddress(evt){

        this.showGoogleApiResultsMailing = false; 
        var street = evt.currentTarget.dataset.street;
        var city = evt.currentTarget.dataset.city;
        var state = evt.currentTarget.dataset.state;
        var postal = evt.currentTarget.dataset.postal;
        this.person['ARC_MailingAddressStreet__c'] = street;
        this.person['ARC_MailingAddressCity__c'] = city;
        this.person['ARC_MailingAddressState__c'] = state;
        this.person['ARC_MailingAddressZipCode__c'] = postal;
    
        this.mailingAddressColumns = [];
        var newListAux = [];
        this.headerColumns.forEach(column => {
            if ( (column.fieldName).includes('Mailing') && column.fieldName != 'ARC_IgnoreMailing__c' ){
                var valueNew = column.value;
                var isRequired = true;
                if ( (column.fieldName) == 'ARC_MailingAddressStreet__c') {
                    valueNew = street;
                } else if ( (column.fieldName) == 'ARC_MailingAddressCity__c' ) {
                    valueNew = city;
                } else if ( (column.fieldName) == 'ARC_MailingAddressState__c' ) {
                    valueNew = state;
                } else if ( (column.fieldName) == 'ARC_MailingAddressZipCode__c' ) {
                    valueNew = postal;
                }
                if ((column.fieldName) == 'ARC_MailingAddressStreet2__c') {
                    isRequired = false;
                }
                if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
                    isRequired = false;
                }
                newListAux.push({
                    disableColumn: false,
                    dataType: column.dataType,
                    isUpdateable: column.isUpdateable,
                    options: column.options,
                    label: column.label,
                    isRequired: isRequired,
                    value: valueNew,
                    fieldName: column.fieldName,
                    objectApiName: column.objectApiName                
                });
            }
        });
        this.mailingAddressColumns = newListAux;
        const selectedEvent = new CustomEvent('update', { detail: this.person });
        this.dispatchEvent(selectedEvent);
    }

    pushPhysicalAddress(evt){
        // console.log("entro al pushphysical")
        this.showGoogleApiResults = false; 
        var street = evt.currentTarget.dataset.street;
        var city = evt.currentTarget.dataset.city;
        var state = evt.currentTarget.dataset.state;
        var postal = evt.currentTarget.dataset.postal;
        this.person['ARC_PhysicalAddressStreet__c'] = street;
        this.person['ARC_PhysicalAddressCity__c'] = city;
        this.person['ARC_PhysicalAddressState__c'] = state;
        this.person['ARC_PhysicalAddressZipCode__c'] = postal;
        this.physicalAddressColumns = [];
        var newListAux = [];
        this.headerColumns.forEach(column => {
            if ( (column.fieldName).includes('Physical') ){
                var valueNew = column.value;
                var isRequired = true;
                if ( (column.fieldName) == 'ARC_PhysicalAddressStreet__c') {
                    valueNew = street;
                } else if ( (column.fieldName) == 'ARC_PhysicalAddressCity__c' ) {
                    valueNew = city;
                } else if ( (column.fieldName) == 'ARC_PhysicalAddressState__c' ) {
                    valueNew = state;
                } else if ( (column.fieldName) == 'ARC_PhysicalAddressZipCode__c' ) {
                    valueNew = postal;
                }
                if ((column.fieldName) == 'ARC_PhysicalAddressStreet2__c') {
                    isRequired = false;
                }
                if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
                    isRequired = false;
                }
                newListAux.push({
                    disableColumn: false,
                    dataType: column.dataType,
                    isUpdateable: column.isUpdateable,
                    options: column.options,
                    label: column.label,
                    isRequired: isRequired,
                    value: valueNew,
                    fieldName: column.fieldName,
                    objectApiName: column.objectApiName                
                });
            }
        });
        this.physicalAddressColumns = newListAux;
        const selectedEvent = new CustomEvent('update', { detail: this.person });
        this.dispatchEvent(selectedEvent);
        
    }


    handleChecked(evt){
        // console.log("entro al handlechecked")
        if(evt.target.checked){
            this.showMailingSection = false;
            this.handleEmptyMailing();
            this.person['ARC_IgnoreMailing__c'] = true;
            this.person['ARC_MailingAddressCity__c'] = this.person['ARC_PhysicalAddressCity__c'];
            this.person['ARC_MailingAddressState__c'] = this.person['ARC_PhysicalAddressState__c'];
            this.person['ARC_MailingAddressStreet__c'] = this.person['ARC_PhysicalAddressStreet__c'];
            this.person['ARC_MailingAddressStreet2__c'] = this.person['ARC_PhysicalAddressStreet2__c'];
            this.person['ARC_MailingAddressZipCode__c'] = this.person['ARC_PhysicalAddressZipCode__c'];
            
            const selectedEvent = new CustomEvent('update', { detail: this.person });
            this.dispatchEvent(selectedEvent);
            
        }else{
            var mailingAux = []
            this.headerColumns.forEach(column => {
                var isRequired = true;
                if ( (column.fieldName).includes('Mailing') && column.fieldName != 'ARC_IgnoreMailing__c' ){
                    if ((column.fieldName) == 'ARC_MailingAddressStreet2__c') {
                        isRequired = false;
                    }
                    if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
                        isRequired = false;
                    }
                    mailingAux.push({
                        disableColumn: false,
                        dataType: column.dataType,
                        isUpdateable: column.isUpdateable,
                        options: column.options,
                        label: column.label,
                        isRequired: isRequired,
                        value: "",
                        fieldName: column.fieldName,
                        objectApiName: column.objectApiName                
                    });
                } 
            });
            this.showMailingSection = true;
            this.mailingAddressColumns = mailingAux;
            this.person['ARC_IgnoreMailing__c'] = false;
            const selectedEvent = new CustomEvent('update', { detail: this.person });
            this.dispatchEvent(selectedEvent);
            // console.log("this.person en handle!"+JSON.stringify(this.person))
        }
    }

    handleParentCheck(evt) {
        
        if(evt.target.checked){
            this.showInfoAddress = false;
            this.ignoreAddress = true;
            this.handleEmptyMailing();
            this.handleEmptyPhysical();
            this.person['ARC_IgnoreMailing__c'] = false;
            this.person['ARC_UseParentAddress__c'] = true;
            const selectedEvent = new CustomEvent('update', { detail: this.person });
            
            this.dispatchEvent(selectedEvent);
            
        }else {
            var mailingAux = []
            var physicalAux = []
            this.showInfoAddress = true;
            this.ignoreAddress = false;
            this.showMailingSection = true;
            this.headerColumns.forEach(column => {
                
                var isRequired = true;
                if ( (column.fieldName).includes('Mailing') && column.fieldName != 'ARC_IgnoreMailing__c' ){
                    if ((column.fieldName) == 'ARC_MailingAddressStreet2__c') {
                        isRequired = false;
                    }
                    if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
                        isRequired = false;
                    }
                    mailingAux.push({
                        disableColumn: false,
                        dataType: column.dataType,
                        isUpdateable: column.isUpdateable,
                        options: column.options,
                        label: column.label,
                        isRequired: isRequired,
                        value: "",
                        fieldName: column.fieldName,
                        objectApiName: column.objectApiName                
                    });
                } else if ( (column.fieldName).includes('Physical') ){
                    var isRequired = true;
                    if ((column.fieldName) == 'ARC_PhysicalAddressStreet2__c') {
                        isRequired = false;
                    }
                    if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
                        isRequired = false;
                    }
                    physicalAux.push({
                        disableColumn: false,
                        dataType: column.dataType,
                        isUpdateable: column.isUpdateable,
                        options: column.options,
                        label: column.label,
                        isRequired: isRequired,
                        value: "",
                        fieldName: column.fieldName,
                        objectApiName: column.objectApiName                
                    });
                } 
            });
            //esto estaba comentado
            this.handleEmptyMailing();
            this.handleEmptyPhysical();


            this.mailingAddressColumns = mailingAux;
            this.physicalAddressColumns = physicalAux;
            this.person['ARC_UseParentAddress__c'] = false; 
            const selectedEvent = new CustomEvent('update', { detail: this.person });
            this.dispatchEvent(selectedEvent);
        }
    }
    
    handleEmptyMailing() {
        this.mailingAddressColumns = [];
        this.person['ARC_MailingAddressStreet__c'] = "";
        this.person['ARC_MailingAddressStreet2__c'] = "";
        this.person['ARC_MailingAddressCity__c']= "";
        this.person['ARC_MailingAddressState__c'] = "";
        this.person['ARC_MailingAddressZipCode__c'] = "";
    }

    handleEmptyPhysical() {
        this.physicalAddressColumns = [];
        this.person['ARC_MailingAddressStreet__c'] = "";
        this.person['ARC_PhysicalAddressStreet2__c'] = "";
        this.person['ARC_MailingAddressCity__c']= "";
        this.person['ARC_MailingAddressState__c'] = "";
        this.person['ARC_MailingAddressZipCode__c'] = "";
    }

    
}