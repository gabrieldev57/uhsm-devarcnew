import LightningDatatable from 'lightning/datatable';
import navigateToRecordTemplate from './navToRecordTemplate.html';

export default class DatatableWithCustomTypes extends LightningDatatable {
    static customTypes = {
        navigateToRecord: {
            template: navigateToRecordTemplate,
            standardCellLayout: true,
            typeAttributes: ['recordId']
        }
    };
}