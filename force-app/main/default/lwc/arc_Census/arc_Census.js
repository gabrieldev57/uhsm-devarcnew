import insOsCensus from 'vlocity_ins/insOsCensus';
import template from './arc_Census.html'
import { omniscriptUtils, commonUtils, dataFormatter } from 'vlocity_ins/insUtility';
import { track, api } from 'lwc';


export default class arc_Census extends insOsCensus {
    @api osData;
    @api requiredFieldsPrimary = [];
    @api requiredFieldsDependent = [];
    @api visibleFieldsPrimary = [];
    @api visibleFieldsDependent = [];
    @api dependentUseAddress;
    @api jsondata;
    @track addressModified;
    @track hasOneMedical;
    @track hasOneVision;
    @track hasOneDental;
    @track medicalId;
    @track visionId;
    @track dentalId;
    @track planSave = true;
    @track medicalPlanListElements = [];
    @track visionPlanListElements = [];
    @track dentalPlanListElements = [];
    @track requiredFieldMissing = false;
    @track saveActionMembers = new Map();
    @track savedByTemplate = false;
    @track SavedMembers = [];
    @track savedMembersForUncommited = []; 
    @track firstSave = true;
   
    @api get censusInfo() {

        return this._censusInfo;
    }

    set censusInfo(value) {

        this._censusInfo = value;
        if (this.censusInfo.total <= 0) {
            this.omniApplyCallResp(
                {
                    'hasEmployee': false
                }
            )
        } else {
            this.omniApplyCallResp(
                {
                    'hasEmployee': true
                }
            )
        }
        if (this.requiredFieldsPrimary != null) {
            this.requiredFieldsValidation();
        }
    }

    connectedCallback() {

        this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
        if (this.osData.QuoteProcess == 'IFP' || this.osData.QuoteProcess == 'IMApplication') {
            this.stateData = omniscriptUtils.getSaveState(this);

            if (this.omniJsonDef.propSetMap.displaySettings) {
                this.displaySettings = JSON.parse(JSON.stringify(this.omniJsonDef.propSetMap.displaySettings || {}));
            }

            if (this.osData.STEP_SubscriberPersonalInformation && 
                JSON.stringify(this.osData.STEP_SubscriberPersonalInformation) == JSON.stringify(this.osData.savedSubscriberData)) {
                this.omniApplyCallResp(
                    {
                        'newCensus': true,
                    })
                this.parseSavedState(this.stateData); 

            } else if(this.osData.newCensus && this.osData.newCensus == false && 
                JSON.stringify(this.osData.STEP_SubscriberPersonalInformation) == JSON.stringify(this.osData.savedSubscriberData))
                {
                this.omniApplyCallResp(
                    {
                        'savedSubscriberData': this.osData.STEP_SubscriberPersonalInformation
                    })
                this.parseSavedState(this.stateData); 
  
            } else {
                this.omniApplyCallResp(
                    {
                        'clickedCensus': false,
                        'newCensus': false,
                        'savedSubscriberData': this.osData.STEP_SubscriberPersonalInformation,
                        
                    })
                  
                this.init();
            } 
            
            const dataOmniLayout = this.getAttribute('data-omni-layout');
            this.theme = dataOmniLayout === 'newport' ? 'nds' : 'slds';
            this.itemsPerPage = parseInt(this.itemsPerPage, 10);
            this.censusMemberUploadLimit = parseInt(this.censusMemberUploadLimit, 10);
          
          
            
        } else {
            super.connectedCallback();
         }
         if(this.osData.afterCensus == false){
            this.omniApplyCallResp(
                {
                    'requiredFieldMissing': false
                }
            )
        }
        if (this.osData.QuoteProcess == 'IFP') {
            this.hideDiv = this.osData.QuoteProcess == 'IFP' ? true : false;
        } else if (this.osData.QuoteProcess == 'IMApplication') {
            this.hideDiv = this.osData.QuoteProcess == 'IMApplication' ? true : false;

        }
        this.requiredFieldsPrimary = JSON.parse(JSON.stringify(this.osData.requiredFieldsPrimary));
        this.requiredFieldsDependent = JSON.parse(JSON.stringify(this.osData.requiredFieldsDependent));
        this.visibleFieldsPrimary = JSON.parse(JSON.stringify(this.osData.visibleFieldsPrimary));
        this.visibleFieldsDependent = JSON.parse(JSON.stringify(this.osData.visibleFieldsDependent));

        if (this.osData && this.osData.selectedQuoteMedicalPlans) {
            let medicalPlanList = [];
            let medicalPlanDetails = this.osData.selectedQuoteMedicalPlans;

            medicalPlanList = medicalPlanDetails.map(item => {
                return {
                    "value": item.productId,
                    "label": item.Name
                }
            });
            this.medicalPlanListElements = medicalPlanList;
            if (medicalPlanDetails.length == 1) {
                this.medicalId = medicalPlanList[0].value;
                this.hasOneMedical = true;
            }
        }

        if (this.osData && this.osData.selectedQuoteDentalPlans) {
            let dentalPlanList = [];
            let dentalPlanDetails = this.osData.selectedQuoteDentalPlans;

            dentalPlanList = dentalPlanDetails.map(item => {
                return {
                    "value": item.productId,
                    "label": item.Name
                }
            });
            this.dentalPlanListElements = dentalPlanList;
            if (dentalPlanDetails.length == 1) {
                this.dentalId = dentalPlanList[0].value;
                this.hasOneDental = true;
            }

        }

        if (this.osData && this.osData.selectedQuoteVisionPlans) {
            let visionPlanList = [];
            let visionPlanDetails = this.osData.selectedQuoteVisionPlans;

            visionPlanList = visionPlanDetails.map(item => {
                return {
                    "value": item.productId,
                    "label": item.Name
                }
            });
            this.visionPlanListElements = visionPlanList;
            if (visionPlanDetails.length == 1) {
                this.visionId = visionPlanList[0].value;
                this.hasOneVision = true;
            }
        }

        this.jsondata = JSON.parse(JSON.stringify(this.omniJsonData));
    }

