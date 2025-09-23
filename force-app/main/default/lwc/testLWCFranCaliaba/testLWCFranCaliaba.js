import { LightningElement,api } from 'lwc';
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";

export default class TestLWCFranCaliaba extends OmniscriptBaseMixin(LightningElement) {
    @api columns = [
        {label: 'Start Date', fieldName: 'StartDate'},
        {label: 'End Date', fieldName: 'EndDate'}
    ]

    data = [
        {
            id: 1,
            name: 'John Doe',
            info: 'Some info',
            showHelpIcon: true,
            helpText: 'This is help text for John',
            rowData: {} // will be filled dynamically
        },
        {
            id: 2,
            name: 'Jane Smith',
            info: 'Other info',
            showHelpIcon: false,
            helpText: '',
            rowData: {} // will be filled dynamically
        }
    ];

    connectedCallback(){

    }

}