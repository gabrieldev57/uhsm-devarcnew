import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'vlocity_ins/omniscriptBaseMixin';

const sectionAColumns = [
    { label: 'SECTION A', fieldName: 'membername', type: 'text', hideDefaultActions: true },
    { label: 'Unexplained Symptoms', fieldName: 'unexplainedsymptoms', type: 'boolean' },
    { label: 'Internations', fieldName: 'internations', type: 'boolean' },
    { label: 'Addictions', fieldName: 'addictions', type: 'boolean' },
    { label: 'Pending Tests', fieldName: 'pendingtests', type: 'boolean' },
    { label: 'Consults', fieldName: 'consults', type: 'boolean' },
];

const sectionBColumns = [
    { label: 'SECTION B', fieldName: 'membername', type: 'text', hideDefaultActions: true },
    { label: 'Pre-existing conditions', fieldName: 'conditions', type: 'text', hideDefaultActions: true }
];

const sectionCColumns = [
    { label: 'CANCER INFORMATION', fieldName: 'membername', type: 'text', hideDefaultActions: true },
    { label: 'Type', fieldName: 'type', type: 'text', hideDefaultActions: true },
    { label: 'Date', fieldName: 'date', type: 'date', hideDefaultActions: true }
];

const sectionDColumns = [
    { label: 'PRESCRIPTION MEDICATIONS', fieldName: 'membername', type: 'text', hideDefaultActions: true },
    { label: 'Medication', fieldName: 'medication', type: 'text', hideDefaultActions: true },
    { label: 'Months Used', fieldName: 'months', type: 'number', hideDefaultActions: true, cellAttributes: { alignment: 'left' } },
    { label: 'Reason for Medication', fieldName: 'reason', type: 'text', hideDefaultActions: true }
];

const sectionEColumns = [
    { label: 'PRIMARY CARE INFORMATION', fieldName: 'membername', type: 'text', hideDefaultActions: true },
    { label: 'Physician’s Name', fieldName: 'physician', type: 'text', hideDefaultActions: true },
    { label: 'City', fieldName: 'city', type: 'text', hideDefaultActions: true },
    { label: 'Phone Number', fieldName: 'phone', type: 'phone', hideDefaultActions: true },
];

export default class Arc_MedicalQuestionsSummary extends OmniscriptBaseMixin(LightningElement) {
    @api medicalquestions;

    sectionAColumns = sectionAColumns;
    sectionAData = [];

    sectionBColumns = sectionBColumns;
    sectionBData = [];

    sectionCColumns = sectionCColumns;
    sectionCData = [];

    sectionDColumns = sectionDColumns;
    sectionDData = [];

    sectionEColumns = sectionEColumns;
    sectionEData = [];

    connectedCallback() {
        let medicalQuestions = JSON.parse(JSON.stringify(this.medicalquestions));
        this.createSectionAData(medicalQuestions);

        let pastConditions = medicalQuestions.RAD_PastConditions;
        if (pastConditions == "Yes" && medicalQuestions.EB_PastConditions != undefined && medicalQuestions.EB_PastConditions != null) {
            this.createSectionBData(medicalQuestions);
        }
        else {
            let emptyTableMessage = {
                membername: "Pre-Existing Conditions are empty",
            }
            this.sectionBData.push(emptyTableMessage);
        }

        let cancer = medicalQuestions.RAD_Cancer;
        if (cancer == "Yes" && medicalQuestions.EB_Cancer != undefined && medicalQuestions.EB_Cancer != null) {
            this.createSectionCData(medicalQuestions);
        }
        else {
            let emptyTableMessage = {
                membername: "Cancer Information is empty",
            }
            this.sectionCData.push(emptyTableMessage);
        }

        let prescriptions = medicalQuestions.RAD_PrescriptionMedications;
        if (prescriptions == "Yes" && medicalQuestions.ED_MemberPrescription != undefined && medicalQuestions.ED_MemberPrescription != null) {
            this.createSectionDData(medicalQuestions);
        }
        else {
            let emptyTableMessage = {
                membername: "Prescription Medications are empty",
            }
            this.sectionDData.push(emptyTableMessage);
        }

        if (medicalQuestions.EB_Physician != undefined && medicalQuestions.EB_Physician != null) {
            this.createSectionEData(medicalQuestions);
        }
        else {
            let emptyTableMessage = {
                membername: "Primary Care Information is empty",
            }
            this.sectionDData.push(emptyTableMessage);
        }
    }

