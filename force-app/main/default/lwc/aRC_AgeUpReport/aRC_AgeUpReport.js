import { LightningElement, wire, track, api } from 'lwc';
import getAgeUpsData from '@salesforce/apex/ARC_AgeUpReportController.getAgeUpsData';

export default class ARC_AgeUpReport extends LightningElement {
    ageUps = [
        // {
        //     oldestMember: 'John Doe',
        //     birthdate: '01/01/1990'
        // },
        // {
        //     oldestMember: 'Jane Doe',
        //     birthdate: '01/01/1980'
        // },
        // {
        //     oldestMember: 'Jill Doe',
        //     birthdate: '01/01/1970'
        // }
    ];
    @wire(getAgeUpsData) getAgeUpRecord({ data, error }) {
        if (data) {
            this.ageUps = data;
            this.ageUps.forEach(ageUp =>{
                console.log(ageUp.recordId,ageUp);
                
                // console.log(ageUp.oldestMember + ' ' + ageUp.recordId + ' ' + ageUp.firstNotification + ' ' + ageUp.secondNotification + ' ' + ageUp.finalNotification);
                
            });
        } else if (error) {
            console.log('Error: ' + JSON.stringify(error));
        }
    };

    get hasData() {
        return this.ageUps && this.ageUps.length > 0;
    }

    get columns() {
        return [
            { label: 'Age Up', fieldName: 'recordId', type: 'text' },
            { label: 'Oldest Member', fieldName: 'oldestMember', type: 'text' },
            { label: 'Birthdate', fieldName: 'birthdate', type: 'date' },
            { label: 'Effective Date', fieldName: 'effectiveDate', type: 'date', sorteable:true },
            { label: 'Remaining Days', fieldName: 'remainingDays', type: 'number',sorteable:true},
            { label: 'Contract Price', fieldName: 'contractTotalPrice', type: 'currency' },
            { label: 'Price Before', fieldName: 'oldPrice', type: 'currency' },
            { label: 'Price After', fieldName: 'newPrice', type: 'currency' },
            { label: 'Is Applied', fieldName: 'isApplied', type: 'boolean' },
            { label: '60 Days Email', fieldName: 'firstNotification', type: 'boolean' },
            { label: '30 Days Email', fieldName: 'secondNotification', type: 'boolean' },
            { label: '14 Days Email', fieldName: 'finalNotification', type: 'boolean' },
        ];
    }

    get filteredData() {
        return this.ageUps
        // return this.ageUp.filter(ageUp => {
        //     return ageUp;
        // });s
    }

    get showReport() {
        return this.filteredData.length > 0;
    }





}