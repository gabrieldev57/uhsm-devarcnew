/* eslint-disable no-else-return */
import { LightningElement, track } from 'lwc';
import getfilteredOSList from "@salesforce/apex/ARC_OmniScriptManager.getfilteredOSList";
import getOSDefinition from "@salesforce/apex/ARC_OmniScriptManager.getOSDefinition";
import getAllMetadataSettings from "@salesforce/apex/ARC_OmniScriptManager.getAllMetadataSettings";
// import getMetadataSettingByApiName from "@salesforce/apex/ARC_OmniScriptManager.getMetadataSettingByApiName";
import saveSettings from "@salesforce/apex/ARC_OmniScriptManager.saveSettings";

export default class ARC_OmniscriptManager extends LightningElement {

/* ----------------------------------------------------------- */
/* ------------------------ VARIABLES ------------------------ */
/* ----------------------------------------------------------- */

    /* -------------------------------- */
    /* --------- GET FROM APEX -------- */
    /* -------------------------------- */
    jsonDef = "";
    settingMetadata = [];
    allMetadataSettings = [];
    
    /* -------------------------------- */
    /* ----- CONDITIONALLY DISPLAY ---- */
    /* -------------------------------- */
    @track page_OSList = false;
    @track page_SETTINGS = false;
    @track page_SETTING_details = false;
    @track page_SETTING_details_children = false;
    @track page_SAVE = false;
    @track page_UNSAVED_CHANGES = false;

    @track enableButtons = false;

    hasBeenInPage_SETTING_details = false;

    @track ready_details = true;
    @track ready_osList = false;
    @track ready_settingList = false;

    @track ringInDiv = false;
    @track ringSaving = false;
    hasBeenEdited = false;

    get isPage_SETTING_details() { if (this.page_SETTING_details && !this.ringInDiv) { return true; } else { return false } }
    get ringAll() { if ((!this.ready_settingList && this.page_SETTINGS) || (!this.ready_osList && this.page_OSList)) { return true; } else { return false } }
    get enableBack() { if (this.ready_settingList) { return true; } else { return false } }
    get enableSave() { if (this.hasBeenEdited && this.page_SETTING_details) { return false; } else { return true; } }
    get isSelected() { if (this.hasBeenInPage_SETTING_details) { return true } else { return false } }
    
    /* -------------------------------- */
    /* ------- DISPLAY ON SCREEN ------ */
    /* -------------------------------- */
    @track osList = []; //FROM APEX
    @track os_displayableJSON = []
    os_displayableJSON2 = []
    @track os_displayableJSON_details = [];
    
    /* -------------------------------- */
    /* --------- GET FROM HTML -------- */
    /* -------------------------------- */
    confLabel ="";
    osId;
    settingApiName = "";

    /* -------------------------------- */
    /* ------------ OTHERS ------------ */
    /* -------------------------------- */
    settingsToDisplay = [];

    /* -------------------------------- */
    /* ------------ TO SAVE ----------- */
    /* -------------------------------- */
    editedSettings = [];

/* ----------------------------------------------------------- */
/* ------------------ WHEN THE LWC STARTS -------------------- */
/* ----------------------------------------------------------- */
    
    connectedCallback() {
        this.page_OSList = true;
        this.getfilteredOSList();
        this.getAllMetadataSettings();

    }

/* ----------------------------------------------------------- */
/* ------------------------ FUNCTIONS ------------------------ */
/* ----------------------------------------------------------- */


