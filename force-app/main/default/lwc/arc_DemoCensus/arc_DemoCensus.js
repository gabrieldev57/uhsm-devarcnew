import { api, track } from 'lwc';
import insOsCensus from 'vlocity_ins/insOsCensus';
import { omniscriptUtils, commonUtils, dataFormatter } from 'vlocity_ins/insUtility';
import { OmniscriptActionCommonUtil } from "vlocity_ins/omniscriptActionUtils";
import template from './arc_DemoCensus.html';


export default class arc_DemoCensus extends insOsCensus {
  @api osData;
  @api originalOSData;
  @api requiredFieldsPrimary = [];
  @api requiredFieldsDependent = [];
  @api visibleFieldsPrimary = [];
  @api visibleFieldsDependent = [];
  @api dependentUseAddress;
  @api ignoreAddress;
  @track addressModified;
  @track hasOneMedical;
  @track hasOneVision;
  @track hasOneDental;
  @track medicalId;
  @track visionId;
  @track dentalId;
  // @track clonedCensus = false;
  @track planSave = true;
  @track isEnrollment = false;
  @track medicalPlanListElements = [];
  @track visionPlanListElements = [];
  @track dentalPlanListElements = [];
  @track requiredFieldMissing = false;
  @track saveActionMembers = new Map();
  @track savedMemberIds = [];
  @track saveCheck = false;
  @track savedByTemplate = false;
  @track SavedMembers = [];
  @track savedAux = {};
  @track savedMembersForUncommited = [];
  @track firstSave = true;
  @track auxCensusInfo = [];
  @track censunsInfoTrigger;
  @track finishedSaving = false;
  @track onlyOneOver26 = false;
  @track addedNewPrimary = false;
  @track saveMemberFilterForNewPrimary = false;
  @track involvedMembers;
  @track allCensusMembers;

  existingSpouse = false;

  @api moreThan3Dependents = false;
  extraMemberPopupDisplayed = false;
  memberAmmount = 0;
  childsAmmount = 0;
  pcInitialChildsAmmount = 0


