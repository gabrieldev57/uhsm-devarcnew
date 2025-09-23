import { LightningElement, api, wire, track } from 'lwc';
import getData from '@salesforce/apex/ARC_ShowClaimsPerPolicyController.getData';


const columns = [
    {
        label: 'Shareable Medical Bill', fieldName: 'claimId', type: 'url', initialWidth: 200, sortable: "true",
        typeAttributes: {
            label: {
                fieldName: 'claimName'
            }
        },
    },
    { label: 'HAX', fieldName: 'isHax', initialWidth: 67, sortable: "true", type: 'boolean' },
    { label: 'Status', fieldName: 'claimStatus', initialWidth: 130, sortable: "true", type: 'text' },
    { label: 'DOS From', fieldName: 'claimDOSFrom', initialWidth: 100, sortable: "true", type: 'date' },
    {
        label: 'Zelis received date', fieldName: 'zelisRD', initialWidth: 100, sortable: "true", type: 'date',
        typeAttributes: {
            timeZone: 'UTC',
        }
    },
    { label: 'POS', fieldName: 'placeOfService', initialWidth: 67, sortable: "true", type: 'text' },
    {
        label: 'Vendor', fieldName: 'vendorId', initialWidth: 85, type: 'url', sortable: "true",
        typeAttributes: {
            label: {
                fieldName: 'vendorName'
            }
        }
    },
    { label: 'Sharing Program', fieldName: 'sharingProgram', initialWidth: 100, sortable: "true", },
    {
        label: 'Check Run', fieldName: 'checkrunId', type: 'url', initialWidth: 120, sortable: "true",
        typeAttributes: {
            label: {
                fieldName: 'checkrunName'
            }
        }
    },
    {
        label: 'Billed', fieldName: 'totalBilled', initialWidth: 75, sortable: "true", type: 'currency',
        cellAttributes: { alignment: 'right' }
    },
    {
        label: 'Allowed Amount', fieldName: 'totalAllowedAmount', initialWidth: 75, sortable: "true", type: 'currency',
        cellAttributes: { alignment: 'right' }
    },
    {
        label: 'Pre Exisiting Condition', fieldName: 'totalPreExCond', initialWidth: 75, sortable: "true", type: 'currency',
        cellAttributes: { alignment: 'right' }
    },
    {
        label: 'AMCS', fieldName: 'totalAMCS', initialWidth: 75, sortable: "true", type: 'currency',
        cellAttributes: { alignment: 'right' }
        ,
    },
    {
        label: 'Copay', fieldName: 'totalCopay', initialWidth: 75, sortable: "true", type: 'currency',
        cellAttributes: { alignment: 'right' }
    },
    {
        label: 'MBR Liability', fieldName: 'totalMbrLiability', initialWidth: 75, sortable: "true", type: 'currency',
        cellAttributes: { alignment: 'right' }
    },
    {
        label: 'Net Paid', fieldName: 'totalNetPaid', initialWidth: 75, sortable: "true", type: 'currency',
        cellAttributes: { alignment: 'right' }
    },
];

export default class ARC_ShowClaimsPerPolicy extends LightningElement {
    @api recordId;
    columns = columns;
    @track claimData = [];
    @track tableData = [];
    @track sortBy;
    @track sortDirection;
    @track totals = {};
    @wire(getData, { recordId: '$recordId' })
    claims({ error, data }) {
        if (data) {
            console.log('data', data)
            this.data = data;
            this.optPolicy = [{ label: 'All', value: 'all' }];
            this.optionsYear = [{ label: 'All', value: 'all' }];
            this.valueYear = 'all';

            this.valFilterPolicy = this.optPolicy[0].value;
            data.forEach(item => {
                const contReason = item.PolicyNumber?.ARC_Contract__r?.ARC_ContractReason__c.split(';');
                let aggregatorTrack = '';
                if (contReason && contReason.length > 0) {
                    if (contReason.includes('Program Upgrade') || contReason.includes('New Application') || contReason.includes('Upgraded Spin Off')) {
                        aggregatorTrack = ' (Agg. Reset)';
                    } else {
                        aggregatorTrack = ' (Agg. Carry Over)';
                    }
                }

                if (!this.optPolicy.some(element => element.value == item.PolicyNumberId) && item.PolicyNumber != null) {
                    this.optPolicy.push({ label: item.PolicyNumber.Name + aggregatorTrack, value: item.PolicyNumberId });
                }

                // MANAGE YEAR FILTER
                if (item.ARC_DOSFrom__c == null) return;

                const serviceDate = new Date(item.ARC_DOSFrom__c);
                const serviceYear = serviceDate.getFullYear();
                if (!this.optionsYear.some(element => element.value == serviceYear)) {
                    this.optionsYear.push({ label: serviceYear + '', value: serviceYear + '' });
                }
            });

            this.claimData = this.formatData(data);
            this.tableData = [...this.claimData, this.totals];
        } else if (error) {
            console.error(error);
        }
    }