    settingHasChildren(confLabel) {
        let hasChildren = false;
        this.os_displayableJSON.forEach(os_lvl1 => {
            if (os_lvl1.confLabel === confLabel) {
                if (os_lvl1.children.length > 0) {
                    hasChildren = true;
                }
            }
        });
        return hasChildren;
    }
    getSettingDetails() {
       this.os_displayableJSON_details = [];
        this.os_displayableJSON2.forEach(os_lvl1 => {
            if (os_lvl1.confLabel === this.confLabel) {
                this.os_displayableJSON_details.push(os_lvl1);
            }
        });
        console.log("---- DISPLAYABLE JSON DETAILS ---");
        console.log(this.os_displayableJSON_details);
        console.log("---------------------------------");
    }
    async getSettingsToDisplay() {
        this.settingsToDisplay = [];
        if (this.confLabel === "") {
            await this.os_displayableJSON.forEach(setting => {
                if (setting.apiName !== undefined) {
                    this.settingsToDisplay.push(setting.apiName);
                }
                if (setting.children.length > 0) {
                    setting.children.forEach(settingChild => {
                        if (settingChild.apiName !== undefined) {
                            this.settingsToDisplay.push(settingChild.apiName);
                        }
                    });
                }
            });
            console.log("------- DISPLAYED SETTINGS ALL ------");
            console.log(this.settingsToDisplay);
            console.log("---------------------------------");
        } else {
            console.log("AAA")
            console.log(this.os_displayableJSON_details);
            await this.os_displayableJSON_details.forEach(setting => {
                if (setting.apiName!==undefined) {
                    this.settingsToDisplay.push(setting.apiName);
                    console.log(setting.apiName);
                }
                if (setting.children.length>0) {
                    setting.children.forEach(settingChild => {
                        if (settingChild.apiName !== undefined) {
                            console.log(settingChild.apiName);
                            this.settingsToDisplay.push(settingChild.apiName);
                        }
                    });
                }
        });
        console.log("------- DISPLAYED SETTINGS ------");
        console.log(this.settingsToDisplay);
        console.log("---------------------------------");
        }
        
        
    }
    async getSettingMetadata() {
        this.settingMetadata = [];
        for (const s of await this.settingsToDisplay) {
            this.allMetadataSettings.forEach(a => {
                if (a.QualifiedApiName===s) {
                    this.settingMetadata.push(a);
                }
            });
        }
        let a = await this.settingMetadata
        this.settingMetadata = [];
        await Promise.all(a).then(values => {
            this.settingMetadata.push(values);
        });
        this.settingMetadata = await this.settingMetadata[0];
        console.log("------- SETTING METADATA --------");
        console.log(this.settingMetadata);
        console.log("---------------------------------");
    }

    mergeMetadataOSJSON() {
        
        let children = [];
        let newJSON = [];
        if (this.confLabel==="") {
            this.os_displayableJSON.forEach(d => {
                this.settingMetadata.forEach(s => {
                    d.children.forEach(dChild => {
                        if (dChild.apiName === s.QualifiedApiName) {
                            children.push({
                                longText: s.ARC_LongText__c,
                                value: s.ARC_Value__c,
                                visible: s.ARC_Visible__c,
                                display: dChild.display,
                                confLabel: dChild.confLabel,
                                apiName: s.QualifiedApiName
                            })
                        }
                    });
                    if (d.apiName !== undefined) {
                        if (d.apiName === s.QualifiedApiName) {
                            newJSON.push({
                                longText: s.ARC_LongText__c,
                                value: s.ARC_Value__c,
                                visible: s.ARC_Visible__c,
                                display: d.display,
                                confLabel: d.confLabel,
                                apiName: s.QualifiedApiName,
                                children: children
                            });
                        }
                    } 
                });
                if (d.apiName === undefined) {
                    newJSON.push({
                            visible: true,
                            display: d.display,
                            confLabel: d.confLabel,
                            children: children
                        });
                    }
            });
            this.os_displayableJSON = newJSON;
            console.log("----- DISPLAYABLE JSON MERGED----");
            console.log(this.os_displayableJSON);
            console.log("---------------------------------");
            this.ready_settingList = true;
        } else {
            this.os_displayableJSON_details.forEach(d => {
                    this.settingMetadata.forEach(s => {
                        d.children.forEach(dChild => {
                            if (dChild.apiName === s.QualifiedApiName) {
                                console.log("APINAME: " + s.QualifiedApiName);
                                children.push({
                                    longText: s.ARC_LongText__c,
                                    value: s.ARC_Value__c,
                                    visible: s.ARC_Visible__c,
                                    display: dChild.display,
                                    confLabel: dChild.confLabel,
                                    apiName: s.QualifiedApiName
                                })
                            }
                        });
                        if (d.apiName !== undefined) {
                            if (d.apiName === s.QualifiedApiName) {
                                console.log("APINAME: " + s.QualifiedApiName);
                                newJSON.push({
                                    longText: s.ARC_LongText__c,
                                    value: s.ARC_Value__c,
                                    visible: s.ARC_Visible__c,
                                    display: d.display,
                                    confLabel: d.confLabel,
                                    apiName: s.QualifiedApiName,
                                    children: children
                                });
                            }
                        }
                    });
                    if (d.apiName === undefined) {
                        newJSON.push({
                            visible: true,
                            display: d.display,
                            confLabel: d.confLabel,
                            children: children
                        });
                    }
                
            });   
                
            
        this.os_displayableJSON_details = newJSON;
        console.log("------------ NEW JSON -----------");
        console.log(this.os_displayableJSON_details);
        console.log("---------------------------------");
        }
        
    }


