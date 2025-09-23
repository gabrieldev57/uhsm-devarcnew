import { api, track } from 'lwc';
import insOsCensusInfo from 'vlocity_ins/insOsCensusInfo';
import template from './arc_DemoCensusInfo.html';
import { omniscriptUtils, commonUtils, dataFormatter } from 'vlocity_ins/insUtility';
import { OmniscriptActionCommonUtil } from 'vlocity_ins/omniscriptActionUtils';

import pubsub from 'vlocity_ins/pubsub';

export default class arc_DemoCensusInfo extends insOsCensusInfo {
    @api osData;
    @api requiredFieldsPrimary;
    @api requiredFieldsDependent;
    @api visibleFieldsPrimary;
    @api visibleFieldsDependent;
    @api tabAddressPosition;
    @api ignoreAddress = false;
    medicalValue;
    visionValue;
    dentalValue;
    hasOneMedical = false;
    hasOneVision = false;
    hasOneDental = false;
    customColumns = [];
    mapAddress = new Map();
    pubsubPayload = {
        changeFieldValue: this.handleChange.bind(this)
    };
    @track showGoogleApiResults = false;
    @track showGoogleApiResultsMailing = false;
    @track listAddress = [];
    @track listAddressMailing = [];
    @track customAddressPhysical = [];
    @track mailingAddressColumns = [];
    @track physicalAddressColumns = [];
    @track showMailingSection = false;
    @track ignoreValue = false;
    @track showInfoAddress = false;
    @track isEnrollment = false;
    @track listPrimaryAddress = [];
    @track counter = 0;
    @api hideDeleteDependent = false;
    @api hideAddressDependent = false;
    render() {
        return template;
    }

    connectedCallback() {
        ///////console.log("ENTRO AL CENSUSINFO!!!")
        this.hideDeleteDependent = (this.osData.FieldsetType == 'IFPEnroll' || this.osData.FieldsetType == 'IFPProgramChangePlan' || this.osData.FieldsetType == 'IFPProgramChangeMultiple') ? true : false;

        this.hideAddressDependent = this.osData.FieldsetType == 'IFPEnroll' ? false : true;


        super.connectedCallback();

        if (this.osData != null && this.osData.FieldsetType == 'IFPProgramChangeAddMember' || this.osData.FieldsetType == 'IFPProgramChangeMultiple' && this.person.programChangeDependent) {
            this.hideDeleteDependent = false;
        }

        if (this.osData != null && this.osData.FieldsetType == "IFPShop") {
            this.hideDeleteDependent = false;
            this.listPrimaryAddress = this.osData.Address;
            this.populatePhysicalAddress();
            this.ignoreValue = true;
            this.showMailingSection = false;
        }
        this._actionUtilClass = new OmniscriptActionCommonUtil();
        // this.mailingAddressColumns = this.mailingAddressColumnsFunc();
        this.physicalAddressColumns = this.physicalAddressColumnsFunc();
        this.dependentUseAddress = true;

    }
    handleMultiValueUpdate(event) {
        const dataset = event.target && event.target.dataset;
        if (!dataset) {
            return;
        }
        const fieldName = dataset.fieldName;
        let currentValue = this.person[fieldName] ? this.person[fieldName].split(';') : [];
        const fieldValue = dataset.fieldValue;
        if (currentValue.includes(fieldValue)) {
            currentValue = currentValue.filter(value => value !== fieldValue);
        } else {
            currentValue.push(fieldValue);
        }
        this.person[fieldName] = currentValue.join(';');
        commonUtils.triggerCustomEvent.call(this, 'update', { detail: this.person });
    }

    handleChange(payload) {
        this.person[payload.fieldName] = payload.value;
        commonUtils.triggerCustomEvent.call(this, 'update', { detail: this.person });
    }

    handleActive(event) {
        const tab = event.target;
        // 

        this.tabAddressPosition = true;

    }