    formatData(data) {
        let clmData = [];
        let totalBilled = 0;
        let totalAMCS = 0;
        let totalCopay = 0;
        let totalNetPaid = 0;
        let totalAllowedAmount = 0;
        let totalPreExCond = 0;
        let totalMbrLiability = 0;

        data.forEach(item => {
            let obj = {};
            obj['claimName'] = item.Name;
            obj['isHax'] = item.HaxSMB__c;
            obj['claimId'] = '/' + item.Id;
            obj['claimStatus'] = item.Status;
            
            if (item.ARC_DOSFrom__c) {
                //Treating this as UTC date so as to avoid javascript daylight savings time trap 
                let dateObject = new Date(item.ARC_DOSFrom__c + 'T00:00:00Z'); 
                dateObject.setUTCDate(dateObject.getUTCDate() + 1);
                obj['claimDOSFrom'] = dateObject.toISOString().split('T')[0];
            }

            obj['placeOfService'] = item.ARC_PlaceOfService__c;
            //obj['policyName'] = item.PolicyNumber?.Name;
            //obj['policyId'] = item.PolicyNumberId != null ? '/' + item.PolicyNumberId : null;
            obj['zelisRD'] = item.ARC_OriginalReceivedDate__c;
            obj['vendorName'] = item.ARC_Vendor__r?.Name;
            obj['vendorId'] = item.ARC_Vendor__c != null ? '/' + item.ARC_Vendor__c : null;
            obj['sharingProgram'] = item.ARC_MemberBenefitPlan__c;
            obj['checkrunName'] = item.ARC_CheckRun__r?.Name;
            obj['checkrunId'] = item.ARC_CheckRun__c != null ? '/' + item.ARC_CheckRun__c : null;

            obj['totalBilled'] = item.ARC_ClaimTotalAmount__c != null && item.ARC_ClaimTotalAmount__c != undefined ? Number(item.ARC_ClaimTotalAmount__c).toFixed(2) : null;
            obj['totalAMCS'] = item.ARC_TotalDeductibleAmount__c != null && item.ARC_TotalDeductibleAmount__c != undefined ? Number(item.ARC_TotalDeductibleAmount__c).toFixed(2) : null;
            obj['totalCopay'] = item.ARC_TotalCopayAmount__c != null && item.ARC_TotalCopayAmount__c != undefined ? Number(item.ARC_TotalCopayAmount__c).toFixed(2) : null;
            obj['totalNetPaid'] = item.ARC_TotalNetPaidAmount__c != null && item.ARC_TotalNetPaidAmount__c != undefined ? Number(item.ARC_TotalNetPaidAmount__c).toFixed(2) : null;
            obj['totalAllowedAmount'] = item.ARC_TotalAllowedAmount__c != null && item.ARC_TotalAllowedAmount__c != undefined ? Number(item.ARC_TotalAllowedAmount__c).toFixed(2) : null;
            obj['totalPreExCond'] = item.ARC_Total_PreExistingConditions__c != null & item.ARC_Total_PreExistingConditions__c != undefined ? Number(item.ARC_Total_PreExistingConditions__c).toFixed(2) : null;
            obj['totalMbrLiability'] = item.ARC_TotalMBRLiabilityAmount__c != null && item.ARC_TotalMBRLiabilityAmount__c != undefined ? Number(item.ARC_TotalMBRLiabilityAmount__c).toFixed(2) : null;

            clmData.push(obj);


            totalBilled += Number(item.ARC_ClaimTotalAmount__c) != null ? Number(item.ARC_ClaimTotalAmount__c) : 0;
            totalAMCS += Number(item.ARC_TotalDeductibleAmount__c) != null ? Number(item.ARC_TotalDeductibleAmount__c) : 0;
            totalCopay += Number(item.ARC_TotalCopayAmount__c) != null ? Number(item.ARC_TotalCopayAmount__c) : 0;
            totalNetPaid += Number(item.ARC_TotalNetPaidAmount__c) != null ? Number(item.ARC_TotalNetPaidAmount__c) : 0;
            totalAllowedAmount += Number(item.ARC_TotalAllowedAmount__c) != null ? Number(item.ARC_TotalAllowedAmount__c) : 0;
            totalMbrLiability += Number(item.ARC_TotalMBRLiabilityAmount__c) != null ? Number(item.ARC_TotalMBRLiabilityAmount__c) : 0;
            totalPreExCond += Number(item.ARC_Total_PreExistingConditions__c) != null ? Number(item.ARC_Total_PreExistingConditions__c) : 0;
        });
        if (data.length) {
            this.totals = {
                'totalBilled': totalBilled.toFixed(2),
                'totalAMCS': totalAMCS.toFixed(2),
                'totalCopay': totalCopay.toFixed(2),
                'totalNetPaid': totalNetPaid.toFixed(2),
                'totalAllowedAmount': totalAllowedAmount.toFixed(2),
                'totalPreExCond': totalPreExCond.toFixed(2),
                'totalMbrLiability': totalMbrLiability.toFixed(2),
            };
        }

        return clmData;
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.claimData));
        let isReverse = direction === 'asc' ? 1 : -1;

        parseData.sort((x, y) => {
            let valueX = x[fieldname];
            let valueY = y[fieldname];

            const columnType = this.getColumnType(fieldname);

            if (columnType === 'url') {
                // URL comparison
                valueX = valueX ? valueX.toString().toLowerCase() : '';
                valueY = valueY ? valueY.toString().toLowerCase() : '';
                return valueX.localeCompare(valueY) * isReverse;
            } else if (columnType === 'currency' || columnType === 'number') {
                // Numeric comparison
                valueX = valueX ? parseFloat(valueX) : null;
                valueY = valueY ? parseFloat(valueY) : null;

                if (valueX === null && valueY === null) {
                    return 0; // Leave items in the same order if both values are null
                } else if (valueX === null) {
                    return 1 * isReverse; // Nulls go to the end when ascending
                } else if (valueY === null) {
                    return -1 * isReverse; // Nulls go to the end when descending
                } else {
                    return (valueX - valueY) * isReverse;
                }
            } else if (columnType === 'date') {
                // Date comparison
                valueX = valueX ? new Date(valueX) : null;
                valueY = valueY ? new Date(valueY) : null;
                return (valueX - valueY) * isReverse;
            } else {
                // String comparison for 'text'
                valueX = valueX ? valueX.toString().toLowerCase() : '';
                valueY = valueY ? valueY.toString().toLowerCase() : '';
                return valueX.localeCompare(valueY) * isReverse;
            }
        });

        this.tableData = [...parseData, this.totals];
    }

    getColumnType(fieldname) {
        const column = this.columns.find(col => col.fieldName === fieldname);
        return column ? column.type : 'text'; // Default to 'text' if type is not specified
    }

    handleChangePolicy(e) {
        const pol = e.detail.value;

        let filteredData = this.data.filter(item => {
						let date_of_service = new Date(item.ARC_DOSFrom__c);
						date_of_service.setDate(date_of_service.getDate() + 1);
            if (
                (item.PolicyNumberId == pol || pol == 'all') &&
                (this.valueYear == 'all' || date_of_service.getFullYear() == this.valueYear)
            ) return true;
        })
        this.claimData = this.formatData(filteredData);
        this.tableData = [...this.claimData, this.totals];
    }

    handleChangeYear(e) {
        this.valueYear = e.detail.value;
				
        let filteredData = this.data.filter(item => {
						let date_of_service = new Date(item.ARC_DOSFrom__c);
						date_of_service.setDate(date_of_service.getDate() + 1);
            if (
                (date_of_service.getFullYear() == this.valueYear || this.valueYear == 'all') &&
                (this.valFilterPolicy == 'all' || item.PolicyNumberId == this.valFilterPolicy)
            ) return true;
        })
        this.claimData = this.formatData(filteredData);
        this.tableData = [...this.claimData, this.totals];
    }

    renderedCallback() {
        let haxString = '';
        this.claimData.forEach(item => {
            if (item.isHax) haxString += `.custom-table tbody tr[data-row-number="${this.claimData.indexOf(item) + 1}"] td:nth-child(2){background-color: #ffd7d773;}`;
        });
        console.log('haxstring: ' + haxString);

        let style = document.createElement('style');
        style.innerText =
            '.custom-table tr:not(:last-child) {font-weight: normal;color:inherit;text-decoration:none;background-color:inherit}' +
            '.custom-table th {z-index:1;background:rgb(240,240,240);}' +
            '.custom-table tr:last-child {font-weight: bold;color:inherit;text-decoration:none;background-color:rgb(243, 243, 243)}' +
            '.custom-table .slds-scrollable_y {padding-right: 18px;box-sizing: content-box; max-height: 300px;}' + haxString;
        console.log('style: ' + style.innerText);
        this.template.querySelector('.custom-table').appendChild(style);
    }
}