    resetAll() {
        this.enableButtons = false;
        this.jsonDef = "";
        this.settingMetadata = [];
        this.allMetadataSettings = [];
        this.page_OSList = false;
        this.page_SETTINGS = false;
        this.page_SETTING_details = false;
        this.page_SETTING_details_children = false;
        this.page_UNSAVED_CHANGES = false;
        this.page_SAVE = false
        this.ready_details = true;
        this.ready_osList = false;
        this.ready_settingList = false;
        this.ringInDiv = false;
        this.hasBeenEdited = false;
        this.osList = []; 
        this.os_displayableJSON = []
        this.os_displayableJSON_details = [];
        this.settingsToDisplay = [];
        this.editedSettings = [];
        this.settingApiName = "";
        this.confLabel = "";
        this.hasBeenInPage_SETTING_details = false;
        this.ringSaving = false;

    }


    async getSettingDetailsAll() {
        this.os_displayableJSON_details = [];
        this.settingsToDisplay = [];
        this.settingMetadata = [];

        if (this.confLabel === "") {
           
            await this.getSettingsToDisplay();
            await this.getSettingMetadata();
            await this.mergeMetadataOSJSON();
            

        } else {
            await this.getSettingDetails();
            await this.getSettingsToDisplay();
            await this.getSettingMetadata();
            await this.os_displayableJSON_details.forEach(osd => {
                if (osd.confLabel === this.confLabel) {
                    if (osd.apiName!==undefined) {
                        this.editedSettings.forEach(eds => {
                            if (eds.setting===osd.apiName) {
                                this.settingMetadata.forEach(sm => {
                                    if (sm.QualifiedApiName===eds.setting) {
                                        if (eds.longText!==undefined) {
                                            sm.ARC_LongText__c = eds.longText;
                                        }
                                        if (eds.visible!==undefined) {
                                            sm.ARC_Visible__c = eds.visible;
                                        }
                                        if (eds.value!==undefined) {
                                            sm.ARC_Value__c = eds.value;
                                        }
                                    }
                                });
                            }
                        });
                    }
                    osd.children.forEach(osdChild => {
                        if (osdChild.apiName!==undefined) {
                            this.editedSettings.forEach(eds => {
                                if (eds.setting===osdChild.apiName) {
                                    this.settingMetadata.forEach(sm => {
                                        if (sm.QualifiedApiName===eds.setting) {
                                            if (eds.longText!==undefined) {
                                                sm.ARC_LongText__c = eds.longText;
                                            }
                                            if (eds.visible!==undefined) {
                                                sm.ARC_Visible__c = eds.visible;
                                            }
                                            if (eds.value!==undefined) {
                                                sm.ARC_Value__c = eds.value;
                                            }
                                        }
                                    });
                                }
                            });
                        }
                    });
                    
                }
            });   
            await this.mergeMetadataOSJSON();
        }
            
    }


/* ----------------------------------------------------------- */
/* ------------------------- EVENTS -------------------------- */
/* ----------------------------------------------------------- */

    
    evt_clickBack() {
        if (this.enableSave) {
            this.resetAll();
            this.page_OSList = true;
            this.getfilteredOSList();
            this.getAllMetadataSettings();
        } else{
            this.page_UNSAVED_CHANGES = true;
        }
        
    }