    /**
     * Handle initial census load response.
     * @param {Object} response
     */
    handleInitialCensusLoad(response) {
        super.handleInitialCensusLoad(response);
        this.requiredFieldsValidation();
    }
    render() {
        return template;
    }

    saveMembers(needRecalculation) {
        let medicalPlan;
        let visionPlan;
        let dentalPlan;
        if (this.requiredFieldMissing == false) {

            let editedMembers = this.census.filter(m => m.edited); // Filter edited members only

            if (needRecalculation == true) {
                editedMembers = this.census;
            }
            if (editedMembers.length > 0) {

                if (!this.firstSave) {
                    Object.entries(this.saveActionMembers).forEach(m => {
                        for (let member of m) {
                            for (let memberSaved of editedMembers) {
                                if (!memberSaved.addressModified && member.vlocity_ins__MemberIdentifier__c == memberSaved.vlocity_ins__MemberIdentifier__c) {
                                    memberSaved = this.replaceAddress(member, memberSaved);
                                }
                            }
                        }
                    })
                }

                Object.entries(this.saveActionMembers).forEach(m => {
                    for (let member of m) {
                        for (let memberSaved of editedMembers) {
                            if (member.vlocity_ins__MemberIdentifier__c == memberSaved.vlocity_ins__MemberIdentifier__c) {
                                memberSaved.Id = member.Id;
                            }

                        }
                    }
                })

                for (let member of editedMembers) {//plans selected by the primary member are copied to dependents
                    if (member.vlocity_ins__IsPrimaryMember__c) {
                        medicalPlan = member.ARC_MedicalProduct__c;
                        visionPlan = member.ARC_VisionProduct__c;
                        dentalPlan = member.ARC_DentalProduct__c;
                        for (let dependent of member.dependents) {
                            dependent.ARC_MedicalProduct__c = medicalPlan;
                            dependent.ARC_DentalProduct__c = dentalPlan;
                            dependent.ARC_VisionProduct__c = visionPlan;
                            if (member.addressModified && dependent.ARC_UseParentAddress__c) {
                                dependent = this.replaceAddress(member, dependent)
                                if (!dependent.hasOwnProperty('edited')) {
                                    dependent.edited = true;
                                    if(this.osData.QuoteProcess != 'SmallGroupEnrollment'){
                                        editedMembers.push(dependent);
                                    }
                                }
                            }
                        }
                    }
                }
                this.isLoaded = false;
                let saveAction = JSON.parse(JSON.stringify(this.omniJsonDef.propSetMap.saveAction || {}));

                saveAction.inputMap = { ...saveAction.inputMap, ...this.censusInputMap(editedMembers) };
                this.invokeService(saveAction, 'InsCensusService', 'updateMembers')
                    .then(saveResponse => {
                        this.loadCensus().then(loadResponse => {

                            if (needRecalculation == true) {
                                this.isLoaded = true;
                            } else {
                                const newCensusMap = this.generateUpdatedCensusMap(loadResponse);
                                this.handleUpdateCensusLoad(newCensusMap, saveResponse);
                                this.omniApplyCallResp(
                                    {
                                        'needRecalculation': true,
                                        'uncommittedChanges': false,
                                        'memberEntered': false,
                                        'nextStepValidation': true
                                    }
                                );
                                if (this.savedByTemplate == false) {

                                    this.saveActionMembers = newCensusMap;
                                }

                            }
                        });
                    })

                    .catch(err => this.showError({ message: err }));
            }
            if (!this.savedByTemplate && !this.firstSave) {
                this.SavedMembers = editedMembers;
            }

            this.savedMembersForUncommited = editedMembers;

        }
        if (!this.savedByTemplate) {
            this.firstSave = false;
        }
        this.savedByTemplate = false;
    }

