import insFileUpload from 'vlocity_ins/insFileUpload';
import template from './arc_InsFileUpload.html';
import { commonUtils } from 'vlocity_ins/insUtility';

export default class arc_InsFileUpload extends insFileUpload {
    
    render () {
        return template;
    }

    createDefaultHeaderFieldMapValues(sheetHeaders, availableFields) {
        const headerFieldMap = {};
        availableFields.forEach(field => {
            
            if(sheetHeaders.includes(field.label) && field.value != 'ARC_DependentRelationship__c') {
                headerFieldMap[field.label] = field.value;  
            }
            if(field.value == 'ARC_DependentRelationship__c'){
                headerFieldMap[field.label] = field.value;
            }
        });
        return headerFieldMap;
    }

    handleSaveClick() {

        commonUtils.triggerCustomEvent.call(this, 'clearall');
        const headerFieldMapConfig = this.createHeaderFieldConfigMap(this.headerFieldMap, this.availableFields);
        const data = this.sheetData.map(row => {
            return this.mapRowToHeaders(row, headerFieldMapConfig);
        });

        
        commonUtils.triggerCustomEvent.call(this, 'filemapcreated', {
            detail: { data }
        });
        this.closeMapper();
    }

    mapRowToHeaders(row, headerFieldConfigMap) {
        const mappedRow = {};
        Object.keys(headerFieldConfigMap).forEach(header => {
            const field = headerFieldConfigMap[header];
            if (field.allowMultiple) {
                mappedRow[field.value] = mappedRow[field.value] || [];
                mappedRow[field.value].push({
                    value: row[header],
                    header
                });
            } else {
                mappedRow[field.value] = row[header];
                if(header == 'Relationship'){
                    if ( row[header] == 'Child' ) {
                        mappedRow['ARC_DependentRelationship__c'] = 'Child';
                    } else if ( row[header] == 'Spouse' ) {
                        mappedRow['ARC_DependentRelationship__c'] = 'Spouse';
                    } else if ( row[header] == 'Domestic Partner' ) {
                        mappedRow['ARC_DependentRelationship__c'] = 'Domestic Partner';
                    } else {
                        mappedRow['ARC_DependentRelationship__c'] = '';
                    }
                }
            }
        });
        return mappedRow;
    }

    closeMapper() {
        this.template.querySelector('.vloc-ins-file-mapper').closeModal();
        this.template.querySelector('.vloc-ins-file-selector').value = '';
    }
}