    async evt_clickContinue() {
        
        this.page_SAVE = false;
        
    }

    evt_clickDiscard() {
        this.resetAll();
        this.page_OSList = true;
        this.getfilteredOSList();
        this.getAllMetadataSettings();
    }
    
    async evt_OSClick(event) {
        
        this.page_OSList = false;
        this.page_SETTINGS = true;

        this.osId = event.target.dataset.osid;
        await this.getOSDefinition(this.osId);
        console.log("------ SELECTED OMNISCRIPT ------");
        console.log("Id: " + this.osId);
        console.log("JSONDef:");
        console.log(this.jsonDef);
        console.log("---------------------------------");
        this.enableButtons = true;
    }
    async evt_STEPClick(event) {
        this.hasBeenInPage_SETTING_details = true;
        this.ringInDiv = true;

        this.confLabel = event.target.dataset.conflabel;
        this.settingApiName = event.target.dataset.apiname;

        this.os_displayableJSON.forEach(step => delete step.isActive)
        this.os_displayableJSON.forEach(step => {if(step.confLabel === this.confLabel) step.isActive = true});

        console.log("------- SELECTED SETTING --------");
        console.log("confLabel: " + this.confLabel);
        console.log("---------------------------------");
        if (this.ready_details) {
            await this.getSettingDetailsAll(this.confLabel);
        }
        this.page_SETTING_details_children = await this.settingHasChildren(this.confLabel);
        this.page_SETTING_details = true;
        this.ringInDiv = false;
        console.log(this.page_SETTING_details_children);
        

    }
    evt_valueChange(event) {
        this.hasBeenEdited = true;
        let exist = false
        this.editedSettings.forEach(e => {
            
            if (e.setting === event.target.dataset.apiname) {
                exist = true
            }
        });
        if (exist) {
        this.editedSettings.forEach(e => {
            if (e.setting === event.target.dataset.apiname) {
                e.value = event.target.value;
            }
        });
        } else {
        this.editedSettings.push({
            "setting": event.target.dataset.apiname,
            "value": event.target.value
        });
        }
        console.log(this.editedSettings);
    }
    evt_visibleChange(event) {
        this.hasBeenEdited = true;
        let exist = false
        this.stepLabelClass='step-label visible-'+event.target.checked;
        this.os_displayableJSON_details.forEach(d => {
            if (d.apiName===event.target.dataset.apiname) {
                d.visible = event.target.checked;
            }
        });
        this.os_displayableJSON.forEach(d => {
            if (d.apiName===event.target.dataset.apiname) {
                d.visible = event.target.checked;
            }
        });
        this.editedSettings.forEach(e => {
            if (e.setting === event.target.dataset.apiname) {
                exist = true
            }
        });
        if (exist) {
        this.editedSettings.forEach(e => {
            if (e.setting === event.target.dataset.apiname) {
                e.visible = event.target.checked;
            }
        });
        } else {
        this.editedSettings.push({
            "setting": event.target.dataset.apiname,
            "visible": event.target.checked
        });
        }
        console.log(this.editedSettings);
    }
    evt_longTextChange(event) {
        this.hasBeenEdited = true;
        let exist = false
        this.editedSettings.forEach(e => {
            if (e.setting === event.target.dataset.apiname) {
                exist = true
            }
        });
        if (exist) {
        this.editedSettings.forEach(e => {
            if (e.setting === event.target.dataset.apiname) {
                e.longText = event.target.value;
            }
        });
        } else {
        this.editedSettings.push({
            "setting": event.target.dataset.apiname,
            "longText": event.target.value
        });
        }
        console.log(this.editedSettings);
    }
    evt_clickSave(){
        this.editedSettings.forEach((field) => {
            if (field.longText === undefined) {
                this.allMetadataSettings.forEach(m => {
                    if (m.QualifiedApiName === field.setting) {
                        field.longText = m.ARC_LongText__c;
                    }
                });
            }
            if (field.visible===undefined) {
                    this.allMetadataSettings.forEach(m => {
                        if (m.QualifiedApiName === field.setting) {
                            field.visible = m.ARC_Visible__c;
                        }
                    });
                
            }
            if (field.value===undefined) {
                    this.allMetadataSettings.forEach(m => {
                        if (m.QualifiedApiName === field.setting) {
                            field.value = m.ARC_Value__c;
                        }
                    });
                
            }
            console.log(field);
            this.ringSaving = true;
            this.page_SETTINGS = false;
            this.ready_settingList = false;

            saveSettings({
                settingApiName: field.setting,
                longText: field.longText,
                showElement: field.visible,
                value: field.value
            }).then(() => {
                console.log("successful");
                // this.resetAll();
                this.page_SAVE = true;
                this.ringSaving = false;
                            this.page_SETTINGS = true;
                this.ready_settingList = true;
                this.hasBeenEdited = false;


            }).catch((error) => {
                console.log(error);
            });
        });
        this.getSettingDetailsAll(this.confLabel);
    }