    createSectionAData(medicalQuestions) {
        if (medicalQuestions.RAD_UnexplainedSymptoms == "Yes") {
            let BLK_UnexpectedSymptoms = medicalQuestions.BLK_UnexpectedSymptoms;
            if (BLK_UnexpectedSymptoms != undefined && BLK_UnexpectedSymptoms != null && BLK_UnexpectedSymptoms.length > 0) {
                for (let i = 0; i < BLK_UnexpectedSymptoms.length; i++) {
                    const element = BLK_UnexpectedSymptoms[i];
                    let member = undefined;
                    if (element.TXT_MemberIdUnexpectedSymptoms != null && element.TXT_MemberIdUnexpectedSymptoms != undefined) {
                        const memberId = element.TXT_MemberIdUnexpectedSymptoms;
                        member = this.sectionAData.find(x => x.id === memberId)
                    }
                    if (member != undefined) {
                        member.unexplainedsymptoms = element.CHKBOX_UnexpectedSymptoms;
                    } else {
                        let newMember = {
                            id: element.TXT_MemberIdUnexpectedSymptoms,
                            membername: element.TXT_MemberUnexpectedSymptoms,
                            unexplainedsymptoms: element.CHKBOX_UnexpectedSymptoms
                        };
                        this.sectionAData.push(newMember);
                    }
                }
            }
        }

        if (medicalQuestions.RAD_Internations == "Yes") {
            let BLK_Internations = medicalQuestions.BLK_Internations;
            if (BLK_Internations != undefined && BLK_Internations != null && BLK_Internations.length > 0) {
                for (let i = 0; i < BLK_Internations.length; i++) {
                    const element = BLK_Internations[i];
                    let member = undefined;
                    if (element.TXT_MemberIdInternations != null && element.TXT_MemberIdInternations != undefined) {
                        const memberId = element.TXT_MemberIdInternations;
                        member = this.sectionAData.find(x => x.id === memberId)
                    }
                    if (member != undefined) {
                        member.internations = element.CHKBOX_Internations;
                    } else {
                        let newMember = {
                            id: element.TXT_MemberIdInternations,
                            membername: element.TXT_MemberInternations,
                            internations: element.CHKBOX_Internations
                        };
                        this.sectionAData.push(newMember);
                    }
                }
            }
        }

        if (medicalQuestions.RAD_Addictions == "Yes") {
            let BLK_Addictions = medicalQuestions.BLK_Addictions;
            if (BLK_Addictions != undefined && BLK_Addictions != null && BLK_Addictions.length > 0) {
                for (let i = 0; i < BLK_Addictions.length; i++) {
                    const element = BLK_Addictions[i];
                    let member = undefined;
                    if (element.TXT_MemberIdAddictions != null && element.TXT_MemberIdAddictions != undefined) {
                        const memberId = element.TXT_MemberIdAddictions;
                        member = this.sectionAData.find(x => x.id === memberId)
                    }
                    if (member != undefined) {
                        member.addictions = element.CHKBOX_Addictions;
                    } else {
                        let newMember = {
                            id: element.TXT_MemberIdAddictions,
                            membername: element.TXT_MemberAddictions,
                            addictions: element.CHKBOX_Addictions
                        };
                        this.sectionAData.push(newMember);
                    }
                }
            }
        }

        if (medicalQuestions.RAD_PendingTests == "Yes") {
            let BLK_PendingTests = medicalQuestions.BLK_PendingTests;
            if (BLK_PendingTests != undefined && BLK_PendingTests != null && BLK_PendingTests.length > 0) {
                for (let i = 0; i < BLK_PendingTests.length; i++) {
                    const element = BLK_PendingTests[i];
                    let member = undefined;
                    if (element.TXT_MemberIdPendingTests != null && element.TXT_MemberIdPendingTests != undefined) {
                        const memberId = element.TXT_MemberIdPendingTests;
                        member = this.sectionAData.find(x => x.id === memberId)
                    }
                    if (member != undefined) {
                        member.pendingtests = element.CHKBOX_PendingTests;
                    } else {
                        let newMember = {
                            id: element.TXT_MemberIdPendingTests,
                            membername: element.TXT_MemberPendingTests,
                            pendingtests: element.CHKBOX_PendingTests
                        };
                        this.sectionAData.push(newMember);
                    }
                }
            }
        }

        if (medicalQuestions.RAD_Consults == "Yes") {
            let BLK_Consults = medicalQuestions.BLK_Consults;
            if (BLK_Consults != undefined && BLK_Consults != null && BLK_Consults.length > 0) {
                for (let i = 0; i < BLK_Consults.length; i++) {
                    const element = BLK_Consults[i];
                    let member = undefined;
                    if (element.TXT_MemberIdConsults != null && element.TXT_MemberIdConsults != undefined) {
                        const memberId = element.TXT_MemberIdConsults;
                        member = this.sectionAData.find(x => x.id === memberId)
                    }
                    if (member != undefined) {
                        member.consults = element.CHKBOX_Consulted;
                    } else {
                        let newMember = {
                            id: element.TXT_MemberIdConsults,
                            membername: element.TXT_MemberConsults,
                            consults: element.CHKBOX_Consulted
                        };
                        this.sectionAData.push(newMember);
                    }
                }
            }
        }

        if (this.sectionAData.length == 0) {
            let emptyTableMessage = {
                membername: "Section A is empty"
            }
            this.sectionAData.push(emptyTableMessage);
        }
    }