    addEmployee() {
        this.omniApplyCallResp(
            {
                'uncommittedChanges': true,
                'memberEntered': false
            }
        );
        let member = this.addNewMember(false);

        this.census.push(member);
        this.calculateCensusInfo();
        this.navigateToLastPage();
        //this.requiredFieldsValidation();
    }

    // Add new dependent under an employee record.
    handleNewDependent(ev) {
        const employee = this.employees.find(
            e =>
                dataFormatter.getNamespacedProperty(e, 'MemberIdentifier__c') ===
                dataFormatter.getNamespacedProperty(ev.detail, 'MemberIdentifier__c')
        );

        if (employee) {
            const member = this.addNewMember(true, employee);
            this.census.push(member);
            this.calculateCensusInfo();
            this.omniApplyCallResp(
                {
                    'uncommittedChanges': true
                }
            );
        }
    this.requiredFieldsValidation();
    }

    addNewMember(addDependent, employee) {
        let newMember = this.headers.reduce((result, header) => {
            result[header.name] = '';
            return result;
        }, {});
        newMember[`vlocity_ins__IsPrimaryMember__c`] = !addDependent;
        newMember[`vlocity_ins__PrimaryMemberIdentifier__c`] = addDependent
            ? dataFormatter.getNamespacedProperty(employee, 'MemberIdentifier__c')
            : '';
        newMember[`vlocity_ins__MemberIdentifier__c`] = dataFormatter.uniqueKey();
        newMember['Relationship'] = '';
        newMember.memberIndex = this.census.length; // Index starts at zero, so next one = current count

        //newMember.uuid = this.employees.uuid;

        newMember.edited = true;
        return newMember;
    }

    handleDeleteCensusLoad(newCensusMap, memberIdentifiers) {
        memberIdentifiers.forEach(memberId => {
            if (newCensusMap[memberId]) {
                delete newCensusMap[memberId];
            }
        });
        this.census = Object.values(newCensusMap).map(member => {
            //    member.uuid = dataFormatter.uniqueKey();
            return member;
        });
        this.calculateCensusInfo();
        if (this.currentPageHasNoItems()) {
            this.navigateToLastPage();
        }
    }

