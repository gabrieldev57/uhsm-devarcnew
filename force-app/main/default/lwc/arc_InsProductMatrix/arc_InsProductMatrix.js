import InsProductMatrix from 'vlocity_ins/insProductMatrix';
import template from './arc_InsProductMatrix.html';
import { api, LightningElement } from 'lwc';
import pubsub from 'vlocity_ins/pubsub';

export default class arc_InsProductMatrix extends InsProductMatrix {

    @api lastMedicalSelectionId;
    @api rootChannel;
    @api medicalWarning;
    @api smartWarning;
    @api aiddWarning;
    pubsubPayload = {}
    productsHeader = {};
    displayProductsHeader = false;



    connectedCallback() {
        // this.productsHeader = {};
        // this.displayProductsHeader = {};
        //products={products} last-medical-selection-id={lastMedicalSelectionId} hide-header={hideHeader} is-editable={isEditable} root - channel={ rootChannel } theme = { theme } compare - limit={ compareLimit } select - btn - fn={ selectBtnFn } medical - warning={ medicalWarning } smart - warning={ smartWarning } aidd - warning={ aiddWarning }


        this.createMatrix();

        pubsub.register(this.rootChannel, this.pubsubPayload);

    }

    render() {
        return template;
    }

    getLastMedicalSelectionIndex() {
        productId = this.lastMedicalSelectionId;

    }

    /**
     * Using detailrows, create row and add to matrix
     * @param {Array} matrix
     * @param {Object} detailRows
     * EX: [{label : '', contents: [{productcells}, {productcells}], matrix: [{label: 'Coverage', contents: [] }]}, {label: Alvin, contest:[{productscell}, {productcells}]}]
     */
    addRows(matrix, detailRows) {
        if (detailRows.displaySequence) {
            Object.keys(detailRows).sort(function (a, b) { return a.displaySequence - b.displaySequence });
        }

        Object.keys(detailRows).forEach(key => {
            //take coverage map and create rows [{row1}, {row2}, {row3}]
            let details = { ...detailRows[key].matrix };
            let attributes = { ...detailRows[key].attrMatrix };
            delete detailRows[key].matrix;
            delete detailRows[key].attrMatrix;


            const row = this.createRow(key, 'vloc-ins-cell', detailRows[key]);
            row.addLabel();
            row.addDisplaySequence();
            row.addRecordType();
            // if(hideAttributes.includes(row.label)){
            //     row.showDetail = false;
            // }else{
            row.showDetail = true;
            //}
            // 
            // 
            // if (row.id === 'header' && row.contents.length > 1) {

            //     
            //     // this.productsHeader.contents = row?.contents;
            //     this.productsHeader = JSON.parse(JSON.stringify(row));
            //     this.productsHeader.className = 'vloc-ins-cell nds-size_1-of-' + (this.productsHeader.contents.length + 1);
            //     
            //     if (row.contents.length > 1) {
            //         this.displayProductsHeader = true;
            //     } else {
            //         this.displayProductsHeader = false;
            //     }
            //     row.contents = [];
            // }
            matrix.push(row);
            if (details && Object.keys(details).length > 0) {
                row.matrix = [];
                this.addRows(row.matrix, details);
            }
            if (attributes && Object.keys(attributes).length > 0) {
                row.attrMatrix = [];
                this.addRows(row.attrMatrix, attributes);
            }


        });

    }

    /**
 * Create a row
 * @param {string} id
 * @param {string} className - defaults to empty string
 * @param {Array} contents - defaults to empty array
 */
    createRow(id, className = '', contents = []) {
        return {
            id,
            contents,
            className,
            key: id + '_' + Math.random(),
            isLoading: false,
            addSizeClass: function (theme) {

                this.className += ` ${theme}-size_1-of-` + (this.contents.length + 1);
                if (id = 'header') {
                    // 
                }
            },
            addLabel: function () {
                this.label = this.contents.length > 0 && this.id !== 'header' ? this.contents[0].label : '';
            },
            addRecordType: function () {
                const recordType = this.contents.length > 0 ? this.contents[0].recordType : '';
                const isHeader = this.contents.length > 0 ? this.contents[0].isHeader : '';
                if (recordType && !isHeader) {
                    this[`is${recordType}`] = true;
                } else if (isHeader) {
                    this.isHeader = true;
                }
            },
            addDisplaySequence: function () {
                const cell = this.contents.length ? this.contents[0] : {};
                this.sortByGroup = cell.sortByGroup;
                this.displaySequence = cell.displaySequence || '';
            }
        };
    }

    handleSectionToggle(event) {
        const index = event.currentTarget.dataset.recordIndex;

        if (index !== '0') {
            //not for first row
            const row = this.matrix[index];
            row.showDetail = !row.showDetail;
        }
        // this.template.querySelector('vlocity_ins-modal').closeModal();
    }

    // productsHeader;
    // attributes;

    // set matrix(matrix) {
    //     
    //     if (!matrix || matrix.length === 0) {
    //         return;
    //     }
    //     this.productsHeader = matrix[0]?.contents;
    //     this.attributes = matrix;
    //     delete this.attributes[0]?.contents;
    // }


}