    populatePhysicalAddress() {
        this.showGoogleApiResults = false;
        var street = this.listPrimaryAddress.BillingStreet;
        ///console.log("POPULANDO!")
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
            if ((column.fieldName).includes('Physical')) {
                var valueNew = column.value;
                var isRequired = true;
                if ((column.fieldName) == 'ARC_PhysicalAddressStreet__c') {
                    valueNew = street;
                } else if ((column.fieldName) == 'ARC_PhysicalAddressCity__c') {
                    valueNew = city;
                } else if ((column.fieldName) == 'ARC_PhysicalAddressState__c') {
                    valueNew = state;
                } else if ((column.fieldName) == 'ARC_PhysicalAddressZipCode__c') {
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
        ///console.log("this.person", this.person);
        ///////console.log("populatePhysicalAddress" + JSON.stringify(this.person))
        const selectedEvent = new CustomEvent('update', { detail: this.person });

        this.dispatchEvent(selectedEvent);
    }


    physicalAddressColumnsFunc() {

        this.customAddressPhysical = [];
        this.showInfoAddress = true;
        if (this.isDependent == true) {
            this.ignoreAddress = true;
        }
        if (this.ignoreAddress == true) {
            this.showInfoAddress = false;
            this.person['ARC_UseParentAddress__c'] = true;
        }
        this.headerColumns.forEach(column => {
            var isRequired = true;
            if ((column.fieldName).includes('Physical')) {
                this.isEnrollment = true;
                if ((column.fieldName) == 'ARC_PhysicalAddressStreet2__c') {
                    isRequired = false;
                }
                if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment'
                    || this.osData != null && this.osData.QuoteProcess == 'IMApplication'
                ) {
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
        return this.customAddressPhysical;

    }

    // mailingAddressColumnsFunc() {

    //     var customAddressMailing = [];
    //     if (this.isDependent == true) {
    //         this.ignoreAddress = true;
    //     }
    //     if (this.ignoreAddress == true) {
    //         this.showMailingSection = false;
    //         this.person['ARC_UseParentAddress__c'] = true;
    //     }
    //     // this.headerColumns.forEach(column => {
    //     //     if (column.fieldName == 'ARC_IgnoreMailing__c' && column.value == true) {
    //     //         this.ignoreValue = true;
    //     //         this.showMailingSection = false;
    //     //     }
    //     // }
    //     // );



    //     this.headerColumns.forEach(column => {
    //         var isRequired = true;
    //         if ( !this.hideMailingSection && (column.fieldName).includes('Mailing') && column.fieldName != 'ARC_IgnoreMailing__c' ){
    //             this.showInfoAddress = true;
    //             this.isEnrollment = true;
    //             if ((column.fieldName) == 'ARC_MailingAddressStreet2__c') {
    //                 isRequired = false;
    //             }
    //             if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
    //                 isRequired = false;
    //             }
    //             customAddressMailing.push({
    //                 disableColumn: false,
    //                 dataType: column.dataType,
    //                 isUpdateable: column.isUpdateable,
    //                 options: column.options,
    //                 label: column.label,
    //                 isRequired: isRequired,
    //                 value: column.value,
    //                 fieldName: column.fieldName,
    //                 objectApiName: column.objectApiName                
    //             });
    //         } 
    //     });
    //     return customAddressMailing;
    // }

    get customHeaderColumns() {
        let medicalPlanList = [];
        let visionPlanList = [];
        let dentalPlanList = [];
        var isMinor = false;
        var isFemale = false;
        var isNewborn = false;
        let parsedOsData = { ...this.osData };
        if (this.osData && parsedOsData.selectedQuoteMedicalPlans) {
            let medicalPlanDetails = parsedOsData.selectedQuoteMedicalPlans;
            medicalPlanList = medicalPlanDetails.map(item => {
                return {
                    "value": item.productId,
                    "label": item.Name
                }
            });
            if (medicalPlanDetails.length == 1) {
                this.medicalValue = medicalPlanList[0].value;
                this.hasOneMedical = true;
            }
        }

        if (this.osData && parsedOsData.selectedQuoteVisionPlans) {
            let visionPlanDetails = parsedOsData.selectedQuoteVisionPlans;
            visionPlanList = visionPlanDetails.map(item => {
                return {
                    "value": item.productId,
                    "label": item.Name
                }
            });
            if (visionPlanDetails.length == 1) {
                this.visionValue = visionPlanList[0].value;
                this.hasOneVision = true;
            }
        }

        if (this.osData && parsedOsData.selectedQuoteDentalPlans) {
            let dentalPlanDetails = parsedOsData.selectedQuoteDentalPlans;
            dentalPlanList = dentalPlanDetails.map(item => {
                return {
                    "value": item.productId,
                    "label": item.Name
                }
            });
            if (dentalPlanDetails.length == 1) {
                this.dentalValue = dentalPlanList[0].value;
                this.hasOneDental = true;
            }
        }

        this.customColumns = [];
        this.headerColumns.forEach(column => {
            if (!(column.fieldName).includes('Mailing') && !(column.fieldName).includes('Physical')) {
                var isRequiredVar = false;
                var containsField = false;
                if (this.osData?.Reason == "Add Newborn") {
                    this.requiredFieldsDependent = this.requiredFieldsDependent.filter(function (e) { return e !== 'vlocity_ins__SocialSecurityNumber__c' })
                }
                if (this.isDependent) {
                    isRequiredVar = this.requiredFieldsDependent.includes(column.fieldName);
                    containsField = this.visibleFieldsDependent.includes(column.fieldName);
                } else if (this.osData.FieldsetType != 'IFPProgramChangeAddMember' || this.osData.FieldsetType != 'IFPProgramChangeMultiple') {
                    isRequiredVar = this.requiredFieldsPrimary.includes(column.fieldName);
                    containsField = this.visibleFieldsPrimary.includes(column.fieldName);
                }

                if (column.fieldName === 'ARC_UseParentAddress__c') {

                    if (this.isDependent && column.value == true) {
                        this.showInfoAddress = false;
                        this.showMailingSection = false;
                        this.ignoreAddress = true;
                    }
                    return;
                }

                if (column.fieldName === 'ARC_MedicalProduct__c' && this.isDependent == false) {
                    var customValue = column.value;
                    if (this.hasOneMedical) {
                        customValue = this.medicalValue;
                    }

                    if (medicalPlanList.length == 0) {
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
                    if (this.hasOneVision) {
                        customValue = this.visionValue;
                    }

                    if (visionPlanList.length == 0) {
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
                    if (this.hasOneDental) {
                        customValue = this.dentalValue;
                    }

                    if (dentalPlanList.length == 0) {
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
                    var customOptions = [];
                    let newOptions = [];
                    let childOption = [];
                    var customType = column.dataType;
                    var customLabel = column.label;
                    var customMaxLength = column.maxlength;
                    var customMinLength = column.minlength;
                    var customDisableColumn = false;


                    if (column.fieldName === 'vlocity_ins__Birthdate__c') {
                        var currentdate = new Date();
                        var depMemberBirthdate = new Date(column.value);
                        var depMonth_diff = Date.now() - depMemberBirthdate.getTime();
                        var depAge_dt = new Date(depMonth_diff);
                        var depYear = depAge_dt.getUTCFullYear();
                        var depAge = Math.abs(depYear - 1970);

                        var priorDate = new Date().setDate(currentdate.getDate() - 30)
                        if (depAge < 18) {
                            isMinor = true;
                        }
                        // if(depAge == 10){
                        //     testMinor = true;
                        // }
                        if (depMemberBirthdate.getTime() >= priorDate) {
                            isNewborn = true;
                        }
                    }

                    if (column.fieldName === 'vlocity_ins__Email__c' || column.fieldName === 'ARC_Phone__c') {
                        if (isMinor) {
                            customDisableColumn = true;
                        }
                    }

                    if (column.fieldName === 'vlocity_ins__SocialSecurityNumber__c') {
                        customType = 'password';
                        if (isNewborn) {
                            isRequiredVar = false;
                        }
                    }

                    if (column.fieldName === 'ARC_Smoker__c') {
                        if (isMinor) {
                            customDisableColumn = true;
                        } else {
                            customType = 'boolean';
                        }
                        customLabel = this.isDependent ? "Is dependent a smoker?" : "Are you a smoker?";
                    }

                    if (column.fieldName === 'vlocity_ins__Gender__c' && column.value == "Female") {
                        isFemale = true;
                    }

                    if (column.fieldName === 'ARC_DependentRelationship__c' && column.fieldName != 'vlocity_ins__Gender__c') {
                        ///console.log(column.fieldName, column.value);
                        customOptions = JSON.parse(JSON.stringify(column.options));
                        newOptions.push(customOptions.find(option => option.value === "Child"));
                        newOptions.push(customOptions.find(option => option.value === "Spouse"));
                        if (isMinor == true) {
                            childOption.push(customOptions.find(option => option.value === "Child"));
                        }

                        if (this.osData?.Reason?.includes("Add Existing Member")) {
                            if (column.value == "Past Primary") {
                                column.value = "Spouse";

                            }
                            if (!(this.osData.InvolvedMembers.filter(member => member.Existing === true).map(member => member.Id).includes(this.person?.Id) || this.person?.isNew)) {
                                ///console.log('this.person.Id', this.person.Id);
                                customDisableColumn = true;
                            }
                            // column.value = null;
                        }
                    }



                    if (column.fieldName === 'ARC_isPregnant__c') {
                        if (!isFemale || isMinor) {
                            customDisableColumn = true;

                        }
                        customLabel = "Are you Pregnant?";
                        customLabel = this.isDependent ? "Is dependent pregnant?" : "Are you pregnant?";

                    }

                    if (column.fieldName === 'ARC_HeightInches__c') {
                        customType = 'string';

                    }
                    if (column.fieldName === 'ARC_HeightFeet__c') {
                        customType = 'string';

                    }
                    if (column.fieldName === 'ARC_Height__c') {
                        customDisableColumn = true;

                    }
                    if (column.fieldName === 'ARC_Weight__c') {
                        customType = 'string';

                    }

                    if (this.osData.FieldsetType == 'IFPEnroll' || this.osData.FieldsetType == 'IFPProgramChangePlan') {
                        if (column.fieldName === 'vlocity_ins__Birthdate__c') {
                            customDisableColumn = true;
                        }
                    }

                    // Birthday field read only for IFPShop and the primary in the second step

                    if (this.osData.FieldsetType == 'IFPShop' && this.isDependent == false) {
                        if (column.fieldName === 'vlocity_ins__Birthdate__c') {
                            column.isUpdateable = false;
                        }
                    }


                    if (isMinor && column.fieldName === 'ARC_DependentRelationship__c' && column.fieldName != 'vlocity_ins__Gender__c') {

                        this.customColumns.push({
                            disableColumn: customDisableColumn,
                            dataType: customType,
                            isUpdateable: column.isUpdateable,
                            options: childOption,
                            label: customLabel,
                            isRequired: isRequiredVar,
                            value: column.value,
                            fieldName: column.fieldName,
                            objectApiName: column.objectApiName,
                            maxlength: customMaxLength,
                            minlength: customMinLength
                        });
                    } else if (column.fieldName === 'ARC_DependentRelationship__c' && column.fieldName != 'vlocity_ins__Gender__c') {
                        this.customColumns.push({
                            disableColumn: customDisableColumn,
                            dataType: customType,
                            isUpdateable: column.isUpdateable,
                            options: newOptions,
                            label: customLabel,
                            isRequired: isRequiredVar,
                            value: column.value,
                            fieldName: column.fieldName,
                            objectApiName: column.objectApiName,
                            maxlength: customMaxLength,
                            minlength: customMinLength

                        });
                    } else {
                        this.customColumns.push({
                            disableColumn: customDisableColumn,
                            dataType: customType,
                            isUpdateable: column.isUpdateable,
                            options: column.options,
                            label: customLabel,
                            isRequired: isRequiredVar,
                            value: column.value,
                            fieldName: column.fieldName,
                            objectApiName: column.objectApiName,
                            maxlength: customMaxLength,
                            minlength: customMinLength

                        });
                    }





                    return;
                }
            }
        });

        return this.customColumns
    }

    async googleAPi(e) {
        var value = e.target.value;
        if (value && value.length > 1) {
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
                    var postalCode = "";
                    var streetNumber = "";
                    item.map.forEach(function (elemItem, index) {
                        if (elemItem.type[0] == "postal_code") {
                            postalCode = elemItem.value;
                        } else if (elemItem.type[0] == "street_number") {
                            streetNumber = elemItem.value;
                        } else if (elemItem.type[0] == "route") {
                            street = elemItem.value;
                        } else if (elemItem.type[0] == "locality") {
                            city = elemItem.value;
                        } else if (elemItem.type[0] == "administrative_area_level_1") {
                            state = elemItem.value;
                        }
                    });
                    var finalStreet = streetNumber + " " + street;
                    var addressObject = { 'address': item.address, 'index': index, 'state': state, 'street': finalStreet, 'city': city, 'postalCode': postalCode };
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
        if (value && value.length > 1) {
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
                    var postalCode = "";
                    var streetNumber = "";
                    item.map.forEach(function (elemItem, index) {
                        if (elemItem.type[0] == "postal_code") {
                            postalCode = elemItem.value;
                        } else if (elemItem.type[0] == "street_number") {
                            streetNumber = elemItem.value;
                        } else if (elemItem.type[0] == "route") {
                            street = elemItem.value;
                        } else if (elemItem.type[0] == "locality") {
                            city = elemItem.value;
                        } else if (elemItem.type[0] == "administrative_area_level_1") {
                            state = elemItem.value;
                        }
                    });
                    var finalStreet = streetNumber + " " + street;
                    var addressObject = { 'address': item.address, 'index': index, 'state': state, 'street': finalStreet, 'city': city, 'postalCode': postalCode };
                    auxList.push(addressObject);
                });
                return auxList;
            });
        } else {
            this.listAddressMailing = [];
            this.showGoogleApiResultsMailing = false;
        }
    }

    // pushMailingAddress(evt){

    //     this.showGoogleApiResultsMailing = false; 
    //     var street = evt.currentTarget.dataset.street;
    //     var city = evt.currentTarget.dataset.city;
    //     var state = evt.currentTarget.dataset.state;
    //     var postal = evt.currentTarget.dataset.postal;
    //     this.person['ARC_MailingAddressStreet__c'] = street;
    //     this.person['ARC_MailingAddressCity__c'] = city;
    //     this.person['ARC_MailingAddressState__c'] = state;
    //     this.person['ARC_MailingAddressZipCode__c'] = postal;

    //     this.mailingAddressColumns = [];
    //     var newListAux = [];
    //     this.headerColumns.forEach(column => {
    //         if ( (column.fieldName).includes('Mailing') && column.fieldName != 'ARC_IgnoreMailing__c' ){
    //             var valueNew = column.value;
    //             var isRequired = true;
    //             if ( (column.fieldName) == 'ARC_MailingAddressStreet__c') {
    //                 valueNew = street;
    //             } else if ( (column.fieldName) == 'ARC_MailingAddressCity__c' ) {
    //                 valueNew = city;
    //             } else if ( (column.fieldName) == 'ARC_MailingAddressState__c' ) {
    //                 valueNew = state;
    //             } else if ( (column.fieldName) == 'ARC_MailingAddressZipCode__c' ) {
    //                 valueNew = postal;
    //             }
    //             if ((column.fieldName) == 'ARC_MailingAddressStreet2__c') {
    //                 isRequired = false;
    //             }
    //             if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
    //                 isRequired = false;
    //             }
    //             newListAux.push({
    //                 disableColumn: false,
    //                 dataType: column.dataType,
    //                 isUpdateable: column.isUpdateable,
    //                 options: column.options,
    //                 label: column.label,
    //                 isRequired: isRequired,
    //                 value: valueNew,
    //                 fieldName: column.fieldName,
    //                 objectApiName: column.objectApiName                
    //             });
    //         }
    //     });
    //     this.mailingAddressColumns = newListAux;
    //     const selectedEvent = new CustomEvent('update', { detail: this.person });
    //     this.dispatchEvent(selectedEvent);
    // }

    pushPhysicalAddress(evt) {
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
            if ((column.fieldName).includes('Physical')) {
                var valueNew = column.value;
                var isRequired = true;
                if ((column.fieldName) == 'ARC_PhysicalAddressStreet__c') {
                    valueNew = street;
                } else if ((column.fieldName) == 'ARC_PhysicalAddressCity__c') {
                    valueNew = city;
                } else if ((column.fieldName) == 'ARC_PhysicalAddressState__c') {
                    valueNew = state;
                } else if ((column.fieldName) == 'ARC_PhysicalAddressZipCode__c') {
                    valueNew = postal;
                }
                if ((column.fieldName) == 'ARC_PhysicalAddressStreet2__c') {
                    isRequired = false;
                }
                if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication') {
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


    handleChecked(evt) {
        if (evt.target.checked) {
            this.showMailingSection = false;
            this.handleEmptyMailing();
            // this.person['ARC_IgnoreMailing__c'] = true;
            ///////console.log("handlechecked" + JSON.stringify(this.person))

            const selectedEvent = new CustomEvent('update', { detail: this.person });
            this.dispatchEvent(selectedEvent);

        } else {
            var mailingAux = []
            // this.headerColumns.forEach(column => {
            //     var isRequired = true;
            //     if ( (column.fieldName).includes('Mailing') && column.fieldName != 'ARC_IgnoreMailing__c' ){
            //         if ((column.fieldName) == 'ARC_MailingAddressStreet2__c') {
            //             isRequired = false;
            //         }
            //         if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
            //             isRequired = false;
            //         }
            //         mailingAux.push({
            //             disableColumn: false,
            //             dataType: column.dataType,
            //             isUpdateable: column.isUpdateable,
            //             options: column.options,
            //             label: column.label,
            //             isRequired: isRequired,
            //             value: "",
            //             fieldName: column.fieldName,
            //             objectApiName: column.objectApiName                
            //         });
            //     } 
            // });
            this.showMailingSection = true;
            this.mailingAddressColumns = mailingAux;
            // this.person['ARC_IgnoreMailing__c'] = false;
            ///////console.log("pushPhysicalAddress2" + JSON.stringify(this.person))
            const selectedEvent = new CustomEvent('update', { detail: this.person });
            this.dispatchEvent(selectedEvent);
        }
    }

    handleParentCheck(evt) {
        if (evt.target.checked) {
            this.showInfoAddress = false;
            this.ignoreAddress = true;
            this.handleEmptyMailing();
            this.handleEmptyPhysical();
            // this.person['ARC_IgnoreMailing__c'] = false;
            this.person['ARC_UseParentAddress__c'] = true;
            ///////console.log("handleParentCheck" + JSON.stringify(this.person))
            const selectedEvent = new CustomEvent('update', { detail: this.person });
            console.log("selectedEvent this.person", this.person);

            this.dispatchEvent(selectedEvent);

        } else {
            var mailingAux = []
            var physicalAux = []
            this.showInfoAddress = true;
            this.ignoreAddress = false;
            this.showMailingSection = true;
            this.headerColumns.forEach(column => {

                var isRequired = true;
                // if ( (column.fieldName).includes('Mailing') && column.fieldName != 'ARC_IgnoreMailing__c' ){
                //     if ((column.fieldName) == 'ARC_MailingAddressStreet2__c') {
                //         isRequired = false;
                //     }
                //     if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication'){
                //         isRequired = false;
                //     }
                //     mailingAux.push({
                //         disableColumn: false,
                //         dataType: column.dataType,
                //         isUpdateable: column.isUpdateable,
                //         options: column.options,
                //         label: column.label,
                //         isRequired: isRequired,
                //         value: "",
                //         fieldName: column.fieldName,
                //         objectApiName: column.objectApiName                
                //     });
                // } 
                if ((column.fieldName).includes('Physical')) {
                    var isRequired = true;
                    if ((column.fieldName) == 'ARC_PhysicalAddressStreet2__c') {
                        isRequired = false;
                    }
                    if (this.osData != null && this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData != null && this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData != null && this.osData.QuoteProcess == 'IMApplication') {
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
            ///////console.log("handleParentCheck2" + JSON.stringify(this.person))
            const selectedEvent = new CustomEvent('update', { detail: this.person });
            console.log("selectedEvent this.person", this.person);

            this.dispatchEvent(selectedEvent);
        }
    }

    handleEmptyMailing() {
        this.mailingAddressColumns = [];
        this.person['ARC_MailingAddressStreet__c'] = "";
        this.person['ARC_MailingAddressStreet2__c'] = "";
        this.person['ARC_MailingAddressCity__c'] = "";
        this.person['ARC_MailingAddressState__c'] = "";
        this.person['ARC_MailingAddressZipCode__c'] = "";
    }

    handleEmptyPhysical() {
        this.physicalAddressColumns = [];
        this.person['ARC_PhysicalAddressStreet__c'] = "";
        this.person['ARC_PhysicalAddressStreet2__c'] = "";
        this.person['ARC_PhysicalddressCity__c'] = "";
        this.person['ARC_PhysicalAddressState__c'] = "";
        this.person['ARC_PhysicalAddressZipCode__c'] = "";
    }


}