    handleUpdateCensusLoad(newCensusMap, saveMembersResponse) {
        const saveResponse = JSON.parse(saveMembersResponse);
        let updatedCensusMap = { ...newCensusMap };
        Object.values(updatedCensusMap).forEach(member => delete member.error); // Reset errors

        if (saveResponse.addPlanErrors) {
            this.showError({ message: saveResponse.addPlanErrors });
        }
        if (saveResponse.errors) {
            saveResponse.errors.forEach(erroredMember => {
                const memberIdentifier = dataFormatter.getNamespacedProperty(erroredMember, 'MemberIdentifier__c');
                if (memberIdentifier) {
                    updatedCensusMap[memberIdentifier].error = erroredMember.error;
                }
            });
        }
        this.census = Object.values(updatedCensusMap).map(member => {
            //    member.uuid = dataFormatter.uniqueKey();
            return member;
        });

        this.calculateCensusInfo();
    }
    // Updates member information in census.
    handleUpdate(ev) {
        let member = { ...ev.detail };
        member.addressModified;
        if (member.vlocity_ins__IsPrimaryMember__c && member.ARC_IgnoreMailing__c == "") {
            member.addressModified = true;
        } else {
            member.addressModified = true;
        }
        let memberIndex = this.census.findIndex(
            m =>
                dataFormatter.getNamespacedProperty(m, 'MemberIdentifier__c') ===
                dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c')
        );
        if (memberIndex > -1) {
            member.edited = true;

            member.vlocity_ins__IsSpouse__c = (member.ARC_DependentRelationship__c == 'Spouse' || member.ARC_DependentRelationship__c == 'Domestic Partner') ? true : false;
            if (this.osData.QuoteProcess != 'SmallGroupQuote') {//|| this.osData.QuoteProcess != 'SmallGroupEnrollment') {
                member.ARC_EnrollmentCensusMember__c = true;
            }

            this.census[memberIndex] = member;
           
            
            this.calculateCensusInfo(); // Since census is changed.
        }
     
        if(this.osData.afterCensus == false){
            this.omniApplyCallResp(
                {
                    'clickedCensus': true
                    
                }
            )
        }
        
       
        this.requiredFieldsValidation();
        
    }

    filemapCreated(ev) {
        this.isLoaded = false;
        const csvData = ev.detail.data || [];
        if (csvData.length > this.censusMemberUploadLimit) {
            this.showError({
                message: this.labels.InsOSCensusErrorExceedRowCount.replace('{0}', this.censusMemberUploadLimit)
            });
            this.isLoaded = true;
            return;
        }

        if (this.medicalPlanListElements) {

            for (const elemCensus of Object.values(csvData)) {

                var hasProduct = false;
                for (const planName of this.medicalPlanListElements) {
                    if (elemCensus.ARC_MedicalProduct__c == planName.label) {
                        elemCensus.ARC_MedicalProduct__c = planName.value;
                        hasProduct = true;

                    }
                }
                if (!hasProduct) {
                    elemCensus.ARC_MedicalProduct__c = '';
                }
            }
        }

        if (this.visionPlanListElements) {

            for (const elemCensus of Object.values(csvData)) {

                var hasProduct = false;
                for (const planName of this.visionPlanListElements) {
                    if (elemCensus.ARC_VisionProduct__c == planName.label) {
                        elemCensus.ARC_VisionProduct__c = planName.value;
                        hasProduct = true;

                    }
                }
                if (!hasProduct) {
                    elemCensus.ARC_VisionProduct__c = '';
                }
            }
        }

        if (this.dentalPlanListElements) {

            for (const elemCensus of Object.values(csvData)) {

                var hasProduct = false;
                for (const planName of this.dentalPlanListElements) {
                    if (elemCensus.ARC_DentalProduct__c == planName.label) {
                        elemCensus.ARC_DentalProduct__c = planName.value;
                        hasProduct = true;

                    }
                }
                if (!hasProduct) {
                    elemCensus.ARC_DentalProduct__c = '';
                }
            }
        }

        this.csvDataToCensus(csvData);
    }

