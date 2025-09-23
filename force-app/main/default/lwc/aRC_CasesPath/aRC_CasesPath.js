import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, RecordFieldDataType, updateRecord  } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Fields for getRecord method in uiRecordApi
const FIELDS = [
    'Case.Status',
    'Case.Reason',
];

/* JSON with all the RecordTypes, Reasons with a specific Path within the RecordType and the Steps of each Reason in default_Steps
To add a Path you must update this JSON creating the RecordType/Reason and then assign it in the setSteps method

Example JSON (You can use this to create new ones)
"Record_Type_Name_JSON": {
    "label": "Actual label for the RecordType",
    "reasons": {
        // These two are specific reasons that have a different Path in the RecordType
        "Reason_Number_1": {
            "label": "Actual label for the Reason number one",
            "steps": [
                // This Steps must correspond to the status of the Case
                { label: "New", value: "New" },
                { label: "Pending Claims Review", value: "Pending Claims Review" },
                { label: "Claims Review Completed", value: "Claims Review Completed" },
                { label: "Pending Benefit Processing", value: "Pending Benefit Processing" },
                { label: "Closed", value: "Closed" }
            ]
        },
        "Reason_Number_2": {
            "label": "Actual label for the Reason number two",
            "steps": [
                // This Steps must correspond to the status of the Case
                { label: "New", value: "New" },
                { label: "Pending PA Review", value: "Pending PA Review" },
                { label: "PA Review Completed", value: "PA Review Completed" },
                { label: "Closed", value: "Closed" }
            ]
        },
        // This is the default Path to every other reason that does not have a different Path
        "default_Steps": {
            "steps": [
                // This Steps must correspond to the status of the Case
                { label: "New", value: "New" },
                { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                { label: "Pending Claims Review", value: "Pending Claims Review" },
                { label: "Claims Review Completed", value: "Claims Review Completed" },
                { label: "Closed", value: "Closed" }
            ]
        }
        // Add as many reasons as needed and repeat from the RecordType
    }
}
*/
const RECORD_STEPS = {
    "Claims_Paper_Medical_Bill": {
        "label": "Claims/Paper Medical Bill",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Pending Benefit Processing", value: "Pending Benefit Processing" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "Claims_Pending_Medical_Bills_Rush_Request": {
        "label": "Claims/Pending Medical Bills/Rush Request",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "Claims_Denied_Medical_Bill": {
        "label": "Claims/Denied Medical Bill",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Pending Member Contact", value: "Pending Member Contact" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "Claims_Medical_Bill_Exception_Reprocess": {
        "label": "Claims/Medical Bill Exception Reprocess",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "Claims_Member_Reimbursement_Request": {
        "label": "Member Reimbursement Request",
        "reasons": {
            "Exception": {
                "label": "Exception",
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "Member Not Eligible", value: "Member Not Eligible" },
                    { label: "Pending Medical Information", value: "Pending Medical Information" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            },
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "Claims_Notification_to_Billing_Dept": {
        "label": "Claims/Notification to Billing Dept",
        "reasons": {
            "Possible_traditional_insurance": {
                "label": "Possible traditional insurance",
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Review", value: "Pending MS Review" },
                    { label: "MS Review Completed", value: "MS Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            },
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "SMB_Paper_Medical_Bill": {
        "label": "SMB/Paper Medical Bill",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Pending Benefit Processing", value: "Pending Benefit Processing" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "SMB_Pending_Medical_Bills_Rush_Request": {
        "label": "SMB/Pending Medical Bills/Rush Request",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "SMB_Denied_Medical_Bill": {
        "label": "SMB/Denied Medical Bill",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Pending Member Contact", value: "Pending Member Contact" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "SMB_Medical_Bill_Exception_Reprocess": {
        "label": "SMB/Medical Bill Exception Reprocess",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "SMB_Member_Reimbursement_Request": {
        "label": "SMB/Member Reimbursement Request",
        "reasons": {
            "Exception": {
                "label": "Exception",
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "Member Not Eligible", value: "Member Not Eligible" },
                    { label: "Pending Medical Information", value: "Pending Medical Information" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            },
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "SMB_Notification_to_Billing_Dept": {
        "label": "SMB/Notification to Billing Dept",
        "reasons": {
            "Possible_traditional_insurance": {
                "label": "Possible traditional insurance",
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Review", value: "Pending MS Review" },
                    { label: "MS Review Completed", value: "MS Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            },
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending Claims Review", value: "Pending Claims Review" },
                    { label: "Claims Review Completed", value: "Claims Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "PA_Change_Request_Updated_PA": {
        "label": "PA/Change Request/Updated PA",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending PA Review", value: "Pending PA Review" },
                    { label: "PA Review Completed", value: "PA Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "PA_Service_Exception": {
        "label": "PA/Service Exception",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "Member Not Eligible", value: "Member Not Eligible" },
                    { label: "Pending PA Review", value: "Pending PA Review" },
                    { label: "PA Review Completed", value: "PA Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "PA_Rush_Request": {
        "label": "PA/Rush Request",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending PA Review", value: "Pending PA Review" },
                    { label: "PA Review Completed", value: "PA Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "PA_Possible_Error_Second_Review_Request": {
        "label": "PA/Possible Error/Second Review Request",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "Pending PA Review", value: "Pending PA Review" },
                    { label: "PA Review Completed", value: "PA Review Completed" },
                    { label: "Contact Member", value: "Contact Member" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
        
    },
    "PA_Appeal": {
        "label": "PA/Appeal",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "Pending PA Review", value: "Pending PA Review" },
                    { label: "PA Review Completed", value: "PA Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "PA_Incomplete_PA_More_information_Needed": {
        "label": "PA/Incomplete PA/More information Needed",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending PA Review", value: "Pending PA Review" },
                    { label: "PA Review Completed", value: "PA Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "MS_Benefit_Inquiry": {
        "label": "MS/Benefit Inquiry",
        "reasons": {
            "Locate_a_provider" : {
                "label": "Locate a provider",
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Review", value: "Pending MS Review" },
                    { label: "Provider not Found", value: "Provider not Found" },
                    { label: "Pending PS Review", value: "Pending PS Review" },
                    { label: "Found Provider", value: "Found Provider" },
                    { label: "Closed", value: "Closed" }
                ]
            },
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Review", value: "Pending MS Review" },
                    { label: "MS Review Completed", value: "MS Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "MS_Complaint": {
        "label": "MS/Complaint",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Manager Review", value: "Pending MS Manager Review" },
                    { label: "MS Manager Review Completed", value: "MS Manager Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "MS_Demographics_Change": {
        "label": "MS/Demographics Change",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Review", value: "Pending MS Review" },
                    { label: "MS Review Completed", value: "MS Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "MS_Member_Request": {
        "label": "MS/Member Request",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "MS_Praise": {
        "label": "MS/Praise",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Review", value: "Pending MS Review" },
                    { label: "MS Review Completed", value: "MS Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    },
    "ARC_MS_Incomplete_PA_More_Information_Needed": {
        "label": "MS/Incomplete PA/More Information Needed",
        "reasons": {
            "default_Steps": {
                "steps": [
                    { label: "New", value: "New" },
                    { label: "Pending MS Review", value: "Pending MS Review" },
                    { label: "MS Review Completed", value: "MS Review Completed" },
                    { label: "Closed", value: "Closed" }
                ]
            }
        }
    }
}

// Toast message variables
const SUCCESS_TITLE = 'Status changed successfully.';
const SUCCESS_VARIANT = 'success';
const ERROR_TITLE = 'You encountered some errors when trying to save this record';
const ERROR_VARIANT = 'error';

export default class ARC_CasesPath extends LightningElement {

    // Case variables
    @api recordId;
    @track caseStatus;
    caseReason;
    caseRecordTypeName;

    // Path variables
    steps;
    selectedStatus;
    selectedClosedStatus;

    // Status change button variables
    buttonText;
    buttonIcon = false;
    buttonLoading = false;

    // Close modal variables
    closedSelection = false;
    closedModalHeader = 'Close This Case';
    closedOptions = [
        { label: 'Closed Approved', value: 'Closed Approved' },
        { label: 'Closed Rejected', value: 'Closed Rejected' },
    ]

    // Mobile/Small screen variables
    stepsMinWidth = 80;
    stepsScrollerInner;
    stepsScrollerWrapper;
    stepsContainer;
    stepsTranslate = 0;    

    // Event listener for the window for Mobile/Small screens
    connectedCallback() {
        //console.log("entro al connected")
        window.addEventListener("resize", () => {
            window.setTimeout( Function.prototype.bind(this.checkStepsWidth()), 0);
            
        });

        document.addEventListener('pointerenter', () => {
            window.setTimeout(Function.prototype.bind(this.checkStepsWidth()), 0);
        });

        document.addEventListener('visibilitychange', () => {
            if(document.visibilityState === 'visible') {
                window.setTimeout(Function.prototype.bind(this.checkStepsWidth()), 0);
            }
        });
    }
    
    // wire method to get Case information
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    case({ error, data }) {
        if(data) {
            this.caseRecordTypeName = data.recordTypeInfo.name;
            this.caseStatus = data.fields.Status.value;
            this.caseReason = data.fields.Reason.value;
            this.setSteps();
        } else if(error) {
            console.log("ERROR:" + error)
        }
    }

    // Steps are defined here
    // First goes by RecordType.label
    // Then a switch follows with the reasons.label in case that there are reasons with a different Path
    // In every specific reason case you have to assign reason.Reason_JSON.steps to this.steps and break the switch 
    // The same must be done with the default case, assign reason.default_Steps.steps to this.steps and break the switch 
    /* Example Code

    // A case is added with the label of the Record_Type_Name_JSON created before
    case RECORD_STEPS.Record_Type_Name_JSON.label:
    // Then there is another switch to filter the Reason
    switch(this.caseReason) {
        // A case is created with the label of each Reason created in the JSON
        case RECORD_STEPS.Record_Type_Name_JSON.reasons.Reason_Number_1.label:
            // this.steps get assigned the steps for the Reason created in the JSON
            this.steps = RECORD_STEPS.Record_Type_Name_JSON.reasons.Reason_Number_1.steps;
            // Every case in the switch must include a break
            break;
        
        // Repeat the cases for all the Reasons created
        case RECORD_STEPS.Record_Type_Name_JSON.reasons.Reason_Number_2.label:
            this.steps = RECORD_STEPS.Record_Type_Name_JSON.reasons.Reason_Number_2.steps;
            break;
            
        // default steps when no specific Reason is matched and uses the RecordType default Path
        default:
            this.steps = RECORD_STEPS.Record_Type_Name_JSON.reasons.default_Steps.steps;
            break;
    }
    break;
    */
    setSteps() {
        //console.log("entro al setSteps")
        switch(this.caseRecordTypeName) {
            case RECORD_STEPS.Claims_Paper_Medical_Bill.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.Claims_Paper_Medical_Bill.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.Claims_Pending_Medical_Bills_Rush_Request.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.Claims_Pending_Medical_Bills_Rush_Request.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.Claims_Denied_Medical_Bill.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.Claims_Denied_Medical_Bill.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.Claims_Medical_Bill_Exception_Reprocess.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.Claims_Medical_Bill_Exception_Reprocess.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.Claims_Member_Reimbursement_Request.label:
                switch(this.caseReason) {
                    case RECORD_STEPS.Claims_Member_Reimbursement_Request.reasons.Exception.label:
                        this.steps = RECORD_STEPS.Claims_Member_Reimbursement_Request.reasons.Exception.steps;
                        break;
                        
                    default:
                        this.steps = RECORD_STEPS.Claims_Member_Reimbursement_Request.reasons.default_Steps.steps;
                        break;
                }
                break;
            
            case RECORD_STEPS.Claims_Notification_to_Billing_Dept.label:
                switch(this.caseReason) {                        
                    case RECORD_STEPS.Claims_Notification_to_Billing_Dept.reasons.Possible_traditional_insurance.label:
                        this.steps = RECORD_STEPS.Claims_Notification_to_Billing_Dept.reasons.Possible_traditional_insurance.steps;
                        break;

                    default:
                        this.steps = RECORD_STEPS.Claims_Notification_to_Billing_Dept.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.SMB_Paper_Medical_Bill.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.SMB_Paper_Medical_Bill.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.SMB_Pending_Medical_Bills_Rush_Request.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.SMB_Pending_Medical_Bills_Rush_Request.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.SMB_Denied_Medical_Bill.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.SMB_Denied_Medical_Bill.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.SMB_Medical_Bill_Exception_Reprocess.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.SMB_Medical_Bill_Exception_Reprocess.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.SMB_Member_Reimbursement_Request.label:
                switch(this.caseReason) {
                    case RECORD_STEPS.SMB_Member_Reimbursement_Request.reasons.Exception.label:
                        this.steps = RECORD_STEPS.SMB_Member_Reimbursement_Request.reasons.Exception.steps;
                        break;
                        
                    default:
                        this.steps = RECORD_STEPS.SMB_Member_Reimbursement_Request.reasons.default_Steps.steps;
                        break;
                }
                break;
            
            case RECORD_STEPS.SMB_Notification_to_Billing_Dept.label:
                switch(this.caseReason) {                        
                    case RECORD_STEPS.SMB_Notification_to_Billing_Dept.reasons.Possible_traditional_insurance.label:
                        this.steps = RECORD_STEPS.SMB_Notification_to_Billing_Dept.reasons.Possible_traditional_insurance.steps;
                        break;

                    default:
                        this.steps = RECORD_STEPS.SMB_Notification_to_Billing_Dept.reasons.default_Steps.steps;
                        break;
                }
                break;
            
            case RECORD_STEPS.PA_Possible_Error_Second_Review_Request.label:
                switch(this.caseReason) {                    
                    default:
                        this.steps = RECORD_STEPS.PA_Possible_Error_Second_Review_Request.reasons.default_Steps.steps;
                        break;
                }
                break;
           
            case RECORD_STEPS.PA_Service_Exception.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.PA_Service_Exception.reasons.default_Steps.steps;
                        break;
                }
                break;
            
            case RECORD_STEPS.PA_Rush_Request.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.PA_Rush_Request.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.PA_Change_Request_Updated_PA.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.PA_Change_Request_Updated_PA.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.PA_Appeal.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.PA_Appeal.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.PA_Incomplete_PA_More_information_Needed.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.PA_Incomplete_PA_More_information_Needed.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.MS_Benefit_Inquiry.label:
                switch(this.caseReason) {
                    case RECORD_STEPS.MS_Benefit_Inquiry.reasons.Locate_a_provider.label:
                        this.steps = RECORD_STEPS.MS_Benefit_Inquiry.reasons.Locate_a_provider.steps;
                        break;

                    default:
                        this.steps = RECORD_STEPS.MS_Benefit_Inquiry.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.MS_Demographics_Change.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.MS_Demographics_Change.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.MS_Complaint.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.MS_Complaint.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.MS_Praise.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.MS_Praise.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.MS_Member_Request.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.MS_Member_Request.reasons.default_Steps.steps;
                        break;
                }
                break;

            case RECORD_STEPS.ARC_MS_Incomplete_PA_More_Information_Needed.label:
                switch(this.caseReason) {
                    default:
                        this.steps = RECORD_STEPS.ARC_MS_Incomplete_PA_More_Information_Needed.reasons.default_Steps.steps;
                        break;
                }
                break;

            default: 
                this.steps = [
                    { label: 'New', value: 'New' },
                    { label: 'Closed', value: 'Closed' }
                ];
                break;
        }

        // A timeout is set to wait until the steps are created to target the active and current one
        window.setTimeout(() => {
            //console.log("entro al setTimeout")
            let activeStep = this.template.querySelector('lightning-progress-step.slds-is-active');
            if(activeStep) {
                activeStep.classList.toggle('slds-is-active');
            }
            // The current step is marked as the active one and also clicked so it's targeted by the change status button
            let currentStep = this.template.querySelector('lightning-progress-step.slds-is-current');
            currentStep.classList.add('slds-is-active');
            currentStep.click();

            this.checkStepsWidth();
        }, 0);
        
        // Is the Case is Closed Rejected or Closed Approved then the last spot in the steps (Closed) is replaced with its corresponding close status
        if(this.caseStatus === 'Closed Rejected' || this.caseStatus === 'Closed Approved') {
            this.steps[this.steps.length - 1].value = this.caseStatus;
            this.steps[this.steps.length - 1].label = this.caseStatus;
        }

        // Every time the Path gets loaded the change status button variables are checked corresponding to the Case status
        this.checkButtonVariables(this.caseStatus);
    }
    
    // Method executed when selecting a Step in the Path
    handlePathSelect(event) {
        //console.log("entro al handlePathSelect")
        // The value is stored in the selectedStatus variable
        this.selectedStatus = event.target.value;
        this.checkButtonVariables(this.selectedStatus);
    }

    // Method executed on change status button click
    handleStatusChange() {
        //console.log("entro al handleStatusChange")
        // If no status is selected then the case status is used
        if(!this.selectedStatus) {
            this.selectedStatus = this.caseStatus;
        }
        // If the status is closed or before being closed, then it follows on the Modal/Popup Box for the closed status
        if(this.selectedStatus === 'Closed' || this.selectedStatus === 'Closed Rejected' || this.selectedStatus === 'Closed Approved' || (this.caseStatus === this.selectedStatus && this.selectedStatus === this.steps[this.steps.length - 2].value)){
            this.closedSelection = true;
        } else {
            // If it's not any closed status it follows the status update
            // Button variables are changed
            this.buttonLoading = true;
            this.buttonText = 'Saving...';
            this.buttonIcon = false;
            // This variable is created to update the status corresponding to the index in the steps variable
            let newStatusIndex;
            // The selected status is looked in the JSON
            for(let i = 0; i < this.steps.length; i++){
                if(this.steps[i].label === this.selectedStatus){
                    newStatusIndex = i;
                    break;
                }
            }
            // If the status is the same, then we take the next status
            if(this.steps[newStatusIndex].value === this.caseStatus){
                newStatusIndex++;
            }
            // Record Update Starts Here
            updateRecord({ fields: { Id: this.recordId, Status: this.steps[newStatusIndex].value } }).then(() => {
                // If it goes from a Closed status to another one then the last node in the steps variable is defined as Closed
                if(this.steps[this.steps.length - 1].label === 'Closed Rejected' || this.steps[this.steps.length - 1].label === 'Closed Approved') {
                    this.steps[this.steps.length - 1].label = 'Closed';
                    this.steps[this.steps.length - 1].value = 'Closed';
                }
                // Toast message showing the success of the update
                const toastEvent = new ShowToastEvent({
                    title: SUCCESS_TITLE,
                    variant: SUCCESS_VARIANT
                });
                this.dispatchEvent(toastEvent);
            }).catch(error => {
                // Toast message showing the error of the update
                const toastEvent = new ShowToastEvent({
                    title: ERROR_TITLE,
                    variant: ERROR_VARIANT,
                    message: error.body.output.fieldErrors.Status[0].message
                });
                this.dispatchEvent(toastEvent);
            }).finally(() => {
                // Button variables are checked
                this.checkButtonVariables(this.steps[newStatusIndex].value);
                this.buttonLoading = false;
            });
        }
    }

    // Method executed when a selecting a Closed status
    closedStatusSelected(event) {
        //console.log("entro al closedStatusSelected")
        // The value is stored in the selectedClosedStatus variable
       this.selectedClosedStatus = event.detail.value;
    }

    // Method executed on Save in the Close Modal/Popup box
    handleClosedStatusChange() {
        //console.log("entro al handleClosedStatusChange")
        // First we close the box
        this.closeModal();
        // If there is any closed status selected we proceed
        if(this.selectedClosedStatus){
            // We change the status change button variables
            this.buttonLoading = true;
            this.buttonText = 'Saving...';
            this.buttonIcon = false
            
            // We start the record update
            updateRecord({ fields: { Id: this.recordId, Status: this.selectedClosedStatus } }).then(() => {
                // If successful que change the caseStatus variable to the closed status
                this.caseStatus = this.selectedClosedStatus;
                // Display the success toast message
                const toastEvent = new ShowToastEvent({
                    title: SUCCESS_TITLE,
                    variant: SUCCESS_VARIANT
                });
                this.dispatchEvent(toastEvent);
                // Change the steps according to the Closed status selected
                this.steps[this.steps.length - 1].value = this.selectedClosedStatus;
                this.steps[this.steps.length - 1].label = this.selectedClosedStatus;
            }).catch(error => {
                // If there is any error then the toast message displays it
                const toastEvent = new ShowToastEvent({
                    title: ERROR_TITLE,
                    variant: ERROR_VARIANT,
                    message: error.body.output.fieldErrors.Status[0].message
                });
                this.dispatchEvent(toastEvent);
            }).finally(() => {
                // And finally we check the button variables and adjust other things
                this.checkButtonVariables(this.selectedClosedStatus);
                this.buttonLoading = false;
                // selectedClosedStatus is assigned to undefined in case that the user opens the modal and saves with no closed status selected, this will prevent it from updating
                this.selectedClosedStatus = undefined;
            });
        }
    }

    // Status change button variables are checked according to the status
    // These values are from the original Salesforce Path
    checkButtonVariables(statusCheck) {
        //console.log("entro al checkButtonVariables")
        if(statusCheck === 'Closed') {
            this.buttonText = 'Select Closed Status';
            this.buttonIcon = false;
        } else if(statusCheck === 'Closed Rejected' || statusCheck === 'Closed Approved') {
            this.buttonText = 'Change Closed Status';
            this.buttonIcon = false;
        } else if(statusCheck === this.caseStatus) {
            this.buttonText = 'Mark Step as Complete';
            this.buttonIcon = true;
        } else {
            this.buttonText = 'Mark as Current Status';
            this.buttonIcon = false;
        }
    }

    // Method that closes the Closed Modal/Popup box
    closeModal() {
        this.closedSelection = false;
    }

    // Method that executes once the page loads and every time it changes size
    checkStepsWidth() {
        //console.log("entro al checkStepsWidth")
        // Save the scroller div
        if(!this.stepsScrollerInner) {
           
            //console.log("entro al stepsScrollerInner")
            this.stepsScrollerInner = this.template.querySelector('div.slds-path__scroller_inner');
        }
            
        // Save the container of the steps
        if(!this.stepsContainer) {
            //console.log("entro al stepsContainer")
            this.stepsContainer = this.template.querySelector('div.slds-path__scroller-container');
        }

        if(+this.stepsContainer.clientWidth !== 0) {
            // Check if the container size y less than the amount of steps and the steps minimum width (80px), plus another step for the buttons
            if(+this.stepsContainer.clientWidth < (+this.steps.length * +this.stepsMinWidth) + +this.stepsMinWidth) {
               // Add this class to the path track
                let pathTrackDiv = this.template.querySelector('div.slds-path__track');
                pathTrackDiv.classList.add('slds-has-overflow');
                
                // Switch between the classes in the scroller div
                this.stepsScrollerInner.classList.remove('scroller-inner__helper');
                this.stepsScrollerInner.classList.add('scroller-inner__overflow-helper');
            } else {

                let pathTrackDiv = this.template.querySelector('div.slds-path__track');
                pathTrackDiv.classList.remove('slds-has-overflow');
                
                this.stepsScrollerInner.classList.add('scroller-inner__helper');
                this.stepsScrollerInner.classList.remove('scroller-inner__overflow-helper');
                this.stepsScrollerInner.style.transform = '';
            }
        }
        
    }

    // Method that executes on the scroller buttons
    handleStatusScroll(event) {
        //console.log("entro al handleStatusScroll")
        // Save the scroller wrapper to check its size
        if(!this.stepsScrollerWrapper) {
            this.stepsScrollerWrapper = this.template.querySelector('div.scroller-wrapper');
        }

        // Defined maximum and minimum translations for the scroller div
        let maxTranslate = 0;
        // Minimum is the total size of the scroller div minus the scroller wrapper and it has to be negative for the translation
        let minTranslate = this.stepsScrollerWrapper.clientWidth - this.stepsScrollerInner.clientWidth;   

        // Check which button was clicked and add an amount of 100 to the translation variable
        if(event.target.name === 'rightScrollButton') {
            this.stepsTranslate -= 100;
        } else {
            this.stepsTranslate += 100;
        }

        // If it surpasses the limits of translation then the limit is set
        if(this.stepsTranslate < minTranslate) {
            this.stepsTranslate = minTranslate;
        }
        if(this.stepsTranslate > maxTranslate) {
            this.stepsTranslate = maxTranslate;
        }

        // The transform is added to the scroller div
        this.stepsScrollerInner.style.transform = `translateX(${this.stepsTranslate}px)`;
    }
}