    evt_clickCancel() {
        this.page_UNSAVED_CHANGES = false;
    }
    
    
/* ----------------------------------------------------------- */
/* ---------------------- APEX CLASSES ----------------------- */
/* ----------------------------------------------------------- */
    getfilteredOSList() {
        getfilteredOSList()
        .then((result) => {
            this.osList = result;
            this.ready_osList = true;
            // console.log(result);
        })
        .catch((error) => {
            console.log(error);
            console.log("error");
        }); 
    }
    async getOSDefinition(osId) {
                    this.ready_details = false;

        await getOSDefinition({
            Name: osId
        })
        .then((result) => {
            this.jsonDef = "";
            this.os_displayableJSON = [];
            this.os_displayableJSON_details = [];
            
            result.forEach(os => {
                
                if (os.vlocity_ins__Content__c.length > 131072) {
                    console.log("too much text");
                    this.jsonDef = os.vlocity_ins__Content__c;
                } else {
                    this.jsonDef = this.jsonDef + os.vlocity_ins__Content__c;
                }
            });
            this.jsonDef = JSON.parse(this.jsonDef);
            this.jsonDef.children.forEach(os_lvl1 => {
                let os_displayableJSONChildren = [];
                if (os_lvl1.propSetMap.confLabel !== undefined) {
                    if (os_lvl1.propSetMap.children !== undefined) {
                        os_lvl1.propSetMap.children.forEach(os_lvl1_additional => {
                        os_displayableJSONChildren.push({
                            apiName: os_lvl1_additional.apiName,
                            display: os_lvl1_additional.display,
                            confLabel: os_lvl1_additional.confLabel
                        })
                    });
                    }
                    this.os_displayableJSON.push({
                        confLabel:os_lvl1.propSetMap.confLabel,
                        apiName: os_lvl1.propSetMap.apiName,
                        display: os_lvl1.propSetMap.display,
                        children: os_displayableJSONChildren,
                        isActive: false
                    });    
                }
            });

            // let a = await this.os_displayableJSON
            // this.os_displayableJSON = [];
            // await Promise.all(a).then(values => {
            //     this.os_displayableJSON.push(values);
            // });
            // this.os_displayableJSON = await this.os_displayableJSON[0];   
            
            console.log("-------- DISPLAYABLE JSON -------");
            console.log(this.os_displayableJSON);
            console.log("---------------------------------");
            this.os_displayableJSON2 = this.os_displayableJSON;
            this.ready_details = true;


        })
        .catch((error) => {
            console.log(error);
            console.log("error");
        });
                await this.getSettingDetailsAll();

    }
    getAllMetadataSettings() {
        getAllMetadataSettings()
        .then(( result) => {
            this.allMetadataSettings = result;
            console.log("---------- ALL METADATA ---------");
            console.log(this.allMetadataSettings);
            console.log("---------------------------------");
        })
        .catch((error) => {
            console.log(error);
            console.log("error");
        }); 
    } 
    async getMetadataSettingByApiName(settingApiName) {
        let s;
        try {
            s =  await getMetadataSettingByApiName({ settingApiName: settingApiName });
        } catch (error) {
            console.log(error);
        }
        return s;
    }

    

    
}