    csvDataToCensus(csvData) {
        const availableEnrollmentPlanOptions = this.availableEnrollmentPlanOptions;
        let empUniqueId = null;
        let currentDepBatch = [];
        let members = csvData.map(csvRow => {
            let member = this.addNewMember(false);
            Object.keys(csvRow).forEach(key => {
                member[key] = csvRow[key];
            });
            if (member['Relationship']) {
                if (member['Relationship'] === 'Employee' || member['Relationship'] === 'Subscriber') {
                    empUniqueId = dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c');
                } else if (member['Relationship'] === 'Spouse') {
                    member[`vlocity_ins__IsPrimaryMember__c`] = false;
                    member[`vlocity_ins__IsSpouse__c`] = true;
                    member[`vlocity_ins__PrimaryMemberIdentifier__c`] = empUniqueId || '';
                } else {
                    member[`vlocity_ins__IsPrimaryMember__c`] = false;
                    member[`vlocity_ins__IsSpouse__c`] = false;
                    member[`vlocity_ins__PrimaryMemberIdentifier__c`] = empUniqueId || '';
                }
                if (empUniqueId === null) {
                    currentDepBatch.push(member);
                } else {
                    currentDepBatch.forEach(m => {
                        m[`vlocity_ins__PrimaryMemberIdentifier__c`] = empUniqueId;
                    });
                    currentDepBatch.length = 0;
                }
            }
            if (member[this.planHeaderFieldName]) {
                this.addPlansToMember(member, availableEnrollmentPlanOptions);
            }
            return member;
        });
        this.formatAllDateFields(members);
        this.census = members;
        this.calculateCensusInfo();
        this.navigateToFirstPage();
        if (!this.requiredFieldMissing) {
            this.savedByTemplate = true;
            this.saveMembers();
        } else {
            this.isLoaded = true;
            this.savedByTemplate = false;

        }

        this.omniApplyCallResp(
            {
                'templateEntered': true,
                "memberEntered": false
            })
    }