  currentPrimary;
  getSavedCensus = true;
  removingPrimary = false;

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
    // if (this.requiredFieldsPrimary != null) {
    //     this.requiredFieldsValidation();
    // }
  }


  compareMaps(map1, map2) {
    var testVal;
    if (map1 == undefined || map2 == undefined) {
      return false;
    } else if (map1.size !== map2.size) {
      return false;
    }
    for (var [key, val] of map1) {
      testVal = map2.get(key);
      // in cases of an undefined value, make sure the key
      // actually exists on the object so there are no false positives
      if (testVal !== val || (testVal === undefined && !map2.has(key))) {
        return false;
      }
    }
    return true;
  }

  connectedCallback() {
    commonUtils.triggerCustomEvent.call(this, 'update', { detail: this.member });
    if (!this.osData) {
      this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
      this.originalOSData = JSON.parse(JSON.stringify(this.omniJsonData));
    }

    // this.addEventListener('update', this.handleUpdate.bind(this));
    if (this.omniGetSaveState(JSON.parse(JSON.stringify(this.omniJsonData)).CensusId) && this.getSavedCensus /*&& !this.osData.savedSubscriberData*/ && (this.osData.FieldsetType == 'IFPShop' || this.osData.FieldsetType == 'IFPEnroll')) {
      this.osData = this.omniGetSaveState(JSON.parse(JSON.stringify(this.omniJsonData)).CensusId);
      
      if(this.osData.FieldsetType == 'IFPShop' ){
        let jsonBirthDate = this.osData?.STEP_SubscriberPersonalInformation?.DATE_SubscriberDateOfBirth;
        let originalJsonBirthDate = this.originalOSData?.STEP_SubscriberPersonalInformation?.DATE_SubscriberDateOfBirth;
        if(originalJsonBirthDate != jsonBirthDate){
          this.osData.STEP_SubscriberPersonalInformation.DATE_SubscriberDateOfBirth = originalJsonBirthDate;
        }
      }
      this.getSavedCensus = false;
    }

    if (!this.osData?.savedFieldSetType) {
      this.omniApplyCallResp(
        {
          'savedFieldSetType': this.osData.FieldsetType
        })
    }


    if (!this.osData?.savedReason) {
      this.omniApplyCallResp(
        {
          'savedReason': this.osData.Reason
        })
    }

    if (this.osData.FieldsetType == 'IFPEnroll') {
      this.isEnrollment = true;
    }

    if (this.osData.FieldsetType == 'IFPProgramChangeMultiple' || this.osData.FieldsetType == 'IFPProgramChangeAddMember' || this.osData.STEP_ChangeReason?.SEL_ChangeReason?.includes('Add Existing Member')) {
      if (this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member') && this.osData.STEP_RemoveMember != null || this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member') && this.osData.FieldsetType == 'IFPProgramChangeMultiple' && !this.osData.savedRemoved || this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member') && this.osData.FieldsetType == 'IFPProgramChangeAddMember' && !this.osData.savedRemoved) {
        let selectedRemovedMembers = this.osData.STEP_RemoveMember?.EDITBLK_RemoveMembers?.filter(m => m.CHK_Delete).map(m => m.TXT_CensusMemberId);

        this.omniApplyCallResp(
          {
            'selectedRemovedMembers': selectedRemovedMembers,
            'savedRemoved': true
          })
      }
      if (this.osData.STEP_ChangeReason?.SEL_ChangeReason?.includes('Add Existing Member') && this.osData.STEP_AddExistingMembers != null) {
        let selectedAddedExistingMembers = [this.osData.STEP_AddExistingMembers?.EB_AddMember]?.flat().filter(m => m.CHK_Add).map(m => m.Id);

        this.omniApplyCallResp(
          {
            'selectedAddedExistingMembers': selectedAddedExistingMembers,
            'savedAddedExistingMembers': true
          })
      }
    }



    this.stateData = omniscriptUtils.getSaveState(this);


    if (this.omniJsonDef.propSetMap.displaySettings) {
      this.displaySettings = JSON.parse(JSON.stringify(this.omniJsonDef.propSetMap.displaySettings || {}));
    }

    if (this.osData.FieldsetType == 'IFPShop') {

      if (this.osData.STEP_SubscriberPersonalInformation &&
        JSON.stringify(this.osData.STEP_SubscriberPersonalInformation) == JSON.stringify(this.osData.savedSubscriberData)) {

        this.omniApplyCallResp(
          {
            'newCensus': true,
          })
        this.parseSavedState(this.stateData);

      } else if (this.osData.newCensus && this.osData.newCensus == false &&
        JSON.stringify(this.osData.STEP_SubscriberPersonalInformation) == JSON.stringify(this.osData.savedSubscriberData)) {

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
            'savedSubscriberData': this.osData.STEP_SubscriberPersonalInformation

          })
        this.init();
      }
    } else if ((this.osData.FieldsetType == 'IFPProgramChangeMultiple' || this.osData.FieldsetType == 'IFPProgramChangeAddMember') && (this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member')) || this.osData.STEP_ChangeReason?.SEL_ChangeReason?.includes('Add Existing Member')) {

      if (this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member')) {
        let removedMembers = this.osData.STEP_RemoveMember?.EDITBLK_RemoveMembers?.filter(m => m.CHK_Delete).map(m => m.TXT_CensusMemberId);

        if (JSON.stringify(this.osData.selectedRemovedMembers) == JSON.stringify(removedMembers) && this.osData.Reason == this.osData.savedReason) {
          this.omniApplyCallResp(
            {
              'savedReason': this.osData.Reason
            })
          this.parseSavedState(this.stateData);
        } else {
          this.omniApplyCallResp(
            {
              'savedReason': this.osData.Reason
            })
          this.init();
        }
      }
      if (this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Add Existing Member')) {

        let addedExistingMembers = [this.osData.STEP_AddExistingMembers?.EB_AddMember]?.flat().filter(m => m.CHK_Add).map(m => m.Id);

        if (JSON.stringify(this.osData.selectedAddedExistingMembers) == JSON.stringify(addedExistingMembers) && this.osData.Reason == this.osData.savedReason) {
          this.omniApplyCallResp(
            {
              'savedReason': this.osData.Reason
            })
          this.parseSavedState(this.stateData);
        } else {
          this.omniApplyCallResp(
            {
              'savedReason': this.osData.Reason
            })
          this.init();
        }
      }

    } else if (this.osData.Reason != this.osData.savedReason) {
      this.omniApplyCallResp(
        {
          'savedReason': this.osData.Reason
        })
      this.init();
    }
    else {
      if (this.stateData && this.osData.savedFieldSetType == this.osData.FieldsetType) {
        this.omniApplyCallResp(
          {
            'savedReason': this.osData.Reason
          })
        this.parseSavedState(this.stateData);

      } else {
        this.omniApplyCallResp(
          {
            'savedReason': this.osData.Reason
          })
        this.init();
      }

    }
    // this.init();

    const dataOmniLayout = this.getAttribute('data-omni-layout');
    this.theme = dataOmniLayout === 'newport' ? 'nds' : 'slds';
    this.itemsPerPage = parseInt(this.itemsPerPage, 10);
    this.censusMemberUploadLimit = parseInt(this.censusMemberUploadLimit, 10);
    this.ignoreAddress = true;

    if (this.osData.FieldsetType == 'IFPShop') {
      this.requiredFieldMissing = false;
    }

    this.censunsInfoTrigger = false;
    if (this.osData.afterCensus == false) {
      this.omniApplyCallResp(
        {
          'requiredFieldMissing': false
        }
      )
    }

    //  this.osData.nextStepValidation = false;
    //  this.osData.uncommittedChanges = false;
    //  this.omniApplyCallResp(
    //      {
    //          'uncommittedChanges': false,
    //          'nextStepValidation': false
    //      }
    //  );



    //Hides divs in the html for families and individual members
    if (this.osData.QuoteProcess == 'IFP') {
      this.hideDiv = this.osData.QuoteProcess == 'IFP' ? true : false;
    } else if (this.osData.QuoteProcess == 'IMApplication') {
      this.hideDiv = this.osData.QuoteProcess == 'IMApplication' ? true : false;
    }
    this.hideFile = this.osData.clonedCensus === true ? true : false;

    this.requiredFieldsPrimary = JSON.parse(JSON.stringify(this.osData.requiredFieldsPrimary));
    this.visibleFieldsPrimary = JSON.parse(JSON.stringify(this.osData.visibleFieldsPrimary));
    this.requiredFieldsDependent = JSON.parse(JSON.stringify(this.osData.requiredFieldsDependent));
    this.visibleFieldsDependent = JSON.parse(JSON.stringify(this.osData.visibleFieldsDependent));

    // if(this.osData?.Reason == "Add Newborn"){
    //     this.requiredFieldsDependent = this.requiredFieldsDependent.filter(function(e) { return e !== 'vlocity_ins__SocialSecurityNumber__c' })
    // }
    //Connectedcallback code for the plans selected in plan selection (only SGEnrollment OS is using it)
    // if (this.osData && this.osData.selectedQuoteMedicalPlans) {
    //     let medicalPlanList = [];
    //     let medicalPlanDetails = this.osData.selectedQuoteMedicalPlans;

    //     medicalPlanList = medicalPlanDetails.map(item => {
    //         return {
    //             "value": item.productId,
    //             "label": item.Name
    //         }
    //     });
    //     this.medicalPlanListElements = medicalPlanList;
    //     if (medicalPlanDetails.length == 1) {
    //         this.medicalId = medicalPlanList[0].value;
    //         this.hasOneMedical = true;
    //     }
    // }

    // if (this.osData && this.osData.selectedQuoteDentalPlans) {
    //     let dentalPlanList = [];
    //     let dentalPlanDetails = this.osData.selectedQuoteDentalPlans;

    //     dentalPlanList = dentalPlanDetails.map(item => {
    //         return {
    //             "value": item.productId,
    //             "label": item.Name
    //         }
    //     });
    //     this.dentalPlanListElements = dentalPlanList;
    //     if (dentalPlanDetails.length == 1) {
    //         this.dentalId = dentalPlanList[0].value;
    //         this.hasOneDental = true;
    //     }

    // }

    // if (this.osData && this.osData.selectedQuoteVisionPlans) {
    //     let visionPlanList = [];
    //     let visionPlanDetails = this.osData.selectedQuoteVisionPlans;

    //     visionPlanList = visionPlanDetails.map(item => {
    //         return {
    //             "value": item.productId,
    //             "label": item.Name
    //         }
    //     });
    //     this.visionPlanListElements = visionPlanList;
    //     if (visionPlanDetails.length == 1) {
    //         this.visionId = visionPlanList[0].value;
    //         this.hasOneVision = true;
    //     }
    // }

    this._actionUtilClass = new OmniscriptActionCommonUtil();


    // if(!this.saveActionMembers.length > 0 && this.osData.saveActionMembers){
    //     this.saveActionMembers = this.osData.saveActionMembers;

    // }
    this.finishedSaving = false;
    this.saveForLater();
  }
  /**

* Set UI to previous saved state

* @param {Object} stateData

*/
  init() {
    if (!this.censusId) {
      this.showError({
        message: this.labels.InsOSCensusErrorMissingParameter.replace('{0}', 'censusId')
      });
      this.isValidCensus = false;
      this.isLoaded = true;
      return;
    }
    this.loadCensus().then(response => {

      this.handleInitialCensusLoad(response);
    }); // Fetching census data from API
  }


  loadCensus() {

    let initAction = JSON.parse(JSON.stringify(this.omniJsonDef.propSetMap.initAction || {}));
    const inputMapFromProperties = {
      censusId: this.censusId,
      ...(this.fieldsetName && { fieldsetName: this.fieldsetName })
    };
    initAction.inputMap = { ...initAction.inputMap, ...inputMapFromProperties };
    return this.invokeService(initAction, 'InsCensusService', 'getMembers').catch(err => {
      this.showError({ message: err })
    }
    );
  }

  parseSavedState(stateData) {

    if (this.osData?.savedCensus) {

      this.census = this.osData.savedMemberIds;
    } else {

      this.census = stateData.census;
    }
    this.headers = stateData.headers;

    this.labels = stateData.labels;

    this.calculateCensusInfo();

    this.isLoaded = true;
  }

  render() {
    return template;
  }

  //Saves members that were entered in the census.
  saveMembers(needRecalculation) {

    if (this.osData.STEP_ChangeReason?.CHK_AddParents == true && !needRecalculation) {

      this.savedMemberIds = JSON.parse(JSON.stringify(this.census));
    }
    let newPrimaryIsMinorEffDate = true;
    let atLeastOneMemberAdded = true;
    if (this.osData.NewPrimaryIsMinor && this.osData.STEP_PrepareYourCensus.FRML_PrimaryIsMinorEffDate) {
      newPrimaryIsMinorEffDate = true;
    } else {
      newPrimaryIsMinorEffDate = false;
    }
    this.osData.nextStepValidation = true;
    this.omniApplyCallResp(
      {
        'nextStepValidation': true
      }
    );

    if (this.osData.FieldsetType == 'IFPProgramChangeAddMember' || this.osData.FieldsetType == 'IFPProgramChangeMultiple') {

      let thereIsNewMember = this.census.filter(m => m.isNew);
      atLeastOneMemberAdded = thereIsNewMember.length > 0 ? true : false;

    }
    this.requiredFieldsValidation();




    if (this.requiredFieldMissing == false && !newPrimaryIsMinorEffDate && this.saveMemberFilterForNewPrimary && atLeastOneMemberAdded) {
      if (this.osData.STEP_ChangeReason?.CHK_AddParents == true) {
        this.census = this.editCensusBeforeSave(this.census);
      }
      let editedMembers = this.census.filter(m => m.edited); // Filter edited members only
      if (needRecalculation == true || editedMembers.length == 0) {
        editedMembers = this.census;
      }
      if (editedMembers.length > 0) {

        editedMembers.forEach(element => {
          if (element?.vlocity_ins__FirstName__c?.length == 15) {
            element.vlocity_ins__FirstName__c += ' ';
          }
          if (element?.vlocity_ins__LastName__c?.length == 15) {
            element.vlocity_ins__LastName__c += ' ';
          }
          if (element?.vlocity_ins__Email__c?.length == 15) {
            element.vlocity_ins__Email__c += ' ';
          }

        });

        //PRGGRAM CHANGE
        if (this.osData.FieldsetType == 'IFPProgramChangeAddMember' || this.osData.FieldsetType == 'IFPProgramChangeMultiple' || this.osData.FieldsetType == 'IFPProgramChangePlan') {
          if (this.census.filter(m => m.vlocity_ins__IsPrimaryMember__c && (m.vlocity_ins__IsSpouse__c || m.ARC_DependentRelationship__c == 'Child')) && !this.osData.STEP_ChangeReason?.CHK_AddParents) {
            if (!this.allCensusMembers?.length) {
              this.allCensusMembers = this.osData.savedMemberIds;
            }

            let savePrimaryId;
            let savePrimaryIdentifier;
            if (this.allCensusMembers?.length) {
              this.allCensusMembers?.forEach(element => {
                if (element.vlocity_ins__IsPrimaryMember__c && element.ARC_DependentRelationship__c == null) {
                  savePrimaryId = element.Id;
                  savePrimaryIdentifier = element.vlocity_ins__MemberIdentifier__c;
                }
              });
            }



            editedMembers.forEach(element => {
              if (element.vlocity_ins__IsSpouse__c) {

                element.vlocity_ins__IsPrimaryMember__c = false;


                element.vlocity_ins__RelatedCensusMemberId__c = savePrimaryId;

                element.vlocity_ins__PrimaryMemberIdentifier__c = savePrimaryIdentifier;
              } else if (!element.vlocity_ins__IsPrimaryMember__c) {

                if (!this.osData.STEP_ChangeReason?.CHK_AddParents) {
                  element.vlocity_ins__RelatedCensusMemberId__c = savePrimaryId;
                  element.vlocity_ins__PrimaryMemberIdentifier__c = savePrimaryIdentifier;
                }


              }
            });
          }


        }
        //replaces address information for dependents after the first save
        if (!this.firstSave && this.osData.savedMemberIds) {
          Object.entries(this?.osData.savedMemberIds).forEach(m => {
            for (let member of m) {
              for (let memberSaved of editedMembers) {
                if (!memberSaved.addressModified && member.vlocity_ins__MemberIdentifier__c == memberSaved.vlocity_ins__MemberIdentifier__c) {
                  memberSaved = this.replaceAddress(member, memberSaved);
                }
              }
            }
          })
        }
        //Fixes an issue with members Id's
        if (this.osData.savedMemberIds) {

          Object.entries(this.osData.savedMemberIds).forEach(m => {
            for (let member of m) {
              for (let memberSaved of editedMembers) {
                if (member.vlocity_ins__MemberIdentifier__c == memberSaved.vlocity_ins__MemberIdentifier__c) {

                  memberSaved.Id = member.Id;
                  // memberSaved.isNew = false;

                }

              }
            }
          })
        }


        //plans and address information selected by the primary member are copied to dependents

        if (needRecalculation == false) {
          for (let member of editedMembers) {
            if (member.vlocity_ins__IsPrimaryMember__c) {
              if (member.dependents) {
                this.omniApplyCallResp(
                  {
                    'hasDependents': true
                  }
                );
                for (let dependent of member.dependents) {

                  if (dependent.ARC_DependentRelationship__c == 'Spouse') {
                    dependent.vlocity_ins__IsSpouse__c = true;
                  }
                  if (member.addressModified && dependent.ARC_UseParentAddress__c) {

                    dependent = this.replaceAddress(member, dependent)
                    if (!dependent.hasOwnProperty('edited')) {
                      dependent.edited = true;
                      if (this.osData.QuoteProcess != 'SmallGroupEnrollment') {
                        editedMembers.push(dependent);
                      }
                    }

                    if (dependent.isNew) {
                      dependent.ARC_ActiveMember__c = "";
                    }
                  }
                }
              }

            }
          }
        }
        this.isLoaded = false;

        if ((this.osData.FieldsetType == 'IFPProgramChangePlan' || this.osData.FieldsetType == 'IFPProgramChangeMultiple')
          && this.osData.STEP_RemoveMember != null && this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member')) {
          let primaryRemoved = false;
          let removedMembers = this.osData.STEP_RemoveMember.EDITBLK_RemoveMembers;

          removedMembers.forEach(element => {
            if (element.CHK_Delete == true && element.CHK_isPrimary == true) {
              primaryRemoved = true;
            }
          });

          if (!this.allCensusMembers?.length) {
            this.allCensusMembers = this.osData.savedMemberIds;

          }


          if (primaryRemoved) {

            let savePrimaryId;
            let savePrimaryIdentifier;

            if (this.allCensusMembers?.length) {
              this.allCensusMembers?.forEach(element => {
                if (element.vlocity_ins__IsPrimaryMember__c && element.ARC_DependentRelationship__c == null) {
                  savePrimaryId = element.Id;
                  savePrimaryIdentifier = element.vlocity_ins__MemberIdentifier__c;
                }
              });
            }

            editedMembers.forEach(element => {
              if (element.vlocity_ins__IsSpouse__c) {

                element.vlocity_ins__IsPrimaryMember__c = false;
                element.vlocity_ins__RelatedCensusMemberId__c = savePrimaryId;
                element.vlocity_ins__PrimaryMemberIdentifier__c = savePrimaryIdentifier;
              } else {

                element.vlocity_ins__RelatedCensusMemberId__c = savePrimaryId;
                element.vlocity_ins__PrimaryMemberIdentifier__c = savePrimaryIdentifier;
              }
            });
          }
        }



        let saveAction = JSON.parse(JSON.stringify(this.omniJsonDef.propSetMap.saveAction || {}));
        //Saves census
        saveAction.inputMap = { ...saveAction.inputMap, ...this.censusInputMap(editedMembers) };
        //If the user profile is member community it will use the IP for encrypted censusId, else will use the census
        //service class.

        if (this.osData.userProfile == 'Member Community Profile') {

          this.IPInput = {
            censusId: saveAction.inputMap.censusId,
            Members: saveAction.inputMap.census.members
          }
          console.log('this.IPInput', JSON.stringify(this.IPInput));
          const params = {
            input: JSON.stringify(this.IPInput),
            sClassName: 'vlocity_ins.IntegrationProcedureService',
            sMethodName: 'CustomUpdateCensus_GuestUsers',
            options: '{}'
          };
          this._actionUtilClass
            .executeAction(params, null, this, null, null)
            //this.invokeService(saveAction, 'InsCensusService', 'updateMembers')
            .then(response => {
              this.loadCensus().then(loadResponse => {
                if (needRecalculation == true) {
                  this.isLoaded = true;
                }
                else {
                  const newCensusMap = this.generateUpdatedCensusMap(loadResponse);
                  this.handleUpdateCensusLoadEncrypted(newCensusMap);
                  this.omniApplyCallResp(
                    {
                      'needRecalculation': true,
                      'uncommittedChanges': false,
                      'memberEntered': false,
                      'nextStepValidation': false,
                      'savedCensus': true
                    }
                  );
                  if (this.savedByTemplate == false) {
                    if (!this.osData.STEP_ChangeReason?.CHK_AddParents) {
                      this.saveActionMembers = newCensusMap;
                      Object.entries(this.saveActionMembers).forEach(element => {
                        let newMember = this.census.filter(item => item.vlocity_ins__MemberIdentifier__c == element[1].vlocity_ins__MemberIdentifier__c);
                        if (newMember.length != 0) {
                          this.savedMemberIds.push(newMember[0]);
                        }

                      });
                    }
                    this.omniApplyCallResp(
                      {
                        'savedMemberIds': this.savedMemberIds
                      }
                    );
                  }

                }
              })
                .then(async () => {
                  await this.omniNextStep();
                })
              this.isLoaded = true;
              this.finishedSaving = true;
            })
            .catch((error) => {
              console.error(error, 'ERROR');
            });
        } else {


          this.invokeService(saveAction, 'InsCensusService', 'updateMembers')
            .then(response => {

              this.loadCensus()
                .then(loadResponse => {
                  if (needRecalculation == true) {
                    this.isLoaded = true;
                  } else {
                    const newCensusMap = this.generateUpdatedCensusMap(loadResponse);
                    this.handleUpdateCensusLoad(newCensusMap, response);
                    this.omniApplyCallResp(
                      {
                        'needRecalculation': true,
                        'memberEntered': false,
                        'nextStepValidation': false,
                        'savedCensus': true

                      }
                    );

                    this.saveActionMembers = newCensusMap;

                    if (!this.osData.STEP_ChangeReason?.CHK_AddParents) {
                      Object.entries(this.saveActionMembers).forEach(element => {
                        let newMember = this.census.filter(item => item.vlocity_ins__MemberIdentifier__c == element[1].vlocity_ins__MemberIdentifier__c);
                        if (newMember.length != 0) {
                          this.savedMemberIds.push(newMember[0]);
                        }

                      });
                    } else {
                      this.savedMemberIds.forEach(element => {
                        if (element.Id == null) {

                          element.Id = Object.values(this.saveActionMembers).filter(item => item.vlocity_ins__MemberIdentifier__c == element.vlocity_ins__MemberIdentifier__c)[0].Id;
                        }
                      });
                    }

                    this.omniApplyCallResp(
                      {
                        'savedMemberIds': this.savedMemberIds
                      }
                    );

                  }
                  this.isLoaded = true;
                }
                )
                .then(async () => {
                  await this.omniNextStep();

                })
            })
            .catch((error) => {
              console.error(error, 'ERROR');
            });
        }

        this.omniApplyCallResp(
          {
            'savedMembersForUncommited': this.census
          }
        );

        this.savedMembersForUncommited = this.census;
        this.saveCheck = true;

      }

      this.omniApplyCallResp(
        {
          'auxSavedMembers': this.formatARCHeight(this.census)
        }
      );
      //Setting variables for functions after saving.
      if (!this.savedByTemplate && !this.firstSave) {
        this.SavedMembers = editedMembers;
      }
    }
    if (!this.savedByTemplate) {
      this.firstSave = false;
    }

    this.savedByTemplate = false;
    this.saveForLater();
  }
  //this function is used to edit the census before saving it. when adding parents
  editCensusBeforeSave(census) {

    this.currentPrimary = this.currentPrimary == null ? this.osData.currentPrimary : this.currentPrimary;


    if (this.currentPrimary?.Id != census[0].Id) {
      const primaryMember = census.find(m => m.vlocity_ins__IsPrimaryMember__c);
      const dependents = census.filter(m => !m.vlocity_ins__IsPrimaryMember__c && m.vlocity_ins__MemberIdentifier__c != this.currentPrimary.vlocity_ins__MemberIdentifier__c);
      const oldPrimaryMember = census.filter(m => m.vlocity_ins__MemberIdentifier__c == this.currentPrimary.vlocity_ins__MemberIdentifier__c)[0];
      const newPrimaryMember = JSON.parse(JSON.stringify(primaryMember));
      const editedMembers = [];


      if (oldPrimaryMember) {
        newPrimaryMember.Id = oldPrimaryMember.Id;
        newPrimaryMember.ARC_isPregnant__c = oldPrimaryMember.ARC_isPregnant__c;
        newPrimaryMember.ARC_IgnoreMailing__c = oldPrimaryMember.ARC_IgnoreMailing__c;
        newPrimaryMember.ARC_Height__c = oldPrimaryMember.ARC_Height__c;
        newPrimaryMember.ARC_Weight__c = oldPrimaryMember.ARC_Weight__c;
        newPrimaryMember.ARC_UseParentAddress__c = oldPrimaryMember.ARC_UseParentAddress__c;
        newPrimaryMember.ARC_Smoker__c = oldPrimaryMember.ARC_Smoker__c;
        newPrimaryMember.ARC_Phone__c = oldPrimaryMember.ARC_Phone__c;
        newPrimaryMember.ARC_MiddleInitial__c = oldPrimaryMember.ARC_MiddleInitial__c;
        newPrimaryMember.ARC_HeightInches__c = oldPrimaryMember.ARC_HeightInches__c;
        newPrimaryMember.ARC_HeightFeet__c = oldPrimaryMember.ARC_HeightFeet__c;
        newPrimaryMember.vlocity_ins__SocialSecurityNumber__c = oldPrimaryMember.vlocity_ins__SocialSecurityNumber__c;
        newPrimaryMember.vlocity_ins__Gender__c = oldPrimaryMember.vlocity_ins__Gender__c;
        newPrimaryMember.ARC_DependentRelationship__c = null;
        newPrimaryMember.ARC_ActiveMember__c = oldPrimaryMember.ARC_ActiveMember__c;
        newPrimaryMember.vlocity_ins__RelatedCensusMemberId__c = null;
        newPrimaryMember.vlocity_ins__PrimaryMemberIdentifier__c = null;
        newPrimaryMember.vlocity_ins__MemberIdentifier__c = oldPrimaryMember.vlocity_ins__MemberIdentifier__c;
        newPrimaryMember.vlocity_ins__LastName__c = oldPrimaryMember.vlocity_ins__LastName__c;
        newPrimaryMember.vlocity_ins__IsSpouse__c = oldPrimaryMember.vlocity_ins__IsSpouse__c;
        newPrimaryMember.vlocity_ins__IsPrimaryMember__c = true;
        newPrimaryMember.vlocity_ins__FirstName__c = oldPrimaryMember.vlocity_ins__FirstName__c;
        newPrimaryMember.vlocity_ins__Email__c = oldPrimaryMember.vlocity_ins__Email__c;
        newPrimaryMember.vlocity_ins__Birthdate__c = oldPrimaryMember.vlocity_ins__Birthdate__c;
        newPrimaryMember.edited = true;
        delete newPrimaryMember.isNew;

      }


      editedMembers.push({
        vlocity_ins__ContractLineId__c: primaryMember.vlocity_ins__ContractLineId__c,
        Id: primaryMember.Id,
        ARC_isPregnant__c: primaryMember.ARC_isPregnant__c,
        ARC_IgnoreMailing__c: primaryMember.ARC_IgnoreMailing__c,
        ARC_Height__c: primaryMember.ARC_Height__c,
        ARC_Weight__c: primaryMember.ARC_Weight__c,
        ARC_UseParentAddress__c: primaryMember.ARC_UseParentAddress__c,
        ARC_Smoker__c: primaryMember.ARC_Smoker__c,
        ARC_PhysicalAddressZipCode__c: primaryMember.ARC_PhysicalAddressZipCode__c,
        ARC_PhysicalAddressStreet__c: primaryMember.ARC_PhysicalAddressStreet__c,
        ARC_PhysicalAddressState__c: primaryMember.ARC_PhysicalAddressState__c,
        ARC_PhysicalAddressCity__c: primaryMember.ARC_PhysicalAddressCity__c,
        ARC_Phone__c: primaryMember.ARC_Phone__c,
        ARC_MiddleInitial__c: primaryMember.ARC_MiddleInitial__c,
        ARC_HeightInches__c: primaryMember.ARC_HeightInches__c,
        ARC_HeightFeet__c: primaryMember.ARC_HeightFeet__c,
        ARC_DependentRelationship__c: 'Future Primary',
        ARC_ActiveMember__c: primaryMember.ARC_ActiveMember__c,
        vlocity_ins__MemberIdentifier__c: primaryMember.vlocity_ins__MemberIdentifier__c,
        vlocity_ins__Gender__c: primaryMember.vlocity_ins__Gender__c,
        vlocity_ins__LastName__c: primaryMember.vlocity_ins__LastName__c,
        vlocity_ins__IsSpouse__c: primaryMember.vlocity_ins__IsSpouse__c,
        vlocity_ins__IschildMember__c: primaryMember.vlocity_ins__IschildMember__c,
        vlocity_ins__IsPrimaryMember__c: false,
        vlocity_ins__FirstName__c: primaryMember.vlocity_ins__FirstName__c,
        vlocity_ins__Email__c: primaryMember.vlocity_ins__Email__c,
        vlocity_ins__Birthdate__c: primaryMember.vlocity_ins__Birthdate__c,
        vlocity_ins__SocialSecurityNumber__c: primaryMember.vlocity_ins__SocialSecurityNumber__c,
        isNew: true,
        memberIndex: dependents.length + 2
      },
        ...dependents
      );



      for (const dependent of editedMembers) {
        dependent.vlocity_ins__PrimaryMemberIdentifier__c = JSON.parse(JSON.stringify(this.currentPrimary)).vlocity_ins__MemberIdentifier__c;
        dependent.vlocity_ins__RelatedCensusMemberId__c = JSON.parse(JSON.stringify(this.currentPrimary)).Id;
        dependent.edited = true;
      }



      if (newPrimaryMember) {
        delete newPrimaryMember.dependents;

        newPrimaryMember.dependents = (JSON.stringify(editedMembers));

      }



      return oldPrimaryMember ? [newPrimaryMember, ...editedMembers] : [...editedMembers];
    }
    return census;

  }

  //this function receives this.census and transform the primary into a child, and empty all the fields of the primary
  primaryToChild(census) {

    // if (this.currentPrimary == null) {
    if (!this.currentPrimary) {
      this.currentPrimary = JSON.parse(JSON.stringify(census.find(m => m.vlocity_ins__IsPrimaryMember__c == true)));
    }
    const primaryMember = JSON.parse(JSON.stringify(this.currentPrimary));
    const dependents = census.filter(m => m.vlocity_ins__IsPrimaryMember__c == false);
    const childPrimaryMember = this.removingPrimary ? null : JSON.parse(JSON.stringify(primaryMember));




    delete primaryMember.Id;

    primaryMember.ARC_isPregnant__c = false;
    primaryMember.ARC_IgnoreMailing__c = false;
    primaryMember.ARC_Height__c = null;
    primaryMember.ARC_Weight__c = null;
    primaryMember.ARC_UseParentAddress__c = true;
    primaryMember.ARC_Smoker__c = false;
    primaryMember.ARC_Phone__c = null;
    primaryMember.ARC_MiddleInitial__c = null;
    primaryMember.ARC_HeightInches__c = null;
    primaryMember.ARC_HeightFeet__c = null;
    primaryMember.vlocity_ins__SocialSecurityNumber__c = null;
    primaryMember.vlocity_ins__Gender__c = null;
    primaryMember.ARC_DependentRelationship__c = null;
    primaryMember.ARC_ActiveMember__c = false;
    primaryMember.vlocity_ins__RelatedCensusMemberId__c = null;
    primaryMember.vlocity_ins__PrimaryMemberIdentifier__c = null;
    primaryMember.vlocity_ins__MemberIdentifier__c = this.osData.newPrimaryIdentifier != null ? this.osData.newPrimaryIdentifier : dataFormatter.uniqueKey();
    primaryMember.vlocity_ins__LastName__c = null;
    primaryMember.vlocity_ins__IsSpouse__c = false;
    primaryMember.vlocity_ins__IsPrimaryMember__c = true;
    primaryMember.vlocity_ins__FirstName__c = null;
    primaryMember.vlocity_ins__Email__c = null;
    primaryMember.vlocity_ins__Birthdate__c = null;
    primaryMember.isNew = true;



    this.omniApplyCallResp(
      {
        'currentPrimary': JSON.parse(JSON.stringify(this.currentPrimary)),
        'newPrimaryIdentifier:': primaryMember.vlocity_ins__MemberIdentifier__c
      }
    )

    if (childPrimaryMember?.Id) {
      dependents.push({
        vlocity_ins__ContractLineId__c: childPrimaryMember.vlocity_ins__ContractLineId__c,
        Id: childPrimaryMember.Id,
        ARC_isPregnant__c: childPrimaryMember.ARC_isPregnant__c,
        ARC_IgnoreMailing__c: childPrimaryMember.ARC_IgnoreMailing__c,
        ARC_Height__c: childPrimaryMember.ARC_Height__c,
        ARC_Weight__c: childPrimaryMember.ARC_Weight__c,
        ARC_UseParentAddress__c: childPrimaryMember.ARC_UseParentAddress__c,
        ARC_Smoker__c: childPrimaryMember.ARC_Smoker__c,
        ARC_PhysicalAddressZipCode__c: childPrimaryMember.ARC_PhysicalAddressZipCode__c,
        ARC_PhysicalAddressStreet__c: childPrimaryMember.ARC_PhysicalAddressStreet__c,
        ARC_PhysicalAddressState__c: childPrimaryMember.ARC_PhysicalAddressState__c,
        ARC_PhysicalAddressCity__c: childPrimaryMember.ARC_PhysicalAddressCity__c,
        ARC_Phone__c: childPrimaryMember.ARC_Phone__c,
        ARC_MiddleInitial__c: childPrimaryMember.ARC_MiddleInitial__c,
        ARC_HeightInches__c: childPrimaryMember.ARC_HeightInches__c,
        ARC_HeightFeet__c: childPrimaryMember.ARC_HeightFeet__c,
        ARC_DependentRelationship__c: 'Child',
        ARC_ActiveMember__c: childPrimaryMember.ARC_ActiveMember__c,
        vlocity_ins__RelatedCensusMemberId__c: childPrimaryMember.vlocity_ins__RelatedCensusMemberId__c,
        vlocity_ins__MemberIdentifier__c: childPrimaryMember.vlocity_ins__MemberIdentifier__c,
        vlocity_ins__Gender__c: childPrimaryMember.vlocity_ins__Gender__c,
        vlocity_ins__LastName__c: childPrimaryMember.vlocity_ins__LastName__c,
        vlocity_ins__IsSpouse__c: childPrimaryMember.vlocity_ins__IsSpouse__c,
        vlocity_ins__IschildMember__c: childPrimaryMember.vlocity_ins__IschildMember__c,
        vlocity_ins__IsPrimaryMember__c: false,
        vlocity_ins__FirstName__c: childPrimaryMember.vlocity_ins__FirstName__c,
        vlocity_ins__Email__c: childPrimaryMember.vlocity_ins__Email__c,
        vlocity_ins__Birthdate__c: childPrimaryMember.vlocity_ins__Birthdate__c,
        vlocity_ins__SocialSecurityNumber__c: childPrimaryMember.vlocity_ins__SocialSecurityNumber__c,
        memberIndex: dependents.length + 2
      });
    }

    dependents.forEach(dependent => {
      dependent.vlocity_ins__PrimaryMemberIdentifier__c = primaryMember.vlocity_ins__MemberIdentifier__c;
    });

    delete primaryMember.dependents;
    primaryMember.dependents = dependents;




    return [primaryMember, ...dependents];
    // }
    // return census;
  }

  //Adds employee
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
  }

  // Add new dependent under an employee record.
  handleNewDependent(ev) {

    const employee = this.employees.find(
      e =>
        dataFormatter.getNamespacedProperty(e, 'MemberIdentifier__c') ==
        dataFormatter.getNamespacedProperty(ev.detail, 'MemberIdentifier__c')
    );

    if (employee) {
      const member = this.addNewMember(true, employee);
      this.ignoreAddress = true;
      member.ARC_UseParentAddress__c = true;
      this.census.push(member);
      this.calculateCensusInfo();
      this.omniApplyCallResp(
        {
          'uncommittedChanges': true,
          'dependentAdded': true
        }
      );

    }

    this.requiredFieldsValidation();

  }

  //Function that adds member to census (primary and dependents)
  addNewMember(addDependent, employee) {

    let newMember = this.headers.reduce((result, header) => {
      result[header.name] = '';
      return result;
    }, {});
    newMember[`isNew`] = true;
    newMember[`vlocity_ins__IsPrimaryMember__c`] = !addDependent;
    newMember[`vlocity_ins__PrimaryMemberIdentifier__c`] = addDependent
      ? dataFormatter.getNamespacedProperty(employee, 'MemberIdentifier__c')
      : '';
    newMember[`vlocity_ins__Birthdate__c`] = null;
    newMember[`vlocity_ins__MemberIdentifier__c`] = dataFormatter.uniqueKey();
    if (this.osData.FieldsetType == 'IFPProgramChangeAddMember' || this.osData.FieldsetType == 'IFPProgramChangeMultiple') {
      newMember[`programChangeDependent`] = true;

    }
    if (this.osData.NewPrimaryIsMinor && !this.onlyOneOver26) {
      newMember[`canBeOver26`] = true;
      this.onlyOneOver26 = true;
    }
    newMember['Relationship'] = '';
    newMember.memberIndex = this.census.length; // Index starts at zero, so next one = current count
    newMember.edited = true;
    this.auxCensusInfo.push(newMember);
    return newMember;
  }

  //Handles the delete of member

  // handleDeleteCensusLoad(newCensusMap, memberIdentifiers) {
  //     memberIdentifiers.forEach(memberId => {
  //         if (newCensusMap[memberId]) {
  //             delete newCensusMap[memberId];
  //         }
  //     });
  //     this.census = Object.values(newCensusMap).map(member => {
  //         return member;
  //     });
  //     this.calculateCensusInfo();
  //     if (this.currentPageHasNoItems()) {
  //         this.navigateToLastPage();
  //     }
  // }

  handleDeleteCensusLoad(newCensusMap, memberIdentifiers) {

    var result = new Map();
    var updatedCensusMap = { ...newCensusMap };
    var auxAddMemberCensus = {};
    var auxCensus = {};
    var mappedResult = {};

    memberIdentifiers.forEach(memberId => {
      if (newCensusMap[memberId]) {
        delete newCensusMap[memberId];
      }
    });


    auxCensus = this.census;
    Object.values(updatedCensusMap).forEach(member => delete member.error); // Reset errors

    for (let property in this.census) {
      if (this.census.hasOwnProperty(property)) {
        result[property] = { ...this.census[property], ...newCensusMap[property] };
      }
    }

    mappedResult = Object.values(result).map(member => {
      return member;
    });

    for (var i = mappedResult.length - 1; i >= 0; i--) {
      memberIdentifiers.forEach(memberId => {
        if (mappedResult[i].vlocity_ins__MemberIdentifier__c == memberId) {
          mappedResult.splice(i, 1);
        }
      })
    }

    if (this.osData.FieldsetType == 'IFPProgramChangeAddMember') {

      auxAddMemberCensus = this.census[0];
      this.census = [];
      this.census.push(auxAddMemberCensus);

      mappedResult.forEach(member => {


        if (member.programChangeDependent && member.programChangeDependent == true) {
          this.census.push(member);
        }

      })
      this.removeNull(this.census);

    } else if (this.osData.FieldsetType == 'IFPProgramChangePlan') {

      this.census = [];
      auxCensus.forEach(member => {
        if (member.ARC_ActiveMember__c == true) {
          this.census.push(member);
        }

      })
      this.removeNull(this.census);
    } else if (this.osData.FieldsetType == 'IFPProgramChangeMultiple') {

      this.census = [];
      auxCensus.forEach(member => {
        if (member.ARC_ActiveMember__c == true) {
          this.census.push(member);
        }
      })
      mappedResult.forEach(member => {
        if (member.programChangeDependent && member.programChangeDependent == true) {
          this.census.push(member);
        }
      })
      this.removeNull(this.census);

    } else if (this.osData.FieldsetType == 'IFPEnroll') {
      // this.censusthis.census.filter(m => mappedResult.map(mr => { return mr.vlocity_ins__MemberIdentifier__c }).includes(m.vlocity_ins__MemberIdentifier__c));

    } else {
      this.census = [];
      this.census = mappedResult;
      // this.census = auxCensus;
    }


    this.calculateCensusInfo();

  }

  //Function that fires after saving census for Members
  handleUpdateCensusLoadEncrypted(newCensusMap) {

    let updatedCensusMap = { ...newCensusMap };
    Object.values(updatedCensusMap).forEach(member => delete member.error); // Reset errors

    this.census = Object.values(updatedCensusMap).map(member => {
      //    member.uuid = dataFormatter.uniqueKey();
      return member;
    });

    this.calculateCensusInfo();
  }

  //Function that fires after saving census
  handleUpdateCensusLoad(newCensusMap, response) {

    var result = new Map();
    var mappedResult = {};
    var auxCensus = {};
    var auxAddMemberCensus = {};
    var auxRemoveMemberCensus = {};
    const saveResponse = JSON.parse(response);

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

    auxCensus = Object.values(updatedCensusMap).map(member => {
      //    member.uuid = dataFormatter.uniqueKey();
      return member;
    });

    for (let property in this.census) {
      if (this.census.hasOwnProperty(property)) {
        result[property] = { ...this.census[property], ...auxCensus[property] };
      }
    }

    mappedResult = Object.values(result).map(member => {
      //    member.uuid = dataFormatter.uniqueKey();
      return member;
    });

    if (this.osData.FieldsetType == 'IFPProgramChangeAddMember') {

      auxAddMemberCensus = this.census[0];

      this.census = [];
      this.census.push(auxAddMemberCensus);

      mappedResult.forEach(member => {
        if (member.programChangeDependent && member.programChangeDependent == true) {
          this.census.push(member);
        }
      })
      this.removeNull(this.census);

    }
    else if (this.osData.FieldsetType == 'IFPProgramChangeMultiple' || this.osData.FieldsetType == 'IFPProgramChangePlan') {
      let idList = [];
      this.involvedMembers = this.osData.InvolvedMembers;
      if (Array.isArray(this.involvedMembers)) {
        this.involvedMembers.forEach(element => {
          idList.push(element.Id);
        });
      } else {
        idList.push(this.involvedMembers.Id);
      }
      auxRemoveMemberCensus = auxCensus.filter(m => idList.includes(m['Id']));

      if (this.osData.STEP_RemoveMember != null && this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member')) {
        let primaryRemoved = false;
        let removedMembers = this.osData.STEP_RemoveMember.EDITBLK_RemoveMembers;

        removedMembers.forEach(element => {
          if (element.CHK_Delete == true && element.CHK_isPrimary == true && this.osData.STEP_ChangeReason?.CHK_AddParents != true) {
            primaryRemoved = true;
          }
        });
        removedMembers = removedMembers.filter(m => !m.CHK_Delete).map(m => m.TXT_CensusMemberId); // converts to array of CensusMemberIds strings 

        auxRemoveMemberCensus = auxCensus.filter(m => removedMembers.includes(m['Id']));


        if (primaryRemoved) {

          removedMembers.forEach(element => {
            if (element.CHK_Delete == true && element.CHK_isPrimary == true && this.osData.STEP_ChangeReason?.CHK_AddParents != true) {
              primaryRemoved = true;
            }
            if (element.CHK_Delete == true && element.TXT_Relationships == 'Spouse') {
              spouseRemoved = true;
            }
          });
          auxRemoveMemberCensus = auxRemoveMemberCensus.filter(m => removedMembers.includes(m['Id']));
          removedMembers = removedMembers.filter(m => !m.CHK_Delete).map(m => m.TXT_CensusMemberId); // converts to array of CensusMemberIds strings 
          if (primaryRemoved) {


            let newPrimaryId;
            let newPrimaryIdentifier;
            auxRemoveMemberCensus.forEach(element => {
              if (element.Id == this.osData.ChangePrimaryMember.TXT_NewPrimaryCensusMemberId) {
                newPrimaryId = element.Id;
                newPrimaryIdentifier = element.vlocity_ins__MemberIdentifier__c;
                element.vlocity_ins__IsPrimaryMember__c = true;
                element.vlocity_ins__PrimaryMemberIdentifier__c = null;

                element.vlocity_ins__RelatedCensusMemberId__c = null;
              } else {


                element.vlocity_ins__RelatedCensusMemberId__c = newPrimaryId;
                element.vlocity_ins__PrimaryMemberIdentifier__c = newPrimaryIdentifier;
              }
            });
          }
        }
      }



      this.census = [];
      auxRemoveMemberCensus.forEach(m => {
        this.census.push(m);
      })

      mappedResult.forEach(member => {
        if (member.programChangeDependent && member.programChangeDependent == true) {
          this.census.push(member);
        }
      })
      this.removeNull(this.census);

    } else {
      this.census = auxCensus;
    }


    this.calculateCensusInfo();
  }



  // Updates member information / fields in census.
  handleUpdate(ev) {

    let member = { ...ev.detail };
    member.addressModified;
    if (member.vlocity_ins__IsPrimaryMember__c) {
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
      if (!member.vlocity_ins__IsSpouse__c) {
        member.vlocity_ins__IsSpouse__c = (member.ARC_DependentRelationship__c == 'Spouse' || member.ARC_DependentRelationships__c == 'Spouse') ? true : false;

      }
      if (this.osData.QuoteProcess != 'SmallGroupQuote') {
        member.ARC_EnrollmentCensusMember__c = true;
      }

      member.vlocity_ins__FirstName__c = member.vlocity_ins__FirstName__c != null ? member.vlocity_ins__FirstName__c : '';
      member.vlocity_ins__LastName__c = member.vlocity_ins__LastName__c != null ? member.vlocity_ins__LastName__c : '';

      this.census[memberIndex] = member;


      this.calculateCensusInfo(); // Since census is changed.
    }

    if (this.osData.afterCensus == false) {
      this.omniApplyCallResp(
        {
          'clickedCensus': true

        }
      )
    }

    this.requiredFieldsValidation();

  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /////These 2 functions are commented (filemapCreated and csvDataToCensus) because these functionalities were erased from the census/////
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

  // filemapCreated(ev) {
  //     this.isLoaded = false;
  //     const csvData = ev.detail.data || [];
  //     if (csvData.length > this.censusMemberUploadLimit) {
  //         this.showError({
  //             message: this.labels.InsOSCensusErrorExceedRowCount.replace('{0}', this.censusMemberUploadLimit)
  //         });
  //         this.isLoaded = true;
  //         return;
  //     }

  //     if (this.medicalPlanListElements) {

  //         for (const elemCensus of Object.values(csvData)) {

  //             var hasProduct = false;
  //             for (const planName of this.medicalPlanListElements) {
  //                 if (elemCensus.ARC_MedicalProduct__c == planName.label) {
  //                     elemCensus.ARC_MedicalProduct__c = planName.value;
  //                     hasProduct = true;

  //                 }
  //             }
  //             if (!hasProduct) {
  //                 elemCensus.ARC_MedicalProduct__c = '';
  //             }
  //         }
  //     }

  //     if (this.visionPlanListElements) {

  //         for (const elemCensus of Object.values(csvData)) {

  //             var hasProduct = false;
  //             for (const planName of this.visionPlanListElements) {
  //                 if (elemCensus.ARC_VisionProduct__c == planName.label) {
  //                     elemCensus.ARC_VisionProduct__c = planName.value;
  //                     hasProduct = true;

  //                 }
  //             }
  //             if (!hasProduct) {
  //                 elemCensus.ARC_VisionProduct__c = '';
  //             }
  //         }
  //     }

  //     if (this.dentalPlanListElements) {

  //         for (const elemCensus of Object.values(csvData)) {

  //             var hasProduct = false;
  //             for (const planName of this.dentalPlanListElements) {
  //                 if (elemCensus.ARC_DentalProduct__c == planName.label) {
  //                     elemCensus.ARC_DentalProduct__c = planName.value;
  //                     hasProduct = true;

  //                 }
  //             }
  //             if (!hasProduct) {
  //                 elemCensus.ARC_DentalProduct__c = '';
  //             }
  //         }
  //     }

  //     this.csvDataToCensus(csvData);
  // }

  // csvDataToCensus(csvData) {
  //     const availableEnrollmentPlanOptions = this.availableEnrollmentPlanOptions;
  //     let empUniqueId = null;
  //     let currentDepBatch = [];
  //     let members = csvData.map(csvRow => {
  //         let member = this.addNewMember(false);
  //         Object.keys(csvRow).forEach(key => {
  //             member[key] = csvRow[key];
  //         });
  //         if (member['Relationship']) {
  //             if (member['Relationship'] === 'Employee' || member['Relationship'] === 'Subscriber') {
  //                 empUniqueId = dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c');
  //             } else if (member['Relationship'] === 'Spouse') {
  //                 member[`vlocity_ins__IsPrimaryMember__c`] = false;
  //                 member[`vlocity_ins__IsSpouse__c`] = true;
  //                 member[`vlocity_ins__PrimaryMemberIdentifier__c`] = empUniqueId || '';
  //             } else {
  //                 member[`vlocity_ins__IsPrimaryMember__c`] = false;
  //                 member[`vlocity_ins__IsSpouse__c`] = false;
  //                 member[`vlocity_ins__PrimaryMemberIdentifier__c`] = empUniqueId || '';
  //             }
  //             if (empUniqueId === null) {
  //                 currentDepBatch.push(member);
  //             } else {
  //                 currentDepBatch.forEach(m => {
  //                     m[`vlocity_ins__PrimaryMemberIdentifier__c`] = empUniqueId;
  //                 });
  //                 currentDepBatch.length = 0;
  //             }
  //         }
  //         if (member[this.planHeaderFieldName]) {
  //             this.addPlansToMember(member, availableEnrollmentPlanOptions);
  //         }
  //         return member;
  //     });
  //     this.formatAllDateFields(members);
  //     this.census = members;
  //     this.calculateCensusInfo();
  //     this.navigateToFirstPage();
  //     if (!this.requiredFieldMissing) {
  //         this.savedByTemplate = true;
  //         this.saveMembers();
  //     } else {
  //         this.isLoaded = true;
  //         this.savedByTemplate = false;

  //     }

  //     this.omniApplyCallResp(
  //         {
  //             'templateEntered': true,
  //             "memberEntered": false
  //         })
  // }


  //Function for deleting members
  deleteMembers(memberIdentifiers) {


    let deletionIds = [];
    this.census.forEach(member => {
      if (member.canBeOver26) {
        this.addedNewPrimary = false;
        this.onlyOneOver26 = false;
      }
      // Extract Ids for members
      if (memberIdentifiers.some(id => dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c') === id) && member.Id) {
        deletionIds.push({ Id: member.Id });
      }

    });
    if (deletionIds.length > 0) {
      // Make API call to delete the members
      this.isLoaded = false;


      let deleteAction = JSON.parse(JSON.stringify(this.omniJsonDef.propSetMap.deleteAction || {}));
      deleteAction.inputMap = { ...deleteAction.inputMap, ...this.censusInputMap(deletionIds) };


      //If the user profile is member community it will use the IP for encrypted censusId, else will use the census
      //service class.
      if (this.osData.userProfile == 'Member Community Profile') {
        this.IPInput = {
          Members: deleteAction.inputMap.census.members
        }
        const params = {
          input: JSON.stringify(this.IPInput),
          sClassName: 'vlocity_ins.IntegrationProcedureService',
          sMethodName: 'CustomDeleteCensus_GuestUsers',
          options: '{}'
        };
        this._actionUtilClass
          .executeAction(params, null, this, null, null)


          // this.invokeService(deleteAction, 'InsCensusService', 'deleteMembers')

          .then(() => {


            this.loadCensus().then(loadResponse => {
              const newCensusMap = this.generateUpdatedCensusMap(loadResponse);
              this.handleDeleteCensusLoad(newCensusMap, memberIdentifiers);
            });
          })
          .catch((error) => {
            console.error(error, 'ERROR');
          });

      } else {
        this.invokeService(deleteAction, 'InsCensusService', 'deleteMembers')

          .then(() => {

            this.loadCensus().then(loadResponse => {

              const newCensusMap = this.generateUpdatedCensusMap(loadResponse);

              this.handleDeleteCensusLoad(newCensusMap, memberIdentifiers);
            });
          })

          .catch((error) => {
            console.error(error, 'ERROR');
          });

      }

    } else {
      // Delete members from client end since associate record ID is not created yet.
      this.census = this.census.filter(
        member =>
          !memberIdentifiers.includes(dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c'))
      );

      if (this.currentPageHasNoItems()) {
        this.navigateToLastPage();
      }

    }
    const editedMembers = this.census.filter(m => m.edited); // Filter edited members only
    if (editedMembers.length == 0) {
      this.omniApplyCallResp(
        {
          "uncommittedChanges": false,
          "requiredFieldMissing": false
        }
      )
    }

    this.calculateCensusInfo();
  }

  //Calculates census info for the employees, and it calls the generateMessaging function for showing error messages.
  calculateCensusInfo() {

    this.memberAmmount = this.getMembersAmmount();



    if (this.osData.FieldsetType != 'IFPShop') {
      this.pcInitialChildsAmmount = this.getChildsAmmount(this.osData.userInputs2, true);
      if (this.osData.FieldsetType == 'IFPProgramChangeAddMember') this.pcInitialChildsAmmount++;
    }
    this.childsAmmount = this.getChildsAmmount(this.census[0].dependents, false);

    this.childsAmmount = this.childsAmmount + this.pcInitialChildsAmmount;





    let censusLength = this.census.length;
    if (this.childsAmmount >= 4 && this.osData.FieldsetType != 'IFPEnroll') {
      if (!this.extraMemberPopupDisplayed) {
        this.extraMemberPopupDisplayed = true;
        this.moreThan3Dependents = true;
      }
    } else {
      this.moreThan3Dependents = false;

    }
    let censusInfo = { total: censusLength, empCount: 0, empChCount: 0, empSpCount: 0, empFaCount: 0 };
    let employees = [];

    let empDeps = {}; // Stores dependents  information on primary member's ID
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

      if (this.osData.FieldsetType != 'IFPProgramChangeAddMember' || this.osData.FieldsetType == 'IFPProgramChangeMultiple') {
        if (member.vlocity_ins__IsPrimaryMember__c == false) {
          this.osData.existsDependent = true;
          this.omniApplyCallResp(

            {
              "clickedDependent": true
            }
          );
        } else if (this.osData.existsDependent == false && member.vlocity_ins__IsPrimaryMember__c == true && !member.dependents) {

          this.omniApplyCallResp(

            {
              "clickedDependent": false
            }
          );

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




    if (JSON.stringify(this.SavedMembers) == JSON.stringify(this.employees)) {

      this.omniApplyCallResp(

        {
          "uncommittedChanges": true
        }
      );
    }
    this.generateMessaging(this.employees);


    if (this.omniGetSaveState(JSON.parse(JSON.stringify(this.omniJsonData)).CensusId) && this.getSavedCensus) {
      this.osData = this.omniGetSaveState(JSON.parse(JSON.stringify(this.omniJsonData)).CensusId);
      this.getSavedCensus = false;
    } else {
      this.osData = JSON.parse(JSON.stringify(this.omniJsonData));

    }

    this.requiredFieldsValidation();


  }

  //This function fires only when the census is initiated
  handleInitialCensusLoad(response) {
    console.log('handleInitialCensusLoad');


    this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
    this.requiredFieldsPrimary = JSON.parse(JSON.stringify(this.osData.requiredFieldsPrimary));
    this.visibleFieldsPrimary = JSON.parse(JSON.stringify(this.osData.visibleFieldsPrimary));
    this.requiredFieldsDependent = JSON.parse(JSON.stringify(this.osData.requiredFieldsDependent));
    this.visibleFieldsDependent = JSON.parse(JSON.stringify(this.osData.visibleFieldsDependent));
    // if(this.osData?.Reason == "Add Newborn"){
    //     this.requiredFieldsDependent = this.requiredFieldsDependent.filter(function(e) { return e !== 'vlocity_ins__SocialSecurityNumber__c' })
    // }
    this.isLoaded = true;
    var auxCensus = {};
    const parsedData = JSON.parse(response);

    this.existingSpouse = parsedData.census.members.filter(m => m.vlocity_ins__IsSpouse__c && m.ARC_ActiveMember__c).length > 0;

    const responseError = parsedData.errors || parsedData.error;
    if (responseError && responseError !== 'OK') {
      this.showError({ message: responseError });
      this.isValidCensus = false;
      return;
    }

    auxCensus = parsedData.census.members.map((m, index) => {
      m.memberIndex = index;
      return m;
    });
    this.allCensusMembers = parsedData.census.members.map((m, index) => {
      m.memberIndex = index;
      return m;
    });

    if (this.osData.FieldsetType == 'IFPProgramChangePlan' || this.osData.FieldsetType == 'IFPProgramChangeMultiple') {
      let idList = [];
      this.involvedMembers = this.osData.InvolvedMembers;


      this.census = [];
      let thereIsAPrimary = false;
      if (Array.isArray(this.involvedMembers)) {
        this.involvedMembers.forEach(element => {
          idList.push(element.Id);
        });
      } else {
        idList.push(this.involvedMembers.Id);
      }

      auxCensus = auxCensus.filter(m => idList.includes(m['Id']));
      auxCensus.forEach(element => {
        if (element.vlocity_ins__IsPrimaryMember__c) {
          thereIsAPrimary = true;
          if (this.osData.STEP_ChangeReason?.CHK_AddParents) {

            this.currentPrimary = JSON.parse(JSON.stringify(element));
          }
        }
      });
      if (!thereIsAPrimary) {
        function getNextBirthday(date) {
          // Current Date
          let currentDate = new Date();

          // Set the users birthday to this year (originally from thier birth year)
          let birthday = new Date(date);
          birthday.setFullYear(currentDate.getFullYear());

          // If the birthday has already occured this year.  Then thier next birthday is next year.
          if (birthday - currentDate < 0) {
            birthday.setFullYear(currentDate.getFullYear() + 1);
          }

          // Return the users next birthday as a date.
          return birthday;
        }

        auxCensus = auxCensus.slice(0).sort((a, b) => {
          return getNextBirthday(a[1]) - getNextBirthday(b[1]);
        });
        let newPrimaryId = auxCensus[0].vlocity_ins__RelatedCensusMemberId__c;
        let newPrimaryIdentifier = auxCensus[0].vlocity_ins__MemberIdentifier__c;
        auxCensus[0].vlocity_ins__IsPrimaryMember__c = true;
        auxCensus.forEach(element => {
          if (!element.vlocity_ins__IsPrimaryMember__c) {


            element.vlocity_ins__RelatedCensusMemberId__c = newPrimaryId;
            element.vlocity_ins__PrimaryMemberIdentifier__c = newPrimaryIdentifier;
          }
        });
      }

      if (this.osData.STEP_RemoveMember != null && this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member')) {
        let primaryRemoved = false;
        let removedMembers = this.osData.STEP_RemoveMember.EDITBLK_RemoveMembers;
        if (this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Add Existing Member')) {
          removedMembers.push(...(Array.isArray(this.osData.STEP_AddExistingMembers.EB_AddMember) ? this.osData.STEP_AddExistingMembers.EB_AddMember : [this.osData.STEP_AddExistingMembers.EB_AddMember]).filter(member => member.CHK_Add == true).map(function (member) {
            member.TXT_CensusMemberId = member.Id;
            return member;
          }));

        }
        removedMembers.forEach(element => {
          if (element.CHK_Delete == true && element.CHK_isPrimary == true) {
            if (this.osData.STEP_ChangeReason?.CHK_AddParents != true) {
              primaryRemoved = true;
            } else {
              this.removingPrimary = true;
            }
          }


        });
        removedMembers = removedMembers.filter(m => !m.CHK_Delete).map(m => m.TXT_CensusMemberId); // converts to array of CensusMemberIds strings 

        auxCensus = auxCensus.filter(m => removedMembers.includes(m['Id']));

        if (primaryRemoved) {

          let newPrimaryId;
          let newPrimaryIdentifier;
          if (!this.osData.NewPrimaryIsMinor) {

            auxCensus.forEach(element => {
              if (element.Id == this.osData.ChangePrimaryMember.TXT_NewPrimaryCensusMemberId) {
                newPrimaryId = element.Id;
                element.vlocity_ins__HasSpouse__c = false;
                element.vlocity_ins__IsSpouse__c = false;
                newPrimaryIdentifier = element.vlocity_ins__MemberIdentifier__c;
                element.vlocity_ins__IsPrimaryMember__c = true;
                element.vlocity_ins__PrimaryMemberIdentifier__c = null;


                element.vlocity_ins__RelatedCensusMemberId__c = null;
              }
            });
            auxCensus.forEach(element => {
              if (element.Id != this.osData.ChangePrimaryMember.TXT_NewPrimaryCensusMemberId) {


                element.vlocity_ins__RelatedCensusMemberId__c = newPrimaryId;
                element.vlocity_ins__PrimaryMemberIdentifier__c = newPrimaryIdentifier;
              }
            });
          }
        }

      }
      auxCensus.forEach(m => {
        this.census.push(m);
      })
    }
    else if (this.osData.FieldsetType == 'IFPProgramChangeAddMember') {
      this.involvedMembers = this.osData.InvolvedMembers;


      let primaryRemoved = false;
      this.census = [];
      let idList = [];
      let thereIsAPrimary = false;
      let thePrimary;
      if (Array.isArray(this.involvedMembers)) {
        this.involvedMembers.forEach(element => {
          idList.push(element.Id);
        });
      } else {
        idList.push(this.involvedMembers.Id);
      }
      auxCensus = auxCensus.filter(m => idList.includes(m['Id']));
      auxCensus.forEach(element => {
        if (element.vlocity_ins__IsPrimaryMember__c) {
          thereIsAPrimary = true;
          thePrimary = element;
        }
      });


      if (this.osData.STEP_RemoveMember != null && this.osData.STEP_ChangeReason.SEL_ChangeReason.includes('Remove Member')) {
        let spouseRemoved = false;
        let removedMembers = this.osData.STEP_RemoveMember.EDITBLK_RemoveMembers;

        removedMembers.forEach(element => {
          if (element.CHK_Delete == true && element.CHK_isPrimary == true && this.osData.STEP_ChangeReason?.CHK_AddParents != true) {
            primaryRemoved = true;
          }
          if (element.CHK_Delete == true && element.TXT_Relationships == 'Spouse') {
            spouseRemoved = true;
          }
        });

        function getNextBirthday(date) {
          // Current Date
          let currentDate = new Date();

          // Set the users birthday to this year (originally from thier birth year)
          let birthday = new Date(date);
          birthday.setFullYear(currentDate.getFullYear());

          // If the birthday has already occured this year.  Then thier next birthday is next year.
          if (birthday - currentDate < 0) {
            birthday.setFullYear(currentDate.getFullYear() + 1);
          }

          // Return the users next birthday as a date.
          return birthday;
        }
        if (!spouseRemoved) {
          auxCensus.forEach(element => {
            if (element.ARC_DependentRelationship__c == "Spouse") {
              element.vlocity_ins__IsPrimaryMember__c = true;

            }
          });
        } else {
          auxCensus = auxCensus.slice(0).sort((a, b) => {
            return getNextBirthday(a[1]) - getNextBirthday(b[1]);
          });

          auxCensus[0].vlocity_ins__IsPrimaryMember__c = true;
        }



        removedMembers = removedMembers.filter(m => !m.CHK_Delete).map(m => m.TXT_CensusMemberId); // converts to array of CensusMemberIds strings 

        auxCensus = auxCensus.filter(m => removedMembers.includes(m['Id']));

        if (primaryRemoved) {

          let newPrimaryId;
          let newPrimaryIdentifier;
          if (!this.osData.NewPrimaryIsMinor) {

            auxCensus.forEach(element => {
              if (element.Id == this.osData.ChangePrimaryMember.TXT_NewPrimaryCensusMemberId) {
                newPrimaryId = element.Id;
                element.vlocity_ins__HasSpouse__c = false;
                element.vlocity_ins__IsSpouse__c = false;
                newPrimaryIdentifier = element.vlocity_ins__MemberIdentifier__c;
                element.vlocity_ins__IsPrimaryMember__c = true;
                element.vlocity_ins__PrimaryMemberIdentifier__c = null;


                element.vlocity_ins__RelatedCensusMemberId__c = null;
              }
            });
            auxCensus.forEach(element => {
              if (element.Id != this.osData.ChangePrimaryMember.TXT_NewPrimaryCensusMemberId) {


                element.vlocity_ins__RelatedCensusMemberId__c = newPrimaryId;

                element.vlocity_ins__PrimaryMemberIdentifier__c = newPrimaryIdentifier;
              }
            });
          }
        }

      }

      if (primaryRemoved) {
        auxCensus.forEach(element => {
          if (element.vlocity_ins__IsPrimaryMember__c) {
            this.census.push(element);
          }
        });
      } else {
        this.census.push(thePrimary);
      }

      this.removeNull(this.census);

    }
    else {
      console.log('auxCensus', JSON.parse(JSON.stringify(auxCensus)));
      console.log('this.census', JSON.parse(JSON.stringify(this.census)));
      this.census = auxCensus;
      this.removeNull(this.census);
    }
    this.initHeaders(parsedData.census.headers);

    if (this.osData.STEP_ChangeReason?.CHK_AddParents) {
      this.census = this.primaryToChild(this.census)
    }


    this.calculateCensusInfo();
  }

  // Delete all census members on button click, this was removed from html.
  // @api
  // clearAll() {
  //     if(this.osData.afterCensus == true || this.osData.QuoteProcess == 'SmallGroupQuote' || this.osData.QuoteProcess == 'SmallGroupEnrollment' || 
  //     this.osData.templateEntered == true){
  //         const memberIdentifiers = this.census.map(member =>
  //             dataFormatter.getNamespacedProperty(member, 'MemberIdentifier__c')
  //         );

  //         this.deleteMembers(memberIdentifiers);
  //         this.closeDeleteAllModal();
  //         this.omniApplyCallResp(
  //             {
  //                 'uncommittedChanges': true,
  //             }
  //         )
  //     }

  // }

  //This function validates each one of the fields in the census (primary, address information and dependents), shows messages of error in case 
  //something is wrong.
  requiredFieldsValidation() {

    let memberOver18noEmailPhoneError = false;
    const regex = /^\d+$/;
    let tempRequiredFieldsMissing = [];
    let tempRequiredFieldsMissingPrimary = [];
    let tempRequiredFieldsMissingDependent = [];
    let requiredFieldsDependentValidation = this.requiredFieldsDependent;
    let hasErrorDates = false;
    let childError = false;
    let spouseError = false;
    let SSNError1 = false;
    let SSNError2 = false;
    let newBornAddMember = false;
    let newBorn = false;
    let auxForPrimaryBD = new Date();
    let childFamilyError = false;
    let myDependentSpouseMap = new Map();
    let hasErrorSaleState = false;
    let AddOver18Dependent = true;
    let heightsFeets = false;
    let heightsInches = false;
    let errorMap = new Map();
    this.census.forEach(member => {
      let firstDependentCanBeOver26 = true;
      let ssnHasError = false;
      let ssnHasLess = false;
      let moreThanOneSpouse = false;
      let errorSSN = false;
      let childOver26 = false;
      let childOver18 = false;
      let spouseOver65 = false;
      let memberOver18noEmailPhone = false;
      let primaryOver65 = false;
      let notABaby = false;
      let error = false;
      let heightOver7 = false;
      let heightOver12 = false;
      let futureBirthDate = false;
      let useParent = false;
      let noSaleState = false;

      let spouseInCensus = this.census.filter(m => m.vlocity_ins__IsSpouse__c == true).size > 0 || this.existingSpouse;

      if (member.ARC_Smoker__c == null || member.ARC_Smoker__c == undefined || member.ARC_Smoker__c == "") {
        member.ARC_Smoker__c = false;
      }

      if (this.osData.FieldsetType == 'IFPEnroll') {
        member[`isNew`] = true;
      }

      if (this.osData.STEP_ChangeReason?.SEL_ChangeReason?.includes('Add Existing Member')) {
        member.ARC_DependentRelationship__c = member.ARC_DependentRelationship__c == 'Past Primary' ? 'Spouse' : member.ARC_DependentRelationship__c;
      }

      // //sweeps every required field in the primary field set (this can be modified in census Member fieldset)
      if (this.osData.FieldsetType != 'IFPProgramChangeAddMember') {
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
          if (member.vlocity_ins__IsPrimaryMember__c == true && (!member[primaryField] || member[primaryField] == " ")) {

            tempRequiredFieldsMissing.push(primaryField);
            tempRequiredFieldsMissingPrimary.push(primaryField);

          } if (!error && primaryField == 'vlocity_ins__Birthdate__c') {
            var currentdate = new Date();

            var memberBirthdate = new Date(member[primaryField]);
            if (member.vlocity_ins__IsPrimaryMember__c == true) {
              auxForPrimaryBD = memberBirthdate;


            }

            //calculate month difference from current date in time
            var month_diff = Date.now() - memberBirthdate.getTime();

            //convert the calculated difference in date format
            var age_dt = new Date(month_diff);

            //extract year from date    
            var year = age_dt.getUTCFullYear();

            //calculate the age of the user
            var age = Math.abs(year - 1970);

            if (currentdate.getTime() < memberBirthdate.getTime()) {
              futureBirthDate = true;
              hasErrorDates = true;
            } else if (age > 64) {
              primaryOver65 = false;
              hasErrorDates = false;
            }

          }

        });
      }


      // //Copy address from primary to dependent if ignoreAddress is true
      if (this.ignoreAddress == true) {
        if (member.vlocity_ins__IsPrimaryMember__c) {
          for (let dependent of member.dependents) {
            if (dependent.ARC_UseParentAddress__c) {
              dependent = this.replaceAddress(member, dependent)
            }
          }
        }
      }

      if (this.isNewborn(member)) {
        requiredFieldsDependentValidation = requiredFieldsDependentValidation.filter(function (e) { return e !== 'vlocity_ins__SocialSecurityNumber__c' })
      } else {
        requiredFieldsDependentValidation = this.requiredFieldsDependent;
      }


      //  //sweeps every required field in the dependent field set (this can be modified in census Member fieldset)
      requiredFieldsDependentValidation.forEach(dependentField => {

        if (dependentField == 'vlocity_ins__Birthdate__c' && member.vlocity_ins__IsPrimaryMember__c == false) {
          var currentdate = new Date();
          var memberBirthdate = new Date(member[dependentField]);

          var isProgramChange = member.programChangeDependent;
          //calculate month difference from current date in time
          var month_diff = Date.now() - memberBirthdate.getTime();
          //convert the calculated difference in date format
          var age_dt = new Date(month_diff);
          //extract year from date    
          var year = age_dt.getUTCFullYear();
          //calculate the age of the user
          var age = Math.abs(year - 1970);
          var priorDate = new Date().setDate(currentdate.getDate() - 32)

          if (currentdate.getTime() < memberBirthdate.getTime()) {
            futureBirthDate = true;
            hasErrorDates = true;

          } else if (member.isNew == true && this.osData.STEP_ChangeReason && !this.osData.STEP_ChangeReason.SEL_ChangeReason.includes("Add Newborn") && this.osData.FieldsetType == 'IFPProgramChangeAddMember' &&
            memberBirthdate.getTime() >= priorDate ||
            member.isNew == true && this.osData.STEP_ChangeReason && !this.osData.STEP_ChangeReason.SEL_ChangeReason.includes("Add Newborn") && this.osData.FieldsetType == 'IFPProgramChangeMultiple' &&
            memberBirthdate.getTime() >= priorDate && isProgramChange == true) {


            newBornAddMember = true;
            hasErrorDates = true;

          } else if (member.isNew == true && this.osData.STEP_ChangeReason && this.osData.STEP_ChangeReason.SEL_ChangeReason.includes("Add Newborn") && memberBirthdate.getTime() <= priorDate ||
            member.isNew == true && this.osData.STEP_ChangeReason && this.osData.STEP_ChangeReason.SEL_ChangeReason.includes("Add Newborn") && this.osData.FieldsetType == 'IFPProgramChangeMultiple' &&
            memberBirthdate.getTime() <= priorDate && isProgramChange == true) {
            newBorn = true;
            hasErrorDates = true;

          }

          else if (member.canBeOver26 && age >= 18) {
            AddOver18Dependent = true;
            this.addedNewPrimary = true;
            firstDependentCanBeOver26 = false;

          }

          else if (age > 26 && member.ARC_DependentRelationship__c == 'Child' && member[dependentField] != null && firstDependentCanBeOver26) {
            childOver26 = true;
          }

          else if (age >= 65  && member.ARC_DependentRelationship__c == 'Spouse' && member[dependentField] != null) {
            spouseOver65 = true;
          }

          else if (this.osData.NewPrimaryIsMinor && member.canBeOver26 && age < 18) {

            AddOver18Dependent = false;
            this.addedNewPrimary = false;
          }


          else if (age > 64 && member[dependentField] != null) {
            primaryOver65 = false;
            hasErrorDates = false;
          }
          else if (this.osData.STEP_GuardiansInformation && auxForPrimaryBD.getTime() > memberBirthdate.getTime()) {
            childFamilyError = true;
            hasErrorDates = true;
          }

        }

        if (dependentField == 'ARC_PhysicalAddressState__c' && member.vlocity_ins__IsPrimaryMember__c == false) {
          var memberState = member[dependentField];
          var stateExists = false;
          this.osData.availableStates.forEach(as => {
            if (as.abbreviation == memberState) {
              stateExists = true;
            }
          })
          if (stateExists == false) {
            noSaleState = true;
            hasErrorSaleState = true;
          }
        }

        if (member.vlocity_ins__IsPrimaryMember__c == false && (!member[dependentField] || member[dependentField] == " ")) {
          tempRequiredFieldsMissing.push(dependentField);
          tempRequiredFieldsMissingDependent.push(dependentField);
        }

      })

      // if(member.vlocity_ins__IsPrimaryMember__c == true && member.dependents){
      //     member.dependents.forEach(dep => {
      //         if((dep.ARC_DependentRelationship__c == 'Spouse' || dep.ARC_DependentRelationships__c == 'Spouse') && dep.ARC_ActiveMember__c == true){
      //             member.vlocity_ins__HasSpouse__c = true;
      //         } else {
      //             member.vlocity_ins__HasSpouse__c = false;
      //         }
      //     });
      // }


      //Checks if primary has only 1 spouse. if a second one is added it will show error message. Checks hasSpouse field for primary if there is a Spouse dependent.

      if (this.osData.FieldsetType == 'IFPProgramChangeAddMember' && member.vlocity_ins__IsPrimaryMember__c == true && spouseInCensus) {
        myDependentSpouseMap.set(member.vlocity_ins__MemberIdentifier__c, { quantity: 1 });
      }

      //If program change removes spouse and eff date is before the add member, this logic takes out the "has spouse" property to the primary so it can add a new one.
      if ((this.osData.STEP_ChangeReason?.SEL_ChangeReason?.includes("Add Member") && this.osData.STEP_ChangeReason?.SEL_ChangeReason?.includes("Remove Member"))
        // && (this.osData.STEP_RemoveMember?.LWC_RemoveMemberEffDate_?.DATE_EffectiveDateRemoveMember <= this.osData.STEP_PrepareYourCensus?.FRML_EffectiveDate) 
        && member.vlocity_ins__IsPrimaryMember__c == true && spouseInCensus) {
        let spouseRemoved = this.osData.Changes_RemoveMember_RemovedMembers.filter(item => item.CHK_Delete == true && item.TXT_Relationships == 'Spouse');
        if (spouseRemoved?.length > 0) {

          member.vlocity_ins__HasSpouse__c = false;
        }

      }

      if (member.vlocity_ins__IsPrimaryMember__c == false && member.ARC_DependentRelationship__c == 'Spouse') {
        if (!myDependentSpouseMap.has(member.vlocity_ins__PrimaryMemberIdentifier__c)) {
          myDependentSpouseMap.set(member.vlocity_ins__PrimaryMemberIdentifier__c, { quantity: 1 });
        } else {
          myDependentSpouseMap.get(member.vlocity_ins__PrimaryMemberIdentifier__c).quantity++;
          if (myDependentSpouseMap.get(member.vlocity_ins__PrimaryMemberIdentifier__c).quantity > 1) {
            moreThanOneSpouse = true;
          }
        }
      }



      var depMemberBirthdate = new Date(member['vlocity_ins__Birthdate__c']);
      var depCurrentdate = new Date();
      var ninetyDaysAgoDate = new Date(depCurrentdate);
      ninetyDaysAgoDate.setDate(ninetyDaysAgoDate.getDate() - 90);
      //calculate month difference from current date in time
      var depMonth_diff = Date.now() - depMemberBirthdate.getTime();
      //convert the calculated difference in date format
      var depAge_dt = new Date(depMonth_diff);
      //extract year from date    
      var depYear = depAge_dt.getUTCFullYear();
      //calculate the age of the user
      var depAge = Math.abs(depYear - 1970);

      if (member.vlocity_ins__IsPrimaryMember__c == false && depAge > 17 && this.osData.FieldsetType != 'IFPShop' && (!member['vlocity_ins__Email__c'] || member['ARC_Phone__c']?.length < 10) && this.osData.FieldsetType != 'IFPShop') {
        childOver18 = true;
      }
      if (depAge > 17 && (!member['vlocity_ins__Email__c'] || member['ARC_Phone__c']?.length < 10) && this.osData.FieldsetType != 'IFPShop') {
        if (!member['vlocity_ins__Email__c']) {
          tempRequiredFieldsMissing.push('vlocity_ins__Email__c');
          tempRequiredFieldsMissingPrimary.push('vlocity_ins__Email__c');
        }
        if (member['ARC_Phone__c']?.length < 10) {
          tempRequiredFieldsMissing.push('ARC_Phone__c');
          tempRequiredFieldsMissingPrimary.push('ARC_Phone__c');
        }

        memberOver18noEmailPhone = true;
      }

      if (!heightOver7 && member.ARC_HeightFeet__c) {
        if (member.ARC_HeightFeet__c != null && member.ARC_HeightFeet__c > 7 && member.ARC_HeightFeet__c != undefined) {
          heightOver7 = true;
          if (depMemberBirthdate < ninetyDaysAgoDate) {
            tempRequiredFieldsMissing.push('ARC_HeightFeet__c')

            if (member.vlocity_ins__IsPrimaryMember__c) {
              tempRequiredFieldsMissingPrimary.push('ARC_HeightFeet__c');
            } else {
              tempRequiredFieldsMissingDependent.push('ARC_HeightFeet__c');
            }

          }
        }
      }

      if (!heightOver12 && member.ARC_HeightInches__c) {
        if (member.ARC_HeightInches__c != null && member.ARC_HeightInches__c > 12 && member.ARC_HeightInches__c != undefined) {
          heightOver12 = true;

          if (depMemberBirthdate < ninetyDaysAgoDate) {
            tempRequiredFieldsMissing.push('ARC_HeightInches__c')

            if (member.vlocity_ins__IsPrimaryMember__c) {
              tempRequiredFieldsMissingPrimary.push('ARC_HeightInches__c');
            } else {
              tempRequiredFieldsMissingDependent.push('ARC_HeightInches__c');
            }

          }
        }
      }


      //    Checks if the ssn is empty. If it is, it will show an error message.
      if (!errorSSN && member.vlocity_ins__SocialSecurityNumber__c) {
        if (member.vlocity_ins__SocialSecurityNumber__c == "" || member.vlocity_ins__SocialSecurityNumber__c == undefined || member.vlocity_ins__SocialSecurityNumber__c == null) {
          errorSSN = true;
          ssnHasLess = true;
          if (depMemberBirthdate < ninetyDaysAgoDate) {
            tempRequiredFieldsMissing.push('vlocity_ins__SocialSecurityNumber__c')
            if (member.vlocity_ins__IsPrimaryMember__c) {
              tempRequiredFieldsMissingPrimary.push('vlocity_ins__SocialSecurityNumber__c');
            } else {
              tempRequiredFieldsMissingDependent.push('vlocity_ins__SocialSecurityNumber__c');
            }
          }


        }
        else if (member.vlocity_ins__SocialSecurityNumber__c.length <= 8) {
          errorSSN = true;
          ssnHasLess = true;
          if (depMemberBirthdate < ninetyDaysAgoDate) {
            tempRequiredFieldsMissing.push('vlocity_ins__SocialSecurityNumber__c')

            if (member.vlocity_ins__IsPrimaryMember__c) {
              tempRequiredFieldsMissingPrimary.push('vlocity_ins__SocialSecurityNumber__c');
            } else {
              tempRequiredFieldsMissingDependent.push('vlocity_ins__SocialSecurityNumber__c');
            }

          }
        }
        else if (member.vlocity_ins__SocialSecurityNumber__c.length < 9 || !regex.test(member.vlocity_ins__SocialSecurityNumber__c)) {
          errorSSN = true;
          ssnHasError = true;
          if (depMemberBirthdate < ninetyDaysAgoDate) {
            tempRequiredFieldsMissing.push('vlocity_ins__SocialSecurityNumber__c')

            if (member.vlocity_ins__IsPrimaryMember__c) {
              tempRequiredFieldsMissingPrimary.push('vlocity_ins__SocialSecurityNumber__c');
            } else {
              tempRequiredFieldsMissingDependent.push('vlocity_ins__SocialSecurityNumber__c');
            }

          }
        }
      } else if (this.osData.FieldsetType != 'IFPShop' && this.osData.FieldsetType != 'IFPProgramChangePlan' && !member.vlocity_ins__SocialSecurityNumber__c) {
        if (depMemberBirthdate < ninetyDaysAgoDate) {
          tempRequiredFieldsMissing.push('vlocity_ins__SocialSecurityNumber__c')
          notABaby = true;

          if (member.vlocity_ins__IsPrimaryMember__c) {
            tempRequiredFieldsMissingPrimary.push('vlocity_ins__SocialSecurityNumber__c');
          } else {
            tempRequiredFieldsMissingDependent.push('vlocity_ins__SocialSecurityNumber__c');
          }

        }
      }



      tempRequiredFieldsMissing.forEach(reqField => {

        if (reqField.includes('Mailing')) {
          tempRequiredFieldsMissing.pop(reqField);
        }
      })

      if (tempRequiredFieldsMissing.length > 0) {
        console.log('tempRequiredFieldsMissing', tempRequiredFieldsMissing);
        console.log('tempRequiredFieldsMissingPrimary', tempRequiredFieldsMissingPrimary);

        let RequiredFieldsMissingPrimary = this.changeLabelsForErrorFields(tempRequiredFieldsMissingPrimary);
        let RequiredFieldsMissingDependent = this.changeLabelsForErrorFields(tempRequiredFieldsMissingDependent);
        console.log('RequiredFieldsMissingPrimary', RequiredFieldsMissingPrimary);
        let uniquePrimary = [... new Set(RequiredFieldsMissingPrimary)]
        let uniqueDependent = [... new Set(RequiredFieldsMissingDependent)]

        let errorStringPrimary = "";
        let errorStringDependent = "";
        uniquePrimary.forEach(element => {
          errorStringPrimary = errorStringPrimary + ", " + element;
        });
        uniqueDependent.forEach(element => {
          errorStringDependent = errorStringDependent + ", " + element;
        });

        errorStringPrimary = errorStringPrimary.substring(1);
        errorStringDependent = errorStringDependent.substring(1);

        let errorMap = {
          'errorMap': {
            'primaryFields': errorStringPrimary,
            'dependentFields': errorStringDependent
          }
        }
        this.omniApplyCallResp(errorMap);
      } else if (tempRequiredFieldsMissing.length == 0) {
        errorMap.clear();
        this.omniApplyCallResp(errorMap);
      }



      // Different errors
      if (error && this.osData.nextStepValidation == true) {
        member.error = 'Required field/s missing';
        // } 
        // else if (noSaleState) {
        //     member.error = 'Unfortunately, our program is not available in your state.';
      } else if (heightOver7) {
        heightsFeets = true;
        member.error = 'Height cannot be more than 7 feet.';
      } else if (heightOver12) {
        heightsInches = true;
        member.error = 'Height cannot be more than 12 inches.';
      } else if (!AddOver18Dependent) {
        member.error = 'You need to add a new dependent over 18 years old.';
      } else if (futureBirthDate) {
        member.error = 'Invalid Birthdate. Future dates are not allowed.';
      } else if (childFamilyError) {
        member.error = 'Dependent members of the child family must be younger than primary member.';
      } else if (newBornAddMember) {
        member.error = 'Cant add a newborn. Please go to the 360º view and select "Add Newborn" icon in the member card.';
      } else if (newBorn) {
        member.error = 'Cant add a non-newborn. Please go to the 360º view and make a Program Change selecting "Add Member" as a reason.';
      } else if (primaryOver65) {
        // member.error = 'Applicant cannot be more than 65 years old.';
      } else if (childOver26) {
        childError = true;
        member.error = 'Child Dependent cannot be more than 26 years old.';
      } else if (spouseOver65) {
        spouseError = true;
        member.error = 'Spouse Dependent cannot be 65 or older.'
      }
      else if (childOver18) {
        childError = true;
        member.error = 'Dependents over 18 must enter a phone and an email.';
      }
      else if (memberOver18noEmailPhone) {
        memberOver18noEmailPhoneError = true;
        member.error = 'Members over 18 must enter a phone and an email.';
      }
      //  else if (notABaby) {
      //     childError = true;
      //     member.error = 'The SSN is empty and dependent birthdate is over 90 days ago. Please enter it (8 digits, no letters).';
      // } 
      else if (moreThanOneSpouse) {
        spouseError = true;
        member.error = "Primary Applicant can't have more than one spouse.";
      } else if (errorSSN && ssnHasError && this.osData.nextStepValidation == true) {
        SSNError1 = true;
        member.error = 'the SSN is empty or a letter has been entered. please re-enter it.';
      } else if (errorSSN && ssnHasLess) {
        SSNError2 = true;
        member.error = 'the SSN has less than 8 digits.';
      } else if (member.error) {
        delete member.error;
      }
    });



    if ((this.osData.STEP_RemoveMember?.FRML_PrimaryWasSelected && !this.osData.STEP_RemoveMember.FRML_PrimaryWasSelected) || this.addedNewPrimary || this.osData.AddNewborn || !this.osData.RemoveMember || this.osData.AddMember && !this.osData.NewPrimaryIsMinor || this.osData.FieldsetType == 'IFPShop' || this.osData.FieldsetType == 'IFPEnroll' || this.osData.FieldsetType == 'IFPProgramChangePlan') {
      this.saveMemberFilterForNewPrimary = true;


    } else if (this.osData.STEP_RemoveMember.FRML_PrimaryWasSelected) {
      this.saveMemberFilterForNewPrimary = false;
    }


    if (this.hasOneMedical && this.planSave || this.hasOneDental && this.planSave || this.hasOneVision && this.planSave) {
      this.planSave = false;
      this.saveMembers(true);
    }


    //This block code dynamically changes the requiredFieldMissing of the census if a field has an error and will not let the user to click next
    //until the issue is solved.


    if (tempRequiredFieldsMissing.length > 0) {



      if (tempRequiredFieldsMissingPrimary.length > 0) {
        this.requiredFieldMissing = true;
        this.omniApplyCallResp(
          {
            'requiredFieldMissingPrimary': false,
          }
        )
      } else {
        this.omniApplyCallResp(
          {
            'requiredFieldMissingPrimary': true,
          }
        )
      }
      if (tempRequiredFieldsMissingDependent.length > 0) {

        this.requiredFieldMissing = true;
        this.omniApplyCallResp(
          {
            'requiredFieldMissingDependent': false,
          }
        )
      } else {
        this.omniApplyCallResp(
          {
            'requiredFieldMissingDependent': true,
          }
        )
      }

    } else
      if (hasErrorSaleState) {
        this.requiredFieldMissing = true;

      } else if (hasErrorDates) {
        this.requiredFieldMissing = true;

      } else if (spouseError) {
        this.requiredFieldMissing = true;

      } else if (childError) {
        this.requiredFieldMissing = true;

      } else if (SSNError1) {
        this.requiredFieldMissing = true;

      } else if (SSNError2) {
        this.requiredFieldMissing = true;

      } else if (heightsFeets) {
        this.requiredFieldMissing = true;
      } else if (heightsInches) {
        this.requiredFieldMissing = true;
      }
      else if (memberOver18noEmailPhoneError) {
        this.requiredFieldMissing = true;

      }

      else if (!this.saveMemberFilterForNewPrimary) {
        this.omniApplyCallResp(
          {
            'DidntAddNewPrimary': true,
            'requiredFieldMissingDependent': true,
            'requiredFieldMissingPrimary': true
          }
        )

      } else {
        this.requiredFieldMissing = false;
        this.omniApplyCallResp(
          {
            'DidntAddNewPrimary': false,
            'requiredFieldMissingDependent': true,
            'requiredFieldMissingPrimary': true
          }
        )
      }
    if (this.addedNewPrimary) {
      this.omniApplyCallResp(
        {
          'AddOver18Dependent': true
        }
      )

    }

    if (this.saveMemberFilterForNewPrimary) {
      this.omniApplyCallResp(
        {
          'DidntAddNewPrimary': false
        }
      )
    }

    this.stateData = omniscriptUtils.getSaveState(this);
    this.osData = JSON.parse(JSON.stringify(this.omniJsonData));
  }

  //This function replaces the address of the dependent with the one selected in the primary member.
  replaceAddress(member, memberSaved) {

    if (member.ARC_PhysicalAddressCity__c != null && member?.ARC_PhysicalAddressCity__c?.length == 15) {
      member.ARC_PhysicalAddressCity__c = member.ARC_PhysicalAddressCity__c + ' ';
    }
    memberSaved.ARC_PhysicalAddressCity__c = member.ARC_PhysicalAddressCity__c;
    if (member.ARC_PhysicalAddressState__c != null && member?.ARC_PhysicalAddressState__c?.length == 15) {
      member.ARC_PhysicalAddressState__c = member.ARC_PhysicalAddressState__c + ' ';
    }
    memberSaved.ARC_PhysicalAddressState__c = member.ARC_PhysicalAddressState__c;
    if (member.ARC_PhysicalAddressStreet__c != null && member?.ARC_PhysicalAddressStreet__c?.length == 15) {
      member.ARC_PhysicalAddressStreet__c = member.ARC_PhysicalAddressStreet__c + ' ';
    }
    memberSaved.ARC_PhysicalAddressStreet__c = member.ARC_PhysicalAddressStreet__c;
    if (member.ARC_PhysicalAddressZipCode__c != null && member?.ARC_PhysicalAddressZipCode__c?.length == 15) {
      member.ARC_PhysicalAddressZipCode__c = member.ARC_PhysicalAddressZipCode__c + ' ';
    }
    memberSaved.ARC_PhysicalAddressZipCode__c = member.ARC_PhysicalAddressZipCode__c;

    return memberSaved;
  }


  //This function generates the messaging dynamically of uncommitted changes. 
  generateMessaging(employees, newCensusMap) {

    let savedAuxMessaging = [];
    let employeesAux = [];
    let deleteEmployees = JSON.parse(JSON.stringify(employees));
    let savedAuxWithDependents = [];

    //If the user clicks "previous" the savedMembers will be saved in the osData and it will be retrieved here, instead if the user is
    //working in the lwc will retrieve the data from a global array. 
    if (this.osData.savedMembersForUncommited && this.osData.savedMembersForUncommited.length > this.savedMembersForUncommited.length) {
      this.savedAux = JSON.parse(JSON.stringify(this.osData.savedMembersForUncommited));
    } else {
      this.savedAux = JSON.parse(JSON.stringify(this.savedMembersForUncommited));
    }
    savedAuxWithDependents = this.savedAux;

    if (this.savedAux.length > 0) {
      this.savedAux.forEach(m => {
        //This block code will copy all the fields that are in the field set to an object. 
        if (m.vlocity_ins__IsPrimaryMember__c == true) {
          let employeesMap = {};
          delete m.dependents;
          delete m.ARC_EnrollmentCensusMember__c;


          delete m.vlocity_ins__RelatedCensusMemberId__c;
          delete m.vlocity_ins__ContractLineId__c;
          delete m.ARC_IgnoreMailing__c;

          for (let [key, value] of Object.entries(m).sort()) {
            if (value == null || value == undefined) {
              value = "";
            }
            if (key.startsWith("ARC") || key.startsWith("vlocity"))
              employeesMap[key] = value;
          }

          savedAuxMessaging.push(employeesMap);
        }

      })
    }
    if (deleteEmployees.length > 0) {
      deleteEmployees.forEach(m => {
        let employeesMap = {};
        delete m.dependents;
        delete m.ARC_EnrollmentCensusMember__c;


        delete m.vlocity_ins__RelatedCensusMemberId__c;
        delete m.vlocity_ins__ContractLineId__c;
        // delete m.ARC_IgnoreMailing__c;

        for (let [key, value] of Object.entries(m).sort()) {
          if (value == null || value == undefined) {
            value = "";
          }
          if (key.startsWith("ARC") || key.startsWith("vlocity"))
            employeesMap[key] = value;
        }

        employeesAux.push(employeesMap);
      })

    }

    if (this.saveCheck == true) {
      this.omniApplyCallResp(

        {
          //    "auxSavedMembers": this.savedAux,
          "uncommittedChanges": true
        }
      );

    }
    this.osData = JSON.parse(JSON.stringify(this.omniJsonData));

    //If auxiliars are differents, the messaging for uncommitted changes will be true, if they are equals it will be false.
    if (this.censunsInfoTrigger == false) {
      if (JSON.stringify(savedAuxMessaging) != JSON.stringify(employeesAux)) {

        this.omniApplyCallResp(

          {
            "uncommittedChanges": true
          }
        );
      }

      else if (JSON.stringify(savedAuxMessaging) == JSON.stringify(employeesAux)) {
        this.omniApplyCallResp(

          {
            "uncommittedChanges": false
          }
        );
        this.dependentUncommittedChanges(employees, savedAuxWithDependents);

      }
    }

    this.requiredFieldsValidation();

  }


  //Messaging for dependents
  dependentUncommittedChanges(employees, savedAuxWithDependents) {

    if (employees.length > 0) {
      let employeesAux = [];
      let savedAuxWithDependentsAux = [];

      employees.forEach(member => {
        if (member.dependents.length > 0) {
          member.dependents.forEach(m => {
            let employeesMap = {};
            delete m.ARC_EnrollmentCensusMember__c;


            delete m.vlocity_ins__RelatedCensusMemberId__c;
            delete m.vlocity_ins__ContractLineId__c;
            // delete m.ARC_IgnoreMailing__c;

            for (let [key, value] of Object.entries(m).sort()) {
              if (value == null || value == undefined) {
                value = "";
              }
              if (key.startsWith("ARC") || key.startsWith("vlocity"))
                employeesMap[key] = value;
            }
            // var mapAsc = new Map([...employeesMap.entries()].sort());         
            employeesAux.push(employeesMap);

          })
        }

      })

      savedAuxWithDependents.forEach(m => {
        let employeesMap = {};
        delete m.ARC_EnrollmentCensusMember__c;


        delete m.vlocity_ins__RelatedCensusMemberId__c;
        delete m.vlocity_ins__ContractLineId__c;
        // delete m.ARC_IgnoreMailing__c;

        if (m.vlocity_ins__IsPrimaryMember__c == false) {

          for (let [key, value] of Object.entries(m).sort()) {
            if (value == null || value == undefined) {
              value = "";
            }
            if (key.startsWith("ARC") || key.startsWith("vlocity"))
              employeesMap[key] = value;
          }
          // var mapAsc = new Map([...employeesMap.entries()].sort());        
          savedAuxWithDependentsAux.push(employeesMap);

        }

      })
      if (JSON.stringify(employeesAux) != JSON.stringify(savedAuxWithDependentsAux)) {

        this.omniApplyCallResp(
          {
            "uncommittedChanges": true
          }
        );
      }

    }



  }

  removeNull(array) {

    return array.filter(x => x !== null)
  }

  saveForLater() {

    let mySaveState = this.osData;
    this.omniSaveState(mySaveState, mySaveState.CensusId);

  }

  handleNext() {

    this.requiredFieldsValidation();
    this.saveMembers(false);

  }

  // GoToNextStep(){

  // }

  isNewborn(member) {

    var currentdate = new Date();
    var memberBirthdate = new Date(member['vlocity_ins__Birthdate__c']);
    var priorDate = new Date().setDate(currentdate.getDate() - 30)
    if (memberBirthdate.getTime() >= priorDate) {
      return true;
    } else {
      return false;
    }
  }

  handlePrev() {

    this.omniPrevStep();
  }

  changeLabelsForErrorFields(tempRequiredFields) {

    let newTempReqFields = [];
    let newElement;
    tempRequiredFields.forEach(element => {
      if (element == "vlocity_ins__FirstName__c") {
        newElement = "First Name";
        newTempReqFields.push(newElement);
      } else if (element == "vlocity_ins__LastName__c") {
        newElement = "Last Name";
        newTempReqFields.push(newElement);
      } else if (element == "vlocity_ins__Birthdate__c") {
        newElement = "Birthdate";
        newTempReqFields.push(newElement);
      } else if (element == "vlocity_ins__Gender__c") {
        newElement = "Gender";
        newTempReqFields.push(newElement);
      } else if (element == "vlocity_ins__SocialSecurityNumber__c") {
        newElement = "SSN";
        newTempReqFields.push(newElement);
      } else if (element == "ARC_HeightFeet__c") {
        newElement = "Height(Feets)";
        newTempReqFields.push(newElement);
      } else if (element == "ARC_HeightInches__c") {
        newElement = "Height(Inches)";
        newTempReqFields.push(newElement);
      } else if (element == "ARC_Weight__c") {
        newElement = "Weight(lbs)";
        newTempReqFields.push(newElement);
      } else if (element == "ARC_PhysicalAddressCity__c") {
        newElement = "Physical Address: City";
        newTempReqFields.push(newElement);
      } else if (element == "ARC_PhysicalAddressState__c") {
        newElement = "Physical Address: State";
        newTempReqFields.push(newElement);
      } else if (element == "ARC_PhysicalAddressStreet__c") {
        newElement = "Physical Address: Street";
        newTempReqFields.push(newElement);
      } else if (element == "ARC_PhysicalAddressZipCode__c") {
        newElement = "Physical Address: Zip Code";
        newTempReqFields.push(newElement);
      } else if (element == "ARC_DependentRelationship__c") {
        newElement = "Relationship";
        newTempReqFields.push(newElement);
      }
      else if (element == "ARC_Phone__c") {
        newElement = "Phone";
        newTempReqFields.push(newElement);
      }
      else if (element == "vlocity_ins__Email__c") {
        newElement = "Email";
        newTempReqFields.push(newElement);
      }
    });
    return newTempReqFields;
  }

  formatARCHeight(auxSavedMembers) {

    auxSavedMembers.forEach(function (member) {
      if (member.ARC_HeightFeet__c && member.ARC_HeightInches__c) {
        member.ARC_Height__c = member.ARC_HeightFeet__c + "' " + member.ARC_HeightInches__c;
      }
    });
    return auxSavedMembers;
  }

  getMembersAmmount() {



    let membersAmmount = this.census.length;
    if (this.osData.FieldsetType == 'IFPProgramChangeAddMember' && this.osData.InvolvedMembers) {
      membersAmmount += this.osData.InvolvedMembers.length;
    }

    return membersAmmount;
  }

  getChildsAmmount(memberList, isPCInitial) {

    if (!isPCInitial && Array.isArray(memberList)) {
      let childsInCensus = memberList?.filter(m => (m.ARC_DependentRelationship__c == 'Child' || m.ARC_DependentRelationship__c == ''));
      return childsInCensus.length;
    }
    else if (isPCInitial && Array.isArray(memberList)) {
      let childsInCensus = memberList?.filter(m => m.Relationship == 'Child');
      return childsInCensus.length;
    }
    else return 0;
  }



  handleCloseExtraDepModal() {
    this.moreThan3Dependents = false;

  }
}