import { LightningElement, track } from 'lwc';

export default class ARC_SMBCustomReports extends LightningElement {
    openReport = false;
    @track reportsToDisplay = [
        { aRC_SMBPolicyActivity: false },
    ];

    resetVariables(){
        this.openReport = false;
        this.reportsToDisplay = [
            { aRC_SMBPolicyActivity: false },
        ];
    }

    handleSelectReport(e){
        const reportName = e.currentTarget.dataset.rpt;
        this.reportsToDisplay.find(item => item[reportName] = true);
        this.openReport = true;
    }
}