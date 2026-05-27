import LightningDatatable from 'lightning/datatable';
import { LightningElement, api, wire, track } from 'lwc';
import picklistTemplate from './picklistTemplate.html';
import picklistEditTemplate from './picklistEditTemplate.html';
import badgeTemplate from './badgeTemplate.html';


export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        picklist: {
            template: picklistTemplate,
            editTemplate: picklistEditTemplate,
            standardCellLayout: true,
            typeAttributes: ['options', 'value', 'context']
        },

        // Block to show employee status as pill shaped badge
        badge: {
            template: badgeTemplate,
            standardCellLayout: true,
            typeAttributes: ['value']
        }
    };

    handleChange(event) {
        this.value = event.detail.value;
        console.log('Selected value:', this.value);
        const context = event.target.dataset.id;
        console.log('Context of combobox:', context);
    }
}