    deleteMembers(memberIdentifiers) {
        let deletionIds = [];
        this.census.forEach(member => {
            // Extract Ids for members
            if (
                memberIdentifiers.some(
                    id => dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c') === id
                ) &&
                member.Id
            ) {
                deletionIds.push({ Id: member.Id });
            }
        });
        if (deletionIds.length > 0) {
            // Make API call to delete the members
            this.isLoaded = false;
            let deleteAction = JSON.parse(JSON.stringify(this.omniJsonDef.propSetMap.deleteAction || {}));
            deleteAction.inputMap = { ...deleteAction.inputMap, ...this.censusInputMap(deletionIds) };
            this.invokeService(deleteAction, 'InsCensusService', 'deleteMembers')
                .then(() => {
                    this.loadCensus().then(loadResponse => {
                        const newCensusMap = this.generateUpdatedCensusMap(loadResponse);
                        this.handleDeleteCensusLoad(newCensusMap, memberIdentifiers);
                    });
                })
                .catch(err => this.showError({ message: err }));
        } else {
            // Delete members from client end since associate record ID is not created yet.
            this.census = this.census.filter(
                member =>
                    !memberIdentifiers.includes(dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c'))
            );
            this.calculateCensusInfo();
            if (this.currentPageHasNoItems()) {
                this.navigateToLastPage();
            }
        }
        const editedMembers = this.census.filter(m => m.edited); // Filter edited members only
        if (editedMembers.length == 0) {
            this.omniApplyCallResp(
                {
                    "uncommittedChanges": false,
                    "requiredFieldMissing" : false
                }
            )
        }

    }

    calculateCensusInfo() {
      console.log("entro al calculateCensusInfo")
        let censusInfo = { total: this.census.length, empCount: 0, empChCount: 0, empSpCount: 0, empFaCount: 0 };
        let employees = [];
        let savedAux = [];
        let empDeps = {}; // Stores dependents information on primary member's ID
        // Add employee dependents
        this.census.forEach(member => {
            if (dataFormatter.getNamespacedProperty(member, 'IsPrimaryMember__c')) {
                // Check if a primary member
                if (this.selectedEmployee) {
                    const selectedEmployeeIdentifier = dataFormatter.getNamespacedProperty(
                        this.selectedEmployee,
                        'MemberIdentifier__c'
                    );
                    const memberIdentifier = dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c');
                    if (selectedEmployeeIdentifier === memberIdentifier) {
                        member.isSelected = true;
                    }
                }
                employees.push(member);
            } else {
                const primaryMemberId = dataFormatter.getNamespacedProperty(member, 'PrimaryMemberIdentifier__c');
                if (empDeps[primaryMemberId]) {
                    empDeps[primaryMemberId].push(member);
                } else {
                    empDeps[primaryMemberId] = [member];
                }
            }
        });

        // Update census info
        employees.forEach((member, index) => {
            const memberIdentifier = dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c');
            let hasSpouse = false;
            let hasChild = false;

            member.index = index;
            member.dependents = empDeps[memberIdentifier] ? empDeps[memberIdentifier] : [];
            member.dependents.forEach(dependent => {
                const dependentIsSpouse = dataFormatter.getNamespacedProperty(dependent, 'IsSpouse__c');
                if (dependentIsSpouse) {
                    hasSpouse = true;
                } else {
                    hasChild = true;
                }
            });

            if (hasSpouse && hasChild) {
                censusInfo.empFaCount++;
            } else if (hasSpouse && !hasChild) {
                censusInfo.empSpCount++;
            } else if (!hasSpouse && hasChild) {
                censusInfo.empChCount++;
            } else if (!hasSpouse && !hasChild) {
                censusInfo.empCount++;
            }
        });
        this.censusInfo = censusInfo;
        this.employees = employees;
        this.empDeps = empDeps;

        // if (JSON.stringify(this.SavedMembers) == JSON.stringify(this.employees)) {

        //     this.omniApplyCallResp(

        //         {
        //             "uncommittedChanges": true
        //         }
        //     );

        // } else
        console.log("opcion 1: "+ JSON.stringify(this.savedMembersForUncommited))
        console.log("opcion 2: "+ JSON.stringify(this.employees))


        if(this.savedMembersForUncommited){
            savedAux = this.savedMembersForUncommited;
            savedAux.forEach(member => {
                delete member.memberIndex;
            })
             console.log("opcion 1: "+ JSON.stringify(savedAux))
             console.log("opcion 2: "+ JSON.stringify(this.employees))

             console.log("opcion 1 diferente?: "+ JSON.parse(JSON.stringify(savedAux)) != JSON.parse(JSON.stringify(this.employees)))
             console.log("opcion 2 iguales?: "+ JSON.parse(JSON.stringify(savedAux)) == JSON.parse(JSON.stringify(this.employees)))


            if (JSON.parse(JSON.stringify(savedAux)) != JSON.parse(JSON.stringify(this.employees))) {
                this.omniApplyCallResp(
    
                    {
                        "uncommittedChanges": true
                    }
                );
            }
            else if (JSON.parse(JSON.stringify(savedAux)) == JSON.parse(JSON.stringify(this.employees))) {
                this.omniApplyCallResp(
    
                    {
                        "uncommittedChanges": false
                    }
                );
            }
    

        }
        
      
    }

    handleInitialCensusLoad(response) {
        this.isLoaded = true;
        const parsedData = JSON.parse(response);
        const responseError = parsedData.errors || parsedData.error;
        if (responseError && responseError !== 'OK') {
            this.showError({ message: responseError });
            this.isValidCensus = false;
            return;
        }
        this.census = parsedData.census.members.map((m, index) => {
            m.memberIndex = index;
            //    m.uuid = dataFormatter.uniqueKey();

            return m;
           
        });
        this.initHeaders(parsedData.census.headers);
        this.calculateCensusInfo();
    }

    // Delete all census members on button click
    @api
    clearAll() {
      //  console.log("this.osdata aftercensus?: " + JSON.stringify(this.osData.afterCensus))
        if(this.osData.afterCensus == true || this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData.QuoteProcess == 'SmallGroupEnrollment' || this.osData.templateEntered == true){
            const memberIdentifiers = this.census.map(member =>
                dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c')
            );
    
            this.deleteMembers(memberIdentifiers);
            this.closeDeleteAllModal();
            this.omniApplyCallResp(
                {
                    'uncommittedChanges': true,
                }
            )
        }
        
    }

    requiredFieldsValidation() {
     console.log("entro al requiredFieldsValidation")

        let tempRequiredFieldsMissing = [];
        let hasErrorDates = false;

        let myDependentMap = new Map();
        let moreThanOneSpouse = false;

        this.census.forEach(member => {

            
            let error = false;
            let futureBirthDate = false;
            let useMailing = member['ARC_IgnoreMailing__c'];
            let useParent = false;

            if (this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData.QuoteProcess == 'SmallGroupEnrollment') {
                useMailing = false;
                useParent = false;
            }

            this.requiredFieldsPrimary.forEach(primaryField => {
                if (primaryField == 'ARC_MedicalProduct__c' && this.hasOneMedical) {
                    member[primaryField] = this.medicalId;
                }
                if (primaryField == 'ARC_DentalProduct__c' && this.hasOneDental) {
                    member[primaryField] = this.dentalId;
                }
                if (primaryField == 'ARC_VisionProduct__c' && this.hasOneVision) {
                    member[primaryField] = this.visionId;
                }
                if (member.vlocity_ins__IsPrimaryMember__c == true && !member[primaryField]) {
                    if (useMailing == true && !primaryField.includes('Mailing')) {
                        tempRequiredFieldsMissing.push(primaryField);
                        
                        error = true

                    }
                    else if (useMailing == false) {
                        tempRequiredFieldsMissing.push(primaryField);
                        error = true
                        // if (this.osData.QuoteProcess == 'IFP' || this.osData.QuoteProcess == 'IMApplication'){
                        //     error = false;
                            
                        // }
                    }

                } if (!error && primaryField == 'vlocity_ins__Birthdate__c') {
                    var currentdate = new Date();
                    var memberBirthdate = new Date(member[primaryField]);
                    if (currentdate.getTime() < memberBirthdate.getTime()) {
                        futureBirthDate = true;
                        hasErrorDates = true;

                    }

                }

            });
           
                this.requiredFieldsDependent.forEach(dependentField =>{
                    if(member.vlocity_ins__IsPrimaryMember__c == false && !member[dependentField] && (!dependentField.includes('Mailing') && !dependentField.includes('Physical'))){
                        console.log(dependentField)
                        if ( useParent == true && (!dependentField.includes('Mailing') && !dependentField.includes('Physical')) ) {
                           
                            tempRequiredFieldsMissing.push(dependentField);
                            error = true
                        // } else if ( useMailing == true && !dependentField.includes('Mailing') ) {
                        //     tempRequiredFieldsMissing.push(dependentField);
                        //     error = true
                        } else if (useMailing == false && useParent == false) {
                     
                            tempRequiredFieldsMissing.push(dependentField);
                            error = true
                        } 
                    } 
                      
                   
                    if ( !error && dependentField == 'vlocity_ins__Birthdate__c') {
                       
                        var currentdate = new Date(); 
                        var memberBirthdate = new Date(member[dependentField]);
                        if (currentdate.getTime() < memberBirthdate.getTime()) {
                            futureBirthDate = true;
                            hasErrorDates = true;
                        }
                    }
                    
                })
                
                if (member.vlocity_ins__IsPrimaryMember__c == false && member.ARC_DependentRelationship__c == 'Spouse') {
                    if (!myDependentMap.has(member.vlocity_ins__PrimaryMemberIdentifier__c)) {
                        myDependentMap.set(member.vlocity_ins__PrimaryMemberIdentifier__c, { quantity: 1 });
                    } else {
                        myDependentMap.get(member.vlocity_ins__PrimaryMemberIdentifier__c).quantity++;
    
    
                        if (myDependentMap.get(member.vlocity_ins__PrimaryMemberIdentifier__c).quantity > 1) {
                            moreThanOneSpouse = true;
    
                        }
                    }
                }
            // }
           
            //Code for demo only
                tempRequiredFieldsMissing.forEach(reqField =>{
          
                    if (reqField.includes('Mailing') || reqField.includes('Physical')){
                        tempRequiredFieldsMissing.pop(reqField);
                    } 
            })
            //


            if (error) {
                member.error = 'Required field/s missing';
            } else if (futureBirthDate) {
                member.error = 'Invalid Birthdate. Future dates are not allowed.';
            } else if (moreThanOneSpouse) {
                member.error = 'Primary member cant have more than one spouse.';
            } else {
                delete member.error;
            }
        });


        if (this.hasOneMedical && this.planSave || this.hasOneDental && this.planSave || this.hasOneVision && this.planSave) {
            this.planSave = false;
            this.saveMembers(true);
        }  
   

        console.log("temprequired:"+tempRequiredFieldsMissing + " "+ tempRequiredFieldsMissing.length)
        if (tempRequiredFieldsMissing.length > 0) {
            this.requiredFieldMissing = true;
            console.log("errorrrrr")
            if(this.osData.afterCensus == false){
            //     console.log("UPS ERROR EN REQUIRED 1!")
                this.omniApplyCallResp(
                    {
                        'requiredFieldMissing': false,
                    }
                )
             }
            
        } else if (hasErrorDates) {
            this.requiredFieldMissing = true;
            if(this.osData.afterCensus == false){
            //     console.log("UPS ERROR EN REQUIRED 2!")
            this.omniApplyCallResp(
                {
                    'requiredFieldMissing': false,
                }
            )
        }
            
        } else if (moreThanOneSpouse) {
            this.requiredFieldMissing = true;
            if(this.osData.afterCensus == false){
            //     console.log("UPS ERROR EN REQUIRED 3!")
            this.omniApplyCallResp(
                {
                    'requiredFieldMissing': false,
                }
            )
        }
            
        } else if (this.visionPlanListElements.length == 0 || this.dentalPlanListElements.length == 0 || this.medicalPlanListElements.length == 0) {
            this.requiredFieldMissing = false;
            this.omniApplyCallResp(
                {
                    'requiredFieldMissing': true,
                }
            )

        } else {
            this.requiredFieldMissing = false;

            this.omniApplyCallResp(
                {
                    'requiredFieldMissing': true,
                }
            )
        }
    }

    replaceAddress(member, memberSaved) {
        memberSaved.ARC_PhysicalAddressCity__c = member.ARC_PhysicalAddressCity__c;
        memberSaved.ARC_PhysicalAddressState__c = member.ARC_PhysicalAddressState__c;
        memberSaved.ARC_PhysicalAddressStreet__c = member.ARC_PhysicalAddressStreet__c;
        memberSaved.ARC_PhysicalAddressStreet2__c = member.ARC_PhysicalAddressStreet2__c;
        memberSaved.ARC_PhysicalAddressZipCode__c = member.ARC_PhysicalAddressZipCode__c;
        memberSaved.ARC_MailingAddressCity__c = member.ARC_MailingAddressCity__c;
        memberSaved.ARC_MailingAddressState__c = member.ARC_MailingAddressState__c;
        memberSaved.ARC_MailingAddressStreet__c = member.ARC_MailingAddressStreet__c;
        memberSaved.ARC_MailingAddressStreet2__c = member.ARC_MailingAddressStreet2__c;
        memberSaved.ARC_MailingAddressZipCode__c = member.ARC_MailingAddressZipCode__c;

        return memberSaved;
    }

}