    createSectionBData(medicalQuestions) {
        let EB_PastConditions = medicalQuestions.EB_PastConditions;
        if (EB_PastConditions != undefined && EB_PastConditions != null && EB_PastConditions.length > 0) {
            for (let i = 0; i < EB_PastConditions.length; i++) {
                const element = EB_PastConditions[i];
                const memberId = element.TXT_MemberIdPastConditions;
                let member = this.sectionBData.find(x => x.id === memberId)
                if (member != undefined) {
                    if (element.MULSEL_Conditions == undefined) {
                        member.conditions = element.TXT_MemberOtherPastConditions;
                    } else if (element.TXT_MemberOtherPastConditions == undefined) {
                        member.conditions = element.MULSEL_Conditions;
                    } else {
                        member.conditions = element.MULSEL_Conditions + ';' + element.TXT_MemberOtherPastConditions;
                    }
                } else {
                    let jointConditions = '';
                    if (element.MULSEL_Conditions == undefined) {
                        jointConditions = element.TXT_MemberOtherPastConditions;
                    } else if (element.TXT_MemberOtherPastConditions == undefined) {
                        jointConditions = element.MULSEL_Conditions;
                    } else {
                        jointConditions = element.MULSEL_Conditions + ';' + element.TXT_MemberOtherPastConditions;
                    }
                    let newMember = {
                        id: memberId,
                        membername: element.TXT_MemberPastConditions,
                        conditions: jointConditions
                    };
                    this.sectionBData.push(newMember);
                }
            }
        }
    }

    createSectionCData(medicalQuestions) {
        let EB_Cancer = medicalQuestions.EB_Cancer;
        if (EB_Cancer != undefined && EB_Cancer != null && EB_Cancer.length > 0) {
            for (let i = 0; i < EB_Cancer.length; i++) {
                const element = EB_Cancer[i];
                const memberId = element.TXT_MemberIdCancer;
                let member = this.sectionCData.find(x => x.id === memberId)
                if (member != undefined) {
                    member.membername = element.TXT_MemberNameCancer;
                    member.type = element.TXT_TypeOfCancer;
                    member.date = element.DATE_Cancer;
                } else {
                    let newMember = {
                        id: memberId,
                        membername: element.TXT_MemberNameCancer,
                        type: element.TXT_TypeOfCancer,
                        date: element.DATE_Cancer
                    };
                    this.sectionCData.push(newMember);
                }
            }
        }
    }

    createSectionDData(medicalQuestions) {
        let ED_MemberPrescription = medicalQuestions.ED_MemberPrescription;
        if (ED_MemberPrescription != undefined && ED_MemberPrescription != null && ED_MemberPrescription.length > 0) {
            for (let i = 0; i < ED_MemberPrescription.length; i++) {
                const element = ED_MemberPrescription[i];
                let newMember = {
                    id: element.TXT_MemberIdPrescription,
                    membername: element.TXT_MemberName,
                    medication: element.TXT_NameOfMedication,
                    months: element.NUM_MonthsUsed,
                    reason: element.TXT_ReasonForMedication
                };
                this.sectionDData.push(newMember);
            }
        }
    }

    createSectionEData(medicalQuestions) {
        let EB_Physician = medicalQuestions.EB_Physician;
        if (EB_Physician != undefined && EB_Physician != null && EB_Physician.length > 0) {
            for (let i = 0; i < EB_Physician.length; i++) {
                const element = EB_Physician[i];
                const memberId = element.CensusMemberId;
                let member = this.sectionEData.find(x => x.id === memberId)
                if (member != undefined) {
                    member.membername = element.TXT_CensusMemberName;
                    member.physician = element.TXT_PhysicianName;
                    member.city = element.TXT_PhysicianCity;
                    member.phone = element.TXT_PhysicianPhone;
                } else {
                    let newMember = {
                        id: memberId,
                        membername: element.TXT_CensusMemberName,
                        physician: element.TXT_PhysicianName,
                        city: element.TXT_PhysicianCity,
                        phone: element.TXT_PhysicianPhone
                    };
                    this.sectionEData.push(newMember);
                }
            }
        }
    }

    handleClick(evt) {
        this.omniPrevStep();
    }
}